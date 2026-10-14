-- ========================================================
-- 🧱 BLOCK BLAST CLONE (NEXUS OS CLOUD MODULE)
-- Repository File: blockblast.lua
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

local BOARD_SIZE = 8
local grid = {}
for r = 1, BOARD_SIZE do
    grid[r] = {}
    for c = 1, BOARD_SIZE do
        grid[r][c] = nil
    end
end

local score = 0
local currentUser = getCurrentUser()
local userDb = (currentUser and db.users[currentUser]) or {}
local bestScore = userDb.blockBlastBest or 0

-- Color Palette
local COLORS = {
    c1 = Color3.fromRGB(255, 71, 87),   -- Red
    c2 = Color3.fromRGB(46, 213, 115),  -- Green
    c3 = Color3.fromRGB(30, 144, 255),  -- Blue
    c4 = Color3.fromRGB(255, 165, 2),   -- Orange
    c5 = Color3.fromRGB(155, 89, 182)   -- Purple
}

local SHAPES = {
    { shape = {{1}}, color = COLORS.c1 },
    { shape = {{1, 1}}, color = COLORS.c2 },
    { shape = {{1}, {1}}, color = COLORS.c2 },
    { shape = {{1, 1, 1}}, color = COLORS.c3 },
    { shape = {{1}, {1}, {1}}, color = COLORS.c3 },
    { shape = {{1, 1}, {1, 1}}, color = COLORS.c4 },
    { shape = {{1, 1, 1}, {1, 1, 1}, {1, 1, 1}}, color = COLORS.c5 },
    { shape = {{1, 0}, {1, 1}}, color = COLORS.c1 },
    { shape = {{1, 1, 1}, {0, 1, 0}}, color = COLORS.c4 },
    { shape = {{1, 1}, {0, 1}, {0, 1}}, color = COLORS.c5 }
}

local currentPieces = {nil, nil, nil}

-- App Main Container
local gameFrame = Instance.new("Frame")
gameFrame.Name = "BlockBlastApp"
gameFrame.Size = UDim2.new(1, 0, 1, -40)
gameFrame.Position = UDim2.new(0, 0, 0, 30)
gameFrame.BackgroundTransparency = 1
gameFrame.Visible = true
gameFrame.ZIndex = 51
gameFrame.Parent = phoneFrame

-- Score Displays
local scoreBox = Instance.new("Frame")
scoreBox.Size = UDim2.new(0, 125, 0, 32)
scoreBox.Position = UDim2.new(0, 20, 0, 10)
scoreBox.BackgroundColor3 = Color3.fromRGB(31, 41, 61)
scoreBox.ZIndex = 52
scoreBox.Parent = gameFrame
Instance.new("UICorner", scoreBox).CornerRadius = UDim.new(0, 8)

local scoreLabel = Instance.new("TextLabel")
scoreLabel.Size = UDim2.new(1, 0, 1, 0)
scoreLabel.BackgroundTransparency = 1
scoreLabel.TextColor3 = Color3.fromRGB(0, 242, 254)
scoreLabel.TextSize = 10
scoreLabel.Font = Enum.Font.GothamBold
scoreLabel.Text = "SCORE: 0"
scoreLabel.ZIndex = 53
scoreLabel.Parent = scoreBox

local bestBox = Instance.new("Frame")
bestBox.Size = UDim2.new(0, 125, 0, 32)
bestBox.Position = UDim2.new(1, -145, 0, 10)
bestBox.BackgroundColor3 = Color3.fromRGB(31, 41, 61)
bestBox.ZIndex = 52
bestBox.Parent = gameFrame
Instance.new("UICorner", bestBox).CornerRadius = UDim.new(0, 8)

local bestLabel = Instance.new("TextLabel")
bestLabel.Size = UDim2.new(1, 0, 1, 0)
bestLabel.BackgroundTransparency = 1
bestLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
bestLabel.TextSize = 10
bestLabel.Font = Enum.Font.GothamBold
bestLabel.Text = "BEST: " .. bestScore
bestLabel.ZIndex = 53
bestLabel.Parent = bestBox

