print("Three?")

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Services = {
    RunService = game:GetService("RunService"),
    UserInput = game:GetService("UserInputService"),
    Players = game:GetService("Players"),
    CoreGui = game:GetService("CoreGui"),
    Workspace = game:GetService("Workspace"),
    Lighting = game:GetService("Lighting")
}
local LocalPlayer = Services.Players.LocalPlayer

local Keys = {
    Toggle = Enum.KeyCode.F,
    Fly = Enum.KeyCode.M
}

local ESP = {
    Enabled = true,
    TeamCheck = false,
    ShowDistance = false,
    EnableFill = true,
    EnableOutline = true,
    Instances = {},
    HullColor = Color3.new(0.8, 0.2, 0.9),
    TurretColor = Color3.new(0.2, 0.9, 0.4),
    FillTransparency = 0.5,
    OutlineTransparency = 0.2
}

local Mark = {
    Enabled = false,
    Distance = 1000,
    DecalID = "11552476728",
    OffsetY = 50,
    Size = 25,
    UpdateInterval = 0.016,
    TimeSinceUpdate = 0
}

local Timers = {
    VehicleScan = 0,
    Cleanup = 0,
    ScanInterval = 0.5,
    CleanupInterval = 2
}

local Fly = {
    Active = false,
    Speed = 70,
    Root = nil,
    IsRebinding = false,
    LastRebindTime = 0
}

local Other = {
    RemoveFog = false,
    PenView = false
}

local PenView = {
    UI = nil,
    HeartbeatConnection = nil,
    LastPart = nil,
    LastChassisName = nil,
    ArmorTypes = {
        "Structural Steel", "RHA", "HHRA", "CHA", "NERA", "Internal RHA", "Internal HHRA",
        "Internal CHA", "Composite Screen", "Rubber-fabric Screen", "Internal Aluminium",
        "Aluminium", "Aluminium Alloy", "Internal Aluminium Alloy", "Internal Structural Steel",
        "ERA", "Wood", "Armour"
    }
}

local Camera = Services.Workspace.CurrentCamera

local function PenView_CreateUI()
    for _, v in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
        if v.Name == "PenViewport" then v:Destroy() end
    end
    
    local sg = Instance.new("ScreenGui")
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = -100
    sg.Name = "PenViewport"
    sg.Parent = LocalPlayer.PlayerGui
    
    local vp = Instance.new("ViewportFrame", sg)
    vp.Size = UDim2.new(1, 0, 1, 0)
    vp.BackgroundTransparency = 1
    vp.ImageTransparency = 0.25
    vp.ZIndex = -100
    
    local cam = Instance.new("Camera")
    vp.CurrentCamera = cam
    cam.CameraType = Enum.CameraType.Scriptable
    
    return {viewport = vp, vpcam = cam}
end

local function PenView_GetPenetration()
    local vehicles = Services.Workspace:FindFirstChild("Vehicles")
    if not vehicles then return 200 end
    
    local chassis = vehicles:FindFirstChild("Chassis" .. LocalPlayer.Name)
    if not chassis then return 200 end
    
    local gunFolder = chassis:FindFirstChild("Gun")
    if not gunFolder then return 200 end
    
    for _, gunWeapon in ipairs(gunFolder:GetChildren()) do
        local config = gunWeapon:FindFirstChild("Config")
        if config then
            local shells = config:FindFirstChild("Shells")
            if shells then
                for _, folder in ipairs(shells:GetChildren()) do
                    local penVal = folder:FindFirstChild("Penetration")
                    if penVal then return penVal.Value end
                end
            end
        end
    end
    
    return 200
end

local function PenView_FindGunBrick(chassis)
    local gun = chassis:FindFirstChild("Gun", true)
    if not gun then return nil end
    for _, obj in ipairs(gun:GetDescendants()) do
        if obj.Name == "GunBrick" then return obj end
    end
    return nil
end

