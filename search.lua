local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local request = request or http_request or (syn and syn.request)

local function deepcopy(tbl)
    local copy = {}

    for i, v in pairs(tbl) do
        copy[i] = type(v) == "table" and deepcopy(v) or v
    end

    return copy
end

local function SaveConfig(name, settings)
    local newconfigs = {}

    if isfile("catsakenconfigs.json") then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(readfile("catsakenconfigs.json"))
        end)

        if success and type(decoded) == "table" then
            newconfigs = deepcopy(decoded)
        end
    end

    newconfigs[name] = deepcopy(settings)

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
Main.Size = UDim2.fromScale(.9, .82)
Main.Position = UDim2.fromScale(.5, .5)
Main.AnchorPoint = Vector2.new(.5, .5)
Main.BackgroundColor3 = Color3.fromRGB(17, 17, 21)
Main.BackgroundTransparency = 1
Main.BorderSizePixel = 0
Main.ZIndex = 2
Main.Parent = GUI

local SizeConstraint = Instance.new("UISizeConstraint")
SizeConstraint.MinSize = Vector2.new(320, 380)
SizeConstraint.MaxSize = Vector2.new(560, 520)
SizeConstraint.Parent = Main

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 16)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(55, 55, 64)
Stroke.Transparency = 1
Stroke.Thickness = 1
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
List.Size = UDim2.new(1, -48, 1, -154)
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

    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1, -4, 0, 82)
    Card.BackgroundColor3 = Color3.fromRGB(23, 23, 28)
    Card.BackgroundTransparency = 1
    Card.BorderSizePixel = 0
    Card.ZIndex = 4
    Card.Parent = List

    Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 11)

    local CardPadding = Instance.new("UIPadding")
    CardPadding.PaddingLeft = UDim.new(0, 14)
    CardPadding.PaddingRight = UDim.new(0, 12)
    CardPadding.Parent = Card

    local Name = Instance.new("TextLabel")
    Name.Size = UDim2.new(1, -118, 0, 21)
    Name.Position = UDim2.fromOffset(0, 9)
    Name.BackgroundTransparency = 1
    Name.Text = tostring(config.name or "Unnamed")
    Name.TextColor3 = Color3.fromRGB(235, 235, 240)
    Name.TextSize = 14
    Name.Font = Enum.Font.GothamSemibold
    Name.TextXAlignment = Enum.TextXAlignment.Left
    Name.TextTruncate = Enum.TextTruncate.AtEnd
    Name.ZIndex = 5
    Name.Parent = Card

    local Description = Instance.new("TextLabel")
    Description.Size = UDim2.new(1, -118, 0, 19)
    Description.Position = UDim2.fromOffset(0, 31)
    Description.BackgroundTransparency = 1
    Description.Text = tostring(data.description or "No description")
    Description.TextColor3 = Color3.fromRGB(125, 125, 135)
    Description.TextSize = 11
    Description.Font = Enum.Font.Gotham
    Description.TextXAlignment = Enum.TextXAlignment.Left
    Description.TextTruncate = Enum.TextTruncate.AtEnd
    Description.ZIndex = 5
    Description.Parent = Card

    local Publisher = Instance.new("TextLabel")
    Publisher.Size = UDim2.new(1, -118, 0, 15)
    Publisher.Position = UDim2.fromOffset(0, 53)
    Publisher.BackgroundTransparency = 1
    Publisher.Text = data.anonymous
        and "Published anonymously"
        or ("Published by " .. tostring(data.username or "Unknown"))
    Publisher.TextColor3 = Color3.fromRGB(90, 90, 100)
    Publisher.TextSize = 10
    Publisher.Font = Enum.Font.Gotham
    Publisher.TextXAlignment = Enum.TextXAlignment.Left
    Publisher.TextTruncate = Enum.TextTruncate.AtEnd
    Publisher.ZIndex = 5
    Publisher.Parent = Card

    local Save = Instance.new("TextButton")
    Save.Size = UDim2.fromOffset(92, 36)
    Save.Position = UDim2.new(1, -92, .5, -18)
    Save.BackgroundColor3 = Color3.fromRGB(0, 190, 160)
    Save.BorderSizePixel = 0
    Save.Text = "Save"
    Save.TextColor3 = Color3.fromRGB(7, 25, 22)
    Save.TextSize = 12
    Save.Font = Enum.Font.GothamSemibold
    Save.AutoButtonColor = false
    Save.ZIndex = 5
    Save.Parent = Card

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
        local settings = deepcopy(data)

        settings.anonymous = nil
        settings.username = nil
        settings.description = nil

        local success, err = pcall(function()
            SaveConfig(
                tostring(config.name),
                settings
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

    local successDecode, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)

    if not successDecode or type(data) ~= "table" then
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

local function CloseMenu()
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

        if obj:IsA("TextBox")
            or obj:IsA("TextButton")
            or obj:IsA("Frame")
        then
            if obj ~= Main then
                TweenService:Create(obj, info, {
                    BackgroundTransparency = 1
                }):Play()
            end
        end
    end

    task.wait(.3)
    GUI:Destroy()
end

Close.MouseButton1Click:Connect(CloseMenu)

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
