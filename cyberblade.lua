-- ========================================================
-- ⚔️ CYBER-BLADE: NEON OVERDRIVE (ROBLOX LUAU CLOUD APP)
-- Repository File: cyberblade.lua
-- ========================================================

local NexusOS = getgenv().NexusOS
if not NexusOS then return end

local phoneFrame = NexusOS.phoneFrame
local db = NexusOS.db
local saveDatabase = NexusOS.saveDatabase
local getCurrentUser = NexusOS.getCurrentUser
local showHome = NexusOS.showHome

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- App Main Container
local gameFrame = Instance.new("Frame")
gameFrame.Name = "CyberBladeApp"
gameFrame.Size = UDim2.new(1, 0, 1, -40)
gameFrame.Position = UDim2.new(0, 0, 0, 30)
gameFrame.BackgroundColor3 = Color3.fromRGB(3, 3, 8)
gameFrame.ClipsDescendants = true
gameFrame.ZIndex = 51
gameFrame.Parent = phoneFrame

-- HUD Overlay Frame
local hudFrame = Instance.new("Frame")
hudFrame.Size = UDim2.new(1, -20, 0, 65)
hudFrame.Position = UDim2.new(0, 10, 0, 8)
hudFrame.BackgroundTransparency = 1
hudFrame.ZIndex = 60
hudFrame.Parent = gameFrame

-- HP Bar
local hpContainer = Instance.new("Frame")
hpContainer.Size = UDim2.new(0, 110, 0, 22)
hpContainer.Position = UDim2.new(0, 0, 0, 0)
hpContainer.BackgroundColor3 = Color3.fromRGB(10, 15, 30)
hpContainer.ZIndex = 61
hpContainer.Parent = hudFrame
Instance.new("UICorner", hpContainer).CornerRadius = UDim.new(0, 6)

local hpBar = Instance.new("Frame")
hpBar.Size = UDim2.new(1, -4, 1, -4)
hpBar.Position = UDim2.new(0, 2, 0, 2)
hpBar.BackgroundColor3 = Color3.fromRGB(0, 243, 255)
hpBar.ZIndex = 62
hpBar.Parent = hpContainer
Instance.new("UICorner", hpBar).CornerRadius = UDim.new(0, 4)

local hpText = Instance.new("TextLabel")
hpText.Size = UDim2.new(1, 0, 1, 0)
hpText.BackgroundTransparency = 1
hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
hpText.TextSize = 9
hpText.Font = Enum.Font.GothamBold
hpText.Text = "HP: 100/100"
hpText.ZIndex = 63
hpText.Parent = hpContainer

-- Level & Wave Info
local infoText = Instance.new("TextLabel")
infoText.Size = UDim2.new(0, 110, 0, 18)
infoText.Position = UDim2.new(0, 0, 0, 26)
infoText.BackgroundTransparency = 1
infoText.TextColor3 = Color3.fromRGB(255, 0, 127)
infoText.TextSize = 10
infoText.Font = Enum.Font.GothamBlack
infoText.Text = "LVL: 1 | WAVE: 1"
infoText.TextXAlignment = Enum.TextXAlignment.Left
infoText.ZIndex = 61
infoText.Parent = hudFrame

-- Score
local scoreText = Instance.new("TextLabel")
scoreText.Size = UDim2.new(0, 120, 0, 25)
scoreText.Position = UDim2.new(1, -120, 0, 0)
scoreText.BackgroundTransparency = 1
scoreText.TextColor3 = Color3.fromRGB(0, 243, 255)
scoreText.TextSize = 13
scoreText.Font = Enum.Font.GothamBlack
scoreText.Text = "SCORE: 0"
scoreText.TextXAlignment = Enum.TextXAlignment.Right
scoreText.ZIndex = 61
scoreText.Parent = hudFrame

-- Game Arena Area
local arena = Instance.new("Frame")
arena.Size = UDim2.new(0, 280, 0, 320)
arena.Position = UDim2.new(0.5, -140, 0, 60)
arena.BackgroundColor3 = Color3.fromRGB(10, 12, 22)
arena.ClipsDescendants = true
arena.ZIndex = 52
arena.Parent = gameFrame
Instance.new("UICorner", arena).CornerRadius = UDim.new(0, 12)
local arenaStroke = Instance.new("UIStroke", arena)
arenaStroke.Color = Color3.fromRGB(0, 243, 255)
arenaStroke.Thickness = 1.5

-- Player Icon
local playerIcon = Instance.new("Frame")
playerIcon.Size = UDim2.new(0, 20, 0, 20)
playerIcon.Position = UDim2.new(0.5, -10, 0.5, -10)
playerIcon.BackgroundColor3 = Color3.fromRGB(0, 243, 255)
playerIcon.ZIndex = 55
playerIcon.Parent = arena
Instance.new("UICorner", playerIcon).CornerRadius = UDim.new(1, 0)

-- Game State Variables
local playerHp = 100
local maxHp = 100
local score = 0
local wave = 1
local level = 1
local exp = 0
local maxExp = 50
local isPlaying = true

local enemies = {}
local isAttacking = false

-- Update HUD Function
local function updateHUD()
    hpText.Text = "HP: " .. math.max(0, math.floor(playerHp)) .. "/" .. maxHp
    hpBar.Size = UDim2.new(math.max(0, playerHp / maxHp), -4, 1, -4)
    infoText.Text = "LVL: " .. level .. " | WAVE: " .. wave
    scoreText.Text = "SCORE: " .. score
end

