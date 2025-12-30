// -----------------------------------------------------
// 🔧 IMPORTLAR
// -----------------------------------------------------
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const Parser = require("rss-parser");
const axios = require("axios");
const admin = require("firebase-admin");

// Firebase Admin init
admin.initializeApp();
const db = admin.firestore();
const parser = new Parser();

/* -----------------------------------------------------
   ⏰ 1) RSS HABER ÇEKME — Her 5 dakikada bir
----------------------------------------------------- */
exports.fetchRssNews = onSchedule(
  {
    schedule: "*/5 * * * *",
    timeZone: "Europe/Istanbul",
  },
  async () => {
    logger.info("📡 RSS haberleri güncelleniyor...");

    try {
      const sourceSnapshot = await db.collection("sources").get();
      const sources = sourceSnapshot.docs.map((doc) => doc.data().url);

      for (const url of sources) {
        try {
          const feed = await parser.parseURL(url);

          for (const item of feed.items) {
            const link = item.link;
            if (!link) continue;

            const newsId = Buffer.from(link).toString("base64");
            const newsRef = db.collection("news").doc(newsId);
            const exists = await newsRef.get();

            if (!exists.exists) {
              await newsRef.set({
                title: item.title || "",
                link: item.link || "",
                image: item.enclosure?.url || "",
                pubDate: item.pubDate ? new Date(item.pubDate) : new Date(),
                source: url,
                createdAt: new Date(),
              });
            }
          }
        } catch (err) {
          logger.error("❌ RSS okunurken hata oluştu:", err?.message || err);
        }
      }

      logger.info("✅ Tüm RSS haberleri güncellendi.");
    } catch (err) {
      logger.error("🔥 Genel RSS hatası:", err?.message || err);
    }
  }
);

/* -----------------------------------------------------
   🧹 2) ESKİ HABER TEMİZLEME — Günde 1 kez (180 gün)
----------------------------------------------------- */
exports.cleanupOldNews = onSchedule(
  {
    schedule: "0 4 * * *",
    timeZone: "Europe/Istanbul",
  },
  async () => {
    logger.info("🧹 Eski haber temizliği başlıyor...");

    try {
      const cutoff = new Date();
      cutoff.setDate(cutoff.getDate() - 180);

      const oldNewsSnapshot = await db
        .collection("news")
        .where("createdAt", "<", cutoff)
        .get();

      if (!oldNewsSnapshot.empty) {
        const batch = db.batch();
        oldNewsSnapshot.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
      }

      logger.info("✅ Eski haber temizliği tamamlandı.");
    } catch (err) {
      logger.error("❌ Temizlik hatası:", err);
    }
  }
);

/* -----------------------------------------------------
   🧰 3) NÖBETÇİ ECZANE — API'den veri çekme (Amasya)
   ÇIKTI: { "Merkez": [...], "Merzifon": [...], ... }
----------------------------------------------------- */
async function fetchDutyPharmacies() {
  const apiKey = process.env.COLLECTAPI_KEY;
  if (!apiKey) throw new Error("COLLECTAPI_KEY bulunamadı");

  const response = await axios.get(
    "https://api.collectapi.com/health/dutyPharmacy?il=Amasya",
    {
      headers: {
        "content-type": "application/json",
        authorization: `apikey ${apiKey}`,
      },
    }
  );

  const grouped = {};

  (response.data?.result || []).forEach((p) => {
    // İlçe ismi Türkçe haliyle, olduğu gibi
    const district = p.district || "Merkez";

    if (!grouped[district]) grouped[district] = [];
    grouped[district].push({
      name: p.name || "",
      address: p.address || "",
      phone: p.phone || "",
    });
  });

  return grouped; // { "Merkez": [...], "Merzifon": [...], ... }
}

/* -----------------------------------------------------
   📝 4) Firestore yazma
   duty_pharmacy / amasya  (TEK DOKÜMAN)
   {
     date: "2025-12-07",
     updatedAt: ...,
     data: {
       "Merkez":   [ {...}, {...} ],
       "Merzifon": [ {...} ],
       ...
     }
   }
----------------------------------------------------- */
async function writeDutyPharmaciesToFirestore(grouped) {
  logger.info("📝 Firestore yazma (tek doküman) başlıyor...");

  await db.collection("duty_pharmacy").doc("amasya").set({
    date: new Date().toISOString().split("T")[0],
    updatedAt: new Date(),
    data: grouped, // 🔥 TÜM İLÇELER BURADA
  });

  logger.info("🔥 Firestore yazma tamamlandı (amasya/data).");
}

/* -----------------------------------------------------
   ⛑️ 5) CRON — Her gece 01:00
----------------------------------------------------- */
exports.updateDutyPharmacies = onSchedule(
  {
    schedule: "0 1 * * *",
    timeZone: "Europe/Istanbul",
    secrets: ["COLLECTAPI_KEY"],
  },
  async () => {
    try {
      logger.info("⏰ Cron tetiklendi (Amasya nöbetçi eczane)...");
      const grouped = await fetchDutyPharmacies();
      await writeDutyPharmaciesToFirestore(grouped);
      logger.info("✔️ Cron işlem tamamlandı.");
    } catch (err) {
      logger.error("❌ Cron hatası:", err?.response?.data || err);
    }
  }
);

/* -----------------------------------------------------
   🧪 6) MANUEL HTTP ENDPOINT (debug)
   URL: https://<region>-<project>.cloudfunctions.net/debugDutyPharmacies
----------------------------------------------------- */
exports.debugDutyPharmacies = onRequest(
  {
    secrets: ["COLLECTAPI_KEY"],
  },
  async (req, res) => {
    try {
      logger.info("💥 Manuel tetikleme başladı!");
      const grouped = await fetchDutyPharmacies();
      await writeDutyPharmaciesToFirestore(grouped);
      res.send("OK");
    } catch (err) {
      logger.error("❌ Debug endpoint hatası:", err?.response?.data || err);
      res.status(500).send("ERROR");
    }
  }
);
