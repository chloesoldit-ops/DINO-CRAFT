'use strict';
/* DinoCraft 4.7 optional WebSocket room server.
   Rooms are ephemeral and private by invite code; not an authenticated service. */
const http = require('node:http');
const crypto = require('node:crypto');
const WebSocket = require('ws');
const PORT = Number(process.env.PORT || 3000);
const LIMIT = 8, WORLD_X = 80, WORLD_Y = 128, WORLD_Z = 80, WORLD_BYTES = WORLD_X*WORLD_Y*WORLD_Z;
const rooms = new Map();
const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const hostileTypes=new Set(['zombie','skeleton','spider','raptor','triceratops','rex','golem','dragon','sporeburst','voidmoth','blaze','piglin','end_guardian']);
function code() {
  let k;
  do { k = Array.from(crypto.randomBytes(8),b=>alphabet[b%alphabet.length]).join(''); } while(rooms.has(k));
  return k;
}
function safeName(v) { return String(v||'Explorer').replace(/[^a-zA-Z0-9 _-]/g,'').trim().slice(0,18)||'Explorer'; }
function send(ws,msg) { if(ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(msg)); }
function broadcast(room,msg,except) { for(const p of room.players.values()) if(p.ws!==except)send(p.ws,msg); }
function info(p) { return {id:p.id,name:p.name,x:p.x,y:p.y,z:p.z,yaw:p.yaw,hp:p.hp}; }
function fail(ws,message) {send(ws,{t:'error',message});}
function rleDecode(data) {
  if(typeof data!=='string'||data.length>2400000||!/^[A-Za-z0-9+/]*={0,2}$/.test(data))return null;
  const bytes=Buffer.from(data,'base64');
  if(bytes.length===0||bytes.length%3!==0)return null;
  const out=Buffer.alloc(WORLD_BYTES);
  let offset=0;
  for(let i=0;i<bytes.length;i+=3){
    const n=(bytes[i]<<8)|bytes[i+1];
    if(!n||offset+n>WORLD_BYTES)return null;
    out.fill(bytes[i+2],offset,offset+n);
    offset+=n;
  }
  return offset===WORLD_BYTES?out:null;
}
function rleEncode(world) {
  const triples=[];
  for(let i=0;i<world.length;){
    const v=world[i];let n=1;
    while(n<65535&&i+n<world.length&&world[i+n]===v)n++;
    triples.push((n>>8)&255,n&255,v);i+=n;
  }
  return Buffer.from(triples).toString('base64');
}
function join(ws,req) {
  if(ws.player)return fail(ws,'Already in a room.');
  const mode=req.mode;
  if(!['survival','pvp'].includes(mode))return fail(ws,'Choose Survival or PvP before joining.');
  let room;
  if(req.t==='create'){
    const k=code();
    room={code:k,mode,players:new Map(),world:null,mobs:new Map(),lastMobs:0,created:Date.now()};
    rooms.set(k,room);
  } else {
    const k=String(req.code||'').trim().toUpperCase();
    room=rooms.get(k);
    if(!room)return fail(ws,'Room not found. Ask your friend for the current code.');
    if(room.mode!==mode)return fail(ws,'This room uses '+room.mode+'. Switch worlds first.');
  }
  if(room.players.size>=LIMIT)return fail(ws,'Room is full (8 players).');
  const id=crypto.randomUUID().slice(0,8);
  const p={id,ws,room,name:safeName(req.name),x:40,y:23,z:40,yaw:0,hp:20,lastMove:0,lastAttack:0,lastMobAttack:0,nextMobHit:0,mobCharge:null};
  const others=Array.from(room.players.values(),info);
  room.players.set(id,p);ws.player=p;
  send(ws,{t:'joined',code:room.code,id,mode:room.mode,players:others,world:room.world?rleEncode(room.world):null});
  broadcast(room,{t:'peer',player:info(p)},ws);
}
const server=http.createServer((req,res)=>{
  res.writeHead(200,{'content-type':'application/json','cache-control':'no-store'});
  res.end(JSON.stringify({name:'DinoCraft multiplayer',version:'4.7',status:'ok',rooms:rooms.size}));
});
const wss=new WebSocket.Server({server,path:'/ws',maxPayload:2600000,perMessageDeflate:false});
wss.on('connection',(ws,req)=>{
  const origin=req.headers.origin||'';
  const allowed=String(process.env.ALLOWED_ORIGINS||'').split(',').map(x=>x.trim()).filter(Boolean);
  if(allowed.length && !allowed.includes(origin)){ws.close(1008,'Origin not allowed');return;}
  let count=0,second=Date.now();ws.isAlive=true;
  ws.on('pong',()=>{ws.isAlive=true;});
  ws.on('message',(raw)=>{
    if(Date.now()-second>1000){second=Date.now();count=0;}
    if(++count>40){ws.close(1008,'Message rate exceeded');return;}
    let m;try{m=JSON.parse(raw.toString());}catch{return;}
    if(!m||typeof m!=='object'||typeof m.t!=='string')return;
    if(!ws.player){if(m.t==='create'||m.t==='join')join(ws,m);else fail(ws,'Join a room first.');return;}
    const p=ws.player,room=p.room,now=Date.now();
    if(m.t==='ping'){
      if(Number.isInteger(m.n) && m.n>=0 && m.n<=2147483647)
        send(ws,{t:'pong',n:m.n,players:room.players.size});
    } else if(m.t==='world'){
      if(room.world)return;
      // Only room creator (first remaining player) can initialize its shared terrain.
      if(Array.from(room.players.keys())[0]!==p.id)return;
      const decoded=rleDecode(m.data);
      if(!decoded)return fail(ws,'Invalid world snapshot.');
      room.world=decoded;
      broadcast(room,{t:'world',world:m.data},ws);
      send(ws,{t:'world_ok'});
    } else if(m.t==='state'){
      if(now-p.lastMove<65)return;
      const a=[m.x,m.y,m.z,m.yaw];
      if(a.some(x=>typeof x!=='number'||!Number.isFinite(x)))return;
      if(m.x<0||m.x>WORLD_X||m.z<0||m.z>WORLD_Z||m.y< -25||m.y>WORLD_Y+60)return;
      p.x=m.x;p.y=m.y;p.z=m.z;p.yaw=m.yaw;p.lastMove=now;
      broadcast(room,{t:'state',player:info(p)},ws);
    } else if(m.t==='block'){
      if(!room.world)return;
      const {x,y,z,type}=m;
      if(![x,y,z,type].every(Number.isInteger))return;
      if(x<0||x>=WORLD_X||y<0||y>=WORLD_Y||z<0||z>=WORLD_Z||type<0||type>255)return;
      if(Math.hypot(x+.5-p.x,y-p.y,z+.5-p.z)>7.8)return;
      const idx=y*WORLD_X*WORLD_Z+z*WORLD_X+x;
      if(room.world[idx]===type)return;
      room.world[idx]=type;
      broadcast(room,{t:'block',x,y,z,type},ws);
    } else if(m.t==='mobs'){
      // Only the first connected room member simulates the shared creatures.
      if(!room.world||Array.from(room.players.keys())[0]!==p.id||now-room.lastMobs<180)return;
      if(!Array.isArray(m.mobs)||m.mobs.length>48)return;
      const clean=[],snapshot=new Map();
      for(const item of m.mobs){
        if(!item||typeof item.id!=='string'||!/^[a-zA-Z0-9_-]{1,18}$/.test(item.id))continue;
        if(typeof item.type!=='string'||!/^[a-z_]{1,18}$/.test(item.type))continue;
        if(![item.x,item.y,item.z,item.hp,item.maxHp].every(x=>typeof x==='number'&&Number.isFinite(x)))continue;
        if(item.x<0||item.x>WORLD_X||item.z<0||item.z>WORLD_Z||item.y< -25||item.y>WORLD_Y+40)continue;
        if(item.maxHp<=0||item.maxHp>50000||item.hp<0||item.hp>item.maxHp)continue;
        const v={id:item.id,type:item.type,x:item.x,y:item.y,z:item.z,hp:item.hp,maxHp:item.maxHp};
        clean.push(v);snapshot.set(v.id,v);
      }
      room.mobs=snapshot;room.lastMobs=now;
      broadcast(room,{t:'mobs',mobs:clean},ws);
      // Server-checked attack telegraphs for visiting co-op players.
      for(const guest of room.players.values()){
        if(guest.id===p.id||now<guest.nextMobHit)continue;
        const nearby=clean.find(m=>hostileTypes.has(m.type)&&Math.hypot(m.x-guest.x,m.y-guest.y,m.z-guest.z)<(['rex','dragon','golem','triceratops'].includes(m.type)?3.5:2.4));
        if(!nearby){guest.mobCharge=null;continue;}
        if(!guest.mobCharge || guest.mobCharge.id!==nearby.id){
          guest.mobCharge={id:nearby.id,due:now+520};
          send(guest.ws,{t:'mob_warning',name:nearby.type});continue;
        }
        if(now>=guest.mobCharge.due){
          const damage=['rex','dragon','golem'].includes(nearby.type)?8:['triceratops','blaze'].includes(nearby.type)?5:3;
          send(guest.ws,{t:'mob_attack',name:nearby.type,damage});
          guest.nextMobHit=now+1200;guest.mobCharge=null;
        }
      }
    } else if(m.t==='mob_hit'){
      if(!room.world||now-p.lastMobAttack<350)return;
      const mob=room.mobs.get(String(m.id||''));
      if(!mob||Math.hypot(mob.x-p.x,mob.y-p.y,mob.z-p.z)>7)return;
      const host=room.players.values().next().value;
      if(!host||host.id===p.id)return;
      p.lastMobAttack=now;
      send(host.ws,{t:'mob_hit',id:mob.id,damage:6,from:p.name});
      send(ws,{t:'mob_hit_ok',name:mob.type});
    } else if(m.t==='hit'){
      if(room.mode!=='pvp'||now-p.lastAttack<380)return;
      const victim=room.players.get(String(m.id||''));
      if(!victim||victim.id===p.id)return;
      const dist=Math.hypot(p.x-victim.x,p.y-victim.y,p.z-victim.z);
      if(dist>5.2)return;
      p.lastAttack=now;
      send(victim.ws,{t:'hit',from:p.name,damage:5});
      send(ws,{t:'hit_ok',name:victim.name});
    }
  });
  ws.on('close',()=>{
    const p=ws.player;if(!p)return;
    const wasHost=Array.from(p.room.players.keys())[0]===p.id;
    p.room.players.delete(p.id);
    if(wasHost){p.room.mobs.clear();p.room.lastMobs=0;}
    broadcast(p.room,{t:'left',id:p.id});
    if(wasHost&&p.room.players.size){const successor=p.room.players.values().next().value;send(successor.ws,{t:'host'});}
    if(!p.room.players.size)rooms.delete(p.room.code);
  });
  ws.on('error',()=>{});
});
const heart=setInterval(()=>{
 for(const ws of wss.clients){if(!ws.isAlive){ws.terminate();continue;}ws.isAlive=false;ws.ping();}
},30000);
wss.on('close',()=>clearInterval(heart));
server.listen(PORT,'0.0.0.0',()=>console.log('DinoCraft 4.7 server on port '+PORT));
