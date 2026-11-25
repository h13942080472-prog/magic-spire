// Offline contract tests: never contact Google and never send real email.
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const properties = {};
const sent = [];
let remaining = 100, available = true, throwSend = false;
const sandbox = {
  ContentService: {MimeType: {JSON:'json'}, createTextOutput: text => ({text, setMimeType(){return this;}})},
  LockService: {getScriptLock: () => ({tryLock:()=>available, releaseLock(){}})},
  PropertiesService: {getScriptProperties: () => ({getProperty:k=>properties[k],setProperty:(k,v)=>properties[k]=v,
    getProperties:()=>({...properties}),deleteProperty:k=>delete properties[k]})},
  MailApp: {getRemainingDailyQuota:()=>remaining, sendEmail: mail=>{if(throwSend)throw Error('private diagnostic');sent.push(mail);}},
  Utilities: {DigestAlgorithm:{SHA_256:'sha256'},computeDigest:(alg,s)=>crypto.createHash(alg).update(s).digest(),
    base64Encode:b=>Buffer.from(b).toString('base64'),base64Decode:s=>Array.from(Buffer.from(s,'base64')),
    newBlob:(bytes,mime,name)=>({bytes,mime,name,getDataAsString:()=>Buffer.from(bytes).toString('utf8')})}
};
vm.createContext(sandbox); vm.runInContext(fs.readFileSync(__dirname+'/Code.gs','utf8'),sandbox);
const valid = () => ({schema:1,id:crypto.randomBytes(16).toString('hex'),kind:'bug',title:'测试',description:'复现步骤',
  context:{version:'0.15',platform:'Windows',phase:'战斗',scene:'练习',floor:1,round:2,seed:42},logs:'',images:[]});
const post = p => JSON.parse(sandbox.doPost({postData:{contents:typeof p==='string'?p:JSON.stringify(p)}}).text);
let p = valid();p.images=[{data:Buffer.from([255,216,255,217]).toString('base64')}];p.to='other@example.com';
assert.equal(post(p).ok,true);assert.equal(sent.length,1);assert.equal(sent[0].to,'towerlover7787@gmail.com');
assert.equal(sent[0].attachments[0].mime,'image/jpeg');assert.equal(sent[0].attachments[0].name,'screenshot-1.jpg');
assert.equal(post(p).ok,true);assert.equal(sent.length,1);
p.title='改变原编号内容';assert.equal(post(p).code,'invalid');
assert.equal(post(valid()).code,'busy');
const invalids=[{title:'x'.repeat(201)},{description:'x'.repeat(8001)},{logs:'x'.repeat(40001)},
  {images:[{data:Buffer.alloc(2097153).toString('base64')}]}];
for(const change of invalids) assert.equal(post({...valid(),...change}).code,'invalid');
assert.equal(post('{bad').code,'invalid');available=false;assert.equal(post(valid()).code,'busy');available=true;
remaining=0;assert.equal(post(valid()).code,'limited');remaining=100;
properties.usage=JSON.stringify({start:Date.now(),last:0,count:80});assert.equal(post(valid()).code,'limited');
delete properties.usage;throwSend=true;assert.equal(post(valid()).code,'unavailable');assert.equal(sent.length,1);
throwSend=false;delete properties.usage;p=valid();p.kind='suggestion';p.logs='玩家确认的日志';
assert.equal(post(p).ok,true);assert.match(sent[1].subject,/修改建议/);assert.match(sent[1].body,/玩家确认的日志/);
assert.equal(JSON.parse(sandbox.doGet().text).schema,2);
assert.equal(JSON.parse(sandbox.doGet({parameter:{receipt:p.id}}).text).id,p.id);
assert.equal(JSON.parse(sandbox.doGet({parameter:{receipt:'invalid'}}).text).code,'not_found');
assert.equal(JSON.parse(sandbox.doGet({parameter:{receipt:'0'.repeat(32)}}).text).code,'not_found');

