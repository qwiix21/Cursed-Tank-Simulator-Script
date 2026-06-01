print("two")
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local ToggleKey = Enum.KeyCode.F
local FlyKey = Enum.KeyCode.M

local VehicleScanInterval = 0.5
local CleanupInterval = 2
local HullColor = Color3.new(0.8, 0.2, 0.9)
local TurretColor = Color3.new(0.2, 0.9, 0.4)
local FillTransparency = 0.5
local OutlineTransparency = 0.2
local ShowDistance = false
local MarkDistance = 1000
local MarkDecalID = "11552476728"
local MarkOffsetY = 50
local MarkSize = 25
local MarkUpdateInterval = 0.016
local TimeSinceLastMarkUpdate = 0

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "PerfData"
ESPFolder.Parent = CoreGui

local MarkScreenGui = Instance.new("ScreenGui")
MarkScreenGui.Name = "MarkDisplay"
MarkScreenGui.ResetOnSpawn = false
MarkScreenGui.Parent = CoreGui

local ESPEnabled = true
local TeamCheckEnabled = false
local EnableMark = false
local EnableFill = true
local EnableOutline = true
local RemoveFogEnabled = false
local TimeSinceLastVehicleScan = 0
local TimeSinceLastCleanup = 0
local ESPInstances = {}
local Camera = Workspace.CurrentCamera

local function parseKeyCode(str)
    if not str or str == "" then return nil end
    local name = str:match("KeyCode%.(.+)") or str
    for _, item in ipairs(Enum.KeyCode:GetEnumItems()) do
        if item.Name == name then return item end
    end
    return nil
end

local isRebinding = false
local lastRebindTime = 0


local flying   = false
local flySpeed = 70
local flyRoot  = nil

local bv = Instance.new("BodyVelocity")
bv.Name = "TankFlyVelocity"
bv.MaxForce = Vector3.new(500000, 500000, 500000)

local bg = Instance.new("BodyGyro")
bg.Name = "TankFlyGyro"
bg.MaxTorque = Vector3.new(500000, 500000, 500000)
bg.D = 120

local function findFlyPart(model)
    local candidates = {}
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") and not part:IsA("VehicleSeat") then
            table.insert(candidates, part)
        end
    end
    for _, part in ipairs(candidates) do
        if part.Name:lower():find("hull") then return part end
    end
    if #candidates > 0 then
        table.sort(candidates, function(a, b)
            return (a.Size.X*a.Size.Y*a.Size.Z) > (b.Size.X*b.Size.Y*b.Size.Z)
        end)
        return candidates[1]
    end
    return nil
end

local function initFlyRoot()
    local vehicles = workspace:FindFirstChild("Vehicles")
    if not vehicles then return end
    local tankModel = vehicles:FindFirstChild("Chassis" .. LocalPlayer.Name)
    if not tankModel then return end
    flyRoot = findFlyPart(tankModel)
end

local function startFly()
    if flying then return end
    initFlyRoot()
    flying = true
    if flyRoot then
        bv.Parent = flyRoot
        bg.Parent = flyRoot
    end
end

local function stopFly()
    if not flying then return end
    flying = false
    bv.Parent = nil
    bg.Parent = nil
end


local function UpdateESPInstance(espData)
    if not espData.Instance then return end
    
    local showFill = (EnableFill == true)
    local showOutline = (EnableOutline == true)
    local showESP = (ESPEnabled == true)
    
    espData.Instance.FillColor = showFill and espData.Color or Color3.new(0,0,0)
    espData.Instance.FillTransparency = showFill and FillTransparency or 1
    espData.Instance.OutlineColor = showOutline and espData.Color or Color3.new(0,0,0)
    espData.Instance.OutlineTransparency= showOutline and OutlineTransparency or 1
    espData.Instance.Enabled = showESP

    if espData.DistanceBillboard then
        espData.DistanceBillboard.Enabled = showESP and (ShowDistance == true) and (espData.IsHull == true)
    end
end

local function UpdateAllESPInstances()
    for _, espData in pairs(ESPInstances) do
        UpdateESPInstance(espData)
    end
end

