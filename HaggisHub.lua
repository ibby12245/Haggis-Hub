
-- Haggis Hub Free
-- LocalScript: StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TOGGLE_KEY = Enum.KeyCode.K
local BRAINROTS_FOLDER = "Brainrots"
local BASES_FOLDER = "Bases"
local ZONES_FOLDER = "Zones"
local REFRESH_INTERVAL = 1

local rarityOrder = {
    Secret = 1,
    Mythical = 2,
    Mythic = 2,
    Legendary = 3,
    Epic = 4,
    Rare = 5,
    Uncommon = 6,
    Common = 7,
}

local COLORS = {
    background = Color3.fromRGB(16, 17, 24),
    header = Color3.fromRGB(23, 25, 35),
    sidebar = Color3.fromRGB(20, 22, 31),
    panel = Color3.fromRGB(25, 27, 38),
    entry = Color3.fromRGB(33, 36, 50),
    entryHover = Color3.fromRGB(45, 49, 68),
    accent = Color3.fromRGB(133, 111, 255),
    accentDark = Color3.fromRGB(76, 65, 140),
    text = Color3.fromRGB(239, 240, 255),
    muted = Color3.fromRGB(151, 158, 183),
    green = Color3.fromRGB(65, 139, 99),
    red = Color3.fromRGB(170, 58, 73),
}

-- Cleanup previous UI
local oldGui = playerGui:FindFirstChild("IbbysBrainrotHub")
if oldGui then
    oldGui:Destroy()
end

-- General helpers
local function findFolder(name)
    return workspace:FindFirstChild(name, true)
end

local function getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

local function getObjectPosition(object)
    if not object or not object.Parent then
        return nil
    end

    if object:IsA("Model") then
        local ok, pivot = pcall(function()
            return object:GetPivot()
        end)
        return ok and pivot or nil
    elseif object:IsA("BasePart") then
        return object.CFrame
    else
        local part = object:FindFirstChildWhichIsA("BasePart", true)
        return part and part.CFrame or nil
    end
end

local function teleportTo(object)
    local destination = getObjectPosition(object)
    if not destination then
        return false
    end

    local character = player.Character
    if not character or not character.Parent then
        return false
    end

    local ok = pcall(function()
        character:PivotTo(destination + Vector3.new(0, 3, 0))
    end)

    return ok
end

local function getRarity(object)
    local rarity = object:GetAttribute("RarityType")
        or object:GetAttribute("Rarity")

    if not rarity then
        local value = object:FindFirstChild("RarityType", true)
            or object:FindFirstChild("Rarity", true)

        if value and value:IsA("ValueBase") then
            rarity = value.Value
        end
    end

    return tostring(rarity or "Unknown")
end

-- Brainrots
local function getBrainrots()
    local folder = findFolder(BRAINROTS_FOLDER)
    local results = {}

    if not folder then
        return results
    end

    for _, object in ipairs(folder:GetChildren()) do
        if object:IsA("Model") or object:IsA("BasePart") then
            table.insert(results, object)
        end
    end

    table.sort(results, function(a, b)
        local aOrder = rarityOrder[getRarity(a)] or 99
        local bOrder = rarityOrder[getRarity(b)] or 99

        if aOrder == bOrder then
            return a.Name:lower() < b.Name:lower()
        end

        return aOrder < bOrder
    end)

    return results
end

local function isCurrentBrainrot(object)
    if not object or not object.Parent then
        return false
    end

    local folder = findFolder(BRAINROTS_FOLDER)

    return folder ~= nil
        and object.Parent == folder
        and (object:IsA("Model") or object:IsA("BasePart"))
        and getObjectPosition(object) ~= nil
end

