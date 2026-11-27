--!strict
-- RAINBOW TROLL OBBY 0.8 — Betrayal Edition
-- Put this Script in ServerScriptService. No models or command setup required.
local Players=game:GetService("Players")
local MarketplaceService=game:GetService("MarketplaceService")
local DataStoreService=game:GetService("DataStoreService")
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

-- Optional, permanent cosmetic pass. Set to a real Game Pass ID after publishing.
local RAINBOW_TRAIL_PASS_ID=0
-- Replace 0 with IDs created in Roblox Creator Hub. All purchases are off until configured.
local GAME_PASSES={rainbow_trail=0,speed=0,gravity=0,double_coins=0,vip=0}
local PRODUCTS={skip_1=0,skip_3=0,coins_250=0,coins_1200=0,fireworks=0,chaos=0}
local passOwnership={}
local lastChaosTime=0
local freeBoostCooldown={}
local resetCooldown={}
local raceStarted={}
local raceEligible={}
local productIndex={}
for name,id in pairs(PRODUCTS) do
 if id>0 then productIndex[id]=name end
end
local STAGES=36
local STAGE_LENGTH=70
-- Unpublished Studio places may not have DataStore access.
-- Use a memory-only test store so the obby and HUD can still run before publishing.
local storeOkay,realStore=pcall(function()
 return DataStoreService:GetDataStore("RainbowRush_Progress_01")
end)
local temporaryRecords={}
local SAVE_STORE=if storeOkay then realStore else {
 GetAsync=function(_,key)
  return temporaryRecords[key]
 end,
 UpdateAsync=function(_,key,callback)
  local value=callback(temporaryRecords[key])
  if value~=nil then temporaryRecords[key]=value end
  return temporaryRecords[key]
 end
}
if not storeOkay then
 warn("Rainbow Rush: DataStore unavailable. Using temporary test progress; publish and enable Studio API access to test saving.")
end
-- Purchases are stored in the same player record as progression for atomic grants.
local checkpoints={}
local touchCooldown={}
local coins={}
local spinningCoins={}
local mapFolder=Instance.new("Folder")
mapFolder.Name="RainbowRushWorld"
mapFolder.Parent=workspace
local events=Instance.new("Folder")
events.Name="RainbowRushEvents"
events.Parent=ReplicatedStorage
local showMessage=Instance.new("RemoteEvent")
showMessage.Name="Message"
showMessage.Parent=events
local passInfo=Instance.new("RemoteFunction")
passInfo.Name="PassInfo"
passInfo.Parent=events
passInfo.OnServerInvoke=function()return GAME_PASSES.rainbow_trail end
local replayEvent=Instance.new("RemoteEvent")
replayEvent.Name="ReplayCourse";replayEvent.Parent=events
local boostEvent=Instance.new("RemoteEvent")
boostEvent.Name="PracticeBoost";boostEvent.Parent=events
local resetEvent=Instance.new("RemoteEvent")
resetEvent.Name="ResetCheckpoint";resetEvent.Parent=events
local shopCatalog=Instance.new("RemoteFunction")
shopCatalog.Name="ShopCatalog";shopCatalog.Parent=events
shopCatalog.OnServerInvoke=function() return {passes=GAME_PASSES,products=PRODUCTS} end

local palette={
 Color3.fromRGB(248,81,114),Color3.fromRGB(255,171,57),
 Color3.fromRGB(253,234,93),Color3.fromRGB(90,230,157),
 Color3.fromRGB(74,198,252),Color3.fromRGB(165,112,245)
}
local function block(name,size,cf,color,material,collide)
 local p=Instance.new("Part")
 p.Name=name;p.Size=size;p.CFrame=cf;p.Anchored=true
 p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
 p.CanCollide=(collide~=false);p.TopSurface=Enum.SurfaceType.Smooth
 p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=mapFolder
 return p
end
local function stagePos(stage)
 return Vector3.new(0,10,(stage-1)*STAGE_LENGTH)
end
local function message(player,text)
 showMessage:FireClient(player,text)
end
local function playerOf(part)
 local model=part and part:FindFirstAncestorOfClass("Model")
 local humanoid=model and model:FindFirstChildOfClass("Humanoid")
 local player=model and Players:GetPlayerFromCharacter(model)
 if not player or not humanoid or humanoid.Health<=0 then return nil end
 return player,humanoid
end
local function teleport(player,stage)
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if root and root:IsA("BasePart") then
  root.AssemblyLinearVelocity=Vector3.zero
  local target=stagePos(stage)+Vector3.new(0,6,stage==1 and -18 or 0)
  root.CFrame=CFrame.lookAt(target,target+Vector3.new(0,0,12))
 end
end
local function save(player)
 local stats=player:FindFirstChild("leaderstats")
 local stage=stats and stats:FindFirstChild("Stage")
 local points=stats and stats:FindFirstChild("Coins")
 local wins=stats and stats:FindFirstChild("Wins")
 if not (stage and points and wins) then return end
 local data={stage=stage.Value,coins=points.Value,wins=wins.Value,best=player:GetAttribute("BestTimeMs") or 0}
 pcall(function()SAVE_STORE:UpdateAsync(tostring(player.UserId),function(old)
  old=type(old)=="table" and old or {}
  local previousBest=tonumber(old.best) or 0
  local best=data.best
  if previousBest>0 and (best<=0 or previousBest<best) then best=previousBest end
  return {stage=data.stage,coins=data.coins,wins=math.max(old.wins or 0,data.wins),best=best,receipts=old.receipts or {}}
 end)end)
