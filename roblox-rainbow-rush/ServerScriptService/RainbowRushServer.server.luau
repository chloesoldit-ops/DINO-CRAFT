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
local STAGES=12
local STAGE_LENGTH=70
local SAVE_STORE=DataStoreService:GetDataStore("RainbowRush_Progress_01")
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
passInfo.OnServerInvoke=function()return RAINBOW_TRAIL_PASS_ID end

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
  return {stage=math.max(old.stage or 1,data.stage),coins=math.max(old.coins or 0,data.coins),wins=math.max(old.wins or 0,data.wins)}
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
  coinStat.Value+=25
  message(player,"✅ CHECKPOINT "..stage.."! +25 free coins!")
  if stage==STAGES+1 then winStat.Value+=1;coinStat.Value+=200;message(player,"🏆 YOU WON! +200 BONUS COINS!") end
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
  if stat then stat.Value+=5;message(player,"🪙 +5 FREE COINS!") end
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

-- Wide checkpoints, then alternating jumps, thin beams, moving-looking obstacles.
for stage=1,STAGES+1 do
 local pos=stagePos(stage)
 local color=palette[(stage-1)%#palette+1]
 local platform=block("Checkpoint_"..stage,Vector3.new(24,2,20),CFrame.new(pos),color)
 neonText(platform,stage<=STAGES and ("🌈 STAGE "..stage) or "🏆 FINISH!")
 checkpoints[stage]=platform
 if stage==1 then
  local spawn=Instance.new("SpawnLocation")
  spawn.Name="RainbowRushSpawn";spawn.Size=Vector3.new(16,1,12)
  spawn.Position=pos+Vector3.new(0,1.5,0);spawn.Anchored=true
  spawn.Neutral=true;spawn.Color=Color3.fromRGB(80,240,195)
  spawn.Parent=mapFolder
 end
 platform.Touched:Connect(function(hit)
  local p=playerOf(hit);if p then awardCheckpoint(p,stage)end
 end)
 if stage<=STAGES then
  local difficulty=stage
  local startZ=pos.Z+14
  for jump=1,5 do
   local z=startZ+jump*9
   local x=math.sin(jump*1.65+stage)*math.min(10,3+difficulty*.65)
   local width=math.max(5.3,10-stage*.35)
   local pad=block("Jump_"..stage.."_"..jump,Vector3.new(width,1.4,7.2),
    CFrame.new(x,10,z),palette[(stage+jump-1)%#palette+1])
   if jump==2 or jump==4 then coinPad(Vector3.new(x,13,z),stage,jump)end
   if stage>=4 and jump==3 then
    local laser=block("RedDanger_"..stage,Vector3.new(width,.6,1.2),
     CFrame.new(x,10.9,z-1.7),Color3.fromRGB(255,40,64),Enum.Material.Neon,false)
    movingHarm(laser)
   end
  end
  local bridge=block("Bridge_"..stage,Vector3.new(10,1.3,9),
   CFrame.new(0,10,pos.Z+61),color)
 end
end
local void=block("VoidRespawn",Vector3.new(300,2,STAGES*STAGE_LENGTH+250),
 CFrame.new(0,-22,STAGES*STAGE_LENGTH/2),Color3.fromRGB(30,22,54))
void.Touched:Connect(function(hit)
 local p,h=playerOf(hit)
 if h then h.Health=0 end
end)
local lighting=game:GetService("Lighting")
lighting.ClockTime=14;lighting.Brightness=2.4
lighting.Ambient=Color3.fromRGB(190,185,230)
lighting.OutdoorAmbient=Color3.fromRGB(160,195,230)

local function applyTrail(player)
 if RAINBOW_TRAIL_PASS_ID<=0 then return end
 local ok,owned=pcall(function()return MarketplaceService:UserOwnsGamePassAsync(player.UserId,RAINBOW_TRAIL_PASS_ID)end)
 if not ok or not owned then return end
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 if not root or root:FindFirstChild("RainbowTrailA") then return end
 local a=Instance.new("Attachment");a.Name="RainbowTrailA";a.Position=Vector3.new(-.4,-1,0);a.Parent=root
 local b=Instance.new("Attachment");b.Name="RainbowTrailB";b.Position=Vector3.new(.4,-1,0);b.Parent=root
 local trail=Instance.new("Trail");trail.Name="RainbowCosmeticTrail"
 trail.Attachment0=a;trail.Attachment1=b;trail.Lifetime=.7
 trail.Color=ColorSequence.new(palette[1],palette[5])
 trail.LightEmission=1;trail.Parent=root
end
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player,id,purchased)
 if purchased and id==RAINBOW_TRAIL_PASS_ID then task.delay(1,applyTrail,player)end
end)
Players.PlayerAdded:Connect(function(player)
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
 player.CharacterAdded:Connect(function()
  task.wait(.3)
  teleport(player,stage.Value)
  applyTrail(player)
 end)
end)
Players.PlayerRemoving:Connect(function(player)save(player);touchCooldown[player]=nil end)
game:BindToClose(function()
 for _,player in Players:GetPlayers() do save(player)end
end)