-- Base number detection
local function getBaseNumber(base)
    local numberNames = {
        "BaseNumber",
        "BaseIndex",
        "PlotNumber",
        "PlotIndex",
        "Number",
        "Index",
        "BaseId",
        "PlotId",
    }

    for _, name in ipairs(numberNames) do
        local value = base:GetAttribute(name)

        if value ~= nil then
            local number = tonumber(value)
            if number then
                return number
            end
        end
    end

    for _, name in ipairs(numberNames) do
        local value = base:FindFirstChild(name, true)

        if value and value:IsA("ValueBase") then
            local number = tonumber(value.Value)
            if number then
                return number
            end
        end
    end

    local digits = base.Name:match("(%d+)%s*$")
        or base.Name:match("(%d+)")

    return digits and tonumber(digits) or nil
end

local function getBases()
    local folder = findFolder(BASES_FOLDER)
    local results = {}

    if not folder then
        return results
    end

    for _, object in ipairs(folder:GetChildren()) do
        if object:IsA("Model") or object:IsA("BasePart") then
            table.insert(results, object)
        end
    end

    table.sort(results, function(a, b)
        local aNumber = getBaseNumber(a)
        local bNumber = getBaseNumber(b)

        if aNumber and bNumber then
            return aNumber < bNumber
        elseif aNumber then
            return true
        elseif bNumber then
            return false
        end

        return a.Name:lower() < b.Name:lower()
    end)

    return results
end

local function getBaseOwner(base)
    local ownerNames = {
        "Owner",
        "OwnerName",
        "OwnerUserId",
        "OwnerId",
    }

    for _, name in ipairs(ownerNames) do
        local value = base:GetAttribute(name)

        if value ~= nil and tostring(value) ~= "" then
            return tostring(value)
        end
    end

    for _, name in ipairs(ownerNames) do
        local value = base:FindFirstChild(name, true)

        if value and value:IsA("ValueBase") then
            local result = tostring(value.Value)

            if result ~= "" then
                return result
            end
        end
    end

    return nil
end

local function findMyBase()
    for _, base in ipairs(getBases()) do
        local owner = getBaseOwner(base)

        if owner == player.Name
            or owner == player.DisplayName
            or owner == tostring(player.UserId) then
            return base
        end
    end

    return nil
end

-- Zones
local function getZones()
    local folder = findFolder(ZONES_FOLDER)
    local results = {}

    if not folder then
        return results
    end

    for _, object in ipairs(folder:GetChildren()) do
        if object:IsA("Model") or object:IsA("BasePart") then
            table.insert(results, object)
        end
    end

    table.sort(results, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)

    return results
end

-- Autofarm helpers
local function unequipTools()
    local character = player.Character
    local humanoid = character
        and character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        humanoid:UnequipTools()
    end
end

local function findPrompt(object)
    if not object or not object.Parent then
        return nil
    end

    for _, descendant in ipairs(object:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") and descendant.Enabled then
            return descendant
        end
    end

    return nil
end

-- UI
local gui = Instance.new("ScreenGui")
gui.Name = "IbbysBrainrotHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(590, 425)
main.Position = UDim2.new(0.5, -295, 0.5, -212)
main.BackgroundColor3 = COLORS.background
main.BorderSizePixel = 0
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = COLORS.accent
mainStroke.Transparency = 0.58
mainStroke.Thickness = 1.2
mainStroke.Parent = main

local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 54)
top.BackgroundColor3 = COLORS.header
top.BorderSizePixel = 0
top.Parent = main

Instance.new("UICorner", top).CornerRadius = UDim.new(0, 14)

local headerCover = Instance.new("Frame")
headerCover.Size = UDim2.new(1, 0, 0, 14)
headerCover.Position = UDim2.new(0, 0, 1, -14)
headerCover.BackgroundColor3 = COLORS.header
headerCover.BorderSizePixel = 0
headerCover.Parent = top

