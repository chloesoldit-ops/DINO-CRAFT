--!strict
-- DinoCraft Roblox Edition 0.1
-- Paste into ServerScriptService > Script named DinoCraftServer.
-- Generates a free-to-play multiplayer arena; Roblox supplies player networking.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

-- OPTIONAL: replace 0 with your real Developer Product ID after creating it in Creator Hub.
-- The product is a cosmetic fireworks celebration, NOT stronger weapons or more damage.
local FIREWORK_PRODUCT_ID = 0
local MAX_DINOS = 12
local ATTACK_RANGE = 14
local ATTACK_DAMAGE = 24
local ATTACK_COOLDOWN = 0.55
local UPDATE_INTERVAL = 0.10

local events = ReplicatedStorage:FindFirstChild("DinoCraftEvents") or Instance.new("Folder")
events.Name = "DinoCraftEvents"
events.Parent = ReplicatedStorage
local attackEvent = events:FindFirstChild("Attack") or Instance.new("RemoteEvent")
attackEvent.Name = "Attack"
attackEvent.Parent = events
local gameMessage = events:FindFirstChild("Message") or Instance.new("RemoteEvent")
gameMessage.Name = "Message"
gameMessage.Parent = events
local fireworkRequest = events:FindFirstChild("FireworksInfo") or Instance.new("RemoteFunction")
fireworkRequest.Name = "FireworksInfo"
fireworkRequest.Parent = events
local cosmeticRequest=events:FindFirstChild("FreeCosmetic") or Instance.new("RemoteEvent")
cosmeticRequest.Name="FreeCosmetic"
cosmeticRequest.Parent=events
local duelToggle=events:FindFirstChild("DuelToggle") or Instance.new("RemoteEvent")
duelToggle.Name="DuelToggle"
duelToggle.Parent=events
local duelHit=events:FindFirstChild("DuelHit") or Instance.new("RemoteEvent")
duelHit.Name="DuelHit"
duelHit.Parent=events
fireworkRequest.OnServerInvoke = function(_player)
    return FIREWORK_PRODUCT_ID
end

local arena = Workspace:FindFirstChild("DinoCraftArena") or Instance.new("Folder")
arena.Name = "DinoCraftArena"
arena.Parent = Workspace
local dinosaurs = {}
local attackTimers = {}
local cosmeticCooldowns = {}
local duelCooldowns={}
local wave = 0
local nextWaveTime = 0
local phase = "waiting"
local tickAccumulator = 0
local coinStore = DataStoreService:GetDataStore("DinoCraftRobloxCoinsV1")
local receiptStore = DataStoreService:GetDataStore("DinoCraftRobloxReceiptsV1")

local function part(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, anchored: boolean): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Position = position
    p.Color = color
    p.Anchored = anchored
    p.CanCollide = true
    p.Material = Enum.Material.SmoothPlastic
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function sendAll(text: string)
    gameMessage:FireAllClients(text)
end

