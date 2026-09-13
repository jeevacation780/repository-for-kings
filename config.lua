local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local plr = Players.LocalPlayer
local request = request or http_request or (syn and syn.request)

local GUI = Instance.new("ScreenGui")
GUI.Name = "ConfigPublisher"
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
Main.Size = UDim2.fromOffset(480, 455)
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
Stroke.Thickness = 1
Stroke.Parent = Main

local Scale = Instance.new("UIScale")
Scale.Scale = .94
Scale.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -48, 0, 32)
Title.Position = UDim2.fromOffset(24, 20)
Title.BackgroundTransparency = 1
Title.Text = "Publish Configuration"
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
Sub.Text = "Share your current Catsaken settings with others."
Sub.TextColor3 = Color3.fromRGB(135, 135, 145)
Sub.TextTransparency = 1
Sub.TextSize = 12
Sub.Font = Enum.Font.Gotham
Sub.TextXAlignment = Enum.TextXAlignment.Left
Sub.ZIndex = 3
Sub.Parent = Main

local function Label(text, y)
    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, -48, 0, 17)
    L.Position = UDim2.fromOffset(24, y)
    L.BackgroundTransparency = 1
    L.Text = text
    L.TextColor3 = Color3.fromRGB(175, 175, 185)
    L.TextTransparency = 1
    L.TextSize = 11
    L.Font = Enum.Font.GothamMedium
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.ZIndex = 3
    L.Parent = Main
    return L
end

local function Box(y, placeholder)
    local B = Instance.new("TextBox")
    B.Size = UDim2.new(1, -48, 0, 43)
    B.Position = UDim2.fromOffset(24, y)
    B.BackgroundColor3 = Color3.fromRGB(24, 24, 29)
    B.BackgroundTransparency = 1
    B.BorderSizePixel = 0
    B.Text = ""
    B.PlaceholderText = placeholder
    B.PlaceholderColor3 = Color3.fromRGB(92, 92, 102)
    B.TextColor3 = Color3.fromRGB(235, 235, 240)
    B.TextTransparency = 1
    B.TextSize = 13
    B.Font = Enum.Font.Gotham
    B.ClearTextOnFocus = false
    B.TextXAlignment = Enum.TextXAlignment.Left
    B.ZIndex = 3
    B.Parent = Main

    Instance.new("UICorner", B).CornerRadius = UDim.new(0, 10)

    local P = Instance.new("UIPadding")
    P.PaddingLeft = UDim.new(0, 13)
    P.PaddingRight = UDim.new(0, 13)
    P.Parent = B

    return B
end

Label("CONFIGURATION NAME", 86)
local NameBox = Box(106, "Enter a configuration name")

Label("DESCRIPTION", 163)
local DescBox = Box(183, "Tell people what this configuration does")

Label("PUBLISHER NAME", 240)
local UsernameBox = Box(260, "Enter the name you want displayed")

local Anon = Instance.new("Frame")
Anon.Size = UDim2.new(1, -48, 0, 42)
Anon.Position = UDim2.fromOffset(24, 313)
Anon.BackgroundTransparency = 1
Anon.ZIndex = 3
Anon.Parent = Main

local AnonText = Instance.new("TextLabel")
AnonText.Size = UDim2.new(1, -58, 0, 18)
AnonText.BackgroundTransparency = 1
AnonText.Text = "Publish anonymously"
AnonText.TextColor3 = Color3.fromRGB(220, 220, 225)
AnonText.TextTransparency = 1
AnonText.TextSize = 13
AnonText.Font = Enum.Font.GothamMedium
AnonText.TextXAlignment = Enum.TextXAlignment.Left
AnonText.ZIndex = 3
AnonText.Parent = Anon

local AnonSub = Instance.new("TextLabel")
AnonSub.Size = UDim2.new(1, -58, 0, 15)
AnonSub.Position = UDim2.fromOffset(0, 21)
AnonSub.BackgroundTransparency = 1
AnonSub.Text = "Hide the publisher name"
AnonSub.TextColor3 = Color3.fromRGB(105, 105, 115)
AnonSub.TextTransparency = 1
AnonSub.TextSize = 10
AnonSub.Font = Enum.Font.Gotham
AnonSub.TextXAlignment = Enum.TextXAlignment.Left
AnonSub.ZIndex = 3
AnonSub.Parent = Anon

local Toggle = Instance.new("TextButton")
Toggle.Size = UDim2.fromOffset(42, 24)
Toggle.Position = UDim2.new(1, -42, .5, -12)
Toggle.BackgroundColor3 = Color3.fromRGB(39, 39, 46)
Toggle.BackgroundTransparency = 1
Toggle.Text = ""
Toggle.AutoButtonColor = false
Toggle.ZIndex = 4
Toggle.Parent = Anon

Instance.new("UICorner", Toggle).CornerRadius = UDim.new(1, 0)

local Knob = Instance.new("Frame")
Knob.Size = UDim2.fromOffset(18, 18)
Knob.Position = UDim2.fromOffset(3, 3)
Knob.BackgroundColor3 = Color3.fromRGB(175, 175, 185)
Knob.BackgroundTransparency = 1
Knob.BorderSizePixel = 0
Knob.ZIndex = 5
Knob.Parent = Toggle

Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