end
-- Replaying is free and never resets purchases, coins or wins.
replayEvent.OnServerEvent:Connect(function(player)
 local stats=player:FindFirstChild("leaderstats")
 local stage=stats and stats:FindFirstChild("Stage")
 if not stage then return end
 if stage.Value<=STAGES then
  message(player,"🏁 Finish all 36 stages to unlock replay!")
  return
 end
 stage.Value=1
 raceStarted[player]=workspace:GetServerTimeNow()
 raceEligible[player]=true
 player:SetAttribute("RunStartedAt",raceStarted[player])
 player:SetAttribute("LastTimeMs",0)
 teleport(player,1)
 task.spawn(save,player)
 message(player,"🌈 NEW RUN! Race the clock and beat your personal best!")
end)
resetEvent.OnServerEvent:Connect(function(player)
 if os.clock()-(resetCooldown[player] or -1000)<3 then return end
 resetCooldown[player]=os.clock()
 local stats=player:FindFirstChild("leaderstats")
 local stage=stats and stats:FindFirstChild("Stage")
 if not stage then return end
 teleport(player,math.clamp(stage.Value,1,STAGES+1))
 message(player,"📍 Returned to your saved checkpoint!")
end)
boostEvent.OnServerEvent:Connect(function(player)
 local stats=player:FindFirstChild("leaderstats")
 local balance=stats and stats:FindFirstChild("Coins")
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if not balance or not humanoid or humanoid.Health<=0 then return end
 if os.clock()-(freeBoostCooldown[player] or -1000)<70 then
  message(player,"⚡ Practice Boost is cooling down!")
  return
 end
 if balance.Value<40 then
  message(player,"⚡ Earn 40 coins to activate a 15-second speed boost!")
  return
 end
 freeBoostCooldown[player]=os.clock()
 balance.Value-=40
 local current=passOwnership[player] and passOwnership[player].speed and 24 or 16
 humanoid.WalkSpeed=math.max(current,27)
 message(player,"⚡ PRACTICE BOOST! 15 seconds of super speed!")
 task.delay(15,function()
  if humanoid.Parent then
   humanoid.WalkSpeed=current
  end
 end)
end)
local function neonText(part,text)
 local gui=Instance.new("BillboardGui")
 gui.Adornee=part;gui.Size=UDim2.fromOffset(250,75)
 gui.StudsOffset=Vector3.new(0,8,0);gui.AlwaysOnTop=true;gui.MaxDistance=120;gui.Parent=part
 local label=Instance.new("TextLabel")
 label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1
 label.Text=text;label.TextScaled=true;label.Font=Enum.Font.GothamBlack
 label.TextColor3=Color3.new(1,1,1);label.TextStrokeTransparency=0;label.Parent=gui
end
local function celebrateCheckpoint(player,isFinish)
 local char=player.Character
 local root=char and char:FindFirstChild("HumanoidRootPart")
 if not root or not root:IsA("BasePart") then return end
 local attachment=Instance.new("Attachment")
 attachment.Name="CheckpointConfetti";attachment.Parent=root
 local particles=Instance.new("ParticleEmitter")
 particles.Name="RainbowVictoryBurst"
 particles.Texture="rbxasset://textures/particles/sparkles_main.dds"
 particles.Rate=0
 particles.Lifetime=NumberRange.new(.8,1.5)
 particles.Speed=NumberRange.new(isFinish and 14 or 7,isFinish and 24 or 13)
 particles.SpreadAngle=Vector2.new(360,360)
 particles.Size=NumberSequence.new(.65)
 particles.Color=ColorSequence.new(Color3.fromRGB(255,92,170),Color3.fromRGB(79,224,255))
 particles.Parent=attachment
 particles:Emit(isFinish and 140 or 35)
 game:GetService("Debris"):AddItem(attachment,3)
end
local function awardCheckpoint(player,stage)
 local stats=player:FindFirstChild("leaderstats")
 local stageStat=stats and stats:FindFirstChild("Stage")
 local coinStat=stats and stats:FindFirstChild("Coins")
 local winStat=stats and stats:FindFirstChild("Wins")
 if not(stageStat and coinStat and winStat) then return end
 if stage==stageStat.Value+1 then
  stageStat.Value=stage
  celebrateCheckpoint(player,stage==STAGES+1)
  coinStat.Value+=25*(passOwnership[player] and passOwnership[player].double_coins and 2 or 1)
  message(player,"✅ CHECKPOINT "..stage.."! +25 free coins!")
  if stage==STAGES+1 then
   winStat.Value+=1
   coinStat.Value+=200*(passOwnership[player] and passOwnership[player].double_coins and 2 or 1)
   local start=raceStarted[player]
   if start and raceEligible[player] then
    local elapsed=math.max(1,math.floor((workspace:GetServerTimeNow()-start)*1000))
    player:SetAttribute("LastTimeMs",elapsed)
    local oldBest=player:GetAttribute("BestTimeMs") or 0
    if oldBest==0 or elapsed<oldBest then
     player:SetAttribute("BestTimeMs",elapsed)
     coinStat.Value+=100*(passOwnership[player] and passOwnership[player].double_coins and 2 or 1)
     message(player,"🏆 NEW PERSONAL BEST! +100 bonus coins!")
    else
     message(player,"🏆 YOU WON! Replay to try for a faster time!")
    end
   else
    message(player,"🏆 COURSE COMPLETE! Finish a fresh run to set a personal best!")
   end
   raceStarted[player]=nil
  end
  task.spawn(save,player)
 elseif stage>stageStat.Value+1 then
  message(player,"Reach the previous checkpoint first!")
 end