local function PenView_GetArmorThickness(hitPart, hitPos, direction, hitNormal)
    if not hitPart or not hitPos then return 0 end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Whitelist
    params.FilterDescendantsInstances = {hitPart}
    
    local result = Services.Workspace:Raycast(hitPos + direction * 4, -direction * 50, params)
    if result and result.Instance == hitPart then
        local thickness = (hitPos - result.Position).Magnitude / 0.00357
        if hitNormal then
            local cos = math.abs(hitNormal:Dot(-direction.Unit))
            thickness = thickness / math.max(cos, 0.05)
        end
        return thickness
    end
    return 0
end

local function PenView_UpdateViewport(ui, part, thickness, pen)
    if not ui or not ui.viewport or not ui.viewport.Parent then
        return
    end
    
    if not part or not part.Parent then
        if ui.viewport then ui.viewport:ClearAllChildren() end
        PenView.LastPart = nil
        return
    end
    
    local mesh = ui.viewport:FindFirstChildWhichIsA("BasePart")
    
    if PenView.LastPart ~= part or not mesh then
        PenView.LastPart = part
        ui.viewport:ClearAllChildren()
        
        local clone = part:Clone()
        clone.Transparency = 0.3
        clone.CanCollide = false
        clone.Anchored = true
        clone.Parent = ui.viewport
        
        mesh = clone
    end
    
    if not mesh then return end
    
    local ok = pcall(function()
        mesh.CFrame = part.CFrame
    end)
    if not ok then
        ui.viewport:ClearAllChildren()
        PenView.LastPart = nil
        return
    end
    
    ui.vpcam.CFrame = Services.Workspace.CurrentCamera.CFrame
    ui.vpcam.FieldOfView = Services.Workspace.CurrentCamera.FieldOfView
    
    local color
    if thickness <= 0.1 or pen <= 0 then
        color = Color3.fromRGB(90, 90, 90)
    elseif thickness <= pen * 0.5 then
        color = Color3.fromRGB(0, 255, 0)
    elseif thickness < pen then
        local t = (thickness - pen * 0.5) / (pen * 0.5)
        color = Color3.new(1, 1 - t, 0)
    else
        color = Color3.fromRGB(255, 0, 0)
    end
    mesh.Color = color
end

local function PenView_StartHeartbeat(ui)
    if PenView.HeartbeatConnection then PenView.HeartbeatConnection:Disconnect() end
    PenView.LastPart = nil
    
    PenView.HeartbeatConnection = Services.RunService.Heartbeat:Connect(function()
        if not ui or not ui.viewport or not ui.viewport.Parent then
            if PenView.HeartbeatConnection then 
                PenView.HeartbeatConnection:Disconnect()
                PenView.HeartbeatConnection = nil
            end
            return
        end
        
        local vehicles = Services.Workspace:FindFirstChild("Vehicles")
        if not vehicles or not ui then
            if ui and ui.viewport then ui.viewport:ClearAllChildren() end
            return
        end
        
        local chassis = vehicles:FindFirstChild("Chassis" .. LocalPlayer.Name)
        if not chassis then
            if ui.viewport then ui.viewport:ClearAllChildren() end
            PenView.LastPart = nil
            PenView.LastChassisName = nil
            return
        end
        
        if chassis.Name ~= PenView.LastChassisName then
            PenView.LastChassisName = chassis.Name
            PenView.LastPart = nil
        end
        
        local gunBrick = PenView_FindGunBrick(chassis)
        if not gunBrick then return end
        
        local pen = PenView_GetPenetration()
        local origin = gunBrick.Position + gunBrick.CFrame.LookVector * 2
        local dir = gunBrick.CFrame.LookVector
        
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
        rayParams.FilterDescendantsInstances = {chassis, Services.Workspace:FindFirstChild("Projectiles")}
        rayParams.IgnoreWater = true
        rayParams.CollisionGroup = "Default"
        
        local result = Services.Workspace:Raycast(origin, dir * 3000, rayParams)
        
        if result and result.Instance and table.find(PenView.ArmorTypes, result.Instance.Name) and result.Instance.CanCollide then
            if not ui.viewport:FindFirstChildWhichIsA("BasePart") then
                PenView.LastPart = nil
            end
            
            local thickness = PenView_GetArmorThickness(result.Instance, result.Position, dir, result.Normal)
            PenView_UpdateViewport(ui, result.Instance, thickness, pen)
        else
            if ui.viewport then ui.viewport:ClearAllChildren() end
            PenView.LastPart = nil
        end
    end)
