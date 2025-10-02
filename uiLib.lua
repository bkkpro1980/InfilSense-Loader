-- ============================================================================
-- INFILSENSE LIBRARY - FULLY REFACTORED
-- Developed by bkkpro1980
-- ============================================================================

--!nolint UnknownGlobal
--!nocheck

local module = {}
module.__index = module

-- ============================================================================
-- SERVICES & UTILITIES
-- ============================================================================

cloneref = cloneref or clonereference or function(v) return v end
local CAS = cloneref(game:GetService("ContextActionService"))
local UIS = cloneref(game:GetService("UserInputService"))
local COREGUI = cloneref(game:GetService("CoreGui"))
local TS = cloneref(game:GetService("TweenService"))
local HttpService = cloneref(game:GetService("HttpService"))

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local Constants = {
    TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
    TWEEN_INFO_QUAD = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TIMEOUT_KEYBIND = 5,
}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local function randomString()
    local length = math.random(10, 20)
    local array = {}
    for i = 1, length do
        array[i] = string.char(math.random(32, 126))
    end
    return table.concat(array)
end

local function isValidKey(keyText)
    keyText = keyText:gsub("Enum.KeyCode.", "")
    return pcall(function()
        return Enum.KeyCode[keyText] ~= nil
    end)
end

local function stringToKeyCode(str)
    local keyName = str:gsub("Enum.KeyCode.", "")
    return Enum.KeyCode[keyName]
end

-- ============================================================================
-- STATE MANAGEMENT
-- ============================================================================

local State = {
    libName = "Unnamed Script",
    version = "Unknown Version",
    saveFolder = "",
    saveFileName = "unnamed",
    nameId = "unnamed",
    
    -- UI References
    mainGui = nil,
    container = nil,
    background = nil,
    scrollFrame = nil,
    closeButton = nil,
    headers = nil,
    nextPrev = nil,
    selectFrame = nil,
    selectScrollFrame = nil,
    selectClose = nil,
    quickcmdUI = nil,
    
    -- State
    pageNum = 1,
    lastPageNum = 1,
    pagesAmount = 0,
    uiPages = {},
    values = {},
    savedData = {},
    guiClosed = false,
    selectClosed = true,
    quickcmdList = {},
    quickcmdListOrder = {},
    quickcmdActive = false,
    quickcmdDB = false,
    
    -- Tweens
    activeTweens = {}
}

-- ============================================================================
-- CONFIG MANAGER
-- ============================================================================

local ConfigManager = {}

function ConfigManager.getPath()
    local folder = State.saveFolder ~= "" and State.saveFolder .. "/" or ""
    return folder .. State.saveFileName .. ".json"
end

function ConfigManager.getDefault()
    return {
        Startup = {},
        Keybinds = {},
        Settings = {},
        MenuToggle = "RightShift"
    }
end

function ConfigManager.save(config)
    local success, encoded = pcall(HttpService.JSONEncode, HttpService, config)
    if not success then return false end
    
    local writeSuccess = pcall(writefile, ConfigManager.getPath(), encoded)
    return writeSuccess
end

function ConfigManager.load()
    if not isfile(ConfigManager.getPath()) then
        return ConfigManager.getDefault()
    end
    
    local success, content = pcall(readfile, ConfigManager.getPath())
    if not success then
        return ConfigManager.getDefault()
    end
    
    local decodeSuccess, decoded = pcall(HttpService.JSONDecode, HttpService, content)
    if not decodeSuccess then
        return ConfigManager.getDefault()
    end
    
    return decoded
end

function ConfigManager.set(key, value, dict)
    if not isfile(ConfigManager.getPath()) then
        ConfigManager.save(ConfigManager.getDefault())
    end
    
    local config = ConfigManager.load()
    
    if dict then
        config[dict] = config[dict] or {}
        config[dict][key] = value
    else
        config[key] = value
    end
    
    return ConfigManager.save(config)
end

function ConfigManager.remove(key, dict)
    if not isfile(ConfigManager.getPath()) then
        return false
    end
    
    local config = ConfigManager.load()
    
    if dict then
        if config[dict] then
            config[dict][key] = nil
        end
    else
        config[key] = nil
    end
    
    return ConfigManager.save(config)
end

function ConfigManager.get(dict)
    if not isfile(ConfigManager.getPath()) then
        return {}
    end
    
    local config = ConfigManager.load()
    return dict and (config[dict] or {}) or config
end

function ConfigManager.clear()
    ConfigManager.save(ConfigManager.getDefault())
    return ConfigManager.getDefault()
end

-- ============================================================================
-- KEYBIND MANAGER
-- ============================================================================

local KeybindManager = {}

function KeybindManager.bind(command, func, key)
    if not command or not func or not key then
        return false
    end
    
    ConfigManager.set(command, key.Name, "Keybinds")
    CAS:UnbindAction(command)
    
    CAS:BindAction(
        command,
        function(actionName, inputState, inputObject)
            if inputState == Enum.UserInputState.End then
                State.values[command] = not State.values[command]
                func(State.values[command], true)
            end
        end,
        false,
        key
    )
    
    return true
end

function KeybindManager.unbind(command)
    ConfigManager.remove(command, "Keybinds")
    CAS:UnbindAction(command)
    return true
end

function KeybindManager.capture(command, func, label)
    label.Text = "Press a key... (Click to unbind)"
    local captureStart = tick()
    local connection
    
    connection = UIS.InputBegan:Connect(function(input)
        if tick() - captureStart > Constants.TIMEOUT_KEYBIND then
            label.Text = "Capture Timed Out"
            connection:Disconnect()
            return
        end
        
        if input.UserInputType == Enum.UserInputType.Keyboard then
            KeybindManager.bind(command, func, input.KeyCode)
            label.Text = "Bound to: " .. input.KeyCode.Name
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 or 
               input.UserInputType == Enum.UserInputType.MouseButton2 then
            KeybindManager.unbind(command)
            label.Text = "Click to set a keybind"
        else
            label.Text = "Invalid Input!"
            task.delay(1.5, function()
                label.Text = "Click to set a keybind"
            end)
        end
        
        connection:Disconnect()
    end)
    
    task.delay(Constants.TIMEOUT_KEYBIND, function()
        if connection and connection.Connected then
            label.Text = "Capture Timed Out"
            task.delay(1.5, function()
                label.Text = "Click to set a keybind"
            end)
            connection:Disconnect()
        end
    end)
