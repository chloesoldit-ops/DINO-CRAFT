'use strict';
/* Run from repo root after: npm install --no-save playwright && npx playwright install chromium
   A browser smoke test, not a claim of complete gameplay coverage. */
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const http=require('node:http');
const {chromium}=require('playwright');
const ROOT=path.resolve(__dirname,'..');
const MIMES={'.html':'text/html; charset=utf-8','.js':'application/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.png':'image/png','.webp':'image/webp','.jpg':'image/jpeg','.json':'application/json'};
const server=http.createServer((req,res)=>{
 const url=new URL(req.url,'http://localhost');
 const requested=decodeURIComponent(url.pathname);
 const pathname=path.resolve(ROOT,'.'+(requested==='/'?'/index.html':requested));
 if(!pathname.startsWith(ROOT+path.sep)){res.writeHead(403);res.end('Forbidden');return;}
 fs.readFile(pathname,(err,data)=>{
  if(err){res.writeHead(404);res.end('Not found');return;}
  res.writeHead(200,{'content-type':MIMES[path.extname(pathname)]||'application/octet-stream'});
  res.end(data);
 });
});
(async()=>{
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 const browser=await chromium.launch({headless:true,args:['--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--disable-web-security']});
 try{
  const page=await browser.newPage({viewport:{width:1280,height:800}});
  const errors=[];
  page.on('pageerror',err=>errors.push(err.message));
  const address='http://127.0.0.1:'+server.address().port+'/';
  await page.goto(address,{waitUntil:'domcontentloaded'});
  await page.waitForTimeout(1500);
  assert.equal(await page.title(),'DinoCraft 4.8 — Classic Multiplayer');
  assert.equal(await page.locator('#title').isVisible(),true,'Title must be visible');
  assert.equal(await page.locator('#dcMpTitle').isVisible(),true,'Title multiplayer button is missing');
  await page.locator('#dcMpTitle').click();
  assert.equal(await page.locator('#dcMpPanel').isVisible(),true,'Multiplayer panel did not open from the title');
  assert.equal(await page.locator('#title').isVisible(),true,'Clicking Multiplayer must not start the game');
  await page.locator('#dcMpClose').click();
  assert.equal(await page.locator('#dcMpPanel').isVisible(),false,'Multiplayer panel did not close');
  assert.equal(await page.locator('#dcMpWorld').count(),1);
  assert.equal(await page.locator('#dcMpPause').count(),1);
  assert.equal(await page.locator('#dcMuteButton').count(),1);
  const fatal=errors.filter(x=>/ReferenceError|SyntaxError|TypeError/.test(x));
  assert.deepEqual(fatal,[],'Uncaught browser errors: '+fatal.join('; '));
  console.log('PASS: Classic 4.8 loads, multiplayer title button opens and closes, no fatal JS errors');
 }finally{await browser.close();}
})().catch(err=>{console.error(err);process.exitCode=1;}).finally(()=>server.close());