-- Grid Board Container
local boardFrame = Instance.new("Frame")
boardFrame.Size = UDim2.new(0, 260, 0, 260)
boardFrame.Position = UDim2.new(0.5, -130, 0, 50)
boardFrame.BackgroundColor3 = Color3.fromRGB(31, 41, 61)
boardFrame.ZIndex = 52
boardFrame.Parent = gameFrame
Instance.new("UICorner", boardFrame).CornerRadius = UDim.new(0, 12)

local boardGrid = Instance.new("UIGridLayout")
boardGrid.CellSize = UDim2.new(0, 28, 0, 28)
boardGrid.CellPadding = UDim2.new(0, 3, 0, 3)
boardGrid.StartCorner = Enum.StartCorner.TopLeft
boardGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
boardGrid.VerticalAlignment = Enum.VerticalAlignment.Center
boardGrid.Parent = boardFrame

local boardCells = {}

for r = 1, BOARD_SIZE do
    boardCells[r] = {}
    for c = 1, BOARD_SIZE do
        local cell = Instance.new("Frame")
        cell.Name = "Cell_" .. r .. "_" .. c
        cell.BackgroundColor3 = Color3.fromRGB(42, 53, 77)
        cell.ZIndex = 53
        cell.Parent = boardFrame
        Instance.new("UICorner", cell).CornerRadius = UDim.new(0, 5)

        boardCells[r][c] = cell
    end
end

-- Piece Slots Area
local piecesArea = Instance.new("Frame")
piecesArea.Size = UDim2.new(0, 260, 0, 80)
piecesArea.Position = UDim2.new(0.5, -130, 0, 320)
piecesArea.BackgroundColor3 = Color3.fromRGB(31, 41, 61)
piecesArea.ZIndex = 52
piecesArea.Parent = gameFrame
Instance.new("UICorner", piecesArea).CornerRadius = UDim.new(0, 12)

local slotFrames = {}
for i = 1, 3 do
    local slot = Instance.new("Frame")
    slot.Size = UDim2.new(0, 75, 0, 75)
    slot.Position = UDim2.new(0, (i - 1) * 85 + 10, 0.5, -37)
    slot.BackgroundTransparency = 1
    slot.ZIndex = 53
    slot.Parent = piecesArea
    slotFrames[i] = slot
end

-- Render Board Functions
local function renderBoard()
    for r = 1, BOARD_SIZE do
        for c = 1, BOARD_SIZE do
            if grid[r][c] then
                boardCells[r][c].BackgroundColor3 = grid[r][c]
            else
                boardCells[r][c].BackgroundColor3 = Color3.fromRGB(42, 53, 77)
            end
        end
    end
end

local function addScore(pts)
    score = score + pts
    scoreLabel.Text = "SCORE: " .. score
    if score > bestScore then
        bestScore = score
        bestLabel.Text = "BEST: " .. bestScore
        if currentUser and db.users[currentUser] then
            db.users[currentUser].blockBlastBest = bestScore
            saveDatabase(db)
        end
    end
end

local function canPlace(shape, startR, startC)
    for r = 1, #shape do
        for c = 1, #shape[r] do
            if shape[r][c] == 1 then
                local targetR = startR + r - 1
                local targetC = startC + c - 1
                if targetR < 1 or targetR > BOARD_SIZE or targetC < 1 or targetC > BOARD_SIZE then
                    return false
                end
                if grid[targetR][targetC] ~= nil then
                    return false
                end
            end
        end
    end
    return true
end

local function clearLines()
    local rowsToClear = {}
    local colsToClear = {}

    for r = 1, BOARD_SIZE do
        local full = true
        for c = 1, BOARD_SIZE do
            if grid[r][c] == nil then full = false break end
        end
        if full then table.insert(rowsToClear, r) end
    end

    for c = 1, BOARD_SIZE do
        local full = true
        for r = 1, BOARD_SIZE do
            if grid[r][c] == nil then full = false break end
        end
        if full then table.insert(colsToClear, c) end
    end

    local clearedCount = #rowsToClear + #colsToClear

    for _, r in ipairs(rowsToClear) do
        for c = 1, BOARD_SIZE do grid[r][c] = nil end
    end
    for _, c in ipairs(colsToClear) do
        for r = 1, BOARD_SIZE do grid[r][c] = nil end
    end

    if clearedCount > 0 then
        addScore(clearedCount * 100)
        renderBoard()
    end
end

-- Drag & Drop Interaction
local activeDrag = nil

