const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const Parser = require("rss-parser");
const admin = require("firebase-admin");
const axios = require("axios");

const { defineSecret } = require("firebase-functions/params");

// Firebase
admin.initializeApp();
const db = admin.firestore();

// RSS parser (farklı feed tag'lerini yakalamak için)
const parser = new Parser({
  timeout: 15000,
  customFields: {
    item: [
      ["image", "image"],
      ["category", "category"],
      ["content:encoded", "contentEncoded"],
      ["media:content", "mediaContent"],
      ["media:thumbnail", "mediaThumbnail"],
    ],
  },
});

// -----------------------------------------------------
// Helpers
// -----------------------------------------------------
function safeStr(v) {
  return typeof v === "string" ? v.trim() : "";
}

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

function extractImgSrcFromHtml(html) {
  const h = safeStr(html);
  if (!h) return "";

  const m = h.match(/<img[^>]+src=["']([^"']+)["']/i);
  return m && m[1] ? safeStr(m[1]) : "";
}

function pickMediaUrl(v) {
  if (!v) return "";
  if (Array.isArray(v)) {
    const first = v[0];
    return safeStr(first?.$?.url || first?.url);
  }
  return safeStr(v?.$?.url || v?.url);
}

function extractImageUrl(item) {
  const enc = safeStr(item?.enclosure?.url);
  if (enc) return enc;

  const imgTag = safeStr(item?.image);
  if (imgTag) return imgTag;

  const mt = pickMediaUrl(item?.mediaThumbnail);
  if (mt) return mt;

  const mc = pickMediaUrl(item?.mediaContent);
  if (mc) return mc;

  const itunesImg = safeStr(item?.itunes?.image);
  if (itunesImg) return itunesImg;

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

function extractCategory(item) {
  const directCategory = safeStr(item?.category);
  if (directCategory) return directCategory;

  if (Array.isArray(item?.categories) && item.categories.length > 0) {
    const firstCategory = safeStr(item.categories[0]);
    if (firstCategory) return firstCategory;
  }

  return "Genel";
}

function createCategorySlug(category) {
  return safeStr(category)
    .toLocaleLowerCase("tr-TR")
    .replaceAll("ı", "i")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "") || "genel";
}

async function findHourlyNewsCandidate() {
  const now = new Date();

  let selectedDoc = null;
  let selectedWindowHours = null;

  for (const hours of [1, 2, 3]) {
    const start = new Date(now.getTime() - hours * 60 * 60 * 1000);

    const newsSnap = await db
      .collection("news")
      .where("pubDate", ">=", start)
      .where("pubDate", "<=", now)
      .orderBy("pubDate", "desc")
      .limit(30)
      .get();

    if (newsSnap.empty) {
      logger.info(`Son ${hours} saat içinde haber yok.`);
      continue;
    }

    for (const doc of newsSnap.docs) {
      const sentRef = db.collection("sent_hourly_news").doc(doc.id);
      const sentSnap = await sentRef.get();

      if (!sentSnap.exists) {
        selectedDoc = doc;
        selectedWindowHours = hours;
        break;
      }
    }

    if (selectedDoc) break;
  }

  return { selectedDoc, selectedWindowHours };
}

async function sendHourlyNews(doc, selectedWindowHours) {
  const data = doc.data() || {};
  const title = safeStr(data.title) || "Yeni Haber";
  const body =
    safeStr(data.description).slice(0, 140) ||
    "Detaylar için uygulamayı açın.";
  const link = safeStr(data.link);
  const imageUrl = safeStr(data.imageUrl);

  const message = {
    topic: "hourly_news",
    notification: {
      title,
      body,
    },
    data: {
      type: "news",
      newsId: doc.id,
      link,
    },
    android: {
      notification: {
        channelId: "hourly_news_channel_v1",
        priority: "high",
        sound: "hourly_news_sound",
        imageUrl: imageUrl || undefined,
      },
    },
    apns: {
      fcmOptions: {
        image: imageUrl || undefined,
      },
    },
  };

  await admin.messaging().send(message);

  await db.collection("sent_hourly_news").doc(doc.id).set({
    newsId: doc.id,
    title,
    link,
    sentAt: admin.firestore.FieldValue.serverTimestamp(),
    selectedWindowHours,
    pubDate: data.pubDate || null,
  });

  logger.info(
    `Saatlik haber bildirimi gönderildi. newsId=${doc.id}, pencere=${selectedWindowHours} saat`
  );

  return { title, link };
}


