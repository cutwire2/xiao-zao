-- ekx.client.lua
-- Rocket Auto — 复古色 UI + 音频版

local plrs = game:GetService("Players")
local run = game:GetService("RunService")
local rep = game:GetService("ReplicatedStorage")
local gui = game:GetService("CoreGui")
local uis = game:GetService("UserInputService")
local snd = game:GetService("SoundService")
local ts  = game:GetService("TweenService")

local lp = plrs.LocalPlayer
local ev = rep:WaitForChild("RocketSystem"):WaitForChild("Events"):WaitForChild("RocketHit")

local on = false
local cur = nil
local conn = nil
local last = 0
local lastLockType = nil
local music = nil

-- 音频配置
local SFX_ENABLE_ONCE = "rbxassetid://140014208317483"
local SFX_LOCK_BASE   = "rbxassetid://81248860006896"
local SFX_LOCK_PLAYER = "rbxassetid://120462559778072"
local MUSIC_LOOP      = "rbxassetid://79275242664744"

-- ─────────────────────────────────────────────
-- 复古配色
-- ─────────────────────────────────────────────
local C = {
	bg       = Color3.fromRGB(58, 45, 34),
	surface  = Color3.fromRGB(79, 62, 48),
	bar      = Color3.fromRGB(103, 79, 58),
	border   = Color3.fromRGB(166, 132, 92),
	text     = Color3.fromRGB(247, 232, 200),
	muted    = Color3.fromRGB(204, 176, 134),
	accent   = Color3.fromRGB(160, 77, 53),
	success  = Color3.fromRGB(115, 148, 92),
	minBtn   = Color3.fromRGB(132, 103, 76),
	closeBtn = Color3.fromRGB(138, 64, 46),
	hlFill   = Color3.fromRGB(210, 119, 74),
	hlOut    = Color3.fromRGB(255, 236, 205),
	beam     = Color3.fromRGB(255, 196, 104),
}

local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_MED  = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function tween(obj, props, info)
	ts:Create(obj, info or TWEEN_FAST, props):Play()
end

local function playOneShot(id, volume)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 1
	s.Parent = snd
	s:Play()
	s.Ended:Connect(function()
		s:Destroy()
	end)
	return s
end

local function startMusic()
	if music then
		music:Stop()
		music:Destroy()
		music = nil
	end

	music = Instance.new("Sound")
	music.Name = "EKX_BackgroundMusic"
	music.SoundId = MUSIC_LOOP
	music.Volume = 1
	music.Looped = true
	music.TimePosition = 120
	music.Parent = snd

	music.Loaded:Connect(function()
		pcall(function()
			music.TimePosition = 120
		end)
	end)

	music:Play()
	task.delay(0.2, function()
		if music and music.Parent then
			pcall(function()
				music.TimePosition = 120
			end)
		end
	end)
end

local function stopMusic()
	if music then
		music:Stop()
		music:Destroy()
		music = nil
	end
end

-- ─────────────────────────────────────────────
-- World indicators
-- ─────────────────────────────────────────────
local hl = Instance.new("Highlight")
hl.FillColor = C.hlFill
hl.OutlineColor = C.hlOut
hl.FillTransparency = 0.55
hl.OutlineTransparency = 0

local bb = Instance.new("BillboardGui")
bb.Size = UDim2.new(0, 120, 0, 32)
bb.StudsOffset = Vector3.new(0, 3.2, 0)
bb.AlwaysOnTop = true

local lbl = Instance.new("TextLabel")
lbl.Parent = bb
lbl.Size = UDim2.new(1, 0, 1, 0)
lbl.BackgroundTransparency = 1
lbl.TextColor3 = C.text
lbl.TextScaled = true
lbl.Font = Enum.Font.Garamond
lbl.TextStrokeTransparency = 0.4
lbl.TextStrokeColor3 = Color3.fromRGB(35, 20, 10)

-- ─────────────────────────────────────────────
-- ScreenGui + root frame
-- ─────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = gui

-- 卡密验证：通过后才显示主界面。
local ACCESS_KEY = "泽萧hello"
local frm, shadow

local authFrame = Instance.new("Frame")
authFrame.Name = "EKX_KeyPrompt"
authFrame.Parent = sg
authFrame.Size = UDim2.new(0, 230, 0, 142)
authFrame.Position = UDim2.new(0.5, -115, 0.5, -71)
authFrame.BackgroundColor3 = Color3.fromRGB(58, 45, 34)
authFrame.BorderSizePixel = 0
authFrame.ZIndex = 20
Instance.new("UICorner", authFrame).CornerRadius = UDim.new(0, 10)

