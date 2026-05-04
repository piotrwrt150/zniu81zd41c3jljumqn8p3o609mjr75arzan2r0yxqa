local UserInputService = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- --- Configuration & Theme ----------------------------------------------------
local THEME = {
    BG_MAIN      = Color3.fromRGB(15, 17, 21),
    PANEL        = Color3.fromRGB(30, 34, 43),
    ACCENT       = Color3.fromRGB(59, 130, 246),
    TEXT_MAIN    = Color3.fromRGB(229, 231, 235),
    TEXT_SEC     = Color3.fromRGB(156, 163, 175),
    TEXT_MUTED   = Color3.fromRGB(107, 114, 128),
    BTN_BG       = Color3.fromRGB(42, 47, 58),
    BTN_HOVER    = Color3.fromRGB(52, 57, 68),
    BORDER       = Color3.fromRGB(45, 45, 65),
    DANGER       = Color3.fromRGB(220, 38, 38),
    DANGER_HOVER = Color3.fromRGB(185, 28, 28)
}

-- --- Cleanup ------------------------------------------------------------------
if getgenv().EclipseHubGui then
    pcall(function() getgenv().EclipseHubGui:Destroy() end)
end

-- --- GUI Creation -------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = HttpService:GenerateGUID(false) -- Randomized name
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Enhanced Protection (gethui > protect_gui > CoreGui > PlayerGui)
if gethui then
    ScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
else
    local success = pcall(function() ScreenGui.Parent = CoreGui end)
    if not success then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
end
getgenv().EclipseHubGui = ScreenGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = HttpService:GenerateGUID(false) -- Randomized name
MainFrame.Size = UDim2.new(0, 550, 0, 450)
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -225)
MainFrame.BackgroundColor3 = THEME.BG_MAIN
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = THEME.BORDER
UIStroke.Thickness = 1
UIStroke.Parent = MainFrame

-- --- Dragging Logic -----------------------------------------------------------
local dragging, dragInput, dragStart, startPos
local function updateDrag(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then updateDrag(input) end
end)

-- --- Topbar & Tabs Layout -----------------------------------------------------
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 50)
TopBar.BackgroundTransparency = 1
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Text = "Eclipse Hub"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextColor3 = THEME.TEXT_MAIN
Title.Position = UDim2.new(0, 20, 0, 0)
Title.Size = UDim2.new(0, 150, 1, 0)
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(0, 250, 0, 32)
TabContainer.Position = UDim2.new(0, 160, 0, 9)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = TopBar

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.FillDirection = Enum.FillDirection.Horizontal
TabListLayout.Padding = UDim.new(0, 10)
TabListLayout.Parent = TabContainer

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -40, 1, -70)
ContentContainer.Position = UDim2.new(0, 20, 0, 60)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

-- --- UI Factory Functions -----------------------------------------------------
local Tabs = {}
local activeTab = nil

local function CreateTab(name, icon)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(0, 100, 1, 0)
    TabBtn.BackgroundColor3 = THEME.PANEL
    TabBtn.Text = icon .. "  " .. name
    TabBtn.Font = Enum.Font.GothamSemibold
    TabBtn.TextColor3 = THEME.TEXT_MUTED
    TabBtn.TextSize = 14
    TabBtn.AutoButtonColor = false
    TabBtn.Parent = TabContainer

    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 8)
    
    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.ScrollBarThickness = 4
    Page.Visible = false
    Page.BorderSizePixel = 0
    Page.Parent = ContentContainer

    local PageLayout = Instance.new("UIListLayout")
    PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PageLayout.Padding = UDim.new(0, 10)
    PageLayout.Parent = Page

    Tabs[name] = {Btn = TabBtn, Page = Page}

    TabBtn.MouseButton1Click:Connect(function()
        for tName, tab in pairs(Tabs) do
            tab.Page.Visible = (tName == name)
            TweenService:Create(tab.Btn, TweenInfo.new(0.3), {
                BackgroundColor3 = (tName == name) and THEME.ACCENT or THEME.PANEL,
                TextColor3 = (tName == name) and Color3.new(1,1,1) or THEME.TEXT_MUTED
            }):Play()
        end
    end)

    return Page
end

