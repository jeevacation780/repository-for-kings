local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local plr = Players.LocalPlayer
local request = request or http_request or (syn and syn.request)

local function deepcopy(value, seen)
    if type(value) ~= "table" then
        return value
    end

    seen = seen or {}

    if seen[value] then
        return seen[value]
    end

    local copy = {}
    seen[value] = copy

    for key, val in pairs(value) do
        copy[deepcopy(key, seen)] = deepcopy(val, seen)
    end

    return setmetatable(copy, getmetatable(value))
end

local function SaveConfig(CONFIGNAME, CONFIGSETTINGS_NON_JSON)
    local newconfigs = {}

    if isfile and isfile("catsakenconfigs.json") then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(readfile("catsakenconfigs.json"))
        end)

        if success and type(decoded) == "table" then
            newconfigs = deepcopy(decoded)
        end
    end

    newconfigs[CONFIGNAME] = deepcopy(CONFIGSETTINGS_NON_JSON)

    writefile(
        "catsakenconfigs.json",
        HttpService:JSONEncode(newconfigs)
    )
end

local GUI = Instance.new("ScreenGui")
GUI.Name = "ConfigBrowser"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.Parent = game:GetService("CoreGui")

local Shadow = Instance.new("Frame")
Shadow.Size = UDim2.fromScale(1, 1)
Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Shadow.BackgroundTransparency = 1
Shadow.BorderSizePixel = 0
Shadow.ZIndex = 1
Shadow.Parent = GUI

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(560, 500)
Main.Position = UDim2.fromScale(.5, .5)
Main.AnchorPoint = Vector2.new(.5, .5)
Main.BackgroundColor3 = Color3.fromRGB(17, 17, 21)
Main.BackgroundTransparency = 1
Main.BorderSizePixel = 0
Main.ZIndex = 2
Main.Parent = GUI

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 16)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(55, 55, 64)
Stroke.Transparency = 1
Stroke.Parent = Main

local Scale = Instance.new("UIScale")
Scale.Scale = .94
Scale.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -48, 0, 32)
Title.Position = UDim2.fromOffset(24, 20)
Title.BackgroundTransparency = 1
Title.Text = "Configuration Browser"
Title.TextColor3 = Color3.fromRGB(245, 245, 248)
Title.TextTransparency = 1
Title.TextSize = 22
Title.Font = Enum.Font.GothamSemibold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 3
Title.Parent = Main

local Sub = Instance.new("TextLabel")
Sub.Size = UDim2.new(1, -48, 0, 20)
Sub.Position = UDim2.fromOffset(24, 52)
Sub.BackgroundTransparency = 1
Sub.Text = "Search and save configurations shared by other users."
Sub.TextColor3 = Color3.fromRGB(135, 135, 145)
Sub.TextTransparency = 1
Sub.TextSize = 12
Sub.Font = Enum.Font.Gotham
Sub.TextXAlignment = Enum.TextXAlignment.Left
Sub.ZIndex = 3
Sub.Parent = Main

local Search = Instance.new("TextBox")
Search.Size = UDim2.new(1, -48, 0, 43)
Search.Position = UDim2.fromOffset(24, 83)
Search.BackgroundColor3 = Color3.fromRGB(24, 24, 29)
Search.BackgroundTransparency = 1
Search.BorderSizePixel = 0
Search.Text = ""
Search.PlaceholderText = "Search configurations..."
Search.PlaceholderColor3 = Color3.fromRGB(92, 92, 102)
Search.TextColor3 = Color3.fromRGB(235, 235, 240)
Search.TextTransparency = 1
Search.TextSize = 13
Search.Font = Enum.Font.Gotham
Search.ClearTextOnFocus = false
Search.TextXAlignment = Enum.TextXAlignment.Left
Search.ZIndex = 3
Search.Parent = Main

Instance.new("UICorner", Search).CornerRadius = UDim.new(0, 10)

local SearchPadding = Instance.new("UIPadding")
SearchPadding.PaddingLeft = UDim.new(0, 14)
SearchPadding.PaddingRight = UDim.new(0, 14)
SearchPadding.Parent = Search

local List = Instance.new("ScrollingFrame")
List.Size = UDim2.new(1, -48, 1, -150)
List.Position = UDim2.fromOffset(24, 137)
List.BackgroundTransparency = 1
List.BorderSizePixel = 0
List.ScrollBarThickness = 3
List.ScrollBarImageColor3 = Color3.fromRGB(65, 65, 75)
List.CanvasSize = UDim2.new()
List.AutomaticCanvasSize = Enum.AutomaticSize.Y
List.ZIndex = 3
List.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 8)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = List

