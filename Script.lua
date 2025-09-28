local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local ToggleKey = Enum.KeyCode.F
local VehicleScanInterval = 0.5
local CleanupInterval = 0
local HullColor = Color3.new(0.8, 0.2, 0.9)
local TurretColor = Color3.new(0.2, 0.9, 0.4)
local FillTransparency = 0.5
local OutlineTransparency = 0.2
local ShowDistance = false
local MaxDistance = 1000
local DepthMode = "AlwaysOnTop"

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "PerfData"
ESPFolder.Parent = CoreGui

local ESPEnabled = true
local TimeSinceLastVehicleScan = 0
local TimeSinceLastCleanup = 0
local ESPInstances = {}

local Window = Rayfield:CreateWindow({
   Name = "C.T.S",
   LoadingTitle = "Cursed Tank Simulator",
   LoadingSubtitle = "by Qwiix21",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "CTS",
      FileName = "config"
   },
   Discord = {
      Enabled = false,
   },
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
local SettingsTab = Window:CreateTab("Settings", 4483362458)

local MainSection = MainTab:CreateSection("Control")



MainTab:CreateLabel("Press K to hide/show interface")

local ESPToggle = MainTab:CreateToggle({
   Name = "Enable ESP",
   CurrentValue = true,
   Flag = "ESPToggle",
   Callback = function(Value)
      ESPEnabled = Value
      for targetObject, espData in pairs(ESPInstances) do
         if espData.Instance then
            espData.Instance.Adornee = ESPEnabled and targetObject or nil
         end
      end
   end,
})

local DistanceToggle = MainTab:CreateToggle({
   Name = "Show Distance",
   CurrentValue = false,
   Flag = "ShowDistance",
   Callback = function(Value)
      ShowDistance = Value
   end,
})

local MaxDistanceSlider = MainTab:CreateSlider({
   Name = "Max ESP Distance",
   Range = {100, 5000},
   Increment = 50,
   Suffix = " studs",
   CurrentValue = 1000,
   Flag = "MaxDistance",
   Callback = function(Value)
      MaxDistance = Value
   end,
})

local VisualSection = VisualTab:CreateSection("Colors")

local HullColorPicker = VisualTab:CreateColorPicker({
   Name = "Hull Color",
   Color = Color3.new(0.8, 0.2, 0.9),
   Flag = "HullColor",
   Callback = function(Value)
      HullColor = Value
   end
})

local TurretColorPicker = VisualTab:CreateColorPicker({
   Name = "Turret Color",
   Color = Color3.new(0.2, 0.9, 0.4),
   Flag = "TurretColor",
   Callback = function(Value)
      TurretColor = Value
   end
})

local HighlightSection = VisualTab:CreateSection("Highlight Settings")

local EnableFill = true
local EnableOutline = true

local FillTransparencySlider = VisualTab:CreateSlider({
   Name = "Fill Transparency",
   Range = {0, 1},
   Increment = 0.01,
   CurrentValue = 0.5,
   Flag = "FillTransparency",
   Callback = function(Value)
      FillTransparency = Value
      for targetObject, espData in pairs(ESPInstances) do
         if espData.Instance then
            espData.Instance.FillTransparency = EnableFill and Value or 1
         end
      end
   end,
})

local OutlineTransparencySlider = VisualTab:CreateSlider({
   Name = "Outline Transparency",
   Range = {0, 1},
   Increment = 0.01,
   CurrentValue = 0.2,
   Flag = "OutlineTransparency",
   Callback = function(Value)
      OutlineTransparency = Value
      for targetObject, espData in pairs(ESPInstances) do
         if espData.Instance then
            espData.Instance.OutlineTransparency = EnableOutline and Value or 1
         end
      end
   end,
})

local DepthModeDropdown = VisualTab:CreateDropdown({
   Name = "Depth Mode",
   Options = {"AlwaysOnTop", "Occluded"},
   CurrentOption = "AlwaysOnTop",
   Flag = "DepthMode",
   Callback = function(Option)
      DepthMode = Option
      for targetObject, espData in pairs(ESPInstances) do
         if espData.Instance then
            espData.Instance.DepthMode = Enum.HighlightDepthMode[Option]
         end
      end
   end,
})

local EnableFillToggle = VisualTab:CreateToggle({
   Name = "Enable Fill",
   CurrentValue = true,
   Flag = "EnableFill",
   Callback = function(Value)
      EnableFill = Value
      for targetObject, espData in pairs(ESPInstances) do
         if espData.Instance then
            espData.Instance.FillColor = Value and espData.Color or Color3.new(0, 0, 0)
            espData.Instance.FillTransparency = Value and FillTransparency or 1
         end
      end
   end,
})

local EnableOutlineToggle = VisualTab:CreateToggle({
   Name = "Enable Outline",
   CurrentValue = true,
   Flag = "EnableOutline",
   Callback = function(Value)
      EnableOutline = Value
      for targetObject, espData in pairs(ESPInstances) do
         if espData.Instance then
            espData.Instance.OutlineColor = Value and espData.Color or Color3.new(0, 0, 0)
            espData.Instance.OutlineTransparency = Value and OutlineTransparency or 1
         end
      end
   end,
})

local PerformanceSection = SettingsTab:CreateSection("Performance")

local ScanSlider = SettingsTab:CreateSlider({
   Name = "Scan Interval",
   Range = {0.1, 2.0},
   Increment = 0.1,
   Suffix = "s",
   CurrentValue = 0.5,
   Flag = "ScanInterval",
   Callback = function(Value)
      VehicleScanInterval = Value
   end,
})

local ControlsSection = SettingsTab:CreateSection("Controls")

local ToggleKeybind = SettingsTab:CreateKeybind({
   Name = "Toggle ESP Key",
   CurrentKeybind = "F",
   HoldToInteract = false,
   Flag = "ToggleKey",
   Callback = function(Value)
      ToggleKey = Enum.KeyCode[Value]
   end,
})



local ProjectSection = SettingsTab:CreateSection("Project")

local GitHubButton = SettingsTab:CreateButton({
   Name = "Copy GitHub Link",
   Callback = function()
      setclipboard("https://github.com/qwiix21/Cursed-Tank-Simulator-Script")
      Rayfield:Notify({
         Title = "Repository Link",
         Content = "Link copied to clipboard!",
         Duration = 3,
         Image = 4483362458,
      })
   end,
})

local function CreateESP(targetObject, color)
    if ESPInstances[targetObject] then
        return ESPInstances[targetObject]
    end
    
    local highlight = Instance.new("Highlight")
    highlight.FillColor = EnableFill and color or Color3.new(0, 0, 0)
    highlight.FillTransparency = EnableFill and FillTransparency or 1
    highlight.OutlineColor = EnableOutline and color or Color3.new(0, 0, 0)
    highlight.OutlineTransparency = EnableOutline and OutlineTransparency or 1
    highlight.DepthMode = Enum.HighlightDepthMode[DepthMode]
    highlight.Adornee = targetObject
    highlight.Parent = ESPFolder
    
    ESPInstances[targetObject] = {
        Type = "highlight",
        Instance = highlight,
        Target = targetObject,
        Color = color
    }
    return ESPInstances[targetObject]
end

local function CleanupESP()
    for targetObject, espData in pairs(ESPInstances) do
        if not targetObject or not targetObject:IsDescendantOf(game) then
            if espData.Instance then
                espData.Instance:Destroy()
            end
            ESPInstances[targetObject] = nil
        elseif espData.Instance then
            espData.Instance.Adornee = ESPEnabled and targetObject or nil
        end
    end
end

local function ProcessChassis(chassis)
    if chassis:IsA("Actor") and chassis.Name:match("^Chassis") then
        local hull = chassis:FindFirstChild("Hull")
        if hull then
            for _, object in ipairs(hull:GetChildren()) do
                if object:IsA("Model") then
                    CreateESP(object, HullColor)
                    break
                end
            end
        end
        local turret = chassis:FindFirstChild("Turret")
        if turret then
            for _, object in ipairs(turret:GetChildren()) do
                if object:IsA("Model") then
                    CreateESP(object, TurretColor)
                    break
                end
            end
        end
    end
end

local function ScanVehicles()
    local vehiclesFolder = workspace:FindFirstChild("Vehicles")
    if vehiclesFolder then
        for _, chassis in ipairs(vehiclesFolder:GetChildren()) do
            ProcessChassis(chassis)
        end
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == ToggleKey and not gameProcessed then
        ESPEnabled = not ESPEnabled
        for targetObject, espData in pairs(ESPInstances) do
            if espData.Instance then
                espData.Instance.Adornee = ESPEnabled and targetObject or nil
            end
        end
    end
end)

RunService.RenderStepped:Connect(function(deltaTime)
    TimeSinceLastVehicleScan = TimeSinceLastVehicleScan + deltaTime
    if TimeSinceLastVehicleScan >= VehicleScanInterval then
        TimeSinceLastVehicleScan = 0
        ScanVehicles()
    end
    TimeSinceLastCleanup = TimeSinceLastCleanup + deltaTime
    if TimeSinceLastCleanup >= CleanupInterval then
        TimeSinceLastCleanup = 0
        CleanupESP()
    end
end)

ScanVehicles()

game:BindToClose(function()
    ESPFolder:Destroy()
    ESPInstances = {}
end)