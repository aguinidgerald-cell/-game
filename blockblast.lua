-- ========================================================
-- 🧱 BLOCK BLAST CLONE (TAP-TO-SELECT & TAP-TO-PLACE)
-- Repository File: blockblast.lua
-- ========================================================

local NexusOS = getgenv().NexusOS
if not NexusOS then return end

local phoneFrame = NexusOS.phoneFrame
local db = NexusOS.db
local saveDatabase = NexusOS.saveDatabase
local getCurrentUser = NexusOS.getCurrentUser
local showHome = NexusOS.showHome

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

local COLORS = {
    c1 = Color3.fromRGB(255, 71, 87),
    c2 = Color3.fromRGB(46, 213, 115),
    c3 = Color3.fromRGB(30, 144, 255),
    c4 = Color3.fromRGB(255, 165, 2),
    c5 = Color3.fromRGB(155, 89, 182)
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
local selectedPieceIndex = nil

local gameFrame = Instance.new("Frame")
gameFrame.Name = "BlockBlastApp"
gameFrame.Size = UDim2.new(1, 0, 1, -40)
gameFrame.Position = UDim2.new(0, 0, 0, 30)
gameFrame.BackgroundTransparency = 1
gameFrame.Visible = true
gameFrame.ZIndex = 51
gameFrame.Parent = phoneFrame

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

local function renderBoard()
    for r = 1, BOARD_SIZE do
        for c = 1, BOARD_SIZE do
            if grid[r][c] then
                boardCells[r][c].btn.BackgroundColor3 = grid[r][c]
            else
                boardCells[r][c].btn.BackgroundColor3 = Color3.fromRGB(42, 53, 77)
            end
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

local slotFrames = {}

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

local function highlightSlots()
    for i = 1, 3 do
        if slotFrames[i] then
            local stroke = slotFrames[i]:FindFirstChild("UIStroke")
            if i == selectedPieceIndex then
                if not stroke then
                    stroke = Instance.new("UIStroke")
                    stroke.Thickness = 2
                    stroke.Color = Color3.fromRGB(0, 255, 150)
                    stroke.Parent = slotFrames[i]
                end
            else
                if stroke then stroke:Destroy() end
            end
        end
    end
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

            renderPieceUI(randShape, slotFrames[i], 12)

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.ZIndex = 60
            btn.Parent = slotFrames[i]

            btn.Activated:Connect(function()
                if selectedPieceIndex == i then
                    selectedPieceIndex = nil
                else
                    selectedPieceIndex = i
                end
                highlightSlots()
            end)
        end
    end
end

-- Create Board Cells
for r = 1, BOARD_SIZE do
    boardCells[r] = {}
    for c = 1, BOARD_SIZE do
        local cellBtn = Instance.new("TextButton")
        cellBtn.Name = "Cell_" .. r .. "_" .. c
        cellBtn.BackgroundColor3 = Color3.fromRGB(42, 53, 77)
        cellBtn.Text = ""
        cellBtn.ZIndex = 53
        cellBtn.Parent = boardFrame
        Instance.new("UICorner", cellBtn).CornerRadius = UDim.new(0, 5)

        cellBtn.Activated:Connect(function()
            if selectedPieceIndex and currentPieces[selectedPieceIndex] then
                local piece = currentPieces[selectedPieceIndex]
                if canPlace(piece.shape, r, c) then
                    local blocksPlaced = 0
                    for pr = 1, #piece.shape do
                        for pc = 1, #piece.shape[pr] do
                            if piece.shape[pr][pc] == 1 then
                                grid[r + pr - 1][c + pc - 1] = piece.color
                                blocksPlaced = blocksPlaced + 1
                            end
                        end
                    end
                    addScore(blocksPlaced * 10)
                    renderBoard()
                    clearLines()

                    slotFrames[selectedPieceIndex]:ClearAllChildren()
                    currentPieces[selectedPieceIndex] = nil
                    selectedPieceIndex = nil
                    highlightSlots()
                    spawnPieces()
                end
            end
        end)

        boardCells[r][c] = {btn = cellBtn}
    end
end

local piecesArea = Instance.new("Frame")
piecesArea.Size = UDim2.new(0, 260, 0, 80)
piecesArea.Position = UDim2.new(0.5, -130, 0, 320)
piecesArea.BackgroundColor3 = Color3.fromRGB(31, 41, 61)
piecesArea.ZIndex = 52
piecesArea.Parent = gameFrame
Instance.new("UICorner", piecesArea).CornerRadius = UDim.new(0, 12)

for i = 1, 3 do
    local slot = Instance.new("Frame")
    slot.Size = UDim2.new(0, 75, 0, 75)
    slot.Position = UDim2.new(0, (i - 1) * 85 + 10, 0.5, -37)
    slot.BackgroundColor3 = Color3.fromRGB(22, 28, 42)
    slot.ZIndex = 53
    slot.Parent = piecesArea
    Instance.new("UICorner", slot).CornerRadius = UDim.new(0, 8)
    slotFrames[i] = slot
end

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