-- Attack Mechanism (Slash Attack)
local function attackSlash()
    if isAttacking or not isPlaying then return end
    isAttacking = true

    -- Visual Slash Effect
    local slashEffect = Instance.new("Frame")
    slashEffect.Size = UDim2.new(0, 80, 0, 80)
    slashEffect.Position = UDim2.new(playerIcon.Position.X.Scale, playerIcon.Position.X.Offset - 30, playerIcon.Position.Y.Scale, playerIcon.Position.Y.Offset - 30)
    slashEffect.BackgroundColor3 = Color3.fromRGB(255, 0, 127)
    slashEffect.BackgroundTransparency = 0.4
    slashEffect.ZIndex = 56
    slashEffect.Parent = arena
    Instance.new("UICorner", slashEffect).CornerRadius = UDim.new(1, 0)

    -- Damage Enemies Nearby
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        if enemy and enemy.Frame and enemy.Frame.Parent then
            local pPos = Vector2.new(playerIcon.Position.X.Offset, playerIcon.Position.Y.Offset)
            local ePos = Vector2.new(enemy.Frame.Position.X.Offset, enemy.Frame.Position.Y.Offset)
            local dist = (pPos - ePos).Magnitude

            if dist <= 65 then
                enemy.Hp = enemy.Hp - 35
                if enemy.Hp <= 0 then
                    enemy.Frame:Destroy()
                    table.remove(enemies, i)
                    score = score + 100
                    exp = exp + 15
                    if exp >= maxExp then
                        level = level + 1
                        exp = 0
                        maxExp = math.floor(maxExp * 1.3)
                    end
                    updateHUD()
                end
            end
        end
    end

    TweenService:Create(slashEffect, TweenInfo.new(0.2), {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}):Play()
    task.delay(0.2, function()
        slashEffect:Destroy()
        isAttacking = false
    end)
end

-- Spawn Enemies
local function spawnEnemy()
    if #enemies >= 6 or not isPlaying then return end

    local eFrame = Instance.new("Frame")
    eFrame.Size = UDim2.new(0, 16, 0, 16)
    
    -- Spawn along edges
    local randSide = math.random(1, 4)
    local spawnX, spawnY = 0, 0
    if randSide == 1 then spawnX = math.random(10, 260); spawnY = 10
    elseif randSide == 2 then spawnX = math.random(10, 260); spawnY = 300
    elseif randSide == 3 then spawnX = 10; spawnY = math.random(10, 300)
    else spawnX = 260; spawnY = math.random(10, 300) end

    eFrame.Position = UDim2.new(0, spawnX, 0, spawnY)
    eFrame.BackgroundColor3 = Color3.fromRGB(255, 71, 87)
    eFrame.ZIndex = 54
    eFrame.Parent = arena
    Instance.new("UICorner", eFrame).CornerRadius = UDim.new(1, 0)

    table.insert(enemies, {Frame = eFrame, Hp = 40, MaxHp = 40})
end

-- Main Game Update Loop
task.spawn(function()
    while gameFrame and gameFrame.Parent and isPlaying do
        task.wait(0.05)

        -- Move Enemies towards Player
        local pX = playerIcon.Position.X.Offset
        local pY = playerIcon.Position.Y.Offset

        for _, enemy in ipairs(enemies) do
            if enemy.Frame and enemy.Frame.Parent then
                local eX = enemy.Frame.Position.X.Offset
                local eY = enemy.Frame.Position.Y.Offset

                local dirX = pX - eX
                local dirY = pY - eY
                local dist = math.sqrt(dirX^2 + dirY^2)

                if dist > 15 then
                    enemy.Frame.Position = UDim2.new(0, eX + (dirX / dist) * 2, 0, eY + (dirY / dist) * 2)
                else
                    -- Attack Player
                    playerHp = playerHp - 1
                    updateHUD()
                    if playerHp <= 0 then
                        isPlaying = false
                        infoText.Text = "SYSTEM FAILURE!"
                    end
                end
            end
        end
    end
end)

-- Spawner Timer
task.spawn(function()
    while gameFrame and gameFrame.Parent and isPlaying do
        task.wait(2)
        spawnEnemy()
    end
end)

-- Touch Attack Screen Control
local attackBtn = Instance.new("TextButton")
attackBtn.Size = UDim2.new(0, 100, 0, 35)
attackBtn.Position = UDim2.new(0.5, -50, 1, -80)
attackBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 127)
attackBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
attackBtn.TextSize = 11
attackBtn.Font = Enum.Font.GothamBlack
attackBtn.Text = "⚔️ SLASH"
attackBtn.ZIndex = 60
attackBtn.Parent = gameFrame
Instance.new("UICorner", attackBtn).CornerRadius = UDim.new(0, 10)

attackBtn.Activated:Connect(attackSlash)

-- Home Screen Button
local backToHome = Instance.new("TextButton")
backToHome.Size = UDim2.new(1, -40, 0, 28)
backToHome.Position = UDim2.new(0, 20, 1, -38)
backToHome.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
backToHome.TextColor3 = Color3.fromRGB(255, 255, 255)
backToHome.TextSize = 11
backToHome.Font = Enum.Font.GothamBold
backToHome.Text = "🏠 HOME SCREEN"
backToHome.ZIndex = 60
backToHome.Parent = gameFrame
Instance.new("UICorner", backToHome).CornerRadius = UDim.new(0, 8)

backToHome.Activated:Connect(function()
    isPlaying = false
    gameFrame:Destroy()
    showHome()
end)

updateHUD()
