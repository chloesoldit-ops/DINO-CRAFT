--!strict
-- RAINBOW RUSH OBBY 0.1 — Put this LocalScript in StarterPlayerScripts.
-- Uses standard Roblox chat; no special commands.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local MarketplaceService=game:GetService("MarketplaceService")
local TweenService=game:GetService("TweenService")

local player=Players.LocalPlayer
local events=ReplicatedStorage:WaitForChild("RainbowRushEvents")
local messageEvent=events:WaitForChild("Message") :: RemoteEvent
local info=events:WaitForChild("PassInfo") :: RemoteFunction
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

local banner=label("GameTitle","🌈 RAINBOW RUSH OBBY",UDim2.new(.5,-155,0,10),UDim2.fromOffset(310,44),20)
banner.BackgroundColor3=Color3.fromRGB(91,44,159)
local progress=label("Progress","Stage 1 / 12",UDim2.new(.5,-110,0,60),UDim2.fromOffset(220,40),18)
local currency=label("Currency","🪙 Coins: 0   🏆 Wins: 0",UDim2.new(0,12,0,12),UDim2.fromOffset(240,44),15)
local instructions=label("Instructions","Jump between colorful platforms. Touch checkpoints to save!",UDim2.new(.5,-188,0,104),UDim2.fromOffset(376,40),13)
local notification=label("Notification","",UDim2.new(.5,-190,0,152),UDim2.fromOffset(380,52),16)
notification.Visible=false
notification.BackgroundColor3=Color3.fromRGB(24,100,99)

local shop=button("CosmeticShop","✨ RAINBOW TRAIL",UDim2.new(1,-194,0,12),UDim2.fromOffset(181,48))
shop.BackgroundColor3=Color3.fromRGB(81,137,205)
local shopPanel=Instance.new("Frame")
shopPanel.Name="ShopPanel"
shopPanel.Position=UDim2.new(.5,-175,.5,-110)
shopPanel.Size=UDim2.fromOffset(350,220)
shopPanel.BackgroundColor3=Color3.fromRGB(30,30,72)
shopPanel.BorderSizePixel=0
shopPanel.Visible=false
shopPanel.Parent=gui
local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,18);corner.Parent=shopPanel
local title=Instance.new("TextLabel")
title.Size=UDim2.new(1,-24,0,45);title.Position=UDim2.fromOffset(12,9)
title.BackgroundTransparency=1;title.Text="✨ OPTIONAL COSMETIC"
title.Font=Enum.Font.GothamBlack;title.TextSize=21;title.TextColor3=Color3.fromRGB(255,231,143)
title.Parent=shopPanel
local desc=Instance.new("TextLabel")
desc.Size=UDim2.new(1,-24,0,60);desc.Position=UDim2.fromOffset(12,56)
desc.BackgroundTransparency=1;desc.TextWrapped=true
desc.Text="Rainbow Trail adds colorful particles as you run. It doesn't make you faster or help you win."
desc.Font=Enum.Font.Gotham;desc.TextSize=14;desc.TextColor3=Color3.new(1,1,1)
desc.Parent=shopPanel
local purchase=Instance.new("TextButton")
purchase.Name="Purchase"
purchase.Position=UDim2.fromOffset(15,125);purchase.Size=UDim2.fromOffset(320,40)
purchase.Text="🌈 RAINBOW TRAIL — NOT SET UP"
purchase.Font=Enum.Font.GothamBold;purchase.TextScaled=true;purchase.TextWrapped=true
purchase.TextColor3=Color3.new(1,1,1)
purchase.BackgroundColor3=Color3.fromRGB(115,70,192)
purchase.Parent=shopPanel
local purchaseCorner=Instance.new("UICorner");purchaseCorner.CornerRadius=UDim.new(0,9);purchaseCorner.Parent=purchase
local close=Instance.new("TextButton")
close.Name="Close";close.Position=UDim2.fromOffset(109,177);close.Size=UDim2.fromOffset(132,34)
close.Text="CLOSE";close.TextColor3=Color3.new(1,1,1)
close.Font=Enum.Font.GothamBold;close.TextSize=16
close.BackgroundColor3=Color3.fromRGB(74,91,135);close.Parent=shopPanel
local closeCorner=Instance.new("UICorner");closeCorner.CornerRadius=UDim.new(0,8);closeCorner.Parent=close
shop.Activated:Connect(function()shopPanel.Visible=not shopPanel.Visible end)
close.Activated:Connect(function()shopPanel.Visible=false end)

local passId=0
local ok,id=pcall(function()return info:InvokeServer()end)
if ok and typeof(id)=="number" and id>0 then
 passId=id
 purchase.Text="🌈 VIEW ROBLOX PRICE & BUY"
else
 purchase.Text="🌈 COMING SOON — FREE GAME"
 purchase.BackgroundColor3=Color3.fromRGB(71,79,106)
end
purchase.Activated:Connect(function()
 if passId==0 then
  notification.Text="Rainbow Trail is not available yet. You can play every stage for free!"
  notification.Visible=true
  task.delay(3,function()notification.Visible=false end)
  return
 end
 local success=pcall(function()
  MarketplaceService:PromptGamePassPurchase(player,passId)
 end)
 if not success then
  notification.Text="Roblox purchasing isn't available right now."
  notification.Visible=true
  task.delay(3,function()notification.Visible=false end)
 end
end)

local stats=player:WaitForChild("leaderstats",30)
if stats then
 local stage=stats:WaitForChild("Stage",20)
 local coins=stats:WaitForChild("Coins",20)
 local wins=stats:WaitForChild("Wins",20)
 local function update()
  if stage and stage:IsA("IntValue") then
   progress.Text=stage.Value>12 and "🏆 ALL 12 STAGES COMPLETE!" or ("🌈 Stage "..stage.Value.." / 12")
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
