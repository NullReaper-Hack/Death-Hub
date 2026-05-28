-- Fetch required services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Fetch the local player
local LocalPlayer = Players.LocalPlayer

-- Load the Wind UI library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/GreenDeno/Venyx-UI-Library/main/source.lua"))()

-- Create the main window
local Window = Library.CreateWindow("DeathHub", Vector2.new(492, 598), Enum.KeyCode.RightControl)

-- Create the main tab
local MainTab = Window:AddTab("Main")

-- Teleportation section
local TeleportSection = MainTab:AddSection("Teleportation")

-- Teleport to Meteorite Ingot
TeleportSection:AddButton("Teleport to Meteorite Ingot", function()
    teleportTo("Items", "Meteorite Ingot")
end)

-- Teleport to Truck
TeleportSection:AddButton("Teleport to Truck", function()
    teleportTo("Vehicle", "Truck")
end)

-- ESP section
local ESPSection = MainTab:AddSection("ESP")

-- Toggle ESP
local ESPToggle = ESPSection:AddToggle("ESP NPC and Players", false, function(value)
    espEnabled = value
    if espEnabled then
        updateHighlights()
    else
        clearHighlights()
    end
end)

-- Teleport function
local function teleportTo(folderName, modelName)
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanoidRootPart")

    local folder = Workspace:FindFirstChild(folderName)
    if not folder then warn("Folder not found:", folderName) return end

    local model = folder:FindFirstChild(modelName)
    if not model or not model:IsA("Model") then warn("Invalid model:", modelName) return end

    local mainPart = model.PrimaryPart or model:FindFirstChild("Main") or model:FindFirstChildWhichIsA("BasePart")
    if not mainPart then warn("No main part found in model.") return end

    if not model.PrimaryPart then model.PrimaryPart = mainPart end

    root.CFrame = model.PrimaryPart.CFrame + Vector3.new(0, 5, 0)
end

-- ESP system
local espEnabled = false
local highlightInstances = {}

local function isNPC(model)
    if not model:IsA("Model") then return false end
    if model:FindFirstChildOfClass("Humanoid") then
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character == model then
                return false
            end
        end
        return true
    end
    return false
end

local function createHighlightForHeads(model)
    if not model or not model:IsA("Model") then return end
    if highlightInstances[model] then return highlightInstances[model] end

    -- Find all "Head" parts and highlight them
    for _, part in pairs(model:GetChildren()) do
        if part:IsA("BasePart") and part.Name == "Head" then
            local highlight = Instance.new("Highlight")
            highlight.Adornee = part
            highlight.FillColor = Color3.fromRGB(0, 255, 0)
            highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = Workspace
            highlightInstances[part] = highlight
        end
    end
end

local function clearHighlights()
    for part, highlight in pairs(highlightInstances) do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end
    highlightInstances = {}
end

local function updateHighlights()
    if not espEnabled then return end

    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and player.Character.Parent then
            createHighlightForHeads(player.Character)
        end
    end

    for _, descendant in pairs(Workspace:GetDescendants()) do
        if isNPC(descendant) then
            createHighlightForHeads(descendant)
        end
    end
end

Workspace.DescendantAdded:Connect(function(descendant)
    if espEnabled and isNPC(descendant) then
        createHighlightForHeads(descendant)
    end
end)