local accentLine = Instance.new("Frame")
accentLine.Position = UDim2.new(0, 0, 1, -2)
accentLine.Size = UDim2.new(1, 0, 0, 2)
accentLine.BackgroundColor3 = COLORS.accent
accentLine.BorderSizePixel = 0
accentLine.Parent = top

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -100, 0, 25)
title.Position = UDim2.fromOffset(17, 7)
title.BackgroundTransparency = 1
title.Text = "HAGGIS HUB FREE"
title.TextColor3 = COLORS.text
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = top

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -100, 0, 15)
subtitle.Position = UDim2.fromOffset(18, 31)
subtitle.BackgroundTransparency = 1
subtitle.Text = "BRAINROT TELEPORT HUB"
subtitle.TextColor3 = COLORS.muted
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 9
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = top

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.fromOffset(34, 32)
closeButton.Position = UDim2.new(1, -44, 0, 11)
closeButton.BackgroundColor3 = COLORS.red
closeButton.Text = "×"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 23
closeButton.BorderSizePixel = 0
closeButton.AutoButtonColor = false
closeButton.Parent = top

Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 9)

local sidebar = Instance.new("Frame")
sidebar.Position = UDim2.fromOffset(12, 66)
sidebar.Size = UDim2.new(0, 148, 1, -78)
sidebar.BackgroundColor3 = COLORS.sidebar
sidebar.BorderSizePixel = 0
sidebar.Parent = main

Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 10)

local sidebarPadding = Instance.new("UIPadding")
sidebarPadding.PaddingTop = UDim.new(0, 9)
sidebarPadding.PaddingLeft = UDim.new(0, 8)
sidebarPadding.PaddingRight = UDim.new(0, 8)
sidebarPadding.Parent = sidebar

local content = Instance.new("Frame")
content.Position = UDim2.fromOffset(172, 66)
content.Size = UDim2.new(1, -184, 1, -78)
content.BackgroundTransparency = 1
content.Parent = main

local pageTitle = Instance.new("TextLabel")
pageTitle.Size = UDim2.new(1, 0, 0, 28)
pageTitle.BackgroundTransparency = 1
pageTitle.Text = "Brainrots"
pageTitle.TextColor3 = COLORS.text
pageTitle.TextSize = 18
pageTitle.Font = Enum.Font.GothamBold
pageTitle.TextXAlignment = Enum.TextXAlignment.Left
pageTitle.Parent = content

local search = Instance.new("TextBox")
search.Position = UDim2.fromOffset(0, 34)
search.Size = UDim2.new(1, 0, 0, 34)
search.BackgroundColor3 = COLORS.panel
search.BorderSizePixel = 0
search.PlaceholderText = "Search..."
search.Text = ""
search.ClearTextOnFocus = false
search.TextColor3 = COLORS.text
search.PlaceholderColor3 = COLORS.muted
search.Font = Enum.Font.Gotham
search.TextSize = 13
search.Parent = content

Instance.new("UICorner", search).CornerRadius = UDim.new(0, 8)

local searchStroke = Instance.new("UIStroke")
searchStroke.Color = COLORS.accent
searchStroke.Transparency = 0.85
searchStroke.Parent = search

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(0, 77)
list.Size = UDim2.new(1, 0, 1, -77)
list.BackgroundColor3 = COLORS.sidebar
list.BorderSizePixel = 0
list.ScrollBarThickness = 4
list.ScrollBarImageColor3 = COLORS.accent
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = content

Instance.new("UICorner", list).CornerRadius = UDim.new(0, 9)

local listStroke = Instance.new("UIStroke")
listStroke.Color = Color3.fromRGB(50, 53, 72)
listStroke.Transparency = 0.4
listStroke.Parent = list

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = list

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.PaddingLeft = UDim.new(0, 8)
padding.PaddingRight = UDim.new(0, 8)
padding.Parent = list

local currentTab = "Brainrots"
local autofarmEnabled = false
local renderPage
local tabButtons = {}

local function clearList()
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
end