local function buildArena()
    if arena:FindFirstChild("ArenaFloor") then return end
    local floor = part(arena, "ArenaFloor", Vector3.new(170, 4, 170), Vector3.new(0, -3, 0), Color3.fromRGB(72, 113, 72), true)
    floor.Material = Enum.Material.Grass
    local wallColor = Color3.fromRGB(100, 91, 109)
    for _, wall in ipairs({
        {Vector3.new(170, 30, 6), Vector3.new(0, 12, -85)},
        {Vector3.new(170, 30, 6), Vector3.new(0, 12, 85)},
        {Vector3.new(6, 30, 170), Vector3.new(-85, 12, 0)},
        {Vector3.new(6, 30, 170), Vector3.new(85, 12, 0)},
    }) do
        local p = part(arena, "ArenaWall", wall[1], wall[2], wallColor, true)
        p.Material = Enum.Material.Slate
    end
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "DinoCraftSpawn"
    spawn.Size = Vector3.new(12, 1, 12)
    spawn.Position = Vector3.new(0, 1, 58)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Material = Enum.Material.Neon
    spawn.Color = Color3.fromRGB(70, 212, 181)
    spawn.Parent = arena
    for n = 1, 14 do
        local a = n * math.pi * 2 / 14
        local x, z = math.cos(a) * 72, math.sin(a) * 72
        local trunk = part(arena, "PalmTrunk", Vector3.new(3, 16, 3), Vector3.new(x, 7, z), Color3.fromRGB(100, 68, 47), true)
        trunk.Material = Enum.Material.Wood
        local foliage = part(arena, "PalmLeaves", Vector3.new(13, 8, 13), Vector3.new(x, 18, z), Color3.fromRGB(44, 149, 84), true)
        foliage.Shape = Enum.PartType.Ball
        foliage.CanCollide = false
    end
    local board = part(arena, "EntranceSign", Vector3.new(37, 8, 1), Vector3.new(0, 17, 67), Color3.fromRGB(16, 39, 65), true)
    board.CanCollide = false
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.Parent = board
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(240, 248, 255)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBlack
    label.Text = "DINOCRAFT ROBLOX\nSURVIVE THE DINOSAURS!"
    label.Parent = gui
end

local function makeDino(kind: string, position: Vector3, healthMultiplier: number)
    local rex = kind == "REX"
    local bodyColor = rex and Color3.fromRGB(157, 82, 57) or Color3.fromRGB(77, 152, 88)
    local model = Instance.new("Model")
    model.Name = kind == "REX" and "Tyrant Rex" or "Raptor"
    model.Parent = arena
    local y = position.Y
    local center = part(model, "Root", rex and Vector3.new(9, 7, 12) or Vector3.new(5, 4, 7), position, bodyColor, true)
    center.CanCollide = false
    model.PrimaryPart = center
    local head = part(model, "Head", rex and Vector3.new(6, 5, 6) or Vector3.new(3, 3, 4), position + Vector3.new(0, rex and 4.5 or 2.7, -5), bodyColor, true)
    head.CanCollide = false
    local jaw = part(model, "Jaw", rex and Vector3.new(5, 1.1, 6) or Vector3.new(2.5, 0.8, 3.5), position + Vector3.new(0, rex and 2.0 or 1.4, -5.4), Color3.fromRGB(211, 188, 147), true)
    jaw.CanCollide = false
    for side = -1, 1, 2 do
        local foot = part(model, "Claw", rex and Vector3.new(2.2, 5, 2.6) or Vector3.new(1.1, 3, 1.4), position + Vector3.new(side*(rex and 3 or 1.9), -(rex and 4 or 2.7), 2), bodyColor, true)
        foot.CanCollide = false
        local eye = part(model, "Eye", Vector3.new(.55, .55, .55), position + Vector3.new(side*(rex and 2.9 or 1.5), rex and 5.3 or 3.4, -7), Color3.fromRGB(248, 231, 93), true)
        eye.Shape = Enum.PartType.Ball
        eye.CanCollide = false
    end
    local tail = part(model, "Tail", rex and Vector3.new(3, 2.3, 8) or Vector3.new(1.6, 1.4, 6), position + Vector3.new(0, 0.3, rex and 8 or 5), bodyColor, true)
    tail.CanCollide = false
    local hp = math.floor((rex and 320 or 95)*healthMultiplier)
    local healthGui = Instance.new("BillboardGui")
    healthGui.Name = "DinoHealth"
    healthGui.Size = UDim2.new(0, 180, 0, 46)
    healthGui.StudsOffset = Vector3.new(0, rex and 10 or 6, 0)
    healthGui.AlwaysOnTop = true
    healthGui.Adornee = center
    healthGui.Parent = model
    local healthText = Instance.new("TextLabel")
    healthText.Size = UDim2.fromScale(1, 1)
    healthText.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
    healthText.BackgroundTransparency = .15
    healthText.TextColor3 = Color3.fromRGB(255, 240, 172)
    healthText.TextScaled = true
    healthText.Font = Enum.Font.GothamBold
    healthText.Parent = healthGui
    local entry = {model=model, root=center, hp=hp, maxHp=hp, speed=rex and 10 or 17, damage=rex and 22 or 9,
        reach=rex and 11 or 7, lastHit=0, kind=kind, healthText=healthText, phase=math.random()*10}
    dinosaurs[model] = entry
    healthText.Text = model.Name .. "  " .. hp .. "/" .. hp
