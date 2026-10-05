--================================================================--
--  main.lua  |  ไฟล์หลักที่ "รัน" และแก้เนื้อหาได้ง่าย                 --
--================================================================--

--------------------------------------------------------------------
-- 1) ใส่ลิงก์ไฟล์ ui_library.lua บน GitHub (ต้องเป็นลิงก์ Raw)
--    รูปแบบ: https://raw.githubusercontent.com/ชื่อผู้ใช้/ชื่อrepo/main/ui_library.lua
--------------------------------------------------------------------
local LIB_URL = "https://raw.githubusercontent.com/Aipplazz2017/Xerm/main/ui_library.lua"

--------------------------------------------------------------------
-- 2) ตั้งค่าหน้าต่าง (ชื่อบนหัว / รูปไอคอน / ขนาด)
--------------------------------------------------------------------
local WINDOW_CONFIG = {
	Title = "1yui discrod",       -- ชื่อบนหัว
	Subtitle = "Mobile Edition",  -- ข้อความใต้ชื่อ (ตอนไม่มีฟังก์ชันทำงาน)
	IconAsset = "",               -- ใส่ "rbxassetid://เลข ID" ถ้ามีรูป
	IconFile = "xanax_icon.png",  -- หรือวางไฟล์รูปในโฟลเดอร์ workspace
	Width = 440,
	Height = 290,
}

--------------------------------------------------------------------
-- 3) รายการสคริปต์ (ปุ่ม "▶ ชื่อ" ในหน้า EPS) ← เพิ่มของคุณที่นี่
--------------------------------------------------------------------
local Scripts = {
	{
		Name = "ตัวอย่างสคริปต์",
		Run = function()
			print("[1yui] ตัวอย่างสคริปต์ทำงานแล้ว")
		end,
	},
	-- รูปแบบสำหรับเพิ่มสคริปต์ของคุณ (ลบ -- หน้าบรรทัดออกแล้วแก้ชื่อ/ลิงก์):
	-- {
	--     Name = "ชื่อสคริปต์",
	--     Run = function()
	--         loadstring(game:HttpGet("ลิงก์สคริปต์"))()
	--     end,
	-- },
}

--------------------------------------------------------------------
-- โหลด UI
--------------------------------------------------------------------
-- แจ้งเตือนบนจอ (เห็นได้แม้เปิด console ไม่ได้)
local function notify(text)
	print("[1yui] " .. tostring(text))
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "1yui discrod",
			Text = string.sub(tostring(text), 1, 180),
			Duration = 10,
		})
	end)
end

notify("กำลังโหลด UI...")

if not loadstring or not game.HttpGet then
	notify("executor นี้ไม่รองรับ loadstring/HttpGet")
	return
end

if string.find(LIB_URL, "ชื่อผู้ใช้", 1, true) then
	notify("ยังไม่ได้ใส่ลิงก์ LIB_URL")
	return
end

local okGet, src = pcall(function() return game:HttpGet(LIB_URL) end)
if not okGet then
	notify("โหลดลิงก์ไม่ได้ (404?): " .. tostring(src))
	return
end

local fn, compileErr = loadstring(src)
if not fn then
	notify("ไฟล์ ui_library.lua มีข้อผิดพลาด: " .. tostring(compileErr))
	return
end

local okRun, Library = pcall(fn)
if not okRun or type(Library) ~= "table" then
	notify("รันไฟล์ UI ไม่สำเร็จ: " .. tostring(Library))
	return
end

local okWin, Window = pcall(Library.new, WINDOW_CONFIG)
if not okWin then
	notify("สร้างหน้าต่างไม่สำเร็จ: " .. tostring(Window))
	return
end

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

--------------------------------------------------------------------
-- 4) ฟังก์ชันการทำงาน
--    Window.SetActive("ชื่อ", true/false) = โชว์สถานะบนหัวหน้าต่าง + แจ้งเตือน
--------------------------------------------------------------------
local function getHumanoid()
	local c = LocalPlayer.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

-- Auto Speed
local speedValue = 50
local origSpeed = 16
local speedConn