end
local function coinPad(position,stage,index)
 local pad=block("Coin_"..stage.."_"..index,Vector3.new(2.1,2.1,2.1),CFrame.new(position),
  Color3.fromRGB(255,216,60),Enum.Material.Neon,false)
 pad.Shape=Enum.PartType.Ball
 coins[pad]={stage=stage,index=index}
 local lastCollected={}
 spinningCoins[pad]=true
 local glow=Instance.new("PointLight")
 glow.Color=Color3.fromRGB(255,216,85);glow.Range=10;glow.Brightness=.7
 glow.Parent=pad
 pad.Touched:Connect(function(hit)
  local player=playerOf(hit)
  if not player then return end
  local now=os.clock()
  if now-(lastCollected[player.UserId] or -1000)<25 then return end
  lastCollected[player.UserId]=now
  local stats=player:FindFirstChild("leaderstats")
  local stat=stats and stats:FindFirstChild("Coins")
  if stat then stat.Value+=5*(passOwnership[player] and passOwnership[player].double_coins and 2 or 1);message(player,"🪙 COINS COLLECTED!") end
 end)
end
local function movingHarm(part)
 part.Touched:Connect(function(hit)
  local player,humanoid=playerOf(hit)
  if not player or not humanoid then return end
  if os.clock()-(touchCooldown[player] or 0)<1 then return end
  touchCooldown[player]=os.clock()
  humanoid.Health=0
 end)
end

-- RAINBOW RUSH 0.3: 12 distinct, reachable islands in the sky.
-- Every obstacle section has a path with ~8-9 stud forward hops.
local Lighting=game:GetService("Lighting")
local TweenService=game:GetService("TweenService")
Lighting.ClockTime=14.2
Lighting.Brightness=3
Lighting.Ambient=Color3.fromRGB(175,183,240)
Lighting.OutdoorAmbient=Color3.fromRGB(187,205,255)
Lighting.EnvironmentDiffuseScale=.8
Lighting.EnvironmentSpecularScale=.7
local atmosphere=Lighting:FindFirstChild("RainbowAtmosphere") or Instance.new("Atmosphere")
atmosphere.Name="RainbowAtmosphere"
atmosphere.Density=.27
atmosphere.Offset=.1
atmosphere.Color=Color3.fromRGB(210,233,255)
atmosphere.Decay=Color3.fromRGB(150,169,238)
atmosphere.Parent=Lighting
local bloom=Lighting:FindFirstChild("RainbowBloom") or Instance.new("BloomEffect")
bloom.Name="RainbowBloom"
bloom.Intensity=.33;bloom.Size=20;bloom.Threshold=1.4
bloom.Parent=Lighting
local oldBaseplate=workspace:FindFirstChild("Baseplate")
if oldBaseplate and oldBaseplate:IsA("BasePart") then
 oldBaseplate.Transparency=1
 oldBaseplate.CanCollide=false
end
local stageNames={
 "Trust Issues","Fake Coin Alley","Wrong Way","Boost or Bust",
 "Laser Lies","Now You See Me","Cloud Betrayal","Tiny Troll Bridge",
 "Bounce Surprise","Spin to Lose","Almost the End","Fake Finish",
 "Invisible Ink","Trust the Floor","Door of Lies","Banana Factory",
 "No Jump Zone","Laser Sandwich","The Wrong Button","Ghost Bridge",
 "Sneaky Steps","Reverse Express","Fake Checkpoint","Floor Roulette",
 "The Long Jump","Pop Goes the Floor","Invisible Wall","Moving Madness",
 "Tiny Trouble","Double Betrayal","Wrong Turn","The Final Exam",
 "Definitely the End","Disappearing Act","Last Laugh","Actually the End"
}
local function floatingPart(name,size,position,color,material,collide)
 local p=block(name,size,CFrame.new(position),color,material or Enum.Material.Neon,collide)
 if name:find("Platform") or name:find("Pad") or name:find("Cloud") then
  local rim=Instance.new("Highlight")
  rim.Name="GlowRim";rim.FillTransparency=1
  rim.OutlineColor=color;rim.OutlineTransparency=.45;rim.Parent=p
 end
 return p
end
local function littleCloud(position,scale)
 local model=Instance.new("Model");model.Name="FluffyCloud";model.Parent=mapFolder
 for i=1,4 do
  local x=(i-2.5)*4.1*scale
  local cloud=block("Cloud",Vector3.new(8,3.8,5.8)*scale,CFrame.new(position+Vector3.new(x,math.sin(i)*.5,0)),Color3.fromRGB(240,246,255),Enum.Material.SmoothPlastic,false)
  cloud.Shape=Enum.PartType.Ball
  cloud.Parent=model
  cloud.CastShadow=false
 end
end
local function sparkles(part,color)
 local a=Instance.new("Attachment");a.Parent=part
 local particle=Instance.new("ParticleEmitter")
 particle.Name="RainbowSparkles"
 particle.Texture="rbxasset://textures/particles/sparkles_main.dds"
 particle.Color=ColorSequence.new(color)
 particle.Rate=5;particle.Lifetime=NumberRange.new(.5,1.3)
 particle.Speed=NumberRange.new(.3,1.1)
 particle.Size=NumberSequence.new(.7)
 particle.Parent=a
end

-- Obby visual kit: no colliding decoration obstructs jumping.
local function decorative(name,size,position,color,material)
 local p=block(name,size,CFrame.new(position),color,material or Enum.Material.Neon,false)
 p.CanTouch=false;p.CastShadow=false
 return p
end
local function orb(name,position,diameter,color)
 local p=decorative(name,Vector3.new(diameter,diameter,diameter),position,color,Enum.Material.SmoothPlastic)
 p.Shape=Enum.PartType.Ball
 return p
end
local function rainbowArch(center,stage)
 local z=center.Z+7.7
 for index=1,6 do
  local c=palette[index]
  local width=9.6+(index-1)*.55
  local height=13.5+(index-1)*.65
  decorative("ArchLeft_"..stage.."_"..index,Vector3.new(.76,height,.76),Vector3.new(-width,10+height/2,z),c)
  decorative("ArchRight_"..stage.."_"..index,Vector3.new(.76,height,.76),Vector3.new(width,10+height/2,z),c)
  decorative("ArchTop_"..stage.."_"..index,Vector3.new(width*2+.76,.76,.76),Vector3.new(0,10+height,z),c)
 end
 orb("ArchStarL_"..stage,Vector3.new(-13.5,22,z),3.0,Color3.fromRGB(255,249,166))
 orb("ArchStarR_"..stage,Vector3.new(13.5,22,z),3.0,Color3.fromRGB(255,249,166))