end

local function PenView_Reset()
    if PenView.HeartbeatConnection then
        PenView.HeartbeatConnection:Disconnect()
        PenView.HeartbeatConnection = nil
    end
    PenView.LastPart = nil
    PenView.LastChassisName = nil

    PenView.UI = PenView_CreateUI()
    PenView_StartHeartbeat(PenView.UI)
end

local function PenView_Monitor()
    task.spawn(function()
        while Other.PenView do
            local vehicles = Services.Workspace:FindFirstChild("Vehicles")
            local chassis = vehicles and vehicles:FindFirstChild("Chassis" .. LocalPlayer.Name)
            
            if chassis and not PenView.HeartbeatConnection then
                PenView_Reset()
            elseif not chassis and PenView.HeartbeatConnection then
                if PenView.UI and PenView.UI.viewport then
                    PenView.UI.viewport:ClearAllChildren()
                end
            end
            task.wait(0.5)
        end
    end)
end

local PenView_VehiclesAddedConn
local PenView_VehiclesRemovedConn

local function PenView_Start()
    PenView_Reset()
    PenView_Monitor()
    
    local vehiclesFolder = Services.Workspace:FindFirstChild("Vehicles")
    if vehiclesFolder then
        PenView_VehiclesAddedConn = vehiclesFolder.ChildAdded:Connect(function(child)
            if child.Name == "Vehicles" then
                task.wait(0.8)
                PenView_Reset()
            end
        end)
        
        PenView_VehiclesRemovedConn = vehiclesFolder.ChildRemoved:Connect(function(child)
            if child.Name == "Vehicles" then
                if PenView.UI and PenView.UI.viewport then
                    PenView.UI.viewport:ClearAllChildren()
                end
            end
        end)
    end
end

local function PenView_Stop()
    if PenView.HeartbeatConnection then
        PenView.HeartbeatConnection:Disconnect()
        PenView.HeartbeatConnection = nil
    end
    
    if PenView_VehiclesAddedConn then
        PenView_VehiclesAddedConn:Disconnect()
        PenView_VehiclesAddedConn = nil
    end
    
    if PenView_VehiclesRemovedConn then
        PenView_VehiclesRemovedConn:Disconnect()
        PenView_VehiclesRemovedConn = nil
    end
    
    local pg = LocalPlayer.PlayerGui
    local vp = pg:FindFirstChild("PenViewport")
    if vp then vp:Destroy() end
    
    PenView.UI = nil
    PenView.LastPart = nil
    PenView.LastChassisName = nil
end

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "PerfData"
ESPFolder.Parent = Services.CoreGui

local MarkScreenGui = Instance.new("ScreenGui")
MarkScreenGui.Name = "MarkDisplay"
MarkScreenGui.ResetOnSpawn = false
MarkScreenGui.Parent = Services.CoreGui

local function parseKeyCode(str)
    if not str or str == "" then return nil end
    local name = str:match("KeyCode%.(.+)") or str
    for _, item in ipairs(Enum.KeyCode:GetEnumItems()) do
        if item.Name == name then return item end
    end
    return nil
end

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
    Fly.Root = findFlyPart(tankModel)
end

local function startFly()
    if Fly.Active then return end
    initFlyRoot()
    Fly.Active = true
    if Fly.Root then
        bv.Parent = Fly.Root
        bg.Parent = Fly.Root
    end
end

local function stopFly()
    if not Fly.Active then return end
    Fly.Active = false
    bv.Parent = nil
    bg.Parent = nil
end