local function setAutoSpeed(on)
	if speedConn then speedConn:Disconnect() speedConn = nil end

	if on then
		local hum = getHumanoid()
		if hum and hum.WalkSpeed ~= speedValue then origSpeed = hum.WalkSpeed end
		speedConn = RunService.Heartbeat:Connect(function()
			local h = getHumanoid()
			if h and h.WalkSpeed ~= speedValue then h.WalkSpeed = speedValue end
		end)
	else
		local hum = getHumanoid()
		if hum then hum.WalkSpeed = origSpeed end
	end

	Window.SetActive("Auto Speed", on)
end

-- FPS Boost (ลดกราฟิกให้ลื่นขึ้น)
local boostBackup

local function setFPSBoost(on)
	if on then
		boostBackup = { Shadows = Lighting.GlobalShadows }
		pcall(function() boostBackup.Quality = settings().Rendering.QualityLevel end)
		Lighting.GlobalShadows = false
		pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
	elseif boostBackup then
		Lighting.GlobalShadows = boostBackup.Shadows
		if boostBackup.Quality then
			pcall(function() settings().Rendering.QualityLevel = boostBackup.Quality end)
		end
		boostBackup = nil
	end

	Window.SetActive("FPS Boost", on)
end

-- กระสุนตรง / ลดแรงดีด
-- หมายเหตุ: ระบบปืนต่างกันในแต่ละเกม ต้องใส่โค้ดของเกมที่คุณเล่นในช่อง "ใส่โค้ดตรงนี้"
-- ตอนนี้สวิตช์แค่แสดงสถานะ (บนหัว + แจ้งเตือน) ยังไม่ได้แก้ค่าในเกมให้
local function setNoSpread(on)
	if on then
		-- ใส่โค้ดตรงนี้: ทำให้กระสุนตรง
	else
		-- ใส่โค้ดตรงนี้: คืนค่าเดิม
	end
	Window.SetActive("กระสุนตรง", on)
end

local function setNoRecoil(on)
	if on then
		-- ใส่โค้ดตรงนี้: ลดแรงดีด
	else
		-- ใส่โค้ดตรงนี้: คืนค่าเดิม
	end
	Window.SetActive("ลดแรงดีด", on)
end

-- เก็บกวาดตอนปิด UI
Window.Gui.Destroying:Connect(function()
	if speedConn then
		speedConn:Disconnect()
		local hum = getHumanoid()
		if hum then hum.WalkSpeed = origSpeed end
	end
	if boostBackup then
		Lighting.GlobalShadows = boostBackup.Shadows
		if boostBackup.Quality then
			pcall(function() settings().Rendering.QualityLevel = boostBackup.Quality end)
		end
	end
end)

--------------------------------------------------------------------
-- 5) หน้าต่างๆ  (เพิ่มของได้ด้วย: Section / Label / Button / Toggle / Slider)
--    ตัวอย่าง: Home.Button("ชื่อปุ่ม", function() print("กดแล้ว") end)
--------------------------------------------------------------------

-- 🏠 หน้าหลัก
local Home = Window.CreateTab("หน้าหลัก", "🏠")

Home.Section("🔫 ปืน")
Home.Toggle("กระสุนตรง", false, setNoSpread)
Home.Toggle("ลดแรงดีด", false, setNoRecoil)

-- 📊 หน้า EPS: ฟังก์ชัน + ปุ่มเปิดสคริปต์
local EPS = Window.CreateTab("EPS", "📊")

EPS.Section("⚡ ฟังก์ชัน")
EPS.Toggle("Auto Speed (วิ่งเร็ว)", false, setAutoSpeed)
EPS.Slider("ความเร็ว Auto Speed", 16, 120, speedValue, function(v)
	speedValue = v
end)
EPS.Toggle("FPS Boost (ลดกราฟิก)", false, setFPSBoost)

EPS.Section("📜 สคริปต์")
for _, s in ipairs(Scripts) do
	EPS.Button("▶  " .. s.Name, function()
		local okRun, err = pcall(s.Run)
		if okRun then
			Window.Toast(s.Name .. "  :  เปิดแล้ว", Window.Theme.Good)
		else
			warn("[1yui] " .. s.Name .. " error:", err)
			Window.Toast(s.Name .. "  :  ผิดพลาด", Window.Theme.Danger)
		end
	end)
end

-- ⚙️ หน้าตั้งค่า (สี UI / ขนาด / FPS / รีเซ็ต) สำเร็จรูปจากไลบรารี
Window.AddSettingsTab("ตั้งค่า")

notify("โหลดสำเร็จ ✅")