local Padding = Instance.new("UIPadding")
Padding.PaddingBottom = UDim.new(0, 4)
Padding.Parent = List

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -48, 0, 18)
Status.Position = UDim2.new(0, 24, 1, -30)
Status.BackgroundTransparency = 1
Status.Text = "Loading configurations..."
Status.TextColor3 = Color3.fromRGB(110, 110, 120)
Status.TextTransparency = 1
Status.TextSize = 11
Status.Font = Enum.Font.Gotham
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.ZIndex = 3
Status.Parent = Main

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(30, 30)
Close.Position = UDim2.new(1, -42, 0, 18)
Close.BackgroundTransparency = 1
Close.Text = "×"
Close.TextColor3 = Color3.fromRGB(130, 130, 140)
Close.TextTransparency = 1
Close.TextSize = 22
Close.Font = Enum.Font.Gotham
Close.ZIndex = 4
Close.Parent = Main

local configs = {}
local closing = false

local function SetStatus(text, color)
    Status.Text = text
    Status.TextColor3 = color or Color3.fromRGB(110, 110, 120)
end

local function CreateConfig(config)
    local data = config.config_data

    if type(data) == "string" then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(data)
        end)

        if not success then
            return
        end

        data = decoded
    end

    if type(data) ~= "table" then
        return
    end

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -4, 0, 82)
    card.BackgroundColor3 = Color3.fromRGB(23, 23, 28)
    card.BackgroundTransparency = 1
    card.BorderSizePixel = 0
    card.ZIndex = 4
    card.Parent = List

    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 11)

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -145, 0, 22)
    name.Position = UDim2.fromOffset(14, 11)
    name.BackgroundTransparency = 1
    name.Text = tostring(config.name or "Unnamed")
    name.TextColor3 = Color3.fromRGB(235, 235, 240)
    name.TextSize = 14
    name.Font = Enum.Font.GothamSemibold
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.TextTruncate = Enum.TextTruncate.AtEnd
    name.ZIndex = 5
    name.Parent = card

    local description = Instance.new("TextLabel")
    description.Size = UDim2.new(1, -145, 0, 19)
    description.Position = UDim2.fromOffset(14, 34)
    description.BackgroundTransparency = 1
    description.Text = tostring(data.description or "No description")
    description.TextColor3 = Color3.fromRGB(125, 125, 135)
    description.TextSize = 11
    description.Font = Enum.Font.Gotham
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.TextTruncate = Enum.TextTruncate.AtEnd
    description.ZIndex = 5
    description.Parent = card

    local publisher = Instance.new("TextLabel")
    publisher.Size = UDim2.new(1, -145, 0, 15)
    publisher.Position = UDim2.fromOffset(14, 56)
    publisher.BackgroundTransparency = 1

    publisher.Text = data.anonymous
        and "Published anonymously"
        or ("Published by " .. tostring(data.username or "Unknown"))

    publisher.TextColor3 = Color3.fromRGB(90, 90, 100)
    publisher.TextSize = 10
    publisher.Font = Enum.Font.Gotham
    publisher.TextXAlignment = Enum.TextXAlignment.Left
    publisher.ZIndex = 5
    publisher.Parent = card

    local Save = Instance.new("TextButton")
    Save.Size = UDim2.fromOffset(100, 36)
    Save.Position = UDim2.new(1, -112, .5, -18)
    Save.BackgroundColor3 = Color3.fromRGB(0, 190, 160)
    Save.BackgroundTransparency = 0
    Save.BorderSizePixel = 0
    Save.Text = "Save"
    Save.TextColor3 = Color3.fromRGB(7, 25, 22)
    Save.TextSize = 12
    Save.Font = Enum.Font.GothamSemibold
    Save.AutoButtonColor = false
    Save.ZIndex = 5
    Save.Parent = card

    Instance.new("UICorner", Save).CornerRadius = UDim.new(0, 9)

    Save.MouseEnter:Connect(function()
        TweenService:Create(Save, TweenInfo.new(.15), {
            BackgroundColor3 = Color3.fromRGB(0, 215, 180)
        }):Play()
    end)

    Save.MouseLeave:Connect(function()
        TweenService:Create(Save, TweenInfo.new(.15), {
            BackgroundColor3 = Color3.fromRGB(0, 190, 160)
        }):Play()
    end)

    Save.MouseButton1Click:Connect(function()
        local CONFIGSETTINGS_NON_JSON = deepcopy(data)
        CONFIGSETTINGS_NON_JSON.anonymous = nil
        CONFIGSETTINGS_NON_JSON.username = nil
        CONFIGSETTINGS_NON_JSON.description = nil

        local success, err = pcall(function()
            SaveConfig(
                tostring(config.name),
                CONFIGSETTINGS_NON_JSON
            )
        end)

        if success then
            Save.Text = "Saved"
            Save.BackgroundColor3 = Color3.fromRGB(65, 190, 130)
            SetStatus(
                "Saved " .. tostring(config.name) .. " to catsakenconfigs.json.",
                Color3.fromRGB(80, 220, 180)
            )

            task.delay(1.2, function()
                if Save.Parent then
                    Save.Text = "Save"
                    Save.BackgroundColor3 = Color3.fromRGB(0, 190, 160)
                end
            end)
        else
            SetStatus(
                "Failed to save: " .. tostring(err),
                Color3.fromRGB(255, 100, 100)
            )
        end
    end)