local function ClearAllESP()
    for obj, espData in pairs(ESPInstances) do
        if espData.Instance then espData.Instance:Destroy() end
        if espData.DistanceBillboard then espData.DistanceBillboard:Destroy() end
        if espData.MarkBillboard then espData.MarkBillboard:Destroy() end
    end
    ESPInstances = {}
end

local function ScanVehicles()
    local vehiclesFolder = workspace:FindFirstChild("Vehicles")
    if not vehiclesFolder then return end
    for _, chassis in ipairs(vehiclesFolder:GetChildren()) do
        ProcessChassis(chassis)
    end
end


local Window = Rayfield:CreateWindow({
    Name = "C.T.S",
    LoadingTitle = "Cursed Tank Simulator",
    LoadingSubtitle = "by Qwiix21",
    ConfigurationSaving = { Enabled = true, FolderName = "CTS", FileName = "config" },
    Discord = { Enabled = false },
    KeySystem = false,
})

Rayfield:Notify({
    Title = "C.T.S Loaded",
    Content = "Press K to hide interface during gameplay",
    Duration = 5,
    Image = 4483362458,
})

local MainTab = Window:CreateTab("Main", 4483362458)
local VisualTab = Window:CreateTab("Visual", 4483362458)
local WeaponTab = Window:CreateTab("Weapon", 4483362458)
local FlyTab = Window:CreateTab("Fly", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)


MainTab:CreateSection("Control")
MainTab:CreateLabel("Press K to hide/show interface")

MainTab:CreateToggle({
    Name = "Enable ESP", CurrentValue = true, Flag = "ESPToggle",
    Callback = function(Value)
        ESPEnabled = Value
        UpdateAllESPInstances()
    end,
})

MainTab:CreateToggle({
    Name = "Team Check (enemies only)", CurrentValue = false, Flag = "TeamCheckFlag",
    Callback = function(Value)
        TeamCheckEnabled = Value
        task.defer(function()
            ClearAllESP()
            ScanVehicles()
        end)
    end,
})

MainTab:CreateToggle({
    Name = "Show Distance", CurrentValue = false, Flag = "ShowDistanceFlag",
    Callback = function(Value)
        ShowDistance = Value
        UpdateAllESPInstances()
    end,
})

MainTab:CreateSection("Mark Settings")

MainTab:CreateToggle({
    Name = "Enable Mark", CurrentValue = false, Flag = "EnableMarkFlag",
    Callback = function(Value)
        EnableMark = Value
        for _, espData in pairs(ESPInstances) do
            if espData.MarkBillboard and espData.IsHull then
                espData.MarkBillboard.Visible = false
                espData.MarkBillboard.Position = UDim2.new(0, 0, 0, 0)
            end
        end
    end,
})

MainTab:CreateLabel("Distance to show mark")
MainTab:CreateSlider({
    Name = "Mark Distance", Range = {0,5000}, Increment = 50,
    Suffix = " studs", CurrentValue = 1000, Flag = "MarkDistanceFlag",
    Callback = function(Value) MarkDistance = Value end,
})

MainTab:CreateLabel("Mark appearance")
MainTab:CreateInput({
    Name = "Mark Decal ID", PlaceholderText = "11552476728",
    RemoveTextAfterFocusLost = false, CurrentValue = "11552476728", Flag = "MarkDecalIDFlag",
    Callback = function(Value)
        local id = tonumber(Value)
        if id and id > 0 then
            MarkDecalID = tostring(id)
            local textureId = "rbxassetid://" .. MarkDecalID
            for _, espData in pairs(ESPInstances) do
                if espData.MarkBillboard then
                    local img = espData.MarkBillboard:FindFirstChild("MarkImage")
                    if img then img.Image = textureId end
                end
            end
            Rayfield:Notify({ Title = "Mark Updated", Content = "Decal ID: "..MarkDecalID, Duration = 2, Image = 4483362458 })
        else
            Rayfield:Notify({ Title = "Invalid ID", Content = "Please enter a valid number", Duration = 3, Image = 4483362458 })
        end
    end,
})

MainTab:CreateSlider({
    Name = "Mark Offset Y", Range = {0,200}, Increment = 5,
    Suffix = " px", CurrentValue = 50, Flag = "MarkOffsetYFlag",
    Callback = function(Value) MarkOffsetY = Value end,
})