end

-- ============================================================================
-- UI BUILDER UTILITIES
-- ============================================================================

local UIBuilder = {}

function UIBuilder.createInstance(className, properties)
    local instance = Instance.new(className)
    for prop, value in pairs(properties) do
        instance[prop] = value
    end
    return instance
end

function UIBuilder.applyPadding(parent, bottom, left, right, top)
    local padding = Instance.new("UIPadding")
    padding.PaddingBottom = UDim.new(0, bottom)
    padding.PaddingLeft = UDim.new(0, left)
    padding.PaddingRight = UDim.new(0, right)
    padding.PaddingTop = UDim.new(0, top)
    padding.Parent = parent
    return padding
end

function UIBuilder.createStroke(parent, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.LineJoinMode = Enum.LineJoinMode.Miter
    stroke.Thickness = thickness or 0
    stroke.Transparency = 0.8
    stroke.Parent = parent
    return stroke
end

function UIBuilder.setupHoverEffects(button)
    button.MouseEnter:Connect(function()
        TS:Create(button, Constants.TWEEN_INFO, {BackgroundTransparency = 0.95}):Play()
        if button:FindFirstChild("stroke") then
            TS:Create(button.stroke, Constants.TWEEN_INFO, {Thickness = 2}):Play()
        end
    end)
    
    button.MouseLeave:Connect(function()
        TS:Create(button, Constants.TWEEN_INFO, {BackgroundTransparency = 0.9}):Play()
        if button:FindFirstChild("stroke") then
            TS:Create(button.stroke, Constants.TWEEN_INFO, {Thickness = 0}):Play()
        end
    end)
    
    button.MouseButton1Down:Connect(function()
        TS:Create(button, Constants.TWEEN_INFO, {BackgroundTransparency = 0.7}):Play()
        if button:FindFirstChild("stroke") then
            TS:Create(button.stroke, Constants.TWEEN_INFO, {Thickness = 3}):Play()
        end
    end)
    
    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            TS:Create(button, Constants.TWEEN_INFO, {BackgroundTransparency = 0.9}):Play()
            if button:FindFirstChild("stroke") then
                TS:Create(button.stroke, Constants.TWEEN_INFO, {Thickness = 0}):Play()
            end
        end
    end)
end

-- ============================================================================
-- GUI MANAGER
-- ============================================================================

local GUIManager = {}

function GUIManager.toggle(showBackground, override)
    if State.guiClosed then
        if State.activeTweens.container then
            State.activeTweens.container:Cancel()
        end
        if State.activeTweens.background then
            State.activeTweens.background:Cancel()
        end
        
        State.activeTweens.container = TS:Create(State.container, Constants.TWEEN_INFO, 
            {Position = UDim2.new(0.5, 0, 0.5, 0)})
        State.activeTweens.container:Play()
        
        if showBackground ~= false then
            State.activeTweens.background = TS:Create(State.background, Constants.TWEEN_INFO, 
                {Position = UDim2.new(0.5, 0, 0.5, 0)})
            State.activeTweens.background:Play()
        end
        
        State.guiClosed = false
        State.closeButton.Modal = true
    else
        if State.activeTweens.container then
            State.activeTweens.container:Cancel()
        end
        if State.activeTweens.background then
            State.activeTweens.background:Cancel()
        end
        
        State.activeTweens.container = TS:Create(State.container, Constants.TWEEN_INFO, 
            {Position = UDim2.new(0.5, 0, -0.5, 0)})
        State.activeTweens.container:Play()
        
        if showBackground ~= false then
            State.activeTweens.background = TS:Create(State.background, Constants.TWEEN_INFO, 
                {Position = UDim2.new(0.5, 0, -0.5, 0)})
            State.activeTweens.background:Play()
        end
        
        State.guiClosed = true
        State.closeButton.Modal = false
    end
end

function GUIManager.toggleSelection(labelText)
    if not State.selectFrame or not State.selectClose then
        return
    end
    
    local label = State.selectFrame:FindFirstChild("top") and 
                  State.selectFrame.top:FindFirstChild("label")
    
    if State.selectClosed then
        if label then
            label.Text = labelText
        end
        
        local tween = TS:Create(State.selectFrame, Constants.TWEEN_INFO, 
            {Position = UDim2.new(0.5, 0, 0.5, 0)})
        tween:Play()
        
        State.selectClosed = false
        State.selectClose.Modal = true
    else
        local tween = TS:Create(State.selectFrame, Constants.TWEEN_INFO, 
            {Position = UDim2.new(0.5, 0, -0.5, 0)})
        tween:Play()
        
        State.selectClosed = true
        State.selectClose.Modal = false
    end
end

function GUIManager.clearSelectionButtons()
    if not State.selectScrollFrame then return end
    
    for _, button in ipairs(State.selectScrollFrame:GetChildren()) do
        if button:IsA("ImageButton") then
            button:Destroy()
        end
    end
end