local authStroke = Instance.new("UIStroke")
authStroke.Parent = authFrame
authStroke.Color = Color3.fromRGB(166, 132, 92)
authStroke.Thickness = 2

local authTitle = Instance.new("TextLabel")
authTitle.Parent = authFrame
authTitle.Size = UDim2.new(1, -24, 0, 26)
authTitle.Position = UDim2.new(0, 12, 0, 12)
authTitle.BackgroundTransparency = 1
authTitle.Text = "EKX  卡密验证"
authTitle.TextColor3 = Color3.fromRGB(247, 232, 200)
authTitle.TextSize = 17
authTitle.Font = Enum.Font.Garamond
authTitle.TextXAlignment = Enum.TextXAlignment.Left
authTitle.ZIndex = 21

local keyBox = Instance.new("TextBox")
keyBox.Parent = authFrame
keyBox.Size = UDim2.new(1, -24, 0, 34)
keyBox.Position = UDim2.new(0, 12, 0, 48)
keyBox.BackgroundColor3 = Color3.fromRGB(79, 62, 48)
keyBox.BorderSizePixel = 0
keyBox.PlaceholderText = "请输入卡密"
keyBox.PlaceholderColor3 = Color3.fromRGB(204, 176, 134)
keyBox.Text = ""
keyBox.TextColor3 = Color3.fromRGB(247, 232, 200)
keyBox.TextSize = 15
keyBox.Font = Enum.Font.Garamond
keyBox.ClearTextOnFocus = false
keyBox.ZIndex = 21
Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0, 7)

local keyStroke = Instance.new("UIStroke")
keyStroke.Parent = keyBox
keyStroke.Color = Color3.fromRGB(196, 157, 112)
keyStroke.Thickness = 1

local verifyBtn = Instance.new("TextButton")
verifyBtn.Parent = authFrame
verifyBtn.Size = UDim2.new(1, -24, 0, 30)
verifyBtn.Position = UDim2.new(0, 12, 0, 92)
verifyBtn.BackgroundColor3 = Color3.fromRGB(160, 77, 53)
verifyBtn.BorderSizePixel = 0
verifyBtn.Text = "验证"
verifyBtn.TextColor3 = Color3.fromRGB(247, 232, 200)
verifyBtn.TextSize = 15
verifyBtn.Font = Enum.Font.Garamond
verifyBtn.AutoButtonColor = false
verifyBtn.ZIndex = 21
Instance.new("UICorner", verifyBtn).CornerRadius = UDim.new(0, 7)

local function verifyKey()
	if keyBox.Text == ACCESS_KEY then
		authFrame:Destroy()
		frm.Visible = true
		shadow.Visible = true
	else
		keyBox.Text = ""
		keyBox.PlaceholderText = "卡密错误，请重试"
		keyBox.PlaceholderColor3 = Color3.fromRGB(235, 118, 86)
		tween(authFrame, { BackgroundColor3 = Color3.fromRGB(82, 45, 36) })
		task.delay(0.2, function()
			if authFrame.Parent then
				tween(authFrame, { BackgroundColor3 = Color3.fromRGB(58, 45, 34) })
			end
		end)
	end
end

verifyBtn.MouseButton1Click:Connect(verifyKey)
keyBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		verifyKey()
	end
end)

shadow = Instance.new("Frame")
shadow.Parent = sg
shadow.Size = UDim2.new(0, 176, 0, 138)
shadow.Position = UDim2.new(0.1, 4, 0.4, 4)
shadow.BackgroundColor3 = Color3.fromRGB(25, 15, 10)
shadow.BackgroundTransparency = 0.45
shadow.BorderSizePixel = 0
shadow.ZIndex = 1
Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 14)

frm = Instance.new("Frame")
frm.Parent = sg
frm.Size = UDim2.new(0, 170, 0, 132)
frm.Position = UDim2.new(0.1, 0, 0.4, 0)
frm.BackgroundColor3 = C.bg
frm.BorderSizePixel = 0
frm.Active = true
frm.ZIndex = 2
frm.Visible = false
shadow.Visible = false
Instance.new("UICorner", frm).CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke")
stroke.Parent = frm
stroke.Color = C.border
stroke.Thickness = 2
stroke.Transparency = 0

