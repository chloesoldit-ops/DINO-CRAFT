-- TOWER OF TROLLS 2.2: paste entire file into Studio Command Bar in EDIT mode.
-- Does not delete old scripts; only disables scripts identified as this obby.
assert(not game:GetService("RunService"):IsRunning(),"STOP the playtest before installing.")
local ss=game:GetService("ServerScriptService")
local sp=game:GetService("StarterPlayer")
local ps=sp:WaitForChild("StarterPlayerScripts")
local serverSource=[====[
--!nonstrict
-- TOWER OF TROLLS 2.2 — Stability
-- Put this Script in ServerScriptService. No models or command setup required.
local Players=game:GetService("Players")
local MarketplaceService=game:GetService("MarketplaceService")
local DataStoreService=game:GetService("DataStoreService")
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

-- Optional, permanent cosmetic pass. Set to a real Game Pass ID after publishing.
local RAINBOW_TRAIL_PASS_ID=0
-- Replace 0 with IDs created in Roblox Creator Hub. All purchases are off until configured.
local GAME_PASSES={slap=2102130597,speed=2100229418,gravity=2101878610,fusion=2100445411,double_jump=2099863405,vip=2100127273,carpet=2099779265,rainbow_trail=0,double_coins=0}
local LIVE_SHOP_ENABLED=false -- Enable only after live private purchase testing.
-- Final Boss Skip: configured Developer Product, price controlled by Creator Dashboard.
local PRODUCTS={skip_boss=3736985491,skip_1=0,skip_3=0,coins_250=0,coins_1200=0,fireworks=0,chaos=0}
local passOwnership={}
local powerMode={}
local flying={}
local lounging={}
local stopSpecial=function() end
local lastChaosTime=0
local freeBoostCooldown={}
local resetCooldown={}
local raceStarted={}
local raceEligible={}
local productIndex={}
for name,id in pairs(PRODUCTS) do
 if id>0 then productIndex[id]=name end
end
-- Version 1.2: multiplayer betrayal bridges
local STAGES=61
local bossProgress=setmetatable({}, {__mode="k"})
local CHECKPOINT_INTERVAL=10
local function savedFloor(stage)
 if stage>=STAGES+1 then return STAGES+1 end
 return math.min(51,1+math.floor((math.clamp(stage,1,STAGES)-1)/CHECKPOINT_INTERVAL)*CHECKPOINT_INTERVAL)
end
local STAGE_LENGTH=30
local TOWER_RADIUS=13.5
-- Unpublished Studio places may not have DataStore access.
-- Use a memory-only test store so the obby and HUD can still run before publishing.
local studio=RunService:IsStudio()
local storeOkay,realStore=pcall(function()
 if studio then return nil end
 return DataStoreService:GetDataStore("RainbowRush_Tower_10")
end)
local temporaryRecords={}
storeOkay=storeOkay and realStore~=nil
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
if studio then print("Tower 2.2: Studio memory-only test mode.") elseif not storeOkay then warn("Tower data unavailable; purchases and saves disabled.") end
-- Purchases are stored in the same player record as progression for atomic grants.
local checkpoints={}
local touchCooldown={}
local coins={}
local spinningCoins={}
if workspace:FindFirstChild("RainbowRushWorld") or ReplicatedStorage:FindFirstChild("RainbowRushEvents") then
 error("Duplicate tower detected. Stop and disable old obby scripts before playing.")
end
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
shopCatalog.OnServerInvoke=function() return {passes=GAME_PASSES,products=PRODUCTS,live=LIVE_SHOP_ENABLED} end

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
 return Vector3.new(TOWER_RADIUS,10+(stage-1)*STAGE_LENGTH,0)
end
local function message(player,text)
 showMessage:FireClient(player,text)
end
local function playerOf(part)
 local model=part and part:FindFirstAncestorOfClass("Model")
 local humanoid=model and model:FindFirstChildOfClass("Humanoid")
 local player=model and Players:GetPlayerFromCharacter(model)
 if not player or not humanoid or humanoid.Health<=0 or flying[player] or lounging[player] then return nil end
 return player,humanoid
end
local prison={}; local prisonDone={}; local prisonSpawn
local function teleport(player,stage)
 stopSpecial(player)
 bossProgress[player]=nil
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if root and root:IsA("BasePart") then
  root.AssemblyLinearVelocity=Vector3.zero
  root.AssemblyAngularVelocity=Vector3.zero
  local target=stagePos(stage)+Vector3.new(0,5,0)
  if prison[player] then target=Vector3.new(80,15,0) end
  local sign=stage%2==0 and -1 or 1
  if stage==STAGES or stage%10==5 or stage%10==8 then root.CFrame=CFrame.lookAt(target,target+Vector3.new(1,0,0)) else root.CFrame=CFrame.lookAt(target,target+Vector3.new(-.25,0,sign)) end
 end
end
local function returnToSavedFloor(player)
 local stats=player:FindFirstChild("leaderstats")
 local stage=stats and stats:FindFirstChild("Stage")
 if not stage then return end
 if not prison[player] then stage.Value=savedFloor(stage.Value) end
 teleport(player,stage.Value)
end
local dataBusy={}
local function save(player)
 if not player:GetAttribute("TowerDataReady") or dataBusy[player] then return end
 local stats=player:FindFirstChild("leaderstats")
 local stage=stats and stats:FindFirstChild("Stage")
 local points=stats and stats:FindFirstChild("Coins")
 local wins=stats and stats:FindFirstChild("Wins")
 if not (stage and points and wins) then return end
 local data={stage=savedFloor(stage.Value),coins=points.Value,wins=wins.Value,best=player:GetAttribute("BestTimeMs") or 0}
 dataBusy[player]=true
 pcall(function()SAVE_STORE:UpdateAsync(tostring(player.UserId),function(old)
  old=type(old)=="table" and old or {}
  local previousBest=tonumber(old.best) or 0
  local best=data.best
  if previousBest>0 and (best<=0 or previousBest<best) then best=previousBest end
  old.stage=data.stage;old.coins=data.coins;old.wins=math.max(tonumber(old.wins) or 0,data.wins);old.best=best
  return old
 end)end)
 dataBusy[player]=nil
end
-- Replaying is free and never resets purchases, coins or wins.
replayEvent.OnServerEvent:Connect(function(player)
 local stats=player:FindFirstChild("leaderstats")
 local stage=stats and stats:FindFirstChild("Stage")
 if not stage then return end
 if stage.Value<=STAGES then
  message(player,"🏁 Finish all 61 floors to unlock replay!")
  return
 end
 stage.Value=1
 raceStarted[player]=workspace:GetServerTimeNow()
 raceEligible[player]=(powerMode[player] or "normal")=="normal"
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
 returnToSavedFloor(player)
 message(player,"📍 Returned to your saved checkpoint!")
end)
boostEvent.OnServerEvent:Connect(function(player)
 local stats=player:FindFirstChild("leaderstats")
 local balance=stats and stats:FindFirstChild("Coins")
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if not balance or not humanoid or humanoid.Health<=0 or prison[player] or flying[player] or lounging[player] then return end
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
 raceEligible[player]=false
 local current=humanoid.WalkSpeed
 humanoid.WalkSpeed=math.max(current,27)
 message(player,"⚡ PRACTICE BOOST! 15 seconds of super speed!")
 task.delay(15,function()
  if humanoid.Parent then
   if humanoid.WalkSpeed==27 then humanoid.WalkSpeed=current end
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
 -- Do not roll progression backwards when landing on an earlier marker.
 if stage<=stageStat.Value then return end
 if stage==stageStat.Value+1 then
  if stage==STAGES+1 and (bossProgress[player] or 0)~=4 then
   message(player,"Finish all four boss sections first!")
   return
  end
  stageStat.Value=stage
  if savedFloor(stage)==stage then
   celebrateCheckpoint(player,stage==STAGES+1)
   coinStat.Value+=25*(passOwnership[player] and passOwnership[player].double_coins and 2 or 1)
   message(player,"CHECKPOINT SAVED! Floor "..stage)
  else
   message(player,"Floor "..stage.." reached. NOT a checkpoint!")
  end
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
  if savedFloor(stage)==stage then task.spawn(save,player) end
 elseif stage>stageStat.Value+1 then
  message(player,"Reach the previous floor first!")
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
 "The Floor Is Lying",
 "Free Coins",
 "Jump Prison",
 "Ghost Twins",
 "Laser Kitchen",
 "Vanishing Act",
 "Wrong Button",
 "Tiny Steps",
 "Fake Shortcut",
 "Spin Cycle",
 "Invisible Edge",
 "Almost There",
 "Trust Nobody",
 "Side Quest",
 "Moving Target",
 "False Hope",
 "Laser Laundry",
 "Thin Ice",
 "Wrong Door",
 "Ghost Town",
 "Precision Panic",
 "The Floor Quit",
 "Spin Doctor",
 "Fake Checkpoint",
 "Needle Walk",
 "No Refunds",
 "Laser Sandwich",
 "The Betrayal",
 "Sky Needles",
 "Halfway (Maybe)",
 "Floor Problems",
 "Ghost Factory",
 "The Long Way",
 "Moving Madness",
 "Tiny Trouble",
 "Double Trouble",
 "False Victory",
 "Laser Ballet",
 "Disappearing Steps",
 "Wrong Turn",
 "No Easy Mode",
 "The Narrow Road",
 "Spin Again",
 "Troll Toll",
 "Cloud Nine",
 "Invisible Ink",
 "The Final Exam",
 "Just One More",
 "Fake Ending",
 "Gravity Wins",
 "Needle Tower",
 "The Last Lie",
 "Ghost Elevator",
 "Laser Circus",
 "Trust Issues",
 "Final Final Exam",
 "Definitely Done",
 "Not Done",
 "Last Laugh",
 "Actually the End",
 "FINAL BOSS: THE IMPOSSIBLE EXAM"
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
   if stage then returnToSavedFloor(player) end
   message(player,"😂 FAKE FINISH! You got trolled! Your checkpoint is safe.")
  elseif kind=="fake_coin" then
   message(player,"YOU JUST GOT RICKROLLED! Free coins? Nice try.")
   local h=char:FindFirstChildOfClass("Humanoid")
   if h then task.delay(.6,function() if h.Parent then h.Health=0 end end) end
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
 pivot.Size=Vector3.new(6,.55,.7)
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
-- White box prison: temporary, player-specific and reset-proof during this session.
local prisonRemote=Instance.new("RemoteEvent")
prisonRemote.Name="PrisonPress"; prisonRemote.Parent=events
local white=Color3.fromRGB(250,250,250)
local function roomPart(name,size,pos)
 return block(name,size,CFrame.new(pos),white,Enum.Material.SmoothPlastic,true)
end
roomPart("PrisonFloor",Vector3.new(24,2,24),Vector3.new(80,10,0))
roomPart("PrisonRoof",Vector3.new(24,2,24),Vector3.new(80,25,0))
for _,side in ipairs({-1,1}) do
 roomPart("PrisonWall",Vector3.new(2,15,24),Vector3.new(80+side*11,17.5,0))
 roomPart("PrisonWall",Vector3.new(24,15,2),Vector3.new(80,17.5,side*11))
end
prisonSpawn=Instance.new("SpawnLocation")
prisonSpawn.Name="TrollRespawn";prisonSpawn.Size=Vector3.new(5,1,5)
prisonSpawn.Position=Vector3.new(80,22,0);prisonSpawn.Anchored=true
prisonSpawn.Neutral=true;prisonSpawn.Enabled=false;prisonSpawn.CanCollide=false;prisonSpawn.Transparency=.25
prisonSpawn.Parent=mapFolder
local function releasePrison(p)
 if not prison[p] then return end
 prison[p]=nil;prisonDone[p]=true;p:SetAttribute("TrollPrison",false)
 p:SetAttribute("PrisonCount",10)
 local stats=p:FindFirstChild("leaderstats");local st=stats and stats:FindFirstChild("Stage")
 if st then returnToSavedFloor(p) end
 message(p,"PAROLE GRANTED. Unfortunately, the obby continues.")
end
local function enterPrison(p)
 if prison[p] or prisonDone[p] then return end
 local state={count=0,last=0};prison[p]=state;raceEligible[p]=false
 p:SetAttribute("PrisonCount",0);p:SetAttribute("TrollPrison",true)
 teleport(p,3)
 message(p,"WELCOME TO THE WHITE BOX. Resetting won't help!")
 -- A free escape after 60 seconds prevents permanent softlocks.
 task.delay(60,function() if prison[p]==state then releasePrison(p) end end)
end
prisonRemote.OnServerEvent:Connect(function(p)
 local state=prison[p];if not state or state.count>=10 or os.clock()-state.last<.65 then return end
 state.last=os.clock();state.count+=1;p:SetAttribute("PrisonCount",state.count)
 if state.count>=10 then task.delay(.85,function() if prison[p]==state then releasePrison(p) end end) end
end)
local jokes={"Skill issue detected.","The floor has resigned.","Gravity wins again.","Your keyboard is innocent.","Certified bruh moment.","Plot twist: the floor is a liar."}
local function jokeTrap(part,stage,index)
 local seen=setmetatable({}, {__mode="k"})
 part.Touched:Connect(function(hit)
  local p,h=playerOf(hit);if not p or not h or seen[p] then return end
  local stats=p:FindFirstChild("leaderstats");local st=stats and stats:FindFirstChild("Stage")
  if not st or st.Value~=stage then return end
  seen[p]=true
  message(p,jokes[(stage+index)%#jokes+1])
  -- Jokes on the real route are text only; deadly traps are separate obstacles.
 end)
end
-- Vertical spiral tower: 12 jumps per floor, 60 floors.
local function towerPoint(stage,step)
 local direction=stage%2==0 and -1 or 1
 local angle=direction*step*math.pi/6
 local mode=(stage-1)%6
 local radius=TOWER_RADIUS
 if mode==1 then radius=radius-1.5*math.sin(step*math.pi/3) end
 if mode==4 then radius=radius-2*math.sin(step*math.pi/2)^2 end
 local rise=step*2.5
 if mode==2 then rise=rise+0.65*math.sin(step*math.pi/2) end
 return Vector3.new(radius*math.cos(angle),10+(stage-1)*STAGE_LENGTH+rise,radius*math.sin(angle))
end
local function radial(step)
 local angle=step*math.pi/6
 return Vector3.new(math.cos(angle),0,math.sin(angle))
end
-- Decorative central spine: cannot obstruct the route.
for _,obj in ipairs(workspace:GetChildren()) do
 if obj:IsA("SpawnLocation") then obj.Enabled=false end
end
local spine=decorative("TowerSpine",Vector3.new(3,STAGES*STAGE_LENGTH,3),Vector3.new(0,10+STAGES*STAGE_LENGTH/2,0),Color3.fromRGB(50,48,72),Enum.Material.SmoothPlastic)
spine.Transparency=.35
-- Multiplayer betrayal floors. The bridge is shared, never purchased.
local betrayalFloors={[8]=true,[18]=true,[28]=true,[38]=true,[48]=true,[58]=true}
local function betrayalCourse(stage,center,color)
 local green=Color3.fromRGB(55,220,125)
 local gold=Color3.fromRGB(255,210,65)
 local control=block("HoldPad_"..stage,Vector3.new(5,1.1,5),CFrame.new(center+Vector3.new(0,0,-6)),green,Enum.Material.Neon,true)
 prankSign(control,"HOLD TO OPEN BRIDGE")
 local bridge={}
 local waypoints={center,center+Vector3.new(42,10,0),center+Vector3.new(42,15,12),center+Vector3.new(0,25,12),center+Vector3.new(0,30,0)}
 for segment=1,#waypoints-1 do
  local a,b=waypoints[segment],waypoints[segment+1]
  local delta=b-a
  local horizontal=Vector3.new(delta.X,0,delta.Z)
  local length=horizontal.Magnitude
  local count=math.ceil(length/6.5)
  local forward=horizontal.Unit
  local lateral=Vector3.new(-forward.Z,0,forward.X)
  for i=1,count do
   local pos=a:Lerp(b,i/count)
   -- The gold one-stud route stays solid even when nobody helps.
   if not (segment==#waypoints-1 and i==count) then
    local size=(i==count and 4 or 1)
    block("Needle_"..stage.."_"..segment.."_"..i,Vector3.new(size,1,size),CFrame.new(pos),gold,Enum.Material.SmoothPlastic,true)
   end
   local middle=a:Lerp(b,(i-.5)/count)+lateral*2.5
   local deck=block("BetrayalBridge_"..stage.."_"..segment.."_"..i,Vector3.new(3,.65,delta.Magnitude/count+.2),CFrame.lookAt(middle,middle+delta.Unit),color,Enum.Material.Neon,false)
   deck.Transparency=1;deck.CanTouch=false
   table.insert(bridge,deck)
   -- Wide permanent corner landings join the two directions.
   if i==count and segment<#waypoints-1 then
    block("Corner_"..stage.."_"..segment,Vector3.new(7,1,7),CFrame.new(pos),gold,Enum.Material.SmoothPlastic,true)
   end
  end
 end
 local active=false
 RunService.Heartbeat:Connect(function()
  local held=false
  for _,p in ipairs(Players:GetPlayers()) do
   local char=p.Character
   local root=char and char:FindFirstChild("HumanoidRootPart")
   local hum=char and char:FindFirstChildOfClass("Humanoid")
   if root and root:IsA("BasePart") and hum and hum.Health>0 and not prison[p] then
    local q=control.CFrame:PointToObjectSpace(root.Position)
    if math.abs(q.X)<=2.5 and math.abs(q.Z)<=2.5 and q.Y>=1 and q.Y<=5 and hum.FloorMaterial~=Enum.Material.Air then held=true;break end
   end
  end
  if held~=active then
   active=held
   control.Color=active and green or Color3.fromRGB(235,65,80)
   for _,deck in ipairs(bridge) do
    deck.CanCollide=active;deck.Transparency=active and .1 or 1
   end
  end
 end)
 prankSign(block("BetrayalSign_"..stage,Vector3.new(1,1,1),CFrame.new(center+Vector3.new(4,0,0)),gold,Enum.Material.SmoothPlastic,false),"TRUST A FRIEND... OR JUMP THE GOLD STUDS")
end
-- FINAL BOSS: no checkpoint, four ordered gates, fixed geometry.
local function finalBoss(center)
 local gold=Color3.fromRGB(255,200,64)
 local dark=Color3.fromRGB(44,38,60)
 local needle=Color3.fromRGB(255,93,125)
 local function platform(name,pos,size,color)
  return block(name,size,CFrame.new(pos),color,Enum.Material.SmoothPlastic,true)
 end
 local function gate(index,pos,label)
  local pad=platform("BossGate_"..index,pos,Vector3.new(4,1,4),gold)
  prankSign(pad,label)
  pad.Touched:Connect(function(hit)
   local p=playerOf(hit)
   local stats=p and p:FindFirstChild("leaderstats")
   local stage=stats and stats:FindFirstChild("Stage")
   if stage and stage.Value==STAGES and (bossProgress[p] or 0)==index-1 then
    bossProgress[p]=index
    message(p,"Boss section "..index.." / 4 cleared. NOT a checkpoint!")
   end
  end)
  return pad
 end
 local function P(x,y,z) return center+Vector3.new(x,y,z) end
 -- 12 one-stud landings, 6.5-7 studs center to center, low rise.
 prankSign(platform("BossEntrance",P(5,0,0),Vector3.new(3,1,3),dark),"FINAL EXAM - NO CHECKPOINTS")
 for i=1,12 do
  platform("BossNeedleA_"..i,P(5+i*6.6,i*.35,(i%2)*1.2),Vector3.new(1,1,1),needle)
 end
 gate(1,P(91,4.5,0),"1/4 - WALL WRAPS NEXT")
 -- Alternating 4/5-stud barriers: tall enough that jumping over is not the route.
 -- Wide landing pads allow takeoff from the side, then steer around the wall.
 for i=1,8 do
  local z=i*5.5
  local y=4.5+i*.65
  local width=i%2==0 and 5 or 4
  local wallX=91+(i%2==0 and -.25 or .25)
  platform("BossWrapLanding_"..i,P(91,y,z),Vector3.new(3.5,1,3.1),gold)
  block("BossWrapWall_"..i,Vector3.new(width,12,.65),CFrame.new(P(wallX,y+5.4,z-2.75)),dark,Enum.Material.SmoothPlastic,true)
 end
 gate(2,P(91,10,49.5),"2/4 - NEEDLE MARATHON")
 -- Return along a separate elevated leg, 13 tiny landings.
 for i=1,13 do
  platform("BossNeedleB_"..i,P(91-i*6.5,10+i*.65,49.5+(i%2)*1.2),Vector3.new(1,1,1),needle)
 end
 gate(3,P(0,19,49.5),"3/4 - FINAL WRAPS")
 for i=1,7 do
  local z=49.5-i*5.5
  local y=19+i*1.05
  local width=i%2==0 and 5 or 4
  platform("BossFinalLanding_"..i,P(0,y,z),Vector3.new(3.5,1,3.1),gold)
  block("BossFinalWall_"..i,Vector3.new(width,12,.65),CFrame.new(P((i%2==0 and -.25 or .25),y+5.4,z+2.75)),dark,Enum.Material.SmoothPlastic,true)
 end
 gate(4,P(0,27.5,5.5),"4/4 - JUMP TO FINISH")
end
-- 2.1: Six extended skill gauntlets. No extra checkpoints.
local gauntletFloors={[5]=1,[15]=2,[25]=3,[35]=4,[45]=5,[55]=6}
stageNames[5]="Laser Switchback"
stageNames[15]="Needle Marathon"
stageNames[25]="Balance Labyrinth"
stageNames[35]="Wall Wrap Academy"
stageNames[45]="Ghost Forks"
stageNames[55]="Collapsing Nightmare"
local function gauntlet(stage,center,color,kind)
 local direction=stage%4==1 and 1 or -1
 local corners={Vector3.zero,Vector3.new(24,0,0),Vector3.new(24,0,24*direction),Vector3.new(0,0,24*direction),Vector3.zero}
 local function point(i)
  local segment=math.min(4,math.floor(i/4)+1)
  local t=(i-(segment-1)*4)/4
  return center+corners[segment]:Lerp(corners[segment+1],t)+Vector3.new(0,i*STAGE_LENGTH/16,0)
 end
 local gold=Color3.fromRGB(255,213,80)
 local dark=Color3.fromRGB(41,32,60)
 for i=1,15 do
  local pos=point(i)
  local nextPos=point(i+1)
  local flat=Vector3.new(nextPos.X-pos.X,0,nextPos.Z-pos.Z)
  local cf=CFrame.lookAt(pos,pos+flat)
  local corner=i%4==0
  local size=corner and Vector3.new(5,1,5) or Vector3.new(2.8,1,2.8)
  if kind==1 and not corner then size=Vector3.new(4,1,3.5) end
  if kind==2 and not corner then size=Vector3.new(1,1,1) end
  if kind==3 and not corner then size=Vector3.new(1.35,1,4.5) end
  if kind==4 then size=corner and Vector3.new(5,1,5) or Vector3.new(3.8,1,3.8) end
  if kind==5 and not corner then size=Vector3.new(2.4,1,2.4) end
  if kind==6 and not corner then size=Vector3.new(2.3,1,2.3) end
  local pad=block("Gauntlet_"..stage.."_"..i,size,cf,corner and gold or color,Enum.Material.SmoothPlastic,true)
  if i==1 then prankSign(pad,stageNames[stage].." - NO SAVE") end
  if kind==1 and corner then
   local a=pos-cf.RightVector*2+Vector3.new(0,1.05,0)
   local b=pos+cf.RightVector*2+Vector3.new(0,1.05,0)
   local beam=secretHazard(a,Vector3.new(.45,.5,2),true)
   TweenService:Create(beam,TweenInfo.new(1.3,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1,true),{Position=b}):Play()
  elseif kind==4 and i%4==1 then
   local middle=pos:Lerp(nextPos,.5)
   local width=math.floor(i/4)%2==0 and 4 or 5
   block("GauntletWrap_"..stage.."_"..i,Vector3.new(width,11,.5),CFrame.lookAt(middle+Vector3.new(0,4.5,0),middle+Vector3.new(0,4.5,0)+flat),dark,Enum.Material.SmoothPlastic,true)
  elseif kind==5 and i%4==2 then
   local fake=fakeFloor(pos+cf.RightVector*4.5,size,color)
   prankSign(fake,"EASY ROUTE")
   local other=fakeFloor(pos-cf.RightVector*4.5,size,color)
   prankSign(other,"TRUST ME")
  elseif kind==6 and not corner then
   vanishingPad(pad)
  end
  if corner then coinPad(pos+Vector3.new(0,2.5,0),stage,i) end
 end
end
for stage=1,STAGES+1 do
 local center=stagePos(stage)
 local color=palette[(stage-1)%#palette+1]
 local isSaved=savedFloor(stage)==stage
 local checkpoint=block((isSaved and "Checkpoint_" or "FloorMarker_")..stage,Vector3.new(7,1.3,7),CFrame.new(center),color,Enum.Material.SmoothPlastic,true)
 checkpoints[stage]=checkpoint
 neonText(checkpoint,stage<=STAGES and ((isSaved and "CHECKPOINT " or "FLOOR ")..stage.." — "..stageNames[stage]) or "TOWER CHAMPION!")
 if isSaved then checkpoint.Material=Enum.Material.Neon;checkpointTheme(center,stage,color) end
 checkpoint.Touched:Connect(function(hit)
  local p=playerOf(hit)
  if p and not prison[p] then awardCheckpoint(p,stage) end
 end)
 if stage==1 then
  local spawn=Instance.new("SpawnLocation")
  spawn.Name="RainbowRushSpawn";spawn.Size=Vector3.new(7,.5,7)
  spawn.Position=center+Vector3.new(0,.9,0);spawn.Anchored=true;spawn.Neutral=true
  spawn.CanCollide=true;spawn.Transparency=.35;spawn.Parent=mapFolder
 elseif stage==STAGES+1 then
  sparkles(checkpoint,color);finishPodium(center)
 end
 if stage==STAGES then
  finalBoss(center)
 elseif stage<=STAGES and betrayalFloors[stage] then
  betrayalCourse(stage,center,color)
 elseif stage<=STAGES and gauntletFloors[stage] then
  gauntlet(stage,center,color,gauntletFloors[stage])
 elseif stage<=STAGES then
  local mode=(stage-1)%6
  for step=1,11 do
   local pos=towerPoint(stage,step)
   local side=Vector3.new(pos.X,0,pos.Z).Unit
   local width=stage<=10 and 3.8 or (stage<=30 and 3.2 or 2.5)
   -- Extra wide timing platforms provide space to dodge hazards.
   if step==5 and mode==3 then width=4.5 end
   local nextPos=towerPoint(stage,step+1)
   local flat=Vector3.new(nextPos.X-pos.X,0,nextPos.Z-pos.Z)
   local facing=CFrame.lookAt(pos,pos+flat)
   local size=Vector3.new(width,1.1,width)
   -- Distinct obstacle geometry, not merely a different color.
   if mode==0 and (step==5 or step==8) then size=Vector3.new(1.5,1.1,5) end
   if mode==1 and (step==5 or step==8) then size=Vector3.new(2.2,1.1,3.6) end
   if mode==2 and step==6 then size=Vector3.new(4.8,1.1,4.8) end
   if mode==4 and step==3 then size=Vector3.new(1.8,1.1,4.5) end
   if mode==4 and step==8 then size=Vector3.new(5.2,1.1,4.5) end
   if stage>=12 and stage%5==2 and (step==3 or step==7 or step==9) then size=Vector3.new(1,1.1,1) end
   if stage%5==4 and (step==3 or step==7) then size=Vector3.new(1.35,1.1,5.2) end
   local pad=block("RainbowPlatform_"..stage.."_"..step,size,facing,color,Enum.Material.SmoothPlastic,true)
   if mode==1 and (step==5 or step==8) then
    local shift=side*1.15
    TweenService:Create(pad,TweenInfo.new(1.6,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Position=pos+shift}):Play()
   elseif mode==2 and step==6 then
    -- Jump over a visible bar before making the next jump.
    local bar=block("LowHurdle_"..stage,Vector3.new(4.8,.6,.45),facing*CFrame.new(0,1.05,0),Color3.fromRGB(255,70,95),Enum.Material.Neon,false)
    movingHarm(bar)
   elseif mode==4 and step==8 then
    -- Wall wrap: a short wall blocks the direct landing line; both edges are open.
    local wall=block("WrapWall_"..stage,Vector3.new(.65,3.2,1.8),facing*CFrame.new(0,2.05,0),Color3.fromRGB(39,40,64),Enum.Material.SmoothPlastic,true)
   elseif mode==5 and step==4 then
    -- Two tempting decoys flanking the actual path, consistent on every attempt.
    local left=fakeFloor(pos+facing.RightVector*4,Vector3.new(2.8,1.1,3),color)
    local right=fakeFloor(pos-facing.RightVector*4,Vector3.new(2.8,1.1,3),color)
    prankSign(left,"100% SAFE")
   end
   -- Fixed timing challenge: the platform is stationary, the beam moves.
   if stage>=11 and step==2 and stage%2==0 then
    local beam=secretHazard(pos+Vector3.new(-width/2,1.1,0),Vector3.new(.35,.45,width),true)
    TweenService:Create(beam,TweenInfo.new(1.1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1,true),{Position=pos+Vector3.new(width/2,1.1,0)}):Play()
   end
   -- A second collapsing landing, with a short learnable reaction window.
   if stage>=31 and step==10 and mode~=2 then vanishingPad(pad) end
   if stage==3 and step==3 then
    prankSign(pad,"JUMP!")
    local trigger=block("JumpTrap",Vector3.new(width+1,3,width+1),CFrame.new(pos+Vector3.new(0,5,0)),white,Enum.Material.SmoothPlastic,false)
    trigger.Transparency=1
    trigger.Touched:Connect(function(hit)
     local p=playerOf(hit);if not p then return end
     local stats=p:FindFirstChild("leaderstats");local st=stats and stats:FindFirstChild("Stage")
     local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
     if st and st.Value==stage and root and root:IsA("BasePart") and root.Position.Y>pos.Y+3.5 and root.AssemblyLinearVelocity.Y>2 then enterPrison(p) end
    end)
   elseif mode==0 and step==4 then
    local ghost=fakeFloor(pos+side*(width+1),pad.Size,color)
    prankSign(ghost,"EASY WAY")
   elseif mode==1 and step==4 then
    baitPad(stage,step,pos+side*(width+3),"fake_coin","FREE COINS!")
   elseif mode==2 and (step==4 or step==8) then
    vanishingPad(pad)
   elseif mode==3 and step==5 then
    spinner(pos+Vector3.new(0,1.5,0),stage)
   elseif mode==4 and step==6 then
    -- A hidden outer edge, leaving the inner half safe.
    secretHazard(pos+side*(width*.38)+Vector3.new(0,1,0),Vector3.new(1.05,1.2,1.05),false)
   elseif mode==5 and step==7 then
    local fake=baitPad(stage,step,pos+side*(width+3),"fake_finish","CHECKPOINT!")
    fake.Color=color
   end
   -- New optional bait and learnable precision hazards. No random launch effects.
   if stage%7==0 and step==6 then
    local decoy=fakeFloor(pos+side*5,Vector3.new(3,1.1,3),pad.Color)
    prankSign(decoy,"DEFINITELY SOLID")
   end
   if stage%7==3 and step==7 then
    local decoy=block("FakeRest_"..stage,Vector3.new(3,1,3),CFrame.new(pos+side*5),color,Enum.Material.SmoothPlastic,true)
    prankSign(decoy,"AFK SAFE ZONE")
    prankTarget(decoy,"fake_finish")
   end
   -- A timed side-to-side hurdle, with space to wait on either end.
   if stage%6==0 and step==5 then
    pad.Size=Vector3.new(5,1.1,4.5)
    local start=pos+facing.RightVector*2+Vector3.new(0,1.15,0)
    local finish=pos-facing.RightVector*2+Vector3.new(0,1.15,0)
    local beam=secretHazard(start,Vector3.new(.45,.5,2.3),true)
    TweenService:Create(beam,TweenInfo.new(1.6,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1,true),{Position=finish}):Play()
   end
   if stage%5==4 and step==7 then
    local ghost=fakeFloor(pos+facing.RightVector*4,Vector3.new(3,1.1,5),color)
    prankSign(ghost,"EASY MODE")
   end
   if stage%5==2 and step==9 then prankSign(pad,"Please land responsibly.") end
   if step==2 or step==10 then coinPad(pos+Vector3.new(0,2.5,0),stage,step) end
   if step==9 and stage%5==0 then jokeTrap(pad,stage,step) end
  end
 end
end
-- Falling below your saved floor resets you, not the entire tower.
local fallClock=0
RunService.Heartbeat:Connect(function(dt)
 fallClock+=dt;if fallClock<.15 then return end;fallClock=0
 for _,p in ipairs(Players:GetPlayers()) do
  local char=p.Character
  local root=char and char:FindFirstChild("HumanoidRootPart")
  local h=char and char:FindFirstChildOfClass("Humanoid")
  local stats=p:FindFirstChild("leaderstats");local st=stats and stats:FindFirstChild("Stage")
  if root and h and st and h.Health>0 and not prison[p] and not flying[p] and not lounging[p] and root.Position.Y<stagePos(savedFloor(st.Value)).Y-8 then h.Health=0 end
 end
end)

local function applyTrail(player)
 if not(passOwnership[player] and (passOwnership[player].rainbow_trail or passOwnership[player].vip)) then return end
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 if not root or root:FindFirstChild("RainbowTrailA") then return end
 local a=Instance.new("Attachment");a.Name="RainbowTrailA";a.Position=Vector3.new(-.4,-1,0);a.Parent=root
 local b=Instance.new("Attachment");b.Name="RainbowTrailB";b.Position=Vector3.new(.4,-1,0);b.Parent=root
 local trail=Instance.new("Trail");trail.Name="RainbowCosmeticTrail"
 trail.Attachment0=a;trail.Attachment1=b;trail.Lifetime=.7
 trail.Color=passOwnership[player].vip and ColorSequence.new(Color3.fromRGB(255,190,30),Color3.fromRGB(255,245,150)) or ColorSequence.new(palette[1],palette[5])
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
 for name in pairs(GAME_PASSES) do player:SetAttribute("Own_"..name,owned[name]==true) end
end
local function applyBenefits(player)
 local owned=passOwnership[player] or {}
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if humanoid then
  local mode=powerMode[player] or "normal"
  local speed=(mode=="speed" and owned.speed) or (mode=="fusion" and owned.fusion)
  local gravity=(mode=="gravity" and owned.gravity) or (mode=="fusion" and owned.fusion)
  humanoid.WalkSpeed=speed and 24 or 16
  humanoid.UseJumpPower=true
  humanoid.JumpPower=gravity and 65 or 50
  if speed or gravity then raceEligible[player]=false end
  player:SetAttribute("PowerMode",mode)
 end
 if owned.vip and character and not character:FindFirstChild("RainbowVIPGlow") then
  local h=Instance.new("Highlight");h.Name="RainbowVIPGlow"
  h.FillColor=Color3.fromRGB(251,199,54)
  h.OutlineColor=Color3.fromRGB(255,240,130)
  h.FillTransparency=.62
  h.Parent=character
 end
 if owned.vip and character then
  local head=character:FindFirstChild("Head")
  if head and not head:FindFirstChild("VIPTag") then
   local tag=Instance.new("BillboardGui");tag.Name="VIPTag";tag.Size=UDim2.fromOffset(100,25);tag.StudsOffset=Vector3.new(0,2.8,0);tag.AlwaysOnTop=true;tag.Parent=head
   local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Text="VIP";label.Font=Enum.Font.GothamBlack;label.TextColor3=Color3.fromRGB(255,215,55);label.TextStrokeTransparency=.2;label.TextScaled=true;label.Parent=tag
  end
 end
 applyTrail(player)
end
-- All abilities are authorized on the server. The carpet is exploration only.
local ability=Instance.new("RemoteEvent");ability.Name="TowerAbility";ability.Parent=events
local lastAction={};local airState={}
local loungeCenter=Vector3.new(-110,18,0)
local lounge=block("VIPLounge",Vector3.new(42,2,42),CFrame.new(loungeCenter),Color3.fromRGB(255,197,60),Enum.Material.SmoothPlastic,true)
neonText(lounge,"VIP LOUNGE - RELAX")
for i=1,4 do
 local a=i*math.pi/2
 local seat=Instance.new("Seat");seat.Name="VIPSeat";seat.Size=Vector3.new(5,1,5);seat.Anchored=true;seat.Color=Color3.fromRGB(115,55,180);seat.Position=loungeCenter+Vector3.new(math.cos(a)*12,2,math.sin(a)*12);seat.Parent=mapFolder
end
stopSpecial=function(p)
 local state=flying[p]
 if state then
  if state.root.Parent then state.root.Anchored=false;state.root.AssemblyLinearVelocity=Vector3.zero end
  if state.carpet then state.carpet:Destroy() end
 end
 flying[p]=nil;lounging[p]=nil
 p:SetAttribute("CarpetFlying",false);p:SetAttribute("VIPLounge",false)
end
local function validCharacter(p)
 local char=p.Character;local h=char and char:FindFirstChildOfClass("Humanoid");local root=char and char:FindFirstChild("HumanoidRootPart")
 if h and root and root:IsA("BasePart") and h.Health>0 then return h,root end
end
local function returnSpecial(p)
 stopSpecial(p);returnToSavedFloor(p);applyBenefits(p)
end
ability.OnServerEvent:Connect(function(p,action,value)
 if type(action)~="string" or prison[p] then return end
 local owned=passOwnership[p] or {}
 local h,root=validCharacter(p);if not h then return end
 if action=="move" then
  local state=flying[p]
  if not state or typeof(value)~="Vector3" or value.X~=value.X or value.Y~=value.Y or value.Z~=value.Z or value.Magnitude>1.01 then return end
  if os.clock()-(state.inputAt or 0)<.045 then return end
  state.direction=value;state.inputAt=os.clock();return
 end
 if os.clock()-(lastAction[p] or -10)<.18 then return end
 lastAction[p]=os.clock()
 if action=="mode" then
  if value~="normal" and value~="speed" and value~="gravity" and value~="fusion" then return end
  if value~="normal" and not owned[value] then return end
  powerMode[p]=value;applyBenefits(p)
 elseif action=="double" and owned.double_jump and not flying[p] and not lounging[p] then
  local a=airState[p]
  if not a or a.root~=root or a.used or h.FloorMaterial~=Enum.Material.Air or os.clock()-a.since<.12 then return end
  a.used=true;raceEligible[p]=false
  local v=root.AssemblyLinearVelocity;root.AssemblyLinearVelocity=Vector3.new(v.X,46,v.Z)
 elseif action=="carpet" and owned.carpet then
  if flying[p] then returnSpecial(p);return end
  if lounging[p] then returnSpecial(p) end
  raceEligible[p]=false
  local carpet=Instance.new("Part");carpet.Name="MagicCarpet";carpet.Size=Vector3.new(5,.25,7);carpet.Color=Color3.fromRGB(145,40,220);carpet.Material=Enum.Material.Neon;carpet.Anchored=true;carpet.CanCollide=false;carpet.CanTouch=false;carpet.Parent=mapFolder
  root.Anchored=true;root.AssemblyLinearVelocity=Vector3.zero
  flying[p]={root=root,carpet=carpet,direction=Vector3.zero,inputAt=os.clock()};p:SetAttribute("CarpetFlying",true)
  message(p,"Carpet exploration: no checkpoints or wins. Exit returns to your save.")
 elseif action=="lounge" and owned.vip then
  if lounging[p] then returnSpecial(p);return end
  stopSpecial(p);lounging[p]=true;raceEligible[p]=false;p:SetAttribute("VIPLounge",true)
  root.CFrame=CFrame.new(loungeCenter+Vector3.new(0,5,0));root.AssemblyLinearVelocity=Vector3.zero
 end
end)
RunService.Heartbeat:Connect(function(dt)
 for _,p in ipairs(Players:GetPlayers()) do
  local h,root=validCharacter(p)
  if not h then stopSpecial(p);airState[p]=nil;continue end
  local a=airState[p]
  if h.FloorMaterial~=Enum.Material.Air then airState[p]={root=root,used=false,since=os.clock()}
  elseif not a or a.root~=root then airState[p]={root=root,used=false,since=os.clock()} end
  local state=flying[p]
  if state then
   if state.root~=root or prison[p] then stopSpecial(p) else
    local direction=os.clock()-state.inputAt<.5 and state.direction or Vector3.zero
    local v=root.Position+direction*32*math.min(dt,.1)
    v=Vector3.new(math.clamp(v.X,-160,160),math.clamp(v.Y,12,stagePos(STAGES+1).Y+20),math.clamp(v.Z,-160,160))
    root.CFrame=CFrame.new(v)*root.CFrame.Rotation;state.carpet.CFrame=root.CFrame*CFrame.new(0,-3,0)
   end
  elseif lounging[p] and (root.Position-loungeCenter).Magnitude>30 then
   root.CFrame=CFrame.new(loungeCenter+Vector3.new(0,5,0));root.AssemblyLinearVelocity=Vector3.zero
  end
 end
end)
if studio then
 local testPass=Instance.new("RemoteEvent");testPass.Name="StudioTestPasses";testPass.Parent=events
 testPass.OnServerEvent:Connect(function(p)
  if not RunService:IsStudio() then return end
  local owned=passOwnership[p] or {};local enable=not p:GetAttribute("StudioAllPasses")
  for k,id in pairs(GAME_PASSES) do owned[k]=enable and (id>0 or k=="slap");p:SetAttribute("Own_"..k,owned[k]) end
  passOwnership[p]=owned;p:SetAttribute("StudioAllPasses",enable);powerMode[p]="normal";if flying[p] or lounging[p] then returnSpecial(p) else applyBenefits(p) end
  if not enable and p.Character then
   local ch=p.Character;local root=ch:FindFirstChild("HumanoidRootPart");local head=ch:FindFirstChild("Head")
   for _,obj in ipairs({ch:FindFirstChild("RainbowVIPGlow"),head and head:FindFirstChild("VIPTag"),root and root:FindFirstChild("RainbowCosmeticTrail"),root and root:FindFirstChild("RainbowTrailA"),root and root:FindFirstChild("RainbowTrailB")}) do if obj then obj:Destroy() end end
  end
  message(p,enable and "All test passes enabled. Open ABILITIES." or "Test passes disabled.")
 end)
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
 if name=="skip_boss" then return 0,0 end
 if name=="coins_250" then return 0,250 end
 if name=="coins_1200" then return 0,1200 end
 if name=="skip_1" then return CHECKPOINT_INTERVAL,0 end
 if name=="skip_3" then return 3*CHECKPOINT_INTERVAL,0 end
 if name=="fireworks" or name=="chaos" then return 0,0 end
 return nil,nil
end
-- For permanent progress changes, mark each receipt exactly once in the same
-- DataStore transaction that awards the stage or coin balance.
-- The only configured product grants one durable boss-skip credit.
-- Redeeming a credit is a separate transaction, so delayed receipts cannot be lost.
local redeemBoss=Instance.new("RemoteEvent")
redeemBoss.Name="RedeemBossSkip";redeemBoss.Parent=events
local function liveData(p)
 return not studio and storeOkay and p:GetAttribute("TowerDataReady") and not dataBusy[p]
end
MarketplaceService.ProcessReceipt=function(receipt)
 if receipt.ProductId~=PRODUCTS.skip_boss then return Enum.ProductPurchaseDecision.NotProcessedYet end
 local p=Players:GetPlayerByUserId(receipt.PlayerId)
 if not p or not liveData(p) then return Enum.ProductPurchaseDecision.NotProcessedYet end
 dataBusy[p]=true
 local ok,result=pcall(function()
  return SAVE_STORE:UpdateAsync(tostring(p.UserId),function(old)
   old=type(old)=="table" and old or {}
   old.receipts=old.receipts or {}
   local id=tostring(receipt.PurchaseId)
   if not old.receipts[id] then
    old.bossCredits=(tonumber(old.bossCredits) or 0)+1
    old.receipts[id]=true
   end
   return old
  end)
 end)
 dataBusy[p]=nil
 if not ok or type(result)~="table" then return Enum.ProductPurchaseDecision.NotProcessedYet end
 if p.Parent then
  p:SetAttribute("BossSkipCredits",tonumber(result.bossCredits) or 0)
  message(p,"Boss skip credit saved! Redeem at floor 61.")
 end
 return Enum.ProductPurchaseDecision.PurchaseGranted
end
redeemBoss.OnServerEvent:Connect(function(p)
 if not liveData(p) or prison[p] then return end
 local stats=p:FindFirstChild("leaderstats")
 local st=stats and stats:FindFirstChild("Stage")
 local coin=stats and stats:FindFirstChild("Coins")
 local wins=stats and stats:FindFirstChild("Wins")
 if not st or not coin or not wins or st.Value~=STAGES then return end
 dataBusy[p]=true
 local granted=false
 local ok,result=pcall(function()
  return SAVE_STORE:UpdateAsync(tostring(p.UserId),function(old)
   granted=false
   if type(old)~="table" or (tonumber(old.bossCredits) or 0)<1 then return nil end
   old.bossCredits-=1
   old.stage=STAGES+1;old.coins=coin.Value;old.wins=wins.Value
   granted=true;return old
  end)
 end)
 if ok and granted and result and p.Parent then
  p:SetAttribute("BossSkipCredits",result.bossCredits)
  raceEligible[p]=false;raceStarted[p]=nil
  prison[p]=nil;p:SetAttribute("TrollPrison",false)
  st.Value=STAGES+1;teleport(p,STAGES+1)
  message(p,"Paid completion! No earned win or speedrun record.")
 end
 dataBusy[p]=nil
end)
-- Studio-only testing remote. No live server can expose it.
if studio then
 local test=Instance.new("RemoteEvent");test.Name="StudioTestFloor";test.Parent=events
 test.OnServerEvent:Connect(function(p,n)
  if not RunService:IsStudio() or type(n)~="number" or n~=n then return end
  local stats=p:FindFirstChild("leaderstats");local st=stats and stats:FindFirstChild("Stage")
  if not st then return end
  prison[p]=nil;p:SetAttribute("TrollPrison",false)
  st.Value=math.clamp(math.floor(n),1,STAGES);raceEligible[p]=false
  teleport(p,st.Value);message(p,"STUDIO TEST FLOOR "..st.Value)
 end)
end

local initialized=setmetatable({}, {__mode="k"})
local function initializePlayer(player)
 if initialized[player] or not player.Parent then return end
 initialized[player]=true
 local leaderstats=Instance.new("Folder");leaderstats.Name="leaderstats";leaderstats.Parent=player
 local stage=Instance.new("IntValue");stage.Name="Stage";stage.Value=1;stage.Parent=leaderstats
 local coin=Instance.new("IntValue");coin.Name="Coins";coin.Parent=leaderstats
 local wins=Instance.new("IntValue");wins.Name="Wins";wins.Parent=leaderstats
 local ok,data=pcall(function()return SAVE_STORE:GetAsync(tostring(player.UserId))end)
 if ok and type(data)=="table" then
  stage.Value=savedFloor(tonumber(data.stage) or 1)
  coin.Value=math.max(0,tonumber(data.coins) or 0)
  wins.Value=math.max(0,tonumber(data.wins) or 0)
  player:SetAttribute("BestTimeMs",math.max(0,math.floor(tonumber(data.best) or 0)))
 end
 player:SetAttribute("BossSkipCredits",ok and type(data)=="table" and (tonumber(data.bossCredits) or 0) or 0)
 player:SetAttribute("TowerDataReady",ok and storeOkay and not studio)
 if player:GetAttribute("BestTimeMs")==nil then player:SetAttribute("BestTimeMs",0) end
 player:SetAttribute("LastTimeMs",0)
 raceStarted[player]=workspace:GetServerTimeNow()
 raceEligible[player]=stage.Value==1
 player:SetAttribute("RunStartedAt",raceStarted[player])
 local function onSpawn(character)
  local root=character:WaitForChild("HumanoidRootPart",10)
  if root and player.Parent and player.Character==character then
   returnToSavedFloor(player)
   applyBenefits(player)
  end
 end
 player.CharacterAdded:Connect(onSpawn)
 if player.Character then task.spawn(onSpawn,player.Character) end
 if not studio then task.spawn(function() refreshPasses(player);if player.Parent then applyBenefits(player) end end) end
end
Players.PlayerAdded:Connect(initializePlayer)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(initializePlayer,p) end
Players.PlayerRemoving:Connect(function(player)
 save(player)
 prison[player]=nil;prisonDone[player]=nil
 touchCooldown[player]=nil
 stopSpecial(player);powerMode[player]=nil;airState[player]=nil;lastAction[player]=nil
 passOwnership[player]=nil
 freeBoostCooldown[player]=nil
 resetCooldown[player]=nil
 raceStarted[player]=nil
 raceEligible[player]=nil
end)
task.spawn(function()
 while task.wait(90) do
  for _,p in ipairs(Players:GetPlayers()) do task.spawn(save,p) end
 end
end)
game:BindToClose(function()
 for _,player in Players:GetPlayers() do save(player)end
end)

-- 2.0: Slap Glove. Server chooses nearby target; no client-supplied force.
do
 local remote=Instance.new("RemoteEvent")
 remote.Name="SlapGlove";remote.Parent=events
 local lastSlap=setmetatable({}, {__mode="k"})
 local shield=setmetatable({}, {__mode="k"})
 local function safe(p,root)
  if prison[p] or flying[p] or lounging[p] or root.Anchored then return true end
  local stats=p:FindFirstChild("leaderstats")
  local stage=stats and stats:FindFirstChild("Stage")
  if not stage or stage.Value>=STAGES+1 then return true end
  if root.Position.Y<30 then return true end
  for floor=11,51,10 do
   if (root.Position-stagePos(floor)).Magnitude<12 then return true end
  end
  return false
 end
 remote.OnServerEvent:Connect(function(p)
  local owned=passOwnership[p]
  if not owned or not owned.slap then return end
  if GAME_PASSES.slap==0 and not studio then return end
  local now=os.clock()
  if now-(lastSlap[p] or -100)<12 then return end
  lastSlap[p]=now
  local h,root=validCharacter(p)
  if not h or safe(p,root) then message(p,"No slapping in safe zones.");return end
  local target,targetRoot,best
  local forward=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
  for _,other in ipairs(Players:GetPlayers()) do
   if other~=p and now>=(shield[other] or 0) then
    local oh,oroot=validCharacter(other)
    if oh and not safe(other,oroot) then
     local d=oroot.Position-root.Position
     local flat=Vector3.new(d.X,0,d.Z)
     if d.Magnitude<=8 and math.abs(d.Y)<3.5 and flat.Magnitude>0.1 and forward:Dot(flat.Unit)>.25 then
      local params=RaycastParams.new()
      params.FilterType=Enum.RaycastFilterType.Exclude
      params.FilterDescendantsInstances={p.Character,other.Character}
      params.RespectCanCollide=true
      if not workspace:Raycast(root.Position,d,params) and (not best or d.Magnitude<best) then
       target,targetRoot,best=other,oroot,d.Magnitude
      end
     end
    end
   end
  end
  if not target then message(p,"SLAP MISSED! Face a nearby player.");return end
  shield[target]=now+25
  raceEligible[p]=false;raceEligible[target]=false
  local d=targetRoot.Position-root.Position
  local direction=Vector3.new(d.X,0,d.Z).Unit
  targetRoot:ApplyImpulse((direction*38+Vector3.new(0,19,0))*targetRoot.AssemblyMass)
  local impact=Instance.new("Part")
  impact.Name="BonkFlash";impact.Shape=Enum.PartType.Ball;impact.Size=Vector3.new(2,2,2);impact.CFrame=CFrame.new(targetRoot.Position)
  impact.Color=Color3.fromRGB(255,205,65);impact.Material=Enum.Material.Neon;impact.Anchored=true;impact.CanCollide=false;impact.CanTouch=false;impact.CanQuery=false;impact.Transparency=.35;impact.Parent=mapFolder
  TweenService:Create(impact,TweenInfo.new(.3),{Size=Vector3.new(7,7,7),Transparency=1}):Play()
  game:GetService("Debris"):AddItem(impact,.4)
  message(p,"BONK! Slap landed.")
  message(target,"BONK! You have 25 seconds of slap protection.")
 end)
 Players.PlayerAdded:Connect(function(p)
  shield[p]=os.clock()+8
  p.CharacterAdded:Connect(function() shield[p]=os.clock()+8 end)
 end)
 for _,p in ipairs(Players:GetPlayers()) do
  shield[p]=os.clock()+8
  p.CharacterAdded:Connect(function() shield[p]=os.clock()+8 end)
 end
end

events:SetAttribute("TowerVersion","2.2")
print("TOWER OF TROLLS 2.2 SERVER READY")

]====]
local clientSource=[====[
--!nonstrict
-- TOWER OF TROLLS 2.2. Put in StarterPlayerScripts.
-- Uses standard Roblox chat; no special commands.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local MarketplaceService=game:GetService("MarketplaceService")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")

local player=Players.LocalPlayer
local studio=RunService:IsStudio()
local UserInputService=game:GetService("UserInputService")
local events=ReplicatedStorage:WaitForChild("RainbowRushEvents")
local ability=events:WaitForChild("TowerAbility")
local messageEvent=events:WaitForChild("Message") :: RemoteEvent
local info=events:WaitForChild("PassInfo") :: RemoteFunction
local catalog=events:WaitForChild("ShopCatalog") :: RemoteFunction
local replay=events:WaitForChild("ReplayCourse") :: RemoteEvent
local practice=events:WaitForChild("PracticeBoost") :: RemoteEvent
local checkpointReset=events:WaitForChild("ResetCheckpoint") :: RemoteEvent
local playerGui=player:WaitForChild("PlayerGui")
-- A persistent HUD must be owned by a persistent PlayerScripts controller.
if not script:IsDescendantOf(player:WaitForChild("PlayerScripts")) then warn("Move Tower client into StarterPlayerScripts, not StarterCharacterScripts.");return end
for _,name in ipairs({"RainbowRushHUD","TrollPrisonUI"}) do local old=playerGui:FindFirstChild(name);if old then old:Destroy() end end
local gui=Instance.new("ScreenGui")
gui.Name="RainbowRushHUD"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=false
gui.DisplayOrder=10
gui.Parent=player:WaitForChild("PlayerGui")

local function label(name:string,txt:string,pos:UDim2,size:UDim2,textSize:number):TextLabel
 local element=Instance.new("TextLabel")
 element.Name=name;element.Text=txt;element.Position=pos;element.Size=size
 element.Font=Enum.Font.GothamBold;element.TextSize=textSize;element.TextWrapped=true
 element.TextColor3=Color3.fromRGB(255,255,255)
 element.TextStrokeTransparency=.55
 element.BackgroundColor3=Color3.fromRGB(23,31,70)
 element.BackgroundTransparency=0;element.BorderSizePixel=0
 element.Parent=gui
 local round=Instance.new("UICorner");round.CornerRadius=UDim.new(0,12);round.Parent=element
 return element
end
local function stylePanel(target:GuiObject,c1:Color3,c2:Color3)
 target.BackgroundColor3=c1:Lerp(c2,.25)
 if target:IsA("TextLabel") or target:IsA("TextButton") then target.TextColor3=Color3.new(1,1,1);target.TextStrokeTransparency=1 end
 local stroke=Instance.new("UIStroke")
 stroke.Color=Color3.fromRGB(242,241,255)
 stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;stroke.Transparency=.65;stroke.Thickness=1.4;stroke.Parent=target
end
local stageNames={
 "The Floor Is Lying",
 "Free Coins",
 "Jump Prison",
 "Ghost Twins",
 "Laser Kitchen",
 "Vanishing Act",
 "Wrong Button",
 "Tiny Steps",
 "Fake Shortcut",
 "Spin Cycle",
 "Invisible Edge",
 "Almost There",
 "Trust Nobody",
 "Side Quest",
 "Moving Target",
 "False Hope",
 "Laser Laundry",
 "Thin Ice",
 "Wrong Door",
 "Ghost Town",
 "Precision Panic",
 "The Floor Quit",
 "Spin Doctor",
 "Fake Checkpoint",
 "Needle Walk",
 "No Refunds",
 "Laser Sandwich",
 "The Betrayal",
 "Sky Needles",
 "Halfway (Maybe)",
 "Floor Problems",
 "Ghost Factory",
 "The Long Way",
 "Moving Madness",
 "Tiny Trouble",
 "Double Trouble",
 "False Victory",
 "Laser Ballet",
 "Disappearing Steps",
 "Wrong Turn",
 "No Easy Mode",
 "The Narrow Road",
 "Spin Again",
 "Troll Toll",
 "Cloud Nine",
 "Invisible Ink",
 "The Final Exam",
 "Just One More",
 "Fake Ending",
 "Gravity Wins",
 "Needle Tower",
 "The Last Lie",
 "Ghost Elevator",
 "Laser Circus",
 "Trust Issues",
 "Final Final Exam",
 "Definitely Done",
 "Not Done",
 "Last Laugh",
 "Actually the End",
 "FINAL BOSS: THE IMPOSSIBLE EXAM"
}
stageNames[5]="Laser Switchback"
stageNames[15]="Needle Marathon"
stageNames[25]="Balance Labyrinth"
stageNames[35]="Wall Wrap Academy"
stageNames[45]="Ghost Forks"
stageNames[55]="Collapsing Nightmare"
local stageHints={}
for i=1,61 do stageHints[i]="Good luck." end
local function button(name:string,txt:string,pos:UDim2,size:UDim2):TextButton
 local element=Instance.new("TextButton")
 element.Name=name;element.Text=txt;element.Position=pos;element.Size=size
 element.Font=Enum.Font.GothamBlack;element.TextScaled=true;element.TextWrapped=true
 element.TextColor3=Color3.new(1,1,1)
 element.BackgroundColor3=Color3.fromRGB(117,58,204)
 element.BorderSizePixel=0;element.Parent=gui
 local round=Instance.new("UICorner");round.CornerRadius=UDim.new(0,12);round.Parent=element
 return element
end

local banner=label("GameTitle","😂 TOWER OF TROLLS 2.2",UDim2.new(.5,-178,0,7),UDim2.fromOffset(356,38),18)
banner.BackgroundColor3=Color3.fromRGB(91,44,159)
stylePanel(banner,Color3.fromRGB(94,48,204),Color3.fromRGB(211,68,173))
local progress=label("Progress","Floor 1 / 61",UDim2.new(.5,-112,0,49),UDim2.fromOffset(224,36),17)
stylePanel(progress,Color3.fromRGB(41,74,168),Color3.fromRGB(34,138,190))
local currency=label("Currency","🪙 Coins: 0   🏆 Wins: 0",UDim2.new(0,13,0,63),UDim2.fromOffset(226,36),14)
local timer=label("RaceTimer","⏱️ 00:00.0   🥇 BEST —",UDim2.new(.5,-145,0,131),UDim2.fromOffset(290,34),14)
timer.BackgroundColor3=Color3.fromRGB(34,59,105)
local stageTitle=label("StageTheme","STAGE 1 · ROOKIE RAINBOW",
 UDim2.new(.5,-165,0,174),UDim2.fromOffset(330,30),14)
stageTitle.BackgroundColor3=Color3.fromRGB(59,92,142)
stylePanel(stageTitle,Color3.fromRGB(46,104,178),Color3.fromRGB(91,62,167))
local progressBack=Instance.new("Frame")
progressBack.Name="ProgressBack"
progressBack.Position=UDim2.new(.5,-140,0,88)
progressBack.Size=UDim2.fromOffset(280,7)
progressBack.BackgroundColor3=Color3.fromRGB(45,40,93)
progressBack.BorderSizePixel=0;progressBack.Parent=gui
local progressFill=Instance.new("Frame")
progressFill.Name="ProgressFill";progressFill.Size=UDim2.fromScale(0,1)
progressFill.BackgroundColor3=Color3.fromRGB(92,251,188)
progressFill.BorderSizePixel=0;progressFill.Parent=progressBack
local instructions=label("Instructions","Trust nothing.",UDim2.new(.5,-195,0,102),UDim2.fromOffset(390,26),12)
local notification=label("Notification","",UDim2.new(.5,-190,0,212),UDim2.fromOffset(380,50),16)
notification.Visible=false
notification.BackgroundColor3=Color3.fromRGB(24,100,99)

local shop=button("CosmeticShop","🛒 SHOP",UDim2.new(0,13,0,107),UDim2.fromOffset(155,43))
local boost=button("PracticeBoost","⚡ BOOST · 40 COINS",UDim2.new(0,13,0,157),UDim2.fromOffset(155,43))
boost.BackgroundColor3=Color3.fromRGB(29,138,162)
boost.Activated:Connect(function()practice:FireServer()end)
local resetButton=button("ResetCheckpoint","📍 CHECKPOINT",UDim2.new(0,13,0,207),UDim2.fromOffset(155,42))
resetButton.BackgroundColor3=Color3.fromRGB(86,86,152)
resetButton.Activated:Connect(function()checkpointReset:FireServer()end)
local deaths=0
local deathLabel=label("Deaths","Deaths: 0",UDim2.fromOffset(13,257),UDim2.fromOffset(155,32),14)
local function watchDeath(character)
 local humanoid=character:WaitForChild("Humanoid",10)
 if humanoid and humanoid:IsA("Humanoid") then
  humanoid.Died:Connect(function()
   deaths+=1
   deathLabel.Text="Deaths: "..deaths
  end)
 end
end
player.CharacterAdded:Connect(watchDeath)
if player.Character then task.spawn(watchDeath,player.Character) end
local replayButton=button("ReplayCourse","🏁 REPLAY COURSE",UDim2.new(.5,-107,1,-74),UDim2.fromOffset(214,49))
replayButton.BackgroundColor3=Color3.fromRGB(63,163,119)
replayButton.Visible=false
replayButton.Activated:Connect(function()replay:FireServer()end)
shop.BackgroundColor3=Color3.fromRGB(81,137,205)
stylePanel(shop,Color3.fromRGB(51,115,220),Color3.fromRGB(120,72,207))
stylePanel(boost,Color3.fromRGB(20,183,172),Color3.fromRGB(30,111,186))
stylePanel(resetButton,Color3.fromRGB(88,89,174),Color3.fromRGB(124,81,156))
stylePanel(replayButton,Color3.fromRGB(44,182,132),Color3.fromRGB(48,125,208))
-- The shop lists actual Roblox Marketplace prices; IDs remain 0 until configured.
local fullShop=Instance.new("Frame")
fullShop.Name="ShopPanel";fullShop.AnchorPoint=Vector2.new(.5,.5)
fullShop.Position=UDim2.fromScale(.5,.5)
fullShop.Size=UDim2.new(.86,0,.8,0)
fullShop.BackgroundColor3=Color3.fromRGB(24,22,62)
fullShop.BorderSizePixel=0;fullShop.Visible=false;fullShop.Parent=gui;fullShop.ZIndex=20
stylePanel(fullShop,Color3.fromRGB(30,25,78),Color3.fromRGB(19,56,107))
local sizeLimit=Instance.new("UISizeConstraint")
sizeLimit.MaxSize=Vector2.new(620,640);sizeLimit.MinSize=Vector2.new(290,280)
sizeLimit.Parent=fullShop
local round=Instance.new("UICorner")
round.CornerRadius=UDim.new(0,18);round.Parent=fullShop
local header=Instance.new("TextLabel")
header.Text="😂 TROLL OBBY SHOP"
header.Size=UDim2.new(1,-92,0,49);header.Position=UDim2.fromOffset(14,7)
header.Font=Enum.Font.GothamBlack;header.TextScaled=true;header.TextColor3=Color3.fromRGB(255,222,125)
header.BackgroundTransparency=1;header.Parent=fullShop
local x=Instance.new("TextButton")
x.Text="✕";x.Size=UDim2.fromOffset(48,43);x.Position=UDim2.new(1,-58,0,8)
x.TextSize=25;x.Font=Enum.Font.GothamBold
x.BackgroundColor3=Color3.fromRGB(111,62,102);x.TextColor3=Color3.new(1,1,1)
x.Parent=fullShop
local xRound=Instance.new("UICorner");xRound.CornerRadius=UDim.new(0,9);xRound.Parent=x
local infoText=Instance.new("TextLabel")
infoText.Text="FREE TO PLAY · Paid upgrades are optional · Official Roblox checkout"
infoText.Size=UDim2.new(1,-18,0,36);infoText.Position=UDim2.fromOffset(9,56)
infoText.Font=Enum.Font.Gotham;infoText.TextSize=12
infoText.TextWrapped=true;infoText.BackgroundTransparency=1
infoText.TextColor3=Color3.fromRGB(211,234,255);infoText.Parent=fullShop
local scrolling=Instance.new("ScrollingFrame")
scrolling.Size=UDim2.new(1,-18,1,-103);scrolling.Position=UDim2.fromOffset(9,96)
scrolling.CanvasSize=UDim2.fromOffset(0,0);scrolling.ScrollBarThickness=6
scrolling.ScrollingDirection=Enum.ScrollingDirection.Y
scrolling.AutomaticCanvasSize=Enum.AutomaticSize.Y
scrolling.BackgroundTransparency=1;scrolling.BorderSizePixel=0;scrolling.Parent=fullShop
local list=Instance.new("UIListLayout")
list.Padding=UDim.new(0,7);list.Parent=scrolling
local rawCatalog=nil
local okCatalog,catalogData=pcall(function()return catalog:InvokeServer()end)
if okCatalog and typeof(catalogData)=="table" then rawCatalog=catalogData end
local passes=rawCatalog and rawCatalog.passes or {}
local products=rawCatalog and rawCatalog.products or {}
local offers={
 {"Slap Glove","slap","pass","Knock a nearby player backwards. 12-second cooldown; safe zones and victim protection."},
 {"FINAL BOSS SKIP","skip_boss","product","One credit: finish Floor 61 without an earned win."},
 {"Speed Coil","speed","pass","Toggle +50% running speed."},
 {"Gravity Coil","gravity","pass","Toggle +30% jump power."},
 {"Fusion Coil","fusion","pass","Toggle both coil abilities together."},
 {"Double Jump","double_jump","pass","Press jump again in midair."},
 {"VIP","vip","pass","Golden trail, name tag and VIP lounge."},
 {"Magic Carpet","carpet","pass","Explore in flight; exit returns to saved floor. No progress during flight."}
}
local function row(titleText:string,key:string,kind:string,detail:string)
 local holder=Instance.new("Frame")
 holder.Name=key;holder.Size=UDim2.new(1,-8,0,89)
 holder.BackgroundColor3=Color3.fromRGB(46,48,100);holder.BorderSizePixel=0;holder.Parent=scrolling
 local radius=Instance.new("UICorner");radius.CornerRadius=UDim.new(0,10);radius.Parent=holder
 local title=Instance.new("TextLabel")
 title.Size=UDim2.new(.60,0,0,28);title.Position=UDim2.fromOffset(10,5)
 title.BackgroundTransparency=1;title.TextXAlignment=Enum.TextXAlignment.Left
 title.Text=titleText;title.Font=Enum.Font.GothamBold;title.TextSize=15
 title.TextColor3=Color3.new(1,1,1);title.Parent=holder
 local explanation=Instance.new("TextLabel")
 explanation.Size=UDim2.new(.59,0,0,49);explanation.Position=UDim2.fromOffset(10,34)
 explanation.BackgroundTransparency=1;explanation.TextXAlignment=Enum.TextXAlignment.Left
 explanation.TextWrapped=true;explanation.Text=detail;explanation.Font=Enum.Font.Gotham
 explanation.TextSize=12;explanation.TextColor3=Color3.fromRGB(209,224,247);explanation.Parent=holder
 local buy=Instance.new("TextButton")
 buy.Size=UDim2.new(.35,-8,0,53);buy.Position=UDim2.new(.65,0,.5,-26)
 buy.BackgroundColor3=Color3.fromRGB(121,61,189);buy.BorderSizePixel=0
 buy.Font=Enum.Font.GothamBold;buy.TextScaled=true;buy.TextWrapped=true
 buy.TextColor3=Color3.new(1,1,1);buy.Parent=holder
 local buyRound=Instance.new("UICorner");buyRound.CornerRadius=UDim.new(0,8);buyRound.Parent=buy
 local id=(kind=="pass" and passes[key] or products[key]) or 0
 if typeof(id)~="number" or id<=0 then
  buy.Text="COMING SOON"
  buy.BackgroundColor3=Color3.fromRGB(77,77,98)
 else
  local price="VIEW PRICE"
  local function refresh()
   buy.BackgroundColor3=Color3.fromRGB(121,61,189)
   if kind=="pass" and player:GetAttribute("Own_"..key) then buy.Text="OWNED";buy.BackgroundColor3=Color3.fromRGB(43,125,80)
   elseif key=="skip_boss" and (player:GetAttribute("BossSkipCredits") or 0)>0 then buy.Text="REDEEM CREDIT"
   else buy.Text=price end
  end
  if kind=="pass" then player:GetAttributeChangedSignal("Own_"..key):Connect(refresh) end
  if key=="skip_boss" then player:GetAttributeChangedSignal("BossSkipCredits"):Connect(refresh) end
  refresh()
  task.spawn(function()
   local success,product=pcall(function()
    return MarketplaceService:GetProductInfo(id,kind=="pass" and Enum.InfoType.GamePass or Enum.InfoType.Product)
   end)
   if success and typeof(product)=="table" and typeof(product.PriceInRobux)=="number" then
    price=tostring(product.PriceInRobux).." ROBUX";refresh()
   end
  end)
  buy.Activated:Connect(function()
   if kind=="pass" and player:GetAttribute("Own_"..key) then return end
   if not studio and not (rawCatalog and rawCatalog.live) then notification.Text="Shop is being tested. Purchases disabled.";notification.Visible=true;task.delay(3,function() notification.Visible=false end);return end
   if studio then notification.Text="Studio test: real purchases disabled.";notification.Visible=true;task.delay(3,function() notification.Visible=false end);return end
   if key=="skip_boss" then
    local stats=player:FindFirstChild("leaderstats")
    local stage=stats and stats:FindFirstChild("Stage")
    if not stage or stage.Value~=61 or player:GetAttribute("TrollPrison") or not player:GetAttribute("TowerDataReady") then
     notification.Text="Boss skip is available at floor 61 when saving is online."
     notification.Visible=true
     task.delay(3,function() notification.Visible=false end)
     return
    end
    if (player:GetAttribute("BossSkipCredits") or 0)>0 then
     events:WaitForChild("RedeemBossSkip"):FireServer();return
    end
   end
   if key=="skip_1" or key=="skip_3" then
    local stats=player:FindFirstChild("leaderstats")
    local stage=stats and stats:FindFirstChild("Stage")
    if not stage or stage.Value>=51 then
     notification.Text="No checkpoint skips available beyond floor 51."
     notification.Visible=true
     task.delay(3,function() notification.Visible=false end)
     return
    end
   end
   local success=pcall(function()
    if kind=="pass" then
     MarketplaceService:PromptGamePassPurchase(player,id)
    else
     MarketplaceService:PromptProductPurchase(player,id)
    end
   end)
   if not success then
    notification.Text="Purchase couldn't open. Try again later."
    notification.Visible=true
    task.delay(3,function()notification.Visible=false end)
   end
  end)
 end
end
for _,offer in ipairs(offers) do row(offer[1],offer[2],offer[3],offer[4]) end
for _,obj in ipairs(fullShop:GetDescendants()) do if obj:IsA("GuiObject") then obj.ZIndex=21 end end
-- A compact abilities menu, separate from the purchase shop.
local powerButton=button("PowerMenu","ABILITIES",UDim2.fromOffset(13,295),UDim2.fromOffset(155,39))
local powers=Instance.new("Frame");powers.Name="Powers";powers.Size=UDim2.fromOffset(205,282);powers.Position=UDim2.fromOffset(175,100);powers.BackgroundColor3=Color3.fromRGB(25,30,58);powers.Visible=false;powers.Parent=gui
local powerList=Instance.new("UIListLayout");powerList.Padding=UDim.new(0,5);powerList.Parent=powers
local function powerRow(key,caption,action,value)
 local b=Instance.new("TextButton");b.Size=UDim2.new(1,0,0,35);b.TextColor3=Color3.new(1,1,1);b.BackgroundColor3=Color3.fromRGB(80,65,160);b.Font=Enum.Font.GothamBold;b.TextSize=14;b.Parent=powers
 local function update()
  local own=key=="normal" or player:GetAttribute("Own_"..key)==true
  b.Visible=own;b.Text=caption
  if action=="mode" and player:GetAttribute("PowerMode")==value then b.Text=caption.." [ON]" end
  if key=="carpet" and player:GetAttribute("CarpetFlying") then b.Text="EXIT CARPET" end
  if key=="vip" and player:GetAttribute("VIPLounge") then b.Text="EXIT VIP LOUNGE" end
 end
 b.Activated:Connect(function() ability:FireServer(action,value) end)
 for _,attr in ipairs({"Own_"..key,"PowerMode","CarpetFlying","VIPLounge"}) do player:GetAttributeChangedSignal(attr):Connect(update) end
 update()
end
powerRow("normal","Normal movement","mode","normal")
powerRow("speed","Speed Coil","mode","speed")
powerRow("gravity","Gravity Coil","mode","gravity")
powerRow("fusion","Fusion Coil","mode","fusion")
powerRow("carpet","Magic Carpet","carpet")
powerRow("vip","VIP Lounge","lounge")
powerButton.Activated:Connect(function() powers.Visible=not powers.Visible;fullShop.Visible=false end)
UserInputService.JumpRequest:Connect(function()
 if not player:GetAttribute("Own_double_jump") or player:GetAttribute("CarpetFlying") then return end
 local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 if h and h.FloorMaterial==Enum.Material.Air then ability:FireServer("double") end
end)
local up,down=false,false
local upButton=button("CarpetUp","UP",UDim2.new(1,-90,.5,-40),UDim2.fromOffset(75,45))
local downButton=button("CarpetDown","DOWN",UDim2.new(1,-90,.5,10),UDim2.fromOffset(75,45))
upButton.Visible=false;downButton.Visible=false
upButton.MouseButton1Down:Connect(function() up=true end);upButton.MouseButton1Up:Connect(function() up=false end)
downButton.MouseButton1Down:Connect(function() down=true end);downButton.MouseButton1Up:Connect(function() down=false end)
local function updateFlight() local on=player:GetAttribute("CarpetFlying")==true;upButton.Visible=on;downButton.Visible=on;up=false;down=false end
player:GetAttributeChangedSignal("CarpetFlying"):Connect(updateFlight);updateFlight()
local flightTick=0
RunService.RenderStepped:Connect(function(dt)
 if not player:GetAttribute("CarpetFlying") then return end
 flightTick+=dt;if flightTick<.1 then return end;flightTick=0
 local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid");if not h then return end
 local v=h.MoveDirection;local y=0
 if up or UserInputService:IsKeyDown(Enum.KeyCode.Space) then y+=1 end
 if down or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then y-=1 end
 v=Vector3.new(v.X,y,v.Z);if v.Magnitude>1 then v=v.Unit end
 ability:FireServer("move",v)
end)
if studio then
 local tester=events:WaitForChild("StudioTestPasses",5)
 if tester then local b=button("TestPowers","TEST ALL PASSES",UDim2.new(0,13,1,-55),UDim2.fromOffset(155,35));b.Activated:Connect(function() tester:FireServer() end) end
end
local bossShopButton=button("BossShopShortcut","FINAL BOSS SHOP",UDim2.new(1,-174,0,65),UDim2.fromOffset(160,42))
bossShopButton.Visible=false
bossShopButton.Activated:Connect(function() fullShop.Visible=true end)
shop.Text="🛒 SHOP · 8 ITEMS"
shop.Activated:Connect(function()fullShop.Visible=not fullShop.Visible;powers.Visible=false end)
x.Activated:Connect(function()fullShop.Visible=false end)

local function timeText(milliseconds:number):string
 local tenths=math.floor(milliseconds/100)%10
 local seconds=math.floor(milliseconds/1000)%60
 local minutes=math.floor(milliseconds/60000)
 return string.format("%02d:%02d.%d",minutes,seconds,tenths)
end
local function updateTimer()
 local started=player:GetAttribute("RunStartedAt")
 local lastTime=player:GetAttribute("LastTimeMs")
 local best=player:GetAttribute("BestTimeMs") or 0
 local stageStats=player:FindFirstChild("leaderstats")
 local stageValue=stageStats and stageStats:FindFirstChild("Stage")
 local finished=stageValue and stageValue:IsA("IntValue") and stageValue.Value>61
 local current=0
 if finished and type(lastTime)=="number" and lastTime>0 then
  current=lastTime
 elseif not finished and type(started)=="number" then
  current=math.max(0,(workspace:GetServerTimeNow()-started)*1000)
 end
 timer.Text="⏱️ "..timeText(current).."   🥇 BEST "..(best>0 and timeText(best) or "—")
end
local lastTimerUpdate=0
RunService.RenderStepped:Connect(function()
 if os.clock()-lastTimerUpdate>.1 then lastTimerUpdate=os.clock();updateTimer() end
end)
local stats=player:WaitForChild("leaderstats",30)
if stats then
 local stage=stats:WaitForChild("Stage",20)
 local coins=stats:WaitForChild("Coins",20)
 local wins=stats:WaitForChild("Wins",20)
 local function update()
  if stage and stage:IsA("IntValue") then
   progress.Text=stage.Value>61 and "🏆 ALL 61 FLOORS COMPLETE!" or ("☁️ Floor "..stage.Value.." / 61")
   replayButton.Visible=stage.Value>61
   bossShopButton.Visible=stage.Value==61
   local index=math.clamp(stage.Value,1,61)
   stageTitle.Text=stage.Value>61 and "🏆 CHAMPION · COURSE COMPLETE" or
    ("FLOOR "..index.." · "..string.upper(stageNames[index]))
   instructions.Text=stage.Value>61 and "Replay for a new record!" or
    (index>=51 and "Saved floor: 51 | Next: FINISH (no more checkpoints)" or ("Saved floor: "..(1+math.floor((index-1)/10)*10).." | Next: "..(11+math.floor((index-1)/10)*10)))
   local fraction=math.clamp((stage.Value-1)/61,0,1)
   TweenService:Create(progressFill,TweenInfo.new(.25),{Size=UDim2.fromScale(fraction,1)}):Play()
  end
  currency.Text="🪙 Coins: "..(coins and tostring(coins.Value) or "0").."    🏆 Wins: "..(wins and tostring(wins.Value) or "0")
 end
 for _,value in {stage,coins,wins} do
  if value and value:IsA("IntValue") then value.Changed:Connect(update) end
 end
 update()
end
local seq=0
messageEvent.OnClientEvent:Connect(function(msg:any)
 seq+=1;local current=seq
 notification.Text=tostring(msg):sub(1,160)
 notification.Visible=true
 TweenService:Create(notification,TweenInfo.new(.15),{BackgroundTransparency=.1}):Play()
 task.delay(3.2,function()if current==seq then notification.Visible=false end end)
end)

-- Text-only Rickroll prison interface.
local prisonPress=events:WaitForChild("PrisonPress")
local jail=Instance.new("ScreenGui")
jail.Name="TrollPrisonUI";jail.ResetOnSpawn=false;jail.DisplayOrder=200;jail.Enabled=false;jail.Parent=player:WaitForChild("PlayerGui")
local panel=Instance.new("Frame");panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5);panel.Size=UDim2.fromScale(.7,.46);panel.BackgroundColor3=Color3.fromRGB(25,25,30);panel.Parent=jail
local limit=Instance.new("UISizeConstraint");limit.MaxSize=Vector2.new(520,340);limit.Parent=panel
local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,16);corner.Parent=panel
local text=Instance.new("TextLabel");text.Size=UDim2.fromScale(.92,.56);text.Position=UDim2.fromScale(.04,.04);text.BackgroundTransparency=1;text.TextColor3=Color3.new(1,1,1);text.Font=Enum.Font.GothamBlack;text.TextScaled=true;text.TextWrapped=true;text.Parent=panel
local escape=Instance.new("TextButton");escape.Size=UDim2.fromScale(.86,.25);escape.Position=UDim2.fromScale(.07,.67);escape.BackgroundColor3=Color3.fromRGB(230,75,120);escape.TextColor3=Color3.new(1,1,1);escape.Font=Enum.Font.GothamBlack;escape.TextScaled=true;escape.Parent=panel
local lines={"YOU JUST GOT RICKROLLED!", "RICKROLLED AGAIN!", "Rickroll loading...", "That was another Rickroll.", "Halfway to freedom!", "Still here? Rickrolled!", "Seven Rickrolls. Impressive.", "The box says hello.", "One more Rickroll!", "RICKROLL COMPLETE!"}
local function updatePrison()
 local active=player:GetAttribute("TrollPrison")==true
 local count=player:GetAttribute("PrisonCount") or 0
 jail.Enabled=active
 gui.Enabled=not active
 text.Text=count==0 and "YOU GOT BOXED!\nPress 10 times to escape." or lines[math.clamp(count,1,10)]
 escape.Text="RICKROLL ME • "..count.." / 10"
end
escape.Activated:Connect(function() prisonPress:FireServer() end)
player:GetAttributeChangedSignal("TrollPrison"):Connect(updatePrison)
player:GetAttributeChangedSignal("PrisonCount"):Connect(updatePrison)
updatePrison()

-- Studio testing panel, absent in the published game.
if studio then
 local test=events:WaitForChild("StudioTestFloor",10)
 if test then
  local testBox=Instance.new("TextBox");testBox.Size=UDim2.fromOffset(100,35);testBox.Position=UDim2.new(1,-220,1,-50);testBox.Text="61";testBox.PlaceholderText="Floor 1-61";testBox.BackgroundColor3=Color3.fromRGB(35,40,65);testBox.TextColor3=Color3.new(1,1,1);testBox.TextSize=18;testBox.Parent=gui
  local go=button("StudioGo","TEST GO",UDim2.new(1,-112,1,-50),UDim2.fromOffset(100,35))
  go.Activated:Connect(function() local n=tonumber(testBox.Text);if n then test:FireServer(n) end end)
 end
end

-- 2.0: Slap action (mobile and desktop).
do
 local slap=events:WaitForChild("SlapGlove",10)
 if slap then
  local b=button("SlapAction","SLAP",UDim2.new(1,-125,1,-145),UDim2.fromOffset(110,45))
  local readyAt=0
  local function visibility()
   b.Visible=player:GetAttribute("Own_slap")==true and not player:GetAttribute("TrollPrison") and not player:GetAttribute("CarpetFlying") and not player:GetAttribute("VIPLounge")
  end
  for _,attr in ipairs({"Own_slap","TrollPrison","CarpetFlying","VIPLounge"}) do player:GetAttributeChangedSignal(attr):Connect(visibility) end
  visibility()
  local function doSlap()
   if not b.Visible or not gui.Enabled or os.clock()<readyAt then return end
   readyAt=os.clock()+12;slap:FireServer()
  end
  b.Activated:Connect(doSlap)
  UserInputService.InputBegan:Connect(function(input,processed) if not processed and input.KeyCode==Enum.KeyCode.F then doSlap() end end)
  task.spawn(function()
   while b.Parent do
    local left=math.ceil(readyAt-os.clock())
    b.Text=left>0 and ("SLAP "..left.."s") or "SLAP"
    task.wait(.2)
   end
  end)
 end
end

print("TOWER OF TROLLS 2.2 CLIENT READY")

]====]
local function isObby(obj)
 if not (obj:IsA("Script") or obj:IsA("LocalScript")) then return false end
 local ok,src=pcall(function() return obj.Source end)
 return ok and (string.find(src,"RainbowRushEvents",1,true) or string.find(src,"RainbowRushHUD",1,true) or string.find(src,"RainbowRushWorld",1,true))
end
local server=Instance.new("Script")
server.Name="TowerOfTrolls_22_Server"
server.Disabled=true
server.Source=serverSource
local client=Instance.new("LocalScript")
client.Name="TowerOfTrolls_22_Client"
client.Disabled=true
client.Source=clientSource
local count=0
for _,obj in ipairs(game:GetDescendants()) do
 if isObby(obj) then obj.Disabled=true;count+=1;print("Disabled old obby script: "..obj:GetFullName()) end
end
server.Parent=ss
client.Parent=ps
server.Disabled=false
client.Disabled=false
print("TOWER 2.2 INSTALLED. Disabled "..count.." old scripts. Press Play.")
