--// Aim Assist - Mobile + PC (test build) - LocalScript
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

--// ===== clean up a previous run (running the script twice must not stack menus or bindings) =====
local env = (getgenv and getgenv()) or _G
if type(env.AimAssistSettings) == "table" then
	for k, v in pairs(env.AimAssistSettings) do -- switch every old feature off
		if type(v) == "boolean" then env.AimAssistSettings[k] = false end
	end
end
for _, name in ipairs({ "AimAssistStep", "PlayerTracers", "AA_ViewModel", "AA_HandsXZ", "AA_FOV", "AA_Cosmetics", "AA_GunSkin", "AA_FreeCam", "AA_CamOffset", "AA_HUD" }) do
	pcall(function() RunService:UnbindFromRenderStep(name) end)
end
do
	local pg = player:WaitForChild("PlayerGui")
	for _, child in ipairs(pg:GetChildren()) do -- the menu and every AA_ gui / billboard of a previous run
		if child.Name == "AimMenu" or child.Name:sub(1, 3) == "AA_" then child:Destroy() end
	end
	for _, child in ipairs(game:GetService("Lighting"):GetChildren()) do
		if child.Name:sub(1, 3) == "AA_" then child:Destroy() end
	end
	local cam = workspace.CurrentCamera
	if cam then
		for _, n in ipairs({ "WorldParticles", "AA_ShaderExtras", "AA_TargetFX", "AA_JumpFX", "AA_Cosmetics", "AA_Effects" }) do
			local old = cam:FindFirstChild(n)
			if old then old:Destroy() end
		end
	end
end

--// ===== ANTI KICK (always on, starts with the script) =====
-- Blocks kicks that the game asks for from the CLIENT side (LocalScripts calling
-- LocalPlayer:Kick). A kick or ban decided by the game's SERVER cannot be stopped from here.
do
	local blocked = false
	if hookfunction then
		-- replace the Kick function itself: covers player:Kick() and player.Kick(player)
		blocked = pcall(function()
			hookfunction(player.Kick, newcclosure and newcclosure(function() end) or function() end)
		end)
	end
	if not blocked and hookmetamethod and getnamecallmethod then
		-- fallback: ignore the method call "Kick" on your own player
		local oldNamecall
		oldNamecall = hookmetamethod(game, "__namecall", (newcclosure or function(f) return f end)(function(self, ...)
			local method = getnamecallmethod()
			if self == player and type(method) == "string" and method:lower() == "kick"
				and not (checkcaller and checkcaller()) then
				return nil
			end
			return oldNamecall(self, ...)
		end))
	end
end

local Settings = {
	AimEnabled = false,
	SilentAim = false,
	WallFire = false,
	Fullbright = false,
	ShowList = true,   -- module list HUD
	AimPart = "Head",  -- Head / Torso / Root
	Tracers = false,
	TracerMode = "Straight", -- Straight / Square
	TracerThickness = 1.5,
	Theme = "Blue",
	MenuTheme = "Default",
	SpeedMethod = "WalkSpeed", -- WalkSpeed / CFrame
	AutoSprint = false,
	FreeCam = false,
	FreeCamSpeed = 50,
	NoRecoil = false,
	FastReload = false,
	FastReloadMult = 8,
	Hitbox = false,
	HitboxSize = 8,
	HitboxPart = "Root", -- Root / Head
	HitboxShow = true,
	HitMarker = false,
	DamageNumbers = false,
	Vignette = false,
	VignetteStrength = 0.5,
	SelfGlow = false,
	CamOffset = false,
	CamOffsetX = 2,
	Speedometer = false,
	Coords = false,
	Compass = false,
	Clock = false,
	HideKey = false,
	ClickGUI = false,
	ClickSkin = "Chocolate", -- Chocolate / New Year / Toxic / Magma
	MenuStyle = "None",      -- None / Cloud / Glass / Metal / Carpet
	Music = false,
	MusicId = "",
	MusicVolume = 2,
	MusicLoop = true,
	BoxESP2 = false,
	LowHealth = false,
	LowHealthThreshold = 25,
	XadesaMod = false,
	XadesaHeight = 1.18,
	Fling = false,
	FlingPower = 10000,
	AntiFling = false,
	Afterimage = false,
	AfterimageColor = "Theme", -- Theme / Rainbow / Ice / Fire
	AfterimageLife = 0.6,
	Rewind = false,
	RewindSeconds = 8,
	Grapple = false,
	GrappleSpeed = 90,
	Invisible = false, -- mirrors FE Invisible so it can be bound; not saved in configs
	Lightning = false,
	LightningRadius = 30,
	LightningRate = 3,
	Winter = false,
	WinterSnow = 150,
	Washed = false,
	WashedShine = 0.35,
	WashedRain = false,
	WashedRainAmount = 100,
	CosHands = "None",
	CosPet = "None",
	CosWings = "None",   -- cosmetics: None or the name of the item
	CosCap = "None",
	CosShoes = "None",
	CosTorso = "None",
	CosFace = "None",
	CosBack = "None",
	CosAura = "None",
	CosTail = "None",
	CosGunSkin = "None", -- skin on the weapon in your hands
	KillEffect = "None", -- effect when you kill a player
	DieEffect = "None",  -- effect when you die
	AutoExecute = false,
	AutoExecuteSource = "",
	NameTags = false,
	Crosshair = false,
	CrosshairStyle = "Cross",  -- Cross / Dot / Circle / Plus
	CrosshairSize = 14,
	FovChanger = false,
	FovValue = 90,
	Radar = false,
	RadarRange = 200,
	ZoomUnlock = false,
	-- premium extras
	SpinBot = false,
	SpinSpeed = 4,
	TapTeleport = false,
	GravityMod = false,
	GravityValue = 100,
	AntiAFK = false,
	AutoClicker = false,
	ClickCPS = 8,
	Shader = false,
	TimeOfDay = "Day",        -- Day / Evening / Night / Morning
	WorldParticles = false,
	ParticleShape = "Cubes",  -- Cubes / Circles
	ParticleCount = 60,
	ViewModel = false,
	VM_LX = 0, VM_LY = 0, VM_LZ = 0, -- left arm offset  (studs: X right, Y up, Z forward)
	VM_RX = 0, VM_RY = 0, VM_RZ = 0, -- right arm offset
	HandShader = false,
	HandStyle = "Both",  -- Both / Fire / Glow
	Watermark = true,
	TargetESP = false,
	InfiniteJump = false,
	JumpCircle = false,
	JumpCircleShape = "Circle", -- Circle / Square / Triangle
	AutoGrab = false,
	HandsXZ = false,
	HandsXZMode = "Bottom to top", -- Bottom to top / Top to bottom / Left to right / Right to left
	HandsXZSpeed = 1,
	-- premium
	GodMode = false,
	GodShift = 150,            -- studs above you where the hitbox is moved
	FlyPlus = false,
	FlyPlusSpeed = 60,         -- 20 - 120
	HandsXZ2 = false,
	HandsXZ2Palette = "Rainbow",
	HandsXZ2Dir = "Bottom to top",
	HandsXZ2Speed = 1,
	Screen = false,
	ScreenMode = "Red VHS",    -- Red VHS / White VHS
	AirStuck = false,
	PlayerTrail = false,
	PlayerTrailStyle = "Theme", -- Theme / Rainbow
	Beautiful = false,
	TargetParticles = false,
	TargetParticlesMode = "Crystals", -- Crystals / Souls / Crosshair / Squares
	ShaderPlus = false,
	ShaderPlusMode = "Day",    -- Day / Evening / Sunset / Night / Sunrise / Morning / Winter / Winter Evening / Winter Night / Autumn / Space / Milky Way / Black Hole / Galaxy
	WallCheck = true,
	TeamCheck = true,
	PlayersOnly = true,
	Noclip = false,
	SpeedEnabled = false,
	InstantPrompt = false,
	FlyEnabled = false,
	ESPEnabled = false,
	FOV = 150,
	Speed = 0.30,      -- aim smoothing
	WalkSpeed = 16,    -- 16 - 60
	FlySpeed = 20,     -- 20 - 80
	BoostHP = 350,     -- health set by Health Boost
	TpStep = 0.15,     -- seconds between hops along the path (0 = jump straight to the end)
}


-- Players excluded from Aim + Silent Aim (keyed by UserId, so it survives a rejoin)
local excluded = {}

-- Premium tab: unlocked with a password; premium settings from configs are ignored while locked
local premiumUnlocked = false
local PREMIUM_KEYS = {
	GodMode = true, GodShift = true, FlyPlus = true, FlyPlusSpeed = true,
	HandsXZ2 = true, HandsXZ2Palette = true, HandsXZ2Dir = true, HandsXZ2Speed = true,
	Screen = true, ScreenMode = true, ShaderPlus = true, ShaderPlusMode = true,
	TargetParticles = true, TargetParticlesMode = true, AirStuck = true, Beautiful = true,
	PlayerTrail = true, PlayerTrailStyle = true,
	SpinBot = true, SpinSpeed = true, TapTeleport = true, GravityMod = true, GravityValue = true,
	AntiAFK = true, AutoClicker = true, ClickCPS = true, FreeCam = true, FreeCamSpeed = true,
}
local function isExcluded(model)
	local plr = Players:GetPlayerFromCharacter(model)
	return plr ~= nil and excluded[plr.UserId] == true
end
env.AimAssistSettings = Settings -- lets a later run switch this one off

--// ===== WELCOME SPLASH (plays once, right when the script starts) =====
-- Blurred backdrop, a glowing purple V that pops in, "Welcome to", the title typed out letter by
-- letter ("RECODE" in red) with a light sweep, a loading bar with stages, then everything fades.
do
	local Lighting = game:GetService("Lighting")
	local splash = Instance.new("ScreenGui")
	splash.Name = "AA_Welcome"
	splash.ResetOnSpawn = false
	splash.IgnoreGuiInset = true
	splash.DisplayOrder = 50
	splash.Parent = player:WaitForChild("PlayerGui")

	local blur = Instance.new("BlurEffect")
	blur.Name = "AA_SplashBlur"
	blur.Size = 0
	blur.Parent = Lighting

	local root = Instance.new("CanvasGroup") -- one group, so the whole splash fades as a unit
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = Color3.fromRGB(7, 4, 13)
	root.BackgroundTransparency = 0.08
	root.BorderSizePixel = 0
	root.GroupTransparency = 1
	root.Parent = splash

	local function label(name, y, size, font, color)
		local l = Instance.new("TextLabel")
		l.Name = name
		l.AnchorPoint = Vector2.new(0.5, 0.5)
		l.Position = UDim2.fromScale(0.5, y)
		l.BackgroundTransparency = 1
		l.Font = font
		l.TextSize = size
		l.TextColor3 = color
		l.Parent = root
		return l
	end

	-- soft purple glow behind the logo, breathing slowly
	local glow = Instance.new("Frame")
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.fromScale(0.5, 0.3)
	glow.Size = UDim2.fromOffset(340, 340)
	glow.BackgroundColor3 = Color3.fromRGB(150, 60, 235)
	glow.BackgroundTransparency = 0.82
	glow.BorderSizePixel = 0
	glow.Parent = root
	Instance.new("UICorner", glow).CornerRadius = UDim.new(1, 0)
	local glowScale = Instance.new("UIScale", glow)

	local logo = label("Logo", 0.3, 120, Enum.Font.GothamBlack, Color3.new(1, 1, 1))
	logo.Size = UDim2.fromOffset(200, 170)
	logo.Text = "V"
	logo.TextTransparency = 1
	local logoGrad = Instance.new("UIGradient", logo)
	logoGrad.Rotation = 90
	logoGrad.Color = ColorSequence.new(Color3.fromRGB(255, 190, 255), Color3.fromRGB(150, 60, 235))
	local logoStroke = Instance.new("UIStroke", logo)
	logoStroke.Color = Color3.fromRGB(190, 70, 255)
	logoStroke.Thickness = 3
	logoStroke.Transparency = 1
	local logoScale = Instance.new("UIScale", logo)
	logoScale.Scale = 0.4

	local line1 = label("Welcome", 0.5, 26, Enum.Font.Gotham, Color3.fromRGB(205, 205, 220))
	line1.Size = UDim2.fromScale(0.9, 0.06)
	line1.Text = "Welcome to"
	line1.TextTransparency = 1

	local titleHolder = Instance.new("Frame")
	titleHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	titleHolder.Position = UDim2.fromScale(0.5, 0.58)
	titleHolder.Size = UDim2.fromScale(0.96, 0.13)
	titleHolder.BackgroundTransparency = 1
	titleHolder.ClipsDescendants = true
	titleHolder.Parent = root
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 1)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.RichText = true
	title.TextStrokeTransparency = 0.7
	title.Text = '<font color="rgb(255,255,255)">VALHALLA CLIENT </font><font color="rgb(255,45,45)">RECODE</font>'
	title.MaxVisibleGraphemes = 0
	title.Parent = titleHolder
	local titleGlow = Instance.new("UIStroke", title) -- red outline pulses once it is fully typed
	titleGlow.Color = Color3.fromRGB(255, 45, 45)
	titleGlow.Thickness = 1.5
	titleGlow.Transparency = 1

	local sweep = Instance.new("Frame")
	sweep.AnchorPoint = Vector2.new(0.5, 0.5)
	sweep.Position = UDim2.fromScale(-0.3, 0.5)
	sweep.Size = UDim2.fromScale(0.2, 2.4)
	sweep.Rotation = 18
	sweep.BackgroundColor3 = Color3.new(1, 1, 1)
	sweep.BackgroundTransparency = 1
	sweep.BorderSizePixel = 0
	sweep.ZIndex = 2
	sweep.Parent = titleHolder
	local sweepGrad = Instance.new("UIGradient", sweep)
	sweepGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.45), NumberSequenceKeypoint.new(1, 1),
	})

	local underline = Instance.new("Frame")
	underline.AnchorPoint = Vector2.new(0.5, 0)
	underline.Position = UDim2.fromScale(0.5, 0.655)
	underline.Size = UDim2.fromOffset(0, 2)
	underline.BackgroundColor3 = Color3.fromRGB(255, 45, 45)
	underline.BackgroundTransparency = 1
	underline.BorderSizePixel = 0
	underline.Parent = root

	local stage = label("Stage", 0.82, 13, Enum.Font.Gotham, Color3.fromRGB(170, 160, 190))
	stage.Size = UDim2.fromScale(0.6, 0.04)
	stage.Text = ""
	local barBack = Instance.new("Frame")
	barBack.AnchorPoint = Vector2.new(0.5, 0.5)
	barBack.Position = UDim2.fromScale(0.5, 0.87)
	barBack.Size = UDim2.new(0.36, 0, 0, 4)
	barBack.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
	barBack.BorderSizePixel = 0
	barBack.Parent = root
	Instance.new("UICorner", barBack).CornerRadius = UDim.new(1, 0)
	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.fromScale(0, 1)
	barFill.BackgroundColor3 = Color3.new(1, 1, 1)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBack
	Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)
	local barGrad = Instance.new("UIGradient", barFill)
	barGrad.Color = ColorSequence.new(Color3.fromRGB(255, 120, 230), Color3.fromRGB(150, 60, 235))

	local function tween(obj, time, props, style, dir)
		local t = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
		t:Play()
		return t
	end
	local function setStage(text, fill)
		stage.Text = text
		tween(barFill, 0.9, { Size = UDim2.fromScale(fill, 1) }, Enum.EasingStyle.Quint)
	end

	task.spawn(function()
		pcall(function()
			tween(blur, 0.8, { Size = 18 })
			tween(root, 0.5, { GroupTransparency = 0 })
			task.wait(0.35)

			tween(logoScale, 0.8, { Scale = 1 }, Enum.EasingStyle.Back)
			tween(logo, 0.5, { TextTransparency = 0 })
			tween(logoStroke, 0.8, { Transparency = 0.25 })
			TweenService:Create(glowScale, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.15 }):Play()
			setStage("Loading modules...", 0.3)
			task.wait(0.9)

			line1.Position = UDim2.fromScale(0.5, 0.515)
			tween(line1, 0.6, { TextTransparency = 0, Position = UDim2.fromScale(0.5, 0.5) })
			task.wait(0.7)

			for i = 1, 22 do -- type "VALHALLA CLIENT RECODE"
				title.MaxVisibleGraphemes = i
				task.wait(0.05)
			end
			title.MaxVisibleGraphemes = -1
			setStage("Building menu...", 0.65)
			tween(underline, 0.6, { BackgroundTransparency = 0.2, Size = UDim2.fromOffset(320, 2) })
			tween(sweep, 0.85, { Position = UDim2.fromScale(1.3, 0.5), BackgroundTransparency = 0.55 }, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
			task.wait(0.9)
			tween(sweep, 0.1, { BackgroundTransparency = 1 })

			TweenService:Create(titleGlow, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 3, true), { Transparency = 0.15 }):Play()
			setStage("Applying theme...", 0.9)
			task.wait(1.2)
			setStage("Ready", 1)
			task.wait(1.0)

			tween(root, 0.7, { GroupTransparency = 1 })
			tween(blur, 0.7, { Size = 0 })
			task.wait(0.75)
		end)
		blur:Destroy()
		splash:Destroy()
	end)
end

local isTouch = UserInputService.TouchEnabled

-- colors of the menu (dark, translucent, blue accent)
local THEME = {
	panel  = Color3.fromRGB(16, 16, 20),
	card   = Color3.fromRGB(27, 27, 33),
	field  = Color3.fromRGB(36, 36, 44),
	off    = Color3.fromRGB(46, 46, 56),
	text   = Color3.fromRGB(235, 235, 242),
	sub    = Color3.fromRGB(125, 125, 140),
	accent = Color3.fromRGB(59, 130, 246),
	onAccent = Color3.new(1, 1, 1), -- text/tick color on top of the accent color
}

--// ===== GUI =====
local gui = Instance.new("ScreenGui")
gui.Name = "AimMenu"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20 -- above the VHS screen effect
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function isPress(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1
		or i.UserInputType == Enum.UserInputType.Touch
end
local function isMove(i)
	return i.UserInputType == Enum.UserInputType.MouseMovement
		or i.UserInputType == Enum.UserInputType.Touch
end

-- FOV circle
local circle = Instance.new("Frame")
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.BackgroundTransparency = 1
circle.Active = false
circle.Parent = gui
Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
do
local cs = Instance.new("UIStroke", circle)
cs.Thickness = 1.5
cs.Color = Color3.new(1, 1, 1)
end -- (scope: keeps the main chunk under the 200-locals limit)

-- key -> function that redraws that toggle/slider/dropdown from Settings (configs, keybinds, themes)
local uiRefresh = {}
local onToggle = {} -- key -> function(value) run after a setting was changed from the menu

local function setSetting(key, value)
	Settings[key] = value
	if uiRefresh[key] then uiRefresh[key]() end
	if onToggle[key] then onToggle[key](value) end
end

--// ----- themes -----
local WHITE, DARK = Color3.new(1, 1, 1), Color3.fromRGB(20, 20, 24)
local THEMES = {
	{ "Red",    Color3.fromRGB(239, 68, 68),   WHITE },
	{ "Blue",   Color3.fromRGB(59, 130, 246),  WHITE },
	{ "White",  Color3.fromRGB(236, 236, 242), DARK },
	{ "Pink",   Color3.fromRGB(236, 72, 153),  WHITE },
	{ "Purple", Color3.fromRGB(139, 92, 246),  WHITE },
	{ "Yellow", Color3.fromRGB(234, 179, 8),   DARK },
	{ "Green",  Color3.fromRGB(34, 197, 94),   WHITE },
	{ "Red-White", Color3.fromRGB(230, 50, 60), WHITE, Color3.fromRGB(245, 245, 250) }, -- 4th value = second color
	{ "New Year",  Color3.fromRGB(220, 50, 60), WHITE, Color3.fromRGB(40, 170, 90) },
	{ "Rainbow",   Color3.fromRGB(255, 90, 90), DARK, Color3.fromRGB(90, 160, 255), true }, -- 5th value: animated
	{ "Ocean",     Color3.fromRGB(0, 190, 210), DARK, Color3.fromRGB(20, 90, 190) },
	{ "Blue-Purple", Color3.fromRGB(59, 130, 246), WHITE, Color3.fromRGB(139, 92, 246) },
	{ "Lime",      Color3.fromRGB(163, 230, 53), DARK },
	{ "Orange",    Color3.fromRGB(249, 115, 22), WHITE },
	{ "Cyan",      Color3.fromRGB(34, 211, 238), DARK },
	{ "Teal",      Color3.fromRGB(20, 184, 166), WHITE },
	{ "Mint",      Color3.fromRGB(110, 231, 183), DARK },
	{ "Crimson",   Color3.fromRGB(190, 24, 60), WHITE },
	{ "Gold",      Color3.fromRGB(212, 175, 55), DARK },
	{ "Silver",    Color3.fromRGB(176, 184, 196), DARK },
	{ "Coral",     Color3.fromRGB(255, 111, 97), WHITE },
	{ "Indigo",    Color3.fromRGB(99, 102, 241), WHITE },
	{ "Magenta",   Color3.fromRGB(217, 70, 239), WHITE },
	{ "Sunset",    Color3.fromRGB(251, 146, 60), WHITE, Color3.fromRGB(236, 72, 153) },
	{ "Sakura",    Color3.fromRGB(251, 182, 206), DARK, Color3.fromRGB(255, 255, 255) },
	{ "Cherry",    Color3.fromRGB(220, 38, 38), WHITE, Color3.fromRGB(236, 72, 153) },
	{ "Forest",    Color3.fromRGB(22, 101, 52), WHITE, Color3.fromRGB(132, 204, 22) },
	{ "Midnight",  Color3.fromRGB(30, 58, 138), WHITE, Color3.fromRGB(126, 34, 206) },
	{ "Neon",      Color3.fromRGB(34, 211, 238), DARK, Color3.fromRGB(217, 70, 239) },
	{ "Lava",      Color3.fromRGB(220, 38, 38), WHITE, Color3.fromRGB(251, 146, 60) },
	{ "Frost",     Color3.fromRGB(255, 255, 255), DARK, Color3.fromRGB(147, 197, 253) },
	{ "Toxic",     Color3.fromRGB(132, 204, 22), DARK, Color3.fromRGB(250, 204, 21) },
	{ "Candy",     Color3.fromRGB(244, 114, 182), DARK, Color3.fromRGB(103, 232, 249) },
	{ "Grape",     Color3.fromRGB(126, 34, 206), WHITE, Color3.fromRGB(236, 72, 153) },
	{ "Sky",       Color3.fromRGB(56, 189, 248), WHITE, Color3.fromRGB(129, 140, 248) },
	{ "Fire",      Color3.fromRGB(239, 68, 68), WHITE, Color3.fromRGB(250, 204, 21) },
	{ "Galaxy",    Color3.fromRGB(88, 28, 135), WHITE, Color3.fromRGB(30, 64, 175) },
	{ "Emerald",   Color3.fromRGB(16, 185, 129), WHITE, Color3.fromRGB(6, 95, 70) },
	{ "Rose Gold", Color3.fromRGB(244, 164, 150), DARK, Color3.fromRGB(212, 175, 55) },
	{ "Halloween", Color3.fromRGB(249, 115, 22), WHITE, Color3.fromRGB(126, 34, 206) },
	{ "Mint-Pink", Color3.fromRGB(110, 231, 183), DARK, Color3.fromRGB(244, 114, 182) },
	{ "Coffee",    Color3.fromRGB(120, 72, 40), WHITE, Color3.fromRGB(230, 200, 160) },
}
local themed = {}        -- { object, property, "accent" | "onAccent" }
local themeHooks = {}    -- extra functions run after a theme change
local gradientOf = setmetatable({}, { __mode = "k" }) -- object -> UIGradient used by two-color themes
local swatchStrokes = {} -- theme name -> outline of its color circle (button theme)
local menuSwatchStrokes = {} -- same for the menu color
local currentPage
local showPage           -- defined below

local function themeBind(obj, prop, which)
	table.insert(themed, { obj, prop, which })
	obj[prop] = THEME[which]
end

local function applyTheme(name)
	local def
	for _, t in ipairs(THEMES) do
		if t[1] == name then def = t end
	end
	if not def then def = THEMES[2] end
	Settings.Theme = def[1]
	local acc, onAcc, acc2 = def[2], def[3], def[4]
	if def[5] then -- animated Rainbow: the hue moves with time
		local h = (os.clock() * 0.08) % 1
		acc, acc2, onAcc = Color3.fromHSV(h, 0.75, 1), Color3.fromHSV((h + 0.2) % 1, 0.75, 1), DARK
	end
	THEME.accent, THEME.onAccent, THEME.accent2 = acc, onAcc, acc2
	THEME.accentFill = acc2 and Color3.new(1, 1, 1) or acc -- color to give gradient-capable backgrounds

	for i = #themed, 1, -1 do
		local e = themed[i]
		local obj = e[1]
		if obj.Parent then
			-- (a gradient would also tint the text of a button, so buttons stay one solid color)
			if e[3] == "accent" and e[2] == "BackgroundColor3"
				and not obj:IsA("TextButton") and not obj:IsA("TextLabel") then
				-- two-color themes paint these as a gradient accent -> accent2
				local g = gradientOf[obj]
				if not g then
					g = Instance.new("UIGradient")
					g.Parent = obj
					gradientOf[obj] = g
				end
				g.Enabled = THEME.accent2 ~= nil
				if THEME.accent2 then g.Color = ColorSequence.new(THEME.accent, THEME.accent2) end
				obj.BackgroundColor3 = THEME.accentFill
			else
				obj[e[2]] = THEME[e[3]]
			end
		else
			table.remove(themed, i)
		end
	end
	for key, fn in pairs(uiRefresh) do -- checkboxes, dropdown highlights ...
		if key ~= "Theme" then fn() end
	end
	for n, stroke in pairs(swatchStrokes) do
		stroke.Transparency = (n == Settings.Theme) and 0 or 1
	end
	if currentPage then showPage(currentPage, true) end
	for _, fn in ipairs(themeHooks) do pcall(fn) end
end
uiRefresh["Theme"] = function() applyTheme(Settings.Theme) end

-- the Rainbow button theme moves 4 times a second
task.spawn(function()
	while true do
		if Settings.Theme == "Rainbow" then applyTheme("Rainbow") end
		task.wait(0.25)
	end
end)

--// ----- menu colors (panel, cards, fields, texts): a theme of its own, buttons keep the button theme -----
local DEFAULT_ROLES = {
	panel = Color3.fromRGB(16, 16, 20), card = Color3.fromRGB(27, 27, 33),
	field = Color3.fromRGB(36, 36, 44), off = Color3.fromRGB(46, 46, 56),
	text = Color3.fromRGB(235, 235, 242), sub = Color3.fromRGB(125, 125, 140),
}
local LIGHT_ROLES = { -- the "White" menu is a light menu with dark texts
	panel = Color3.fromRGB(238, 238, 243), card = Color3.fromRGB(222, 222, 230),
	field = Color3.fromRGB(206, 206, 216), off = Color3.fromRGB(186, 186, 198),
	text = Color3.fromRGB(28, 28, 34), sub = Color3.fromRGB(105, 105, 120),
}
local ROLE_NAMES = { "panel", "card", "field", "off", "text", "sub" }

local function menuRolesFor(def)
	if not def then return DEFAULT_ROLES end
	if def[1] == "White" then return LIGHT_ROLES end
	local c1, c2 = def[2], def[4] or def[2] -- panel from the first color, cards from the second
	if def[5] then
		local h = (os.clock() * 0.05) % 1
		c1, c2 = Color3.fromHSV(h, 0.8, 1), Color3.fromHSV((h + 0.3) % 1, 0.8, 1)
	end
	local h1, s1 = c1:ToHSV()
	local h2, s2 = c2:ToHSV()
	return {
		panel = Color3.fromHSV(h1, math.min(s1 * 0.55, 0.6), 0.075),
		card = Color3.fromHSV(h2, math.min(s2 * 0.45, 0.5), 0.115),
		field = Color3.fromHSV(h2, math.min(s2 * 0.4, 0.45), 0.165),
		off = Color3.fromHSV(h2, math.min(s2 * 0.35, 0.4), 0.22),
		text = DEFAULT_ROLES.text,
		sub = Color3.fromHSV(h1, 0.18, 0.62),
	}
end

local function sameColor(a, b)
	return math.abs(a.R - b.R) < 0.0015 and math.abs(a.G - b.G) < 0.0015 and math.abs(a.B - b.B) < 0.0015
end

local function applyMenuTheme(name)
	local def
	for _, t in ipairs(THEMES) do
		if t[1] == name then def = t end
	end
	Settings.MenuTheme = def and def[1] or "Default"
	local new = menuRolesFor(def)
	local old = {}
	for _, role in ipairs(ROLE_NAMES) do old[role] = THEME[role] end

	local function remap(c)
		for _, role in ipairs(ROLE_NAMES) do
			if sameColor(c, old[role]) then return new[role] end
		end
		return nil
	end
	-- every object of the menu, the module list, watermark, cards ... that uses one of the old colors
	for _, d in ipairs(gui:GetDescendants()) do
		if d:IsA("GuiObject") then
			local c = remap(d.BackgroundColor3)
			if c then d.BackgroundColor3 = c end
			if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
				local tc = remap(d.TextColor3)
				if tc then d.TextColor3 = tc end
				if d:IsA("TextBox") then
					local pc = remap(d.PlaceholderColor3)
					if pc then d.PlaceholderColor3 = pc end
				end
			end
			if d:IsA("ScrollingFrame") then
				local sc = remap(d.ScrollBarImageColor3)
				if sc then d.ScrollBarImageColor3 = sc end
			end
		end
	end
	for _, role in ipairs(ROLE_NAMES) do THEME[role] = new[role] end -- objects created later use them too

	for key, fn in pairs(uiRefresh) do -- dropdown highlights, checkboxes ...
		if key ~= "MenuTheme" and key ~= "Theme" then fn() end
	end
	for n, stroke in pairs(menuSwatchStrokes) do
		stroke.Transparency = (n == Settings.MenuTheme) and 0 or 1
	end
	if currentPage then showPage(currentPage, true) end
end
uiRefresh["MenuTheme"] = function() applyMenuTheme(Settings.MenuTheme) end

--// ----- module list HUD (top-left, like the "Keybinds" list) -----
local HUD_MODULES = {
	{ "Aim", "AimEnabled" }, { "Silent Aim", "SilentAim" }, { "Wall Fire", "WallFire" },
	{ "ESP", "ESPEnabled" }, { "Tracers", "Tracers" }, { "Fullbright", "Fullbright" },
	{ "Shader", "Shader" }, { "World Particles", "WorldParticles" },
	{ "View Model", "ViewModel" }, { "Hand Shader", "HandShader" }, { "Target ESP", "TargetESP" }, { "Hands XZ", "HandsXZ" },
	{ "God Mode", "GodMode" }, { "Fly+", "FlyPlus" }, { "Hands XZ2", "HandsXZ2" }, { "Screen", "Screen" }, { "Shaders+", "ShaderPlus" }, { "Target Particles", "TargetParticles" },
	{ "Infinite Jump", "InfiniteJump" }, { "Auto Grab", "AutoGrab" }, { "Air Stuck", "AirStuck" }, { "Beautiful", "Beautiful" },
	{ "Jump Circle", "JumpCircle" }, { "Player Trail", "PlayerTrail" },
	{ "Auto Sprint", "AutoSprint" }, { "No Recoil", "NoRecoil" }, { "Fast Reload", "FastReload" }, { "Hitbox", "Hitbox" }, { "Name Tags", "NameTags" }, { "Crosshair", "Crosshair" },
	{ "FOV", "FovChanger" }, { "Radar", "Radar" }, { "Spin Bot", "SpinBot" },
	{ "Tap Teleport", "TapTeleport" }, { "Free Cam", "FreeCam" }, { "Gravity", "GravityMod" }, { "Auto Clicker", "AutoClicker" },
	{ "Fly", "FlyEnabled" }, { "Speed", "SpeedEnabled" }, { "Noclip", "Noclip" },
	{ "Instant Prompt", "InstantPrompt" }, { "Music", "Music" }, { "Box ESP", "BoxESP2" }, { "Low Health Warning", "LowHealth" }, { "Xadesa Mod", "XadesaMod" }, { "Fling", "Fling" }, { "Anti Fling", "AntiFling" }, { "Afterimage", "Afterimage" }, { "Rewind", "Rewind" }, { "Grapple", "Grapple" }, { "Lightning Storm", "Lightning" }, { "Winter", "Winter" }, { "Washed", "Washed" },
}
local hud = Instance.new("TextLabel")
hud.Position = UDim2.fromOffset(64, 70)
hud.Size = UDim2.fromOffset(0, 0)
hud.AutomaticSize = Enum.AutomaticSize.XY
hud.BackgroundColor3 = THEME.panel
hud.BackgroundTransparency = 0.12
hud.TextColor3 = THEME.text
hud.Font = Enum.Font.GothamMedium
hud.TextSize = 12
hud.RichText = true
hud.TextXAlignment = Enum.TextXAlignment.Left
hud.TextYAlignment = Enum.TextYAlignment.Top
hud.Visible = false
hud.Parent = gui
Instance.new("UICorner", hud).CornerRadius = UDim.new(0, 8)
do
	local p = Instance.new("UIPadding", hud)
	p.PaddingTop, p.PaddingBottom = UDim.new(0, 6), UDim.new(0, 6)
	p.PaddingLeft, p.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
end

local function updateHud()
	if not Settings.ShowList then hud.Visible = false return end
	local lines = { '<font color="#7d7d8c">Modules</font>' }
	for _, m in ipairs(HUD_MODULES) do
		if Settings[m[2]] then table.insert(lines, m[1]) end
	end
	hud.Visible = #lines > 1
	hud.Text = table.concat(lines, "\n")
end

--// ----- main panel (CanvasGroup so the whole menu can fade) -----
local menu = Instance.new("CanvasGroup")
menu.AnchorPoint = Vector2.new(0.5, 0.5)
menu.Position = UDim2.fromScale(0.5, 0.5)
menu.Size = isTouch and UDim2.fromScale(0.95, 0.82) or UDim2.fromScale(0.8, 0.85) -- phones: use more of the screen
menu.BackgroundColor3 = THEME.panel
menu.BackgroundTransparency = 0.06
menu.BorderSizePixel = 0
menu.GroupTransparency = 1
menu.Visible = false
menu.Parent = gui
Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 16)
local menuScale = Instance.new("UIScale", menu)
menuScale.Scale = 0.9
do
	-- the menu never exceeds the screen: on a narrow phone the min/max shrink to fit
	local sizeConstraint = Instance.new("UISizeConstraint", menu)
	local function updateMenuConstraints()
		local cam = workspace.CurrentCamera
		local vp = (cam and cam.ViewportSize) or Vector2.new(800, 600)
		local maxW, maxH = math.min(680, vp.X - 16), math.min(340, vp.Y - 90)
		sizeConstraint.MaxSize = Vector2.new(maxW, maxH)
		sizeConstraint.MinSize = Vector2.new(math.min(420, maxW), math.min(210, maxH))
	end
	updateMenuConstraints()
	local function hookCamera(cam)
		if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateMenuConstraints) end
	end
	hookCamera(workspace.CurrentCamera)
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		hookCamera(workspace.CurrentCamera)
		updateMenuConstraints()
	end)

	local glow = Instance.new("UIStroke", menu) -- soft ambient glow around the whole panel
	glow.Thickness = 7
	glow.Transparency = 0.85
	themeBind(glow, "Color", "accent")

	local st = Instance.new("UIStroke", menu)
	st.Thickness = 1.5
	st.Transparency = 0.45
	themeBind(st, "Color", "accent")
end

-- open / close animation: scale pop + fade
local menuOpen = false
local menuTweens = {}
local function setMenu(open)
	menuOpen = open
	for _, t in ipairs(menuTweens) do t:Cancel() end
	if open then
		if not menu.Visible then
			menuScale.Scale = 0.9
			menu.GroupTransparency = 1
		end
		menu.Visible = true
		menuTweens = {
			TweenService:Create(menuScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }),
			TweenService:Create(menu, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0 }),
		}
	else
		local fade = TweenService:Create(menu, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { GroupTransparency = 1 })
		menuTweens = {
			TweenService:Create(menuScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.92 }),
			fade,
		}
		fade.Completed:Connect(function(state)
			if not menuOpen and state == Enum.PlaybackState.Completed then menu.Visible = false end
		end)
	end
	for _, t in ipairs(menuTweens) do t:Play() end
end

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(12, 0)
title.Size = UDim2.new(0.5, -12, 0, 28)
title.BackgroundTransparency = 1
title.Active = true
title.Text = "Aim Assist  -  drag here"
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = THEME.sub
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.Parent = menu

local status = Instance.new("TextLabel")
status.Position = UDim2.new(0.5, 0, 0, 0)
status.Size = UDim2.new(0.5, -12, 0, 28)
status.BackgroundTransparency = 1
status.TextXAlignment = Enum.TextXAlignment.Right
status.TextColor3 = THEME.sub
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.Text = "Target: none"
status.Parent = menu

-- the Rainbow menu color moves twice a second, only while the menu is open
task.spawn(function()
	while true do
		if Settings.MenuTheme == "Rainbow" and menu.Visible then applyMenuTheme("Rainbow") end
		task.wait(0.5)
	end
end)

-- drag the menu by its title
do
	local dragInput, dragStart, startPos
	title.InputBegan:Connect(function(i)
		if isPress(i) then
			dragInput, dragStart, startPos = i, i.Position, menu.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragInput and isMove(i)
			and (i == dragInput or i.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = i.Position - dragStart
			menu.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i == dragInput then dragInput = nil end
	end)
end

--// ----- pages (tabs at the bottom, columns of cards per page) -----
local holder = Instance.new("Frame")
holder.Position = UDim2.fromOffset(8, 30)
holder.Size = UDim2.new(1, -16, 1, -72)
holder.BackgroundTransparency = 1
holder.Parent = menu

-- dark veil that fades out when a page appears (page-switch animation)
local holderFade = Instance.new("Frame")
holderFade.Size = UDim2.fromScale(1, 1)
holderFade.BackgroundColor3 = THEME.panel
holderFade.BackgroundTransparency = 1
holderFade.BorderSizePixel = 0
holderFade.Active = false
holderFade.ZIndex = 50
holderFade.Parent = holder

local tabBarOuter = Instance.new("Frame")
tabBarOuter.AnchorPoint = Vector2.new(0.5, 1)
tabBarOuter.Position = UDim2.new(0.5, 0, 1, -8)
tabBarOuter.Size = UDim2.new(0.94, 0, 0, 28)
tabBarOuter.BackgroundColor3 = THEME.card
tabBarOuter.BorderSizePixel = 0
tabBarOuter.Parent = menu
Instance.new("UICorner", tabBarOuter).CornerRadius = UDim.new(0, 14)

-- the tabs scroll sideways: with this many tabs they would not all fit a phone screen otherwise
local tabBar = Instance.new("ScrollingFrame")
tabBar.Size = UDim2.fromScale(1, 1)
tabBar.BackgroundTransparency = 1
tabBar.BorderSizePixel = 0
tabBar.ScrollBarThickness = 3
tabBar.ScrollBarImageColor3 = THEME.off
tabBar.ScrollingDirection = Enum.ScrollingDirection.X
tabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
tabBar.CanvasSize = UDim2.new()
tabBar.Parent = tabBarOuter
do
	local l = Instance.new("UIListLayout", tabBar)
	l.FillDirection = Enum.FillDirection.Horizontal
	l.Padding = UDim.new(0, 2)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.VerticalAlignment = Enum.VerticalAlignment.Center
	local p = Instance.new("UIPadding", tabBar)
	p.PaddingLeft, p.PaddingRight = UDim.new(0, 4), UDim.new(0, 4)
end

local pages, tabs, tabBars, onPageShown = {}, {}, {}, {}
local pageNameOf = {} -- page frame -> tab name (used by the search)
local pageCols = {}   -- tab name -> its columns
local orderOf = setmetatable({}, { __mode = "k" })
local function place(parent, obj) -- parent with a running LayoutOrder (keeps creation order)
	orderOf[parent] = (orderOf[parent] or 0) + 1
	obj.LayoutOrder = orderOf[parent]
	obj.Parent = parent
end

showPage = function(name, instant)
	local changed = name ~= currentPage
	currentPage = name
	for n, pg in pairs(pages) do
		pg.Visible = (n == name)
		if n ~= name then pg.Position = UDim2.fromOffset(0, 0) end
	end
	for n, b in pairs(tabs) do
		local active = (n == name)
		local textColor = active and THEME.accent or THEME.sub
		local barSize = UDim2.new(active and 0.6 or 0, 0, 0, 3)
		tabBars[n].BackgroundColor3 = THEME.accent
		if instant then
			b.TextColor3 = textColor
			tabBars[n].Size = barSize
		else
			TweenService:Create(b, TweenInfo.new(0.18), { TextColor3 = textColor }):Play()
			TweenService:Create(tabBars[n], TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Size = barSize }):Play()
		end
	end
	if changed and not instant then
		local pg = pages[name]
		pg.Position = UDim2.fromOffset(0, 18)
		TweenService:Create(pg, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ Position = UDim2.fromOffset(0, 0) }):Play()
		holderFade.BackgroundTransparency = 0.25
		TweenService:Create(holderFade, TweenInfo.new(0.28, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
	end
	if onPageShown[name] and not instant then onPageShown[name]() end
end

-- single = true gives one full-width column instead of three
local function newPage(name, single)
	local pg = Instance.new("Frame")
	pg.Size = UDim2.fromScale(1, 1)
	pg.BackgroundTransparency = 1
	pg.Visible = false
	pg.Parent = holder
	local l = Instance.new("UIListLayout", pg)
	l.FillDirection = Enum.FillDirection.Horizontal
	l.Padding = UDim.new(0, 8)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	pages[name] = pg
	pageNameOf[pg] = name

	local cols = {}
	for i = 1, (single and 1 or 3) do
		local col = Instance.new("ScrollingFrame")
		col.LayoutOrder = i
		col.Size = single and UDim2.new(1, 0, 1, 0) or UDim2.new(1 / 3, -6, 1, 0)
		col.BackgroundTransparency = 1
		col.BorderSizePixel = 0
		col.ScrollBarThickness = 3
		col.ScrollBarImageColor3 = THEME.off
		col.ScrollingDirection = Enum.ScrollingDirection.Y
		col.AutomaticCanvasSize = Enum.AutomaticSize.Y
		col.CanvasSize = UDim2.new()
		col.Parent = pg
		local cl = Instance.new("UIListLayout", col)
		cl.Padding = UDim.new(0, 8)
		cl.SortOrder = Enum.SortOrder.LayoutOrder
		cols[i] = col
	end

	pageCols[name] = cols
	local tab = Instance.new("TextButton")
	tab.Size = UDim2.fromOffset(52, 24)
	tab.BackgroundTransparency = 1
	tab.Text = name
	tab.Font = Enum.Font.GothamMedium
	tab.TextSize = 11
	tab.TextColor3 = THEME.sub
	place(tabBar, tab)
	tab.Activated:Connect(function() showPage(name) end)
	tabs[name] = tab

	local bar = Instance.new("Frame") -- underline of the active tab
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, 0)
	bar.Size = UDim2.new(0, 0, 0, 3)
	bar.BorderSizePixel = 0
	bar.Parent = tab
	themeBind(bar, "BackgroundColor3", "accent")
	tabBars[name] = bar
	return cols
end

--// ----- keybinds (PC): click the chip on a card, press a key; Esc clears -----
local binds = {}     -- Settings key -> KeyCode
local listening      -- { key =, chip = }
UserInputService.InputBegan:Connect(function(i, processed)
	if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
	if listening then
		local l = listening
		listening = nil
		binds[l.key] = (i.KeyCode ~= Enum.KeyCode.Escape) and i.KeyCode or nil
		l.chip.Text = binds[l.key] and binds[l.key].Name:upper() or "NONE"
		return
	end
	if processed then return end
	for key, kc in pairs(binds) do
		if kc == i.KeyCode then setSetting(key, not Settings[key]) end
	end
end)

--// ----- components -----
local function mkLabel(parent, text, size, color, font)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size
	l.TextColor3 = color
	l.Font = font
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

-- checkbox bound to Settings[key]; returns the box and a flip() function
local function attachToggle(host, key, px)
	local box = Instance.new("TextButton")
	box.AnchorPoint = Vector2.new(1, 0.5)
	box.Position = UDim2.new(1, 0, 0.5, 0)
	box.Size = UDim2.fromOffset(px, px)
	box.AutoButtonColor = false
	box.BorderSizePixel = 0
	box.Font = Enum.Font.GothamBold
	box.TextSize = 12
	box.Parent = host
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)
	local boxScale = Instance.new("UIScale", box)
	local shown -- the state last drawn (nil = nothing drawn yet, so the first draw is instant)
	local function refresh()
		local on = Settings[key] and true or false
		local color = on and THEME.accent or THEME.off
		box.TextColor3 = THEME.onAccent
		box.Text = on and "✓" or ""
		if shown ~= nil and shown ~= on then
			TweenService:Create(box, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = color }):Play()
			boxScale.Scale = 0.78
			TweenService:Create(boxScale, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		else
			box.BackgroundColor3 = color
		end
		shown = on
		updateHud()
	end
	local function flip() setSetting(key, not Settings[key]) end
	box.Activated:Connect(flip)
	uiRefresh[key] = refresh
	refresh()
	return box, flip
end

-- registry of all modules (cards) for the search: name, tab, description, names of the settings inside
local cardInfo = setmetatable({}, { __mode = "k" })
local moduleList = {}
local function addItem(card, text)
	local info = cardInfo[card]
	if info then table.insert(info.items, text) end
end

-- card with a header: title, [keybind chip], [master toggle]; returns card, title label
-- small keybind chip (PC only elsewhere; this helper itself has no isTouch check so it can be reused)
local function addBindChip(host, key)
	local chip = Instance.new("TextButton")
	chip.AnchorPoint = Vector2.new(1, 0.5)
	chip.Position = UDim2.new(1, -26, 0.5, 0)
	chip.Size = UDim2.fromOffset(46, 18)
	chip.BackgroundColor3 = THEME.field
	chip.BorderSizePixel = 0
	chip.AutoButtonColor = false
	chip.Text = (binds[key] and binds[key].Name:upper()) or "NONE"
	chip.TextColor3 = THEME.sub
	chip.Font = Enum.Font.GothamMedium
	chip.TextSize = 9
	chip.TextTruncate = Enum.TextTruncate.AtEnd
	chip.Parent = host
	Instance.new("UICorner", chip).CornerRadius = UDim.new(0, 5)
	chip.Activated:Connect(function()
		listening = { key = key, chip = chip }
		chip.Text = "..."
	end)
	return chip
end

-- ===== phone binds =====
-- On a phone, the chip next to a function puts a round button for it on the screen (max 5).
-- Tap the button to switch the function on/off, drag it to move it, tap the x to remove it,
-- or tap the chip again.
local TOUCH_MAX = 5
local touchBinds = {} -- slot (1..3) -> { key =, btn = }
local touchChips = {} -- { key =, chip = }

local function touchSlotOf(key)
	for slot, b in pairs(touchBinds) do
		if b.key == key then return slot end
	end
end

local function refreshTouchChips()
	for _, e in ipairs(touchChips) do
		local on = touchSlotOf(e.key) ~= nil
		e.chip.Text = on and "ADDED" or "BTN"
		e.chip.BackgroundColor3 = on and THEME.accent or THEME.field
		e.chip.TextColor3 = on and THEME.onAccent or THEME.sub
	end
end

local function removeTouchBind(slot)
	local b = touchBinds[slot]
	if b then
		b.btn:Destroy()
		touchBinds[slot] = nil
	end
	refreshTouchChips()
end

local function addTouchBind(key, label)
	local free
	for slot = 1, TOUCH_MAX do
		if not touchBinds[slot] then free = slot break end
	end
	if not free then return false end

	local btn = Instance.new("TextButton")
	btn.Name = "AA_TouchBind" .. free
	btn.AnchorPoint = Vector2.new(0, 0.5)
	btn.Position = UDim2.new(0, 190, 0.16 + 0.14 * (free - 1), 0)
	btn.Size = UDim2.fromOffset(62, 62)
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.TextScaled = true
	btn.TextWrapped = true
	btn.Text = label
	btn.Parent = gui
	Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
	local limit = Instance.new("UITextSizeConstraint", btn)
	limit.MaxTextSize, limit.MinTextSize = 12, 7
	local ring = Instance.new("UIStroke", btn)
	ring.Thickness = 2

	local x = Instance.new("TextButton") -- small remove badge on the corner
	x.AnchorPoint = Vector2.new(0.5, 0.5)
	x.Position = UDim2.fromScale(0.86, 0.14)
	x.Size = UDim2.fromOffset(22, 22)
	x.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
	x.BorderSizePixel = 0
	x.AutoButtonColor = false
	x.Font = Enum.Font.GothamBold
	x.TextSize = 14
	x.TextColor3 = Color3.new(1, 1, 1)
	x.Text = "×"
	x.ZIndex = 2
	x.Parent = btn
	Instance.new("UICorner", x).CornerRadius = UDim.new(1, 0)
	x.Activated:Connect(function() removeTouchBind(free) end)

	-- tap = switch the function, drag = move the button
	btn.InputBegan:Connect(function(i)
		if not isPress(i) then return end
		local isMouse = i.UserInputType == Enum.UserInputType.MouseButton1
		local startPos = isMouse and UserInputService:GetMouseLocation() or Vector2.new(i.Position.X, i.Position.Y)
		local startUi = btn.Position
		local moved = false
		local changed, ended
		changed = UserInputService.InputChanged:Connect(function(ch)
			if ch == i or (isMouse and ch.UserInputType == Enum.UserInputType.MouseMovement) then
				local pos = isMouse and UserInputService:GetMouseLocation() or Vector2.new(ch.Position.X, ch.Position.Y)
				local d = pos - startPos
				if moved or d.Magnitude > 10 then
					moved = true
					btn.Position = UDim2.new(startUi.X.Scale, startUi.X.Offset + d.X, startUi.Y.Scale, startUi.Y.Offset + d.Y)
				end
			end
		end)
		ended = UserInputService.InputEnded:Connect(function(e)
			if e == i then
				changed:Disconnect()
				ended:Disconnect()
				if not moved then setSetting(key, not Settings[key]) end
			end
		end)
	end)

	touchBinds[free] = { key = key, btn = btn, ring = ring }
	return true
end

-- the buttons show the current state of their function
RunService.Heartbeat:Connect(function()
	for _, b in pairs(touchBinds) do
		local on = Settings[b.key] and true or false
		b.btn.BackgroundColor3 = on and THEME.accent or Color3.fromRGB(28, 28, 34)
		b.btn.TextColor3 = on and THEME.onAccent or Color3.new(1, 1, 1)
		b.btn.BackgroundTransparency = on and 0.1 or 0.25
		b.ring.Color = THEME.accent
	end
end)

local function addTouchChip(host, key, label)
	local chip = Instance.new("TextButton")
	chip.AnchorPoint = Vector2.new(1, 0.5)
	chip.Position = UDim2.new(1, -26, 0.5, 0)
	chip.Size = UDim2.fromOffset(46, 18)
	chip.BackgroundColor3 = THEME.field
	chip.BorderSizePixel = 0
	chip.AutoButtonColor = false
	chip.Text = "BTN"
	chip.TextColor3 = THEME.sub
	chip.Font = Enum.Font.GothamMedium
	chip.TextSize = 9
	chip.Parent = host
	Instance.new("UICorner", chip).CornerRadius = UDim.new(0, 5)
	touchChips[#touchChips + 1] = { key = key, chip = chip }
	chip.Activated:Connect(function()
		local slot = touchSlotOf(key)
		if slot then
			removeTouchBind(slot)
		elseif not addTouchBind(key, label) then
			chip.Text = "MAX 5"
			task.delay(1, refreshTouchChips)
		else
			refreshTouchChips()
		end
	end)
	refreshTouchChips()
	return chip
end

-- a thin, near-invisible light line along the top edge, for a soft "glass" highlight look
local function topHighlight(parent)
	local h = Instance.new("Frame")
	h.Position = UDim2.fromOffset(6, 0)
	h.Size = UDim2.new(1, -12, 0, 1)
	h.BackgroundColor3 = Color3.new(1, 1, 1)
	h.BackgroundTransparency = 0.88
	h.BorderSizePixel = 0
	h.Parent = parent
	return h
end

local function newCard(col, titleText, key)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -4, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = THEME.card
	card.BorderSizePixel = 0
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 11)
	do
		local edge = Instance.new("UIStroke", card) -- soft glass edge (a child Frame would join the list layout)
		edge.Color = Color3.new(1, 1, 1)
		edge.Transparency = 0.93
		edge.Thickness = 1
	end
	local pad = Instance.new("UIPadding", card)
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 8), UDim.new(0, 8)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 9), UDim.new(0, 9)
	local list = Instance.new("UIListLayout", card)
	list.Padding = UDim.new(0, 6)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	place(col, card)

	local pageFrame = col:IsA("ScrollingFrame") and col.Parent or nil
	local info = { name = titleText, key = key, items = {}, card = card, page = pageFrame and pageNameOf[pageFrame] }
	cardInfo[card] = info
	if info.page then table.insert(moduleList, info) end

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 20)
	header.BackgroundTransparency = 1
	place(card, header)

	local reserve = 0
	if key then
		attachToggle(header, key, 18)
		if isTouch then addTouchChip(header, key, titleText) else addBindChip(header, key) end
		reserve = 76
	end
	local t = mkLabel(header, titleText, 13, THEME.text, Enum.Font.GothamBold)
	t.Size = UDim2.new(1, -reserve, 1, 0)
	return card, t
end

local function makeNote(card, text)
	local l = mkLabel(card, text, 10, THEME.sub, Enum.Font.Gotham)
	l.Size = UDim2.new(1, 0, 0, 0)
	l.AutomaticSize = Enum.AutomaticSize.Y
	l.TextWrapped = true
	l.TextYAlignment = Enum.TextYAlignment.Top
	place(card, l)
	local info = cardInfo[card]
	if info and not info.desc then info.desc = text end
	return l
end

-- setting row: name + small description on the left, checkbox on the right
local function makeToggle(card, text, key, desc)
	addItem(card, text)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, desc and 32 or 24)
	row.BackgroundTransparency = 1
	place(card, row)

	local hit = Instance.new("TextButton")
	hit.Size = UDim2.fromScale(1, 1)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.Parent = row

	local reserve = 78 -- room for the bind chip (keyboard on PC, on-screen button on phones)
	local name = mkLabel(row, text, 12, THEME.text, Enum.Font.GothamMedium)
	name.Position = UDim2.fromOffset(0, desc and 2 or 0)
	name.Size = UDim2.new(1, -reserve, 0, desc and 14 or 24)
	if desc then
		local d = mkLabel(row, desc, 10, THEME.sub, Enum.Font.Gotham)
		d.Position = UDim2.fromOffset(0, 17)
		d.Size = UDim2.new(1, -reserve, 0, 12)
	end
	local _, flip = attachToggle(row, key, 18)
	hit.Activated:Connect(flip)
	if isTouch then addTouchChip(row, key, text) else addBindChip(row, key) end
end

local function makeSlider(card, text, min, max, key, decimals)
	addItem(card, text)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 36)
	row.BackgroundTransparency = 1
	place(card, row)

	local name = mkLabel(row, text, 12, THEME.text, Enum.Font.GothamMedium)
	name.Size = UDim2.new(0.7, 0, 0, 14)
	local value = mkLabel(row, "", 11, THEME.sub, Enum.Font.Gotham)
	value.Position = UDim2.fromScale(0.7, 0)
	value.Size = UDim2.new(0.3, 0, 0, 14)
	value.TextXAlignment = Enum.TextXAlignment.Right

	local hit = Instance.new("TextButton")
	hit.Text = ""
	hit.AutoButtonColor = false
	hit.BackgroundTransparency = 1
	hit.Position = UDim2.fromOffset(0, 14)
	hit.Size = UDim2.new(1, 0, 0, 22)
	hit.Parent = row

	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0, 0.5)
	bar.Size = UDim2.new(1, 0, 0, 6)
	bar.Position = UDim2.fromScale(0, 0.5)
	bar.BackgroundColor3 = THEME.off
	bar.BorderSizePixel = 0
	bar.Active = false
	bar.Parent = hit
	Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame")
	fill.BorderSizePixel = 0
	fill.Parent = bar
	themeBind(fill, "BackgroundColor3", "accent")
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
	local knob = Instance.new("Frame")
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(1, 0, 0.5, 0)
	knob.Size = UDim2.fromOffset(13, 13)
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	knob.BorderSizePixel = 0
	knob.Active = false
	knob.Parent = fill
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
	local knobStroke = Instance.new("UIStroke", knob)
	knobStroke.Thickness = 2
	themeBind(knobStroke, "Color", "accent")

	local function setValue(v)
		v = math.clamp(v, min, max)
		local m = 10 ^ decimals
		Settings[key] = math.floor(v * m + 0.5) / m
		fill.Size = UDim2.new((Settings[key] - min) / (max - min), 0, 1, 0)
		value.Text = tostring(Settings[key])
	end
	setValue(Settings[key])
	uiRefresh[key] = function() setValue(Settings[key]) end

	local dragInput, scrollCol
	local function update(x)
		local a = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		setValue(min + (max - min) * a)
	end
	hit.InputBegan:Connect(function(i)
		if isPress(i) then
			dragInput = i
			scrollCol = card:FindFirstAncestorWhichIsA("ScrollingFrame")
			if scrollCol then scrollCol.ScrollingEnabled = false end
			update(i.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragInput and isMove(i)
			and (i == dragInput or i.UserInputType == Enum.UserInputType.MouseMovement) then
			update(i.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i == dragInput then
			dragInput = nil
			if scrollCol then scrollCol.ScrollingEnabled = true end
		end
	end)
end

-- plain button in the theme color; returns the TextButton so other code can change its text
local function makeAction(card, text)
	addItem(card, text)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 28)
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 12
	btn.BorderSizePixel = 0
	btn.Text = text
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	themeBind(btn, "BackgroundColor3", "accent")
	themeBind(btn, "TextColor3", "onAccent")
	topHighlight(btn)
	local press = Instance.new("UIScale", btn)
	btn.InputBegan:Connect(function(i)
		if isPress(i) then
			TweenService:Create(press, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.95 }):Play()
		elseif i.UserInputType == Enum.UserInputType.MouseMovement then
			btn.BackgroundTransparency = 0.12
		end
	end)
	btn.InputEnded:Connect(function(i)
		if isPress(i) then
			TweenService:Create(press, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		elseif i.UserInputType == Enum.UserInputType.MouseMovement then
			btn.BackgroundTransparency = 0
		end
	end)
	place(card, btn)
	return btn
end

local function makeTextBox(card, placeholder)
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, 0, 0, 28)
	box.BackgroundColor3 = THEME.field
	box.BorderSizePixel = 0
	box.TextColor3 = THEME.text
	box.PlaceholderText = placeholder
	box.PlaceholderColor3 = THEME.sub
	box.Text = ""
	box.ClearTextOnFocus = false
	box.Font = Enum.Font.Gotham
	box.TextSize = 12
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.TextTruncate = Enum.TextTruncate.AtEnd
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
	Instance.new("UIPadding", box).PaddingLeft = UDim.new(0, 8)
	local focusEdge = Instance.new("UIStroke", box) -- accent edge while typing
	focusEdge.Thickness = 1.5
	focusEdge.Transparency = 1
	themeBind(focusEdge, "Color", "accent")
	box.Focused:Connect(function()
		TweenService:Create(focusEdge, TweenInfo.new(0.15), { Transparency = 0.15 }):Play()
	end)
	box.FocusLost:Connect(function()
		TweenService:Create(focusEdge, TweenInfo.new(0.2), { Transparency = 1 }):Play()
	end)
	place(card, box)
	return box
end

-- dropdown: caption, field with the current value, list that opens below it
local function makeDropdown(card, text, key, options)
	addItem(card, text)
	local box = Instance.new("Frame")
	box.Size = UDim2.new(1, 0, 0, 0)
	box.AutomaticSize = Enum.AutomaticSize.Y
	box.BackgroundTransparency = 1
	place(card, box)
	local l = Instance.new("UIListLayout", box)
	l.Padding = UDim.new(0, 3)
	l.SortOrder = Enum.SortOrder.LayoutOrder

	local cap = mkLabel(box, text, 12, THEME.text, Enum.Font.GothamMedium)
	cap.Size = UDim2.new(1, 0, 0, 14)
	place(box, cap)

	local field = Instance.new("TextButton")
	field.Size = UDim2.new(1, 0, 0, 26)
	field.BackgroundColor3 = THEME.field
	field.BorderSizePixel = 0
	field.AutoButtonColor = false
	field.TextXAlignment = Enum.TextXAlignment.Left
	field.Font = Enum.Font.Gotham
	field.TextSize = 12
	field.TextColor3 = THEME.text
	Instance.new("UICorner", field).CornerRadius = UDim.new(0, 6)
	Instance.new("UIPadding", field).PaddingLeft = UDim.new(0, 8)
	place(box, field)
	local arrow = mkLabel(field, "▼", 8, THEME.sub, Enum.Font.Gotham)
	arrow.AnchorPoint = Vector2.new(1, 0.5)
	arrow.Position = UDim2.new(1, -6, 0.5, 0)
	arrow.Size = UDim2.fromOffset(12, 12)

	local openEdge = Instance.new("UIStroke", field) -- accent edge while the list is open
	openEdge.Thickness = 1.5
	openEdge.Transparency = 1
	themeBind(openEdge, "Color", "accent")

	local list = Instance.new("Frame")
	list.Size = UDim2.new(1, 0, 0, 0)
	list.AutomaticSize = Enum.AutomaticSize.Y
	list.BackgroundColor3 = THEME.field
	list.BorderSizePixel = 0
	list.Visible = false
	Instance.new("UICorner", list).CornerRadius = UDim.new(0, 6)
	local ll = Instance.new("UIListLayout", list)
	ll.SortOrder = Enum.SortOrder.LayoutOrder
	place(box, list)

	local optButtons = {}
	local function refresh()
		local valid = false
		for _, o in ipairs(options) do if o == Settings[key] then valid = true end end
		if not valid then Settings[key] = options[1] end
		field.Text = tostring(Settings[key])
		for o, b in pairs(optButtons) do
			b.Text = (o == Settings[key]) and (o .. "   ✓") or o
			b.TextColor3 = (o == Settings[key]) and THEME.accent or THEME.text
		end
	end
	for idx, o in ipairs(options) do
		local b = Instance.new("TextButton")
		b.LayoutOrder = idx
		b.Size = UDim2.new(1, 0, 0, 24)
		b.BackgroundTransparency = 1
		b.Font = Enum.Font.Gotham
		b.TextSize = 12
		b.TextXAlignment = Enum.TextXAlignment.Left
		Instance.new("UIPadding", b).PaddingLeft = UDim.new(0, 8)
		b.Parent = list
		optButtons[o] = b
		b.Activated:Connect(function()
			list.Visible = false
			arrow.Text = "▼"
			openEdge.Transparency = 1
			setSetting(key, o)
		end)
	end
	field.Activated:Connect(function()
		list.Visible = not list.Visible
		arrow.Text = list.Visible and "▲" or "▼"
		TweenService:Create(openEdge, TweenInfo.new(0.15), { Transparency = list.Visible and 0.2 or 1 }):Play()
	end)
	uiRefresh[key] = refresh
	refresh()
end

--// ----- build the pages -----
local pickBtn, tpBtn, backBtn, healthBtn, invisBtn

local cols = newPage("Combat")
local c = newCard(cols[1], "Aim", "AimEnabled")
makeNote(c, "Camera follows the target. Hold RMB on PC; on phones it is always active while Aim is on.")
makeSlider(c, "FOV Radius", 20, 500, "FOV", 0)
makeSlider(c, "Smoothing", 0.01, 1, "Speed", 2)
c = newCard(cols[1], "Fast Reload", "FastReload")
makeNote(c, "Speeds up reloading of your weapons: reload times in values, attributes and weapon config tables, and the reload animations. Only works where the reload is decided on your side.")
makeSlider(c, "Speed (x)", 2, 30, "FastReloadMult", 0)
c = newCard(cols[2], "Silent Aim", "SilentAim")
makeNote(c, "Shots go to the target while the camera stays still.")
c = newCard(cols[2], "Wall Fire", "WallFire")
makeNote(c, "Cannon shots ignore walls. Aim and Silent Aim also target through walls.")
c = newCard(cols[2], "No Recoil", "NoRecoil")
makeNote(c, "Sets the recoil of your weapons to zero (values, attributes and weapon config tables whose name contains \"recoil\").")
c = newCard(cols[3], "Targeting")
makeToggle(c, "Wall Check", "WallCheck", "Skip targets behind walls")
makeToggle(c, "Team Check", "TeamCheck", "Ignore teammates")
makeToggle(c, "Players Only", "PlayersOnly", "Ignore NPCs")
makeDropdown(c, "Aim Part", "AimPart", { "Head", "Torso", "Root" })
c = newCard(cols[3], "Hitbox", "Hitbox")
makeNote(c, "Makes the hitboxes of other players bigger (not teammates with Team Check, not excluded players). Only on your side: it helps where your own game decides what a shot hits. Root is invisible; Head also makes the head look big.")
makeSlider(c, "Size", 2, 30, "HitboxSize", 0)
makeDropdown(c, "Part", "HitboxPart", { "Root", "Head" })
makeToggle(c, "Show box", "HitboxShow", "See the enlarged hitbox")

cols = newPage("Movement")
c = newCard(cols[1], "Fly", "FlyEnabled")
makeSlider(c, "Fly Speed", 20, 80, "FlySpeed", 0)
c = newCard(cols[1], "Noclip", "Noclip")
c = newCard(cols[1], "Infinite Jump", "InfiniteJump")
makeNote(c, "Jump again in mid-air, as often as you like.")
c = newCard(cols[1], "Auto Sprint", "AutoSprint")
makeNote(c, "Holds the sprint key (Shift) for you while you move, if the game has sprint.")
c = newCard(cols[2], "Auto Grab", "AutoGrab")
makeNote(c, "When a prompt needs a special item, it is taken into your hand and your old item comes back afterwards.")
c = newCard(cols[2], "Speed", "SpeedEnabled")
makeSlider(c, "Walk Speed", 16, 350, "WalkSpeed", 0)
makeDropdown(c, "Method", "SpeedMethod", { "WalkSpeed", "CFrame" })
makeNote(c, "If the game keeps resetting your speed, use CFrame: it pushes you forward on top of the normal speed.")
c = newCard(cols[2], "FE Invisible", "Invisible")
invisBtn = makeAction(c, "FE Invisible: OFF")
c = newCard(cols[3], "Teleport Path")
pickBtn = makeAction(c, "Pick Path")
tpBtn = makeAction(c, "TP to End")
backBtn = makeAction(c, "TP Back")
makeSlider(c, "TP Step (0 = instant)", 0, 1, "TpStep", 2)

cols = newPage("Visuals")
c = newCard(cols[1], "ESP", "ESPEnabled")
makeNote(c, "Highlights players in their team color, also through walls.")
c = newCard(cols[1], "Target ESP", "TargetESP")
makeNote(c, "Card with the avatar, name and health of the player you are aiming at (Aim or Silent Aim).")
c = newCard(cols[1], "Fullbright", "Fullbright")
makeNote(c, "Removes darkness, fog and shadows.")
c = newCard(cols[1], "View Model", "ViewModel")
makeNote(c, "Moves your arms, also a first-person viewmodel inside the camera. X = right, Y = up, Z = forward (studs).")
makeSlider(c, "Left X", -3, 3, "VM_LX", 2)
makeSlider(c, "Left Y", -3, 3, "VM_LY", 2)
makeSlider(c, "Left Z", -3, 3, "VM_LZ", 2)
makeSlider(c, "Right X", -3, 3, "VM_RX", 2)
makeSlider(c, "Right Y", -3, 3, "VM_RY", 2)
makeSlider(c, "Right Z", -3, 3, "VM_RZ", 2)
do
local vmReset = makeAction(c, "Reset arms")
vmReset.Activated:Connect(function()
	for _, k in ipairs({ "VM_LX", "VM_LY", "VM_LZ", "VM_RX", "VM_RY", "VM_RZ" }) do
		setSetting(k, 0)
	end
end)
end -- (scope: keeps the main chunk under the 200-locals limit)
c = newCard(cols[2], "Player Tracers", "Tracers")
makeNote(c, "Arrows from you to other players. Turns ESP on automatically.")
makeDropdown(c, "Mode", "TracerMode", { "Straight", "Square" })
makeSlider(c, "Thickness", 1, 4, "TracerThickness", 1)
c = newCard(cols[2], "Shader", "Shader")
makeNote(c, "Sets the time of day and adds color grading, bloom, sun rays and atmosphere.")
makeDropdown(c, "Time", "TimeOfDay", { "Day", "Evening", "Night", "Morning" })
c = newCard(cols[2], "Jump Circle", "JumpCircle")
makeNote(c, "An animated glowing shape opens under you every time you jump.")
makeDropdown(c, "Shape", "JumpCircleShape", { "Circle", "Square", "Triangle" })
c = newCard(cols[3], "World Particles", "WorldParticles")
makeNote(c, "Floating glowing shapes around you, in the color of the menu theme.")
makeDropdown(c, "Shape", "ParticleShape", { "Cubes", "Circles" })
makeSlider(c, "Amount", 20, 150, "ParticleCount", 0)
c = newCard(cols[3], "Hand Shader", "HandShader")
makeNote(c, "Fire and glow on your hands and on everything you hold, in the theme color.")
makeDropdown(c, "Style", "HandStyle", { "Both", "Fire", "Glow" })
c = newCard(cols[3], "Hands XZ", "HandsXZ")
makeNote(c, "Shimmering color wave over the item you hold, in the theme color.")
makeDropdown(c, "Direction", "HandsXZMode", { "Bottom to top", "Top to bottom", "Left to right", "Right to left" })
makeSlider(c, "Speed", 0.3, 3, "HandsXZSpeed", 1)
c = newCard(cols[1], "Name Tags", "NameTags")
makeNote(c, "Name, distance and a health bar above every player.")
c = newCard(cols[1], "Zoom Unlock", "ZoomUnlock")
makeNote(c, "Lets the camera zoom out much further and zoom in closer.")
c = newCard(cols[2], "Crosshair", "Crosshair")
makeNote(c, "A crosshair in the middle of the screen, in the button theme color.")
makeDropdown(c, "Style", "CrosshairStyle", { "Cross", "Dot", "Circle", "Plus" })
makeSlider(c, "Size", 6, 40, "CrosshairSize", 0)
c = newCard(cols[2], "FOV Changer", "FovChanger")
makeNote(c, "Changes how wide the camera sees.")
makeSlider(c, "Field of view", 30, 120, "FovValue", 0)
c = newCard(cols[3], "Radar", "Radar")
makeNote(c, "A small round map: you in the middle, players around you as colored dots.")
makeSlider(c, "Range (studs)", 50, 500, "RadarRange", 0)
c = newCard(cols[3], "Module list", "ShowList")
makeNote(c, "Shows enabled modules at the top left.")

cols = newPage("Misc")
c = newCard(cols[1], "Instant Prompt", "InstantPrompt")
makeNote(c, "Proximity prompts trigger without holding.")
c = newCard(cols[2], "Health Boost")
healthBtn = makeAction(c, "Health Boost (350 HP)")

-- a text report about how the game is built, to fit the script to it
do
local function buildReport()
	local lines = {}
	local function add(t) lines[#lines + 1] = t end
	local function names(list, limit)
		local out = {}
		for i, o in ipairs(list) do
			if i > limit then out[#out + 1] = "..." break end
			out[#out + 1] = o.Name .. "(" .. o.ClassName .. ")"
		end
		return table.concat(out, ", ")
	end
	add("Place " .. game.PlaceId .. " / " .. game.Name)
	local char = player.Character
	if char then
		local rig = char:FindFirstChild("UpperTorso") and "R15" or (char:FindFirstChild("Torso") and "R6" or "other")
		add("Character " .. char.Name .. " rig=" .. rig .. " Humanoid=" .. tostring(char:FindFirstChildOfClass("Humanoid") ~= nil))
		add("Character children: " .. names(char:GetChildren(), 30))
	else
		add("Character: none")
	end
	local pack = player:FindFirstChildOfClass("Backpack")
	if pack then add("Backpack: " .. names(pack:GetChildren(), 20)) end
	local tool = char and char:FindFirstChildOfClass("Tool")
	if tool then add("Held tool " .. tool.Name .. ": " .. names(tool:GetDescendants(), 30)) end
	local cam = workspace.CurrentCamera
	if cam then add("Camera children: " .. names(cam:GetChildren(), 20)) end
	add("Workspace: " .. names(workspace:GetChildren(), 40))
	local rs = game:GetService("ReplicatedStorage")
	add("ReplicatedStorage: " .. names(rs:GetChildren(), 40))
	local remotes, modules = {}, {}
	for i, d in ipairs(rs:GetDescendants()) do
		if i > 1500 then break end
		if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
			if #remotes < 40 then remotes[#remotes + 1] = d:GetFullName():gsub("^ReplicatedStorage%.", "") end
		elseif d:IsA("ModuleScript") then
			local n = d.Name:lower()
			if #modules < 30 and (n:find("weapon") or n:find("gun") or n:find("config") or n:find("recoil") or n:find("stat")) then
				modules[#modules + 1] = d:GetFullName():gsub("^ReplicatedStorage%.", "")
			end
		end
	end
	add("Remotes: " .. table.concat(remotes, ", "))
	add("Weapon-like modules: " .. table.concat(modules, ", "))
	return table.concat(lines, "\n")
end

c = newCard(cols[2], "Game Report")
makeNote(c, "Collects how this game is built (character, weapons, camera, remotes). Copy the text and send it, so the script can be fitted to your game.")
local reportBtn = makeAction(c, "Create report")
local reportBox = makeTextBox(c, "the report appears here")
reportBox.MultiLine = true
reportBox.TextWrapped = true
reportBox.TextYAlignment = Enum.TextYAlignment.Top
reportBox.Size = UDim2.new(1, 0, 0, 110)
reportBtn.Activated:Connect(function()
	local ok, text = pcall(buildReport)
	reportBox.Text = ok and text or ("Report failed: " .. tostring(text))
	if ok and setclipboard then
		pcall(setclipboard, text)
		reportBtn.Text = "Copied to clipboard"
	else
		reportBtn.Text = "Create report"
	end
end)
end -- (scope: keeps the main chunk under the 200-locals limit)

-- errors written to the output since the script started (so they can be copied and sent)
do
local errorLog = {}
game:GetService("LogService").MessageOut:Connect(function(msg, kind)
	if kind == Enum.MessageType.MessageError or (kind == Enum.MessageType.MessageWarning and msg:sub(1, 1) == "[") then
		errorLog[#errorLog + 1] = os.date("%H:%M:%S") .. " " .. msg:sub(1, 300)
		if #errorLog > 25 then table.remove(errorLog, 1) end
	end
end)

local function buildDiagnostics()
	local lines = {}
	local function add(t) lines[#lines + 1] = t end
	local function has(name) return env[name] ~= nil end
	local function check(name, what) add((has(name) and "yes  " or "NO   ") .. name .. "  (" .. what .. ")") end
	add("-- executor functions --")
	check("hookmetamethod", "Silent Aim, Wall Fire")
	check("getnamecallmethod", "Silent Aim, Wall Fire")
	check("checkcaller", "Silent Aim, Wall Fire")
	check("hookfunction", "Anti Kick")
	check("newcclosure", "hooks")
	check("getgc", "No Recoil (memory scan)")
	check("writefile", "configs, 24 h Premium")
	check("readfile", "configs, 24 h Premium")
	check("listfiles", "configs list")
	check("makefolder", "configs")
	check("setclipboard", "copy buttons")
	check("queue_on_teleport", "Auto Execute")
	check("isnetworkowner", "projectiles")
	local okVim = pcall(function() return game:GetService("VirtualInputManager") end)
	add((okVim and "yes  " or "NO   ") .. "VirtualInputManager  (Auto Sprint, Auto Clicker)")
	local okVu = pcall(function() return game:GetService("VirtualUser") end)
	add((okVu and "yes  " or "NO   ") .. "VirtualUser  (Anti AFK)")
	add("-- character --")
	local char = player.Character
	if char then
		local rig = char:FindFirstChild("UpperTorso") and "R15" or (char:FindFirstChild("Torso") and "R6" or "other")
		add("rig " .. rig .. ", Humanoid " .. tostring(char:FindFirstChildOfClass("Humanoid") ~= nil)
			.. ", Head " .. tostring(char:FindFirstChild("Head") ~= nil)
			.. ", HumanoidRootPart " .. tostring(char:FindFirstChild("HumanoidRootPart") ~= nil))
	else
		add("no character")
	end
	add("-- switched on --")
	local on = {}
	for k, v in pairs(Settings) do
		if v == true then on[#on + 1] = k end
	end
	table.sort(on)
	add(#on > 0 and table.concat(on, ", ") or "nothing")
	add("-- last errors --")
	add(#errorLog > 0 and table.concat(errorLog, "\n") or "none")
	return table.concat(lines, "\n")
end

c = newCard(cols[2], "Diagnostics")
makeNote(c, "Checks which executor functions exist and lists the last errors. Copy the text and send it if a function does not work.")
local diagBtn = makeAction(c, "Create diagnostics")
local diagBox = makeTextBox(c, "the result appears here")
diagBox.MultiLine = true
diagBox.TextWrapped = true
diagBox.TextYAlignment = Enum.TextYAlignment.Top
diagBox.Size = UDim2.new(1, 0, 0, 110)
diagBtn.Activated:Connect(function()
	local ok, text = pcall(buildDiagnostics)
	diagBox.Text = ok and text or ("Diagnostics failed: " .. tostring(text))
	if ok and setclipboard then
		pcall(setclipboard, text)
		diagBtn.Text = "Copied to clipboard"
	else
		diagBtn.Text = "Create diagnostics"
	end
end)
end -- (scope: keeps the main chunk under the 200-locals limit)
c = newCard(cols[1], "Watermark", "Watermark")
makeNote(c, "Top bar with your name, the game, FPS, ping and players. Uses the theme color.")
c = newCard(cols[1], "Auto Execute", "AutoExecute")
makeNote(c, "Runs your script again after you teleport to another place. Paste your loadstring line or the raw link below.")
do
	local aeBox = makeTextBox(c, "loadstring(...) or raw link")
	aeBox.Text = Settings.AutoExecuteSource
	aeBox.FocusLost:Connect(function() Settings.AutoExecuteSource = aeBox.Text end)
	uiRefresh["AutoExecuteSource"] = function() aeBox.Text = Settings.AutoExecuteSource end
end
-- a grid of color circles; tapping one sets Settings[key] to the theme name
do
local function swatchGrid(card, withDefault, key, strokes)
	local grid = Instance.new("Frame")
	grid.Size = UDim2.new(1, 0, 0, 0)
	grid.AutomaticSize = Enum.AutomaticSize.Y
	grid.BackgroundTransparency = 1
	place(card, grid)
	local gl = Instance.new("UIGridLayout", grid)
	gl.CellSize = UDim2.fromOffset(26, 26)
	gl.CellPadding = UDim2.fromOffset(8, 8)
	gl.SortOrder = Enum.SortOrder.LayoutOrder

	local function swatch(order, name, c1, c2, rainbow)
		local sw = Instance.new("TextButton")
		sw.LayoutOrder = order
		sw.Text = ""
		sw.AutoButtonColor = false
		sw.BackgroundColor3 = (c2 or rainbow) and Color3.new(1, 1, 1) or c1
		sw.BorderSizePixel = 0
		sw.Parent = grid
		Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)
		if rainbow then
			local g = Instance.new("UIGradient", sw)
			local keys = {}
			for i = 0, 6 do
				keys[#keys + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 7, 0.8, 1))
			end
			g.Color = ColorSequence.new(keys)
			g.Rotation = 45
		elseif c2 then
			local g = Instance.new("UIGradient", sw)
			g.Color = ColorSequence.new(c1, c2)
			g.Rotation = 45
		end
		local stroke = Instance.new("UIStroke", sw)
		stroke.Color = Color3.new(1, 1, 1)
		stroke.Thickness = 2
		stroke.Transparency = 1
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		strokes[name] = stroke
		sw.Activated:Connect(function() setSetting(key, name) end)
	end

	local order = 0
	if withDefault then
		order += 1
		swatch(order, "Default", Color3.fromRGB(70, 70, 84)) -- (not equal to any menu color on purpose)
	end
	for _, t in ipairs(THEMES) do
		order += 1
		swatch(order, t[1], t[2], t[4], t[5])
	end
end

c = newCard(cols[3], "Button theme")
swatchGrid(c, false, "Theme", swatchStrokes)
makeNote(c, "Color of buttons, ticks, sliders and effects. 42 themes: single colors, two-color gradients and the moving Rainbow.")
c = newCard(cols[2], "Menu color")
swatchGrid(c, true, "MenuTheme", menuSwatchStrokes)
end -- (scope: keeps the main chunk under the 200-locals limit)
makeNote(c, "Color of the menu itself (panel, cards, texts). White makes a light menu.")

showPage("Combat", true)
applyTheme(Settings.Theme)
updateHud()

--// ----- search: the "Search functions" button in the header opens a full search screen -----
-- Left: found modules (all tabs; Premium ones once unlocked). Right: description and what the
-- module contains. Tap a result twice, tap the description, or tap "Open in menu" to jump to it.
do
	local function magnifier(parent, x, y, color)
		local ring = Instance.new("Frame")
		ring.Position = UDim2.fromOffset(x, y)
		ring.Size = UDim2.fromOffset(9, 9)
		ring.BackgroundTransparency = 1
		ring.BorderSizePixel = 0
		ring.Parent = parent
		Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
		local st = Instance.new("UIStroke", ring)
		st.Thickness = 1.5
		st.Color = color
		local handle = Instance.new("Frame")
		handle.AnchorPoint = Vector2.new(0.5, 0.5)
		handle.Position = UDim2.fromOffset(x + 11, y + 12)
		handle.Size = UDim2.fromOffset(5, 1.6)
		handle.Rotation = 45
		handle.BackgroundColor3 = color
		handle.BorderSizePixel = 0
		handle.Parent = parent
	end

	-- button in the header
	local openBtn = Instance.new("TextButton")
	openBtn.AnchorPoint = Vector2.new(0.5, 0)
	openBtn.Position = UDim2.new(0.5, 0, 0, 4)
	openBtn.Size = UDim2.fromOffset(160, 20)
	openBtn.BackgroundColor3 = THEME.field
	openBtn.BorderSizePixel = 0
	openBtn.AutoButtonColor = false
	openBtn.Text = "Search functions"
	openBtn.TextColor3 = THEME.sub
	openBtn.Font = Enum.Font.Gotham
	openBtn.TextSize = 12
	openBtn.TextXAlignment = Enum.TextXAlignment.Left
	openBtn.Parent = menu
	Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 10)
	Instance.new("UIPadding", openBtn).PaddingLeft = UDim.new(0, 28)
	magnifier(openBtn, 9, 4, THEME.sub)

	-- the search screen (covers everything under the header)
	local root = Instance.new("Frame")
	root.Name = "SearchScreen"
	root.Position = UDim2.fromOffset(0, 28)
	root.Size = UDim2.new(1, 0, 1, -28)
	root.BackgroundColor3 = THEME.panel
	root.BorderSizePixel = 0
	root.Visible = false
	root.ZIndex = 60
	root.Parent = menu
	Instance.new("UICorner", root).CornerRadius = UDim.new(0, 12)

	magnifier(root, 14, 14, THEME.sub)
	local box = Instance.new("TextBox")
	box.Position = UDim2.fromOffset(36, 8)
	box.Size = UDim2.new(1, -110, 0, 26)
	box.BackgroundTransparency = 1
	box.Text = ""
	box.PlaceholderText = "Search functions"
	box.PlaceholderColor3 = THEME.sub
	box.TextColor3 = THEME.text
	box.Font = Enum.Font.Gotham
	box.TextSize = 14
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.ClearTextOnFocus = false
	box.Parent = root
	local divider = Instance.new("Frame")
	divider.Position = UDim2.fromOffset(12, 40)
	divider.Size = UDim2.new(1, -24, 0, 1)
	divider.BackgroundColor3 = THEME.off
	divider.BorderSizePixel = 0
	divider.Parent = root

	-- body: results on the left, details on the right
	local body = Instance.new("Frame")
	body.Position = UDim2.fromOffset(12, 50)
	body.Size = UDim2.new(1, -24, 1, -100)
	body.BackgroundTransparency = 1
	body.Parent = root

	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(0.4, -6, 1, 0)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 3
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Parent = body
	do
		local l = Instance.new("UIListLayout", list)
		l.Padding = UDim.new(0, 4)
		l.SortOrder = Enum.SortOrder.LayoutOrder
	end

	local detail = Instance.new("Frame")
	detail.Position = UDim2.new(0.4, 6, 0, 0)
	detail.Size = UDim2.new(0.6, -6, 1, 0)
	detail.BackgroundColor3 = THEME.card
	detail.BorderSizePixel = 0
	detail.Parent = body
	Instance.new("UICorner", detail).CornerRadius = UDim.new(0, 8)

	local capDesc = mkLabel(detail, "DESCRIPTION", 10, THEME.sub, Enum.Font.GothamBold)
	capDesc.Position = UDim2.fromOffset(12, 10)
	capDesc.Size = UDim2.new(1, -24, 0, 14)
	local descLbl = mkLabel(detail, "", 12, THEME.text, Enum.Font.Gotham)
	descLbl.Position = UDim2.fromOffset(12, 28)
	descLbl.Size = UDim2.new(1, -24, 0.5, -34)
	descLbl.TextWrapped = true
	descLbl.TextYAlignment = Enum.TextYAlignment.Top
	local descBtn = Instance.new("TextButton") -- tapping the description opens the module
	descBtn.Size = UDim2.new(1, 0, 0.55, 0)
	descBtn.BackgroundTransparency = 1
	descBtn.Text = ""
	descBtn.Parent = detail

	local contFrame = Instance.new("Frame") -- lower part: what the module contains
	contFrame.Position = UDim2.fromScale(0, 0.55)
	contFrame.Size = UDim2.fromScale(1, 0.45)
	contFrame.BackgroundTransparency = 1
	contFrame.Parent = detail
	local capCont = mkLabel(contFrame, "CONTAINS", 10, THEME.sub, Enum.Font.GothamBold)
	capCont.Position = UDim2.fromOffset(12, 2)
	capCont.Size = UDim2.new(1, -24, 0, 14)
	local pills = Instance.new("ScrollingFrame")
	pills.Position = UDim2.fromOffset(12, 20)
	pills.Size = UDim2.new(1, -24, 1, -26)
	pills.BackgroundTransparency = 1
	pills.BorderSizePixel = 0
	pills.ScrollBarThickness = 2
	pills.AutomaticCanvasSize = Enum.AutomaticSize.Y
	pills.CanvasSize = UDim2.new()
	pills.Parent = contFrame
	do
		local l = Instance.new("UIListLayout", pills)
		l.Padding = UDim.new(0, 4)
		l.SortOrder = Enum.SortOrder.LayoutOrder
	end

	-- bottom bar: your avatar, a date tag and name, Hide
	local userBar = Instance.new("Frame")
	userBar.Position = UDim2.new(0, 12, 1, -44)
	userBar.Size = UDim2.new(1, -24, 0, 36)
	userBar.BackgroundColor3 = THEME.card
	userBar.BorderSizePixel = 0
	userBar.Parent = root
	Instance.new("UICorner", userBar).CornerRadius = UDim.new(0, 8)
	local avatar = Instance.new("ImageLabel")
	avatar.Position = UDim2.fromOffset(8, 4)
	avatar.Size = UDim2.fromOffset(28, 28)
	avatar.BackgroundColor3 = THEME.field
	avatar.BorderSizePixel = 0
	avatar.Parent = userBar
	Instance.new("UICorner", avatar).CornerRadius = UDim.new(0, 6)
	local tagRing = Instance.new("Frame")
	tagRing.Position = UDim2.fromOffset(44, 7)
	tagRing.Size = UDim2.fromOffset(7, 7)
	tagRing.BackgroundTransparency = 1
	tagRing.BorderSizePixel = 0
	tagRing.Parent = userBar
	Instance.new("UICorner", tagRing).CornerRadius = UDim.new(1, 0)
	do
		local st = Instance.new("UIStroke", tagRing)
		st.Thickness = 1.5
		themeBind(st, "Color", "accent")
	end
	local tag = mkLabel(userBar, os.date("%d.%m.%Y"), 9, THEME.sub, Enum.Font.GothamMedium)
	tag.Position = UDim2.fromOffset(56, 4)
	tag.Size = UDim2.new(1, -150, 0, 12)
	local userName = mkLabel(userBar, player.Name, 12, THEME.text, Enum.Font.GothamBold)
	userName.Position = UDim2.fromOffset(44, 16)
	userName.Size = UDim2.new(1, -130, 0, 16)
	userName.TextTruncate = Enum.TextTruncate.AtEnd
	local hideBtn = Instance.new("TextButton")
	hideBtn.AnchorPoint = Vector2.new(1, 0.5)
	hideBtn.Position = UDim2.new(1, -8, 0.5, 0)
	hideBtn.Size = UDim2.fromOffset(70, 24)
	hideBtn.BackgroundTransparency = 1
	hideBtn.Font = Enum.Font.GothamMedium
	hideBtn.TextSize = 12
	hideBtn.TextColor3 = THEME.sub
	hideBtn.Text = "Hide  v"
	hideBtn.Parent = userBar
	task.spawn(function()
		local ok, img = pcall(Players.GetUserThumbnailAsync, Players, player.UserId,
			Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		if ok and img then avatar.Image = img end
	end)

	local selected
	local resultBtns, pillObjs = {}, {}

	local function paintSelection()
		for _, r in ipairs(resultBtns) do
			local on = (r.info == selected)
			r.btn.BackgroundColor3 = THEME.accent
			r.btn.BackgroundTransparency = on and 0.78 or 1
		end
	end
	table.insert(themeHooks, paintSelection)

	local function showDetails(info)
		descLbl.Text = (info.desc and (info.desc .. "\n\n") or "")
			.. "Module " .. info.name .. " from the " .. tostring(info.page) .. " tab. Tap to jump to it in the menu."
		for _, o in ipairs(pillObjs) do o:Destroy() end
		table.clear(pillObjs)
		local n = 0
		for _, it in ipairs(info.items) do
			n += 1
			local pill = mkLabel(pills, it, 11, THEME.text, Enum.Font.Gotham)
			pill.Size = UDim2.new(1, -4, 0, 22)
			pill.BackgroundTransparency = 0
			pill.BackgroundColor3 = THEME.field
			pill.TextTruncate = Enum.TextTruncate.AtEnd
			pill.LayoutOrder = n
			Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 6)
			Instance.new("UIPadding", pill).PaddingLeft = UDim.new(0, 8)
			pillObjs[#pillObjs + 1] = pill
		end
		if n == 0 then
			local none = mkLabel(pills, "Only a switch", 11, THEME.sub, Enum.Font.Gotham)
			none.Size = UDim2.new(1, 0, 0, 18)
			pillObjs[#pillObjs + 1] = none
		end
	end

	local function selectResult(info)
		selected = info
		paintSelection()
		showDetails(info)
	end

	local function closeSearch()
		if not root.Visible then return end
		root.Visible = false
		box.Text = ""
		pcall(function() box:ReleaseFocus() end)
	end

	-- open the module: its tab, scrolled to its card, which flashes once
	local function goTo(info)
		closeSearch()
		showPage(info.page)
		task.delay(0.08, function()
			local col = info.card.Parent
			if col and col:IsA("ScrollingFrame") then
				local y = info.card.AbsolutePosition.Y - col.AbsolutePosition.Y + col.CanvasPosition.Y
				col.CanvasPosition = Vector2.new(0, math.max(0, y - 4))
			end
			info.card.BackgroundColor3 = THEME.accent
			TweenService:Create(info.card, TweenInfo.new(0.9), { BackgroundColor3 = THEME.card }):Play()
		end)
	end

	local function score(info, q)
		if q == "" then return 6 end -- no text yet: show everything
		local name = info.name:lower()
		if name == q then return 1 end
		if name:sub(1, #q) == q then return 2 end
		if name:find(q, 1, true) then return 3 end
		for _, it in ipairs(info.items) do
			if tostring(it):lower():find(q, 1, true) then return 4 end
		end
		if info.desc and info.desc:lower():find(q, 1, true) then return 5 end
		return nil
	end

	local function rebuild()
		local q = box.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
		for _, r in ipairs(resultBtns) do r.btn:Destroy() end
		table.clear(resultBtns)

		local found = {}
		for _, info in ipairs(moduleList) do
			-- Premium modules are searched only once the Premium tab has been unlocked
			if info.page ~= "Premium" or premiumUnlocked then
				local sc = score(info, q)
				if sc then found[#found + 1] = { info = info, sc = sc } end
			end
		end
		table.sort(found, function(a, b)
			if a.sc ~= b.sc then return a.sc < b.sc end
			return a.info.name < b.info.name
		end)

		for i, f in ipairs(found) do
			local btn = Instance.new("TextButton")
			btn.LayoutOrder = i
			btn.Size = UDim2.new(1, -4, 0, 44)
			btn.BackgroundTransparency = 1
			btn.BorderSizePixel = 0
			btn.AutoButtonColor = false
			btn.Text = ""
			btn.Parent = list
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
			local icon = Instance.new("Frame") -- small round icon, like in the picture
			icon.Position = UDim2.fromOffset(10, 15)
			icon.Size = UDim2.fromOffset(14, 14)
			icon.BackgroundTransparency = 1
			icon.BorderSizePixel = 0
			icon.Parent = btn
			Instance.new("UICorner", icon).CornerRadius = UDim.new(1, 0)
			local ist = Instance.new("UIStroke", icon)
			ist.Thickness = 2
			ist.Color = THEME.sub
			local cap = mkLabel(btn, "MODULE", 9, THEME.sub, Enum.Font.GothamBold)
			cap.Position = UDim2.fromOffset(34, 7)
			cap.Size = UDim2.new(1, -40, 0, 12)
			local name = mkLabel(btn, f.info.name, 13, THEME.text, Enum.Font.GothamBold)
			name.Position = UDim2.fromOffset(34, 20)
			name.Size = UDim2.new(1, -40, 0, 18)
			name.TextTruncate = Enum.TextTruncate.AtEnd
			resultBtns[#resultBtns + 1] = { btn = btn, name = name, info = f.info }
			btn.Activated:Connect(function()
				if selected == f.info then goTo(f.info) else selectResult(f.info) end -- second tap opens it
			end)
		end

		if #found == 0 then
			selected = nil
			descLbl.Text = "Nothing found."
			for _, o in ipairs(pillObjs) do o:Destroy() end
			table.clear(pillObjs)
		else
			selectResult(found[1].info)
		end
	end

	-- a mistake in the search must never be silent: it is written into the description
	local function safeRebuild()
		local ok, err = pcall(rebuild)
		if not ok then descLbl.Text = "Search error: " .. tostring(err) end
	end

	local function openSearch()
		root.Visible = true
		box.Text = ""
		safeRebuild()
		box:CaptureFocus()
	end

	openBtn.Activated:Connect(openSearch)
	hideBtn.Activated:Connect(closeSearch)
	descBtn.Activated:Connect(function()
		if selected then goTo(selected) end
	end)
	box:GetPropertyChangedSignal("Text"):Connect(safeRebuild)
	menu:GetPropertyChangedSignal("Visible"):Connect(function()
		if not menu.Visible then closeSearch() end
	end)

	-- changing the tab closes the search
	local baseShowPage = showPage
	showPage = function(name, instant)
		if not instant then closeSearch() end
		return baseShowPage(name, instant)
	end
end

-- Menu open/close button
do
local menuBtn = Instance.new("TextButton")
menuBtn.Size = UDim2.fromOffset(44, 44)
menuBtn.Position = UDim2.fromOffset(10, 20)
menuBtn.BackgroundColor3 = THEME.panel
menuBtn.Text = "≡"
menuBtn.TextSize = 28
menuBtn.TextColor3 = Color3.new(1, 1, 1)
menuBtn.Font = Enum.Font.GothamBold
menuBtn.BorderSizePixel = 0
menuBtn.Parent = gui
Instance.new("UICorner", menuBtn).CornerRadius = UDim.new(0, 10)
-- drag the button anywhere on the screen; a short tap opens / closes the menu
do
	local dragInput, dragStart, btnStart, moved
	menuBtn.InputBegan:Connect(function(i)
		if isPress(i) then
			dragInput, dragStart, btnStart, moved = i, i.Position, menuBtn.Position, false
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragInput and isMove(i)
			and (i == dragInput or i.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = i.Position - dragStart
			if moved or d.Magnitude > 8 then -- a real drag, not a shaky tap
				moved = true
				local vp = gui.AbsoluteSize
				local x = math.clamp(btnStart.X.Offset + d.X, 0, math.max(0, vp.X - menuBtn.AbsoluteSize.X))
				local y = math.clamp(btnStart.Y.Offset + d.Y, 0, math.max(0, vp.Y - menuBtn.AbsoluteSize.Y))
				menuBtn.Position = UDim2.fromOffset(x, y)
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i == dragInput then
			dragInput = nil
			if not moved then setMenu(not menuOpen) end
		end
	end)
end
end -- (scope: keeps the main chunk under the 200-locals limit)

-- (the fixed INVIS button was removed: on a phone, bind FE Invisible with the BTN chip on its card)

--// ===== PLAYER LIST (own tab) =====
do
local plRows = {} -- Player -> { btn, stripe }
local refreshRow
do
	local plCols = newPage("Players", true)
	local plCard, plTitle = newCard(plCols[1], "Players")
	makeNote(plCard, "Tap a player to exclude them from Aim and Silent Aim. The stripe shows their team color.")

	local function updateCount()
		local n = 0
		for _ in pairs(plRows) do n += 1 end
		plTitle.Text = "Players (" .. n .. ")"
	end

	refreshRow = function(plr)
		local r = plRows[plr]
		if not r then return end
		local ex = excluded[plr.UserId]
		r.btn.Text = (ex and "[X] " or "") .. plr.DisplayName .. " (@" .. plr.Name .. ")"
		r.btn.BackgroundColor3 = ex and Color3.fromRGB(140, 45, 45) or THEME.field
		r.stripe.BackgroundColor3 = plr.Team and plr.TeamColor.Color or Color3.new(1, 1, 1)
	end

	local function addRow(plr)
		if plr == player or plRows[plr] then return end
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 30)
		btn.Font = Enum.Font.GothamMedium
		btn.TextSize = 12
		btn.TextColor3 = THEME.text
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.TextTruncate = Enum.TextTruncate.AtEnd
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
		local pad = Instance.new("UIPadding", btn)
		pad.PaddingLeft = UDim.new(0, 16)
		pad.PaddingRight = UDim.new(0, 6)
		place(plCard, btn)

		local stripe = Instance.new("Frame") -- team color stripe on the left edge
		stripe.Size = UDim2.new(0, 5, 1, -10)
		stripe.Position = UDim2.fromOffset(-11, 5)
		stripe.BorderSizePixel = 0
		stripe.Parent = btn
		Instance.new("UICorner", stripe).CornerRadius = UDim.new(1, 0)

		plRows[plr] = { btn = btn, stripe = stripe }
		btn.Activated:Connect(function()
			excluded[plr.UserId] = not excluded[plr.UserId] or nil
			refreshRow(plr)
		end)
		plr:GetPropertyChangedSignal("Team"):Connect(function() refreshRow(plr) end)
		plr:GetPropertyChangedSignal("TeamColor"):Connect(function() refreshRow(plr) end)
		refreshRow(plr)
		updateCount()
	end

	local function removeRow(plr)
		local r = plRows[plr]
		if r then
			r.btn:Destroy()
			plRows[plr] = nil
			updateCount()
		end
	end

	Players.PlayerAdded:Connect(addRow)
	Players.PlayerRemoving:Connect(removeRow)
	for _, plr in ipairs(Players:GetPlayers()) do addRow(plr) end
	updateCount()
end

--// ===== CONFIGS (own tab: save / load / export / import) =====
-- Files go to <executor workspace>/AimAssistConfigs/<name>.json (needs writefile/readfile/listfiles).
-- Export/Import via text works even without file support.
do
	local HttpService = game:GetService("HttpService")
	local CONFIG_DIR = "AimAssistConfigs"
	local fsOK = (writefile and readfile and isfile and listfiles and makefolder and isfolder) and true or false

	local cfgCols = newPage("Configs")

	local saveCard = newCard(cfgCols[1], "Save")
	local nameBox = makeTextBox(saveCard, "config name")
	local saveBtn = makeAction(saveCard, "Save")
	local exportBtn = makeAction(saveCard, "Export (text)")
	local cfgStatus = makeNote(saveCard, fsOK and "Tap a saved config to load it." or "No file support: use Export / Import.")

	local importCard = newCard(cfgCols[2], "Import")
	local pasteBox = makeTextBox(importCard, "paste config text here")
	local importBtn = makeAction(importCard, "Import (from text)")
	makeNote(importCard, "Export fills this box with the config text, and copies it if your executor can.")

	local listCard = newCard(cfgCols[3], "Saved configs")
	local listRows = {}

	local function setMsg(text, good)
		cfgStatus.Text = text
		cfgStatus.TextColor3 = good == nil and THEME.sub
			or (good and Color3.fromRGB(90, 200, 120) or Color3.fromRGB(230, 90, 90))
	end

	local function cleanName(n)
		n = (n or ""):gsub("[^%w_%-]", "_")
		return n ~= "" and n or "default"
	end

	local function serializeConfig()
		local data = {}
		for k, v in pairs(Settings) do
			local t = type(v)
			if t == "boolean" or t == "number" or t == "string" then data[k] = v end
		end
		local ex = {}
		for id in pairs(excluded) do table.insert(ex, id) end
		data._excluded = ex
		return HttpService:JSONEncode(data)
	end

	local function applyConfig(json)
		local ok, data = pcall(HttpService.JSONDecode, HttpService, json)
		if not ok or type(data) ~= "table" then return false, "Invalid config" end

		for k, v in pairs(data) do
			-- only known settings with the same type are accepted
			if k ~= "_excluded" and k ~= "Invisible" and Settings[k] ~= nil and type(Settings[k]) == type(v)
				and not (PREMIUM_KEYS[k] and not premiumUnlocked) then
				Settings[k] = v
				if uiRefresh[k] then uiRefresh[k]() end -- redraws + clamps + applies the theme
			end
		end
		if type(data._excluded) == "table" then
			table.clear(excluded)
			for _, id in ipairs(data._excluded) do
				if type(id) == "number" then excluded[id] = true end
			end
			for plr in pairs(plRows) do refreshRow(plr) end
		end
		-- tracers need ESP
		if Settings.Tracers and not Settings.ESPEnabled then setSetting("ESPEnabled", true) end
		return true
	end

	local function pathOf(name) return CONFIG_DIR .. "/" .. name .. ".json" end

	local refreshList
	local function loadByName(name)
		local ok, content = pcall(readfile, pathOf(name))
		if not ok then setMsg("Could not read " .. name, false) return end
		local good, err = applyConfig(content)
		if good then
			nameBox.Text = name
			setMsg("Loaded: " .. name, true)
		else
			setMsg(err, false)
		end
	end

	refreshList = function()
		for _, r in ipairs(listRows) do r:Destroy() end
		table.clear(listRows)
		if not fsOK then return end
		if not isfolder(CONFIG_DIR) then pcall(makefolder, CONFIG_DIR) end
		local ok, files = pcall(listfiles, CONFIG_DIR)
		if not ok then return end

		for _, path in ipairs(files) do
			local name = tostring(path):match("([^/\\]+)%.json$")
			if name then
				local row = Instance.new("Frame")
				row.Size = UDim2.new(1, 0, 0, 28)
				row.BackgroundTransparency = 1
				place(listCard, row)
				table.insert(listRows, row)

				local load = Instance.new("TextButton")
				load.Size = UDim2.new(1, delfile and -32 or 0, 1, 0)
				load.BackgroundColor3 = THEME.field
				load.BorderSizePixel = 0
				load.Text = name
				load.TextColor3 = THEME.text
				load.Font = Enum.Font.GothamMedium
				load.TextSize = 12
				load.TextTruncate = Enum.TextTruncate.AtEnd
				load.Parent = row
				Instance.new("UICorner", load).CornerRadius = UDim.new(0, 6)
				load.Activated:Connect(function() loadByName(name) end)

				if delfile then
					local del = Instance.new("TextButton")
					del.AnchorPoint = Vector2.new(1, 0)
					del.Position = UDim2.new(1, 0, 0, 0)
					del.Size = UDim2.fromOffset(28, 28)
					del.BackgroundColor3 = Color3.fromRGB(140, 45, 45)
					del.BorderSizePixel = 0
					del.Text = "X"
					del.TextColor3 = Color3.new(1, 1, 1)
					del.Font = Enum.Font.GothamBold
					del.TextSize = 12
					del.Parent = row
					Instance.new("UICorner", del).CornerRadius = UDim.new(0, 6)
					del.Activated:Connect(function()
						pcall(delfile, pathOf(name))
						setMsg("Deleted: " .. name)
						refreshList()
					end)
				end
			end
		end
	end
	onPageShown["Configs"] = refreshList

	saveBtn.Activated:Connect(function()
		if not fsOK then setMsg("No file support: use Export", false) return end
		local name = cleanName(nameBox.Text)
		if not isfolder(CONFIG_DIR) then pcall(makefolder, CONFIG_DIR) end
		local ok = pcall(writefile, pathOf(name), serializeConfig())
		if ok then
			nameBox.Text = name
			setMsg("Saved: " .. name, true)
			refreshList()
		else
			setMsg("Save failed", false)
		end
	end)

	exportBtn.Activated:Connect(function()
		local json = serializeConfig()
		pasteBox.Text = json
		if setclipboard then
			pcall(setclipboard, json)
			setMsg("Exported + copied to clipboard", true)
		else
			setMsg("Exported: copy the text from the box", true)
		end
	end)

	importBtn.Activated:Connect(function()
		local good, err = applyConfig(pasteBox.Text)
		setMsg(good and "Imported config" or err, good and true or false)
	end)
end
end -- (scope: keeps the main chunk under the 200-locals limit)

--// ===== NOCLIP =====
do
local noclipParts, noclipChar, noclipAt = {}, nil, 0
RunService.Stepped:Connect(function()
	if not Settings.Noclip then return end
	local char = player.Character
	if not char then return end
	-- rebuild the part list only when the character changes or once per second
	local now = os.clock()
	if char ~= noclipChar or now - noclipAt > 1 then
		noclipChar, noclipAt = char, now
		table.clear(noclipParts)
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then table.insert(noclipParts, part) end
		end
	end
	for i = 1, #noclipParts do
		local part = noclipParts[i]
		if part.CanCollide then part.CanCollide = false end
	end
end)
end -- (scope: keeps the main chunk under the 200-locals limit)

--// ===== WALK SPEED =====
-- Method "WalkSpeed": the value is written right before the physics step (after the game's own
--   scripts), and written back at once when the game changes it.
-- Method "CFrame": WalkSpeed is left alone; you are pushed forward on top of the normal speed,
--   so it also works when the game forces WalkSpeed every frame.
do
	local originalSpeed = {}   -- humanoid -> WalkSpeed before we touched it
	local guarded = setmetatable({}, { __mode = "k" })
	local activeHum
	local fixes = 0            -- corrections this frame (stops two scripts fighting forever)

	local function guard(hum)
		if guarded[hum] then return end
		guarded[hum] = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			if Settings.SpeedEnabled and Settings.SpeedMethod ~= "CFrame"
				and hum.WalkSpeed ~= Settings.WalkSpeed and fixes < 3 then
				fixes += 1
				hum.WalkSpeed = Settings.WalkSpeed
			end
		end)
	end

	RunService.Stepped:Connect(function()
		fixes = 0
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and Settings.SpeedEnabled and Settings.SpeedMethod ~= "CFrame" then
			if originalSpeed[hum] == nil then originalSpeed[hum] = hum.WalkSpeed end
			guard(hum)
			if hum.WalkSpeed ~= Settings.WalkSpeed then hum.WalkSpeed = Settings.WalkSpeed end
			activeHum = hum
		elseif activeHum then -- switched off or changed to CFrame: give the old speed back
			if activeHum.Parent and originalSpeed[activeHum] then activeHum.WalkSpeed = originalSpeed[activeHum] end
			originalSpeed[activeHum] = nil
			activeHum = nil
		end
	end)

	RunService.Heartbeat:Connect(function(dt)
		if not (Settings.SpeedEnabled and Settings.SpeedMethod == "CFrame") then return end
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if hum and root and hum.Health > 0 and hum.MoveDirection.Magnitude > 0 then
			local extra = math.max(0, Settings.WalkSpeed - hum.WalkSpeed)
			root.CFrame = root.CFrame + hum.MoveDirection * extra * dt
		end
	end)
end

--// ===== INSTANT PROXIMITY PROMPT =====
do
local originalHold = setmetatable({}, { __mode = "k" }) -- prompt -> original HoldDuration

local function applyPrompt(prompt)
	if not prompt:IsA("ProximityPrompt") then return end
	if originalHold[prompt] == nil then
		originalHold[prompt] = prompt.HoldDuration
	end
	prompt.HoldDuration = 0
end

local promptsWereInstant = false
task.spawn(function()
	while true do
		if Settings.InstantPrompt then
			if not promptsWereInstant then
				-- one full scan when switched on; new prompts are handled by DescendantAdded
				promptsWereInstant = true
				local n = 0
				for _, obj in ipairs(workspace:GetDescendants()) do
					if obj:IsA("ProximityPrompt") and obj.HoldDuration ~= 0 then
						applyPrompt(obj)
					end
					n += 1
					if n % 500 == 0 then task.wait() end
				end
			end
		elseif promptsWereInstant then
			promptsWereInstant = false
			for prompt, original in pairs(originalHold) do
				if prompt.Parent then
					prompt.HoldDuration = original
				end
			end
			table.clear(originalHold)
		end
		task.wait(0.5)
	end
end)

workspace.DescendantAdded:Connect(function(obj)
	if Settings.InstantPrompt and obj:IsA("ProximityPrompt") then
		applyPrompt(obj)
	end
end)
end -- (scope: keeps the main chunk under the 200-locals limit)

--// ===== FLY =====
do
local flyVelocity
local function stopFly()
	if flyVelocity then
		flyVelocity:Destroy()
		flyVelocity = nil
	end
end

RunService.RenderStepped:Connect(function()
	if not (Settings.FlyEnabled or Settings.FlyPlus) then
		if flyVelocity then stopFly() end
		return
	end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera

	if not (hum and root and camera) then
		stopFly()
		return
	end

	if not flyVelocity or flyVelocity.Parent ~= root then
		stopFly()
		flyVelocity = Instance.new("BodyVelocity")
		flyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
		flyVelocity.Velocity = Vector3.zero
		flyVelocity.Parent = root
	end

	-- Joystick / WASD, converted to camera-relative so looking up = flying up
	local rel = camera.CFrame:VectorToObjectSpace(hum.MoveDirection)
	local dir = camera.CFrame.LookVector * (-rel.Z) + camera.CFrame.RightVector * rel.X

	-- Optional vertical keys on PC
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
		dir += Vector3.yAxis
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		dir -= Vector3.yAxis
	end

	flyVelocity.Velocity = dir.Magnitude > 0.01 and dir.Unit * (Settings.FlyPlus and Settings.FlyPlusSpeed or Settings.FlySpeed) or Vector3.zero
end)
end -- (scope: keeps the main chunk under the 200-locals limit)

--// ===== TPEND (teleport to the end of the selected path, and back) =====
local pathContainer      -- Model/Folder that holds the path parts
local picking = false
local teleporting = false
local returnCFrame       -- where you were before tpend

local function flash(btn, text, resetText)
	btn.Text = text
	task.delay(1.5, function()
		if btn.Parent then btn.Text = resetText end
	end)
end

-- Path parts in order: trailing number in the name (Part1, Part2...), else child order
local function sortedParts(container)
	local parts = {}
	for _, v in ipairs(container:GetChildren()) do
		if v:IsA("BasePart") then table.insert(parts, v) end
	end
	if #parts == 0 then
		for _, v in ipairs(container:GetDescendants()) do
			if v:IsA("BasePart") then table.insert(parts, v) end
		end
	end
	local idx = {}
	for i, p in ipairs(parts) do idx[p] = i end
	table.sort(parts, function(a, b)
		local na = tonumber(a.Name:match("%d+$"))
		local nb = tonumber(b.Name:match("%d+$"))
		if na and nb and na ~= nb then return na < nb end
		return idx[a] < idx[b]
	end)
	return parts
end

local function getRoot()
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

do
local function tpend(container, step)
	if teleporting or not container then return false end
	local root = getRoot()
	if not root then return false end

	local parts = sortedParts(container)
	if #parts == 0 then return false end

	teleporting = true
	returnCFrame = root.CFrame -- remember where we came from

	step = step or Settings.TpStep
	if step <= 0 then
		root.CFrame = parts[#parts].CFrame + Vector3.new(0, 4, 0)
	else
		for _, p in ipairs(parts) do
			if not (root and root.Parent) then break end
			root.CFrame = p.CFrame + Vector3.new(0, 4, 0)
			root.AssemblyLinearVelocity = Vector3.zero
			task.wait(step)
		end
	end
	teleporting = false
	return true
end

local function tpback()
	if teleporting or not returnCFrame then return false end
	local root = getRoot()
	if not root then return false end
	root.CFrame = returnCFrame
	root.AssemblyLinearVelocity = Vector3.zero
	return true
end

pickBtn.Activated:Connect(function()
	picking = not picking
	pickBtn.Text = picking and "Tap a part of the path..." or (pathContainer and ("Path: " .. pathContainer.Name) or "Pick Path")
end)

tpBtn.Activated:Connect(function()
	if not pathContainer then
		flash(tpBtn, "Pick a path first", "TP to End")
		return
	end
	task.spawn(tpend, pathContainer, Settings.TpStep)
end)

backBtn.Activated:Connect(function()
	if not tpback() then
		flash(backBtn, "Nothing to go back to", "TP Back")
	end
end)
end -- (scope: keeps the main chunk under the 200-locals limit)

-- Tap/click a part in the world to select its parent as the path
UserInputService.InputBegan:Connect(function(i, processed)
	if not picking or processed or not isPress(i) then return end
	local camera = workspace.CurrentCamera
	if not camera then return end

	local pos = (i.UserInputType == Enum.UserInputType.Touch) and i.Position
		or UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(pos.X, pos.Y)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)

	if result and result.Instance.Parent and result.Instance.Parent ~= workspace then
		pathContainer = result.Instance.Parent
		picking = false
		pickBtn.Text = "Path: " .. pathContainer.Name
	end
end)

--// ===== HEALTH BOOST (sets your max health and health to 350) =====
do
local function healthboost(amount)
	amount = amount or Settings.BoostHP
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end
	hum.MaxHealth = amount
	hum.Health = amount
	return true
end

healthBtn.Activated:Connect(function()
	if healthboost() then
		flash(healthBtn, "Health set to " .. Settings.BoostHP, "Health Boost (350 HP)")
	else
		flash(healthBtn, "No character", "Health Boost (350 HP)")
	end
end)
end -- (scope: keeps the main chunk under the 200-locals limit)

--// ===== FE INVISIBLE (ghost method) =====
-- 1. Your real character is cloned. The clone (local only) becomes your controlled character.
-- 2. The real character is parked far above the map (and anchored on your side), so the SERVER
--    and every other player see your body up there, not where you are.
-- 3. Because the server only knows the parked body, you are also not hittable while invisible.
-- Proximity prompts: while a prompt is on screen the real body is brought to the clone's spot
-- (so the server's distance check passes) and parked again shortly after the prompt is gone.
-- Respawning ends it. Some games detect/kick for this.
local INVIS_FAR_CF = CFrame.new(0, 5e5, 0)
local invisReal, invisClone
local invisPark = INVIS_FAR_CF -- where the real body is parked right now
local invisShift = nil         -- studs above you to park it (God Mode); nil = far away (FE Invisible)
local invisBusy = false
local invisWanted = false     -- what you asked for (stays ON while briefly revealed for a prompt)
local invisRevealed = false   -- real body currently brought to the clone's position
local invisSwapAt = 0         -- os.clock() of last Player.Character swap

local function refreshInvisBtn()
	local on = invisWanted and not Settings.GodMode -- God Mode uses the same mechanism but has its own switch
	invisBtn.Text = "FE Invisible: " .. (on and "ON" or "OFF")
	invisBtn.BackgroundColor3 = on and Color3.fromRGB(40, 140, 70) or THEME.accent
	if Settings.Invisible ~= on then -- keep the bindable toggle in step with the real state
		Settings.Invisible = on
		if uiRefresh.Invisible then uiRefresh.Invisible() end
	end
end

table.insert(themeHooks, refreshInvisBtn)

local function setCameraTo(char)
	local cam = workspace.CurrentCamera
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if cam and hum then cam.CameraSubject = hum end
end

local function enableInvisible()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and root and hum.Health > 0) then return false, "No character" end

	char.Archivable = true
	local clone = char:Clone()
	if not clone then return false, "Clone failed" end
	local cloneHum = clone:FindFirstChildOfClass("Humanoid")
	local cloneRoot = clone:FindFirstChild("HumanoidRootPart")
	if not (cloneHum and cloneRoot) then
		clone:Destroy()
		return false, "Clone incomplete"
	end

	local saved = root.CFrame
	clone.Parent = workspace
	clone:PivotTo(saved)
	invisReal, invisClone = char, clone

	-- park the real body far away; wait so the position reaches the server
	root.AssemblyLinearVelocity = Vector3.zero
	invisPark = invisShift and (saved + Vector3.new(0, invisShift, 0)) or INVIS_FAR_CF
	char:PivotTo(invisPark)
	task.wait(0.25)
	root.Anchored = true -- keeps it from falling on your side

	-- hand control to the clone
	invisSwapAt = os.clock()
	player.Character = clone
	setCameraTo(clone)
	invisRevealed = false
	return true
end

local function disableInvisible()
	local real, clone = invisReal, invisClone
	if not real then return end
	local realRoot = real:FindFirstChild("HumanoidRootPart")
	local cloneRoot = clone and clone:FindFirstChild("HumanoidRootPart")

	if realRoot then
		realRoot.Anchored = false
		realRoot.AssemblyLinearVelocity = Vector3.zero
		if cloneRoot then real:PivotTo(cloneRoot.CFrame) end
	end
	invisSwapAt = os.clock()
	player.Character = real
	setCameraTo(real)
	if clone then clone:Destroy() end
	invisReal, invisClone = nil, nil
	invisRevealed = false
end

-- bring the real body to the clone's position (for prompts)
local function revealReal()
	if not (invisReal and invisClone) or invisRevealed then return end
	local realRoot = invisReal:FindFirstChild("HumanoidRootPart")
	local cloneRoot = invisClone:FindFirstChild("HumanoidRootPart")
	if not (realRoot and cloneRoot) then return end
	for _, d in ipairs(invisReal:GetDescendants()) do
		if d:IsA("BasePart") then d.CanCollide = false end -- don't push the clone
	end
	realRoot.Anchored = false
	realRoot.AssemblyLinearVelocity = Vector3.zero
	invisReal:PivotTo(cloneRoot.CFrame)
	invisRevealed = true
end

local function hideReal()
	if not (invisReal and invisRevealed) then return end
	local real = invisReal
	local realRoot = real:FindFirstChild("HumanoidRootPart")
	if not realRoot then return end
	realRoot.AssemblyLinearVelocity = Vector3.zero
	real:PivotTo(invisPark)
	invisRevealed = false
	task.wait(0.25)
	if invisReal == real then realRoot.Anchored = true end
end

local function setInvisible(on)
	if invisBusy then return end
	invisBusy = true
	if on and not invisReal then
		local ok, msg = enableInvisible()
		if not ok then flash(invisBtn, msg or "Failed", "FE Invisible: OFF") end
	elseif not on and invisReal then
		disableInvisible()
	end
	invisBusy = false
end

do
local function toggleInvis()
	if Settings.GodMode then -- God Mode is using the ghost: this button just ends it
		setSetting("GodMode", false)
		return
	end
	invisBtn.Text = "Working..."
	local ok, err = pcall(setInvisible, not invisWanted)
	if not ok then
		invisBusy = false
		warn("[FE Invisible] " .. tostring(err))
		invisBtn.Text = "Error: " .. tostring(err):sub(1, 40)
		return
	end
	invisWanted = invisReal ~= nil
	refreshInvisBtn()
end

invisBtn.Activated:Connect(toggleInvis)
onToggle.Invisible = function(v) -- the card's toggle / a keyboard or on-screen bind
	local on = invisWanted and not Settings.GodMode
	if v ~= on then toggleInvis() end
end
end -- (scope: keeps the main chunk under the 200-locals limit)

-- Prompts: reveal the real body while any prompt is shown, park it again after they are gone
do
local ProximityPromptService = game:GetService("ProximityPromptService")
local shownPrompts = {}
local hideToken = 0

local function onPromptActive(prompt)
	if not invisReal then return end
	shownPrompts[prompt] = true
	hideToken += 1 -- cancel a pending hide
	revealReal()
end

local function onPromptGone(prompt)
	shownPrompts[prompt] = nil
	if next(shownPrompts) ~= nil then return end
	hideToken += 1
	local mine = hideToken
	task.delay(0.8, function()
		if mine == hideToken and invisReal and invisRevealed and next(shownPrompts) == nil then
			pcall(hideReal)
		end
	end)
end

ProximityPromptService.PromptShown:Connect(function(prompt) onPromptActive(prompt) end)
ProximityPromptService.PromptHidden:Connect(function(prompt) onPromptGone(prompt) end)
ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, who)
	if who == player then onPromptActive(prompt) end
end)

-- a real respawn = new character: the effect is over
player.CharacterAdded:Connect(function()
	if os.clock() - invisSwapAt < 1 then return end -- that was our own swap
	if invisClone then invisClone:Destroy() end
	invisReal, invisClone = nil, nil
	invisRevealed = false
	invisWanted = false
	invisBusy = false
	table.clear(shownPrompts)
	invisShift = nil
	if Settings.GodMode then
		Settings.GodMode = false
		if uiRefresh.GodMode then uiRefresh.GodMode() end
	end
	refreshInvisBtn()
end)
end -- (scope: keeps the main chunk under the 200-locals limit)

--// ===== FULLBRIGHT =====
local Lighting = game:GetService("Lighting")
do
local FB_VALUES = {
	Brightness = 2,
	ClockTime = 14,
	FogEnd = 1e6,
	GlobalShadows = false,
	Ambient = Color3.new(1, 1, 1),
	OutdoorAmbient = Color3.new(1, 1, 1),
}
local fbSaved -- original lighting while fullbright is on

RunService.Heartbeat:Connect(function()
	if Settings.Fullbright then
		if not fbSaved then
			fbSaved = { atmos = {} }
			for k in pairs(FB_VALUES) do fbSaved[k] = Lighting[k] end
			for _, child in ipairs(Lighting:GetChildren()) do
				if child:IsA("Atmosphere") then fbSaved.atmos[child] = child.Density end
			end
		end
		-- the game may change lighting again (day/night), so only rewrite what differs
		for k, v in pairs(FB_VALUES) do
			if Lighting[k] ~= v then Lighting[k] = v end
		end
		for atmos in pairs(fbSaved.atmos) do
			if atmos.Parent and atmos.Density ~= 0 then atmos.Density = 0 end
		end
	elseif fbSaved then
		for k in pairs(FB_VALUES) do
			pcall(function() Lighting[k] = fbSaved[k] end)
		end
		for atmos, density in pairs(fbSaved.atmos) do
			if atmos.Parent then atmos.Density = density end
		end
		fbSaved = nil
	end
end)

--// ===== SHADER + SHADERS+ (time of day, seasons, space scenes) =====
-- Shader: Day / Evening / Night / Morning. Shaders+ (Premium) adds Sunset, Sunrise, Winter (snow),
-- Autumn (falling leaves), Space, Milky Way, Black Hole and Galaxy (a sky of glowing parts).
-- The time changes smoothly and a color grading / bloom / sun rays / atmosphere look is blended in.
-- Switching off restores the original lighting. Shader, Shaders+ and Fullbright exclude each other.
do
	local function others(me)
		for _, k in ipairs({ "Shader", "ShaderPlus", "Fullbright" }) do
			if k ~= me and Settings[k] then setSetting(k, false) end
		end
	end
	onToggle["Shader"] = function(on) if on then others("Shader") end end
	onToggle["ShaderPlus"] = function(on) if on then others("ShaderPlus") end end
	onToggle["Fullbright"] = function(on) if on then others("Fullbright") end end

	local C = Color3.fromRGB
	local PRESETS = {
		Day = {
			clock = 14,
			light = { Brightness = 3, ExposureCompensation = 0.15, Ambient = C(110, 115, 125),
				OutdoorAmbient = C(135, 145, 160), ColorShift_Top = C(255, 244, 225) },
			cc = { Brightness = 0.02, Contrast = 0.1, Saturation = 0.2, TintColor = C(255, 250, 242) },
			bloom = { Intensity = 0.35, Size = 28, Threshold = 0.95 },
			rays = { Intensity = 0.1, Spread = 0.8 },
			atmo = { Density = 0.28, Offset = 0.2, Color = C(190, 210, 240), Decay = C(105, 135, 185), Glare = 0.15, Haze = 1 },
		},
		Evening = {
			clock = 18.1,
			light = { Brightness = 2.2, ExposureCompensation = 0.1, Ambient = C(105, 80, 95),
				OutdoorAmbient = C(150, 105, 105), ColorShift_Top = C(255, 170, 110) },
			cc = { Brightness = 0, Contrast = 0.14, Saturation = 0.3, TintColor = C(255, 210, 175) },
			bloom = { Intensity = 0.7, Size = 34, Threshold = 0.85 },
			rays = { Intensity = 0.28, Spread = 0.9 },
			atmo = { Density = 0.35, Offset = 0.3, Color = C(255, 185, 135), Decay = C(255, 110, 70), Glare = 0.45, Haze = 2.2 },
		},
		Night = {
			clock = 0,
			light = { Brightness = 1.2, ExposureCompensation = 0.25, Ambient = C(45, 55, 100),
				OutdoorAmbient = C(55, 70, 125), ColorShift_Top = C(110, 130, 255) },
			cc = { Brightness = 0, Contrast = 0.2, Saturation = 0.1, TintColor = C(175, 195, 255) },
			bloom = { Intensity = 0.6, Size = 36, Threshold = 0.8 },
			rays = { Intensity = 0, Spread = 0.8 },
			atmo = { Density = 0.3, Offset = 0, Color = C(55, 75, 140), Decay = C(25, 35, 80), Glare = 0, Haze = 1.5 },
		},
		Morning = {
			clock = 6.4,
			light = { Brightness = 2.3, ExposureCompensation = 0.1, Ambient = C(120, 105, 115),
				OutdoorAmbient = C(155, 130, 135), ColorShift_Top = C(255, 205, 165) },
			cc = { Brightness = 0.01, Contrast = 0.08, Saturation = 0.22, TintColor = C(255, 228, 212) },
			bloom = { Intensity = 0.45, Size = 30, Threshold = 0.9 },
			rays = { Intensity = 0.22, Spread = 0.85 },
			atmo = { Density = 0.32, Offset = 0.25, Color = C(255, 220, 200), Decay = C(255, 165, 135), Glare = 0.3, Haze = 1.8 },
		},
		Sunset = {
			clock = 18.5,
			light = { Brightness = 2, ExposureCompensation = 0.1, Ambient = C(110, 70, 85),
				OutdoorAmbient = C(170, 100, 95), ColorShift_Top = C(255, 130, 80) },
			cc = { Brightness = 0, Contrast = 0.16, Saturation = 0.35, TintColor = C(255, 175, 145) },
			bloom = { Intensity = 0.9, Size = 36, Threshold = 0.8 },
			rays = { Intensity = 0.35, Spread = 0.95 },
			atmo = { Density = 0.36, Offset = 0.35, Color = C(255, 140, 90), Decay = C(200, 60, 50), Glare = 0.6, Haze = 2.6 },
		},
		Sunrise = {
			clock = 5.9,
			light = { Brightness = 1.8, ExposureCompensation = 0.1, Ambient = C(95, 85, 120),
				OutdoorAmbient = C(140, 115, 145), ColorShift_Top = C(255, 170, 160) },
			cc = { Brightness = 0, Contrast = 0.12, Saturation = 0.3, TintColor = C(255, 205, 225) },
			bloom = { Intensity = 0.7, Size = 34, Threshold = 0.85 },
			rays = { Intensity = 0.3, Spread = 0.9 },
			atmo = { Density = 0.34, Offset = 0.3, Color = C(255, 180, 190), Decay = C(200, 120, 170), Glare = 0.5, Haze = 2 },
		},
		Winter = {
			clock = 12,
			light = { Brightness = 2.4, ExposureCompensation = 0.1, Ambient = C(150, 165, 190),
				OutdoorAmbient = C(170, 185, 210), ColorShift_Top = C(225, 240, 255) },
			cc = { Brightness = 0.03, Contrast = 0.12, Saturation = -0.15, TintColor = C(215, 230, 255) },
			bloom = { Intensity = 0.5, Size = 30, Threshold = 0.9 },
			rays = { Intensity = 0.12, Spread = 0.8 },
			atmo = { Density = 0.38, Offset = 0.1, Color = C(210, 225, 245), Decay = C(170, 190, 220), Glare = 0, Haze = 2.2 },
			extra = "Snow",
		},
		["Winter Evening"] = {
			clock = 17.8,
			light = { Brightness = 1.9, ExposureCompensation = 0.1, Ambient = C(110, 100, 130),
				OutdoorAmbient = C(150, 130, 155), ColorShift_Top = C(255, 190, 170) },
			cc = { Brightness = 0, Contrast = 0.14, Saturation = -0.05, TintColor = C(255, 215, 225) },
			bloom = { Intensity = 0.7, Size = 34, Threshold = 0.85 },
			rays = { Intensity = 0.25, Spread = 0.9 },
			atmo = { Density = 0.4, Offset = 0.2, Color = C(230, 190, 205), Decay = C(180, 130, 160), Glare = 0.3, Haze = 2.4 },
			extra = "Snow",
		},
		["Winter Night"] = {
			clock = 0,
			light = { Brightness = 1.2, ExposureCompensation = 0.25, Ambient = C(55, 70, 120),
				OutdoorAmbient = C(70, 90, 150), ColorShift_Top = C(150, 180, 255) },
			cc = { Brightness = 0, Contrast = 0.2, Saturation = -0.05, TintColor = C(185, 205, 255) },
			bloom = { Intensity = 0.8, Size = 36, Threshold = 0.78 },
			rays = { Intensity = 0, Spread = 0.8 },
			atmo = { Density = 0.36, Offset = 0, Color = C(90, 115, 170), Decay = C(50, 70, 120), Glare = 0, Haze = 2 },
			extra = "Snow",
		},
		Autumn = {
			clock = 16.5,
			light = { Brightness = 2.4, ExposureCompensation = 0.1, Ambient = C(130, 95, 70),
				OutdoorAmbient = C(165, 120, 85), ColorShift_Top = C(255, 190, 120) },
			cc = { Brightness = 0.01, Contrast = 0.12, Saturation = 0.35, TintColor = C(255, 205, 160) },
			bloom = { Intensity = 0.5, Size = 30, Threshold = 0.9 },
			rays = { Intensity = 0.2, Spread = 0.85 },
			atmo = { Density = 0.3, Offset = 0.25, Color = C(235, 175, 120), Decay = C(190, 110, 60), Glare = 0.2, Haze = 1.6 },
			extra = "Leaves",
		},
		Space = {
			clock = 0,
			light = { Brightness = 1.4, ExposureCompensation = 0.3, Ambient = C(35, 35, 80),
				OutdoorAmbient = C(45, 50, 110), ColorShift_Top = C(120, 120, 255) },
			cc = { Brightness = 0, Contrast = 0.2, Saturation = 0.25, TintColor = C(190, 200, 255) },
			bloom = { Intensity = 0.9, Size = 40, Threshold = 0.75 },
			rays = { Intensity = 0, Spread = 0.8 },
			atmo = { Density = 0, Offset = 0, Color = C(60, 60, 120), Decay = C(20, 20, 60), Glare = 0, Haze = 0 },
			extra = "Space",
		},
		["Milky Way"] = {
			clock = 0,
			light = { Brightness = 1.3, ExposureCompensation = 0.3, Ambient = C(40, 30, 85),
				OutdoorAmbient = C(55, 45, 120), ColorShift_Top = C(170, 130, 255) },
			cc = { Brightness = 0, Contrast = 0.2, Saturation = 0.3, TintColor = C(205, 185, 255) },
			bloom = { Intensity = 1, Size = 40, Threshold = 0.75 },
			rays = { Intensity = 0, Spread = 0.8 },
			atmo = { Density = 0, Offset = 0, Color = C(70, 50, 130), Decay = C(30, 20, 70), Glare = 0, Haze = 0 },
			extra = "MilkyWay",
		},
		["Black Hole"] = {
			clock = 0,
			light = { Brightness = 1.3, ExposureCompensation = 0.3, Ambient = C(45, 30, 40),
				OutdoorAmbient = C(70, 45, 50), ColorShift_Top = C(255, 160, 100) },
			cc = { Brightness = 0, Contrast = 0.3, Saturation = 0.1, TintColor = C(255, 200, 170) },
			bloom = { Intensity = 1.1, Size = 44, Threshold = 0.7 },
			rays = { Intensity = 0, Spread = 0.8 },
			atmo = { Density = 0, Offset = 0, Color = C(80, 40, 30), Decay = C(40, 15, 10), Glare = 0, Haze = 0 },
			extra = "BlackHole",
		},
		Galaxy = {
			clock = 0,
			light = { Brightness = 1.3, ExposureCompensation = 0.3, Ambient = C(50, 35, 95),
				OutdoorAmbient = C(65, 50, 130), ColorShift_Top = C(200, 140, 255) },
			cc = { Brightness = 0, Contrast = 0.2, Saturation = 0.3, TintColor = C(220, 190, 255) },
			bloom = { Intensity = 1, Size = 40, Threshold = 0.75 },
			rays = { Intensity = 0, Spread = 0.8 },
			atmo = { Density = 0, Offset = 0, Color = C(80, 55, 140), Decay = C(35, 25, 80), Glare = 0, Haze = 0 },
			extra = "Galaxy",
		},
	}
	for _, pr in pairs(PRESETS) do pr.light.FogEnd = 1e5 end -- no game fog over the sky
	local LIGHT_KEYS = { "ClockTime", "Brightness", "ExposureCompensation", "Ambient", "OutdoorAmbient", "ColorShift_Top", "FogEnd" }

	--// ----- extras: snow / leaves / a sky made of glowing parts -----
	local DIST = 2300 -- how far away the sky objects are
	local SKY_PROPS = { "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp",
		"StarCount", "CelestialBodiesShown" }
	local skyObj, skySaved, skyOwn

	-- space scenes: blank the sky box (black) and show many stars
	local function skyOn()
		if skyObj then return end
		skyObj = Lighting:FindFirstChildOfClass("Sky")
		if skyObj then
			skySaved = {}
			for _, k in ipairs(SKY_PROPS) do skySaved[k] = skyObj[k] end
			skyOwn = false
		else
			skyObj = Instance.new("Sky")
			skyObj.Name = "AA_Shader_Sky"
			skyObj.Parent = Lighting
			skyOwn = true
		end
		for _, k in ipairs({ "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp" }) do
			skyObj[k] = ""
		end
		skyObj.StarCount = 4000
		skyObj.CelestialBodiesShown = false
	end
	local function skyOff()
		if not skyObj then return end
		if skyOwn then
			skyObj:Destroy()
		elseif skyObj.Parent and skySaved then
			for k, v in pairs(skySaved) do pcall(function() skyObj[k] = v end) end
		end
		skyObj, skySaved, skyOwn = nil, nil, false
	end

	local extraFolder, extraKind, weatherPart, rig
	local rigAt, rigCenter = 0, Vector3.zero

	local function clearExtra()
		if extraFolder then extraFolder:Destroy() end
		extraFolder, weatherPart, rig, extraKind = nil, nil, nil, nil
		skyOff()
	end

	-- one glowing ball
	local function body(parent, pos, size, color, transparency)
		local p = Instance.new("Part")
		p.Shape = Enum.PartType.Ball
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Massless = true
		p.Material = Enum.Material.Neon
		p.Color = color
		p.Transparency = transparency or 0
		p.Size = Vector3.new(size, size, size)
		p.Position = pos
		p.Parent = parent
		return p
	end

	local function randDir(rng)
		local v = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1))
		if v.Magnitude < 0.1 then v = Vector3.yAxis end
		return v.Unit
	end

	local function backgroundStars(model, rng, n)
		for _ = 1, n do
			body(model, randDir(rng) * DIST, rng:NextNumber(2, 7),
				Color3.fromHSV(rng:NextNumber(0.5, 0.68), rng:NextNumber(0, 0.5), 1), 0.05)
		end
	end

	local BUILDERS = {}

	BUILDERS.Space = function(model, rng)
		backgroundStars(model, rng, 200)
		local pdir = Vector3.new(0.55, 0.3, -0.78).Unit
		body(model, pdir * DIST, 560, C(130, 190, 255), 0.9)      -- atmosphere glow
		body(model, pdir * DIST, 520, C(25, 55, 140), 0)          -- planet
		body(model, Vector3.new(-0.6, 0.5, -0.62).Unit * DIST, 90, C(200, 200, 210), 0.1) -- moon
	end

	BUILDERS.MilkyWay = function(model, rng)
		backgroundStars(model, rng, 120)
		local n = Vector3.new(0.35, 0.8, 0.45).Unit            -- the band is a great circle around n
		local u = n:Cross(Vector3.yAxis).Unit
		local v = n:Cross(u)
		for _ = 1, 340 do
			local th = rng:NextNumber(0, math.pi * 2)
			local lat = (rng:NextNumber() + rng:NextNumber() + rng:NextNumber() - 1.5) * 0.3
			local dir = (u * math.cos(th) + v * math.sin(th)) * math.cos(lat) + n * math.sin(lat)
			local core = 1 - math.min(1, math.abs(lat) / 0.45)    -- brighter and bigger in the middle
			body(model, dir.Unit * DIST, rng:NextNumber(1.5, 4) * (1 + core * 1.4),
				Color3.fromHSV(rng:NextNumber(0.55, 0.8), rng:NextNumber(0, 0.45), 1), 0.05)
		end
		local blobColors = { C(150, 90, 255), C(80, 120, 255), C(255, 110, 190) }
		for i = 1, 9 do                                          -- soft nebula clouds along the band
			local th = (i / 9) * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
			local dir = (u * math.cos(th) + v * math.sin(th)).Unit
			body(model, dir * DIST, rng:NextNumber(700, 1100), blobColors[(i % 3) + 1], rng:NextNumber(0.93, 0.96))
		end
	end

	BUILDERS.Galaxy = function(model, rng)
		backgroundStars(model, rng, 100)
		local center = Vector3.new(0.25, 0.65, -0.72).Unit * DIST
		local tilt = CFrame.Angles(math.rad(60), math.rad(20), 0)
		for arm = 0, 1 do                                         -- two spiral arms
			for i = 1, 150 do
				local t = i / 150
				local r = 140 + t * 960
				local th = arm * math.pi + t * 3.4 * math.pi + rng:NextNumber(-0.18, 0.18)
				local off = Vector3.new(r * math.cos(th), rng:NextNumber(-1, 1) * 40 * (1 - t), r * math.sin(th))
				off = off + Vector3.new(rng:NextNumber(-25, 25), 0, rng:NextNumber(-25, 25))
				local col = Color3.fromHSV(0.12 + t * 0.55, 0.45 + t * 0.4, 1) -- yellow core -> blue / violet rim
				body(model, center + tilt:VectorToWorldSpace(off), rng:NextNumber(5, 14) * (1.3 - t * 0.6), col, 0.05)
			end
		end
		body(model, center, 420, C(255, 215, 150), 0.88)           -- glow
		body(model, center, 200, C(255, 240, 200), 0.4)            -- bright core
	end

	BUILDERS.BlackHole = function(model, rng)
		backgroundStars(model, rng, 100)
		local dir = Vector3.new(0, 0.42, -0.9).Unit
		local center = dir * DIST
		body(model, center, 920, C(255, 120, 40), 0.94)            -- soft glow around it
		local disk = CFrame.Angles(math.rad(72), math.rad(15), 0)  -- accretion disk, seen almost edge-on
		for _ = 1, 150 do
			local r = 300 + rng:NextNumber() ^ 1.4 * 330
			local th = rng:NextNumber(0, math.pi * 2)
			local off = Vector3.new(r * math.cos(th), rng:NextNumber(-8, 8), r * math.sin(th))
			local k = (r - 300) / 330                              -- 0 inside, 1 outside
			body(model, center + disk:VectorToWorldSpace(off), rng:NextNumber(10, 26) * (1.2 - k * 0.5),
				Color3.fromHSV(0.12 - k * 0.1, 0.55 + k * 0.4, 1), 0.05)
		end
		local nrm = -dir                                           -- bright ring around the hole (lensing)
		local u = nrm:Cross(Vector3.yAxis).Unit
		local v = nrm:Cross(u)
		for i = 1, 70 do
			local th = (i / 70) * math.pi * 2
			body(model, center + (u * math.cos(th) + v * math.sin(th)) * 195, 14, C(255, 225, 175), 0.05)
		end
		body(model, center, 340, C(0, 0, 0), 0)                    -- the black hole itself
	end

	local function buildWeather(kind)
		local part = Instance.new("Part")
		part.Name = "AA_Weather"
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Transparency = 1
		part.Size = Vector3.new(90, 1, 90)
		part.Parent = extraFolder
		weatherPart = part

		local e = Instance.new("ParticleEmitter")
		e.EmissionDirection = Enum.NormalId.Bottom
		e.LockedToPart = false
		e.Lifetime = NumberRange.new(5, 7)
		e.Rotation = NumberRange.new(0, 360)
		if kind == "Snow" then
			e.Rate = 90
			e.Speed = NumberRange.new(6, 10)
			e.SpreadAngle = Vector2.new(20, 20)
			e.Size = NumberSequence.new(0.35)
			e.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
			e.Acceleration = Vector3.new(1.5, 0, 0.5)
			e.RotSpeed = NumberRange.new(-30, 30)
			e.LightEmission = 0.3
			e.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.15),
				NumberSequenceKeypoint.new(1, 0.6),
			})
		else -- Leaves
			e.Rate = 45
			e.Speed = NumberRange.new(3, 6)
			e.SpreadAngle = Vector2.new(25, 25)
			e.Size = NumberSequence.new(0.55)
			e.Color = ColorSequence.new(Color3.fromRGB(255, 160, 40), Color3.fromRGB(170, 60, 20))
			e.Acceleration = Vector3.new(3, -1, 1)
			e.RotSpeed = NumberRange.new(-140, 140)
			e.LightEmission = 0
			e.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.1),
				NumberSequenceKeypoint.new(1, 0.5),
			})
		end
		e.Parent = part
	end

	local function setExtra(kind)
		if kind == extraKind and extraFolder and extraFolder.Parent then return end
		clearExtra()
		if not kind then return end
		local cam = workspace.CurrentCamera
		if not cam then return end
		extraKind = kind
		extraFolder = Instance.new("Folder")
		extraFolder.Name = "AA_ShaderExtras"
		extraFolder.Parent = cam

		if kind == "Snow" or kind == "Leaves" then
			buildWeather(kind)
		else
			skyOn()
			local model = Instance.new("Model")
			model.Name = "AA_SkyRig"
			local root = Instance.new("Part")
			root.Name = "Root"
			root.Anchored = true
			root.CanCollide = false
			root.CanQuery = false
			root.CanTouch = false
			root.Transparency = 1
			root.Size = Vector3.one
			root.Parent = model
			model.PrimaryPart = root
			BUILDERS[kind](model, Random.new(7))
			model.Parent = extraFolder
			rig = model
			rigAt = 0 -- place it right away
		end
	end

	local function updateExtras()
		if not extraKind then return end
		local cam = workspace.CurrentCamera
		if not cam then return end
		if not (extraFolder and extraFolder.Parent) then -- the camera was replaced: build again
			setExtra(extraKind)
			return
		end
		local pos = cam.CFrame.Position
		if weatherPart then weatherPart.Position = pos + Vector3.new(0, 38, 0) end
		if rig then
			local now = os.clock()
			-- the sky follows you (far away, so only when you moved) and drifts slowly
			if now - rigAt > 0.2 or (pos - rigCenter).Magnitude > 25 then
				rigAt, rigCenter = now, pos
				rig:PivotTo(CFrame.new(pos) * CFrame.Angles(0, now * 0.012, 0))
			end
		end
	end

	--// ----- the lighting engine -----
	local active, tweening = false, false
	local appliedKey
	local saved, fx
	local curTweens = {}

	local function wantedKey()
		if Settings.ShaderPlus and premiumUnlocked then
			return PRESETS[Settings.ShaderPlusMode] and Settings.ShaderPlusMode or "Day"
		end
		if Settings.Shader then
			return PRESETS[Settings.TimeOfDay] and Settings.TimeOfDay or "Day"
		end
		return nil
	end

	local function activate()
		saved = {}
		for _, k in ipairs(LIGHT_KEYS) do saved[k] = Lighting[k] end
		fx = {}
		fx.cc = Instance.new("ColorCorrectionEffect")
		fx.cc.Name = "AA_Shader_ColorCorrection"
		fx.cc.Parent = Lighting
		fx.bloom = Instance.new("BloomEffect")
		fx.bloom.Name = "AA_Shader_Bloom"
		fx.bloom.Parent = Lighting
		fx.rays = Instance.new("SunRaysEffect")
		fx.rays.Name = "AA_Shader_SunRays"
		fx.rays.Parent = Lighting
		-- reuse the game's Atmosphere if it has one (two would fight), otherwise add our own
		local existing = Lighting:FindFirstChildOfClass("Atmosphere")
		if existing then
			fx.atmo = existing
			fx.atmoSaved = {
				Density = existing.Density, Offset = existing.Offset, Color = existing.Color,
				Decay = existing.Decay, Glare = existing.Glare, Haze = existing.Haze,
			}
		else
			fx.atmo = Instance.new("Atmosphere")
			fx.atmo.Name = "AA_Shader_Atmosphere"
			fx.atmo.Parent = Lighting
			fx.ownAtmo = true
		end
		active = true
	end

	local function goTo(key)
		local pr = PRESETS[key] or PRESETS.Day
		appliedKey = key
		for _, t in ipairs(curTweens) do t:Cancel() end
		table.clear(curTweens)

		local info = TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		local light = { ClockTime = pr.clock }
		for k, v in pairs(pr.light) do light[k] = v end
		table.insert(curTweens, TweenService:Create(Lighting, info, light))
		table.insert(curTweens, TweenService:Create(fx.cc, info, pr.cc))
		table.insert(curTweens, TweenService:Create(fx.bloom, info, pr.bloom))
		table.insert(curTweens, TweenService:Create(fx.rays, info, pr.rays))
		table.insert(curTweens, TweenService:Create(fx.atmo, info, pr.atmo))

		tweening = true
		local first = curTweens[1]
		first.Completed:Connect(function()
			if curTweens[1] == first then tweening = false end
		end)
		for _, t in ipairs(curTweens) do t:Play() end
		setExtra(pr.extra)
	end

	local function deactivate()
		for _, t in ipairs(curTweens) do t:Cancel() end
		table.clear(curTweens)
		clearExtra()
		for k, v in pairs(saved) do
			pcall(function() Lighting[k] = v end)
		end
		fx.cc:Destroy()
		fx.bloom:Destroy()
		fx.rays:Destroy()
		if fx.ownAtmo then
			fx.atmo:Destroy()
		elseif fx.atmo.Parent then
			for k, v in pairs(fx.atmoSaved) do fx.atmo[k] = v end
		end
		fx, saved = nil, nil
		active, tweening, appliedKey = false, false, nil
	end

	RunService.Heartbeat:Connect(function()
		local key = wantedKey()
		if key then
			if Settings.Fullbright then -- e.g. both came from a config: the shader wins
				Settings.Fullbright = false
				if uiRefresh.Fullbright then uiRefresh.Fullbright() end
			end
			if not active then
				if fbSaved then return end -- wait until Fullbright has given the lighting back
				activate()
				goTo(key)
			elseif appliedKey ~= key then
				goTo(key)
			elseif not tweening then
				-- the game may move the clock / lighting again, so hold our values
				local pr = PRESETS[appliedKey] or PRESETS.Day
				if math.abs(Lighting.ClockTime - pr.clock) > 0.02 then Lighting.ClockTime = pr.clock end
				for k, v in pairs(pr.light) do
					if Lighting[k] ~= v then Lighting[k] = v end
				end
			end
			updateExtras()
		elseif active then
			deactivate()
		end
	end)
end
end -- (scope: keeps the main chunk under the 200-locals limit)

--// ===== WORLD PARTICLES (floating cubes / circles in the theme color) =====
-- Client-side parts parked in the camera folder (other players never see them). They drift and
-- spin around you, fade in and out, and are recycled when they leave the radius.
do
	local RADIUS = 70
	local rng = Random.new()
	local folder
	local list = {}
	local frame = 0
	local shapeBall

	-- theme accent with a little hue / brightness variation per particle
	local function colorOf(p)
		local h, sat, val = THEME.accent:ToHSV()
		return Color3.fromHSV((h + p.hue) % 1, math.clamp(sat * p.sat, 0, 1), math.clamp(val * p.val, 0, 1))
	end

	local function randomPoint(center, minR)
		local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1))
		if dir.Magnitude < 0.05 then dir = Vector3.yAxis end
		return center + dir.Unit * (RADIUS * (minR + (1 - minR) * rng:NextNumber() ^ (1 / 3)))
	end

	local function addParticle(center)
		local part = Instance.new("Part")
		part.Name = "WorldParticle"
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false -- shots and wall checks ignore them
		part.CanTouch = false
		part.CastShadow = false
		part.Massless = true
		part.Material = Enum.Material.Neon
		part.Shape = shapeBall and Enum.PartType.Ball or Enum.PartType.Block
		local size = rng:NextNumber(0.25, 0.75)
		part.Size = Vector3.new(size, size, size)
		part.Parent = folder

		local p = {
			part = part,
			pos = randomPoint(center, 0),
			vel = Vector3.new(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0.3, 1.2), rng:NextNumber(-0.3, 0.3)),
			spin = Vector3.new(rng:NextNumber(-2, 2), rng:NextNumber(-2, 2), rng:NextNumber(-2, 2)),
			rot = Vector3.zero,
			phase = rng:NextNumber(0, math.pi * 2),
			hue = rng:NextNumber(-0.03, 0.03),
			sat = rng:NextNumber(0.8, 1.05),
			val = rng:NextNumber(0.85, 1.1),
		}
		part.Color = colorOf(p)
		table.insert(list, p)
	end

	-- the cloud follows the menu theme
	table.insert(themeHooks, function()
		for _, p in ipairs(list) do p.part.Color = colorOf(p) end
	end)

	local parts, cfs = {}, {}
	RunService.Heartbeat:Connect(function(dt)
		if not Settings.WorldParticles then
			if folder then
				folder:Destroy()
				folder = nil
				table.clear(list)
			end
			return
		end
		local camera = workspace.CurrentCamera
		if not camera then return end
		if folder and not folder.Parent then -- the camera was replaced
			folder = nil
			table.clear(list)
		end
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "WorldParticles"
			folder.Parent = camera
		end

		local center = camera.CFrame.Position
		local ball = Settings.ParticleShape == "Circles"
		if ball ~= shapeBall then
			shapeBall = ball
			for _, p in ipairs(list) do
				p.part.Shape = ball and Enum.PartType.Ball or Enum.PartType.Block
			end
		end
		local want = math.floor(Settings.ParticleCount)
		while #list < want do addParticle(center) end
		while #list > want do
			local p = table.remove(list)
			p.part:Destroy()
		end

		frame += 1
		local t = os.clock()
		table.clear(parts)
		table.clear(cfs)
		for i, p in ipairs(list) do
			local sway = Vector3.new(
				math.sin(t * 0.7 + p.phase) * 0.5,
				math.cos(t * 0.9 + p.phase) * 0.35,
				math.cos(t * 0.6 + p.phase) * 0.5)
			p.pos += (p.vel + sway) * dt
			local dist = (p.pos - center).Magnitude
			if dist > RADIUS then -- left the area: come back on the outer edge
				p.pos = randomPoint(center, 0.85)
				dist = (p.pos - center).Magnitude
			end
			p.rot += p.spin * dt
			parts[i] = p.part
			cfs[i] = CFrame.new(p.pos) * CFrame.Angles(p.rot.X, p.rot.Y, p.rot.Z)

			if frame % 2 == 0 then -- soft pulse + fade near the edge
				local pulse = 0.5 + 0.5 * math.sin(t * 1.6 + p.phase)
				local tr = 0.2 + 0.5 * pulse
				local edge = math.clamp((dist - RADIUS * 0.7) / (RADIUS * 0.3), 0, 1)
				p.part.Transparency = tr + (1 - tr) * edge
			end
		end
		workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	end)
end

--// ===== FIRST-PERSON VIEWMODEL DISCOVERY (shared by View Model and Hand Shader) =====
-- Many games draw your arms and weapon as a separate model inside the camera (not as your
-- character). Such models are found here by their parts (names with arm / hand / glove / sleeve)
-- or by the model name (viewmodel, arms, hands, ...). View Model moves their arms and
-- Hand Shader outlines the whole model, so a weapon in the hands is covered as well.
local VMX = { roots = {} }
do
	local ARM_WORDS = { "arm", "hand", "glove", "sleeve" }
	local VM_WORDS = { "viewmodel", "view_model", "firstperson", "first_person", "fparms", "arms", "hands" }

	local function has(name, list)
		name = name:lower()
		for _, w in ipairs(list) do
			if name:find(w, 1, true) then return true end
		end
		return false
	end

	function VMX.isArm(name) return has(name, ARM_WORDS) end

	-- "L" / "R" / nil from a part name (LeftArm, Left Hand, L_Arm, Arm_R ...)
	function VMX.sideOf(name)
		local n = name:lower()
		if n:find("left", 1, true) or n:match("^l[_%-%s]?arm") or n:match("^l[_%-%s]?hand")
			or n:match("[_%-%s]l$") then
			return "L"
		end
		if n:find("right", 1, true) or n:match("^r[_%-%s]?arm") or n:match("^r[_%-%s]?hand")
			or n:match("[_%-%s]r$") then
			return "R"
		end
		return nil
	end

	local function looksLikeArms(inst)
		if inst:IsA("BasePart") then return VMX.isArm(inst.Name) end
		if has(inst.Name, VM_WORDS) then return true end
		for _, d in ipairs(inst:GetDescendants()) do
			if d:IsA("BasePart") and VMX.isArm(d.Name) then return true end
		end
		return false
	end

	local cache = setmetatable({}, { __mode = "k" }) -- instance -> { t =, ok = }
	local function qualifies(inst)
		local c = cache[inst]
		local now = os.clock()
		if not c or now - c.t > (c.ok and 10 or 3) then
			c = { t = now, ok = looksLikeArms(inst) }
			cache[inst] = c
		end
		return c.ok
	end

	local worldRoots, worldAt = {}, 0
	task.spawn(function()
		while true do
			if Settings.ViewModel or Settings.HandShader or Settings.HandsXZ or Settings.HandsXZ2
				or Settings.CosGunSkin ~= "None" then
				local roots = {}
				local cam = workspace.CurrentCamera
				if cam then
					for _, ch in ipairs(cam:GetChildren()) do
						if ch.Name ~= "WorldParticles"
							and (ch:IsA("Model") or ch:IsA("Folder") or ch:IsA("BasePart"))
							and qualifies(ch) then
							table.insert(roots, ch)
						end
					end
				end
				-- some games keep the viewmodel in workspace: look for it by name every 2 s
				if os.clock() - worldAt > 2 then
					worldAt = os.clock()
					worldRoots = {}
					for _, ch in ipairs(workspace:GetChildren()) do
						if (ch:IsA("Model") or ch:IsA("Folder")) and has(ch.Name, VM_WORDS)
							and not Players:GetPlayerFromCharacter(ch) then
							table.insert(worldRoots, ch)
						end
					end
				end
				for _, r in ipairs(worldRoots) do
					if r.Parent then table.insert(roots, r) end
				end
				VMX.roots = roots
			else
				VMX.roots = {}
			end
			task.wait(0.25)
		end
	end)
end

--// ===== VIEW MODEL (move the left / right arm) =====
-- 1) Your character's arms: the shoulder joint is shifted in torso space (R15 and R6).
-- 2) A first-person viewmodel in the camera: the joint that holds each arm is shifted in the
--    space of the part it hangs on (arms without a joint that are anchored are shifted in
--    camera space). The weapon is not moved, only the arms.
do
	local base = setmetatable({}, { __mode = "k" })  -- joint -> { C0 =, C1 = } (original values)
	local base2 = setmetatable({}, { __mode = "k" }) -- anchored arm part -> the game's CFrame
	local ours = setmetatable({}, { __mode = "k" })  -- anchored arm part -> CFrame we set last
	local cachedChar, mL, mR
	local recs, recsAt = {}, 0
	local wasOn = false

	local function findMotors(char)
		local lu = char:FindFirstChild("LeftUpperArm")
		local ru = char:FindFirstChild("RightUpperArm")
		local ml = lu and lu:FindFirstChild("LeftShoulder")
		local mr = ru and ru:FindFirstChild("RightShoulder")
		local torso = char:FindFirstChild("Torso") -- R6
		if torso then
			ml = ml or torso:FindFirstChild("Left Shoulder")
			mr = mr or torso:FindFirstChild("Right Shoulder")
		end
		return ml, mr
	end

	local function setMotor(motor, x, y, z)
		if not motor then return end
		local b = base[motor]
		if not b then
			b = { C0 = motor.C0, C1 = motor.C1 }
			base[motor] = b
		end
		local target = CFrame.new(x, y, -z) * b.C0 -- -Z is "forward" in Roblox
		if motor.C0 ~= target then motor.C0 = target end
	end

	-- find the arm joints / anchored arm parts of every viewmodel
	local function rebuild()
		recs = {}
		for _, root in ipairs(VMX.roots) do
			local jointed = {}
			local desc = root:GetDescendants()
			for _, d in ipairs(desc) do
				if d:IsA("JointInstance") and d.Part0 and d.Part1 then
					for _, which in ipairs({ "Part1", "Part0" }) do
						local arm = d[which]
						local other = (which == "Part1") and d.Part0 or d.Part1
						if VMX.isArm(arm.Name) then
							local side = VMX.sideOf(arm.Name)
							-- skip a hand hanging on an arm: it already follows the arm
							if side and not (VMX.isArm(other.Name) and VMX.sideOf(other.Name) == side) then
								table.insert(recs, { joint = d, which = which, side = side })
								jointed[arm] = true
								break
							end
						end
					end
				end
			end
			for _, d in ipairs(desc) do
				if d:IsA("BasePart") and d.Anchored and not jointed[d] and VMX.isArm(d.Name) then
					local side = VMX.sideOf(d.Name)
					if side then table.insert(recs, { part = d, side = side }) end
				end
			end
		end
	end

	local function offsetOf(side)
		if side == "L" then return Settings.VM_LX, Settings.VM_LY, Settings.VM_LZ end
		return Settings.VM_RX, Settings.VM_RY, Settings.VM_RZ
	end

	-- runs last in the frame, after the game has positioned its own viewmodel
	RunService:BindToRenderStep("AA_ViewModel", Enum.RenderPriority.Last.Value, function()
		if not Settings.ViewModel then
			if wasOn then
				wasOn = false
				for joint, b in pairs(base) do
					if joint.Parent then
						joint.C0 = b.C0
						joint.C1 = b.C1
					end
				end
				for part, cf in pairs(base2) do
					if part.Parent and ours[part] and part.CFrame == ours[part] then part.CFrame = cf end
				end
				table.clear(base2)
				table.clear(ours)
			end
			return
		end
		wasOn = true

		-- 1) character arms
		local char = player.Character
		if char then
			if char ~= cachedChar or (mL and not mL.Parent) or (mR and not mR.Parent) then
				cachedChar = char
				mL, mR = findMotors(char)
			end
			setMotor(mL, Settings.VM_LX, Settings.VM_LY, Settings.VM_LZ)
			setMotor(mR, Settings.VM_RX, Settings.VM_RY, Settings.VM_RZ)
		end

		-- 2) viewmodel arms
		if os.clock() - recsAt > 1 then
			recsAt = os.clock()
			rebuild()
		end
		local cam = workspace.CurrentCamera
		for _, r in ipairs(recs) do
			local x, y, z = offsetOf(r.side)
			if r.joint then
				local j = r.joint
				if j.Parent then
					local b = base[j]
					if not b then
						b = { C0 = j.C0, C1 = j.C1 }
						base[j] = b
					end
					local o = CFrame.new(x, y, -z)
					if r.which == "Part1" then
						local t = o * b.C0
						if j.C0 ~= t then j.C0 = t end
					else
						local t = o * b.C1
						if j.C1 ~= t then j.C1 = t end
					end
				end
			elseif r.part and cam and r.part.Parent then
				local part = r.part
				local cur = part.CFrame
				-- if the CFrame is still the one we set, the game did not move it: keep its base
				local b = (ours[part] and cur == ours[part]) and base2[part] or cur
				base2[part] = b
				part.CFrame = b + cam.CFrame:VectorToWorldSpace(Vector3.new(x, y, -z))
				ours[part] = part.CFrame
			end
		end
	end)
end

--// ===== HAND SHADER (fire + glow on hands and held items, theme color) =====
-- Glow = Highlight outline. Fire = flames on hands / lower arms / the tool handle.
-- Covers: your character's arms, the tool in your hand, and a first-person viewmodel in the
-- camera (the whole model, so the weapon in the hands is outlined too).
-- (Roblox draws only a limited number of Highlights at once, shared with ESP.)
do
	local ARM_NAMES = {
		"RightUpperArm", "RightLowerArm", "RightHand",
		"LeftUpperArm", "LeftLowerArm", "LeftHand",
		"Right Arm", "Left Arm", -- R6
	}
	local glow = {}  -- instance -> Highlight
	local fires = {} -- part -> Fire
	local fireCache = setmetatable({}, { __mode = "k" }) -- viewmodel root -> { t =, list = }

	local function paint()
		local col = THEME.accent
		for _, h in pairs(glow) do
			h.FillColor = col
			h.OutlineColor = col:Lerp(Color3.new(1, 1, 1), 0.35)
		end
		for _, f in pairs(fires) do
			f.Color = col:Lerp(Color3.new(1, 1, 1), 0.3)
			f.SecondaryColor = col
		end
	end
	table.insert(themeHooks, paint)

	local function firePart(part)
		local n = part.Name
		return n:find("Hand") or n:find("LowerArm") or n == "Right Arm" or n == "Left Arm"
	end

	-- arm / hand parts of a viewmodel (cached for a second, at most 6 flames per model)
	local function viewmodelFireParts(root)
		local c = fireCache[root]
		local now = os.clock()
		if c and now - c.t < 1 then return c.list end
		local hands, arms = {}, {}
		local function consider(d)
			if d:IsA("BasePart") and VMX.isArm(d.Name) then
				if d.Name:lower():find("hand", 1, true) then table.insert(hands, d) else table.insert(arms, d) end
			end
		end
		consider(root)
		for _, d in ipairs(root:GetDescendants()) do consider(d) end
		local list = (#hands > 0) and hands or arms
		while #list > 6 do table.remove(list) end
		fireCache[root] = { t = now, list = list }
		return list
	end

	local function collect()
		local wantGlow, wantFire = {}, {}
		local style = Settings.HandStyle
		local g = (style == "Both" or style == "Glow")
		local f = (style == "Both" or style == "Fire")

		local char = player.Character
		if char then
			for _, name in ipairs(ARM_NAMES) do
				local part = char:FindFirstChild(name)
				if part and part:IsA("BasePart") then
					if g then wantGlow[part] = true end
					if f and firePart(part) then wantFire[part] = true end
				end
			end
			-- whatever is held in the hand
			local tool = char:FindFirstChildOfClass("Tool")
			if tool then
				if g then wantGlow[tool] = true end
				local handle = tool:FindFirstChild("Handle")
				if f and handle and handle:IsA("BasePart") then wantFire[handle] = true end
			end
		end

		for _, root in ipairs(VMX.roots) do
			if g then wantGlow[root] = true end
			if f then
				for _, part in ipairs(viewmodelFireParts(root)) do wantFire[part] = true end
			end
		end
		return wantGlow, wantFire
	end

	local function reconcile(wantGlow, wantFire)
		for inst, h in pairs(glow) do
			if not wantGlow[inst] or not h.Parent or not inst.Parent then
				h:Destroy()
				glow[inst] = nil
			end
		end
		for inst in pairs(wantGlow) do
			if not glow[inst] and inst.Parent then
				local h = Instance.new("Highlight")
				h.Name = "AA_HandGlow"
				h.FillTransparency = 0.55
				h.OutlineTransparency = 0
				h.DepthMode = Enum.HighlightDepthMode.Occluded
				h.Adornee = inst
				h.Parent = inst
				glow[inst] = h
			end
		end

		for part, f in pairs(fires) do
			if not wantFire[part] or not f.Parent or not part.Parent then
				f:Destroy()
				fires[part] = nil
			end
		end
		for part in pairs(wantFire) do
			if not fires[part] and part.Parent then
				local f = Instance.new("Fire")
				f.Name = "AA_HandFire"
				f.Size = 3
				f.Heat = 6
				f.Parent = part
				fires[part] = f
			end
		end
		paint()
	end

	task.spawn(function()
		while true do
			if Settings.HandShader then
				reconcile(collect())
			elseif next(glow) ~= nil or next(fires) ~= nil then
				reconcile({}, {})
			end
			task.wait(0.25)
		end
	end)
end

--// ===== HANDS XZ / HANDS XZ2 (shimmering color wave over hands and the held item) =====
-- A bright band of light runs over every part of your hands and of the item you hold, in the
-- chosen direction (bottom to top, top to bottom, left to right, right to left). Parts glow
-- (Neon), the outline pulses and little sparks float the same way.
-- Hands XZ uses the menu theme color. Hands XZ2 (Premium) has its own palettes: Rainbow,
-- Black & White, Pink, Blue, Green, Red, Green-Yellow.
-- Only the ITEM you hold is animated (the tool in your hand, or the weapon of a first-person
-- viewmodel in the camera), not the arms. Everything is restored when it is off.
do
	local FREQ = 0.45     -- waves per stud
	local MAX_PARTS = 120
	local ARM_NAMES = {
		"RightUpperArm", "RightLowerArm", "RightHand",
		"LeftUpperArm", "LeftLowerArm", "LeftHand",
		"Right Arm", "Left Arm", -- R6
	}

	local orig = {}     -- part -> { Color =, Material = } before we touched it
	local active = {}   -- parts animated right now (list, used every frame)
	local glow = {}     -- instance -> Highlight (pulsing outline)
	local emit = {}     -- part -> ParticleEmitter (sparks)

	-- narrow bright band: 1 in the middle of the phase, 0 at the edges
	local function band(phase)
		local d = math.abs(phase - 0.5) * 2
		return math.max(0, 1 - d * 3.2) ^ 2
	end

	-- single-hue shimmer around a base color (hue / brightness wave + bright band)
	local function shimmer(phase, h, s, v)
		local wave = math.sin(phase * math.pi * 2)
		local shine = band(phase)
		local hue = (h + 0.07 * wave) % 1
		local sat = math.clamp(s * (1 - 0.55 * shine), 0, 1)
		local val = math.clamp(v * (0.7 + 0.3 * (0.5 + 0.5 * wave)) + 0.25 * shine, 0, 1)
		return Color3.fromHSV(hue, sat, val)
	end

	-- Hands XZ2 palettes: phase (0..1) -> color
	local PALETTES = {
		["Rainbow"] = function(ph)
			return Color3.fromHSV(ph % 1, 0.85 - 0.5 * band(ph), 1)
		end,
		["Black & White"] = function(ph)
			local w = 0.5 + 0.5 * math.sin(ph * math.pi * 2)
			return Color3.fromHSV(0, 0, w ^ 1.5)
		end,
		["Pink"]  = function(ph) return shimmer(ph, 0.92, 0.8, 1) end,
		["Blue"]  = function(ph) return shimmer(ph, 0.6, 0.85, 1) end,
		["Green"] = function(ph) return shimmer(ph, 0.35, 0.85, 1) end,
		["Red"]   = function(ph) return shimmer(ph, 0.0, 0.9, 1) end,
		["Green-Yellow"] = function(ph)
			local wave = math.sin(ph * math.pi * 2)
			return Color3.fromHSV(0.25 + 0.1 * wave, 0.9 - 0.4 * band(ph), 1)
		end,
	}

	local function restorePart(p)
		local o = orig[p]
		if o then
			if p.Parent then
				p.Color = o.Color
				p.Material = o.Material
			end
			orig[p] = nil
		end
	end

	-- colors of the sparks (theme for Hands XZ, palette for Hands XZ2)
	local function sparkColors()
		if Settings.HandsXZ2 then
			local pal = Settings.HandsXZ2Palette
			if pal == "Rainbow" then
				local keys = {}
				for i = 0, 6 do
					keys[#keys + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 7, 0.8, 1))
				end
				return ColorSequence.new(keys)
			elseif pal == "Black & White" then
				return ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(140, 140, 140))
			elseif pal == "Green-Yellow" then
				return ColorSequence.new(Color3.fromHSV(0.33, 0.9, 1), Color3.fromHSV(0.16, 0.9, 1))
			end
			local hue = ({ Pink = 0.92, Blue = 0.6, Green = 0.35, Red = 0 })[pal] or 0
			return ColorSequence.new(Color3.fromHSV(hue, 0.35, 1), Color3.fromHSV(hue, 0.85, 1))
		end
		local c = THEME.accent
		return ColorSequence.new(c:Lerp(Color3.new(1, 1, 1), 0.6), c)
	end
	table.insert(themeHooks, function()
		for _, e in pairs(emit) do e.Color = sparkColors() end
	end)

	-- is this part inside an arm-named ancestor of the viewmodel? then it is an arm, not the item
	local function isUnderArm(d, root)
		local a = d
		while a and a ~= root do
			if VMX.isArm(a.Name) then return true end
			a = a.Parent
		end
		return false
	end

	-- what should be animated: ONLY the item held in the hand (not the arms)
	-- parts, outlines and spark emitters
	local function collect()
		local set, list, wantGlow, wantEmit = {}, {}, {}, {}
		local function addPart(p)
			if #list < MAX_PARTS and p:IsA("BasePart") and not set[p] then
				set[p] = true
				table.insert(list, p)
			end
		end

		-- the tool in the character's hand
		local char = player.Character
		local tool = char and char:FindFirstChildOfClass("Tool")
		if tool then
			for _, d in ipairs(tool:GetDescendants()) do addPart(d) end
			wantGlow[tool] = true
			local handle = tool:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then wantEmit[handle] = true end
		end

		-- the weapon of a first-person viewmodel: every part that is not an arm
		for _, root in ipairs(VMX.roots) do
			local held = {}
			local nodes = root:IsA("BasePart") and { root } or root:GetDescendants()
			for _, d in ipairs(nodes) do
				if d:IsA("BasePart") and not VMX.isArm(d.Name) and not isUnderArm(d, root) then
					addPart(d)
					table.insert(held, d)
				end
			end
			table.sort(held, function(a, b)
				return a.Size.X * a.Size.Y * a.Size.Z > b.Size.X * b.Size.Y * b.Size.Z
			end)
			for i = 1, math.min(#held, 4) do wantGlow[held[i]] = true end -- outline the biggest parts
			if held[1] then wantEmit[held[1]] = true end                  -- sparks from the main part
		end
		return list, set, wantGlow, wantEmit
	end

	local function reconcile(list, set, wantGlow, wantEmit)
		-- parts that are no longer targets get their look back
		for p in pairs(orig) do
			if not set[p] then restorePart(p) end
		end
		for _, p in ipairs(list) do
			if not orig[p] then orig[p] = { Color = p.Color, Material = p.Material } end
		end
		active = list

		for inst, hl in pairs(glow) do
			if not wantGlow[inst] or not hl.Parent or not inst.Parent then
				hl:Destroy()
				glow[inst] = nil
			end
		end
		for inst in pairs(wantGlow) do
			if not glow[inst] and inst.Parent then
				local hl = Instance.new("Highlight")
				hl.Name = "AA_HandsXZGlow"
				hl.FillTransparency = 1
				hl.OutlineTransparency = 0.1
				hl.DepthMode = Enum.HighlightDepthMode.Occluded
				hl.Adornee = inst
				hl.Parent = inst
				glow[inst] = hl
			end
		end

		for part, e in pairs(emit) do
			if not wantEmit[part] or not e.Parent or not part.Parent then
				e:Destroy()
				emit[part] = nil
			end
		end
		for part in pairs(wantEmit) do
			if not emit[part] and part.Parent then
				local e = Instance.new("ParticleEmitter")
				e.Name = "AA_HandsXZSparks"
				e.Rate = 14
				e.Lifetime = NumberRange.new(0.6, 1.2)
				e.Speed = NumberRange.new(0.2, 0.6)
				e.SpreadAngle = Vector2.new(180, 180)
				e.Rotation = NumberRange.new(0, 360)
				e.RotSpeed = NumberRange.new(-60, 60)
				e.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.12),
					NumberSequenceKeypoint.new(0.5, 0.18),
					NumberSequenceKeypoint.new(1, 0),
				})
				e.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.1),
					NumberSequenceKeypoint.new(1, 1),
				})
				e.LightEmission = 1
				e.Color = sparkColors()
				e.Parent = part
				emit[part] = e
			end
		end
	end

	local function clearAll()
		for p in pairs(orig) do restorePart(p) end
		active = {}
		for inst, hl in pairs(glow) do
			hl:Destroy()
			glow[inst] = nil
		end
		for part, e in pairs(emit) do
			e:Destroy()
			emit[part] = nil
		end
	end

	-- 4 times a second: find what to animate (not every frame)
	local lastSparkKey
	task.spawn(function()
		while true do
			if Settings.HandsXZ or Settings.HandsXZ2 then
				reconcile(collect())
				local key = Settings.HandsXZ2 and ("p:" .. tostring(Settings.HandsXZ2Palette)) or "theme"
				if key ~= lastSparkKey then -- palette changed: recolor the sparks
					lastSparkKey = key
					for _, e in pairs(emit) do e.Color = sparkColors() end
				end
			elseif next(orig) ~= nil or next(glow) ~= nil or next(emit) ~= nil then
				clearAll()
			end
			task.wait(0.25)
		end
	end)

	-- every frame: move the wave
	RunService:BindToRenderStep("AA_HandsXZ", Enum.RenderPriority.Last.Value + 1, function()
		local xz2 = Settings.HandsXZ2
		if not (Settings.HandsXZ or xz2) then return end
		local cam = workspace.CurrentCamera
		if not cam then return end

		local mode = xz2 and Settings.HandsXZ2Dir or Settings.HandsXZMode
		local dirV = Vector3.yAxis                          -- bottom to top
		if mode == "Top to bottom" then
			dirV = -Vector3.yAxis
		elseif mode == "Left to right" then
			dirV = cam.CFrame.RightVector
		elseif mode == "Right to left" then
			dirV = -cam.CFrame.RightVector
		end

		local t = os.clock() * (xz2 and Settings.HandsXZ2Speed or Settings.HandsXZSpeed)
		local h, s, v = THEME.accent:ToHSV()
		local pal = xz2 and PALETTES[Settings.HandsXZ2Palette] or nil

		for i = 1, #active do
			local p = active[i]
			if p.Parent then
				if p.Material ~= Enum.Material.Neon then p.Material = Enum.Material.Neon end
				-- the band moves along dirV as time goes on
				local ph = (p.Position:Dot(dirV) * FREQ - t) % 1
				p.Color = pal and pal(ph) or shimmer(ph, h, s, v)
			end
		end

		local gph = (t * 0.5) % 1
		local outline = pal and pal(gph) or shimmer(gph, h, s, v)
		for _, hl in pairs(glow) do hl.OutlineColor = outline end
		local accel = dirV * 6 -- sparks drift the same way
		for _, e in pairs(emit) do e.Acceleration = accel end
	end)
end

--// ===== WATERMARK (top bar: logo | name | game | FPS | ping | players) =====
-- Dark pill at the top center. The logo and the units (FPS / MS / PLR) use the menu theme color.
do
	local Stats = game:GetService("Stats")
	local MarketplaceService = game:GetService("MarketplaceService")

	local bar = Instance.new("Frame")
	bar.Name = "Watermark"
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.new(0.5, 0, 0, 8)
	bar.Size = UDim2.fromOffset(0, 24)
	bar.AutomaticSize = Enum.AutomaticSize.X
	bar.BackgroundColor3 = THEME.panel
	bar.BackgroundTransparency = 0.12
	bar.BorderSizePixel = 0
	bar.Visible = false
	bar.Parent = gui
	Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 10)
	do
		local st = Instance.new("UIStroke", bar)
		st.Transparency = 0.6
		themeBind(st, "Color", "accent")
		local l = Instance.new("UIListLayout", bar)
		l.FillDirection = Enum.FillDirection.Horizontal
		l.Padding = UDim.new(0, 8)
		l.SortOrder = Enum.SortOrder.LayoutOrder
		l.VerticalAlignment = Enum.VerticalAlignment.Center
		local p = Instance.new("UIPadding", bar)
		p.PaddingLeft, p.PaddingRight = UDim.new(0, 9), UDim.new(0, 10)
	end

	local order = 0
	local function add(obj)
		order += 1
		obj.LayoutOrder = order
		obj.Parent = bar
		return obj
	end

	-- logo: the purple flaming "V". To use the real picture, upload it to Roblox (Creator Hub ->
	-- Decals) and put the number here, for example LOGO_IMAGE_ID = "123456789".
	local LOGO_IMAGE_ID = ""
	if LOGO_IMAGE_ID ~= "" then
		local img = Instance.new("ImageLabel")
		img.Size = UDim2.fromOffset(22, 22)
		img.BackgroundTransparency = 1
		img.Image = "rbxassetid://" .. LOGO_IMAGE_ID
		add(img)
	else
		local logo = Instance.new("TextLabel")
		logo.Size = UDim2.fromOffset(18, 20)
		logo.BackgroundTransparency = 1
		logo.Font = Enum.Font.GothamBlack
		logo.TextSize = 20
		logo.Text = "V"
		logo.TextColor3 = Color3.new(1, 1, 1)
		add(logo)
		local g = Instance.new("UIGradient", logo) -- hot pink on top, deep purple at the bottom
		g.Rotation = 90
		g.Color = ColorSequence.new(Color3.fromRGB(255, 190, 255), Color3.fromRGB(150, 60, 235))
		local glow = Instance.new("UIStroke", logo) -- purple glow around the letter
		glow.Color = Color3.fromRGB(190, 70, 255)
		glow.Thickness = 1.5
		glow.Transparency = 0.3
	end

	local function separator()
		local f = Instance.new("Frame")
		f.Size = UDim2.fromOffset(1, 12)
		f.BackgroundColor3 = THEME.off
		f.BorderSizePixel = 0
		add(f)
	end

	local function text(initial)
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(0, 0, 1, 0)
		l.AutomaticSize = Enum.AutomaticSize.X
		l.BackgroundTransparency = 1
		l.RichText = true
		l.Font = Enum.Font.GothamMedium
		l.TextSize = 12
		l.TextColor3 = THEME.text
		l.Text = initial
		return add(l)
	end

	separator()
	text(player.Name)
	separator()
	do
		local RANKS = { -- keys are lowercase: Roblox names do not care about case
			yt120984 = { "OWNER", "FFD24D" },
			timofeyyy23 = { "D.OWNER", "FF3B3B" },
			tysm777uwu2 = { "TESTER", "4FC3F7" },
		}
		local r = RANKS[player.Name:lower()] or { "PLAYER", "9E9E9E" }
		text(string.format('<font color="#%s">%s</font>', r[2], r[1]))
	end
	separator()
	local gameLbl = text(game.Name ~= "" and game.Name or "Roblox")
	separator()
	local fpsLbl = text("0 FPS")
	separator()
	local pingLbl = text("0 MS")
	separator()
	local plrLbl = text("0 PLR")

	-- the game's real name (needs a web request, so it is done in the background)
	task.spawn(function()
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, game.PlaceId)
		if ok and info and info.Name then
			gameLbl.Text = #info.Name > 24 and (info.Name:sub(1, 23) .. "…") or info.Name
		end
	end)

	local fps, ping = 0, 0
	local function unit(t)
		return string.format('<font color="#%s">%s</font>', THEME.accent:ToHex(), t)
	end
	local function refresh()
		fpsLbl.Text = fps .. " " .. unit("FPS")
		pingLbl.Text = ping .. " " .. unit("MS")
		plrLbl.Text = #Players:GetPlayers() .. "/" .. Players.MaxPlayers .. " " .. unit("PLR")
	end
	table.insert(themeHooks, refresh) -- units follow the theme color
	refresh()

	local frames, acc = 0, 0
	RunService.Heartbeat:Connect(function(dt)
		if not Settings.Watermark then
			if bar.Visible then bar.Visible = false end
			return
		end
		if not bar.Visible then bar.Visible = true end

		frames += 1
		acc += dt
		if acc >= 0.5 then -- numbers refresh twice a second
			fps = math.floor(frames / acc + 0.5)
			frames, acc = 0, 0
			local ok, v = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
			ping = ok and math.floor(v + 0.5) or 0
			refresh()
		end
	end)
end

--// ===== MOVEMENT EXTRAS: Infinite Jump, Auto Grab =====
do
	-- Infinite Jump: every jump request (space bar / jump button) jumps again, also in the air
	UserInputService.JumpRequest:Connect(function()
		if not Settings.InfiniteJump then return end
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end)

	-- Auto Grab: some prompts need a special item. When such a prompt shows up (or you start using
	-- it) the item is equipped; after the interaction the item that was in your hand comes back.
	local PPS = game:GetService("ProximityPromptService")
	local STRONG_ATTRS = { "RequiredTool", "ToolName", "Tool", "RequiresTool", "Item", "RequiredItem" }
	local shown = {}      -- prompt -> tool it needs
	local previous        -- nil = no grab in progress, false = hand was empty, Tool = item to give back
	local grabbed         -- the item we equipped
	local token = 0       -- cancels a pending "give back"

	local function ownTools()
		local list = {}
		local pack = player:FindFirstChildOfClass("Backpack")
		if pack then
			for _, t in ipairs(pack:GetChildren()) do
				if t:IsA("Tool") then list[#list + 1] = t end
			end
		end
		local char = player.Character
		if char then
			for _, t in ipairs(char:GetChildren()) do
				if t:IsA("Tool") then list[#list + 1] = t end
			end
		end
		return list
	end

	-- which of your tools does this prompt ask for? (attributes, value objects, the prompt's own
	-- texts and the names of the object it sits on are compared with the tool names)
	local function neededTool(prompt)
		local tools = ownTools()
		if #tools == 0 then return nil end

		local strong, weak = {}, {}
		for _, a in ipairs(STRONG_ATTRS) do
			local v = prompt:GetAttribute(a)
			if v == nil and prompt.Parent then v = prompt.Parent:GetAttribute(a) end
			if type(v) == "string" and v ~= "" then strong[#strong + 1] = v:lower() end
		end
		for _, c in ipairs(prompt:GetChildren()) do
			if c:IsA("StringValue") then
				local n = c.Name:lower()
				if (n:find("tool", 1, true) or n:find("item", 1, true)) and c.Value ~= "" then
					strong[#strong + 1] = c.Value:lower()
				end
			end
		end
		if prompt.ObjectText ~= "" then strong[#strong + 1] = prompt.ObjectText:lower() end
		if prompt.ActionText ~= "" then strong[#strong + 1] = prompt.ActionText:lower() end

		local inst, depth = prompt.Parent, 0
		while inst and inst ~= workspace and depth < 3 do
			weak[#weak + 1] = inst.Name:lower()
			inst, depth = inst.Parent, depth + 1
		end

		for _, tool in ipairs(tools) do
			local tn = tool.Name:lower()
			if #tn >= 3 then
				for _, h in ipairs(strong) do
					if h:find(tn, 1, true) or (#h >= 3 and tn:find(h, 1, true)) then return tool end
				end
				for _, h in ipairs(weak) do
					if h:find(tn, 1, true) then return tool end
				end
			end
		end
		return nil
	end

	local function equip(tool)
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum or tool.Parent == char then return end -- no character, or already in the hand
		if previous == nil then
			previous = char:FindFirstChildOfClass("Tool") or false -- remember what was in the hand
		end
		pcall(function() hum:EquipTool(tool) end)
		grabbed = tool
	end

	local function giveBack()
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			if previous then
				pcall(function() hum:EquipTool(previous) end)
			else
				pcall(function() hum:UnequipTools() end)
			end
		end
		previous, grabbed = nil, nil
	end

	local function giveBackLater()
		token += 1
		local mine = token
		task.delay(0.6, function()
			if mine == token and grabbed then giveBack() end
		end)
	end

	PPS.PromptShown:Connect(function(prompt)
		if not Settings.AutoGrab then return end
		local tool = neededTool(prompt)
		if tool then
			shown[prompt] = tool
			token += 1
			equip(tool)
		end
	end)
	PPS.PromptButtonHoldBegan:Connect(function(prompt, who)
		if not Settings.AutoGrab or who ~= player then return end
		local tool = shown[prompt] or neededTool(prompt)
		if tool then
			shown[prompt] = tool
			token += 1
			equip(tool)
		end
	end)
	PPS.PromptTriggered:Connect(function(prompt, who) -- interaction done: take the old item back
		if who == player and shown[prompt] and grabbed then giveBackLater() end
	end)
	PPS.PromptHidden:Connect(function(prompt)
		if shown[prompt] == nil then return end
		shown[prompt] = nil
		if next(shown) == nil and grabbed then giveBackLater() end
	end)
end

--// ===== AIR STUCK (Premium) =====
-- Freezes you in mid-air (anchors your root part). On phones there is an AIR button on the right.
do
	local airBtn = Instance.new("TextButton")
	airBtn.AnchorPoint = Vector2.new(1, 0)
	airBtn.Size = UDim2.fromOffset(70, 70)
	airBtn.Position = UDim2.new(1, -30, 0, 120)
	airBtn.Text = "AIR"
	airBtn.Font = Enum.Font.GothamBold
	airBtn.TextSize = 18
	airBtn.AutoButtonColor = false
	airBtn.BorderSizePixel = 0
	airBtn.Visible = false
	airBtn.Parent = gui
	Instance.new("UICorner", airBtn).CornerRadius = UDim.new(1, 0)
	themeBind(airBtn, "TextColor3", "onAccent")
	airBtn.Activated:Connect(function()
		if premiumUnlocked then setSetting("AirStuck", not Settings.AirStuck) end
	end)

	local frozen
	local function release(root)
		-- never un-anchor the parked body of FE Invisible / God Mode
		if root.Parent and not (invisReal and root:IsDescendantOf(invisReal)) then root.Anchored = false end
	end

	RunService.Heartbeat:Connect(function()
		local on = premiumUnlocked and Settings.AirStuck
		local root = getRoot()
		if on and root then
			if frozen ~= root then
				if frozen then release(frozen) end
				frozen = root
			end
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			if not root.Anchored then root.Anchored = true end
		elseif frozen then
			release(frozen)
			frozen = nil
		end

		-- phone button: only on touch devices, only after Premium is unlocked
		local show = isTouch and premiumUnlocked
		if airBtn.Visible ~= show then airBtn.Visible = show end
		if show then
			local isOn = Settings.AirStuck and true or false
			airBtn.Text = isOn and "AIR\nON" or "AIR"
			airBtn.BackgroundColor3 = isOn and Color3.fromRGB(40, 170, 80) or THEME.accent
			airBtn.BackgroundTransparency = isOn and 0 or 0.35
		end
	end)
end

--// ===== BEAUTIFUL (Premium): wet, freshly washed world =====
-- Parts get a glossy reflection and a slightly darker color (like wet surfaces), the picture gets
-- a clean, crisp look (color correction, bloom, stronger reflections). Characters keep their skins.
-- Everything is restored when it is off. On very big maps the first pass takes a moment.
do
	local origPart = setmetatable({}, { __mode = "k" }) -- part -> { Reflectance =, Color = }
	local fx, savedSpec, savedDiffuse
	local scanning, scanned = false, false

	local function skip(p)
		if p.Transparency >= 0.95 or p.Material == Enum.Material.Neon or p:IsA("Terrain") then return true end
		local cam = workspace.CurrentCamera
		if cam and p:IsDescendantOf(cam) then return true end -- our own effects
		local m = p:FindFirstAncestorOfClass("Model")
		return m ~= nil and m:FindFirstChildOfClass("Humanoid") ~= nil -- players and NPCs
	end

	local function wet(p)
		local o = origPart[p]
		if not o then
			o = { Reflectance = p.Reflectance, Color = p.Color }
			origPart[p] = o
		end
		p.Reflectance = math.max(o.Reflectance, 0.22)
		p.Color = o.Color:Lerp(Color3.new(0, 0, 0), 0.12)
	end

	local function scan()
		scanning = true
		local n = 0
		for _, d in ipairs(workspace:GetDescendants()) do
			if not (premiumUnlocked and Settings.Beautiful) then break end
			if d:IsA("BasePart") and not skip(d) then wet(d) end
			n += 1
			if n % 400 == 0 then task.wait() end -- do not freeze the game
		end
		scanning = false
		scanned = true
	end

	workspace.DescendantAdded:Connect(function(d)
		if scanned and Settings.Beautiful and d:IsA("BasePart") then
			task.defer(function()
				if d.Parent and not skip(d) then wet(d) end
			end)
		end
	end)

	local function enable()
		fx = {}
		fx.cc = Instance.new("ColorCorrectionEffect")
		fx.cc.Name = "AA_Beautiful_ColorCorrection"
		fx.cc.Saturation = 0.18
		fx.cc.Contrast = 0.1
		fx.cc.Brightness = 0.02
		fx.cc.TintColor = Color3.fromRGB(240, 248, 255)
		fx.cc.Parent = Lighting
		fx.bloom = Instance.new("BloomEffect")
		fx.bloom.Name = "AA_Beautiful_Bloom"
		fx.bloom.Intensity = 0.45
		fx.bloom.Size = 30
		fx.bloom.Threshold = 0.9
		fx.bloom.Parent = Lighting
		pcall(function()
			savedSpec, savedDiffuse = Lighting.EnvironmentSpecularScale, Lighting.EnvironmentDiffuseScale
			Lighting.EnvironmentSpecularScale = 1
		end)
	end

	local function disable()
		if fx then
			fx.cc:Destroy()
			fx.bloom:Destroy()
			fx = nil
		end
		pcall(function()
			if savedSpec then Lighting.EnvironmentSpecularScale = savedSpec end
			if savedDiffuse then Lighting.EnvironmentDiffuseScale = savedDiffuse end
		end)
		savedSpec, savedDiffuse = nil, nil
		for p, o in pairs(origPart) do -- dry again
			if p.Parent then
				p.Reflectance = o.Reflectance
				p.Color = o.Color
			end
			origPart[p] = nil
		end
		scanned = false
	end

	task.spawn(function()
		while true do
			local on = premiumUnlocked and Settings.Beautiful
			if on and not fx then enable() end
			if on and not scanned and not scanning then task.spawn(scan) end
			if not on and fx and not scanning then disable() end
			task.wait(0.3)
		end
	end)
end

--// ===== JUMP CIRCLE =====
-- Every jump opens a glowing animated shape under you (two layers that grow, turn and fade).
-- The shape is drawn with a SurfaceGui on a flat transparent part lying on the ground.
do
	local folder
	local active = {}
	local lastState

	local function buildShape(parent, shape, color)
		if shape == "Triangle" then
			local function bar(x, y, rot) -- one side of an equilateral triangle
				local f = Instance.new("Frame")
				f.AnchorPoint = Vector2.new(0.5, 0.5)
				f.Position = UDim2.fromScale(x, y)
				f.Size = UDim2.new(0.866, 0, 0, 6)
				f.Rotation = rot
				f.BackgroundColor3 = color
				f.BorderSizePixel = 0
				f.Parent = parent
			end
			bar(0.5, 0.75, 0)
			bar(0.2835, 0.375, -60)
			bar(0.7165, 0.375, 60)
		else
			local f = Instance.new("Frame")
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.Position = UDim2.fromScale(0.5, 0.5)
			f.Size = UDim2.fromScale(0.96, 0.96)
			f.BackgroundColor3 = color
			f.BackgroundTransparency = 0.88
			f.BorderSizePixel = 0
			f.Parent = parent
			if shape == "Circle" then Instance.new("UICorner", f).CornerRadius = UDim.new(1, 0) end
			local st = Instance.new("UIStroke", f)
			st.Thickness = 6
			st.Color = color
		end
	end

	local function addLayer(sg, shape, color, delay, finalScale, rot, dur)
		local g = Instance.new("CanvasGroup")
		g.AnchorPoint = Vector2.new(0.5, 0.5)
		g.Position = UDim2.fromScale(0.5, 0.5)
		g.Size = UDim2.fromScale(0.06, 0.06)
		g.BackgroundTransparency = 1
		g.GroupTransparency = 1
		g.Parent = sg
		local holder = Instance.new("Frame")
		holder.AnchorPoint = Vector2.new(0.5, 0.5)
		holder.Position = UDim2.fromScale(0.5, 0.5)
		holder.Size = UDim2.fromScale(0.84, 0.84)
		holder.BackgroundTransparency = 1
		holder.Parent = g
		buildShape(holder, shape, color)
		task.delay(delay, function()
			if not g.Parent then return end
			g.GroupTransparency = 0.05
			TweenService:Create(g, TweenInfo.new(dur, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{ Size = UDim2.fromScale(finalScale, finalScale), Rotation = rot }):Play()
			TweenService:Create(g, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
				{ GroupTransparency = 1 }):Play()
		end)
	end

	local function spawnEffect(root, hum)
		local cam = workspace.CurrentCamera
		if not cam then return end
		if not folder or not folder.Parent then
			folder = Instance.new("Folder")
			folder.Name = "AA_JumpFX"
			folder.Parent = cam
		end

		-- the ground under your feet (in mid-air it opens at the feet)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { player.Character, cam }
		local feet = root.Position - Vector3.new(0, hum.HipHeight + root.Size.Y / 2, 0)
		local hit = workspace:Raycast(feet + Vector3.new(0, 1.5, 0), Vector3.new(0, -8, 0), params)
		local pos, normal = feet, Vector3.yAxis
		if hit then pos, normal = hit.Position, hit.Normal end
		pos = pos + normal * 0.06
		local cf = CFrame.new(pos)
		if normal.Y < 0.99 then -- lie flat on a slope
			local up = (math.abs(normal.X) > 0.9) and Vector3.zAxis or Vector3.xAxis
			cf = CFrame.lookAt(pos, pos + normal, up) * CFrame.Angles(-math.rad(90), 0, 0)
		end

		local part = Instance.new("Part")
		part.Name = "AA_JumpCircle"
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Transparency = 1
		part.Size = Vector3.new(12, 0.05, 12)
		part.CFrame = cf
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Top
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 50
		sg.LightInfluence = 0
		sg.Brightness = 2
		sg.AlwaysOnTop = false
		sg.Parent = part
		part.Parent = folder

		local shape = Settings.JumpCircleShape
		local c1 = THEME.accent
		local c2 = THEME.accent2 or c1:Lerp(Color3.new(1, 1, 1), 0.5)
		local turn = (shape == "Circle") and 0 or 70
		addLayer(sg, shape, c1, 0, 1, turn, 0.9)
		addLayer(sg, shape, c2, 0.12, 0.65, -turn, 0.75)

		table.insert(active, part)
		if #active > 5 then -- never more than 5 at once (infinite jump spam)
			local old = table.remove(active, 1)
			if old then old:Destroy() end
		end
		task.delay(1.3, function()
			if part.Parent then part:Destroy() end
			local i = table.find(active, part)
			if i then table.remove(active, i) end
		end)
	end

	RunService.Heartbeat:Connect(function()
		if not Settings.JumpCircle then
			lastState = nil
			return
		end
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not (hum and root) then return end
		local st = hum:GetState()
		if st == Enum.HumanoidStateType.Jumping and lastState ~= Enum.HumanoidStateType.Jumping then
			spawnEffect(root, hum)
		end
		lastState = st
	end)
end

--// ===== PLAYER TRAIL (Premium): a glowing ribbon behind you =====
do
	local trail, att0, att1, trailRoot

	local function colors()
		if Settings.PlayerTrailStyle == "Rainbow" then
			local keys = {}
			for i = 0, 6 do
				keys[#keys + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 7, 0.85, 1))
			end
			return ColorSequence.new(keys)
		end
		local c = THEME.accent
		return ColorSequence.new(c, THEME.accent2 or c:Lerp(Color3.new(1, 1, 1), 0.5))
	end

	local function destroy()
		if trail then trail:Destroy() end
		if att0 then att0:Destroy() end
		if att1 then att1:Destroy() end
		trail, att0, att1, trailRoot = nil, nil, nil, nil
	end

	local function ensure(root)
		if trail and trail.Parent and trailRoot == root then return end
		destroy()
		att0 = Instance.new("Attachment")
		att0.Name = "AA_TrailTop"
		att0.Position = Vector3.new(0, 1.5, 0)
		att0.Parent = root
		att1 = Instance.new("Attachment")
		att1.Name = "AA_TrailBottom"
		att1.Position = Vector3.new(0, -2.5, 0)
		att1.Parent = root
		trail = Instance.new("Trail")
		trail.Name = "AA_PlayerTrail"
		trail.Attachment0, trail.Attachment1 = att0, att1
		trail.Lifetime = 0.9
		trail.MinLength = 0.05
		trail.LightEmission = 1
		trail.FaceCamera = false
		trail.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
		trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) })
		trail.Color = colors()
		trail.Parent = root
		trailRoot = root
	end

	table.insert(themeHooks, function()
		if trail then trail.Color = colors() end
	end)

	task.spawn(function()
		local lastStyle
		while true do
			if premiumUnlocked and Settings.PlayerTrail then
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root then
					ensure(root)
					if lastStyle ~= Settings.PlayerTrailStyle then
						lastStyle = Settings.PlayerTrailStyle
						trail.Color = colors()
					end
				end
			elseif trail then
				destroy()
			end
			task.wait(0.25)
		end
	end)
end

--// ===== NO RECOIL =====
-- Sets the recoil of your weapons to zero in three places (everything is restored when it is off):
--  1) Number / Int values and attributes whose name contains "recoil" on your tools,
--  2) the tables returned by the ModuleScripts inside your tools (fields with "recoil" in the name),
--  3) weapon config tables found in memory (needs getgc), by common key names.
-- It only works when the game keeps its recoil in data like this. If the recoil is calculated
-- inside the game's own camera script, the Game Report (Misc tab) shows what is there.
do
	local WORD = "recoil"
	local KEYS = {
		"Recoil", "recoil", "RecoilX", "RecoilY", "RecoilAmount", "RecoilPattern", "RecoilMin", "RecoilMax",
		"VerticalRecoil", "HorizontalRecoil", "CameraRecoil", "RecoilStrength", "RecoilPower",
	}
	local saved = {} -- { kind = "value" / "attr" / "key", obj/tbl, name, original }

	local function zeroOf(v)
		local t = typeof(v)
		if t == "number" then return 0 end
		if t == "Vector2" then return Vector2.zero end
		if t == "Vector3" then return Vector3.zero end
		if t == "NumberRange" then return NumberRange.new(0) end
		if t == "table" then
			local copy = {}
			for k, x in pairs(v) do copy[k] = zeroOf(x) end -- recoil patterns: every step becomes zero
			return copy
		end
		return v
	end

	local function zeroKey(tbl, key)
		local ok, cur = pcall(function() return tbl[key] end)
		if not ok or cur == nil then return end
		local t = typeof(cur)
		if t ~= "number" and t ~= "Vector2" and t ~= "Vector3" and t ~= "NumberRange" and t ~= "table" then return end
		if t == "number" and cur == 0 then return end
		if pcall(function() tbl[key] = zeroOf(cur) end) then
			saved[#saved + 1] = { kind = "key", tbl = tbl, name = key, original = cur }
		end
	end

	-- every field with "recoil" in its name, also in tables inside tables (depth is limited)
	local function scanTable(tbl, depth, seen)
		if seen[tbl] or depth > 4 then return end
		seen[tbl] = true
		local keys = {}
		local ok = pcall(function()
			for k in pairs(tbl) do keys[#keys + 1] = k end
		end)
		if not ok then return end
		for _, k in ipairs(keys) do
			if type(k) == "string" and k:lower():find(WORD, 1, true) then
				zeroKey(tbl, k)
			else
				local okv, v = pcall(function() return tbl[k] end)
				if okv and type(v) == "table" then scanTable(v, depth + 1, seen) end
			end
		end
	end

	local function scanTool(tool)
		for _, d in ipairs(tool:GetDescendants()) do
			if (d:IsA("NumberValue") or d:IsA("IntValue")) and d.Name:lower():find(WORD, 1, true) and d.Value ~= 0 then
				saved[#saved + 1] = { kind = "value", obj = d, original = d.Value }
				d.Value = 0
			elseif d:IsA("ModuleScript") then
				local ok, result = pcall(require, d)
				if ok and type(result) == "table" then scanTable(result, 1, {}) end
			end
		end
		for _, inst in ipairs({ tool, table.unpack(tool:GetDescendants()) }) do
			local okA, attrs = pcall(function() return inst:GetAttributes() end)
			if okA then
				for name, v in pairs(attrs) do
					if type(v) == "number" and v ~= 0 and name:lower():find(WORD, 1, true) then
						saved[#saved + 1] = { kind = "attr", obj = inst, name = name, original = v }
						inst:SetAttribute(name, 0)
					end
				end
			end
		end
	end

	local function scanMemory()
		if not getgc then return end
		local ok, all = pcall(getgc, true)
		if not ok then return end
		local n = 0
		for _, t in ipairs(all) do
			if type(t) == "table" then
				for _, key in ipairs(KEYS) do
					local okv, v = pcall(rawget, t, key)
					if okv and v ~= nil then zeroKey(t, key) end
				end
			end
			n += 1
			if n % 3000 == 0 then task.wait() end -- do not freeze the game
		end
	end

	local function restore()
		for i = #saved, 1, -1 do
			local e = saved[i]
			if e.kind == "value" then
				if e.obj.Parent then e.obj.Value = e.original end
			elseif e.kind == "attr" then
				if e.obj.Parent then e.obj:SetAttribute(e.name, e.original) end
			else
				pcall(function() e.tbl[e.name] = e.original end)
			end
			saved[i] = nil
		end
	end

	local function apply()
		restore() -- start clean, so nothing is saved twice
		local tools = {}
		local pack = player:FindFirstChildOfClass("Backpack")
		if pack then for _, t in ipairs(pack:GetChildren()) do tools[#tools + 1] = t end end
		if player.Character then for _, t in ipairs(player.Character:GetChildren()) do tools[#tools + 1] = t end end
		for _, t in ipairs(tools) do
			if t:IsA("Tool") then pcall(scanTool, t) end
		end
		scanMemory()
	end

	task.spawn(function()
		local lastKey, lastAt = nil, 0
		while true do
			if Settings.NoRecoil then
				local char = player.Character
				local tool = char and char:FindFirstChildOfClass("Tool")
				-- again when the weapon in your hand changes, and every 8 seconds for new weapons
				if tool ~= lastKey or os.clock() - lastAt > 8 then
					lastKey, lastAt = tool, os.clock()
					apply()
				end
			elseif #saved > 0 then
				restore()
				lastKey = nil
			end
			task.wait(0.5)
		end
	end)
end

--// ===== AUTO SPRINT =====
-- Holds the sprint key (Left Shift) while you move; does nothing in games without sprint.
do
	local vim
	pcall(function() vim = game:GetService("VirtualInputManager") end)
	local held = false
	local function setShift(down)
		if held == down then return end
		held = down
		if vim then
			pcall(function() vim:SendKeyEvent(down, Enum.KeyCode.LeftShift, false, game) end)
		end
	end
	RunService.Heartbeat:Connect(function()
		if not Settings.AutoSprint then
			setShift(false)
			return
		end
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		setShift(hum ~= nil and hum.Health > 0 and hum.MoveDirection.Magnitude > 0.1)
	end)
end

--// ===== PREMIUM EXTRAS: Spin Bot, Tap Teleport, Gravity, Anti AFK, Auto Clicker =====
do
	-- Spin Bot
	RunService.Heartbeat:Connect(function(dt)
		if not (premiumUnlocked and Settings.SpinBot) then return end
		local root = getRoot()
		if root then
			root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(360 * Settings.SpinSpeed * dt), 0)
		end
	end)

	-- Tap Teleport: tap (phone) or Ctrl + click (PC) on the world
	local pending = {} -- touch input -> { pos =, t = }
	local function teleportTo(screenPos)
		local cam = workspace.CurrentCamera
		local root = getRoot()
		if not (cam and root) then return end
		local ray = cam:ViewportPointToRay(screenPos.X, screenPos.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { player.Character, cam }
		local hit = workspace:Raycast(ray.Origin, ray.Direction * 2000, params)
		if hit then
			root.CFrame = CFrame.new(hit.Position + hit.Normal * 3 + Vector3.new(0, 2, 0)) * root.CFrame.Rotation
			root.AssemblyLinearVelocity = Vector3.zero
		end
	end
	UserInputService.InputBegan:Connect(function(i, processed)
		if processed or not (premiumUnlocked and Settings.TapTeleport) then return end
		if i.UserInputType == Enum.UserInputType.MouseButton1
			and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			teleportTo(UserInputService:GetMouseLocation())
		elseif i.UserInputType == Enum.UserInputType.Touch then
			pending[i] = { pos = Vector2.new(i.Position.X, i.Position.Y), t = os.clock() }
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		local p = pending[i]
		if not p then return end
		pending[i] = nil
		-- a tap: short and without moving (a drag is only the camera turning)
		if premiumUnlocked and Settings.TapTeleport and os.clock() - p.t < 0.25
			and (Vector2.new(i.Position.X, i.Position.Y) - p.pos).Magnitude < 10 then
			teleportTo(p.pos)
		end
	end)

	-- Gravity
	local originalGravity
	RunService.Heartbeat:Connect(function()
		if premiumUnlocked and Settings.GravityMod then
			if not originalGravity then originalGravity = workspace.Gravity end
			if workspace.Gravity ~= Settings.GravityValue then workspace.Gravity = Settings.GravityValue end
		elseif originalGravity then
			workspace.Gravity = originalGravity
			originalGravity = nil
		end
	end)

	-- Anti AFK: answers the idle check of Roblox with a fake click
	player.Idled:Connect(function()
		if not (premiumUnlocked and Settings.AntiAFK) then return end
		pcall(function()
			local vu = game:GetService("VirtualUser")
			vu:CaptureController()
			vu:ClickButton2(Vector2.new())
		end)
	end)

	-- Auto Clicker: clicks in the middle of the screen
	local vim
	pcall(function() vim = game:GetService("VirtualInputManager") end)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		if not (premiumUnlocked and Settings.AutoClicker and vim) then
			acc = 0
			return
		end
		acc += dt
		if acc >= 1 / math.max(Settings.ClickCPS, 1) then
			acc = 0
			local cam = workspace.CurrentCamera
			if cam then
				local c = cam.ViewportSize / 2
				pcall(function()
					vim:SendMouseButtonEvent(c.X, c.Y, 0, true, game, 0)
					vim:SendMouseButtonEvent(c.X, c.Y, 0, false, game, 0)
				end)
			end
		end
	end)
end

--// ===== AUTO EXECUTE (Misc): runs your script again after a teleport =====
-- Needs queue_on_teleport from your executor. Paste your loadstring line or the raw link in the
-- Misc tab; the script cannot know where it was loaded from.
do
	local queue = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
	local function source()
		local src = tostring(Settings.AutoExecuteSource or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if src == "" then return nil end
		if src:match("^https?://") then
			return 'loadstring(game:HttpGet("' .. src .. '"))()'
		end
		return src
	end
	player.OnTeleport:Connect(function()
		if Settings.AutoExecute and queue then
			local src = source()
			if src then pcall(queue, src) end
		end
	end)
end

--// ===== SCREEN (VHS look: red / white) =====
-- Color grading + a little blur, scanlines, a rolling tracking band, random glitch bars, dark
-- corners and a camcorder text (PLAY, date, time, counter) on top of the whole screen.
do
	local LOOKS = {
		["Red VHS"] = {
			tint = Color3.fromRGB(255, 115, 115), sat = -0.15, contrast = 0.3, bright = 0.02,
			line = Color3.fromRGB(45, 0, 0), text = Color3.fromRGB(255, 85, 85),
			band = Color3.fromRGB(255, 150, 150),
			glitch = { Color3.fromRGB(255, 60, 60), Color3.fromRGB(255, 255, 255) },
		},
		["White VHS"] = {
			tint = Color3.fromRGB(235, 235, 245), sat = -1, contrast = 0.35, bright = 0.06,
			line = Color3.fromRGB(10, 10, 14), text = Color3.fromRGB(245, 245, 250),
			band = Color3.new(1, 1, 1),
			glitch = { Color3.new(1, 1, 1), Color3.fromRGB(150, 150, 160) },
		},
	}

	local created, appliedMode = false, nil
	local sg, lines, bandFrame, labels = nil, nil, nil, {}
	local lineFrames, bars, cc, blur = {}, {}, nil, nil
	local startedAt, acc = 0, 0
	local look = LOOKS["Red VHS"]

	local function overlayFrame(parent)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.Active = false
		f.Parent = parent
		return f
	end

	local function build()
		created = true
		sg = Instance.new("ScreenGui")
		sg.Name = "AA_ScreenFX"
		sg.IgnoreGuiInset = true
		sg.ResetOnSpawn = false
		sg.DisplayOrder = 10
		sg.Enabled = false
		sg.Parent = player:WaitForChild("PlayerGui")

		local root = overlayFrame(sg)
		root.Size = UDim2.fromScale(1, 1)
		root.BackgroundTransparency = 1

		-- scanlines
		lines = overlayFrame(root)
		lines.Size = UDim2.fromScale(1, 1)
		lines.BackgroundTransparency = 1
		for i = 0, 139 do
			local f = overlayFrame(lines)
			f.Size = UDim2.new(1, 0, 0, 1)
			f.Position = UDim2.new(0, 0, i / 140, 0)
			f.BackgroundTransparency = 0.78
			lineFrames[#lineFrames + 1] = f
		end

		-- rolling tracking band
		bandFrame = overlayFrame(root)
		bandFrame.Size = UDim2.new(1, 0, 0, 70)
		local g = Instance.new("UIGradient", bandFrame)
		g.Rotation = 90
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.86),
			NumberSequenceKeypoint.new(1, 1),
		})

		-- glitch bars
		for i = 1, 4 do
			local b = overlayFrame(root)
			b.Visible = false
			bars[i] = b
		end

		-- dark corners
		local function vignette(pos, size, rot)
			local f = overlayFrame(root)
			f.Position, f.Size = pos, size
			f.BackgroundColor3 = Color3.new(0, 0, 0)
			local vg = Instance.new("UIGradient", f)
			vg.Rotation = rot
			vg.Transparency = NumberSequence.new(0.35, 1)
		end
		vignette(UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.2), 90)
		vignette(UDim2.fromScale(0, 0.8), UDim2.fromScale(1, 0.2), 270)
		vignette(UDim2.fromScale(0, 0), UDim2.fromScale(0.12, 1), 0)
		vignette(UDim2.fromScale(0.88, 0), UDim2.fromScale(0.12, 1), 180)

		-- camcorder text
		local function label(anchor, pos, align)
			local l = Instance.new("TextLabel")
			l.AnchorPoint = anchor
			l.Position = pos
			l.Size = UDim2.fromOffset(220, 48)
			l.BackgroundTransparency = 1
			l.Font = Enum.Font.Code
			l.TextSize = 20
			l.TextXAlignment = align
			l.TextYAlignment = Enum.TextYAlignment.Bottom
			l.TextStrokeTransparency = 0.4
			l.Active = false
			l.Parent = root
			labels[#labels + 1] = l
			return l
		end
		labels.date = label(Vector2.new(0, 1), UDim2.new(0, 24, 1, -24), Enum.TextXAlignment.Left)
		labels.play = label(Vector2.new(1, 1), UDim2.new(1, -24, 1, -24), Enum.TextXAlignment.Right)

		-- color grading + soft blur in Lighting
		cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "AA_Screen_CC"
		cc.Enabled = false
		cc.Parent = Lighting
		blur = Instance.new("BlurEffect")
		blur.Name = "AA_Screen_Blur"
		blur.Size = 1.5
		blur.Enabled = false
		blur.Parent = Lighting
	end

	local function applyLook(mode)
		appliedMode = mode
		look = LOOKS[mode] or LOOKS["Red VHS"]
		TweenService:Create(cc, TweenInfo.new(0.5), {
			TintColor = look.tint, Saturation = look.sat, Contrast = look.contrast, Brightness = look.bright,
		}):Play()
		for _, f in ipairs(lineFrames) do f.BackgroundColor3 = look.line end
		bandFrame.BackgroundColor3 = look.band
		labels.date.TextColor3 = look.text
		labels.play.TextColor3 = look.text
	end

	RunService.Heartbeat:Connect(function(dt)
		if not Settings.Screen then
			if created and sg.Enabled then
				sg.Enabled = false
				cc.Enabled = false
				blur.Enabled = false
			end
			return
		end
		if not created then build() end
		if not sg.Enabled then
			sg.Enabled = true
			cc.Enabled = true
			blur.Enabled = true
			startedAt = os.clock()
			appliedMode = nil
		end
		if appliedMode ~= Settings.ScreenMode then applyLook(Settings.ScreenMode) end

		local t = os.clock()
		bandFrame.Position = UDim2.new(0, 0, ((t * 0.22) % 1.3) - 0.15, 0) -- band rolls down
		lines.Position = UDim2.fromOffset(0, math.random(-1, 1))           -- picture jitter

		acc += dt
		if acc >= 0.08 then -- glitches and text refresh ~12 times a second
			acc = 0
			for _, b in ipairs(bars) do
				if math.random() < 0.3 then
					b.Visible = true
					b.Position = UDim2.new(math.random() * 0.3, 0, math.random(), 0)
					b.Size = UDim2.new(0.4 + math.random() * 0.6, 0, 0, math.random(2, 10))
					b.BackgroundColor3 = look.glitch[math.random(1, #look.glitch)]
					b.BackgroundTransparency = 0.6 + math.random() * 0.25
				else
					b.Visible = false
				end
			end
			local el = math.floor(t - startedAt)
			labels.date.Text = os.date("%d.%m.%Y") .. "\n" .. os.date("%H:%M:%S")
			labels.play.Text = "PLAY >\n" .. string.format("%02d:%02d:%02d", el // 3600, (el // 60) % 60, el % 60)
		end
	end)
end

local effectApi = {} -- filled by the kill / die effects at the end of the file

--// ===== COSMETICS (tab): wings, caps, shoes, torso, face, back, tail, aura, effects, gun skin =====
-- Every item is described once as a list of simple shapes. The same list is
--   * built as parts on YOUR character (only you see them, they follow your body), and
--   * drawn as flat pictures on the 2D preview on the right of the Cosmetics tab
--     (the preview is your real avatar picture, the items are drawn on top of / behind it).
-- Shape coordinates: x = character's right, y = up, z = back (front is negative), in studs.
do
	local function V(x, y, z) return Vector3.new(x, y, z) end
	local function C(r, g, b) return Color3.fromRGB(r, g, b) end
	local WHITE_C, BLACK_C = Color3.new(1, 1, 1), Color3.new(0, 0, 0)

	-- fills in the defaults of a shape
	local function S(t)
		t.kind = t.kind or "Block" -- Block / Ball / Disc (flat round plate)
		t.pos = t.pos or V(0, 0, 0)
		t.size = t.size or V(1, 1, 1)
		t.rot = t.rot or V(0, 0, 0) -- degrees; the z turn is also used by the 2D picture
		t.mat = t.mat or "SmoothPlastic"
		t.tr = t.tr or 0
		t.pivot = t.pivot or V(0, 0, 0)
		t.flap = t.flap or 0         -- wings: -1 / 1 = flaps around its pivot
		t.sway = t.sway or false     -- tails: swings left and right around its pivot
		return t
	end
	local function join(a, b)
		for _, x in ipairs(b) do a[#a + 1] = x end
		return a
	end

	-- a wing is a fan of long thin panels that start at the shoulder
	local function fanWing(o)
		local list = {}
		local base = V(0.4, 0.6, 0.62 + (o.zoff or 0))
		for _, side in ipairs({ 1, -1 }) do
			local pivot = V(base.X * side, base.Y, base.Z)
			for i = 1, o.n do
				local t = (i - 1) / math.max(o.n - 1, 1)
				local a = math.rad(o.a0 + (o.a1 - o.a0) * t)
				local len, width = o.len(i, t), o.w(i, t)
				local dir = V(side * math.cos(a), math.sin(a), 0)
				list[#list + 1] = S({
					attach = "Torso",
					pos = pivot + dir * (len / 2),
					size = V(len, width, o.thick or 0.05),
					rot = V(0, 0, side == 1 and math.deg(a) or (180 - math.deg(a))),
					color = o.color(i, t),
					mat = o.mat,
					tr = o.tr,
					flap = side,
					pivot = pivot,
					flicker = o.flicker,
				})
			end
		end
		return list
	end

	--// ----- items -----
	local WINGS, CAPS, SHOES, TORSO, FACE = {}, {}, {}, {}, {}

	WINGS["Electric"] = function() -- glowing blue-white lightning rays that flicker
		return fanWing({ n = 9, a0 = 85, a1 = -75, thick = 0.04, mat = "Neon", flicker = true,
			len = function(i, t) return 2.2 + 2.2 * math.abs(math.sin(i * 1.9)) + (1 - t) * 0.6 end,
			w = function() return 0.1 end,
			color = function(i) return (i % 2 == 0) and C(120, 220, 255) or C(255, 255, 255) end })
	end
	WINGS["Dragon"] = function() -- red membrane on dark bones
		local list = fanWing({ n = 7, a0 = 80, a1 = -60, thick = 0.05,
			len = function(i, t) return 4.3 - 1.7 * t end, w = function() return 1.15 end,
			color = function(i, t) return C(160, 22, 32):Lerp(C(70, 8, 14), t) end })
		return join(list, fanWing({ n = 4, a0 = 88, a1 = -45, thick = 0.09, zoff = 0.05,
			len = function(i, t) return 4.7 - 1.9 * t end, w = function() return 0.16 end,
			color = function() return C(38, 12, 14) end }))
	end
	WINGS["Vampire"] = function() -- black bat wings with purple bones
		local lens = { 4.4, 3.3, 3.9, 2.9, 3.3, 2.3 }
		local list = fanWing({ n = 6, a0 = 72, a1 = -72, thick = 0.05,
			len = function(i) return lens[i] end, w = function() return 1.0 end,
			color = function() return C(22, 22, 28) end })
		return join(list, fanWing({ n = 6, a0 = 72, a1 = -72, thick = 0.08, zoff = 0.05,
			len = function(i) return lens[i] + 0.35 end, w = function() return 0.1 end,
			color = function() return C(95, 25, 70) end }))
	end
	WINGS["Cyborg"] = function() -- metal plates with glowing cyan circuits
		local function len(i) return 3.9 - i * 0.35 end
		local list = fanWing({ n = 6, a0 = 75, a1 = -60, thick = 0.07, mat = "Metal", len = len,
			w = function() return 0.62 end,
			color = function(i) return (i % 2 == 0) and C(120, 130, 142) or C(150, 158, 168) end })
		return join(list, fanWing({ n = 6, a0 = 75, a1 = -60, thick = 0.05, zoff = 0.06, mat = "Neon", len = len,
			w = function() return 0.08 end, color = function() return C(60, 230, 255) end }))
	end

	local function cap(color)
		return {
			S({ attach = "Head", pos = V(0, 0.8, 0), size = V(1.34, 0.46, 1.34), color = color, mat = "Fabric" }),
			S({ attach = "Head", kind = "Ball", pos = V(0, 1.04, 0), size = V(0.16, 0.16, 0.16),
				color = color:Lerp(WHITE_C, 0.25) }),
			S({ attach = "Head", pos = V(0, 0.64, -0.95), size = V(1.1, 0.08, 0.7),
				color = color:Lerp(BLACK_C, 0.25), mat = "Fabric" }), -- brim
		}
	end
	CAPS["Cap"] = function() return cap(C(35, 45, 95)) end
	CAPS["Green Cap"] = function() return cap(C(30, 150, 70)) end
	CAPS["Summer Hat"] = function() -- wide straw hat with a red band
		return {
			S({ attach = "Head", kind = "Disc", pos = V(0, 0.62, 0), size = V(2.5, 0.08, 2.5), color = C(228, 200, 120), mat = "Fabric" }),
			S({ attach = "Head", pos = V(0, 0.9, 0), size = V(1.22, 0.5, 1.22), color = C(228, 200, 120), mat = "Fabric" }),
			S({ attach = "Head", pos = V(0, 0.72, 0), size = V(1.27, 0.14, 1.27), color = C(200, 70, 70), mat = "Fabric" }),
		}
	end
	CAPS["Panama"] = function() -- cream Panama with a black band
		return {
			S({ attach = "Head", kind = "Disc", pos = V(0, 0.62, 0), size = V(1.9, 0.07, 1.9), color = C(240, 232, 205), mat = "Fabric" }),
			S({ attach = "Head", pos = V(0, 0.93, 0), size = V(1.15, 0.62, 1.15), color = C(240, 232, 205), mat = "Fabric" }),
			S({ attach = "Head", pos = V(0, 0.72, 0), size = V(1.2, 0.12, 1.2), color = C(30, 30, 32), mat = "Fabric" }),
			S({ attach = "Head", pos = V(0, 1.23, 0), size = V(0.5, 0.06, 0.6), color = C(215, 205, 175), mat = "Fabric" }),
		}
	end

	-- shoes: the origin is the middle of the sole; both feet get the same shapes
	local function sneaker(upper, sole, toe, accent)
		return {
			S({ attach = "Foot", pos = V(0, 0.07, -0.12), size = V(1.12, 0.14, 1.42), color = sole }),
			S({ attach = "Foot", pos = V(0, 0.36, -0.05), size = V(1.0, 0.44, 1.1), color = upper, mat = "Fabric" }),
			S({ attach = "Foot", pos = V(0, 0.24, -0.58), size = V(0.96, 0.24, 0.4), color = toe }),
			S({ attach = "Foot", pos = V(0, 0.4, 0.58), size = V(0.5, 0.18, 0.06), color = accent }),
		}
	end
	SHOES["Canvas Shoes"] = function()
		local list = sneaker(C(35, 55, 125), C(240, 240, 240), C(245, 245, 245), C(200, 40, 50))
		list[#list + 1] = S({ attach = "Foot", pos = V(0, 0.18, -0.12), size = V(1.14, 0.05, 1.44), color = C(200, 40, 50) })
		return list
	end
	SHOES["Adidas"] = function() -- white with three black stripes on each side
		local list = sneaker(C(245, 245, 245), C(255, 255, 255), C(235, 235, 235), C(20, 20, 20))
		for _, sx in ipairs({ -0.52, 0.52 }) do
			for k = -1, 1 do
				list[#list + 1] = S({ attach = "Foot", pos = V(sx, 0.38, -0.1 + k * 0.2), size = V(0.05, 0.36, 0.09),
					rot = V(0, 0, 30), color = C(20, 20, 20) })
			end
		end
		return list
	end
	SHOES["Red Sneakers"] = function()
		local list = sneaker(C(205, 30, 40), C(250, 250, 250), C(250, 250, 250), C(30, 30, 30))
		list[#list + 1] = S({ attach = "Foot", pos = V(0, 0.6, -0.15), size = V(0.6, 0.05, 0.5), color = WHITE_C }) -- laces
		return list
	end
	SHOES["White Sneakers"] = function()
		return sneaker(C(250, 250, 250), C(215, 215, 220), C(240, 240, 244), C(180, 180, 190))
	end
	SHOES["Flip-flops"] = function() -- thin sole, two straps and a toe post
		return {
			S({ attach = "Foot", pos = V(0, 0.05, -0.1), size = V(1.05, 0.1, 1.4), color = C(60, 170, 200) }),
			S({ attach = "Foot", pos = V(0.2, 0.16, -0.12), size = V(0.1, 0.08, 0.75), rot = V(0, 28, 0), color = WHITE_C }),
			S({ attach = "Foot", pos = V(-0.2, 0.16, -0.12), size = V(0.1, 0.08, 0.75), rot = V(0, -28, 0), color = WHITE_C }),
			S({ attach = "Foot", kind = "Ball", pos = V(0, 0.14, -0.45), size = V(0.14, 0.14, 0.14), color = WHITE_C }),
		}
	end

	-- torso: bags on a strap across the chest, bag on the character's left hip
	TORSO["Bag"] = function()
		return {
			S({ attach = "Torso", pos = V(-0.22, 0.28, -0.56), size = V(2.0, 0.14, 0.05), rot = V(0, 0, 41), color = C(90, 60, 35), mat = "Fabric" }),
			S({ attach = "Torso", pos = V(-0.95, -0.6, -0.68), size = V(0.9, 0.7, 0.36), color = C(150, 100, 60), mat = "Leather" }),
			S({ attach = "Torso", pos = V(-0.95, -0.38, -0.68), size = V(0.92, 0.28, 0.4), color = C(120, 80, 45), mat = "Leather" }),
			S({ attach = "Torso", kind = "Ball", pos = V(-0.95, -0.44, -0.9), size = V(0.14, 0.14, 0.14), color = C(230, 190, 60), mat = "Metal" }),
		}
	end
	TORSO["Balenciaga Bag"] = function()
		local list = {
			S({ attach = "Torso", pos = V(-0.22, 0.28, -0.56), size = V(2.0, 0.1, 0.05), rot = V(0, 0, 41), color = C(190, 195, 200), mat = "Metal" }),
			S({ attach = "Torso", pos = V(-0.95, -0.62, -0.7), size = V(1.05, 0.78, 0.42), color = C(22, 22, 25), mat = "Leather", text = "BALENCIAGA" }),
			S({ attach = "Torso", pos = V(-0.95, -0.3, -0.7), size = V(1.07, 0.05, 0.44), color = C(190, 195, 200), mat = "Metal" }),
		}
		for _, sx in ipairs({ -0.4, 0.4 }) do -- gold studs
			for _, sy in ipairs({ -0.9, -0.34 }) do
				list[#list + 1] = S({ attach = "Torso", kind = "Ball", pos = V(-0.95 + sx, sy, -0.93), size = V(0.1, 0.1, 0.1),
					color = C(230, 190, 60), mat = "Metal" })
			end
		end
		return list
	end

	-- face
	local function eyes(color)
		local list = {}
		for _, sx in ipairs({ -0.25, 0.25 }) do
			list[#list + 1] = S({ attach = "Head", pos = V(sx, 0.08, -0.62), size = V(0.24, 0.16, 0.05), color = color, mat = "Neon" })
			list[#list + 1] = S({ attach = "Head", pos = V(sx, 0.08, -0.65), size = V(0.08, 0.12, 0.05), color = BLACK_C })
		end
		return list
	end
	FACE["Glasses"] = function()
		local list = {
			S({ attach = "Head", pos = V(0, 0.25, -0.64), size = V(1.2, 0.06, 0.06), color = C(15, 15, 18) }),
			S({ attach = "Head", pos = V(0, 0.12, -0.65), size = V(0.16, 0.05, 0.05), color = C(15, 15, 18) }),
		}
		for _, sx in ipairs({ -0.3, 0.3 }) do
			list[#list + 1] = S({ attach = "Head", pos = V(sx, 0.08, -0.63), size = V(0.44, 0.3, 0.05), color = C(25, 25, 30), tr = 0.2 })
			list[#list + 1] = S({ attach = "Head", pos = V(sx * 2.1, 0.15, -0.3), size = V(0.05, 0.05, 0.65), color = C(15, 15, 18) })
		end
		return list
	end
	FACE["Red Eyes"] = function() return eyes(C(255, 40, 40)) end
	FACE["Blue Eyes"] = function() return eyes(C(60, 130, 255)) end
	FACE["Green Eyes"] = function() return eyes(C(60, 255, 110)) end


	-- ---------- more headwear ----------
	CAPS["Crown"] = function()
		local gold = C(240, 195, 60)
		local list = {
			S({ attach = "Head", pos = V(0, 0.78, 0), size = V(1.3, 0.3, 1.3), color = gold, mat = "Metal" }),
			S({ attach = "Head", kind = "Ball", pos = V(0, 0.8, -0.66), size = V(0.18, 0.18, 0.18), color = C(255, 50, 70), mat = "Neon" }),
		}
		for _, p in ipairs({ { -0.5, -0.5 }, { 0.5, -0.5 }, { -0.5, 0.5 }, { 0.5, 0.5 }, { 0, 0 } }) do
			list[#list + 1] = S({ attach = "Head", pos = V(p[1], 1.05, p[2]), size = V(0.2, 0.4, 0.2), color = gold, mat = "Metal" })
			list[#list + 1] = S({ attach = "Head", kind = "Ball", pos = V(p[1], 1.28, p[2]), size = V(0.14, 0.14, 0.14), color = gold, mat = "Neon" })
		end
		return list
	end
	CAPS["Halo"] = function() -- a ring of golden light above the head
		local list = {}
		for i = 0, 13 do
			local a = i / 14 * math.pi * 2
			list[#list + 1] = S({ attach = "Head", kind = "Ball", pos = V(math.cos(a) * 0.7, 1.4, math.sin(a) * 0.7),
				size = V(0.16, 0.16, 0.16), color = C(255, 230, 120), mat = "Neon" })
		end
		return list
	end
	CAPS["Devil Horns"] = function()
		local list = {}
		for _, sx in ipairs({ -1, 1 }) do
			list[#list + 1] = S({ attach = "Head", pos = V(sx * 0.42, 0.92, -0.05), size = V(0.2, 0.55, 0.2), rot = V(0, 0, -sx * 20), color = C(190, 20, 30) })
			list[#list + 1] = S({ attach = "Head", pos = V(sx * 0.55, 1.2, -0.05), size = V(0.12, 0.3, 0.12), rot = V(0, 0, -sx * 35), color = C(120, 10, 20) })
		end
		return list
	end
	CAPS["Cat Ears"] = function()
		local list = {}
		for _, sx in ipairs({ -1, 1 }) do
			list[#list + 1] = S({ attach = "Head", pos = V(sx * 0.42, 0.88, 0), size = V(0.42, 0.42, 0.16), rot = V(0, 0, 45), color = C(25, 25, 28) })
			list[#list + 1] = S({ attach = "Head", pos = V(sx * 0.42, 0.88, -0.06), size = V(0.22, 0.22, 0.12), rot = V(0, 0, 45), color = C(255, 140, 180) })
		end
		return list
	end
	CAPS["Headphones"] = function()
		local list = { S({ attach = "Head", pos = V(0, 0.72, 0), size = V(1.45, 0.12, 0.2), color = C(30, 30, 34) }) }
		for _, sx in ipairs({ -0.74, 0.74 }) do
			list[#list + 1] = S({ attach = "Head", pos = V(sx, 0.05, 0), size = V(0.26, 0.6, 0.6), color = C(30, 30, 34) })
			list[#list + 1] = S({ attach = "Head", pos = V(sx * 1.05, 0.05, 0), size = V(0.08, 0.45, 0.45), color = C(220, 40, 60), mat = "Neon" })
			list[#list + 1] = S({ attach = "Head", pos = V(sx * 0.93, 0.4, 0), size = V(0.1, 0.65, 0.18), color = C(30, 30, 34) })
		end
		return list
	end

	-- ---------- more shoes ----------
	SHOES["Boots"] = function()
		return {
			S({ attach = "Foot", pos = V(0, 0.08, -0.1), size = V(1.14, 0.16, 1.4), color = C(25, 25, 28) }),
			S({ attach = "Foot", pos = V(0, 0.6, 0), size = V(1.06, 1.0, 1.1), color = C(35, 30, 28), mat = "Leather" }),
			S({ attach = "Foot", pos = V(0, 1.12, 0), size = V(1.12, 0.14, 1.16), color = C(80, 75, 70), mat = "Leather" }),
			S({ attach = "Foot", pos = V(0, 0.3, -0.55), size = V(0.98, 0.3, 0.4), color = C(45, 40, 38), mat = "Leather" }),
		}
	end
	SHOES["Gold Sneakers"] = function()
		local list = sneaker(C(255, 200, 60), C(255, 235, 150), C(255, 215, 90), C(255, 255, 255))
		for _, sh in ipairs(list) do sh.mat = "Metal" end
		return list
	end

	-- ---------- more for the torso ----------
	TORSO["Gold Chain"] = function()
		local list = {}
		for d = -70, 70, 10 do
			local a = math.rad(d)
			list[#list + 1] = S({ attach = "Torso", kind = "Ball", pos = V(math.sin(a) * 0.75, 0.95 - 0.4 * math.cos(a), -0.58),
				size = V(0.11, 0.11, 0.11), color = C(240, 195, 60), mat = "Metal" })
		end
		list[#list + 1] = S({ attach = "Torso", kind = "Ball", pos = V(0, 0.48, -0.6), size = V(0.26, 0.26, 0.26), color = C(255, 215, 80), mat = "Neon" })
		return list
	end
	TORSO["Scarf"] = function()
		return {
			S({ attach = "Torso", pos = V(0, 0.98, 0), size = V(1.5, 0.3, 1.2), color = C(190, 30, 40), mat = "Fabric" }),
			S({ attach = "Torso", pos = V(0.45, 0.35, -0.62), size = V(0.36, 1.0, 0.1), color = C(190, 30, 40), mat = "Fabric" }),
			S({ attach = "Torso", pos = V(0.45, 0.5, -0.64), size = V(0.38, 0.1, 0.1), color = C(245, 245, 245), mat = "Fabric" }),
			S({ attach = "Torso", pos = V(0.45, 0.2, -0.64), size = V(0.38, 0.1, 0.1), color = C(245, 245, 245), mat = "Fabric" }),
		}
	end

	-- ---------- more for the face ----------
	FACE["Sunglasses"] = function()
		local list = { S({ attach = "Head", pos = V(0, 0.12, -0.66), size = V(1.2, 0.06, 0.06), color = C(10, 10, 12) }) }
		for _, sx in ipairs({ -0.3, 0.3 }) do
			list[#list + 1] = S({ attach = "Head", pos = V(sx, 0.06, -0.64), size = V(0.5, 0.34, 0.05), color = C(8, 8, 10), tr = 0.05 })
			list[#list + 1] = S({ attach = "Head", pos = V(sx * 2.1, 0.12, -0.3), size = V(0.05, 0.05, 0.65), color = C(10, 10, 12) })
		end
		return list
	end
	FACE["Ninja Mask"] = function()
		return {
			S({ attach = "Head", pos = V(0, -0.2, -0.6), size = V(1.3, 0.5, 0.14), color = C(20, 20, 24), mat = "Fabric" }),
			S({ attach = "Head", pos = V(0, 0.3, 0), size = V(1.3, 0.18, 1.3), color = C(200, 30, 40), mat = "Fabric" }),
			S({ attach = "Head", pos = V(0.4, 0.3, 0.75), size = V(0.2, 0.5, 0.08), rot = V(0, 0, 15), color = C(200, 30, 40), mat = "Fabric" }),
		}
	end
	FACE["Pink Eyes"] = function() return eyes(C(255, 100, 200)) end
	FACE["Purple Eyes"] = function() return eyes(C(170, 90, 255)) end
	FACE["Yellow Eyes"] = function() return eyes(C(255, 230, 60)) end

	-- ---------- back: capes and packs ----------
	local BACK, AURA, TAIL = {}, {}, {}
	BACK["Red Cape"] = function()
		return {
			S({ attach = "Torso", pos = V(0, -0.35, 0.62), size = V(1.8, 2.6, 0.06), rot = V(8, 0, 0), color = C(170, 20, 30), mat = "Fabric" }),
			S({ attach = "Torso", pos = V(0, 0.95, 0.55), size = V(1.7, 0.22, 0.22), color = C(110, 10, 20), mat = "Fabric" }),
		}
	end
	BACK["Royal Cape"] = function()
		local gold = C(240, 195, 60)
		local list = {
			S({ attach = "Torso", pos = V(0, -0.35, 0.62), size = V(1.8, 2.6, 0.06), rot = V(8, 0, 0), color = C(80, 30, 130), mat = "Fabric" }),
			S({ attach = "Torso", pos = V(0, -1.62, 0.68), size = V(1.8, 0.12, 0.08), color = gold, mat = "Metal" }),
			S({ attach = "Torso", pos = V(0, 0.95, 0.55), size = V(1.75, 0.3, 0.26), color = C(245, 245, 245), mat = "Fabric" }),
		}
		for _, sx in ipairs({ -0.9, 0.9 }) do
			list[#list + 1] = S({ attach = "Torso", pos = V(sx, -0.35, 0.64), size = V(0.1, 2.6, 0.08), rot = V(8, 0, 0), color = gold, mat = "Metal" })
		end
		return list
	end
	BACK["Backpack"] = function()
		return {
			S({ attach = "Torso", pos = V(0, 0.1, 0.8), size = V(1.2, 1.5, 0.5), color = C(40, 90, 200), mat = "Fabric" }),
			S({ attach = "Torso", pos = V(0, -0.2, 1.1), size = V(0.9, 0.55, 0.15), color = C(25, 60, 150), mat = "Fabric" }),
			S({ attach = "Torso", pos = V(-0.45, 0.65, -0.5), size = V(0.14, 1.1, 0.06), color = C(25, 60, 150), mat = "Fabric" }),
			S({ attach = "Torso", pos = V(0.45, 0.65, -0.5), size = V(0.14, 1.1, 0.06), color = C(25, 60, 150), mat = "Fabric" }),
		}
	end
	BACK["Jetpack"] = function()
		local list = {}
		for _, sx in ipairs({ -0.45, 0.45 }) do
			list[#list + 1] = S({ attach = "Torso", pos = V(sx, 0.05, 0.85), size = V(0.5, 1.4, 0.5), color = C(120, 128, 138), mat = "Metal" })
			list[#list + 1] = S({ attach = "Torso", pos = V(sx, -0.78, 0.85), size = V(0.34, 0.2, 0.34), color = C(255, 140, 40), mat = "Neon" })
			list[#list + 1] = S({ attach = "Torso", kind = "Emitter", pos = V(sx, -0.95, 0.85), size = V(0.3, 0.2, 0.3), color = C(255, 160, 40), tr = 0.5,
				emitter = { colors = { C(255, 240, 150), C(255, 140, 30), C(200, 40, 20) }, rate = 45, life = { 0.3, 0.5 }, speed = { 3, 5 },
					size = 0.45, accel = V(0, -8, 0), light = 1, spread = 12 } })
		end
		return list
	end

	-- ---------- auras: particles around the body ----------
	local function aura(colors, rate, life, speed, size, accel)
		return { S({ attach = "Torso", kind = "Emitter", pos = V(0, 0, 0.1), size = V(2.2, 2.8, 1.6), color = colors[1], tr = 0.65,
			emitter = { colors = colors, rate = rate, life = life, speed = speed, size = size, accel = accel, light = 1 } }) }
	end
	AURA["Fire Aura"] = function() return aura({ C(255, 220, 90), C(255, 110, 20), C(190, 30, 10) }, 45, { 0.7, 1.1 }, { 0.5, 1.5 }, 0.55, V(0, 4, 0)) end
	AURA["Ice Aura"] = function() return aura({ C(255, 255, 255), C(150, 220, 255) }, 28, { 1.2, 1.8 }, { 0.2, 0.8 }, 0.3, V(0, 1, 0)) end
	AURA["Galaxy Aura"] = function() return aura({ C(255, 255, 255), C(170, 120, 255), C(90, 80, 230) }, 32, { 1.2, 2 }, { 0.3, 1 }, 0.28, V(0, 0.4, 0)) end
	AURA["Toxic Aura"] = function() return aura({ C(200, 255, 80), C(90, 220, 40) }, 30, { 1, 1.6 }, { 0.3, 0.9 }, 0.35, V(0, 1.5, 0)) end
	AURA["Golden Aura"] = function() return aura({ C(255, 250, 200), C(255, 205, 70) }, 30, { 1, 1.7 }, { 0.3, 1 }, 0.25, V(0, 1, 0)) end

	-- ---------- tails: a chain of balls that sways ----------
	local function tail(colors, sizes, tip)
		local pts = { V(0, -0.95, 0.75), V(0, -0.9, 1.05), V(0, -0.78, 1.35), V(0, -0.55, 1.6), V(0, -0.25, 1.8), V(0, 0.1, 1.9) }
		local pivot = pts[1]
		local list = {}
		for i, pt in ipairs(pts) do
			local col = (i == #pts and tip) or colors[(i % #colors) + 1]
			list[#list + 1] = S({ attach = "Torso", kind = "Ball", pos = pt, size = V(sizes[i], sizes[i], sizes[i]), color = col,
				mat = "Fabric", sway = true, pivot = pivot })
		end
		return list
	end
	TAIL["Fox Tail"] = function() return tail({ C(235, 120, 30) }, { 0.5, 0.58, 0.64, 0.62, 0.55, 0.45 }, C(250, 250, 250)) end
	TAIL["Devil Tail"] = function() return tail({ C(190, 20, 30) }, { 0.26, 0.24, 0.22, 0.2, 0.2, 0.34 }, C(255, 60, 70)) end
	TAIL["Cat Tail"] = function() return tail({ C(30, 30, 34) }, { 0.3, 0.3, 0.3, 0.3, 0.3, 0.3 }, C(30, 30, 34)) end


	local BOTH_SIDES = { Foot = { "LFoot", "RFoot" }, Hand = { "LHand", "RHand" } }
	local HANDS, PETS = {}, {}
	local function B(attach, x, y, z, sx, sy, sz, color, mat, o) -- a block
		local t = { attach = attach, pos = V(x, y, z), size = V(sx, sy, sz), color = color, mat = mat or "SmoothPlastic" }
		if o then for k, v in pairs(o) do t[k] = v end end
		return S(t)
	end
	local function Bl(attach, x, y, z, d, color, mat, o) -- a ball
		local t = { attach = attach, kind = "Ball", pos = V(x, y, z), size = V(d, d, d), color = color, mat = mat or "SmoothPlastic" }
		if o then for k, v in pairs(o) do t[k] = v end end
		return S(t)
	end
	local function Dc(attach, x, y, z, d, th, color, mat) -- a flat round plate
		return S({ attach = attach, kind = "Disc", pos = V(x, y, z), size = V(d, th, d), color = color, mat = mat or "SmoothPlastic" })
	end
	local function rotz(a) return { rot = V(0, 0, a) } end

	-- ---------- more wings ----------
	WINGS["Angel"] = function()
		local lens = { 3.4, 3.9, 4.3, 4.2, 3.9, 3.5, 3.0, 2.5, 2.0 }
		return fanWing({ n = 9, a0 = 75, a1 = -70, thick = 0.05, mat = "Fabric",
			len = function(i) return lens[i] end, w = function() return 0.62 end,
			color = function(i, t) return C(250, 250, 255):Lerp(C(205, 220, 245), t) end })
	end
	WINGS["Demon"] = function()
		local lens = { 4.2, 3.0, 4.0, 2.8, 3.6, 2.4, 3.0 }
		local list = fanWing({ n = 7, a0 = 78, a1 = -65, thick = 0.05, len = function(i) return lens[i] end,
			w = function() return 0.85 end, color = function(i, t) return C(32, 10, 14):Lerp(C(90, 12, 20), t) end })
		return join(list, fanWing({ n = 7, a0 = 78, a1 = -65, thick = 0.07, zoff = 0.05, mat = "Neon",
			len = function(i) return lens[i] + 0.2 end, w = function() return 0.06 end, color = function() return C(255, 40, 40) end }))
	end
	WINGS["Butterfly"] = function()
		local lens = { 3.8, 4.0, 3.6, 2.6, 2.4, 3.0, 3.2, 2.6 }
		return fanWing({ n = 8, a0 = 75, a1 = -70, thick = 0.04, mat = "Fabric", len = function(i) return lens[i] end,
			w = function() return 0.8 end, color = function(i, t) return C(255, 120, 200):Lerp(C(120, 160, 255), t) end })
	end
	WINGS["Crystal"] = function()
		return fanWing({ n = 7, a0 = 80, a1 = -65, thick = 0.08, mat = "Glass", tr = 0.35,
			len = function(i) return (i % 2 == 0) and 3.0 or 4.2 end, w = function() return 0.4 end,
			color = function(i) return (i % 2 == 0) and C(190, 150, 255) or C(150, 235, 255) end })
	end
	WINGS["Fire"] = function()
		return fanWing({ n = 9, a0 = 85, a1 = -70, thick = 0.05, mat = "Neon", flicker = true,
			len = function(i, t) return 2.4 + 2.0 * math.abs(math.sin(i * 1.7)) + (1 - t) * 0.5 end, w = function() return 0.16 end,
			color = function(i) return (i % 2 == 0) and C(255, 200, 60) or C(255, 90, 20) end })
	end
	WINGS["Ice"] = function()
		return fanWing({ n = 6, a0 = 75, a1 = -60, thick = 0.07, mat = "Ice", len = function(i) return 3.9 - i * 0.3 end,
			w = function() return 0.55 end, color = function(i) return C(190, 235, 255):Lerp(C(255, 255, 255), (i % 2) * 0.4) end })
	end
	WINGS["Rainbow"] = function()
		return fanWing({ n = 7, a0 = 80, a1 = -65, thick = 0.05, mat = "Neon", len = function(i) return 4.2 - 0.3 * i end,
			w = function() return 0.7 end, color = function(i) return Color3.fromHSV((i - 1) / 7, 0.8, 1) end })
	end
	WINGS["Galaxy"] = function()
		local list = fanWing({ n = 8, a0 = 78, a1 = -68, thick = 0.05, mat = "Neon", len = function(i) return 4.0 - 0.18 * i end,
			w = function() return 0.7 end, color = function(i, t) return C(70, 20, 150):Lerp(C(30, 80, 210), t) end })
		return join(list, fanWing({ n = 8, a0 = 78, a1 = -68, thick = 0.06, zoff = 0.05, mat = "Neon", flicker = true,
			len = function(i) return 4.0 - 0.18 * i end, w = function() return 0.05 end, color = function() return C(255, 255, 255) end }))
	end

	-- ---------- more headwear ----------
	CAPS["Beanie"] = function()
		return { B("Head", 0, 0.8, 0, 1.3, 0.4, 1.3, C(180, 40, 60), "Fabric"),
			B("Head", 0, 0.64, 0, 1.36, 0.18, 1.36, C(130, 25, 42), "Fabric"),
			Bl("Head", 0, 1.06, 0, 0.24, C(250, 250, 250), "Fabric") }
	end
	CAPS["Top Hat"] = function()
		return { Dc("Head", 0, 0.62, 0, 1.8, 0.07, C(20, 20, 24), "Fabric"),
			B("Head", 0, 1.12, 0, 1.1, 0.95, 1.1, C(20, 20, 24), "Fabric"),
			B("Head", 0, 0.78, 0, 1.15, 0.14, 1.15, C(190, 30, 40), "Fabric") }
	end
	CAPS["Cowboy Hat"] = function()
		return { Dc("Head", 0, 0.64, 0, 2.5, 0.07, C(125, 82, 45), "Fabric"),
			B("Head", 0, 0.93, 0, 1.15, 0.5, 1.15, C(125, 82, 45), "Fabric"),
			B("Head", 0, 0.74, 0, 1.2, 0.1, 1.2, C(60, 40, 25), "Fabric"),
			B("Head", 0, 1.2, 0, 0.5, 0.06, 0.9, C(105, 68, 38), "Fabric") }
	end
	CAPS["Wizard Hat"] = function()
		local list = { Dc("Head", 0, 0.62, 0, 1.9, 0.07, C(50, 40, 120), "Fabric") }
		local sizes = { 1.0, 0.8, 0.55, 0.3 }
		for i, w in ipairs(sizes) do
			list[#list + 1] = B("Head", 0, 0.82 + (i - 1) * 0.36, 0, w, 0.4, w, C(50, 40, 120):Lerp(C(110, 70, 200), i / 4), "Fabric")
		end
		list[#list + 1] = Bl("Head", 0, 2.2, 0, 0.22, C(255, 220, 90), "Neon")
		return list
	end
	CAPS["Santa Hat"] = function()
		return { B("Head", 0, 0.8, 0, 1.25, 0.4, 1.25, C(200, 30, 40), "Fabric"),
			B("Head", 0, 1.1, 0.05, 0.9, 0.4, 0.9, C(200, 30, 40), "Fabric"),
			B("Head", 0, 1.4, 0.12, 0.55, 0.4, 0.55, C(200, 30, 40), "Fabric"),
			B("Head", 0, 0.66, 0, 1.32, 0.2, 1.32, C(250, 250, 250), "Fabric"),
			Bl("Head", 0, 1.58, 0.28, 0.26, C(250, 250, 250), "Fabric") }
	end
	CAPS["Pirate Hat"] = function()
		return { B("Head", 0, 0.8, 0, 1.9, 0.35, 1.15, C(25, 25, 28), "Fabric"),
			B("Head", 0, 0.62, 0, 1.92, 0.07, 1.17, C(220, 180, 60), "Metal"),
			Bl("Head", 0, 0.82, -0.6, 0.3, C(245, 245, 245), "Fabric"),
			B("Head", 0, 0.82, -0.62, 0.34, 0.06, 0.04, C(25, 25, 28)) }
	end
	CAPS["Viking Helmet"] = function()
		local list = { B("Head", 0, 0.78, 0, 1.36, 0.5, 1.36, C(150, 155, 165), "Metal"),
			B("Head", 0, 0.64, -0.68, 0.18, 0.4, 0.06, C(120, 125, 135), "Metal") }
		for _, sx in ipairs({ -1, 1 }) do
			list[#list + 1] = B("Head", sx * 0.78, 0.95, 0, 0.2, 0.55, 0.2, C(240, 232, 210), "Fabric", rotz(-sx * 28))
			list[#list + 1] = B("Head", sx * 0.95, 1.28, 0, 0.14, 0.3, 0.14, C(240, 232, 210), "Fabric", rotz(-sx * 40))
		end
		return list
	end
	CAPS["Bunny Ears"] = function()
		local list = {}
		for _, sx in ipairs({ -1, 1 }) do
			list[#list + 1] = B("Head", sx * 0.3, 1.4, 0, 0.28, 1.0, 0.12, C(250, 250, 250), "Fabric", rotz(-sx * 8))
			list[#list + 1] = B("Head", sx * 0.3, 1.35, -0.02, 0.14, 0.75, 0.13, C(255, 170, 200), "Fabric", rotz(-sx * 8))
		end
		return list
	end
	CAPS["Flower Crown"] = function()
		local list = {}
		local cols = { C(255, 150, 200), C(255, 230, 90), C(250, 250, 250), C(190, 130, 255) }
		for i = 0, 9 do
			local a = i / 10 * math.pi * 2
			list[#list + 1] = Bl("Head", math.cos(a) * 0.64, 0.7, math.sin(a) * 0.64, 0.24, cols[(i % 4) + 1], "Fabric")
			list[#list + 1] = Bl("Head", math.cos(a + 0.3) * 0.64, 0.68, math.sin(a + 0.3) * 0.64, 0.14, C(70, 160, 80), "Fabric")
		end
		return list
	end
	CAPS["Party Hat"] = function()
		return { B("Head", 0, 0.78, 0, 0.7, 0.3, 0.7, C(255, 100, 180), "Fabric"),
			B("Head", 0, 1.05, 0, 0.5, 0.3, 0.5, C(90, 220, 240), "Fabric"),
			B("Head", 0, 1.32, 0, 0.3, 0.3, 0.3, C(255, 230, 90), "Fabric"),
			Bl("Head", 0, 1.55, 0, 0.16, C(255, 255, 255), "Neon") }
	end
	CAPS["Chef Hat"] = function()
		return { B("Head", 0, 1.1, 0, 1.2, 0.9, 1.2, C(250, 250, 250), "Fabric"),
			B("Head", 0, 0.7, 0, 1.3, 0.25, 1.3, C(240, 240, 240), "Fabric") }
	end

	-- ---------- more shoes ----------
	local function boot(color, sole, height)
		return {
			S({ attach = "Foot", pos = V(0, 0.08, -0.1), size = V(1.14, 0.16, 1.4), color = sole }),
			S({ attach = "Foot", pos = V(0, 0.1 + height / 2, 0), size = V(1.06, height, 1.1), color = color, mat = "Leather" }),
			S({ attach = "Foot", pos = V(0, 0.3, -0.55), size = V(0.98, 0.3, 0.4), color = color:Lerp(WHITE_C, 0.1), mat = "Leather" }),
		}
	end
	SHOES["Rocket Boots"] = function()
		local list = boot(C(120, 128, 140), C(60, 64, 72), 0.95)
		list[#list + 1] = S({ attach = "Foot", pos = V(0, 0.4, 0.58), size = V(0.5, 0.5, 0.08), color = C(255, 120, 40), mat = "Neon" })
		list[#list + 1] = S({ attach = "Foot", kind = "Emitter", pos = V(0, -0.05, 0.1), size = V(0.5, 0.2, 0.5), color = C(255, 160, 40), tr = 0.5,
			emitter = { colors = { C(255, 240, 150), C(255, 120, 30), C(180, 40, 20) }, rate = 40, life = { 0.25, 0.45 }, speed = { 3, 5 },
				size = 0.4, accel = V(0, -8, 0), light = 1, spread = 10 } })
		return list
	end
	SHOES["Cowboy Boots"] = function()
		local list = boot(C(120, 75, 40), C(50, 32, 20), 1.0)
		list[#list + 1] = B("Foot", 0, 0.2, 0.62, 0.14, 0.14, 0.22, C(200, 205, 210), "Metal") -- spur
		return list
	end
	SHOES["Rainbow Sneakers"] = function()
		local list = sneaker(C(255, 80, 120), C(250, 250, 250), C(90, 200, 255), C(255, 230, 80))
		for i, sh in ipairs(list) do sh.mat = "Neon"; sh.color = Color3.fromHSV((i - 1) / 5, 0.8, 1) end
		return list
	end
	SHOES["Neon Sneakers"] = function()
		local list = sneaker(C(60, 255, 120), C(30, 30, 34), C(40, 220, 100), C(255, 255, 255))
		list[2].mat = "Neon"
		list[3].mat = "Neon"
		return list
	end
	SHOES["Ice Skates"] = function()
		local list = boot(C(245, 245, 250), C(60, 60, 68), 0.8)
		list[#list + 1] = B("Foot", 0, -0.05, -0.05, 0.06, 0.1, 1.5, C(210, 220, 230), "Metal")
		return list
	end
	SHOES["Slippers"] = function()
		return { S({ attach = "Foot", pos = V(0, 0.14, -0.05), size = V(1.1, 0.28, 1.35), color = C(255, 170, 205), mat = "Fabric" }),
			S({ attach = "Foot", pos = V(0, 0.32, -0.4), size = V(1.0, 0.3, 0.6), color = C(255, 205, 225), mat = "Fabric" }),
			S({ attach = "Foot", kind = "Ball", pos = V(0, 0.45, -0.5), size = V(0.3, 0.3, 0.3), color = C(250, 250, 250), mat = "Fabric" }) }
	end

	-- ---------- more for the torso ----------
	TORSO["Tie"] = function()
		return { B("Torso", 0, 0.82, -0.55, 0.22, 0.2, 0.1, C(190, 30, 40), "Fabric"),
			B("Torso", 0, 0.2, -0.54, 0.3, 1.1, 0.08, C(190, 30, 40), "Fabric"),
			B("Torso", 0, -0.4, -0.54, 0.34, 0.2, 0.08, C(150, 20, 30), "Fabric") }
	end
	TORSO["Bow Tie"] = function()
		return { B("Torso", -0.22, 0.88, -0.56, 0.36, 0.28, 0.08, C(25, 25, 28), "Fabric", rotz(12)),
			B("Torso", 0.22, 0.88, -0.56, 0.36, 0.28, 0.08, C(25, 25, 28), "Fabric", rotz(-12)),
			Bl("Torso", 0, 0.88, -0.58, 0.16, C(25, 25, 28), "Fabric") }
	end
	TORSO["Medal"] = function()
		return { B("Torso", 0, 0.65, -0.54, 0.18, 0.55, 0.05, C(50, 90, 200), "Fabric"),
			Bl("Torso", 0, 0.3, -0.58, 0.32, C(240, 195, 60), "Metal") }
	end
	TORSO["Armor"] = function()
		local list = { B("Torso", 0, 0.2, -0.58, 1.9, 1.5, 0.18, C(175, 182, 195), "Metal"),
			B("Torso", 0, 0.25, -0.7, 0.5, 0.6, 0.06, C(240, 195, 60), "Metal") }
		for _, sx in ipairs({ -1, 1 }) do
			list[#list + 1] = B("Torso", sx * 1.0, 0.95, 0, 0.7, 0.3, 0.95, C(175, 182, 195), "Metal")
		end
		return list
	end
	TORSO["Sash"] = function()
		return { B("Torso", 0, 0.2, -0.56, 2.3, 0.3, 0.06, C(120, 40, 170), "Fabric", rotz(-35)),
			B("Torso", 0, 0.2, -0.6, 2.3, 0.07, 0.06, C(240, 195, 60), "Metal", rotz(-35)) }
	end
	TORSO["Belt"] = function()
		return { B("Torso", 0, -0.7, 0, 2.05, 0.22, 1.05, C(95, 60, 35), "Leather"),
			B("Torso", 0, -0.7, -0.55, 0.36, 0.28, 0.06, C(240, 195, 60), "Metal") }
	end
	TORSO["Fanny Pack"] = function()
		return { B("Torso", 0, -0.78, -0.62, 0.9, 0.5, 0.35, C(255, 80, 200), "Neon", { tr = 0.1 }),
			B("Torso", 0, -0.7, -0.5, 2.05, 0.14, 1.05, C(30, 30, 34), "Fabric") }
	end

	-- ---------- more for the face ----------
	FACE["Mustache"] = function()
		return { B("Head", -0.25, -0.22, -0.63, 0.5, 0.12, 0.06, C(25, 20, 18), "Fabric", rotz(-12)),
			B("Head", 0.25, -0.22, -0.63, 0.5, 0.12, 0.06, C(25, 20, 18), "Fabric", rotz(12)) }
	end
	FACE["Beard"] = function()
		return { B("Head", 0, -0.45, -0.58, 1.0, 0.55, 0.15, C(90, 60, 40), "Fabric"),
			Bl("Head", 0, -0.7, -0.5, 0.6, C(90, 60, 40), "Fabric") }
	end
	FACE["Clown Nose"] = function()
		return { Bl("Head", 0, -0.05, -0.68, 0.3, C(230, 40, 50)) }
	end
	FACE["Monocle"] = function()
		return { B("Head", 0.3, 0.05, -0.64, 0.42, 0.42, 0.04, C(200, 230, 255), "Glass", { tr = 0.55 }),
			B("Head", 0.3, 0.05, -0.65, 0.48, 0.06, 0.04, C(240, 195, 60), "Metal"),
			B("Head", 0.53, -0.2, -0.6, 0.03, 0.5, 0.03, C(240, 195, 60), "Metal") }
	end
	FACE["Eye Patch"] = function()
		return { B("Head", -0.28, 0.06, -0.64, 0.45, 0.35, 0.05, C(20, 20, 24), "Fabric"),
			B("Head", 0, 0.3, 0, 1.28, 0.08, 1.28, C(20, 20, 24), "Fabric", rotz(8)) }
	end
	FACE["Cat Whiskers"] = function()
		local list = {}
		for _, sx in ipairs({ -1, 1 }) do
			for k = -1, 1 do
				list[#list + 1] = B("Head", sx * 0.55, -0.12 + k * 0.1, -0.62, 0.45, 0.03, 0.03, C(25, 25, 28), "SmoothPlastic", rotz(sx * k * 12))
			end
		end
		list[#list + 1] = Bl("Head", 0, -0.08, -0.66, 0.12, C(255, 140, 170))
		return list
	end
	FACE["Heart Eyes"] = function()
		local list = {}
		for _, sx in ipairs({ -0.25, 0.25 }) do
			list[#list + 1] = Bl("Head", sx - 0.07, 0.14, -0.63, 0.15, C(255, 50, 100), "Neon")
			list[#list + 1] = Bl("Head", sx + 0.07, 0.14, -0.63, 0.15, C(255, 50, 100), "Neon")
			list[#list + 1] = B("Head", sx, 0.05, -0.63, 0.17, 0.17, 0.05, C(255, 50, 100), "Neon", rotz(45))
		end
		return list
	end
	FACE["Cyclops Eye"] = function()
		return { Bl("Head", 0, 0.05, -0.62, 0.55, C(250, 250, 250)),
			Bl("Head", 0, 0.05, -0.78, 0.28, C(255, 60, 60), "Neon"),
			Bl("Head", 0, 0.05, -0.88, 0.13, C(10, 10, 10)) }
	end
	FACE["Odd Eyes"] = function()
		return { B("Head", -0.25, 0.08, -0.62, 0.24, 0.16, 0.05, C(255, 40, 40), "Neon"),
			B("Head", 0.25, 0.08, -0.62, 0.24, 0.16, 0.05, C(60, 130, 255), "Neon"),
			B("Head", -0.25, 0.08, -0.65, 0.08, 0.12, 0.05, C(10, 10, 10)),
			B("Head", 0.25, 0.08, -0.65, 0.08, 0.12, 0.05, C(10, 10, 10)) }
	end
	FACE["Gas Mask"] = function()
		local list = {
			B("Head", 0, -0.08, -0.5, 1.2, 1.1, 0.6, C(40, 46, 40), "Plastic"),
			Bl("Head", -0.28, 0.08, -0.72, 0.42, C(30, 55, 60), "Glass", { tr = 0.2 }),
			Bl("Head", 0.28, 0.08, -0.72, 0.42, C(30, 55, 60), "Glass", { tr = 0.2 }),
			Bl("Head", -0.28, 0.08, -0.74, 0.1, C(130, 220, 230), "Neon"),
			Bl("Head", 0.28, 0.08, -0.74, 0.1, C(130, 220, 230), "Neon"),
			B("Head", 0, -0.42, -0.58, 0.36, 0.3, 0.36, C(55, 60, 55), "Plastic"),
			B("Head", 0, 0.14, 0.32, 1.2, 0.12, 0.12, C(25, 25, 25), "Fabric"),
		}
		for _, sx in ipairs({ -1, 1 }) do
			list[#list + 1] = Bl("Head", sx * 0.62, -0.15, -0.3, 0.32, C(60, 66, 60), "Metal")
		end
		return list
	end

	-- ---------- more for the back ----------
	BACK["Sword"] = function()
		return { B("Torso", 0.1, 0.2, 0.7, 0.16, 2.6, 0.05, C(210, 220, 232), "Metal", rotz(35)),
			B("Torso", -0.85, -0.55, 0.7, 0.7, 0.1, 0.1, C(240, 195, 60), "Metal", rotz(35)),
			B("Torso", -0.95, -0.7, 0.7, 0.14, 0.5, 0.12, C(40, 30, 30), "Fabric", rotz(35)) }
	end
	BACK["Guitar"] = function()
		return { B("Torso", 0, -0.5, 0.75, 0.95, 1.0, 0.25, C(160, 95, 45), "Leather"),
			B("Torso", 0, -0.45, 0.88, 0.3, 0.3, 0.05, C(25, 25, 28)),
			B("Torso", 0, 0.5, 0.75, 0.14, 1.3, 0.12, C(60, 40, 28), "Fabric"),
			B("Torso", 0, 1.25, 0.75, 0.24, 0.3, 0.1, C(40, 28, 20), "Fabric") }
	end
	BACK["Quiver"] = function()
		local list = { B("Torso", 0.2, 0.0, 0.8, 0.45, 1.2, 0.4, C(110, 70, 38), "Leather", rotz(-14)) }
		for k = -1, 1 do
			list[#list + 1] = B("Torso", 0.1 + k * 0.12 + 0.25, 0.9, 0.8, 0.04, 0.8, 0.04, C(190, 150, 100), "Fabric", rotz(-14))
			list[#list + 1] = B("Torso", 0.05 + k * 0.12 + 0.25, 1.28, 0.8, 0.14, 0.2, 0.05, C(220, 50, 50), "Fabric", rotz(-14))
		end
		return list
	end
	BACK["Turtle Shell"] = function()
		local list = { S({ attach = "Torso", kind = "Ball", pos = V(0, 0.1, 0.85), size = V(1.7, 1.9, 0.9), color = C(70, 130, 60), mat = "Fabric" }) }
		for _, p in ipairs({ { 0, 0.4 }, { -0.4, -0.1 }, { 0.4, -0.1 }, { 0, -0.5 } }) do
			list[#list + 1] = S({ attach = "Torso", kind = "Ball", pos = V(p[1], p[2], 1.25), size = V(0.5, 0.5, 0.15), color = C(45, 95, 40), mat = "Fabric" })
		end
		return list
	end
	BACK["Rainbow Cape"] = function()
		local list = {}
		for i = 0, 5 do
			list[#list + 1] = B("Torso", -0.75 + i * 0.3, -0.35, 0.62, 0.3, 2.6, 0.06, Color3.fromHSV(i / 6, 0.8, 1), "Fabric", { rot = V(8, 0, 0) })
		end
		return list
	end

	-- ---------- more tails ----------
	TAIL["Dragon Tail"] = function()
		local list = tail({ C(60, 150, 70) }, { 0.5, 0.46, 0.42, 0.38, 0.32, 0.26 }, C(200, 40, 40))
		for i, sh in ipairs(list) do
			if i % 2 == 0 then sh.color = C(40, 110, 50) end
		end
		return list
	end
	TAIL["Bunny Tail"] = function()
		return { S({ attach = "Torso", kind = "Ball", pos = V(0, -0.8, 0.72), size = V(0.8, 0.8, 0.8), color = C(250, 250, 250), mat = "Fabric",
			sway = true, pivot = V(0, -0.95, 0.75) }) }
	end
	TAIL["Wolf Tail"] = function() return tail({ C(120, 120, 128), C(90, 90, 98) }, { 0.55, 0.65, 0.72, 0.7, 0.6, 0.45 }, C(230, 230, 235)) end
	TAIL["Scorpion Tail"] = function()
		local pts = { V(0, -0.95, 0.75), V(0, -0.7, 1.05), V(0, -0.3, 1.25), V(0, 0.2, 1.3), V(0, 0.65, 1.1), V(0, 0.9, 0.75) }
		local list = {}
		for i, pt in ipairs(pts) do
			list[#list + 1] = S({ attach = "Torso", kind = "Ball", pos = pt, size = V(0.4 - i * 0.02, 0.4 - i * 0.02, 0.4 - i * 0.02),
				color = (i == #pts) and C(220, 40, 40) or C(70, 55, 45), mat = "Metal", sway = true, pivot = pts[1] })
		end
		return list
	end
	TAIL["Rainbow Tail"] = function()
		local list = tail({ C(255, 80, 80) }, { 0.5, 0.5, 0.48, 0.46, 0.4, 0.34 }, C(255, 255, 255))
		for i, sh in ipairs(list) do sh.color = Color3.fromHSV((i - 1) / 6, 0.8, 1); sh.mat = "Neon" end
		return list
	end

	-- ---------- more auras ----------
	AURA["Lightning Aura"] = function() return aura({ C(255, 255, 255), C(130, 220, 255) }, 40, { 0.15, 0.3 }, { 2, 4 }, 0.22, V(0, 0, 0)) end
	AURA["Heart Aura"] = function() return aura({ C(255, 120, 170), C(255, 60, 110) }, 14, { 1.2, 1.8 }, { 0.2, 0.6 }, 0.36, V(0, 1.6, 0)) end
	AURA["Shadow Aura"] = function() return aura({ C(30, 20, 50), C(90, 40, 140) }, 26, { 1, 1.6 }, { 0.3, 0.8 }, 0.7, V(0, 1.2, 0)) end
	AURA["Water Aura"] = function() return aura({ C(220, 245, 255), C(70, 150, 255) }, 24, { 1, 1.6 }, { 0.3, 0.8 }, 0.25, V(0, 1.5, 0)) end
	AURA["Rainbow Aura"] = function()
		return aura({ C(255, 80, 80), C(255, 220, 80), C(80, 255, 120), C(80, 160, 255), C(200, 100, 255) }, 36, { 1, 1.6 }, { 0.3, 0.9 }, 0.3, V(0, 1, 0))
	end
	AURA["Sakura Petals"] = function() return aura({ C(255, 200, 220), C(255, 150, 190) }, 18, { 2, 3 }, { 0.2, 0.6 }, 0.28, V(0.5, -1.4, 0)) end
	AURA["Snow Aura"] = function() return aura({ C(255, 255, 255), C(210, 235, 255) }, 22, { 1.8, 2.6 }, { 0.2, 0.5 }, 0.2, V(0, -1.2, 0)) end
	AURA["Star Aura"] = function() return aura({ C(255, 250, 200), C(255, 215, 80) }, 20, { 0.8, 1.4 }, { 0.4, 1.2 }, 0.3, V(0, 0.6, 0)) end

	-- ---------- hands (both hands get the same shapes; the origin is the middle of the hand) ----------
	HANDS["Boxing Gloves"] = function()
		return { Bl("Hand", 0, -0.12, 0, 1.15, C(210, 30, 40), "Leather"),
			B("Hand", 0, 0.5, 0, 0.8, 0.25, 0.8, C(245, 245, 245), "Fabric") }
	end
	HANDS["Black Gloves"] = function()
		return { B("Hand", 0, 0, 0, 0.98, 0.5, 0.98, C(22, 22, 26), "Leather"),
			B("Hand", 0, 0.34, 0, 1.04, 0.2, 1.04, C(80, 80, 90), "Leather") }
	end
	HANDS["Glow Gloves"] = function()
		return { B("Hand", 0, 0, 0, 0.98, 0.5, 0.98, C(60, 230, 255), "Neon", { tr = 0.15 }),
			B("Hand", 0, 0.34, 0, 1.04, 0.14, 1.04, C(255, 255, 255), "Neon") }
	end
	HANDS["Gold Rings"] = function()
		return { B("Hand", 0, 0.1, 0, 0.72, 0.1, 0.72, C(240, 195, 60), "Metal"),
			Bl("Hand", 0, 0.15, -0.38, 0.16, C(255, 50, 70), "Neon") }
	end
	HANDS["Watch"] = function()
		return { B("Hand", 0, 0.5, 0, 1.06, 0.2, 1.06, C(25, 25, 28), "Leather"),
			B("Hand", 0, 0.62, -0.35, 0.5, 0.1, 0.5, C(60, 230, 255), "Neon") }
	end
	HANDS["Bracelet"] = function()
		local list = {}
		for i = 0, 7 do
			local a = i / 8 * math.pi * 2
			list[#list + 1] = Bl("Hand", math.cos(a) * 0.55, 0.45, math.sin(a) * 0.55, 0.2, Color3.fromHSV(i / 8, 0.6, 1), "Neon")
		end
		return list
	end
	HANDS["Claws"] = function()
		return { B("Hand", -0.25, -0.1, -0.7, 0.08, 0.08, 0.75, C(215, 220, 230), "Metal"),
			B("Hand", 0, -0.1, -0.78, 0.08, 0.08, 0.85, C(215, 220, 230), "Metal"),
			B("Hand", 0.25, -0.1, -0.7, 0.08, 0.08, 0.75, C(215, 220, 230), "Metal") }
	end

	-- ---------- pets: they circle around you ----------
	local function pet(parts, r, speed, h, phase)
		local orbit = { r = r, speed = speed, h = h, bob = 0.3, phase = phase or 0 }
		for _, sh in ipairs(parts) do sh.orbit = orbit end
		return parts
	end
	PETS["Fairy"] = function()
		return pet({ Bl("Torso", 0, 0, 0, 0.35, C(255, 170, 230), "Neon"),
			B("Torso", -0.25, 0.1, 0.1, 0.4, 0.25, 0.03, C(220, 240, 255), "Neon", { tr = 0.3, rot = V(0, 0, 25) }),
			B("Torso", 0.25, 0.1, 0.1, 0.4, 0.25, 0.03, C(220, 240, 255), "Neon", { tr = 0.3, rot = V(0, 0, -25) }),
			S({ attach = "Torso", kind = "Emitter", pos = V(0, 0, 0), size = V(0.3, 0.3, 0.3), color = C(255, 200, 240), tr = 0.6,
				emitter = { colors = { C(255, 255, 255), C(255, 150, 230) }, rate = 14, life = { 0.5, 0.9 }, speed = { 0.1, 0.4 }, size = 0.12, accel = V(0, -0.5, 0), light = 1 } }) },
			2.4, 1.3, 1.6, 0)
	end
	PETS["Ghost Pet"] = function()
		return pet({ Bl("Torso", 0, 0, 0, 0.75, C(245, 248, 255), "Neon", { tr = 0.2 }),
			Bl("Torso", 0, -0.3, 0, 0.45, C(245, 248, 255), "Neon", { tr = 0.3 }),
			Bl("Torso", -0.15, 0.08, -0.34, 0.1, C(10, 10, 14)),
			Bl("Torso", 0.15, 0.08, -0.34, 0.1, C(10, 10, 14)) }, 2.6, 0.9, 1.4, 1)
	end
	PETS["Drone"] = function()
		local parts = { B("Torso", 0, 0, 0, 0.6, 0.2, 0.6, C(60, 64, 72), "Metal"),
			Bl("Torso", 0, -0.02, -0.32, 0.15, C(60, 200, 255), "Neon") }
		for _, p in ipairs({ { -0.4, -0.4 }, { 0.4, -0.4 }, { -0.4, 0.4 }, { 0.4, 0.4 } }) do
			parts[#parts + 1] = B("Torso", p[1], 0.14, p[2], 0.34, 0.03, 0.06, C(200, 205, 215), "Metal")
		end
		return pet(parts, 2.5, 1.6, 1.8, 2)
	end
	PETS["Fire Spirit"] = function()
		return pet({ Bl("Torso", 0, 0, 0, 0.5, C(255, 150, 40), "Neon"),
			S({ attach = "Torso", kind = "Emitter", pos = V(0, 0, 0), size = V(0.4, 0.4, 0.4), color = C(255, 140, 40), tr = 0.6,
				emitter = { colors = { C(255, 230, 120), C(255, 100, 20), C(160, 30, 10) }, rate = 30, life = { 0.4, 0.7 }, speed = { 0.2, 0.6 }, size = 0.35, accel = V(0, 2.5, 0), light = 1 } }) },
			2.3, 1.4, 1.5, 3)
	end
	PETS["Moon Buddy"] = function()
		return pet({ Bl("Torso", 0, 0, 0, 0.75, C(205, 205, 212)),
			Bl("Torso", 0.15, 0.1, -0.3, 0.16, C(160, 160, 170)),
			Bl("Torso", -0.2, -0.1, -0.28, 0.12, C(160, 160, 170)),
			Bl("Torso", 0.1, -0.22, -0.3, 0.1, C(160, 160, 170)) }, 2.7, 0.7, 1.7, 4)
	end
	PETS["Mini Earth"] = function()
		return pet({ Bl("Torso", 0, 0, 0, 0.75, C(40, 100, 210)),
			Bl("Torso", 0.2, 0.15, -0.25, 0.25, C(70, 170, 80)),
			Bl("Torso", -0.25, -0.1, -0.22, 0.22, C(70, 170, 80)) }, 2.5, 1.0, 1.5, 5)
	end


	-- ---------- 20 more cosmetics ----------
	WINGS["Phoenix"] = function()
		local list = fanWing({ n = 8, a0 = 80, a1 = -65, thick = 0.05, mat = "Neon", flicker = true,
			len = function(i, t) return 3.6 + 1.6 * math.abs(math.sin(i * 1.5)) + (1 - t) * 0.5 end, w = function() return 0.4 end,
			color = function(i) return (i % 2 == 0) and C(255, 190, 60) or C(255, 80, 20) end })
		return join(list, fanWing({ n = 8, a0 = 80, a1 = -65, thick = 0.07, zoff = 0.05,
			len = function(i, t) return 3.6 + 1.6 * math.abs(math.sin(i * 1.5)) + (1 - t) * 0.5 end, w = function() return 0.08 end,
			color = function() return C(140, 20, 10) end }))
	end
	WINGS["Shadow"] = function()
		local list = fanWing({ n = 7, a0 = 78, a1 = -62, thick = 0.06, mat = "SmoothPlastic",
			len = function(i) return 4.0 - 0.2 * i end, w = function() return 0.7 end,
			color = function(i) return C(18, 14, 24):Lerp(C(45, 30, 60), (i % 2)) end })
		return join(list, fanWing({ n = 7, a0 = 78, a1 = -62, thick = 0.05, zoff = 0.04, mat = "Neon",
			len = function(i) return 4.0 - 0.2 * i end, w = function() return 0.04 end, color = function() return C(150, 90, 255) end }))
	end

	CAPS["Astronaut Helmet"] = function()
		return { Bl("Head", 0, 0.45, 0, 1.5, C(235, 238, 242), "SmoothPlastic"),
			Bl("Head", 0, 0.4, -0.55, 0.9, C(60, 90, 120), "Glass", { tr = 0.25 }),
			B("Head", 0, 0.1, 0.5, 0.9, 0.5, 0.5, C(215, 218, 222), "SmoothPlastic"),
			Bl("Head", 0.55, 0.2, 0.3, 0.26, C(220, 40, 40), "Neon") }
	end
	CAPS["Jester Hat"] = function()
		local list = {}
		local cols = { C(220, 40, 60), C(60, 90, 220), C(240, 210, 60) }
		for i, dx in ipairs({ -0.55, 0, 0.55 }) do
			list[#list + 1] = B("Head", dx, 0.75 + math.abs(dx) * 0.2, 0, 0.5, 0.9, 0.5, cols[i], "Fabric")
			list[#list + 1] = Bl("Head", dx, 1.3 + math.abs(dx) * 0.2, 0, 0.2, cols[(i % 3) + 1], "Fabric")
		end
		return list
	end

	SHOES["Astronaut Boots"] = function()
		local list = boot(C(230, 232, 236), C(60, 60, 66), 1.0)
		list[#list + 1] = B("Foot", 0, 0.5, -0.1, 1.1, 0.14, 0.9, C(200, 60, 40), "SmoothPlastic")
		return list
	end
	SHOES["Lava Boots"] = function()
		local list = boot(C(40, 30, 28), C(255, 120, 30), 0.95)
		list[2].mat = "CrackedLava"
		list[3].mat = "Neon"
		list[3].color = C(255, 140, 30)
		return list
	end

	TORSO["Hoodie"] = function()
		return { B("Torso", 0, 0.1, 0, 2.0, 1.7, 1.0, C(60, 64, 72), "Fabric"),
			B("Torso", 0, 1.0, -0.3, 0.9, 0.5, 0.9, C(55, 58, 66), "Fabric"),
			B("Torso", 0, 0.75, -0.6, 0.3, 0.1, 0.06, C(220, 220, 225), "Fabric") }
	end
	TORSO["Lab Coat"] = function()
		return { B("Torso", 0, -0.1, 0, 2.0, 2.1, 1.0, C(248, 248, 250), "Fabric"),
			B("Torso", 0, 0.2, -0.56, 0.22, 1.2, 0.05, C(230, 230, 232), "Fabric"),
			Bl("Torso", -0.25, 0.1, -0.6, 0.1, C(40, 90, 200), "Metal") }
	end

	FACE["Welding Mask"] = function()
		return { B("Head", 0, 0.05, -0.55, 1.2, 1.1, 0.4, C(35, 38, 35), "Plastic"),
			B("Head", 0, 0.1, -0.76, 0.75, 0.35, 0.05, C(20, 120, 90), "Glass", { tr = 0.1 }) }
	end
	FACE["Bandana Mask"] = function()
		return { B("Head", 0, -0.3, -0.56, 1.25, 0.6, 0.12, C(40, 60, 140), "Fabric"),
			B("Head", 0, 0.3, 0.45, 1.3, 0.2, 1.3, C(40, 60, 140), "Fabric", rotz(6)) }
	end

	BACK["Shield"] = function()
		return { Bl("Torso", 0, -0.1, 0.78, 1.5, C(140, 20, 30), "Metal"),
			Bl("Torso", 0, -0.1, 0.84, 0.95, C(230, 230, 235), "Metal"),
			Bl("Torso", 0, -0.1, 0.9, 0.3, C(240, 195, 60), "Metal") }
	end
	BACK["Umbrella"] = function()
		return { B("Torso", 0.1, 0.9, 0.6, 0.1, 1.0, 0.1, C(40, 30, 28), "SmoothPlastic", rotz(15)),
			Bl("Torso", 0.35, 1.5, 0.7, 1.1, C(190, 30, 40), "Fabric") }
	end

	AURA["Cosmic Aura"] = function() return aura({ C(40, 20, 90), C(170, 110, 255), C(70, 180, 255) }, 30, { 1.2, 2 }, { 0.2, 0.8 }, 0.3, V(0, 0.6, 0)) end
	AURA["Royal Aura"] = function() return aura({ C(240, 195, 60), C(110, 30, 180) }, 24, { 1.2, 1.8 }, { 0.2, 0.7 }, 0.3, V(0, 1, 0)) end

	TAIL["Mermaid Tail"] = function()
		local list = tail({ C(30, 150, 170) }, { 0.6, 0.66, 0.6, 0.5, 0.36, 0.5 }, C(60, 200, 210))
		for i, sh in ipairs(list) do sh.mat = "Neon"; if i == #list then sh.size = sh.size * V(2.4, 0.5, 1) end end
		return list
	end
	TAIL["Peacock Tail"] = function()
		local list = tail({ C(20, 90, 110), C(20, 140, 150) }, { 0.4, 0.45, 0.5, 0.55, 0.6, 0.65 }, C(30, 170, 160))
		for _, sh in ipairs(list) do sh.mat = "Neon" end
		return list
	end

	HANDS["Ninja Wraps"] = function()
		return { B("Hand", 0, 0, 0, 0.95, 0.5, 0.95, C(40, 40, 46), "Fabric"),
			B("Hand", 0, 0.3, 0, 1.0, 0.1, 1.0, C(220, 220, 225), "Fabric") }
	end
	HANDS["Energy Gauntlets"] = function()
		return { B("Hand", 0, 0, 0, 1.0, 0.55, 1.0, C(50, 55, 64), "Metal"),
			B("Hand", 0, 0.32, 0, 1.05, 0.14, 1.05, C(60, 220, 255), "Neon"),
			Bl("Hand", 0, 0, -0.48, 0.14, C(60, 220, 255), "Neon") }
	end

	PETS["Baby Dragon"] = function()
		return pet({ Bl("Torso", 0, 0, 0, 0.6, C(60, 160, 70)),
			Bl("Torso", 0, 0.15, -0.42, 0.3, C(60, 160, 70)),
			Bl("Torso", -0.1, 0.22, -0.55, 0.08, C(255, 210, 60), "Neon"),
			Bl("Torso", 0.1, 0.22, -0.55, 0.08, C(255, 210, 60), "Neon") }, 2.4, 1.1, 1.6, 6)
	end
	PETS["Robot Dog"] = function()
		local parts = { B("Torso", 0, 0, 0, 0.75, 0.4, 0.95, C(170, 175, 185), "Metal"),
			B("Torso", 0, 0.12, -0.5, 0.35, 0.3, 0.25, C(150, 155, 165), "Metal"),
			Bl("Torso", 0, 0.14, -0.63, 0.08, C(60, 220, 255), "Neon") }
		for _, sx in ipairs({ -0.3, 0.3 }) do
			parts[#parts + 1] = B("Torso", sx, -0.3, 0.3, 0.12, 0.35, 0.12, C(120, 124, 132), "Metal")
			parts[#parts + 1] = B("Torso", sx, -0.3, -0.3, 0.12, 0.35, 0.12, C(120, 124, 132), "Metal")
		end
		return pet(parts, 2.3, 1.5, 1.3, 7)
	end

	local DEFS = { Wings = WINGS, Caps = CAPS, Shoes = SHOES, Torso = TORSO, Face = FACE, Back = BACK, Aura = AURA,
		Tail = TAIL, Hands = HANDS, Pet = PETS }
	local CATS = {
		{ cat = "Wings", key = "CosWings" }, { cat = "Caps", key = "CosCap" }, { cat = "Shoes", key = "CosShoes" },
		{ cat = "Torso", key = "CosTorso" }, { cat = "Face", key = "CosFace" },
		{ cat = "Back", key = "CosBack" }, { cat = "Aura", key = "CosAura" }, { cat = "Tail", key = "CosTail" },
		{ cat = "Hands", key = "CosHands" }, { cat = "Pet", key = "CosPet" },
	}

	--// ----- the tab -----
	local cols = newPage("Cosmetics")
	local c = newCard(cols[1], "Wings")
	makeDropdown(c, "Style", "CosWings", { "None", "Electric", "Dragon", "Vampire", "Cyborg", "Angel", "Demon",
		"Butterfly", "Crystal", "Fire", "Ice", "Rainbow", "Galaxy", "Phoenix", "Shadow" })
	c = newCard(cols[1], "Headwear")
	makeDropdown(c, "Style", "CosCap", { "None", "Cap", "Green Cap", "Summer Hat", "Panama", "Crown", "Halo",
		"Devil Horns", "Cat Ears", "Headphones", "Beanie", "Top Hat", "Cowboy Hat", "Wizard Hat", "Santa Hat",
		"Pirate Hat", "Viking Helmet", "Bunny Ears", "Flower Crown", "Party Hat", "Chef Hat", "Astronaut Helmet", "Jester Hat" })
	c = newCard(cols[1], "Shoes")
	makeDropdown(c, "Style", "CosShoes", { "None", "Canvas Shoes", "Adidas", "Red Sneakers", "White Sneakers",
		"Flip-flops", "Boots", "Gold Sneakers", "Rocket Boots", "Cowboy Boots", "Rainbow Sneakers", "Neon Sneakers",
		"Ice Skates", "Slippers", "Astronaut Boots", "Lava Boots" })
	c = newCard(cols[1], "Back")
	makeDropdown(c, "Style", "CosBack", { "None", "Red Cape", "Royal Cape", "Backpack", "Jetpack", "Sword", "Guitar",
		"Quiver", "Turtle Shell", "Rainbow Cape", "Shield", "Umbrella" })
	c = newCard(cols[2], "Torso")
	makeDropdown(c, "Style", "CosTorso", { "None", "Bag", "Balenciaga Bag", "Gold Chain", "Scarf", "Tie", "Bow Tie",
		"Medal", "Armor", "Sash", "Belt", "Fanny Pack", "Hoodie", "Lab Coat" })
	c = newCard(cols[2], "Face")
	makeDropdown(c, "Style", "CosFace", { "None", "Glasses", "Sunglasses", "Ninja Mask", "Gas Mask", "Red Eyes", "Blue Eyes",
		"Green Eyes", "Pink Eyes", "Purple Eyes", "Yellow Eyes", "Mustache", "Beard", "Clown Nose", "Monocle",
		"Eye Patch", "Cat Whiskers", "Heart Eyes", "Cyclops Eye", "Odd Eyes", "Welding Mask", "Bandana Mask" })
	c = newCard(cols[2], "Hands")
	makeDropdown(c, "Style", "CosHands", { "None", "Boxing Gloves", "Black Gloves", "Glow Gloves", "Gold Rings",
		"Watch", "Bracelet", "Claws", "Ninja Wraps", "Energy Gauntlets" })
	c = newCard(cols[2], "Tail")
	makeDropdown(c, "Style", "CosTail", { "None", "Fox Tail", "Devil Tail", "Cat Tail", "Dragon Tail", "Bunny Tail",
		"Wolf Tail", "Scorpion Tail", "Rainbow Tail", "Mermaid Tail", "Peacock Tail" })
	c = newCard(cols[2], "Aura")
	makeDropdown(c, "Style", "CosAura", { "None", "Fire Aura", "Ice Aura", "Galaxy Aura", "Toxic Aura", "Golden Aura",
		"Lightning Aura", "Heart Aura", "Shadow Aura", "Water Aura", "Rainbow Aura", "Sakura Petals", "Snow Aura",
		"Star Aura", "Cosmic Aura", "Royal Aura" })
	c = newCard(cols[2], "Pet")
	makeDropdown(c, "Style", "CosPet", { "None", "Fairy", "Ghost Pet", "Drone", "Fire Spirit", "Moon Buddy", "Mini Earth", "Baby Dragon", "Robot Dog" })
	c = newCard(cols[2], "Cosmetics")
	makeNote(c, "What you pick is drawn on the preview (right) and put on your character. Only you can see it on your character.")
	local clearBtn = makeAction(c, "Remove all")
	clearBtn.Activated:Connect(function()
		for _, e in ipairs(CATS) do setSetting(e.key, "None") end
		setSetting("CosGunSkin", "None")
		setSetting("KillEffect", "None")
		setSetting("DieEffect", "None")
	end)

	--// ----- 2D preview -----
	local previewCard = newCard(cols[3], "Preview")
	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1, 0, 0, 190)
	holder.BackgroundTransparency = 1
	place(previewCard, holder)
	local square = Instance.new("Frame") -- a square that fits into the holder
	square.AnchorPoint = Vector2.new(0.5, 0.5)
	square.Position = UDim2.fromScale(0.5, 0.5)
	square.Size = UDim2.fromScale(1, 1)
	square.BackgroundTransparency = 1
	square.Parent = holder
	do
		local ar = Instance.new("UIAspectRatioConstraint", square)
		ar.AspectRatio = 1
		ar.AspectType = Enum.AspectType.FitWithinMaxSize
	end

	-- how the avatar picture maps to studs: tune these two if the items sit a bit off
	local IMG_STUDS = 6.2     -- the picture shows about this many studs of height
	local IMG_CENTER_Y = -0.35 -- the stud height shown in the middle of the picture
	local K = 1 / IMG_STUDS
	local function to2D(x3, y3) -- front view: the character's right is on the viewer's left
		return UDim2.fromScale(0.5 - x3 * K, 0.5 - (y3 - IMG_CENTER_Y) * K)
	end

	local avatarImg = Instance.new("ImageLabel")
	avatarImg.Size = UDim2.fromScale(1, 1)
	avatarImg.BackgroundTransparency = 1
	avatarImg.ZIndex = 2
	avatarImg.Parent = square

	-- plain figure in the colors of your character, used when the avatar picture cannot be loaded
	local function drawFallback()
		local char = player.Character
		local bc = char and char:FindFirstChildOfClass("BodyColors")
		local skin = bc and bc.HeadColor3 or C(253, 234, 141)
		local function blk(x, y, w, h, color)
			local f = Instance.new("Frame")
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.Position = to2D(x, y)
			f.Size = UDim2.fromScale(w * K, h * K)
			f.BackgroundColor3 = color
			f.BorderSizePixel = 0
			f.ZIndex = 2
			f.Parent = square
		end
		blk(0, -2, 1, 2, bc and bc.RightLegColor3 or C(40, 127, 71))
		blk(-0.5, -2, 1, 2, bc and bc.LeftLegColor3 or C(40, 127, 71))
		blk(0, 0, 2, 2, bc and bc.TorsoColor3 or C(13, 105, 172))
		blk(-1.5, 0, 1, 2, bc and bc.RightArmColor3 or skin)
		blk(1.5, 0, 1, 2, bc and bc.LeftArmColor3 or skin)
		blk(0, 1.6, 1.2, 1.2, skin)
	end
	task.spawn(function()
		local ok, img = pcall(Players.GetUserThumbnailAsync, Players, player.UserId,
			Enum.ThumbnailType.AvatarThumbnail, Enum.ThumbnailSize.Size420x420)
		if ok and img and img ~= "" then avatarImg.Image = img else drawFallback() end
	end)

	local ORIGIN2D = { Head = V(0, 1.6, 0), Torso = V(0, 0, 0), LFoot = V(-0.5, -3, 0), RFoot = V(0.5, -3, 0),
		LHand = V(-1.5, -1, 0), RHand = V(1.5, -1, 0) }
	local frames2D = {}
	local function build2D(cat, name)
		for _, f in ipairs(frames2D[cat] or {}) do f:Destroy() end
		frames2D[cat] = {}
		local def = DEFS[cat][name]
		if not def then return end
		for _, shape in ipairs(def()) do
			local attaches = BOTH_SIDES[shape.attach] or { shape.attach }
			for _, a in ipairs(attaches) do
				local o = ORIGIN2D[a]
				local base = V(0, 0, 0) -- pets circle the body: the picture shows them at one spot
				if shape.orbit then
					local a0 = -math.pi / 3
					base = V(math.cos(a0) * shape.orbit.r, shape.orbit.h, math.sin(a0) * shape.orbit.r)
				end
				local x3, y3, z3 = o.X + shape.pos.X + base.X, o.Y + shape.pos.Y + base.Y, o.Z + shape.pos.Z + base.Z
				local w, h = shape.size.X, shape.size.Y
				if shape.kind == "Ball" then h = w end
				if shape.kind == "Disc" then h = math.max(shape.size.Y, w * 0.2) end -- a plate seen from the side
				local fr = Instance.new("Frame")
				fr.AnchorPoint = Vector2.new(0.5, 0.5)
				fr.Position = to2D(x3, y3)
				fr.Size = UDim2.fromScale(w * K, h * K)
				fr.Rotation = shape.rot.Z
				fr.BackgroundColor3 = shape.color
				fr.BackgroundTransparency = shape.tr
				fr.BorderSizePixel = 0
				fr.ZIndex = (z3 > 0.05) and 1 or 3 -- things on the back are behind the avatar
				Instance.new("UISizeConstraint", fr).MinSize = Vector2.new(2, 2)
				if shape.kind ~= "Block" then Instance.new("UICorner", fr).CornerRadius = UDim.new(1, 0) end
				if shape.text then
					local tl = Instance.new("TextLabel")
					tl.Size = UDim2.fromScale(1, 1)
					tl.BackgroundTransparency = 1
					tl.Font = Enum.Font.GothamBold
					tl.TextScaled = true
					tl.TextColor3 = WHITE_C
					tl.Text = shape.text
					tl.Parent = fr
				end
				fr.Parent = square
				frames2D[cat][#frames2D[cat] + 1] = fr
			end
		end
	end

	-- effects and weapon skin (their engines are at the end of the file)
	c = newCard(cols[3], "Kill effect")
	makeNote(c, "Appears where a player dies after you killed him.")
	makeDropdown(c, "Effect", "KillEffect", { "None", "Black Hole", "Earth", "Sky Pillar", "Fireworks" })
	local testKill = makeAction(c, "Test it")
	testKill.Activated:Connect(function() if effectApi.test then effectApi.test(Settings.KillEffect) end end)
	c = newCard(cols[3], "Die effect")
	makeNote(c, "Appears where you die.")
	makeDropdown(c, "Effect", "DieEffect", { "None", "Black Hole", "Earth", "Sky Pillar", "Fireworks" })
	local testDie = makeAction(c, "Test it")
	testDie.Activated:Connect(function() if effectApi.test then effectApi.test(Settings.DieEffect) end end)
	c = newCard(cols[3], "Gun skin")
	makeNote(c, "A skin on the weapon in your hands (tools and first-person weapons).")
	makeDropdown(c, "Skin", "CosGunSkin", { "None", "Galaxy", "Black Hole", "Water", "Lava", "Ice", "Gold",
		"Diamond", "Rainbow", "Matrix", "Toxic" })

	--// ----- the items on your character -----
	local folder
	local inst3D = {}  -- category -> list of { part =, shape =, attach =, f = }
	local applied = {} -- category -> item built right now
	local builtChar

	-- the point of the body an item hangs on, and a scale for the body size
	local function getAttach(char, name)
		if name == "Head" then
			local h = char:FindFirstChild("Head")
			if h then return h.CFrame, math.max(h.Size.Y, 0.3) end
		elseif name == "Torso" then
			local ut = char:FindFirstChild("UpperTorso") -- R15: the middle of the whole torso
			if ut then
				local f = ut.Size.Y / 1.6
				return ut.CFrame * CFrame.new(0, -0.2 * f, 0), f
			end
			local t = char:FindFirstChild("Torso") -- R6
			if t then return t.CFrame, t.Size.Y / 2 end
		elseif name == "LFoot" or name == "RFoot" then
			local ft = char:FindFirstChild(name == "LFoot" and "LeftFoot" or "RightFoot")
				or char:FindFirstChild(name == "LFoot" and "Left Leg" or "Right Leg")
			if ft then return ft.CFrame * CFrame.new(0, -ft.Size.Y / 2, 0), math.max(ft.Size.X, 0.5) end
		elseif name == "LHand" or name == "RHand" then
			local hd = char:FindFirstChild(name == "LHand" and "LeftHand" or "RightHand") -- R15
			if hd then return hd.CFrame, math.max(hd.Size.X, 0.4) end
			local arm = char:FindFirstChild(name == "LHand" and "Left Arm" or "Right Arm") -- R6: the end of the arm
			if arm then return arm.CFrame * CFrame.new(0, -arm.Size.Y / 2 + 0.3, 0), 1 end
		end
		return nil
	end

	-- particles for aura / jetpack items
	local function buildEmitter(part, cfg)
		local e = Instance.new("ParticleEmitter")
		local keys = {}
		local colors = cfg.colors
		if #colors == 1 then colors = { colors[1], colors[1] } end
		for i, col in ipairs(colors) do
			keys[#keys + 1] = ColorSequenceKeypoint.new((i - 1) / (#colors - 1), col)
		end
		e.Color = ColorSequence.new(keys)
		e.Rate = cfg.rate
		e.Lifetime = NumberRange.new(cfg.life[1], cfg.life[2])
		e.Speed = NumberRange.new(cfg.speed[1], cfg.speed[2])
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, cfg.size), NumberSequenceKeypoint.new(1, 0) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		e.Acceleration = cfg.accel or Vector3.zero
		e.LightEmission = cfg.light or 0
		e.SpreadAngle = Vector2.new(cfg.spread or 180, cfg.spread or 180)
		e.LockedToPart = false
		e.Parent = part
	end

	local function makePart(shape, f)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Massless = true
		local okMat, mat = pcall(function() return Enum.Material[shape.mat] end)
		p.Material = okMat and mat or Enum.Material.SmoothPlastic
		p.Color = shape.color
		p.Transparency = shape.tr
		if shape.kind == "Emitter" then
			p.Size = shape.size * f
			p.Transparency = 1 -- only the particles are seen
			buildEmitter(p, shape.emitter)
		elseif shape.kind == "Ball" then
			p.Shape = Enum.PartType.Ball
			p.Size = V(shape.size.X, shape.size.X, shape.size.X) * f
		elseif shape.kind == "Disc" then
			p.Shape = Enum.PartType.Cylinder
			p.Size = V(shape.size.Y, shape.size.X, shape.size.X) * f
		else
			p.Size = shape.size * f
		end
		if shape.text then -- logo on the front of the bag
			local sg = Instance.new("SurfaceGui")
			sg.Face = Enum.NormalId.Front
			sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			sg.PixelsPerStud = 60
			sg.LightInfluence = 0
			sg.Parent = p
			local tl = Instance.new("TextLabel")
			tl.Size = UDim2.fromScale(1, 1)
			tl.BackgroundTransparency = 1
			tl.Font = Enum.Font.GothamBold
			tl.TextScaled = true
			tl.TextColor3 = WHITE_C
			tl.Text = shape.text
			tl.Parent = sg
		end
		return p
	end

	local function build3D(cat, name)
		for _, it in ipairs(inst3D[cat] or {}) do it.part:Destroy() end
		inst3D[cat] = {}
		local def = DEFS[cat][name]
		local char = player.Character
		if not def or not char then return end
		local cam = workspace.CurrentCamera
		if not cam then return end
		if not folder or not folder.Parent then
			folder = Instance.new("Folder")
			folder.Name = "AA_Cosmetics"
			folder.Parent = cam
		end
		for _, shape in ipairs(def()) do
			local attaches = BOTH_SIDES[shape.attach] or { shape.attach }
			for _, a in ipairs(attaches) do
				local origin, f = getAttach(char, a)
				if origin then
					local p = makePart(shape, f)
					p.Parent = folder
					inst3D[cat][#inst3D[cat] + 1] = {
						part = p, shape = shape, attach = a, f = f,
						emitter = p:FindFirstChildOfClass("ParticleEmitter"),
						gui = p:FindFirstChildOfClass("SurfaceGui"),
					}
				end
			end
		end
	end

	-- every frame, after the animations: the items follow the body; wings flap
	local parts, cfs = {}, {}
	RunService:BindToRenderStep("AA_Cosmetics", Enum.RenderPriority.Last.Value + 2, function()
		local char = player.Character
		if not char then return end
		local flap = 0.25 + 0.22 * math.sin(os.clock() * 2.2)
		-- first person (the camera is at the head): the items are not drawn
		local cam = workspace.CurrentCamera
		local head = char:FindFirstChild("Head")
		local fp = cam ~= nil and head ~= nil and (cam.CFrame.Position - head.Position).Magnitude < 1.4
		local hide = fp and 1 or 0
		local origins = {}
		table.clear(parts)
		table.clear(cfs)
		local n = 0
		for _, list in pairs(inst3D) do
			for _, it in ipairs(list) do
				local origin = origins[it.attach]
				if origin == nil then
					origin = getAttach(char, it.attach) or false
					origins[it.attach] = origin
				end
				if origin and it.part.Parent then
					local s, f = it.shape, it.f
					if it.part.LocalTransparencyModifier ~= hide then it.part.LocalTransparencyModifier = hide end
					if it.emitter and it.emitter.Enabled == fp then it.emitter.Enabled = not fp end
					if it.gui and it.gui.Enabled == fp then it.gui.Enabled = not fp end
					local theta = 0
					if s.sway then
						theta = 0.3 * math.sin(os.clock() * 2.4)
					elseif s.flap ~= 0 then
						theta = -s.flap * flap
					end
					local turn = CFrame.Angles(math.rad(s.rot.X), math.rad(s.rot.Y), math.rad(s.rot.Z))
					if s.kind == "Disc" then turn = turn * CFrame.Angles(0, 0, math.pi / 2) end -- lay the plate flat
					local posv = s.pos
					if s.orbit then -- pets circle around the body and bob up and down
						local o, now = s.orbit, os.clock()
						local ang = now * o.speed + o.phase
						posv = posv + V(math.cos(ang) * o.r, o.h + o.bob * math.sin(now * 2.3), math.sin(ang) * o.r)
					end
					n += 1
					parts[n] = it.part
					cfs[n] = origin * CFrame.new(s.pivot * f) * CFrame.Angles(0, theta, 0)
						* CFrame.new((posv - s.pivot) * f) * turn
					if s.flicker then it.part.Transparency = 0.05 + math.random() * 0.45 end
				end
			end
		end
		if n > 0 then workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged) end
	end)

	-- 5 times a second: build what changed (a new pick, a config, a new body after a respawn)
	task.spawn(function()
		while true do
			local char = player.Character
			if (folder and not folder.Parent) or char ~= builtChar then
				folder, builtChar = nil, char
				for _, e in ipairs(CATS) do build3D(e.cat, applied[e.cat] or "None") end
			end
			for _, e in ipairs(CATS) do
				local want = Settings[e.key]
				if applied[e.cat] ~= want then
					applied[e.cat] = want
					build3D(e.cat, want)
					build2D(e.cat, want)
				end
			end
			task.wait(0.2)
		end
	end)
end

--// ===== PREMIUM TAB (password: xmas) =====
-- God Mode: the ghost mechanism of FE Invisible, but your real body (what the server and other
--   players hit) is parked N studs above you instead of far away.
-- Fly+: normal fly with a maximum speed of 120.
-- Hands XZ2: Hands XZ with its own palettes.
-- Screen: VHS look (see above).
do
	local cols = newPage("Premium")
	local pg = pages["Premium"]

	-- lock screen
	local lock = Instance.new("Frame")
	lock.Size = UDim2.fromScale(1, 1)
	lock.BackgroundTransparency = 1
	lock.LayoutOrder = 0
	lock.Parent = pg
	local lockCard = newCard(lock, "Premium")
	lockCard.AnchorPoint = Vector2.new(0.5, 0.5)
	lockCard.Position = UDim2.fromScale(0.5, 0.5)
	lockCard.Size = UDim2.fromOffset(250, 0)
	makeNote(lockCard, "This tab is locked. Enter the password.")
	local pwBox = makeTextBox(lockCard, "password")
	local unlockBtn = makeAction(lockCard, "Unlock")
	local pwMsg = makeNote(lockCard, "")
	for _, col in ipairs(cols) do col.Visible = false end

	-- the unlock is remembered for 24 hours (a file; without file support only until the game closes)
	local CONFIG_DIR = "AimAssistConfigs"
	local STAMP = CONFIG_DIR .. "/premium_unlock.txt"
	local DAY = 24 * 60 * 60

	local function readStamp()
		local t
		if readfile and isfile then
			pcall(function()
				if isfile(STAMP) then t = tonumber(readfile(STAMP)) end
			end)
		end
		return t or env.AimAssistPremiumAt
	end
	local function saveStamp(t)
		env.AimAssistPremiumAt = t
		if writefile and makefolder and isfolder then
			pcall(function()
				if not isfolder(CONFIG_DIR) then makefolder(CONFIG_DIR) end
				writefile(STAMP, tostring(t))
			end)
		end
	end
	local function stampValid()
		local t, now = readStamp(), os.time()
		return t ~= nil and now >= t and now - t < DAY
	end

	local function showUnlocked()
		premiumUnlocked = true
		lock.Visible = false
		for _, col in ipairs(cols) do col.Visible = true end
	end

	local function lockAgain() -- 24 hours are over
		premiumUnlocked = false
		for key in pairs(PREMIUM_KEYS) do -- every premium feature goes off
			if type(Settings[key]) == "boolean" and Settings[key] then setSetting(key, false) end
		end
		for _, col in ipairs(cols) do col.Visible = false end
		lock.Visible = true
		pwBox.Text = ""
		pwMsg.Text = "The 24 hours are over. Enter the password again."
		pwMsg.TextColor3 = THEME.sub
	end

	local function tryUnlock()
		local text = (pwBox.Text:lower():gsub("%s+", ""))
		if text == "xmas" then
			saveStamp(os.time())
			showUnlocked()
			currentPage = nil
			showPage("Premium") -- replay the page animation
		else
			pwMsg.Text = "Wrong password"
			pwMsg.TextColor3 = Color3.fromRGB(230, 90, 90)
		end
	end
	unlockBtn.Activated:Connect(tryUnlock)
	pwBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then tryUnlock() end
	end)

	-- unlocked within the last 24 hours: no password needed
	if stampValid() then showUnlocked() end
	-- and after 24 hours the password is asked again (checked every minute)
	task.spawn(function()
		while true do
			task.wait(60)
			if premiumUnlocked and not stampValid() then lockAgain() end
		end
	end)

	-- God Mode
	local c = newCard(cols[1], "God Mode", "GodMode")
	makeNote(c, "Parks your hitbox N studs above you. Others still see your body (hovering above you) but cannot reach, hit or use it. A hit that does land on it hurts you, so keep the shift high.")
	makeSlider(c, "Shift (studs)", 50, 2000, "GodShift", 0)
	c = newCard(cols[1], "Fly+", "FlyPlus")
	makeNote(c, "Fly with a higher top speed (up to 120).")
	makeSlider(c, "Fly+ Speed", 20, 120, "FlyPlusSpeed", 0)
	c = newCard(cols[1], "Air Stuck", "AirStuck")
	makeNote(c, "Freezes you in mid-air. On phones there is an AIR button on the right side of the screen.")
	c = newCard(cols[1], "Spin Bot", "SpinBot")
	makeNote(c, "Your character spins around. Others see you turning.")
	makeSlider(c, "Spin speed", 1, 20, "SpinSpeed", 0)
	c = newCard(cols[1], "Free Camera", "FreeCam")
	makeNote(c, "The camera leaves your character and flies freely. PC: WASD, E / Q up and down, hold the right mouse button to look, Shift = faster. Phone: joystick to fly, drag to look, jump = up. Your character stands still.")
	makeSlider(c, "Camera speed", 5, 300, "FreeCamSpeed", 0)

	-- Hands XZ2
	c = newCard(cols[2], "Hands XZ2", "HandsXZ2")
	makeNote(c, "Color wave over the item you hold, with its own palettes.")
	makeDropdown(c, "Palette", "HandsXZ2Palette",
		{ "Rainbow", "Black & White", "Pink", "Blue", "Green", "Red", "Green-Yellow" })
	makeDropdown(c, "Direction", "HandsXZ2Dir", { "Bottom to top", "Top to bottom", "Left to right", "Right to left" })
	makeSlider(c, "Speed", 0.3, 3, "HandsXZ2Speed", 1)
	c = newCard(cols[2], "Target Particles", "TargetParticles")
	makeNote(c, "Needs Target ESP. Crystals, souls, an animated crosshair or squares float around the player you are aiming at.")
	makeDropdown(c, "Style", "TargetParticlesMode", { "Crystals", "Souls", "Crosshair", "Squares" })
	c = newCard(cols[2], "Player Trail", "PlayerTrail")
	makeNote(c, "A glowing ribbon follows you when you move.")
	makeDropdown(c, "Style", "PlayerTrailStyle", { "Theme", "Rainbow" })
	c = newCard(cols[2], "Tap Teleport", "TapTeleport")
	makeNote(c, "Teleports you to the spot you tap. On PC hold Ctrl and click.")

	-- Screen
	c = newCard(cols[3], "Screen", "Screen")
	makeNote(c, "Old video tape look: scanlines, tracking band, glitches, camcorder text.")
	makeDropdown(c, "Mode", "ScreenMode", { "Red VHS", "White VHS" })
	c = newCard(cols[3], "Shaders+", "ShaderPlus")
	makeNote(c, "Time of day, season and space scenes with color grading, bloom, rays and atmosphere.")
	makeDropdown(c, "Mode", "ShaderPlusMode", {
		"Day", "Evening", "Sunset", "Night", "Sunrise", "Morning",
		"Winter", "Winter Evening", "Winter Night", "Autumn",
		"Space", "Milky Way", "Black Hole", "Galaxy",
	})
	c = newCard(cols[3], "Beautiful", "Beautiful")
	makeNote(c, "Everything looks wet and freshly washed: glossy, slightly darker surfaces and a crisp, clean picture.")
	c = newCard(cols[3], "Gravity", "GravityMod")
	makeNote(c, "Changes the gravity of the world. Normal is about 196.")
	makeSlider(c, "Gravity", 0, 400, "GravityValue", 0)
	c = newCard(cols[3], "Anti AFK", "AntiAFK")
	makeNote(c, "Stops the game from kicking you for standing idle.")
	c = newCard(cols[3], "Auto Clicker", "AutoClicker")
	makeNote(c, "Clicks in the middle of the screen over and over.")
	makeSlider(c, "Clicks per second", 1, 30, "ClickCPS", 0)

	--// switches that exclude each other
	onToggle["FlyPlus"] = function(on)
		if on and Settings.FlyEnabled then setSetting("FlyEnabled", false) end
	end
	onToggle["FlyEnabled"] = function(on)
		if on and Settings.FlyPlus then setSetting("FlyPlus", false) end
	end
	onToggle["HandsXZ2"] = function(on)
		if on and Settings.HandsXZ then setSetting("HandsXZ", false) end
	end
	onToggle["HandsXZ"] = function(on)
		if on and Settings.HandsXZ2 then setSetting("HandsXZ2", false) end
	end

	-- God Mode uses the ghost (clone + parked body) of FE Invisible
	onToggle["GodMode"] = function(on)
		if on then
			if invisWanted then -- FE Invisible is on: switch it off first
				pcall(setInvisible, false)
				invisWanted = false
			end
			invisShift = Settings.GodShift
			pcall(setInvisible, true)
			invisWanted = invisReal ~= nil
			if not invisWanted then -- could not start (no character yet)
				invisShift = nil
				Settings.GodMode = false
				if uiRefresh.GodMode then uiRefresh.GodMode() end
			end
		else
			pcall(setInvisible, false)
			invisWanted = false
			invisShift = nil
		end
		refreshInvisBtn()
	end
end

--// ===== ESP (highlight players by team color) =====
local espHighlights = {} -- Player -> Highlight

local function teamColorOf(plr)
	if plr.Team then
		return plr.TeamColor.Color
	end
	return Color3.new(1, 1, 1) -- no team = white
end

do
local function removeESP(plr)
	local h = espHighlights[plr]
	if h then
		h:Destroy()
		espHighlights[plr] = nil
	end
end

local function clearESP()
	for plr in pairs(espHighlights) do
		removeESP(plr)
	end
end

local function updateESP()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			local char = plr.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local h = espHighlights[plr]

			if char and hum and hum.Health > 0 then
				-- (re)create if missing or the character respawned
				if not h or h.Parent ~= char then
					removeESP(plr)
					h = Instance.new("Highlight")
					h.Name = "ESPHighlight"
					h.Adornee = char
					h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- visible through walls
					h.FillTransparency = 0.5
					h.OutlineTransparency = 0
					h.Parent = char
					espHighlights[plr] = h
				end
				local color = teamColorOf(plr)
				h.FillColor = color
				h.OutlineColor = color
			else
				removeESP(plr)
			end
		end
	end
end

Players.PlayerRemoving:Connect(removeESP)

task.spawn(function()
	local wasOn = false
	while true do
		if Settings.ESPEnabled then
			wasOn = true
			updateESP()
		elseif wasOn then
			wasOn = false
			clearESP()
		end
		task.wait(0.5)
	end
end)
end -- (scope: keeps the main chunk under the 200-locals limit)

--// ===== NAME TAGS (name, distance and health bar above every player) =====
do
	local tags = {} -- Player -> { gui =, name =, info =, fill = }

	local function removeTag(plr)
		local t = tags[plr]
		if t then
			t.gui:Destroy()
			tags[plr] = nil
		end
	end
	Players.PlayerRemoving:Connect(removeTag)

	local function makeTag(head)
		local bb = Instance.new("BillboardGui")
		bb.Name = "AA_NameTag"
		bb.Adornee = head
		bb.AlwaysOnTop = true
		bb.LightInfluence = 0
		bb.ResetOnSpawn = false
		bb.Size = UDim2.fromOffset(130, 38)
		bb.StudsOffset = Vector3.new(0, 2.7, 0)
		bb.Parent = gui.Parent -- PlayerGui

		local name = Instance.new("TextLabel")
		name.Size = UDim2.new(1, 0, 0, 16)
		name.BackgroundTransparency = 1
		name.Font = Enum.Font.GothamBold
		name.TextSize = 13
		name.TextStrokeTransparency = 0.35
		name.Parent = bb
		local info = Instance.new("TextLabel")
		info.Position = UDim2.fromOffset(0, 16)
		info.Size = UDim2.new(1, 0, 0, 12)
		info.BackgroundTransparency = 1
		info.Font = Enum.Font.Gotham
		info.TextSize = 11
		info.TextColor3 = Color3.new(1, 1, 1)
		info.TextStrokeTransparency = 0.4
		info.Parent = bb
		local barBg = Instance.new("Frame")
		barBg.AnchorPoint = Vector2.new(0.5, 0)
		barBg.Position = UDim2.new(0.5, 0, 0, 31)
		barBg.Size = UDim2.new(0.7, 0, 0, 4)
		barBg.BackgroundColor3 = Color3.new(0, 0, 0)
		barBg.BackgroundTransparency = 0.4
		barBg.BorderSizePixel = 0
		barBg.Parent = bb
		Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)
		local fill = Instance.new("Frame")
		fill.Size = UDim2.fromScale(1, 1)
		fill.BorderSizePixel = 0
		fill.Parent = barBg
		Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
		return { gui = bb, name = name, info = info, fill = fill }
	end

	task.spawn(function()
		while true do
			if Settings.NameTags then
				local cam = workspace.CurrentCamera
				local camPos = cam and cam.CFrame.Position
				for _, plr in ipairs(Players:GetPlayers()) do
					if plr ~= player then
						local char = plr.Character
						local head = char and char:FindFirstChild("Head")
						local hum = char and char:FindFirstChildOfClass("Humanoid")
						if head and hum and hum.Health > 0 then
							local t = tags[plr]
							if not t or not t.gui.Parent or t.gui.Adornee ~= head then
								removeTag(plr)
								t = makeTag(head)
								tags[plr] = t
							end
							t.name.Text = plr.DisplayName
							t.name.TextColor3 = teamColorOf(plr)
							t.info.Text = (camPos and math.floor((head.Position - camPos).Magnitude) or 0) .. " studs"
							local r = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
							t.fill.Size = UDim2.fromScale(r, 1)
							t.fill.BackgroundColor3 = Color3.fromHSV(r * 0.33, 0.8, 1) -- green -> red
						else
							removeTag(plr)
						end
					end
				end
			elseif next(tags) ~= nil then
				for plr in pairs(tags) do removeTag(plr) end
			end
			task.wait(0.1)
		end
	end)
end

--// ===== CROSSHAIR (screen center, Cross / Dot / Circle / Plus) =====
do
	local holder = Instance.new("Frame")
	holder.Name = "AA_Crosshair"
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.BackgroundTransparency = 1
	holder.Active = false
	holder.Visible = false
	holder.Parent = gui

	local builtKey
	local function clear()
		for _, c in ipairs(holder:GetChildren()) do c:Destroy() end
	end

	local function bar(x, y, w, h, round)
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.new(0.5, x, 0.5, y)
		f.Size = UDim2.fromOffset(w, h)
		f.BorderSizePixel = 0
		f.Parent = holder
		if round then Instance.new("UICorner", f).CornerRadius = UDim.new(1, 0) end
		themeBind(f, "BackgroundColor3", "accent")
		return f
	end

	local function build(style, size)
		clear()
		holder.Size = UDim2.fromOffset(size * 5, size * 5)
		local gap, len = 4, size
		if style == "Cross" or style == "Plus" then
			bar(0, -(gap + len / 2), 2, len)
			bar(0, gap + len / 2, 2, len)
			bar(-(gap + len / 2), 0, len, 2)
			bar(gap + len / 2, 0, len, 2)
		end
		if style == "Dot" or style == "Plus" then bar(0, 0, 4, 4, true) end
		if style == "Circle" then
			local ring = Instance.new("Frame")
			ring.AnchorPoint = Vector2.new(0.5, 0.5)
			ring.Position = UDim2.fromScale(0.5, 0.5)
			ring.Size = UDim2.fromOffset(size * 2, size * 2)
			ring.BackgroundTransparency = 1
			ring.BorderSizePixel = 0
			ring.Parent = holder
			Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
			local st = Instance.new("UIStroke", ring)
			st.Thickness = 2
			themeBind(st, "Color", "accent")
			bar(0, 0, 3, 3, true)
		end
	end

	task.spawn(function()
		while true do
			local on = Settings.Crosshair
			if holder.Visible ~= on then holder.Visible = on end
			if on then
				local key = Settings.CrosshairStyle .. ":" .. Settings.CrosshairSize
				if key ~= builtKey then
					builtKey = key
					build(Settings.CrosshairStyle, Settings.CrosshairSize)
				end
			end
			task.wait(0.1)
		end
	end)
end

--// ===== FOV CHANGER =====
do
	local original
	-- runs after the game's camera scripts, so it wins when the game also sets the field of view
	RunService:BindToRenderStep("AA_FOV", Enum.RenderPriority.Camera.Value + 3, function()
		local cam = workspace.CurrentCamera
		if not cam then return end
		if Settings.FovChanger then
			if not original then original = cam.FieldOfView end
			if cam.FieldOfView ~= Settings.FovValue then cam.FieldOfView = Settings.FovValue end
		elseif original then
			cam.FieldOfView = original
			original = nil
		end
	end)
end

--// ===== ZOOM UNLOCK =====
do
	local saved
	RunService.Heartbeat:Connect(function()
		if Settings.ZoomUnlock then
			if not saved then saved = { player.CameraMaxZoomDistance, player.CameraMinZoomDistance } end
			if player.CameraMaxZoomDistance ~= 1000 then player.CameraMaxZoomDistance = 1000 end
			if player.CameraMinZoomDistance ~= 0.5 then player.CameraMinZoomDistance = 0.5 end
		elseif saved then
			player.CameraMaxZoomDistance, player.CameraMinZoomDistance = saved[1], saved[2]
			saved = nil
		end
	end)
end

--// ===== RADAR (round map on the right side of the screen) =====
do
	local SIZE = 130
	local frame = Instance.new("Frame")
	frame.Name = "AA_Radar"
	frame.AnchorPoint = Vector2.new(1, 0.5)
	frame.Position = UDim2.new(1, -16, 0.5, 0)
	frame.Size = UDim2.fromOffset(SIZE, SIZE)
	frame.BackgroundColor3 = THEME.panel
	frame.BackgroundTransparency = 0.25
	frame.BorderSizePixel = 0
	frame.Active = false
	frame.Visible = false
	frame.Parent = gui
	Instance.new("UICorner", frame).CornerRadius = UDim.new(1, 0)
	do
		local st = Instance.new("UIStroke", frame)
		st.Color = Color3.new(1, 1, 1)
		st.Transparency = 0.85
		local function line(w, h)
			local f = Instance.new("Frame")
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.Position = UDim2.fromScale(0.5, 0.5)
			f.Size = UDim2.new(0, w, 0, h)
			f.BackgroundColor3 = THEME.off
			f.BackgroundTransparency = 0.4
			f.BorderSizePixel = 0
			f.Parent = frame
		end
		line(SIZE - 10, 1)
		line(1, SIZE - 10)
		local me = Instance.new("Frame") -- you
		me.AnchorPoint = Vector2.new(0.5, 0.5)
		me.Position = UDim2.fromScale(0.5, 0.5)
		me.Size = UDim2.fromOffset(7, 7)
		me.BorderSizePixel = 0
		me.Parent = frame
		Instance.new("UICorner", me).CornerRadius = UDim.new(1, 0)
		themeBind(me, "BackgroundColor3", "accent")
	end

	local dots = {}
	local function removeDot(plr)
		local d = dots[plr]
		if d then
			d:Destroy()
			dots[plr] = nil
		end
	end
	Players.PlayerRemoving:Connect(removeDot)

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		if not Settings.Radar then
			if frame.Visible then frame.Visible = false end
			return
		end
		if not frame.Visible then frame.Visible = true end
		acc += dt
		if acc < 0.05 then return end
		acc = 0

		local cam = workspace.CurrentCamera
		local char = player.Character
		local myRoot = char and char:FindFirstChild("HumanoidRootPart")
		if not (cam and myRoot) then return end
		local range = math.max(Settings.RadarRange, 1)
		local half = SIZE / 2 - 4

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player then
				local c = plr.Character
				local root = c and c:FindFirstChild("HumanoidRootPart")
				local hum = c and c:FindFirstChildOfClass("Humanoid")
				if root and hum and hum.Health > 0 then
					local dot = dots[plr]
					if not dot then
						dot = Instance.new("Frame")
						dot.AnchorPoint = Vector2.new(0.5, 0.5)
						dot.Size = UDim2.fromOffset(6, 6)
						dot.BorderSizePixel = 0
						dot.Parent = frame
						Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
						dots[plr] = dot
					end
					-- forward (camera direction) is up on the radar
					local rel = cam.CFrame:VectorToObjectSpace(root.Position - myRoot.Position)
					local v = Vector2.new(rel.X, rel.Z) / range * half
					local m = v.Magnitude
					if m > half then v = v / m * half end -- farther than the range: stays on the edge
					dot.Position = UDim2.new(0.5, v.X, 0.5, v.Y)
					dot.BackgroundColor3 = teamColorOf(plr)
					dot.BackgroundTransparency = (m > half) and 0.55 or 0
					dot.Visible = true
				else
					local dot = dots[plr]
					if dot then dot.Visible = false end
				end
			end
		end
	end)
end

--// ===== PLAYER TRACERS (arrows from you to other players) =====
-- Straight: one line + arrow head. Square: horizontal then vertical line (right angle) + arrow head.
-- Needs ESP: switching Tracers on switches ESP on, switching ESP off switches Tracers off.
do
	onToggle["Tracers"] = function(on)
		if on and not Settings.ESPEnabled then setSetting("ESPEnabled", true) end
	end
	onToggle["ESPEnabled"] = function(on)
		if not on and Settings.Tracers then setSetting("Tracers", false) end
	end

	local layer = Instance.new("Frame")
	layer.Name = "Tracers"
	layer.Size = UDim2.fromScale(1, 1)
	layer.BackgroundTransparency = 1
	layer.Active = false
	layer.ZIndex = -1 -- behind the menu and buttons
	layer.Parent = gui

	local pool = {} -- Player -> 4 line frames: [1],[2] body, [3],[4] arrow head
	local function newLine()
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.BorderSizePixel = 0
		f.Active = false
		f.Visible = false
		f.Parent = layer
		return f
	end
	local function getObj(plr)
		local o = pool[plr]
		if not o then
			o = { newLine(), newLine(), newLine(), newLine() }
			pool[plr] = o
		end
		return o
	end
	local function hideObj(o)
		for i = 1, 4 do o[i].Visible = false end
	end
	Players.PlayerRemoving:Connect(function(plr)
		local o = pool[plr]
		if o then
			for i = 1, 4 do o[i]:Destroy() end
			pool[plr] = nil
		end
	end)

	local function setLine(f, a, b, thick, color)
		local d = b - a
		local len = d.Magnitude
		if len < 1 then f.Visible = false return end
		f.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
		f.Size = UDim2.fromOffset(len, thick)
		f.Rotation = math.deg(math.atan2(d.Y, d.X))
		f.BackgroundColor3 = color
		f.Visible = true
	end

	local function arrowHead(o, tip, angle, thick, color)
		for i = 1, 2 do
			local side = (i == 1) and 1 or -1
			local a = angle + math.pi + side * math.rad(28)
			setLine(o[2 + i], tip, tip + Vector2.new(math.cos(a), math.sin(a)) * 12, thick, color)
		end
	end

	local wasOn = false
	RunService:BindToRenderStep("PlayerTracers", Enum.RenderPriority.Camera.Value + 2, function()
		if not Settings.Tracers then
			if wasOn then
				wasOn = false
				for _, o in pairs(pool) do hideObj(o) end
			end
			return
		end
		wasOn = true

		local camera = workspace.CurrentCamera
		if not camera then return end
		local vp = camera.ViewportSize

		-- start point: your character on screen (bottom middle if it is behind the camera)
		local origin = Vector2.new(vp.X / 2, vp.Y * 0.85)
		local myRoot = getRoot()
		if myRoot then
			local p3 = camera:WorldToViewportPoint(myRoot.Position)
			if p3.Z > 0 then origin = Vector2.new(p3.X, p3.Y) end
		end

		local thick = Settings.TracerThickness
		local square = Settings.TracerMode == "Square"
		local margin = 12

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player then
				local char = plr.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if not (root and hum and hum.Health > 0) then
					if pool[plr] then hideObj(pool[plr]) end
					continue
				end

				local p3 = camera:WorldToViewportPoint(root.Position)
				local target = Vector2.new(p3.X, p3.Y)
				if p3.Z < 0 then target = vp - target end -- behind you: mirror so the arrow points the right way
				target = Vector2.new(
					math.clamp(target.X, margin, vp.X - margin),
					math.clamp(target.Y, margin, vp.Y - margin))

				local color = teamColorOf(plr)
				local o = getObj(plr)
				if square then
					local corner = Vector2.new(target.X, origin.Y)
					setLine(o[1], origin, corner, thick, color)
					setLine(o[2], corner, target, thick, color)
					local from = ((corner - target).Magnitude > 6) and corner or origin
					arrowHead(o, target, math.atan2(target.Y - from.Y, target.X - from.X), thick, color)
				else
					setLine(o[1], origin, target, thick, color)
					o[2].Visible = false
					arrowHead(o, target, math.atan2(target.Y - origin.Y, target.X - origin.X), thick, color)
				end
			end
		end
	end)
end

--// ===== TARGETING =====
local targets = {}

local function isTeammate(model)
	local other = Players:GetPlayerFromCharacter(model)
	if not other then return false end
	if other == player then return true end
	if player.Team and other.Team then
		return player.Team == other.Team
	end
	return false
end

-- Humanoid models are tracked by events (one scan at start), and the target list is only
-- rebuilt while Aim / Silent Aim / Wall Fire is on - no more full workspace scan every 0.5 s.
do
local humModels = {} -- model -> true
local function trackHumanoid(obj)
	if obj:IsA("Humanoid") and obj.Parent then humModels[obj.Parent] = true end
end
workspace.DescendantAdded:Connect(trackHumanoid)
workspace.DescendantRemoving:Connect(function(obj)
	if obj:IsA("Humanoid") and obj.Parent then humModels[obj.Parent] = nil end
end)
task.spawn(function()
	local n = 0
	for _, obj in ipairs(workspace:GetDescendants()) do
		trackHumanoid(obj)
		n += 1
		if n % 500 == 0 then task.wait() end
	end
end)

task.spawn(function()
	while true do
		if Settings.AimEnabled or Settings.SilentAim or Settings.WallFire then
			table.clear(targets)
			for model in pairs(humModels) do
				local hum = model.Parent and model:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 and model ~= player.Character
					and model ~= invisReal and model:FindFirstChild("Head") then
					table.insert(targets, model)
				end
			end
		end
		task.wait(0.5)
	end
end)
end -- (scope: keeps the main chunk under the 200-locals limit)

local function isVisible(camera, model, part)
	local ignore = { player.Character }
	local origin = camera.CFrame.Position
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	for _ = 1, 10 do
		params.FilterDescendantsInstances = ignore
		local result = workspace:Raycast(origin, part.Position - origin, params)
		if not result then return true end
		local hit = result.Instance
		if hit:IsDescendantOf(model) then return true end
		if hit.Transparency >= 0.95 or not hit.CanCollide then
			table.insert(ignore, hit)
		else
			return false
		end
	end
	return false
end

local function getAimPart(model)
	local mode = Settings.AimPart
	local part
	if mode == "Torso" then
		part = model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
	elseif mode == "Root" then
		part = model:FindFirstChild("HumanoidRootPart")
	end
	return part or model:FindFirstChild("Head")
end

local function getClosestTarget(camera)
	local vp = camera.ViewportSize
	local center = Vector2.new(vp.X / 2, vp.Y / 2)
	local best, bestDist, bestName = nil, Settings.FOV, nil
	for _, model in ipairs(targets) do
		local hum = model:FindFirstChildOfClass("Humanoid")
		local head = getAimPart(model)
		local isPlayer = Players:GetPlayerFromCharacter(model) ~= nil
		if hum and hum.Health > 0 and head
			and (not Settings.PlayersOnly or isPlayer)
			and not (Settings.TeamCheck and isTeammate(model))
			and not isExcluded(model) then
			local pos, onScreen = camera:WorldToViewportPoint(head.Position)
			if onScreen and pos.Z > 0 then
				local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
				if dist < bestDist
					and (not Settings.WallCheck or Settings.WallFire or isVisible(camera, model, head)) then
					best, bestDist, bestName = head, dist, model.Name
				end
			end
		end
	end
	return best, bestName
end

--// ===== SILENT AIM + WALL FIRE (cannons) =====
-- Silent Aim: the camera does not move; shot rays / Mouse.Hit are pointed at the target's head.
-- Wall Fire: shot rays only "see" other characters, so walls never stop a cannon shot.
-- With Wall Fire ON, Aim and Silent Aim also pick targets behind walls (Wall Check is bypassed).
-- Needs an executor with hookmetamethod, getnamecallmethod and checkcaller.
-- Works in games where YOUR client decides what a shot hit (Raycast / FindPartOnRay) or
-- where the cannon reads Mouse.Hit. Server-side hit detection can still block shots.
local silentTarget = nil

-- Names used to recognise cannons / cannonballs (edit these to match your game)
do
local CANNON_KEYWORDS = { "cannon", "canon", "mortar" }
local PROJECTILE_KEYWORDS = { "cannonball", "cannon_ball", "projectile", "shell" }

local function nameMatches(name, list)
	name = name:lower()
	for _, k in ipairs(list) do
		if name:find(k, 1, true) then return true end
	end
	return false
end

local function isCannonPart(part)
	if nameMatches(part.Name, CANNON_KEYWORDS) then return true end
	local p = part.Parent
	if p and p ~= workspace and nameMatches(p.Name, CANNON_KEYWORDS) then return true end
	local pp = p and p.Parent
	return pp ~= nil and pp ~= workspace and nameMatches(pp.Name, CANNON_KEYWORDS)
end

-- every part that belongs to a cannon (refreshed every 2 s while Silent Aim / Wall Fire is on)
-- one scan the first time Silent Aim / Wall Fire is switched on, then new parts come in by event
local cannonParts, cannonKnown, cannonScanned = {}, {}, false
local function addCannon(obj)
	if obj:IsA("BasePart") and not cannonKnown[obj] and isCannonPart(obj) then
		cannonKnown[obj] = true
		table.insert(cannonParts, obj)
	end
end
task.spawn(function()
	while true do
		if Settings.SilentAim or Settings.WallFire then
			if not cannonScanned then
				cannonScanned = true
				local n = 0
				for _, obj in ipairs(workspace:GetDescendants()) do
					addCannon(obj)
					n += 1
					if n % 500 == 0 then task.wait() end
				end
			end
			for i = #cannonParts, 1, -1 do -- drop removed parts
				local part = cannonParts[i]
				if not part.Parent then
					cannonKnown[part] = nil
					table.remove(cannonParts, i)
				end
			end
		end
		task.wait(3)
	end
end)

-- Is this ray a "shot"? (starts at the camera, or at a cannon)
local function isShotRay(origin, dir)
	local len = dir.Magnitude
	local camera = workspace.CurrentCamera
	if camera and len >= 100 and (origin - camera.CFrame.Position).Magnitude < 15 then
		return true
	end
	if len >= 30 then
		for _, part in ipairs(cannonParts) do
			if part.Parent and (part.Position - origin).Magnitude < 30 then
				return true
			end
		end
	end
	return false
end

-- Cannonballs that your own client simulates must not collide with walls either
workspace.DescendantAdded:Connect(function(obj)
	if cannonScanned then addCannon(obj) end
	if Settings.WallFire and obj:IsA("BasePart") and nameMatches(obj.Name, PROJECTILE_KEYWORDS) then
		task.defer(function()
			if isnetworkowner == nil or isnetworkowner(obj) then
				pcall(function() obj.CanCollide = false end)
			end
		end)
	end
end)

local silentTimer = 0
RunService.Heartbeat:Connect(function(dt)
	if not Settings.SilentAim then
		silentTarget = nil
		return
	end
	silentTimer += dt
	if silentTimer < 0.05 then return end -- pick the target ~20x per second, not every frame
	silentTimer = 0
	local camera = workspace.CurrentCamera
	silentTarget = camera and getClosestTarget(camera) or nil
end)

do
	local hookmm = hookmetamethod
	local getnc = getnamecallmethod
	local setnc = setnamecallmethod
	local checkcall = checkcaller

	if hookmm and getnc and checkcall then
		local wrap = newcclosure or function(f) return f end
		local mouse = player:GetMouse()

		-- Mouse.Hit / Mouse.Target -> target's head (cannons that follow the mouse)
		local oldIndex
		oldIndex = hookmm(game, "__index", wrap(function(self, key)
			if self == mouse and Settings.SilentAim and silentTarget and not checkcall() then
				if key == "Hit" then
					return silentTarget.CFrame
				elseif key == "Target" then
					return silentTarget
				end
			end
			return oldIndex(self, key)
		end))

		-- only characters can be hit: walls, props and terrain are not in the filter
		-- (teammates with Team Check and players you excluded are left out as well,
		--  so they cannot absorb a shot meant for someone behind them)
		local function wallfireParams()
			local list = {}
			for _, model in ipairs(targets) do
				if model.Parent
					and not (Settings.TeamCheck and isTeammate(model))
					and not isExcluded(model) then
					table.insert(list, model)
				end
			end
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Include
			params.FilterDescendantsInstances = list
			return params
		end

		local function redirect(origin, dir)
			if Settings.SilentAim and silentTarget then
				return (silentTarget.Position - origin).Unit * dir.Magnitude
			end
			return dir
		end

		local oldNamecall
		oldNamecall = hookmm(game, "__namecall", wrap(function(self, ...)
			local method = getnc()
			if self == workspace and (Settings.SilentAim or Settings.WallFire) and not checkcall() then
				if method == "Raycast" then
					local args = table.pack(...)
					local origin, dir = args[1], args[2]
					if typeof(origin) == "Vector3" and typeof(dir) == "Vector3" and isShotRay(origin, dir) then
						args[2] = redirect(origin, dir)
						if Settings.WallFire then
							args[3] = wallfireParams()
							args.n = math.max(args.n, 3)
						end
						return oldNamecall(self, table.unpack(args, 1, args.n))
					end

				elseif Settings.WallFire and setnc
					and (method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList"
						or method == "FindPartOnRayWithWhitelist") then
					-- old-style ray API: answer it with a wall-free Raycast instead
					local ray = ...
					if typeof(ray) == "Ray" and isShotRay(ray.Origin, ray.Direction) then
						local dir = redirect(ray.Origin, ray.Direction)
						setnc("Raycast")
						local result = oldNamecall(self, ray.Origin, dir, wallfireParams())
						if result then
							return result.Instance, result.Position, result.Normal, result.Material
						end
						return nil, ray.Origin + dir, Vector3.yAxis, Enum.Material.Air
					end
				end
			end
			return oldNamecall(self, ...)
		end))
	else
		warn("[Silent Aim / Wall Fire] executor lacks hookmetamethod/getnamecallmethod/checkcaller - both disabled")
	end
end
end -- (scope: keeps the main chunk under the 200-locals limit)

--// ===== MAIN LOOP (after default camera) =====
do
local lastVP, lastFOV
local aimHead, aimName
local aimTimer = 0

RunService:BindToRenderStep("AimAssistStep", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local show = Settings.AimEnabled or Settings.SilentAim
	if circle.Visible ~= show then circle.Visible = show end

	local camera = workspace.CurrentCamera
	if not camera then return end

	-- only touch the FOV circle when its size or the screen changed
	if show then
		local vp = camera.ViewportSize
		if vp ~= lastVP or Settings.FOV ~= lastFOV then
			lastVP, lastFOV = vp, Settings.FOV
			circle.Size = UDim2.fromOffset(Settings.FOV * 2, Settings.FOV * 2)
			circle.Position = UDim2.fromOffset(vp.X / 2, vp.Y / 2)
		end
	end

	-- nothing more to do when the camera aim itself is off
	if not Settings.AimEnabled then
		aimHead = nil
		if menu.Visible then status.Text = "Aim is OFF" end
		return
	end

	-- phones have no AIM button: with Aim switched on in the menu it is always active there
	local active = isTouch or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
	if not active then
		aimHead = nil
		if menu.Visible then
			status.Text = "Hold RMB | Target: none"
		end
		return
	end

	-- choose the target ~20x per second; the camera still follows it smoothly every frame
	aimTimer += dt
	if aimTimer >= 0.05 then
		aimTimer = 0
		aimHead, aimName = getClosestTarget(camera)
	elseif aimHead and not aimHead.Parent then
		aimHead = nil
	end

	if aimHead then
		if menu.Visible then status.Text = "Target: " .. tostring(aimName) end
		local goal = CFrame.lookAt(camera.CFrame.Position, aimHead.Position)
		local alpha = 1 - (1 - Settings.Speed) ^ (dt * 60)
		camera.CFrame = camera.CFrame:Lerp(goal, alpha)
	elseif menu.Visible then
		status.Text = "None in FOV / blocked"
	end
end)

--// ===== TARGET ESP (card with avatar, name and health of the current target) =====
-- Shown while Aim or Silent Aim has a target. Placed at the end of the file because it reads the
-- current targets (silentTarget / aimHead) of those two features.
do
	local card = Instance.new("CanvasGroup")
	card.Name = "TargetESP"
	card.AnchorPoint = Vector2.new(0.5, 0)
	card.Position = UDim2.new(0.5, 0, 0, 44)
	card.Size = UDim2.fromOffset(210, 54)
	card.BackgroundColor3 = THEME.panel
	card.BackgroundTransparency = 0.08
	card.BorderSizePixel = 0
	card.GroupTransparency = 1
	card.Visible = false
	card.Parent = gui
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
	local cardScale = Instance.new("UIScale", card)
	cardScale.Scale = 0.9
	do
		local st = Instance.new("UIStroke", card)
		st.Color = Color3.new(1, 1, 1)
		st.Transparency = 0.92
	end

	-- avatar (head shot of the player's skin)
	local avatar = Instance.new("ImageLabel")
	avatar.Position = UDim2.fromOffset(7, 7)
	avatar.Size = UDim2.fromOffset(40, 40)
	avatar.BackgroundColor3 = THEME.field
	avatar.BorderSizePixel = 0
	avatar.Parent = card
	Instance.new("UICorner", avatar).CornerRadius = UDim.new(0, 8)
	local letter = Instance.new("TextLabel") -- shown for NPCs (no skin to load)
	letter.Size = UDim2.fromScale(1, 1)
	letter.BackgroundTransparency = 1
	letter.Font = Enum.Font.GothamBold
	letter.TextSize = 18
	letter.TextColor3 = THEME.sub
	letter.Text = "?"
	letter.Parent = avatar

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Position = UDim2.fromOffset(54, 6)
	nameLbl.Size = UDim2.new(1, -62, 0, 16)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextSize = 13
	nameLbl.TextColor3 = THEME.text
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
	nameLbl.Parent = card

	local capLbl = Instance.new("TextLabel")
	capLbl.Position = UDim2.fromOffset(54, 22)
	capLbl.Size = UDim2.new(0.5, -30, 0, 12)
	capLbl.BackgroundTransparency = 1
	capLbl.Font = Enum.Font.Gotham
	capLbl.TextSize = 10
	capLbl.TextColor3 = THEME.sub
	capLbl.TextXAlignment = Enum.TextXAlignment.Left
	capLbl.Text = "Health"
	capLbl.Parent = card

	local hpLbl = Instance.new("TextLabel")
	hpLbl.AnchorPoint = Vector2.new(1, 0)
	hpLbl.Position = UDim2.new(1, -8, 0, 22)
	hpLbl.Size = UDim2.new(0.5, -20, 0, 12)
	hpLbl.BackgroundTransparency = 1
	hpLbl.Font = Enum.Font.GothamMedium
	hpLbl.TextSize = 10
	hpLbl.TextColor3 = THEME.text
	hpLbl.TextXAlignment = Enum.TextXAlignment.Right
	hpLbl.Parent = card

	local barBg = Instance.new("Frame")
	barBg.Position = UDim2.fromOffset(54, 37)
	barBg.Size = UDim2.new(1, -62, 0, 9)
	barBg.BackgroundColor3 = THEME.off
	barBg.BorderSizePixel = 0
	barBg.Parent = card
	Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)
	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.fromScale(1, 1)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)
	themeBind(barFill, "BackgroundColor3", "accent") -- the health bar follows the menu theme

	-- skin thumbnails are loaded once per player, in the background
	local thumbs, loading = {}, {}
	local function loadThumb(userId)
		if thumbs[userId] or loading[userId] then return end
		loading[userId] = true
		task.spawn(function()
			local ok, img = pcall(Players.GetUserThumbnailAsync, Players, userId,
				Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
			loading[userId] = nil
			if ok and img then thumbs[userId] = img end
		end)
	end

	-- appear / disappear animation
	local shown = false
	local tweens = {}
	local function setShown(on)
		if shown == on then return end
		shown = on
		for _, t in ipairs(tweens) do t:Cancel() end
		if on then
			card.Visible = true
			tweens = {
				TweenService:Create(cardScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }),
				TweenService:Create(card, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { GroupTransparency = 0 }),
			}
		else
			local fade = TweenService:Create(card, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { GroupTransparency = 1 })
			tweens = {
				TweenService:Create(cardScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { Scale = 0.92 }),
				fade,
			}
			fade.Completed:Connect(function(state)
				if not shown and state == Enum.PlaybackState.Completed then card.Visible = false end
			end)
		end
		for _, t in ipairs(tweens) do t:Play() end
	end

	local currentModel, currentPlayer
	local ratio = 1
	local lostFor = 0

	RunService.Heartbeat:Connect(function(dt)
		-- who is being targeted right now?
		local part
		if Settings.TargetESP then
			part = (Settings.SilentAim and silentTarget) or (Settings.AimEnabled and aimHead) or nil
		end
		local model = part and part.Parent
		local hum = model and model:FindFirstChildOfClass("Humanoid")
		if not (hum and hum.Health > 0) then model = nil end

		if not model then
			lostFor += dt
			if lostFor > 0.25 then setShown(false) end -- short grace time so it does not flicker
			return
		end
		lostFor = 0

		if model ~= currentModel then
			currentModel = model
			currentPlayer = Players:GetPlayerFromCharacter(model)
			if currentPlayer then
				nameLbl.Text = currentPlayer.Name
				letter.Text = "?"
				loadThumb(currentPlayer.UserId)
				avatar.Image = thumbs[currentPlayer.UserId] or ""
				letter.Visible = not thumbs[currentPlayer.UserId]
			else
				nameLbl.Text = model.Name
				avatar.Image = ""
				letter.Text = model.Name:sub(1, 1):upper()
				letter.Visible = true
			end
			ratio = hum.Health / math.max(hum.MaxHealth, 1)
		end

		-- the skin may finish loading after the card was already shown
		if currentPlayer then
			local img = thumbs[currentPlayer.UserId]
			if img and avatar.Image ~= img then
				avatar.Image = img
				letter.Visible = false
			end
		end

		local goal = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
		ratio += (goal - ratio) * math.min(1, dt * 10) -- smooth bar
		barFill.Size = UDim2.fromScale(ratio, 1)
		hpLbl.Text = math.floor(hum.Health + 0.5) .. " / " .. math.floor(hum.MaxHealth + 0.5)
		setShown(true)
	end)
end

--// ===== TARGET PARTICLES (Premium) =====
-- Works while Target ESP is on. Small things fly around the player Aim / Silent Aim is targeting:
-- Crystals, Souls (glowing orbs with a tail), Crosshair (animated sight), Squares.
-- Colors follow the menu theme. Placed at the end of the file because it reads silentTarget / aimHead.
do
	local rng = Random.new()
	local folder, items, builtMode, crosshair
	local alpha = 0               -- fade in / out (0..1)
	local center = Vector3.zero   -- smoothed position of the target

	-- accent color with a little variation per particle
	local function tint(i)
		local h, s, v = THEME.accent:ToHSV()
		local k = ((i * 37) % 100) / 100
		return Color3.fromHSV((h + (k - 0.5) * 0.06) % 1,
			math.clamp(s * (0.8 + k * 0.25), 0, 1), math.clamp(v * (0.85 + k * 0.2), 0, 1))
	end

	local function recolor()
		for i, it in ipairs(items or {}) do
			local c = tint(i)
			if it.trail then
				c = c:Lerp(Color3.new(1, 1, 1), 0.55) -- souls are paler
				it.trail.Color = ColorSequence.new(c, c:Lerp(Color3.new(1, 1, 1), 0.5))
			end
			if it.part.Parent then it.part.Color = c end
		end
		if crosshair and crosshair.gui.Parent then
			for _, f in ipairs(crosshair.frames) do f.BackgroundColor3 = THEME.accent end
			crosshair.stroke.Color = THEME.accent
		end
	end
	table.insert(themeHooks, recolor)

	local function clear()
		if folder then folder:Destroy() end
		if crosshair then crosshair.gui:Destroy() end
		folder, items, builtMode, crosshair = nil, {}, nil, nil
	end

	local function newPart(name, size)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Massless = true
		p.Material = Enum.Material.Neon
		p.Size = size
		p.Transparency = 1
		p.Parent = folder
		return p
	end

	local function buildCrosshair()
		local bb = Instance.new("BillboardGui")
		bb.Name = "AA_TargetCrosshair"
		bb.AlwaysOnTop = true
		bb.LightInfluence = 0
		bb.Size = UDim2.fromOffset(120, 120)
		bb.ResetOnSpawn = false
		bb.Parent = gui.Parent -- PlayerGui

		local box = Instance.new("CanvasGroup")
		box.AnchorPoint = Vector2.new(0.5, 0.5)
		box.Position = UDim2.fromScale(0.5, 0.5)
		box.Size = UDim2.fromScale(1, 1)
		box.BackgroundTransparency = 1
		box.GroupTransparency = 1
		box.Parent = bb

		local ring = Instance.new("Frame")
		ring.AnchorPoint = Vector2.new(0.5, 0.5)
		ring.Position = UDim2.fromScale(0.5, 0.5)
		ring.Size = UDim2.fromScale(0.72, 0.72)
		ring.BackgroundTransparency = 1
		ring.BorderSizePixel = 0
		ring.Parent = box
		Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
		local stroke = Instance.new("UIStroke", ring)
		stroke.Thickness = 2
		stroke.Color = THEME.accent

		local frames = {}
		local function mark(pos, size)
			local f = Instance.new("Frame")
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.Position = pos
			f.Size = size
			f.BackgroundColor3 = THEME.accent
			f.BorderSizePixel = 0
			f.Parent = box
			frames[#frames + 1] = f
		end
		mark(UDim2.fromScale(0.5, 0.05), UDim2.fromOffset(2, 16)) -- ticks: up, down, left, right
		mark(UDim2.fromScale(0.5, 0.95), UDim2.fromOffset(2, 16))
		mark(UDim2.fromScale(0.05, 0.5), UDim2.fromOffset(16, 2))
		mark(UDim2.fromScale(0.95, 0.5), UDim2.fromOffset(16, 2))
		mark(UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(4, 4))   -- center dot

		crosshair = { gui = bb, box = box, ring = ring, stroke = stroke, frames = frames }
	end

	local function build(mode)
		clear()
		local cam = workspace.CurrentCamera
		if not cam then return end
		folder = Instance.new("Folder")
		folder.Name = "AA_TargetFX"
		folder.Parent = cam
		items = {}
		builtMode = mode
		if mode == "Crosshair" then
			buildCrosshair()
			recolor()
			return
		end

		local n = (mode == "Souls") and 8 or 14
		for i = 1, n do
			local it = {
				phase = rng:NextNumber(0, math.pi * 2),
				radius = rng:NextNumber(1.8, 3.2),
				speed = rng:NextNumber(0.7, 1.6) * (rng:NextInteger(0, 1) == 0 and 1 or -1),
				height = rng:NextNumber(-0.8, 1.8),
			}
			if mode == "Crystals" then
				it.part = newPart("Crystal", Vector3.new(0.16, 0.36, 0.16))
			elseif mode == "Squares" then
				it.part = newPart("Square", Vector3.new(0.32, 0.32, 0.04))
			else -- Souls
				local p = newPart("Soul", Vector3.new(0.34, 0.34, 0.34))
				p.Shape = Enum.PartType.Ball
				local a0 = Instance.new("Attachment", p)
				a0.Position = Vector3.new(0, 0.17, 0)
				local a1 = Instance.new("Attachment", p)
				a1.Position = Vector3.new(0, -0.17, 0)
				local tr = Instance.new("Trail")
				tr.Attachment0, tr.Attachment1 = a0, a1
				tr.Lifetime = 0.55
				tr.LightEmission = 1
				tr.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
				tr.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
				tr.Parent = p
				it.part, it.trail = p, tr
				it.speed = it.speed * 0.6
			end
			items[i] = it
		end
		recolor()
	end

	local parts, cfs = {}, {}
	local function update(mode, t)
		if mode == "Crosshair" then
			if crosshair then
				crosshair.box.Rotation = (t * 70) % 360
				crosshair.box.GroupTransparency = 1 - alpha
				local k = 0.72 + 0.08 * math.sin(t * 4)           -- the ring breathes
				crosshair.ring.Size = UDim2.fromScale(k, k)
			end
			return
		end
		table.clear(parts)
		table.clear(cfs)
		for i, it in ipairs(items) do
			local a = t * it.speed + it.phase
			local r = it.radius
			local y = it.height + math.sin(t * 1.3 + it.phase) * 0.35
			if mode == "Souls" then
				r = r + math.sin(t * 0.8 + it.phase) * 0.4
				y = y + math.sin(t * 0.6 + it.phase * 2) * 0.5
			end
			local cf = CFrame.new(center + Vector3.new(math.cos(a) * r, y, math.sin(a) * r))
			if mode == "Crystals" then
				cf = cf * CFrame.Angles(math.rad(25), t * 2 + it.phase, 0)
			elseif mode == "Squares" then
				cf = cf * CFrame.Angles(t * 1.5 + it.phase, t * 2 + it.phase, t + it.phase)
			end
			parts[i], cfs[i] = it.part, cf
			it.part.Transparency = 1 - alpha * 0.85
		end
		if #parts > 0 then workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged) end
	end

	RunService.Heartbeat:Connect(function(dt)
		local model, part
		if premiumUnlocked and Settings.TargetParticles and Settings.TargetESP then
			part = (Settings.SilentAim and silentTarget) or (Settings.AimEnabled and aimHead) or nil
			model = part and part.Parent
			local hum = model and model:FindFirstChildOfClass("Humanoid")
			if not (hum and hum.Health > 0) then model = nil end
		end

		local mode = Settings.TargetParticlesMode
		if folder and not folder.Parent then clear() end -- the camera was replaced
		local t = os.clock()

		if model then
			local root = model:FindFirstChild("HumanoidRootPart") or part
			if not folder or builtMode ~= mode then
				build(mode)
				center = root.Position
			end
			if not folder then return end
			alpha = math.min(1, alpha + dt * 4)
			center = center:Lerp(root.Position, math.min(1, dt * 14))
			if crosshair then crosshair.gui.Adornee = root end
			update(mode, t)
		elseif folder then -- no target: fade out where it was, then remove
			alpha = alpha - dt * 4
			if alpha <= 0 then
				alpha = 0
				clear()
			else
				update(builtMode, t)
			end
		end
	end)
end

--// ===== KILL / DIE EFFECTS (Cosmetics) =====
-- When a player you were aiming at / killed dies, or when you die, a short effect plays where it
-- happened: Black Hole, Earth, Sky Pillar or Fireworks. Everything is drawn only for you.
-- Placed at the end of the file because it reads silentTarget / aimHead (your current target).
do
	local function C(r, g, b) return Color3.fromRGB(r, g, b) end
	local function V(x, y, z) return Vector3.new(x, y, z) end
	local rng = Random.new()
	local folder
	local active = {} -- { group =, fx =, born = }
	local MAX = 4

	local function newPart(group, size, color, transparency, material)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = material or Enum.Material.Neon
		p.Color = color
		p.Transparency = transparency or 0
		p.Size = size
		p.Parent = group
		return p
	end
	local function ball(group, size, color, transparency, material)
		local p = newPart(group, V(size, size, size), color, transparency, material)
		p.Shape = Enum.PartType.Ball
		return p
	end
	local function disc(group, color, transparency)
		local p = newPart(group, V(0.15, 4, 4), color, transparency)
		p.Shape = Enum.PartType.Cylinder
		return p
	end
	-- grows in, stays, shrinks out (0..1)
	local function envelope(age, dur, inT, outT)
		local k = 1
		if age < inT then k = age / inT elseif age > dur - outT then k = math.max(0, (dur - age) / outT) end
		return k * k * (3 - 2 * k)
	end

	local EFFECTS = {}

	EFFECTS["Black Hole"] = function(group, pos)
		local dur = 3.6
		local center = pos + V(0, 4, 0)
		local hole = ball(group, 1, Color3.new(0, 0, 0), 0, Enum.Material.SmoothPlastic)
		local glow = ball(group, 1, C(255, 140, 40), 0.92)
		local ring = {}
		for i = 1, 28 do
			ring[i] = {
				part = ball(group, 0.4, Color3.fromHSV(0.06 + (i % 5) * 0.02, 0.85, 1), 0.1),
				a = i / 28 * math.pi * 2,
				r = 2.8 + ((i * 7) % 10) / 10 * 1.4,
			}
		end
		local tilt = CFrame.Angles(math.rad(65), 0, math.rad(15))
		return { dur = dur, update = function(age)
			local k = envelope(age, dur, 0.6, 0.7)
			hole.Size = V(3.2, 3.2, 3.2) * k
			hole.Position = center
			glow.Size = V(7.5, 7.5, 7.5) * k
			glow.Position = center
			for _, r in ipairs(ring) do
				local a = r.a + age * (3.2 / (0.6 + r.r * 0.25)) -- the inner ones turn faster
				r.part.Size = V(0.4, 0.4, 0.4) * k
				r.part.CFrame = CFrame.new(center) * tilt * CFrame.new(math.cos(a) * r.r * k, 0, math.sin(a) * r.r * k)
			end
		end }
	end

	EFFECTS["Earth"] = function(group, pos)
		local dur = 4.2
		local planet = ball(group, 1, C(30, 90, 200), 0, Enum.Material.SmoothPlastic)
		local atmo = ball(group, 1, C(120, 190, 255), 0.85)
		local moon = ball(group, 0.9, C(200, 200, 205), 0, Enum.Material.SmoothPlastic)
		local lands = {}
		for i, d in ipairs({ V(0.6, 0.5, 0.6), V(-0.7, 0.3, 0.6), V(0.1, -0.6, 0.8), V(-0.5, -0.4, -0.7),
			V(0.8, -0.1, -0.5), V(0, 0.9, 0.2), V(-0.2, 0.2, -0.95) }) do
			local land = ball(group, 1, C(60, 160, 70), 0, Enum.Material.SmoothPlastic)
			lands[i] = { part = land, dir = d.Unit }
		end
		return { dur = dur, update = function(age)
			local k = envelope(age, dur, 0.7, 0.8)
			local rise = 2 + 4 * math.min(age / 1.2, 1)
			local center = pos + V(0, rise + 1.5, 0)
			local R = 2.3 * k
			planet.Size = V(1, 1, 1) * 2 * R
			planet.Position = center
			atmo.Size = V(1, 1, 1) * (2 * R + 0.7 * k)
			atmo.Position = center
			local rot = CFrame.new(center) * CFrame.Angles(math.rad(23), age * 1.1, 0) -- the planet turns
			for _, l in ipairs(lands) do
				l.part.Size = V(1.7, 1.4, 0.3) * k
				l.part.CFrame = rot * CFrame.lookAt(l.dir * R, l.dir * (R + 1)) -- a flat patch lying on the surface
			end
			local a = age * 2
			moon.Size = V(0.9, 0.9, 0.9) * k
			moon.Position = center + CFrame.Angles(math.rad(30), 0, 0) * V(math.cos(a) * 4.5 * k, 0, math.sin(a) * 4.5 * k)
		end }
	end

	EFFECTS["Sky Pillar"] = function(group, pos)
		local dur = 3.2
		local col = THEME.accent:Lerp(Color3.new(1, 1, 1), 0.55)
		local pillar = newPart(group, V(1, 300, 1), col, 0.25)
		local core = newPart(group, V(1, 300, 1), Color3.new(1, 1, 1), 0)
		local rings = {}
		for j = 1, 3 do rings[j] = disc(group, col, 0.3) end
		return { dur = dur, update = function(age)
			local k = envelope(age, dur, 0.25, 0.7)
			local w = 3.4 * k
			pillar.Size = V(w, 300, w)
			pillar.Position = pos + V(0, 150, 0)
			core.Size = V(w * 0.35, 300, w * 0.35)
			core.Position = pillar.Position
			for j, r in ipairs(rings) do -- rings spread out on the ground
				local ph = (age * 1.3 + j / 3) % 1
				local d = 2 + ph * 14
				r.Size = V(0.15, d, d)
				r.CFrame = CFrame.new(pos + V(0, 0.15, 0)) * CFrame.Angles(0, 0, math.pi / 2)
				r.Transparency = 0.2 + 0.8 * ph
			end
		end }
	end

	EFFECTS["Fireworks"] = function(group, pos)
		local dur = 1.8
		local origin = pos + V(0, 3, 0)
		local sparks = {}
		for i = 1, 44 do
			local dir = V(rng:NextNumber(-1, 1), rng:NextNumber(-0.2, 1), rng:NextNumber(-1, 1))
			if dir.Magnitude < 0.1 then dir = Vector3.yAxis end
			sparks[i] = {
				part = ball(group, 0.4, Color3.fromHSV(rng:NextNumber(), 0.8, 1), 0),
				vel = dir.Unit * rng:NextNumber(12, 22),
			}
		end
		return { dur = dur, update = function(age)
			local k = 1 - age / dur
			for _, sp in ipairs(sparks) do
				sp.part.Position = origin + sp.vel * age + V(0, -15 * age * age, 0) -- gravity
				sp.part.Size = V(0.4, 0.4, 0.4) * k
				sp.part.Transparency = (1 - k) * 0.8
			end
		end }
	end

	local function spawnEffect(name, pos)
		local build = EFFECTS[name]
		local cam = workspace.CurrentCamera
		if not build or not cam then return end
		if not folder or not folder.Parent then
			folder = Instance.new("Folder")
			folder.Name = "AA_Effects"
			folder.Parent = cam
			active = {}
		end
		local group = Instance.new("Folder")
		group.Parent = folder
		local ok, fx = pcall(build, group, pos)
		if not ok then
			group:Destroy()
			warn("[Effect] " .. tostring(fx))
			return
		end
		active[#active + 1] = { group = group, fx = fx, born = os.clock() }
		if #active > MAX then
			local old = table.remove(active, 1)
			old.group:Destroy()
		end
	end
	effectApi.spawn = spawnEffect
	effectApi.test = function(name) -- the "Test it" buttons: plays it a few steps in front of you
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then spawnEffect(name, root.Position + root.CFrame.LookVector * 10 - V(0, 3, 0)) end
	end

	-- remember who I aimed at (a kill = that player dies shortly after), and animate running effects
	local lastTarget, lastAt
	RunService.Heartbeat:Connect(function()
		local part = (Settings.SilentAim and silentTarget) or (Settings.AimEnabled and aimHead) or nil
		if part and part.Parent then
			lastTarget, lastAt = part.Parent, os.clock()
		end
		for i = #active, 1, -1 do
			local e = active[i]
			local age = os.clock() - e.born
			if age >= e.fx.dur or not e.group.Parent then
				e.group:Destroy()
				table.remove(active, i)
			else
				pcall(e.fx.update, age)
			end
		end
	end)

	local function watchCharacter(plr, char)
		local hum = char:WaitForChild("Humanoid", 10)
		if not hum then return end
		hum.Died:Connect(function()
			local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
			if not root then return end
			local ground = root.Position - V(0, 2.5, 0)
			if plr == player then
				if Settings.DieEffect ~= "None" then spawnEffect(Settings.DieEffect, ground) end
			elseif Settings.KillEffect ~= "None" then
				local tag = hum:FindFirstChild("creator") -- the classic "who killed him" tag
				local byMe = tag ~= nil and tag.Value == player
				local recent = lastTarget == char and lastAt ~= nil and os.clock() - lastAt < 4
				if byMe or recent then spawnEffect(Settings.KillEffect, ground) end
			end
		end)
	end
	local function watchPlayer(plr)
		if plr.Character then task.spawn(watchCharacter, plr, plr.Character) end
		plr.CharacterAdded:Connect(function(char) watchCharacter(plr, char) end)
	end
	for _, plr in ipairs(Players:GetPlayers()) do watchPlayer(plr) end
	Players.PlayerAdded:Connect(watchPlayer)
end

--// ===== GUN SKIN (Cosmetics) =====
-- Puts a skin on the weapon in your hands: the tool you hold, or the weapon of a first-person
-- viewmodel in the camera (never the arms). Colors, materials, an outline and little particles
-- change; everything is restored when you pick None. Hands XZ has priority while it is on.
do
	local function C(r, g, b) return Color3.fromRGB(r, g, b) end
	local function wave(t, i, speed) return 0.5 + 0.5 * math.sin(t * speed + i) end

	local SKINS = {
		["Galaxy"] = { mat = "Neon", outline = C(150, 120, 255),
			color = function(t, i)
				return C(40, 20, 120):Lerp(C(190, 70, 230), wave(t, i * 0.9, 1.2)):Lerp(C(30, 90, 220), wave(t, i, 0.7))
			end,
			emit = { colors = { C(255, 255, 255), C(170, 140, 255) }, rate = 10, life = { 0.8, 1.4 }, speed = { 0.2, 0.6 }, size = 0.12, accel = Vector3.zero } },
		["Black Hole"] = { mat = "SmoothPlastic", fill = Color3.new(0, 0, 0),
			outline = function(t) return C(255, 130 + math.floor(60 * math.sin(t * 3)), 30) end,
			color = function() return Color3.new(0, 0, 0) end,
			emit = { colors = { C(255, 190, 80), C(255, 100, 20) }, rate = 12, life = { 0.5, 0.9 }, speed = { 0.3, 0.8 }, size = 0.12, accel = Vector3.zero } },
		["Water"] = { mat = "Glass", transp = 0.3, reflect = 0.3, outline = C(120, 210, 255),
			color = function(t, i) return C(60, 140, 255):Lerp(C(130, 215, 255), wave(t, i, 1.6)) end,
			emit = { colors = { C(220, 245, 255), C(120, 200, 255) }, rate = 9, life = { 0.8, 1.3 }, speed = { 0.2, 0.5 }, size = 0.14, accel = Vector3.new(0, 1.5, 0) } },
		["Lava"] = { mat = "CrackedLava", outline = C(255, 120, 30),
			color = function(t, i) return C(255, 70 + math.floor(60 * wave(t, i, 4)), 0) end,
			emit = { colors = { C(255, 220, 90), C(255, 90, 20) }, rate = 12, life = { 0.5, 1 }, speed = { 0.4, 1 }, size = 0.12, accel = Vector3.new(0, 3, 0) } },
		["Ice"] = { mat = "Ice", reflect = 0.25, outline = C(200, 245, 255),
			color = function() return C(170, 230, 255) end,
			emit = { colors = { C(255, 255, 255), C(170, 230, 255) }, rate = 8, life = { 0.8, 1.4 }, speed = { 0.1, 0.4 }, size = 0.1, accel = Vector3.zero } },
		["Gold"] = { mat = "Metal", reflect = 0.4, outline = C(255, 225, 120),
			color = function(t, i) return C(240, 185, 50):Lerp(C(255, 235, 140), wave(t, i, 2)) end },
		["Diamond"] = { mat = "Glass", transp = 0.15, reflect = 0.5, outline = C(200, 255, 255),
			color = function(t, i) return C(150, 240, 255):Lerp(C(255, 255, 255), wave(t, i, 3) * 0.5) end,
			emit = { colors = { C(255, 255, 255), C(150, 240, 255) }, rate = 10, life = { 0.4, 0.8 }, speed = { 0.2, 0.6 }, size = 0.1, accel = Vector3.zero } },
		["Rainbow"] = { mat = "Neon", outline = Color3.new(1, 1, 1),
			color = function(t, i) return Color3.fromHSV((t * 0.3 + i * 0.12) % 1, 0.85, 1) end },
		["Matrix"] = { mat = "Neon", outline = C(0, 255, 90),
			color = function(t, i) return C(0, 170 + math.floor(85 * wave(t, i * 3, 9)), 70) end,
			emit = { colors = { C(0, 255, 90), C(0, 120, 40) }, rate = 14, life = { 0.6, 1 }, speed = { 0.2, 0.6 }, size = 0.1, accel = Vector3.new(0, -4, 0) } },
		["Toxic"] = { mat = "Neon", outline = C(180, 255, 60),
			color = function(t, i) return C(110, 230, 0):Lerp(C(190, 255, 40), wave(t, i, 2.5)) end,
			emit = { colors = { C(220, 255, 120), C(110, 230, 0) }, rate = 10, life = { 0.8, 1.3 }, speed = { 0.2, 0.5 }, size = 0.16, accel = Vector3.new(0, 1.5, 0) } },
	}

	local orig = {}   -- part -> { Color, Material, Reflectance, Transparency }
	local active = {} -- parts that wear the skin (list)
	local glow = {}   -- instance -> Highlight
	local emit = {}   -- part -> ParticleEmitter
	local appliedSkin

	local function isUnderArm(d, root)
		local a = d
		while a and a ~= root do
			if VMX.isArm(a.Name) then return true end
			a = a.Parent
		end
		return false
	end

	local function makeEmitter(part, cfg)
		local e = Instance.new("ParticleEmitter")
		local colors = cfg.colors
		if #colors == 1 then colors = { colors[1], colors[1] } end
		local keys = {}
		for i, col in ipairs(colors) do
			keys[#keys + 1] = ColorSequenceKeypoint.new((i - 1) / (#colors - 1), col)
		end
		e.Color = ColorSequence.new(keys)
		e.Rate = cfg.rate
		e.Lifetime = NumberRange.new(cfg.life[1], cfg.life[2])
		e.Speed = NumberRange.new(cfg.speed[1], cfg.speed[2])
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, cfg.size), NumberSequenceKeypoint.new(1, 0) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		e.Acceleration = cfg.accel
		e.LightEmission = 1
		e.SpreadAngle = Vector2.new(180, 180)
		e.LockedToPart = false
		e.Parent = part
		return e
	end

	local function volume(p) return p.Size.X * p.Size.Y * p.Size.Z end

	-- the weapon: the tool in the character's hand and the non-arm parts of a viewmodel
	local function collect()
		local set, list, wantGlow, wantEmit = {}, {}, {}, {}
		local function add(p)
			if #list < 120 and p:IsA("BasePart") and not set[p] and p.Transparency < 0.95 then
				set[p] = true
				list[#list + 1] = p
				return true
			end
		end
		local char = player.Character
		local tool = char and char:FindFirstChildOfClass("Tool")
		if tool then
			local biggest
			for _, d in ipairs(tool:GetDescendants()) do
				if add(d) and (not biggest or volume(d) > volume(biggest)) then biggest = d end
			end
			wantGlow[tool] = true
			if biggest then wantEmit[biggest] = true end
		end
		for _, root in ipairs(VMX.roots) do
			local held = {}
			local nodes = root:IsA("BasePart") and { root } or root:GetDescendants()
			for _, d in ipairs(nodes) do
				if d:IsA("BasePart") and not VMX.isArm(d.Name) and not isUnderArm(d, root) and add(d) then
					held[#held + 1] = d
				end
			end
			table.sort(held, function(a, b) return volume(a) > volume(b) end)
			for i = 1, math.min(#held, 3) do wantGlow[held[i]] = true end
			if held[1] then wantEmit[held[1]] = true end
		end
		return list, set, wantGlow, wantEmit
	end

	local function restorePart(p)
		local o = orig[p]
		if o then
			if p.Parent then
				p.Color, p.Material, p.Reflectance, p.Transparency = o.Color, o.Material, o.Reflectance, o.Transparency
			end
			orig[p] = nil
		end
	end

	local function reconcile(name, list, set, wantGlow, wantEmit)
		local sk = SKINS[name]
		if appliedSkin ~= name then -- a different skin: its particles must be new
			for part, e in pairs(emit) do
				e:Destroy()
				emit[part] = nil
			end
			appliedSkin = name
		end
		for p in pairs(orig) do
			if not set[p] then restorePart(p) end
		end
		for _, p in ipairs(list) do
			if not orig[p] then
				orig[p] = { Color = p.Color, Material = p.Material, Reflectance = p.Reflectance, Transparency = p.Transparency }
			end
		end
		active = list

		for inst, h in pairs(glow) do
			if not wantGlow[inst] or not h.Parent or not inst.Parent then
				h:Destroy()
				glow[inst] = nil
			end
		end
		for inst in pairs(wantGlow) do
			if not glow[inst] and inst.Parent then
				local h = Instance.new("Highlight")
				h.Name = "AA_GunSkinGlow"
				h.OutlineTransparency = 0.1
				h.DepthMode = Enum.HighlightDepthMode.Occluded
				h.Adornee = inst
				h.Parent = inst
				glow[inst] = h
			end
		end
		for part, e in pairs(emit) do
			if not wantEmit[part] or not sk.emit or not e.Parent or not part.Parent then
				e:Destroy()
				emit[part] = nil
			end
		end
		if sk.emit then
			for part in pairs(wantEmit) do
				if not emit[part] and part.Parent then emit[part] = makeEmitter(part, sk.emit) end
			end
		end
	end

	local function clearAll()
		for p in pairs(orig) do restorePart(p) end
		active = {}
		for inst, h in pairs(glow) do
			h:Destroy()
			glow[inst] = nil
		end
		for part, e in pairs(emit) do
			e:Destroy()
			emit[part] = nil
		end
		appliedSkin = nil
	end

	local function wanted()
		if Settings.HandsXZ or Settings.HandsXZ2 then return nil end -- Hands XZ has priority
		local n = Settings.CosGunSkin
		return SKINS[n] and n or nil
	end

	task.spawn(function()
		while true do
			local name = wanted()
			if name then
				reconcile(name, collect())
			elseif next(orig) ~= nil or next(glow) ~= nil or next(emit) ~= nil then
				clearAll()
			end
			task.wait(0.25)
		end
	end)

	-- every frame: the animated colors
	RunService:BindToRenderStep("AA_GunSkin", Enum.RenderPriority.Last.Value + 3, function()
		local name = wanted()
		local sk = name and SKINS[name]
		if not sk then return end
		local t = os.clock()
		local mat = Enum.Material[sk.mat]
		for i, p in ipairs(active) do
			if p.Parent then
				if p.Material ~= mat then p.Material = mat end
				p.Color = sk.color(t, i)
				p.Reflectance = sk.reflect or 0
				if sk.transp then p.Transparency = sk.transp end
			end
		end
		local outline = type(sk.outline) == "function" and sk.outline(t) or sk.outline
		for _, h in pairs(glow) do
			h.OutlineColor = outline
			h.FillColor = sk.fill or Color3.new(1, 1, 1)
			h.FillTransparency = sk.fill and 0 or 1
		end
	end)
end

--// ===== FREE CAMERA (Premium) =====
-- The camera leaves your character and flies freely; the character stands still (its root part is
-- anchored while the free camera is on).
do
	local active = false
	local pos, yaw, pitch
	local prevType, prevAnchored, frozenRoot
	local looking = false -- right mouse button held

	local function enter()
		local cam = workspace.CurrentCamera
		if not cam then return end
		active = true
		prevType = cam.CameraType
		pitch, yaw = cam.CFrame:ToOrientation()
		pos = cam.CFrame.Position
		cam.CameraType = Enum.CameraType.Scriptable
		local root = getRoot()
		if root then
			frozenRoot, prevAnchored = root, root.Anchored
			root.Anchored = true
		end
	end

	local function leave()
		active = false
		looking = false
		local cam = workspace.CurrentCamera
		if cam then
			cam.CameraType = prevType or Enum.CameraType.Custom
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if hum then cam.CameraSubject = hum end
		end
		-- give the root part back (the parked body of FE Invisible / God Mode stays anchored)
		if frozenRoot and frozenRoot.Parent and not (invisReal and frozenRoot:IsDescendantOf(invisReal)) then
			frozenRoot.Anchored = prevAnchored
		end
		frozenRoot = nil
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	UserInputService.InputBegan:Connect(function(i)
		if active and i.UserInputType == Enum.UserInputType.MouseButton2 then
			looking = true
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton2 then
			looking = false
			if active then UserInputService.MouseBehavior = Enum.MouseBehavior.Default end
		end
	end)
	UserInputService.InputChanged:Connect(function(i, processed)
		if not active then return end
		if i.UserInputType == Enum.UserInputType.MouseMovement and looking then
			yaw = yaw - i.Delta.X * 0.0035
			pitch = math.clamp(pitch - i.Delta.Y * 0.0035, -1.5, 1.5)
		elseif i.UserInputType == Enum.UserInputType.Touch and not processed then -- drag on the screen
			yaw = yaw - i.Delta.X * 0.006
			pitch = math.clamp(pitch - i.Delta.Y * 0.006, -1.5, 1.5)
		end
	end)
	UserInputService.JumpRequest:Connect(function() -- phone: the jump button flies up
		if active then pos = pos + Vector3.new(0, 3, 0) end
	end)

	RunService:BindToRenderStep("AA_FreeCam", Enum.RenderPriority.Camera.Value + 4, function(dt)
		local want = premiumUnlocked and Settings.FreeCam
		if want and not active then
			enter()
		elseif not want and active then
			leave()
		end
		if not active then return end
		local cam = workspace.CurrentCamera
		if not cam then return end

		local rot = CFrame.fromOrientation(pitch, yaw, 0)
		local look, right = rot.LookVector, rot.RightVector
		local move = Vector3.zero
		local function down(key) return UserInputService:IsKeyDown(key) end
		if down(Enum.KeyCode.W) then move = move + look end
		if down(Enum.KeyCode.S) then move = move - look end
		if down(Enum.KeyCode.D) then move = move + right end
		if down(Enum.KeyCode.A) then move = move - right end
		if down(Enum.KeyCode.E) or down(Enum.KeyCode.Space) then move = move + Vector3.yAxis end
		if down(Enum.KeyCode.Q) or down(Enum.KeyCode.LeftControl) then move = move - Vector3.yAxis end

		-- phone joystick: the character's MoveDirection is the stick, turned into the camera's frame
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum and hum.MoveDirection.Magnitude > 0 then
			local flat = Vector3.new(look.X, 0, look.Z)
			local flatRight = Vector3.new(right.X, 0, right.Z)
			if flat.Magnitude > 0.01 and flatRight.Magnitude > 0.01 then
				local md = hum.MoveDirection
				move = move + look * md:Dot(flat.Unit) + right * md:Dot(flatRight.Unit)
			end
		end

		if move.Magnitude > 0 then
			if move.Magnitude > 1 then move = move.Unit end
			local speed = Settings.FreeCamSpeed * (down(Enum.KeyCode.LeftShift) and 3 or 1)
			pos = pos + move * speed * dt
		end
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = CFrame.new(pos) * rot
	end)
end

--// ===== HITBOX =====
-- Makes the body part (HumanoidRootPart or Head) of other players bigger on YOUR side, so shots,
-- raycasts and touches that your own game checks hit more easily. The server is not told, so it
-- only helps where the hit check runs on your client. Teammates (with Team Check) and players you
-- excluded in the Players tab keep their normal size. Everything is restored when it is off.
do
	local changed = {} -- part -> { Size, Transparency, CanCollide, Massless, Color, Material }

	local function restore(part)
		local o = changed[part]
		if o then
			if part.Parent then
				part.Size, part.Transparency, part.CanCollide, part.Massless = o.Size, o.Transparency, o.CanCollide, o.Massless
				part.Color, part.Material = o.Color, o.Material
			end
			changed[part] = nil
		end
	end

	task.spawn(function()
		while true do
			local want = {}
			if Settings.Hitbox then
				local size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize)
				for _, plr in ipairs(Players:GetPlayers()) do
					local model = plr ~= player and plr.Character
					if model then
						local hum = model:FindFirstChildOfClass("Humanoid")
						local part = model:FindFirstChild(Settings.HitboxPart == "Head" and "Head" or "HumanoidRootPart")
						if part and part:IsA("BasePart") and hum and hum.Health > 0
							and not (Settings.TeamCheck and isTeammate(model)) and not isExcluded(model) then
							want[part] = true
							local o = changed[part]
							if not o then
								o = { Size = part.Size, Transparency = part.Transparency, CanCollide = part.CanCollide,
									Massless = part.Massless, Color = part.Color, Material = part.Material }
								changed[part] = o
							end
							if part.Size ~= size then part.Size = size end
							part.CanCollide = false -- the big box must not push anyone
							part.Massless = true
							if Settings.HitboxShow then
								part.Transparency = 0.7
								part.Color = THEME.accent
								part.Material = Enum.Material.Neon
							else
								part.Transparency, part.Color, part.Material = o.Transparency, o.Color, o.Material
							end
						end
					end
				end
			end
			for part in pairs(changed) do
				if not want[part] then restore(part) end
			end
			task.wait(0.15)
		end
	end)
end

--// ===== 10 EXTRA FUNCTIONS =====
-- Visuals: Camera Offset, Hit Marker, Damage Numbers, Vignette, Self Glow
-- Misc:    Speedometer, Coordinates, Compass, Clock, Hide Menu Key
-- All of them are local: they only draw things for you and do not change what other players see.
do
	local vis, misc = pageCols["Visuals"], pageCols["Misc"]

	--// 1. Hit Marker: an X in the middle of the screen flashes when your aim target loses health
	local hitHolder = Instance.new("Frame")
	hitHolder.Name = "AA_HitMarker"
	hitHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	hitHolder.Position = UDim2.fromScale(0.5, 0.5)
	hitHolder.Size = UDim2.fromOffset(22, 22)
	hitHolder.BackgroundTransparency = 1
	hitHolder.Visible = false
	hitHolder.Parent = gui
	for _, rot in ipairs({ 45, -45 }) do
		local bar = Instance.new("Frame")
		bar.AnchorPoint = Vector2.new(0.5, 0.5)
		bar.Position = UDim2.fromScale(0.5, 0.5)
		bar.Size = UDim2.fromOffset(20, 2)
		bar.Rotation = rot
		bar.BorderSizePixel = 0
		bar.Parent = hitHolder
		themeBind(bar, "BackgroundColor3", "accent")
	end
	local hitUntil = 0

	--// 2. Damage Numbers: "-N" floats above a player's head when their health drops
	local dmgCount = 0
	local function spawnDamage(head, amount)
		local cam = workspace.CurrentCamera
		if not cam or dmgCount > 25 or (cam.CFrame.Position - head.Position).Magnitude > 200 then return end
		dmgCount += 1
		local bb = Instance.new("BillboardGui")
		bb.Name = "AA_DamageNumber"
		bb.Adornee = head
		bb.AlwaysOnTop = true
		bb.LightInfluence = 0
		bb.ResetOnSpawn = false
		bb.Size = UDim2.fromOffset(80, 30)
		bb.StudsOffset = Vector3.new(math.random(-10, 10) / 10, 2.5, 0)
		bb.Parent = gui.Parent
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, 1)
		l.BackgroundTransparency = 1
		l.Font = Enum.Font.GothamBold
		l.TextSize = 18
		l.TextColor3 = Color3.new(1, 1, 1)
		l.TextStrokeTransparency = 0.3
		l.Text = "-" .. tostring(math.floor(amount + 0.5))
		l.Parent = bb
		TweenService:Create(bb, TweenInfo.new(0.9, Enum.EasingStyle.Quad), {
			StudsOffset = Vector3.new(bb.StudsOffset.X, 4.5, 0),
		}):Play()
		TweenService:Create(l, TweenInfo.new(0.9), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		task.delay(0.95, function()
			bb:Destroy()
			dmgCount -= 1
		end)
	end

	-- health is always sampled (so turning a feature on does not report old damage); the action runs only when on
	local lastHp = setmetatable({}, { __mode = "k" })
	task.spawn(function()
		while true do
			for _, plr in ipairs(Players:GetPlayers()) do
				local model = plr ~= player and plr.Character
				local hum = model and model:FindFirstChildOfClass("Humanoid")
				if hum then
					local prev, now = lastHp[hum], hum.Health
					lastHp[hum] = now
					if prev and now < prev and now >= 0 then
						local head = model:FindFirstChild("Head")
						if Settings.DamageNumbers and head then spawnDamage(head, prev - now) end
						if Settings.HitMarker then
							-- the target of Aim / Silent Aim is the player you are shooting at
							local aimed = (silentTarget and silentTarget.Parent == model)
								or (aimHead and aimHead.Parent == model)
							if aimed then hitUntil = os.clock() + 0.25 end
						end
					end
				end
			end
			task.wait(0.05)
		end
	end)

	--// 3. Vignette: dark edges of the screen, strength slider
	local vigRoot
	local vigGradients = {}
	local function buildVignette()
		vigRoot = Instance.new("Frame")
		vigRoot.Name = "AA_Vignette"
		vigRoot.Size = UDim2.fromScale(1, 1)
		vigRoot.BackgroundTransparency = 1
		vigRoot.Active = false
		vigRoot.Visible = false
		vigRoot.Parent = gui
		local function edge(pos, size, rot)
			local f = Instance.new("Frame")
			f.Position, f.Size = pos, size
			f.BackgroundColor3 = Color3.new(0, 0, 0)
			f.BorderSizePixel = 0
			f.Active = false
			f.Parent = vigRoot
			local g = Instance.new("UIGradient", f)
			g.Rotation = rot
			vigGradients[#vigGradients + 1] = g
		end
		edge(UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.28), 90)
		edge(UDim2.fromScale(0, 0.72), UDim2.fromScale(1, 0.28), 270)
		edge(UDim2.fromScale(0, 0), UDim2.fromScale(0.2, 1), 0)
		edge(UDim2.fromScale(0.8, 0), UDim2.fromScale(0.2, 1), 180)
	end
	task.spawn(function()
		while true do
			if Settings.Vignette then
				if not vigRoot then buildVignette() end
				vigRoot.Visible = true
				local seq = NumberSequence.new(1 - Settings.VignetteStrength, 1)
				for _, g in ipairs(vigGradients) do g.Transparency = seq end
			elseif vigRoot then
				vigRoot.Visible = false
			end
			task.wait(0.2)
		end
	end)

	--// 4. Self Glow: outline around your own character in the theme color
	task.spawn(function()
		local hl
		while true do
			local char = player.Character
			if Settings.SelfGlow and char then
				if not hl or hl.Adornee ~= char or not hl.Parent then
					if hl then hl:Destroy() end
					hl = Instance.new("Highlight")
					hl.Name = "AA_SelfGlow"
					hl.Adornee = char
					hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					hl.FillTransparency = 0.85
					hl.OutlineTransparency = 0
					hl.Parent = char
					themeBind(hl, "FillColor", "accent")
					themeBind(hl, "OutlineColor", "accent")
				end
			elseif hl then
				hl:Destroy()
				hl = nil
			end
			task.wait(0.25)
		end
	end)

	--// 5. Camera Offset: over-the-shoulder view (skipped while Free Cam is on)
	RunService:BindToRenderStep("AA_CamOffset", Enum.RenderPriority.Camera.Value + 5, function()
		if not Settings.CamOffset or Settings.FreeCam then return end
		local cam = workspace.CurrentCamera
		if not cam or cam.CameraType == Enum.CameraType.Scriptable then return end
		cam.CFrame = cam.CFrame * CFrame.new(Settings.CamOffsetX, 0, 0)
	end)

	--// HUD elements (all children of the menu gui, so a re-run removes them)
	local function hudLabel(anchor, pos, width)
		local l = Instance.new("TextLabel")
		l.AnchorPoint = anchor
		l.Position = pos
		l.Size = UDim2.fromOffset(width, 20)
		l.BackgroundColor3 = THEME.panel
		l.BackgroundTransparency = 0.2
		l.BorderSizePixel = 0
		l.Font = Enum.Font.GothamMedium
		l.TextSize = 12
		l.TextColor3 = THEME.text
		l.Visible = false
		l.Parent = gui
		Instance.new("UICorner", l).CornerRadius = UDim.new(0, 6)
		return l
	end
	local speedL = hudLabel(Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -14), 150)
	local coordL = hudLabel(Vector2.new(0, 1), UDim2.new(0, 8, 1, -14), 190)
	local clockL = hudLabel(Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 58), 90)

	--// 6. Compass: a strip at the top that shows the direction you face
	local compass = Instance.new("Frame")
	compass.Name = "AA_Compass"
	compass.AnchorPoint = Vector2.new(0.5, 0)
	compass.Position = UDim2.new(0.5, 0, 0, 34)
	compass.Size = UDim2.fromOffset(240, 18)
	compass.BackgroundColor3 = THEME.panel
	compass.BackgroundTransparency = 0.25
	compass.BorderSizePixel = 0
	compass.ClipsDescendants = true
	compass.Visible = false
	compass.Parent = gui
	Instance.new("UICorner", compass).CornerRadius = UDim.new(0, 6)
	local marks = {}
	for _, m in ipairs({ { "N", 0 }, { "NE", 45 }, { "E", 90 }, { "SE", 135 }, { "S", 180 },
		{ "SW", 225 }, { "W", 270 }, { "NW", 315 } }) do
		local l = Instance.new("TextLabel")
		l.AnchorPoint = Vector2.new(0.5, 0.5)
		l.Position = UDim2.fromScale(0.5, 0.5)
		l.Size = UDim2.fromOffset(34, 16)
		l.BackgroundTransparency = 1
		l.Font = Enum.Font.GothamBold
		l.TextSize = 11
		l.Text = m[1]
		l.TextColor3 = THEME.text
		if m[1] == "N" then themeBind(l, "TextColor3", "accent") end -- north is highlighted
		l.Parent = compass
		marks[#marks + 1] = { label = l, bearing = m[2] }
	end

	--// Hide Menu Key: RightShift shows / hides the menu (PC)
	UserInputService.InputBegan:Connect(function(i, processed)
		if processed or not Settings.HideKey then return end
		if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == Enum.KeyCode.RightShift then
			setMenu(not menuOpen)
		end
	end)

	-- one per-frame update for the hit marker and the compass, and a 10 Hz update for the texts
	local acc = 0
	RunService:BindToRenderStep("AA_HUD", Enum.RenderPriority.Last.Value, function(dt)
		hitHolder.Visible = os.clock() < hitUntil

		local cam = workspace.CurrentCamera
		compass.Visible = Settings.Compass
		if Settings.Compass and cam then
			local look = cam.CFrame.LookVector
			local heading = (math.deg(math.atan2(look.X, -look.Z)) + 360) % 360
			for _, mk in ipairs(marks) do
				local d = ((mk.bearing - heading + 540) % 360) - 180
				mk.label.Visible = math.abs(d) <= 90
				mk.label.Position = UDim2.fromScale(0.5 + d / 180, 0.5)
			end
		end

		acc += dt
		if acc < 0.1 then return end
		acc = 0
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")

		speedL.Visible = Settings.Speedometer and root ~= nil
		if speedL.Visible then
			local v = root.AssemblyLinearVelocity
			speedL.Text = string.format("%.1f studs/s", Vector3.new(v.X, 0, v.Z).Magnitude)
		end
		coordL.Visible = Settings.Coords and root ~= nil
		if coordL.Visible then
			local p = root.Position
			coordL.Text = "X " .. tostring(math.floor(p.X)) .. "  Y " .. tostring(math.floor(p.Y))
				.. "  Z " .. tostring(math.floor(p.Z))
		end
		clockL.Visible = Settings.Clock
		if clockL.Visible then clockL.Text = os.date("%H:%M:%S") end
	end)

	--// cards
	local c = newCard(vis[1], "Camera Offset", "CamOffset")
	makeNote(c, "Moves the camera to the side (over-the-shoulder view). Negative values move it to the left.")
	makeSlider(c, "Offset (studs)", -6, 6, "CamOffsetX", 1)

	c = newCard(vis[2], "Hit Marker", "HitMarker")
	makeNote(c, "Flashes an X in the middle of the screen when the player you aim at loses health.")
	c = newCard(vis[2], "Damage Numbers", "DamageNumbers")
	makeNote(c, "Shows the damage above a player's head when their health drops.")

	c = newCard(vis[3], "Vignette", "Vignette")
	makeNote(c, "Darkens the edges of the screen.")
	makeSlider(c, "Strength", 0.1, 1, "VignetteStrength", 2)
	c = newCard(vis[3], "Self Glow", "SelfGlow")
	makeNote(c, "Outlines your own character in the menu theme color.")

	c = newCard(misc[1], "Speedometer", "Speedometer")
	makeNote(c, "Your horizontal speed in studs per second, at the bottom of the screen.")
	c = newCard(misc[1], "Coordinates", "Coords")
	makeNote(c, "Your position (X, Y, Z) in the bottom left corner.")
	c = newCard(misc[2], "Compass", "Compass")
	makeNote(c, "Shows the direction you face along the top of the screen. North is highlighted.")
	c = newCard(misc[2], "Clock", "Clock")
	makeNote(c, "Real time (hour:minute:second) under the compass.")
	c = newCard(misc[3], "Hide Menu Key", "HideKey")
	makeNote(c, "On PC, RightShift shows and hides the menu.")

	--// Click GUI: a themed keycap / click ripple whenever you press a key or click
	local CLICK_SKINS = {
		Chocolate = { bg = Color3.fromRGB(74, 44, 24), hi = Color3.fromRGB(150, 100, 58), text = Color3.fromRGB(255, 240, 220) },
		["New Year"] = { bg = Color3.fromRGB(170, 25, 35), hi = Color3.fromRGB(35, 140, 65), text = Color3.fromRGB(255, 220, 130) },
		Toxic = { bg = Color3.fromRGB(35, 110, 15), hi = Color3.fromRGB(150, 255, 60), text = Color3.new(1, 1, 1) },
		Magma = { bg = Color3.fromRGB(110, 20, 8), hi = Color3.fromRGB(255, 140, 30), text = Color3.fromRGB(255, 225, 150) },
	}
	local keycap = Instance.new("TextLabel")
	keycap.AnchorPoint = Vector2.new(0.5, 1)
	keycap.Position = UDim2.new(0.5, 0, 1, -90)
	keycap.Size = UDim2.fromOffset(0, 34)
	keycap.AutomaticSize = Enum.AutomaticSize.X
	keycap.BorderSizePixel = 0
	keycap.Font = Enum.Font.GothamBold
	keycap.TextSize = 15
	keycap.Visible = false
	keycap.Parent = gui
	Instance.new("UICorner", keycap).CornerRadius = UDim.new(0, 8)
	Instance.new("UIPadding", keycap).PaddingLeft = UDim.new(0, 14)
	Instance.new("UIPadding", keycap).PaddingRight = UDim.new(0, 14)
	local keycapScale = Instance.new("UIScale", keycap)

	local function popKeycap(text)
		local skin = CLICK_SKINS[Settings.ClickSkin] or CLICK_SKINS.Chocolate
		keycap.Text = text
		keycap.BackgroundColor3 = skin.bg
		keycap.TextColor3 = skin.text
		keycap.Visible = true
		keycapScale.Scale = 0.6
		TweenService:Create(keycapScale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		local hl = Instance.new("UIStroke", keycap)
		hl.Thickness = 2
		hl.Color = skin.hi
		task.delay(0.35, function()
			TweenService:Create(keycap, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(hl, TweenInfo.new(0.25), { Transparency = 1 }):Play()
			task.delay(0.26, function()
				if keycap.Visible then
					keycap.Visible = false
					keycap.BackgroundTransparency = 0
				end
				hl:Destroy()
			end)
		end)
	end

	local function popRipple(pos)
		local skin = CLICK_SKINS[Settings.ClickSkin] or CLICK_SKINS.Chocolate
		local ring = Instance.new("Frame")
		ring.AnchorPoint = Vector2.new(0.5, 0.5)
		ring.Position = UDim2.fromOffset(pos.X, pos.Y)
		ring.Size = UDim2.fromOffset(6, 6)
		ring.BackgroundTransparency = 1
		ring.BorderSizePixel = 0
		ring.Parent = gui
		Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
		local st = Instance.new("UIStroke", ring)
		st.Thickness = 3
		st.Color = skin.hi
		TweenService:Create(ring, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(46, 46) }):Play()
		TweenService:Create(st, TweenInfo.new(0.35), { Transparency = 1 }):Play()
		task.delay(0.36, function() ring:Destroy() end)
	end

	UserInputService.InputBegan:Connect(function(i, processed)
		if not Settings.ClickGUI then return end
		if i.UserInputType == Enum.UserInputType.Keyboard then
			if processed then return end
			popKeycap(i.KeyCode.Name)
		elseif not processed and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
			local pos = (i.UserInputType == Enum.UserInputType.Touch) and i.Position or UserInputService:GetMouseLocation()
			popRipple(Vector2.new(pos.X, pos.Y))
		end
	end)

	c = newCard(misc[1], "Click GUI", "ClickGUI")
	makeNote(c, "Every key press and click shows a themed pop-up / ripple.")
	makeDropdown(c, "Skin", "ClickSkin", { "Chocolate", "New Year", "Toxic", "Magma" })

	--// Menu Style: a decorative look behind the menu's cards (Cloud / Glass / Metal / Carpet)
	local menuBaseTransparency = menu.BackgroundTransparency
	local menuStyleOverlay
	local function applyMenuStyle(name)
		if menuStyleOverlay then
			menuStyleOverlay:Destroy()
			menuStyleOverlay = nil
		end
		menu.BackgroundTransparency = menuBaseTransparency
		if name == "None" or not name then return end

		local ov = Instance.new("Frame")
		ov.Name = "AA_MenuStyle"
		ov.Size = UDim2.fromScale(1, 1)
		ov.BorderSizePixel = 0
		ov.ZIndex = -1
		ov.Parent = menu
		Instance.new("UICorner", ov).CornerRadius = UDim.new(0, 12)
		menuStyleOverlay = ov

		if name == "Cloud" then
			menu.BackgroundTransparency = 0.3
			ov.BackgroundColor3 = Color3.fromRGB(240, 248, 255)
			ov.BackgroundTransparency = 0.25
			local g = Instance.new("UIGradient", ov)
			g.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(215, 235, 255))
			g.Rotation = 90
		elseif name == "Glass" then
			menu.BackgroundTransparency = 0.6
			ov.BackgroundColor3 = Color3.new(1, 1, 1)
			ov.BackgroundTransparency = 0.88
			local g = Instance.new("UIGradient", ov)
			g.Rotation = 45
			g.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(0.45, 0.95),
				NumberSequenceKeypoint.new(0.55, 0.95), NumberSequenceKeypoint.new(1, 0.7),
			})
			local st = Instance.new("UIStroke", ov)
			st.Thickness = 1
			st.Color = Color3.new(1, 1, 1)
			st.Transparency = 0.5
		elseif name == "Metal" then
			ov.BackgroundColor3 = Color3.fromRGB(140, 142, 150)
			ov.BackgroundTransparency = 0.08
			local g = Instance.new("UIGradient", ov)
			g.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(95, 97, 105)),
				ColorSequenceKeypoint.new(0.45, Color3.fromRGB(205, 208, 215)),
				ColorSequenceKeypoint.new(0.55, Color3.fromRGB(205, 208, 215)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 82, 90)),
			})
			g.Rotation = 60
		elseif name == "Carpet" then
			ov.BackgroundColor3 = Color3.fromRGB(110, 20, 28)
			ov.BackgroundTransparency = 0.05
			local g = Instance.new("UIGradient", ov)
			g.Rotation = 45
			local seq = {}
			for i = 0, 16 do
				seq[#seq + 1] = NumberSequenceKeypoint.new(i / 16, (i % 2 == 0) and 0 or 0.22)
			end
			g.Transparency = NumberSequence.new(seq)
			local st = Instance.new("UIStroke", ov)
			st.Thickness = 2
			st.Color = Color3.fromRGB(70, 10, 16)
		end
	end
	local menuStyleCard = newCard(misc[2], "Menu Style")
	makeNote(menuStyleCard, "Changes the look of the menu itself.")
	makeDropdown(menuStyleCard, "Style", "MenuStyle", { "None", "Cloud", "Glass", "Metal", "Carpet" })
	local menuStyleDropdownRefresh = uiRefresh["MenuStyle"]
	uiRefresh["MenuStyle"] = function()
		menuStyleDropdownRefresh()
		applyMenuStyle(Settings.MenuStyle)
	end
	applyMenuStyle(Settings.MenuStyle)
end
end -- (scope: keeps the main chunk under the 200-locals limit)

--// ===== MUSIC (own tab): play a Roblox sound/song by ID, only for you =====
-- The ID box sits in a bar fixed to the bottom of the tab (always visible, not part of the
-- scrolling list). Back / Forward move through the IDs you played this session.
do
	local SoundService = game:GetService("SoundService")
	local cols = newPage("Music", true)
	local page = pages["Music"]
	local col = cols[1]
	col.Size = UDim2.new(1, 0, 1, -90) -- leave room for the bottom ID bar

	local c = newCard(col, "Music", "Music")
	makeNote(c, "Plays a Roblox audio by its ID, only for you. Many audios are private or removed and cannot be played.")
	makeSlider(c, "Volume", 0, 10, "MusicVolume", 1)
	makeToggle(c, "Loop", "MusicLoop", "Repeat the song")
	local statusLbl = makeNote(c, "Music is off.")

	local histCard = newCard(col, "History")
	makeNote(histCard, "Back / Forward move through the IDs you have played this session.")
	local histRow = Instance.new("Frame")
	histRow.Size = UDim2.new(1, 0, 0, 30)
	histRow.BackgroundTransparency = 1
	place(histCard, histRow)
	local backBtn = Instance.new("TextButton")
	backBtn.Size = UDim2.new(0.48, -4, 1, 0)
	backBtn.BackgroundColor3 = THEME.field
	backBtn.BorderSizePixel = 0
	backBtn.Font = Enum.Font.GothamMedium
	backBtn.TextSize = 12
	backBtn.TextColor3 = THEME.text
	backBtn.Text = "< Back"
	backBtn.Parent = histRow
	Instance.new("UICorner", backBtn).CornerRadius = UDim.new(0, 6)
	local fwdBtn = Instance.new("TextButton")
	fwdBtn.AnchorPoint = Vector2.new(1, 0)
	fwdBtn.Position = UDim2.new(1, 0, 0, 0)
	fwdBtn.Size = UDim2.new(0.48, -4, 1, 0)
	fwdBtn.BackgroundColor3 = THEME.field
	fwdBtn.BorderSizePixel = 0
	fwdBtn.Font = Enum.Font.GothamMedium
	fwdBtn.TextSize = 12
	fwdBtn.TextColor3 = THEME.text
	fwdBtn.Text = "Forward >"
	fwdBtn.Parent = histRow
	Instance.new("UICorner", fwdBtn).CornerRadius = UDim.new(0, 6)
	local histLbl = mkLabel(histCard, "No track played yet", 10, THEME.sub, Enum.Font.Gotham)
	histLbl.Size = UDim2.new(1, 0, 0, 14)
	place(histCard, histLbl)

	-- built-in presets: one tap plays them (wiring happens below, once setId exists)
	local BUILTIN_PRESETS = {
		{ label = "Назад в кресты", id = "122585466408339" },
		{ label = "Son of a Birch (DOORS, may not play)", id = "72485389733441" },
	}
	local presetCard = newCard(col, "Built-in")
	makeNote(presetCard, "Tap to play.")
	local presetBtns = {}
	for _, p in ipairs(BUILTIN_PRESETS) do
		local btn = makeAction(presetCard, p.label)
		presetBtns[#presetBtns + 1] = { btn = btn, id = p.id }
	end

	-- bottom bar: parented to the menu itself (not the page), so the page's own list layout
	-- cannot reposition it; only visible while the Music tab is open
	local bar = Instance.new("Frame")
	bar.Name = "AA_MusicBar"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -44)
	bar.Size = UDim2.new(1, -16, 0, 74)
	bar.BackgroundColor3 = THEME.card
	bar.BorderSizePixel = 0
	bar.ZIndex = 5
	bar.Visible = false
	bar.Parent = menu
	Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 8)
	local barPad = Instance.new("UIPadding", bar)
	barPad.PaddingTop, barPad.PaddingBottom = UDim.new(0, 8), UDim.new(0, 8)
	barPad.PaddingLeft, barPad.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)

	local idBox = Instance.new("TextBox")
	idBox.Size = UDim2.new(1, -78, 0, 30)
	idBox.BackgroundColor3 = THEME.field
	idBox.BorderSizePixel = 0
	idBox.TextColor3 = THEME.text
	idBox.PlaceholderText = "song ID or rbxassetid://..."
	idBox.PlaceholderColor3 = THEME.sub
	idBox.Text = Settings.MusicId
	idBox.ClearTextOnFocus = false
	idBox.Font = Enum.Font.Gotham
	idBox.TextSize = 12
	idBox.TextXAlignment = Enum.TextXAlignment.Left
	idBox.ZIndex = 6
	idBox.Parent = bar
	Instance.new("UICorner", idBox).CornerRadius = UDim.new(0, 6)
	Instance.new("UIPadding", idBox).PaddingLeft = UDim.new(0, 8)

	local playBtn = Instance.new("TextButton")
	playBtn.AnchorPoint = Vector2.new(1, 0)
	playBtn.Position = UDim2.new(1, 0, 0, 0)
	playBtn.Size = UDim2.fromOffset(70, 30)
	playBtn.BorderSizePixel = 0
	playBtn.Font = Enum.Font.GothamMedium
	playBtn.TextSize = 12
	playBtn.Text = "Play"
	playBtn.ZIndex = 6
	playBtn.Parent = bar
	Instance.new("UICorner", playBtn).CornerRadius = UDim.new(0, 6)
	themeBind(playBtn, "BackgroundColor3", "accent")
	themeBind(playBtn, "TextColor3", "onAccent")

	local hintLbl = Instance.new("TextLabel")
	hintLbl.Position = UDim2.fromOffset(0, 34)
	hintLbl.Size = UDim2.new(1, 0, 0, 14)
	hintLbl.BackgroundTransparency = 1
	hintLbl.Font = Enum.Font.Gotham
	hintLbl.TextSize = 10
	hintLbl.TextColor3 = THEME.sub
	hintLbl.TextXAlignment = Enum.TextXAlignment.Left
	hintLbl.Text = "Type the ID here, then Play."
	hintLbl.ZIndex = 6
	hintLbl.Parent = bar

	-- only show the bottom bar while the Music tab is the one open
	local baseShowPageMusic = showPage
	showPage = function(name, instant)
		baseShowPageMusic(name, instant)
		bar.Visible = (name == "Music")
	end

	-- history (session only): the digit-only ids you have played, and where you are in it
	local history, historyPos = {}, 0
	local function refreshHistoryLabel()
		histLbl.Text = (#history == 0) and "No track played yet" or ("Track " .. historyPos .. " / " .. #history)
	end

	local function setId(digits, fromHistory)
		Settings.MusicId = digits
		idBox.Text = digits
		setSetting("Music", true)
		if not fromHistory then
			if history[historyPos] ~= digits then
				for i = #history, historyPos + 1, -1 do history[i] = nil end
				historyPos += 1
				history[historyPos] = digits
			end
		end
		refreshHistoryLabel()
	end

	playBtn.Activated:Connect(function()
		local digits = idBox.Text:match("%d+")
		if digits then setId(digits) end
	end)
	for _, p in ipairs(presetBtns) do
		p.btn.Activated:Connect(function() setId(p.id) end)
	end
	idBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			local digits = idBox.Text:match("%d+")
			if digits then setId(digits) end
		end
	end)
	backBtn.Activated:Connect(function()
		if historyPos > 1 then
			historyPos -= 1
			setId(history[historyPos], true)
		end
	end)
	fwdBtn.Activated:Connect(function()
		if historyPos < #history then
			historyPos += 1
			setId(history[historyPos], true)
		end
	end)

	--// playback engine
	local sound, appliedId, startedAt
	local function say(text)
		if statusLbl.Text ~= text then statusLbl.Text = text end
	end
	local function stopSound()
		if sound then
			sound:Stop()
			sound:Destroy()
			sound = nil
		end
		appliedId = nil
	end
	task.spawn(function()
		while true do
			if Settings.Music then
				local digits = tostring(Settings.MusicId or ""):match("%d+")
				if not digits then
					say("Type a song ID at the bottom first.")
					stopSound()
				else
					local id = "rbxassetid://" .. digits
					if not sound or not sound.Parent then
						sound = Instance.new("Sound")
						sound.Name = "AA_Music"
						sound.Parent = SoundService
						sound.Ended:Connect(function()
							if Settings.Music and not Settings.MusicLoop then setSetting("Music", false) end
						end)
						appliedId = nil
					end
					if appliedId ~= id then
						sound:Stop()
						sound.SoundId = id
						appliedId = id
						startedAt = os.clock()
						sound:Play()
					end
					sound.Volume = Settings.MusicVolume
					sound.Looped = Settings.MusicLoop
					if sound.IsPlaying then
						say("Playing: " .. digits)
					elseif sound.IsLoaded and sound.TimeLength > 0 then
						say("Loaded, starting...")
						sound:Play()
					elseif os.clock() - startedAt > 8 then
						say("Could not play this ID (wrong, private or removed audio).")
					else
						say("Loading...")
					end
				end
			else
				if sound then say("Music is off.") end
				stopSound()
			end
			task.wait(0.3)
		end
	end)
end

--// ===== 2 MORE FUNCTIONS: Box ESP, Low Health Warning =====
do
	local vis = pageCols["Visuals"]

	--// Box ESP: a billboard frame around every player, in his team color, also through walls
	local boxes = {}
	local function removeBox(plr)
		local b = boxes[plr]
		if b then
			b:Destroy()
			boxes[plr] = nil
		end
	end
	Players.PlayerRemoving:Connect(removeBox)
	task.spawn(function()
		while true do
			if Settings.BoxESP2 then
				for _, plr in ipairs(Players:GetPlayers()) do
					if plr ~= player then
						local char = plr.Character
						local root = char and char:FindFirstChild("HumanoidRootPart")
						local hum = char and char:FindFirstChildOfClass("Humanoid")
						if root and hum and hum.Health > 0 then
							local b = boxes[plr]
							if not b or not b.Parent or b.Adornee ~= root then
								removeBox(plr)
								b = Instance.new("BillboardGui")
								b.Name = "AA_Box2"
								b.Adornee = root
								b.AlwaysOnTop = true
								b.LightInfluence = 0
								b.ResetOnSpawn = false
								b.Size = UDim2.fromScale(4, 6.2) -- scale on a billboard is in studs
								b.Parent = gui.Parent
								local f = Instance.new("Frame")
								f.Size = UDim2.fromScale(1, 1)
								f.BackgroundTransparency = 1
								f.BorderSizePixel = 0
								f.Parent = b
								Instance.new("UIStroke", f).Thickness = 2
								boxes[plr] = b
							end
							local col = teamColorOf(plr)
							local f = b:FindFirstChildOfClass("Frame")
							f:FindFirstChildOfClass("UIStroke").Color = col
						else
							removeBox(plr)
						end
					end
				end
			elseif next(boxes) ~= nil then
				for plr in pairs(boxes) do removeBox(plr) end
			end
			task.wait(0.1)
		end
	end)
	local c = newCard(vis[1], "Box ESP", "BoxESP2")
	makeNote(c, "A box around every player in his team color, also through walls.")

	--// Low Health Warning: the screen pulses red once your own health drops below the threshold
	local overlay = Instance.new("Frame")
	overlay.Name = "AA_LowHealth"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(200, 20, 20)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.Active = false
	overlay.Visible = false
	overlay.Parent = gui
	do
		local g = Instance.new("UIGradient", overlay)
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(1, 0.55),
		})
	end
	task.spawn(function()
		local phase = 0
		while true do
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local low = Settings.LowHealth and hum and hum.Health > 0 and hum.Health <= Settings.LowHealthThreshold
			if low then
				overlay.Visible = true
				phase += 0.18
				overlay.BackgroundTransparency = 0.72 + 0.2 * math.sin(phase * math.pi * 2)
			else
				phase = 0
				if overlay.Visible then
					overlay.Visible = false
				end
			end
			task.wait(0.05)
		end
	end)
	c = newCard(vis[2], "Low Health Warning", "LowHealth")
	makeNote(c, "The screen pulses red once your health drops below the threshold.")
	makeSlider(c, "Threshold", 5, 80, "LowHealthThreshold", 0)
end

--// ===== RECODE (tab): Xadesa Mod =====
-- Makes you taller, and puts you in a white hoodie with black shoulder stripes, wide black
-- pants, and a black backpack. An original look built from plain shapes, not a copy of a real
-- outfit's texture. Only you see it on your own character; other players see your normal avatar.
do
	local function V(x, y, z) return Vector3.new(x, y, z) end
	local function C(r, g, b) return Color3.fromRGB(r, g, b) end
	local WHITE_TOP, BLACK = C(248, 248, 250), C(18, 18, 20)

	local cols = newPage("Recode")
	local c = newCard(cols[1], "Xadesa Mod", "XadesaMod")
	makeNote(c, "Taller, white hoodie with black shoulder stripes, wide black pants, white sneakers, black backpack.")
	makeSlider(c, "Height", 1.0, 1.5, "XadesaHeight", 2)

	-- one overlay spec per body part: offset is in that part's own local space
	-- (x = its right, y = up, z = its back) ; sizeMul scales relative to the part's own size
	local SPEC = {
		{ part = { "UpperTorso", "Torso" }, offset = V(0, 0, 0), sizeMul = V(1.18, 1.12, 1.3), color = WHITE_TOP, mat = "Fabric" },
		{ part = { "LeftUpperArm", "Left Arm" }, offset = V(0, 0.05, 0), sizeMul = V(1.22, 1.08, 1.22), color = WHITE_TOP, mat = "Fabric" },
		{ part = { "RightUpperArm", "Right Arm" }, offset = V(0, 0.05, 0), sizeMul = V(1.22, 1.08, 1.22), color = WHITE_TOP, mat = "Fabric" },
		-- shoulder arrow stripes (two short bars meeting at a point), one on each arm
		{ part = { "LeftUpperArm", "Left Arm" }, offset = V(0, 0.33, 0.02), size = V(0.5, 0.1, 0.1), rot = V(0, 0, 35), color = BLACK, mat = "Fabric" },
		{ part = { "LeftUpperArm", "Left Arm" }, offset = V(0.12, 0.2, 0.02), size = V(0.5, 0.1, 0.1), rot = V(0, 0, -35), color = BLACK, mat = "Fabric" },
		{ part = { "RightUpperArm", "Right Arm" }, offset = V(0, 0.33, 0.02), size = V(0.5, 0.1, 0.1), rot = V(0, 0, -35), color = BLACK, mat = "Fabric" },
		{ part = { "RightUpperArm", "Right Arm" }, offset = V(-0.12, 0.2, 0.02), size = V(0.5, 0.1, 0.1), rot = V(0, 0, 35), color = BLACK, mat = "Fabric" },
		-- wide black pants (upper legs always; lower legs only on R15, for a baggier look down to the ankle)
		{ part = { "LeftUpperLeg", "Left Leg" }, offset = V(0, 0, 0), sizeMul = V(1.45, 1.05, 1.3), color = BLACK, mat = "Fabric" },
		{ part = { "RightUpperLeg", "Right Leg" }, offset = V(0, 0, 0), sizeMul = V(1.45, 1.05, 1.3), color = BLACK, mat = "Fabric" },
		{ part = { "LeftLowerLeg" }, offset = V(0, 0.1, 0), sizeMul = V(1.4, 1.1, 1.25), color = BLACK, mat = "Fabric" },
		{ part = { "RightLowerLeg" }, offset = V(0, 0.1, 0), sizeMul = V(1.4, 1.1, 1.25), color = BLACK, mat = "Fabric" },
		-- sneakers: white body with a black sole (R15 feet; R6 falls back to the bottom of the leg)
		{ part = { "LeftFoot" }, offset = V(0, 0, -0.05), size = V(1.3, 0.55, 1.55), color = WHITE_TOP, mat = "Fabric" },
		{ part = { "LeftFoot" }, offset = V(0, -0.22, -0.05), size = V(1.32, 0.16, 1.57), color = BLACK, mat = "SmoothPlastic" },
		{ part = { "RightFoot" }, offset = V(0, 0, -0.05), size = V(1.3, 0.55, 1.55), color = WHITE_TOP, mat = "Fabric" },
		{ part = { "RightFoot" }, offset = V(0, -0.22, -0.05), size = V(1.32, 0.16, 1.57), color = BLACK, mat = "SmoothPlastic" },
		{ part = { "Left Leg" }, offset = V(0, -0.85, -0.05), size = V(1.05, 0.55, 1.3), color = WHITE_TOP, mat = "Fabric" },
		{ part = { "Left Leg" }, offset = V(0, -1.05, -0.05), size = V(1.07, 0.16, 1.32), color = BLACK, mat = "SmoothPlastic" },
		{ part = { "Right Leg" }, offset = V(0, -0.85, -0.05), size = V(1.05, 0.55, 1.3), color = WHITE_TOP, mat = "Fabric" },
		{ part = { "Right Leg" }, offset = V(0, -1.05, -0.05), size = V(1.07, 0.16, 1.32), color = BLACK, mat = "SmoothPlastic" },
		-- backpack: main body + flap + two straps over the shoulders
		{ part = { "UpperTorso", "Torso" }, offset = V(0, 0.05, 0.62), size = V(1.3, 1.5, 0.55), color = BLACK, mat = "Fabric" },
		{ part = { "UpperTorso", "Torso" }, offset = V(0, -0.3, 0.92), size = V(1.0, 0.6, 0.18), color = C(30, 30, 33), mat = "Fabric" },
		{ part = { "UpperTorso", "Torso" }, offset = V(-0.42, 0.55, 0.3), size = V(0.22, 1.2, 0.1), rot = V(10, 0, 0), color = BLACK, mat = "Fabric" },
		{ part = { "UpperTorso", "Torso" }, offset = V(0.42, 0.55, 0.3), size = V(0.22, 1.2, 0.1), rot = V(10, 0, 0), color = BLACK, mat = "Fabric" },
	}

	local folder, built, builtChar
	local parts, cfs = {}, {}
	local heightSaved = setmetatable({}, { __mode = "k" }) -- Humanoid -> original BodyHeightScale value
	local hipSaved = setmetatable({}, { __mode = "k" }) -- Humanoid -> original HipHeight

	local function clearAll()
		if folder then folder:Destroy() end
		folder, built = nil, nil
	end

	local function build(char)
		clearAll()
		local cam = workspace.CurrentCamera
		if not cam then return end
		folder = Instance.new("Folder")
		folder.Name = "AA_Xadesa"
		folder.Parent = cam
		built = {}
		for _, spec in ipairs(SPEC) do
			local host
			for _, name in ipairs(spec.part) do
				host = char:FindFirstChild(name)
				if host and host:IsA("BasePart") then break end
				host = nil
			end
			if host then
				local p = Instance.new("Part")
				p.Anchored = true
				p.CanCollide = false
				p.CanQuery = false
				p.CanTouch = false
				p.CastShadow = false
				local okMat, mat = pcall(function() return Enum.Material[spec.mat] end)
				p.Material = okMat and mat or Enum.Material.SmoothPlastic
				p.Color = spec.color
				p.Size = spec.size or (host.Size * spec.sizeMul)
				p.Parent = folder
				built[#built + 1] = { part = p, host = host, offset = spec.offset, rot = spec.rot }
			end
		end
	end

	RunService:BindToRenderStep("AA_Xadesa", Enum.RenderPriority.Last.Value + 2, function()
		local char = player.Character
		local on = Settings.XadesaMod

		-- height: a few R15 avatars expose separate scale axes; only the height one is changed
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local heightVal = hum and hum:FindFirstChild("BodyHeightScale")
		if on and heightVal then
			if heightSaved[hum] == nil then heightSaved[hum] = heightVal.Value end
			local want = heightSaved[hum] * Settings.XadesaHeight
			if math.abs(heightVal.Value - want) > 0.001 then heightVal.Value = want end
		elseif not on then
			for h, original in pairs(heightSaved) do
				local hv = h.Parent and h:FindFirstChild("BodyHeightScale")
				if hv then hv.Value = original end
				heightSaved[h] = nil
			end
		end

		-- no scalable rig (R6 etc.): raise the character a little via HipHeight instead.
		-- On R15 the height scale already adjusts HipHeight by itself, so it is left alone there.
		if on and hum and not heightVal then
			if hipSaved[hum] == nil then hipSaved[hum] = hum.HipHeight end
			local wantHip = hipSaved[hum] + (Settings.XadesaHeight - 1) * 2
			if math.abs(hum.HipHeight - wantHip) > 0.01 then hum.HipHeight = wantHip end
		elseif not on then
			for h, original in pairs(hipSaved) do
				if h.Parent then h.HipHeight = original end
				hipSaved[h] = nil
			end
		end

		if not on or not char then
			if folder then clearAll() end
			return
		end
		if char ~= builtChar or not built or not folder or not folder.Parent then
			builtChar = char
			build(char)
		end
		if not built then return end

		local cam = workspace.CurrentCamera
		local fp = false
		if cam then
			local head = char:FindFirstChild("Head")
			fp = head ~= nil and (cam.CFrame.Position - head.Position).Magnitude < 1.4
		end
		local hide = fp and 1 or 0
		table.clear(parts)
		table.clear(cfs)
		for i, it in ipairs(built) do
			if it.part.Parent and it.host.Parent then
				if it.part.LocalTransparencyModifier ~= hide then it.part.LocalTransparencyModifier = hide end
				local turn = it.rot and CFrame.Angles(math.rad(it.rot.X), math.rad(it.rot.Y), math.rad(it.rot.Z)) or CFrame.new()
				parts[i] = it.part
				cfs[i] = it.host.CFrame * CFrame.new(it.offset) * turn
			end
		end
		if #parts > 0 then workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged) end
	end)
end

--// ===== RECODE (tab): Fling + Anti Fling =====
-- Fling: your body hits other players with a huge one-frame velocity and is put back before it
-- is drawn, so you stay in place while whoever touches you is thrown. Anti Fling: other players'
-- bodies stop colliding with you, and any absurd spin/speed you pick up is cancelled.
do
	local cols = pageCols["Recode"]

	local function ownRoot()
		local char = player.Character
		return char and char:FindFirstChild("HumanoidRootPart")
	end

	local c = newCard(cols[2], "Fling", "Fling")
	makeNote(c, "Touch someone to throw them away. Works best while standing close to them.")
	makeSlider(c, "Power", 1000, 100000, "FlingPower", 0)

	local c2 = newCard(cols[3], "Anti Fling", "AntiFling")
	makeNote(c2, "Other players cannot push you, and wild spin/speed is cancelled.")

	task.spawn(function()
		local movel = 0.1
		while true do
			RunService.Heartbeat:Wait()
			if Settings.Fling then
				local root = ownRoot()
				if root and root.Parent then
					local vel, ang = root.AssemblyLinearVelocity, root.AssemblyAngularVelocity
					local power = Settings.FlingPower
					root.AssemblyLinearVelocity = vel * power + Vector3.new(0, power, 0)
					root.AssemblyAngularVelocity = Vector3.new(0, power, 0)
					RunService.RenderStepped:Wait()
					if root.Parent then
						root.AssemblyLinearVelocity = vel
						root.AssemblyAngularVelocity = ang
					end
					RunService.Stepped:Wait()
					if root.Parent then root.AssemblyLinearVelocity = vel + Vector3.new(0, movel, 0) end
					movel = -movel
				end
			end
		end
	end)

	local changed = setmetatable({}, { __mode = "k" }) -- parts whose collision this feature turned off
	RunService.Stepped:Connect(function()
		if Settings.AntiFling then
			for _, plr in ipairs(Players:GetPlayers()) do
				local char = plr ~= player and plr.Character
				if char then
					for _, part in ipairs(char:GetDescendants()) do
						if part:IsA("BasePart") and part.CanCollide then
							part.CanCollide = false
							changed[part] = true
						end
					end
				end
			end
			if not Settings.Fling then
				local root = ownRoot()
				if root then
					if root.AssemblyAngularVelocity.Magnitude > 60 then root.AssemblyAngularVelocity = Vector3.zero end
					if root.AssemblyLinearVelocity.Magnitude > 500 then root.AssemblyLinearVelocity = Vector3.zero end
				end
			end
		elseif next(changed) ~= nil then
			for part in pairs(changed) do
				if part.Parent then part.CanCollide = true end
				changed[part] = nil
			end
		end
	end)
end

--// ===== RECODE (tab): Afterimage + Rewind =====
-- Afterimage: glowing copies of your body stay behind you and fade out while you move.
-- Rewind: hold R (or the on-screen REWIND button) and you run backwards through the last
-- seconds of your own movement, with a blue time-reverse screen effect.
do
	local cols = pageCols["Recode"]
	local Lighting = game:GetService("Lighting")

	--// ---------- Afterimage ----------
	local c1 = newCard(cols[3], "Afterimage", "Afterimage")
	makeNote(c1, "Leaves fading glowing copies of your body behind you while you move (hidden in first person).")
	makeDropdown(c1, "Color", "AfterimageColor", { "Theme", "Rainbow", "Ice", "Fire" })
	makeSlider(c1, "Fade time", 0.2, 1.5, "AfterimageLife", 1)

	local ghostFolder
	local ghosts = {} -- { parts =, born =, life = }

	local function ghostColor()
		local mode = Settings.AfterimageColor
		if mode == "Rainbow" then return Color3.fromHSV((os.clock() * 0.6) % 1, 0.75, 1) end
		if mode == "Ice" then return Color3.fromRGB(120, 220, 255) end
		if mode == "Fire" then return Color3.fromRGB(255, 130, 35):Lerp(Color3.fromRGB(255, 210, 70), math.random()) end
		return THEME.accent
	end

	local function spawnGhost(char)
		local cam = workspace.CurrentCamera
		if not cam then return end
		if not ghostFolder or not ghostFolder.Parent then
			ghostFolder = Instance.new("Folder")
			ghostFolder.Name = "AA_Afterimage"
			ghostFolder.Parent = cam
		end
		local color = ghostColor()
		local list = {}
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Transparency < 0.95 then
				local ok, clone = pcall(function() return part:Clone() end)
				if ok and clone then
					for _, child in ipairs(clone:GetChildren()) do
						if not child:IsA("DataModelMesh") then child:Destroy() end
					end
					clone.Anchored = true
					clone.CanCollide = false
					clone.CanQuery = false
					clone.CanTouch = false
					clone.CastShadow = false
					pcall(function() clone.TextureID = "" end)
					clone.Material = Enum.Material.Neon
					clone.Color = color
					clone.Transparency = 0.35
					clone.CFrame = part.CFrame
					clone.Parent = ghostFolder
					list[#list + 1] = clone
				end
			end
		end
		ghosts[#ghosts + 1] = { parts = list, born = os.clock(), life = Settings.AfterimageLife }
		while #ghosts > 16 do
			for _, p in ipairs(ghosts[1].parts) do p:Destroy() end
			table.remove(ghosts, 1)
		end
	end

	local ghostAcc = 0
	RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		for i = #ghosts, 1, -1 do
			local g = ghosts[i]
			local a = (now - g.born) / g.life
			if a >= 1 then
				for _, p in ipairs(g.parts) do p:Destroy() end
				table.remove(ghosts, i)
			else
				local t = 0.35 + 0.65 * a
				for _, p in ipairs(g.parts) do p.Transparency = t end
			end
		end
		if not Settings.Afterimage then return end
		ghostAcc += dt
		if ghostAcc < 0.06 then return end
		ghostAcc = 0
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local cam = workspace.CurrentCamera
		if root and cam and root.AssemblyLinearVelocity.Magnitude > 4
			and (cam.CFrame.Position - root.Position).Magnitude > 3 then
			spawnGhost(char)
		end
	end)

	--// ---------- Rewind ----------
	local c2 = newCard(cols[1], "Rewind", "Rewind")
	makeNote(c2, "Hold R (or the REWIND button) to run backwards through your last seconds of movement.")
	makeSlider(c2, "Memory (s)", 2, 15, "RewindSeconds", 0)

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "AA_Rewind"
	cc.Enabled = false
	cc.Parent = Lighting

	local rewinding = false
	local function setRewinding(on)
		if rewinding == on then return end
		rewinding = on
		if on then
			cc.Enabled = true
			TweenService:Create(cc, TweenInfo.new(0.2), {
				Saturation = -0.7, Contrast = 0.15, TintColor = Color3.fromRGB(140, 190, 255),
			}):Play()
		else
			local t = TweenService:Create(cc, TweenInfo.new(0.25), {
				Saturation = 0, Contrast = 0, TintColor = Color3.new(1, 1, 1),
			})
			t.Completed:Connect(function()
				if not rewinding then cc.Enabled = false end
			end)
			t:Play()
		end
	end

	-- on-screen hold button (shown while Rewind is switched on)
	local btn = Instance.new("TextButton")
	btn.Name = "AA_RewindButton"
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.Position = UDim2.new(1, -20, 0.62, 0)
	btn.Size = UDim2.fromOffset(78, 78)
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.Text = "REWIND"
	btn.Visible = false
	btn.Parent = gui
	Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
	themeBind(btn, "BackgroundColor3", "accent")
	themeBind(btn, "TextColor3", "onAccent")

	local keyHeld, btnHeld, btnInput = false, false, nil
	btn.InputBegan:Connect(function(i)
		if isPress(i) then
			btnHeld, btnInput = true, i
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i == btnInput then btnHeld, btnInput = false, nil end
		if i.KeyCode == Enum.KeyCode.R then keyHeld = false end
	end)
	UserInputService.InputBegan:Connect(function(i, processed)
		if not processed and i.KeyCode == Enum.KeyCode.R and Settings.Rewind then keyHeld = true end
	end)

	local buf, recAcc, popAcc = {}, 0, 0
	RunService.Heartbeat:Connect(function(dt)
		btn.Visible = Settings.Rewind and true or false
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not root or not hum or hum.Health <= 0 then
			table.clear(buf)
			setRewinding(false)
			return
		end
		if not Settings.Rewind or hum.SeatPart then
			setRewinding(false)
			return
		end
		if (keyHeld or btnHeld) and #buf > 0 then
			setRewinding(true)
			popAcc += dt * 60 -- samples are 1/30 s apart, so this plays back at 2x speed
			local n = math.floor(popAcc)
			popAcc -= n
			local cf
			for _ = 1, math.min(n, #buf) do cf = table.remove(buf) end
			if cf then
				root.CFrame = cf
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end
		else
			setRewinding(false)
			recAcc += dt
			if recAcc >= 1 / 30 then
				recAcc = 0
				buf[#buf + 1] = root.CFrame
				local maxN = Settings.RewindSeconds * 30
				while #buf > maxN do table.remove(buf, 1) end
			end
		end
	end)
end

--// ===== FAST RELOAD =====
-- Same approach as No Recoil, for reload data:
--  1) NumberValue / IntValue / attributes on your tools whose name contains "reload",
--  2) fields of the tables returned by ModuleScripts inside your tools,
--  3) weapon config tables found in memory (needs getgc),
--  4) reload animations (tracks with "reload" in the name) are played faster.
-- Names that look like times are divided by the speed, names that look like speeds are
-- multiplied; names about ammo / magazine size are left alone. If the server times the
-- reload, nothing on your side can change that (check the Game Report in the Misc tab).
do
	local SKIP = { "ammo", "mag", "clip", "count", "amount", "capacity", "max", "round", "bullet" }
	local SPEEDISH = { "speed", "rate", "mult" }
	local KEYS = {
		"ReloadTime", "reloadTime", "ReloadDuration", "ReloadDelay", "ReloadLength", "ReloadCooldown",
		"ReloadSpeed", "reloadSpeed", "ReloadRate", "TimeToReload", "reload_time", "Reload_Time",
	}
	local saved = {} -- { kind = "value" / "attr" / "key", obj/tbl, name, original }

	local function classify(name, ctx)
		local l = tostring(name):lower()
		if not ctx and not l:find("reload", 1, true) then return nil end
		for _, w in ipairs(SKIP) do
			if l:find(w, 1, true) then return nil end
		end
		for _, w in ipairs(SPEEDISH) do
			if l:find(w, 1, true) then return "speed" end
		end
		return "time"
	end

	local function faster(kind, v)
		local m = Settings.FastReloadMult
		if kind == "speed" then return v * m end
		return math.min(v, math.max(0.03, v / m))
	end

	local function setKey(tbl, key, kind0)
		local ok, cur = pcall(function() return tbl[key] end)
		if not ok or type(cur) ~= "number" or cur <= 0 then return end
		local kind = kind0 or classify(key)
		if not kind then return end
		if pcall(function() tbl[key] = faster(kind, cur) end) then
			saved[#saved + 1] = { kind = "key", tbl = tbl, name = key, original = cur }
		end
	end

	local function scanTable(tbl, depth, seen, ctx)
		if seen[tbl] or depth > 4 then return end
		seen[tbl] = true
		local keys = {}
		if not pcall(function() for k in pairs(tbl) do keys[#keys + 1] = k end end) then return end
		for _, k in ipairs(keys) do
			local okv, v = pcall(function() return tbl[k] end)
			if okv then
				if type(v) == "number" and type(k) == "string" then
					local kind = classify(k, ctx)
					if kind then setKey(tbl, k, kind) end
				elseif type(v) == "table" then
					local inReload = ctx or (type(k) == "string" and k:lower():find("reload", 1, true) ~= nil)
					scanTable(v, depth + 1, seen, inReload)
				end
			end
		end
	end

	local function scanTool(tool)
		for _, d in ipairs(tool:GetDescendants()) do
			if (d:IsA("NumberValue") or d:IsA("IntValue")) and d.Value > 0 then
				local kind = classify(d.Name)
					or (d.Parent and d.Parent.Name:lower():find("reload", 1, true) and classify(d.Name, true))
				if kind then
					saved[#saved + 1] = { kind = "value", obj = d, original = d.Value }
					d.Value = faster(kind, d.Value)
				end
			elseif d:IsA("ModuleScript") then
				local ok, result = pcall(require, d)
				if ok and type(result) == "table" then scanTable(result, 1, {}) end
			end
		end
		for _, inst in ipairs({ tool, table.unpack(tool:GetDescendants()) }) do
			local okA, attrs = pcall(function() return inst:GetAttributes() end)
			if okA then
				for name, v in pairs(attrs) do
					local kind = type(v) == "number" and v > 0 and classify(name)
					if kind then
						saved[#saved + 1] = { kind = "attr", obj = inst, name = name, original = v }
						inst:SetAttribute(name, faster(kind, v))
					end
				end
			end
		end
	end

	local function scanMemory()
		if not getgc then return end
		local ok, all = pcall(getgc, true)
		if not ok then return end
		local n = 0
		for _, t in ipairs(all) do
			if type(t) == "table" then
				for _, key in ipairs(KEYS) do
					local okv, v = pcall(rawget, t, key)
					if okv and v ~= nil then setKey(t, key) end
				end
				for _, key in ipairs({ "Reload", "reload" }) do -- Reload = { Time = 2, ... } or Reload = 2
					local okv, v = pcall(rawget, t, key)
					if okv and type(v) == "table" then scanTable(v, 1, {}, true)
					elseif okv and type(v) == "number" then setKey(t, key, "time") end
				end
			end
			n += 1
			if n % 3000 == 0 then task.wait() end
		end
	end

	local function restore()
		for i = #saved, 1, -1 do
			local e = saved[i]
			if e.kind == "value" then
				if e.obj.Parent then e.obj.Value = e.original end
			elseif e.kind == "attr" then
				if e.obj.Parent then e.obj:SetAttribute(e.name, e.original) end
			else
				pcall(function() e.tbl[e.name] = e.original end)
			end
			saved[i] = nil
		end
	end

	local function apply()
		restore() -- start clean, so nothing is saved twice
		local tools = {}
		local pack = player:FindFirstChildOfClass("Backpack")
		if pack then for _, t in ipairs(pack:GetChildren()) do tools[#tools + 1] = t end end
		if player.Character then for _, t in ipairs(player.Character:GetChildren()) do tools[#tools + 1] = t end end
		for _, t in ipairs(tools) do
			if t:IsA("Tool") then pcall(scanTool, t) end
		end
		scanMemory()
	end

	task.spawn(function()
		local lastTool, lastAt, lastMult = nil, 0, nil
		while true do
			if Settings.FastReload then
				local char = player.Character
				local tool = char and char:FindFirstChildOfClass("Tool")
				if tool ~= lastTool or lastMult ~= Settings.FastReloadMult or os.clock() - lastAt > 8 then
					lastTool, lastAt, lastMult = tool, os.clock(), Settings.FastReloadMult
					apply()
				end
			elseif #saved > 0 then
				restore()
				lastTool, lastMult = nil, nil
			end
			task.wait(0.5)
		end
	end)

	-- reload animations: your character's and the first-person arms that many games keep in the camera
	local function speedTracks(animator)
		for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do
			local an = tr.Animation and tr.Animation.Name or ""
			if tr.Name:lower():find("reload", 1, true) or an:lower():find("reload", 1, true) then
				if tr.Speed ~= Settings.FastReloadMult then tr:AdjustSpeed(Settings.FastReloadMult) end
			end
		end
	end
	task.spawn(function()
		while true do
			if Settings.FastReload then
				local char = player.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				local animator = hum and hum:FindFirstChildOfClass("Animator")
				if animator then pcall(speedTracks, animator) end
				local cam = workspace.CurrentCamera
				if cam then
					for _, d in ipairs(cam:GetDescendants()) do
						if d:IsA("Animator") then pcall(speedTracks, d) end
					end
				end
			end
			task.wait(0.1)
		end
	end)
end

--// ===== RELOAD REPORT (Combat tab) =====
-- Lists what the weapon in your hand keeps in data (values, attributes, module tables, tables in
-- memory) and which animations are playing, so Fast Reload can be fitted to the game.
do
	local cols = pageCols["Combat"]
	local WORDS = { "reload", "ammo", "mag", "clip", "time", "delay", "cooldown", "wait", "speed", "rate", "fire", "round" }
	local GC_KEYS = {
		"ReloadTime", "reloadTime", "Reload", "reload", "ReloadSpeed", "ReloadDuration",
		"Ammo", "MaxAmmo", "Magazine", "MagSize", "ClipSize", "MaxMagazine",
	}

	local function interesting(name)
		local l = tostring(name):lower()
		for _, w in ipairs(WORDS) do
			if l:find(w, 1, true) then return true end
		end
		return false
	end

	local function dumpTable(tbl, path, depth, seen, out, budget)
		if seen[tbl] or depth > 3 then return end
		seen[tbl] = true
		local keys = {}
		if not pcall(function() for k in pairs(tbl) do keys[#keys + 1] = k end end) then return end
		table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
		for _, k in ipairs(keys) do
			if budget.n <= 0 then return end
			local okv, v = pcall(function() return tbl[k] end)
			if okv then
				local tv = type(v)
				if tv == "table" then
					dumpTable(v, path .. "." .. tostring(k), depth + 1, seen, out, budget)
				elseif (tv == "number" or tv == "boolean" or tv == "string") and interesting(k) then
					out[#out + 1] = "  " .. path .. "." .. tostring(k) .. " = " .. tostring(v)
					budget.n -= 1
				end
			end
		end
	end

	local function trackLine(tr, where)
		local an = tr.Animation and tr.Animation.Name or "?"
		return string.format("  [%s] track %s (anim %s) length=%.2f speed=%.2f playing=%s",
			where, tr.Name, an, tr.Length, tr.Speed, tostring(tr.IsPlaying))
	end

	local function build()
		local out = {}
		out[#out + 1] = "Place " .. game.PlaceId .. " / " .. game.Name
		local char = player.Character
		local tool = char and char:FindFirstChildOfClass("Tool")
		if not tool then
			out[#out + 1] = "No tool in hand: take the weapon in your hand and press the button again."
		else
			out[#out + 1] = "TOOL " .. tool:GetFullName()
			local budget = { n = 70 }
			local scripts = {}
			for _, d in ipairs(tool:GetDescendants()) do
				if d:IsA("ValueBase") and budget.n > 0 then
					local okv, v = pcall(function() return d.Value end)
					out[#out + 1] = "  value " .. d.Name .. " (" .. d.ClassName .. ") = " .. tostring(okv and v or "?")
					budget.n -= 1
				elseif d:IsA("LuaSourceContainer") and #scripts < 20 then
					scripts[#scripts + 1] = d.Name .. "(" .. d.ClassName .. ")"
				end
			end
			out[#out + 1] = "  scripts: " .. table.concat(scripts, ", ")
			for _, inst in ipairs({ tool, table.unpack(tool:GetDescendants()) }) do
				local okA, attrs = pcall(function() return inst:GetAttributes() end)
				if okA then
					for name, v in pairs(attrs) do
						local tv = type(v)
						if budget.n > 0 and (tv == "number" or tv == "boolean" or tv == "string") then
							out[#out + 1] = "  attr " .. inst.Name .. "." .. name .. " = " .. tostring(v)
							budget.n -= 1
						end
					end
				end
			end
			for _, d in ipairs(tool:GetDescendants()) do
				if d:IsA("ModuleScript") then
					out[#out + 1] = "  module " .. d.Name
					local ok, result = pcall(require, d)
					if ok and type(result) == "table" then
						dumpTable(result, d.Name, 1, {}, out, { n = 40 })
					else
						out[#out + 1] = "    (could not be required)"
					end
				end
			end
		end

		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local animator = hum and hum:FindFirstChildOfClass("Animator")
		if animator then
			for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do out[#out + 1] = trackLine(tr, "character") end
		end
		local cam = workspace.CurrentCamera
		if cam then
			for _, d in ipairs(cam:GetDescendants()) do
				if d:IsA("Animator") then
					for _, tr in ipairs(d:GetPlayingAnimationTracks()) do out[#out + 1] = trackLine(tr, "camera") end
				end
			end
		end

		if getgc then
			local ok, all = pcall(getgc, true)
			if ok then
				local found, n = 0, 0
				for _, t in ipairs(all) do
					if found >= 6 then break end
					if type(t) == "table" then
						local hit = false
						for _, key in ipairs(GC_KEYS) do
							local okv, v = pcall(rawget, t, key)
							if okv and v ~= nil then hit = true break end
						end
						if hit then
							found += 1
							out[#out + 1] = "MEMORY TABLE #" .. found
							dumpTable(t, "t" .. found, 1, {}, out, { n = 25 })
						end
					end
					n += 1
					if n % 3000 == 0 then task.wait() end
				end
			end
		end
		return table.concat(out, "\n")
	end

	local c = newCard(cols[1], "Reload Report")
	makeNote(c, "Take the weapon in your hand, reload once, press the button and send the text. It shows where this game keeps its reload.")
	local btn = makeAction(c, "Create reload report")
	local box = makeTextBox(c, "the report appears here")
	box.MultiLine = true
	box.TextWrapped = true
	box.TextYAlignment = Enum.TextYAlignment.Top
	box.Size = UDim2.new(1, 0, 0, 110)
	btn.Activated:Connect(function()
		btn.Text = "Working..."
		local ok, text = pcall(build)
		box.Text = ok and text or ("Report failed: " .. tostring(text))
		if ok and setclipboard then
			pcall(setclipboard, text)
			btn.Text = "Copied to clipboard"
		else
			btn.Text = "Create reload report"
		end
	end)
end

--// ===== RECODE (tab): Grapple Hook =====
-- Hold G (or the GRAPPLE button): a glowing rope shoots to where you aim and pulls you to it.
-- Let go and you keep your speed. Only moves your own character, like Fly or Speed.
do
	local cols = pageCols["Recode"]
	local c = newCard(cols[2], "Grapple Hook", "Grapple")
	makeNote(c, "Hold G or the GRAPPLE button: a rope shoots to where you aim and pulls you there.")
	makeSlider(c, "Pull speed", 30, 200, "GrappleSpeed", 0)

	local MAX_RANGE = 300
	local folder, rope, tip
	local anchor -- world point the rope is stuck to, nil when not grappling

	local function ensureVisuals()
		local cam = workspace.CurrentCamera
		if not cam then return false end
		if not folder or not folder.Parent then
			folder = Instance.new("Folder")
			folder.Name = "AA_Grapple"
			folder.Parent = cam
			rope = Instance.new("Part")
			rope.Anchored = true
			rope.CanCollide = false
			rope.CanQuery = false
			rope.CanTouch = false
			rope.CastShadow = false
			rope.Material = Enum.Material.Neon
			rope.Size = Vector3.new(0.14, 0.14, 1)
			rope.Parent = folder
			tip = Instance.new("Part")
			tip.Shape = Enum.PartType.Ball
			tip.Anchored = true
			tip.CanCollide = false
			tip.CanQuery = false
			tip.CanTouch = false
			tip.CastShadow = false
			tip.Material = Enum.Material.Neon
			tip.Size = Vector3.new(0.7, 0.7, 0.7)
			tip.Parent = folder
		end
		return true
	end

	local function release()
		anchor = nil
		if folder then
			folder:Destroy()
			folder = nil
		end
	end

	local function fire(useScreenCenter)
		local char = player.Character
		local cam = workspace.CurrentCamera
		if not char or not cam then return end
		local pos
		if useScreenCenter then
			local vp = cam.ViewportSize
			pos = Vector2.new(vp.X / 2, vp.Y / 2)
		else
			pos = UserInputService:GetMouseLocation()
		end
		local ray = cam:ViewportPointToRay(pos.X, pos.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { char, folder }
		local hit = workspace:Raycast(ray.Origin, ray.Direction * MAX_RANGE, params)
		if hit then anchor = hit.Position end
	end

	-- input: G on PC, hold button on phones
	local held, heldInput = false, nil
	local function start(useCenter)
		if not Settings.Grapple or held then return end
		held = true
		fire(useCenter)
	end
	local function stop()
		held, heldInput = false, nil
		release()
	end

	local btn = Instance.new("TextButton")
	btn.Name = "AA_GrappleButton"
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.Position = UDim2.new(1, -108, 0.62, 0)
	btn.Size = UDim2.fromOffset(78, 78)
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.Text = "GRAPPLE"
	btn.Visible = false
	btn.Parent = gui
	Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
	themeBind(btn, "BackgroundColor3", "accent")
	themeBind(btn, "TextColor3", "onAccent")
	btn.InputBegan:Connect(function(i)
		if isPress(i) then
			heldInput = i
			start(true)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i == heldInput or i.KeyCode == Enum.KeyCode.G then stop() end
	end)
	UserInputService.InputBegan:Connect(function(i, processed)
		if not processed and i.KeyCode == Enum.KeyCode.G then start(false) end
	end)

	RunService.Heartbeat:Connect(function()
		btn.Visible = Settings.Grapple and true or false
		if not Settings.Grapple then
			if held or anchor then stop() end
			return
		end
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not root or not hum or hum.Health <= 0 then
			if anchor then release() end
			return
		end
		if not anchor or not held then return end
		if not ensureVisuals() then return end

		local handPart = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm") or root
		local from = handPart.Position
		local offset = anchor - root.Position
		local dist = offset.Magnitude
		if dist > 6 then
			local want = offset.Unit * Settings.GrappleSpeed
			root.AssemblyLinearVelocity = root.AssemblyLinearVelocity:Lerp(want, 0.3)
		end
		local color = THEME.accent
		rope.Color = color
		tip.Color = color
		local len = (anchor - from).Magnitude
		rope.Size = Vector3.new(0.14, 0.14, math.max(len, 0.1))
		rope.CFrame = CFrame.lookAt(from, anchor) * CFrame.new(0, 0, -len / 2)
		tip.CFrame = CFrame.new(anchor)
	end)
end

--// ===== RECODE (tab): Lightning Storm =====
-- Bolts of lightning keep striking the ground around you, with a flash of light at every hit.
-- Purely visual (only you see it). Radius sets how far from you they land, Rate how many
-- strikes per second.
do
	local cols = pageCols["Recode"]
	local c = newCard(cols[3], "Lightning Storm", "Lightning")
	makeNote(c, "Lightning keeps striking around you, with a flash of light at every hit. Only you see it.")
	makeSlider(c, "Radius", 10, 60, "LightningRadius", 0)
	makeSlider(c, "Strikes / second", 1, 6, "LightningRate", 0)

	local folder
	local bolts = {} -- { parts =, light =, born =, life = }

	local function strike(root)
		local cam = workspace.CurrentCamera
		if not cam then return end
		if not folder or not folder.Parent then
			folder = Instance.new("Folder")
			folder.Name = "AA_Lightning"
			folder.Parent = cam
		end
		local ang = math.random() * math.pi * 2
		local dist = math.random() * Settings.LightningRadius
		local top = root.Position + Vector3.new(math.cos(ang) * dist, 90, math.sin(ang) * dist)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { player.Character, folder }
		local hit = workspace:Raycast(top, Vector3.new(0, -220, 0), params)
		if not hit then return end
		local ground = hit.Position

		-- a zigzag line from the sky to the ground
		local points = { top }
		local steps = 9
		for i = 1, steps - 1 do
			local t = i / steps
			local base = top:Lerp(ground, t)
			points[#points + 1] = base + Vector3.new((math.random() - 0.5) * 9, 0, (math.random() - 0.5) * 9)
		end
		points[#points + 1] = ground

		local parts = {}
		local function seg(a, b, width, color, transparency)
			local len = (b - a).Magnitude
			if len < 0.05 then return end
			local part = Instance.new("Part")
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.CastShadow = false
			part.Material = Enum.Material.Neon
			part.Color = color
			part.Transparency = transparency
			part.Size = Vector3.new(width, width, len)
			part.CFrame = CFrame.lookAt(a, b) * CFrame.new(0, 0, -len / 2)
			part.Parent = folder
			parts[#parts + 1] = { part = part, base = transparency }
		end
		for i = 1, #points - 1 do
			seg(points[i], points[i + 1], 0.9, THEME.accent, 0.55) -- soft outer glow
			seg(points[i], points[i + 1], 0.25, Color3.new(1, 1, 1), 0) -- bright core
		end

		local flash = Instance.new("Part")
		flash.Anchored = true
		flash.CanCollide = false
		flash.CanQuery = false
		flash.CanTouch = false
		flash.Transparency = 1
		flash.Size = Vector3.new(1, 1, 1)
		flash.CFrame = CFrame.new(ground + Vector3.new(0, 3, 0))
		flash.Parent = folder
		local light = Instance.new("PointLight")
		light.Color = Color3.new(1, 1, 1):Lerp(THEME.accent, 0.35)
		light.Brightness = 8
		light.Range = 32
		light.Parent = flash
		parts[#parts + 1] = { part = flash, base = 1 }

		bolts[#bolts + 1] = { parts = parts, light = light, born = os.clock(), life = 0.3 }
		while #bolts > 30 do
			for _, e in ipairs(bolts[1].parts) do e.part:Destroy() end
			table.remove(bolts, 1)
		end
	end

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		for i = #bolts, 1, -1 do
			local b = bolts[i]
			local a = (now - b.born) / b.life
			if a >= 1 then
				for _, e in ipairs(b.parts) do e.part:Destroy() end
				table.remove(bolts, i)
			else
				for _, e in ipairs(b.parts) do
					if e.base < 1 then e.part.Transparency = e.base + (1 - e.base) * a end
				end
				b.light.Brightness = 8 * (1 - a)
			end
		end
		if not Settings.Lightning then return end
		acc += dt
		if acc < 1 / Settings.LightningRate then return end
		acc = 0
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then strike(root) end
	end)
end

--// ===== WINTER + WASHED (Visuals tab) =====
-- Winter: surfaces turn snowy white (snow material), terrain goes white, snow falls around you,
-- a cold tint covers the screen. Washed: every surface gets a shine (Reflectance) so it looks
-- freshly washed and mirrors its surroundings; its Rain option makes drops fall that dissolve
-- into small, transparent rings where they hit a surface. Everything is only on your screen and
-- is put back when you switch it off.
do
	local Lighting = game:GetService("Lighting")
	local cols = pageCols["Visuals"]

	local c = newCard(cols[3], "Winter", "Winter")
	makeNote(c, "Covers the world in snow: white snowy surfaces, white terrain, falling snow and a cold tint.")
	makeSlider(c, "Snowfall", 20, 400, "WinterSnow", 0)

	local c2 = newCard(cols[3], "Washed", "Washed")
	makeNote(c2, "Every surface looks freshly washed and reflects its surroundings.")
	makeSlider(c2, "Shine", 0.1, 0.7, "WashedShine", 2)
	makeToggle(c2, "Rain", "WashedRain", "Drops dissolve into small rings on the ground")
	makeSlider(c2, "Rain amount", 20, 250, "WashedRainAmount", 0)

	--// ---------- shared: which parts to touch ----------
	local winterSaved = setmetatable({}, { __mode = "k" }) -- part -> { Color, Material }
	local washedSaved = setmetatable({}, { __mode = "k" }) -- part -> Reflectance

	local function eligible(part)
		if not part:IsA("BasePart") or part:IsA("Terrain") or part.Transparency >= 0.9 then return false end
		local cam = workspace.CurrentCamera
		if cam and part:IsDescendantOf(cam) then return false end
		local m = part.Parent
		while m and m ~= workspace do
			if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") then return false end -- people and NPCs stay as they are
			m = m.Parent
		end
		return true
	end

	local SKIP_MATERIALS = {
		[Enum.Material.Glass] = true, [Enum.Material.Neon] = true,
		[Enum.Material.ForceField] = true, [Enum.Material.Water] = true,
	}
	local SNOW_WHITE = Color3.fromRGB(245, 248, 255)

	local function winterOn(part)
		if winterSaved[part] or not eligible(part) or SKIP_MATERIALS[part.Material] then return end
		winterSaved[part] = { part.Color, part.Material }
		part.Color = part.Color:Lerp(SNOW_WHITE, 0.75)
		part.Material = Enum.Material.Snow
	end
	local function washedOn(part)
		if washedSaved[part] ~= nil or not eligible(part) then return end
		washedSaved[part] = part.Reflectance
		part.Reflectance = Settings.WashedShine
	end

	local function scan(apply, stillWanted)
		local n = 0
		for _, d in ipairs(workspace:GetDescendants()) do
			if not stillWanted() then return end
			if d:IsA("BasePart") then apply(d) end
			n += 1
			if n % 400 == 0 then task.wait() end
		end
	end

	workspace.DescendantAdded:Connect(function(d) -- parts streamed in later get the same treatment
		if d:IsA("BasePart") and (Settings.Winter or Settings.Washed) then
			task.defer(function()
				if Settings.Winter then winterOn(d) end
				if Settings.Washed then washedOn(d) end
			end)
		end
	end)

	--// ---------- Winter extras: terrain colour, cold tint, falling snow ----------
	local TERRAIN_MATS = {
		Enum.Material.Grass, Enum.Material.Ground, Enum.Material.Mud, Enum.Material.Sand, Enum.Material.Rock,
		Enum.Material.Slate, Enum.Material.Sandstone, Enum.Material.Limestone, Enum.Material.Pavement,
		Enum.Material.Basalt, Enum.Material.Salt, Enum.Material.LeafyGrass, Enum.Material.Asphalt,
		Enum.Material.Cobblestone, Enum.Material.Concrete,
	}
	local terrainSaved = {}
	local function terrainWinter(on)
		local terrain = workspace:FindFirstChildOfClass("Terrain")
		if not terrain then return end
		if on then
			for _, m in ipairs(TERRAIN_MATS) do
				local ok, col = pcall(function() return terrain:GetMaterialColor(m) end)
				if ok then
					terrainSaved[m] = col
					pcall(function() terrain:SetMaterialColor(m, col:Lerp(SNOW_WHITE, 0.8)) end)
				end
			end
		else
			for m, col in pairs(terrainSaved) do
				pcall(function() terrain:SetMaterialColor(m, col) end)
				terrainSaved[m] = nil
			end
		end
	end

	local tint = Instance.new("ColorCorrectionEffect")
	tint.Name = "AA_Winter"
	tint.TintColor = Color3.fromRGB(215, 230, 255)
	tint.Saturation = -0.15
	tint.Brightness = 0.03
	tint.Enabled = false
	tint.Parent = Lighting

	local snowPart, snowEmitter
	local function ensureSnow()
		local cam = workspace.CurrentCamera
		if not cam then return false end
		if not snowPart or not snowPart.Parent then
			snowPart = Instance.new("Part")
			snowPart.Name = "AA_Snow"
			snowPart.Anchored = true
			snowPart.CanCollide = false
			snowPart.CanQuery = false
			snowPart.CanTouch = false
			snowPart.Transparency = 1
			snowPart.Size = Vector3.new(90, 1, 90)
			snowPart.Parent = cam
			snowEmitter = Instance.new("ParticleEmitter")
			snowEmitter.Color = ColorSequence.new(Color3.new(1, 1, 1))
			snowEmitter.Size = NumberSequence.new(0.35)
			snowEmitter.Lifetime = NumberRange.new(7, 9)
			snowEmitter.Speed = NumberRange.new(5, 9)
			snowEmitter.SpreadAngle = Vector2.new(15, 15)
			snowEmitter.EmissionDirection = Enum.NormalId.Bottom
			snowEmitter.Acceleration = Vector3.new(2, 0, 1)
			snowEmitter.Rotation = NumberRange.new(0, 360)
			snowEmitter.RotSpeed = NumberRange.new(-40, 40)
			snowEmitter.LightEmission = 0.35
			snowEmitter.Parent = snowPart
		end
		return true
	end

	RunService.Heartbeat:Connect(function()
		if Settings.Winter then
			if ensureSnow() then
				snowPart.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position + Vector3.new(0, 40, 0))
				snowEmitter.Rate = Settings.WinterSnow
			end
		elseif snowPart then
			snowPart:Destroy()
			snowPart, snowEmitter = nil, nil
		end
	end)

	--// ---------- Rain (Washed option): drops dissolve into small transparent rings ----------
	local RAIN_SPEED, DROP_LEN, RING_MAX = 85, 1.5, 50
	local rainFolder
	local drops, rings = {}, {}
	local rainParams = RaycastParams.new()
	rainParams.FilterType = Enum.RaycastFilterType.Exclude

	local function newPart(size)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Size = size
		return p
	end

	local function respawn(d, center)
		local ang = math.random() * math.pi * 2
		local r = math.sqrt(math.random()) * 45
		d.x, d.z = center.X + math.cos(ang) * r, center.Z + math.sin(ang) * r
		d.y = center.Y + 30 + math.random() * 30
		local hit = workspace:Raycast(Vector3.new(d.x, d.y, d.z), Vector3.new(0, -200, 0), rainParams)
		if hit then
			d.landY, d.hit, d.normal, d.valid = hit.Position.Y, hit.Position, hit.Normal, true
		else
			d.landY, d.valid = d.y - 200, false
		end
	end

	local function spawnRing(pos, normal)
		local p = newPart(Vector3.new(0.03, 0.35, 0.35))
		p.Shape = Enum.PartType.Cylinder
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromRGB(215, 232, 255)
		p.Transparency = 0.5
		local up = math.abs(normal.Y) > 0.99 and Vector3.new(0, 0, 1) or Vector3.new(0, 1, 0)
		local at = pos + normal * 0.04
		p.CFrame = CFrame.lookAt(at, at + normal, up) * CFrame.Angles(0, math.rad(90), 0) -- flat on the surface
		p.Parent = rainFolder
		rings[#rings + 1] = { part = p, born = os.clock() }
	end

	RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		for i = #rings, 1, -1 do
			local r = rings[i]
			local a = (now - r.born) / 0.45
			if a >= 1 then
				r.part:Destroy()
				table.remove(rings, i)
			else
				local d = 0.35 + 1.5 * a
				r.part.Size = Vector3.new(0.03, d, d)
				r.part.Transparency = 0.5 + 0.5 * a
			end
		end

		local cam = workspace.CurrentCamera
		if not Settings.WashedRain or not cam then
			if #drops > 0 then
				for _, d in ipairs(drops) do d.part:Destroy() end
				table.clear(drops)
			end
			return
		end
		if not rainFolder or not rainFolder.Parent then
			rainFolder = Instance.new("Folder")
			rainFolder.Name = "AA_Rain"
			rainFolder.Parent = cam
			table.clear(drops) -- the old parts went with the old folder
			table.clear(rings)
		end
		rainParams.FilterDescendantsInstances = { player.Character, rainFolder }
		local center = cam.CFrame.Position

		local want = math.floor(Settings.WashedRainAmount)
		while #drops < want do
			local p = newPart(Vector3.new(0.04, DROP_LEN, 0.04))
			p.Material = Enum.Material.SmoothPlastic
			p.Color = Color3.fromRGB(200, 225, 255)
			p.Transparency = 0.45
			p.Parent = rainFolder
			local d = { part = p, tr = 0.45 }
			respawn(d, center)
			d.y -= math.random() * 40 -- spread the first drops out so they do not all land together
			drops[#drops + 1] = d
		end
		while #drops > want do
			drops[#drops].part:Destroy()
			table.remove(drops)
		end

		local parts, cfs = {}, {}
		for i, d in ipairs(drops) do
			d.y -= RAIN_SPEED * dt
			if d.y <= d.landY then
				if d.valid and #rings < RING_MAX then spawnRing(d.hit, d.normal) end
				respawn(d, center)
			end
			local near = d.y - d.landY -- the drop fades out over the last stretch before the surface
			local tr = near < 0.9 and (0.45 + 0.55 * (1 - near / 0.9)) or 0.45
			if d.tr ~= tr then
				d.part.Transparency = tr
				d.tr = tr
			end
			parts[i] = d.part
			cfs[i] = CFrame.new(d.x, d.y + DROP_LEN / 2, d.z)
		end
		workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	end)

	--// ---------- switching on and off ----------
	local wasWinter, wasWashed, lastShine = false, false, nil
	local savedSpec, savedDiffuse
	task.spawn(function()
		while true do
			if Settings.Winter ~= wasWinter then
				wasWinter = Settings.Winter
				if wasWinter then
					tint.Enabled = true
					terrainWinter(true)
					scan(winterOn, function() return Settings.Winter end)
				else
					tint.Enabled = false
					terrainWinter(false)
					for p, v in pairs(winterSaved) do
						if p.Parent then
							p.Color = v[1]
							p.Material = v[2]
						end
						winterSaved[p] = nil
					end
				end
			end
			if Settings.Washed ~= wasWashed then
				wasWashed = Settings.Washed
				if wasWashed then
					savedSpec, savedDiffuse = Lighting.EnvironmentSpecularScale, Lighting.EnvironmentDiffuseScale
					Lighting.EnvironmentSpecularScale = 1 -- lets the shine actually mirror the sky and the scene
					lastShine = Settings.WashedShine
					scan(washedOn, function() return Settings.Washed end)
				else
					if savedSpec then
						Lighting.EnvironmentSpecularScale = savedSpec
						Lighting.EnvironmentDiffuseScale = savedDiffuse
					end
					for p, v in pairs(washedSaved) do
						if p.Parent then p.Reflectance = v end
						washedSaved[p] = nil
					end
				end
			end
			if wasWashed and lastShine ~= Settings.WashedShine then
				lastShine = Settings.WashedShine
				for p in pairs(washedSaved) do
					if p.Parent then p.Reflectance = lastShine end
				end
			end
			task.wait(0.3)
		end
	end)
end