local bar = Instance.new("Frame")
bar.Parent = frm
bar.Size = UDim2.new(1, 0, 0, 40)
bar.BackgroundColor3 = C.bar
bar.BorderSizePixel = 0
bar.ZIndex = 3
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 12)

local barFill = Instance.new("Frame")
barFill.Parent = bar
barFill.Size = UDim2.new(1, 0, 0, 12)
barFill.Position = UDim2.new(0, 0, 1, -12)
barFill.BackgroundColor3 = C.bar
barFill.BorderSizePixel = 0
barFill.ZIndex = 3

local dot = Instance.new("Frame")
dot.Parent = bar
dot.Size = UDim2.new(0, 8, 0, 8)
dot.Position = UDim2.new(0, 12, 0.5, -4)
dot.BackgroundColor3 = C.accent
dot.BorderSizePixel = 0
dot.ZIndex = 4
Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

local tit = Instance.new("TextLabel")
tit.Parent = bar
tit.Size = UDim2.new(1, -100, 1, 0)
tit.Position = UDim2.new(0, 28, 0, 0)
tit.BackgroundTransparency = 1
tit.Text = "EKX"
tit.TextColor3 = C.text
tit.TextSize = 18
tit.Font = Enum.Font.Garamond
tit.TextXAlignment = Enum.TextXAlignment.Left
tit.ZIndex = 4

local minBtn = Instance.new("TextButton")
minBtn.Parent = bar
minBtn.Size = UDim2.new(0, 22, 0, 22)
minBtn.Position = UDim2.new(1, -52, 0.5, -11)
minBtn.BackgroundColor3 = C.minBtn
minBtn.Text = "–"
minBtn.TextColor3 = C.text
minBtn.TextSize = 16
minBtn.Font = Enum.Font.Garamond
minBtn.BorderSizePixel = 0
minBtn.AutoButtonColor = false
minBtn.ZIndex = 4
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 5)

local clsBtn = Instance.new("TextButton")
clsBtn.Parent = bar
clsBtn.Size = UDim2.new(0, 22, 0, 22)
clsBtn.Position = UDim2.new(1, -26, 0.5, -11)
clsBtn.BackgroundColor3 = C.closeBtn
clsBtn.Text = "×"
clsBtn.TextColor3 = C.text
clsBtn.TextSize = 15
clsBtn.Font = Enum.Font.Garamond
clsBtn.BorderSizePixel = 0
clsBtn.AutoButtonColor = false
clsBtn.ZIndex = 4
Instance.new("UICorner", clsBtn).CornerRadius = UDim.new(0, 5)

local body = Instance.new("Frame")
body.Parent = frm
body.Size = UDim2.new(1, 0, 1, -40)
body.Position = UDim2.new(0, 0, 0, 40)
body.BackgroundTransparency = 1
body.ZIndex = 3

local panel = Instance.new("Frame")
panel.Parent = body
panel.Size = UDim2.new(1, -18, 1, -18)
panel.Position = UDim2.new(0, 9, 0, 9)
panel.BackgroundColor3 = C.surface
panel.BorderSizePixel = 0
panel.ZIndex = 3
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

local panelStroke = Instance.new("UIStroke")
panelStroke.Parent = panel
panelStroke.Color = Color3.fromRGB(196, 157, 112)
panelStroke.Thickness = 1

local statusLbl = Instance.new("TextLabel")
statusLbl.Parent = panel
statusLbl.Size = UDim2.new(1, -18, 0, 18)
statusLbl.Position = UDim2.new(0, 9, 0, 8)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "状态：待机"
statusLbl.TextColor3 = C.muted
statusLbl.TextSize = 14
statusLbl.Font = Enum.Font.Garamond
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.ZIndex = 4

local tgl = Instance.new("TextButton")
tgl.Parent = panel
tgl.Size = UDim2.new(1, -18, 0, 42)
tgl.Position = UDim2.new(0, 9, 0, 34)
tgl.BackgroundColor3 = C.accent
tgl.Text = "OFF"
tgl.TextColor3 = C.text
tgl.TextSize = 16
tgl.Font = Enum.Font.Garamond
tgl.BorderSizePixel = 0
tgl.AutoButtonColor = false
tgl.ZIndex = 4
Instance.new("UICorner", tgl).CornerRadius = UDim.new(0, 8)

local tglStroke = Instance.new("UIStroke")
tglStroke.Parent = tgl
tglStroke.Color = Color3.fromRGB(255, 226, 178)
tglStroke.Thickness = 1
tglStroke.Transparency = 0.35