end
local function checkpointTheme(center,stage,color)
 for side=-1,1,2 do
  local base=center+Vector3.new(side*14,3.3,-4)
  decorative("BeaconPole_"..stage.."_"..side,Vector3.new(1,7,1),base,color)
  orb("BeaconOrb_"..stage.."_"..side,base+Vector3.new(0,4.2,0),2.6,Color3.fromRGB(255,242,134))
 end
 decorative("CheckpointStripe_"..stage,Vector3.new(23,.3,.65),
  center+Vector3.new(0,1.22,8.8),Color3.fromRGB(255,255,255))
end
local function finishPodium(center)
 for i=1,6 do
  decorative("ChampionCarpet_"..i,Vector3.new(2.1,.3,11),
   center+Vector3.new((i-3.5)*2.1,1.3,-5),palette[i])
 end
 for side=-1,1,2 do
  local p=decorative("TrophyPillar",Vector3.new(2,11,2),
   center+Vector3.new(side*11,5,0),Color3.fromRGB(255,218,78))
  orb("TrophyOrb",p.Position+Vector3.new(0,6.8,0),3.5,Color3.fromRGB(255,248,168))
 end
end
RunService.Heartbeat:Connect(function(dt)
 for p in pairs(spinningCoins) do
  if p.Parent then p.CFrame=p.CFrame*CFrame.Angles(0,dt*2.5,0)
  else spinningCoins[p]=nil end
 end
end)

local function boostPad(part)
 part.Touched:Connect(function(hit)
  local p,h=playerOf(hit)
  if not p or not h then return end
  local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
  if not root or not root:IsA("BasePart") then return end
  if os.clock()-(touchCooldown[p] or 0)<2.5 then return end
  touchCooldown[p]=os.clock()
  root.AssemblyLinearVelocity=Vector3.new(root.AssemblyLinearVelocity.X,70,root.AssemblyLinearVelocity.Z+19)
  message(p,"🚀 BOOST! Fly to the next platform!")
 end)
end
local function vanishingPad(part)
 local busy=false
 part.Touched:Connect(function(hit)
  if busy or not playerOf(hit) then return end
  busy=true
  task.delay(.4,function()
   if not part.Parent then return end
   part.Transparency=.72;part.CanCollide=false
   task.delay(2.8,function()
    if part.Parent then part.Transparency=0;part.CanCollide=true end
    busy=false
   end)
  end)
 end)
end

-- Side-path pranks: never delete progress, purchases or earned coins.
local trollCooldown={}
local function prankTarget(part,kind)
 part.Touched:Connect(function(hit)
  local player=playerOf(hit)
  if not player then return end
  if os.clock()-(trollCooldown[player] or -1000)<3 then return end
  trollCooldown[player]=os.clock()
  local char=player.Character
  local root=char and char:FindFirstChild("HumanoidRootPart")
  if not root or not root:IsA("BasePart") then return end
  if kind=="fake_finish" then
   local stats=player:FindFirstChild("leaderstats")
   local stage=stats and stats:FindFirstChild("Stage")
   if stage then teleport(player,stage.Value) end
   message(player,"😂 FAKE FINISH! You got trolled! Your checkpoint is safe.")
  elseif kind=="fake_coin" then
   root.AssemblyLinearVelocity=Vector3.new(0,45,-18)
   message(player,"🪙 FREE COINS? NAH! YOU GOT LAUNCHED!")
  elseif kind=="wrong_way" then
   root.AssemblyLinearVelocity=Vector3.zero
   root.CFrame=root.CFrame*CFrame.Angles(0,math.pi,0)
   message(player,"↩️ WRONG WAY! The path was behind you!")
  elseif kind=="bounce" then
   root.AssemblyLinearVelocity=Vector3.new(0,59,0)
   message(player,"🚀 SECRET BOUNCE! Surprise!")
  end
 end)
end
local function prankSign(part,words)
 local g=Instance.new("BillboardGui")
 g.Size=UDim2.fromOffset(175,55);g.StudsOffset=Vector3.new(0,3,0)
 g.Adornee=part;g.AlwaysOnTop=true;g.MaxDistance=90;g.Parent=part
 local t=Instance.new("TextLabel")
 t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1
 t.Text=words;t.TextScaled=true;t.Font=Enum.Font.GothamBlack
 t.TextColor3=Color3.fromRGB(255,242,101)
 t.TextStrokeTransparency=.1;t.Parent=g
end
local function baitPad(stage,jump,position,kind,label)
 local part=block("TrollBait_"..stage.."_"..jump,Vector3.new(7.5,1.1,7),
  CFrame.new(position),Color3.fromRGB(255,194,28),Enum.Material.Neon,true)
 prankSign(part,label)
 prankTarget(part,kind)
 return part
end

local spinnerParts={}
local function spinner(center,stage)
 local pivot=Instance.new("Part")
 pivot.Name="SpinnerBeam_"..stage
 pivot.Size=Vector3.new(14,.55,.7)
 pivot.Material=Enum.Material.Neon
 pivot.Color=Color3.fromRGB(255,61,112)
 pivot.CanCollide=false;pivot.Anchored=true
 pivot.Position=center
 pivot.Parent=mapFolder
 movingHarm(pivot)
 table.insert(spinnerParts,{part=pivot,center=center,offset=stage*.75})
