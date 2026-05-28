--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

--// PLAYER
local LocalPlayer = Players.LocalPlayer

--// UI LIBRARY
local Library = loadstring(game:HttpGetAsync(
    "https://raw.githubusercontent.com/GreenDeno/Venyx-UI-Library/main/source.lua"
))()

--// WINDOW
local Window = Library.CreateWindow(
    "DeathHub",
    Vector2.new(492, 598),
    Enum.KeyCode.RightControl
)

--// TAB
local MainTab = Window:AddTab("Main")

------------------------------------------------
-- 📦 TELEPORT FUNCTION
------------------------------------------------

local function teleportTo(folderName, modelName)

    local character =
        LocalPlayer.Character
        or LocalPlayer.CharacterAdded:Wait()

    local root =
        character:WaitForChild("HumanoidRootPart")

    local folder = Workspace:FindFirstChild(folderName)

    if not folder then
        warn("Folder not found:", folderName)
        return
    end

    local model = folder:FindFirstChild(modelName)

    if not model or not model:IsA("Model") then
        warn("Invalid model:", modelName)
        return
    end

    local mainPart =
        model.PrimaryPart
        or model:FindFirstChild("Main")
        or model:FindFirstChildWhichIsA("BasePart")

    if not mainPart then
        warn("No BasePart found.")
        return
    end

    if not model.PrimaryPart then
        model.PrimaryPart = mainPart
    end

    root.CFrame =
        model.PrimaryPart.CFrame
        + Vector3.new(0,5,0)
end

------------------------------------------------
-- 👁 ESP SYSTEM
------------------------------------------------

local espEnabled = false
local highlightInstances = {}

local function isNPC(model)

    if not model:IsA("Model") then
        return false
    end

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

local function createHighlight(model)

    if not model or not model:IsA("Model") then
        return
    end

    for _, part in pairs(model:GetChildren()) do

        if part:IsA("BasePart")
        and part.Name == "Head" then

            if highlightInstances[part] then
                continue
            end

            local highlight = Instance.new("Highlight")

            highlight.Adornee = part
            highlight.FillColor = Color3.fromRGB(0,255,0)
            highlight.OutlineColor = Color3.fromRGB(0,255,0)
            highlight.DepthMode =
                Enum.HighlightDepthMode.AlwaysOnTop

            highlight.Parent = Workspace

            highlightInstances[part] = highlight
        end
    end
end

local function clearHighlights()

    for _, highlight in pairs(highlightInstances) do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end

    highlightInstances = {}
end

local function updateHighlights()

    if not espEnabled then
        return
    end

    -- players
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            createHighlight(player.Character)
        end
    end

    -- npcs
    for _, descendant in pairs(Workspace:GetDescendants()) do
        if isNPC(descendant) then
            createHighlight(descendant)
        end
    end
end

Workspace.DescendantAdded:Connect(function(descendant)

    if espEnabled and isNPC(descendant) then
        createHighlight(descendant)
    end
end)

------------------------------------------------
-- 🚀 FLY SYSTEM
------------------------------------------------

local flyEnabled = false
local flySpeed = 70

local bodyVelocity
local bodyGyro
local flyConnection

local function startFly()

    local character =
        LocalPlayer.Character
        or LocalPlayer.CharacterAdded:Wait()

    local humanoid =
        character:WaitForChild("Humanoid")

    local root =
        character:WaitForChild("HumanoidRootPart")

    flyEnabled = true

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce =
        Vector3.new(math.huge, math.huge, math.huge)

    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.Parent = root

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque =
        Vector3.new(math.huge, math.huge, math.huge)

    bodyGyro.P = 10000
    bodyGyro.Parent = root

    humanoid.AutoRotate = false

    flyConnection =
        RunService.RenderStepped:Connect(function()

        if not flyEnabled then
            return
        end

        local cam = Workspace.CurrentCamera
        local moveDirection = humanoid.MoveDirection

        bodyVelocity.Velocity =
            cam.CFrame:VectorToWorldSpace(moveDirection)
            * flySpeed

        bodyGyro.CFrame =
            CFrame.new(
                root.Position,
                root.Position + cam.CFrame.LookVector
            )
    end)
end

local function stopFly()

    flyEnabled = false

    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end

    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end

    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end

    local character = LocalPlayer.Character

    if character then

        local humanoid =
            character:FindFirstChild("Humanoid")

        local root =
            character:FindFirstChild("HumanoidRootPart")

        if humanoid then
            humanoid.AutoRotate = true
        end

        if root then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

------------------------------------------------
-- 📦 TELEPORT SECTION
------------------------------------------------

local TeleportSection =
    MainTab:AddSection("Teleportation")

TeleportSection:AddButton(
    "Teleport to Meteorite Ingot",
    function()
        teleportTo("Items", "Meteorite Ingot")
    end
)

TeleportSection:AddButton(
    "Teleport to Truck",
    function()
        teleportTo("Vehicle", "Truck")
    end
)

------------------------------------------------
-- 👁 ESP SECTION
------------------------------------------------

local ESPSection = MainTab:AddSection("ESP")

ESPSection:AddToggle(
    "ESP NPC and Players",
    false,
    function(value)

        espEnabled = value

        if espEnabled then
            updateHighlights()
        else
            clearHighlights()
        end
    end
)

------------------------------------------------
-- 🚀 FLY SECTION
------------------------------------------------

local FlySection = MainTab:AddSection("Fly")

FlySection:AddToggle(
    "Enable Fly",
    false,
    function(value)

        if value then
            startFly()
        else
            stopFly()
        end
    end
)

FlySection:AddSlider(
    "Fly Speed",
    10,
    200,
    70,
    function(value)
        flySpeed = value
    end
)

------------------------------------------------
-- 🔗 DISCORD SECTION
------------------------------------------------

local MiscSection =
    MainTab:AddSection("Discord")

MiscSection:AddButton(
    "Copy Discord Link",
    function()

        setclipboard(
            "https://discord.gg/HsTVeBHAV"
        )

        Library:Notify(
            "Copied",
            "Discord link copied to clipboard",
            3
        )
    end
)

------------------------------------------------
-- ✅ NOTIFICATION
------------------------------------------------

Library:Notify(
    "DeathHub Loaded",
    "Press RightCtrl to open/close UI",
    5
)
