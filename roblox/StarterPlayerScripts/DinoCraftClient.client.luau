--!strict
-- DinoCraft Roblox Edition 0.1
-- Paste into StarterPlayer > StarterPlayerScripts > LocalScript named DinoCraftClient.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local MarketplaceService=game:GetService("MarketplaceService")
local UserInputService=game:GetService("UserInputService")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
local mouse=player:GetMouse()
local events=ReplicatedStorage:WaitForChild("DinoCraftEvents")
local attackEvent=events:WaitForChild("Attack") :: RemoteEvent
local messageEvent=events:WaitForChild("Message") :: RemoteEvent
local productInfo=events:WaitForChild("FireworksInfo") :: RemoteFunction

local ui=Instance.new("ScreenGui")
ui.Name="DinoCraftHUD"
ui.IgnoreGuiInset=false
ui.ResetOnSpawn=false
ui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
ui.Parent=player:WaitForChild("PlayerGui")

local function text(parent:Instance,name:string,content:string,pos:UDim2,size:UDim2,fontsize:number,color:Color3):TextLabel
    local label=Instance.new("TextLabel")
    label.Name=name
    label.Text=content
    label.Position=pos
    label.Size=size
    label.TextSize=fontsize
    label.Font=Enum.Font.GothamBold
    label.TextColor3=color
    label.TextStrokeTransparency=.45
    label.TextWrapped=true
    label.BackgroundColor3=Color3.fromRGB(11,25,42)
    label.BackgroundTransparency=.12
    label.BorderSizePixel=0
    label.Parent=parent
    local corner=Instance.new("UICorner")
    corner.CornerRadius=UDim.new(0,10)
    corner.Parent=label
    return label
end
local function button(parent:Instance,name:string,content:string,pos:UDim2,size:UDim2,color:Color3):TextButton
    local b=Instance.new("TextButton")
    b.Name=name
    b.Text=content
    b.Position=pos
    b.Size=size
    b.TextScaled=true
    b.TextWrapped=true
    b.Font=Enum.Font.GothamBlack
    b.TextColor3=Color3.new(1,1,1)
    b.BackgroundColor3=color
    b.AutoButtonColor=true
    b.Parent=parent
    local corner=Instance.new("UICorner")
    corner.CornerRadius=UDim.new(0,12)
    corner.Parent=b
    return b
end

local title=text(ui,"Title","🦖 DINOCRAFT ROBLOX 0.1",UDim2.new(.5,-180,0,10),UDim2.fromOffset(360,42),20,Color3.fromRGB(153,255,198))
local waveLabel=text(ui,"Wave","⚔️ WAVE 0 — GET READY",UDim2.new(.5,-160,0,60),UDim2.fromOffset(320,37),16,Color3.fromRGB(255,224,150))
local help=text(ui,"Help","Click / tap ATTACK to hit dinosaurs  •  Survive waves with friends!",UDim2.new(.5,-210,0,105),UDim2.fromOffset(420,35),13,Color3.fromRGB(225,237,255))
local message=text(ui,"Announcement","",UDim2.new(.5,-210,0,151),UDim2.fromOffset(420,42),15,Color3.fromRGB(255,227,133))
message.Visible=false
local status=text(ui,"Status","DinoCoins and DinoKills appear in the Roblox leaderboard.",UDim2.new(0,12,1,-62),UDim2.fromOffset(340,46),13,Color3.fromRGB(211,243,255))
local attackButton=button(ui,"AttackButton","⚔️ ATTACK",UDim2.new(1,-167,1,-115),UDim2.fromOffset(155,85),Color3.fromRGB(178,57,47))
local shopButton=button(ui,"ShopButton","✨ COSMETIC SHOP",UDim2.new(1,-165,0,12),UDim2.fromOffset(155,45),Color3.fromRGB(61,117,160))
local shop=Instance.new("Frame")
shop.Name="Shop"
shop.Position=UDim2.new(.5,-195,.5,-145)
shop.Size=UDim2.fromOffset(390,290)
shop.BackgroundColor3=Color3.fromRGB(13,29,49)
shop.BorderSizePixel=0
shop.Visible=false
shop.Parent=ui
local shopCorner=Instance.new("UICorner")
shopCorner.CornerRadius=UDim.new(0,16)
shopCorner.Parent=shop
text(shop,"ShopTitle","✨ DINOCRAFT COSMETICS",UDim2.fromOffset(16,14),UDim2.fromOffset(355,40),19,Color3.fromRGB(160,255,227))
text(shop,"ShopInfo","Optional cosmetics only. All dinosaur fights are FREE.",UDim2.fromOffset(16,60),UDim2.fromOffset(355,48),14,Color3.fromRGB(227,240,255))
local robux=button(shop,"Fireworks","🎆 CELEBRATION FIREWORKS (ROBux)",UDim2.fromOffset(19,123),UDim2.fromOffset(352,56),Color3.fromRGB(125,70,164))
text(shop,"PurchaseNote","Price appears in the official Roblox purchase window. No purchase required.",UDim2.fromOffset(19,186),UDim2.fromOffset(352,39),12,Color3.fromRGB(219,234,255))
local close=button(shop,"Close","CLOSE",UDim2.fromOffset(115,237),UDim2.fromOffset(160,40),Color3.fromRGB(83,106,139))
shopButton.Activated:Connect(function()shop.Visible=not shop.Visible end)
close.Activated:Connect(function()shop.Visible=false end)

