-- ========================================================
-- 🦆 FLAPPY DUCK: PIXEL POND JUMP (NEXUS OS CLOUD MODULE)
-- Repository File: flappyduck.lua
-- ========================================================

local NexusOS = getgenv().NexusOS
if not NexusOS then return end

local phoneFrame = NexusOS.phoneFrame
local db = NexusOS.db
local saveDatabase = NexusOS.saveDatabase
local getCurrentUser = NexusOS.getCurrentUser
local showHome = NexusOS.showHome

local currentUser = getCurrentUser()
local userDb = (currentUser and db.users[currentUser]) or {}
local bestScore = userDb.flappyDuckBest or 0

-- App Main Container
local gameFrame = Instance.new("Frame")
gameFrame.Name = "FlappyDuckApp"
gameFrame.Size = UDim2.new(1, 0, 1, -40)
gameFrame.Position = UDim2.new(0, 0, 0, 30)
gameFrame.BackgroundColor3 = Color3.fromRGB(13, 27, 42)
gameFrame.ClipsDescendants = true
gameFrame.ZIndex = 51
gameFrame.Parent = phoneFrame

-- HUD Overlay Scores
local scoreLabel = Instance.new("TextLabel")
scoreLabel.Size = UDim2.new(0, 120, 0, 30)
scoreLabel.Position = UDim2.new(0, 15, 0, 10)
scoreLabel.BackgroundColor3 = Color3.fromRGB(15, 32, 67)
scoreLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
scoreLabel.TextSize = 11
scoreLabel.Font = Enum.Font.GothamBold
scoreLabel.Text = "SCORE: 0"
scoreLabel.ZIndex = 52
scoreLabel.Parent = gameFrame
Instance.new("UICorner", scoreLabel).CornerRadius = UDim.new(0, 8)

local bestLabel = Instance.new("TextLabel")
bestLabel.Size = UDim2.new(0, 120, 0, 30)
bestLabel.Position = UDim2.new(1, -135, 0, 10)
bestLabel.BackgroundColor3 = Color3.fromRGB(15, 32, 67)
bestLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
bestLabel.TextSize = 11
bestLabel.Font = Enum.Font.GothamBold
bestLabel.Text = "BEST: " .. bestScore
bestLabel.ZIndex = 52
bestLabel.Parent = gameFrame
Instance.new("UICorner", bestLabel).CornerRadius = UDim.new(0, 8)

-- Game Arena Area
local arena = Instance.new("Frame")
arena.Size = UDim2.new(0, 280, 0, 340)
arena.Position = UDim2.new(0.5, -140, 0, 50)
arena.BackgroundColor3 = Color3.fromRGB(20, 40, 70)
arena.ClipsDescendants = true
arena.ZIndex = 52
arena.Parent = gameFrame
Instance.new("UICorner", arena).CornerRadius = UDim.new(0, 12)

-- Duck Character
local duck = Instance.new("Frame")
duck.Size = UDim2.new(0, 24, 0, 24)
duck.Position = UDim2.new(0, 60, 0, 150)
duck.BackgroundColor3 = Color3.fromRGB(255, 204, 0)
duck.ZIndex = 55
duck.Parent = arena
Instance.new("UICorner", duck).CornerRadius = UDim.new(1, 0)

local score = 0
local duckY = 150
local duckVy = 0
local gravity = 0.4
local jumpForce = -7.5
local isPlaying = true

-- Tap Control Button to Flap
local tapBtn = Instance.new("TextButton")
tapBtn.Size = UDim2.new(1, 0, 1, 0)
tapBtn.BackgroundTransparency = 1
tapBtn.Text = ""
tapBtn.ZIndex = 60
tapBtn.Parent = arena

tapBtn.Activated:Connect(function()
    if isPlaying then
        duckVy = jumpForce
    end
end)

local obstacles = {}

local function spawnPipe()
    if not isPlaying then return end
    local gap = 110
    local topHeight = math.random(40, 160)

    local topPipe = Instance.new("Frame")
    topPipe.Size = UDim2.new(0, 45, 0, topHeight)
    topPipe.Position = UDim2.new(0, 280, 0, 0)
    topPipe.BackgroundColor3 = Color3.fromRGB(46, 106, 79)
    topPipe.ZIndex = 53
    topPipe.Parent = arena
    Instance.new("UICorner", topPipe).CornerRadius = UDim.new(0, 6)

    local botPipe = Instance.new("Frame")
    botPipe.Size = UDim2.new(0, 45, 0, 340 - topHeight - gap)
    botPipe.Position = UDim2.new(0, 280, 0, topHeight + gap)
    botPipe.BackgroundColor3 = Color3.fromRGB(46, 106, 79)
    botPipe.ZIndex = 53
    botPipe.Parent = arena
    Instance.new("UICorner", botPipe).CornerRadius = UDim.new(0, 6)

    table.insert(obstacles, {top = topPipe, bot = botPipe, passed = false})
end

-- Game Engine Loop
task.spawn(function()
    while gameFrame and gameFrame.Parent and isPlaying do
        task.wait(0.02)

        duckVy = duckVy + gravity
        duckY = duckY + duckVy
        duck.Position = UDim2.new(0, 60, 0, duckY)

        -- Screen Bounds Collision
        if duckY < 0 or duckY > 316 then
            isPlaying = false
        end

        -- Move Pipes & Check Collision
        for i = #obstacles, 1, -1 do
            local obs = obstacles[i]
            if obs.top and obs.top.Parent then
                local posX = obs.top.Position.X.Offset - 3
                obs.top.Position = UDim2.new(0, posX, 0, 0)
                obs.bot.Position = UDim2.new(0, posX, 0, obs.bot.Position.Y.Offset)

                -- Score Increment
                if not obs.passed and posX < 40 then
                    obs.passed = true
                    score = score + 1
                    scoreLabel.Text = "SCORE: " + score -- handled safely
                    scoreLabel.Text = "SCORE: " .. score
                    if score > bestScore then
                        bestScore = score
                        bestLabel.Text = "BEST: " .. bestScore
                        if currentUser and db.users[currentUser] then
                            db.users[currentUser].flappyDuckBest = bestScore
                            saveDatabase(db)
                        end
                    end
                end

                -- Pipe Hit Detection
                if posX < 84 and posX > 36 then
                    local topH = obs.top.Size.Y.Offset
                    local botY = obs.bot.Position.Y.Offset
                    if duckY < topH or (duckY + 24) > botY then
                        isPlaying = false
                    end
                end

                -- Clean up offscreen pipes
                if posX < -50 then
                    obs.top:Destroy()
                    obs.bot:Destroy()
                    table.remove(obstacles, i)
                end
            end
        end
    end

    scoreLabel.Text = "GAME OVER!"
end)

-- Spawner Routine
task.spawn(function()
    while gameFrame and gameFrame.Parent and isPlaying do
        task.wait(1.8)
        spawnPipe()
    end
end)

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
