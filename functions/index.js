const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

const Parser = require("rss-parser");
const admin = require("firebase-admin");
const axios = require("axios");

const { defineSecret } = require("firebase-functions/params");

// ✅ Secret adı SABİT: GEMINI_API_KEY
const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");

// Firebase
admin.initializeApp();
const db = admin.firestore();

// RSS parser (farklı feed tag'lerini yakalamak için)
const parser = new Parser({
  timeout: 15000,
  customFields: {
    item: [
      ["image", "image"], // <image>...</image>
      ["content:encoded", "contentEncoded"], // <content:encoded>...</content:encoded>
      ["media:content", "mediaContent"], // <media:content .../>
      ["media:thumbnail", "mediaThumbnail"], // <media:thumbnail .../>
    ],
  },
});

// -----------------------------------------------------
// Helpers
// -----------------------------------------------------
function safeStr(v) {
  return typeof v === "string" ? v.trim() : "";
}

// pubDate formatları değişebilir → sağlam parse
function parsePubDate(item) {
  const iso = safeStr(item?.isoDate);
  if (iso) {
    const d = new Date(iso);
    if (!isNaN(d.getTime())) return d;
  }

  const raw = safeStr(item?.pubDate);
  if (raw) {
    const d = new Date(raw);
    if (!isNaN(d.getTime())) return d;
  }

  return new Date();
}

// HTML içinden ilk img src yakala
function extractImgSrcFromHtml(html) {
  const h = safeStr(html);
  if (!h) return "";

  const m = h.match(/<img[^>]+src=["']([^"']+)["']/i);
  return m && m[1] ? safeStr(m[1]) : "";
}

// rss-parser bazen media tag’lerini object/array olarak verir → url’yi güvenle çek
function pickMediaUrl(v) {
  if (!v) return "";
  if (Array.isArray(v)) {
    const first = v[0];
    return safeStr(first?.$?.url || first?.url);
  }
  return safeStr(v?.$?.url || v?.url);
}

// Kalıcı + maliyetsiz görsel çıkarımı (sadece RSS item içinden)
function extractImageUrl(item) {
  // 1) enclosure
  const enc = safeStr(item?.enclosure?.url);
  if (enc) return enc;

  // 2) <image> tag’i
  const imgTag = safeStr(item?.image);
  if (imgTag) return imgTag;

  // 3) media:thumbnail / media:content
  const mt = pickMediaUrl(item?.mediaThumbnail);
  if (mt) return mt;

  const mc = pickMediaUrl(item?.mediaContent);
  if (mc) return mc;

  // 4) itunes:image (bazı feed’lerde)
  const itunesImg = safeStr(item?.itunes?.image);
  if (itunesImg) return itunesImg;

  // 5) content/description içinde <img src="">
  const html1 = safeStr(item?.contentEncoded);
  const html2 = safeStr(item?.content);
  const html3 = safeStr(item?.summary);
  const html4 = safeStr(item?.contentSnippet);

  const fromHtml =
    extractImgSrcFromHtml(html1) ||
    extractImgSrcFromHtml(html2) ||
    extractImgSrcFromHtml(html3) ||
    extractImgSrcFromHtml(html4);

  if (fromHtml) return fromHtml;

  return "";
}

// -----------------------------------------------------
// 1) RSS (15 dakikada bir)
// - ref.get() yok → read yakmaz
// - sadece yoksa create eder
// -----------------------------------------------------
exports.fetchRssNews = onSchedule(
  { schedule: "*/15 * * * *", timeZone: "Europe/Istanbul" },
  async () => {
    try {
      const sourcesSnap = await db.collection("sources").get();
      const sources = sourcesSnap.docs.map((d) => d.data()?.url).filter(Boolean);

      for (const url of sources) {
        try {
          const feed = await parser.parseURL(url);

          for (const item of feed.items || []) {
            const link = safeStr(item.link || item.guid);
            if (!link) continue;

            const docId = Buffer.from(link).toString("base64url");
            const ref = db.collection("news").doc(docId);

            const imageUrl = extractImageUrl(item);

            try {
              await ref.create({
                title: safeStr(item.title),
                description: safeStr(item.contentSnippet || item.summary),
                link,
                imageUrl: imageUrl || "",
                pubDate: parsePubDate(item),
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
              });
            } catch (e) {
              // Doküman zaten varsa normal → geç
              const msg = String(e?.message || "");
              const code = String(e?.code || "");
              if (
                code === "6" || // gRPC ALREADY_EXISTS
                code === "already-exists" ||
                msg.includes("ALREADY_EXISTS") ||
                msg.includes("already exists") ||
                msg.includes("Already exists")
              ) {
                continue;
              }
              logger.error("RSS create hata:", link, e);
            }
          }
        } catch (e) {
          logger.error("RSS hata:", url, e);
        }
      }
    } catch (e) {
      logger.error("RSS genel hata:", e);
    }
  }
);