// docs/spec/feedback-deployment.md「存档附件」: the optional save travels as one application/json
// attachment whose bytes equal the submitted text, the receipt hash ignores it, and a save-less
// report keeps the previous behavior. The GET schema declares the capability.
const envelope = format => JSON.stringify({format,saved_at:'2026-09-19 00:00:00',payload:'{}',map_drawings:'',checksum:'x'});
const base64 = text => Buffer.from(text,'utf8').toString('base64');
const attach = (text,name='tower.json') => ({...valid(),save:{name,data:base64(text)}});
const textOf = blob => Buffer.from(blob.bytes).toString('utf8');
const last = () => sent[sent.length-1];
const sentBefore = sent.length;
delete properties.usage;
p = attach(envelope(2));
assert.equal(post(p).ok,true);
assert.equal(sent.length,sentBefore+1);
assert.equal(last().attachments.length,1);
assert.equal(last().attachments[0].mime,'application/json');
assert.equal(last().attachments[0].name,'progress-save.json');
assert.equal(textOf(last().attachments[0]),envelope(2));
assert.match(last().body,/附带当前进度存档：progress-save\.json/);
assert.equal(post(p).ok,true);assert.equal(sent.length,sentBefore+1);
assert.equal(post({...p,save:{name:'tower.json',data:base64(envelope(2).replace('00:00:00','01:02:03'))}}).ok,true);
assert.equal(sent.length,sentBefore+1,'the receipt ignores a changed save');
assert.equal(post({...p,title:'改变原编号内容'}).code,'invalid');
delete properties.usage;
p = valid();p.images=[{data:Buffer.from([255,216,255,217]).toString('base64')}];
assert.equal(post(p).ok,true);
assert.equal(sent.length,sentBefore+2);
assert.equal(last().attachments.length,1);
assert.match(last().body,/未附带进度存档。/);
delete properties.usage;
p = attach(envelope(2),'practice.json');p.images=[{data:Buffer.from([255,216,255,217]).toString('base64')}];
assert.equal(post(p).ok,true);
assert.equal(sent.length,sentBefore+3);
assert.equal(last().attachments.map(a=>a.mime).join(','),'image/jpeg,application/json');
assert.equal(last().attachments[1].name,'progress-save.json');
const rejected=[
  ['save is not an object','tower.json'],
  ['save data is not base64',{name:'tower.json',data:'hello'}],
  ['save payload is not JSON',{name:'tower.json',data:base64('存档损坏')}],
  ['save envelope is not an object',{name:'tower.json',data:base64('42')}],
  ['save decodes past two mebibytes',{name:'tower.json',data:Buffer.alloc(2097153,32).toString('base64')}],
  ['save base64 is longer than the attachment cap',{name:'tower.json',data:'A'.repeat(2796205)}],
];
for(const [label,save] of rejected){
  delete properties.usage;
  const before=sent.length;
  assert.equal(post({...valid(),save}).ok,true,label);
  assert.equal(sent.length,before+1,'a dropped save preserves the report: '+label);
  assert.equal(last().attachments.length,0,label);
  assert.match(last().body,/已丢弃/,label);
}
const beforeOversize=sent.length;
assert.equal(post('x'.repeat(12*1024*1024+1)).code,'invalid');
assert.equal(sent.length,beforeOversize);
delete properties.usage;
assert.equal(post(valid()).ok,true,'the service still accepts the old format after a rejected attachment');
// The supplied service accepts content loosely; names and recipients remain server-owned.
for(const change of [{title:''},{description:''},{title:'x\nBcc:evil'},{kind:'mail'},{id:'bad'},
  {images:Array(4).fill({data:base64('image')})},{context:{}},{logs:22},
  {title:'x'.repeat(200),description:'x'.repeat(8000),logs:'x'.repeat(40000)}]) {
  delete properties.usage;
  assert.equal(post({...valid(),...change}).ok,true);
  assert.doesNotMatch(last().subject,/[\r\n]/);
  assert.equal(last().to,'towerlover7787@gmail.com');
  assert.ok(last().attachments.length<=3);
}
for(const save of [{name:'../run.exe',data:base64(envelope(3)),extra:true},
  {data:base64('{}')},{data:base64(' '.repeat(2097150)+'{}')}]) {
  delete properties.usage;
  assert.equal(post({...valid(),save}).ok,true);
  assert.equal(last().attachments[0].name,'progress-save.json');
  assert.equal(last().attachments[0].mime,'application/json');
  assert.equal(textOf(last().attachments[0]),Buffer.from(save.data,'base64').toString('utf8'));
}
for(const payload of ['null','[]','42']) assert.equal(post(payload).code,'invalid');
delete properties.usage;
p=valid();p.images=Array(4).fill({data:base64('image')});
assert.equal(post(p).ok,true);assert.equal(last().attachments.length,3);
delete properties.usage;
p=valid();p.images=[{data:''},{data:base64('image')}];
assert.equal(post(p).ok,true);assert.equal(last().attachments.length,1);
assert.equal(last().attachments[0].name,'screenshot-1.jpg');
// Exercise the decoder exception branch without pretending Node's permissive decoder is Apps Script.
const originalDecode=sandbox.Utilities.base64Decode;
sandbox.Utilities.base64Decode=()=>{throw Error('decode failed');};
delete properties.usage;
assert.equal(post({...valid(),images:[{data:'bad'}],save:{data:'bad'}}).ok,true);
assert.equal(last().attachments.length,0);assert.match(last().body,/已丢弃/);
sandbox.Utilities.base64Decode=originalDecode;
delete properties.usage;
p=valid();delete p.id;
assert.equal(post(p).ok,true);
assert.equal(properties.receipt_,undefined,'an absent id never creates a shared receipt');
delete properties.usage;
const beforeRetry=sent.length;
assert.equal(post(p).ok,true);assert.equal(sent.length,beforeRetry+1);
delete properties.usage;
p=valid();p.id='r'.repeat(80);
assert.equal(post(p).id,'r'.repeat(64));
assert.ok(properties['receipt_'+'r'.repeat(64)]);
assert.equal(JSON.parse(sandbox.doGet({parameter:{receipt:p.id}}).text).ok,true);
console.log('Feedback service contract tests passed; no email sent.');