end
RunService.Heartbeat:Connect(function()
 local now=os.clock()
 for _,entry in ipairs(spinnerParts) do
  if entry.part.Parent then
   entry.part.CFrame=CFrame.new(entry.center)*CFrame.Angles(0,now*1.55+entry.offset,0)
  end
 end
end)
-- New traps use deterministic safe routes; no purchase is required.
local function secretHazard(position,size,visible)
 local hazard=block("SecretHazard",size,CFrame.new(position),Color3.fromRGB(255,55,80),Enum.Material.Neon,false)
 hazard.Transparency=visible and 0 or 1
 movingHarm(hazard)
 return hazard
end
local function fakeFloor(position,size,color)
 local fake=block("FakeFloor",size,CFrame.new(position),color,Enum.Material.SmoothPlastic,false)
 fake.CanTouch=false
 return fake
end
-- Reactive pranks: each surprise fires once per player per stage per session.
local prankSeen=setmetatable({}, {__mode="k"})
local function reactivePrank(pad,stage,kind)
 pad.Touched:Connect(function(hit)
  local p,h=playerOf(hit)
  if not p or not h then return end
  local stats=p:FindFirstChild("leaderstats")
  local st=stats and stats:FindFirstChild("Stage")
  if not st or st.Value~=stage then return end
  local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
  if not root or not root:IsA("BasePart") then return end
  local seen=prankSeen[p] or {}
  prankSeen[p]=seen
  local key=tostring(stage)..kind
  if seen[key] then return end
  seen[key]=true
  if kind=="yeet" then
   root.AssemblyLinearVelocity=Vector3.new(0,38,-38)
   message(p,"NOPE. Back you go!")
  elseif kind=="freeze" then
   local speed=h.WalkSpeed
   h.WalkSpeed=0
   message(p,"Your legs are buffering...")
   task.delay(.85,function() if h.Parent and h.Health>0 and h.WalkSpeed==0 then h.WalkSpeed=speed end end)
  elseif kind=="backstep" then
   root.CFrame=root.CFrame+Vector3.new(0,2,-8.3)
   root.AssemblyLinearVelocity=Vector3.zero
   message(p,"One step forward, one step back.")
  elseif kind=="pop" then
   root.AssemblyLinearVelocity=Vector3.new(24,52,0)
   message(p,"POP QUIZ: can you fly?")
  elseif kind=="fakewin" then
   message(p,"YOU WON! ...just kidding.")
   task.delay(.45,function()
    if p.Character and p.Character:FindFirstChild("HumanoidRootPart")==root and st.Value==stage and h.Health>0 then teleport(p,stage) end
   end)
  elseif kind=="tinyjump" then
   local oldPower,oldHeight=h.JumpPower,h.JumpHeight
   h.JumpPower=15;h.JumpHeight=1
   message(p,"Jump subscription expired.")
   task.delay(1.3,function()
    if h.Parent and h.Health>0 then
     if h.JumpPower==15 then h.JumpPower=oldPower end
     if h.JumpHeight==1 then h.JumpHeight=oldHeight end
    end
   end)
  end
 end)
