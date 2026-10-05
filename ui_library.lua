--================================================================--
--  ui_library.lua  |  ส่วนที่ 1/2
--================================================================--

local Library = {}

function Library.new(config)
	config = config or {}
	local Title = config.Title or "My Hub"
	local Subtitle = config.Subtitle or "Mobile Edition"
	local ICON_ASSET = config.IconAsset or ""
	local ICON_FILE = config.IconFile or "icon.png"
	local WINDOW_W = config.Width or 440
	local WINDOW_H = config.Height or 290
	local GUI_NAME = config.Name or ("UILib_" .. (Title:gsub("%s", "")))

	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local CoreGui = game:GetService("CoreGui")
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer

	local Presets = {
		{ Name = "ฟ้า",   Accent = Color3.fromRGB(56, 189, 248),  Accent2 = Color3.fromRGB(14, 116, 217) },
		{ Name = "ม่วง",  Accent = Color3.fromRGB(168, 85, 247),  Accent2 = Color3.fromRGB(109, 40, 217) },
		{ Name = "เขียว", Accent = Color3.fromRGB(52, 211, 153),  Accent2 = Color3.fromRGB(5, 150, 105) },
		{ Name = "แดง",   Accent = Color3.fromRGB(248, 113, 113), Accent2 = Color3.fromRGB(220, 38, 38) },
		{ Name = "ส้ม",   Accent = Color3.fromRGB(251, 146, 60),  Accent2 = Color3.fromRGB(234, 88, 12) },
		{ Name = "ชมพู",  Accent = Color3.fromRGB(244, 114, 182), Accent2 = Color3.fromRGB(219, 39, 119) },
	}

	local Theme = {
		Bg      = Color3.fromRGB(8, 11, 17),
		Element = Color3.fromRGB(16, 23, 34),
		Accent  = Presets[1].Accent,
		Accent2 = Presets[1].Accent2,
		Text    = Color3.fromRGB(235, 245, 255),
		SubText = Color3.fromRGB(125, 150, 175),
		Off     = Color3.fromRGB(38, 50, 68),
		Danger  = Color3.fromRGB(235, 70, 90),
		Good    = Color3.fromRGB(74, 222, 128),
	}

	local FONT = Enum.Font.GothamMedium
	local FONT_BOLD = Enum.Font.GothamBold

	local ThemeHooks = {}
	local function hook(fn)
		fn()
		table.insert(ThemeHooks, fn)
	end

	local function applyPreset(p)
		Theme.Accent, Theme.Accent2 = p.Accent, p.Accent2
		for _, fn in ipairs(ThemeHooks) do fn() end
	end

	--------------------------------------------------------------------
	-- Helpers
	--------------------------------------------------------------------
	local function new(class, props, children)
		local obj = Instance.new(class)
		for k, v in pairs(props or {}) do obj[k] = v end
		for _, c in ipairs(children or {}) do c.Parent = obj end
		return obj
	end

	local function corner(r) return new("UICorner", { CornerRadius = UDim.new(0, r) }) end

	local function stroke(color, thickness, transparency)
		return new("UIStroke", {
			Color = color,
			Thickness = thickness or 1,
			Transparency = transparency or 0,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		})
	end

	local function gradient(c1, c2, rot)
		return new("UIGradient", { Color = ColorSequence.new(c1, c2), Rotation = rot or 0 })
	end

	local function tween(obj, time, props, style, dir)
		local t = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
		t:Play()
		return t
	end

	local function darken(c, a) return c:Lerp(Color3.new(0, 0, 0), a or 0.7) end

	local function isPress(i)
		return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
	end

	local function isMove(i)
		return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
	end

	local function makeDraggable(handle, target, onTap)
		local dragging, dragStart, startPos, moved = false, nil, nil, 0

		handle.InputBegan:Connect(function(input)
			if isPress(input) then
				dragging, moved = true, 0
				dragStart, startPos = input.Position, target.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
						if onTap and moved < 8 then onTap() end
					end
				end)
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if dragging and isMove(input) then
				local d = input.Position - dragStart
				moved = math.max(moved, d.Magnitude)
				target.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + d.X,
					startPos.Y.Scale, startPos.Y.Offset + d.Y
				)
			end
		end)
	end

	local function getGuiParent()
		if gethui then
			local ok, res = pcall(gethui)
			if ok and res then return res end
		end
		local ok = pcall(function() return CoreGui.Name end)
		if ok then return CoreGui end
		return LocalPlayer:WaitForChild("PlayerGui")
	end

	local function resolveIcon()
		if getcustomasset and isfile then
			local okFile, exists = pcall(isfile, ICON_FILE)
			if okFile and exists then
				local ok, res = pcall(getcustomasset, ICON_FILE)
				if ok and res then return res end
			end
		end
		if ICON_ASSET ~= "" then return ICON_ASSET end
		return nil
	end

	local ICON = resolveIcon()

	local function makeIcon(parent, padding)
		if ICON then
			return new("ImageLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, padding, 0, padding),
				Size = UDim2.new(1, -padding * 2, 1, -padding * 2),
				Image = ICON,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 3,
				Parent = parent,
			})
		end
		return new("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Font = FONT_BOLD,
			Text = "X",
			TextColor3 = Color3.new(0, 0, 0),
			TextScaled = true,
			ZIndex = 3,
			Parent = parent,
		}, { new("UIPadding", {
			PaddingTop = UDim.new(0, padding + 2), PaddingBottom = UDim.new(0, padding + 2),
		}) })
	end

	--------------------------------------------------------------------
	-- Root GUI
	--------------------------------------------------------------------
	local old = getGuiParent():FindFirstChild(GUI_NAME)
	if old then old:Destroy() end

	local Gui = new("ScreenGui", {
		Name = GUI_NAME,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = getGuiParent(),
	})

	local function toast(text, color)
		local t = new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, -44),
			Size = UDim2.new(0, 0, 0, 32),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = Theme.Bg,
			BackgroundTransparency = 0.05,
			Font = FONT_BOLD,
			Text = text,
			TextColor3 = Theme.Text,
			TextSize = 14,
			ZIndex = 50,
			Parent = Gui,
		}, {
			corner(12),
			stroke(color or Theme.Accent, 1.5, 0),
			new("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }),
		})
		tween(t, 0.3, { Position = UDim2.new(0.5, 0, 0, 14) }, Enum.EasingStyle.Back)
		task.delay(1.6, function()
			if t.Parent then
				tween(t, 0.25, { Position = UDim2.new(0.5, 0, 0, -44) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Wait()
				t:Destroy()
			end
		end)
	end

	--------------------------------------------------------------------
	-- Main window
	--------------------------------------------------------------------
	local MAIN_POS = UDim2.new(0.5, 0, 0.5, 0)
	local TOGGLE_POS = UDim2.new(0.03, 0, 0.25, 0)

	local MainStroke = stroke(Theme.Accent, 1.5, 0.35)
	local MainGrad = gradient(Color3.new(), Color3.new(), 90)

	local Main = new("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = MAIN_POS,
		Size = UDim2.new(0, WINDOW_W, 0, WINDOW_H),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = Gui,
	}, { corner(16), MainStroke, MainGrad })

	hook(function()
		MainStroke.Color = Theme.Accent
		MainGrad.Color = ColorSequence.new(
			Color3.fromRGB(10, 14, 22):Lerp(Theme.Accent2, 0.14),
			Color3.fromRGB(4, 6, 10)
		)
	end)

	local MainScale = new("UIScale", { Scale = 1, Parent = Main })
	local userScale = 1

	-- Header
	local HEADER_H = 44

	local HeaderGrad = gradient(Color3.new(), Color3.new(), 0)
	local PatchGrad = gradient(Color3.new(), Color3.new(), 0)
	local LineGrad = gradient(Color3.new(), Color3.new(), 0)
	local BadgeGrad = gradient(Color3.new(), Color3.new(), 45)

	local Header = new("Frame", {
		Size = UDim2.new(1, 0, 0, HEADER_H),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = Main,
	}, { corner(16), HeaderGrad })

	new("Frame", {
		Position = UDim2.new(0, 0, 1, -14),
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = Header,
	}, { PatchGrad })

	new("Frame", {
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = Header,
	}, { LineGrad })

	local Badge = new("Frame", {
		Position = UDim2.new(0, 10, 0.5, -15),
		Size = UDim2.new(0, 30, 0, 30),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 2,
		Parent = Header,
	}, { corner(9), BadgeGrad })
	makeIcon(Badge, 3)

	new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 48, 0, 5),
		Size = UDim2.new(1, -150, 0, 20),
		Font = FONT_BOLD,
		Text = Title,
		TextColor3 = Theme.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 2,
		Parent = Header,
	})

	local SubTitle = new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 48, 0, 23),
		Size = UDim2.new(1, -150, 0, 14),
		Font = FONT,
		Text = Subtitle,
		TextColor3 = Theme.Accent,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 2,
		Parent = Header,
	})

	local ActiveList = {}

	local function refreshStatus()
		if #ActiveList == 0 then
			SubTitle.Text = Subtitle
			SubTitle.TextColor3 = Theme.Accent
		else
			SubTitle.Text = "● ทำงานอยู่: " .. table.concat(ActiveList, ", ")
			SubTitle.TextColor3 = Theme.Good
		end
	end

	local function setActive(name, on)
		local idx = table.find(ActiveList, name)
		if on and not idx then
			table.insert(ActiveList, name)
		elseif not on and idx then
			table.remove(ActiveList, idx)
		end
		refreshStatus()
		toast(name .. (on and "  :  เปิด" or "  :  ปิด"), on and Theme.Good or Theme.SubText)
	end

	local function headerButton(text, xOffset, color)
		return new("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, xOffset, 0.5, 0),
			Size = UDim2.new(0, 28, 0, 28),
			BackgroundColor3 = color,
			BackgroundTransparency = 0.25,
			Font = FONT_BOLD,
			Text = text,
			TextColor3 = Theme.Text,
			TextSize = 15,
			AutoButtonColor = false,
			ZIndex = 3,
			Parent = Header,
		}, { corner(9) })
	end

	local CloseBtn = headerButton("✕", -10, Theme.Danger)
	local HideBtn = headerButton("–", -44, Theme.Off)

	makeDraggable(Header, Main)

	-- Sidebar + Body
	local Sidebar = new("Frame", {
		Position = UDim2.new(0, 10, 0, HEADER_H + 10),
		Size = UDim2.new(0, 108, 1, -(HEADER_H + 20)),
		BackgroundColor3 = Theme.Element,
		BackgroundTransparency = 0.2,
		Parent = Main,
	}, {
		corner(12),
		new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
		new("UIPadding", {
			PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6),
		}),
	})

	local Body = new("Frame", {
		Position = UDim2.new(0, 126, 0, HEADER_H + 10),
		Size = UDim2.new(1, -136, 1, -(HEADER_H + 20)),
		BackgroundTransparency = 1,
		Parent = Main,
	})

	--------------------------------------------------------------------
	-- ปุ่มลอย เปิด/ปิด UI
	--------------------------------------------------------------------
	local ToggleStroke = stroke(Color3.new(1, 1, 1), 2, 0.2)
	local ToggleGrad = gradient(Color3.new(), Color3.new(), 45)

	local Toggle = new("TextButton", {
		Name = "FloatingToggle",
		Position = TOGGLE_POS,
		Size = UDim2.new(0, 56, 0, 56),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 10,
		Parent = Gui,
	}, { corner(18), ToggleStroke, ToggleGrad })
	makeIcon(Toggle, 6)

	hook(function()
		local dark = darken(Theme.Accent, 0.68)
		local base = Color3.fromRGB(8, 12, 20)
		HeaderGrad.Color = ColorSequence.new(dark, base)
		PatchGrad.Color = ColorSequence.new(dark, base)
		LineGrad.Color = ColorSequence.new(Theme.Accent, base)
		local light = Theme.Accent:Lerp(Color3.new(1, 1, 1), 0.4)
		BadgeGrad.Color = ColorSequence.new(light, Theme.Accent2)
		ToggleGrad.Color = ColorSequence.new(light, Theme.Accent2)
		ToggleStroke.Color = Theme.Accent:Lerp(Color3.new(1, 1, 1), 0.6)
		refreshStatus()
	end)

	local uiOpen, busy = true, false

	local function setOpen(state)
		if busy or state == uiOpen then return end
		busy = true
		uiOpen = state

		if state then
			MainScale.Scale = 0
			Main.Visible = true
			tween(MainScale, 0.35, { Scale = userScale }, Enum.EasingStyle.Back).Completed:Wait()
		else
			tween(MainScale, 0.2, { Scale = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Wait()
			Main.Visible = false
		end
		tween(Toggle, 0.2, { BackgroundTransparency = state and 0 or 0.3 })
		busy = false
	end

	makeDraggable(Toggle, Toggle, function() setOpen(not uiOpen) end)
	HideBtn.MouseButton1Click:Connect(function() setOpen(false) end)
	CloseBtn.MouseButton1Click:Connect(function() Gui:Destroy() end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.RightShift then
			setOpen(not uiOpen)
		end
	end)
		--------------------------------------------------------------------
	-- ชุดองค์ประกอบ (ผูกกับแต่ละหน้า)
	--------------------------------------------------------------------
	local function Elements(Content)
		local E = {}
		local order = 0
		local function nextOrder() order += 1 return order end

		function E.Section(text)
			local l = new("TextLabel", {
				LayoutOrder = nextOrder(),
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundTransparency = 1,
				Font = FONT_BOLD,
				Text = string.upper(text),
				TextColor3 = Theme.Accent,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = Content,
			}, { new("UIPadding", { PaddingLeft = UDim.new(0, 4) }) })
			hook(function() l.TextColor3 = Theme.Accent end)
		end

		function E.Label(text)
			return new("TextLabel", {
				LayoutOrder = nextOrder(),
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundColor3 = Theme.Element,
				Font = FONT,
				Text = text,
				TextColor3 = Theme.SubText,
				TextSize = 13,
				TextWrapped = true,
				Parent = Content,
			}, { corner(10) })
		end

		function E.Stat(text, initial)
			local row = new("Frame", {
				LayoutOrder = nextOrder(),
				Size = UDim2.new(1, 0, 0, 34),
				BackgroundColor3 = Theme.Element,
				Parent = Content,
			}, { corner(10) })

			new("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 0),
				Size = UDim2.new(1, -90, 1, 0),
				Font = FONT,
				Text = text,
				TextColor3 = Theme.Text,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})

			local value = new("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -12, 0, 0),
				Size = UDim2.new(0, 70, 1, 0),
				Font = FONT_BOLD,
				Text = initial or "-",
				TextColor3 = Theme.Accent,
				TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = row,
			})

			return function(t, color)
				value.Text = t
				if color then value.TextColor3 = color end
			end
		end

		function E.Button(text, callback)
			local b = new("TextButton", {
				LayoutOrder = nextOrder(),
				Size = UDim2.new(1, 0, 0, 38),
				BackgroundColor3 = Theme.Element,
				Font = FONT,
				Text = text,
				TextColor3 = Theme.Text,
				TextSize = 14,
				AutoButtonColor = false,
				Parent = Content,
			}, { corner(10) })

			local s = stroke(Theme.Accent, 1, 0.65)
			s.Parent = b
			hook(function() s.Color = Theme.Accent end)

			b.MouseButton1Down:Connect(function() tween(b, 0.1, { BackgroundColor3 = Theme.Accent2 }) end)
			b.MouseButton1Up:Connect(function() tween(b, 0.2, { BackgroundColor3 = Theme.Element }) end)
			b.MouseLeave:Connect(function() tween(b, 0.2, { BackgroundColor3 = Theme.Element }) end)
			b.MouseButton1Click:Connect(function() if callback then callback() end end)
			return b
		end

		function E.Toggle(text, default, callback)
			local state = default or false

			local row = new("TextButton", {
				LayoutOrder = nextOrder(),
				Size = UDim2.new(1, 0, 0, 38),
				BackgroundColor3 = Theme.Element,
				Text = "",
				AutoButtonColor = false,
				Parent = Content,
			}, { corner(10) })

			new("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 0),
				Size = UDim2.new(1, -70, 1, 0),
				Font = FONT,
				Text = text,
				TextColor3 = Theme.Text,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = row,
			})

			local pill = new("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.new(0, 42, 0, 22),
				BackgroundColor3 = Theme.Off,
				Parent = row,
			}, { corner(11) })

			local knob = new("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
				Size = UDim2.new(0, 18, 0, 18),
				BackgroundColor3 = Color3.new(1, 1, 1),
				Parent = pill,
			}, { corner(9) })

			hook(function() pill.BackgroundColor3 = state and Theme.Accent or Theme.Off end)

			row.MouseButton1Click:Connect(function()
				state = not state
				tween(pill, 0.2, { BackgroundColor3 = state and Theme.Accent or Theme.Off })
				tween(knob, 0.2, {
					Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
				}, Enum.EasingStyle.Back)
				if callback then callback(state) end
			end)
		end

		function E.Slider(text, min, max, default, callback, suffix)
			suffix = suffix or ""
			local value = default or min

			local frame = new("Frame", {
				LayoutOrder = nextOrder(),
				Size = UDim2.new(1, 0, 0, 54),
				BackgroundColor3 = Theme.Element,
				Parent = Content,
			}, { corner(10) })

			new("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 6),
				Size = UDim2.new(1, -80, 0, 18),
				Font = FONT,
				Text = text,
				TextColor3 = Theme.Text,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = frame,
			})

			local valueLabel = new("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -12, 0, 6),
				Size = UDim2.new(0, 60, 0, 18),
				Font = FONT_BOLD,
				Text = tostring(value) .. suffix,
				TextColor3 = Theme.Accent,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = frame,
			})

			local bar = new("Frame", {
				Position = UDim2.new(0, 12, 0, 36),
				Size = UDim2.new(1, -24, 0, 6),
				BackgroundColor3 = Theme.Off,
				Parent = frame,
			}, { corner(3) })

			local a0 = (value - min) / (max - min)
			local fillGrad = gradient(Theme.Accent2, Theme.Accent, 0)
			local fill = new("Frame", {
				Size = UDim2.new(a0, 0, 1, 0),
				BackgroundColor3 = Color3.new(1, 1, 1),
				Parent = bar,
			}, { corner(3), fillGrad })

			local knobStroke = stroke(Theme.Accent, 2, 0)
			local knob = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(a0, 0, 0.5, 0),
				Size = UDim2.new(0, 16, 0, 16),
				BackgroundColor3 = Color3.new(1, 1, 1),
				ZIndex = 2,
				Parent = bar,
			}, { corner(8), knobStroke })

			hook(function()
				fillGrad.Color = ColorSequence.new(Theme.Accent2, Theme.Accent)
				knobStroke.Color = Theme.Accent
				valueLabel.TextColor3 = Theme.Accent
			end)

			local hit = new("TextButton", {
				Position = UDim2.new(0, 6, 0, 24),
				Size = UDim2.new(1, -12, 0, 30),
				BackgroundTransparency = 1,
				Text = "",
				Parent = frame,
			})

			local function setValue(v)
				v = math.clamp(math.floor(v + 0.5), min, max)
				local s = (v - min) / (max - min)
				fill.Size = UDim2.new(s, 0, 1, 0)
				knob.Position = UDim2.new(s, 0, 0.5, 0)
				valueLabel.Text = tostring(v) .. suffix
				if v ~= value then
					value = v
					if callback then callback(v) end
				end
			end

			local dragging = false
			local function update(x)
				local a = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
				setValue(min + (max - min) * a)
			end

			hit.InputBegan:Connect(function(input)
				if isPress(input) then
					dragging = true
					Content.ScrollingEnabled = false
					update(input.Position.X)
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if dragging and isMove(input) then update(input.Position.X) end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if dragging and isPress(input) then
					dragging = false
					Content.ScrollingEnabled = true
				end
			end)

			return { Set = setValue }
		end

		function E.ColorPicker(text, presets, callback)
			local frame = new("Frame", {
				LayoutOrder = nextOrder(),
				Size = UDim2.new(1, 0, 0, 76),
				BackgroundColor3 = Theme.Element,
				Parent = Content,
			}, { corner(10) })

			new("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 6),
				Size = UDim2.new(1, -100, 0, 18),
				Font = FONT,
				Text = text,
				TextColor3 = Theme.Text,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = frame,
			})

			local nameLabel = new("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -12, 0, 6),
				Size = UDim2.new(0, 80, 0, 18),
				Font = FONT_BOLD,
				Text = presets[1].Name,
				TextColor3 = Theme.Accent,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = frame,
			})
			hook(function() nameLabel.TextColor3 = Theme.Accent end)

			local row = new("Frame", {
				Position = UDim2.new(0, 12, 0, 34),
				Size = UDim2.new(1, -24, 0, 30),
				BackgroundTransparency = 1,
				Parent = frame,
			}, {
				new("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 9),
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
			})

			local swatches = {}

			local function set(i)
				nameLabel.Text = presets[i].Name
				for j, sw in ipairs(swatches) do
					local on = (j == i)
					tween(sw.Stroke, 0.2, { Transparency = on and 0 or 1 })
					tween(sw.Btn, 0.2, { Size = on and UDim2.new(0, 30, 0, 30) or UDim2.new(0, 26, 0, 26) })
				end
				if callback then callback(presets[i], i) end
			end

			for i, p in ipairs(presets) do
				local sStroke = stroke(Color3.new(1, 1, 1), 2, i == 1 and 0 or 1)
				local btn = new("TextButton", {
					LayoutOrder = i,
					Size = i == 1 and UDim2.new(0, 30, 0, 30) or UDim2.new(0, 26, 0, 26),
					BackgroundColor3 = Color3.new(1, 1, 1),
					Text = "",
					AutoButtonColor = false,
					Parent = row,
				}, { corner(15), sStroke, gradient(p.Accent, p.Accent2, 45) })
				swatches[i] = { Btn = btn, Stroke = sStroke }
				btn.MouseButton1Click:Connect(function() set(i) end)
			end

			return { Set = set }
		end

		return E
	end

	--------------------------------------------------------------------
	-- ระบบแท็บ
	--------------------------------------------------------------------
	local Tabs = {}
	local selectedTab = nil

	local function CreateTab(name, emoji)
		emoji = emoji or "📁"
		local btn = new("TextButton", {
			LayoutOrder = #Tabs + 1,
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = Theme.Accent,
			BackgroundTransparency = 1,
			Font = FONT,
			Text = emoji .. "  " .. name,
			TextColor3 = Theme.SubText,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutoButtonColor = false,
			Parent = Sidebar,
		}, { corner(9), new("UIPadding", { PaddingLeft = UDim.new(0, 10) }) })

		local page = new("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.Accent,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
			Parent = Body,
		}, {
			new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
			new("UIPadding", { PaddingRight = UDim.new(0, 5), PaddingBottom = UDim.new(0, 6) }),
		})

		local tab = { Btn = btn, Page = page }
		table.insert(Tabs, tab)

		hook(function()
			page.ScrollBarImageColor3 = Theme.Accent
			btn.BackgroundColor3 = Theme.Accent
			if selectedTab == tab then btn.TextColor3 = Theme.Accent end
		end)

		local function select()
			selectedTab = tab
			for _, t in ipairs(Tabs) do
				t.Page.Visible = false
				tween(t.Btn, 0.2, { BackgroundTransparency = 1, TextColor3 = Theme.SubText })
			end
			page.Visible = true
			tween(btn, 0.2, { BackgroundTransparency = 0.82, TextColor3 = Theme.Accent })
		end

		btn.MouseButton1Click:Connect(select)
		if #Tabs == 1 then select() end

		return Elements(page)
	end

	--------------------------------------------------------------------
	-- ส่วนที่ main.lua เรียกใช้
	--------------------------------------------------------------------
	local fpsSetters = {}

	local Window = {
		Gui = Gui,
		Theme = Theme,
		Toast = toast,
		SetActive = setActive,
		SetOpen = setOpen,
		CreateTab = CreateTab,
	}

	function Window.Destroy()
		Gui:Destroy()
	end

	-- เพิ่มแถวแสดง FPS
	function Window.AddFPSStat(tab, text)
		table.insert(fpsSetters, tab.Stat(text or "FPS", "-"))
	end

	-- สร้างแท็บ "ตั้งค่า" สำเร็จรูป
	function Window.AddSettingsTab(name)
		local Settings = CreateTab(name or "ตั้งค่า", "⚙️")

		Settings.Section("ธีม")
		local colorCtl = Settings.ColorPicker("สี UI", Presets, function(p)
			applyPreset(p)
		end)

		Settings.Section("ขนาด")
		local sizeCtl = Settings.Slider("ขนาด UI", 60, 120, 100, function(v)
			userScale = v / 100
			if uiOpen and not busy then MainScale.Scale = userScale end
		end, "%")

		Settings.Section("ประสิทธิภาพ")
		Window.AddFPSStat(Settings, "FPS")

		Settings.Section("ระบบ")
		Settings.Button("🔄 รีเซ็ตการตั้งค่า", function()
			colorCtl.Set(1)
			sizeCtl.Set(100)
			tween(Main, 0.35, { Position = MAIN_POS }, Enum.EasingStyle.Back)
			tween(Toggle, 0.35, { Position = TOGGLE_POS }, Enum.EasingStyle.Back)
			toast("รีเซ็ตการตั้งค่าแล้ว", Theme.Accent)
		end)

		return Settings
	end

	-- ตัวนับ FPS
	do
		local frames, last = 0, os.clock()
		RunService.RenderStepped:Connect(function()
			frames += 1
			local now = os.clock()
			if now - last >= 0.5 then
				local fps = math.floor(frames / (now - last) + 0.5)
				frames, last = 0, now
				if uiOpen then
					local c = fps >= 50 and Theme.Good
						or fps >= 30 and Color3.fromRGB(250, 204, 21)
						or Theme.Danger
					for _, set in ipairs(fpsSetters) do set(tostring(fps), c) end
				end
			end
		end)
	end

	-- แอนิเมชันตอนโหลด
	MainScale.Scale = 0
	tween(MainScale, 0.4, { Scale = userScale }, Enum.EasingStyle.Back)

	return Window
end

return Library