end

local function awardKill(player: Player, kind: string)
    local stats = player:FindFirstChild("leaderstats")
    if not stats then return end
    local coins = stats:FindFirstChild("DinoCoins")
    local kills = stats:FindFirstChild("DinoKills")
    if coins and coins:IsA("IntValue") then coins.Value += (kind == "REX" and 75 or 15) end
    if kills and kills:IsA("IntValue") then kills.Value += 1 end
end

local function spawnWave()
    wave += 1
    ReplicatedStorage:SetAttribute("DinoCraftWave", wave)
    local amount = math.min(MAX_DINOS, 2 + math.floor(wave * .6))
    sendAll("WAVE " .. wave .. "! Fight " .. amount .. " dinosaurs!")
    for n = 1, amount do
        local angle = n * math.pi * 2 / amount
        local pos = Vector3.new(math.cos(angle)*38, 7, math.sin(angle)*38)
        local kind = ((wave % 5 == 0 and n == 1) or (wave > 8 and n % 6 == 0)) and "REX" or "RAPTOR"
        makeDino(kind, pos, 1 + math.min(2, wave * .09))
    end
    phase = "fighting"
end

attackEvent.OnServerEvent:Connect(function(player: Player, requestedTarget: Instance?)
    if typeof(requestedTarget) ~= "Instance" then return end
    local enemy = dinosaurs[requestedTarget]
    if not enemy or enemy.hp <= 0 or not enemy.model.Parent then return end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then return end
    local now = os.clock()
    if now - (attackTimers[player] or 0) < ATTACK_COOLDOWN then return end
    local delta = enemy.root.Position-root.Position
    if delta.Magnitude > ATTACK_RANGE then return end
    if delta.Magnitude > 0.01 and root.CFrame.LookVector:Dot(delta.Unit) < -.45 then return end
    attackTimers[player] = now
    enemy.hp = math.max(0, enemy.hp - ATTACK_DAMAGE)
    enemy.healthText.Text = enemy.model.Name .. "  " .. enemy.hp .. "/" .. enemy.maxHp
    if enemy.hp <= 0 then
        dinosaurs[enemy.model] = nil
        awardKill(player, enemy.kind)
        gameMessage:FireClient(player, "Dino defeated! You earned free DinoCoins.")
        enemy.model:Destroy()
    end
end)

local function nearestLivingPlayer(position: Vector3)
    local nearest: Player? = nil
    local distance = 1e9
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
            local d = (root.Position-position).Magnitude
            if d < distance and d < 110 then
                nearest = player
                distance = d
            end
        end
    end
    return nearest, distance
end