end
local routePoints={}
for stage=1,STAGES+1 do
 local center=stagePos(stage)
 local color=palette[(stage-1)%#palette+1]
 local checkpoint=floatingPart("Checkpoint_"..stage,Vector3.new(27,2.2,19),center,color,Enum.Material.SmoothPlastic,true)
 checkpoints[stage]=checkpoint
 rainbowArch(center,stage)
 checkpointTheme(center,stage,color)
 if stage==STAGES+1 then finishPodium(center) end
 local core=floatingPart("CheckpointCore_"..stage,Vector3.new(12,.4,9),center+Vector3.new(0,1.35,0),Color3.fromRGB(209,245,255),Enum.Material.Neon,false)
 core.Transparency=.22
 if stage==1 or stage==STAGES+1 then sparkles(core,color) end
 neonText(checkpoint,stage<=STAGES and ("STAGE "..stage.." — "..stageNames[stage]) or "🏆 RAINBOW CHAMPION!")
 checkpoint.Touched:Connect(function(hit)
  local p=playerOf(hit)
  if p then awardCheckpoint(p,stage) end
 end)
 if stage==1 then
  local welcome=floatingPart("WelcomeDeck",Vector3.new(36,1.8,21),
   center+Vector3.new(0,-.4,-17),Color3.fromRGB(123,91,231),Enum.Material.SmoothPlastic,true)
  local path=floatingPart("LobbyPath",Vector3.new(13,1.3,6),
   center+Vector3.new(0,0,-5),Color3.fromRGB(255,194,99),Enum.Material.SmoothPlastic,true)
  for i=1,6 do
   decorative("WelcomeStripe_"..i,Vector3.new(3.5,.32,14),
    center+Vector3.new((i-3.5)*3.6,.65,-19),palette[i])
  end
  for side=-1,1,2 do
   local pillar=decorative("WelcomeTower_"..side,Vector3.new(2,12,2),
    center+Vector3.new(side*16,6,-20),Color3.fromRGB(255,214,104))
   orb("WelcomeGlobe_"..side,pillar.Position+Vector3.new(0,7,0),
    4,Color3.fromRGB(255,248,175))
  end
  neonText(welcome,"RAINBOW TROLL OBBY! TRUST NOTHING!")
  local spawn=Instance.new("SpawnLocation")
  spawn.Name="RainbowRushSpawn";spawn.Size=Vector3.new(11,1,8)
  spawn.Position=center+Vector3.new(0,1.8,-18)
  spawn.Anchored=true;spawn.Neutral=true;spawn.CanCollide=true
  spawn.Transparency=.38
  spawn.Color=Color3.fromRGB(104,251,209);spawn.Material=Enum.Material.Neon
  spawn.Parent=mapFolder
 end
 -- Under each section, add distant cloud clusters as a sense of altitude.
 if stage%2==1 then
  littleCloud(center+Vector3.new(-35,-13,30),1.2)
  littleCloud(center+Vector3.new(34,-17,50),.85)
 end
 for side=-1,1,2 do
  orb("FloatingSkyOrb_"..stage.."_"..side,center+Vector3.new(side*34,15,20),
   4.2,palette[(stage+2)%#palette+1])
 end
 if stage<=STAGES then
  local points={}
  local pattern=stage%4
  for jump=1,6 do
   local z=center.Z+9+jump*8.3
   local x=0
   if stage==1 then x=math.sin(jump*.7)*1.2
   elseif stage==2 then x=(jump%2==0 and 4.2 or -4.2)
   elseif stage==3 then x=math.sin(jump*1.18)*5.2
   elseif stage==4 then x=math.sin(jump*.7)*1.6
   elseif stage==5 then x=(jump%2==0 and 2.9 or -2.9)
   elseif stage==6 then x=math.sin(jump*.8)*3.2
   elseif stage==7 then x=math.sin(jump*.7)*3.2
   elseif stage==8 then x=math.sin(jump*1.1)*2.5
   elseif stage==9 then x=(jump%2==0 and 3.2 or -3.2)
   elseif stage==10 then x=math.sin(jump*.8)*2.4
   elseif stage==11 then x=math.sin(jump*.85)*3.5
   else x=math.sin(jump*1.15)*5.0 end
   if stage>=13 then x=math.sin(jump*1.1+stage)*math.min(5,2.5+stage/15) end
   local width=(stage>=8 and 9 or 11)
   if stage==1 or stage==4 or stage==9 then width=13 end
   if stage==8 then width=6.8 end
   if stage>=25 then width=8 end
   local pad=floatingPart("RainbowPlatform_"..stage.."_"..jump,
    Vector3.new(width,1.3,7.1),Vector3.new(x,10,z),
    palette[(stage+jump-1)%#palette+1],Enum.Material.SmoothPlastic,true)
   table.insert(points,{x=x,z=z,part=pad})
   -- Ordinary-looking main route pads hide the surprises. Each is learnable.
   local tricks={"yeet","freeze","backstep","pop","fakewin","tinyjump"}
   if stage>=2 and jump==2+(stage%3) then
    reactivePrank(pad,stage,tricks[(stage-2)%#tricks+1])
   end
   if stage>=19 and jump==5 then
    reactivePrank(pad,stage,tricks[(stage+1)%#tricks+1])
   end
   -- A real-looking bridge with a missing middle: the original route remains open.
   if stage%5==0 and jump==3 then
    local side=stage%2==0 and 1 or -1
    for k=1,3 do
     local pos=Vector3.new(x+side*(width/2+3.5),10,z+(k-2)*3)
     if k==2 then fakeFloor(pos,Vector3.new(4,1.3,3),pad.Color)
     else block("ShortcutTile",Vector3.new(4,1.3,3),CFrame.new(pos),pad.Color,Enum.Material.SmoothPlastic,true) end
    end
   end

   if stage>=13 then
    local mode=(stage-13)%12
    local side=(jump%2==0 and 1 or -1)
    if mode==0 or mode==4 or mode==11 then
     -- Unmarked lethal strip; opposite half remains safe.
     if jump==2 or jump==4 or (stage>=30 and jump==5) then
      secretHazard(Vector3.new(x+side*width*.31,11.35,z),Vector3.new(width*.38,1.3,6.5),false)
     end
    elseif mode==1 or mode==7 then
     -- Identical-looking ghost twins, with a real center route.
     if jump%2==0 then fakeFloor(Vector3.new(x+side*(width+1),10,z),pad.Size,pad.Color) end
    elseif mode==2 or mode==6 then
     if jump==3 then
      local fake= baitPad(stage,jump,Vector3.new(x+12,10,z),"fake_finish","NEXT STAGE!")
      fake.Color=pad.Color
     end
    elseif mode==3 or mode==9 then
     if jump==2 or jump==5 then vanishingPad(pad) end
    elseif mode==5 then
     if jump==2 or jump==4 then
      secretHazard(Vector3.new(x,11.25,z-1.8),Vector3.new(width,.5,.6),true)
     end
    elseif mode==8 then
     if jump==3 or jump==5 then spinner(Vector3.new(x,11.45,z),stage+jump) end
    elseif mode==10 then
     if jump==3 then
      -- Hidden side wall leaves a clear route on the other side.
      local wall=block("InvisibleWall",Vector3.new(2,6,4),CFrame.new(x+side*3,13,z),pad.Color,Enum.Material.SmoothPlastic,true)
      wall.Transparency=1
     end
    end
   end

   -- An optional shiny branch beside the true course; no forced trap.
   if jump==3 and stage%3==1 then
    baitPad(stage,jump,Vector3.new(x+10.5,10,z),"fake_coin","FREE COINS!")
   elseif jump==3 and stage%3==2 then
    baitPad(stage,jump,Vector3.new(x-10.5,10,z),"wrong_way","SHORTCUT!")
   elseif jump==3 and stage%3==0 then
    baitPad(stage,jump,Vector3.new(x+10.5,10,z),"bounce","SECRET BOOST!")
   end
   -- Painted edges and chevrons make the next jump obvious.
   for side=-1,1,2 do
    decorative("PadStripe_"..stage.."_"..jump.."_"..side,
     Vector3.new(.35,.3,6.2),Vector3.new(x+side*(width/2-.5),10.83,z),
     Color3.fromRGB(250,253,255))
   end
   if stage<=12 and (jump==1 or jump==6) then
    decorative("ForwardMarker_"..stage.."_"..jump,Vector3.new(2.2,.35,2.8),
     Vector3.new(x,10.85,z),Color3.fromRGB(255,255,239))
   end
   if jump==2 or jump==5 then coinPad(Vector3.new(x,12.8,z),stage,jump) end
   if stage==4 and (jump==2 or jump==5) then
    local boost=floatingPart("SpeedPad_"..stage.."_"..jump,Vector3.new(4,.5,4),Vector3.new(x,10.95,z),
     Color3.fromRGB(92,251,198),Enum.Material.Neon,false)
    boostPad(boost)
   elseif stage==5 and (jump==2 or jump==4) then
    local laser=floatingPart("Laser_"..stage.."_"..jump,Vector3.new(width,.4,.6),
     Vector3.new(x,11.25,z-2.25),Color3.fromRGB(255,52,102),Enum.Material.Neon,false)
    movingHarm(laser)
   elseif stage==6 and jump>=2 then
    vanishingPad(pad)
   elseif stage==7 and (jump==2 or jump==4) then
    TweenService:Create(pad,TweenInfo.new(2.3,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{
     Position=pad.Position+Vector3.new(2.6,0,0)
    }):Play()
   elseif stage==9 and (jump==2 or jump==4) then
    local bounce=floatingPart("BouncePad_"..stage.."_"..jump,Vector3.new(4.5,.5,4),Vector3.new(x,10.95,z),
     Color3.fromRGB(255,207,88),Enum.Material.Neon,false)
    boostPad(bounce)
   elseif stage==10 and (jump==3 or jump==5) then
    spinner(Vector3.new(x,11.45,z),stage+jump)
   elseif stage==11 then
    local cloud=block("SkyPuff_"..stage.."_"..jump,Vector3.new(width+3,.7,8),CFrame.new(x,9.1,z),
     Color3.fromRGB(238,246,255),Enum.Material.SmoothPlastic,false)
    cloud.Shape=Enum.PartType.Ball
   end
  end
  routePoints[stage]=points
  local endBridge=floatingPart("LandingPlatform_"..stage,Vector3.new(15,1.3,10),
   Vector3.new(0,10,center.Z+62),color,Enum.Material.SmoothPlastic,true)
  if stage==12 or stage==33 or stage==36 then
   baitPad(stage,9,Vector3.new(-14,10,center.Z+61),"fake_finish","FREE FINISH!")
    sparkles(endBridge,color)
   for i=1,6 do
    decorative("FinaleStreamer_"..i,Vector3.new(.7,6,.7),
     Vector3.new((i-3.5)*3.0,16,center.Z+62),palette[i])
   end
  end
 end
end
-- Invisible catch-up death plane; Roblox's default Baseplate is hidden.
local void=block("SkyVoid",Vector3.new(450,2,STAGES*STAGE_LENGTH+280),
 CFrame.new(0,-33,STAGES*STAGE_LENGTH/2),Color3.fromRGB(108,130,204),Enum.Material.SmoothPlastic,false)
void.Transparency=1
void.Touched:Connect(function(hit)
 local _,humanoid=playerOf(hit)
 if humanoid then humanoid.Health=0 end
end)
-- Fall protection in case physics misses the invisible surface.
RunService.Heartbeat:Connect(function()
 for _,p in ipairs(Players:GetPlayers()) do
  local char=p.Character
  local root=char and char:FindFirstChild("HumanoidRootPart")
  local humanoid=char and char:FindFirstChildOfClass("Humanoid")
  if root and humanoid and root.Position.Y< -15 and humanoid.Health>0 then humanoid.Health=0 end
 end
end)

local function applyTrail(player)
 if not(passOwnership[player] and passOwnership[player].rainbow_trail) then return end
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 if not root or root:FindFirstChild("RainbowTrailA") then return end
 local a=Instance.new("Attachment");a.Name="RainbowTrailA";a.Position=Vector3.new(-.4,-1,0);a.Parent=root
 local b=Instance.new("Attachment");b.Name="RainbowTrailB";b.Position=Vector3.new(.4,-1,0);b.Parent=root
 local trail=Instance.new("Trail");trail.Name="RainbowCosmeticTrail"
 trail.Attachment0=a;trail.Attachment1=b;trail.Lifetime=.7
 trail.Color=ColorSequence.new(palette[1],palette[5])
 trail.LightEmission=1;trail.Parent=root
end
local function refreshPasses(player)
 local owned={}
 for name,id in pairs(GAME_PASSES) do
  owned[name]=false
  if id>0 then
   local success,value=pcall(function()return MarketplaceService:UserOwnsGamePassAsync(player.UserId,id)end)
   if success then owned[name]=value==true end
  end
 end
 passOwnership[player]=owned
 player:SetAttribute("RainbowVIP",owned.vip or false)
end
local function applyBenefits(player)
 local owned=passOwnership[player] or {}
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if humanoid then
  humanoid.WalkSpeed=owned.speed and 24 or 16
  humanoid.UseJumpPower=true
  humanoid.JumpPower=owned.gravity and 68 or 50
 end
 if owned.vip and character and not character:FindFirstChild("RainbowVIPGlow") then
  local h=Instance.new("Highlight");h.Name="RainbowVIPGlow"
  h.FillColor=Color3.fromRGB(251,199,54)
  h.OutlineColor=Color3.fromRGB(255,240,130)
  h.FillTransparency=.62
  h.Parent=character
 end
 applyTrail(player)
end
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player,id,purchased)
 if not purchased then return end
 for _,productId in pairs(GAME_PASSES) do
  if id>0 and id==productId then
   task.delay(2,function()
    if player.Parent then refreshPasses(player);applyBenefits(player) end
   end)
   break
  end
 end
end)
local function launchRainbowFireworks(player)
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if not root or not root:IsA("BasePart") then return end
 local fire=Instance.new("ParticleEmitter")
 fire.Name="RainbowFireworks";fire.Rate=0
 fire.Lifetime=NumberRange.new(.8,1.8)
 fire.Speed=NumberRange.new(12,27)
 fire.SpreadAngle=Vector2.new(360,360)
 fire.Color=ColorSequence.new(Color3.fromRGB(255,88,172),Color3.fromRGB(73,229,255))
 fire.Parent=root
 fire:Emit(130)
 game:GetService("Debris"):AddItem(fire,4)
end
local function productDelta(name)
 if name=="coins_250" then return 0,250 end
 if name=="coins_1200" then return 0,1200 end
 if name=="skip_1" then return 1,0 end
 if name=="skip_3" then return 3,0 end
 if name=="fireworks" or name=="chaos" then return 0,0 end
 return nil,nil
end
-- For permanent progress changes, mark each receipt exactly once in the same
-- DataStore transaction that awards the stage or coin balance.
MarketplaceService.ProcessReceipt=function(receipt)
 local name=productIndex[receipt.ProductId]
 if not name then return Enum.ProductPurchaseDecision.NotProcessedYet end
 local player=Players:GetPlayerByUserId(receipt.PlayerId)
 if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
 local stats=player:FindFirstChild("leaderstats")
 local stage=stats and stats:FindFirstChild("Stage")
 local balance=stats and stats:FindFirstChild("Coins")
 local wins=stats and stats:FindFirstChild("Wins")
 if not(stage and balance and wins) then return Enum.ProductPurchaseDecision.NotProcessedYet end
 local addStages,addCoins=productDelta(name)
 if not addStages then return Enum.ProductPurchaseDecision.NotProcessedYet end
 local key=tostring(player.UserId)
 local purchaseId=tostring(receipt.PurchaseId)
 local previousWasGranted=false
 local ok,result=pcall(function()
  return SAVE_STORE:UpdateAsync(key,function(old)
   old=type(old)=="table" and old or {}
   local receipts=old.receipts or {}
   if receipts[purchaseId] then
    previousWasGranted=true
    return old
   end
   -- Keep current earned in-session progress before granting the product.
   local currentStage=math.max(1,tonumber(old.stage) or 1,stage.Value)
   local currentCoins=math.max(0,tonumber(old.coins) or 0,balance.Value)
   local currentWins=math.max(0,tonumber(old.wins) or 0,wins.Value)
   receipts[purchaseId]=true
   return {stage=math.min(STAGES+1,currentStage+addStages),coins=currentCoins+addCoins,wins=currentWins,best=tonumber(old.best) or 0,receipts=receipts}
  end)
 end)
 if not ok or type(result)~="table" then return Enum.ProductPurchaseDecision.NotProcessedYet end
 if not previousWasGranted then
  stage.Value=math.max(stage.Value,math.min(STAGES+1,tonumber(result.stage) or stage.Value))
  balance.Value=math.max(balance.Value,tonumber(result.coins) or balance.Value)
  if addStages>0 then
   raceEligible[player]=false
   teleport(player,stage.Value)
  end
  if name=="fireworks" or name=="chaos" then launchRainbowFireworks(player) end
  if name=="chaos" then
   if os.time()-lastChaosTime>120 then
    lastChaosTime=os.time()
    showMessage:FireAllClients("🌈 CHECKPOINT CHAOS IN 3 SECONDS! Saved progress stays safe.")
    task.delay(3,function()
     for _,other in ipairs(Players:GetPlayers()) do
      local ownStats=other:FindFirstChild("leaderstats")
      local ownStage=ownStats and ownStats:FindFirstChild("Stage")
      if ownStage then teleport(other,ownStage.Value) end
     end
    end)
   else message(player,"Chaos cooling down. You received fireworks instead!") end
  end
  message(player,"✅ PURCHASE DELIVERED: "..name:gsub("_"," "))
 end
 return Enum.ProductPurchaseDecision.PurchaseGranted
end

Players.PlayerAdded:Connect(function(player)
 refreshPasses(player)
 local leaderstats=Instance.new("Folder");leaderstats.Name="leaderstats";leaderstats.Parent=player
 local stage=Instance.new("IntValue");stage.Name="Stage";stage.Value=1;stage.Parent=leaderstats
 local coin=Instance.new("IntValue");coin.Name="Coins";coin.Parent=leaderstats
 local wins=Instance.new("IntValue");wins.Name="Wins";wins.Parent=leaderstats
 local ok,data=pcall(function()return SAVE_STORE:GetAsync(tostring(player.UserId))end)
 if ok and type(data)=="table" then
  stage.Value=math.clamp(tonumber(data.stage) or 1,1,STAGES+1)
  coin.Value=math.max(0,tonumber(data.coins) or 0)
  wins.Value=math.max(0,tonumber(data.wins) or 0)
  player:SetAttribute("BestTimeMs",math.max(0,math.floor(tonumber(data.best) or 0)))
 end
 if player:GetAttribute("BestTimeMs")==nil then player:SetAttribute("BestTimeMs",0) end
 player:SetAttribute("LastTimeMs",0)
 raceStarted[player]=workspace:GetServerTimeNow()
 raceEligible[player]=stage.Value==1
 player:SetAttribute("RunStartedAt",raceStarted[player])
 local function onSpawn()
  task.wait(.3)
  if player.Parent and player.Character then
   teleport(player,stage.Value)
   applyBenefits(player)
  end
 end
 player.CharacterAdded:Connect(onSpawn)
 if player.Character then task.spawn(onSpawn) end
end)
Players.PlayerRemoving:Connect(function(player)
 save(player)
 touchCooldown[player]=nil
 passOwnership[player]=nil
 freeBoostCooldown[player]=nil
 resetCooldown[player]=nil
 raceStarted[player]=nil
 raceEligible[player]=nil
end)
game:BindToClose(function()
 for _,player in Players:GetPlayers() do save(player)end
end)