local lastAttack=0
local function findDinosaur():Model?
    local target=mouse.Target
    if not target then return nil end
    local model=target:FindFirstAncestorOfClass("Model")
    if not model or not model:IsDescendantOf(workspace) then return nil end
    if model.Parent and model.Parent.Name=="DinoCraftArena" and (model.Name=="Raptor" or model.Name=="Tyrant Rex") then
        return model
    end
    return nil
end
local function attack()
    if shop.Visible or os.clock()-lastAttack<.22 then return end
    lastAttack=os.clock()
    local model=findDinosaur()
    if model then
        attackEvent:FireServer(model)
        attackButton.BackgroundColor3=Color3.fromRGB(255,130,68)
        TweenService:Create(attackButton,TweenInfo.new(.23),{BackgroundColor3=Color3.fromRGB(178,57,47)}):Play()
    else
        status.Text="🎯 Aim at a dinosaur before attacking!"
    end
end
attackButton.Activated:Connect(attack)
UserInputService.InputBegan:Connect(function(input:InputObject,processed:boolean)
    if processed or shop.Visible then return end
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.KeyCode==Enum.KeyCode.F then
        attack()
    end
end)
local productId=0
local ok,value=pcall(function()return productInfo:InvokeServer() end)
if ok and typeof(value)=="number" then productId=value end
if productId<=0 then
    robux.Text="🎆 FIREWORKS — COMING SOON"
    robux.BackgroundColor3=Color3.fromRGB(73,78,98)
end
robux.Activated:Connect(function()
    if productId<=0 then
        status.Text="Robux product not enabled yet. Keep playing for FREE!"
        return
    end
    local success=pcall(function()
        MarketplaceService:PromptProductPurchase(player,productId)
    end)
    if not success then status.Text="Purchase unavailable. You can keep playing for free." end
end)

local messageSerial=0
messageEvent.OnClientEvent:Connect(function(content:any)
    messageSerial+=1
    local serial=messageSerial
    message.Text=tostring(content):sub(1,150)
    message.Visible=true
    task.delay(4,function()
        if serial==messageSerial then message.Visible=false end
    end)
end)
local function updateWave()
    waveLabel.Text="⚔️ WAVE "..tostring(ReplicatedStorage:GetAttribute("DinoCraftWave") or 0).." — SURVIVE!"
end
ReplicatedStorage:GetAttributeChangedSignal("DinoCraftWave"):Connect(updateWave)
updateWave()