local Anonymous = false

local function SetToggle(value)
    Anonymous = value

    TweenService:Create(Toggle, TweenInfo.new(.18), {
        BackgroundColor3 = value
            and Color3.fromRGB(0, 210, 175)
            or Color3.fromRGB(39, 39, 46)
    }):Play()

    TweenService:Create(Knob, TweenInfo.new(.18, Enum.EasingStyle.Quart), {
        Position = value
            and UDim2.fromOffset(21, 3)
            or UDim2.fromOffset(3, 3),

        BackgroundColor3 = value
            and Color3.fromRGB(255, 255, 255)
            or Color3.fromRGB(175, 175, 185)
    }):Play()
end

Toggle.MouseButton1Click:Connect(function()
    SetToggle(not Anonymous)
end)

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -48, 0, 18)
Status.Position = UDim2.fromOffset(24, 362)
Status.BackgroundTransparency = 1
Status.Text = ""
Status.TextColor3 = Color3.fromRGB(255, 100, 100)
Status.TextTransparency = 1
Status.TextSize = 11
Status.Font = Enum.Font.Gotham
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.ZIndex = 3
Status.Parent = Main

local Cancel = Instance.new("TextButton")
Cancel.Size = UDim2.fromOffset(115, 42)
Cancel.Position = UDim2.new(1, -270, 1, -62)
Cancel.BackgroundColor3 = Color3.fromRGB(27, 27, 33)
Cancel.BackgroundTransparency = 1
Cancel.BorderSizePixel = 0
Cancel.Text = "Cancel"
Cancel.TextColor3 = Color3.fromRGB(190, 190, 200)
Cancel.TextTransparency = 1
Cancel.TextSize = 13
Cancel.Font = Enum.Font.GothamMedium
Cancel.ZIndex = 3
Cancel.Parent = Main

Instance.new("UICorner", Cancel).CornerRadius = UDim.new(0, 10)

local Publish = Instance.new("TextButton")
Publish.Size = UDim2.fromOffset(135, 42)
Publish.Position = UDim2.new(1, -159, 1, -62)
Publish.BackgroundColor3 = Color3.fromRGB(0, 210, 175)
Publish.BackgroundTransparency = 1
Publish.BorderSizePixel = 0
Publish.Text = "Publish"
Publish.TextColor3 = Color3.fromRGB(8, 25, 22)
Publish.TextTransparency = 1
Publish.TextSize = 13
Publish.Font = Enum.Font.GothamSemibold
Publish.ZIndex = 3
Publish.Parent = Main

Instance.new("UICorner", Publish).CornerRadius = UDim.new(0, 10)

local closing = false

local function Close()
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

        if obj:IsA("TextBox") or obj:IsA("TextButton") then
            TweenService:Create(obj, info, {
                BackgroundTransparency = 1
            }):Play()
        end
    end

    task.wait(.3)
    GUI:Destroy()
end

Cancel.MouseButton1Click:Connect(Close)

Publish.MouseButton1Click:Connect(function()
    local name = NameBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    local description = DescBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    local username = UsernameBox.Text:gsub("^%s+", ""):gsub("%s+$", "")

    if #name < 10 then
        Status.Text = "Configuration name must be at least 10 characters."
        Status.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end

    if #description < 20 then
        Status.Text = "Description must be at least 20 characters."
        Status.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end

    if not Anonymous and #username < 1 then
        Status.Text = "Enter a publisher name or enable anonymous publishing."
        Status.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end

    Publish.Text = "Publishing..."
    Publish.Active = false
    Status.Text = ""

    local cfg = {}

    for flag, value in pairs(Catsaken.Flags) do
        cfg[flag] = value
    end

    cfg.anonymous = Anonymous
    cfg.username = username
    cfg.description = description

    local body = HttpService:JSONEncode({
        name = name,
        cfg = cfg
    })

    task.spawn(function()
        local success, response = pcall(function()
            return request({
                Url = "https://config-manager.chieokure.workers.dev/",
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = body
            })
        end)

        if not success then
            Publish.Text = "Publish"
            Publish.Active = true
            Status.Text = "Request failed: " .. tostring(response)
            return
        end

        if response.StatusCode == 201 then
            Publish.Text = "Published"
            Status.TextColor3 = Color3.fromRGB(80, 220, 180)
            Status.Text = "Configuration published successfully."

            task.wait(.8)
            Close()
            return
        end

        Publish.Text = "Publish"
        Publish.Active = true
        Status.TextColor3 = Color3.fromRGB(255, 100, 100)

        if response.StatusCode == 409 then
            Status.Text = "A configuration with this name already exists."
        elseif response.StatusCode == 403 then
            Status.Text = "This feature is not available for your executor."
        else
            Status.Text = response.Body or "Something went wrong."
        end
    end)
end)

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

        if obj:IsA("TextBox") or obj:IsA("TextButton") then
            TweenService:Create(obj, TweenInfo.new(.3), {
                BackgroundTransparency = 0
            }):Play()
        end
    end

    TweenService:Create(Knob, TweenInfo.new(.3), {
        BackgroundTransparency = 0
    }):Play()
end)