MainTab:CreateSlider({
    Name = "Mark Size", Range = {5,50}, Increment = 5,
    Suffix = " px", CurrentValue = 25, Flag = "MarkSizeFlag",
    Callback = function(Value)
        MarkSize = Value
        for _, espData in pairs(ESPInstances) do
            if espData.MarkBillboard then
                espData.MarkBillboard.Size = UDim2.new(0, Value, 0, Value)
            end
        end
    end,
})


VisualTab:CreateSection("Fog")

VisualTab:CreateToggle({
    Name = "Remove Fog", CurrentValue = false, Flag = "RemoveFogFlag",
    Callback = function(Value)
        RemoveFogEnabled = Value
        for _, child in ipairs(Lighting:GetChildren()) do
            if child:IsA("Atmosphere") then
                if Value then
                    child.Density = 0
                    child.Haze = 0
                end
            end
        end
    end,
})

VisualTab:CreateSection("Colors")

VisualTab:CreateColorPicker({
    Name = "Hull Color", Color = Color3.new(0.8, 0.2, 0.9), Flag = "HullColorFlag",
    Callback = function(Value) HullColor = Value end,
})

VisualTab:CreateColorPicker({
    Name = "Turret Color", Color = Color3.new(0.2, 0.9, 0.4), Flag = "TurretColorFlag",
    Callback = function(Value) TurretColor = Value end,
})

VisualTab:CreateSection("Highlight Settings")

VisualTab:CreateSlider({
    Name = "Fill Transparency", Range = {0,1}, Increment = 0.01,
    CurrentValue = 0.5, Flag = "FillTransparencyFlag",
    Callback = function(Value)
        FillTransparency = Value
        UpdateAllESPInstances()
    end,
})

VisualTab:CreateSlider({
    Name = "Outline Transparency", Range = {0,1}, Increment = 0.01,
    CurrentValue = 0.2, Flag = "OutlineTransparencyFlag",
    Callback = function(Value)
        OutlineTransparency = Value
        UpdateAllESPInstances()
    end,
})

VisualTab:CreateToggle({
    Name = "Enable Fill", CurrentValue = true, Flag = "EnableFillFlag",
    Callback = function(Value)
        EnableFill = Value
        UpdateAllESPInstances()
    end,
})

VisualTab:CreateToggle({
    Name = "Enable Outline", CurrentValue = true, Flag = "EnableOutlineFlag",
    Callback = function(Value)
        EnableOutline = Value
        UpdateAllESPInstances()
    end,
})


FlyTab:CreateSection("Flight Control")
FlyTab:CreateLabel("W/A/S/D — move  |  Space — up  |  LCtrl — down")

FlyTab:CreateButton({
    Name = "Toggle Fly",
    Callback = function()
        if flying then
            stopFly()
            Rayfield:Notify({ Title = "Fly", Content = "Flight disabled", Duration = 2, Image = 4483362458 })
        else
            startFly()
            Rayfield:Notify({ Title = "Fly", Content = "Flight enabled", Duration = 2, Image = 4483362458 })
        end
    end,
})

FlyTab:CreateSlider({
    Name = "Fly Speed", Range = {10,300}, Increment = 10,
    Suffix = " studs/s", CurrentValue = 70, Flag = "FlySpeedFlag",
    Callback = function(Value) flySpeed = Value end,
})

FlyTab:CreateSection("Keybind")

FlyTab:CreateKeybind({
    Name = "Toggle Fly Key", CurrentKeybind = "M", HoldToInteract = false, Flag = "FlyKeyFlag",
    Callback = function(Value)
        isRebinding = true
        lastRebindTime = tick()
        local key = parseKeyCode(Value)
        if key then FlyKey = key end
        task.delay(0.5, function() isRebinding = false end)
    end,
})


SettingsTab:CreateSection("Performance")

SettingsTab:CreateSlider({
    Name = "Mark Update Rate", Range = {0.016,0.1}, Increment = 0.016,
    Suffix = "s", CurrentValue = 0.016, Flag = "MarkUpdateIntervalFlag",
    Callback = function(Value) MarkUpdateInterval = Value end,
})