local function addEntry(name, detail, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -2, 0, 49)
    button.BackgroundColor3 = COLORS.entry
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = list

    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

    local entryStroke = Instance.new("UIStroke")
    entryStroke.Color = Color3.fromRGB(60, 64, 87)
    entryStroke.Transparency = 0.78
    entryStroke.Parent = button

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Position = UDim2.fromOffset(10, 5)
    nameLabel.Size = UDim2.new(1, -20, 0, 19)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = name
    nameLabel.TextColor3 = COLORS.text
    nameLabel.Font = Enum.Font.GothamSemibold
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = button

    local detailLabel = Instance.new("TextLabel")
    detailLabel.Position = UDim2.fromOffset(10, 25)
    detailLabel.Size = UDim2.new(1, -20, 0, 16)
    detailLabel.BackgroundTransparency = 1
    detailLabel.Text = detail
    detailLabel.TextColor3 = COLORS.muted
    detailLabel.Font = Enum.Font.Gotham
    detailLabel.TextSize = 11
    detailLabel.TextXAlignment = Enum.TextXAlignment.Left
    detailLabel.TextTruncate = Enum.TextTruncate.AtEnd
    detailLabel.Parent = button

    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.12), {
            BackgroundColor3 = COLORS.entryHover,
        }):Play()
        entryStroke.Transparency = 0.35
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.12), {
            BackgroundColor3 = COLORS.entry,
        }):Play()
        entryStroke.Transparency = 0.78
    end)

    button.MouseButton1Click:Connect(callback)
end

local function addMessage(message)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -4, 0, 48)
    label.BackgroundTransparency = 1
    label.Text = message
    label.TextWrapped = true
    label.TextColor3 = COLORS.muted
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.Parent = list
end

local function matchesSearch(name, detail)
    local query = search.Text:lower()

    return query == ""
        or name:lower():find(query, 1, true) ~= nil
        or detail:lower():find(query, 1, true) ~= nil
end

local function renderBrainrots()
    local brainrots = getBrainrots()
    local shown = 0

    for _, object in ipairs(brainrots) do
        if isCurrentBrainrot(object) then
            local rarity = getRarity(object)

            if matchesSearch(object.Name, rarity) then
                shown += 1

                addEntry(object.Name, rarity, function()
                    if not isCurrentBrainrot(object) then
                        renderPage()
                        return
                    end

                    if not teleportTo(object) then
                        renderPage()
                    end
                end)
            end
        end
    end

    if shown == 0 then
        if #brainrots == 0 then
            addMessage('No Brainrots found. Check the "Brainrots" folder.')
        else
            addMessage("No matching Brainrots are currently available.")
        end
    end
end

local function renderBases()
    local bases = getBases()

    if #bases == 0 then
        addMessage('No bases found. Check the "Bases" folder.')
        return
    end

    for fallbackIndex, base in ipairs(bases) do
        local owner = getBaseOwner(base)
        local actualNumber = getBaseNumber(base)
        local number = actualNumber or fallbackIndex
        local baseLabel = "Base #" .. tostring(number)
        local playerName = owner or "Empty base"

        if matchesSearch(playerName, baseLabel) then
            addEntry(playerName, baseLabel, function()
                if base.Parent then
                    teleportTo(base)
                end
            end)
        end
    end
end

local function renderZones()
    local zones = getZones()

    if #zones == 0 then
        addMessage('No zones found. Check the "Zones" folder.')
        return
    end

    for _, zone in ipairs(zones) do
        if matchesSearch(zone.Name, "Zone") then
            addEntry(zone.Name, "Teleport to zone", function()
                if zone.Parent then
                    teleportTo(zone)
                end
            end)
        end
    end
end

local function renderAutofarm()
    addMessage(
        "Collects available Brainrots, returns to your base, " ..
        "then unequips the held Tool."
    )

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(1, -4, 0, 45)
    toggle.BackgroundColor3 = autofarmEnabled and COLORS.red or COLORS.green
    toggle.BorderSizePixel = 0
    toggle.Text = autofarmEnabled and "Stop Autofarm" or "Start Autofarm"
    toggle.TextColor3 = Color3.new(1, 1, 1)
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 14
    toggle.AutoButtonColor = true
    toggle.Parent = list

    Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 8)

    toggle.MouseButton1Click:Connect(function()
        autofarmEnabled = not autofarmEnabled
        renderPage()
    end)
end

