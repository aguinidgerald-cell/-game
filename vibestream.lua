-- ========================================================
-- 🎵 VIBE STREAM & MUSIC PLAYER (SINGLE REPOSITORY MODULE)
-- Repository File: vibestream.lua
-- ========================================================

local NexusOS = getgenv().NexusOS
if not NexusOS then return end

local phoneFrame = NexusOS.phoneFrame
local db = NexusOS.db
local saveDatabase = NexusOS.saveDatabase
local getCurrentUser = NexusOS.getCurrentUser
local showHome = NexusOS.showHome

local SoundService = game:GetService("SoundService")

-- Global Sound Instance para sa Background Music
local backgroundMusic = SoundService:FindFirstChild("NexusMusicPlayer")
if not backgroundMusic then
    backgroundMusic = Instance.new("Sound")
    backgroundMusic.Name = "NexusMusicPlayer"
    backgroundMusic.SoundId = "rbxassetid://1848354536"
    backgroundMusic.Looped = true
    backgroundMusic.Volume = 0.5
    backgroundMusic.Parent = SoundService
end

-- Main App Frame
local musicFrame = Instance.new("Frame")
musicFrame.Name = "VibeStreamApp"
musicFrame.Size = UDim2.new(1, 0, 1, -40)
musicFrame.Position = UDim2.new(0, 0, 0, 30)
musicFrame.BackgroundTransparency = 1
musicFrame.Visible = true
musicFrame.ZIndex = 51
musicFrame.Parent = phoneFrame

-- App Header Title
local musicTitle = Instance.new("TextLabel")
musicTitle.Size = UDim2.new(1, 0, 0, 26)
musicTitle.Position = UDim2.new(0, 0, 0, 6)
musicTitle.BackgroundTransparency = 1
musicTitle.TextColor3 = Color3.fromRGB(0, 255, 150)
musicTitle.TextSize = 13
musicTitle.Font = Enum.Font.GothamBold
musicTitle.Text = "🎵 VIBE STREAM & POSTER"
musicTitle.ZIndex = 52
musicTitle.Parent = musicFrame

-- Posting Panel Box
local postBoxFrame = Instance.new("Frame")
postBoxFrame.Size = UDim2.new(1, -30, 0, 105)
postBoxFrame.Position = UDim2.new(0, 15, 0, 34)
postBoxFrame.BackgroundColor3 = Color3.fromRGB(22, 28, 42)
postBoxFrame.BorderSizePixel = 0
postBoxFrame.ZIndex = 52
postBoxFrame.Parent = musicFrame
Instance.new("UICorner", postBoxFrame).CornerRadius = UDim.new(0, 8)

local songNameBox = Instance.new("TextBox")
songNameBox.Size = UDim2.new(1, -20, 0, 24)
songNameBox.Position = UDim2.new(0, 10, 0, 6)
songNameBox.BackgroundColor3 = Color3.fromRGB(32, 38, 55)
songNameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
songNameBox.PlaceholderText = "Pangalan ng Kanta..."
songNameBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 150)
songNameBox.TextSize = 10
songNameBox.Font = Enum.Font.Gotham
songNameBox.Text = ""
songNameBox.ClearTextOnFocus = false
songNameBox.ZIndex = 53
songNameBox.Parent = postBoxFrame
Instance.new("UICorner", songNameBox).CornerRadius = UDim.new(0, 5)

local songIdBox = Instance.new("TextBox")
songIdBox.Size = UDim2.new(1, -100, 0, 24)
songIdBox.Position = UDim2.new(0, 10, 0, 35)
songIdBox.BackgroundColor3 = Color3.fromRGB(32, 38, 55)
songIdBox.TextColor3 = Color3.fromRGB(255, 255, 255)
songIdBox.PlaceholderText = "Roblox Sound Asset ID..."
songIdBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 150)
songIdBox.TextSize = 10
songIdBox.Font = Enum.Font.Gotham
songIdBox.Text = ""
songIdBox.ClearTextOnFocus = false
songIdBox.ZIndex = 53
songIdBox.Parent = postBoxFrame
Instance.new("UICorner", songIdBox).CornerRadius = UDim.new(0, 5)

local postSongBtn = Instance.new("TextButton")
postSongBtn.Size = UDim2.new(0, 80, 0, 24)
postSongBtn.Position = UDim2.new(1, -90, 0, 35)
postSongBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
postSongBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
postSongBtn.TextSize = 9
postSongBtn.Font = Enum.Font.GothamBold
postSongBtn.Text = "➕ I-POST"
postSongBtn.ZIndex = 53
postSongBtn.Parent = postBoxFrame
Instance.new("UICorner", postSongBtn).CornerRadius = UDim.new(0, 5)