SettingsTab:CreateSlider({
    Name = "Scan Interval", Range = {0.1,2.0}, Increment = 0.1,
    Suffix = "s", CurrentValue = 0.5, Flag = "ScanIntervalFlag",
    Callback = function(Value) VehicleScanInterval = Value end,
})

SettingsTab:CreateSection("Controls")

SettingsTab:CreateKeybind({
    Name = "Toggle ESP Key", CurrentKeybind = "F", HoldToInteract = false, Flag = "ToggleKeyFlag",
    Callback = function(Value)
        isRebinding = true
        lastRebindTime = tick()
        local key = parseKeyCode(Value)
        if key then ToggleKey = key end
        task.delay(0.5, function() isRebinding = false end)
    end,
})

SettingsTab:CreateSection("Project")

SettingsTab:CreateButton({
    Name = "Copy GitHub Link",
    Callback = function()
        setclipboard("https://github.com/qwiix21/Cursed-Tank-Simulator-Script")
        Rayfield:Notify({ Title = "Repository Link", Content = "Link copied to clipboard!", Duration = 3, Image = 4483362458 })
    end,
})

Rayfield:LoadConfiguration()

do
    local tf = Rayfield.Flags and Rayfield.Flags["ToggleKeyFlag"]
    if tf and tf.CurrentKeybind then
        local k = parseKeyCode(tf.CurrentKeybind)
        if k then ToggleKey = k end
    end
    local ff = Rayfield.Flags and Rayfield.Flags["FlyKeyFlag"]
    if ff and ff.CurrentKeybind then
        local k = parseKeyCode(ff.CurrentKeybind)
        if k then FlyKey = k end
    end
end


local function GetModelPosition(model)
    if model:IsA("BasePart") then
        return model.Position
    end
    if model.PrimaryPart then
        return model.PrimaryPart.Position
    end
    local cf, size = model:GetBoundingBox()
    return cf.Position
end

local function CreateESP(targetObject, color, isHull)
    if ESPInstances[targetObject] then return ESPInstances[targetObject] end
    
    local highlight = Instance.new("Highlight")
    highlight.FillColor = EnableFill and color or Color3.new(0,0,0)
    highlight.FillTransparency = EnableFill and FillTransparency or 1
    highlight.OutlineColor = EnableOutline and color or Color3.new(0,0,0)
    highlight.OutlineTransparency = EnableOutline and OutlineTransparency or 1
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = targetObject
    highlight.Parent = ESPFolder
    
    local distanceBillboard, distanceLabel, markBillboard, turretAdornee
    
    if isHull then
        distanceBillboard = Instance.new("BillboardGui")
        distanceBillboard.Name = "DistanceDisplay"
        distanceBillboard.Adornee = targetObject
        distanceBillboard.Size = UDim2.new(0,200,0,50)
        distanceBillboard.StudsOffset = Vector3.new(0,-3,0)
        distanceBillboard.AlwaysOnTop = true
        distanceBillboard.Enabled = (ESPEnabled == true) and (ShowDistance == true)
        distanceBillboard.Parent = ESPFolder
        
        distanceLabel = Instance.new("TextLabel")
        distanceLabel.Name = "DistanceText"
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.Size = UDim2.new(1,0,1,0)
        distanceLabel.Font = Enum.Font.SourceSansBold
        distanceLabel.TextSize = 18
        distanceLabel.TextColor3 = color
        distanceLabel.TextStrokeTransparency = 0
        distanceLabel.TextStrokeColor3 = Color3.new(0,0,0)
        distanceLabel.Text = "0 m"
        distanceLabel.Parent = distanceBillboard
        
        local chassis = targetObject.Parent and targetObject.Parent.Parent
        if chassis then
            local turret = chassis:FindFirstChild("Turret")
            if turret then
                for _, obj in ipairs(turret:GetChildren()) do
                    if obj:IsA("Model") then turretAdornee = obj break end
                end
            end
        end
        
        markBillboard = Instance.new("Frame")
        markBillboard.Name = "MarkDisplay"
        markBillboard.Size = UDim2.new(0, MarkSize, 0, MarkSize)
        markBillboard.Position = UDim2.new(0,0,0,0)
        markBillboard.BackgroundTransparency = 1
        markBillboard.Visible = false
        markBillboard.Parent = MarkScreenGui
        
        local img = Instance.new("ImageLabel")
        img.Name = "MarkImage"
        img.BackgroundTransparency = 1
        img.Size = UDim2.new(1,0,1,0)
        img.Image = "rbxassetid://" .. tostring(MarkDecalID)
        img.Parent = markBillboard
    end
    
    ESPInstances[targetObject] = {
        Instance = highlight,
        DistanceLabel = distanceLabel,
        DistanceBillboard = distanceBillboard,
        MarkBillboard = markBillboard,
        TurretAdornee = turretAdornee,
        Target = targetObject,
        Color = color,
        IsHull = isHull,
    }
    return ESPInstances[targetObject]