// -----------------------------------------------------
// 2) Manuel RSS tetik (Debug) - HTTP
// -----------------------------------------------------
exports.runFetchNow = onRequest({ region: "us-central1" }, async (req, res) => {
  try {
    logger.info("Manual fetch tetiklendi");

    const sourcesSnap = await db.collection("sources").get();
    const sources = sourcesSnap.docs.map((d) => d.data()?.url).filter(Boolean);

    for (const url of sources) {
      const feed = await parser.parseURL(url);

      for (const item of feed.items || []) {
        const link = safeStr(item.link || item.guid);
        if (!link) continue;

        const docId = Buffer.from(link).toString("base64url");
        const ref = db.collection("news").doc(docId);

        const imageUrl = extractImageUrl(item);

        try {
          await ref.create({
            title: safeStr(item.title),
            description: safeStr(item.contentSnippet || item.summary),
            link,
            imageUrl: imageUrl || "",
            pubDate: parsePubDate(item),
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        } catch (e) {
          // varsa geç
        }
      }
    }

    res.send("RSS fetch tamamlandı");
  } catch (e) {
    logger.error(e);
    res.status(500).send("Hata oluştu");
  }
});

// -----------------------------------------------------
// 3) Günün Özeti (Gemini) - Scheduled
// - Firestore: daily_digests/YYYY-MM-DD
// - FCM topic: daily_digest
// -----------------------------------------------------
exports.sendDailyDigest = onSchedule(
  // Test için 1 dakikada bir:
  { schedule: "0 20 * * *", timeZone: "Europe/Istanbul", secrets: [GEMINI_API_KEY] },

  // Canlıda bunu kullan:
  // { schedule: "0 20 * * *", timeZone: "Europe/Istanbul", secrets: [GEMINI_API_KEY] },

  async () => {
    try {
      const now = new Date();
      const dateStr = now.toISOString().slice(0, 10);

      // Cache: aynı gün 1 kere üret
      const digestRef = db.collection("daily_digests").doc(dateStr);
      const existing = await digestRef.get();
      if (existing.exists) {
        logger.info("Bugünün özeti zaten var.");
        return;
      }

      // Bugünün haberlerini çek (00:00 -> şimdi)
      const start = new Date();
      start.setHours(0, 0, 0, 0);

      const newsSnap = await db
        .collection("news")
        .where("pubDate", ">=", start)
        .orderBy("pubDate", "desc")
        .limit(100)
        .get();

      if (newsSnap.empty) {
        logger.info("Bugün haber yok.");
        return;
      }

      // ✅ input'u kısalt: en fazla 40 haber, description max 200 char
      const lines = newsSnap.docs.slice(0, 40).map((doc, i) => {
        const d = doc.data() || {};
        const title = typeof d.title === "string" ? d.title.trim() : "";
        let desc = typeof d.description === "string" ? d.description.trim() : "";
        if (desc.length > 200) desc = desc.slice(0, 200) + "...";
        return `${i + 1}) ${title}${desc ? " — " + desc : ""}`;
      });
      const compactNewsList = lines.join("\n");

      const apiKey = GEMINI_API_KEY.value();

      // ✅ Yeni model
      const modelName = "models/gemini-2.5-flash";

      // ✅ URL: backtick şart (Windows'ta da aynı)
      const url = `https://generativelanguage.googleapis.com/v1beta/${modelName}:generateContent`;

      const prompt = `Yalnızca aşağıdaki haber başlıkları ve açıklamalarına dayan.
Türkçe, nötr haber diliyle TAM OLARAK 3 cümle yaz.
Başlık yazma, maddeleme yapma, emoji kullanma.
Toplam metin en az 60 kelime olsun.
Uydurma yapma.

Haberler:
${compactNewsList}`;

      const payload = {
        contents: [
          {
            role: "user",
            parts: [{ text: prompt }],
          },
        ],
        generationConfig: {
          temperature: 0.2,
          maxOutputTokens: 256,
        },
      };

      const response = await axios.post(url, payload, {
        timeout: 30000,
        headers: {
          "content-type": "application/json",
          "x-goog-api-key": apiKey,
        },
      });

      // ✅ summary parse (parts birden fazla olabilir)
      const cand = response.data?.candidates?.[0];
      let summary =
        cand?.content?.parts?.map((p) => p.text).filter(Boolean).join("") || "";
      summary = (summary || "").trim();


      // Firestore’a yaz (cache)
      await digestRef.set({
        date: dateStr,
        summary,
        newsCount: newsSnap.size,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Push (topic)
      await admin.messaging().send({
        topic: "daily_digest",
        notification: {
          title: "Günün Özeti",
          body: summary,
        },
      });

      logger.info("Günün özeti gönderildi.");
    } catch (e) {
      const status = e?.response?.status;
      const data = e?.response?.data;
      logger.error("sendDailyDigest genel hata:", status, data || e);
      throw e;
    }
  }
);

// -----------------------------------------------------
// 4) Test bildirimi (token ile)
// -----------------------------------------------------
exports.sendTestToToken = onRequest({ region: "us-central1" }, async (req, res) => {
  try {
    const token = (req.query.token || "").toString().trim();
    if (!token) {
      res.status(400).send("token query param gerekli. Örn: ?token=XXXX");
      return;
    }

    await admin.messaging().send({
      token,
      notification: {
        title: "Test Bildirimi",
        body: "FCM token ile test başarılı ✅",
      },
    });

    res.send("OK");
  } catch (e) {
    logger.error(e);
    res.status(500).send("ERROR");
  }
});