local function UpdateESPInstance(espData)
    if not espData.Instance then return end
    
    espData.Instance.FillColor = ESP.EnableFill and espData.Color or Color3.new(0,0,0)
    espData.Instance.FillTransparency = ESP.EnableFill and ESP.FillTransparency or 1
    espData.Instance.OutlineColor = ESP.EnableOutline and espData.Color or Color3.new(0,0,0)
    espData.Instance.OutlineTransparency = ESP.EnableOutline and ESP.OutlineTransparency or 1
    espData.Instance.Enabled = ESP.Enabled

    if espData.DistanceBillboard then
        espData.DistanceBillboard.Enabled = ESP.Enabled and ESP.ShowDistance and espData.IsHull
    end
end

local function UpdateAllESPInstances()
    for _, espData in pairs(ESP.Instances) do
        UpdateESPInstance(espData)
    end
end

local function ClearAllESP()
    for obj, espData in pairs(ESP.Instances) do
        if espData.Instance then espData.Instance:Destroy() end
        if espData.DistanceBillboard then espData.DistanceBillboard:Destroy() end
        if espData.MarkBillboard then espData.MarkBillboard:Destroy() end
    end
    ESP.Instances = {}
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
    Discord = false,
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
        ESP.Enabled = Value
        UpdateAllESPInstances()
    end,
})

MainTab:CreateToggle({
    Name = "Team Check (enemies only)", CurrentValue = false, Flag = "TeamCheckFlag",
    Callback = function(Value)
        ESP.TeamCheck = Value
        task.defer(function()
            ClearAllESP()
            ScanVehicles()
        end)
    end,
})

MainTab:CreateToggle({
    Name = "Show Distance", CurrentValue = false, Flag = "ShowDistanceFlag",
    Callback = function(Value)
        ESP.ShowDistance = Value
        UpdateAllESPInstances()
    end,
})

MainTab:CreateSection("Mark Settings")

MainTab:CreateToggle({
    Name = "Enable Mark", CurrentValue = false, Flag = "EnableMarkFlag",
    Callback = function(Value)
        Mark.Enabled = Value
        for _, espData in pairs(ESP.Instances) do
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
    Callback = function(Value) Mark.Distance = Value end,
})

MainTab:CreateLabel("Mark appearance")
MainTab:CreateInput({
    Name = "Mark Decal ID", PlaceholderText = "11552476728",
    RemoveTextAfterFocusLost = false, CurrentValue = "11552476728", Flag = "MarkDecalIDFlag",
    Callback = function(Value)
        local id = tonumber(Value)
        if id and id > 0 then
            Mark.DecalID = tostring(id)
            local textureId = "rbxassetid://" .. Mark.DecalID
            for _, espData in pairs(ESP.Instances) do
                if espData.MarkBillboard then
                    local img = espData.MarkBillboard:FindFirstChild("MarkImage")
                    if img then img.Image = textureId end
                end
            end
            Rayfield:Notify({ Title = "Mark Updated", Content = "Decal ID: "..Mark.DecalID, Duration = 2, Image = 4483362458 })
        else
            Rayfield:Notify({ Title = "Invalid ID", Content = "Please enter a valid number", Duration = 3, Image = 4483362458 })
        end
    end,
})

MainTab:CreateSlider({
    Name = "Mark Offset Y", Range = {0,200}, Increment = 5,
    Suffix = " px", CurrentValue = 50, Flag = "MarkOffsetYFlag",
    Callback = function(Value) Mark.OffsetY = Value end,
})

MainTab:CreateSlider({
    Name = "Mark Size", Range = {5,50}, Increment = 5,
    Suffix = " px", CurrentValue = 25, Flag = "MarkSizeFlag",
    Callback = function(Value)
        Mark.Size = Value
        for _, espData in pairs(ESP.Instances) do
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
        Other.RemoveFog = Value
        for _, child in ipairs(Services.Lighting:GetChildren()) do
            if child:IsA("Atmosphere") then
                if Value then
                    child.Density = 0
                    child.Haze = 0
                end
            end
        end
    end,
})