end

local function UpdateMarkPositions()
    if not Camera then return end
    if not EnableMark then return end
    
    local camPos = Camera.CFrame.Position
    local vpSize = Camera.ViewportSize
    
    for _, espData in pairs(ESPInstances) do
        if espData.MarkBillboard and espData.IsHull then
            local target = espData.TurretAdornee or espData.Target
            if target and target.Parent then
                local ok, pos = pcall(GetModelPosition, target)
                if not ok then pos = espData.Target.Position end
                if (pos - camPos).Magnitude >= MarkDistance then
                    local sp, onScreen = Camera:WorldToViewportPoint(pos)
                    if onScreen and sp.Z > 0 then
                        local x = math.clamp(sp.X - MarkSize/2, 0, vpSize.X - MarkSize)
                        local y = math.clamp(sp.Y - MarkOffsetY - MarkSize/2, 0, vpSize.Y - MarkSize)
                        espData.MarkBillboard.Position = UDim2.new(0, x, 0, y)
                        espData.MarkBillboard.Visible  = true
                    else
                        espData.MarkBillboard.Visible = false
                    end
                else
                    espData.MarkBillboard.Visible = false
                end
            else
                espData.MarkBillboard.Visible = false
            end
        end
    end
end

local function UpdateDistanceLabels()
    if not Camera then return end
    local camPos = Camera.CFrame.Position
    for _, espData in pairs(ESPInstances) do
        if espData.IsHull and espData.DistanceLabel and espData.Target and espData.Target.Parent then
            local ok, pos = pcall(GetModelPosition, espData.Target)
            if ok then
                local dist = math.floor((pos - camPos).Magnitude / 3)
                espData.DistanceLabel.Text = dist .. " m"
            end
        end
    end
end

local function CleanupESP()
    local toRemove = {}
    for obj, espData in pairs(ESPInstances) do
        if not obj or not obj.Parent then
            table.insert(toRemove, obj)
            if espData.Instance then espData.Instance:Destroy() end
            if espData.DistanceBillboard then espData.DistanceBillboard:Destroy() end
            if espData.MarkBillboard then espData.MarkBillboard:Destroy() end
        end
    end
    for _, obj in ipairs(toRemove) do ESPInstances[obj] = nil end
end

function ProcessChassis(chassis)
    if not chassis:IsA("Model") or not chassis.Name:match("^Chassis") then return end
    
    local playerName = chassis.Name:match("^Chassis(.+)$")
    if not playerName or playerName == "" then return end
    
    if playerName == LocalPlayer.Name then return end
    
    if TeamCheckEnabled then
        local targetPlayer = Players:FindFirstChild(playerName)
        if not targetPlayer then return end
        
        local localTeam  = LocalPlayer.Team
        local targetTeam = targetPlayer.Team
        if localTeam and targetTeam and localTeam == targetTeam then return end
    end
    
    local hull = chassis:FindFirstChild("Hull")
    if hull then
        for _, obj in ipairs(hull:GetChildren()) do
            if obj:IsA("Model") then CreateESP(obj, HullColor, true) break end
        end
    end
    local turret = chassis:FindFirstChild("Turret")
    if turret then
        for _, obj in ipairs(turret:GetChildren()) do
            if obj:IsA("Model") then CreateESP(obj, TurretColor, false) break end
        end
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if isRebinding or (tick() - lastRebindTime) < 0.5 then return end
    if input.KeyCode == ToggleKey then
        ESPEnabled = not ESPEnabled
        UpdateAllESPInstances()
    end
    if input.KeyCode == FlyKey then
        if flying then stopFly() else startFly() end
    end