function GUIManager.createSelectionButtons(options, valueInstance)
    for label, value in pairs(options) do
        local button = UIBuilder.createInstance("ImageButton", {
            Name = "Button",
            Parent = State.selectScrollFrame,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(26, 26, 26),
            BackgroundTransparency = 0.9,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 40),
            AutoButtonColor = false
        })
        
        UIBuilder.applyPadding(button, 10, 20, 20, 10)
        UIBuilder.createStroke(button)
        
        local _ = UIBuilder.createInstance("TextLabel", {
            Name = "label",
            Parent = button,
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(0.5, 0, 1, 0),
            Font = Enum.Font.Montserrat,
            Text = label,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 18,
            TextTransparency = 0.1,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        
        local _ = UIBuilder.createInstance("TextLabel", {
            Name = "valueDisplay",
            Parent = button,
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0.5, 0, 1, 0),
            Font = Enum.Font.Montserrat,
            Text = tostring(value),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 14,
            TextTransparency = 0.1,
            TextXAlignment = Enum.TextXAlignment.Right
        })
        
        UIBuilder.setupHoverEffects(button)
        
        button.Activated:Connect(function()
            valueInstance.Value = value
            GUIManager.toggle(false)
            GUIManager.toggleSelection()
            GUIManager.clearSelectionButtons()
        end)
    end
end

function GUIManager.updatePageButtons()
    local currentPage = State.nextPrev and State.nextPrev:FindFirstChild("UIPageLayout") and 
                       State.nextPrev.UIPageLayout.CurrentPage
    
    if not currentPage then return end
    
    local nextButton = currentPage:FindFirstChild("2")
    local prevButton = currentPage:FindFirstChild("1")
    
    if State.pageNum == 1 then
        if prevButton then prevButton.Visible = false end
        if nextButton then
            nextButton.Size = UDim2.new(0.2, 420, 0, 50)
            nextButton.Visible = true
            if nextButton:FindFirstChild("label") then
                nextButton.label.Text = "Next Page (" .. (State.pageNum + 1) .. ")"
            end
        end
    elseif State.pageNum == State.lastPageNum then
        if nextButton then nextButton.Visible = false end
        if prevButton then
            prevButton.Size = UDim2.new(0.2, 420, 0, 50)
            prevButton.Visible = true
            if prevButton:FindFirstChild("label") then
                prevButton.label.Text = "Previous Page (" .. (State.pageNum - 1) .. ")"
            end
        end
    else
        if nextButton and prevButton then
            nextButton.Size = UDim2.new(0.2, 120, 0, 50)
            prevButton.Size = UDim2.new(0.2, 120, 0, 50)
            nextButton.Visible = true
            prevButton.Visible = true
            if nextButton:FindFirstChild("label") then
                nextButton.label.Text = "Next Page (" .. (State.pageNum + 1) .. ")"
            end
            if prevButton:FindFirstChild("label") then
                prevButton.label.Text = "Previous Page (" .. (State.pageNum - 1) .. ")"
            end
        end
    end
end

-- ============================================================================
-- QUICK COMMAND SYSTEM
-- ============================================================================

local QuickCommand = {}

function QuickCommand.toggle(value, binded)
    if State.quickcmdDB then return end
    
    if binded then
        if not State.quickcmdActive or not State.quickcmdUI or not State.quickcmdUI:FindFirstChild("text") then
            return
        end
        State.quickcmdDB = true
        TS:Create(State.quickcmdUI, Constants.TWEEN_INFO_QUAD, 
            {Position = UDim2.new(0.5, 0, 0, 5)}):Play()
        State.quickcmdUI.text:CaptureFocus()
        return
    end
    
    if type(value) ~= "boolean" then return end
    State.quickcmdActive = value
end

function QuickCommand.process(text)
    local parts = string.split(text, " ")
    local rawCmd = parts[1]
    local cmdKey = State.quickcmdList[tonumber(rawCmd)] and tonumber(rawCmd) or string.lower(rawCmd)
    
    if State.quickcmdList[cmdKey] then
        table.remove(parts, 1)
        
        local toggleKey = State.quickcmdList[cmdKey][3]
        State.values[toggleKey] = not State.values[toggleKey]
        
        local func = State.quickcmdList[cmdKey][1]
        if #parts > 0 then
            func(unpack(parts))
        else
            func(State.values[toggleKey])
        end
        
        return true
    end
    
    return false
end

-- ============================================================================
-- COMPONENT CREATORS
-- ============================================================================

local ComponentFactory = {}

function ComponentFactory.validateArgs(buttonInfo, commandFunc, otherInfo, mainPage)
    if type(buttonInfo) ~= "table" then
        warn("[" .. State.libName .. "]: Invalid buttonInfo")
        return false
    end
    
    if type(commandFunc) ~= "function" then
        warn("[" .. State.libName .. "]: Invalid commandFunc")
        return false
    end
    
    if type(otherInfo) ~= "table" then
        warn("[" .. State.libName .. "]: Invalid otherInfo")
        return false
    end
    
    if not mainPage then
        warn("[" .. State.libName .. "]: Invalid mainPage")
        return false
    end
    
    return true
end

function ComponentFactory.ensureUniqueCommand(otherInfo)
    local command = otherInfo.UniqueCommandId
    if not command or type(command) ~= "string" or command == "" or State.values[command] then
        repeat
            command = randomString()
        until State.values[command] == nil
        otherInfo.UniqueCommandId = command
    end
    return command
end

function ComponentFactory.registerQuickCommands(cmdList, func, title, command)
    if type(cmdList) ~= "table" then return end
    
    for _, cmd in ipairs(cmdList) do
        State.quickcmdList[cmd] = {func, title, command}
        table.insert(State.quickcmdListOrder, cmd)
    end
end

function ComponentFactory.createBaseButton(mainPage, buttonInfo)
    local button = UIBuilder.createInstance("ImageButton", {
        Name = "Button",
        Parent = mainPage,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        Size = UDim2.new(0.2, 420, 0, 50),
        AutoButtonColor = false,
        LayoutOrder = #mainPage:GetChildren()
    })
    
    UIBuilder.applyPadding(button, 10, 20, 20, 10)
    UIBuilder.createStroke(button)
    
    local label = UIBuilder.createInstance("TextLabel", {
        Name = "label",
        Parent = button,
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0.25, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Font = Enum.Font.Montserrat,
        Text = buttonInfo.Title or "Title",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 18,
        TextTransparency = 0.1,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local desc = UIBuilder.createInstance("TextLabel", {
        Name = "desc",
        Parent = button,
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0.8, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Font = Enum.Font.Montserrat,
        Text = buttonInfo.Desc or "Description",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        TextTransparency = 0.1,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    UIBuilder.setupHoverEffects(button)
    
    return button, label, desc
end

function ComponentFactory.addStartupButton(button, command, func)
    local startup = UIBuilder.createInstance("ImageButton", {
        Name = "startup",
        Parent = button,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        Position = UDim2.new(-0.141, 0, -0.333, 0),
        Size = UDim2.new(0.09, 0, 1.667, 0),
        ImageTransparency = 1
    })
    
    UIBuilder.createStroke(startup)
    
    local img = UIBuilder.createInstance("ImageLabel", {
        Name = "image",
        Parent = startup,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.4, 0),
        Size = UDim2.new(0.5, 0, 0.5, 0),
        Image = "rbxassetid://14187539043"
    })
    
    Instance.new("UIAspectRatioConstraint").Parent = img
    
    UIBuilder.createInstance("TextLabel", {
        Name = "label",
        Parent = startup,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.8, 0),
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.Montserrat,
        Text = "Startup?",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 11
    })
    
    -- Load saved state
    if State.savedData.Startup and State.savedData.Startup[command] then
        img.Image = "rbxassetid://14187538370"
        task.spawn(function()
            func(State.values[command])
        end)
    end
    
    UIBuilder.setupHoverEffects(startup)
    
    startup.Activated:Connect(function()
        local config = ConfigManager.get("Startup")
        local isEnabled = config[command]
        
        if not isEnabled then
            ConfigManager.set(command, true, "Startup")
            img.Image = "rbxassetid://14187538370"
        else
            ConfigManager.remove(command, "Startup")
            img.Image = "rbxassetid://14187539043"
        end
    end)
end

function ComponentFactory.addKeybindButton(button, command, func)
    local keybind = UIBuilder.createInstance("ImageButton", {
        Name = "keybind",
        Parent = button,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        Position = UDim2.new(1.052, 0, -0.366, 0),
        Size = UDim2.new(0.09, 0, 1.666, 0),
        ImageTransparency = 1
    })
    
    UIBuilder.createStroke(keybind)
    
    local label = UIBuilder.createInstance("TextLabel", {
        Name = "label",
        Parent = keybind,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.Montserrat,
        Text = "Click to set a keybind",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 11,
        TextWrapped = true
    })
    
    Instance.new("UIAspectRatioConstraint").Parent = label
    
    -- Load saved keybind
    if State.savedData.Keybinds and State.savedData.Keybinds[command] then
        local keyText = State.savedData.Keybinds[command]
        if isValidKey(keyText) then
            label.Text = "Bound to: " .. keyText
            KeybindManager.bind(command, func, stringToKeyCode(keyText))
        end
    end
    
    UIBuilder.setupHoverEffects(keybind)
    
    keybind.Activated:Connect(function()
        KeybindManager.capture(command, func, label)
    end)
end

function ComponentFactory.createButton(buttonInfo, commandFunc, otherInfo, mainPage, quickCmds)
    if not ComponentFactory.validateArgs(buttonInfo, commandFunc, otherInfo, mainPage) then
        return
    end
    
    local command = ComponentFactory.ensureUniqueCommand(otherInfo)
    ComponentFactory.registerQuickCommands(quickCmds, commandFunc, buttonInfo.Title, command)
    
    local button = ComponentFactory.createBaseButton(mainPage, buttonInfo)
    
    UIBuilder.createInstance("TextLabel", {
        Name = "value",
        Parent = button,
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Font = Enum.Font.Montserrat,
        Text = buttonInfo.Action or "Action",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 18,
        TextTransparency = 0.5,
        TextXAlignment = Enum.TextXAlignment.Right
    })
    
    State.values[command] = false
    
    button.Activated:Connect(function()
        State.values[command] = not State.values[command]
        commandFunc(State.values[command])
    end)
    
    if otherInfo.StartupAvailable then
        ComponentFactory.addStartupButton(button, command, commandFunc)
    end
    
    if otherInfo.Bindable then
        ComponentFactory.addKeybindButton(button, command, commandFunc)
    end
    
    return {
        getValue = function() return State.values[command] end,
        getId = function() return command end,
        getFunc = function() return commandFunc end
    }
end

function ComponentFactory.createTextBox(buttonInfo, commandFunc, otherInfo, mainPage, quickCmds)
    if not ComponentFactory.validateArgs(buttonInfo, commandFunc, otherInfo, mainPage) then
        return
    end
    
    local command = ComponentFactory.ensureUniqueCommand(otherInfo)
    ComponentFactory.registerQuickCommands(quickCmds, commandFunc, buttonInfo.Title, command)
    
    local button = ComponentFactory.createBaseButton(mainPage, buttonInfo)
    
    local textbox = UIBuilder.createInstance("TextBox", {
        Name = "textbox",
        Parent = button,
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0.3, 0, 1, 0),
        Font = Enum.Font.Montserrat,
        PlaceholderColor3 = Color3.fromRGB(178, 178, 178),
        PlaceholderText = buttonInfo.Action or "Enter text...",
        Text = "",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Right
    })
    
    button.Activated:Connect(function()
        if textbox.Text ~= "" then
            commandFunc(textbox.Text)
        end
    end)
    
    textbox.FocusLost:Connect(function()
        if textbox.Text ~= "" then
            commandFunc(textbox.Text)
        end
    end)
    
    if otherInfo.StartupAvailable then
        ComponentFactory.addStartupButton(button, command, commandFunc)
    end
    
    if otherInfo.Bindable then
        ComponentFactory.addKeybindButton(button, command, commandFunc)
    end
    
    return {
        getValue = function() return textbox.Text end,
        getId = function() return command end,
        getFunc = function() return commandFunc end
    }
end

function ComponentFactory.createSelection(buttonInfo, commandFunc, otherInfo, mainPage, options, quickCmds)
    if not ComponentFactory.validateArgs(buttonInfo, commandFunc, otherInfo, mainPage) then
        return
    end
    
    if type(options) ~= "table" then
        warn("[" .. State.libName .. "]: Invalid options table")
        return
    end
    
    local command = ComponentFactory.ensureUniqueCommand(otherInfo)
    ComponentFactory.registerQuickCommands(quickCmds, commandFunc, buttonInfo.Title, command)
    
    local button = ComponentFactory.createBaseButton(mainPage, buttonInfo)
    
    local valueButton = UIBuilder.createInstance("ImageButton", {
        Name = "value",
        Parent = button,
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0.5, 0, 1, 15),
        ImageTransparency = 1
    })
    
    local valueLabel = UIBuilder.createInstance("TextLabel", {
        Name = "value",
        Parent = valueButton,
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.Montserrat,
        Text = buttonInfo.Action or "Select...",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 18,
        TextTransparency = 0.5,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Right
    })
    
    local selectedValue = UIBuilder.createInstance("StringValue", {
        Name = "selected",
        Parent = valueButton,
        Value = ""
    })
    
    selectedValue.Changed:Connect(function()
        valueLabel.Text = selectedValue.Value
        State.values[command] = selectedValue.Value
    end)
    
    button.Activated:Connect(function()
        commandFunc(selectedValue.Value)
    end)
    
    valueButton.Activated:Connect(function()
        GUIManager.createSelectionButtons(options, selectedValue)
        GUIManager.toggle(false)
        GUIManager.toggleSelection(buttonInfo.Title)
    end)
    
    return {
        getValue = function() return State.values[command] end,
        getId = function() return command end,
        getFunc = function() return commandFunc end
    }
end

function ComponentFactory.createSlider(buttonInfo, commandFunc, otherInfo, mainPage, settings, quickCmds)
    if not ComponentFactory.validateArgs(buttonInfo, commandFunc, otherInfo, mainPage) then
        return
    end
    
    if type(settings) ~= "table" then
        warn("[" .. State.libName .. "]: Invalid settings table")
        return
    end
    
    local sliderType = settings.sliderType
    local defVal = settings.defVal
    local lowVal = settings.lowVal
    local maxVal = settings.maxVal
    local shouldSave = settings.save
    
    if not (defVal and lowVal and maxVal) then
        warn("[" .. State.libName .. "]: Missing slider values")
        return
    end
    
    local command = ComponentFactory.ensureUniqueCommand(otherInfo)
    ComponentFactory.registerQuickCommands(quickCmds, commandFunc, buttonInfo.Title, command)
    
    local button = ComponentFactory.createBaseButton(mainPage, buttonInfo)
    local label = button:FindFirstChild("label")
    local desc = button:FindFirstChild("desc")
    
    -- Update label position for slider
    if label then
        label.Position = UDim2.new(0, 0, 0.25, 0)
    end
    
    if desc then
        desc.AnchorPoint = Vector2.new(1, 0.5)
        desc.Position = UDim2.new(1, 0, 0.3, 0)
        desc.TextXAlignment = Enum.TextXAlignment.Right
    end
    
    local sliderTrack = UIBuilder.createInstance("Frame", {
        Name = "slider",
        Parent = button,
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 2)
    })
    
    local sliderThumb = UIBuilder.createInstance("ImageButton", {
        Name = "thumb",
        Parent = sliderTrack,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 20, 0, 15),
        Position = UDim2.new((defVal - lowVal) / (maxVal - lowVal), 0, 0.5, 0),
        Image = "",
        ImageTransparency = 1
    })
    
    local value = defVal
    
    -- Load saved value
    if shouldSave and State.savedData.Settings and State.savedData.Settings[command] ~= nil then
        value = State.savedData.Settings[command]
        local percent = sliderType == "bool" and (value and 1 or 0) or 
                       math.clamp((value - lowVal) / (maxVal - lowVal), 0, 1)
        sliderThumb.Position = UDim2.new(percent, 0, 0.5, 0)
    end
    
    if label then
        label.Text = buttonInfo.Title .. ": " .. 
                    (sliderType == "bool" and tostring(value) or string.format("%.2f", value))
    end
    
    State.values[command] = value
    
    -- Call function on startup if enabled
    if otherInfo.StartupAvailable then
        commandFunc(value)
    end
    
    -- Slider logic
    local isDragging = false
    local moveConn, releaseConn, renderConn
    
    local function getValue(percent)
        if sliderType == "bool" then
            return percent > 0.5
        else
            local raw = lowVal + (maxVal - lowVal) * percent
            return math.clamp(math.floor(raw + 0.5), lowVal, maxVal)
        end
    end
    
    local function updateSlider(mouseX)
        local relativeX = math.clamp(mouseX - sliderTrack.AbsolutePosition.X, 0, sliderTrack.AbsoluteSize.X)
        local percent = relativeX / sliderTrack.AbsoluteSize.X
        local newValue = getValue(percent)
        
        State.values[command] = newValue
        
        if label then
            label.Text = buttonInfo.Title .. ": " .. 
                        (sliderType == "bool" and tostring(newValue) or string.format("%.2f", newValue))
        end
        
        return percent, newValue
    end
    
    sliderThumb.MouseButton1Down:Connect(function()
        isDragging = true
        
        TS:Create(button, Constants.TWEEN_INFO, {BackgroundTransparency = 0.7}):Play()
        if button:FindFirstChild("stroke") then
            TS:Create(button.stroke, Constants.TWEEN_INFO, {Thickness = 3}):Play()
        end
        
        local targetPos = sliderThumb.Position
        
        moveConn = UIS.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement and isDragging then
                local percent, newValue = updateSlider(input.Position.X)
                value = newValue
                targetPos = UDim2.new(percent, 0, 0.5, 0)
            end
        end)
        
        releaseConn = UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and isDragging then
                isDragging = false
                
                TS:Create(button, Constants.TWEEN_INFO, {BackgroundTransparency = 0.9}):Play()
                if button:FindFirstChild("stroke") then
                    TS:Create(button.stroke, Constants.TWEEN_INFO, {Thickness = 0}):Play()
                end
                
                if moveConn then moveConn:Disconnect() end
                if releaseConn then releaseConn:Disconnect() end
                if renderConn then renderConn:Disconnect() end
                
                if shouldSave then
                    ConfigManager.set(command, value, "Settings")
                end
                
                commandFunc(value)
                
                local finalPercent = sliderType == "bool" and (value and 1 or 0) or
                                    (value - lowVal) / (maxVal - lowVal)
                TS:Create(sliderThumb, Constants.TWEEN_INFO, 
                    {Position = UDim2.new(finalPercent, 0, 0.5, 0)}):Play()
            end
        end)
        
        renderConn = game:GetService("RunService").RenderStepped:Connect(function()
            if isDragging and targetPos then
                sliderThumb.Position = sliderThumb.Position:Lerp(targetPos, 0.15)
            end
        end)
    end)
    
    if otherInfo.Bindable then
        ComponentFactory.addKeybindButton(button, command, commandFunc)
    end
    
    return {
        getValue = function() return State.values[command] end,
        getId = function() return command end,
        getFunc = function() return commandFunc end
    }