VisualTab:CreateSection("Penetration View")

VisualTab:CreateToggle({
    Name = "Enable Penetration View", CurrentValue = false, Flag = "PenViewFlag",
    Callback = function(Value)
        Other.PenView = Value
        if Value then
            PenView_Start()
        else
            PenView_Stop()
        end
    end,
})

VisualTab:CreateSection("Colors")

VisualTab:CreateColorPicker({
    Name = "Hull Color", Color = Color3.new(0.8, 0.2, 0.9), Flag = "HullColorFlag",
    Callback = function(Value) ESP.HullColor = Value end,
})

VisualTab:CreateColorPicker({
    Name = "Turret Color", Color = Color3.new(0.2, 0.9, 0.4), Flag = "TurretColorFlag",
    Callback = function(Value) ESP.TurretColor = Value end,
})

VisualTab:CreateSection("Highlight Settings")

VisualTab:CreateSlider({
    Name = "Fill Transparency", Range = {0,1}, Increment = 0.01,
    CurrentValue = 0.5, Flag = "FillTransparencyFlag",
    Callback = function(Value)
        ESP.FillTransparency = Value
        UpdateAllESPInstances()
    end,
})

VisualTab:CreateSlider({
    Name = "Outline Transparency", Range = {0,1}, Increment = 0.01,
    CurrentValue = 0.2, Flag = "OutlineTransparencyFlag",
    Callback = function(Value)
        ESP.OutlineTransparency = Value
        UpdateAllESPInstances()
    end,
})

VisualTab:CreateToggle({
    Name = "Enable Fill", CurrentValue = true, Flag = "EnableFillFlag",
    Callback = function(Value)
        ESP.EnableFill = Value
        UpdateAllESPInstances()
    end,
})

VisualTab:CreateToggle({
    Name = "Enable Outline", CurrentValue = true, Flag = "EnableOutlineFlag",
    Callback = function(Value)
        ESP.EnableOutline = Value
        UpdateAllESPInstances()
    end,
})


FlyTab:CreateSection("Flight Control")
FlyTab:CreateLabel("W/A/S/D — move  |  Space — up  |  LCtrl — down")

FlyTab:CreateButton({
    Name = "Toggle Fly",
    Callback = function()
        if Fly.Active then
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
    Callback = function(Value) Fly.Speed = Value end,
})

FlyTab:CreateSection("Keybind")

FlyTab:CreateKeybind({
    Name = "Toggle Fly Key", CurrentKeybind = "M", HoldToInteract = false, Flag = "FlyKeyFlag",
    Callback = function(Value)
        Fly.IsRebinding = true
        Fly.LastRebindTime = tick()
        local key = parseKeyCode(Value)
        if key then Keys.Fly = key end
        task.delay(0.5, function() Fly.IsRebinding = false end)
    end,
})


SettingsTab:CreateSection("Performance")

SettingsTab:CreateSlider({
    Name = "Mark Update Rate", Range = {0.016,0.1}, Increment = 0.016,
    Suffix = "s", CurrentValue = 0.016, Flag = "MarkUpdateIntervalFlag",
    Callback = function(Value) Mark.UpdateInterval = Value end,
})

SettingsTab:CreateSlider({
    Name = "Scan Interval", Range = {0.1,2.0}, Increment = 0.1,
    Suffix = "s", CurrentValue = 0.5, Flag = "ScanIntervalFlag",
    Callback = function(Value) Timers.ScanInterval = Value end,
})

SettingsTab:CreateSection("Controls")