end)


workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera
end)

RunService.Heartbeat:Connect(function(dt)
    TimeSinceLastVehicleScan += dt
    if TimeSinceLastVehicleScan >= VehicleScanInterval then
        TimeSinceLastVehicleScan = 0
        ScanVehicles()
    end
    
    TimeSinceLastCleanup += dt
    if TimeSinceLastCleanup >= CleanupInterval then
        TimeSinceLastCleanup = 0
        CleanupESP()
    end
    
    UpdateDistanceLabels()
end)


RunService.RenderStepped:Connect(function(dt)
    TimeSinceLastMarkUpdate += dt
    if TimeSinceLastMarkUpdate >= MarkUpdateInterval then
        TimeSinceLastMarkUpdate = 0
        UpdateMarkPositions()
    end
    
    if flying then
        if flyRoot and flyRoot.Parent then
            local cam  = Workspace.CurrentCamera
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
            bv.Velocity = move.Magnitude > 0 and move.Unit * flySpeed or Vector3.zero
            bg.CFrame   = cam.CFrame
        end
    end
end)

ScanVehicles()

local function ProcessAtmosphere(atmosphere)
    if RemoveFogEnabled then
        atmosphere.Density = 0
        atmosphere.Haze = 0
    end
end

local function WatchAtmosphere(atmosphere)
    ProcessAtmosphere(atmosphere)
    atmosphere.Changed:Connect(function(property)
        if property == "Density" or property == "Haze" then
            ProcessAtmosphere(atmosphere)
        end
    end)
end

Lighting.ChildAdded:Connect(function(child)
    if child:IsA("Atmosphere") then WatchAtmosphere(child) end
end)

for _, child in ipairs(Lighting:GetChildren()) do
    if child:IsA("Atmosphere") then WatchAtmosphere(child) end
end

local HACKS = {
    Penetration = {
        target = 9999, active = false,
        names = {"Penetration", "Penetrate"},
        patched = {}, origPatched = {}
    },
    Ricochet = {
        target = 9999, active = false,
        names = {"RicochetAngle"},
        patched = {}, origPatched = {}
    },
    BulletGravity = {
        target = 0, active = false,
        names = {"BulletGravity"},
        patched = {}, origPatched = {}
    },
    ShellSpeed = {
        target = 9999, active = false,
        names = {"ShellSpeed"},
        patched = {}, origPatched = {}
    },
}

local WeaponConnections = {}
local ChassisDescendantConn = nil

local function GetOwnChassis()
    local vehicles = Workspace:FindFirstChild("Vehicles")
    if not vehicles then return nil end
    return vehicles:FindFirstChild("Chassis" .. LocalPlayer.Name)
end

local function ForceValue(obj, hack)
    if not hack.patched[obj] then
        hack.patched[obj] = obj.Value
    end
    if obj:GetAttribute("Orig") ~= nil then
        if not hack.origPatched[obj] then
            hack.origPatched[obj] = obj:GetAttribute("Orig")
        end
        obj:SetAttribute("Orig", hack.target)
    end
    obj.Value = hack.target
end

local function WatchWeaponObject(obj)
    for _, hack in pairs(HACKS) do
        if hack.active then
            for _, name in ipairs(hack.names) do
                if obj.Name == name then
                    ForceValue(obj, hack)
                    WeaponConnections[obj] = obj:GetPropertyChangedSignal("Value"):Connect(function()
                        if obj.Value ~= hack.target then
                            ForceValue(obj, hack)
                        end
                    end)
                    return
                end
            end
        end
    end
end

local function ClearWeaponConnections()
    for _, conn in pairs(WeaponConnections) do conn:Disconnect() end
    table.clear(WeaponConnections)
end