local function getCellAtPosition(posX, posY)
    for r = 1, BOARD_SIZE do
        for c = 1, BOARD_SIZE do
            local cell = boardCells[r][c]
            local pos = cell.AbsolutePosition
            local size = cell.AbsoluteSize
            if posX >= pos.X and posX <= pos.X + size.X and posY >= pos.Y and posY <= pos.Y + size.Y then
                return r, c
            end
        end
    end
    return nil, nil
end

local function renderPieceUI(pieceData, parent, cellSize)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, #pieceData.shape[1] * (cellSize + 2), 0, #pieceData.shape * (cellSize + 2))
    container.Position = UDim2.new(0.5, -container.Size.X.Offset / 2, 0.5, -container.Size.Y.Offset / 2)
    container.BackgroundTransparency = 1
    container.ZIndex = 54
    container.Parent = parent

    for r = 1, #pieceData.shape do
        for c = 1, #pieceData.shape[r] do
            if pieceData.shape[r][c] == 1 then
                local blk = Instance.new("Frame")
                blk.Size = UDim2.new(0, cellSize, 0, cellSize)
                blk.Position = UDim2.new(0, (c - 1) * (cellSize + 2), 0, (r - 1) * (cellSize + 2))
                blk.BackgroundColor3 = pieceData.color
                blk.ZIndex = 55
                blk.Parent = container
                Instance.new("UICorner", blk).CornerRadius = UDim.new(0, 3)
            end
        end
    end
    return container
end

local function checkGameOver()
    for idx, piece in ipairs(currentPieces) do
        if piece then
            for r = 1, BOARD_SIZE do
                for c = 1, BOARD_SIZE do
                    if canPlace(piece.shape, r, c) then
                        return false
                    end
                end
            end
        end
    end
    return true
end

local function spawnPieces()
    local allEmpty = true
    for _, p in ipairs(currentPieces) do
        if p ~= nil then allEmpty = false break end
    end

    if allEmpty then
        for i = 1, 3 do
            local randShape = SHAPES[math.random(1, #SHAPES)]
            currentPieces[i] = randShape
            slotFrames[i]:ClearAllChildren()

            local pieceUI = renderPieceUI(randShape, slotFrames[i], 12)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.ZIndex = 60
            btn.Parent = slotFrames[i]

            btn.MouseButton1Down:Connect(function()
                if activeDrag then return end
                slotFrames[i].BackgroundTransparency = 0.8

                local dragVisual = renderPieceUI(randShape, gameFrame, 22)
                dragVisual.ZIndex = 100

                activeDrag = {
                    index = i,
                    data = randShape,
                    visual = dragVisual,
                    slot = slotFrames[i]
                }
            end)
        end
    end

    if checkGameOver() then
        scoreLabel.Text = "GAME OVER!"
    end
end

UserInputService.InputChanged:Connect(function(input)
    if activeDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local mPos = input.Position
        activeDrag.visual.Position = UDim2.new(0, mPos.X - gameFrame.AbsolutePosition.X - 30, 0, mPos.Y - gameFrame.AbsolutePosition.Y - 60)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if activeDrag and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        local mPos = input.Position
        local targetR, targetC = getCellAtPosition(mPos.X, mPos.Y - 30)

        if targetR and targetC and canPlace(activeDrag.data.shape, targetR, targetC) then
            local shape = activeDrag.data.shape
            local blocksPlaced = 0
            for r = 1, #shape do
                for c = 1, #shape[r] do
                    if shape[r][c] == 1 then
                        grid[targetR + r - 1][targetC + c - 1] = activeDrag.data.color
                        blocksPlaced = blocksPlaced + 1
                    end
                end
            end
            addScore(blocksPlaced * 10)
            renderBoard()
            clearLines()

            activeDrag.slot:ClearAllChildren()
            currentPieces[activeDrag.index] = nil
            spawnPieces()
        else
            activeDrag.slot.BackgroundTransparency = 1
        end

        if activeDrag.visual then activeDrag.visual:Destroy() end
        activeDrag = nil
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
backToHome.ZIndex = 52
backToHome.Parent = gameFrame
Instance.new("UICorner", backToHome).CornerRadius = UDim.new(0, 8)

backToHome.Activated:Connect(function()
    gameFrame:Destroy()
    showHome()
end)

spawnPieces()