local toggleMusicBtn = Instance.new("TextButton")
toggleMusicBtn.Size = UDim2.new(1, -20, 0, 28)
toggleMusicBtn.Position = UDim2.new(0, 10, 0, 68)
toggleMusicBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 140)
toggleMusicBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleMusicBtn.TextSize = 10
toggleMusicBtn.Font = Enum.Font.GothamBold
toggleMusicBtn.Text = "▶️ PLAY / ⏸️ PAUSE"
toggleMusicBtn.ZIndex = 53
toggleMusicBtn.Parent = postBoxFrame
Instance.new("UICorner", toggleMusicBtn).CornerRadius = UDim.new(0, 5)

local isPlayingMusic = backgroundMusic.IsPlaying
toggleMusicBtn.Activated:Connect(function()
    isPlayingMusic = not isPlayingMusic
    if isPlayingMusic then
        backgroundMusic:Play()
    else
        backgroundMusic:Pause()
    end
end)

-- Scrolling Song List Feed
local scrollSongFeed = Instance.new("ScrollingFrame")
scrollSongFeed.Size = UDim2.new(1, -30, 0, 235)
scrollSongFeed.Position = UDim2.new(0, 15, 0, 145)
scrollSongFeed.BackgroundColor3 = Color3.fromRGB(22, 26, 38)
scrollSongFeed.BorderSizePixel = 0
scrollSongFeed.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollSongFeed.ScrollBarThickness = 5
scrollSongFeed.ZIndex = 52
scrollSongFeed.Parent = musicFrame
Instance.new("UICorner", scrollSongFeed).CornerRadius = UDim.new(0, 8)

local songListLayout = Instance.new("UIListLayout")
songListLayout.SortOrder = Enum.SortOrder.LayoutOrder
songListLayout.Padding = UDim.new(0, 6)
songListLayout.Parent = scrollSongFeed

local function refreshSongFeed()
    for _, child in ipairs(scrollSongFeed:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    if db.songs then
        for idx, songData in ipairs(db.songs) do
            local songCard = Instance.new("Frame")
            songCard.Size = UDim2.new(1, -10, 0, 42)
            songCard.BackgroundColor3 = Color3.fromRGB(32, 38, 55)
            songCard.ZIndex = 53
            songCard.Parent = scrollSongFeed
            Instance.new("UICorner", songCard).CornerRadius = UDim.new(0, 6)

            local infoLbl = Instance.new("TextLabel")
            infoLbl.Size = UDim2.new(1, -70, 0, 42)
            infoLbl.Position = UDim2.new(0, 10, 0, 0)
            infoLbl.BackgroundTransparency = 1
            infoLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            infoLbl.TextSize = 10
            infoLbl.Font = Enum.Font.GothamBold
            infoLbl.Text = "🎵 " .. songData.title .. "\nNag-post: " .. (songData.postedBy or "Anon")
            infoLbl.TextXAlignment = Enum.TextXAlignment.Left
            infoLbl.ZIndex = 54
            infoLbl.Parent = songCard

            local playBtn = Instance.new("TextButton")
            playBtn.Size = UDim2.new(0, 50, 0, 28)
            playBtn.Position = UDim2.new(1, -55, 0, 7)
            playBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 120)
            playBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            playBtn.TextSize = 10
            playBtn.Font = Enum.Font.GothamBlack
            playBtn.Text = "▶️ TUGTOG"
            playBtn.ZIndex = 54
            playBtn.Parent = songCard
            Instance.new("UICorner", playBtn).CornerRadius = UDim.new(0, 5)

            playBtn.Activated:Connect(function()
                backgroundMusic:Stop()
                backgroundMusic.SoundId = "rbxassetid://" .. songData.id
                backgroundMusic:Play()
                isPlayingMusic = true
            end)
        end
    end
    scrollSongFeed.CanvasSize = UDim2.new(0, 0, 0, songListLayout.AbsoluteContentSize.Y + 10)
end

refreshSongFeed()

postSongBtn.Activated:Connect(function()
    local sName = songNameBox.Text
    local sId = songIdBox.Text
    local currentUser = getCurrentUser()

    if sName ~= "" and sId ~= "" and currentUser then
        if not db.songs then db.songs = {} end
        table.insert(db.songs, {
            title = sName,
            artist = "Custom",
            id = sId,
            postedBy = currentUser
        })
        saveDatabase(db)
        songNameBox.Text = ""
        songIdBox.Text = ""
        refreshSongFeed()
    end
end)

-- Home Screen Button
local backToHomeFromMusic = Instance.new("TextButton")
backToHomeFromMusic.Size = UDim2.new(1, -40, 0, 28)
backToHomeFromMusic.Position = UDim2.new(0, 20, 1, -38)
backToHomeFromMusic.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
backToHomeFromMusic.TextColor3 = Color3.fromRGB(255, 255, 255)
backToHomeFromMusic.TextSize = 11
backToHomeFromMusic.Font = Enum.Font.GothamBold
backToHomeFromMusic.Text = "🏠 HOME SCREEN"
backToHomeFromMusic.ZIndex = 52
backToHomeFromMusic.Parent = musicFrame
Instance.new("UICorner", backToHomeFromMusic).CornerRadius = UDim.new(0, 8)

backToHomeFromMusic.Activated:Connect(function()
    musicFrame:Destroy()
    showHome()
end)