end

-- ============================================================================
-- PAGE MANAGEMENT
-- ============================================================================

local PageManager = {}

function PageManager.create(pageName)
    State.pagesAmount = State.pagesAmount + 1
    
    -- Create header
    local _ = UIBuilder.createInstance("TextLabel", {
        Name = pageName,
        Parent = State.headers,
        Text = pageName,
        LayoutOrder = State.pagesAmount,
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 60),
        Font = Enum.Font.MontserratMedium,
        TextSize = 30,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })
    
    -- Create navigation page
    local navPage = UIBuilder.createInstance("Frame", {
        Name = pageName,
        Parent = State.nextPrev,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0)
    })
    
    local navList = Instance.new("UIListLayout")
    navList.Padding = UDim.new(0, 10)
    navList.SortOrder = Enum.SortOrder.LayoutOrder
    navList.FillDirection = Enum.FillDirection.Horizontal
    navList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    navList.VerticalAlignment = Enum.VerticalAlignment.Bottom
    navList.Parent = navPage
    
    -- Next button
    local nextBtn = UIBuilder.createInstance("ImageButton", {
        Name = "2",
        Parent = navPage,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.9,
        LayoutOrder = 2,
        Size = UDim2.new(0.2, 210, 0, 50),
        AutoButtonColor = false
    })
    
    UIBuilder.applyPadding(nextBtn, 10, 20, 20, 10)
    
    local _ = UIBuilder.createInstance("TextLabel", {
        Name = "label",
        Parent = nextBtn,
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Font = Enum.Font.Montserrat,
        Text = "Next Page",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    UIBuilder.createInstance("ImageLabel", {
        Name = "icon",
        Parent = nextBtn,
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 20, 0, 20),
        Image = "rbxassetid://11422142913",
        ImageTransparency = 0.5
    })
    
    -- Previous button
    local prevBtn = UIBuilder.createInstance("ImageButton", {
        Name = "1",
        Parent = navPage,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.9,
        LayoutOrder = 1,
        Size = UDim2.new(0.2, 210, 0, 50),
        AutoButtonColor = false
    })
    
    UIBuilder.applyPadding(prevBtn, 10, 20, 20, 10)
    
    UIBuilder.createInstance("TextLabel", {
        Name = "label",
        Parent = prevBtn,
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Font = Enum.Font.Montserrat,
        Text = "Previous Page",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    UIBuilder.createInstance("ImageLabel", {
        Name = "icon",
        Parent = prevBtn,
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 20, 0, 20),
        Image = "rbxassetid://11422143469",
        ImageTransparency = 0.5
    })
    
    -- Main page
    local mainPage = UIBuilder.createInstance("Frame", {
        Name = pageName,
        Parent = State.scrollFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0)
    })
    
    local mainList = Instance.new("UIListLayout")
    mainList.SortOrder = Enum.SortOrder.LayoutOrder
    mainList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    mainList.Padding = UDim.new(0, 10)
    mainList.Parent = mainPage
    
    -- Setup navigation
    local function navigatePages()
        for _, uiPage in ipairs(State.uiPages) do
            if State.pageNum < State.lastPageNum and nextBtn.Activated then
                uiPage:Next()
            elseif State.pageNum > 1 and prevBtn.Activated then
                uiPage:Previous()
            end
        end
        GUIManager.updatePageButtons()
        
        -- Show/hide buttons on pages
        local currentPage = State.scrollFrame.UIPageLayout.CurrentPage
        for _, page in ipairs(State.scrollFrame:GetChildren()) do
            if page:IsA("Frame") then
                for _, child in ipairs(page:GetChildren()) do
                    if child:IsA("ImageButton") then
                        child.Visible = (page == currentPage)
                    end
                end
            end
        end
    end
    
    nextBtn.Activated:Connect(function()
        if State.pageNum < State.lastPageNum then
            State.pageNum = State.pageNum + 1
            navigatePages()
        end
    end)
    
    prevBtn.Activated:Connect(function()
        if State.pageNum > 1 then
            State.pageNum = State.pageNum - 1
            navigatePages()
        end
    end)
    
    return mainPage
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

local function initializeGUI()
    State.mainGui = UIBuilder.createInstance("ScreenGui", {
        Name = randomString(),
        Parent = COREGUI,
        ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })
    
    -- Background
    State.background = UIBuilder.createInstance("ImageButton", {
        Name = "background",
        Parent = State.mainGui,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = "rbxassetid://14407899530",
        BackgroundTransparency = 1,
        ImageTransparency = 0.2,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 9998
    })
    
    -- Container
    State.container = UIBuilder.createInstance("Frame", {
        Name = "container",
        Parent = State.mainGui,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 9999
    })
    
    UIBuilder.applyPadding(State.container, 0, 0, 0, 50)
    
    -- Scroll frame
    State.scrollFrame = UIBuilder.createInstance("ScrollingFrame", {
        Name = "scroll",
        Parent = State.container,
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, -0.04, 100),
        Size = UDim2.new(1, -20, 0.8, -110),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
        ScrollBarImageTransparency = 0.5,
        ScrollBarThickness = 2,
        TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
    })
    
    UIBuilder.applyPadding(State.scrollFrame, 5, 5, 5, 5)
    
    local scrollPage = Instance.new("UIPageLayout")
    scrollPage.SortOrder = Enum.SortOrder.LayoutOrder
    scrollPage.EasingStyle = Enum.EasingStyle.Quint
    scrollPage.GamepadInputEnabled = false
    scrollPage.ScrollWheelInputEnabled = false
    scrollPage.TouchInputEnabled = false
    scrollPage.Parent = State.scrollFrame
    table.insert(State.uiPages, scrollPage)
    
    -- Close button
    State.closeButton = UIBuilder.createInstance("ImageButton", {
        Name = "close",
        Parent = State.container,
        Modal = true,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, -10),
        Size = UDim2.new(0, 50, 0, 50),
        Image = ""
    })
    
    UIBuilder.createInstance("ImageLabel", {
        Name = "icon",
        Parent = State.closeButton,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0.5, 0, 0.5, 0),
        Image = "rbxassetid://11293981586"
    })
    
    -- Menu keybind button
    local menuKeybind = UIBuilder.createInstance("ImageButton", {
        Name = "keybind",
        Parent = State.closeButton,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 1.5, 0),
        Size = UDim2.new(1.5, 0, 1, 0),
        ImageTransparency = 1
    })
    
    UIBuilder.createStroke(menuKeybind)
    
    local menuKeybindLabel = UIBuilder.createInstance("TextLabel", {
        Name = "label",
        Parent = menuKeybind,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.Montserrat,
        Text = "Bound to: RightShift",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 11,
        TextWrapped = true
    })
    
    Instance.new("UIAspectRatioConstraint").Parent = menuKeybindLabel
    
    -- Headers
    State.headers = UIBuilder.createInstance("Frame", {
        Name = "headers",
        Parent = State.container,
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundTransparency = 1
    })
    
    local headersPage = Instance.new("UIPageLayout")
    headersPage.SortOrder = Enum.SortOrder.LayoutOrder
    headersPage.EasingStyle = Enum.EasingStyle.Cubic
    headersPage.GamepadInputEnabled = false
    headersPage.ScrollWheelInputEnabled = false
    headersPage.TouchInputEnabled = false
    headersPage.Parent = State.headers
    table.insert(State.uiPages, headersPage)
    
    -- Next/Prev container
    State.nextPrev = UIBuilder.createInstance("Frame", {
        Name = "nextprev",
        Parent = State.container,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, -0.255, 100),
        Size = UDim2.new(1, -20, 1.14, -110)
    })
    
    local nextPrevPage = Instance.new("UIPageLayout")
    nextPrevPage.SortOrder = Enum.SortOrder.LayoutOrder
    nextPrevPage.EasingStyle = Enum.EasingStyle.Cubic
    nextPrevPage.GamepadInputEnabled = false
    nextPrevPage.ScrollWheelInputEnabled = false
    nextPrevPage.TouchInputEnabled = false
    nextPrevPage.Parent = State.nextPrev
    table.insert(State.uiPages, nextPrevPage)
    
    -- Version label
    local verLabel = UIBuilder.createInstance("TextLabel", {
        Name = "ver",
        Parent = State.container,
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -20, 0, -10),
        Size = UDim2.new(0, 75, 0, 50),
        Font = Enum.Font.Montserrat,
        Text = "",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right
    })
    
    task.spawn(function()
        while true do
            verLabel.Text = "InfilSense UI Library - bkkpro1980\n\n" .. 
                           State.libName .. "\nVersion:\n" .. State.version
            task.wait(1)
        end
    end)
    
    -- Setup menu toggle keybind
    local function changeMenuKey(keyText, keyCode)
        menuKeybindLabel.Text = "Bound to: " .. keyText
        CAS:UnbindAction("MenuToggle")
        CAS:BindAction("MenuToggle", function(_, inputState)
            if inputState == Enum.UserInputState.Begin then
                GUIManager.toggle(true)
            end
        end, false, keyCode)
    end
    
    -- Load saved menu key
    local savedKey = ConfigManager.get().MenuToggle or "RightShift"
    if isValidKey(savedKey) then
        changeMenuKey(savedKey, stringToKeyCode(savedKey))
    else
        changeMenuKey("RightShift", Enum.KeyCode.RightShift)
    end
    
    UIBuilder.setupHoverEffects(menuKeybind)
    
    menuKeybind.Activated:Connect(function()
        menuKeybindLabel.Text = "Press a key..."
        local captureStart = tick()
        local connection
        
        connection = UIS.InputBegan:Connect(function(input)
            if tick() - captureStart > Constants.TIMEOUT_KEYBIND then
                menuKeybindLabel.Text = "Capture Timed Out"
                connection:Disconnect()
                return
            end
            
            if input.UserInputType == Enum.UserInputType.Keyboard then
                ConfigManager.set("MenuToggle", input.KeyCode.Name)
                changeMenuKey(input.KeyCode.Name, input.KeyCode)
            else
                ConfigManager.set("MenuToggle", "RightShift")
                changeMenuKey("RightShift", Enum.KeyCode.RightShift)
            end
            
            connection:Disconnect()
        end)
    end)
    
    -- Selection frame
    State.selectFrame = UIBuilder.createInstance("Frame", {
        Name = "selection",
        Parent = State.mainGui,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, -0.5, 0),
        Size = UDim2.new(0.5, 0, 0.5, 0),
        ZIndex = 10000
    })
    
    local selectionTop = UIBuilder.createInstance("Frame", {
        Name = "top",
        Parent = State.selectFrame,
        BackgroundColor3 = Color3.fromRGB(26, 26, 26),
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 30)
    })
    
    local selectionLabel = UIBuilder.createInstance("TextLabel", {
        Name = "label",
        Parent = selectionTop,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.Montserrat,
        Text = "Selection",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    UIBuilder.applyPadding(selectionLabel, 0, 10, 0, 0)
    
    State.selectClose = UIBuilder.createInstance("ImageButton", {
        Name = "close",
        Parent = selectionTop,
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Modal = false
    })
    
    Instance.new("UIAspectRatioConstraint", State.selectClose).DominantAxis = Enum.DominantAxis.Height
    UIBuilder.applyPadding(State.selectClose, 5, 5, 5, 5)
    
    UIBuilder.createInstance("ImageLabel", {
        Parent = State.selectClose,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Image = "rbxassetid://11293981586"
    })
    
    State.selectScrollFrame = UIBuilder.createInstance("ScrollingFrame", {
        Name = "scroll",
        Parent = State.selectFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 30),
        Size = UDim2.new(1, 0, 1, -30),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 1, 0),
        ScrollBarThickness = 2
    })
    
    local selectList = Instance.new("UIListLayout")
    selectList.Padding = UDim.new(0, 5)
    selectList.SortOrder = Enum.SortOrder.LayoutOrder
    selectList.Parent = State.selectScrollFrame
    
    State.selectClose.Activated:Connect(function()
        GUIManager.toggle(false)
        GUIManager.toggleSelection()
        GUIManager.clearSelectionButtons()
    end)
    
    -- Quick command UI
    State.quickcmdUI = UIBuilder.createInstance("Frame", {
        Name = "quickcmd",
        Parent = State.mainGui,
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0, -50),
        Size = UDim2.new(0, 250, 0, 50)
    })
    
    UIBuilder.applyPadding(State.quickcmdUI, 5, 5, 5, 5)
    
    local quickcmdText = UIBuilder.createInstance("TextBox", {
        Name = "text",
        Parent = State.quickcmdUI,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.Montserrat,
        PlaceholderColor3 = Color3.fromRGB(42, 42, 42),
        PlaceholderText = "Command list is in the server",
        Text = "",
        TextColor3 = Color3.fromRGB(0, 0, 0),
        TextSize = 16,
        TextWrapped = true
    })
    
    quickcmdText.FocusLost:Connect(function(enter)
        if enter and quickcmdText.Text ~= "" then
            if QuickCommand.process(quickcmdText.Text) then
                quickcmdText.Text = ""
            else
                quickcmdText.Text = "Invalid command ID"
            end
            task.wait(0.5)
        end
        
        TS:Create(State.quickcmdUI, Constants.TWEEN_INFO_QUAD, 
            {Position = UDim2.new(0.5, 0, 0, -50)}):Play()
        State.quickcmdDB = false
    end)
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function module:SetName(name)
    State.libName = name