RunService.Heartbeat:Connect(function(dt)
    tickAccumulator += dt
    if tickAccumulator < UPDATE_INTERVAL then return end
    local step = math.min(tickAccumulator, .25)
    tickAccumulator = 0
    local now = os.clock()
    local alive = 0
    for model, d in pairs(dinosaurs) do
        if not model.Parent then dinosaurs[model] = nil
        else
            alive += 1
            local target, distance = nearestLivingPlayer(d.root.Position)
            if target and target.Character then
                local root = target.Character:FindFirstChild("HumanoidRootPart")
                local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
                if root and root:IsA("BasePart") and humanoid then
                    local delta = Vector3.new(root.Position.X-d.root.Position.X, 0, root.Position.Z-d.root.Position.Z)
                    if delta.Magnitude > d.reach*.65 and delta.Magnitude > 0.2 then
                        local direction = delta.Unit
                        local newPos = d.root.Position + direction*d.speed*step
                        newPos = Vector3.new(math.clamp(newPos.X, -76, 76), d.root.Position.Y, math.clamp(newPos.Z, -76, 76))
                        local toward = CFrame.lookAt(newPos, Vector3.new(root.Position.X,newPos.Y,root.Position.Z))
                        model:PivotTo(toward)
                    end
                    if distance < d.reach and now-d.lastHit >= (d.kind=="REX" and 1.6 or 1.15) then
                        d.lastHit = now
                        humanoid:TakeDamage(d.damage)
                    end
                end
            end
        end
    end
    if alive==0 then
        if phase=="fighting" then
            phase="intermission"
            nextWaveTime=now+10
            sendAll("Great job! Next dinosaur wave in 10 seconds.")
        elseif phase=="waiting" then
            phase="intermission"
            nextWaveTime=now+7
        elseif phase=="intermission" and now>=nextWaveTime then
            spawnWave()
        end
    end
end)

local function fireworks(player: Player)
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then return end
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "Celebration"
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Rate = 0
    emitter.Lifetime = NumberRange.new(1, 2)
    emitter.Speed = NumberRange.new(18, 33)
    emitter.SpreadAngle = Vector2.new(360, 360)
    emitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 61), Color3.fromRGB(63, 200, 255))
    emitter.Parent = root
    emitter:Emit(110)
    Debris:AddItem(emitter, 4)
    sendAll(player.DisplayName .. " launched celebration fireworks!")
end

-- Optional PvP duels: BOTH players must explicitly enable duels.
-- The server validates opponent identity, range, direction and attack cooldown.
duelToggle.OnServerEvent:Connect(function(player: Player)
    local enabled=not (player:GetAttribute("DinoDuel") == true)
    player:SetAttribute("DinoDuel",enabled)
    gameMessage:FireClient(player,enabled and "⚔️ Duels ON — other duelists can fight you!" or "🛡️ Duels OFF — other players cannot hurt you.")
end)
duelHit.OnServerEvent:Connect(function(player: Player, targetUserId: any)
    if typeof(targetUserId)~="number" or targetUserId==player.UserId then return end
    if player:GetAttribute("DinoDuel")~=true then return end
    local victim=Players:GetPlayerByUserId(targetUserId)
    if not victim or victim:GetAttribute("DinoDuel")~=true then return end
    local attackerCharacter=player.Character
    local victimCharacter=victim.Character
    local from=attackerCharacter and attackerCharacter:FindFirstChild("HumanoidRootPart")
    local toward=victimCharacter and victimCharacter:FindFirstChild("HumanoidRootPart")
    local attackerHumanoid=attackerCharacter and attackerCharacter:FindFirstChildOfClass("Humanoid")
    local victimHumanoid=victimCharacter and victimCharacter:FindFirstChildOfClass("Humanoid")
    if not from or not from:IsA("BasePart") or not toward or not toward:IsA("BasePart") then return end
    if not attackerHumanoid or not victimHumanoid or attackerHumanoid.Health<=0 or victimHumanoid.Health<=0 then return end
    local delta=toward.Position-from.Position
    if delta.Magnitude>12 or delta.Magnitude<.2 then return end
    if from.CFrame.LookVector:Dot(delta.Unit)<-.4 then return end
    local now=os.clock()
    if now-(duelCooldowns[player] or 0)<.65 then return end
    duelCooldowns[player]=now
    victimHumanoid:TakeDamage(14)
    gameMessage:FireClient(player,"⚔️ Duel hit on "..victim.DisplayName)
end)