SettingsTab:CreateKeybind({
    Name = "Toggle ESP Key", CurrentKeybind = "F", HoldToInteract = false, Flag = "ToggleKeyFlag",
    Callback = function(Value)
        Fly.IsRebinding = true
        Fly.LastRebindTime = tick()
        local key = parseKeyCode(Value)
        if key then Keys.Toggle = key end
        task.delay(0.5, function() Fly.IsRebinding = false end)
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

SettingsTab:CreateButton({
    Name = "Copy Discord Link",
    Callback = function()
        setclipboard("https://discord.gg/gHg5g7eDC4")
        Rayfield:Notify({ Title = "Discord Server", Content = "Link copied to clipboard!", Duration = 3, Image = 4483362458 })
    end,
})

Rayfield:LoadConfiguration()

do
    local tf = Rayfield.Flags and Rayfield.Flags["ToggleKeyFlag"]
    if tf and tf.CurrentKeybind then
        local k = parseKeyCode(tf.CurrentKeybind)
        if k then Keys.Toggle = k end
    end
    local ff = Rayfield.Flags and Rayfield.Flags["FlyKeyFlag"]
    if ff and ff.CurrentKeybind then
        local k = parseKeyCode(ff.CurrentKeybind)
        if k then Keys.Fly = k end
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
    if ESP.Instances[targetObject] then return ESP.Instances[targetObject] end
    
    local highlight = Instance.new("Highlight")
    highlight.FillColor = ESP.EnableFill and color or Color3.new(0,0,0)
    highlight.FillTransparency = ESP.EnableFill and ESP.FillTransparency or 1
    highlight.OutlineColor = ESP.EnableOutline and color or Color3.new(0,0,0)
    highlight.OutlineTransparency = ESP.EnableOutline and ESP.OutlineTransparency or 1
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
        distanceBillboard.Enabled = ESP.Enabled and ESP.ShowDistance
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
        markBillboard.Size = UDim2.new(0, Mark.Size, 0, Mark.Size)
        markBillboard.Position = UDim2.new(0,0,0,0)
        markBillboard.BackgroundTransparency = 1
        markBillboard.Visible = false
        markBillboard.Parent = MarkScreenGui
        
        local img = Instance.new("ImageLabel")
        img.Name = "MarkImage"
        img.BackgroundTransparency = 1
        img.Size = UDim2.new(1,0,1,0)
        img.Image = "rbxassetid://" .. tostring(Mark.DecalID)
        img.Parent = markBillboard
    end
    
    ESP.Instances[targetObject] = {
        Instance = highlight,
        DistanceLabel = distanceLabel,
        DistanceBillboard = distanceBillboard,
        MarkBillboard = markBillboard,
        TurretAdornee = turretAdornee,
        Target = targetObject,
        Color = color,
        IsHull = isHull,
    }
    return ESP.Instances[targetObject]
end

local function UpdateMarkPositions()
    if not Camera then return end
    if not Mark.Enabled then return end
    
    local camPos = Camera.CFrame.Position
    local vpSize = Camera.ViewportSize
    
    for _, espData in pairs(ESP.Instances) do
        if espData.MarkBillboard and espData.IsHull then
            local target = espData.TurretAdornee or espData.Target
            if target and target.Parent then
                local ok, pos = pcall(GetModelPosition, target)
                if not ok then pos = espData.Target.Position end
                if (pos - camPos).Magnitude >= Mark.Distance then
                    local sp, onScreen = Camera:WorldToViewportPoint(pos)
                    if onScreen and sp.Z > 0 then
                        local x = math.clamp(sp.X - Mark.Size/2, 0, vpSize.X - Mark.Size)
                        local y = math.clamp(sp.Y - Mark.OffsetY - Mark.Size/2, 0, vpSize.Y - Mark.Size)
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
    for _, espData in pairs(ESP.Instances) do
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
    for obj, espData in pairs(ESP.Instances) do
        if not obj or not obj.Parent then
            table.insert(toRemove, obj)
            if espData.Instance then espData.Instance:Destroy() end
            if espData.DistanceBillboard then espData.DistanceBillboard:Destroy() end
            if espData.MarkBillboard then espData.MarkBillboard:Destroy() end
        end
    end
    for _, obj in ipairs(toRemove) do ESP.Instances[obj] = nil end
end

function ProcessChassis(chassis)
    if not chassis:IsA("Model") or not chassis.Name:match("^Chassis") then return end
    
    local playerName = chassis.Name:match("^Chassis(.+)$")
    if not playerName or playerName == "" then return end
    
    if playerName == LocalPlayer.Name then return end
    
    if ESP.TeamCheck then
        local targetPlayer = Services.Players:FindFirstChild(playerName)
        if not targetPlayer then return end
        
        local localTeam  = LocalPlayer.Team
        local targetTeam = targetPlayer.Team
        if localTeam and targetTeam and localTeam == targetTeam then return end
    end
    
    local hull = chassis:FindFirstChild("Hull")
    if hull then
        for _, obj in ipairs(hull:GetChildren()) do
            if obj:IsA("Model") then CreateESP(obj, ESP.HullColor, true) break end
        end
    end
    local turret = chassis:FindFirstChild("Turret")
    if turret then
        for _, obj in ipairs(turret:GetChildren()) do
            if obj:IsA("Model") then CreateESP(obj, ESP.TurretColor, false) break end
        end
    end
end

Services.UserInput.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if Fly.IsRebinding or (tick() - Fly.LastRebindTime) < 0.5 then return end
    if input.KeyCode == Keys.Toggle then
        ESP.Enabled = not ESP.Enabled
        UpdateAllESPInstances()
    end
    if input.KeyCode == Keys.Fly then
        if Fly.Active then stopFly() else startFly() end
    end
end)


workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Services.Workspace.CurrentCamera
end)