end

function module:SetVersion(ver)
    State.version = ver
end

function module:SetSaveFolder(folder)
    State.saveFolder = folder
end

function module:SetNameId(id)
    State.nameId = id
end

function module:SetSaveFileName(name)
    State.saveFileName = name
end

function module:GetSaveFileLocation()
    return State.saveFolder ~= "" and State.saveFolder .. "/" .. State.saveFileName or State.saveFileName
end

function module:RenameSaveFile(oldName, newName)
    return ConfigManager.renameFile(oldName, newName)
end

function module:Init()
    initializeGUI()
    State.savedData = ConfigManager.load()
    
    local lib = {}
    local pages = {}
    
    function lib:ToggleCheck(command)
        if not command or State.values[command] == nil then
            return "Invalid command id"
        end
        return State.values[command]
    end
    
    function lib:ToggleGui()
        GUIManager.toggle(nil, true)
    end
    
    function lib:AddPage(pageName)
        local mainPage = PageManager.create(pageName)
        
        local page = {}
        
        function page:AddButton(buttonInfo, commandFunc, otherInfo, quickCmds)
            return ComponentFactory.createButton(buttonInfo, commandFunc, otherInfo, mainPage, quickCmds)
        end
        
        function page:AddTextbox(buttonInfo, commandFunc, otherInfo, quickCmds)
            return ComponentFactory.createTextBox(buttonInfo, commandFunc, otherInfo, mainPage, quickCmds)
        end
        
        function page:AddSelection(buttonInfo, commandFunc, otherInfo, options, quickCmds)
            return ComponentFactory.createSelection(buttonInfo, commandFunc, otherInfo, mainPage, options, quickCmds)
        end
        
        function page:AddSlider(buttonInfo, commandFunc, otherInfo, settings, quickCmds)
            return ComponentFactory.createSlider(buttonInfo, commandFunc, otherInfo, mainPage, settings, quickCmds)
        end
        
        pages[pageName] = page
        return page
    end
    
    function lib:GetPageFromTitle(title)
        return pages[title]
    end
    
    function lib:GetQuickCommandsList()
        print("[" .. State.libName .. "]: ---------- COMMANDS LIST OUTPUT START ----------\n")
        
        local grouped = {}
        local keyOrder = {}
        
        for _, cmdKey in ipairs(State.quickcmdListOrder) do
            local data = State.quickcmdList[cmdKey]
            if data then
                local title = data[2]
                local uniqueId = data[3]
                local groupKey = title .. "|" .. uniqueId
                
                if not grouped[groupKey] then
                    grouped[groupKey] = {cmds = {}, title = title, uniqueId = uniqueId}
                    table.insert(keyOrder, groupKey)
                end
                table.insert(grouped[groupKey].cmds, cmdKey)
            end
        end
        
        local output = {}
        for _, groupKey in ipairs(keyOrder) do
            local group = grouped[groupKey]
            local line = string.format("%s (%s): %s", group.title, group.uniqueId, table.concat(group.cmds, ", "))
            print("[" .. State.libName .. "]: " .. line)
            table.insert(output, line)
        end
        
        if #output > 0 then
            local folder = State.saveFolder ~= "" and State.saveFolder .. "/" or ""
            if not isfolder(folder .. "commandIds") then
                makefolder(folder .. "commandIds")
            end
            writefile(folder .. "commandIds/" .. State.nameId .. ".txt", table.concat(output, "\n"))
            print("[" .. State.libName .. "]: File written to: " .. folder .. "commandIds/" .. State.nameId .. ".txt")
        else
            print("[" .. State.libName .. "]: No quick commands found.")
        end
        
        print("\n[" .. State.libName .. "]: ---------- COMMANDS LIST OUTPUT END ----------")
    end
    
    -- Add settings page with quick command toggle
    local settingsPage = lib:AddPage("Settings")
    settingsPage:AddSlider(
        {
            Title = "Quick Command",
            Desc = "Check 'More Command Info' in the settings category.",
            Action = ""
        },
        QuickCommand.toggle,
        {
            UniqueCommandId = "IMPORTANT_QUICKCMD",
            StartupAvailable = true,
            Bindable = true
        },
        {
            sliderType = "bool",
            defVal = 1,
            lowVal = 0,
            maxVal = 1,
            save = true
        }
    )
    
    -- Monitor page count
    task.spawn(function()
        while true do
            State.lastPageNum = State.pagesAmount
            if State.nextPrev then
                State.nextPrev.Visible = State.pagesAmount > 1
            end
            task.wait(1)
        end
    end)
    
    return lib
end

return module