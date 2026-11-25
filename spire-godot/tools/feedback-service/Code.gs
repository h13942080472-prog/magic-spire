// Deploy as a Google Apps Script web app: execute as yourself, access Anyone.
// Minimal service: the only hard rules are a fixed recipient (no relay), server-chosen
// attachment names (nothing executable is ever delivered) and size caps. Content is not
// otherwise validated; an attachment that is clearly not a save is dropped, never the report.
// GET reports the service capabilities (schema>=2 = accepts the optional save attachment);
// the report format field p.schema stays 1.
const FEEDBACK_RECIPIENT = 'towerlover7787@gmail.com';
const SCHEMA_VERSION = 2;
const MAX_REPORTS_PER_DAY = 80;
const DAY = 86400000;
const MAX_REPORT_CHARS = 12 * 1024 * 1024;
const MAX_TEXT = {title: 200, description: 8000, logs: 40000};
const MAX_IMAGES = 3;
const MAX_ATTACHMENT_BYTES = 2097152;
const SAVE_NAME = 'progress-save.json';

function response(value) {
  return ContentService.createTextOutput(JSON.stringify(value))
    .setMimeType(ContentService.MimeType.JSON);
}

function text(value) {
  return value === undefined || value === null ? '' : String(value);
}

// Returns null when absent or not decodable; oversized payloads are reported separately.
function decode(data) {
  if (typeof data !== 'string' || data.length === 0) return null;
  try { return Utilities.base64Decode(data); } catch (_) { return null; }
}

// A save is a JSON object of bounded size; anything else is clearly not one.
function readSave(raw) {
  if (raw === undefined || raw === null) return {blob: null, note: '未附带进度存档。'};
  const bytes = decode(raw && raw.data);
  if (!bytes || bytes.length > MAX_ATTACHMENT_BYTES) return {blob: null, note: '附带的存档超过 2 MiB 或无法解码，已丢弃。'};
  let envelope = null;
  try { envelope = JSON.parse(Utilities.newBlob(bytes).getDataAsString()); } catch (_) { envelope = null; }
  if (!envelope || typeof envelope !== 'object' || Array.isArray(envelope)) {
    return {blob: null, note: '附带的存档不是 JSON 对象，已丢弃。'};
  }
  return {blob: Utilities.newBlob(bytes, 'application/json', SAVE_NAME), note: '附带当前进度存档：' + SAVE_NAME};
}

// Throws only for reports that are too large or not JSON; the client keeps its draft.
function readReport(raw) {
  if (typeof raw !== 'string' || raw.length > MAX_REPORT_CHARS) throw new Error('invalid');
  const p = JSON.parse(raw);
  if (!p || typeof p !== 'object' || Array.isArray(p)) throw new Error('invalid');
  for (const key of Object.keys(MAX_TEXT)) {
    if (text(p[key]).length > MAX_TEXT[key]) throw new Error('invalid');
  }
  const images = Array.isArray(p.images) ? p.images.slice(0, MAX_IMAGES) : [];
  const blobs = [];
  for (const image of images) {
    const bytes = decode(image && image.data);
    if (!bytes) continue;
    if (bytes.length > MAX_ATTACHMENT_BYTES) throw new Error('invalid');
    blobs.push(Utilities.newBlob(bytes, 'image/jpeg', 'screenshot-' + (blobs.length + 1) + '.jpg'));
  }
  const context = p.context && typeof p.context === 'object' ? p.context : {};
  return {p, context, images: blobs, save: readSave(p.save)};
}

function doPost(e) {
  let report;
  try { report = readReport(e && e.postData && e.postData.contents); }
  catch (_) { return response({ok: false, code: 'invalid'}); }
  const lock = LockService.getScriptLock();
  if (!lock.tryLock(5000)) return response({ok: false, code: 'busy'});
  try {
    const {p, context, images, save} = report;
    const id = text(p.id).slice(0, 64);
    const properties = PropertiesService.getScriptProperties();
    const now = Date.now();
    const hash = Utilities.base64Encode(Utilities.computeDigest(Utilities.DigestAlgorithm.SHA_256,
      JSON.stringify({kind: p.kind, title: p.title, description: p.description, context, logs: p.logs, images: p.images})));
    const receiptKey = 'receipt_' + id;
    const receipt = id ? JSON.parse(properties.getProperty(receiptKey) || 'null') : null;
    if (receipt) return response(receipt.hash === hash ? {ok: true, id} : {ok: false, code: 'invalid'});
    let usage = JSON.parse(properties.getProperty('usage') || 'null');
    if (!usage || now - usage.start >= DAY) usage = {start: now, count: 0, last: 0};
    if (usage.count >= MAX_REPORTS_PER_DAY || MailApp.getRemainingDailyQuota() < 1) return response({ok: false, code: 'limited'});
    if (now - usage.last < 10000) return response({ok: false, code: 'busy'});
    // Reserve quota before sending, even if Google rejects the attempt.
    usage.count++; usage.last = now;
    properties.setProperty('usage', JSON.stringify(usage));
    const kind = p.kind === 'suggestion' ? '修改建议' : 'Bug反馈';
    const title = text(p.title).replace(/[\r\n]+/g, ' ').trim() || '（无标题）';
    const body = [kind + '：' + title, '', text(p.description), '', '反馈编号：' + id,
      '游戏版本：' + text(context.version), '平台：' + text(context.platform), '场景：' + text(context.scene),
      '阶段：' + text(context.phase), '层数：' + text(context.floor), '回合：' + text(context.round), '种子：' + text(context.seed),
      '', p.logs ? '玩家勾选附带的行动日志：\n' + text(p.logs) : '玩家未附带行动日志。',
      save.note].join('\n');
    MailApp.sendEmail({to: FEEDBACK_RECIPIENT, subject: '[紧缚尖塔][' + kind + '] ' + title,
      body, attachments: save.blob ? images.concat(save.blob) : images, name: '紧缚尖塔 · 游戏反馈'});
    if (id) properties.setProperty(receiptKey, JSON.stringify({hash, time: now}));
    // Receipts prevent duplicate mail on explicit retries for the following 48 hours.
    const all = properties.getProperties();
    for (const key of Object.keys(all)) {
      if (key.startsWith('receipt_') && now - JSON.parse(all[key]).time > 2 * DAY) properties.deleteProperty(key);
    }
    return response({ok: true, id});
  } catch (_) {
    // Do not return credentials, account diagnostics or submitted contents.
    return response({ok: false, code: 'unavailable'});
  } finally { lock.releaseLock(); }
}

function doGet(e) {
  const id = e && e.parameter && e.parameter.receipt;
  if (id !== undefined) {
    const receipt = PropertiesService.getScriptProperties().getProperty('receipt_' + text(id).slice(0, 64));
    return response(receipt ? {ok: true, id} : {ok: false, code: 'not_found'});
  }
  return response({service: 'spire-feedback', schema: SCHEMA_VERSION});
}
