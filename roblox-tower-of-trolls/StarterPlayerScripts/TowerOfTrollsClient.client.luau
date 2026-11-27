--!nonstrict
-- TOWER OF TROLLS 2.1. Put in StarterPlayerScripts.
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
if playerGui:FindFirstChild("RainbowRushHUD") then return end
local gui=Instance.new("ScreenGui")
gui.Name="RainbowRushHUD"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=false
gui.Parent=player:WaitForChild("PlayerGui")

local function label(name:string,txt:string,pos:UDim2,size:UDim2,textSize:number):TextLabel
 local element=Instance.new("TextLabel")
 element.Name=name;element.Text=txt;element.Position=pos;element.Size=size
 element.Font=Enum.Font.GothamBold;element.TextSize=textSize;element.TextWrapped=true
 element.TextColor3=Color3.fromRGB(255,255,255)
 element.TextStrokeTransparency=.55
 element.BackgroundColor3=Color3.fromRGB(23,31,70)
 element.BackgroundTransparency=.13;element.BorderSizePixel=0
 element.Parent=gui
 local round=Instance.new("UICorner");round.CornerRadius=UDim.new(0,12);round.Parent=element
 return element
end
local function stylePanel(target:GuiObject,c1:Color3,c2:Color3)
 local gradient=Instance.new("UIGradient")
 gradient.Color=ColorSequence.new(c1,c2)
 gradient.Rotation=30;gradient.Parent=target
 local stroke=Instance.new("UIStroke")
 stroke.Color=Color3.fromRGB(242,241,255)
 stroke.Transparency=.62;stroke.Thickness=1.7;stroke.Parent=target
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

local banner=label("GameTitle","😂 TOWER OF TROLLS 2.1",UDim2.new(.5,-178,0,7),UDim2.fromOffset(356,38),18)
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
fullShop.BorderSizePixel=0;fullShop.Visible=false;fullShop.Parent=gui
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
  buy.Text="VIEW PRICE"
  if kind=="pass" then
   local function markOwned() if player:GetAttribute("Own_"..key) then buy.Text="OWNED";buy.BackgroundColor3=Color3.fromRGB(43,125,80) end end
   player:GetAttributeChangedSignal("Own_"..key):Connect(markOwned);markOwned()
  end
  if key=="skip_boss" then
   local function creditText()
    if (player:GetAttribute("BossSkipCredits") or 0)>0 then buy.Text="REDEEM CREDIT" end
   end
   player:GetAttributeChangedSignal("BossSkipCredits"):Connect(creditText)
   creditText()
  end
  task.spawn(function()
   local success,product=pcall(function()
    return MarketplaceService:GetProductInfo(id,kind=="pass" and Enum.InfoType.GamePass or Enum.InfoType.Product)
   end)
   if success and typeof(product)=="table" and typeof(product.PriceInRobux)=="number" then
    if not (kind=="pass" and player:GetAttribute("Own_"..key)) and (key~="skip_boss" or (player:GetAttribute("BossSkipCredits") or 0)==0) then buy.Text=tostring(product.PriceInRobux).." ROBUX" end
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
powerButton.Activated:Connect(function() powers.Visible=not powers.Visible end)
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
shop.Text="🛒 SHOP · 7 ITEMS"
shop.Activated:Connect(function()fullShop.Visible=not fullShop.Visible end)
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
  b.Activated:Connect(function()
   if os.clock()<readyAt then return end
   readyAt=os.clock()+12
   slap:FireServer()
  end)
  task.spawn(function()
   while b.Parent do
    local left=math.ceil(readyAt-os.clock())
    b.Text=left>0 and ("SLAP "..left.."s") or "SLAP"
    task.wait(.2)
   end
  end)
 end
end
