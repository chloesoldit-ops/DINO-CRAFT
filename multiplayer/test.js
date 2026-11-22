'use strict';
/* Smoke test: start an ephemeral server and connect two real WebSocket clients. */
const assert=require('node:assert/strict');
const {spawn}=require('node:child_process');
const WebSocket=require('ws');
const PORT=34000+Math.floor(Math.random()*1500);
const server=spawn(process.execPath,['server.js'],{
 cwd:__dirname,env:{...process.env,PORT:String(PORT),ALLOWED_ORIGINS:''},stdio:['ignore','pipe','pipe']
});
let stderr='';server.stderr.on('data',data=>stderr+=data);
const clients=[];
function wait(ws,predicate,timeout=5000){
 return new Promise((resolve,reject)=>{
  const timer=setTimeout(()=>{ws.off('message',handler);reject(new Error('Timed out waiting for server message'));},timeout);
  function handler(bytes){
   let m;try{m=JSON.parse(String(bytes));}catch{return;}
   if(!predicate(m))return;
   clearTimeout(timer);ws.off('message',handler);resolve(m);
  }
  ws.on('message',handler);
 });
}
function open(){
 return new Promise((resolve,reject)=>{
  const ws=new WebSocket('ws://127.0.0.1:'+PORT+'/ws');
  clients.push(ws);
  ws.once('open',()=>resolve(ws));ws.once('error',reject);
 });
}
function send(ws,m){ws.send(JSON.stringify(m));}
function compressedEmptyWorld(){
 const chunks=[];let left=80*128*80;
 while(left>0){const n=Math.min(left,65535);chunks.push(n>>8,n&255,0);left-=n;}
 return Buffer.from(chunks).toString('base64');
}
async function run(){
 await new Promise((resolve,reject)=>{
  const timer=setTimeout(()=>reject(new Error('Server did not start: '+stderr)),5000);
  server.stdout.on('data',data=>{if(String(data).includes('server on port')){clearTimeout(timer);resolve();}});
  server.on('error',reject);
 });
 const a=await open(), b=await open();
 let reply=wait(a,m=>m.t==='joined');
 send(a,{t:'create',mode:'survival',name:'ExplorerA'});
 const created=await reply;
 assert.equal(created.code.length,8);assert.equal(created.mode,'survival');
 reply=wait(a,m=>m.t==='world_ok');
 send(a,{t:'world',data:compressedEmptyWorld()});
 await reply;
 reply=wait(b,m=>m.t==='joined');
 const appeared=wait(a,m=>m.t==='peer');
 send(b,{t:'join',code:created.code,mode:'survival',name:'ExplorerB'});
 const joined=await reply;await appeared;
 assert.equal(joined.code,created.code);
 assert.equal(typeof joined.world,'string');
 reply=wait(a,m=>m.t==='state');
 send(b,{t:'state',x:40,y:23,z:42,yaw:1});
 await reply;
 reply=wait(b,m=>m.t==='block');
 send(a,{t:'state',x:40,y:22,z:40,yaw:0});
 await new Promise(r=>setTimeout(r,90));
 send(a,{t:'block',x:41,y:22,z:40,type:1});
 const block=await reply;assert.equal(block.type,1);
 reply=wait(b,m=>m.t==='mobs');
 send(a,{t:'mobs',mobs:[{id:'m1',type:'raptor',x:40,y:23,z:41,hp:20,maxHp:20}]});
 await reply;
 reply=wait(a,m=>m.t==='mob_hit');
 send(b,{t:'mob_hit',id:'m1'});
 assert.equal((await reply).damage,6);
 a.close();b.close();
 console.log('PASS create/join, world sync, movement, blocks, co-op monsters and hit relay');
}
run().catch(err=>{console.error(err);process.exitCode=1;}).finally(()=>{
 for(const ws of clients)try{ws.terminate();}catch{}
 server.kill();
});