minBtn.MouseEnter:Connect(function()
	tween(minBtn, { BackgroundColor3 = Color3.fromRGB(156, 124, 93) })
end)
minBtn.MouseLeave:Connect(function()
	tween(minBtn, { BackgroundColor3 = C.minBtn })
end)

clsBtn.MouseEnter:Connect(function()
	tween(clsBtn, { BackgroundColor3 = Color3.fromRGB(168, 76, 54) })
end)
clsBtn.MouseLeave:Connect(function()
	tween(clsBtn, { BackgroundColor3 = C.closeBtn })
end)

tgl.MouseEnter:Connect(function()
	if on then
		tween(tgl, { BackgroundColor3 = Color3.fromRGB(132, 170, 106) })
	else
		tween(tgl, { BackgroundColor3 = Color3.fromRGB(182, 95, 68) })
	end
end)
tgl.MouseLeave:Connect(function()
	tween(tgl, { BackgroundColor3 = on and C.success or C.accent })
end)

local drg, din, dst, stp

bar.InputBegan:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
		drg = true
		dst = inp.Position
		stp = frm.Position
		inp.Changed:Connect(function()
			if inp.UserInputState == Enum.UserInputState.End then
				drg = false
			end
		end)
	end
end)

bar.InputChanged:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
		din = inp
	end
end)

uis.InputChanged:Connect(function(inp)
	if inp == din and drg then
		local d = inp.Position - dst
		local np = UDim2.new(stp.X.Scale, stp.X.Offset + d.X, stp.Y.Scale, stp.Y.Offset + d.Y)
		frm.Position = np
		shadow.Position = UDim2.new(np.X.Scale, np.X.Offset + 4, np.Y.Scale, np.Y.Offset + 4)
	end
end)

local ism = false
minBtn.MouseButton1Click:Connect(function()
	ism = not ism
	if ism then
		tween(frm, { Size = UDim2.new(0, 170, 0, 40) }, TWEEN_MED)
		tween(shadow, { Size = UDim2.new(0, 176, 0, 46) }, TWEEN_MED)
		body.Visible = false
	else
		body.Visible = true
		tween(frm, { Size = UDim2.new(0, 170, 0, 132) }, TWEEN_MED)
		tween(shadow, { Size = UDim2.new(0, 176, 0, 138) }, TWEEN_MED)
	end
end)

local function clr()
	hl.Parent = nil
	bb.Parent = nil
	cur = nil
	lastLockType = nil
end

clsBtn.MouseButton1Click:Connect(function()
	on = false
	if conn then conn:Disconnect() end
	stopMusic()
	clr()
	sg:Destroy()
	shadow:Destroy()
end)

local function getrpg()
	local c = lp.Character
	if not c then return nil end
	local w = c:FindFirstChild("RPG")
	if w and w:IsA("Tool") then
		return w
	end
	return nil
end

local function playsnd()
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://17148249625"
	s.Volume = 1
	s.Parent = snd
	s:Play()
	s.Ended:Connect(function()
		s:Destroy()
	end)
end

local function mkbm(sp, ep)
	local att1 = Instance.new("Attachment")
	att1.WorldPosition = sp
	att1.Parent = workspace.Terrain

	local att2 = Instance.new("Attachment")
	att2.WorldPosition = ep
	att2.Parent = workspace.Terrain

	local bm = Instance.new("Beam")
	bm.Attachment0 = att1
	bm.Attachment1 = att2
	bm.Color = ColorSequence.new(C.beam)
	bm.LightEmission = 1
	bm.LightInfluence = 0
	bm.Width0 = 1.2
	bm.Width1 = 1.2
	bm.FaceCamera = true
	bm.Segments = 10
	bm.Texture = "rbxassetid://446111271"
	bm.TextureMode = Enum.TextureMode.Wrap
	bm.TextureSpeed = 5
	bm.TextureLength = 1.3
	bm.Transparency = NumberSequence.new(0)
	bm.Parent = workspace.Terrain

	task.delay(2, function()
		local t = 0
		local dur = 1
		local step
		step = run.Heartbeat:Connect(function(dt)
			t = t + dt
			local alpha = math.clamp(t / dur, 0, 1)
			bm.Transparency = NumberSequence.new(alpha)
			if alpha >= 1 then
				step:Disconnect()
				bm:Destroy()
				att1:Destroy()
				att2:Destroy()
			end
		end)
	end)
end