// RSS Scraping (every 15 minutes)
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
            const category = extractCategory(item);
            const categorySlug = createCategorySlug(category);

            try {
              await ref.create({
                title: safeStr(item.title),
                description: safeStr(item.contentSnippet || item.summary),
                link,
                imageUrl: imageUrl || "",
                category,
                categorySlug,
                pubDate: parsePubDate(item),
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
              });
            } catch (e) {
              const msg = String(e?.message || "");
              const code = String(e?.code || "");

              if (
                code === "6" ||
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

// Hourly News Notification (every hour, without 22pm - 8 am)
exports.sendHourlyNewsNotification = onSchedule(
  { schedule: "0 * * * *", timeZone: "Europe/Istanbul" },
  async () => {
    try {
      // Türkiye saati
      const now = new Date();

      const turkeyHour = Number(
        new Intl.DateTimeFormat("tr-TR", {
          timeZone: "Europe/Istanbul",
          hour: "2-digit",
          hour12: false,
        }).format(now)
      );

      // 22:00 - 07:59 arası bildirim gönderme
      if (turkeyHour >= 22 || turkeyHour < 8) {
        logger.info("Gece saatleri. Bildirim gönderilmedi.");
        return;
      }

      const { selectedDoc, selectedWindowHours } =
          await findHourlyNewsCandidate();

      if (!selectedDoc) {
        logger.info(
          "1-3 saat aralığında gönderilecek yeni haber bulunamadı."
        );
        return;
      }

      await sendHourlyNews(
        selectedDoc,
        selectedWindowHours
      );

    } catch (e) {
      logger.error(
        "sendHourlyNewsNotification hata:",
        e
      );

      throw e;
    }
  }
);

// Obituary Announcements (every hour)
const cheerio = require("cheerio");
const BASE_URL = "https://amasya.bel.tr";
const LIST_URL = `${BASE_URL}/aramizdan-ayrilanlar`;
const COLLECTION_NAME = "vefat_records";
function normalizeText(value = "") {
  return String(value || "")
    .replace(/\u00a0/g, " ")
    .replace(/\r/g, "\n")
    .replace(/[ \t]+/g, " ")
    .replace(/\n+/g, " ")
    .trim();
}
function toAbsoluteUrl(href = "") {
  const clean = String(href || "").trim();
  if (!clean) return "";
  if (clean.startsWith("http://") || clean.startsWith("https://")) return clean;
  if (clean.startsWith("/")) return `${BASE_URL}${clean}`;
  return `${BASE_URL}/${clean}`;
}
function toSlugFromUrl(url = "") {
  try {
    const clean = url.split("?")[0].split("#")[0];
    const parts = clean.split("/").filter(Boolean);
    return parts[parts.length - 1] || "";
  } catch (e) {
    return "";
  }
}
function parseTurkishDate(dateStr = "") {
  const clean = normalizeText(dateStr)
    .replace(/^Ölüm Tarihi:\s*/i, "")
    .replace(/^Defin Tarihi:\s*/i, "")
    .trim();

  if (!clean) return null;

  const match = clean.match(/^(\d{2})\/(\d{2})\/(\d{4})$/);
  if (!match) return null;

  const [, dd, mm, yyyy] = match;
  const iso = `${yyyy}-${mm}-${dd}T00:00:00+03:00`;
  const date = new Date(iso);

  if (isNaN(date.getTime())) return null;
  return admin.firestore.Timestamp.fromDate(date);
}
async function fetchHtml(url) {
  const response = await axios.get(url, {
    timeout: 20000,
    headers: {
      "User-Agent": "Mozilla/5.0 (compatible; AmasyaSonDakikaBot/1.0)",
      Accept: "text/html,application/xhtml+xml",
    },
  });

  return response.data;
}
async function parseListPage(page = 1) {
  const url = page === 1 ? LIST_URL : `${LIST_URL}?sayfa=${page}`;
  const html = await fetchHtml(url);
  const $ = cheerio.load(html);

  const items = [];
  const seen = new Set();

  $(".blog-listing article.entry-post header.entry-header h4 a").each((_, el) => {
    const href = $(el).attr("href");
    const detailUrl = toAbsoluteUrl(href);
    const slug = toSlugFromUrl(detailUrl);

    if (!detailUrl || !slug || seen.has(slug)) return;
    seen.add(slug);

    items.push({
      slug,
      detailUrl,
      sourcePage: page,
    });
  });

  return items;
}
async function parseDetailPage(detailUrl) {
  const html = await fetchHtml(detailUrl);
  const $ = cheerio.load(html);

  const contentRoot = $(".content-wrap .entry.entry-page").first();

  const name = normalizeText(
    contentRoot.find("h2.entry-title").first().text()
  );

  const deathDateStr = normalizeText(
    contentRoot.find(".meta-data .meta-date").eq(0).text()
  ).replace(/^Ölüm Tarihi:\s*/i, "");

  const burialDateStr = normalizeText(
    contentRoot.find(".meta-data .meta-date").eq(1).text()
  ).replace(/^Defin Tarihi:\s*/i, "");

  const infoParagraph = contentRoot.find(".entry-content p").first().text();
  const burialPlace = normalizeText(infoParagraph)
    .replace(/^.*?Defin Yeri:\s*/i, "")
    .replace(/\s*Ölüm Sebebi:.*$/i, "")
    .trim();

  const paragraphs = [];

  contentRoot.find(".entry-content .grid-column p").each((_, el) => {
    const txt = normalizeText($(el).text());

    if (!txt) return;

    paragraphs.push(txt);
  });

  const fullText = paragraphs.join(" - ");

  return {
    name,
    deathDateStr,
    burialDateStr,
    burialPlace,
    fullText,
  };
}
async function upsertVefatRecord(record) {
  const ref = db.collection(COLLECTION_NAME).doc(record.slug);

  await ref.set(
    {
      slug: record.slug,
      name: record.name || "",
      detailUrl: record.detailUrl || "",
      fullText: record.fullText || "",
      deathDate: record.deathDate || null,
      burialDate: record.burialDate || null,
      burialPlace: record.burialPlace || "",
      sourcePage: record.sourcePage || 1,
      fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
      deathReason: admin.firestore.FieldValue.delete(),
    },
    { merge: true }
  );

  const snap = await ref.get();
  if (!snap.get("createdAt")) {
    await ref.set(
      {
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }

  return { ok: true, slug: record.slug };
}
async function seedInitialPages(pageCount = 3) {
  let savedCount = 0;

  for (let page = 1; page <= pageCount; page++) {
    const listItems = await parseListPage(page);

    for (const item of listItems) {
      try {
        const detail = await parseDetailPage(item.detailUrl);

        await upsertVefatRecord({
          ...item,
          name: detail.name,
          deathDate: parseTurkishDate(detail.deathDateStr),
          burialDate: parseTurkishDate(detail.burialDateStr),
          burialPlace: detail.burialPlace,
          fullText: detail.fullText,
        });

        savedCount++;
      } catch (e) {
        logger.error(`Vefat seed hata: ${item.detailUrl}`, e);
      }
    }
  }

  return { ok: true, savedCount };
}
exports.syncVefatRecords = onSchedule(
  {
    schedule: "every 60 minutes",
    region: "europe-west1",
    timeZone: "Europe/Istanbul",
    memory: "512MiB",
    timeoutSeconds: 120,
  },
  async () => {
    const pagesToCheck = 2;
    let checkedCount = 0;
    let savedCount = 0;

    try {
      for (let page = 1; page <= pagesToCheck; page++) {
        const listItems = await parseListPage(page);

        for (const item of listItems) {
          checkedCount++;

          try {
            const detail = await parseDetailPage(item.detailUrl);

            await upsertVefatRecord({
              ...item,
              name: detail.name,
              deathDate: parseTurkishDate(detail.deathDateStr),
              burialDate: parseTurkishDate(detail.burialDateStr),
              burialPlace: detail.burialPlace,
              fullText: detail.fullText,
            });

            savedCount++;
            logger.info(`Vefat kaydı işlendi: ${item.slug}`);
          } catch (e) {
            logger.error(`Vefat detay parse hatası: ${item.detailUrl}`, e);
          }
        }
      }

      logger.info("Vefat senkronizasyonu tamamlandı", {
        checkedCount,
        savedCount,
      });
    } catch (error) {
      logger.error("Vefat senkronizasyon hatası", error);
    }
  }
);

// Duty Pharmacy (every day at 9 am)
const COLLECTAPI_KEY = defineSecret("COLLECTAPI_KEY");
const OPENWEATHER_API_KEY = defineSecret("OPENWEATHER_API_KEY");
function getTodayStringTR() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const day = String(now.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}
async function fetchAndSaveDutyPharmacies() {
  const url = "https://api.collectapi.com/health/dutyPharmacy?il=Amasya";

  logger.info("💊 CollectAPI'den Amasya nöbetçi eczaneleri çekiliyor...");

  const response = await axios.get(url, {
    headers: {
      authorization: COLLECTAPI_KEY.value(),
      "content-type": "application/json",
    },
    timeout: 20000,
  });

  if (!response.data || response.data.success !== true) {
    throw new Error(
      `CollectAPI başarısız cevap döndü: ${JSON.stringify(response.data)}`
    );
  }

  const result = Array.isArray(response.data.result) ? response.data.result : [];

  const items = result.map((item) => ({
    name: item?.name || "",
    dist: item?.dist || "",
    address: item?.address || "",
    phone: item?.phone || "",
    loc: item?.loc || "",
  }));

  const districtCounts = {};

  for (const item of items) {
    const district = (item.dist || "BILINMEYEN").trim();
    districtCounts[district] = (districtCounts[district] || 0) + 1;
  }

  logger.info("📊 İlçe bazlı nöbetçi eczane sayıları:", districtCounts);
  logger.info(`📦 Toplam kayıt sayısı: ${items.length}`);

  await db.collection("duty_pharmacy").doc("amasya").set(
    {
      il: "Amasya",
      date: getTodayStringTR(),
      items,
      count: items.length,
      districtCounts,
      source: "collectapi",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  logger.info(`✅ ${items.length} adet nöbetçi eczane kaydedildi.`);

  return {
    success: true,
    count: items.length,
    districtCounts,
    items,
  };
}
exports.updateDutyPharmacies = onSchedule(
  {
    schedule: "0 9 * * *",
    timeZone: "Europe/Istanbul",
    region: "us-central1",
    memory: "256MiB",
    secrets: [COLLECTAPI_KEY],
  },
  async () => {
    try {
      await fetchAndSaveDutyPharmacies();
    } catch (error) {
      logger.error("❌ updateDutyPharmacies hatası:", error);
    }
  }
);

// Weather Forecast  (every hour)
const WEATHER_COLLECTION_NAME = "weather_forecasts";
const WEATHER_DISTRICTS = [
  {
    id: "amasya_merkez",
    name: "Amasya Merkez",
    lat: 40.6533,
    lon: 35.8331,
  },
  {
    id: "merzifon",
    name: "Merzifon",
    lat: 40.8733,
    lon: 35.4631,
  },
  {
    id: "suluova",
    name: "Suluova",
    lat: 40.8313,
    lon: 35.6479,
  },
  {
    id: "tasova",
    name: "Taşova",
    lat: 40.7597,
    lon: 36.3222,
  },
  {
    id: "goynucek",
    name: "Göynücek",
    lat: 40.3992,
    lon: 35.5250,
  },
  {
    id: "gumushacikoy",
    name: "Gümüşhacıköy",
    lat: 40.8731,
    lon: 35.2147,
  },
  {
    id: "hamamozu",
    name: "Hamamözü",
    lat: 40.7847,
    lon: 35.0256,
  },
];
function unixToTimestamp(seconds) {
  if (!seconds) return null;
  return admin.firestore.Timestamp.fromDate(new Date(seconds * 1000));
}
function normalizeWeatherText(value = "") {
  return String(value || "").trim();
}
function mapCurrentWeather(rawCurrent = {}) {
  const weather = Array.isArray(rawCurrent.weather)
    ? rawCurrent.weather[0] || {}
    : {};

  return {
    temp: rawCurrent.temp ?? null,
    feelsLike: rawCurrent.feels_like ?? null,
    humidity: rawCurrent.humidity ?? null,
    pressure: rawCurrent.pressure ?? null,
    windSpeed: rawCurrent.wind_speed ?? null,
    windDeg: rawCurrent.wind_deg ?? null,
    clouds: rawCurrent.clouds ?? null,
    uvi: rawCurrent.uvi ?? null,
    visibility: rawCurrent.visibility ?? null,
    description: normalizeWeatherText(weather.description),
    main: normalizeWeatherText(weather.main),
    icon: normalizeWeatherText(weather.icon),
    dt: unixToTimestamp(rawCurrent.dt),
    sunrise: unixToTimestamp(rawCurrent.sunrise),
    sunset: unixToTimestamp(rawCurrent.sunset),
  };
}
function mapHourlyWeather(rawHourly = []) {
  return rawHourly.slice(0, 24).map((item) => {
    const weather = Array.isArray(item.weather) ? item.weather[0] || {} : {};

    return {
      dt: unixToTimestamp(item.dt),
      temp: item.temp ?? null,
      feelsLike: item.feels_like ?? null,
      humidity: item.humidity ?? null,
      windSpeed: item.wind_speed ?? null,
      pop: item.pop ?? null,
      description: normalizeWeatherText(weather.description),
      icon: normalizeWeatherText(weather.icon),
    };
  });
}
function mapDailyWeather(rawDaily = []) {
  return rawDaily.slice(0, 7).map((item) => {
    const weather = Array.isArray(item.weather) ? item.weather[0] || {} : {};

    return {
      dt: unixToTimestamp(item.dt),
      sunrise: unixToTimestamp(item.sunrise),
      sunset: unixToTimestamp(item.sunset),
      minTemp: item.temp?.min ?? null,
      maxTemp: item.temp?.max ?? null,
      dayTemp: item.temp?.day ?? null,
      nightTemp: item.temp?.night ?? null,
      humidity: item.humidity ?? null,
      windSpeed: item.wind_speed ?? null,
      pop: item.pop ?? null,
      description: normalizeWeatherText(weather.description),
      icon: normalizeWeatherText(weather.icon),
      summary: normalizeWeatherText(item.summary),
    };
  });
}
async function fetchWeatherForDistrict(district) {
  const apiKey = OPENWEATHER_API_KEY.value();

  const url =
    "https://api.openweathermap.org/data/3.0/onecall" +
    `?lat=${district.lat}` +
    `&lon=${district.lon}` +
    "&exclude=minutely,alerts" +
    "&units=metric" +
    "&lang=tr" +
    `&appid=${apiKey}`;

  const response = await axios.get(url, {
    timeout: 20000,
    headers: {
      "content-type": "application/json",
    },
  });

  const data = response.data || {};

  const payload = {
    districtId: district.id,
    districtName: district.name,
    lat: district.lat,
    lon: district.lon,
    timezone: data.timezone || "Europe/Istanbul",
    timezoneOffset: data.timezone_offset ?? null,
    source: "openweather",
    current: mapCurrentWeather(data.current || {}),
    hourly: mapHourlyWeather(data.hourly || []),
    daily: mapDailyWeather(data.daily || []),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await db
    .collection(WEATHER_COLLECTION_NAME)
    .doc(district.id)
    .set(payload, { merge: true });

  return {
    id: district.id,
    name: district.name,
    temp: payload.current.temp,
    description: payload.current.description,
  };
}
async function updateAllWeatherForecasts() {
  const results = [];

  for (const district of WEATHER_DISTRICTS) {
    try {
      const result = await fetchWeatherForDistrict(district);
      results.push({
        ...result,
        ok: true,
      });

      logger.info(`Hava durumu güncellendi: ${district.name}`);
    } catch (error) {
      const status = error?.response?.status;
      const data = error?.response?.data;

      results.push({
        id: district.id,
        name: district.name,
        ok: false,
        error: data?.message || error.message,
      });

      logger.error(
        `Hava durumu güncelleme hatası: ${district.name}`,
        status,
        data || error
      );
    }
  }

  await db.collection("system_status").doc("weather").set(
    {
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      results,
    },
    { merge: true }
  );

  return results;
}

exports.updateWeatherForecasts = onSchedule(
  {
    schedule: "0 * * * *",
    timeZone: "Europe/Istanbul",
    region: "us-central1",
    memory: "256MiB",
    timeoutSeconds: 120,
    secrets: [OPENWEATHER_API_KEY],
  },
  async () => {
    const results = await updateAllWeatherForecasts();

    logger.info("Hava durumu otomatik güncelleme tamamlandı", {
      count: results.length,
      successCount: results.filter((r) => r.ok).length,
    });
  }
);

// 10) Shorts - Bunny Stream
const BUNNY_STREAM_API_KEY = defineSecret("BUNNY_STREAM_API_KEY");
const BUNNY_STREAM_LIBRARY_ID = defineSecret("BUNNY_STREAM_LIBRARY_ID");
function requirePost(req, res) {
  if (req.method !== "POST") {
    res.status(405).json({
      ok: false,
      error: "Only POST method is allowed",
    });
    return false;
  }

  return true;
}
exports.createShortsVideoDraft = onRequest(
  {
    region: "us-central1",
    memory: "256MiB",
    timeoutSeconds: 60,
    secrets: [BUNNY_STREAM_API_KEY, BUNNY_STREAM_LIBRARY_ID],
  },
  async (req, res) => {
    try {
      if (!requirePost(req, res)) return;

      const body = req.body || {};

      const title = safeStr(body.title);
      const description = safeStr(body.description);
      const sourceName = safeStr(body.sourceName);
      const sourceUsername = safeStr(body.sourceUsername);
      const sourcePlatform = safeStr(body.sourcePlatform) || "instagram";
      const sourceUrl = safeStr(body.sourceUrl);
      const channelName = safeStr(body.channelName) || "Video Gündem";

      if (!title) {
        res.status(400).json({
          ok: false,
          error: "title zorunlu",
        });
        return;
      }

      const apiKey = BUNNY_STREAM_API_KEY.value();
      const libraryId = BUNNY_STREAM_LIBRARY_ID.value();

      // 1) Bunny üzerinde video objesi oluştur
      const bunnyCreateUrl = `https://video.bunnycdn.com/library/${libraryId}/videos`;

      const bunnyCreateResponse = await axios.post(
        bunnyCreateUrl,
        {
          title,
        },
        {
          timeout: 30000,
          headers: {
            AccessKey: apiKey,
            "content-type": "application/json",
          },
        }
      );

      const bunnyVideo = bunnyCreateResponse.data || {};
      const videoId = bunnyVideo.guid || bunnyVideo.videoGuid || bunnyVideo.id;

      if (!videoId) {
        logger.error("Bunny videoId alınamadı:", bunnyVideo);
        res.status(500).json({
          ok: false,
          error: "Bunny videoId alınamadı",
        });
        return;
      }

      const now = new Date();
      const expiresAt = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

      // 2) Firestore'a draft/processing kaydı oluştur
      const ref = await db.collection("shorts_videos").add({
        title,
        description,
        sourceName,
        sourceUsername,
        sourcePlatform,
        sourceUrl,
        channelName,

        provider: "bunny",
        videoId,
        playbackUrl: "",
        hlsUrl: "",
        thumbnailUrl: "",

        duration: 0,
        status: "processing",

        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
      });

      res.status(200).json({
        ok: true,
        docId: ref.id,
        videoId,
        uploadUrl: `https://video.bunnycdn.com/library/${libraryId}/videos/${videoId}`,
      });
    } catch (error) {
      const status = error?.response?.status;
      const data = error?.response?.data;

      logger.error("createShortsVideoDraft hata:", status, data || error);

      res.status(500).json({
        ok: false,
        error: data?.message || error.message,
      });
    }
  }
);
exports.publishShortsVideo = onRequest(
  {
    region: "us-central1",
    memory: "256MiB",
    timeoutSeconds: 60,
    secrets: [BUNNY_STREAM_LIBRARY_ID],
  },
  async (req, res) => {
    try {
      if (!requirePost(req, res)) return;

      const body = req.body || {};

      const docId = safeStr(body.docId);
      const videoId = safeStr(body.videoId);
      const cdnHostname = safeStr(body.cdnHostname);

      if (!docId || !videoId || !cdnHostname) {
        res.status(400).json({
          ok: false,
          error: "docId, videoId ve cdnHostname zorunlu",
        });
        return;
      }

      const playbackUrl = `https://${cdnHostname}/${videoId}/playlist.m3u8`;
      const thumbnailUrl = `https://${cdnHostname}/${videoId}/thumbnail.jpg`;

      await db.collection("shorts_videos").doc(docId).set(
        {
          playbackUrl,
          hlsUrl: playbackUrl,
          thumbnailUrl,
          status: "published",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      res.status(200).json({
        ok: true,
        playbackUrl,
        thumbnailUrl,
      });
    } catch (error) {
      logger.error("publishShortsVideo hata:", error);

      res.status(500).json({
        ok: false,
        error: error.message,
      });
    }
  }
);