local function SetupWeaponChassis(chassis)
    if ChassisDescendantConn then
        ChassisDescendantConn:Disconnect()
        ChassisDescendantConn = nil
    end
    ClearWeaponConnections()
    for _, obj in ipairs(chassis:GetDescendants()) do
        if obj:IsA("IntValue") or obj:IsA("NumberValue") then
            WatchWeaponObject(obj)
        end
    end
    ChassisDescendantConn = chassis.DescendantAdded:Connect(function(obj)
        if obj:IsA("IntValue") or obj:IsA("NumberValue") then
            WatchWeaponObject(obj)
        end
    end)
end

local function InitWeapon()
    local chassis = GetOwnChassis()
    if chassis then SetupWeaponChassis(chassis) end
end

Workspace:WaitForChild("Vehicles").ChildAdded:Connect(function(obj)
    if obj.Name == ("Chassis" .. LocalPlayer.Name) then
        for _, hack in pairs(HACKS) do
            hack.patched = {}
            hack.origPatched = {}
        end
        task.wait(1)
        SetupWeaponChassis(obj)
    end
end)

Workspace:WaitForChild("Vehicles").ChildRemoved:Connect(function(obj)
    if not obj:IsA("Model") then return end
    local toRemove = {}
    for target, espData in pairs(ESPInstances) do
        if target == obj or (espData.Target and espData.Target:IsDescendantOf(obj)) then
            table.insert(toRemove, target)
            if espData.Instance then espData.Instance:Destroy() end
            if espData.DistanceBillboard then espData.DistanceBillboard:Destroy() end
            if espData.MarkBillboard then espData.MarkBillboard:Destroy() end
        end
    end
    for _, t in ipairs(toRemove) do ESPInstances[t] = nil end
end)

InitWeapon()

WeaponTab:CreateSection("Penetration")
WeaponTab:CreateToggle({
    Name = "Enable Penetration Hack", CurrentValue = false, Flag = "HackPenetrationFlag",
    Callback = function(Value)
        HACKS.Penetration.active = Value
        task.defer(InitWeapon)
    end,
})
WeaponTab:CreateSlider({
    Name = "Penetration Value", Range = {0, 9999}, Increment = 1,
    CurrentValue = 9999, Flag = "PenetrationValueFlag",
    Callback = function(Value)
        HACKS.Penetration.target = Value
        if HACKS.Penetration.active then task.defer(InitWeapon) end
    end,
})

WeaponTab:CreateSection("Ricochet Angle")
WeaponTab:CreateToggle({
    Name = "Enable Ricochet Hack", CurrentValue = false, Flag = "HackRicochetFlag",
    Callback = function(Value)
        HACKS.Ricochet.active = Value
        task.defer(InitWeapon)
    end,
})
WeaponTab:CreateSlider({
    Name = "Ricochet Value", Range = {0, 9999}, Increment = 1,
    CurrentValue = 9999, Flag = "RicochetValueFlag",
    Callback = function(Value)
        HACKS.Ricochet.target = Value
        if HACKS.Ricochet.active then task.defer(InitWeapon) end
    end,
})

WeaponTab:CreateSection("Bullet Gravity")
WeaponTab:CreateToggle({
    Name = "Enable Bullet Gravity Hack", CurrentValue = false, Flag = "HackBulletGravityFlag",
    Callback = function(Value)
        HACKS.BulletGravity.active = Value
        task.defer(InitWeapon)
    end,
})
WeaponTab:CreateSlider({
    Name = "Bullet Gravity Value", Range = {-500, 500}, Increment = 1,
    CurrentValue = 0, Flag = "BulletGravityValueFlag",
    Callback = function(Value)
        HACKS.BulletGravity.target = Value
        if HACKS.BulletGravity.active then task.defer(InitWeapon) end
    end,
})

WeaponTab:CreateSection("Shell Speed")
WeaponTab:CreateToggle({
    Name = "Enable Shell Speed Hack", CurrentValue = false, Flag = "HackShellSpeedFlag",
    Callback = function(Value)
        HACKS.ShellSpeed.active = Value
        task.defer(InitWeapon)
    end,
})
WeaponTab:CreateSlider({
    Name = "Shell Speed Value", Range = {0, 9999}, Increment = 1,
    CurrentValue = 9999, Flag = "ShellSpeedValueFlag",
    Callback = function(Value)
        HACKS.ShellSpeed.target = Value
        if HACKS.ShellSpeed.active then task.defer(InitWeapon) end
    end,
})
