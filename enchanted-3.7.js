/* DinoCraft 3.7 enchanted landscape — independent optional visual layer */
(()=>{'use strict';if(window.Dino37)return;window.Dino37=true;
const T=window.THREE;if(!T)return;
const saved=(()=>{try{return JSON.parse(localStorage.getItem('dino37art')||'{}')}catch(_){return {}}})();
const options=Object.assign({enabled:true,detail:'medium'},saved);
const style=document.createElement('style');style.textContent=`
#d37art{position:fixed;right:12px;bottom:114px;z-index:36;border:1px solid #b3ffd9;background:linear-gradient(120deg,#165c5b,#35518b);color:white;border-radius:14px;font:700 12px system-ui;padding:10px;cursor:pointer}
#d37settings{display:none;position:fixed;right:12px;bottom:165px;z-index:120;background:#102a3ef5;color:white;border:1px solid #98e9ce;border-radius:18px;padding:15px;font:14px system-ui;max-width:260px;box-shadow:0 10px 40px #0009}
#d37settings label{display:block;margin:10px 0}#d37settings button,#d37settings select{padding:8px;background:#24717b;color:white;border:1px solid #94eeca;border-radius:9px}
`;document.head.append(style);
const btn=document.createElement('button');btn.id='d37art';btn.textContent='🌸 Pretty Land';document.body.append(btn);
const panel=document.createElement('div');panel.id='d37settings';panel.innerHTML='<strong>🌈 DinoCraft 3.7 Scenery</strong><label><input type="checkbox" id="d37enable"> Extra colorful land</label><label>Details <select id="d37quality"><option value="low">Low</option><option value="medium">Medium</option><option value="high">High</option></select></label><button id="d37close">Done</button>';document.body.append(panel);
const en=panel.querySelector('#d37enable'),quality=panel.querySelector('#d37quality');en.checked=options.enabled;quality.value=options.detail;
const persist=()=>{try{localStorage.setItem('dino37art',JSON.stringify(options))}catch(_){}};const apply=()=>{options.enabled=en.checked;options.detail=quality.value;persist();cell='';clear()};en.onchange=apply;quality.onchange=apply;btn.onclick=()=>panel.style.display=panel.style.display==='block'?'none':'block';panel.querySelector('#d37close').onclick=()=>panel.style.display='none';
const m={};function material(color,glow=false){let id=color+'-'+glow;if(!m[id])m[id]=new T.MeshLambertMaterial({color,emissive:glow?color:0,emissiveIntensity:glow?.25:0});return m[id]}
const geo={box:new T.BoxGeometry(1,1,1),ball:new T.IcosahedronGeometry(1,1),cone:new T.ConeGeometry(1,1,6),pole:new T.CylinderGeometry(1,1,1,8),gem:new T.OctahedronGeometry(1,0)};
const C={wood:material(0x806348),leaf:[0x48b978,0x65cf8e,0x87dc79,0x41af9c,0xa3df93].map(x=>material(x)),rock:material(0x95b7b0),moss:material(0x79bd83),grass:material(0x57b97a),pink:material(0xff9ecb),yellow:material(0xffd77b),blue:material(0x97d8ff),purple:material(0xc6adff),crystal:material(0x7fffe8,true),crystal2:material(0x9bbbff,true),water:material(0x7ecfe8)};
function mesh(g,shape,mat,x,y,z,sx=1,sy=1,sz=1){const o=new T.Mesh(shape,mat);o.position.set(x,y,z);o.scale.set(sx,sy,sz);g.add(o);return o}
function tree(n){const g=new T.Group(),h=3+(n%5)*.65;mesh(g,geo.pole,C.wood,0,h*.45,0,.28,h,.28);for(let i=0;i<4;i++){const a=i*2.4;mesh(g,n%3===0?geo.cone:geo.ball,C.leaf[(n+i)%5],Math.cos(a)*.65,h*.72+i*.23,Math.sin(a)*.65,1.3-i*.12,1.18,1.3-i*.12)}return g}
function flowers(n){const g=new T.Group(),cols=[C.pink,C.yellow,C.blue,C.purple];for(let i=0;i<9;i++){const x=Math.sin(i*3.7+n)*1.2,z=Math.cos(i*4.2+n)*1.2;mesh(g,geo.pole,C.grass,x,.2,z,.026,.38,.026);mesh(g,geo.ball,cols[(i+n)%4],x,.43,z,.12,.1,.12)}return g}
function fancyBlocks(n){const g=new T.Group();if(n%4===0){for(let k=0;k<4;k++)mesh(g,geo.box,k%2?C.moss:C.rock,(k%2)*.9,.25+Math.floor(k/2)*.1,Math.floor(k/2)*.9,.8,.48,.8)}
else if(n%4===1){mesh(g,geo.box,C.rock,0,.38,0,1.4,.74,1.4);for(let k=0;k<3;k++)mesh(g,geo.gem,k%2?C.crystal:C.crystal2,Math.cos(k*2.09)*.35,1.3+(.2*k),Math.sin(k*2.09)*.35,.3,.72,.3)}
else if(n%4===2){mesh(g,geo.box,C.wood,0,.85,0,.17,1.7,.17);mesh(g,geo.box,C.yellow,0,1.83,0,.43,.45,.43);mesh(g,geo.box,C.rock,0,.15,0,.8,.3,.8)}
else {mesh(g,geo.box,C.rock,0,.17,0,1.5,.34,1.5);const f=flowers(n);f.position.y=.2;g.add(f)}return g}
function shrine(n){const g=new T.Group();for(let j=0;j<5;j++){const a=j*2*Math.PI/5;mesh(g,geo.box,j%2?C.rock:C.moss,Math.cos(a)*1.75,.63,Math.sin(a)*1.75,.48,1.25,.48)}mesh(g,geo.box,C.rock,0,.22,0,2.5,.44,2.5);mesh(g,geo.gem,C.crystal,0,1.4,0,.72,1.4,.72);return g}
function pond(n){const g=new T.Group();mesh(g,geo.pole,C.rock,0,.07,0,2.7,.14,2.7);mesh(g,geo.pole,C.water,0,.155,0,2.3,.04,2.3);for(let i=0;i<4;i++){const a=i*1.57+n*.2;mesh(g,geo.ball,C.moss,Math.cos(a)*1.1,.19,Math.sin(a)*1.1,.4,.045,.4)}return g}
function mush(n){const g=new T.Group();for(let i=0;i<5;i++){const x=Math.sin(i*2.2+n)*.9,z=Math.cos(i*2.2+n)*.9;mesh(g,geo.pole,C.rock,x,.3,z,.09,.6,.09);mesh(g,geo.ball,i%2?C.crystal:C.purple,x,.67,z,.28,.17,.28)}return g}
let scene=null,cam=null,objects=[],cell='',frame=0,building=false;const old=T.WebGLRenderer.prototype.render;
function clear(){for(const o of objects){o.parent?.remove(o)}objects=[]}
function ground(x,z){const r=new T.Raycaster(new T.Vector3(x,120,z),new T.Vector3(0,-1,0),0,230);const candidates=scene.children.filter(o=>o.visible&&!objects.includes(o)&&(o.isMesh||o.isGroup));const hits=r.intersectObjects(candidates,true);return hits.length?hits[0].point.y:null}
function put(obj,x,z){const y=ground(x,z);if(y===null||y<0||y>85)return;obj.position.set(x,y+.04,z);scene.add(obj);objects.push(obj)}
function rebuild(){if(!scene||!cam||building)return;building=true;try{clear();if(!options.enabled)return;const x=cam.position.x,z=cam.position.z,count=options.detail==='high'?70:options.detail==='medium'?42:24;for(let i=0;i<count;i++){const a=i*2.399963,rad=8+Math.sqrt((i+.5)/count)*47,px=x+Math.cos(a)*rad,pz=z+Math.sin(a)*rad;let obj;if(i%13===0)obj=shrine(i);else if(i%11===0)obj=pond(i);else if(i%7===0)obj=mush(i);else if(i%3===0)obj=fancyBlocks(i);else if(i%2===0)obj=flowers(i);else obj=tree(i);obj.rotation.y=(i*1.618)%6.28;put(obj,px,pz)}}finally{building=false}}
T.WebGLRenderer.prototype.render=function(s,c,...args){if(!scene&&s?.isScene&&c?.isCamera&&s.children.length>10){scene=s;cam=c}if(s===scene&&cam){cam=c;if(++frame%18===0){const k=Math.floor(c.position.x/30)+':'+Math.floor(c.position.z/30);if(k!==cell){cell=k;rebuild()}}}return old.call(this,s,c,...args)};
})();