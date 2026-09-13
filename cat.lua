-- Date: 31/12/2025

-- patcher
function deepcopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[deepcopy(k)] = deepcopy(v)
    end
    return setmetatable(copy, getmetatable(t))
end
if isfile('catsakenconfigs.json') and not isfile("catsakenconfigfix.txt") then
    local newconfigs = deepcopy(game:GetService("HttpService"):JSONDecode(readfile('catsakenconfigs.json')))
    for i,v in pairs(newconfigs) do
        if v ~= "[]" then
            for ii,vv in pairs(v) do
                if vv.CurrentOption then
                    local updated = {}
                    for jj,ee in pairs(vv.CurrentOption) do
                        if ee == true then
                            updated[#updated+1] = jj
                        end
                    end
                    vv.CurrentOption = updated
                end
            end
        end
    end
    writefile("catsakenconfigs.json", game:GetService("HttpService"):JSONEncode(newconfigs))
end
writefile("catsakenconfigfix.txt", "")
if isfile('catsakenconfigs.json') and not isfile("catsakenconfigfix2.txt") then
    writefile("catsakenconfigs.json", readfile('catsakenconfigs.json')
        :gsub('"currentcfgname":{"CurrentOption"', '"currentcfgname":{"CurrentValue"')
        :gsub('"currentcfgname":{"CurrentValue":%[""%]', '"currentcfgname":{"CurrentValue":""')
    )
end
writefile("catsakenconfigfix2.txt", "")

_G.LUNAR_BACKGROUND = "https://github.com/aibabylaugh/catsaken/raw/main/catsakenbg.jpg"
_G.LUNAR_TITLE = nil
_G.SINGLE_COLUMNS = false
_G.UNLOCK_ANTICHEAT = true
local Env = getgenv()
local ShouldUseOldUI = isfile("BOOL_CATSAKEN_OLDUI")
if Env.executed then
    return Env.Rayfield:Notify({Title = "Catsaken", Content = "Already loaded! Trying to reload? Press the button in Miscallenous", Duration = 5})
end
Env.executed = true

local Hooks = {}
Env.OldHF = Env.OldHF or hookfunction
hookfunction = newcclosure(function(Func, New)
    if not pcall(function()
        print("[hooks] Replacing", debug.info(Func, "s") .. "/" .. tostring(debug.info(Func, "n")))
    end) then
        print("[hooks] print failed (hookfunction)")
    end
    table.insert(Hooks, Func)
    return Env.OldHF(Func, New)
end)
Env.OldRF = Env.OldRF or restorefunction
restorefunction = newcclosure(function(Func, New)
    if not pcall(function()
        print("[hooks] Restoring", debug.info(Func, "s") .. "/" .. tostring(debug.info(Func, "n")))
    end) then
        print("[hooks] print failed (restorefunction)")
    end
    local Hook = table.find(Hooks, Func)
    if Hook then
        table.remove(Hooks, Hook)
    end
    return Env.OldRF(Func, New)
end)

local RoEnv = getrenv()
hookfunction(RoEnv.debug.traceback, newcclosure(function(self, ...)
    return [[ReplicatedStorage.Systems.Character.Game.Sprinting:423: attempt to call a nil value
        Stack Begin
        Script 'LocalScript' Line 925 - function ToggleSprint
        Script 'LocalScript' Line 490
        Stack End]]
end))

local Unloaded = false
local LogService = game:GetService("LogService")
local ContentProvider = game:GetService('ContentProvider')
local Lighting = game:GetService('Lighting')
local RunService = game:GetService('RunService')
local HttpService = game:GetService('HttpService')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Stats = game:GetService('Stats')
local TweenService = game:GetService('TweenService')
local VirtualInputManager = game:GetService('VirtualInputManager')
local GuiService = game:GetService('GuiService')
local UserInputService = game:GetService('UserInputService')
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local SprintModule = require(ReplicatedStorage.Systems.Character.Game.Sprinting)
local FlowGame = require(ReplicatedStorage.Modules.Minigames.FlowGameManager.FlowGame)
local GetMousePos = require(ReplicatedStorage.Systems.Player.Miscellaneous.GetPlayerMousePosition).GetMousePos
local DirectionalSpeed = require(ReplicatedStorage.Systems.Character.QualityOfLife.DirectionalSpeed)
local DusekkarBehavior = require(ReplicatedStorage.Assets.Survivors.Dusekkar.Behavior)
local ShiftLockModule = require(ReplicatedStorage.Systems.Player.Game.SmoothShiftLock)
local SidebarHandler = require(ReplicatedStorage.Systems.Player.UI.SidebarHandler)
local VeeronicaConfig = require(ReplicatedStorage.Assets.Survivors.Veeronica.Config)
local CharacterReplication = require(ReplicatedStorage.Systems.Player.Game.CharacterReplication)
local TabbedOutScare = ReplicatedStorage.Systems.Player.Miscellaneous.TabbedOutScare
local TopbarPlus = require(ReplicatedStorage.Modules.Utilities.Icon)
local Ragdolls = require(ReplicatedStorage.Modules.Rendering.Ragdolls)
local PlayerControls = require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
-- Effects
local Effects_Slowness = require(ReplicatedStorage.Modules.Schematics.StatusEffects.Slowness)
local Effects_Subspace = require(ReplicatedStorage.Modules.Schematics.StatusEffects.SurvivorExclusive.Subspaced)
local Effects_Blindness = require(ReplicatedStorage.Modules.Schematics.StatusEffects.Blindness)
local Effects_Glitched = require(ReplicatedStorage.Modules.Schematics.StatusEffects.KillerExclusive.Glitched)
local Effects_Slateskin = require(ReplicatedStorage.Modules.Schematics.StatusEffects.Slateskin)
local Effects_Nausea = require(ReplicatedStorage.Modules.Schematics.StatusEffects.Nausea)
local Effects_Stunned = require(ReplicatedStorage.Modules.Schematics.StatusEffects.Stunned)
-- ////////////////////////
local VeeronicaBehavior = ReplicatedStorage.Assets.Survivors.Veeronica.Behavior
local AzureQTE = require(ReplicatedStorage.Assets.Killers.Azure.Config.cl_WorkaroundModules.cl_ConstructQTE)
local DoeConfig = require(ReplicatedStorage.Assets.Killers.JohnDoe.Config)
local Network = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("Network")
local NetworkModule = require(Network)
local ForsakenSettings = LocalPlayer:WaitForChild("PlayerData"):WaitForChild("Settings")
local TemporaryUI = LocalPlayer.PlayerGui.TemporaryUI
local PlayerInfoUI = TemporaryUI:FindFirstChild('PlayerInfo')
local Camera = workspace.CurrentCamera
local IngamePlayers = workspace.Players
local Survivors = IngamePlayers.Survivors
local Killers = IngamePlayers.Killers
local Spectators = IngamePlayers.Spectating
local RealDevice = _G.RealDevice or LocalPlayer:GetAttribute('Device')
_G.RealDevice = RealDevice
local wait = task.wait
local Images = {}
local IsVelocity = identifyexecutor():lower():find('velocity')
local CoreGui = game:GetService('CoreGui')
local ImagesUI = Instance.new('ScreenGui', IsVelocity and CoreGui or gethui())
local OldWarn = warn
local IsMobile = UserInputService.TouchEnabled == true and UserInputService.KeyboardEnabled == false
DoeConfig.CorruptEnergyWindup = 2

function randomstring(l)
    local str = ""
    local chars = ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"):split("")
    for i = 1, l or 16 do
        str = str .. chars[math.random(1, #chars)]
    end
    return str
end

-- anti tamper
if isfunctionhooked(pcall) then
    while true do end
end
local function kck(...)
    pcall(function(...)
        LocalPlayer.Kick(LocalPlayer, ...)
    end, ...)
end
local tamperfile = 'hsCyjZX3Xbh9QKBW4BqSUbABE5qv45Kg.png'
local blacklistfile = 'ip0OYAN3jRQfBzcZacahIhVkKNYpsOhg.png'
if not isfile(tamperfile) then
    writefile(tamperfile, '\0')
end
local function gettampers()
    local res = readfile(tamperfile)
    return string.byte(res)
end
local function itampered()
    local new = gettampers()+1
    writefile(tamperfile, string.char(new))
end
if gettampers() >= 3 then
    writefile(blacklistfile, tostring(os.time()))
end
local blacklist = isfile(blacklistfile) and tonumber(readfile(blacklistfile)) or 0
if blacklist > 0 then
    if os.time() - blacklist >= 86400 then
        delfile(blacklist)
    else
        kck("You have tampered with the script too many times. As a result, we have blacklisted you for 24 hours.")
        task.wait(1)
        while true do end
    end
end
local function getscreengui(p)
    if not p then
        return
    end
    if not p:IsA("ScreenGui") then
        return getscreengui(p.Parent)
    end
    return p
end
local tampersent = false
local function triggered()
    if tampersent then return end
    tampersent = true
    task.spawn(function()
        http.request({
            Method = "POST",
            Url = "https://tamper.chieokure.workers.dev/",
            Headers = {
                ['content-type'] = 'application/json'
            },
            Body = HttpService:JSONEncode({
                content = "TAMPER DETECTED\nBy " .. LocalPlayer.Name .. " (" .. LocalPlayer.UserId .. ")\nDevice: " .. (IsMobile and "Mobile" or "PC") .. "\nExecutor: " .. identifyexecutor()
            })
        })
    end)
    if isfunctionhooked(task.wait) then
        kck('T⁠a⁠m⁠p⁠e⁠r⁠ ⁠d⁠e⁠t⁠e⁠c⁠t⁠e⁠d\nU⁠n⁠l⁠o⁠a⁠d⁠ ⁠a⁠n⁠y⁠ ⁠e⁠x⁠t⁠e⁠r⁠n⁠a⁠l⁠ ⁠s⁠c⁠r⁠i⁠p⁠t⁠s⁠ ⁠(⁠h⁠t⁠t⁠p⁠ ⁠s⁠p⁠y⁠,⁠ ⁠r⁠e⁠m⁠o⁠t⁠e⁠ ⁠s⁠p⁠y⁠,⁠ ⁠e⁠t⁠c⁠)⁠ ⁠a⁠n⁠d⁠ ⁠t⁠r⁠y⁠ ⁠a⁠g⁠a⁠i⁠n⁠.')
        while true do end
    end
    warn(("NO THANK YOU\n"):rep(100))
    itampered()
    if gettampers() >= 3 then
        writefile(blacklistfile, tostring(os.time()))
        while true do kck("You have tampered with the script too many times. As a result, we have blacklisted you for 24 hours. Message mursufan1234 on discord") end
    end
    kck('T⁠a⁠m⁠p⁠e⁠r⁠ ⁠d⁠e⁠t⁠e⁠c⁠t⁠e⁠d\nU⁠n⁠l⁠o⁠a⁠d⁠ ⁠a⁠n⁠y⁠ ⁠e⁠x⁠t⁠e⁠r⁠n⁠a⁠l⁠ ⁠s⁠c⁠r⁠i⁠p⁠t⁠s⁠ ⁠(⁠h⁠t⁠t⁠p⁠ ⁠s⁠p⁠y⁠,⁠ ⁠r⁠e⁠m⁠o⁠t⁠e⁠ ⁠s⁠p⁠y⁠,⁠ ⁠e⁠t⁠c⁠)⁠ ⁠a⁠n⁠d⁠ ⁠t⁠r⁠y⁠ ⁠a⁠g⁠a⁠i⁠n⁠.')
    task.wait(1)
    while true do
        kck('T⁠a⁠m⁠p⁠e⁠r⁠ ⁠d⁠e⁠t⁠e⁠c⁠t⁠e⁠d\nU⁠n⁠l⁠o⁠a⁠d⁠ ⁠a⁠n⁠y⁠ ⁠e⁠x⁠t⁠e⁠r⁠n⁠a⁠l⁠ ⁠s⁠c⁠r⁠i⁠p⁠t⁠s⁠ ⁠(⁠h⁠t⁠t⁠p⁠ ⁠s⁠p⁠y⁠,⁠ ⁠r⁠e⁠m⁠o⁠t⁠e⁠ ⁠s⁠p⁠y⁠,⁠ ⁠e⁠t⁠c⁠)⁠ ⁠a⁠n⁠d⁠ ⁠t⁠r⁠y⁠ ⁠a⁠g⁠a⁠i⁠n⁠.')
    end
end
local old;
old = hookmetamethod(game, "__newindex", function(t, k, v)
    if k == "Text" and ((tostring(v):lower():find("http") and tostring(v):lower():find("spy")) or tostring(msg):lower():find("workers.dev") or tostring(v):lower():find("jeevacation780")) then
        getscreengui(t):Destroy()
        triggered()
    end
    return old(t, k, v)
end)
local old;
old = hookmetamethod(game, "__index", function(t, k)
    local real = old(t, k)
    if k == "Text" and ((tostring(real):lower():find("http") and tostring(real):lower():find("spy")) or tostring(msg):lower():find("workers.dev") or tostring(real):lower():find("jeevacation780")) then
        getscreengui(t):Destroy()
        triggered()
    end
    return real
end)
local old;
old = hookfunction(getconnections, newcclosure(function(signal)
    if signal == LogService.MessageOut then
        triggered()
    end
    return old(signal)
end))
local function msgout(msg)
    if ((tostring(msg):lower():find("http") and tostring(msg):lower():find("spy")) or tostring(msg):lower():find("workers.dev") or tostring(msg):lower():find("jeevacation780") or tostring(msg):lower():find("githubusercontent")) then
        triggered()
    end
end
game.DescendantAdded:Connect(function(v)
    if v:IsA("TextLabel") or v:IsA("TextButton") then
        local msg = v.Text
        if ((tostring(msg):lower():find("http") and tostring(msg):lower():find("spy")) or tostring(msg):lower():find("workers.dev") or tostring(msg):lower():find("jeevacation780") or tostring(msg):lower():find("githubusercontent")) then
            getscreengui(v)
            triggered()
        end
    end
end)
task.spawn(function()
    local s = randomstring()
    local s2 = randomstring()
    local s3 = randomstring()
    local n = 0
    getgenv()[s] = n
    getgenv()[s2] = n
    getgenv()[s3] = n
    while not Unloaded do
        pcall(function()
            if isfunctionhooked(msgout) then
                triggered()
            end
        end)
        pcall(function()
            loadstring("jeevacation780")()
        end)
        pcall(function()
            loadstring("workers.dev")()
        end)
        pcall(function()
            loadstring("githubusercontent")()
        end)
        getgenv()[s] = n + 1
        n = n + 1
        getgenv()[s2] = getgenv()[s]
        n = n + 1
        getgenv()[s3] = getgenv()[s] + 1
        n = math.random(2) + getgenv()[s3]
        RunService.Heartbeat:Wait()
    end
end)
task.spawn(function()
    while not Unloaded do
        pcall(function()
            pcall(function()
                game:HttpGet("https://raw.githusercontent/" .. randomstring(20))
            end )
            pcall(function()
                game:HttpGet("https://github.com/" .. randomstring(20))
            end)
            pcall(function()
                game:HttpGet("https://discord.com/api/webhook/" .. math.random(99999999) .. math.random(99999999) .. math.random(99999999) .. "/" .. randomstring(20))
            end)
            if isfunctionhooked(LogService.GetLogHistory) then
                triggered()
            end
            for i, data in pairs(LogService:GetLogHistory()) do
                local msg = data.message
                if ((tostring(msg):lower():find("http") and tostring(msg):lower():find("spy")) or tostring(msg):lower():find("jeevacation780") or tostring(msg):lower():find("githubusercontent")) then
                    triggered()
                end
            end
            task.wait(1)
        end)
    end
end)
local validatehmm = setmetatable({}, {
    __call = function(_,...)
        getgenv().ts90PxMpW2 = function(...)
            return ...
        end
        return 8447461017 + ...
    end,    
    __index = function(...)
        return function(...)
            return 1159814064, ...
        end
    end
})
getgenv().xAKmkytYgD = validatehmm
if not validatehmm(1) == 8447461018 then
    triggered()
end
hookmetamethod(validatehmm, '__call', function()
    return 2488846905
end)
if not validatehmm(0) == 2488846905 then
    triggered()
end
local le_result = {loadstring('local _=getgenv().xAKmkytYgD;return _:_(getgenv().ts90PxMpW2(...));')('Larry Page')}
if le_result[1] ~= 1159814064 then
    triggered()
end
if le_result[3] ~= 'Larry Page' then
    triggered()
end
if not pcall(function()
    if le_result[2].b()+5278493606 ~= 6438307670 then
        error('')
    end
end) then
    triggered()
end

local gotkicked = false
GuiService.ErrorMessageChanged:Connect(function(message)
    if gotkicked then return end
    local text = CoreGui:WaitForChild("RobloxPromptGui"):WaitForChild("promptOverlay"):WaitForChild("ErrorPrompt"):WaitForChild("MessageArea"):WaitForChild("ErrorFrame"):WaitForChild("ErrorMessage").Text
    warn(text)
    if text:lower():find("error code") then
        gotkicked = true
        http.request({
            Method = "POST",
            Url = "https://tamper.chieokure.workers.dev/",
            Headers = {
                ['content-type'] = 'application/json'
            },
            Body = HttpService:JSONEncode({
                content = "Kick: " .. text .. "\nDevice: " .. (IsMobile and "Mobile" or "PC") .. "\nExecutor: " .. identifyexecutor()
            })
        })
    end
end)

-- Every executor seems to implement Drawing differently or incorrectly :shrug:
local Drawing = loadstring(game:HttpGet('https://raw.githubusercontent.com/aibabylaugh/catsaken/refs/heads/main/drawing.lua'))()

local function warn(...)
    return OldWarn('[Catsaken]', ...)
end

local host = "https://github.com/lunar-repo/pic/raw/main/"
if not isfile("banner.png") then
    writefile("banner.png", game:HttpGet(host .. "banner.png"))
end

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- entire gui module
local SaveFileName = (isfile("catsakenautoload.txt") and readfile("catsakenautoload.txt")) or ("catsaken-default-" .. LocalPlayer.Name .. ".json")
local SaveTable = {}
local mainuimodule = not ShouldUseOldUI and (function()
    if isfile("catsakenconfigs.json") then
        SaveTable = HttpService:JSONDecode(readfile("catsakenconfigs.json"))[SaveFileName] or {}
    else
        writefile("catsakenconfigs.json", HttpService:JSONEncode({[SaveFileName] = {}}))
    end

    local Library = {}

    if RunService:IsStudio() then
        LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("debugUi"):Destroy()
    end

    -- lucide icons
    local Icons = RunService:IsStudio() and require(game:GetService("ReplicatedStorage").Icons) or loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/icons.lua"))()

    local function getIcon(name)
        if name:find("rbxasset") then
            local asset = {
                id = name,
                imageRectSize = Vector2.new(0,0),
                imageRectOffset = Vector2.new(0,0),
            }

            return asset
        end
        name = string.match(string.lower(name), "^%s*(.*)%s*$")
        local sizedicons = Icons['48px']
        local r = sizedicons[name]

        if not r then return end

        local rirs = r[2]
        local riro = r[3]

        local irs = Vector2.new(rirs[1], rirs[2])
        local iro = Vector2.new(riro[1], riro[2])

        local asset = {
            id = "rbxassetid://" .. r[1],
            imageRectSize = irs,
            imageRectOffset = iro,
        }

        return asset
    end

    local function addShadow(frame)
        local shadow = Instance.new("Frame")
        shadow.Size = UDim2.new(1, 0, 0, 80)
        shadow.Position = UDim2.new(0, 0, 1, -80)
        shadow.BackgroundColor3 = Color3.new(0, 0, 0)
        shadow.BackgroundTransparency = 0
        shadow.ZIndex = frame.ZIndex + 1
        shadow.Parent = frame.Parent
        
        local corner = Instance.new("UICorner", shadow)
        corner.CornerRadius = UDim.new(0, 5)
        
        local gradient = Instance.new("UIGradient")
        gradient.Rotation = 90
        gradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0.6),
        })
        gradient.Parent = shadow

        local function update()
            local atBottom = (frame.CanvasPosition.Y + frame.AbsoluteWindowSize.Y + 10)
                >= frame.AbsoluteCanvasSize.Y - 1
            TweenService:Create(shadow, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
                BackgroundTransparency = atBottom and 1 or 0
            }):Play()
        end

        frame:GetPropertyChangedSignal("CanvasPosition"):Connect(update)
        
        return shadow
    end

    local function createRipple(frame, x, y)
        local ripple = Instance.new("Frame")
        ripple.Name = "Ripple"
        ripple.AnchorPoint = Vector2.new(0.5, 0.5)
        ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ripple.BackgroundTransparency = 0.6
        ripple.BorderSizePixel = 0
        ripple.Position = UDim2.fromOffset(x, y)
        ripple.Size = UDim2.fromOffset(0, 0)
        ripple.ZIndex = frame.ZIndex + 1
        ripple.ClipsDescendants = false

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = ripple

        ripple.Parent = frame

        local absSize = frame.AbsoluteSize
        local maxDim = math.sqrt(absSize.X ^ 2 + absSize.Y ^ 2) * 0.2

        local TweenService = game:GetService("TweenService")
        local info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

        local expandTween = TweenService:Create(ripple, info, {
            Size = UDim2.fromOffset(maxDim, maxDim),
            BackgroundTransparency = 1,
        })

        expandTween:Play()
        expandTween.Completed:Connect(function()
            ripple:Destroy()
        end)
    end

    local function addCustomScrollbar(Frame)
        Frame.ScrollBarThickness = 0

        local Track = Instance.new("TextButton")
        Track.Name = "CustomScrollTrack"
        Track.Parent = Frame.Parent
        Track.AnchorPoint = Vector2.new(1, 0)
        Track.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Track.BackgroundTransparency = 0.450
        Track.BorderSizePixel = 0
        Track.ZIndex = Frame.ZIndex + 1
        Track.Text = ""

        local Bar = Instance.new("Frame")
        Bar.Name = "Bar"
        Bar.Parent = Track
        Bar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        Bar.BackgroundTransparency = 0.2
        Bar.BorderSizePixel = 0
        Bar.Size = UDim2.new(1, 0, 1, 0)
        Bar.Position = UDim2.new(0, 0, 0, 0)

        local THICKNESS = 16

        local function updateTrackPosition()
            Track.Position = UDim2.new(1, -2, 0, 0)
            Track.Size = UDim2.new(0, THICKNESS, 1, 0)
        end
        updateTrackPosition()

        local dragging = false
        local dragStartY = 0
        local dragStartCanvasY = 0

        local function updateBar()
            local canvasY = Frame.AbsoluteCanvasSize.Y
            local windowY = Frame.AbsoluteWindowSize.Y

            if canvasY <= windowY + 1 then
                Track.Visible = false
                return
            end
            Track.Visible = true

            local trackHeight = Track.AbsoluteSize.Y
            local barHeightScale = math.clamp(windowY / canvasY, 0.05, 1)
            local barHeightPx = math.max(trackHeight * barHeightScale, 20)

            local maxCanvasPos = canvasY - windowY
            local scrollAlpha = maxCanvasPos > 0 and (Frame.CanvasPosition.Y / maxCanvasPos) or 0
            local maxBarTravel = trackHeight - barHeightPx

            Bar.Size = UDim2.new(1, 0, 0, barHeightPx)
            Bar.Position = UDim2.new(0, 0, 0, maxBarTravel * scrollAlpha)
        end

        Frame:GetPropertyChangedSignal("CanvasPosition"):Connect(updateBar)
        Frame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateBar)
        Frame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updateBar)
        Track:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateBar)
        Frame:GetPropertyChangedSignal("AbsolutePosition"):Connect(updateTrackPosition)
        Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateTrackPosition)

        local function setScrollFromBarCenter(inputY)
            local trackPos = Track.AbsolutePosition.Y
            local trackHeight = Track.AbsoluteSize.Y
            local barHeightPx = Bar.AbsoluteSize.Y

            local canvasY = Frame.AbsoluteCanvasSize.Y
            local windowY = Frame.AbsoluteWindowSize.Y
            local maxCanvasPos = math.max(canvasY - windowY, 0)
            local maxBarTravel = math.max(trackHeight - barHeightPx, 1)

            local relativeY = math.clamp(inputY - trackPos - (barHeightPx / 2), 0, maxBarTravel)
            local alpha = relativeY / maxBarTravel
            Frame.CanvasPosition = Vector2.new(Frame.CanvasPosition.X, maxCanvasPos * alpha)
        end

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local canvasY = Frame.AbsoluteCanvasSize.Y
                local windowY = Frame.AbsoluteWindowSize.Y
                local maxCanvasPos = math.max(canvasY - windowY, 0)
                local trackHeight = Track.AbsoluteSize.Y
                local barHeightPx = Bar.AbsoluteSize.Y
                local maxBarTravel = math.max(trackHeight - barHeightPx, 1)

                local deltaY = input.Position.Y - dragStartY
                local deltaCanvas = (deltaY / maxBarTravel) * maxCanvasPos
                Frame.CanvasPosition = Vector2.new(Frame.CanvasPosition.X, math.clamp(dragStartCanvasY + deltaCanvas, 0, maxCanvasPos))
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        Track.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end

            local barPos = Bar.AbsolutePosition.Y
            local barSize = Bar.AbsoluteSize.Y
            local clickedOnBar = input.Position.Y >= barPos and input.Position.Y <= barPos + barSize

            if clickedOnBar then
                dragging = true
                dragStartY = input.Position.Y
                dragStartCanvasY = Frame.CanvasPosition.Y
            else
                setScrollFromBarCenter(input.Position.Y)
            end
        end)

        updateBar()

        return Track
    end

    local SmoothScroll = (function()
        local RS, UIS, CAS = game:GetService("RunService"), game:GetService("UserInputService"), game:GetService("ContextActionService")

        if not RS:IsClient() then
            error("SmoothScroll can only be used on the client")
        end

        local PlayerGui = RunService:IsStudio() and LocalPlayer:WaitForChild("PlayerGui") or CoreGui
        local Mouse		= LocalPlayer:GetMouse()
        local ipairs,pairs	= ipairs,pairs

        wait()

        local DEFAULT_SENS,DEFAULT_FRICT = Mouse.ViewSizeY/27, 0.78


        local Objects = {}
        local ScrollBarHolder
        local DraggingBar = false
        if not UIS.TouchEnabled then

            ScrollBarHolder = Instance.new("ScreenGui")
            ScrollBarHolder.Name = "SmoothScroll"
            ScrollBarHolder.Parent = PlayerGui

            RS.Heartbeat:Connect(function()
                for Frame, Info in pairs(Objects) do
                    if Info.Velocity > 0.05 or Info.Velocity < -0.05 then
                        Info.Velocity = Info.Velocity*Info.Frict				
                        if Info.Axis == "X" then
                            Frame.CanvasPosition = Vector2.new(Frame.CanvasPosition.X+Info.Velocity,Frame.CanvasPosition.Y)

                            if math.abs(Info.LastPos-Frame.CanvasPosition.X) == 0 then
                                Info.Velocity = 0
                            end
                            Info.LastPos = Frame.CanvasPosition.X
                        else
                            Frame.CanvasPosition = Vector2.new(Frame.CanvasPosition.X,Frame.CanvasPosition.Y+Info.Velocity)

                            if math.abs(Info.LastPos-Frame.CanvasPosition.Y) == 0 then
                                Info.Velocity = 0
                            end
                            Info.LastPos = Frame.CanvasPosition.Y
                        end
                    end
                end
            end)

            UIS.PointerAction:Connect(function(Wheel,Pan,Pinch,GP)
                if not DraggingBar then
                    local HoveredObjects = PlayerGui:GetGuiObjectsAtPosition(Mouse.X, Mouse.Y)	
                    for i, Frame in ipairs(HoveredObjects) do
                        local Info = Objects[Frame]

                        if Info and Info.Visibility.Visible == true then
                            Info.Velocity = Info.Velocity - (Info.Sens * Pan.Y * (Info.Inverted and -1 or 1))
                            break
                        end
                    end
                end
            end)

            CAS:BindActionAtPriority("SmoothScroll", function(Name,State,Input)

                if DraggingBar then return Enum.ContextActionResult.Pass end

                local Processed = false

                local HoveredObjects = PlayerGui:GetGuiObjectsAtPosition(Mouse.X, Mouse.Y)	
                for i, Frame in ipairs(HoveredObjects) do
                    local Info = Objects[Frame]

                    if Info and Info.Visibility.Visible == true then
                        Info.Velocity = Info.Velocity - (Info.Sens * Input.Position.Z * (Info.Inverted and -1 or 1))
                        Processed = true
                        break
                    end
                end

                return Processed and Enum.ContextActionResult.Sink or Enum.ContextActionResult.Pass

            end, false, 8000, Enum.UserInputType.MouseWheel)

        end

        local OnScreenTracker = {}
        OnScreenTracker.__index = OnScreenTracker

        function OnScreenTracker.new(obj)

            assert(typeof(obj) == "Instance" and obj:IsA("GuiObject"), "Argument #1 expected GuiObject")
            local visibleChanged = Instance.new("BindableEvent")

            local self = setmetatable({
                GuiObject = obj;
                Visible = nil;
                Changed = visibleChanged.Event;
                _path = {};
                _conn = {};
                _root = nil;
                _visibleChanged = visibleChanged;
            }, OnScreenTracker)

            local function CheckVisible()
                local vis = (self._root and self._root.Enabled or false)
                if (vis) then
                    local path = self._path
                    for i, p in ipairs(path) do
                        if (not p.Visible) then
                            vis = false
                            break
                        end
                    end
                end
                if (vis ~= self.Visible) then
                    self.Visible = vis
                    visibleChanged:Fire(vis)
                end
            end

            local function BuildAncestryPath()
                for _,c in ipairs(self._conn) do c:Disconnect() end
                local path = {}
                local conn = {}
                local root = nil
                local parent = obj
                while (parent and (parent:IsA("GuiObject") or parent:IsA("Folder"))) do
                    if parent:IsA("GuiObject") then
                        conn[#conn + 1] = parent:GetPropertyChangedSignal("Visible"):Connect(CheckVisible)
                        path[#path + 1] = parent
                    end
                    parent = parent.Parent
                end
                if (parent and parent:IsA("LayerCollector")) then
                    conn[#conn + 1] = parent:GetPropertyChangedSignal("Enabled"):Connect(CheckVisible)
                    root = parent
                end
                self._path = path
                self._conn = conn
                self._root = root
                CheckVisible()
            end

            self._ancestry = obj.AncestryChanged:Connect(function(child, parent)
                BuildAncestryPath()
            end)
            BuildAncestryPath()

            return self

        end

        function OnScreenTracker:Destroy()
            self._visibleChanged:Fire(false)
            self._visibleChanged:Destroy()
            self._ancestry:Disconnect()
            for _,c in ipairs(self._conn) do c:Disconnect() end
        end


        local function CreateBar(Frame,Axis)
            Axis = Axis or "Y"
            if not (Frame and typeof(Frame) == "Instance" and Frame.ClassName == "ScrollingFrame") then
                warn("Invalid frame to create custom bar")
                return
            end

            local Bar = Instance.new("TextButton")
            Bar.Name = Frame.Name.."_Scroller_"..Axis
            Bar.Text = ""
            Bar.BackgroundTransparency = 1
            Bar.Visible = Objects[Frame].Visibility.Visible

            local absSize,absPos,scrollThick = Frame.AbsoluteSize,Frame.AbsolutePosition,Frame.ScrollBarThickness

            local BarDrag
            Bar.MouseButton1Down:Connect(function()
                if not DraggingBar and not BarDrag then
                    DraggingBar = true

                    local LastPos = Vector2.new(Mouse.X,Mouse.Y)
                    BarDrag = UIS.InputChanged:Connect(function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseMovement then

                            local Pos = Vector2.new(Input.Position.X,Input.Position.Y)
                            local Delta = Pos-LastPos
                            local DeltaPercent = (Axis == "Y" and Delta.Y or Delta.X)/(Axis == "Y" and Frame.AbsoluteWindowSize.Y or Frame.AbsoluteWindowSize.X)

                            local Parent = Frame:FindFirstAncestorWhichIsA("GuiBase2d")

                            local CanvasSize = Vector2.new(
                                (Frame.CanvasSize.X.Scale*Parent.AbsoluteSize.X)+Frame.CanvasSize.X.Offset,
                                (Frame.CanvasSize.Y.Scale*Parent.AbsoluteSize.Y)+Frame.CanvasSize.Y.Offset
                            )

                            Frame.CanvasPosition = Vector2.new(Frame.CanvasPosition.X+(Axis == "X" and CanvasSize.X*DeltaPercent or 0),Frame.CanvasPosition.Y+(Axis == "Y" and CanvasSize.Y*DeltaPercent or 0))

                            LastPos = Pos
                        end
                    end)
                end
            end)
            local DragEnded = UIS.InputEnded:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 and BarDrag then
                    DraggingBar = false
                    BarDrag:Disconnect()
                    BarDrag = nil
                end
            end)

            Objects[Frame].Visibility.Changed:Connect(function(Visible)
                Bar.Visible = Visible

                if not Visible and BarDrag then
                    DraggingBar = false
                    BarDrag:Disconnect()
                    BarDrag = nil
                end
            end)

            if Axis == "X" then
                Bar.Size = UDim2.new(0,absSize.X,0,scrollThick)
                Bar.Position = UDim2.new(
                    0,absPos.X,
                    0,absPos.Y+absSize.Y-scrollThick
                )
            else
                Bar.Size = UDim2.new(0,scrollThick,0,absSize.Y)
                Bar.Position = UDim2.new(
                    0,Frame.VerticalScrollBarPosition == Enum.VerticalScrollBarPosition.Right and absPos.X+absSize.X-scrollThick or absPos.X,
                    0,absPos.Y
                )
            end

            local Updater
            Updater = Frame.Changed:Connect(function(Prop)
                if Objects[Frame] then
                    if Frame:FindFirstAncestorWhichIsA("GuiBase2d") then
                        if Prop == "AbsoluteSize" or Prop == "AbsolutePosition" or Prop == "AbsolutePosition" or Prop == "CanvasSize" or Prop == "ScrollBarThickness" then
                            absSize,absPos,scrollThick = Frame.AbsoluteSize,Frame.AbsolutePosition,Frame.ScrollBarThickness

                            if Axis == "X" then
                                Bar.Size = UDim2.new(0,absSize.X,0,scrollThick)
                                Bar.Position = UDim2.new(
                                    0,absPos.X,
                                    0,absPos.Y+absSize.Y-scrollThick
                                )
                            else
                                Bar.Size = UDim2.new(0,scrollThick,0,absSize.Y)
                                Bar.Position = UDim2.new(
                                    0,Frame.VerticalScrollBarPosition == Enum.VerticalScrollBarPosition.Right and absPos.X+absSize.X-scrollThick or absPos.X,
                                    0,absPos.Y
                                )
                            end
                        end

                    end
                else
                    Bar:Destroy()
                    Updater:Disconnect()
                    DragEnded:Disconnect()
                    if BarDrag then
                        BarDrag:Disconnect()
                        BarDrag = nil
                    end
                end
            end)

            Bar.Parent = ScrollBarHolder
        end

        local SmoothScroll = {}

        function SmoothScroll.Enable(Frame, Sensitivity, Friction, Inverted, Axis)
            if UIS.MouseEnabled and not UIS.TouchEnabled then

                if not (Frame and typeof(Frame) == "Instance" and Frame.ClassName == "ScrollingFrame") then
                    warn("Invalid frame to smooth")
                    return
                end

                if not Objects[Frame] then
                    Frame.ScrollingEnabled = false

                    local Actives,Connections = {},{}

                    for _,desc in ipairs(Frame:GetDescendants()) do
                        if desc:IsA("GuiObject") then
                            Actives[desc] = desc.Active
                            desc.Active = false
                            Connections[#Connections+1] = desc:GetPropertyChangedSignal("Active"):Connect(function()
                                desc.Active = false
                            end)
                        end
                    end

                    local parent = Frame
                    while (parent and (parent:IsA("GuiObject") or parent:IsA("Folder"))) do
                        if parent:IsA("GuiObject") then
                            Actives[parent] = parent.Active
                            parent.Active = false
                            Connections[#Connections+1] = parent:GetPropertyChangedSignal("Active"):Connect(function()
                                parent.Active = false
                            end)
                        end
                        parent = parent.Parent
                    end

                    Connections[#Connections+1] = Frame.DescendantAdded:Connect(function(desc)
                        if desc:IsA("GuiObject") then
                            Objects[Frame].Actives[desc] = desc.Active
                            desc.Active = false
                            Objects[Frame].Connections[#Objects[Frame].Connections+1] = desc:GetPropertyChangedSignal("Active"):Connect(function()
                                desc.Active = false
                            end)
                        end
                    end)


                    if Axis and (Axis == "X" or Axis == "Y") then
                    else
                        Axis = "Y" --Default to Y
                        if (Frame.CanvasSize.Y.Offset>0 or Frame.CanvasSize.Y.Scale>0) then
                            Axis = "Y"
                        elseif (Frame.CanvasSize.X.Offset>0 or Frame.CanvasSize.X.Scale>0) then
                            Axis = "X"
                        end
                    end

                    Objects[Frame] = {
                        Connections	= Connections;
                        Actives		= Actives;

                        Velocity	= 0;
                        LastPos		= 0;
                        Visibility	= OnScreenTracker.new(Frame);

                        Inverted	= Inverted;
                        Axis		= Axis;
                        Frict		= math.clamp(type(Friction)=="number" and Friction or DEFAULT_FRICT,0.2,0.99);
                        Sens		= math.clamp(type(Sensitivity)=="number" and Sensitivity or DEFAULT_SENS,0.01,99999999999999999);
                    }

                    CreateBar(Frame, "X")
                    CreateBar(Frame, "Y")
                else
                    Objects[Frame].Sens		= math.clamp(type(Sensitivity)=="number" and Sensitivity or DEFAULT_SENS,0.01,99999999999999999);
                    Objects[Frame].Frict	= math.clamp(type(Friction)=="number" and Friction or DEFAULT_FRICT,0.2,0.99);
                    Objects[Frame].Inverted	= Inverted
                end
            end
        end

        function SmoothScroll.Disable(Frame)

            if Objects[Frame] then
                Frame.ScrollingEnabled = true
                for i,c in ipairs(Objects[Frame].Connections) do
                    c:Disconnect()
                end
                Objects[Frame].Visibility:Destroy()
                for desc,a in pairs(Objects[Frame].Actives) do
                    desc.Active = a
                end

                Objects[Frame] = nil
            end

        end

        return SmoothScroll
    end)()

    local function AddDrag(Frame, DragBar)
        local dragToggle = nil
        local dragSpeed = 0.15
        local dragInput = nil
        local dragStart = nil
        local dragPos = nil
        local Delta
        local Position
        local startPos
        local function updateInput(input)
            Delta = input.Position - dragStart
            Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + Delta.X, startPos.Y.Scale, startPos.Y.Offset + Delta.Y)
            TweenService:Create(Frame, TweenInfo.new(0.05), {Position = Position}):Play()
        end
        DragBar.InputBegan:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and UserInputService:GetFocusedTextBox() == nil then
                dragToggle = true
                dragStart = input.Position
                startPos = Frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragToggle = false
                    end
                end)
            end
        end)
        DragBar.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragToggle then
                updateInput(input)
            end
        end)
    end

    Library.BlatantModeEnabled = Instance.new("BindableEvent")

    function Library:CreateWindow(Properties)
        local SpecialBackground = _G.LUNAR_BACKGROUND or getcustomasset("banner.png")
        local onimgupdate = function() end
        if not isfile("lunarbackgrounds") then
            makefolder("lunarbackgrounds")
        end
        function _G.UpdGuiBackground()
            SpecialBackground = _G.LUNAR_BACKGROUND
            if SpecialBackground then
                local filename = "lunarbackgrounds/" .. randomstring(10)
                if (SpecialBackground:find("https://") or SpecialBackground:find("http://")) and not SpecialBackground:match("http?.://roblox%.com") then
                    local content = game:HttpGet(SpecialBackground)
                    if content then
                        writefile(filename, content)
                        SpecialBackground = getcustomasset(filename) or getcustomasset("banner.png")
                    end
                end
            else
                SpecialBackground = getcustomasset("banner.png")
            end
            onimgupdate()
        end
        _G.UpdGuiBackground()
        local Name = Properties.Name
        local Icon = Properties.Icon
        if typeof(Icon) == "number" then
            Icon = "rbxassetid://" .. Icon
        end
        local uilibrary = Instance.new("ScreenGui")
        local MainFrame = Instance.new("Frame")
        local backgroundimagelabel = Instance.new("ImageLabel")
        local UICorner = Instance.new("UICorner")
        local Frame_2 = Instance.new("Frame")
        local UICorner_2 = Instance.new("UICorner")
        local ImageLabel = Instance.new("ImageLabel")
        local TextLabel = Instance.new("TextLabel")
        local search = Instance.new("Frame")
        local UICorner_3 = Instance.new("UICorner")
        local ImageLabel_2 = Instance.new("ImageLabel")
        local TextBox = Instance.new("TextBox")
        local UICorner_4 = Instance.new("UICorner")
        local Frame_3 = Instance.new("Frame")
        local NavigationBar = Instance.new("ScrollingFrame")
        local UIListLayout = Instance.new("UIListLayout")
        AddDrag(MainFrame, Frame_2)

        uilibrary.Name = game:GetService("HttpService"):GenerateGUID()
        uilibrary.Parent = not RunService:IsStudio() and gethui() or LocalPlayer.PlayerGui
        uilibrary.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        uilibrary.ResetOnSpawn = false
        uilibrary.Enabled = false
        uilibrary.OnTopOfCoreBlur = true
        uilibrary.DisplayOrder = (2^31)-1
        _G.globaluilibrary = uilibrary

        UserInputService.InputBegan:Connect(function(k,Gpe)
            if Unloaded then return end
            if Gpe then return end
            if k.KeyCode == Enum.KeyCode.F4 then
                if Env.MobileToggle.isSelected then
                    Env.MobileToggle:deselect()
                else
                    Env.MobileToggle:select()
                end
            end
        end)

        local Tooltip = Instance.new("Frame")
        local TooltipCorner = Instance.new("UICorner")
        local TooltipStroke = Instance.new("UIStroke")
        local TooltipPadding = Instance.new("UIPadding")
        local TooltipText = Instance.new("TextLabel")
        local TooltipScale = Instance.new("UIScale")

        Tooltip.Name = "Tooltip"
        Tooltip.Parent = uilibrary
        Tooltip.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        Tooltip.BackgroundTransparency = 0.05
        Tooltip.BorderSizePixel = 0
        Tooltip.Size = UDim2.fromOffset(220, 0)
        Tooltip.AutomaticSize = Enum.AutomaticSize.Y
        Tooltip.Visible = false
        Tooltip.ZIndex = 1000

        TooltipCorner.CornerRadius = UDim.new(0, 7)
        TooltipCorner.Parent = Tooltip

        TooltipStroke.Color = Color3.fromRGB(65, 65, 65)
        TooltipStroke.Thickness = 1
        TooltipStroke.Transparency = 0.15
        TooltipStroke.Parent = Tooltip

        TooltipPadding.PaddingLeft = UDim.new(0, 10)
        TooltipPadding.PaddingRight = UDim.new(0, 10)
        TooltipPadding.PaddingTop = UDim.new(0, 7)
        TooltipPadding.PaddingBottom = UDim.new(0, 7)
        TooltipPadding.Parent = Tooltip

        TooltipText.Parent = Tooltip
        TooltipText.BackgroundTransparency = 1
        TooltipText.BorderSizePixel = 0
        TooltipText.Size = UDim2.new(1, 0, 0, 0)
        TooltipText.AutomaticSize = Enum.AutomaticSize.Y
        TooltipText.Font = Enum.Font.Arial
        TooltipText.TextColor3 = Color3.fromRGB(220, 220, 220)
        TooltipText.TextSize = 12
        TooltipText.TextWrapped = true
        TooltipText.TextXAlignment = Enum.TextXAlignment.Left
        TooltipText.TextYAlignment = Enum.TextYAlignment.Top
        TooltipText.RichText = true
        TooltipText.ZIndex = 1001

        TooltipScale.Scale = 1
        TooltipScale.Parent = Tooltip

        local tooltipTarget = nil
        local tooltipText = nil
        local tooltipVisible = false
        local tooltipToken = 0
        local touchInput = nil

        local function getPointerPosition()
            if touchInput then
                return touchInput.Position
            end

            return UserInputService:GetMouseLocation()
        end

        local function positionTooltip()
            if not tooltipVisible then
                return
            end

            local camera = workspace.CurrentCamera
            if not camera then
                return
            end

            local viewport = camera.ViewportSize
            local mouse = getPointerPosition()

            local size = Tooltip.AbsoluteSize
            local padding = 14

            local x = mouse.X + padding
            local y = mouse.Y - size.Y - padding

            if x + size.X > viewport.X - 6 then
                x = mouse.X - size.X - padding
            end

            if y < 6 then
                y = mouse.Y + padding
            end

            x = math.clamp(x, 6, math.max(6, viewport.X - size.X - 6))
            y = math.clamp(y, 6, math.max(6, viewport.Y - size.Y - 6))

            Tooltip.Position = UDim2.fromOffset(x, y)
        end

        local function showTooltip(target, text)
            if not text or text == "" then
                return
            end

            tooltipToken += 1
            local token = tooltipToken

            tooltipTarget = target
            tooltipText = text
            tooltipVisible = true

            TooltipText.Text = text
            Tooltip.Visible = true

            TooltipScale.Scale = 0.96
            Tooltip.BackgroundTransparency = 0.05
            TooltipStroke.Transparency = 0.15

            task.defer(function()
                if token ~= tooltipToken or not tooltipVisible then
                    return
                end

                positionTooltip()

                TweenService:Create(
                    TooltipScale,
                    TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                    {Scale = 1}
                ):Play()
            end)
        end

        local function hideTooltip()
            tooltipToken += 1

            tooltipTarget = nil
            tooltipText = nil
            tooltipVisible = false
            touchInput = nil

            Tooltip.Visible = false
        end

        local function addToolTip(target, properties)
            if not target or not properties then
                return
            end

            local text = properties.ToolTip

            if not text or text == "" then
                return
            end

            target.Active = true

            target.MouseEnter:Connect(function()
                if IsMobile then
                    return
                end

                showTooltip(target, text)
            end)

            target.MouseLeave:Connect(function()
                if IsMobile then
                    return
                end

                if tooltipTarget == target then
                    hideTooltip()
                end
            end)

            target.InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.Touch then
                    return
                end

                touchInput = input

                tooltipToken += 1
                local token = tooltipToken

                task.delay(0.28, function()
                    if token ~= tooltipToken then
                        return
                    end

                    if touchInput ~= input then
                        return
                    end

                    showTooltip(target, text)
                end)
            end)

            target.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then
                    touchInput = input

                    if tooltipTarget == target then
                        positionTooltip()
                    end
                end
            end)

            target.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then
                    if touchInput == input then
                        hideTooltip()
                    end
                end
            end)
        end

        UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                if tooltipVisible then
                    positionTooltip()
                end
            elseif input.UserInputType == Enum.UserInputType.Touch then
                if tooltipVisible then
                    touchInput = input
                    positionTooltip()
                end
            end
        end)

        uilibrary.IgnoreGuiInset = true
        MainFrame.Parent = uilibrary
        MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        MainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        MainFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        MainFrame.BorderSizePixel = 0
        MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        MainFrame.Size = (IsMobile or _G.SINGLE_COLUMNS) and UDim2.new(0, 570, 0, IsMobile and uilibrary.AbsoluteSize.Y / 1.4) or UDim2.new(0, 890, 0, 460)

        UICorner.CornerRadius = UDim.new(0, 5)
        UICorner.Parent = MainFrame

        Frame_2.Parent = MainFrame
        Frame_2.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        Frame_2.BackgroundTransparency = 0.650
        Frame_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Frame_2.BorderSizePixel = 0
        Frame_2.Size = UDim2.new(1, 0, 0, 50)

        UICorner_2.CornerRadius = UDim.new(0, 5)
        UICorner_2.Parent = Frame_2

        ImageLabel.Parent = Frame_2
        ImageLabel.AnchorPoint = Vector2.new(0, 0.5)
        ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ImageLabel.BackgroundTransparency = 1.000
        ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ImageLabel.BorderSizePixel = 0
        ImageLabel.Position = UDim2.new(0, 3, 0.5, 0)
        ImageLabel.Size = UDim2.new(0, 36, 0, 36)
        ImageLabel.Image = Icon

        TextLabel.Parent = Frame_2
        TextLabel.AnchorPoint = Vector2.new(0, 0.5)
        TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.BackgroundTransparency = 1.000
        TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TextLabel.BorderSizePixel = 0
        TextLabel.Position = UDim2.new(0, 50, 0.5, 0)
        TextLabel.Size = UDim2.new(0, 200, 0, 20)
        TextLabel.FontFace = Font.fromName("Arial", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        TextLabel.Text = Name
        TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.TextSize = 12.000
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        function _G.UpdGuiTitle()
            TextLabel.Text = type(_G.LUNAR_TITLE) == "string" and _G.LUNAR_TITLE or Name
        end

        search.Name = "search"
        search.Parent = Frame_2
        search.AnchorPoint = Vector2.new(1, 0.5)
        search.BackgroundColor3 = Color3.fromRGB(140, 85, 15)
        search.BackgroundTransparency = 0.650
        search.BorderColor3 = Color3.fromRGB(0, 0, 0)
        search.BorderSizePixel = 0
        search.Position = UDim2.new(1, -11, 0.5, 0)
        search.Size = UDim2.new(0, 139, 1, -24)

        UICorner_3.CornerRadius = UDim.new(0, 5)
        UICorner_3.Parent = search

        local searchasset = getIcon("search")
        ImageLabel_2.Parent = search
        ImageLabel_2.AnchorPoint = Vector2.new(1, 0.5)
        ImageLabel_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ImageLabel_2.BackgroundTransparency = 1.000
        ImageLabel_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ImageLabel_2.BorderSizePixel = 0
        ImageLabel_2.Position = UDim2.new(1, -6, 0.5, 0)
        ImageLabel_2.Size = UDim2.new(0, 16, 0, 16)
        ImageLabel_2.Image = searchasset.id
        ImageLabel_2.ImageRectOffset = searchasset.imageRectOffset
        ImageLabel_2.ImageRectSize = searchasset.imageRectSize

        TextBox.Parent = search
        TextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TextBox.BackgroundTransparency = 1.000
        TextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TextBox.BorderSizePixel = 0
        TextBox.ClipsDescendants = true
        TextBox.Position = UDim2.new(0, 4, 0, 0)
        TextBox.Size = UDim2.new(1, -34, 1, 0)
        TextBox.Font = Enum.Font.ArialBold
        TextBox.PlaceholderText = "Search"
        TextBox.Text = ""
        TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        TextBox.TextSize = 14.000
        TextBox.TextXAlignment = Enum.TextXAlignment.Left

        backgroundimagelabel.Name = "backgroundimagelabel"
        backgroundimagelabel.Parent = MainFrame
        backgroundimagelabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        backgroundimagelabel.BackgroundTransparency = 1.00
        backgroundimagelabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
        backgroundimagelabel.BorderSizePixel = 0
        backgroundimagelabel.Size = UDim2.new(1, 0, 1, 0)
        backgroundimagelabel.ZIndex = 0
        backgroundimagelabel.Image = SpecialBackground
        backgroundimagelabel.ImageColor3 = Color3.fromRGB(116, 116, 116)
        backgroundimagelabel.ScaleType = Enum.ScaleType.Crop
        onimgupdate = function()
            backgroundimagelabel.Image = SpecialBackground or getcustomasset("banner.png")
        end

        UICorner_4.CornerRadius = UDim.new(0, 5)
        UICorner_4.Parent = backgroundimagelabel

        Frame_3.Parent = MainFrame
        Frame_3.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        Frame_3.BackgroundTransparency = 0.650
        Frame_3.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Frame_3.BorderSizePixel = 0
        Frame_3.Position = UDim2.new(0, 1, 0, 50)
        Frame_3.Size = UDim2.new(0, 160, 1, -50)

        NavigationBar.Parent = Frame_3
        NavigationBar.Active = true
        NavigationBar.AnchorPoint = Vector2.new(0, 0.5)
        NavigationBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        NavigationBar.BackgroundTransparency = 1.000
        NavigationBar.BorderColor3 = Color3.fromRGB(0, 0, 0)
        NavigationBar.BorderSizePixel = 0
        NavigationBar.Position = UDim2.new(0, 0, 0.5, 0)
        NavigationBar.Size = UDim2.new(1, 0, 1, -6)
        NavigationBar.ScrollBarThickness = 2
        NavigationBar.ScrollBarImageColor3 = Color3.fromRGB(245, 159, 39)
        NavigationBar.ScrollBarImageTransparency = 0.4
        NavigationBar.CanvasSize = UDim2.new(0, 0, 0, 0)
        NavigationBar.AutomaticCanvasSize = Enum.AutomaticSize.Y
        NavigationBar.ScrollingDirection = Enum.ScrollingDirection.Y
        NavigationBar.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
        NavigationBar.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
        NavigationBar.ClipsDescendants = true
        addShadow(NavigationBar)
        SmoothScroll.Enable(NavigationBar, 2, 0.9)

        UIListLayout.Parent = NavigationBar
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Padding = UDim.new(0, 4)
        
        local PageHolder = Instance.new("Frame")
        PageHolder.Name = "PageHolder"
        PageHolder.Parent = MainFrame
        PageHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        PageHolder.BackgroundTransparency = 1.000
        PageHolder.BorderColor3 = Color3.fromRGB(0, 0, 0)
        PageHolder.BorderSizePixel = 0
        PageHolder.Position = UDim2.new(0, 161, 0, 50)
        PageHolder.Size = UDim2.new(1, -159, 1, -60)
        PageHolder.ClipsDescendants = true
        
        local Window = {}
        local TabStore = {}

        local function scoreMatch(feature, query)
            local fl = feature:lower()
            local score = 0

            if fl == query then return 100 end

            -- Multi-word: all words must appear
            local queryWords = {}
            for w in query:gmatch("%S+") do table.insert(queryWords, w) end

            if #queryWords > 1 then
                for _, qw in ipairs(queryWords) do
                    if not fl:find(qw, 1, true) then return 0 end
                    score = score + 1
                end
                -- Bonus: feature contains exact full query as substring
                if fl:find(query, 1, true) then score = score + 3 end
                if fl == query then return 100 end
                score = score - (#fl / 20)
                return score
            end

            -- Single word path (your existing logic)
            local s = fl:find(query, 1, true)
            if not s then return 0 end
            score = score + 1
            if s == 1 then score = score + 4 end
            for word in fl:gmatch("%S+") do
                if word:sub(1, #query) == query then score = score + 3; break end
                if word == query then score = score + 5; break end
            end
            score = score - (#fl / 20)
            return score
        end

        local function search(query)
            query = query:lower()
            local bestScore = 0
            local bestTab = nil

            for i, v in pairs(TabStore) do
                local tabScore = 0
                for _, f in pairs(v.Features) do
                    tabScore = tabScore + scoreMatch(f, query)
                end
                v.Frame.Visible = tabScore > 0
                if tabScore > bestScore then
                    bestScore = tabScore
                    bestTab = i
                end
            end

            if bestTab then
                Window:SelectTab(bestTab)
            end
        end

        TextBox:GetPropertyChangedSignal("Text"):Connect(function()
            local text = TextBox.Text
            if text ~= "" then
                search(text)
            else
                for _, v in pairs(TabStore) do
                    v.Frame.Visible = true
                end
            end
        end)
        
        function Window:CreateTab(Name, Icon)
            local TabButton = Instance.new("Frame")
            local Frame = Instance.new("Frame")
            local TextLabel = Instance.new("TextLabel")
            local ImageLabel = Instance.new("ImageLabel")
            local Asset = getIcon(Icon)
            local Page = Instance.new("Frame")
            local NFrame = Instance.new("Frame")
            local NTextLabel = Instance.new("TextLabel")
            local LeftScrolling = Instance.new("ScrollingFrame")
            local RightScrolling = Instance.new("ScrollingFrame")
            local LeftListLayout = Instance.new("UIListLayout")
            local RightListLayout = Instance.new("UIListLayout")
            local ScrollingFrame = LeftScrolling

            Page.Name = "Page"
            Page.Parent = PageHolder
            Page.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Page.BackgroundTransparency = 1.000
            Page.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Page.BorderSizePixel = 0
            Page.Position = UDim2.new(0, 0, 0, -30)
            Page.Size = UDim2.new(1, 0, 1, 0)
            Page.Visible = false

            NFrame.Parent = Page
            NFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            NFrame.BackgroundTransparency = 0.750
            NFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
            NFrame.BorderSizePixel = 0
            NFrame.Size = UDim2.new(1, -1, 0, 28)
            NFrame.Position = UDim2.fromOffset(-1, 0)

            NTextLabel.Parent = NFrame
            NTextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
            NTextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            NTextLabel.BackgroundTransparency = 1.000
            NTextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
            NTextLabel.BorderSizePixel = 0
            NTextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
            NTextLabel.Size = UDim2.new(1, 0, 1, 0)
            NTextLabel.Font = Enum.Font.ArialBold
            NTextLabel.Text = Name
            NTextLabel.TextColor3 = Color3.fromRGB(255, 190, 80)
            NTextLabel.TextSize = 13.000

            for _, sf in ipairs({LeftScrolling, RightScrolling}) do
                sf.Parent = Page
                sf.Active = true
                sf.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                sf.BackgroundTransparency = 1.000
                sf.BorderColor3 = Color3.fromRGB(0, 0, 0)
                sf.BorderSizePixel = 0
                sf.ScrollBarThickness = 0
                sf.CanvasSize = UDim2.new(0, 0, 0, 0)
                sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
                sf.ScrollingDirection = Enum.ScrollingDirection.Y
                sf.ClipsDescendants = true
                if IsMobile then
                    sf.ScrollingEnabled = false
                end
                SmoothScroll.Enable(sf, 4, 0.9)
            end

            LeftScrolling.Position = UDim2.new(0, 0, 0, 28)
            local padding = Instance.new("UIPadding")
            padding.PaddingLeft = UDim.new(0, 6)
            padding.Parent = LeftScrolling
            if IsMobile or _G.SINGLE_COLUMNS then
                LeftScrolling.Size = UDim2.new(1, 0, 1, -28)
                RightScrolling.Visible = false
            else
                LeftScrolling.Size = UDim2.new(0.5, -4, 1, -28)
                RightScrolling.Position = UDim2.new(0.5, 4, 0, 28)
                RightScrolling.Size = UDim2.new(0.5, -4, 1, -28)
            end

            for _, pair in ipairs({{LeftListLayout, LeftScrolling}, {RightListLayout, RightScrolling}}) do
                local layout, sf = pair[1], pair[2]
                layout.Parent = sf
                layout.SortOrder = Enum.SortOrder.LayoutOrder
                if IsMobile or _G.SINGLE_COLUMNS then
                    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
                end
                layout.Padding = UDim.new(0, 3)
            end

            TabButton.Name = "TabButton"
            TabButton.Parent = NavigationBar
            TabButton.BackgroundColor3 = Color3.fromRGB(110, 65, 5)
            TabButton.BackgroundTransparency = 1.000
            TabButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
            TabButton.BorderSizePixel = 0
            TabButton.Size = UDim2.new(1, -4, 0, 35)

            Frame.Parent = TabButton
            Frame.BackgroundColor3 = Color3.fromRGB(255, 190, 80)
            Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Frame.BorderSizePixel = 0
            Frame.AnchorPoint = Vector2.new(0, 0)
            Frame.Position = UDim2.new(0, 0, 0, 0)
            Frame.Size = UDim2.new(0, 1, 0, 0)

            TextLabel.Parent = TabButton
            TextLabel.AnchorPoint = Vector2.new(0, 0.5)
            TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TextLabel.BackgroundTransparency = 1.000
            TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
            TextLabel.BorderSizePixel = 0
            TextLabel.Position = UDim2.new(0, 30, 0.5, 0)
            TextLabel.Size = UDim2.new(0, 200, 0, 20)
            TextLabel.Font = Enum.Font.ArialBold
            TextLabel.Text = Name
            TextLabel.TextColor3 = Color3.fromRGB(161, 161, 161)
            TextLabel.TextSize = 13.000
            TextLabel.TextXAlignment = Enum.TextXAlignment.Left

            ImageLabel.Parent = TabButton
            ImageLabel.AnchorPoint = Vector2.new(0, 0.5)
            ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ImageLabel.BackgroundTransparency = 1.000
            ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
            ImageLabel.BorderSizePixel = 0
            ImageLabel.Position = UDim2.new(0, 7, 0.5, 0)
            ImageLabel.Size = UDim2.new(0, 16, 0, 16)
            ImageLabel.Image = Asset.id
            ImageLabel.ImageColor3 = Color3.fromRGB(161, 161, 161)
            ImageLabel.ImageRectOffset = Asset.imageRectOffset
            ImageLabel.ImageRectSize = Asset.imageRectSize
            ImageLabel.ScaleType = Enum.ScaleType.Fit

            local TInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
            local sepTween = nil

            local function SetSepAnchor(anchorY)
                Frame.AnchorPoint = Vector2.new(0, anchorY)
                Frame.Position = UDim2.new(0, Frame.Position.X.Offset, anchorY, Frame.Position.Y.Offset)
            end

            local function DeselectDirectional(goingDown, callback)
                Page.Position = UDim2.new(0, 0, 0, -10)
                Page.Visible = false
                TweenService:Create(TabButton, TInfo, {BackgroundTransparency = 1}):Play()
                TweenService:Create(TextLabel, TInfo, {TextColor3 = Color3.fromRGB(161, 161, 161)}):Play()
                TweenService:Create(ImageLabel, TInfo, {ImageColor3 = Color3.fromRGB(161, 161, 161)}):Play()
                SetSepAnchor(goingDown and 1 or 0) -- shrink toward new tab
                if sepTween then sepTween:Cancel() end
                sepTween = TweenService:Create(Frame, TInfo, {Size = UDim2.new(0, 1, 0, 0)})
                if callback then
                    sepTween.Completed:Connect(callback)
                end
                sepTween:Play()
            end

            local function SelectDirectional(goingDown)
                Page.Visible = true
                TweenService:Create(Page, TweenInfo.new(0.2), {Position = UDim2.fromOffset(0, 0)}):Play()
                TweenService:Create(TabButton, TInfo, {BackgroundTransparency = 0.65}):Play()
                TweenService:Create(TextLabel, TInfo, {TextColor3 = Color3.fromRGB(255, 190, 80)}):Play()
                TweenService:Create(ImageLabel, TInfo, {ImageColor3 = Color3.fromRGB(255, 190, 80)}):Play()
                SetSepAnchor(goingDown and 0 or 1) -- grow from direction it came from
                if sepTween then sepTween:Cancel() end
                Frame.Size = UDim2.new(0, 1, 0, 0)
                sepTween = TweenService:Create(Frame, TInfo, {Size = UDim2.new(0, 1, 1, 0)})
                sepTween:Play()
            end

            local this = {
                IsSelected = false,
                Frame = TabButton,
                Deselect = function() DeselectDirectional(true, nil) end,
                Select = function() SelectDirectional(true) end,
                DeselectDirectional = DeselectDirectional,
                SelectDirectional = SelectDirectional,
                Index = #TabStore + 1,
                Features = {},
                NumSections = 0,
                AutoIndex = 0
            }
            TabStore[#TabStore+1] = this

            local Click = Instance.new("TextButton")
            Click.Parent = TabButton
            Click.Text = ""
            Click.ZIndex = 2
            Click.BackgroundTransparency = 1
            Click.BorderSizePixel = 0
            Click.Size = UDim2.fromScale(1, 1)

            local function onClick()
                if this.IsSelected then return end

                local goingDown = true
                local prevTab = nil
                for _, v in pairs(TabStore) do
                    if v.IsSelected then
                        goingDown = this.Index > v.Index
                        prevTab = v
                        break
                    end
                end

                for _, v in pairs(TabStore) do
                    v.IsSelected = false
                end
                this.IsSelected = true

                if prevTab then
                    prevTab.DeselectDirectional(goingDown, function()
                        if this.IsSelected then
                            SelectDirectional(goingDown)
                        end
                    end)
                else
                    SelectDirectional(goingDown)
                end
            end

            Click.MouseEnter:Connect(function()
                this.IsHover = true
                if not this.IsSelected then
                    TweenService:Create(TabButton, TInfo, {BackgroundTransparency = 0.8}):Play()
                end
            end)

            Click.MouseLeave:Connect(function()
                this.IsHover = false
                if not this.IsSelected then
                    TweenService:Create(TabButton, TInfo, {BackgroundTransparency = 1}):Play()
                end
            end)
            
            Click.MouseButton1Down:Connect(function()
                if not this.IsSelected then
                    TweenService:Create(TabButton, TInfo, {BackgroundTransparency = 0.7}):Play()
                end
            end)
            
            Click.MouseButton1Up:Connect(function()
                if not this.IsSelected then
                    if this.IsHover then
                        TweenService:Create(TabButton, TInfo, {BackgroundTransparency = 0.8}):Play()
                    else
                        TweenService:Create(TabButton, TInfo, {BackgroundTransparency = 1}):Play()
                    end
                end
            end)
            
            Click.MouseButton1Click:Connect(onClick)
            
            local Tab = {}

            local HiddenHolder = Instance.new("Folder")
            HiddenHolder.Name = "HiddenElements"

            this.CurrentSection = nil
            this.CurrentSectionIndex = this.CurrentSectionIndex or 0
            this.SectionGroups = this.SectionGroups or {}
            this.Columns = this.Columns or {
                Left = {ScrollingFrame = LeftScrolling, Count = 0, LastSection = nil},
                Right = {ScrollingFrame = RightScrolling, Count = 0, LastSection = nil},
            }

            local function insertintosection(el)
                local sec = this.CurrentSection
                if sec then
                    local group = this.SectionGroups[sec]
                    el.LayoutOrder = this.CurrentSectionIndex * 1000 + #group + 1
                    table.insert(group, el)
                else
                    el.LayoutOrder = this.CurrentSectionIndex * 1000
                end
            end
            
            if IsMobile then
                addCustomScrollbar(LeftScrolling)
            end

            function Tab:CreateSection(Name, PreferredColumn)
                this.NumSections = this.NumSections + 1
                local Column
                if IsMobile or _G.SINGLE_COLUMNS then
                    Column = "Left"
                elseif PreferredColumn then
                    Column = PreferredColumn
                else
                    this.AutoIndex = this.AutoIndex + 1
                    Column = (this.AutoIndex % 2 == 1) and "Left" or "Right"
                end
                local colData = this.Columns[Column]

                if colData.Count > 0 and colData.LastSection then
                    local prevGroup = this.SectionGroups[colData.LastSection]
                    local filler = Instance.new("Frame")
                    filler.Parent = colData.ScrollingFrame
                    filler.BackgroundTransparency = 1
                    filler.Size = UDim2.new(0, 0, 0, 10)
                    filler.LayoutOrder = colData.LastSection.LayoutOrder + #prevGroup + 1
                    table.insert(prevGroup, filler)
                end

                ScrollingFrame = colData.ScrollingFrame

                local Section = Instance.new("Frame")
                local TextButton = Instance.new("TextButton")

                Section.Name = "Section"
                Section.Parent = ScrollingFrame
                Section.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Section.BackgroundTransparency = 1.000
                Section.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Section.BorderSizePixel = 0
                Section.Size = UDim2.new(1, 0, 0, 28)

                TextButton.Parent = Section
                TextButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextButton.BackgroundTransparency = 1.000
                TextButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextButton.BorderSizePixel = 0
                TextButton.Position = UDim2.new(0, 10, 0, 0)
                TextButton.Size = UDim2.new(1, -20, 1, 0)
                TextButton.Font = Enum.Font.ArialBold
                TextButton.Text = Name
                TextButton.TextColor3 = Color3.fromRGB(199, 199, 199)
                TextButton.TextSize = 13.000
                TextButton.TextXAlignment = Enum.TextXAlignment.Left
                TextButton.ZIndex = 2

                local tlc = TextButton:Clone()
                tlc.ZIndex = 1
                tlc.TextColor3 = Color3.fromRGB(0, 0, 0)
                tlc.Position = TextButton.Position + UDim2.fromOffset(1, 1)
                tlc.Parent = TextButton.Parent
                tlc.Active = false

                this.CurrentSectionIndex = this.CurrentSectionIndex + 1
                Section.LayoutOrder = this.CurrentSectionIndex * 1000
                this.CurrentSection = Section
                this.SectionGroups[Section] = {}
                colData.Count = colData.Count + 1
                colData.LastSection = Section

                local Collapsed = false
                local Animating = false
                local COLLAPSE_TIME = 0.2
                local STAGGER = 0.06
                local COLLAPSE_TINFO = TweenInfo.new(COLLAPSE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

                local ListLayout = colData.ScrollingFrame:FindFirstChildOfClass("UIListLayout")

                TextButton.MouseButton1Click:Connect(function()
                    if Animating then return end
                    Animating = true
                    Collapsed = not Collapsed
                    local group = this.SectionGroups[Section]
                    local n = #group
                    local totalTime = COLLAPSE_TIME + (n > 0 and (n - 1) * STAGGER or 0)

                    if Collapsed then
                        local originals = {}
                        local origClips = {}
                        local origPos = {}
                        local origAutoSize = {}
                        for i = 1, n do
                            local el = group[i]
                            originals[el] = el.Size
                            origAutoSize[el] = el.AutomaticSize
                            if el.AutomaticSize ~= Enum.AutomaticSize.None then
                                el.AutomaticSize = Enum.AutomaticSize.None
                            end
                            origClips[el] = el.ClipsDescendants
                            origPos[el] = el.Position
                            el.ClipsDescendants = true
                        end
                        for i = n, 1, -1 do
                            local el = group[i]
                            local delay = (n - i) * STAGGER
                            local shrinkHeight = originals[el].Y.Offset
                            task.delay(delay, function()
                                TweenService:Create(el, COLLAPSE_TINFO, {
                                    Size = UDim2.new(el.Size.X.Scale, el.Size.X.Offset, 0, 0)
                                }):Play()
                                for j = i + 1, n do
                                    local below = group[j]
                                    local curPos = below.Position
                                    TweenService:Create(below, COLLAPSE_TINFO, {
                                        Position = UDim2.new(curPos.X.Scale, curPos.X.Offset, curPos.Y.Scale, curPos.Y.Offset - shrinkHeight)
                                    }):Play()
                                end
                            end)
                        end
                        task.delay(totalTime, function()
                            for i = 1, n do
                                local el = group[i]
                                el.Parent = HiddenHolder
                                el.Position = origPos[el]
                                el:SetAttribute("__restoreX", originals[el].X.Scale)
                                el:SetAttribute("__restoreXO", originals[el].X.Offset)
                                el:SetAttribute("__restoreY", originals[el].Y.Scale)
                                el:SetAttribute("__restoreYO", originals[el].Y.Offset)
                                el:SetAttribute("__clips", origClips[el])
                                el:SetAttribute("__autosize", origAutoSize[el].Name)
                            end
                            Animating = false
                        end)
                    else
                        for i = 1, n do
                            local el = group[i]
                            local rx = el:GetAttribute("__restoreX") or 0
                            local rxo = el:GetAttribute("__restoreXO") or 0
                            el.Size = UDim2.new(rx, rxo, 0, 0)
                            el.Parent = colData.ScrollingFrame
                        end
                        task.wait()
                        local restPositions = {}
                        for i = 1, n do
                            restPositions[group[i]] = group[i].Position
                        end
                        for i = 1, n do
                            local el = group[i]
                            el.Position = restPositions[el]
                        end
                        for i = 1, n do
                            local el = group[i]
                            local rx = el:GetAttribute("__restoreX") or 0
                            local rxo = el:GetAttribute("__restoreXO") or 0
                            local ry = el:GetAttribute("__restoreY") or 0
                            local ryo = el:GetAttribute("__restoreYO") or 0
                            local growHeight = ryo
                            local delay = (i - 1) * STAGGER
                            task.delay(delay, function()
                                TweenService:Create(el, COLLAPSE_TINFO, {
                                    Size = UDim2.new(rx, rxo, ry, ryo)
                                }):Play()
                                for j = i + 1, n do
                                    local below = group[j]
                                    local curPos = below.Position
                                    TweenService:Create(below, COLLAPSE_TINFO, {
                                        Position = UDim2.new(curPos.X.Scale, curPos.X.Offset, curPos.Y.Scale, curPos.Y.Offset + growHeight)
                                    }):Play()
                                end
                            end)
                        end
                        task.delay(totalTime, function()
                            for i = 1, n do
                                local el = group[i]
                                local clips = el:GetAttribute("__clips")
                                el.ClipsDescendants = (clips == nil) and false or clips
                                local autosizeName = el:GetAttribute("__autosize")
                                if autosizeName then
                                    el.AutomaticSize = Enum.AutomaticSize[autosizeName]
                                end
                            end
                            Animating = false
                        end)
                    end
                end)

                return {
                    Set = function(self, New)
                        TextButton.Text = New
                        tlc.Text = New
                    end
                }
            end

            function Tab:CreateLabel(Text)
                local Toggle = Instance.new("Frame")
                local TextLabel = Instance.new("TextLabel")
                local UICorner = Instance.new("UICorner")
                local UIPadding = Instance.new("UIPadding")

                Toggle.Name = "Toggle"
                Toggle.Parent = ScrollingFrame
                insertintosection(Toggle)
                Toggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Toggle.BackgroundTransparency = 0.450
                Toggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Toggle.BorderSizePixel = 0
                Toggle.AutomaticSize = Enum.AutomaticSize.Y
                Toggle.Size = UDim2.new(1, -((IsMobile or _G.SINGLE_COLUMNS) and 29 or 10), 0, 28)

                UIPadding.Parent = Toggle
                UIPadding.PaddingTop = UDim.new(0, 6)
                UIPadding.PaddingBottom = UDim.new(0, 6)

                TextLabel.Parent = Toggle
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.BackgroundTransparency = 1.000
                TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextLabel.BorderSizePixel = 0
                TextLabel.Position = UDim2.new(0, 10, 0, 0)
                TextLabel.Size = UDim2.new(1, -20, 0, 0)
                TextLabel.AutomaticSize = Enum.AutomaticSize.Y
                TextLabel.TextWrapped = true
                TextLabel.Font = Enum.Font.ArialBold
                TextLabel.Text = Text
                TextLabel.TextColor3 = Color3.fromRGB(145, 145, 145)
                TextLabel.TextSize = 13.000
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.RichText = true

                UICorner.CornerRadius = UDim.new(0, 5)
                UICorner.Parent = Toggle

                return {
                    Set = function(self, New)
                        TextLabel.Text = New
                    end
                }
            end
            
            function Tab:CreateToggle(Properties)
                local Flag = Properties.Flag
                local CurrentValue = Properties.CurrentValue
                local Name = Properties.Name
                local Callback = Properties.Callback or function() end
                local TextMode = Properties.TextMode
                Window.Flags[Flag] = {CurrentValue = CurrentValue}
                table.insert(this.Features, Name)
                
                local Toggle = Instance.new("Frame")
                local TextLabel = Instance.new("TextButton")
                local UICorner = Instance.new("UICorner")
                local Switch, UICorner_2, ball, UICorner_3, StateLabel

                Toggle.Name = "Toggle"
                Toggle.Parent = ScrollingFrame
                insertintosection(Toggle)
                Toggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Toggle.BackgroundTransparency = 0.450
                Toggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Toggle.BorderSizePixel = 0
                Toggle.Size = UDim2.new(1, -((IsMobile or _G.SINGLE_COLUMNS) and 29 or 10), 0, 28)

                TextLabel.Parent = Toggle
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.BackgroundTransparency = 1.000
                TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextLabel.BorderSizePixel = 0
                TextLabel.Position = UDim2.new(0, 10, 0, 0)
                TextLabel.Size = UDim2.new(0.5, 0, 0, 28)
                TextLabel.Font = Enum.Font.ArialBold
                TextLabel.Text = Name
                TextLabel.TextColor3 = Color3.fromRGB(199, 199, 199)
                TextLabel.TextSize = 13.000
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.RichText = true
                addToolTip(TextLabel, Properties)

                UICorner.CornerRadius = UDim.new(0, 5)
                UICorner.Parent = Toggle

                local Click = Instance.new("TextButton")
                Click.Text = ""
                Click.ZIndex = 2
                Click.BackgroundTransparency = 1
                Click.BorderSizePixel = 0

                local animation

                if TextMode then
                    StateLabel = Instance.new("TextLabel")
                    StateLabel.Name = "StateLabel"
                    StateLabel.Parent = Toggle
                    StateLabel.AnchorPoint = Vector2.new(1, 0.5)
                    StateLabel.BackgroundTransparency = 1
                    StateLabel.Position = UDim2.new(1, -10, 0.5, 0)
                    StateLabel.Size = UDim2.new(0, 40, 0, 20)
                    StateLabel.Font = Enum.Font.ArialBold
                    StateLabel.TextSize = 13
                    StateLabel.TextXAlignment = Enum.TextXAlignment.Right

                    Click.Parent = StateLabel
                    Click.Size = UDim2.fromScale(1, 1)

                    animation = function()
                        if CurrentValue then
                            StateLabel.Text = "ON"
                            StateLabel.TextColor3 = Color3.fromRGB(85, 170, 85)
                        else
                            StateLabel.Text = "OFF"
                            StateLabel.TextColor3 = Color3.fromRGB(170, 60, 60)
                        end

                        StateLabel.TextSize = 18
                        TweenService:Create(StateLabel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextSize = 13}):Play()
                    end
                else
                    Switch = Instance.new("Frame")
                    UICorner_2 = Instance.new("UICorner")
                    ball = Instance.new("Frame")
                    UICorner_3 = Instance.new("UICorner")

                    Switch.Name = "Switch"
                    Switch.Parent = Toggle
                    Switch.AnchorPoint = Vector2.new(1, 0)
                    Switch.BackgroundColor3 = Color3.fromRGB(67, 67, 67)
                    Switch.BackgroundTransparency = 0.700
                    Switch.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    Switch.BorderSizePixel = 0
                    Switch.Position = UDim2.new(1, -4, 0, 4)
                    Switch.Size = UDim2.new(0, 48, 0, 20)

                    UICorner_2.CornerRadius = UDim.new(1, 0)
                    UICorner_2.Parent = Switch

                    ball.Name = "ball"
                    ball.Parent = Switch
                    ball.AnchorPoint = Vector2.new(0, 0.5)
                    ball.BackgroundColor3 = Color3.fromRGB(62, 62, 62)
                    ball.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    ball.BorderSizePixel = 0
                    ball.Position = UDim2.new(0, 2, 0.5, 0)
                    ball.Size = UDim2.new(0, 16, 0, 16)

                    UICorner_3.CornerRadius = UDim.new(1, 0)
                    UICorner_3.Parent = ball

                    Click.Parent = Switch
                    Click.Size = UDim2.fromScale(1, 1)

                    local TInfo = TweenInfo.new(0.3, Enum.EasingStyle.Sine)

                    animation = function()
                        if CurrentValue then
                            TweenService:Create(Switch, TInfo, {BackgroundColor3 = Color3.fromRGB(140, 85, 15)}):Play()
                            TweenService:Create(ball, TInfo, {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                            TweenService:Create(ball, TInfo, {Position = UDim2.new(0, 30, 0.5, 0)}):Play()
                        else
                            TweenService:Create(Switch, TInfo, {BackgroundColor3 = Color3.fromRGB(67, 67, 67)}):Play()
                            TweenService:Create(ball, TInfo, {BackgroundColor3 = Color3.fromRGB(62, 62, 62)}):Play()
                            TweenService:Create(ball, TInfo, {Position = UDim2.new(0, 2, 0.5, 0)}):Play()
                        end
                    end

                    Click.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1
                            or input.UserInputType == Enum.UserInputType.Touch
                        then
                            TweenService:Create(ball, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {Size = UDim2.new(0, 16, 0, 10)}):Play()
                        end
                    end)

                    Click.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1
                            or input.UserInputType == Enum.UserInputType.Touch
                        then
                            TweenService:Create(ball, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {Size = UDim2.new(0, 16, 0, 16)}):Play()
                        end
                    end)
                end

                local F = Window.Flags[Flag]
                function F:Set(New, IsSave)
                    CurrentValue = New
                    Window.Flags[Flag].CurrentValue = CurrentValue
                    animation()
                    task.spawn(function()
                        Callback(New, IsSave)
                    end)
                end

                local toset

                if CurrentValue then
                    toset = CurrentValue
                end
                if SaveTable[Flag] and SaveTable[Flag].CurrentValue ~= nil and not Properties.NoSave then
                    toset = SaveTable[Flag].CurrentValue
                end
                if toset ~= nil then
                    F:Set(toset, true)
                end
                
                Click.MouseButton1Click:Connect(function()
                    if Properties.Blatant and not Properties.__UNLOCKED then return end
                    F:Set(not CurrentValue)
                end)

                if not CurrentValue and TextMode then
                    animation()
                end

                TextLabel.MouseButton1Click:Connect(function()
                    if Properties.Blatant and not Properties.__UNLOCKED then
                        Window:SelectTab(Library.BlatantTabIndex)
                    end
                end)

                if Properties.Blatant and Library.BlatantTabIndex then
                    TextLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
                    Library.BlatantModeEnabled.Event:Connect(function(bool)
                        Properties.__UNLOCKED = bool
                        TextLabel.TextColor3 = bool and Color3.fromRGB(199, 199, 199) or Color3.fromRGB(100, 100, 100)
                        TextLabel.Text = bool and Name or (Name .. '\n<font size="9"><font color="rgb(170, 60, 60)">Blatant mode is required --></font></font>')
                    end)
                end

                return F
            end
            
            function Tab:CreateButton(Properties)
                local Name = Properties.Name
                local Callback = Properties.Callback or function() end
                table.insert(this.Features, Name)
                
                local Button = Instance.new("Frame")
                local TextLabel = Instance.new("TextLabel")
                local UICorner = Instance.new("UICorner")
                local ImageLabel = Instance.new("ImageLabel")

                Button.Name = "Button"
                Button.Parent = ScrollingFrame
                insertintosection(Button)
                Button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Button.BackgroundTransparency = 0.450
                Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Button.BorderSizePixel = 0
                Button.Size = UDim2.new(1, -((IsMobile or _G.SINGLE_COLUMNS) and 29 or 10), 0, 32)
                Button.ClipsDescendants = true

                TextLabel.Parent = Button
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.BackgroundTransparency = 1.000
                TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextLabel.BorderSizePixel = 0
                TextLabel.Position = UDim2.new(0, 10, 0, 0)
                TextLabel.Size = UDim2.new(0.5, 0, 0, 32)
                TextLabel.Font = Enum.Font.ArialBold
                TextLabel.Text = Name
                TextLabel.TextColor3 = Color3.fromRGB(199, 199, 199)
                TextLabel.TextSize = 13.000
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                addToolTip(TextLabel, Properties)

                UICorner.CornerRadius = UDim.new(0, 5)
                UICorner.Parent = Button

                local mouseasset = getIcon("mouse-pointer-2")
                ImageLabel.Parent = Button
                ImageLabel.AnchorPoint = Vector2.new(1, 0)
                ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ImageLabel.BackgroundTransparency = 1.000
                ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                ImageLabel.BorderSizePixel = 0
                ImageLabel.Position = UDim2.new(1, -4, 0, 6)
                ImageLabel.Size = UDim2.new(0, 20, 0, 20)
                ImageLabel.Image = mouseasset.id
                ImageLabel.ImageRectOffset = mouseasset.imageRectOffset
                ImageLabel.ImageRectSize = mouseasset.imageRectSize
                
                Button.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch
                    then
                        task.spawn(function()
                            Callback()
                        end)
                        local absPos = Button.AbsolutePosition
                        local localX = input.Position.X - absPos.X
                        local localY = input.Position.Y - absPos.Y
                        createRipple(Button, localX, localY)
                    end
                end)
            end
            
            function Tab:CreateSlider(Properties)
                local Name = Properties.Name
                local Range = Properties.Range
                local Min = Range[1]
                local Max = Range[2]
                local CurrentValue = Properties.CurrentValue
                local Flag = Properties.Flag
                Window.Flags[Flag] = {CurrentValue = CurrentValue}
                local Callback = Properties.Callback or function() end
                local Suffix = Properties.Suffix or ""
                local Increment = Properties.Increment
                local FormatType = Properties.FormatType
                table.insert(this.Features, Name)

                local Slider = Instance.new("Frame")
                local SliderName = Instance.new("TextLabel")
                local UICorner = Instance.new("UICorner")
                local Bar = Instance.new("Frame")
                local UICorner_2 = Instance.new("UICorner")
                local Ball = Instance.new("Frame")
                local UICorner_3 = Instance.new("UICorner")
                local Fill = Instance.new("Frame")
                local UICorner_4 = Instance.new("UICorner")
                Slider.Name = "Slider"
                Slider.Parent = ScrollingFrame
                insertintosection(Slider)
                Slider.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Slider.BackgroundTransparency = 0.450
                Slider.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Slider.BorderSizePixel = 0
                Slider.Size = UDim2.new(1, -((IsMobile or _G.SINGLE_COLUMNS) and 29 or 10), 0, 32)
                SliderName.Name = "SliderName"
                SliderName.Parent = Slider
                SliderName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                SliderName.BackgroundTransparency = 1.000
                SliderName.BorderColor3 = Color3.fromRGB(0, 0, 0)
                SliderName.BorderSizePixel = 0
                SliderName.Position = UDim2.new(0, 10, 0, 0)
                SliderName.Size = UDim2.new(0.5, 0, 0, 32)
                SliderName.Font = Enum.Font.ArialBold
                SliderName.Text = Name
                SliderName.TextColor3 = Color3.fromRGB(199, 199, 199)
                SliderName.TextSize = 13.000
                SliderName.TextXAlignment = Enum.TextXAlignment.Left
                SliderName.RichText = true
                addToolTip(SliderName, Properties)
                UICorner.CornerRadius = UDim.new(0, 5)
                UICorner.Parent = Slider
                Bar.Name = "Bar"
                Bar.Parent = Slider
                Bar.AnchorPoint = Vector2.new(1, 0)
                Bar.BackgroundColor3 = Color3.fromRGB(109, 109, 129)
                Bar.BackgroundTransparency = 0.500
                Bar.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Bar.BorderSizePixel = 0
                Bar.Position = UDim2.new(1, -16, 0, 13)
                Bar.Size = UDim2.new(0, 120, 0, 6)
                UICorner_2.CornerRadius = UDim.new(1, 0)
                UICorner_2.Parent = Bar
                Ball.Name = "Ball"
                Ball.Parent = Bar
                Ball.AnchorPoint = Vector2.new(0.5, 0.5)
                Ball.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Ball.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Ball.BorderSizePixel = 0
                Ball.Position = UDim2.new(0.5, 0, 0.5, 0)
                Ball.Size = UDim2.new(0, 16, 0, 16)
                Ball.ZIndex = 2
                UICorner_3.CornerRadius = UDim.new(1, 0)
                UICorner_3.Parent = Ball
                Fill.Name = "Fill"
                Fill.Parent = Bar
                Fill.BackgroundColor3 = Color3.fromRGB(245, 159, 39)
                Fill.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Fill.BorderSizePixel = 0
                Fill.Size = UDim2.new(0.5, 0, 1, 0)
                UICorner_4.CornerRadius = UDim.new(1, 0)
                UICorner_4.Parent = Fill
                
                -- Add after UICorner_4.Parent = Fill

                local BAR_DEFAULT_SIZE = UDim2.new(0, 120, 0, 6)
                local BAR_HOVER_SIZE = UDim2.new(0, 120, 0, 9)
                local BALL_DEFAULT_SIZE = UDim2.new(0, 16, 0, 16)
                local BALL_HOVER_SIZE = UDim2.new(0, 20, 0, 20)
                local TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

                local function valueToAlpha(val)
                    return (val - Min) / (Max - Min)
                end

                local function alphaToValue(alpha)
                    local raw = alpha * (Max - Min) + Min
                    local stepped = math.round(raw / Increment) * Increment
                    local decimals = math.max(0, math.ceil(-math.log10(Increment)))
                    return tonumber(string.format("%." .. decimals .. "f", math.clamp(stepped, Min, Max)))
                end

                local function updateVisuals(alpha, tween)
                    local val = alphaToValue(alpha)
                    SliderName.Text = Name .. " <font color=\"rgb(245, 159, 39)\">" .. (FormatType == "time" and truncatetime(val) or val) .. "<font color=\"rgb(141, 141, 141)\">" .. Suffix .. "</font></font>"
                    local targetFill = UDim2.new(alpha, 0, 1, 0)
                    local targetBall = UDim2.new(alpha, 0, 0.5, 0)
                    if tween then
                        TweenService:Create(Fill, TWEEN_INFO, {Size = targetFill}):Play()
                        TweenService:Create(Ball, TWEEN_INFO, {Position = targetBall}):Play()
                    else
                        Fill.Size = targetFill
                        Ball.Position = targetBall
                    end
                end

                if SaveTable[Flag] then
                    CurrentValue = SaveTable[Flag].CurrentValue
                    Window.Flags[Flag] = {CurrentValue = CurrentValue}
                    task.spawn(function()
                        Callback(CurrentValue)
                    end)
                end

                -- Set initial visuals without callback
                updateVisuals(valueToAlpha(CurrentValue), false)

                local dragging = false

                local function onDrag(inputX)
                    local barPos = Bar.AbsolutePosition.X
                    local barSize = Bar.AbsoluteSize.X
                    local alpha = math.clamp((inputX - barPos) / barSize, 0, 1)
                    local newValue = alphaToValue(alpha)
                    if newValue ~= Window.Flags[Flag].CurrentValue then
                        Window.Flags[Flag].CurrentValue = newValue
                        updateVisuals(valueToAlpha(newValue), true)
                        SliderName.Text = Name .. " <font color=\"rgb(245, 159, 39)\">" .. (FormatType == "time" and truncatetime(newValue) or newValue) .. "<font color=\"rgb(141, 141, 141)\">" .. Suffix .. "</font></font>"
                        Callback(newValue)
                    end
                end

                -- Hover
                local Hover = false
                local Hover2 = false
                Bar.MouseEnter:Connect(function()
                    Hover = true
                    TweenService:Create(Bar, TWEEN_INFO, {Size = BAR_HOVER_SIZE}):Play()
                    TweenService:Create(Ball, TWEEN_INFO, {Size = BALL_HOVER_SIZE}):Play()
                end)
                Bar.MouseLeave:Connect(function()
                    Hover = false
                    if not Hover2 and not dragging then
                        TweenService:Create(Bar, TWEEN_INFO, {Size = BAR_DEFAULT_SIZE}):Play()
                        TweenService:Create(Ball, TWEEN_INFO, {Size = BALL_DEFAULT_SIZE}):Play()
                    end
                end)
                Ball.MouseEnter:Connect(function()
                    Hover2 = true
                    TweenService:Create(Bar, TWEEN_INFO, {Size = BAR_HOVER_SIZE}):Play()
                    TweenService:Create(Ball, TWEEN_INFO, {Size = BALL_HOVER_SIZE}):Play()
                end)
                Ball.MouseLeave:Connect(function()
                    Hover2 = false
                    if not Hover and not dragging then
                        TweenService:Create(Bar, TWEEN_INFO, {Size = BAR_DEFAULT_SIZE}):Play()
                        TweenService:Create(Ball, TWEEN_INFO, {Size = BALL_DEFAULT_SIZE}):Play()
                    end
                end)
                
                Ball.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        onDrag(input.Position.X)
                    end
                end)

                -- Mouse
                Bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        onDrag(input.Position.X)
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        onDrag(input.Position.X)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                        dragging = false
                        if input.UserInputType == Enum.UserInputType.Touch or (not Hover and not Hover2) then
                            TweenService:Create(Bar, TWEEN_INFO, {Size = BAR_DEFAULT_SIZE}):Play()
                            TweenService:Create(Ball, TWEEN_INFO, {Size = BALL_DEFAULT_SIZE}):Play()
                        end
                    end
                end)

                -- Init label
                SliderName.Text = Name .. " <font color=\"rgb(245, 159, 39)\">" .. (FormatType == "time" and truncatetime(CurrentValue) or CurrentValue) .. "<font color=\"rgb(141, 141, 141)\">" .. Suffix .. "</font></font>"
            end
            
            function Tab:CreateDropdown(Properties)
                local Name = Properties.Name
                local Flag = Properties.Flag
                local CurrentOption = deepcopy(Properties.CurrentOption)
                local Options = deepcopy(Properties.Options)
                local MultipleOptions = Properties.MultipleOptions
                local Callback = Properties.Callback or function() end
                table.insert(this.Features, Name)
                
                local Dropdown = Instance.new("Frame")
                local DropdownName = Instance.new("TextLabel")
                local UICorner = Instance.new("UICorner")
                local ImageLabel = Instance.new("ImageLabel")
                local ScrollingFrame2 = Instance.new("ScrollingFrame")
                local UIListLayout = Instance.new("UIListLayout")

                Dropdown.Name = "Dropdown"
                Dropdown.Parent = ScrollingFrame
                insertintosection(Dropdown)
                Dropdown.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.BackgroundTransparency = 0.450
                Dropdown.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.BorderSizePixel = 0
                Dropdown.ClipsDescendants = true
                Dropdown.Size = UDim2.new(1, -((IsMobile or _G.SINGLE_COLUMNS) and 29 or 10), 0, 32)
                Dropdown.ClipsDescendants = true

                DropdownName.Name = "SliderName"
                DropdownName.Parent = Dropdown
                DropdownName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                DropdownName.BackgroundTransparency = 1.000
                DropdownName.BorderColor3 = Color3.fromRGB(0, 0, 0)
                DropdownName.BorderSizePixel = 0
                DropdownName.Position = UDim2.new(0, 10, 0, 0)
                DropdownName.Size = UDim2.new(0.5, 0, 0, 32)
                DropdownName.Font = Enum.Font.ArialBold
                DropdownName.TextColor3 = Color3.fromRGB(199, 199, 199)
                DropdownName.TextSize = 13.000
                DropdownName.TextXAlignment = Enum.TextXAlignment.Left
                DropdownName.RichText = true
                addToolTip(DropdownName, Properties)

                UICorner.CornerRadius = UDim.new(0, 5)
                UICorner.Parent = Dropdown

                ImageLabel.Parent = Dropdown
                ImageLabel.AnchorPoint = Vector2.new(1, 0)
                ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ImageLabel.BackgroundTransparency = 1.000
                ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                ImageLabel.BorderSizePixel = 0
                ImageLabel.Position = UDim2.new(1, -4, 0, 6)
                ImageLabel.Size = UDim2.new(0, 20, 0, 20)
                ImageLabel.Image = "rbxassetid://130996747355335"

                ScrollingFrame2.Parent = Dropdown
                ScrollingFrame2.Active = true
                ScrollingFrame2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ScrollingFrame2.BackgroundTransparency = 1.000
                ScrollingFrame2.BorderColor3 = Color3.fromRGB(0, 0, 0)
                ScrollingFrame2.BorderSizePixel = 0
                ScrollingFrame2.Position = UDim2.new(0, 10, 0, 32)
                ScrollingFrame2.Size = UDim2.new(1, -20, 1, -42)
                ScrollingFrame2.ScrollBarThickness = 8
                ScrollingFrame2.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
                ScrollingFrame2.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
                ScrollingFrame2.AutomaticCanvasSize = Enum.AutomaticSize.Y
                ScrollingFrame2.CanvasSize = UDim2.new(0, 0, 0, 0)
                ScrollingFrame2.Visible = false

                UIListLayout.Parent = ScrollingFrame2
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Padding = UDim.new(0, 4)
                UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

                local function ValuesToTable(vals)
                    local a = {}
                    for i, _ in pairs(vals) do
                        if _ == true then
                            table.insert(a, i)
                        end
                    end
                    return a
                end

                local function TableToValues(vals)
                    local a = {}
                    for _, v in pairs(vals) do
                        a[v] = true
                    end
                    return a
                end

                local function DeepEqual(a, b)
                    if type(a) ~= type(b) then return false end
                    if type(a) ~= "table" then return a == b end
                    for k, v in pairs(a) do
                        if not DeepEqual(v, b[k]) then return false end
                    end
                    for k in pairs(b) do
                        if a[k] == nil then return false end
                    end
                    return true
                end

                if (SaveTable[Flag] or {}).CurrentOption and not DeepEqual(SaveTable[Flag].CurrentOption, Options) then
                    CurrentOption = SaveTable[Flag].CurrentOption
                    task.spawn(function()
                        Callback(CurrentOption,true)
                    end)
                end
                local Values = {}
                for i, v in pairs(Options) do
                    Values[v] = false
                end
                for i, v in pairs(CurrentOption) do
                    Values[v] = true
                end
                Window.Flags[Flag] = {CurrentOption = ValuesToTable(Values)}
                
                local Click = Instance.new("TextButton")
                Click.Parent = Dropdown
                Click.Text = ""
                Click.ZIndex = 2
                Click.BackgroundTransparency = 1
                Click.BorderSizePixel = 0
                Click.Size = UDim2.new(1, 0, 0, 32)
                
                local shadow
                if #Options > 3 then
                    shadow = addShadow(ScrollingFrame2)
                    shadow.Visible = false
                end
                
                local Opened = false
                Click.MouseButton1Click:Connect(function(input)
                    Opened = not Opened
                    if shadow then
                        shadow.Visible = Opened
                    end
                    ScrollingFrame2.Visible = Opened
                    if Opened then
                        local NewY = math.clamp(38 + (#Options * (28 + UIListLayout.Padding.Offset)), 0, 38 + (3 * (28 + UIListLayout.Padding.Offset)))
                        TweenService:Create(Dropdown, TweenInfo.new(0.3), {Size = UDim2.new(Dropdown.Size.X.Scale, Dropdown.Size.X.Offset, Dropdown.Size.Y.Scale, NewY)}):Play()
                    else
                        ScrollingFrame2.CanvasPosition = Vector2.new(0, 0)
                        TweenService:Create(Dropdown, TweenInfo.new(0.3), {Size = UDim2.new(Dropdown.Size.X.Scale, Dropdown.Size.X.Offset, Dropdown.Size.Y.Scale, 32)}):Play()
                    end
                end)
                
                local DropdownData = {
                    __DropdownOptions = {}
                }
                local function GetGoodstring(tbl)
                    local John = {}
                    
                    for i, v in pairs(tbl) do
                        if v == true then
                            table.insert(John, tostring(i))
                        end
                    end
                    
                    return #John == 1 and John[1] or ((#John == 0 and "no" or #John) .. " options")
                end
                
                function DropdownData:SetTitle(NewTitle)
                    Name = NewTitle
                    DropdownName.Text = Name .. " <font color=\"rgb(100, 100, 100)\">" .. GetGoodstring(Values) .. "</font>"
                end
                
                DropdownData:SetTitle(Name)
                            
                local function RefreshDropdown(List)
                    Options = List
                    for i, v in pairs(ScrollingFrame2:GetChildren()) do
                        if v.Name == "Option" then
                            v:Destroy()
                        end
                    end
                    for i, v in pairs(List) do
                        local Option = Instance.new("Frame")
                        local UICorner_2 = Instance.new("UICorner")
                        local OName = Instance.new("TextLabel")
                        local ONameShadow = Instance.new("TextLabel")
                        
                        Option.Name = "Option"
                        Option.Parent = ScrollingFrame2
                        Option.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                        Option.BackgroundTransparency = 0.800
                        Option.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        Option.BorderSizePixel = 0
                        Option.Size = UDim2.new(1, 0, 0, 28)
                        Option.ClipsDescendants = true

                        UICorner_2.CornerRadius = UDim.new(0, 5)
                        UICorner_2.Parent = Option

                        OName.Name = "OName"
                        OName.Parent = Option
                        OName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        OName.BackgroundTransparency = 1.000
                        OName.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        OName.BorderSizePixel = 0
                        OName.Position = UDim2.new(0, 10, 0, 0)
                        OName.Size = UDim2.new(1, -20, 1, 0)
                        OName.ZIndex = 2
                        OName.Font = Enum.Font.ArialBold
                        OName.Text = tostring(v)
                        OName.TextColor3 = Color3.fromRGB(199, 199, 199)
                        OName.TextSize = 13.000
                        OName.TextXAlignment = Enum.TextXAlignment.Left

                        ONameShadow.Name = "ONameShadow"
                        ONameShadow.Parent = Option
                        ONameShadow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        ONameShadow.BackgroundTransparency = 1.000
                        ONameShadow.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        ONameShadow.BorderSizePixel = 0
                        ONameShadow.Position = UDim2.new(0, 11, 0, 1)
                        ONameShadow.Size = UDim2.new(1, -20, 1, 0)
                        ONameShadow.Font = Enum.Font.ArialBold
                        ONameShadow.Text = tostring(v)
                        ONameShadow.TextColor3 = Color3.fromRGB(0, 0, 0)
                        ONameShadow.TextSize = 13.000
                        ONameShadow.TextXAlignment = Enum.TextXAlignment.Left
                        
                        local Click = Instance.new("TextButton")
                        Click.Parent = Option
                        Click.Text = ""
                        Click.ZIndex = 2
                        Click.BackgroundTransparency = 1
                        Click.BorderSizePixel = 0
                        Click.Size = UDim2.fromScale(1, 1)
                        
                        table.insert(DropdownData.__DropdownOptions, {
                            Title = setmetatable({}, {
                                __newindex = function(a, b, c)
                                    if b == "Text" then
                                        OName.Text = c
                                        ONameShadow.Text = c
                                    end
                                end,
                            })
                        })
                        
                        local TInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
                        
                        Click.MouseButton1Click:Connect(function()
                            if Values[v] == true and not MultipleOptions then -- stop being able to unselect the selected option if multiple options if off, always have 1 selected
                                return
                            end
                            Values[v] = not Values[v]
                            if not MultipleOptions then
                                for e, b in pairs(Values) do
                                    if e ~= v then
                                        Values[e] = false
                                    end
                                end
                                for i, v in pairs(ScrollingFrame2:GetChildren()) do
                                    if v.Name == "Option" then
                                        TweenService:Create(v, TInfo, {BackgroundColor3 = Color3.fromRGB(100, 100, 100)}):Play()
                                        TweenService:Create(v.OName, TInfo, {TextColor3 = Color3.fromRGB(199, 199, 199)}):Play()
                                    end
                                end
                            end
                            if Values[v] then
                                TweenService:Create(Option, TInfo, {BackgroundColor3 = Color3.fromRGB(245, 159, 39)}):Play()
                                TweenService:Create(OName, TInfo, {TextColor3 = Color3.fromRGB(245, 159, 39)}):Play()
                            else
                                TweenService:Create(Option, TInfo, {BackgroundColor3 = Color3.fromRGB(100, 100, 100)}):Play()
                                TweenService:Create(OName, TInfo, {TextColor3 = Color3.fromRGB(199, 199, 199)}):Play()
                            end
                            
                            DropdownData:SetTitle(Name)
                            
                            Window.Flags[Flag] = {CurrentOption = ValuesToTable(Values)}
                            task.spawn(function()
                                Callback(ValuesToTable(Values))
                            end)
                        end)
                        
                        Click.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1
                                or input.UserInputType == Enum.UserInputType.Touch
                            then
                                local absPos = Option.AbsolutePosition
                                local localX = input.Position.X - absPos.X
                                local localY = input.Position.Y - absPos.Y
                                createRipple(Option, localX, localY)
                            end
                        end)
                        
                        if Values[v] then
                            Option.BackgroundColor3 = Color3.fromRGB(245, 159, 39)
                            OName.TextColor3 = Color3.fromRGB(245, 159, 39)
                        end
                    end
                end
                RefreshDropdown(Options)
                DropdownData.Refresh = RefreshDropdown
                
                return DropdownData
            end

            function Tab:CreateKeybind(Properties)
                local CurrentKeybind = Properties.CurrentKeybind
                local Name = Properties.Name
                local Callback = Properties.Callback or function() end
                table.insert(this.Features, Name)

                local Keybind = Instance.new("Frame")
                local KeybindName = Instance.new("TextLabel")
                local UICorner = Instance.new("UICorner")
                local Frame = Instance.new("Frame")
                local UICorner_2 = Instance.new("UICorner")
                local TextLabel = Instance.new("TextButton")
                local ImageLabel = Instance.new("ImageLabel")
                Keybind.Name = "Keybind"
                Keybind.Parent = ScrollingFrame
                insertintosection(Keybind)
                Keybind.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Keybind.BackgroundTransparency = 0.450
                Keybind.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Keybind.BorderSizePixel = 0
                Keybind.ClipsDescendants = true
                Keybind.Size = UDim2.new(1, -((IsMobile or _G.SINGLE_COLUMNS) and 29 or 10), 0, 32)
                KeybindName.Name = "KeybindName"
                KeybindName.Parent = Keybind
                KeybindName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                KeybindName.BackgroundTransparency = 1.000
                KeybindName.BorderColor3 = Color3.fromRGB(0, 0, 0)
                KeybindName.BorderSizePixel = 0
                KeybindName.Position = UDim2.new(0, 10, 0, 0)
                KeybindName.Size = UDim2.new(0.5, 0, 0, 32)
                KeybindName.Font = Enum.Font.ArialBold
                KeybindName.Text = Name
                KeybindName.TextColor3 = Color3.fromRGB(199, 199, 199)
                KeybindName.TextSize = 13.000
                KeybindName.TextXAlignment = Enum.TextXAlignment.Left
                addToolTip(KeybindName, Properties)
                UICorner.CornerRadius = UDim.new(0, 5)
                UICorner.Parent = Keybind
                Frame.Parent = Keybind
                Frame.AnchorPoint = Vector2.new(1, 0)
                Frame.BackgroundColor3 = Color3.fromRGB(53, 53, 53)
                Frame.BackgroundTransparency = 0.700
                Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Frame.BorderSizePixel = 0
                Frame.Position = UDim2.new(1, -4, 0, 4)
                Frame.Size = UDim2.new(0, 30, 0, 20)
                Frame.ClipsDescendants = true
                UICorner_2.CornerRadius = UDim.new(0, 5)
                UICorner_2.Parent = Frame
                TextLabel.Parent = Frame
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.BackgroundTransparency = 1.000
                TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextLabel.BorderSizePixel = 0
                TextLabel.Size = UDim2.new(1, 0, 1, 0)
                TextLabel.Font = Enum.Font.ArialBold
                TextLabel.Text = CurrentKeybind or ""
                TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.TextSize = 14.000
                TextLabel.ClipsDescendants = true

                ImageLabel.Parent = Frame
                ImageLabel.AnchorPoint = Vector2.new(0.5, 0)
                ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ImageLabel.BackgroundTransparency = 1.000
                ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                ImageLabel.BorderSizePixel = 0
                ImageLabel.Position = UDim2.new(0.5, 0, 0, 2)
                ImageLabel.Size = UDim2.new(0, 16, 0, 16)
                ImageLabel.Image = "rbxassetid://121142147574111"
                ImageLabel.Visible = false

                if CurrentKeybind == nil then
                    ImageLabel.Visible = true
                end

                local KeyInfo = {KeyCode = CurrentKeybind, Callback = Callback, Pressable = true}
                table.insert(Window.Keybinds, KeyInfo)

                local Debounce = false
                local Awaiting = false
                local PulseThread = nil

                local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                local tweenInfoBounce = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

                local function SetAwaiting()
                    -- Pulse color orange to indicate waiting
                    if PulseThread then task.cancel(PulseThread) end
                    TweenService:Create(Frame, tweenInfo, {BackgroundColor3 = Color3.fromRGB(160, 100, 15), BackgroundTransparency = 0.3}):Play()
                    TweenService:Create(TextLabel, tweenInfo, {TextColor3 = Color3.fromRGB(245, 159, 39)}):Play()
                    -- Pulsing loop
                    PulseThread = task.spawn(function()
                        while Awaiting do
                            TweenService:Create(Frame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.1}):Play()
                            task.wait(0.5)
                            TweenService:Create(Frame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.4}):Play()
                            task.wait(0.5)
                        end
                    end)
                end

                local function SetKeybind(keyName)
                    if PulseThread then task.cancel(PulseThread) PulseThread = nil end
                    TweenService:Create(Frame, tweenInfo, {BackgroundColor3 = Color3.fromRGB(60, 180, 80), BackgroundTransparency = 0.2}):Play()
                    TweenService:Create(TextLabel, tweenInfo, {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()

                    -- Set text first, then size to fit, then bounce
                    --TextLabel.Text = Replace[keyName] and tostring(Replace[keyName]) or keyName
                    task.wait() -- wait a frame for TextBounds to update
                    local targetWidth = math.max(30, TextLabel.TextBounds.X + 16)
                    local bigSize = UDim2.new(0, targetWidth + 8, 0, 24)
                    local normalSize = UDim2.new(0, targetWidth, 0, 20)

                    TweenService:Create(Frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = bigSize}):Play()
                    task.delay(0.1, function()
                        TweenService:Create(Frame, tweenInfoBounce, {Size = normalSize}):Play()
                    end)
                    task.delay(0.4, function()
                        TweenService:Create(Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                            BackgroundColor3 = Color3.fromRGB(53, 53, 53), BackgroundTransparency = 0.700
                        }):Play()
                    end)
                end

                local function SetEmpty()
                    if PulseThread then task.cancel(PulseThread) PulseThread = nil end
                    TweenService:Create(Frame, tweenInfo, {BackgroundColor3 = Color3.fromRGB(53, 53, 53), BackgroundTransparency = 0.700}):Play()
                    TweenService:Create(TextLabel, tweenInfo, {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                end

                TextLabel.MouseButton1Click:Connect(function()
                    if Debounce then return end
                    Debounce = true
                    KeyInfo.Pressable = false
                    ImageLabel.Visible = false
                    TextLabel.Text = "..."
                    Awaiting = true
                    SetAwaiting()
                    task.wait(0.1)
                    Debounce = false
                end)

                UserInputService.InputBegan:Connect(function(Input, Gpe)
                    if Unloaded then return end
                    if Gpe then return end
                    if Awaiting and Input.KeyCode.Name ~= "Unknown" then
                        local Previous = KeyInfo.KeyCode
                        KeyInfo.KeyCode = Input.KeyCode.Name
                        Awaiting = false
                        if Previous == KeyInfo.KeyCode then
                            KeyInfo.KeyCode = nil
                            ImageLabel.Visible = true
                            TextLabel.Text = ""
                            SetEmpty()
                            return
                        end
                        TextLabel.Text =  KeyInfo.KeyCode
                        SetKeybind(KeyInfo.KeyCode)
                    end
                    task.wait(0.1)
                    KeyInfo.Pressable = true
                end)
                
                local function UpdateFrameSize()
                    local textWidth = math.max(30, TextLabel.TextBounds.X + 16)
                    TweenService:Create(Frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, textWidth, 0, 20)
                    }):Play()
                end
                
                RunService.RenderStepped:Connect(UpdateFrameSize)
            end
            
            function Tab:CreateInput(Properties)
                local Name = Properties.Name
                local Flag = Properties.Flag
                local RemoveTextAfterFocusLost = Properties.RemoveTextAfterFocusLost
                local CurrentValue = Properties.CurrentValue
                local PlaceholderText = Properties.PlaceholderText
                local Callback = Properties.Callback or function() end
                table.insert(this.Features, Name)
                Window.Flags[Flag] = {CurrentValue = CurrentValue}
                
                local Input = Instance.new("Frame")
                local KeybindName = Instance.new("TextLabel")
                local UICorner = Instance.new("UICorner")
                local Frame = Instance.new("Frame")
                local UICorner_2 = Instance.new("UICorner")
                local TextLabel = Instance.new("TextLabel")
                local ImageLabel = Instance.new("ImageLabel")
                local TextBox = Instance.new("TextBox")

                Input.Name = "Input"
                Input.Parent = ScrollingFrame
                insertintosection(Input)
                Input.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Input.BackgroundTransparency = 0.450
                Input.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Input.BorderSizePixel = 0
                Input.ClipsDescendants = true
                Input.Size = UDim2.new(1, -((IsMobile or _G.SINGLE_COLUMNS) and 29 or 10), 0, 32)

                KeybindName.Name = "KeybindName"
                KeybindName.Parent = Input
                KeybindName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                KeybindName.BackgroundTransparency = 1.000
                KeybindName.BorderColor3 = Color3.fromRGB(0, 0, 0)
                KeybindName.BorderSizePixel = 0
                KeybindName.Position = UDim2.new(0, 10, 0, 0)
                KeybindName.Size = UDim2.new(0.5, 0, 0, 32)
                KeybindName.Font = Enum.Font.ArialBold
                KeybindName.Text = Name
                KeybindName.TextColor3 = Color3.fromRGB(199, 199, 199)
                KeybindName.TextSize = 13.000
                KeybindName.TextXAlignment = Enum.TextXAlignment.Left
                addToolTip(KeybindName, Properties)

                UICorner.CornerRadius = UDim.new(0, 5)
                UICorner.Parent = Input

                Frame.Parent = Input
                Frame.AnchorPoint = Vector2.new(1, 0)
                Frame.BackgroundColor3 = Color3.fromRGB(53, 53, 53)
                Frame.BackgroundTransparency = 0.700
                Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Frame.BorderSizePixel = 0
                Frame.ClipsDescendants = true
                Frame.Position = UDim2.new(1, -4, 0, 4)
                Frame.Size = UDim2.new(0, 0, 0, 20)

                UICorner_2.CornerRadius = UDim.new(0, 5)
                UICorner_2.Parent = Frame

                TextLabel.Parent = Frame
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.BackgroundTransparency = 1.000
                TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextLabel.BorderSizePixel = 0
                TextLabel.Size = UDim2.new(1, 0, 1, 0)
                TextLabel.Font = Enum.Font.ArialBold
                TextLabel.Text = ""
                TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.TextSize = 14.000

                ImageLabel.Parent = Frame
                ImageLabel.AnchorPoint = Vector2.new(1, 0)
                ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ImageLabel.BackgroundTransparency = 1.000
                ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                ImageLabel.BorderSizePixel = 0
                ImageLabel.Position = UDim2.new(1, -8, 0, 2)
                ImageLabel.Size = UDim2.new(0, 16, 0, 16)
                ImageLabel.Image = "rbxassetid://76137750753739"
                ImageLabel.ImageColor3 = Color3.fromRGB(255, 200, 110)

                TextBox.Parent = Frame
                TextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextBox.BackgroundTransparency = 1.000
                TextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextBox.BorderSizePixel = 0
                TextBox.ClipsDescendants = true
                TextBox.Position = UDim2.new(0, 7, 0, 0)
                TextBox.Size = UDim2.new(1, -40, 1, 0)
                TextBox.Font = Enum.Font.ArialBold
                TextBox.PlaceholderColor3 = Color3.fromRGB(127, 127, 127)
                TextBox.PlaceholderText = PlaceholderText or "Input Text"
                TextBox.Text = CurrentValue or ""
                TextBox.TextColor3 = Color3.fromRGB(255, 200, 110)
                TextBox.TextSize = 12.000
                TextBox.TextXAlignment = Enum.TextXAlignment.Left
                TextBox.ClearTextOnFocus = Properties.ClearTextOnFocus
                
                TextBox.FocusLost:Connect(function()
                    local Text = TextBox.Text
                    Window.Flags[Flag] = {CurrentValue = Text}
                    if Properties.RemoveTextAfterFocusLost then
                        TextBox.Text = ""
                    end
                    task.spawn(function()
                        Callback(Text)
                    end)
                end)

                if SaveTable[Flag] and not Properties.DontSave then
                    Window.Flags[Flag] = SaveTable[Flag]
                    TextBox.Text = SaveTable[Flag].CurrentValue
                    task.spawn(function()
                        Callback(TextBox.Text, true)
                    end)
                end
                
                RunService.RenderStepped:Connect(function()
                    local textWidth = math.max(30, TextBox.TextBounds.X + 50)
                    TweenService:Create(Frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, math.clamp(textWidth, 0, 160), 0, 20)
                    }):Play()
                end)
            end
            
            function Tab:CreateColorPicker(Properties)
                local Name = Properties.Name
                local Color = Properties.Color -- default color
                local Flag = Properties.Flag
                local Callback = Properties.Callback or function() end
                Window.Flags[Flag] = {Color = Color}
                table.insert(this.Features, Name)
                
                local Colorpicker = Instance.new("Frame")
                local ColorpickerName = Instance.new("TextLabel")
                local UICorner = Instance.new("UICorner")
                local ColorIndicatorBackground = Instance.new("Frame")
                local UICorner_2 = Instance.new("UICorner")
                local ColorIndicator = Instance.new("Frame")
                local UICorner_3 = Instance.new("UICorner")
                local ColorSlider = Instance.new("Frame")
                local UIGradient = Instance.new("UIGradient")
                local UICorner_5 = Instance.new("UICorner")
                local Base = Instance.new("Frame")
                local UICorner_6 = Instance.new("UICorner")
                local UIGradient_2 = Instance.new("UIGradient")
                local Overlay = Instance.new("Frame")
                local UICorner_7 = Instance.new("UICorner")
                local UIGradient_3 = Instance.new("UIGradient")
                local HexValue = Instance.new("Frame")
                local UICorner_8 = Instance.new("UICorner")
                local HexValueText = Instance.new("TextBox")
                local FormatIndication = Instance.new("TextLabel")
                local RgbValue = Instance.new("Frame")
                local UICorner_9 = Instance.new("UICorner")
                local RgbValueText = Instance.new("TextBox")
                local FormatIndication_2 = Instance.new("TextLabel")
                local HsvValue = Instance.new("Frame")
                local UICorner_10 = Instance.new("UICorner")
                local HsvValueText = Instance.new("TextBox")
                local FormatIndication_3 = Instance.new("TextLabel")

                Colorpicker.Name = "Colorpicker"
                Colorpicker.Parent = ScrollingFrame
                insertintosection(Colorpicker)
                Colorpicker.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Colorpicker.BackgroundTransparency = 0.450
                Colorpicker.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Colorpicker.BorderSizePixel = 0
                Colorpicker.ClipsDescendants = true
                Colorpicker.Size = UDim2.new(1, -((IsMobile or _G.SINGLE_COLUMNS) and 29 or 10), 0, 32)

                ColorpickerName.Name = "SliderName"
                ColorpickerName.Parent = Colorpicker
                ColorpickerName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ColorpickerName.BackgroundTransparency = 1.000
                ColorpickerName.BorderColor3 = Color3.fromRGB(0, 0, 0)
                ColorpickerName.BorderSizePixel = 0
                ColorpickerName.Position = UDim2.new(0, 10, 0, 0)
                ColorpickerName.Size = UDim2.new(0.5, 0, 0, 32)
                ColorpickerName.Font = Enum.Font.ArialBold
                ColorpickerName.Text = Name
                ColorpickerName.TextColor3 = Color3.fromRGB(199, 199, 199)
                ColorpickerName.TextSize = 13.000
                ColorpickerName.TextXAlignment = Enum.TextXAlignment.Left
                addToolTip(ColorpickerName, Properties)

                UICorner.CornerRadius = UDim.new(0, 5)
                UICorner.Parent = Colorpicker

                ColorIndicatorBackground.Name = "ColorIndicatorBackground"
                ColorIndicatorBackground.Parent = Colorpicker
                ColorIndicatorBackground.AnchorPoint = Vector2.new(1, 0.5)
                ColorIndicatorBackground.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                ColorIndicatorBackground.BackgroundTransparency = 0.300
                ColorIndicatorBackground.BorderColor3 = Color3.fromRGB(0, 0, 0)
                ColorIndicatorBackground.BorderSizePixel = 0
                ColorIndicatorBackground.Position = UDim2.new(1, -4, 0, 16)
                ColorIndicatorBackground.Size = UDim2.new(0, 50, 0, 20)

                UICorner_2.CornerRadius = UDim.new(0, 5)
                UICorner_2.Parent = ColorIndicatorBackground

                ColorIndicator.Name = "ColorIndicator"
                ColorIndicator.Parent = Colorpicker
                ColorIndicator.AnchorPoint = Vector2.new(1, 0.5)
                ColorIndicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                ColorIndicator.BorderColor3 = Color3.fromRGB(0, 0, 0)
                ColorIndicator.BorderSizePixel = 0
                ColorIndicator.Position = UDim2.new(1, -6, 0, 16)
                ColorIndicator.Size = UDim2.new(0, 46, 0, 16)

                UICorner_3.CornerRadius = UDim.new(0, 4)
                UICorner_3.Parent = ColorIndicator

                ColorSlider.Name = "ColorSlider"
                ColorSlider.Parent = Colorpicker
                ColorSlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ColorSlider.BorderColor3 = Color3.fromRGB(27, 42, 53)
                ColorSlider.ClipsDescendants = true
                ColorSlider.Position = UDim2.new(0, 10, 0, 120)
                ColorSlider.Size = UDim2.new(0, 173, 0, 12)

                UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.06, Color3.fromRGB(255, 85, 0)), ColorSequenceKeypoint.new(0.11, Color3.fromRGB(255, 170, 0)), ColorSequenceKeypoint.new(0.17, Color3.fromRGB(254, 255, 0)), ColorSequenceKeypoint.new(0.22, Color3.fromRGB(169, 255, 0)), ColorSequenceKeypoint.new(0.28, Color3.fromRGB(83, 255, 0)), ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 1)), ColorSequenceKeypoint.new(0.39, Color3.fromRGB(0, 255, 86)), ColorSequenceKeypoint.new(0.45, Color3.fromRGB(0, 255, 171)), ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 252, 255)), ColorSequenceKeypoint.new(0.56, Color3.fromRGB(0, 167, 255)), ColorSequenceKeypoint.new(0.61, Color3.fromRGB(0, 82, 255)), ColorSequenceKeypoint.new(0.67, Color3.fromRGB(2, 0, 255)), ColorSequenceKeypoint.new(0.72, Color3.fromRGB(88, 0, 255)), ColorSequenceKeypoint.new(0.78, Color3.fromRGB(173, 0, 255)), ColorSequenceKeypoint.new(0.84, Color3.fromRGB(255, 0, 251)), ColorSequenceKeypoint.new(0.89, Color3.fromRGB(255, 0, 166)), ColorSequenceKeypoint.new(0.95, Color3.fromRGB(255, 0, 80)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))}
                UIGradient.Parent = ColorSlider

                UICorner_5.CornerRadius = UDim.new(0, 6)
                UICorner_5.Parent = ColorSlider

                Base.Name = "Base"
                Base.Parent = Colorpicker
                Base.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Base.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Base.BorderSizePixel = 0
                Base.Position = UDim2.new(0, 10, 0, 33)
                Base.Size = UDim2.new(0, 173, 0, 80)

                UICorner_6.CornerRadius = UDim.new(0, 6)
                UICorner_6.Parent = Base
                
                local HueThumb                = Instance.new("Frame")
                local HueThumbCorner          = Instance.new("UICorner")
                
                HueThumb.Name               = "HueThumb"
                HueThumb.Parent             = ColorSlider
                HueThumb.AnchorPoint        = Vector2.new(0.5, 0.5)
                HueThumb.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
                HueThumb.BorderSizePixel    = 0
                HueThumb.Size               = UDim2.new(0, 6, 0, 6)
                HueThumb.ZIndex             = 10
                HueThumb.ClipsDescendants   = false

                HueThumbCorner.CornerRadius = UDim.new(1, 0)
                HueThumbCorner.Parent       = HueThumb
                
                local Stroke = Instance.new("UIStroke", HueThumb)
                Stroke.Color = Color3.fromRGB(0, 0, 0)
                Stroke.Thickness = 1
                
                local ColorThumb                = Instance.new("Frame")
                local ColorThumbCorner          = Instance.new("UICorner")

                ColorThumb.Name               = "ColorThumb"
                ColorThumb.Parent             = Overlay
                ColorThumb.AnchorPoint        = Vector2.new(0.5, 0.5)
                ColorThumb.BackgroundColor3   = Color3.fromRGB(255, 255, 255)
                ColorThumb.BorderColor3       = Color3.fromRGB(0, 0, 0)
                ColorThumb.BorderSizePixel    = 0
                ColorThumb.Size               = UDim2.fromOffset(6, 6)
                ColorThumb.ZIndex             = 10
                ColorThumb.ClipsDescendants   = false

                ColorThumbCorner.CornerRadius = UDim.new(1, 0)
                ColorThumbCorner.Parent       = ColorThumb
                
                local Stroke = Instance.new("UIStroke", ColorThumb)
                Stroke.Color = Color3.fromRGB(0, 0, 0)
                Stroke.Thickness = 1
                
                local function OnHTDrag(inputX)
                    local barPos = ColorSlider.AbsolutePosition.X
                    local barSize = ColorSlider.AbsoluteSize.X
                    local alpha = math.clamp((inputX - barPos) / barSize, 0, 1)
                    return alpha
                end

                local function OnCTDrag(inputX, inputY)
                    local barPos = Overlay.AbsolutePosition.X
                    local barSize = Overlay.AbsoluteSize.X
                    local x = math.clamp((inputX - barPos) / barSize, 0, 1)
                    local barPos = Overlay.AbsolutePosition.Y
                    local barSize = Overlay.AbsoluteSize.Y
                    local y = math.clamp((inputY - barPos) / barSize, 0, 1)
                    return x, y
                end


                local HueThumbPos

                local H, S, V = Color:ToHSV()
                ColorThumb.Position = UDim2.fromScale(1-V, 1-S)
                S = 1
                V = 1
                UIGradient_2.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromHSV(H, S, V))}
                UIGradient_2.Rotation = 270
                UIGradient_2.Parent = Base
                
                HueThumbPos = H
                HueThumb.Position = UDim2.fromScale(H, 0.5)
                
                local OldHex
                local OldRgb
                local OldHsv
                
                local function UpdateEverything(InputX, InputY, X, Y, CallbackYes)
                    if not (X and Y) then 
                        X, Y = OnCTDrag(InputX, InputY)
                    end
                    TweenService:Create(ColorThumb, TweenInfo.new(0.1), {Position = UDim2.fromScale(X, Y)}):Play()
                    local RealColor = Color3.fromHSV(HueThumbPos, 1-Y, 1-X)
                    ColorIndicatorBackground.BackgroundColor3 = RealColor
                    ColorIndicator.BackgroundColor3 = RealColor
                    local ColorStr = tostring(RealColor)
                    HsvValueText.Text = string.format("%s, %s, %s", 
                        math.floor(tonumber(ColorStr:split(", ")[1]) * 360),
                        math.floor(tonumber(ColorStr:split(", ")[2]) * 255),
                        math.floor(tonumber(ColorStr:split(", ")[3]) * 255)
                    )
                    local R, G, B = math.floor((RealColor.R*255)+0.5),math.floor((RealColor.G*255)+0.5),math.floor((RealColor.B*255)+0.5)
                    RgbValueText.Text = string.format("%s, %s, %s", R, G, B)
                    HexValueText.Text = string.format("#%02x%02x%02x", R, G, B)
                    OldHex = HexValueText.Text
                    OldRgb = RgbValueText.Text
                    OldHsv = HsvValueText.Text
                    Window.Flags[Flag] = {Color = RealColor}
                    
                    if not CallbackYes then
                        task.spawn(function()
                            Callback(RealColor)
                        end)
                    end
                end
                
                local DraggingHueThumb = false
                local DraggingColorThumb = false
                local HueThumbDragInput
                local ColorThumbbDragInput
                ColorSlider.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        DraggingHueThumb = true
                        HueThumbDragInput = Input
                        while DraggingHueThumb and task.wait() do
                            local P = OnHTDrag(HueThumbDragInput.Position.X)
                            HueThumbPos = P
                            TweenService:Create(HueThumb, TweenInfo.new(0.1), {Position = UDim2.fromScale(P, 0.5)}):Play()
                            local CLR = Color3.fromHSV(P, 1, 1)
                            UIGradient_2.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, CLR)}
                            UpdateEverything(nil, nil, ColorThumb.Position.X.Scale, ColorThumb.Position.Y.Scale)
                        end
                    end
                end)
                ColorSlider.InputChanged:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                        HueThumbDragInput = Input
                    end
                end)
                
                ColorSlider.InputEnded:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        DraggingHueThumb = false
                    end
                end)
                
                UpdateEverything(nil, nil, ColorThumb.Position.X.Scale, ColorThumb.Position.Y.Scale, true)
                
                Overlay.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        DraggingColorThumb = true
                        ColorThumbbDragInput = Input
                        while DraggingColorThumb and task.wait() do
                            UpdateEverything(ColorThumbbDragInput.Position.X, ColorThumbbDragInput.Position.Y)
                        end
                    end
                end)
                Overlay.InputChanged:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                        ColorThumbbDragInput = Input
                    end
                end)

                Overlay.InputEnded:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        DraggingColorThumb = false
                    end
                end)

                Overlay.Name = "Overlay"
                Overlay.Parent = Colorpicker
                Overlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Overlay.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Overlay.BorderSizePixel = 0
                Overlay.Position = UDim2.new(0, 10, 0, 33)
                Overlay.Size = UDim2.new(0, 173, 0, 80)

                UICorner_7.CornerRadius = UDim.new(0, 6)
                UICorner_7.Parent = Overlay

                UIGradient_3.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 0, 0)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))}
                UIGradient_3.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 1.00), NumberSequenceKeypoint.new(1.00, 0.00)}
                UIGradient_3.Parent = Overlay

                HexValue.Name = "HexValue"
                HexValue.Parent = Colorpicker
                HexValue.AnchorPoint = Vector2.new(1, 1)
                HexValue.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                HexValue.BackgroundTransparency = 0.500
                HexValue.BorderColor3 = Color3.fromRGB(0, 0, 0)
                HexValue.BorderSizePixel = 0
                HexValue.Position = UDim2.new(1, -10, 1, -10)
                HexValue.Size = UDim2.new(0, 100, 0, 26)

                UICorner_8.Parent = HexValue

                HexValueText.Name = "HexValueText"
                HexValueText.Parent = HexValue
                HexValueText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                HexValueText.BackgroundTransparency = 1.000
                HexValueText.BorderColor3 = Color3.fromRGB(0, 0, 0)
                HexValueText.BorderSizePixel = 0
                HexValueText.Size = UDim2.new(1, 0, 1, 0)
                HexValueText.Font = Enum.Font.ArialBold
                HexValueText.TextColor3 = Color3.fromRGB(255, 255, 255)
                HexValueText.TextSize = 14.000
                HexValueText.ClearTextOnFocus = false
                HexValueText.FocusLost:Connect(function()
                    local text = HexValueText.Text
                    if text:sub(1, 1) == "#" then
                        text = text:sub(2)
                    end
                    if not text:match("%x+%x+%x+") then
                        HexValueText.Text = OldHex
                        return
                    end
                    local seg1 = text:sub(1, 2)
                    local seg2 = text:sub(3, 4)
                    local seg3 = text:sub(5, 6)
                    local r, g, b = tonumber(seg1, 16), tonumber(seg2, 16), tonumber(seg3, 16)
                    local h, s, v = Color3.fromRGB(r, g, b):ToHSV()
                    HueThumbPos = h
                    TweenService:Create(HueThumb, TweenInfo.new(0.1), {Position = UDim2.fromScale(h, 0.5)}):Play()
                    UIGradient_2.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromHSV(h, 1, 1))}
                    UpdateEverything(nil, nil, 1-v, 1-s)
                end)

                FormatIndication.Name = "FormatIndication"
                FormatIndication.Parent = HexValue
                FormatIndication.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                FormatIndication.BackgroundTransparency = 1.000
                FormatIndication.BorderColor3 = Color3.fromRGB(0, 0, 0)
                FormatIndication.BorderSizePixel = 0
                FormatIndication.Position = UDim2.new(-1, -7, 0, 0)
                FormatIndication.Size = UDim2.new(1, 0, 1, 0)
                FormatIndication.Font = Enum.Font.ArialBold
                FormatIndication.Text = "HEX"
                FormatIndication.TextColor3 = Color3.fromRGB(141, 141, 141)
                FormatIndication.TextSize = 14.000
                FormatIndication.TextWrapped = true
                FormatIndication.TextXAlignment = Enum.TextXAlignment.Right

                RgbValue.Name = "RgbValue"
                RgbValue.Parent = Colorpicker
                RgbValue.AnchorPoint = Vector2.new(1, 1)
                RgbValue.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                RgbValue.BackgroundTransparency = 0.500
                RgbValue.BorderColor3 = Color3.fromRGB(0, 0, 0)
                RgbValue.BorderSizePixel = 0
                RgbValue.Position = UDim2.new(1, -10, 1, -40)
                RgbValue.Size = UDim2.new(0, 100, 0, 26)

                UICorner_9.Parent = RgbValue

                RgbValueText.Name = "RgbValueText"
                RgbValueText.Parent = RgbValue
                RgbValueText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                RgbValueText.BackgroundTransparency = 1.000
                RgbValueText.BorderColor3 = Color3.fromRGB(0, 0, 0)
                RgbValueText.BorderSizePixel = 0
                RgbValueText.Size = UDim2.new(1, 0, 1, 0)
                RgbValueText.Font = Enum.Font.ArialBold
                RgbValueText.TextColor3 = Color3.fromRGB(255, 255, 255)
                RgbValueText.TextSize = 14.000
                RgbValueText.ClearTextOnFocus = false
                RgbValueText.FocusLost:Connect(function()
                    local text = RgbValueText.Text
                    text = text:gsub(" ", "")
                    if not text:match("%d+,%d+,%d+") then
                        RgbValueText.Text = OldRgb
                        return
                    end
                    local seg1 = text:split(",")[1]
                    local seg2 = text:split(",")[2]
                    local seg3 = text:split(",")[3]
                    local r, g, b = tonumber(seg1), tonumber(seg2), tonumber(seg3)
                    if not (r and g and b) then
                        RgbValueText.Text = OldRgb
                        return
                    end
                    if (r < 0 or r > 255) or (g < 0 or g > 255) or (b < 0 or b > 255) then
                        RgbValueText.Text = OldRgb
                        return
                    end
                    local h, s, v = Color3.fromRGB(r, g, b):ToHSV()
                    HueThumbPos = h
                    TweenService:Create(HueThumb, TweenInfo.new(0.1), {Position = UDim2.fromScale(h, 0.5)}):Play()
                    UIGradient_2.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromHSV(h, 1, 1))}
                    UpdateEverything(nil, nil, 1-v, 1-s)
                end)

                FormatIndication_2.Name = "FormatIndication"
                FormatIndication_2.Parent = RgbValue
                FormatIndication_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                FormatIndication_2.BackgroundTransparency = 1.000
                FormatIndication_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
                FormatIndication_2.BorderSizePixel = 0
                FormatIndication_2.Position = UDim2.new(-1, -7, 0, 0)
                FormatIndication_2.Size = UDim2.new(1, 0, 1, 0)
                FormatIndication_2.Font = Enum.Font.ArialBold
                FormatIndication_2.Text = "RGB"
                FormatIndication_2.TextColor3 = Color3.fromRGB(141, 141, 141)
                FormatIndication_2.TextSize = 14.000
                FormatIndication_2.TextWrapped = true
                FormatIndication_2.TextXAlignment = Enum.TextXAlignment.Right

                HsvValue.Name = "HsvValue"
                HsvValue.Parent = Colorpicker
                HsvValue.AnchorPoint = Vector2.new(1, 1)
                HsvValue.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                HsvValue.BackgroundTransparency = 0.500
                HsvValue.BorderColor3 = Color3.fromRGB(0, 0, 0)
                HsvValue.BorderSizePixel = 0
                HsvValue.Position = UDim2.new(1, -10, 1, -70)
                HsvValue.Size = UDim2.new(0, 100, 0, 26)

                UICorner_10.Parent = HsvValue

                HsvValueText.Name = "HsvValueText"
                HsvValueText.Parent = HsvValue
                HsvValueText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                HsvValueText.BackgroundTransparency = 1.000
                HsvValueText.BorderColor3 = Color3.fromRGB(0, 0, 0)
                HsvValueText.BorderSizePixel = 0
                HsvValueText.Size = UDim2.new(1, 0, 1, 0)
                HsvValueText.Font = Enum.Font.ArialBold
                HsvValueText.TextColor3 = Color3.fromRGB(255, 255, 255)
                HsvValueText.TextSize = 14.000
                HsvValueText.FocusLost:Connect(function()
                    local text = HsvValueText.Text
                    text = text:gsub(" ", "")
                    if not text:match("%d+,%d+,%d+") then
                        HsvValueText.Text = OldRgb
                        return
                    end
                    local seg1 = text:split(",")[1]
                    local seg2 = text:split(",")[2]
                    local seg3 = text:split(",")[3]
                    local h, s, v = tonumber(seg1), tonumber(seg2), tonumber(seg3)
                    if not (h and s and v) then
                        HsvValueText.Text = OldRgb
                        return
                    end
                    if (h < 0 or h > 360) or (s < 0 or s > 255) or (v < 0 or v > 255) then
                        HsvValueText.Text = OldRgb
                        return
                    end
                    h, s, v = h / 360, s / 255, v / 255
                    h, s, v = Color3.fromHSV(h, s, v):ToHSV()
                    print(h, s, v)
                    HueThumbPos = h
                    TweenService:Create(HueThumb, TweenInfo.new(0.1), {Position = UDim2.fromScale(h, 0.5)}):Play()
                    UIGradient_2.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromHSV(h, 1, 1))}
                    UpdateEverything(nil, nil, 1-v, 1-s)
                end)


                FormatIndication_3.Name = "FormatIndication"
                FormatIndication_3.Parent = HsvValue
                FormatIndication_3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                FormatIndication_3.BackgroundTransparency = 1.000
                FormatIndication_3.BorderColor3 = Color3.fromRGB(0, 0, 0)
                FormatIndication_3.BorderSizePixel = 0
                FormatIndication_3.Position = UDim2.new(-1, -7, 0, 0)
                FormatIndication_3.Size = UDim2.new(1, 0, 1, 0)
                FormatIndication_3.Font = Enum.Font.ArialBold
                FormatIndication_3.Text = "HSV"
                FormatIndication_3.TextColor3 = Color3.fromRGB(141, 141, 141)
                FormatIndication_3.TextSize = 14.000
                FormatIndication_3.TextWrapped = true
                FormatIndication_3.TextXAlignment = Enum.TextXAlignment.Right
                
                local Click = Instance.new("TextButton")
                Click.Parent = Colorpicker
                Click.Text = ""
                Click.ZIndex = 2
                Click.BackgroundTransparency = 1
                Click.BorderSizePixel = 0
                Click.Size = UDim2.new(1, 0, 0, 32)
                
                local IsOpen = false
                local function Collapse()
                    Colorpicker.Size = UDim2.new(1, -((IsMobile or _G.SINGLE_COLUMNS) and 29 or 10), 0, 32)
                    HexValue.Visible = false
                    RgbValue.Visible = false
                    HsvValue.Visible = false
                    ColorSlider.Visible = false
                    Overlay.Visible = false
                    Base.Visible = false
                end
                local function Open()
                    Colorpicker.Size = UDim2.new(1, -((IsMobile or _G.SINGLE_COLUMNS) and 29 or 10), 0, 140)
                    HexValue.Visible = true
                    RgbValue.Visible = true
                    HsvValue.Visible = true
                    ColorSlider.Visible = true
                    Overlay.Visible = true
                    Base.Visible = true
                end
                
                Click.MouseButton1Click:Connect(function()
                    IsOpen = not IsOpen
                    if not IsOpen then
                        Collapse()
                    else
                        Open()
                    end
                end)
                
                Collapse()
                
            end

            function Tab:Divide()
                local space = Instance.new("Frame")
                space.Parent = ScrollingFrame
                insertintosection(space)
                space.BackgroundTransparency = 1
                space.Size = UDim2.new(1, 0, 0, 18)
                space.ClipsDescendants = true
                local bar = Instance.new("Frame")
                bar.Parent = space
                bar.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
                bar.Size = UDim2.new(1, -4, 0, 1)
                bar.Position = UDim2.new(0.5, -2, 0.5, 0)
                bar.AnchorPoint = Vector2.new(0.5, 0.5)
                bar.BorderSizePixel = 0
                bar.BackgroundTransparency = 0.5
            end
            
            return Tab
        end
        
        Window.Keybinds = {}
        UserInputService.InputBegan:Connect(function(Input, Gpe)
            if (Unloaded) then return end
            if Gpe then return end
            for i, v in pairs(Window.Keybinds) do
                if v.Pressable and v.KeyCode and Input.KeyCode == Enum.KeyCode[v.KeyCode] then
                    v.Callback()
                end
            end
        end)
        
        function Window:SelectTab(Num)
            for i,v in pairs(TabStore) do
                if v ~= TabStore[Num] then
                    v.IsSelected = false
                    v.Deselect()
                end
            end
            TabStore[Num].IsSelected = true
            TabStore[Num].Select()
        end
        
        Window.Flags = setmetatable({}, {
            __index = function(t, k)
                if not rawget(t, k) then
                    warn("flag", k, "not yet created, but you accessed it")
                    return {
                        CurrentValue = false,
                        Color = Color3.fromRGB(0, 0, 0),
                        CurrentOption = {}
                    }
                end
                return rawget(t, k)
            end
        })
        Library.__Window__ = MainFrame

        return Window
    end

    function Library:Destroy()
        pcall(function()
            Library.__Window__.Parent:Destroy()
        end)
    end

    local NotifQueue = {}
    local NotifHolder
    local NotifList
    do
        NotifHolder = Instance.new("ScreenGui")
        NotifHolder.Name = "NotifHolder"
        NotifHolder.Parent = not RunService:IsStudio() and gethui() or LocalPlayer.PlayerGui
        NotifHolder.ResetOnSpawn = false
        NotifHolder.IgnoreGuiInset = true

        local List = Instance.new("Frame")
        List.Name = "List"
        List.Parent = NotifHolder
        List.AnchorPoint = Vector2.new(1, 1)
        List.Position = UDim2.new(1, -20, 1, -20)
        List.Size = UDim2.new(0, 300, 1, -40)
        List.BackgroundTransparency = 1

        local Layout = Instance.new("UIListLayout")
        Layout.Parent = List
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.VerticalAlignment = Enum.VerticalAlignment.Top
        Layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        Layout.Padding = UDim.new(0, 8)

        NotifList = List

        function Library:ChangeNotificationLayout(new)
            Layout.VerticalAlignment = Enum.VerticalAlignment[new]
        end
    end

    function Library:DeleteNotifications()
        for i, v in pairs(NotifList:GetChildren()) do
            if v.Name == 'Notif' then
                v:Destroy()
            end
        end
        NotifQueue = {}
    end

    function Library:Notify(stuff)
        local Title = stuff.Title or ""
        local Content = stuff.Content or ""
        local Duration = stuff.Duration or 5
        local Icon = stuff.Image
        local NoQueue = stuff.NoQueue

        if NotifQueue[Content] then return end
        if not NoQueue then NotifQueue[Content] = true end
        task.delay(Duration, function()
            NotifQueue[Content] = nil
        end)

        local List = NotifList

        local Notif = Instance.new("Frame")
        Notif.Name = "Notif"
        Notif.Parent = List
        Notif.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        Notif.BorderSizePixel = 0
        Notif.Size = UDim2.new(1, 0, 0, 0)
        Notif.AutomaticSize = Enum.AutomaticSize.Y
        Notif.ClipsDescendants = true
        Notif.LayoutOrder = -os.clock()

        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 8)
        Corner.Parent = Notif

        local Stroke = Instance.new("UIStroke")
        Stroke.Color = Color3.fromRGB(55, 55, 55)
        Stroke.Thickness = 1
        Stroke.Parent = Notif

        local Pad = Instance.new("UIPadding")
        Pad.PaddingTop = UDim.new(0, 12)
        Pad.PaddingBottom = UDim.new(0, 12)
        Pad.PaddingLeft = UDim.new(0, 12)
        Pad.PaddingRight = UDim.new(0, 12)
        Pad.Parent = Notif

        local IconLabel
        local TextLeftOffset = 0
        if Icon then
            local Asset = getIcon(Icon)
            IconLabel = Instance.new("ImageLabel")
            IconLabel.Name = "Icon"
            IconLabel.Parent = Notif
            IconLabel.BackgroundTransparency = 1
            IconLabel.Position = UDim2.new(0, 0, 0, 1)
            IconLabel.Size = UDim2.new(0, 18, 0, 18)
            IconLabel.Image = Asset.id
            IconLabel.ImageRectOffset = Asset.imageRectOffset
            IconLabel.ImageRectSize = Asset.imageRectSize
            IconLabel.ImageColor3 = Color3.fromRGB(230, 230, 230)
            TextLeftOffset = 26
        end

        local CloseBtn = Instance.new("TextButton")
        CloseBtn.Name = "Close"
        CloseBtn.Parent = Notif
        CloseBtn.AnchorPoint = Vector2.new(1, 0)
        CloseBtn.Position = UDim2.new(1, 0, 0, 0)
        CloseBtn.Size = UDim2.new(0, 18, 0, 18)
        CloseBtn.BackgroundTransparency = 1
        CloseBtn.Text = ""
        CloseBtn.ZIndex = 3

        local CloseAsset = getIcon("x")
        local CloseIcon = Instance.new("ImageLabel")
        CloseIcon.Parent = CloseBtn
        CloseIcon.BackgroundTransparency = 1
        CloseIcon.Size = UDim2.new(1, 0, 1, 0)
        CloseIcon.Image = CloseAsset.id
        CloseIcon.ImageRectOffset = CloseAsset.imageRectOffset
        CloseIcon.ImageRectSize = CloseAsset.imageRectSize
        CloseIcon.ImageColor3 = Color3.fromRGB(150, 150, 150)

        CloseBtn.MouseEnter:Connect(function()
            TweenService:Create(CloseIcon, TweenInfo.new(0.15), {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        end)
        CloseBtn.MouseLeave:Connect(function()
            TweenService:Create(CloseIcon, TweenInfo.new(0.15), {ImageColor3 = Color3.fromRGB(150, 150, 150)}):Play()
        end)

        local TitleLabel = Instance.new("TextLabel")
        TitleLabel.Name = "Title"
        TitleLabel.Parent = Notif
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Position = UDim2.new(0, TextLeftOffset, 0, 0)
        TitleLabel.Size = UDim2.new(1, -TextLeftOffset - 22, 0, 18)
        TitleLabel.Font = Enum.Font.GothamBold
        TitleLabel.Text = Title
        TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        TitleLabel.TextSize = 14
        TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        TitleLabel.TextYAlignment = Enum.TextYAlignment.Top

        local ContentLabel = Instance.new("TextLabel")
        ContentLabel.Name = "Content"
        ContentLabel.Parent = Notif
        ContentLabel.BackgroundTransparency = 1
        ContentLabel.Position = UDim2.new(0, TextLeftOffset, 0, 22)
        ContentLabel.Size = UDim2.new(1, -TextLeftOffset, 0, 0)
        ContentLabel.AutomaticSize = Enum.AutomaticSize.Y
        ContentLabel.Font = Enum.Font.Gotham
        ContentLabel.Text = Content
        ContentLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        ContentLabel.TextSize = 13
        ContentLabel.TextWrapped = true
        ContentLabel.TextXAlignment = Enum.TextXAlignment.Left
        ContentLabel.TextYAlignment = Enum.TextYAlignment.Top

        local Bar = Instance.new("Frame")
        Bar.Name = "Bar"
        Bar.Parent = Notif
        Bar.AnchorPoint = Vector2.new(0, 1)
        Bar.Position = UDim2.new(0, 8, 1, 12)
        Bar.Size = UDim2.new(1, -16, 0, 2)
        Bar.BackgroundColor3 = Color3.fromRGB(245, 159, 39)
        Bar.BorderSizePixel = 0

        Notif.Size = UDim2.new(1, 0, 0, 0)
        Notif.BackgroundTransparency = 1
        Notif.Position = UDim2.new(0, 40, 0, 0)
        for _, obj in ipairs(Notif:GetDescendants()) do
            if obj:IsA("TextLabel") then obj.TextTransparency = 1 end
            if obj:IsA("ImageLabel") then obj.ImageTransparency = 1 end
        end
        Stroke.Transparency = 1
        Bar.BackgroundTransparency = 1

        task.wait()
        local EnterInfo = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        TweenService:Create(Notif, EnterInfo, {BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 0)}):Play()
        TweenService:Create(Stroke, TweenInfo.new(0.35), {Transparency = 0}):Play()
        for _, obj in ipairs(Notif:GetDescendants()) do
            if obj:IsA("TextLabel") then
                TweenService:Create(obj, TweenInfo.new(0.35), {TextTransparency = obj == ContentLabel and 0.3 or 0}):Play()
            elseif obj:IsA("ImageLabel") then
                TweenService:Create(obj, TweenInfo.new(0.35), {
                    ImageTransparency = 0
                }):Play()
            end
        end
        TweenService:Create(Bar, TweenInfo.new(0.35), {BackgroundTransparency = 0.3}):Play()
        TweenService:Create(
            Bar,
            TweenInfo.new(Duration, Enum.EasingStyle.Linear),
            {Size = UDim2.new(0, 0, 0, 2)}
        ):Play()

        local closed = false
        local function CloseNotif()
            if closed then return end
            closed = true
            NotifQueue[Content] = nil

            local ExitInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            TweenService:Create(Notif, ExitInfo, {BackgroundTransparency = 1, Position = UDim2.new(0, 40, 0, 0)}):Play()
            TweenService:Create(Stroke, ExitInfo, {Transparency = 1}):Play()
            for _, obj in ipairs(Notif:GetDescendants()) do
                if obj:IsA("TextLabel") then
                    TweenService:Create(obj, ExitInfo, {TextTransparency = 1}):Play()
                elseif obj:IsA("ImageLabel") then
                    TweenService:Create(obj, ExitInfo, {ImageTransparency = 1}):Play()
                end
            end
            TweenService:Create(Bar, ExitInfo, {BackgroundTransparency = 1}):Play()

            task.wait(0.2)
            local shrink = TweenService:Create(Notif, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(1, 0, 0, 0)})
            shrink:Play()
            shrink.Completed:Wait()
            Notif:Destroy()
        end

        CloseBtn.MouseButton1Click:Connect(CloseNotif)

        if not stuff.Sticky then
            task.delay(Duration+1, function()
                Notif:Destroy()
            end)
            task.delay(Duration, CloseNotif)
        end

        return {
            Close = CloseNotif,
        }
    end

    return Library
end)()
local Rayfield = mainuimodule or loadstring(game:HttpGet('https://raw.githubusercontent.com/aibabylaugh/catsaken/refs/heads/main/rayfield.lua'))()
Rayfield.BlatantTabIndex = 12
Env.Rayfield = Rayfield

local PrettyPrint = nil--loadstring(game:HttpGet('https://raw.githubusercontent.com/78n/DataToCode/refs/heads/main/main.lua'))().print

if (not isfolder('Catsaken')) then
    makefolder('Catsaken')
end
if (not isfile('catsakenwoman.png')) then
    writefile("catsakenwoman.png", game:HttpGet("https://github.com/aibabylaugh/catsaken/raw/main/woman.png"))
end
local READYTOSHOWUI = ShouldUseOldUI
local LOADSTEP2 = false
local CHANGELOADSTATE
if not ShouldUseOldUI then
    task.spawn(function()
        local ready = false
        task.spawn(function()
            wait(1)
            local blur = Instance.new("BlurEffect", Lighting)
            blur.Size = 0

            local loadgui = Instance.new("ScreenGui", gethui())
            loadgui.ResetOnSpawn = false

            local container = Instance.new("Frame", loadgui)
            container.Size = UDim2.new(0, 600, 0, 130)

            local loadingText = Instance.new("TextLabel", container)
            loadingText.Text = "Initiating"
            loadingText.Font = Enum.Font.LuckiestGuy
            loadingText.Size = UDim2.new(0, 600, 0, 25)
            loadingText.Position = UDim2.new(0, 0, 0, 105)
            loadingText.TextSize = 18
            loadingText.TextColor3 = Color3.fromRGB(255, 255, 255)
            loadingText.TextXAlignment = Enum.TextXAlignment.Center
            loadingText.BackgroundTransparency = 1

            pcall(function()
                game:HttpGet("https://raw.githusercontent")
                game:HttpGet("https://github.com/")
                game:HttpGet("https://discord.com/api/webhook/1234567890/abcdefghijklmnopqrstuvwxyz")
            end)

            function CHANGELOADSTATE(n)
                loadingText.Text = n
            end

            container.Position = UDim2.new(0.5, 0, 0.5, 0)
            container.AnchorPoint = Vector2.new(0.5, 0.5)
            container.BackgroundTransparency = 1

            local img = Instance.new("ImageLabel", container)
            img.Size = UDim2.new(0, 100, 0, 100)
            img.Position = UDim2.new(0, 250, 0, 0)
            img.AnchorPoint = Vector2.new(0, 0)
            img.BackgroundTransparency = 1
            img.Image = getcustomasset("catsakenwoman.png")
            img.ImageTransparency = 1

            local text = Instance.new("TextLabel", container)
            text.Text = "CATSAKEN REMASTERED"
            text.Font = Enum.Font.LuckiestGuy
            text.Size = UDim2.new(0, 0, 0, 100)
            text.Position = UDim2.new(0, 350, 0, 0)
            text.TextSize = 40
            text.TextColor3 = Color3.fromRGB(0, 0, 0)
            text.TextXAlignment = Enum.TextXAlignment.Left
            text.BackgroundTransparency = 1
            text.ClipsDescendants = true

            local gold = Color3.fromHex("F59F27")
            local white = Color3.fromRGB(0, 0, 0)
            local pulsing = false

            local function startPulse()
                pulsing = true
                task.spawn(function()
                    while pulsing do
                        TweenService:Create(text, TweenInfo.new(0.5), {TextColor3 = gold}):Play()
                        task.wait(0.5)
                        if not pulsing then break end
                        TweenService:Create(text, TweenInfo.new(0.5), {TextColor3 = white}):Play()
                        task.wait(0.5)
                    end
                end)
            end

            local function stopPulse()
                pulsing = false
                TweenService:Create(text, TweenInfo.new(0.5), {TextColor3 = gold}):Play()
                task.wait(0.5)
            end

            -- intro
            TweenService:Create(img, TweenInfo.new(1), {ImageTransparency = 0}):Play()
            TweenService:Create(blur, TweenInfo.new(1), {Size = 12}):Play()
            task.wait(1)

            local infoIn = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            TweenService:Create(img, infoIn, {Position = UDim2.new(0, 0, 0, 0)}):Play()
            TweenService:Create(text, infoIn, {
                Position = UDim2.new(0, 100, 0, 0),
                Size = UDim2.new(0, 500, 0, 100)
            }):Play()
            startPulse()
            repeat task.wait() until ready

            -- outro
            stopPulse()
            task.wait(0.3)

            local infoOut = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            TweenService:Create(img, infoOut, {Position = UDim2.new(0, 250, 0, 0)}):Play()
            TweenService:Create(text, infoOut, {
                Position = UDim2.new(0, 350, 0, 0),
                Size = UDim2.new(0, 0, 0, 100)
            }):Play()
            task.spawn(function()
                TweenService:Create(loadingText, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    TextSize = 22
                }):Play()
                task.wait(0.3)
                TweenService:Create(loadingText, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    TextSize = 13,
                    TextTransparency = 1,
                    Position = UDim2.new(0, 0, 0, 125)
                }):Play()
            end)
            task.wait(1.5)

            TweenService:Create(img, TweenInfo.new(1), {ImageTransparency = 1}):Play()
            TweenService:Create(blur, TweenInfo.new(1), {Size = 0}):Play()
            task.wait(1)

            blur:Destroy()
            loadgui:Destroy()
        end)
        repeat task.wait() until LOADSTEP2 and CHANGELOADSTATE
        local k = _G.globaluilibrary:GetDescendants()
        local f = {}
        for i = 1, #k do
            if k[i]:IsA("ImageLabel") or k[i]:IsA("ImageButton") then
                f[#f+1] = k[i].Image
            end
        end
        CHANGELOADSTATE("Preparing UI (0/" .. #f .. ")")
        local loaded = 0
        local loadedimgs = {}
        task.spawn(function()
            for i = 1, #f do
                if loadedimgs[f[i]] then
                    loaded = loaded + 1
                    continue
                end
                local done = false
                task.spawn(pcall, ContentProvider.PreloadAsync, ContentProvider, {f[i]})
                done = true
                local t = tick()
                repeat task.wait() until done or tick() - t > 2
                loaded = loaded + 1
                loadedimgs[f[i]] = true
            end
        end)
        while task.wait() do
            CHANGELOADSTATE("Preparing UI (" .. loaded .. "/" .. #f .. ")")
            if loaded == #f then break end
        end
        CHANGELOADSTATE("Ready")
        task.wait(2)
        ready = true
        CHANGELOADSTATE("Ready")
        task.wait(2)
        READYTOSHOWUI = true
    end)
end

local Catsaken = Rayfield:CreateWindow({
    Name = 'Catsaken V3 [Remastered]',
    Icon = getcustomasset("catsakenwoman.png"),
    LoadingTitle = 'Catsaken Remastered',
    LoadingSubtitle = 'V3',
    ShowText = 'catsaken',
    Theme = 'AmberGlow',
    ToggleUIKeybind = 'F4',
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = 'CatsakenRemastered',
        FileName = 'Forsaken'
    },
    Discord = {
        Enabled = false,
        Invite = '',
        RememberJoins = true
    },
    SizeSettings = {750, 480}
})
_G.CATSAKENX = Catsaken
if ShouldUseOldUI then
    Catsaken.Flags = setmetatable(Rayfield.Flags, {
        __index = function(t, k)
            if not rawget(t, k) then
                warn("flag", k, "not yet created, but you accessed it")
                return {
                    CurrentValue = false,
                    Color = Color3.fromRGB(0, 0, 0),
                    CurrentOption = {}
                }
            end
            return rawget(t, k)
        end
    })
end
if (IsVelocity) then
    Rayfield:Notify({Title = 'Dear velocity user', Content = 'Your executor is very unstable. Script may crash randomly or if certain features are enabled', Duration = 30, Image = 'bug'})
    --[[fireproximityprompt = newcclosure(function()
        warn('fireproximityprompt called but executor does not support it')
    end)]]
end

local MobileToggle
if not ShouldUseOldUI then
    MobileToggle = TopbarPlus.new():setImage(getcustomasset("catsakenwoman.png")):setCaption('Toggle Menu'):autoDeselect(false):select()
    Env.MobileToggle = MobileToggle
    MobileToggle:setEnabled(false)
end

function FindAnimationAsset(ConfigModule, Name)
    local Module = require(ConfigModule)
    if (not Module.Animations) then return warn('Module "' .. tostring(ConfigModule.Parent) .. '" does not have Animations') end
    if (not Module.Animations[Name]) then return warn(Name .. ' is not an existing attack') end
    return Module.Animations[Name]
end

local AboutTab = Catsaken:CreateTab('About', 'info')
--AboutTab:CreateSection('About Catsaken Remastered')
--AboutTab:CreateLabel('Catsaken Remastered is a branch of Catsaken. We don\'t use any code from catsaken, we are an unofficial recontinuation of the popular script catsaken. Catsaken Remastered is FREE/KEYLESS and always will be. Developed on new year\'s eve by two developers who one also worked for Voidsaken.')
AboutTab:CreateSection('Contact Developers')
AboutTab:CreateLabel("You can send a message directly to the developer of this script using the feature below.")
local UselessText = ""
local LastFeedback = 0
local SentFeedback = {}
AboutTab:CreateInput({
    Name = 'Your Message',
    CurrentValue = UselessText,
    PlaceholderText = 'Empty',
    RemoveTextAfterFocusLost = false,
    Flag = 'FeedbackMessage',
    Callback = function(Text)
        UselessText = Text
    end,
    DontSave = true
})
AboutTab:CreateButton({
    Name = 'SEND IT 📧',
    Callback = function()
        if UselessText == "" then return end
        if #UselessText <= 30 or #UselessText:split(" ") <= 4 then
            return Rayfield:Notify({Title = 'Catsaken', Content = 'Message is not long enough.', Duration = 12, Image = 'ban'})
        end
        if SentFeedback[UselessText] then
            return Rayfield:Notify({Title = 'Catsaken', Content = 'You already sent that message.', Duration = 12, Image = 'ban'})
        end
        if tick() - LastFeedback >= 60 then
            SentFeedback[UselessText] = true
            LastFeedback = tick()
            http.request({
                Method = "POST",
                Url = "https://catsaken.chieokure.workers.dev/",
                Headers = {
                    ['content-type'] = 'application/json'
                },
                Body = HttpService:JSONEncode({
                    content = UselessText .. "\n" .. "By " .. LocalPlayer.Name .. " (" .. LocalPlayer.UserId .. ")\nDevice: " .. (IsMobile and "Mobile" or "PC") .. "\nExecutor: " .. identifyexecutor()
                })
            })
            Rayfield:Notify({Title = 'Catsaken', Content = 'Message sent. Note that I cant actually natively reply to your messages, but I will 100% read them quickly.', Duration = 12, Image = 'check'})
        else
            Rayfield:Notify({Title = 'Catsaken', Content = 'One message per minute.', Duration = 12, Image = 'ban'})
        end
    end
})
AboutTab:CreateSection('Script Help')
AboutTab:CreateLabel("The keybind to the GUI is F4" .. (ShouldUseOldUI and "." or ", or press the button in the top bar. Hold features to show help"))
if not ShouldUseOldUI then AboutTab:Divide() end
local readthis2 = AboutTab:CreateLabel("READ THIS!")
AboutTab:CreateLabel("Use an alt account or be extremely careful. <font color=\"rgb(186, 52, 52)\">NEVER enable blatant features on a main account, you WILL be banned.</font>What you consider blatant is up to you")
task.spawn(function()
    while true do
        readthis2:Set('READ THIS!')
        task.wait(.5)
        readthis2:Set('<font color=\"rgb(186, 52, 52)\">READ THIS!</font>')
        task.wait(.5)
    end
end)
if not ShouldUseOldUI then AboutTab:Divide() end
AboutTab:CreateLabel("As a reminder, we don't collect execution logs or linkable information.")
if ShouldUseOldUI then
    AboutTab:CreateLabel("Since you're using on older GUI with a script made to be built on a new GUI, there may be bugs in this version. Report them if you do catch them.")
else
    AboutTab:CreateSection('Changelog')
    AboutTab:CreateLabel([[-- Pinned --
• Added cheater-detector (Still work in progress so suggest things to add to the detections!)
13/09/2026
    • Esp outline only toggle
    • Added reveal ability trajectorys
    • Added enable sprint after successful block option
    • Added generator grid size changer
    • Added a new cheat detection method
    • Added clear all notifications incase of bug
    • Made anticheat stricter
    • Added notification toggles for several features
    • Fixed auto raging pace (broke it by accident)
12/09/2026
    • Added custom speed (10-70%)
    • Fixed auto-block still running into killer after missing
    • Fixed auto-block when using certain skins
    • Option to change notification position to top/bottom
    • Fixed an autofarm generator issue on pirate bay map
11/09/2026
    • Fixes for broken features
    • Added a prettier notifications UI
    • Decreased UI height for mobile users
    • Added a scrollbar for mobile users
    • Privacy Bypass
    • Stun Spy
09/09/2026
    • Major bug fixes
    • Major improvements to auto-block (Full rework)
    • Azure ESP
    • Auto Disarm Azure Vines
    • Inf Attempts To Disarm Vines
    • Fullbright
    • TP Dagger
    • TP Slash
    • TP One Shot
    • Auto Chicken
    • Auto Raging Pace
08/09/2026
    • Updated to the latest patch of forsaken
    • Bug Fixes and QOL Changes
    • Azure Aimbot
    • Mouse1 Aimbot
    • Improved Auto Slash
    • Killer Auto-Farm Survivors
    • Bypass Killer-Only Walls
    • TP To Random Survivor, TP To Killer, Spectate Killer
    • Always Show Chat
    • Disable AFK Insanity
    • Auto Backstab 'Invis Option'
    • Added multiple configs as someone suggested]])
end

local NULL = function() end
local GeneratorsTab = Catsaken:CreateTab('Generators', 'battery-charging')
local VisualsTab = Catsaken:CreateTab('ESP', 'scan-eye')
local StaminaTab = Catsaken:CreateTab('Stamina', 'footprints')
local SilentTab = Catsaken:CreateTab('Aimbot', 'crosshair')
local HitboxTab = Catsaken:CreateTab('Hitboxes', 'sword')
local ConvenienceTab = Catsaken:CreateTab('Convenience', 'leaf')
local AutoblockTab = Catsaken:CreateTab('Auto Block', 'shield')
local PlayerTab = Catsaken:CreateTab('Self', 'user')
local MapTab = Catsaken:CreateTab('Game', 'gamepad-2')
local AntisTab = Catsaken:CreateTab('Antis', 'ban')
local MiscTab = Catsaken:CreateTab('Miscallenous', 'dices')
local ConfigsTab = Catsaken:CreateTab('Configs', 'cog')
if not ShouldUseOldUI then
    Catsaken:SelectTab(1)
end
local SkinsPath = ReplicatedStorage.Assets.Skins.Killers
local SkinsPathE = SkinsPath
local MainKillersPath = ReplicatedStorage.Assets.Killers
local MainSurvivorsPath = ReplicatedStorage.Assets.Survivors
local Forsaken = {
    ---- Forsaken Vars ----
    GameState = 0,
    RoundStart = 0,
    HitboxesDuration = 0.31,
    RoundGenerators = {},
    Killers = {},
    Survivors = {},
    Items = {},
    Gingerbread = {},
    TaphDebris = {},
    BuildermanDebris = {},
    DoeDebris = {},
    VeeDebris = {},
    AzureDebris = {},
    Spikes = {},
    AttackAnimations = {},
    M1Animations = {},
    SentinelAnimations = {},
    BlockMeta = {},
    DusekkarActive = false,
    NoliActive = false,
    CoolkidActive = false,
    CurrentPuzzle = nil,
    ---- Temp Store ----
    EspAppliedToGenerators = {},
    EspAppliedToItems = {},
    EspAppliedToGingerbread = {},
    EspAppliedToTaphDebris = {},
    EspAppliedToBuildermanDebris = {},
    EspAppliedToDoeDebris = {},
    EspAppliedToVeeDebris = {},
    EspAppliedToAzureDebris = {},
    ConstantImages = {},
    UsingWalkspeedOverride = false,
    WalkspeedOverrideAnimations = {},
    WalkspeedOverrideEndedAnims = {},
    PursuitTracker = nil
}
LocalPlayer.PlayerGui.TemporaryUI.ChildAdded:Connect(function(Object)
    Check()
    if (Object.Name == 'PlayerInfo') then
        PlayerInfoUI = Object
    end
end)

function InsertAttackAnim(Anim)
    if (not Anim) then return end
    if (table.find(Forsaken.AttackAnimations, Anim)) then return end
    table.insert(Forsaken.AttackAnimations, Anim)
end

function SSearch(SurvivorName, Attack)
    local SkinsPath = ReplicatedStorage.Assets.Skins.Survivors
    local Stun = {
        'LungeStart', 'Axe', 'Punch', 'ParryPunch', 'Slash'
    }
    for _, Name in Stun do
        for _, Folder in SkinsPath[SurvivorName]:GetChildren() do
            if (not Folder:FindFirstChild("Config")) then continue end
            local Asset = FindAnimationAsset(Folder.Config, Name)
            if (Asset) then
                if (table.find(Stun, Name)) then
                    table.insert(Forsaken.SentinelAnimations, Asset)
                end
            end
            InsertAttackAnim(Asset)
        end
        local Asset = FindAnimationAsset(MainSurvivorsPath[SurvivorName].Config, Name)
        if (Asset) then
            if (table.find(Stun, Name)) then
                table.insert(Forsaken.SentinelAnimations, Asset)
            end
        end
        InsertAttackAnim(Asset)
    end
end

function Search(KillerName, Attacks, Path, Path2, Attacks2)
    local M1 = {
        'Slash',
        'SlashAir', 'Stab', 'Bite',
        'Attack'
    }

    if (not Forsaken.BlockMeta[KillerName]) then
        Forsaken.BlockMeta[KillerName] = {}
    end

    -- Normal attacks
    for _, Name in Attacks do
        for _, Folder in (Path or SkinsPath)[KillerName]:GetChildren() do
            if (not Folder:FindFirstChild("Config")) then continue end

            local Asset = FindAnimationAsset(Folder.Config, Name)

            if (Asset) then
                Forsaken.BlockMeta[Asset] = Name

                if (table.find(M1, Name)) then
                    table.insert(Forsaken.M1Animations, Asset)
                end
            end

            InsertAttackAnim(Asset)
        end

        local Asset = FindAnimationAsset(
            (Path2 or MainKillersPath)[KillerName].Config,
            Name
        )

        if (Asset) then
            if (table.find(M1, Name)) then
                table.insert(Forsaken.M1Animations, Asset)
            end

            Forsaken.BlockMeta[Asset] = Name
        end

        InsertAttackAnim(Asset)
    end

    -- Secondary attacks
    for _, Name in Attacks2 or {} do
        for _, Folder in (Path or SkinsPath)[KillerName]:GetChildren() do
            if (not Folder:FindFirstChild("Config")) then continue end

            local Asset = FindAnimationAsset(Folder.Config, Name)

            if (Asset) then
                Forsaken.BlockMeta[Asset] = Name
            end

            InsertAttackAnim(Asset)
        end

        local Asset = FindAnimationAsset(
            (Path2 or MainKillersPath)[KillerName].Config,
            Name
        )

        if (Asset) then
            Forsaken.BlockMeta[Asset] = Name
        end

        InsertAttackAnim(Asset)
    end
end

-- Slasher
Search('Slasher', {'Slash'}, nil, nil, {'GashingWoundStart', 'Behead'}) -- L forsaken, behead and gashing wound cant even be blocked now

-- 1x1x1x1
Search('1x1x1x1', {'Slash', 'Entanglement'}) -- another L, mass infection block nerfed to ass

-- Nosferatu
Search('Nosferatu', {'Slash', 'SlashAir'}, nil, nil, {'UppercutPullingLoop'})

-- Noli
Search('Noli', {'Stab'})

-- John doe
Search('JohnDoe', {'Slash'}, nil, nil, {'CorruptEnergy'})

-- Guest666/Sixer
for _, Folder in SkinsPath['Sixer']:GetChildren() do
    if (not Folder:FindFirstChild("Config")) then continue end
    local AttackAnims = FindAnimationAsset(Folder.Config, 'Slash')
    if (AttackAnims) then
        if (AttackAnims['Slash']) then
            table.insert(Forsaken.M1Animations, AttackAnims['Slash'])
            table.insert(Forsaken.M1Animations, AttackAnims['Bite'])
            InsertAttackAnim(AttackAnims['Slash'])
            InsertAttackAnim(AttackAnims['Bite'])
        end
    end
end
local A1 = FindAnimationAsset(MainKillersPath['Sixer'].Config, 'Slash')['Slash']
local A2 = FindAnimationAsset(MainKillersPath['Sixer'].Config, 'Slash')['Bite']
table.insert(Forsaken.M1Animations, A1)
table.insert(Forsaken.M1Animations, A2)
InsertAttackAnim(A1)
InsertAttackAnim(A2)

-- c00lkidd
Search('c00lkidd', {'Attack', 'CorruptNature'})

-- Azure
Search('Azure', {'Slash'}, nil, nil, {'Enstrangle'})

-- Shedletsky
Search('Shedletsky', {'Slash'}, ReplicatedStorage.Assets.Skins.Survivors, MainSurvivorsPath)

-- Shedletsky (2)
SSearch('Shedletsky', {'Slash'})

-- Jane Doe
SSearch('JaneDoe', {'Axe'})

-- Guest 1337
SSearch('Guest1337', {'Punch', 'ParryPunch'})

-- 2Time
SSearch('TwoTime', {'LungeStart'})

-- Insert coolkids animations
do
    local Anims = Forsaken.WalkspeedOverrideAnimations
    local Anims2 = Forsaken.WalkspeedOverrideEndedAnims
    table.insert(Anims, require(MainKillersPath.c00lkidd.Config).Animations.WalkspeedOverrideStart)
    for i, v in SkinsPathE['c00lkidd']:GetChildren() do
        if (not v:FindFirstChild('Config')) then continue end
        local Module = require(v:FindFirstChild('Config'))
        if (not Module.Animations) then continue end
        if (not Module.Animations.WalkspeedOverrideStart) then continue end
        if (not Module.Animations.WalkspeedOverrideHit) then continue end
        if (not Module.Animations.WalkspeedOverrideMiss) then continue end
        if (not table.find(Anims, Module.Animations.WalkspeedOverrideStart)) then
            table.insert(Anims, Module.Animations.WalkspeedOverrideStart)
        end
        if (not table.find(Anims2, Module.Animations.WalkspeedOverrideHit)) then
            table.insert(Anims2, Module.Animations.WalkspeedOverrideHit)
        end
        if (not table.find(Anims2, Module.Animations.WalkspeedOverrideMiss)) then
            table.insert(Anims2, Module.Animations.WalkspeedOverrideMiss)
        end
    end
    task.spawn(function()
        while wait() do
            if (not Killers:FindFirstChild('c00lkidd')) then
                Forsaken.UsingWalkspeedOverride = false
            end
        end
    end)
end
print("inserted", #Forsaken.M1Animations, 'walkspeed override start animations')
print("inserted", #Forsaken.M1Animations, 'walkspeed override end animations')
print("inserted", #Forsaken.M1Animations, 'M1 animations')

function IsRoundLoaded()
    return GetGameMap() ~= nil and workspace:GetAttribute('ClientLoaded') and #Forsaken.RoundGenerators >= 5
end

function GameStateChanged(InRound, InLobby)
    Survivors.ChildAdded:Connect(function(Player)
        if (InRound and Player:GetAttribute('Username') == LocalPlayer.Name) then
            InRound()
        end
    end)
    Killers.ChildAdded:Connect(function(Player)
        if (InRound and Player:GetAttribute('Username') == LocalPlayer.Name) then
            InRound()
        end
    end)
    Spectators.ChildAdded:Connect(function(Player)
        if (InLobby and Player.Name == LocalPlayer.Name) then
            InLobby()
        end
    end)
end

GameStateChanged(function()
    warn('in round')
    Forsaken.RoundStart = tick()
    Forsaken.GameState = 1
end, function()
    warn('spectating')
    Forsaken.GameState = 0
end)
if (Spectators:FindFirstChild(LocalPlayer.Name)) then
    Forsaken.GameState = 0
else
    Forsaken.GameState = 1
end

function WaitAndReset(Key, Time)
    Forsaken[Key] = true
    task.spawn(function()
        wait(Time or 3)
        Forsaken[Key] = false
    end)
end

function GetClosestGenerator(ReturnNum)
    local Root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    if (not Root) then return end
    local Gen, Num
    for i, Generator in Forsaken.RoundGenerators do
        if (Generator:FindFirstChild('Positions') and Generator.Positions:FindFirstChild('Center') and (Generator.Positions.Center.Position - Root.Position).Magnitude <= 7) then
            Gen = Generator
            Num = i
            break
        end
    end
    if (ReturnNum) then
        return Num
    else
        return Gen
    end
end

function IsPlayerNearGenerator(Generator)
    local NewTable = {}
    for i, v in Forsaken.Survivors do table.insert(NewTable, v) end
    for i, v in Forsaken.Killers do table.insert(NewTable, v) end
    for i, Player in NewTable do
        local Root = Player:FindFirstChild('HumanoidRootPart')
        if (not Root) then continue end
        if (Player:GetAttribute('Username') == LocalPlayer.Name) then continue end
        -- how much is like 40 studs? maybe a few metres or something?
        if (Generator:FindFirstChild('Positions') and Generator.Positions:FindFirstChild('Center') and (Generator.Positions.Center.Position - Root.Position).Magnitude <= 40) then
            return true
        end
    end
    return false
end

function GetGameMap()
    return workspace.Map:FindFirstChild('Ingame') and workspace.Map.Ingame:FindFirstChild('Map')
end

function GetGameMapObjects()
    return GetGameMap():GetChildren()
end

function PressKeycode(Code)
    for i = 1, 2 do
        VirtualInputManager:SendKeyEvent(i<2, Code, false, game)
        wait()
    end
end

function GetClosestToMouse(SurvivorOrKiller)
    -- no i didnt use ai this is basic logic fuck off
    local LookFor = (SurvivorOrKiller == 'Killer' and 'Killers' or (SurvivorOrKiller == 'Survivor' and 'Survivors'))
    if (#Forsaken[LookFor] == 0) then return nil end
    local BestDistance = 1/0
    local Closest
    for i, Player in Forsaken[LookFor] do
        local Root = Player:FindFirstChild('HumanoidRootPart')
        if (not Root) then continue end
        if RealDevice ~= 'PC' then
            local Position, OnScreen = Camera:WorldToViewportPoint(Root.Position)
            if (not OnScreen) then continue end
            local ScreenCenter = Camera.ViewportSize / 2
            local Magnitude = (Vector2.new(Position.X, Position.Y) - ScreenCenter).Magnitude
            if (Magnitude < BestDistance) then
                BestDistance = Magnitude
                Closest = Player
            end
        else
            local Mouse = LocalPlayer:GetMouse()
            local Position, OnScreen = Camera:WorldToViewportPoint(Root.Position)
            if (not OnScreen) then continue end
            local MousePosition = Vector2.new(Mouse.X, Mouse.Y)
            local RootPosition = Vector2.new(Position.X, Position.Y)
            local Magnitude = (MousePosition - RootPosition).Magnitude
            if (Magnitude < BestDistance) then
                BestDistance = Magnitude
                Closest = Player
            end
        end
    end
    return Closest
end

function GetClosestSurvivor(MaxDistance)
    local Tbl = {}
    for i, v in Forsaken.Survivors do
        if (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart') and v:FindFirstChild('HumanoidRootPart') and v ~= LocalPlayer.Character) then
            local Mag = (LocalPlayer.Character.HumanoidRootPart.Position - v.HumanoidRootPart.Position).Magnitude
            if (Mag <= MaxDistance) then
                table.insert(Tbl, {Distance = Mag, Player = v})
            end
        end
    end
    table.sort(Tbl, function(a, b)
        return a.Distance < b.Distance
    end)
    return Tbl[1] and Tbl[1].Player
end

function GetClosestKiller(MaxDistance)
    local Tbl = {}
    for i, v in Forsaken.Killers do
        if (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart') and v:FindFirstChild('HumanoidRootPart') and v ~= LocalPlayer.Character) then
            local Mag = (LocalPlayer.Character.HumanoidRootPart.Position - v.HumanoidRootPart.Position).Magnitude
            if (Mag <= MaxDistance) then
                table.insert(Tbl, {Distance = Mag, Player = v})
            end
        end
    end
    table.sort(Tbl, function(a, b)
        return a.Distance < b.Distance
    end)
    return Tbl[1] and Tbl[1].Player
end

function Predict(Char)
    return (Char.HumanoidRootPart.Position) + (Char.Humanoid.MoveDirection * (Char.HumanoidRootPart.Velocity / 20))
end

function GetKillerUsername()
    local Name
    for _, Killer in Forsaken.Killers do
        if (Killer:GetAttribute("Username")) then
            Name = Killer:GetAttribute("Username")
            break
        end
    end
    return Name
end

function IsKiller()
    if (not LocalPlayer.Character) then return end
    if (not LocalPlayer.Character.Parent) then return end
    return LocalPlayer.Character.Parent == Killers
end
function HasAbility(name)
    return PlayerGui.MainUI:FindFirstChild("AbilityContainer") and PlayerGui.MainUI.AbilityContainer:FindFirstChild(name)
end

function HasAbilityReady(name)
    if (not HasAbility(name)) then
        return false
    end
    return HasAbility(name).CooldownTime.Text == ""
end

function GetM1Name()
    local Default = 'Slash'
    if (not LocalPlayer.Character) then return Default end
    if (LocalPlayer.Character.Parent ~= Killers) then return Default end
    local KillerName = LocalPlayer.Character.Name
    if (KillerName == 'c00lkidd') then
        return 'Tag'--'Punch'
    elseif (KillerName == 'Noli') then
        return 'Stab'
    elseif (KillerName == 'Nosferatu') then
        return 'Lacerate'
    end
    return Default
end

function ToggleShiftLock()
    if (not ShiftLockModule.Enabled) then
        ShiftLockModule:ToggleShiftLock()
    end
end

function StartAimbotting(Char, CheckFunc, PresetPos, Timeout)
    local Now = tick()
    local ShiftLockState = ShiftLockModule.Enabled
    while wait() and (tick() - Now <= (Timeout or 6)) do
        if (Char and Char.Parent and CheckFunc()) then
            ToggleShiftLock()
            Camera.CFrame = (PresetPos and PresetPos()) or CFrame.new(Camera.CFrame.Position, Char.HumanoidRootPart.CFrame.Position)
        else
            -- If shift lock was previously on we dont want to disable it
            if (not ShiftLockState) then
                ShiftLockModule:ToggleShiftLock()
            end
            break
        end
    end
end

function HasNotification(text)
    for i, v in pairs(LocalPlayer.PlayerGui.Notis:GetChildren()) do
        if string.find(v.Text:lower(), text) then
            return true
        end
    end
end

function ApplyConstantImage(Part, ImageId)
    if (Images[Part]) then return end
    local Image = Instance.new('ImageLabel', ImagesUI)
    Image.Image = ImageId
    Image.BackgroundTransparency = 1
    Image.BorderSizePixel = 0
    Images[Part] = Image
    local Connection Connection = RunService.RenderStepped:Connect(function()
        if ((not Part.Parent) or (not Part.Parent:FindFirstChild(Part.Name))) then
            return Connection:Disconnect(), Image:Destroy()
        end
        local Pos, OnScreen = Camera:WorldToViewportPoint(Part.Position)
        local Size = Pos - Camera:WorldToViewportPoint(Part.Position + Vector3.new(0, 3, 0))
        Image.Visible = OnScreen
        Image.Position = UDim2.new(0, Pos.X, 0, Pos.Y)
        Image.Size = UDim2.new(0, Size.Y, 0, Size.Y)
    end)
    Forsaken.ConstantImages[Image] = {Connection = Connection, Handle = Part}
end
ImagesUI.IgnoreGuiInset = true

local UpdateCompleted

task.spawn(function()
    while wait(0.3) do
        if (GetGameMap()) then
            local ForsakenCopy = {}
            ForsakenCopy.RoundGenerators = {}
            ForsakenCopy.Killers = {}
            ForsakenCopy.Survivors = {}
            ForsakenCopy.Items = {}
            ForsakenCopy.Gingerbread = {}
            ForsakenCopy.TaphDebris = {}
            ForsakenCopy.BuildermanDebris = {}
            ForsakenCopy.DoeDebris = {}
            ForsakenCopy.VeeDebris = {}
            ForsakenCopy.AzureDebris = {}
            ForsakenCopy.Spikes = {}
            for _, Killer in Killers:GetChildren() do
                if (Killer:GetAttribute("Username") ~= nil) then
                    if (not table.find(ForsakenCopy.Killers, Killer)) then
                        table.insert(ForsakenCopy.Killers, Killer)
                    end
                end
            end
            for _, Survivor in Survivors:GetChildren() do
                if (not table.find(ForsakenCopy.Survivors, Survivor)) then
                    table.insert(ForsakenCopy.Survivors, Survivor)
                end
            end
            for i, Item in ForsakenCopy.Items do
                if ((Item.Parent and (Item.Parent.Parent == Survivors or Item.Parent.Name == 'Backpack')) or not Item.Parent) then
                    table.remove(ForsakenCopy.Items, i)
                end
            end
            for _, Object in GetGameMapObjects() do
                if (Object.Name == 'Generator' and not table.find(ForsakenCopy.RoundGenerators, Object)) then
                    table.insert(ForsakenCopy.RoundGenerators, Object)
                elseif (Object:IsA('Tool') and not table.find(ForsakenCopy.Items, Object)) then
                    table.insert(ForsakenCopy.Items, Object)
                end
            end
            for _, Object in workspace:GetChildren() do -- some items appear in workspace and not ingame folder for some reason. bad coding i guess?
                if (Object:IsA('Tool') and not table.find(ForsakenCopy.Items, Object)) then
                    table.insert(ForsakenCopy.Items, Object)
                end
            end
            for _, Object in workspace.Map.Ingame:GetChildren() do
                if ((string.find(Object.Name, 'TaphTripwire') or Object.Name == 'SubspaceTripmine') and not table.find(ForsakenCopy.TaphDebris, Object)) then
                    table.insert(ForsakenCopy.TaphDebris, Object)
                elseif ((Object.Name == 'BuildermanSentry' or Object.Name == 'BuildermanDispenser') and not table.find(ForsakenCopy.BuildermanDebris, Object)) then
                    table.insert(ForsakenCopy.BuildermanDebris, Object)
                elseif (Object.Name:sub(-7) == 'Shadows' and Object.Name:sub(1, -8) == GetKillerUsername()) then
                    for _, ChildObject in pairs(Object:GetChildren()) do
                        if (not table.find(ForsakenCopy.DoeDebris, ChildObject)) then
                            table.insert(ForsakenCopy.DoeDebris, ChildObject)
                        end
                    end
                elseif (Object.Name:sub(-5) == 'Spray' and Players:FindFirstChild(Object.Name:sub(1, -6)) and not table.find(ForsakenCopy.VeeDebris, Object)) then
                    table.insert(ForsakenCopy.VeeDebris, Object)
                elseif (Object.Name == 'SpikeCollision' and not table.find(ForsakenCopy.Spikes, Object)) then
                    table.insert(ForsakenCopy.Spikes, Object)
                elseif ((Object.Name == 'VineModel' or Object.Name == 'GroundBulbModel') and not table.find(ForsakenCopy.AzureDebris, Object)) then
                    table.insert(ForsakenCopy.AzureDebris, Object)
                end
            end
            if (workspace.Map.Ingame:FindFirstChild('CurrencyLocations')) then
                for i, Object in workspace.Map.Ingame.CurrencyLocations:GetChildren() do
                    if (Object:FindFirstChildWhichIsA('Part').Position.Y > 0 and not table.find(ForsakenCopy.Gingerbread, Object)) then
                        table.insert(ForsakenCopy.Gingerbread, Object)
                    else
                        if (table.find(ForsakenCopy.Gingerbread, Object) and Object[`{Object}Exp`].Transparency == 1) then
                            table.remove(ForsakenCopy.Gingerbread, i)
                        end
                    end
                end
            end
            for i, v in pairs(ForsakenCopy) do
                Forsaken[i] = v
            end
        else
            Forsaken.RoundGenerators = {}
            Forsaken.Killers = {}
            Forsaken.Survivors = {}
            Forsaken.Items = {}
            Forsaken.Gingerbread = {}
            Forsaken.TaphDebris = {}
            Forsaken.BuildermanDebris = {}
            Forsaken.DoeDebris = {}
            Forsaken.VeeDebris = {}
            Forsaken.AzureDebris = {}
            Forsaken.Spikes = {}
        end
        UpdateCompleted = true
    end
end)

repeat
    wait()
until UpdateCompleted

GeneratorsTab:CreateSection('Generators')

-- Hook flow game
function IsNeighbour(R1, C1, R2, C2)
    return (R2 == R1 - 1 and C2 == C1) or (R2 == R1 + 1 and C2 == C1) or (R2 == R1 and C2 == C1 - 1) or (R2 == R1 and C2 == C1 + 1)
end

function Key(Node)
    return Node.row .. '-' .. Node.col
end

function OrderPath(Path, Endpoints)
    if (not Path or #Path == 0) then
        return Path
    end
    local Start = Endpoints and Endpoints[1] or Path[1]
    local Pool = {}
    for _, Node in Path do
        Pool[Key(Node)] = { row = Node.row, col = Node.col }
    end
    local Ordered = {}
    local Cur = { row = Start.row, col = Start.col }
    table.insert(Ordered, Cur)
    Pool[Key(Cur)] = nil
    while next(Pool) do
        local Found = false
        for K, Node in Pool do
            if (IsNeighbour(Cur.row, Cur.col, Node.row, Node.col)) then
                table.insert(Ordered, Node)
                Pool[K] = nil
                Cur = Node
                Found = true
                break
            end
        end
        if (not Found) then
            break
        end
    end
    return Ordered
end

function AutoGenerator(Puzzle, Force)
    for i = 1, #Puzzle.Solution do
        local Path = Puzzle.Solution[i]
        local Ends = Puzzle.targetPairs[i]
        local Ordered = OrderPath(Path, Ends)
        Puzzle.paths[i] = {}
        for _, Node in Ordered do
            if (not Force) then
                if (not Catsaken.Flags.AutoCompleteGenerators.CurrentValue) then
                    return
                end
            end
            table.insert(Puzzle.paths[i], { row = Node.row, col = Node.col })
            Puzzle:updateGui()
            if (Catsaken.Flags.LegitPuzzles.CurrentValue and GetClosestGenerator() and IsPlayerNearGenerator(GetClosestGenerator())) then
                task.wait(Catsaken.Flags.GeneratorLegitPuzzleDelay.CurrentValue)
            else
                task.wait(Catsaken.Flags.GeneratorPuzzleDelay.CurrentValue)
            end
        end
        Puzzle:checkForWin()
    end
end

function DrawSolutions(Puzzle)
    local Grid = Puzzle.gridFrame
    local NewGrid = Instance.new('Frame', Grid.Parent)
    NewGrid.ZIndex = 6
    NewGrid.BackgroundTransparency = 1
    NewGrid.Size = Grid.Size
    NewGrid.Position = Grid.Position
    NewGrid.AnchorPoint = Vector2.new(0.5, 0.5)
    NewGrid.Position = UDim2.fromScale(0.5, 0.5)
    local scale = PlayerGui.PuzzleUI.Container.GridHolder.Grid.UIGridLayout.CellSize.X.Scale
    for i = 1, #Puzzle.Solution do
        local Path = Puzzle.Solution[i]
        local Ends = Puzzle.targetPairs[i]
        local Ordered = OrderPath(Path, Ends)
        for Idx, Node in Ordered do
            local Block = Instance.new('Frame', NewGrid)
            Block.BorderSizePixel = 0
            Block.BackgroundTransparency = 0.7
            Block.Size = UDim2.fromScale(scale, scale)
            Block.ZIndex = 7
            local OriginalColor = Puzzle.colors[i]
            Block.BackgroundColor3 = Color3.new(OriginalColor.R / 1.2, OriginalColor.G / 1.2, OriginalColor.B / 1.2)
            Block.Position = UDim2.fromScale(scale * (Node.col - 1), scale * (Node.row - 1))
        end
        Puzzle:checkForWin()
    end
end

local Old
Old = hookfunction(FlowGame.new, newcclosure(function(...)
    local args = {...}
    if (Catsaken.Flags.GeneratorGridMod.CurrentValue) then
        args[2] = Catsaken.Flags.GeneratorGridModNum.CurrentValue
    end
    local Puzzle = Old(unpack(args))
    Forsaken.CurrentPuzzle = Puzzle
    if (Catsaken.Flags.GeneratorHelper.CurrentValue) then
        if (identifyexecutor() ~= 'Cosmic') then
            local Success, Res = pcall(DrawSolutions, Puzzle)
            if (not Success) then
                warn('Failed to draw puzzle - ' .. tostring(Res))
            end
        else
            task.spawn(function()
                DrawSolutions(Puzzle)
            end)
        end
    end
    if (Catsaken.Flags.AutoCompleteGenerators.CurrentValue) then
        task.spawn(function()
            local Now = tick()
            local Success, Res = pcall(AutoGenerator, Puzzle)
            if (not Success) then
                warn('Failed to complete generator - ' .. tostring(Res))
            end
            local End = math.round((tick() - Now) * 100) / 100
            task.spawn(function()
                setthreadidentity(8) -- Stupid capability shit i guess
                if Catsaken.Flags.GeneratorNotifications.CurrentValue then
                    Rayfield:Notify({Title = 'Auto complete generator', Content = `flow game completed in {End}s`, Duration = 2, Image = 'puzzle', NoQueue = true})
                end
            end)
        end)
    end
    return Puzzle
end))

-- Instantly enter generator
task.spawn(function()
    while wait(0.1) do
        for _, Generator in Forsaken.RoundGenerators do
            local Prompt = Generator:FindFirstChild('Main') and Generator.Main:FindFirstChild('Prompt')
            if (not Prompt) then continue end
            if (Catsaken.Flags.InstantlyEnterGenerator and Catsaken.Flags.InstantlyEnterGenerator.CurrentValue) then
                Prompt.HoldDuration = 0
            else
                Prompt.HoldDuration = 0.25
            end
        end
    end
end)

local DoingAllGenerators = false
function CompleteGenerators()
    if (Forsaken.GameState ~= 1) then return end
    if (not IsRoundLoaded()) then
        repeat warn('waiting for load') wait(1) until IsRoundLoaded()
    end
    if (DoingAllGenerators) then return end
    if (IsKiller()) then return end
    DoingAllGenerators = true
    pcall(function()
        for _, Generator in Forsaken.RoundGenerators do
            if (not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))) then continue end
            function CheckOccupance(Pos)
                if GetGameMap():GetAttribute('MapName') == 'PirateBay' and Pos == Generator.Positions.Right.Position then
                    return true
                end
                for _, Survivor in Forsaken.Survivors do
                    if (Survivor:FindFirstChild("HumanoidRootPart") and (Survivor.HumanoidRootPart.Position - Pos).Magnitude <= 6 and Survivor ~= LocalPlayer) then
                        return true
                    end
                end
                return false
            end
            wait(0.3)
            if (not Generator:FindFirstChild("Progress")) then continue end
            if (Generator.Progress.Value == 100) then continue end
            local Prompt = Generator:FindFirstChild('Main') and Generator.Main:FindFirstChild('Prompt')
            if (not Prompt) then continue end
            local Now = tick()
            local CenterOccupied, RightOccupied, LeftOccupied =
                CheckOccupance(Generator.Positions.Center.Position),
                CheckOccupance(Generator.Positions.Right.Position),
                CheckOccupance(Generator.Positions.Left.Position)
            
            if (CenterOccupied and RightOccupied and LeftOccupied) then continue end
            if (not CenterOccupied) then
                LocalPlayer.Character.HumanoidRootPart.CFrame = Generator.Positions.Center.CFrame
            elseif (not RightOccupied) then
                LocalPlayer.Character.HumanoidRootPart.CFrame = Generator.Positions.Right.CFrame
            else
                LocalPlayer.Character.HumanoidRootPart.CFrame = Generator.Positions.Left.CFrame
            end
            LocalPlayer.Character.Humanoid:MoveTo(Generator.Main.Position)
            repeat
                fireproximityprompt(Prompt)
                wait(0.5)
            until tick() - Now >= 7 or LocalPlayer.PlayerGui:FindFirstChild('PuzzleUI')
            if (tick() - Now >= 7) then
                warn('timed out waiting for response')
                continue
            end
            task.wait(0.4)
            if not (LocalPlayer.PlayerGui:FindFirstChild('PuzzleUI') and LocalPlayer.PlayerGui:FindFirstChild('PuzzleUI').Enabled) then
                continue
            end
            task.spawn(function()
                local Cur
                while wait() and Generator:FindFirstChild('Progress') and Generator.Progress.Value ~= 100 and LocalPlayer.PlayerGui:FindFirstChild('PuzzleUI') do
                    if (Forsaken.CurrentPuzzle == Cur) then continue end
                    Cur = Forsaken.CurrentPuzzle
                    if (not Catsaken.Flags.AutoCompleteGenerators.CurrentValue) then
                        local Success, Res = pcall(AutoGenerator, Forsaken.CurrentPuzzle, true)
                        if (not Success) then
                            warn('Failed to complete generator (all) - ' .. tostring(Res))
                        end
                    end
                end
            end)
            repeat
                wait()
            until (not Generator:FindFirstChild('Progress')) or Generator.Progress.Value == 100 or not LocalPlayer.PlayerGui:FindFirstChild('PuzzleUI')
        end
    end)
    DoingAllGenerators = false
    if Catsaken.Flags.GeneratorNotifications.CurrentValue then
        Rayfield:Notify({Title = "Complete every generator", Content = "All generators have been checked", Duration = 6})
    end
end

GeneratorsTab:CreateToggle({
    Name = 'Autofarm generators',
    CurrentValue = false,
    Flag = 'AutoGeneratorFarm',
    Callback = function(Callback)
        if (Callback) then
            CompleteGenerators()
        end
    end
})

-- Autofarm loop
GameStateChanged(function()
    local Now = tick()
    repeat
        wait()
    until tick() - Now >= 10 or #Forsaken.RoundGenerators == 5
    if (tick() - Now >= 10) then
        return warn("timed out waiting for generators")
    end
    if (Catsaken.Flags.AutoGeneratorFarm.CurrentValue) then
        warn("doing autofarm generators")
        CompleteGenerators()
    end
end)

GeneratorsTab:CreateToggle({
    Name = 'Auto complete generators',
    CurrentValue = false,
    Flag = 'AutoCompleteGenerators',
    Callback = NULL
})

GeneratorsTab:CreateToggle({
    Name = 'Generator helper',
    CurrentValue = false,
    Flag = 'GeneratorHelper',
    Callback = NULL,
    ToolTip = 'Draws the solution to the puzzle on the generator gui'
})

GeneratorsTab:CreateToggle({
    Name = 'Instantly enter generator',
    CurrentValue = false,
    Flag = 'InstantlyEnterGenerator',
    Callback = NULL
})

GeneratorsTab:CreateToggle({
    Name = 'Grid size changer',
    CurrentValue = false,
    Flag = 'GeneratorGridMod',
    Callback = NULL,
    Tooltip = 'Default = 7x7'
})

GeneratorsTab:CreateSlider({
    Name = 'Grid Size',
    Range = {2, 25},
    Increment = 1,
    Suffix = ' cols and rows',
    CurrentValue = 7,
    Flag = 'GeneratorGridModNum',
    Callback = NULL
})


GeneratorsTab:CreateButton({
    Name = 'Complete current generator',
    Callback = function()
        if (LocalPlayer.PlayerGui:FindFirstChild('PuzzleUI')) then
            task.spawn(function()
                local Generator = GetClosestGenerator()
                if (not Generator) then return end
                local Cur
                while wait() and Generator:FindFirstChild('Progress') and Generator.Progress.Value ~= 100 and LocalPlayer.PlayerGui:FindFirstChild('PuzzleUI') do
                    if (Forsaken.CurrentPuzzle == Cur) then continue end
                    Cur = Forsaken.CurrentPuzzle
                    if (not Catsaken.Flags.AutoCompleteGenerators.CurrentValue) then
                        local Success, Res = pcall(AutoGenerator, Forsaken.CurrentPuzzle, true)
                        if (not Success) then
                            warn('Failed to complete generator (ccg) - ' .. tostring(Res))
                        end
                    end
                end
            end)
        else
            warn('no puzzle ui')
        end
    end
})

GeneratorsTab:CreateButton({
    Name = 'Complete every generator',
    Callback = function()
        CompleteGenerators()
    end
})

GeneratorsTab:CreateToggle({
    Name = 'Notifications',
    CurrentValue = false,
    Flag = 'GeneratorNotifications',
    Callback = NULL,
    TextMode = true
})

GeneratorsTab:CreateSection('Teleports')

local GeneratorSelected
local GeneratorDropdown = GeneratorsTab:CreateDropdown({
    Name = 'Select generator',
    Options = {'1', '2', '3', '4', '5'},
    CurrentOption = {'1'},
    Flag = 'GeneratorSelected',
    Callback = function(Options)
        GeneratorSelected = tonumber(Options[1]:sub(1, 1))
    end
})

GeneratorsTab:CreateButton({
    Name = 'Teleport to generator',
    Callback = function()
        if (Forsaken.RoundGenerators[GeneratorSelected] and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')) then
            LocalPlayer.Character.HumanoidRootPart.CFrame = Forsaken.RoundGenerators[GeneratorSelected].Positions.Center.CFrame
        end
    end
})

task.spawn(function()
    while wait(0.2) do
        local NewList = {'1', '2', '3', '4', '5'}
        for i, Generator in Forsaken.RoundGenerators do
            if (Generator:FindFirstChild('Progress')) then
                NewList[i] = `{i} ({Generator.Progress.Value}%)`
            end
        end
        for i, v in NewList do
            GeneratorDropdown.__DropdownOptions[i].Title.Text = v
        end
        local ClosestGenerator = GetClosestGenerator(true)
        if (not ClosestGenerator) then
            GeneratorDropdown:SetTitle("Select generator")
        else
            GeneratorDropdown:SetTitle(`Select generator (you are at #{ClosestGenerator})`)
        end
    end
end)

GeneratorsTab:CreateSection('Generator Settings', 'Right')

GeneratorsTab:CreateSlider({
    Name = 'Puzzle Speed',
    Range = {0.02, 1},
    Increment = 0.01,
    Suffix = 's',
    CurrentValue = 0.08,
    Flag = 'GeneratorPuzzleDelay',
    Callback = NULL
})

GeneratorsTab:CreateToggle({
    Name = 'Use legit delay when players are nearby',
    CurrentValue = false,
    Flag = 'LegitPuzzles',
    Callback = NULL,
    TextMode = true
})

GeneratorsTab:CreateSlider({
    Name = '(Legit) Puzzle Speed',
    Range = {0.1, 2},
    Increment = 0.01,
    Suffix = 's',
    CurrentValue = 0.08,
    Flag = 'GeneratorLegitPuzzleDelay',
    Callback = NULL
})

function AddBoxEsp(Character, ColorFlag, ToggleFlag, ShowHealth, ShowItems)
    --warn(`adding box esp to {Character}`)
    local Box = Drawing.new('Square')
    Box.Visible = false
    Box.ZIndex = 2
    Box.Filled = false
    local BoxOutline = Drawing.new('Square')
    BoxOutline.Visible = false
    BoxOutline.Filled = false
    BoxOutline.Color = Color3.new(0, 0, 0)
    BoxOutline.Thickness = 2
    local HealthBarOutline = Drawing.new('Square')
    HealthBarOutline.Visible = false
    HealthBarOutline.Filled = false
    HealthBarOutline.Color = Color3.new(0, 0, 0)
    HealthBarOutline.Thickness = 2
    local HealthBar = Drawing.new('Square')
    HealthBar.Visible = false
    HealthBar.Color = Color3.new(0, 1, 0)
    HealthBar.ZIndex = 2
    HealthBar.Filled = false
    local Items = Drawing.new('Text')
    Items.Visible = false
    Items.Color = Color3.new(1, 1, 1)
    Items.Outline = true
    Items.Center = true
    Items.Font = 2
    function MapHealthColor(value, value2)
        local t = math.clamp(value / value2, 0, 1)
        return Color3.new(
            1 - t,
            t,
            0
        )
    end
    local Connection Connection = RunService.RenderStepped:Connect(function()
        if (identifyexecutor() == "Cosmic") then
            setthreadidentity(8)
        end
        BoxOutline.Visible = Box.Visible
        if (not ShowHealth) then
            HealthBar.Visible = false
        end
        if (Character and Character.Parent and Character:FindFirstChild('HumanoidRootPart') and Character:FindFirstChild('Head') and Character:FindFirstChild('Humanoid') and Character.Humanoid.Health > 0) then
            local Root = Character.HumanoidRootPart
            local RootPosition, Visible = Camera:WorldToViewportPoint(Root.Position)
            local HeadPosition = Camera:WorldToViewportPoint(Character.Head.Position + Vector3.new(0, 0.5, 0))
            local LegPosition = Camera:WorldToViewportPoint(Character.Head.Position - Vector3.new(0, 3, 0))
            if (Visible and Catsaken.Flags[ToggleFlag].CurrentValue) then
                Box.Visible = true
                if (ShowHealth) then
                    HealthBarOutline.Visible = true
                    HealthBar.Visible = true
                end
                if (ShowItems) then
                    Items.Visible = true
                    Items.Text = (function()
                        local Player = Players:GetPlayerFromCharacter(Character)
                        if (not Player) then return '' end
                        local Text = ''
                        local Backpack = Player.Backpack
                        if (Backpack:FindFirstChild('BloxyCola') and not Backpack:FindFirstChild('Medkit')) then
                            Text = 'Bloxy Cola'
                        elseif (Backpack:FindFirstChild('Medkit') and not Backpack:FindFirstChild('BloxyCola')) then
                            Text = 'Medkit'
                        elseif (Backpack:FindFirstChild('BloxyCola') and Backpack:FindFirstChild('Medkit')) then
                            Text = 'Medkit & Bloxy Cola'
                        end
                        return Text
                    end)()
                end
            else
                Box.Visible = false
                HealthBarOutline.Visible = false
                HealthBar.Visible = false
                Items.Visible = false
                return
            end
            -- Update box
            local root = Character.HumanoidRootPart
            local hum = Character.Humanoid
            local rootPos = Camera:WorldToViewportPoint(root.Position)
            local topPos = Camera:WorldToViewportPoint((CFrame.lookAlong(root.Position, Camera.CFrame.LookVector) * CFrame.new(2, hum.HipHeight, 0)).p)
            local bottomPos = Camera:WorldToViewportPoint((CFrame.lookAlong(root.Position, Camera.CFrame.LookVector) * CFrame.new(-2, -hum.HipHeight - 1, 0)).p)
            local sizex, sizey = topPos.X - bottomPos.X, topPos.Y - bottomPos.Y
            local posx, posy = (rootPos.X - sizex / 1.5),  ((rootPos.Y - sizey / 1.5))
            Box.Position = Vector2.new(posx + (sizex / 2), posy - (sizey))
            Box.Size = Vector2.new(sizex / 2, sizey * 4.5)
            Box.Color = Catsaken.Flags[ColorFlag].Color
            BoxOutline.Size = Box.Size
            BoxOutline.Position = Box.Position
            -- Update health bar
            HealthBar.Position = Box.Position - Vector2.new(6, 0)
            HealthBar.Size = Vector2.new(0, Box.Size.Y / (Character.Humanoid.MaxHealth / Character.Humanoid.Health))
            HealthBar.Color = MapHealthColor(Character.Humanoid.Health, Character.Humanoid.MaxHealth)
            HealthBarOutline.Size = Vector2.new(HealthBar.Size.X, Box.Size.Y)
            HealthBarOutline.Position = HealthBar.Position
            -- Items text
            Items.Position = Box.Position + Vector2.new(Box.Size.X / 2, 0)
            local TestPosition = Camera:WorldToViewportPoint(Character.HumanoidRootPart.Position + Vector3.new(0, 0.5, 0))
            local TestPosition2 = Camera:WorldToViewportPoint(Character.HumanoidRootPart.Position + Vector3.new(0, -0.5, 0))
            Items.Size = (TestPosition2 - TestPosition).Magnitude
            Items.Position = Vector2.new(Items.Position.X, Box.Position.Y + 13)
        else
            if (not Character.Parent) then
                warn("destroying esp - no parent")
                Connection:Disconnect()
                Box:Destroy()
                BoxOutline:Destroy()
                HealthBarOutline:Destroy()
                HealthBar:Destroy()
                Items:Destroy()
            end
            Box.Visible = false
            HealthBarOutline.Visible = false
            HealthBar.Visible = false
            Items.Visible = false
        end
    end)
end

function AddHighlightEsp(Model, ColorFlag, IsGenerator, Name)
    --warn(`adding chams to {Model}`)
    local Highlight = Instance.new('Highlight')
    Highlight.Parent = Model
    Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    Highlight.Name = Name or "Highlight"
    local AppliedCheckmark
    RunService.RenderStepped:Connect(function()
        local Color = Catsaken.Flags[ColorFlag].Color
        local H, S, V = Color:ToHSV()
        V = V + (1 - V) * 0.5
        S = S * (1 - 0.5)
        Highlight.OutlineColor = Color3.fromHSV(H, S, V)
        Highlight.FillColor = Catsaken.Flags[ColorFlag].Color
        if Catsaken.Flags.OutlineOnlyESP.CurrentValue then
            Highlight.FillTransparency = 1
        else
            Highlight.FillTransparency = 0
        end
        if (IsGenerator and Model.Parent and Model:FindFirstChild('Progress') and Model.Progress.Value == 100 and not AppliedCheckmark) then
            ApplyConstantImage(Model.Positions.Center, 'rbxassetid://115758393579036')
            AppliedCheckmark = true
        end
    end)
end

VisualsTab:CreateSection('Esp Toggles')

VisualsTab:CreateToggle({
    Name = 'Outlines only',
    CurrentValue = false,
    Flag = 'OutlineOnlyESP',
    Callback = NULL,
    TextMode = true
})

VisualsTab:CreateToggle({
    Name = 'Generator Esp',
    CurrentValue = false,
    Flag = 'GeneratorEsp',
    Callback = NULL
})

VisualsTab:CreateToggle({
    Name = 'Killer Esp',
    CurrentValue = false,
    Flag = 'KillerEsp',
    Callback = NULL
})

VisualsTab:CreateToggle({
    Name = 'Survivor Esp',
    CurrentValue = false,
    Flag = 'SurvivorEsp',
    Callback = NULL
})

VisualsTab:CreateToggle({
    Name = 'Item Esp',
    CurrentValue = false,
    Flag = 'ItemEsp',
    Callback = NULL
})

VisualsTab:CreateToggle({
    Name = 'Gingerbread Esp [DISABLED]',
    CurrentValue = false,
    Flag = 'GingerbreadEsp',
    Callback = NULL
})

VisualsTab:CreateToggle({
    Name = 'Sukkar Esp [DISABLED]',
    CurrentValue = false,
    Flag = 'SukkarEsp',
    Callback = NULL
})

VisualsTab:CreateToggle({
    Name = 'Zombie/Minion Esp',
    CurrentValue = false,
    Flag = 'EntityEsp',
    Callback = NULL
})

VisualsTab:CreateToggle({
    Name = 'Taph Esp',
    CurrentValue = false,
    Flag = 'TaphEsp',
    Callback = NULL
})

VisualsTab:CreateToggle({
    Name = 'Builderman Esp',
    CurrentValue = false,
    Flag = 'BuildermanEsp',
    Callback = NULL
})

VisualsTab:CreateToggle({
    Name = 'John Doe Esp',
    CurrentValue = false,
    Flag = 'JohnDoeEsp',
    Callback = NULL
})

VisualsTab:CreateToggle({
    Name = 'Veeronica Esp',
    CurrentValue = false,
    Flag = 'VeeronicaEsp',
    Callback = NULL
})

VisualsTab:CreateToggle({
    Name = 'Azure Esp',
    CurrentValue = false,
    Flag = 'AzureEsp',
    Callback = NULL
})

VisualsTab:CreateSection('Esp Colors')

VisualsTab:CreateColorPicker({
    Name = 'Generator Color',
    Color = Color3.fromRGB(221, 51, 255),
    Flag = 'GeneratorEspColor',
    Callback = NULL
})

VisualsTab:CreateColorPicker({
    Name = 'Killer Color',
    Color = Color3.fromRGB(255, 0, 0),
    Flag = 'KillerEspColor',
    Callback = NULL
})

VisualsTab:CreateColorPicker({
    Name = 'Survivor Color',
    Color = Color3.fromRGB(0, 0, 255),
    Flag = 'SurvivorEspColor',
    Callback = NULL
})

VisualsTab:CreateColorPicker({
    Name = 'Item Color',
    Color = Color3.fromRGB(0, 255, 255),
    Flag = 'ItemEspColor',
    Callback = NULL
})

VisualsTab:CreateColorPicker({
    Name = 'Gingerbread Color',
    Color = Color3.fromRGB(255, 50, 204),
    Flag = 'GingerbreadEspColor',
    Callback = NULL
})

VisualsTab:CreateColorPicker({
    Name = 'Zombie/Minion Color',
    Color = Color3.fromRGB(255, 159, 0),
    Flag = 'EntityEspColor',
    Callback = NULL
})

VisualsTab:CreateColorPicker({
    Name = 'Taph Color', -- Tripmines and subspaces
    Color = Color3.fromRGB(75, 255, 145),
    Flag = 'TaphEspColor',
    Callback = NULL
})

VisualsTab:CreateColorPicker({
    Name = 'Builderman Color', -- Sentries and healing machines
    Color = Color3.fromRGB(157, 255, 0),
    Flag = 'BuildermanEspColor',
    Callback = NULL
})

VisualsTab:CreateColorPicker({
    Name = 'John Doe Color', -- Digital Footprint
    Color = Color3.fromRGB(0, 0, 0),
    Flag = 'JohnDoeEspColor',
    Callback = NULL
})

VisualsTab:CreateColorPicker({
    Name = 'Veeronica Color', -- Graffiti
    Color = Color3.fromRGB(255, 0, 242),
    Flag = 'VeeronicaEspColor',
    Callback = NULL
})

VisualsTab:CreateColorPicker({
    Name = 'Azure Color', -- Bulbs, and vines thing
    Color = Color3.fromRGB(255, 255, 255), -- Shit, im out of original colors
    Flag = 'AzureEspColor',
    Callback = NULL
})

for _, Killer in Forsaken.Killers do
    if (Killer:GetAttribute("Username") == LocalPlayer.Name) then continue end
    AddBoxEsp(Killer, 'KillerEspColor', 'KillerEsp')
end
Killers.ChildAdded:Connect(function(Killer)
    if (Killer:GetAttribute("Username") == LocalPlayer.Name) then return end
    AddBoxEsp(Killer, 'KillerEspColor', 'KillerEsp')
end)
for _, Survivor in Forsaken.Survivors do
    if (Survivor:GetAttribute("Username") == LocalPlayer.Name) then continue end
    AddBoxEsp(Survivor, 'SurvivorEspColor', 'SurvivorEsp', true, true)
end
Survivors.ChildAdded:Connect(function(Survivor)
    if (Survivor:GetAttribute("Username") == LocalPlayer.Name) then return end
    AddBoxEsp(Survivor, 'SurvivorEspColor', 'SurvivorEsp', true, true)
end)
for _, Entity in workspace.Map.Ingame:GetChildren() do
    if (Entity.Name ~= 'PizzaDeliveryRig' and Entity.Name ~= '1x1x1x1Zombie') then continue end
    AddBoxEsp(Entity, 'EntityEspColor', 'EntityEsp')
end
workspace.Map.Ingame.ChildAdded:Connect(function(Entity)
    if (Entity.Name ~= 'PizzaDeliveryRig' and Entity.Name ~= '1x1x1x1Zombie') then return end
    AddBoxEsp(Entity, 'EntityEspColor', 'EntityEsp')
end)

task.spawn(function()
    while wait(0.1) do
        -- Esp generators
        local FuckingTable = Forsaken.EspAppliedToGenerators
        for _, Generator in Forsaken.RoundGenerators do
            if (Unloaded) then return end
            if (not Catsaken.Flags.GeneratorEsp.CurrentValue) then
                if (not Generator:FindFirstChildOfClass('Highlight')) then continue end
                Generator:FindFirstChildOfClass('Highlight'):Destroy()
                for Image, Tbl in Forsaken.ConstantImages do
                    local Center = Generator.Positions.Center
                    if (Tbl.Handle == Center) then
                        Tbl.Connection:Disconnect()
                        Image:Destroy()
                        Forsaken.ConstantImages[Image], Images[Center] = nil, nil
                    end
                end
                FuckingTable[Generator] = false
                continue
            end
            if (FuckingTable[Generator]) then continue end
            FuckingTable[Generator] = true
            AddHighlightEsp(Generator, 'GeneratorEspColor', true)
        end
        -- Esp items
        FuckingTable = Forsaken.EspAppliedToItems
        for _, Item in Forsaken.Items do
            if (Unloaded) then return end
            if (not Catsaken.Flags.ItemEsp.CurrentValue) then
                if (not Item:FindFirstChildOfClass('Highlight')) then continue end
                Item:FindFirstChildOfClass('Highlight'):Destroy()
                FuckingTable[Item] = false
                continue
            end
            if (FuckingTable[Item]) then continue end
            FuckingTable[Item] = true
            AddHighlightEsp(Item, 'ItemEspColor')
        end
        -- Esp gingerbread
        FuckingTable = Forsaken.EspAppliedToGingerbread
        for _, Gingerbread in Forsaken.Gingerbread do
            if (Unloaded) then return end
            if (not Catsaken.Flags.GingerbreadEsp.CurrentValue) then
                if (not Gingerbread:FindFirstChildOfClass('Highlight')) then continue end
                Gingerbread:FindFirstChildOfClass('Highlight'):Destroy()
                FuckingTable[Gingerbread] = false
                continue
            end
            if (FuckingTable[Gingerbread]) then continue end
            FuckingTable[Gingerbread] = true
            AddHighlightEsp(Gingerbread, 'GingerbreadEspColor')
        end
        -- Esp taph
        FuckingTable = Forsaken.EspAppliedToTaphDebris
        for _, Debris in Forsaken.TaphDebris do
            if (Unloaded) then return end
            if (not Catsaken.Flags.TaphEsp.CurrentValue) then
                if (not Debris:FindFirstChildOfClass('Highlight')) then continue end
                if (not IsKiller()) then continue end
                Debris:FindFirstChildOfClass('Highlight'):Destroy()
                FuckingTable[Debris] = false
                continue
            end
            if (FuckingTable[Debris]) then continue end
            FuckingTable[Debris] = true
            AddHighlightEsp(Debris, 'TaphEspColor', false)
        end
        -- Esp builderman
        FuckingTable = Forsaken.EspAppliedToBuildermanDebris
        for _, Debris in Forsaken.BuildermanDebris do
            if (Unloaded) then return end
            if (not Catsaken.Flags.BuildermanEsp.CurrentValue) then
                if (not Debris:FindFirstChildOfClass('Highlight')) then continue end
                if (not IsKiller()) then continue end
                Debris:FindFirstChildOfClass('Highlight'):Destroy()
                FuckingTable[Debris] = false
                continue
            end
            if (FuckingTable[Debris]) then continue end
            FuckingTable[Debris] = true
            AddHighlightEsp(Debris, 'BuildermanEspColor', false)
        end
        -- Esp jd (note to myself dont copy this in later esp)
        FuckingTable = Forsaken.EspAppliedToDoeDebris
        for _, Debris in Forsaken.DoeDebris do
            if (Unloaded) then return end
            if (not Catsaken.Flags.JohnDoeEsp.CurrentValue) then
                if (not Debris:FindFirstChild('Highlight')) then continue end
                Debris:FindFirstChild('Highlight'):Destroy()
                FuckingTable[Debris] = false
                continue
            end
            if (Debris:FindFirstChild("PlayerAura")) then
                Debris.PlayerAura:Destroy()
            end
            if (FuckingTable[Debris]) then continue end
            FuckingTable[Debris] = true
            Debris.Transparency = 0
            AddHighlightEsp(Debris, 'JohnDoeEspColor', false)
        end
        -- Esp vee
        FuckingTable = Forsaken.EspAppliedToVeeDebris
        for _, Debris in Forsaken.VeeDebris do
            if (Unloaded) then return end
            if (not Catsaken.Flags.VeeronicaEsp.CurrentValue) then
                if (not Debris:FindFirstChildOfClass('Highlight')) then continue end
                Debris:FindFirstChildOfClass('Highlight'):Destroy()
                FuckingTable[Debris] = false
                continue
            end
            if (FuckingTable[Debris]) then continue end
            FuckingTable[Debris] = true
            AddHighlightEsp(Debris, 'VeeronicaEspColor', false)
        end
        -- Esp azure
        FuckingTable = Forsaken.EspAppliedToAzureDebris
        for _, Debris in Forsaken.AzureDebris do
            if (Unloaded) then return end
            if (not Catsaken.Flags.AzureEsp.CurrentValue) then
                if (not Debris:FindFirstChild('AZUREHIGHLIGHT')) then continue end
                Debris.AZUREHIGHLIGHT:Destroy()
                FuckingTable[Debris] = false
                continue
            end
            if (FuckingTable[Debris]) then continue end
            FuckingTable[Debris] = true
            AddHighlightEsp(Debris, 'AzureEspColor', false, 'AZUREHIGHLIGHT')
        end
    end
end)

StaminaTab:CreateSection('Infinite Stamina')

function UpdateStamina()
    if (Forsaken.GameState ~= 1) then return end
    if not SprintModule.__staminaChangedEvent then return end
    SprintModule.__staminaChangedEvent:Fire()
end

local Values = {
    MaxStamina = tostring(SprintModule.DefaultConfig.MaxStamina),
    StaminaLoss = tostring(SprintModule.DefaultConfig.StaminaLoss),
    StaminaGain = tostring(SprintModule.DefaultConfig.StaminaGain)
}
StaminaTab:CreateToggle({
    Name = 'Infinite Stamina',
    CurrentValue = false,
    Flag = 'UnlimitedRunning',
    Callback = function()
        task.spawn(function()
            while wait() do
                pcall(function()
                    if (not Catsaken.Flags.UnlimitedRunning.CurrentValue) then
                        return
                    elseif (SprintModule.Stamina < SprintModule.MaxStamina) then
                        SprintModule.Stamina = SprintModule.MaxStamina
                        UpdateStamina()
                    end
                end)
            end
        end)
    end,
    Blatant = true
})
StaminaTab:CreateLabel('If you sprint for too long with stamina mods you\'ll get kicked for speedhacking')

StaminaTab:CreateSection('Stamina settings arent compatible with inf stamina.')

StaminaTab:CreateInput({
    Name = 'Max Stamina',
    CurrentValue = Values.MaxStamina,
    PlaceholderText = 'Number',
    RemoveTextAfterFocusLost = false,
    Flag = 'StaminaOptions_MaxStamina',
    Callback = function(Text)
        if (not tonumber(Text)) then
            return Rayfield:Notify({Title = 'Please enter a number', Content = 'to change your max stamina', Duration = 6.5})
        end
        Values.MaxStamina = Text
    end
})

StaminaTab:CreateInput({
    Name = 'Stamina Loss',
    CurrentValue = Values.StaminaLoss,
    PlaceholderText = 'Number',
    RemoveTextAfterFocusLost = false,
    Flag = 'StaminaOptions_StaminaLoss',
    Callback = function(Text)
        if (not tonumber(Text)) then
            return Rayfield:Notify({Title = 'Please enter a number', Content = 'to change your stamina loss', Duration = 6.5})
        end
        Values.StaminaLoss = Text
    end
})

StaminaTab:CreateInput({
    Name = 'Stamina Gain',
    CurrentValue = Values.StaminaGain,
    PlaceholderText = 'Number',
    RemoveTextAfterFocusLost = false,
    Flag = 'StaminaOptions_StaminaGain',
    Callback = function(Text)
        if (not tonumber(Text)) then
            return Rayfield:Notify({Title = 'Please enter a number', Content = 'to change your stamina gain', Duration = 6.5})
        end
        Values.StaminaGain = Text
    end
})

task.spawn(function()
    while wait() do
        for Name, Val in Values do
            if (SprintModule[Name] ~= tonumber(Val)) then
                SprintModule[Name] = tonumber(Val)
                UpdateStamina()
            end
        end
    end
end)

local SilentAimValues = {}
local AimbotValues = {}

SilentTab:CreateSection('Silent Aim allows you to hit your target without aiming')

SilentTab:CreateToggle({
    Name = 'Enable silent aim',
    CurrentValue = false,
    Flag = 'SilentAimToggle',
    Callback = NULL
})

SilentTab:CreateDropdown({
    Name = 'Ability to use silent aim',
    Options = {'Plasma beam - Dusekkar', 'Void Star - Noli', 'Corrupt Nature - Coolkid'},
    CurrentOption = {},
    MultipleOptions = true,
    Flag = 'SilentAimValues',
    Callback = function(Options)
        SilentAimValues = {}
        for _, Option in Options do
            SilentAimValues[Option:match("^(.-)%s*%-")] = true
        end
    end
})

SilentTab:CreateToggle({
    Name = 'Dusekkar target survivor',
    CurrentValue = false,
    Flag = 'DusekkarSurvivor',
    Callback = NULL,
    TextMode = true
})

-- Silent aim for dusekkar
local OldGMP OldGMP = hookfunction(GetMousePos, newcclosure(function(...)
    local Killer = GetClosestToMouse('Killer')
    local Survivor = GetClosestToMouse('Survivor')
    if (Forsaken.DusekkarActive and Catsaken.Flags.SilentAimToggle.CurrentValue) then
        if (SilentAimValues['Plasma beam']) then
            if (Catsaken.Flags.DusekkarSurvivor.CurrentValue and Survivor) then
                return Predict(Survivor)
            elseif (Killer) then
                return Predict(Killer)
            end
        end
    elseif (Forsaken.NoliActive and Catsaken.Flags.SilentAimToggle.CurrentValue) then
        if (SilentAimValues['Void Star'] and Survivor) then
            local Root = Survivor:FindFirstChild("HumanoidRootPart")
            local Hit = workspace:Raycast(Root.Position, Vector3.new(0,-1000,0), RaycastParams.new())
            return (Hit and Hit.Position) or Root.Position
        end
     elseif (Forsaken.CoolkidActive and Catsaken.Flags.SilentAimToggle.CurrentValue) then
        if (SilentAimValues['Corrupt Nature'] and Survivor) then
            -- Prediction on corrupt nature is LITERALLY USELESS because of how slow this ability is!
            return Predict(Survivor)
        end
    end
    return OldGMP(...)
end))

SilentTab:CreateSection('Aimbot')

SilentTab:CreateToggle({
    Name = 'Enable aimbots',
    CurrentValue = false,
    Flag = 'AimbotToggle',
    Callback = NULL
})

SilentTab:CreateDropdown({
    Name = 'Ability to use aimbot',
    Options = {'Entanglement - 1x1x1x1', 'Mass Infection - 1x1x1x1', 'Throw Pizza - Elliot', 'Blood Hook - Nosferatu', 'One Shot - Chance', 'Corrupt Energy - John Doe', 'Enstrangle - Azure'},
    CurrentOption = {},
    MultipleOptions = true,
    Flag = 'AimbotValues',
    Callback = function(Options)
        AimbotValues = {}
        for _, Option in Options do
            AimbotValues[Option:match("^(.-)%s*%-")] = true
        end
    end
})

SilentTab:CreateToggle({
    Name = 'M1 assist',
    CurrentValue = false,
    Flag = 'Mouse1Aimbot',
    Callback = NULL
})

function MassInfectionActive()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('SpeedMultipliers') and LocalPlayer.Character:FindFirstChild('SpeedMultipliers'):FindFirstChild('MassInfection')
end

function EntanglementActive()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('SpeedMultipliers') and LocalPlayer.Character:FindFirstChild('SpeedMultipliers'):FindFirstChild("Entanglement")
end

function ElliotHasPizza()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Pizza') and LocalPlayer.Character:FindFirstChild('Pizza').Transparency == 0
end

function AzureAimingEnstrangle()
    return LocalPlayer.Character and LocalPlayer.Character.Name == 'Azure' and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart:FindFirstChild("Attachment")
end

task.spawn(function()
    while task.wait() do
        if AimbotValues['Enstrangle'] and AzureAimingEnstrangle() then
            local SurvivorClose = GetClosestSurvivor(25)
            if SurvivorClose then
                StartAimbotting(SurvivorClose, function()
                    return AzureAimingEnstrangle()
                end, nil, math.huge)
                task.wait(1.6)
            end
        end
    end
end)

function stareFunc(target)
    local chr = LocalPlayer.Character
    local hrp = chr and chr:FindFirstChild('HumanoidRootPart')
    local troot = target and target:FindFirstChild('HumanoidRootPart')
    if hrp.Anchored or troot.Anchored then return end
    if not (hrp and troot) then return end
    local p = hrp.Position
    hrp.CFrame = CFrame.new(p, Vector3.new(troot.Position.X, p.Y, troot.Position.Z))
end

Network.RemoteEvent.OnClientEvent:Connect(function(...)
    local Args = ({...})
    if Args[1] == "UseActorAbility" then
        local Arg = Args[2]
        if (type(Arg) == "table" and typeof(Arg[1]) == "buffer") then
            local abilityName = buffer.tostring(Arg[1])
            if (
                abilityName:find(GetM1Name()) or abilityName:find('Dagger') or abilityName:find('Axe')
                or abilityName:find('Shoot') or abilityName:find('Punch') or abilityName:find('Block')
                or abilityName:find('Punch') or abilityName:find('Charge')) and CheckInvis()
            then
                Rayfield:Notify({Title = 'Catsaken', Content = 'U cant use that ability when you\'re invisible btw', Duration = 9})
                return
            end
            local Survivor = GetClosestSurvivor(130)
            local Killer = GetClosestKiller(90)
            local AnyKiller = GetClosestKiller(5000)
            local SurvivorClose = GetClosestSurvivor(25)
            local SurvivorMedium = GetClosestSurvivor(95)
            local M1Target = LocalPlayer.Character and (
                (IsKiller() and GetClosestSurvivor(10)) or (LocalPlayer.Character.Name == 'Shedletsky' and GetClosestKiller(10))
            )
            if IsKiller() and Catsaken.Flags.AutoFarmSurvivors.CurrentValue then
                M1Target = nil
            end
            warn("UseActorAbility CLIENTEVENT:", buffer.tostring(Arg[1]))

            if (abilityName:find('MassInfection') and (AimbotValues['Mass Infection'] and Catsaken.Flags.AimbotToggle.CurrentValue) and Survivor and not CheckInvis()) then
                StartAimbotting(Survivor, MassInfectionActive)
            elseif (abilityName:find('Entanglement') and (AimbotValues['Entanglement'] and Catsaken.Flags.AimbotToggle.CurrentValue) and Survivor and not CheckInvis()) then
                StartAimbotting(Survivor, EntanglementActive)
            elseif (abilityName:find('Uppercut') and (AimbotValues['Blood Hook'] and Catsaken.Flags.AimbotToggle.CurrentValue) and SurvivorMedium and not CheckInvis()) then
                local Now = tick()
                StartAimbotting(SurvivorMedium, function()
                    return (tick() - Now <= 2) and IsKiller()
                end)
            elseif (abilityName:find('ThrowPizza') and (AimbotValues['Throw Pizza'] and Catsaken.Flags.AimbotToggle.CurrentValue) and SurvivorClose and not CheckInvis()) then
                StartAimbotting(SurvivorClose, ElliotHasPizza, function()
                    local LocalPlayerRoot = LocalPlayer.Character.HumanoidRootPart
                    local TargetRoot = SurvivorClose.HumanoidRootPart
                    local ArmWorldPosition = LocalPlayerRoot.CFrame * Vector3.new(-1, 0, 0)
                    local AimDirection = (TargetRoot.Position - ArmWorldPosition).Unit
                    return CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + AimDirection)
                end)
            elseif (abilityName:find('Shoot') and ((AimbotValues['One Shot'] and Catsaken.Flags.AimbotToggle.CurrentValue) or Catsaken.Flags.TPOneShot.CurrentValue) and LocalPlayer.Character.Name == 'Chance' and (Catsaken.Flags.TPOneShot.CurrentValue and AnyKiller or Killer) and not CheckInvis()) then
                local Now = tick()
                local LocalPlayerRoot = LocalPlayer.Character.HumanoidRootPart
                local TargetRoot = (Catsaken.Flags.TPOneShot.CurrentValue and AnyKiller or Killer).HumanoidRootPart
                local Old = LocalPlayerRoot.CFrame
                if Catsaken.Flags.TPOneShot.CurrentValue then PlayerControls:Disable() end
                StartAimbotting(Catsaken.Flags.TPOneShot.CurrentValue and AnyKiller or Killer, function() return (tick() - Now <= 2) end, function()
                    if Catsaken.Flags.TPOneShot.CurrentValue then
                        LocalPlayerRoot.CFrame = TargetRoot.CFrame - (TargetRoot.CFrame.LookVector * 4)
                    end
                    local ArmWorldPosition = LocalPlayerRoot.CFrame * Vector3.new(-1, 0, 0)
                    local AimDirection = (TargetRoot.Position - ArmWorldPosition).Unit
                    return CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + AimDirection)
                end)
                if Catsaken.Flags.TPOneShot.CurrentValue then
                    LocalPlayerRoot.CFrame = Old
                end
                PlayerControls:Enable()
            elseif (abilityName:find('Dagger') and Catsaken.Flags.TPDagger.CurrentValue and AnyKiller and not CheckInvis()) then
                PlayerControls:Disable()
                local Now = tick()
                local LocalPlayerRoot = LocalPlayer.Character.HumanoidRootPart
                local TargetRoot = AnyKiller.HumanoidRootPart
                local Old = LocalPlayerRoot.CFrame
                while (tick() - Now <= 2) and (LocalPlayer.Character and LocalPlayer.Character.Parent == Survivors) and not HasNotification('stabbed') and not CheckInvis() do
                    LocalPlayerRoot.CFrame = TargetRoot.CFrame - (TargetRoot.CFrame.LookVector * 2)
                    task.wait()
                end
                LocalPlayerRoot.CFrame = Old
                PlayerControls:Enable()
                LocalPlayer.Character.Humanoid:MoveTo(Old.Position)
            elseif (abilityName:find('Slash') and Catsaken.Flags.TPSlash.CurrentValue and AnyKiller and LocalPlayer.Character.Parent == Survivors and not CheckInvis()) then
                PlayerControls:Disable()
                local Now = tick()
                local LocalPlayerRoot = LocalPlayer.Character.HumanoidRootPart
                local TargetRoot = AnyKiller.HumanoidRootPart
                local Old = LocalPlayerRoot.CFrame
                while (tick() - Now <= 1) and (LocalPlayer.Character and LocalPlayer.Character.Parent == Survivors) and not HasNotification('stunned') and not CheckInvis() do
                    LocalPlayerRoot.CFrame = TargetRoot.CFrame
                    task.wait()
                end
                LocalPlayerRoot.CFrame = Old
                PlayerControls:Enable()
            elseif (abilityName:find('CorruptEnergy') and (AimbotValues['Corrupt Energy'] and Catsaken.Flags.AimbotToggle.CurrentValue) and SurvivorMedium) then
                local Now = tick()
                StartAimbotting(SurvivorMedium, function()
                    return (tick() - Now <= (DoeConfig.DelayBetweenSpikeSummons * DoeConfig.SpikeAmount) + DoeConfig.CorruptEnergyWindup) and IsKiller()
                end)
            elseif (abilityName:find(GetM1Name()) and Catsaken.Flags.Mouse1Aimbot.CurrentValue and M1Target and not (HasNotification('stunned') or HasNotification('you tried')) and not CheckInvis()) then 
                local Now = tick()
                while M1Target.Parent and tick() - Now <= 0.66 and (LocalPlayer.Character and (LocalPlayer.Character.Parent == Killers or LocalPlayer.Character.Parent == Survivors)) and task.wait() do
                    stareFunc(M1Target)
                end
            end
        end
    end
end)

HitboxTab:CreateSection('Hitbox Expander')

HitboxTab:CreateToggle({
    Name = 'Enable hitbox expander',
    CurrentValue = false,
    Flag = 'HitboxExpander',
    Callback = NULL,
    Blatant = true
})

HitboxTab:CreateSlider({
    Name = 'Range',
    Range = {30, 200},
    Increment = 1,
    Suffix = '',
    CurrentValue = 60,
    Flag = 'HitboxExpanderRange',
    Callback = NULL
})

HitboxTab:CreateSection('Hitbox Visualiser (PERFORMANCE INTENSIVE)')

HitboxTab:CreateLabel('To show hitboxes, enable from ingame settings\nThe higher the transparency is, the less visible it is')

HitboxTab:CreateToggle({
    Name = 'Enable visualiser modifications',
    CurrentValue = false,
    Flag = 'HitboxModifications',
    Callback = NULL
})

local Materials = {}
for i, v in Enum.Material:GetEnumItems() do
    Materials[i] = tostring(v):split('.')[3]
end
table.sort(Materials)

HitboxTab:CreateDropdown({
    Name = 'Material',
    Options = Materials,
    CurrentOption = {'Plastic'},
    MultipleOptions = false,
    Flag = 'HitboxMaterialValue',
    Callback = NULL
})

HitboxTab:CreateColorPicker({
    Name = 'Hitbox color',
    Color = Color3.new(1, 0.25, 0.25),
    Flag = 'HitboxColor',
    Callback = NULL
})
HitboxTab:CreateColorPicker({
    Name = 'Hitbox color (Hit)',
    Color = Color3.new(0.5, 1, 0.5),
    Flag = 'HitboxHitColor',
    Callback = NULL
})

HitboxTab:CreateSlider({
    Name = 'Hitbox transparency',
    Range = {0, 1},
    Increment = 0.02,
    Suffix = '',
    CurrentValue = 1,
    Flag = 'HitboxTransparency',
    Callback = NULL
})

HitboxTab:CreateSlider({
    Name = 'Hitbox transparency (Hit)',
    Range = {0, 1},
    Increment = 0.02,
    Suffix = '',
    CurrentValue = 1,
    Flag = 'HitboxHitTransparency',
    Callback = NULL
})

-- Modify hitboxes
workspace.Hitboxes.ChildAdded:Connect(function(Hitbox)
    if (not Catsaken.Flags.HitboxModifications.CurrentValue) then return end
    local Mat = Enum.Material[Catsaken.Flags.HitboxMaterialValue.CurrentOption[1]]
    local OriginalColor = Hitbox.Color
    while Hitbox.Parent and wait() do
        Hitbox.Material = Mat
        if (OriginalColor.R ~= 1) then -- Hit
            Hitbox.Color = Catsaken.Flags.HitboxHitColor.Color
            Hitbox.Transparency = Catsaken.Flags.HitboxHitTransparency.CurrentValue
        else
            Hitbox.Color = Catsaken.Flags.HitboxColor.Color
            Hitbox.Transparency = Catsaken.Flags.HitboxTransparency.CurrentValue
        end
    end
end)

-- Hitbox expander code
task.spawn(function()
    local RunService = game:GetService("RunService")
    local RNG = Random.new()
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")
    local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    LocalPlayer.CharacterAdded:Connect(function(char)
        Character = char
        Humanoid = char:WaitForChild("Humanoid")
        HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    end)
    while wait() do
        if Catsaken.Flags.HitboxExpander.CurrentValue and HumanoidRootPart then
            local playing = false
            for _, track in ipairs(Humanoid:GetPlayingAnimationTracks()) do
                if table.find(Forsaken.AttackAnimations, track.Animation.AnimationId) and (track.TimePosition / track.Length < 0.75) then
                    playing = true
                    break
                end
            end
            if playing then
                local Target
                local NearestDist = Catsaken.Flags.HitboxExpanderRange.CurrentValue
                function scanGroup(group)
                    for _, obj in ipairs(group) do
                        if obj ~= Character and obj:FindFirstChild("HumanoidRootPart") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("Humanoid").Health > 0 then
                            local dist = (obj.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
                            if dist < NearestDist then
                                NearestDist = dist
                                Target = obj
                            end
                        end
                    end
                end
                scanGroup(workspace.Players:GetDescendants())
                local npcs = workspace:FindFirstChild("Map", true) and workspace.Map:FindFirstChild("NPCs", true)
                if npcs then
                    scanGroup(npcs:GetChildren())
                end
                if Target then
                    local ping = tonumber(Stats.PerformanceStats.Ping:GetValue()) / 1000
                    local randomOffset = Vector3.new(RNG:NextNumber(-1.5, 1.5), 0, RNG:NextNumber(-1.5, 1.5))
                    local predicted = Target.HumanoidRootPart.Position + randomOffset + (Target.HumanoidRootPart.Velocity * (ping * 1.25))
                    local neededVelocity = (predicted - HumanoidRootPart.Position) / (ping * 2)
                    local oldVelocity = HumanoidRootPart.Velocity
                    HumanoidRootPart.Velocity = neededVelocity
                    RunService.RenderStepped:Wait()
                    HumanoidRootPart.Velocity = oldVelocity
                end
            end
        end
    end
end)

ConvenienceTab:CreateSection('Convenient features')

ConvenienceTab:CreateToggle({
    Name = 'Disable directional speed',
    CurrentValue = false,
    Flag = 'DisableDirectionalSpeed',
    Callback = function(Callback)
        if (Callback) then
            DirectionalSpeed:Destroy()
        else
            DirectionalSpeed:Start()
        end
    end
})

ConvenienceTab:CreateToggle({
    Name = 'Disable directional movement',
    CurrentValue = false,
    Flag = 'DisableDirectionalMovement',
    Callback = function(Callback)
        if (Callback) then
            task.spawn(function()
                while wait() do
                    if (LocalPlayer.Character and Catsaken.Flags.DisableDirectionalMovement.CurrentValue) then
                        LocalPlayer.Character:SetAttribute('DirectionalMovementDisabled', true)
                    end
                end
            end)
        elseif ((not Callback) and LocalPlayer.Character) then
            LocalPlayer.Character:SetAttribute('DirectionalMovementDisabled', false)
        end
    end
})

ConvenienceTab:CreateToggle({
    Name = 'Anti dusekkar protection break',
    CurrentValue = false,
    Flag = 'ProtectionBreak',
    Callback = NULL
})

ConvenienceTab:CreateToggle({
    Name = 'Speed boost',
    CurrentValue = false,
    Flag = 'SmallSpeedBoost',
    Callback = function()
        task.spawn(function()
            while wait() and Catsaken.Flags.SmallSpeedBoost.CurrentValue do
                local Char = LocalPlayer.Character
                local Hum = Char and Char:FindFirstChild('HumanoidRootPart') and Char:FindFirstChild('Humanoid')
                if (Forsaken.GameState == 1 and Hum and Char.HumanoidRootPart.Velocity.Magnitude > 1) then
                    Char:TranslateBy(Hum.MoveDirection * (Catsaken.Flags.SpeedBoostPercent and (Catsaken.Flags.SpeedBoostPercent.CurrentValue/10) or 7) * RunService.RenderStepped:Wait())
                end
            end
        end)
    end
})

ConvenienceTab:CreateSlider({
    Name = '└── Percent',
    Range = {10, 70},
    Increment = 1,
    Suffix = '%',
    CurrentValue = 70,
    Flag = 'SpeedBoostPercent',
    Callback = NULL
})

ConvenienceTab:CreateToggle({
    Name = 'Auto back to lobby',
    CurrentValue = false,
    Flag = 'AutoLobby',
    Callback = function()
        task.spawn(function()
            while wait() and Catsaken.Flags.AutoLobby.CurrentValue do
                local ReturnButton = LocalPlayer.PlayerGui:FindFirstChild('EndScreen') and LocalPlayer.PlayerGui.EndScreen:FindFirstChild('Main') and LocalPlayer.PlayerGui.EndScreen.Main:FindFirstChild('Return')
                if (ReturnButton) then
                    firesignal(ReturnButton.MouseButton1Click)
                end
            end
        end)
    end
})

ConvenienceTab:CreateToggle({
    Name = 'Always show sidebar',
    CurrentValue = false,
    Flag = 'SidebarVisibility',
    Callback = function(Callback)
        task.spawn(function()
            if (Forsaken.GameState == 1 and Callback == false) then
                if (PlayerInfoUI) then
                    PlayerInfoUI.Position = UDim2.new(0, 20, 1, -20)
                end
                return SidebarHandler:ToggleSidebarButtons(false)
            end
            while wait() and Catsaken.Flags.SidebarVisibility.CurrentValue do
                if (SidebarHandler.MenusHidden) then
                    if (PlayerInfoUI) then
                        PlayerInfoUI.Position = UDim2.new(0, 100, 1, -70)
                    end
                    SidebarHandler:ToggleSidebarButtons(true)
                end
            end
        end)
    end
})

ConvenienceTab:CreateToggle({
    Name = 'Always show chat',
    CurrentValue = false,
    Flag = 'AlwaysShowChat',
    Callback = function(Callback)
        if (Callback) then
            task.spawn(function()
                while task.wait() do
                    if (Catsaken.Flags.AlwaysShowChat.CurrentValue) then
                        game:GetService("TextChatService"):FindFirstChildOfClass("ChatWindowConfiguration").Enabled = true
                    elseif (Forsaken.GameState == 1) then
                        game:GetService("TextChatService"):FindFirstChildOfClass("ChatWindowConfiguration").Enabled = false
                    end
                end
            end)
        end
    end
})

ConvenienceTab:CreateToggle({
    Name = 'Disable AFK insanity',
    CurrentValue = false,
    Flag = 'DisableAFKTaunting',
    Callback = function(Callback)
        task.spawn(function()
            if Callback then
                while Catsaken.Flags.DisableAFKTaunting.CurrentValue do
                    firesignal(UserInputService.InputEnded, {})
                    task.wait(5)
                end
            end
        end)
    end 
})

ConvenienceTab:CreateToggle({
    Name = 'Infinite disarm attempts',
    CurrentValue = false,
    Flag = 'InfiniteDisarmAttempts',
    Callback = NULL,
        ToolTip = 'Gives you infinite attempts in the minigame when disarming a vine or bulb from azure'
});

(function()
    local toggleState = false
    local originalValues = {}
    local paths = {
        "HideKillerWins",
        "HidePlaytime",
        "HideSurvivorWins"
    }
    local function saveOriginals(player)
        if not originalValues[player.UserId] then
            originalValues[player.UserId] = {}
        end;
        for _, key in ipairs(paths) do
            local value = player.PlayerData.Settings.Privacy:FindFirstChild(key)
            originalValues[player.UserId][key] = value.Value
        end
    end;
    local function reveal(player)
        for _, key in ipairs(paths) do
            local value = player.PlayerData.Settings.Privacy:FindFirstChild(key)
            value.Value = false
        end
    end;
    local function restore(player)
        if originalValues[player.UserId] then
            for key, val in pairs(originalValues[player.UserId]) do
                local value = player.PlayerData.Settings.Privacy:FindFirstChild(key)
                value.Value = val
            end
        end
    end;
    local function hiddenStatsFunc(disable)
        for _, player in ipairs(Players:GetPlayers()) do
            if disable then
                saveOriginals(player)
                reveal(player)
            else
                restore(player)
            end
        end
    end;
    Players.PlayerAdded:Connect(function(player)
        if toggleState == true then
            saveOriginals(player)
            reveal(player)
        end
    end)
    ConvenienceTab:CreateToggle({
        Name = 'Privacy bypass',
        CurrentValue = false,
        Flag = 'PrivacyBypass',
        Callback = function(value)
            toggleState = value;
            hiddenStatsFunc(value)
        end,
        ToolTip = 'Let\'s you see players stats, even when they are hidden'
    })
end)()
ConvenienceTab:CreateSection('Ability modifiers')

local cachedParts = {}
function EnableNoclip()
    if LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetChildren()) do
            if v:IsA("BasePart") then
                cachedParts[v] = v
                v.CanCollide = false
            end
        end
    end
end

function DisableNoclip()
    for _, v in pairs(cachedParts) do
        v.CanCollide = true
    end
end

ConvenienceTab:CreateToggle({
    Name = 'Demonic pursuit noclip',
    CurrentValue = false,
    Flag = 'DemonicPursuitNoclip',
    Callback = function()
        task.spawn(function()
            while wait() and Catsaken.Flags.DemonicPursuitNoclip.CurrentValue do
                if (LocalPlayer.Character and LocalPlayer.Character:GetAttribute('PursuitState') == 'Dashing') then
                    EnableNoclip()
                    repeat wait() until not LocalPlayer.Character or LocalPlayer.Character:GetAttribute('PursuitState') ~= 'Dashing' or not IsKiller()
                    DisableNoclip()
                end
            end
        end)
    end,
    Blatant = true
})

ConvenienceTab:CreateToggle({
    Name = 'Demonic pursuit anti-crash',
    CurrentValue = false,
    Flag = 'DemonicPursuitAntiCrash',
    Callback = NULL
})

ConvenienceTab:CreateToggle({
    Name = 'Void rush noclip',
    CurrentValue = false,
    Flag = 'VoidRushNoclip',
    Callback = function()
        task.spawn(function()
            while wait() and Catsaken.Flags.VoidRushNoclip.CurrentValue do
                if (LocalPlayer.Character and LocalPlayer.Character:GetAttribute('VoidRushState') == 'Dashing') then
                    EnableNoclip()
                    repeat wait() until not LocalPlayer.Character or LocalPlayer.Character:GetAttribute('VoidRushState') ~= 'Dashing' or not IsKiller()
                    DisableNoclip()
                end
            end
        end)
    end,
    Blatant = true
})

ConvenienceTab:CreateToggle({
    Name = 'Void rush anti-crash',
    CurrentValue = false,
    Flag = 'VoidRushAntiCrash',
    Callback = NULL
})

-- Hook noli & guest 666 crash remotes
function TrackAttributes(Character)
    Character:GetAttributeChangedSignal('PursuitState'):Connect(function()
        if (Character:GetAttribute('PursuitState') == 'Dashing') then
            Forsaken.PursuitTracker = tick()
        end
    end)
    Character:GetAttributeChangedSignal('VoidRushState'):Connect(function()
        if (Character:GetAttribute('VoidRushState') == 'Dashing') then
            Forsaken.VoidRushTracker = tick()
        end
    end)
end
TrackAttributes(LocalPlayer.Character)
LocalPlayer.CharacterAdded:Connect(TrackAttributes)

local Old
local SixerConfig = require(MainKillersPath.Sixer.Config)
local NoliConfig = require(MainKillersPath.Noli.Config)

-- Get and Hook the function that validates radius during dusekkars spawn protection
local IsCharWithinRadius = debug.getupvalue(DusekkarBehavior.Created, 3)
local Old
Old = hookfunction(IsCharWithinRadius, newcclosure(function(Player, Mag, _)
    if (not Catsaken.Flags.ProtectionBreak.CurrentValue) then return Old(Player, Mag, _) end
    return Old(Player, 9e9)
end))

-- Auto block
AutoblockTab:CreateSection('Auto block')
AutoblockTab:CreateToggle({
    Name = 'Auto block',
    CurrentValue = false,
    Flag = 'AutoBlockToggle',
    Callback = function(S)
        if S and Catsaken.Flags.AntiHit.CurrentValue then
            Rayfield:Notify({Title = 'Auto backstab', Content = 'Disable anti hit, or auto block wont work', Duration = 6, Image = 'sword'})
        end
    end
})

AutoblockTab:CreateToggle({
    Name = 'Auto clone 007n7',
    CurrentValue = false,
    Flag = 'AutoCloneToggle',
    Callback = NULL,
    ToolTip = 'Uses 007n7\'s clone ability when killer hits you to make the killer\'s attack hit the clone instead of you'
})

AutoblockTab:CreateToggle({
    Name = 'Auto raging pace',
    CurrentValue = false,
    Flag = 'AutoParryToggle',
    Callback = NULL,
    ToolTip = 'Uses slasher\'s raging pace ability when it detects shedletsky slash, jane doe axe, two time backstab, or guest1337 punch to parry them and avoid stun'
})

local PingLabel = AutoblockTab:CreateLabel("Ping: 0ms")
task.spawn(function()
    while wait() do
        PingLabel:Set(`Your ping is {Stats.PerformanceStats.Ping:GetValue()/1000}s`)
    end
end)
AutoblockTab:CreateLabel("Having speed boost enabled significantly decreases accuracy")
AutoblockTab:CreateSection('Settings')
AutoblockTab:CreateToggle({
    Name = 'Auto punch',
    CurrentValue = true,
    Flag = 'AutoBlockPunch',
    Callback = NULL
})

AutoblockTab:CreateToggle({
    Name = 'Hitbox drag tech',
    CurrentValue = true,
    Flag = 'HitboxDragTech',
    Callback = NULL,
    ToolTip = 'Walks into the killer\'s old attack hitboxes to get a free parry'
})

AutoblockTab:CreateSlider({
    Name = 'Raging Pace detection range',
    Range = {4, 12},
    Increment = 1,
    Suffix = '',
    CurrentValue = 10,
    Flag = 'RagingPaceRange',
    Callback = NULL
})

AutoblockTab:CreateToggle({
    Name = 'Raging Pace face check',
    CurrentValue = true,
    Flag = 'RagingPaceFaceCheck',
    Callback = NULL,
    TextMode = true
})

AutoblockTab:CreateSlider({
    Name = 'Wait delay before blocking',
    Range = {0, 100},
    Increment = 1,
    Suffix = 'ms',
    CurrentValue = 0,
    Flag = 'AutoBlockMS',
    Callback = NULL
})

AutoblockTab:CreateSection('Visualizer')
AutoblockTab:CreateToggle({
    Name = 'Show visualizer',
    CurrentValue = true,
    Flag = 'AutoBlockVisualizer',
    Callback = NULL
})
AutoblockTab:CreateSlider({
    Name = 'Left size',
    Range = {0, 9},
    Increment = 1,
    Suffix = '',
    CurrentValue = 5,
    Flag = 'VisualizerLeft',
    Callback = NULL
})
AutoblockTab:CreateSlider({
    Name = 'Right size',
    Range = {0, 9},
    Increment = 1,
    Suffix = '',
    CurrentValue = 5,
    Flag = 'VisualizerRight',
    Callback = NULL
})
AutoblockTab:CreateSlider({
    Name = 'Front size',
    Range = {0, 18},
    Increment = 1,
    Suffix = '',
    CurrentValue = 9,
    Flag = 'VisualizerFront',
    Callback = NULL
})
AutoblockTab:CreateSlider({
    Name = 'Back size',
    Range = {0, 11},
    Increment = 1,
    Suffix = '',
    CurrentValue = 5,
    Flag = 'VisualizerBack',
    Callback = NULL
})
AutoblockTab:CreateSlider({
    Name = 'Extra front size when walking',
    Range = {0, 9},
    Increment = 1,
    Suffix = '',
    CurrentValue = 6,
    Flag = 'VisualizerFrontPlus',
    Callback = NULL
})

AutoblockTab:CreateColorPicker({
    Name = 'Color (In hitbox)',
    Color = Color3.fromRGB(0, 255, 0),
    Flag = 'VisualizerInColor',
    Callback = NULL
})

AutoblockTab:CreateColorPicker({
    Name = 'Color (Not in hitbox)',
    Color = Color3.fromRGB(255, 0, 0),
    Flag = 'VisualizerOutColor',
    Callback = NULL
})

AutoblockTab:CreateSection('Block Settings')
AutoblockTab:CreateLabel("Guest 1337 can not parry heavy attacks like mass infection, void rush, etc anymore. he only negates damage, so if you want to spare your block for an actual parry, just turn all these off")
AutoblockTab:CreateToggle({
    Name = 'Block entanglement',
    CurrentValue = true,
    Flag = 'AutoBlockEntanglement',
    Callback = NULL,
    TextMode = true
})
AutoblockTab:CreateToggle({
    Name = 'Block void rush',
    CurrentValue = true,
    Flag = 'AutoBlockVoidRush',
    Callback = NULL,
    TextMode = true
})
AutoblockTab:CreateToggle({
    Name = 'Block walkspeed override',
    CurrentValue = true,
    Flag = 'AutoBlockOverride',
    Callback = NULL,
    TextMode = true
})
AutoblockTab:CreateToggle({
    Name = 'Enable sprint after block',
    CurrentValue = true,
    Flag = 'AutoParrySprint',
    Callback = NULL,
    TextMode = true
})
AutoblockTab:CreateToggle({
    Name = 'Notifications',
    CurrentValue = true,
    Flag = 'AutoBlockNotifications',
    Callback = NULL,
    TextMode = true
})

local DoAntiHit = false

function CheckInvis()
    if (IsKiller() and Catsaken.Flags.AutoFarmSurvivors.CurrentValue) then
        return false
    end
    return DoingAllGenerators or (Catsaken.Flags.PartialInvisibility and Catsaken.Flags.PartialInvisibility.CurrentValue) or (DoAntiHit and (Catsaken.Flags.AntiHit and Catsaken.Flags.AntiHit.CurrentValue))
end

function IsFacing(localRoot, targetRoot, rdot)
    local dir = (localRoot.Position - targetRoot.Position).Unit
    local dot = targetRoot.CFrame.LookVector:Dot(dir)
    return dot > (rdot or 0.6)
end

function Block()
    NetworkModule:FireServerConnection("UseActorAbility", "REMOTE_EVENT", 'Block')
end

function Punch()
    NetworkModule:FireServerConnection("UseActorAbility", "REMOTE_EVENT", 'Punch')
end

function Clone()
    NetworkModule:FireServerConnection("UseActorAbility", "REMOTE_EVENT", 'Clone')
end

function GetTrueWait(Asset)
    local Name
    for i, v in Forsaken.BlockMeta do
        if (i == Asset) then
            Name = v
        end
    end
    -- Wind-up
    if (Name == 'Entanglement') then
        return 0.4
    elseif (Name == 'MassInfection') then
        return 1.4
    elseif (Name == 'Behead' or Name == 'GashingWoundStart') then
        return 0.21
    end
    return 0
end

local IsBlocking = false
local Box = Instance.new("Part", workspace)
Box.Anchored = true
Box.CanCollide = false
Box.Transparency = 0.8
Box.Material = Enum.Material.Neon
Box.CFrame = CFrame.new(99999, 99999999, 9999)
Box:SetAttribute("in", false)

task.spawn(function()
    while true do
        if (Unloaded) then break end
        RunService.RenderStepped:Wait()
        pcall(function()
            local k = Forsaken.Killers[1]
            if tostring(LocalPlayer.Character) ~= 'Guest1337' or not k or not (Catsaken.Flags.AutoBlockVisualizer.CurrentValue and Catsaken.Flags.AutoBlockToggle.CurrentValue) then
                Box:SetAttribute("in", false)
                Box.CFrame = CFrame.new(99999, 99999999, 9999)
                return
            end

            local r = k:FindFirstChild('HumanoidRootPart')
            if r then
                local front = Catsaken.Flags.VisualizerFront.CurrentValue + (k.Humanoid.MoveDirection:Dot(r.CFrame.LookVector) > 0.1 and Catsaken.Flags.VisualizerFrontPlus.CurrentValue or 0)
                local left, right, back = Catsaken.Flags.VisualizerLeft.CurrentValue, Catsaken.Flags.VisualizerRight.CurrentValue, Catsaken.Flags.VisualizerBack.CurrentValue
                Box.CFrame = r.CFrame * CFrame.new((right - left) / 2, 0, -(front - back) / 2)
                Box.Size = Vector3.new(left + right, 10, front + back)
            else
                Box:SetAttribute("in", false)
                Box.CFrame = CFrame.new(99999, 99999999, 9999)
            end

            if not pcall(function()
                Box:SetAttribute("in", workspace:FindPartOnRayWithWhitelist(
                    Ray.new(LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, 100, 0), Vector3.new(0, -999, 0)),
                    {Box}
                ) == Box)
            end) then
                Box:SetAttribute("in", false)
            end

            Box.Color = Catsaken.Flags["Visualizer" .. (Box:GetAttribute("in") and "In" or "Out") .. "Color"].Color
        end)
    end
end)

function Counter(KillerModel, Root, track)
    if (KillerModel:GetAttribute('Invincible') == 1) then return end
    if (CheckInvis()) then return end
    local IsInBox = Box:GetAttribute("in")
    if IsInBox then
        if HasAbilityReady('Block') then
            Block()
            repeat task.wait() until IsBlocking
            if Catsaken.Flags.HitboxDragTech.CurrentValue then PlayerControls:Disable() end
            local SN = LocalPlayer.Character:GetAttribute("SkinName")
            if SN == "" then
                SN = nil
            end
            local DefaultGuest = require(MainSurvivorsPath.Guest1337.Config)
            local GuestInfo = SN and require(ReplicatedStorage.Assets.Skins.Survivors.Guest1337[SN].Config) or DefaultGuest
            pcall(function()
                local Success
                local Start = tick()
                while IsBlocking do
                    stareFunc(KillerModel)
                    if LocalPlayer.Character.HumanoidRootPart:FindFirstChild((GuestInfo.Sounds and GuestInfo.Sounds.BlockSuccess) or DefaultGuest.Sounds.BlockSuccess) then
                        Success = true
                        IsBlocking = false
                        if Catsaken.Flags.AutoBlockNotifications.CurrentValue then
                            Rayfield:Notify({Title = 'Auto Block', Content = 'Successful Block', Duration = 7, Image = 'shield'})
                        end
                        if (Catsaken.Flags.AutoParrySprint.CurrentValue) then
                            SprintModule.IsSprinting = true
                            SprintModule.__sprintedEvent:Fire(true)
                        end
                        break
                    end
                    if Catsaken.Flags.HitboxDragTech.CurrentValue and tick() - Start <= Forsaken.HitboxesDuration then
                        LocalPlayer.Character.Humanoid:MoveTo(KillerModel.HumanoidRootPart.Position)
                    else
                        PlayerControls:Enable()
                        if (tick() - Start >= (Forsaken.HitboxesDuration+.2)) then
                            IsBlocking = false -- failed block, just get away asap
                        end
                    end
                    RunService.RenderStepped:Wait()
                end
                if Success then
                    repeat task.wait() until HasAbilityReady('Punch')
                end
                if Catsaken.Flags.AutoBlockPunch.CurrentValue and HasAbilityReady('Punch') then
                    local s = tick()
                    Punch()
                    local R = KillerModel.HumanoidRootPart
                    while tick() - s <= 1 do
                        stareFunc(KillerModel)
                        LocalPlayer.Character.Humanoid:MoveTo(KillerModel.HumanoidRootPart.Position)
                        if R:FindFirstChild((GuestInfo.Sounds and GuestInfo.Sounds.CriticalPunch) or DefaultGuest.Sounds.CriticalPunch) or R:FindFirstChild((GuestInfo.Sounds and GuestInfo.Sounds.Parry) or DefaultGuest.Sounds.Parry) then
                            if Catsaken.Flags.AutoBlockNotifications.CurrentValue then
                                Rayfield:Notify({Title = 'Auto Punch', Content = 'Successful Punch', Duration = 7, Image = 'flame'})
                            end
                            if (Catsaken.Flags.AutoParrySprint.CurrentValue) then
                                SprintModule.IsSprinting = true
                                SprintModule.__sprintedEvent:Fire(true)
                            end
                            break
                        end
                        RunService.RenderStepped:Wait()
                    end
                end
            end)
            PlayerControls:Enable()
        end
        return true
    end
end

function TableFindThatWorks(Haystack, Needle)
    for i, v in Haystack do
        if v == Needle then
            return v
        end
    end
    return false
end

function IsFacing2(localRoot, targetRoot, fDot, rDot)
    local offset = localRoot.Position - targetRoot.Position
    local dist = offset.Magnitude
    if dist > 30 then
        return false
    end
    local forward = targetRoot.CFrame.LookVector
    local dir = offset.Unit
    local forwardDot = forward:Dot(dir)
    local rightDot = math.abs(targetRoot.CFrame.RightVector:Dot(dir))
    return forwardDot > (fDot or 0.7) and rightDot < (rDot or 0.4)
end

function SpyStuns(Char)
    Char:GetAttributeChangedSignal('Invincible'):Connect(function(v)
        if Char:GetAttribute("Invincible") == 1 then
            if Char:GetAttribute("RecentAttackerTime") and tick() - tonumber(Char:GetAttribute("RecentAttackerTime")) <= 1 then
                if Char == LocalPlayer.Character then return end
                if Catsaken.Flags.StunSpy.CurrentValue then
                    local timestunned = 0
                    local attackerchar = Players[Char:GetAttribute("RecentAttacker")].Character
                    if attackerchar.Name == "Shedletsky" then
                        timestunned = require(MainSurvivorsPath.Shedletsky.Config).SlashStunTime
                    elseif attackerchar.Name == "TwoTime" then
                        timestunned = 2
                    elseif attackerchar.Name == "Guest1337" and (Char.HumanoidRootPart:FindFirstChild("rbxassetid://13471740561") or Char.HumanoidRootPart:FindFirstChild("rbxassetid://116900970230089")) then
                        timestunned = require(MainSurvivorsPath.Guest1337.Config).ParryStunTime
                    end
                    if timestunned == 0 then return warn("cant figure out what stunned") end
                    timestunned = timestunned + 0.75 -- so forsaken usually takes like 1 second to let the killer actually move for some reason
                    local bb = Instance.new("BillboardGui", Char.Head)
                    bb.AlwaysOnTop = true
                    bb.StudsOffset = Vector3.new(0, 2, 0)
                    bb.Size = UDim2.new(1, 40, 1, 0)
                    bb.Name = "stunspybb"
                    local tl = Instance.new("TextLabel", bb)
                    tl.Size = UDim2.new(1, 0, 1, 0)
                    tl.TextSize = 20
                    tl.Font = Enum.Font.LuckiestGuy
                    tl.BackgroundTransparency = 1
                    tl.TextColor3 = Color3.fromRGB(212, 0, 0)
                    local start = tick()
                    while timestunned - (tick() - start) > 0 do
                        tl.Text = string.format("Stunned for %.2fs", timestunned - (tick() - start))
                        task.wait()
                    end
                    bb:Destroy()
                end
            end
        end
    end)
end

local BlockAnims = {}

function TrackAnimations(Char,IsSurvivor,IsNew)
    local Root = Char and Char:WaitForChild('HumanoidRootPart', 7)
    if (not Root) then return end
    local Hum = Root and Char:WaitForChild("Humanoid", 7)
    if (not Hum) then return end
    local Animator = Hum:WaitForChild('Animator', 5)
    if (not Animator) then return end

    local stamina
    local sprinting = false
    local timeUntilRecover = 0
    local lastUpdate = tick()

    local function GetConfig()
        return require((Char.Parent.Name == 'Killers' and MainKillersPath or MainSurvivorsPath)[Char.Name].Config)
    end

    local cfg = GetConfig()

    task.spawn(function()
        if IsNew then return end
        lastUpdate = tick()
        
        while Char.Parent do
            if (Unloaded) then break end
            local now = tick()
            local dt = now - lastUpdate
            lastUpdate = now

            local StaminaLoss = cfg.StaminaLoss or 10
            local StaminaGain = cfg.StaminaGain or 20
            local MaxStamina = cfg.MaxStamina or 100

            if not stamina then
                stamina = MaxStamina
            end

            sprinting = Char:GetAttribute('sprinting')

            if sprinting then
                timeUntilRecover = math.clamp(timeUntilRecover + dt * 0.05, 0.2, 2)
                stamina = math.clamp(stamina - StaminaLoss * dt, 0, MaxStamina)
                if stamina <= 0 then
                    timeUntilRecover = 2
                end
            else
                timeUntilRecover = math.clamp(timeUntilRecover - dt, 0, 2)
                if timeUntilRecover <= 0 then
                    stamina = math.clamp(stamina + StaminaGain * dt, 0, MaxStamina)
                end
            end

            Char:SetAttribute('estimatedStamina', stamina)
            task.wait()
        end
    end)

    Animator.AnimationPlayed:Connect(function(track)
        local AttackName
        for i, v in Forsaken.BlockMeta do
            if (i == track.Animation.AnimationId) then
                AttackName = v
                break
            end
        end
        if (Unloaded) then return end
        local SN = Char:GetAttribute('SkinName')
        if SN == '' then SN = nil end
        local defaultcharconfig = GetConfig()
        local skincharconfig = SN and require(ReplicatedStorage.Assets.Skins[Char.Parent.Name][Char.Name][SN].Config)
        local runanim1
        local runanim2
        if skincharconfig and skincharconfig.Animations and skincharconfig.Animations.InjuredRun then
            runanim2 = skincharconfig.Animations.InjuredRun
        else
            runanim2 = defaultcharconfig.Animations.InjuredRun or "rbxassetid://115946474977409"
        end
        if skincharconfig and skincharconfig.Animations and skincharconfig.Animations.Run then
            runanim1 = skincharconfig.Animations.Run
        else
            runanim1 = defaultcharconfig.Animations.Run or "rbxassetid://136252471123500"
        end
        if track.Animation.AnimationId == runanim1 or track.Animation.AnimationId == runanim2 then
            Char:SetAttribute('sprinting', true)
            Char:SetAttribute("timestartedsprinting", tick())
            track.Stopped:Once(function()
                Char:SetAttribute("timestartedsprinting", nil)
                Char:SetAttribute('sprinting', false)
            end)
        end
        local validblockanim = (skincharconfig and skincharconfig.Animations and skincharconfig.Animations.Block) and skincharconfig.Animations.Block or defaultcharconfig.Animations.Block
        if TableFindThatWorks(BlockAnims, track.Animation.AnimationId) then
            task.spawn(function()
                local foundresistance = false
                local lbt = Char:GetAttribute('LAST_BLOCK_TIME')
                
                while track.IsPlaying and not Unloaded and task.wait() do
                    if track.Animation.AnimationId ~= validblockanim and not Players[Char:GetAttribute("Username")]:GetAttribute('ILLEGAL_ANIMATION_FLAG') and Catsaken.Flags.ANTICHEAT_DETECTANIMATIONS.CurrentValue then
                        warn("[Anticheat]", Char:GetAttribute("Username"), " changed block animation!", validblockanim, "->", track.Animation.AnimationId)
                        Char:SetAttribute('ILLEGAL_ANIMATION_FLAG', true)
                        Players[Char:GetAttribute("Username")]:SetAttribute('ILLEGAL_ANIMATION_FLAG', true)
                    end
                    local rs = Char.ResistanceMultipliers:FindFirstChild('ResistanceStatus')
                    if rs and rs:GetAttribute('Duration') == 1 and rs.Value == 100 then
                        foundresistance = true
                    end
                end
                if GetGameMap() and not foundresistance and not Players[Char:GetAttribute("Username")]:GetAttribute('FAKE_BLOCK_FLAG') and Catsaken.Flags.ANTICHEAT_DETECTANIMATIONS.CurrentValue then
                    warn("[Anticheat]", Char:GetAttribute("Username"), 'committed a fake block (NO resistance status applied)')
                    Char:SetAttribute('FAKE_BLOCK_FLAG', true)
                    Players[Char:GetAttribute("Username")]:SetAttribute('FAKE_BLOCK_FLAG', true)
                elseif foundresistance then
                    warn("[Anticheat]", Char:GetAttribute("Username"), 'blocked, but it was REAL!')
                end
                if ((lbt and tick() - Char:GetAttribute('LAST_BLOCK_TIME') <= 26 and not Players[Char:GetAttribute("Username")]:GetAttribute('FAKE_BLOCK_FLAG') and not ResistanceStatus) or Char.Name ~= 'Guest1337') and Catsaken.Flags.ANTICHEAT_DETECTANIMATIONS.CurrentValue then
                    if Char.Name ~= 'Guest1337' then
                        warn("[Anticheat]", Char:GetAttribute("Username"), " committed a fake block! (blocking as non-guest)")
                    else
                        --warn("[Anticheat]", Char:GetAttribute("Username"), " committed a fake block!", ('%.1f'):format(27 - (tick() - Char:GetAttribute('LAST_BLOCK_TIME'))) .. "s early")
                    end
                    Char:SetAttribute('FAKE_BLOCK_FLAG', true)
                    Players[Char:GetAttribute("Username")]:SetAttribute('FAKE_BLOCK_FLAG', true)
                end
                Char:SetAttribute('LAST_BLOCK_TIME', tick())
            end)
        end
        if Char == LocalPlayer.Character and IsSurvivor and Char.Name == 'Guest1337' then
            if TableFindThatWorks(BlockAnims, track.Animation.AnimationId) then
                IsBlocking = true
                while track.IsPlaying do
                    if not IsBlocking then
                        return -- auto-block reset it after a sucessful block
                    end
                    task.wait()
                end
                IsBlocking = false
            end
        end
        if IsSurvivor and IsKiller() and LocalPlayer.Character.Name == 'Slasher' then
            if not table.find(Forsaken.SentinelAnimations, track.Animation.AnimationId) then return end
            local LRoot = LocalPlayer.Character.HumanoidRootPart
            local TRoot = Char.HumanoidRootPart
            while track.IsPlaying do
                if Catsaken.Flags.AutoParryToggle.CurrentValue and HasAbilityReady('RagingPace') then
                    local mag = (LRoot.Position - TRoot.Position).Magnitude
                    if mag <= Catsaken.Flags.RagingPaceRange.CurrentValue and
                    (mag <= 5 or not Catsaken.Flags.RagingPaceFaceCheck.CurrentValue or IsFacing2(LRoot, TRoot, 0.707, 1)) then
                        NetworkModule:FireServerConnection("UseActorAbility", "REMOTE_EVENT", 'RagingPace')
                    end
                end
                task.wait()
            end
            return
        end
        local iswso
        if (table.find(Forsaken.WalkspeedOverrideAnimations, track.Animation.AnimationId)) then
            Forsaken.UsingWalkspeedOverride = true
            iswso = true
            warn("walkspeed override detected")
        end
        if (table.find(Forsaken.WalkspeedOverrideEndedAnims, track.Animation.AnimationId)) then
            Forsaken.UsingWalkspeedOverride = false
            warn("ws stopped")
        end
        task.spawn(function()
            if Catsaken.Flags.RevealTrajectory.CurrentValue then
                if (AttackName == 'MassInfection' or AttackName == 'Entanglement' or AttackName == 'UppercutPullingLoop' or AttackName == 'Enstrangle' or iswso) then
                    local Box = Instance.new("Part", workspace)
                    Box.Anchored = true
                    Box.CanCollide = false
                    Box.Transparency = 0.7
                    Box.Material = Enum.Material.Neon
                    Box.Color = Color3.fromRGB(255, 0, 0)
                    while track.IsPlaying or Forsaken.UsingWalkspeedOverride do
                        local front = 1000
                        local left, right, back = 6, 6, 0
                        if (AttackName == 'Entanglement' or AttackName == 'Enstrangle' or AttackName == 'UppercutPullingLoop') then
                            left, right = 3, 3
                        end
                        if (iswso) then
                            left, right = 4, 4
                        end
                        Box.CFrame = Char.HumanoidRootPart.CFrame * CFrame.new((right - left) / 2, 0, -(front - back) / 2)
                        Box.Size = Vector3.new(left + right, 10, front + back)
                        RunService.RenderStepped:Wait()
                    end
                    TweenService:Create(Box, TweenInfo.new(2, Enum.EasingStyle.Linear), {Transparency = 1})
                    task.wait(2)
                    Box:Destroy()
                end
            end
        end)
        if (not table.find(Forsaken.AttackAnimations, track.Animation.AnimationId)) then return end
        local KillerModel = Forsaken.Killers[1]
        local KillerModel2 = GetClosestKiller(17)
        function GetHitboxes()
            local Num = 0
            for i, Hitbox in workspace.Hitboxes:GetChildren() do
                if (Hitbox.Name:sub(1, -7) == KillerModel2:GetAttribute('Username')) then
                    Num += 1
                end
            end
            return Num
        end
        task.spawn(function()
            if (table.find(Forsaken.AttackAnimations, track.Animation.AnimationId) and KillerModel2 ~= nil and Char ~= LocalPlayer.Character) then
                warn("detected m1")
                DoAntiHit = true
                while GetHitboxes() > 0 do wait() end
                wait(0.4 + GetTrueWait(track.Animation.AnimationId))
                DoAntiHit = false
            end
        end)
        if (KillerModel ~= nil) then
            local canBlock = true
            if (AttackName == 'Entanglement' and not Catsaken.Flags.AutoBlockEntanglement.CurrentValue) then
                canBlock = false
            end
            if (canBlock) then
                if (HasAbilityReady("Block") and (not IsKiller()) and Catsaken.Flags.AutoBlockToggle.CurrentValue) then
                    local startedtime = tick()
                    while track.IsPlaying and tick() - startedtime <= Forsaken.HitboxesDuration do -- this is roughly the time that hitboxes stop working
                        if Counter(KillerModel, Root, track) then break end
                        task.wait()
                    end
                elseif (HasAbilityReady('Clone') and Catsaken.Flags.AutoCloneToggle.CurrentValue) then
                    Clone()
                end
            end
        end
        task.wait()
    end)
end
for _, Killer in Forsaken.Killers do
    SpyStuns(Killer)
    TrackAnimations(Killer,nil,true)
end
Killers.ChildAdded:Connect(function(Killer)
    SpyStuns(Killer)
    TrackAnimations(Killer)
end)
for _, Surv in Forsaken.Survivors do
    if table.find({'Shedletsky', 'TwoTime', 'JaneDoe', 'Guest1337'}, Surv.Name) then
        TrackAnimations(Surv,true,true)
    end
end
Survivors.ChildAdded:Connect(function(Surv)
    if table.find({'Shedletsky', 'TwoTime', 'JaneDoe', 'Guest1337'}, Surv.Name) then
        TrackAnimations(Surv,true)
    end
end)

function VoidRushIsDangerous()
    for _, Killer in Forsaken.Killers do
        if (Killer:GetAttribute("VoidRushState") == 'Dashing') then
            local LRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
            local Root = Killer:FindFirstChild('HumanoidRootPart')
            if (Root and LRoot) then
                return IsFacing2(LRoot, Root), Killer
            end
        end
    end
end

function OverrideIsDangerous()
    local LRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    if (not LRoot) then return end
    local k = GetClosestKiller(22)
    if (Forsaken.UsingWalkspeedOverride and k and k.Name == 'c00lkidd') then
        local Root = k:FindFirstChild('HumanoidRootPart')
        if (not Root) then return end
        return IsFacing2(LRoot, Root), k
    end
end

local NoliWarned
local CoolkidWarned
RunService.RenderStepped:Connect(function() -- Perfer to use RenderStepped instead of a loop because we need this to check as fast as possible
    if (Catsaken.Flags.AutoBlockToggle.CurrentValue) then
        local Dangerous, Noli = VoidRushIsDangerous()
        if (Dangerous and HasAbilityReady('Block') and Catsaken.Flags.AutoBlockVoidRush.CurrentValue) then
            warn('Scary')
            Block()
        else
            NoliWarned = false
        end
        local Dangerous, Coolkid = OverrideIsDangerous()
        if (Dangerous and HasAbilityReady('Block') and Catsaken.Flags.AutoBlockOverride.CurrentValue) then
            warn('Scary2')
            Block()
        else
            CoolkidWarned = false
        end
    end
end)

PlayerTab:CreateSection('Player related settings')

function NeedToEscapeOrReel()
    local UI = TemporaryUI:FindFirstChild("QTE")
    return UI ~= nil and UI:FindFirstChild('Zone3') == nil
end

function Check()
    for _, Object in TemporaryUI:GetChildren() do
        if (Object.Name == '1x1x1x1Popup') then
            Object:Destroy()
        end
    end
end

PlayerTab:CreateToggle({
    Name = 'Auto remove popups',
    CurrentValue = false,
    Flag = 'AutoClearPopups',
    Callback = function(Callback)
        if (Callback) then
            Check()
        end
    end
})

PlayerTab:CreateToggle({
    Name = 'Auto escape nosferatu',
    CurrentValue = false,
    Flag = 'NosferatuMinigame',
    Callback = NULL
})

PlayerTab:CreateToggle({
    Name = 'Auto unsprint',
    CurrentValue = false,
    Flag = 'AutoUnsprint',
    Callback = function()
        task.spawn(function()
            while wait() and Catsaken.Flags.AutoUnsprint.CurrentValue do
                if (Catsaken.Flags.AutoUnsprint.CurrentValue and SprintModule.Stamina < 3) then
                    SprintModule.IsSprinting = false
                    SprintModule.__sprintedEvent:Fire(false)
                end
            end
        end)
    end
})

PlayerTab:CreateToggle({
    Name = 'Always enable sprint',
    CurrentValue = false,
    Flag = 'AutoSprint',
    Callback = function()
        task.spawn(function()
            while wait() and Catsaken.Flags.AutoSprint.CurrentValue do
                if (Catsaken.Flags.AutoUnsprint.CurrentValue and SprintModule.Stamina ~= 100) then continue end
                if (not SprintModule.IsSprinting and tick() - Forsaken.RoundStart >= 6) then
                    SprintModule.IsSprinting = true
                    SprintModule.__sprintedEvent:Fire(true)
                end
            end
        end)
    end
})

PlayerTab:CreateToggle({
    Name = 'No sprint tweening',
    CurrentValue = false,
    Flag = 'NoSprintTween',
    Callback = NULL,
    ToolTip = 'Makes it so you when you sprint you immediately have full sprint speed instead of gradually getting faster'
})

PlayerTab:CreateToggle({
    Name = 'No slowdown',
    CurrentValue = false,
    Flag = 'NoSlowdown',
    Callback = function()
        task.spawn(function()
            while wait() and Catsaken.Flags.NoSlowdown.CurrentValue do
                if (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('SpeedMultipliers')) then
                    for _, Mul in LocalPlayer.Character.SpeedMultipliers:GetChildren() do
                        if (not HasAbility(Mul.Name) and Mul.Value < 1) then
                            warn("Changing slowness effect: ", Mul)
                            Mul.Value = 1
                            Mul:GetPropertyChangedSignal('Value'):Connect(function()
                                Mul.Value = 1
                            end)
                        end
                    end
                end
            end
        end)
    end
})

PlayerTab:CreateToggle({
    Name = 'No slowdown from abilitys',
    CurrentValue = false,
    Flag = 'NoAbilitySlowdown',
    Callback = function()
        task.spawn(function()
            while wait() and Catsaken.Flags.NoAbilitySlowdown.CurrentValue do
                if (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('SpeedMultipliers')) then
                    for _, Mul in LocalPlayer.Character.SpeedMultipliers:GetChildren() do
                        if (HasAbility(Mul.Name) and Mul.Value < 1) then
                            warn("Changing ability slowness effect: ", Mul)
                            Mul.Value = 1
                            Mul:GetPropertyChangedSignal('Value'):Connect(function()
                                Mul.Value = 1
                            end)
                        end
                    end
                end
            end
        end)
    end
})

PlayerTab:CreateDropdown({
    Name = 'Device Spoofer',
    Options = {'PC', 'Mobile', 'Console', 'Unknown'},
    CurrentOption = {RealDevice},
    MultipleOptions = false,
    Flag = 'DeviceSpooferValue',
    Callback = function(Options)
        NetworkModule:FireServerConnection("SetDevice", "REMOTE_EVENT", Options[1])
    end
})

PlayerTab:CreateSection('Player abilitys')

function VerronicaIsSkating()
    if (Forsaken.GameState ~= 1) then return false end
    if (LocalPlayer.Character.Name ~= 'Veeronica') then return false end
    if (not VeeronicaBehavior:FindFirstChild('Highlight')) then return false end
    if (VeeronicaBehavior.Highlight.Adornee ~= LocalPlayer.Character) then return false end
    return true
end

PlayerTab:CreateToggle({
    Name = 'Veeronica auto trick',  
    CurrentValue = false,
    Flag = 'AutoTrick',
    Callback = function()
        task.spawn(function()
            while wait() and Catsaken.Flags.AutoTrick.CurrentValue do
                if (VerronicaIsSkating()) then
                    PressKeycode(Enum.KeyCode.Space)
                end
            end
        end)
    end
})

PlayerTab:CreateToggle({
    Name = 'Veeronica control',
    CurrentValue = false,
    Flag = 'SkateTurningControl',
    Callback = function(Bool)
        if (Bool) then
            Rayfield:Notify({Title = 'Veeronica control', Content = 'Wait until the next round to start for this feature to apply', Duration = 4})
            VeeronicaConfig.Sk8TurnControl = 6.5
        else
            VeeronicaConfig.Sk8TurnControl = 0.65
        end
    end
})

PlayerTab:CreateToggle({
    Name = 'Nosferatu auto reel',
    CurrentValue = false,
    Flag = 'AutoNosferatuReel',
    Callback = NULL
})

task.spawn(function()
    local MagicVar
    while wait() and (Catsaken.Flags.NosferatuMinigame.CurrentValue or Catsaken.Flags.AutoNosferatuReel.CurrentValue) do
        if (NeedToEscapeOrReel()) then
            if (IsKiller()) then
                if (not Catsaken.Flags.AutoNosferatuReel.CurrentValue) then
                    continue
                end
            else
                if (not Catsaken.Flags.NosferatuMinigame.CurrentValue) then
                    continue
                end
            end
            local Arg = (IsKiller() and LocalPlayer.Name or GetKillerUsername()) .. 'NosHookQTE'
            NetworkModule:FireServerConnection(Arg, "REMOTE_EVENT", true) -- voidsaken my beloved
            if (not MagicVar) then
                task.spawn(function()
                    MagicVar = true -- prevent multiple notifications
                    repeat wait() until not NeedToEscapeOrReel()
                    if (IsKiller()) then
                        Rayfield:Notify({Title = 'Blood Hook', Content = 'Automatically reeled survivor', Duration = 6, Image = tonumber('132244492243010')})
                    else
                        Rayfield:Notify({Title = 'Blood Hook', Content = 'Successfully escaped', Duration = 5, Image = tonumber('132244492243010')})
                    end
                    MagicVar = false
                end)
            end
        end
    end
end)

function GetCharges()
    local Suc, Res = pcall(function() if (HasAbility('Reroll')) then
        return tonumber(PlayerGui.MainUI.AbilityContainer.Reroll.Charges.Text)
    end end)
    if not Suc then return 9e9 end
    return Res or 9e9
end

local LastFlip = 0
PlayerTab:CreateToggle({
    Name = 'Auto flip coin',
    CurrentValue = false,
    Flag = 'AutoCoinFlip',
    Callback = function()
        task.spawn(function()
            while wait() and (Catsaken.Flags.AutoCoinFlip.CurrentValue) do
                if (GetCharges() < Catsaken.Flags.MaxCharges.CurrentValue and HasAbilityReady('CoinFlip') and (tick() - LastFlip >= 2.5)) then
                    NetworkModule:FireServerConnection("UseActorAbility", "REMOTE_EVENT", 'CoinFlip')
                    LastFlip = tick()
                end
            end
        end)
    end
})

PlayerTab:CreateSlider({
    Name = '└── Max charges',
    Range = {1, 3},
    Increment = 1,
    Suffix = '',
    CurrentValue = 1,
    Flag = 'MaxCharges',
    Callback = NULL
})

PlayerTab:CreateToggle({
    Name = 'Auto 404 Error',
    CurrentValue = false,
    Flag = 'AutoUse404Error',
    Callback = function()
        task.spawn(function()
            while wait() and (Catsaken.Flags.AutoUse404Error.CurrentValue) do
                if (HasAbilityReady('404Error')) then
                    NetworkModule:FireServerConnection("UseActorAbility", "REMOTE_EVENT", '404Error')
                end
            end
        end)
    end
})

PlayerTab:CreateToggle({
    Name = 'Auto Disarm Minigame',
    CurrentValue = false,
    Flag = 'AutoDisarmMinigame',
    Callback = NULL,
    Blatant = true
})

local OldAzureQTE; OldAzureQTE = hookfunction(AzureQTE.new, newcclosure(function(self, vine)
    local QTE = OldAzureQTE(self, vine)
    task.spawn(function()
        local name = tostring(vine):match('(.+)\'s Vine')
        if Catsaken.Flags.InfiniteDisarmAttempts.CurrentValue then
            QTE.FailedAttempts = -math.huge
            warn("patched FailedAttempts")
        end
        if Catsaken.Flags.AutoDisarmMinigame.CurrentValue then
            task.wait(1.5)
            QTE.Progress = 100
            QTE:Destroy()
            task.spawn(function()
                setthreadidentity(8)
                Rayfield:Notify({Title = 'Auto Disarm', Content = 'The disarm minigame was skipped successfully.', Duration = 7, Image = 'check'})
            end)
        end
    end)
    return QTE
end))

PlayerTab:CreateToggle({
    Name = 'TP Dagger',
    CurrentValue = false,
    Flag = 'TPDagger',
    Callback = NULL,
        Blatant = true
})

PlayerTab:CreateToggle({
    Name = 'TP Slash',
    CurrentValue = false,
    Flag = 'TPSlash',
    Callback = NULL,
        Blatant = true
})

PlayerTab:CreateToggle({
    Name = 'TP One Shot',
    CurrentValue = false,
    Flag = 'TPOneShot',
    Callback = NULL,
        Blatant = true
})

PlayerTab:CreateToggle({
    Name = 'Auto chicken',
    CurrentValue = false,
    Flag = 'AutoChicken',
    Callback = function()
        task.spawn(function()
            while wait() and (Catsaken.Flags.AutoChicken.CurrentValue) do
                if (HasAbilityReady("FriedChicken") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")) then
                    if (LocalPlayer.Character.Humanoid.Health <= Catsaken.Flags.AutoChickenHealth.CurrentValue) then
                        local ClosestKiller = GetClosestKiller(5000)
                        if (ClosestKiller and (not Catsaken.Flags.AutoChickenFar.CurrentValue or (LocalPlayer.Character.HumanoidRootPart.Position - ClosestKiller.HumanoidRootPart.Position).magnitude >= 100)) then
                            NetworkModule:FireServerConnection("UseActorAbility", "REMOTE_EVENT", 'FriedChicken')
                        end
                    end
                end
            end
        end)
    end
})

PlayerTab:CreateSlider({
    Name = '└── Health limit',
    Range = {1, 99},
    Increment = 1,
    Suffix = '',
    CurrentValue = 40,
    Flag = 'AutoChickenHealth',
    Callback = NULL
})

PlayerTab:CreateToggle({
    Name = '└── Only when far from killer',
    CurrentValue = false,
    Flag = 'AutoChickenFar',
    Callback = NULL,
    TextMode = true
})

PlayerTab:CreateToggle({
    Name = 'Stun spy',
    CurrentValue = false,
    Flag = 'StunSpy',
    Callback = function(cb,is)
        if cb and not is then
            Rayfield:Notify({Title = 'Work in progress', Content = 'Stun spy is still a work in progress, so it doesnt detect some stun types YET, it only detects: shedletsky, guest1337, twotime', Duration = 12, Image = 'info'})
        end
    end
})

PlayerTab:CreateToggle({
    Name = 'Reveal ability trajectory',
    CurrentValue = false,
    Flag = 'RevealTrajectory',
    ToolTip = 'Shows you the path of abilities like mass infection, entanglement, walkspeed override, etc. so you can dodge it easier'
})

PlayerTab:CreateSection('Invisibility')

if (identifyexecutor() ~= "Cosmic") then
    setthreadidentity(8)
    local InvisProp = {
        Name = 'Invisibility',
        CurrentValue = false,   
        Flag = 'PartialInvisibility',
        Callback = function(Callback)
            if (not Callback) then
                InvisToggleButton:deselect()
            else
                InvisToggleButton:select()
            end
        end,
        Blatant = true
    }
    local InvisToggleButton
    InvisToggleButton = TopbarPlus.new():setImage(tonumber('103479372336287')):setCaption('Invisibility'):bindEvent('deselected', function()
        setthreadidentity(8)
        Catsaken.Flags.PartialInvisibility:Set(false)
    end):bindEvent('selected', function()
        if not InvisProp.__UNLOCKED and not ShouldUseOldUI then return InvisToggleButton:deselect() end
        setthreadidentity(8)
        Catsaken.Flags.PartialInvisibility:Set(true)
    end):autoDeselect(false):setEnabled(false)
    Env.InvisToggleButton = InvisToggleButton
    setthreadidentity(8)
    PlayerTab:CreateToggle(InvisProp)
    PlayerTab:CreateToggle({
        Name = 'Invisibility button',
        CurrentValue = false,
        Flag = 'InvisibilityButton',
        Callback = function(Callback)
            InvisToggleButton:setEnabled(Callback)
        end,
        TextMode = true
    })

    if (not IsMobile) then
        PlayerTab:CreateKeybind({
            Name = 'Keybind',
            CurrentKeybind = 'V',
            HoldToInteract = false,
            CallOnChange = false,
            Callback = function()
                if (Catsaken.Flags.PartialInvisibility.CurrentValue) then
                    Catsaken.Flags.PartialInvisibility:Set(false)
                else
                    Catsaken.Flags.PartialInvisibility:Set(true)
                end
            end
        })
    end

    PlayerTab:CreateLabel("Hitboxes and attacks will not work when using invisibility")
    PlayerTab:CreateLabel("Do not run with invisibility or you will get kicked just walk")

    PlayerTab:CreateToggle({
        Name = 'Anti hit',
        CurrentValue = false,
        Flag = 'AntiHit',
        Callback = function(S,is)
            if S and Catsaken.Flags.AutoBackstab.CurrentValue and not is then
                Rayfield:Notify({Title = 'Anti hit', Content = 'Disable this if you want auto backstab to work better', Duration = 6, Image = 'sword'})
            end
            if S and Catsaken.Flags.AutoBlockToggle.CurrentValue and not is then
                Rayfield:Notify({Title = 'Anti hit', Content = 'Disable anti hit or auto block wont work', Duration = 6, Image = 'sword'})
            end
        end,
        Blatant = true
    })

    PlayerTab:CreateLabel("Anti hit uses Invisibility to dodge basic attacks")

    local OldReplicate
    OldReplicate = hookfunction(CharacterReplication.Serialize, newcclosure(function(...)
        if (Forsaken.GameState ~= 1) then
            return OldReplicate(...)
        end
        if (tick() - Forsaken.RoundStart < 3) then
            return OldReplicate(...)
        end
        local Args = {...}
        if (typeof(Args[1]) ~= 'CFrame') then
            return OldReplicate(...)
        end
        if (typeof(Args[2]) ~= 'Vector3') then
            return OldReplicate(...)
        end
        if (CheckInvis()) then
            return OldReplicate(Args[1], Args[2] + Vector3.new(0, 5000, 0))
        end
        return OldReplicate(...)
    end))
else
    PlayerTab:CreateLabel("Anti Hit and Invisibility not supported on cosmic")
end

-- Auto backrape
PlayerTab:CreateSection('Auto backstab')

PlayerTab:CreateToggle({
    Name = 'Auto backstab',
    CurrentValue = false,
    Flag = 'AutoBackstab',
    Callback = function(S)
        if S and Catsaken.Flags.AntiHit.CurrentValue then
            Rayfield:Notify({Title = 'Auto backstab', Content = 'Disable anti hit if you want this to work better', Duration = 6, Image = 'sword'})
        end
    end
})

PlayerTab:CreateToggle({
    Name = 'Enable invisibility after stab',
    CurrentValue = false,
    Flag = 'BackstabInvis',
    Callback = NULL,
    TextMode = true
})

function IsFacingBack(localRoot, targetRoot)
	local offset = localRoot.Position - targetRoot.Position
	local backDir = -targetRoot.CFrame.LookVector
	local backDist = offset:Dot(backDir)
	if (backDist <= 0 or backDist > 7) then
		return false
	end
	local closestPoint = backDir * backDist
	local sideDist = (offset - closestPoint).Magnitude
	return sideDist <= 3.5
end

task.spawn(function()
    while wait() do
        if (Catsaken.Flags.AutoBackstab.CurrentValue and not CheckInvis()) then
            local Root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
            local Killer = GetClosestKiller(15)
            if (Killer and Killer:FindFirstChild('HumanoidRootPart') and Root and HasAbilityReady('Dagger')) then
                stareFunc(Killer)
                if (IsFacingBack(Root, Killer.HumanoidRootPart)) then
                    local Now = tick()
                    StartAimbotting(Killer, function()
                        NetworkModule:FireServerConnection("UseActorAbility", "REMOTE_EVENT", 'Dagger')
                        local Hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Humanoid')
                        Hum:MoveTo(Killer.HumanoidRootPart.Position)
                        return (tick() - Now <= 2) and (LocalPlayer.Character and LocalPlayer.Character.Parent == Survivors) and not HasNotification('stabbed') and not CheckInvis()
                    end)
                    if Catsaken.Flags.BackstabInvis.CurrentValue and not Catsaken.Flags.PartialInvisibility.CurrentValue then
                        Catsaken.Flags.PartialInvisibility:Set(true)
                    end
                end
            end
        end
    end
end)

PlayerTab:CreateSection('Auto M1', 'Right')

PlayerTab:CreateToggle({
    Name = 'Auto Slash/M1',
    CurrentValue = false,
    Flag = 'AutoUseM1',
    Callback = function()
        task.spawn(function()
            while wait() and (Catsaken.Flags.AutoUseM1.CurrentValue) do
                if not CheckInvis() and (HasAbilityReady(GetM1Name())) then
                    local M1Target = LocalPlayer.Character and (
                        (IsKiller() and GetClosestSurvivor(Catsaken.Flags.AutoM1Radius.CurrentValue)) or 
                        (LocalPlayer.Character.Name == 'Shedletsky' and GetClosestKiller(Catsaken.Flags.AutoM1Radius.CurrentValue))
                    )
                    if (M1Target and M1Target:GetAttribute('Invincible') ~= 1 and M1Target:FindFirstChild('HumanoidRootPart') and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')) then
                        if ((not Catsaken.Flags.AutoM1FaceCheck.CurrentValue) or IsFacing(M1Target.HumanoidRootPart, LocalPlayer.Character.HumanoidRootPart, 0.73)) then
                            NetworkModule:FireServerConnection("UseActorAbility", "REMOTE_EVENT", GetM1Name())
                        end
                    end
                end
            end
        end)
    end
})

PlayerTab:CreateToggle({
    Name = 'Face check',
    CurrentValue = true,
    Flag = 'AutoM1FaceCheck',
    Callback = NULL,
    TextMode = true
})

PlayerTab:CreateSlider({
    Name = 'Radius',
    Range = {6, 15},
    Increment = 1,
    Suffix = '',
    CurrentValue = 10,
    Flag = 'AutoM1Radius',
    Callback = NULL
})

-- Map/World Shit
MapTab:CreateSection('Map')

MapTab:CreateToggle({
    Name = 'Spike noclip',
    CurrentValue = false,
    Flag = 'SpikeNoclip',
    Callback = function()
        task.spawn(function()
            while Catsaken.Flags.SpikeNoclip.CurrentValue and task.wait() do
                if (Forsaken.GameState == 1) then
                    for i, Spike in Forsaken.Spikes do
                        table.remove(Forsaken.Spikes, i)
                        Spike:Destroy()
                    end
                end
            end
        end)
    end
})

-- Gb autofarm
MapTab:CreateSection('Currency')

function SearchTool(Name)
    for _, Tool in Forsaken.Items do
        if (Tool.Name == Name) then
            return Tool
        end
    end
    return nil
end

function GrabTool(Tool)
    if (Forsaken.GameState ~= 1) then return end
    if (not Tool) then return end
    local Root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    local ContainsItem
    -- Due to noob's ability, he will always have a tool in his character model named BloxyCola. That is why im not just using findfirstchild
    if (Root) then
        for i, v in LocalPlayer.Character:GetChildren() do
            if (v.Name == Tool.Name and v:IsA('Tool')) then
                ContainsItem = true
                break
            end
        end
    end
    if (LocalPlayer.Backpack:FindFirstChild(Tool.Name) or ContainsItem) then return end
    if (Root and Tool:FindFirstChild('ItemRoot')) then
        local OldCF = Root.CFrame
        Root.CFrame = Tool.ItemRoot.CFrame
        local Now = tick()
        repeat
            local Prompt = Tool:FindFirstChild('ItemRoot') and Tool.ItemRoot:FindFirstChild('ProximityPrompt')
            if (not Prompt) then return end
            fireproximityprompt(Prompt)
            wait()
        until tick() - Now >= 4 or Tool.Parent == LocalPlayer.Backpack or not Tool.Parent
        if (tick() - Now >= 4) then
            return warn("timed out while picking up item")
        end
        Root.CFrame = OldCF
    end
end

function YoinkLoot()
    if (IsKiller()) then return end
    if (Catsaken.Flags.AutoRomania.CurrentValue) then
        GrabTool(SearchTool('BloxyCola'))
        GrabTool(SearchTool('Medkit'))
    end
end

MapTab:CreateToggle({
    Name = 'Autofarm gingerbread [DISABLED]',
    CurrentValue = false,
    Flag = 'AutofarmGingerbread',
    Callback = NULL
})

MapTab:CreateToggle({
    Name = 'Autofarm sukkars [DISABLED]',
    CurrentValue = false,
    Flag = 'AutofarmSukkars',
    Callback = NULL
})

task.spawn(function()
    while wait() do
        if (Forsaken.GameState == 1 and not DoingAllGenerators) then
            pcall(YoinkLoot)
        end
        if (Catsaken.Flags.AutofarmGingerbread.CurrentValue and Forsaken.GameState == 1 and not DoingAllGenerators) then
            for _, Gb in Forsaken.Gingerbread do
                local Root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
                if (Root and Gb:FindFirstChildWhichIsA('Part') and Gb[`{Gb}Exp`].Transparency ~= 1) then
                    Root.CFrame = Gb:FindFirstChildWhichIsA('Part').CFrame
                end
            end
        end
    end
end)

-- Item related stuff
MapTab:CreateSection('Items')

function GrabMedkit()
    local Medkit = SearchTool('Medkit')
    if (not Medkit) then
        return warn('no medkit found')
    end
    GrabTool(Medkit)
end

function GrabCola()
    local Cola = SearchTool('BloxyCola')
    if (not Cola) then
        return warn('no bloxy cola found')
    end
    GrabTool(Cola)
end

MapTab:CreateButton({
    Name = 'Grab medkit',
    Callback = GrabMedkit
})

MapTab:CreateButton({
    Name = 'Grab bloxy cola',
    Callback = GrabCola
})

MapTab:CreateToggle({
    Name = 'Auto pickup all items',
    CurrentValue = false,
    Flag = 'AutoRomania',
    Callback = NULL
})

MapTab:CreateToggle({
    Name = 'Auto pickup near items',
    CurrentValue = false,
    Flag = 'AutoPickCloseItems',
    Callback = NULL
})

task.spawn(function()
    while wait() do
        local Root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
        if (Root and Catsaken.Flags.AutoPickCloseItems.CurrentValue) then
            for _, Item in Forsaken.Items do
                if (Item:FindFirstChild('ItemRoot') and Item.ItemRoot:FindFirstChild('ProximityPrompt')) then
                    if ((Item.ItemRoot.Position - Root.Position).Magnitude <= Item.ItemRoot.ProximityPrompt.MaxActivationDistance) then
                        fireproximityprompt(Item.ItemRoot.ProximityPrompt)
                    end
                end
            end
        end
    end
end)

MapTab:CreateSection('Killer')
local KillerInfoLabel = MapTab:CreateLabel('Killer: @null [Skin]')
MapTab:CreateButton({
    Name = 'Spectate killer',
    Callback = function()
        local Killer = Forsaken.Killers[1]
        if Killer and Killer:FindFirstChild("Humanoid") then
            if workspace.CurrentCamera.CameraSubject == Killer.Humanoid then
                Rayfield:Notify({Title = `Spectate`, Content = 'Stopped spectating ' .. tostring(Killer), Duration = 6, Image = 'eye'})
                workspace.CurrentCamera.CameraSubject = LocalPlayer.Character
            elseif LocalPlayer.Character then
                Rayfield:Notify({Title = `Spectate`, Content = 'Spectating ' .. tostring(Killer) .. ' click again to stop', Duration = 6, Image = 'eye'})
                workspace.CurrentCamera.CameraSubject = Killer.Humanoid
            end
        end
    end
})

MapTab:CreateButton({
    Name = 'Teleport to killer',
    Callback = function()
        local Killer = Forsaken.Killers[1]
        if Killer and Killer:FindFirstChild("HumanoidRootPart") then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = Killer.HumanoidRootPart.CFrame
            end
        end
    end
})

MapTab:CreateToggle({
    Name = 'Farm survivors',
    CurrentValue = false,
    Flag = 'AutoFarmSurvivors',
    Callback = function(Callback)
        task.spawn(function()
            while wait() do
                pcall(function()
                    if (not Catsaken.Flags.AutoFarmSurvivors.CurrentValue) then
                        return
                    elseif (IsKiller()) then
                        local TargetSurvivor = Forsaken.Survivors[math.random(1, #Forsaken.Survivors)]
                        while TargetSurvivor.Parent and TargetSurvivor:FindFirstChild("Humanoid") and TargetSurvivor:FindFirstChild("HumanoidRootPart") and TargetSurvivor.Humanoid.Health > 0 do
                            local rootcf = TargetSurvivor.HumanoidRootPart.CFrame
                            LocalPlayer.Character.HumanoidRootPart.CFrame = rootcf
                            NetworkModule:FireServerConnection("UseActorAbility", "REMOTE_EVENT", GetM1Name())
                            task.wait()
                            if (not Catsaken.Flags.AutoFarmSurvivors.CurrentValue) then
                                return
                            end
                        end
                    end
                end)
            end
        end)
    end
})

MapTab:CreateToggle({
    Name = 'Bypass killer walls',
    CurrentValue = false,
    Flag = 'BypassKillerWalls',
    Callback = function(Callback)
        task.spawn(function()
            while wait() do
                pcall(function()
                    if (not Catsaken.Flags.BypassKillerWalls.CurrentValue) then
                        if (not IsKiller()) then
                            for i, v in pairs(LocalPlayer.Character:GetChildren()) do
                                if v:IsA("BasePart") and v.CollisionGroup == "Killers" then
                                    v.CollisionGroup = "Survivors"
                                end
                            end
                        end
                    elseif (not IsKiller()) then
                        for i, v in pairs(LocalPlayer.Character:GetChildren()) do
                            if v:IsA("BasePart") and v.CollisionGroup == "Survivors" then
                                v.CollisionGroup = "Killers"
                            end
                        end
                    end
                end)
            end
        end)
    end,
    Blatant = true
})

MapTab:CreateSection('Survivors', 'Left')
local SurvivorsNumLabel = MapTab:CreateLabel('Survivors: ' .. #Forsaken.Survivors)
task.spawn(function()
    while task.wait(0.5) do
        SurvivorsNumLabel:Set('Survivors: ' .. #Forsaken.Survivors)
        local K = Forsaken.Killers[1]
        if K then
            KillerInfoLabel:Set('Killer: @' .. K:GetAttribute('Username') .. ' [' .. K.Name .. ']')
        else
            KillerInfoLabel:Set('Killer: None')
        end
    end
end)
MapTab:CreateButton({
    Name = 'Teleport To Random Survivor',
    Callback = function()
        local Target
        repeat
            local Test = Forsaken.Survivors[math.random(1, #Forsaken.Survivors)]
            if Test and Test ~= LocalPlayer.Character then
                Target = Test:FindFirstChild("HumanoidRootPart")
            end
            task.wait()
        until Target or #Forsaken.Survivors < (IsKiller() and 1 or 2) or Unloaded
        if Target then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = Target.CFrame
            end
        end
    end
})

-- antis
AntisTab:CreateSection('Anti affects')

AntisTab:CreateToggle({
    Name = 'Anti slowness',
    CurrentValue = false,
    Flag = 'AntiSlowness',
    Callback = NULL
})

AntisTab:CreateToggle({
    Name = 'Anti subspace',
    CurrentValue = false,
    Flag = 'AntiSubspace',
    Callback = NULL
})

AntisTab:CreateToggle({
    Name = 'Anti blindness',
    CurrentValue = false,
    Flag = 'AntiBlindness',
    Callback = NULL
})

AntisTab:CreateToggle({
    Name = 'Anti glitched',
    CurrentValue = false,
    Flag = 'AntiGlitched',
    Callback = NULL
})

AntisTab:CreateToggle({
    Name = 'Anti slatekin slow/fov',
    CurrentValue = false,
    Flag = 'AntiSlateskin',
    Callback = NULL
})

AntisTab:CreateToggle({
    Name = 'Anti nausea',
    CurrentValue = false,
    Flag = 'AntiNausea',
    Callback = NULL
})

AntisTab:CreateToggle({
    Name = 'Anti stun',
    CurrentValue = false,
    Flag = 'AntiStun',
    Callback = NULL,
    Blatant = true
})

AntisTab:CreateToggle({
    Name = 'Anti hallucinate',
    CurrentValue = false,
    Flag = 'AntiHallu',
    Callback = NULL
})

AntisTab:CreateToggle({
    Name = 'Anti fall slowness',
    CurrentValue = false,
    Flag = 'AntiSlowOnLanding',
    Callback = function(Callback)
        if (Callback) then
            task.spawn(function()
                while wait() do
                    if (LocalPlayer.Character and Catsaken.Flags.AntiSlowOnLanding.CurrentValue) then
                        LocalPlayer.Character:SetAttribute('NoFallSlow', true)
                    end
                end
            end)
        elseif ((not Callback) and LocalPlayer.Character) then
            LocalPlayer.Character:SetAttribute('NoFallSlow', false)
        end
    end
})

AntisTab:CreateToggle({
    Name = 'Anti footsteps',
    CurrentValue = false,
    Flag = 'AntiFootsteps',
    Callback = function()
        if (Callback) then
            task.spawn(function()
                while wait() do
                    if (LocalPlayer.Character and Catsaken.Flags.AntiFootsteps.CurrentValue) then
                        LocalPlayer.Character:SetAttribute('FootstepsMuted', true)
                    end
                end
            end)
        elseif ((not Callback) and LocalPlayer.Character) then
            LocalPlayer.Character:SetAttribute('FootstepsMuted', false)
        end
    end
});

-- anticheat
function clearflags(v,m)
    if v.Character then
        v.Character:SetAttribute("INVISDETECTED", nil)
        v.Character:SetAttribute('TELEPORTS', 0)
        v.Character:SetAttribute('STAMINA_FLAG_TIME', nil)
        v.Character:SetAttribute('STAMINA_FLAGS', nil)
        v.Character:SetAttribute('estimatedStamina', nil)
        v.Character:SetAttribute('sprinting', nil)
        v.Character:SetAttribute('ILLEGAL_ANIMATION_FLAG', nil)
        v.Character:SetAttribute('FAKE_BLOCK_FLAG', nil)
        v.Character:SetAttribute('FOOTSTEP_FLAGS', nil)
        v.Character:SetAttribute('timestartedsprinting', nil)
        v.Character:SetAttribute('SETTINGS_FLAG', nil)
        v.Character:SetAttribute('INVENTORY_FLAG', nil)
    end
    if not m then
        v:SetAttribute('ILLEGAL_ANIMATION_FLAG', nil)
        v:SetAttribute('FAKE_BLOCK_FLAG', nil)
    end
end
(function()
    if not _G.UNLOCK_ANTICHEAT then return end
    AntisTab:CreateSection('Anticheat')
    AntisTab:CreateLabel('If you lag alot it may falsely accuse players, especially teleportation and stamina mods.')
    local cheaters = {}
    local cheatersnames = {}
    local anticheaterrors = {}
    local numcheaters = 0
    local cheaterslabel = AntisTab:CreateLabel('Cheaters:')
    AntisTab:CreateButton({
        Name = 'Clear list',
        Callback = function()
            for i, _ in pairs(cheatersnames) do
                clearflags(Players[i])
            end
            cheaters, cheatersnames, anticheaterrors, numcheaters = {}, {}, {}, 0
        end,
    })
    AntisTab:CreateToggle({
        Name = 'Detect invisibility',
        CurrentValue = true,
        Flag = 'ANTICHEAT_DETECTINVIS',
        Callback = NULL,
        TextMode = true
    })
    AntisTab:CreateToggle({
        Name = 'Detect teleports',
        CurrentValue = true,
        Flag = 'ANTICHEAT_DETECTTELEPORT',
        Callback = NULL,
        TextMode = true
    })
    AntisTab:CreateToggle({
        Name = 'Detect illegal jumps',
        CurrentValue = true,
        Flag = 'ANTICHEAT_DETECTILLEGALJUMP',
        Callback = NULL,
        TextMode = true
    })
    AntisTab:CreateToggle({
        Name = 'Detect illegal animations',
        CurrentValue = true,
        Flag = 'ANTICHEAT_DETECTANIMATIONS',
        Callback = NULL,
        TextMode = true,
        ToolTip = 'Detects fake block and animation changers'
    })
    AntisTab:CreateToggle({
        Name = 'Detect illegal changes',
        CurrentValue = true,
        Flag = 'ANTICHEAT_DETECTSETTINGS',
        Callback = NULL,
        TextMode = true,
        ToolTip = 'Detects when a player changes their survivor/killer or a setting in-game, which is impossible unless they use a hack to always show their sidebar'
    })
    AntisTab:CreateToggle({
        Name = 'Detect stamina modifications',
        CurrentValue = true,
        Flag = 'ANTICHEAT_DETECTSTAMINA',
        Callback = NULL,
        TextMode = true
    })
    AntisTab:CreateToggle({
        Name = 'Notify me when cheaters are detected',
        CurrentValue = true,
        Flag = 'ANTICHEAT_NOTIFY',
        Callback = NULL,
        TextMode = true
    })
    --[[AntisTab:CreateToggle({
        Name = 'Detect hiddden footsteps',
        CurrentValue = true,
        Flag = 'ANTICHEAT_DETECTFOOTSTEPS',
        Callback = NULL,
        TextMode = true,
        ToolTip = 'Detects players using scripts to hide footstep noises'
    })]]
    local positionstracker = {}
    local anticheat = {
        detections = {
            ['INVIS_CHECK'] = {flag='ANTICHEAT_DETECTINVIS', detect=function(plr)
                local magicpos = GetGameMap():WaitForChild('SpawnPoints', 4):WaitForChild('Survivors', 4):GetChildren()[1].Position.Y
                local IS_DTC = plr.Character.HumanoidRootPart.Position.Y >= (magicpos + 300) or plr.Character.HumanoidRootPart.Position.Y <= (magicpos - 100)
                if IS_DTC and not plr.Character:GetAttribute('INVISDETECTED') then
                    plr.Character:SetAttribute('INVISDETECTED', tick())
                elseif plr.Character:GetAttribute('INVISDETECTED') and IS_DTC and tick() - plr.Character:GetAttribute('INVISDETECTED') >= 2 then
                    warn("[Anticheat]", plr.Name, "is invisible")
                    return true
                elseif not IS_DTC then
                    plr.Character:SetAttribute('INVISDETECTED', nil)
                end
                return false
            end,reason='invisibility'},
            ['TELEPORT'] = {flag='ANTICHEAT_DETECTTELEPORT', detect=function(plr)
                local tracked = positionstracker[plr]
                if not plr.Character:GetAttribute('TELEPORTS') then
                    plr.Character:SetAttribute('TELEPORTS', 0)
                end
                if (tracked.position - plr.Character.HumanoidRootPart.Position).magnitude >= 50 then
                    if plr.Character.Name == '007n7' and tick() - tracked.c00lguiequip <= 2 then
                        warn("[Anticheat] Player teleported legitimately using the c00lgui")
                    elseif plr.Character.Name == 'Azure' and tick() - tracked.azuretransformend <= 2 then
                        warn("[Anticheat] Player teleported legitimately with azure golem")
                    else
                        if GetGameMap():GetAttribute('MapName') == 'ClassicBattlegrounds' and plr.Character.Parent == Killers and (Vector3.new(834, 95, 1498) - plr.Character.HumanoidRootPart.Position).magnitude <= 12 then
                            warn("[Anticheat] Player teleported legitimately through grate on classic battlegrounds")
                        else
                            positionstracker[plr] = {lastupd = tick(), position = plr.Character.HumanoidRootPart.Position, c00lguiequip = tracked.c00lguiequip, azuretransformend = tracked.azuretransformend}
                            plr.Character:SetAttribute('TELEPORTS', plr.Character:GetAttribute('TELEPORTS') + 1)
                        end
                    end
                end
                if plr.Character:GetAttribute('TELEPORTS') > 1 then
                    return true
                end
            end,reason='teleportation'},
            ['JUMP'] = {flag='ANTICHEAT_DETECTILLEGALJUMP', detect=function(plr)
                if plr.Character.Humanoid:GetState() == Enum.HumanoidStateType.Jumping then
                    warn("[Anticheat] Oh how silly can you be", plr.Name, "to do that in forsaken, like that?")
                    return true
                end
            end,reason='illegal jump'},
            ['STAMINA'] = {flag='ANTICHEAT_DETECTSTAMINA', detect=function(plr)
                local IsSprinting = plr.Character:GetAttribute("sprinting")
                local Stamina = plr.Character:GetAttribute("estimatedStamina") and plr.Character:GetAttribute("estimatedStamina") * 1.4
                -- inflate stamina so much that if they are possibly sprinting by the time its estimated 0, they are cheating
                if not Stamina then return end
                if not plr.Character:GetAttribute("STAMINA_FLAGS") then
                    plr.Character:SetAttribute("STAMINA_FLAGS", 0)
                end
                local flaggedbefore = plr.Character:GetAttribute("STAMINA_FLAG_TIME")
                if IsSprinting and Stamina <= 0 then
                    if (flaggedbefore and tick() - flaggedbefore >= 3) or not flaggedbefore then
                        warn("[Anticheat]", plr.Name, "flagged for stamina modifications")
                        plr.Character:SetAttribute("STAMINA_FLAGS", plr.Character:GetAttribute("STAMINA_FLAGS") + 1)
                        plr.Character:SetAttribute("STAMINA_FLAG_TIME", tick())
                    end
                    if not flaggedbefore then
                        plr.Character:SetAttribute("STAMINA_FLAG_TIME", tick())
                    end
                    flaggedbefore = plr.Character:GetAttribute("STAMINA_FLAG_TIME")
                    if tick() - flaggedbefore >= 30 and plr.Character:GetAttribute("STAMINA_FLAGS") > 0 then
                        warn("[Anticheat] Removing stamina flag from", plr.Name, "for being a good boy")
                        plr.Character:SetAttribute("STAMINA_FLAGS", plr.Character:GetAttribute("STAMINA_FLAGS") - 1)
                        plr.Character:SetAttribute("STAMINA_FLAG_TIME", tick())
                    end
                    if plr.Character:GetAttribute("STAMINA_FLAGS") > 4 then
                        return true
                    end
                end
            end,reason='stamina mods'},
            ['ANIMATIONS'] = {flag='ANTICHEAT_DETECTANIMATIONS', detect=function(plr)
                return plr.Character:GetAttribute('ILLEGAL_ANIMATION_FLAG')
            end,reason='illegal animation'},
            ['ANIMATIONS2'] = {flag='ANTICHEAT_DETECTANIMATIONS', detect=function(plr)
                return plr.Character:GetAttribute('FAKE_BLOCK_FLAG')
            end,reason='fake block'},
            ['SETTINGS'] = {flag='ANTICHEAT_DETECTSETTINGS', detect=function(plr)
                return plr.Character:GetAttribute('SETTINGS_FLAG')
            end,reason='changing settings in-game'},
            ['SETTINGS2'] = {flag='ANTICHEAT_DETECTSETTINGS', detect=function(plr)
                return plr.Character:GetAttribute('INVENTORY_FLAG')
            end,reason='changing survivor or killer in-game'},
            --[[['FOOTSTEPS'] = {flag='ANTICHEAT_DETECTFOOTSTEPS', detect=function(plr)
                if plr.Character.Name == 'Nosferatu' then return false end
                local IsSprinting = plr.Character:GetAttribute("sprinting")
                local R = plr.Character.HumanoidRootPart
                local footstepnoise
                if not plr.Character:GetAttribute("FOOTSTEP_FLAGS") then
                    plr.Character:SetAttribute("FOOTSTEP_FLAGS", 0)
                end
                for i, v in ipairs(R:GetChildren()) do
                    if v.Name:find('footstep') and v:IsA('Audio') then
                        footstepnoise = v
                    end
                end
                if IsSprinting and not footstepnoise then
                    local ss = plr.Character:GetAttribute("timestartedsprinting")
                    if ss and tick() - ss >= 3 and (not plr.Character:GetAttribute("LAST_FOOTSTEP_FLAG") or tick() - plr.Character:GetAttribute("LAST_FOOTSTEP_FLAG") <= 1)then
                        warn("[Anticheat]", plr:GetAttribute('Username'), 'is hiding footsteps')
                        plr.Character:SetAttribute("LAST_FOOTSTEP_FLAG", tick())
                        plr.Character:SetAttribute('FOOTSTEP_FLAGS', plr.Character:GetAttribute('FOOTSTEP_FLAGS') + 1)
                    end
                end
                if plr.Character:GetAttribute('FOOTSTEP_FLAGS') > 25 then
                    return true
                end
            end,reason='hidden footsteps'}]]
        },
        flag = function(self,plr,reason)
            if not cheatersnames[plr.Name] then
                cheatersnames[plr.Name] = true
            end
            cheatersnames[plr.Name] = true
            if not cheaters[plr] then
                numcheaters = numcheaters + 1
                cheaters[plr] = {reasons = {}}
            end
            if not table.find(cheaters[plr].reasons, reason) and Catsaken.Flags.ANTICHEAT_NOTIFY.CurrentValue then
                Rayfield:Notify({Title = 'Cheater Detected!', Content = plr.Name .. ' has triggered \"' .. reason .. "\" and has been flagged for cheating.", Duration = 30, Image = 'triangle-alert'})
                table.insert(cheaters[plr].reasons, reason)
            end
        end
    }
    function anticheat:runDetection(plr,name)
        if not (GetGameMap()) then return end
        if not (plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid")) then return end
        if plr.Character.Humanoid.Health <= 0 then return end
        if plr.Character.Parent == workspace.Players.Spectating then
            return clearflags(plr,true)
        end
        local detection = anticheat.detections[name]
        if Catsaken.Flags[detection.flag].CurrentValue and detection.detect(plr) then
            anticheat:flag(plr, detection.reason)
        end
    end
    task.spawn(function()
        while not Unloaded and task.wait() do
            local text = ''
            if numcheaters == 0 then
                cheaterslabel:Set('Cheaters: None')
            else
                for i, v in pairs(cheaters) do
                    text = text .. '\n' .. i.Name .. ' (' .. table.concat(v.reasons, ', ') .. ')'
                end
                cheaterslabel:Set('Cheaters:' .. text) 
            end

            for _, i in pairs(Players:GetPlayers()) do
                pcall(function()
                    if not positionstracker[i] then
                        positionstracker[i] = {lastupd = 0, position = i.Character.HumanoidRootPart.Position, c00lguiequip = 0, azuretransformend = 0}
                    end
                    local tracked = positionstracker[i]
                    if i.Character:FindFirstChild('c00lgui') then
                        tracked.c00lguiequip = tick()
                    end
                    if i.Character.SpeedMultipliers:FindFirstChild('GolemDefaultWalkspeed') then
                        tracked.azuretransformend = tick()
                    end
                    if tick() - tracked.lastupd >= 0.5 then
                        tracked.position = i.Character.HumanoidRootPart.Position
                        tracked.lastupd = tick()
                    end
                end)
                for n, v in pairs(anticheat.detections) do
                    local s,r=pcall(anticheat.runDetection,anticheat,i,n)
                    if not s then
                        if anticheaterrors[r] then
                        else
                            anticheaterrors[r] = true
                            warn("[ANTICHEAT] error occured in anticheat!", tostring(r))
                        end
                    end
                end
            end
        end
    end)
end)()

function HookEffect(Module, Name, Flag)
    local Old
    Old = hookfunction(Module.Applied, newcclosure(function(...)
        if (Catsaken.Flags[Flag].CurrentValue) then
            task.spawn(function()
                setthreadidentity(8)
                Rayfield:Notify({Title = `Anti {Name}`, Content = `Blocked a {Name} effect from happening`, Duration = 6, Image = 'ban'})
            end)
            coroutine.yield()
        else
            return Old(...)
        end
    end))
end

-- anti slowness
HookEffect(Effects_Slowness, 'slowness', 'AntiSlowness')
-- anti subspace
HookEffect(Effects_Subspace, 'subspace', 'AntiSubspace')
-- anti blindness
HookEffect(Effects_Blindness, 'blindness', 'AntiBlindness')
-- anti glitched
HookEffect(Effects_Glitched, 'glitched', 'AntiGlitched')
-- anti glitched
HookEffect(Effects_Slateskin, 'slateskin', 'AntiSlateskin')
-- anti nausea
HookEffect(Effects_Nausea, 'nausea', 'AntiNausea')
-- anti stun
HookEffect(Effects_Stunned, 'stunn', 'AntiStun')
-- anti hallucinate
HookEffect(Effects_Stunned, 'hallucinate', 'AntiHallu')

-- unloader
MiscTab:CreateSection('GUI')

local settingsdetectorconnections = {}

local function trackeverything(v)
    local pd = v:WaitForChild('PlayerData', 15)
    if pd then
        local equipped = pd:WaitForChild('Equipped')
        local settings = pd:WaitForChild('Settings')
        for i, l in pairs(equipped:GetDescendants()) do
            if l:IsA("StringValue") then
                table.insert(settingsdetectorconnections, l:GetPropertyChangedSignal("Value"):Connect(function()
                    print(l, "changed2", v.Character, v.Character.Parent, IsRoundLoaded())
                    if v.Character and (v.Character.Parent == Survivors or v.Character.Parent == Killers) then
                        if Catsaken.Flags.ANTICHEAT_DETECTSETTINGS.CurrentValue and tick() - Forsaken.RoundStart >= 8 and IsRoundLoaded() then
                            warn("ba")
                            if l.Name == 'Killer' or l.Name == 'Survivor' or l.Parent.Name == 'Skins' then
                                warn("bb")
                                v.Character:SetAttribute('INVENTORY_FLAG', true)
                            end
                        end
                    end
                end))
            end
        end
        for i, l in pairs(settings:GetDescendants()) do
            if l.ClassName:find('Value') then
                table.insert(settingsdetectorconnections, l:GetPropertyChangedSignal("Value"):Connect(function()
                    print(l, "changed")
                    if v.Character and (v.Character.Parent == Survivors or v.Character.Parent == Killers) then
                        if Catsaken.Flags.ANTICHEAT_DETECTSETTINGS.CurrentValue and tick() - Forsaken.RoundStart >= 8 and IsRoundLoaded() then
                            v.Character:SetAttribute('SETTINGS_FLAG', true)
                        end
                    end
                end))
            end
        end
    else
        warn("[Anticheat] failed to find playerdata folder")
    end
end

Players.PlayerAdded:Connect(function(v)
    trackeverything(v)
end)

for i, v in pairs(Players:GetPlayers()) do
    trackeverything(v)
end

function Unload()
    Unloaded = true
    warn("Destroying ..!")
    for i, v in pairs(settingsdetectorconnections) do
        pcall(function()
            v:Disconnect()
        end)
    end
    Box:Destroy()
    Rayfield:Destroy()
    _G.globaluilibrary = nil
    Env.executed = false
    for i, v in pairs(Players:GetPlayers()) do
        clearflags(v)
    end
    pcall(function()
        Env.InvisToggleButton:setEnabled(false)
        Env.InvisToggleButton = nil

        Env.BlockButton:setEnabled(false)
        Env.BlockButton = nil

        Env.RagButton:setEnabled(false)
        Env.RagButton = nil

        if Env.MobileToggle then
            Env.MobileToggle:setEnabled(false)
            Env.MobileToggle = nil
        end
    end)
    table.foreach(Hooks, function(_, F)
        pcall(restorefunction, F)
    end)
    table.foreach(Forsaken, function(TableName, Tbl)
        if (tostring(TableName):find('EspAppliedTo')) then
            print('clearing highlights for', TableName)
            for obj, v in pairs(Tbl) do
                if (obj:FindFirstChildOfClass('Highlight')) then
                    warn("destroying highlight because unload")
                    obj:FindFirstChildOfClass('Highlight'):Destroy()
                else
                    warn(".")
                end
            end
        end
    end)
    table.foreach(Catsaken.Flags, function(i)
        Catsaken.Flags[i].CurrentValue = false
        Catsaken.Flags[i].CurrentOption = {}
        Catsaken.Flags[i].Set = NULL
    end)
end
if not ShouldUseOldUI then Rayfield.BlatantModeEnabled:Fire(false) end
MiscTab:CreateButton({
    Name = 'Unload',
    Callback = function()
        Unload()
    end
})

MiscTab:CreateButton({
    Name = 'Reload',
    Callback = function()
        Unload()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/aibabylaugh/catsaken-real-script-not-assets/refs/heads/main/obfuscated-1448974601077002340.lua'))()
    end
})

MiscTab:CreateButton({
    Name = (ShouldUseOldUI and 'Disable' or '') .. ' Old GUI',
    Callback = function()
        Unload()
        if ShouldUseOldUI then
            delfile("BOOL_CATSAKEN_OLDUI")
        else
            writefile("BOOL_CATSAKEN_OLDUI", "")
        end
        task.wait(1)
        loadstring(game:HttpGet('https://raw.githubusercontent.com/aibabylaugh/catsaken-real-script-not-assets/refs/heads/main/obfuscated-1448974601077002340.lua'))()
    end
})

if not ShouldUseOldUI then
    MiscTab:CreateButton({
        Name = 'Clear all notifications',
        Callback = function()
            Rayfield:DeleteNotifications()
        end,
        ToolTip = 'Press this is the notifications are bugged and wont dissapear'
    })
end

if not ShouldUseOldUI then
    MiscTab:CreateToggle({
        Name = 'Mobile toggle',
        CurrentValue = true,
        Flag = 'MobileMenuToggle',
        Callback = function(Callback)
            Env.MobileToggle:setEnabled(Callback)
        end
    })
end

MiscTab:CreateToggle({
    Name = 'Disable update notifications',
    CurrentValue = false,
    Flag = 'DisableGitHubNotifications',
    Callback = NULL
})

function fullbrightthedamnmap()
    Lighting.Brightness = 2
	Lighting.ClockTime = 14
	Lighting.FogEnd = 100000
	Lighting.GlobalShadows = false
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    pcall(function()
        Lighting:FindFirstChildOfClass('Atmosphere'):Destroy()
    end)
end

MiscTab:CreateToggle({
    Name = 'Fullbright',
    CurrentValue = false,
    Flag = 'Fullbright',
    Callback = function(Callback)
        task.spawn(function()
            if Callback then
                while Catsaken.Flags.Fullbright.CurrentValue do
                    fullbrightthedamnmap()
                    task.wait()
                end
            end
        end)
    end
})

local oldnotif
if not ShouldUseOldUI then
    MiscTab:CreateDropdown({
        Name = 'Notifications position',
        Options = {'Bottom', 'Top'},
        CurrentOption = {'Bottom'},
        Flag = 'NotificationLayout',
        Callback = function(Options,is)
            pcall(function()
                oldnotif.Close()
            end)
            Rayfield:ChangeNotificationLayout(Options[1])
            if not is then
                oldnotif = Rayfield:Notify({Title = 'Example', Content = 'Changed the notification position to ' .. Options[1], Duration = 6, Image = 'info'})
            end
        end
    })
end

if not ShouldUseOldUI then
    local blatanttext = MiscTab:CreateLabel('Blatant mode is not enabled, risky features are locked')
    MiscTab:CreateToggle({
        Name = 'Blatant Mode',
        CurrentValue = false,
        Callback = function(C)
            if not C then
                blatanttext:Set('Blatant mode is not enabled, risky features are locked')
            else
                blatanttext:Set('Blatant mode is enabled, and you get access to features that are highly risky and from experience are leading causes of BANS. as a reminder, forsaken anticheat can NOT ban you, so if you enable these blatant features and you get reported, you are going to get banned guaranteed!!')
            end
            Rayfield.BlatantModeEnabled:Fire(C)
        end,
        Flag = 'BlatantModeEnabled'
    })
end

--[[MiscTab:CreateButton({
    Name = (Env.DarkMode and 'Disable' or 'Enable') .. ' dark mode GUI',
    Callback = function()
        Unload()
        Env.DarkMode = not Env.DarkMode
        if Env.DarkMode then
            writefile("Catsaken/DarkMode", "")
        else
            delfile("Catsaken/DarkMode")
        end
        loadstring(game:HttpGet('https://raw.githubusercontent.com/aibabylaugh/catsaken-real-script-not-assets/refs/heads/main/obfuscated-1448974601077002340.lua'))()
    end
})]]

-- fake block yayaya
MiscTab:CreateSection('Fake block')

local TheAnimReal = nil
setthreadidentity(8)
function FakeBlockCallback()
    local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Humanoid')
    if (not Humanoid) then return end
    local Anim = Instance.new("Animation")
    Anim.AnimationId = TheAnimReal
    local Track = Humanoid:LoadAnimation(Anim)
    Track:Play()
end
if (identifyexecutor() ~= "Cosmic") then
    local BlockButton = TopbarPlus.new():setImage(tonumber('94723083650256')):setCaption('Fake block'):oneClick():bindEvent('deselected', FakeBlockCallback):setEnabled(false)
    Env.BlockButton = BlockButton
    setthreadidentity(8)
    BlockAnims = {
        Normal = require(MainSurvivorsPath.Guest1337.Config).Animations.Block,
    }
    TheAnimReal = BlockAnims.Normal
    local Options = {'Normal'}
    for i, v in ReplicatedStorage.Assets.Skins.Survivors.Guest1337:GetChildren() do
        if (v:FindFirstChild("Config") and (require(v.Config).Animations or {}).Block ~= nil) then
            local M = require(v.Config)
            local DN = M.DisplayName
            table.insert(Options, DN)
            BlockAnims[DN] = M.Animations.Block
            task.spawn(function()
                ContentProvider:PreloadAsync({M.Animations.Block})
            end)
        end
    end
    MiscTab:CreateToggle({
        Name = 'Fake block (animation)',
        CurrentValue = false,
        Flag = 'FakeBlockUIToggle',
        Callback = function(Callback)
            BlockButton:setEnabled(Callback)
        end
    })

    if (not IsMobile) then
        MiscTab:CreateKeybind({
            Name = 'Keybind',
            CurrentKeybind = 'B',
            HoldToInteract = false,
            CallOnChange = false,
            Callback = function()
                FakeBlockCallback()
            end
        })
    end

    MiscTab:CreateDropdown({
        Name = 'Block animation',
        Options = Options,
        CurrentOption = {'Normal'},
        Flag = 'FakeBlockAnimation',
        Callback = function(Options)
            TheAnimReal = BlockAnims[Options[1]]
        end
    })

    MiscTab:CreateToggle({
        Name = 'Change block animation',
        CurrentValue = false,
        Flag = 'BlockAnimationChanger',
        Callback = NULL
    })
else
    MiscTab:CreateLabel("Fake Block not supported on cosmic")
end

local TrackingConnection
function Track(Char)
    local Root = Char and Char:WaitForChild('HumanoidRootPart', 7)
    if (not Root) then return end
    local Hum = Root and Char:WaitForChild("Humanoid", 7)
    if (not Hum) then return end
    local Animator = Hum:WaitForChild('Animator', 5)
    if (not Animator) then return end
    local function MakeConnection()
        return Animator.AnimationPlayed:Connect(function(track)
            if (not TableFindThatWorks(BlockAnims, track.Animation.AnimationId)) then return end
            if (not Catsaken.Flags.BlockAnimationChanger.CurrentValue) then return end
            track:Stop()
            local NewAnim = Instance.new("Animation")
            NewAnim.AnimationId = TheAnimReal
            local Track = Hum:LoadAnimation(NewAnim)
            TrackingConnection:Disconnect() -- prevents crashing since it would be an infinite loop
            Track:Play()
            TrackingConnection = MakeConnection()
        end)
    end
    TrackingConnection = MakeConnection()
end
Survivors.ChildAdded:Connect(function(Char)
    repeat wait() until (not Char) or Char:GetAttribute('Username') or (not Char.Parent)
    if (Char:GetAttribute('Username') == LocalPlayer.Name) then
        Track(Char)
    end
end)
if (LocalPlayer.Character) then
    Track(LocalPlayer.Character)
end

-- fake die / ragdoll yayayaya
MiscTab:CreateSection('Fake die')

setthreadidentity(8)
local IsRagdolled = false
function RagdollEnable()
    IsRagdolled = true
    local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Humanoid')
    if (not Humanoid) then return end
    Humanoid.PlatformStand = true
    Ragdolls.EnableRagdoll(LocalPlayer.Character)
end

function RagdollDisable()
    IsRagdolled = false
    local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Humanoid')
    if (not Humanoid) then return end
    Humanoid.PlatformStand = false
    Ragdolls.DisableRagdoll(LocalPlayer.Character)
end

if (identifyexecutor() ~= "Cosmic") then
    local RagButton = TopbarPlus.new():setImage(tonumber('96754119500574')):setCaption('Fake die / Ragdoll'):bindEvent('selected',RagdollEnable):bindEvent('deselected', RagdollDisable):autoDeselect(false):setEnabled(false)
    Env.RagButton = RagButton
    setthreadidentity(8)
    MiscTab:CreateToggle({
        Name = 'Ragdoll button (NOT FE)',
        CurrentValue = false,
        Flag = 'RagdollButtonToggle',
        Callback = function(Callback)
            RagButton:setEnabled(Callback)
        end
    })

    if (not IsMobile) then
        MiscTab:CreateKeybind({
            Name = 'Keybind',
            CurrentKeybind = 'Z',
            HoldToInteract = false,
            CallOnChange = false,
            Callback = function()
                if (not IsRagdolled) then
                    RagButton:select()
                    setthreadidentity(8)
                    RagdollEnable()
                else
                    RagButton:deselect()
                    setthreadidentity(8)
                    RagdollDisable()
                end
            end
        })
    end
else
    MiscTab:CreateLabel("Ragdoll not supported on cosmic")
end

-- Load saved settings
if ShouldUseOldUI then
    Rayfield:LoadConfiguration()
end

-- Debug rejoin
local uis = game:GetService('UserInputService')
uis.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    if input.KeyCode == Enum.KeyCode.Backspace then
        if uis:IsKeyDown(Enum.KeyCode.Delete) and uis:IsKeyDown(Enum.KeyCode.KeypadMultiply) then
            game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer, game:GetService("TeleportService"):GetLocalPlayerTeleportData())
        end
    end
end)

-- Music
MiscTab:CreateSection('Music (If nothing is below then assets are still downloading)')

task.spawn(function()
    if ShouldUseOldUI then
        Rayfield:LoadConfiguration()
        while not Unloaded do
            local Old = HttpService:JSONEncode(Catsaken.Flags)
            task.wait(1)
            if Unloaded then return end
            local New = HttpService:JSONEncode(Catsaken.Flags)
            if New ~= Old then
                warn("AutoSaving ...")
                writefile(SaveFileName, New)
            end
        end
    end
end)

task.spawn(function()
    while MobileToggle and not Unloaded do
        _G.globaluilibrary.Enabled = READYTOSHOWUI and MobileToggle.isSelected
        RunService.RenderStepped:Wait()
    end
end)

task.spawn(function()
    local main = "https://raw.githubusercontent.com/jeevacation780/repository-for-kings/refs/heads/main/cat.lua"
    local current = game:HttpGet(main)
    while not Unloaded do
        task.wait(10)
        local new = game:HttpGet(main)
        if current ~= new and not Catsaken.Flags.DisableGitHubNotifications.CurrentValue then
            current = new
            Rayfield:Notify({Title = 'GitHub', Content = 'A new change was detected on the github for catsaken. This could be a new feature or just a bug fix. Reload now or later.', Duration = 15, Image = 'scroll'})
        end
    end
end)

function cfgmanager()
    if not isfile("catsakenautoload.txt") then
        writefile("catsakenautoload.txt", SaveFileName)
    end
    local configs
    local function refreshcfgs()
        configs = HttpService:JSONDecode(readfile("catsakenconfigs.json"))
    end
    refreshcfgs()
    ConfigsTab:CreateSection('Configurations')
    local current = readfile("catsakenautoload.txt")
    local cfgname = "NewConfig"
    local cfgdropdown = ConfigsTab:CreateDropdown({
        Name = 'Selected Config',
        Options = (function()
            local names = {}
            for i, v in pairs(configs) do
                names[#names+1] = i
            end
            return names
        end)(),
        CurrentOption = {current},
        Flag = 'currentcfgselect',
        Callback = function(Options)
            current = Options[1]
        end
    })

    ConfigsTab:CreateButton({
        Name = 'Overwrite Selected',
        Callback = function()
            --if current == ("catsaken-default-"..LocalPlayer.Name..".json") then
            --    return Rayfield:Notify({Title = 'Error', Content = 'You cannot overwrite the default config for an account.', Duration = 15, Image = 'scroll'})
            --end
            Catsaken.Flags.currentcfgname = {CurrentValue = ""}
            Catsaken.Flags.currentcfgselect = {CurrentOption = {current}}
            local newconfigs = deepcopy(HttpService:JSONDecode(readfile('catsakenconfigs.json')))
            newconfigs[current] = deepcopy(Catsaken.Flags)
            writefile("catsakenconfigs.json", HttpService:JSONEncode(newconfigs))
            Rayfield:Notify({Title = 'Done', Content = 'Config saved.', Duration = 15, Image = 'scroll'})
        end
    })

    ConfigsTab:CreateInput({
        Name = "Config Name",
        CurrentValue = cfgname,
        PlaceholderText = "Text",
        RemoveTextAfterFocusLost = false,
        Flag = "currentcfgname",
        Callback = function(Text)
            cfgname = Text .. '.json'
        end
    })

    ConfigsTab:CreateButton({
        Name = 'Save Config',
        Callback = function()
            local newconfigs = deepcopy(HttpService:JSONDecode(readfile('catsakenconfigs.json')))
            if newconfigs[cfgname] then
                return Rayfield:Notify({Title = 'Fail', Content = 'Config already exists. Refresh list, then overwrite it.', Duration = 15, Image = 'scroll'})
            end
            Catsaken.Flags.currentcfgname = {CurrentValue = ""}
            Catsaken.Flags.currentcfgselect = {CurrentOption = {cfgname}}
            newconfigs[cfgname] = deepcopy(Catsaken.Flags)
            writefile("catsakenconfigs.json", HttpService:JSONEncode(newconfigs))
            Rayfield:Notify({Title = 'Done', Content = 'Config saved.', Duration = 15, Image = 'scroll'})
        end
    })

    ConfigsTab:CreateButton({
        Name = 'Delete Selected',
        Callback = function()
            if current == ("catsaken-default-"..LocalPlayer.Name..".json") then
                return Rayfield:Notify({Title = 'Error', Content = 'You cannot delete the default config for an account.', Duration = 15, Image = 'scroll'})
            end
            local newconfigs = deepcopy(HttpService:JSONDecode(readfile('catsakenconfigs.json')))
            newconfigs[current] = nil
            writefile("catsakenconfigs.json", HttpService:JSONEncode(newconfigs))
            Rayfield:Notify({Title = 'Done', Content = 'Config deleted.', Duration = 15, Image = 'scroll'})
        end
    })

    ConfigsTab:CreateButton({
        Name = 'Load Selected',
        Callback = function()
            writefile("catsakenautoload.txt", current)
            Unload()
            loadstring(game:HttpGet('https://raw.githubusercontent.com/aibabylaugh/catsaken-real-script-not-assets/refs/heads/main/obfuscated-1448974601077002340.lua'))()
        end
    })

    ConfigsTab:CreateButton({
        Name = 'Refresh List',
        Callback = function()
            refreshcfgs()
            cfgdropdown.Refresh((function()
                local names = {}
                for i, v in pairs(configs) do
                    names[#names+1] = i
                end
                return names
            end)())
        end
    })

    if identifyexecutor() == 'Delta' then
        ConfigsTab:CreateButton({
            Name = 'Share Current Settings ⭐',
            Callback = function()
                Env.MobileToggle:deselect()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/jeevacation780/repository-for-kings/refs/heads/main/config.lua"))()
            end
        })

        ConfigsTab:CreateButton({
            Name = 'Search For Configs ⭐',
            Callback = function()
                Env.MobileToggle:deselect()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/jeevacation780/repository-for-kings/refs/heads/main/search.lua"))()
            end
        })
    end

    ConfigsTab:CreateLabel("To put Auto-Load on a configuration, simply select that configuration and load it, and then it will become your Auto-Load.")
end

if ShouldUseOldUI then
    ConfigsTab:CreateLabel('You cannot create multiple configs on rayfield.')
else
    cfgmanager()
    print('[Catsaken] config manager initialized')
end

local Old
Old = hookmetamethod(game, '__namecall', function(self, ...)
    if (Unloaded) then return Old(self, ...) end
    local Args = {...}
    if typeof(self) == 'Instance' and tostring(self) == 'RemoteEvent' then
        local Argument = ({...})[2]
        if type(Argument) == 'table' and typeof(Argument[1]) == 'buffer' then
            if buffer.tostring(Argument[1]):find('PlasmaBeam') then
                WaitAndReset('DusekkarActive')
            elseif buffer.tostring(Argument[1]):find('Nova') then
                WaitAndReset('NoliActive')
            elseif buffer.tostring(Argument[1]):find('CorruptNature') then
                WaitAndReset('CoolkidActive')
            end
        end
        return Old(self, unpack(Args))
    end
    if (Catsaken.Flags.DemonicPursuitAntiCrash.CurrentValue and Args[1] == (LocalPlayer.Name .. '666Crashed') and Forsaken.PursuitTracker) then
        repeat wait() until (tick() - Forsaken.PursuitTracker >= SixerConfig.PursuitLength)
        return Old(self, unpack(Args))
    end
    if (Catsaken.Flags.VoidRushAntiCrash.CurrentValue and Args[1] == (LocalPlayer.Name .. 'VoidRushCollision') and Forsaken.VoidRushTracker) then
        repeat wait() until (tick() - Forsaken.VoidRushTracker >= NoliConfig.VoidRushDashLength)
        return Old(self, unpack(Args))
    end
    if (Catsaken.Flags.NoSprintTween.CurrentValue and not checkcaller() and self == TweenService and getnamecallmethod() == 'Create' and Args[1] == SprintModule.__speedMultiplier) then
        Args[2] = TweenInfo.new(0)
    end
    return Old(self, unpack(Args))
end)
print("[metahooks] __namecall hook initialized")

LOADSTEP2 = true

local NoDownload = false
local Files = {
    Names = {"Custom"},
    Data = {}
}
if not NoDownload then
    local Req = HttpService:JSONDecode(game:HttpGet('https://api.github.com/repos/aibabylaugh/catsaken/contents/lms'))
    for i, v in Req do
        pcall(function()
            local Name = v.name:sub(1, -5)
            local Data
            if (isfile(`Catsaken/{Name}`)) then
                --warn("using saved")
                Data = readfile(`Catsaken/{Name}`)
            else
                --warn("requesting")
                Data = game:HttpGet(v.download_url)
            end
            if not Data then return end
            wait()
            Files.Data[Name] = Data
            table.insert(Files.Names, Name)
        end)
    end
end

local SelectedLMS = isfile("Catsaken/Selectedlms") and readfile("Catsaken/Selectedlms") or "None"
function Changelms()
    if (SelectedLMS == 'None') then return end
    local Sound = workspace.Themes:WaitForChild('LastSurvivor', 5)
    if (not Sound) then return end
    local Id = Catsaken.Flags.CustomLMSID.CurrentValue
    local File = Catsaken.Flags.CustomLMSFile.CurrentValue
    local Custom
    if Id ~= "" and tonumber(Id) then
        Custom = "rbxassetid://" .. Id
    else
        if File ~= "" or SelectedLMS == "Custom" then
            Custom = getcustomasset(File)
        else
            Custom = getcustomasset(`Catsaken/{SelectedLMS}`)
        end
    end
    Sound.SoundId = Custom
end

MiscTab:CreateDropdown({
    Name = 'LMS theme',
    Options = Files.Names,
    CurrentOption = {SelectedLMS},
    Flag = 'LMSSelectedTheme',
    Callback = function(Options)
        repeat task.wait() until Catsaken.Flags.LastManStandingChanger ~= nil
        local Name = Options[1]
        writefile("Catsaken/Selectedlms", Name)
        SelectedLMS = Name
        if (Name == 'Custom') then return end
        local Data = Files.Data[Name]
        if (Data and not isfile(`Catsaken/{Name}`)) then
            warn("writing lms")
            writefile(`Catsaken/{Name}`, Data)
        end
        if (Catsaken.Flags.LastManStandingChanger.CurrentValue) then
            Changelms()
        end
    end
})

MiscTab:CreateInput({
   Name = "Custom LMS ID",
   CurrentValue = isfile("Catsaken/CustomLMSID") and readfile("Catsaken/CustomLMSID") or "",
   PlaceholderText = "Leave empty for none",
   RemoveTextAfterFocusLost = false,
   Flag = "CustomLMSID",
   Callback = function(Text)
        writefile("Catsaken/CustomLMSID", Text)
   end
})

MiscTab:CreateInput({
   Name = "Custom LMS File",
   CurrentValue = isfile("Catsaken/CustomLMSFile") and readfile("Catsaken/CustomLMSFile") or "",
   PlaceholderText = "Leave empty for none",
   RemoveTextAfterFocusLost = false,
   Flag = "CustomLMSFile",
   Callback = function(text)
        writefile("Catsaken/CustomLMSFile", text)
        if (text == '') then return end
        if (not isfile(text)) then
            Rayfield:Notify({Title = 'Incorrect file', Content = '"' .. text .. '" is not an existing file', Duration = 8, Image = 'ban'})
        else
            Rayfield:Notify({Title = 'Found file', Content = 'File located in workspace. Please make sure to change the selected lms theme to Custom', Duration = 8, Image = 'check'})
        end
   end
})

MiscTab:CreateToggle({
    Name = 'Change LMS',
    CurrentValue = isfile("Catsaken/LmsChangerEnabled"),
    Flag = 'LastManStandingChanger',
    Callback = function(Callback)
        if (Callback) then
            task.spawn(function()
                writefile("Catsaken/LmsChangerEnabled", "")
            end)
            Changelms()
        else
            task.spawn(function()
                delfile("Catsaken/LmsChangerEnabled")
            end)
        end
    end
})

workspace.Themes.ChildAdded:Connect(function(Sound)
    if (Sound.Name == 'LastSurvivor' and Catsaken.Flags.LastManStandingChanger.CurrentValue) then
        Changelms()
    end
end)