-- Free cosmetic alternative: a glowing player trail purchased with earned DinoCoins.
-- This purchase never needs Robux and does not affect combat power.
cosmeticRequest.OnServerEvent:Connect(function(player: Player)
    local now=os.clock()
    if now-(cosmeticCooldowns[player] or 0)<1 then return end
    cosmeticCooldowns[player]=now
    local stats=player:FindFirstChild("leaderstats")
    local coins=stats and stats:FindFirstChild("DinoCoins")
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not coins or not coins:IsA("IntValue") or not root or not root:IsA("BasePart") then return end
    if root:FindFirstChild("DinoBlueTrail") then
        gameMessage:FireClient(player,"Your blue glow is already active!")
        return
    end
    if coins.Value<60 then
        gameMessage:FireClient(player,"Earn 60 DinoCoins defeating dinosaurs to unlock Blue Glow.")
        return
    end
    coins.Value-=60
    local particles=Instance.new("ParticleEmitter")
    particles.Name="DinoBlueTrail"
    particles.Texture="rbxasset://textures/particles/sparkles_main.dds"
    particles.Rate=13
    particles.Lifetime=NumberRange.new(.35,.8)
    particles.Speed=NumberRange.new(0,2)
    particles.Color=ColorSequence.new(Color3.fromRGB(48,218,255))
    particles.Parent=root
    gameMessage:FireClient(player,"Blue Glow activated for this life! (60 earned DinoCoins)")
end)

-- Purchases are always granted from the server after Roblox confirms the receipt.
-- Each PurchaseId is recorded to prevent accidentally granting twice.
MarketplaceService.ProcessReceipt = function(receipt)
    if FIREWORK_PRODUCT_ID==0 or receipt.ProductId~=FIREWORK_PRODUCT_ID then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    local player=Players:GetPlayerByUserId(receipt.PlayerId)
    if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
    local key="Receipt_"..receipt.PurchaseId
    local ok, stored=pcall(function()
        return receiptStore:UpdateAsync(key, function(previous)
            return previous or {Granted=true,UserId=receipt.PlayerId,At=os.time()}
        end)
    end)
    if not ok or not stored then return Enum.ProductPurchaseDecision.NotProcessedYet end
    -- Celebration is cosmetic. Data-store receipt is recorded before marking processed.
    fireworks(player)
    return Enum.ProductPurchaseDecision.PurchaseGranted
end

Players.PlayerAdded:Connect(function(player)
    player:SetAttribute("DinoDuel",false)
    local leaderstats=Instance.new("Folder")
    leaderstats.Name="leaderstats"
    leaderstats.Parent=player
    local coins=Instance.new("IntValue")
    coins.Name="DinoCoins"
    coins.Parent=leaderstats
    local kills=Instance.new("IntValue")
    kills.Name="DinoKills"
    kills.Parent=leaderstats
    local ok,result=pcall(function() return coinStore:GetAsync(tostring(player.UserId)) end)
    if ok and type(result)=="number" then coins.Value=math.clamp(math.floor(result),0,100000000) end
end)
Players.PlayerRemoving:Connect(function(player)
    attackTimers[player]=nil
    cosmeticCooldowns[player]=nil
    duelCooldowns[player]=nil
    local stats=player:FindFirstChild("leaderstats")
    local coins=stats and stats:FindFirstChild("DinoCoins")
    if coins and coins:IsA("IntValue") then
        pcall(function() coinStore:SetAsync(tostring(player.UserId),coins.Value) end)
    end
end)
game:BindToClose(function()
    for _,player in ipairs(Players:GetPlayers()) do
        local stats=player:FindFirstChild("leaderstats")
        local coins=stats and stats:FindFirstChild("DinoCoins")
        if coins and coins:IsA("IntValue") then
            pcall(function() coinStore:SetAsync(tostring(player.UserId),coins.Value) end)
        end
    end
end)
buildArena()
ReplicatedStorage:SetAttribute("DinoCraftWave",0)
