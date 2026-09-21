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
const invalids=[{title:''},{description:''},{title:'x\nBcc:evil'},{kind:'mail'},{id:'bad'},{images:[{data:'hello'}]},
  {images:Array(4).fill({data:''})},{context:{}},{description:'x'.repeat(4001)},{logs:22}];
for(const change of invalids) assert.equal(post({...valid(),...change}).code,'invalid');
assert.equal(post('{bad').code,'invalid');available=false;assert.equal(post(valid()).code,'busy');available=true;
remaining=0;assert.equal(post(valid()).code,'limited');remaining=100;
properties.usage=JSON.stringify({start:Date.now(),last:0,count:80});assert.equal(post(valid()).code,'limited');
delete properties.usage;throwSend=true;assert.equal(post(valid()).code,'unavailable');assert.equal(sent.length,1);
throwSend=false;delete properties.usage;p=valid();p.kind='suggestion';p.logs='玩家确认的日志';
assert.equal(post(p).ok,true);assert.match(sent[1].subject,/修改建议/);assert.match(sent[1].body,/玩家确认的日志/);
assert.equal(JSON.parse(sandbox.doGet().text).schema,2);
assert.equal(JSON.parse(sandbox.doGet({parameter:{receipt:p.id}}).text).id,p.id);
assert.equal(JSON.parse(sandbox.doGet({parameter:{receipt:'invalid'}}).text).code,'invalid');
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
assert.equal(last().attachments[0].name,'tower.json');
assert.equal(textOf(last().attachments[0]),envelope(2));
assert.match(last().body,/附带当前进度存档：tower\.json/);
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
assert.equal(last().attachments[1].name,'practice.json');
const rejected=[
  ['save is not an object','tower.json'],
  ['save carries an extra key',{name:'tower.json',data:base64(envelope(2)),format:2}],
  ['save name escapes the folder',{name:'../tower.json',data:base64(envelope(2))}],
  ['save name is not a fixed point name',{name:'tower.txt',data:base64(envelope(2))}],
  ['save data is not base64',{name:'tower.json',data:'hello'}],
  ['save payload is not JSON',{name:'tower.json',data:base64('存档损坏')}],
  ['save envelope is another game format',{name:'tower.json',data:base64(envelope(3))}],
  ['save envelope is not an object',{name:'tower.json',data:base64('42')}],
  ['save decodes past two mebibytes',{name:'tower.json',data:Buffer.alloc(2097153,32).toString('base64')}],
  ['save base64 is longer than the attachment cap',{name:'tower.json',data:'A'.repeat(2796205)}],
];
for(const [label,save] of rejected){
  assert.equal(post({...valid(),save}).code,'invalid',label);
  assert.equal(sent.length,sentBefore+3,'a rejected attachment never sends mail: '+label);
}
assert.equal(post('x'.repeat(12*1024*1024+1)).code,'invalid');
assert.equal(sent.length,sentBefore+3);
delete properties.usage;
assert.equal(post(valid()).ok,true,'the service still accepts the old format after a rejected attachment');
console.log('Feedback service contract tests passed; no email sent.');
