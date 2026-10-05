--================================================================--
--  main.lua | ฉบับแก้ไข Toggle ปิดแล้วหยุดทำงานทันที 100%
--================================================================--

--------------------------------------------------------------------
-- [CONFIG] 1. ตั้งค่าพื้นฐาน & ลิงก์ UI Library
--------------------------------------------------------------------
local LIB_URL = "https://raw.githubusercontent.com/Aipplazz2017/Xerm/main/ui_library.lua"

local WINDOW_CONFIG = {
	Title = "1yui discrod",
	Subtitle = "Mobile Edition",
	Width = 440,
	Height = 290,
}

--------------------------------------------------------------------
-- [SCRIPTS] 2. รายการสคริปต์ในหน้า EPS
--------------------------------------------------------------------
local Scripts = {
	{
		Name = "ตัวอย่างสคริปต์ 1",
		Run = function()
			print("[1yui] สคริปต์ 1 ทำงาน")
		end,
	},
}

--------------------------------------------------------------------
-- [SYSTEM] โหลดไลบรารี UI และ Services
--------------------------------------------------------------------
local function notify(text)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "1yui discrod",
			Text = tostring(text),
			Duration = 5,
		})
	end)
end

local okGet, src = pcall(function() return game:HttpGet(LIB_URL) end)
if not okGet then 
	notify("โหลดไฟล์ UI ไม่สำเร็จ")
	return 
end

local Library = loadstring(src)()
local Window = Library.new(WINDOW_CONFIG)
local Lighting = game:GetService("Lighting")

--================================================================--
-- [FUNCTIONS] 3. รวบรวมฟังก์ชันการทำงาน
--================================================================--

local GunFunctions = {}
local isRecoilActive = false
local recoilThread = nil
local originalValues = {}

function GunFunctions.toggleNoRecoil(state)
	-- ตั้งค่าสถานะก่อนเสมอ
	isRecoilActive = state
	Window.SetActive("ลดแรงดีด", state)

	if state then
		-- ป้องกันการสร้าง thread ซ้ำ
		if recoilThread then return end

		recoilThread = task.spawn(function()
			while isRecoilActive do
				if getgc then
					for _, tbl in pairs(getgc(true)) do
						if type(tbl) == "table" then
							-- ตรวจหา property ที่เกี่ยวกับแรงดีด
							if rawget(tbl, "Recoil") or rawget(tbl, "RecoilUp") 
							   or rawget(tbl, "CameraKick") or rawget(tbl, "Spread") then
								
								-- เก็บค่าเดิมไว้ครั้งแรกเท่านั้น
								if not originalValues[tbl] then
									originalValues[tbl] = {
										Recoil       = rawget(tbl, "Recoil"),
										RecoilUp     = rawget(tbl, "RecoilUp"),
										RecoilLeft   = rawget(tbl, "RecoilLeft"),
										RecoilRight  = rawget(tbl, "RecoilRight"),
										CameraKick   = rawget(tbl, "CameraKick"),
										VisualRecoil = rawget(tbl, "VisualRecoil"),
										Spread       = rawget(tbl, "Spread"),
										MinSpread    = rawget(tbl, "MinSpread"),
										MaxSpread    = rawget(tbl, "MaxSpread"),
									}
								end

								-- บังคับเป็น 0
								rawset(tbl, "Recoil", 0)
								rawset(tbl, "RecoilUp", 0)
								rawset(tbl, "RecoilLeft", 0)
								rawset(tbl, "RecoilRight", 0)
								rawset(tbl, "CameraKick", 0)
								rawset(tbl, "VisualRecoil", 0)
								rawset(tbl, "Spread", 0)
								rawset(tbl, "MinSpread", 0)
								rawset(tbl, "MaxSpread", 0)
							end
						end
					end
				end
				task.wait(0.5) -- ลดเวลารอให้ตอบสนองเร็วขึ้น
			end

			-- เมื่อออกจาก loop (ถูกปิด) → กู้ค่าเดิมทันที
			for tbl, data in pairs(originalValues) do
				if type(tbl) == "table" then
					for key, val in pairs(data) do
						if val \~= nil then
							pcall(rawset, tbl, key, val)
						end
					end
				end
			end
			table.clear(originalValues)
			recoilThread = nil
		end)
	else
		-- ปิดทันที: ตั้ง flag แล้วรอให้ loop จบเอง (ปลอดภัยกว่า task.cancel)
		isRecoilActive = false

		-- บังคับยกเลิก thread เผื่อบาง executor
		if recoilThread then
			pcall(task.cancel, recoilThread)
			recoilThread = nil
		end

		-- กู้ค่าเดิมทันที (กรณี task.cancel สำเร็จ)
		for tbl, data in pairs(originalValues) do
			if type(tbl) == "table" then
				for key, val in pairs(data) do
					if val \~= nil then
						pcall(rawset, tbl, key, val)
					end
				end
			end
		end
		table.clear(originalValues)
	end
end

--================================================================--
-- [UI LAYOUT] 4. ส่วนสร้างหน้าต่างและจัดวางปุ่ม (UI Setup)
--================================================================--

-- 🏠 แท็บที่ 1: หน้าหลัก
local Home = Window.CreateTab("หน้าหลัก", "🏠")

Home.Section("🔫 ปืน")
-- รับค่า state (true/false) จาก Toggle ของ UI Library ตรงๆ
Home.Toggle("ลดแรงดีด", false, function(state)
	GunFunctions.toggleNoRecoil(state)
end)

-- 📊 แท็บที่ 2: หน้า EPS (สคริปต์)
local EPS = Window.CreateTab("EPS", "📊")

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

-- 🚀 แท็บที่ 3: หน้า Boost FPS
local BoostTab = Window.CreateTab("Boost FPS", "🚀")

BoostTab.Section("⚡ เพิ่มความลื่น")
local boostBackup = nil
BoostTab.Toggle("FPS Boost (ลดกราฟิก)", false, function(state)
	Window.SetActive("FPS Boost", state)
	if state then
		boostBackup = Lighting.GlobalShadows
		Lighting.GlobalShadows = false
		pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
	else
		if boostBackup \~= nil then
			Lighting.GlobalShadows = boostBackup
		end
	end
end)

-- ⚙️ แท็บที่ 4: ตั้งค่า
Window.AddSettingsTab("ตั้งค่า")

notify("โหลดสำเร็จ ✅")