Services.RunService.Heartbeat:Connect(function(dt)
    Timers.VehicleScan += dt
    if Timers.VehicleScan >= Timers.ScanInterval then
        Timers.VehicleScan = 0
        ScanVehicles()
    end
    
    Timers.Cleanup += dt
    if Timers.Cleanup >= Timers.CleanupInterval then
        Timers.Cleanup = 0
        CleanupESP()
    end
    
    UpdateDistanceLabels()
end)


Services.RunService.RenderStepped:Connect(function(dt)
    Mark.TimeSinceUpdate += dt
    if Mark.TimeSinceUpdate >= Mark.UpdateInterval then
        Mark.TimeSinceUpdate = 0
        UpdateMarkPositions()
    end
    
    if Fly.Active then
        if Fly.Root and Fly.Root.Parent then
            local cam  = Services.Workspace.CurrentCamera
            local move = Vector3.zero
            if Services.UserInput:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
            if Services.UserInput:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
            if Services.UserInput:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
            if Services.UserInput:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
            if Services.UserInput:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
            if Services.UserInput:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
            bv.Velocity = move.Magnitude > 0 and move.Unit * Fly.Speed or Vector3.zero
            bg.CFrame   = cam.CFrame
        end
    end
end)

ScanVehicles()

local function ProcessAtmosphere(atmosphere)
    if Other.RemoveFog then
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

Services.Lighting.ChildAdded:Connect(function(child)
    if child:IsA("Atmosphere") then WatchAtmosphere(child) end
end)

for _, child in ipairs(Services.Lighting:GetChildren()) do
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
    local vehicles = Services.Workspace:FindFirstChild("Vehicles")
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

Services.Workspace:WaitForChild("Vehicles").ChildAdded:Connect(function(obj)
    if obj.Name == ("Chassis" .. LocalPlayer.Name) then
        for _, hack in pairs(HACKS) do
            hack.patched = {}
            hack.origPatched = {}
        end
        task.wait(1)
        SetupWeaponChassis(obj)
    end
end)

Services.Workspace:WaitForChild("Vehicles").ChildRemoved:Connect(function(obj)
    if not obj:IsA("Model") then return end
    local toRemove = {}
    for target, espData in pairs(ESP.Instances) do
        if target == obj or (espData.Target and espData.Target:IsDescendantOf(obj)) then
            table.insert(toRemove, target)
            if espData.Instance then espData.Instance:Destroy() end
            if espData.DistanceBillboard then espData.DistanceBillboard:Destroy() end
            if espData.MarkBillboard then espData.MarkBillboard:Destroy() end
        end
    end
    for _, t in ipairs(toRemove) do ESP.Instances[t] = nil end
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
