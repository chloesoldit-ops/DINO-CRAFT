--!strict
-- RAINBOW RUSH OBBY 0.1 — Standalone Roblox game
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
local productIndex={}
for name,id in pairs(PRODUCTS) do
 if id>0 then productIndex[id]=name end
end
local STAGES=12
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
  root.CFrame=CFrame.new(stagePos(stage)+Vector3.new(0,6,0))
 end
end
local function save(player)
 local stats=player:FindFirstChild("leaderstats")
 local stage=stats and stats:FindFirstChild("Stage")
 local points=stats and stats:FindFirstChild("Coins")
 local wins=stats and stats:FindFirstChild("Wins")
 if not (stage and points and wins) then return end
 local data={stage=stage.Value,coins=points.Value,wins=wins.Value}
 pcall(function()SAVE_STORE:UpdateAsync(tostring(player.UserId),function(old)
  old=type(old)=="table" and old or {}
  return {stage=math.max(old.stage or 1,data.stage),coins=math.max(old.coins or 0,data.coins),wins=math.max(old.wins or 0,data.wins),receipts=old.receipts or {}}
 end)end)
end
local function neonText(part,text)
 local gui=Instance.new("BillboardGui")
 gui.Adornee=part;gui.Size=UDim2.fromOffset(250,75)
 gui.StudsOffset=Vector3.new(0,5,0);gui.AlwaysOnTop=true;gui.Parent=part
 local label=Instance.new("TextLabel")
 label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1
 label.Text=text;label.TextScaled=true;label.Font=Enum.Font.GothamBlack
 label.TextColor3=Color3.new(1,1,1);label.TextStrokeTransparency=0;label.Parent=gui
end
local function awardCheckpoint(player,stage)
 local stats=player:FindFirstChild("leaderstats")
 local stageStat=stats and stats:FindFirstChild("Stage")
 local coinStat=stats and stats:FindFirstChild("Coins")
 local winStat=stats and stats:FindFirstChild("Wins")
 if not(stageStat and coinStat and winStat) then return end
 if stage==stageStat.Value+1 then
  stageStat.Value=stage
  coinStat.Value+=25*(passOwnership[player] and passOwnership[player].double_coins and 2 or 1)
  message(player,"✅ CHECKPOINT "..stage.."! +25 free coins!")
  if stage==STAGES+1 then winStat.Value+=1;coinStat.Value+=200*(passOwnership[player] and passOwnership[player].double_coins and 2 or 1);message(player,"🏆 YOU WON! BONUS COINS!") end
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
 pad.Touched:Connect(function(hit)
  local player=playerOf(hit)
  if not player then return end
  local now=os.clock()
  if now-(lastCollected[player.UserId] or 0)<25 then return end
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
 "Rookie Rainbow","Candy Hop","Zigzag Valley","Speedy Sprint",
 "Laser Lane","Vanishing Steps","Moving Clouds","Neon Tightrope",
 "Bouncy Galaxy","Spinner Storm","Cloud Kingdom","Rainbow Finale"
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
local routePoints={}
for stage=1,STAGES+1 do
 local center=stagePos(stage)
 local color=palette[(stage-1)%#palette+1]
 local checkpoint=floatingPart("Checkpoint_"..stage,Vector3.new(27,2.2,19),center,color,Enum.Material.SmoothPlastic,true)
 checkpoints[stage]=checkpoint
 local core=floatingPart("CheckpointCore_"..stage,Vector3.new(12,.4,9),center+Vector3.new(0,1.35,0),Color3.fromRGB(209,245,255),Enum.Material.Neon,false)
 core.Transparency=.22
 if stage==1 or stage==STAGES+1 then sparkles(core,color) end
 neonText(checkpoint,stage<=STAGES and ("STAGE "..stage.." — "..stageNames[stage]) or "🏆 RAINBOW CHAMPION!")
 checkpoint.Touched:Connect(function(hit)
  local p=playerOf(hit)
  if p then awardCheckpoint(p,stage) end
 end)
 if stage==1 then
  local spawn=Instance.new("SpawnLocation")
  spawn.Name="RainbowRushSpawn";spawn.Size=Vector3.new(11,1,8)
  spawn.Position=center+Vector3.new(0,2,0)
  spawn.Anchored=true;spawn.Neutral=true;spawn.CanCollide=true
  spawn.Transparency=.15
  spawn.Color=Color3.fromRGB(104,251,209);spawn.Material=Enum.Material.Neon
  spawn.Parent=mapFolder
 end
 -- Under each section, add distant cloud clusters as a sense of altitude.
 littleCloud(center+Vector3.new(-35,-13,30),1.2)
 littleCloud(center+Vector3.new(34,-17,50),.85)
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
   local width=(stage>=8 and 9 or 11)
   if stage==1 or stage==4 or stage==9 then width=13 end
   if stage==8 then width=6.8 end
   local pad=floatingPart("RainbowPlatform_"..stage.."_"..jump,
    Vector3.new(width,1.3,7.1),Vector3.new(x,10,z),
    palette[(stage+jump-1)%#palette+1],Enum.Material.SmoothPlastic,true)
   table.insert(points,{x=x,z=z,part=pad})
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
  if stage==12 then sparkles(endBridge,color) end
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
   return {stage=math.min(STAGES+1,currentStage+addStages),coins=currentCoins+addCoins,wins=currentWins,receipts=receipts}
  end)
 end)
 if not ok or type(result)~="table" then return Enum.ProductPurchaseDecision.NotProcessedYet end
 if not previousWasGranted then
  stage.Value=math.max(stage.Value,math.min(STAGES+1,tonumber(result.stage) or stage.Value))
  balance.Value=math.max(balance.Value,tonumber(result.coins) or balance.Value)
  if addStages>0 then teleport(player,stage.Value) end
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
 end
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
Players.PlayerRemoving:Connect(function(player)save(player);touchCooldown[player]=nil;passOwnership[player]=nil end)
game:BindToClose(function()
 for _,player in Players:GetPlayers() do save(player)end
end)