end

local function Render()
    for _, child in ipairs(List:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local query = Search.Text:lower()
    local count = 0

    for _, config in ipairs(configs) do
        local name = tostring(config.name or ""):lower()
        local data = config.config_data

        if type(data) == "string" then
            local success, decoded = pcall(function()
                return HttpService:JSONDecode(data)
            end)

            if success then
                data = decoded
            end
        end

        local description = type(data) == "table"
            and tostring(data.description or ""):lower()
            or ""

        if query == ""
            or name:find(query, 1, true)
            or description:find(query, 1, true)
        then
            CreateConfig(config)
            count += 1
        end
    end

    SetStatus(
        count .. " configuration" .. (count == 1 and "" or "s") .. " found."
    )
end

local function LoadConfigs()
    SetStatus("Loading configurations...")

    local success, response = pcall(function()
        return request({
            Url = "https://config-manager.chieokure.workers.dev/",
            Method = "GET"
        })
    end)

    if not success then
        SetStatus(
            "Request failed: " .. tostring(response),
            Color3.fromRGB(255, 100, 100)
        )
        return
    end

    if response.StatusCode ~= 200 then
        SetStatus(
            "Server returned HTTP " .. tostring(response.StatusCode),
            Color3.fromRGB(255, 100, 100)
        )
        return
    end

    local decodeSuccess, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)

    if not decodeSuccess or type(data) ~= "table" then
        SetStatus(
            "Failed to decode server response.",
            Color3.fromRGB(255, 100, 100)
        )
        return
    end

    configs = data
    Render()
end

Search:GetPropertyChangedSignal("Text"):Connect(Render)

Close.MouseButton1Click:Connect(function()
    if closing then
        return
    end

    closing = true

    local info = TweenInfo.new(
        .28,
        Enum.EasingStyle.Quart,
        Enum.EasingDirection.In
    )

    TweenService:Create(Shadow, info, {
        BackgroundTransparency = 1
    }):Play()

    TweenService:Create(Main, info, {
        BackgroundTransparency = 1
    }):Play()

    TweenService:Create(Scale, info, {
        Scale = .94
    }):Play()

    TweenService:Create(Stroke, info, {
        Transparency = 1
    }):Play()

    for _, obj in ipairs(Main:GetDescendants()) do
        if obj:IsA("TextLabel")
            or obj:IsA("TextButton")
            or obj:IsA("TextBox")
        then
            TweenService:Create(obj, info, {
                TextTransparency = 1
            }):Play()
        end

        if obj:IsA("TextBox") then
            TweenService:Create(obj, info, {
                BackgroundTransparency = 1
            }):Play()
        elseif obj:IsA("TextButton") then
            TweenService:Create(obj, info, {
                BackgroundTransparency = 1
            }):Play()
        elseif obj:IsA("Frame") and obj ~= Main then
            TweenService:Create(obj, info, {
                BackgroundTransparency = 1
            }):Play()
        end
    end

    task.wait(.3)
    GUI:Destroy()
end)

-- opening animation
task.spawn(function()
    TweenService:Create(
        Shadow,
        TweenInfo.new(.3, Enum.EasingStyle.Quart),
        {BackgroundTransparency = .35}
    ):Play()

    TweenService:Create(
        Main,
        TweenInfo.new(.35, Enum.EasingStyle.Quart),
        {BackgroundTransparency = 0}
    ):Play()

    TweenService:Create(
        Scale,
        TweenInfo.new(.4, Enum.EasingStyle.Back),
        {Scale = 1}
    ):Play()

    TweenService:Create(
        Stroke,
        TweenInfo.new(.3),
        {Transparency = .25}
    ):Play()

    for _, obj in ipairs(Main:GetDescendants()) do
        if obj:IsA("TextLabel")
            or obj:IsA("TextButton")
            or obj:IsA("TextBox")
        then
            TweenService:Create(obj, TweenInfo.new(.3), {
                TextTransparency = 0
            }):Play()
        end

        if obj:IsA("TextBox") then
            TweenService:Create(obj, TweenInfo.new(.3), {
                BackgroundTransparency = 0
            }):Play()
        end
    end
end)

LoadConfigs()