local function chkplr(p)
	if p == lp or not p.Character then return false end
	local c = p.Character
	local h = c:FindFirstChildOfClass("Humanoid")
	if not h or h.Health <= 0 then return false end
	if c:FindFirstChildOfClass("ForceField") then return false end
	local r = c:FindFirstChild("HumanoidRootPart")
	if not r then return false end
	return true
end

local function mytyc(v)
	local tycs = workspace:FindFirstChild("Tycoon") and workspace.Tycoon:FindFirstChild("Tycoons")
	if not tycs then return false end
	for _, t in ipairs(tycs:GetChildren()) do
		local o = t:FindFirstChild("Owner") or t:FindFirstChild("Player")
		if o and (o.Value == lp or o.Value == lp.Name) then
			if v:IsDescendantOf(t) then
				return true
			end
		end
	end
	return false
end

local function gettar()
	local c = lp.Character
	if not c then return nil, nil end
	local r = c:FindFirstChild("HumanoidRootPart")
	if not r then return nil, nil end

	local close = nil
	local md = math.huge
	local isshd = false

	for _, p in ipairs(plrs:GetPlayers()) do
		if chkplr(p) then
			local pr = p.Character.HumanoidRootPart
			local d = (pr.Position - r.Position).Magnitude
			if d < md then
				md = d
				close = p
				isshd = false
			end
		end
	end

	local tyc = workspace:FindFirstChild("Tycoon")
	if tyc then
		for _, v in ipairs(tyc:GetDescendants()) do
			if (v.Name == "Base Shield" or v.Name == "Shield") and not mytyc(v) then
				local sp = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart", true)
				if sp then
					local d = (sp.Position - r.Position).Magnitude
					if d < md then
						md = d
						close = sp
						isshd = true
					end
				end
			end
		end
	end

	return close, isshd
end

local function atk(tar, isshd, rpg)
	local c = lp.Character
	if not c then return end
	local r = c:FindFirstChild("HumanoidRootPart")
	local og = r and r.Position or Vector3.zero

	local hp, pos

	if isshd then
		hp = tar
		pos = tar.Position
	else
		local tc = tar.Character
		if not tc then return end
		hp = tc:FindFirstChild("HumanoidRootPart") or tc:FindFirstChild("Torso")
		if not hp then return end
		pos = hp.Position
	end

	local args = {
		{
			Normal = Vector3.yAxis,
			Player = isshd and lp or tar,
			HitPart = hp,
			Origin = vector.create(og.X, og.Y, og.Z),
			Label = lp.Name .. "Rocket0",
			Vehicle = rpg,
			Position = vector.create(pos.X, pos.Y, pos.Z),
			Weapon = rpg
		}
	}
	ev:FireServer(unpack(args))
	playsnd()
	mkbm(og, pos)
end

tgl.MouseButton1Click:Connect(function()
	on = not on
	if on then
		tgl.Text = "ON"
		dot.BackgroundColor3 = C.success
		statusLbl.Text = "状态：运行中"
		statusLbl.TextColor3 = C.success
		tween(tgl, { BackgroundColor3 = C.success })
		playOneShot(SFX_ENABLE_ONCE, 10)
		startMusic()
		lastLockType = nil
	else
		tgl.Text = "OFF"
		dot.BackgroundColor3 = C.accent
		statusLbl.Text = "状态：待机"
		statusLbl.TextColor3 = C.muted
		tween(tgl, { BackgroundColor3 = C.accent })
		stopMusic()
		clr()
	end
end)

conn = run.Heartbeat:Connect(function()
	if not on then return end

	local rpg = getrpg()
	if not rpg then
		clr()
		return
	end

	local tar, isshd = gettar()
	if tar then
		cur = tar

		if isshd then
			hl.Parent = tar
			bb.Parent = nil
			if lastLockType ~= "base" then
				playOneShot(SFX_LOCK_BASE, 1)
				lastLockType = "base"
			end
		else
			local char = tar.Character
			local hd = char and char:FindFirstChild("Head")
			local hum = char and char:FindFirstChildOfClass("Humanoid")

			if char then hl.Parent = char end
			if hd and hum then
				bb.Parent = hd
				lbl.Text = "HP  " .. math.floor(hum.Health)
			end

			if lastLockType ~= "player" then
				playOneShot(SFX_LOCK_PLAYER, 1)
				lastLockType = "player"
			end
		end

		if tick() - last >= 0.1 then
			last = tick()
			atk(tar, isshd, rpg)
		end
	else
		clr()
	end
end)