renderPage = function()
    clearList()
    pageTitle.Text = currentTab
    search.Visible = currentTab ~= "Autofarm"

    -- Keep the active tab visually highlighted.
    for tabName, tabButton in pairs(tabButtons) do
        if tabButton and tabButton.Parent then
            tabButton.BackgroundColor3 = tabName == currentTab
                and COLORS.accentDark
                or COLORS.panel
        end
    end

    if currentTab == "Brainrots" then
        renderBrainrots()
    elseif currentTab == "Bases" then
        renderBases()
    elseif currentTab == "Zones" then
        renderZones()
    elseif currentTab == "Autofarm" then
        renderAutofarm()
    end
end

-- Tabs
for index, tabName in ipairs({
    "Brainrots",
    "Bases",
    "Zones",
    "Autofarm",
}) do
    local tab = Instance.new("TextButton")
    tab.Position = UDim2.fromOffset(0, 10 + (index - 1) * 46)
    tab.Size = UDim2.new(1, 0, 0, 39)
    tab.BackgroundColor3 = COLORS.panel
    tab.BorderSizePixel = 0
    tab.Text = tabName
    tab.TextColor3 = COLORS.text
    tab.Font = Enum.Font.GothamSemibold
    tab.TextSize = 13
    tab.AutoButtonColor = false
    tab.Parent = sidebar

    Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 8)

    tabButtons[tabName] = tab

    tab.MouseEnter:Connect(function()
        if currentTab ~= tabName then
            TweenService:Create(tab, TweenInfo.new(0.12), {
                BackgroundColor3 = COLORS.entryHover,
            }):Play()
        end
    end)

    tab.MouseLeave:Connect(function()
        tab.BackgroundColor3 = currentTab == tabName
            and COLORS.accentDark
            or COLORS.panel
    end)

    tab.MouseButton1Click:Connect(function()
        currentTab = tabName
        renderPage()
    end)
end

search:GetPropertyChangedSignal("Text"):Connect(function()
    if currentTab ~= "Autofarm" then
        renderPage()
    end
end)

-- Live refresh for Brainrots and Bases.
-- Bases are re-read each refresh so player departures and arrivals
-- update owner names without changing tabs.
task.spawn(function()
    while gui.Parent do
        task.wait(REFRESH_INTERVAL)

        if gui.Parent and main.Visible
            and (currentTab == "Brainrots" or currentTab == "Bases") then
            renderPage()
        end
    end
end)

-- Drag window
do
    local dragging = false
    local dragStart
    local startPosition

    top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPosition = main.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart

            main.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

closeButton.MouseEnter:Connect(function()
    TweenService:Create(closeButton, TweenInfo.new(0.12), {
        BackgroundColor3 = Color3.fromRGB(205, 70, 86),
    }):Play()
end)

closeButton.MouseLeave:Connect(function()
    closeButton.BackgroundColor3 = COLORS.red
end)

closeButton.MouseButton1Click:Connect(function()
    main.Visible = false
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == TOGGLE_KEY then
        main.Visible = not main.Visible

        if main.Visible then
            renderPage()
        end
    end
end)

renderPage()

-- Autofarm loop
task.spawn(function()
    while gui.Parent do
        if not autofarmEnabled then
            task.wait(0.25)
            continue
        end

        local collectedSomething = false

        for _, brainrot in ipairs(getBrainrots()) do
            if not autofarmEnabled then
                break
            end

            if not isCurrentBrainrot(brainrot) then
                continue
            end

            local prompt = findPrompt(brainrot)

            if not prompt or not prompt.Enabled or not prompt.Parent then
                continue
            end

            if not teleportTo(prompt.Parent) then
                continue
            end

            task.wait(0.25)

            if isCurrentBrainrot(brainrot)
                and prompt.Parent
                and prompt.Enabled then

                pcall(function()
                    prompt:InputHoldBegin()
                end)

                task.wait(math.max(prompt.HoldDuration, 0.1))

                pcall(function()
                    prompt:InputHoldEnd()
                end)
            end

            task.wait(0.5)

            local base = findMyBase()

            if base and base.Parent then
                teleportTo(base)
                task.wait(0.25)
                unequipTools()
                task.wait(0.25)
            end

            collectedSomething = true
            break
        end

        if not collectedSomething then
            task.wait(1)
        end
    end
end)
