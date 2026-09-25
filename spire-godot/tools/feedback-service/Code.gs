// Deploy as a Google Apps Script web app: execute as yourself, access Anyone.
// Fixed recipient: callers cannot turn this endpoint into an arbitrary mail relay.
// GET reports the service capabilities (schema>=2 = accepts the optional save attachment);
// the report format field p.schema stays 1.
const FEEDBACK_RECIPIENT = 'towerlover7787@gmail.com';
const SCHEMA_VERSION = 2;
const MAX_REPORTS_PER_DAY = 80;
const DAY = 86400000;
const MAX_REPORT_CHARS = 12 * 1024 * 1024;
const MAX_SAVE_BYTES = 2097152;
const MAX_SAVE_CHARS = 2796204;

function response(value) {
  return ContentService.createTextOutput(JSON.stringify(value))
    .setMimeType(ContentService.MimeType.JSON);
}

// Optional save attachment: a single `.json` file the game already serialized; the service
// only checks its shape, size and envelope and forwards the original bytes untouched.
function validateSave(raw) {
  if (raw === undefined) return null;
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) throw new Error('invalid');
  const keys = Object.keys(raw);
  if (keys.length !== 2 || !keys.includes('name') || !keys.includes('data')) throw new Error('invalid');
  if (typeof raw.name !== 'string' || !/^[A-Za-z0-9_-]{1,32}\.json$/.test(raw.name)) throw new Error('invalid');
  if (typeof raw.data !== 'string' || raw.data.length > MAX_SAVE_CHARS ||
      raw.data.length % 4 !== 0 || !/^[A-Za-z0-9+/]+={0,2}$/.test(raw.data)) throw new Error('invalid');
  const bytes = Utilities.base64Decode(raw.data);
  if (bytes.length < 4 || bytes.length > MAX_SAVE_BYTES) throw new Error('invalid');
  const envelope = JSON.parse(Utilities.newBlob(bytes).getDataAsString());
  if (!envelope || typeof envelope !== 'object' || Array.isArray(envelope) || envelope.format !== 2) {
    throw new Error('invalid');
  }
  return Utilities.newBlob(bytes, 'application/json', raw.name);
}

function validateReport(raw) {
  if (typeof raw !== 'string' || raw.length > MAX_REPORT_CHARS) throw new Error('invalid');
  const p = JSON.parse(raw);
  if (!p || p.schema !== 1 || !/^[a-f0-9]{32}$/.test(p.id) ||
      !['bug', 'suggestion'].includes(p.kind)) throw new Error('invalid');
  for (const [key, max] of [['title', 100], ['description', 4000], ['logs', 18000]]) {
    if (typeof p[key] !== 'string' || p[key].length > max) throw new Error('invalid');
  }
  if (!p.title.trim() || /[\r\n]/.test(p.title) || !p.description.trim()) throw new Error('invalid');
  if (!p.context || typeof p.context !== 'object' || Array.isArray(p.context)) throw new Error('invalid');
  const context = {};
  for (const key of ['version', 'platform', 'phase', 'scene', 'floor', 'round', 'seed']) {
    const value = p.context[key];
    if (!['string', 'number'].includes(typeof value) || String(value).length > 120) throw new Error('invalid');
    context[key] = value;
  }
  if (!Array.isArray(p.images) || p.images.length > 3) throw new Error('invalid');
  const images = p.images.map((image, i) => {
    const data = image && image.data;
    if (typeof data !== 'string' || data.length > 2796204 ||
        data.length % 4 !== 0 || !/^[A-Za-z0-9+/]+={0,2}$/.test(data)) throw new Error('invalid');
    const bytes = Utilities.base64Decode(data);
    if (bytes.length < 4 || bytes.length > 2097152 || (bytes[0] & 255) !== 255 ||
        (bytes[1] & 255) !== 216 || (bytes[bytes.length - 2] & 255) !== 255 ||
        (bytes[bytes.length - 1] & 255) !== 217) throw new Error('invalid');
    return Utilities.newBlob(bytes, 'image/jpeg', 'screenshot-' + (i + 1) + '.jpg');
  });
  return {p, context, images, save: validateSave(p.save)};
}

function doPost(e) {
  let report;
  try { report = validateReport(e && e.postData && e.postData.contents); }
  catch (_) { return response({ok: false, code: 'invalid'}); }
  const lock = LockService.getScriptLock();
  if (!lock.tryLock(5000)) return response({ok: false, code: 'busy'});
  try {
    const {p, context, images, save} = report;
    const properties = PropertiesService.getScriptProperties();
    const now = Date.now();
    const hash = Utilities.base64Encode(Utilities.computeDigest(Utilities.DigestAlgorithm.SHA_256,
      JSON.stringify({kind:p.kind, title:p.title, description:p.description, context, logs:p.logs, images:p.images})));
    const receiptKey = 'receipt_' + p.id;
    const receipt = JSON.parse(properties.getProperty(receiptKey) || 'null');
    if (receipt) return response(receipt.hash === hash ? {ok: true, id: p.id} : {ok: false, code: 'invalid'});
    let usage = JSON.parse(properties.getProperty('usage') || 'null');
    if (!usage || now - usage.start >= DAY) usage = {start: now, count: 0, last: 0};
    if (usage.count >= MAX_REPORTS_PER_DAY || MailApp.getRemainingDailyQuota() < 1) return response({ok: false, code: 'limited'});
    if (now - usage.last < 10000) return response({ok: false, code: 'busy'});
    // Reserve quota before sending, even if Google rejects the attempt.
    usage.count++; usage.last = now;
    properties.setProperty('usage', JSON.stringify(usage));
    const kind = p.kind === 'bug' ? 'Bug反馈' : '修改建议';
    const body = [kind + '：' + p.title, '', p.description, '', '反馈编号：' + p.id,
      '游戏版本：' + context.version, '平台：' + context.platform, '场景：' + context.scene,
      '阶段：' + context.phase, '层数：' + context.floor, '回合：' + context.round, '种子：' + context.seed,
      '', p.logs ? '玩家勾选附带的行动日志：\n' + p.logs : '玩家未附带行动日志。',
      save ? '附带当前进度存档：' + p.save.name : '未附带进度存档。'].join('\n');
    MailApp.sendEmail({to: FEEDBACK_RECIPIENT, subject: '[紧缚尖塔][' + kind + '] ' + p.title,
      body, attachments: save ? images.concat(save) : images, name: '紧缚尖塔 · 游戏反馈'});
    properties.setProperty(receiptKey, JSON.stringify({hash, time: now}));
    // Receipts prevent duplicate mail on explicit retries for the following 48 hours.
    const all = properties.getProperties();
    for (const key of Object.keys(all)) {
      if (key.startsWith('receipt_') && now - JSON.parse(all[key]).time > 2 * DAY) properties.deleteProperty(key);
    }
    return response({ok: true, id: p.id});
  } catch (_) {
    // Do not return credentials, account diagnostics or submitted contents.
    return response({ok: false, code: 'unavailable'});
  } finally { lock.releaseLock(); }
}

function doGet(e) {
  const id = e && e.parameter && e.parameter.receipt;
  if (id !== undefined) {
    if (!/^[a-f0-9]{32}$/.test(id)) return response({ok: false, code: 'invalid'});
    const receipt = PropertiesService.getScriptProperties().getProperty('receipt_' + id);
    return response(receipt ? {ok: true, id} : {ok: false, code: 'not_found'});
  }
  return response({service: 'spire-feedback', schema: SCHEMA_VERSION});
}