local function CreateCard(parent, titleStr, lines)
    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1, 0, 0, 40 + (#lines * 20))
    Card.BackgroundColor3 = THEME.PANEL
    Card.Parent = parent

    Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 8)
    local Stroke = Instance.new("UIStroke", Card)
    Stroke.Color = THEME.BORDER
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local Title = Instance.new("TextLabel")
    Title.Text = titleStr
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.TextColor3 = (titleStr:find("Good") and THEME.ACCENT or THEME.TEXT_MAIN)
    Title.Size = UDim2.new(1, -20, 0, 30)
    Title.Position = UDim2.new(0, 15, 0, 5)
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Card

    for i, lineText in ipairs(lines) do
        local Line = Instance.new("TextLabel")
        Line.Text = lineText
        Line.Font = Enum.Font.Gotham
        Line.TextSize = 14
        Line.TextColor3 = THEME.TEXT_SEC
        Line.Size = UDim2.new(1, -20, 0, 20)
        Line.Position = UDim2.new(0, 15, 0, 15 + (i * 20))
        Line.BackgroundTransparency = 1
        Line.TextXAlignment = Enum.TextXAlignment.Left
        Line.Parent = Card
    end
end

local function CreateButton(parent, text, subText, color, hoverColor, callback)
    local BtnColor = color or THEME.BTN_BG
    local HvrColor = hoverColor or THEME.BTN_HOVER

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 45)
    Btn.BackgroundColor3 = BtnColor
    Btn.Text = ""
    Btn.AutoButtonColor = false
    Btn.Parent = parent

    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)

    local Lbl = Instance.new("TextLabel")
    Lbl.Text = text
    Lbl.Font = Enum.Font.GothamSemibold
    Lbl.TextSize = 15
    Lbl.TextColor3 = THEME.TEXT_MAIN
    Lbl.Size = UDim2.new(0.5, 0, 1, 0)
    Lbl.Position = UDim2.new(0, 15, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Btn

    if subText then
        local Sub = Instance.new("TextLabel")
        Sub.Text = subText
        Sub.Font = Enum.Font.Gotham
        Sub.TextSize = 12
        Sub.TextColor3 = THEME.TEXT_MUTED
        Sub.Size = UDim2.new(0.5, -15, 1, 0)
        Sub.Position = UDim2.new(0.5, 0, 0, 0)
        Sub.BackgroundTransparency = 1
        Sub.TextXAlignment = Enum.TextXAlignment.Right
        Sub.Parent = Btn
    end

    -- Animations & Logic
    Btn.MouseEnter:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = HvrColor}):Play()
    end)
    Btn.MouseLeave:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = BtnColor}):Play()
    end)
    Btn.MouseButton1Click:Connect(callback)
end

-- --- Building the UI ----------------------------------------------------------

-- 1. Home Tab
local HomeTab = CreateTab("Home", "🏠")
CreateCard(HomeTab, "Good evening", {"Welcome to Eclipse Hub, " .. LocalPlayer.Name})
CreateCard(HomeTab, "Eclipse Hub", {"All Scripts are Tested Enough!", "Total Number of Games: 3"})
CreateCard(HomeTab, "ⓘ Info", {"Script Version: 2.0", "Rewritten with native UI for better performance."})

-- Unload Button
CreateButton(HomeTab, "UNLOAD HUB", "Closes script completely", THEME.DANGER, THEME.DANGER_HOVER, function()
    ScreenGui:Destroy()
    getgenv().EclipseHubGui = nil
end)

-- 2. Hubs Tab
local HubsTab = CreateTab("Hubs", "💻")

CreateButton(HubsTab, "Infinite Yield", "Admin Commands", nil, nil, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end)

CreateButton(HubsTab, "Dex Explorer", "Game Viewer", nil, nil, function()
    loadstring(game:HttpGet("https://obj.wearedevs.net/2/scripts/Dex%20Explorer.lua"))()
end)

CreateButton(HubsTab, "ScoutCheat Premium", "Combat & Visuals", nil, nil, function()
    local repoURL = "https://raw.githubusercontent.com/piotrwrt150/zniu81zd41c3jljumqn8p3o609mjr75arzan2r0yxqa/main/"
    loadstring(game:HttpGet(repoURL .. "src/ScoutCheat.lua"))()
end)

-- --- Initialization & Toggling ------------------------------------------------
-- Open Home Tab by default
Tabs["Home"].Btn.BackgroundColor3 = THEME.ACCENT
Tabs["Home"].Btn.TextColor3 = Color3.new(1,1,1)
Tabs["Home"].Page.Visible = true

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end)

print("[Eclipse Hub v2] Loaded! Press RightShift to toggle.")