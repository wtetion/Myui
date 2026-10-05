-- CascadeStyleUI adapter for the official Cascade UI library.
-- Cascade v1.4.0 is loaded from the official release or from a local
-- ModuleScript named "Cascade" in ReplicatedStorage.

local UI = {
	CascadeVersion = "v1.4.0",
}

local RELEASE_URL = "https://github.com/cascadeui/Cascade/releases/download/v1.4.0/dist.luau"

function UI.LoadCascade()
	local replicatedStorage = game:GetService("ReplicatedStorage")
	local localCascade = replicatedStorage:FindFirstChild("Cascade")

	if localCascade and localCascade:IsA("ModuleScript") then
		local ok, result = pcall(require, localCascade)
		if not ok then
			error("[CascadeStyleUI] The ReplicatedStorage.Cascade ModuleScript failed to load: " .. tostring(result), 2)
		end
		if type(result) ~= "table" or type(result.New) ~= "function" then
			error("[CascadeStyleUI] ReplicatedStorage.Cascade must return the official Cascade API.", 2)
		end
		return result
	end

	if type(loadstring) ~= "function" then
		error(
			"[CascadeStyleUI] Cascade needs loadstring to load its pinned official release. "
				.. "For Roblox Studio, install the official Cascade v1.4.0 dist.luau as a ModuleScript "
				.. "named 'Cascade' in ReplicatedStorage. This script does not read script.Parent.",
			2
		)
	end

	local ok, source = pcall(function()
		return game:HttpGetAsync(RELEASE_URL)
	end)
	if not ok or type(source) ~= "string" then
		error("[CascadeStyleUI] Could not download Cascade v1.4.0: " .. tostring(source), 2)
	end

	local compileOk, chunk = pcall(loadstring, source, "Cascade v1.4.0")
	if not compileOk or type(chunk) ~= "function" then
		error("[CascadeStyleUI] Cascade v1.4.0 could not be compiled: " .. tostring(chunk), 2)
	end

	local runOk, cascade = pcall(chunk)
	if not runOk then
		error("[CascadeStyleUI] Cascade v1.4.0 failed during initialization: " .. tostring(cascade), 2)
	end
	if type(cascade) ~= "table" or type(cascade.New) ~= "function" then
		error("[CascadeStyleUI] The official release did not return a valid Cascade API.", 2)
	end

	return cascade
end

local function rowControl(form, title, subtitle, componentName, properties)
	local row = form:Row({ SearchIndex = title })
	row:Left():TitleStack({ Title = title, Subtitle = subtitle })

	local right = row:Right()
	local createControl = right[componentName]
	if type(createControl) ~= "function" then
		error("[CascadeStyleUI] Cascade v1.4.0 does not provide the " .. componentName .. " component.", 3)
	end

	return createControl(right, properties or {})
end

local function pageForm(tab, title, subtitle)
	return tab:PageSection({ Title = title, Subtitle = subtitle }):Form()
end

local function make(parent, className, properties)
	local object = Instance.new(className)
	for key, value in pairs(properties or {}) do
		object[key] = value
	end
	object.Parent = parent
	return object
end

local function customRow(form, title, subtitle)
	local row = form:Row({ SearchIndex = title })
	row:Left():TitleStack({ Title = title, Subtitle = subtitle })
	return row:Right().__container, row
end

local function moveSearchIntoSidebar(window)
	local search = window.Structures.Titlebar.SearchField
	local sidebar = window.Structures.SidebarList

	-- Keep Cascade's own search listener and move its actual TextField to the
	-- sidebar, where it appears under the window controls like the reference.
	search.Body.AutomaticSize = Enum.AutomaticSize.None
	search.Body.Size = UDim2.new(1, 0, 0, 32)
	search.Body.LayoutOrder = -1000
	search.Field.AutomaticSize = Enum.AutomaticSize.None
	search.Field.Size = UDim2.new(1, -34, 0, 22)
	search.Field.LayoutOrder = 2
	search.Field.TextXAlignment = Enum.TextXAlignment.Left
	search.Layout.Padding = UDim.new(0, 5)
	search.Body.BackgroundColor3 = Color3.fromRGB(233, 234, 237)
	search.Body.BackgroundTransparency = 0
	local corner = search.Body:FindFirstChildOfClass("UICorner")
	if corner then
		corner.CornerRadius = UDim.new(0, 11)
	end
	local stroke = search.Body:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Transparency = 1
	end
	search.Body.Parent = sidebar
	return search
end

local function addAccountSubtitle(tab, cascade, app)
	local structures = tab.Structures
	local body = structures.Body
	local leading = structures.Leading
	local title = structures.Title
	local symbol = structures.Symbol

	body.Size = UDim2.new(1, 0, 0, 50)
	leading.Size = UDim2.new(1, -34, 0, 0)
	symbol.Visible = true
	symbol.Image = cascade.Symbols.personCropCircle
	symbol.ImageColor3 = Color3.fromRGB(130, 130, 135)
	symbol.Size = UDim2.fromOffset(30, 30)
	title.Visible = false

	local stack = make(leading, "Frame", {
		Name = "AccountTitleStack",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 2,
		Size = UDim2.new(1, -36, 0, 34),
	})
	local titleText = make(stack, "TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		FontFace = Font.new("rbxassetid://12187365364"),
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, 0, 0, 17),
		Text = "Sign In",
		TextColor3 = app.Theme.Text.Primary[1].Value,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local subtitleText = make(stack, "TextLabel", {
		Name = "Subtitle",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		FontFace = Font.new("rbxassetid://12187365364"),
		Position = UDim2.fromOffset(0, 17),
		Size = UDim2.new(1, 0, 0, 15),
		Text = "Set up your Apple Account",
		TextColor3 = app.Theme.Text.Tertiary[1].Value,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	return titleText, subtitleText
end

local function addSoftwareUpdateBadge(tab)
	make(tab.Structures.Trailing, "Frame", {
		Name = "UpdateAvailableBadge",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 59, 48),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(9, 9),
	})
	local badge = tab.Structures.Trailing:FindFirstChild("UpdateAvailableBadge")
	make(badge, "UICorner", { CornerRadius = UDim.new(1, 0) })
end

local function styleTabIcons(tabs)
	local colors = {
		SoftwareUpdate = Color3.fromRGB(78, 122, 218),
		WiFi = Color3.fromRGB(0, 122, 255),
		Bluetooth = Color3.fromRGB(0, 122, 255),
		Network = Color3.fromRGB(48, 166, 101),
		VPN = Color3.fromRGB(80, 112, 206),
		Battery = Color3.fromRGB(52, 199, 89),
		General = Color3.fromRGB(135, 137, 143),
		Accessibility = Color3.fromRGB(0, 122, 255),
		Appearance = Color3.fromRGB(70, 72, 82),
		MenuBar = Color3.fromRGB(99, 99, 102),
		Siri = Color3.fromRGB(113, 81, 219),
		DesktopDock = Color3.fromRGB(255, 149, 0),
		Displays = Color3.fromRGB(0, 122, 255),
		Spotlight = Color3.fromRGB(54, 120, 246),
		Wallpaper = Color3.fromRGB(82, 153, 243),
		PrivacySecurity = Color3.fromRGB(255, 59, 48),
		LocationServices = Color3.fromRGB(0, 122, 255),
		ScreenRecording = Color3.fromRGB(255, 59, 48),
		FilesFolders = Color3.fromRGB(10, 132, 255),
		FarmSettings = Color3.fromRGB(48, 166, 101),
		Harvest = Color3.fromRGB(52, 199, 89),
	}
	local entries = {}

	for key, tab in pairs(tabs) do
		local structures = tab.Structures
		local symbol = structures and structures.Symbol
		if symbol and key ~= "SignIn" then
			local tileColor = colors[key] or Color3.fromRGB(0, 122, 255)
			local leading = structures.Leading
			local tile = make(leading, "Frame", {
				Name = "CascadeColorIconTile",
				BackgroundColor3 = tileColor,
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				LayoutOrder = symbol.LayoutOrder,
				Size = UDim2.fromOffset(26, 26),
			})
			local corner = make(tile, "UICorner", { CornerRadius = UDim.new(0, 7) })
			local stroke = make(tile, "UIStroke", {
				Color = tileColor,
				Thickness = 1,
				Transparency = 1,
			})
			local gradient
			if key == "Siri" then
				gradient = make(tile, "UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 84, 151)),
						ColorSequenceKeypoint.new(0.34, Color3.fromRGB(148, 91, 239)),
						ColorSequenceKeypoint.new(0.68, Color3.fromRGB(61, 163, 255)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 132, 89)),
					}),
				})
			end
			symbol.Parent = tile
			symbol.AnchorPoint = Vector2.new(0.5, 0.5)
			symbol.Position = UDim2.fromScale(0.5, 0.5)
			symbol.Size = UDim2.fromOffset(16, 16)
			symbol.LayoutOrder = 1
			symbol.ImageTransparency = 0
			structures.Body.Size = UDim2.new(1, 0, 0, 36)
			structures.Title.Size = UDim2.new(1, -28, 0, 20)

			local entry = {
				Key = key,
				Tile = tile,
				Stroke = stroke,
				Corner = corner,
				Symbol = symbol,
				Title = structures.Title,
				Body = structures.Body,
				Gradient = gradient,
				BaseColor = tileColor,
			}
			table.insert(entries, entry)
			symbol:GetPropertyChangedSignal("ImageColor3"):Connect(function()
				if symbol.Parent == tile and entry.GlyphColor and symbol.ImageColor3 ~= entry.GlyphColor then
					symbol.ImageColor3 = entry.GlyphColor
				end
			end)
			symbol:GetPropertyChangedSignal("ImageTransparency"):Connect(function()
				if symbol.Parent == tile and symbol.ImageTransparency ~= 0 then
					symbol.ImageTransparency = 0
				end
			end)
		end
	end

	local style = { Value = 1 }
	function style:SetAccent(accent)
		self.Accent = accent
		if self.Value == 4 then
			self:SetValue(4)
		end
	end
	function style:SetValue(value)
		if value < 1 or value > 4 then
			return
		end
		self.Value = value
		for _, entry in ipairs(entries) do
			local tile, symbol = entry.Tile, entry.Symbol
			if tile.Parent then
				local glyphColor = Color3.new(1, 1, 1)
				if value == 1 then
					tile.BackgroundColor3 = entry.BaseColor
					tile.BackgroundTransparency = 0
					entry.Stroke.Transparency = 1
				elseif value == 2 then
					tile.BackgroundColor3 = Color3.fromRGB(53, 54, 59)
					tile.BackgroundTransparency = 0
					entry.Stroke.Transparency = 1
				elseif value == 3 then
					tile.BackgroundColor3 = entry.BaseColor:Lerp(Color3.new(1, 1, 1), 0.55)
					tile.BackgroundTransparency = 0.12
					entry.Stroke.Color = entry.BaseColor
					entry.Stroke.Transparency = 0.5
					glyphColor = entry.BaseColor
				else
					local accent = self.Accent or Color3.fromRGB(255, 69, 58)
					tile.BackgroundColor3 = entry.BaseColor:Lerp(accent, 0.36)
					tile.BackgroundTransparency = 0
					entry.Stroke.Transparency = 1
				end
				entry.GlyphColor = glyphColor
				symbol.ImageColor3 = glyphColor
				if entry.Gradient then
					entry.Gradient.Transparency = value == 1 and NumberSequence.new(0) or NumberSequence.new(1)
				end
			end
		end
	end
	function style:SetSize(value)
		local sizeByValue = { 22, 26, 30 }
		local heightByValue = { 32, 36, 40 }
		local iconSize = sizeByValue[value] or sizeByValue[2]
		local rowHeight = heightByValue[value] or heightByValue[2]
		for _, entry in ipairs(entries) do
			if entry.Tile.Parent then
				entry.Tile.Size = UDim2.fromOffset(iconSize, iconSize)
				entry.Symbol.Size = UDim2.fromOffset(math.floor(iconSize * 0.62), math.floor(iconSize * 0.62))
				entry.Body.Size = UDim2.new(1, 0, 0, rowHeight)
				entry.Title.Size = UDim2.new(1, -(iconSize + 2), 0, 20)
				entry.Corner.CornerRadius = UDim.new(0, math.max(6, math.floor(iconSize * 0.27)))
			end
		end
	end
	style:SetValue(1)
	style:SetSize(2)
	return style
end

local function refreshCard(card, selected, accent)
	local stroke = card:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = selected and accent or Color3.fromRGB(210, 212, 216)
		stroke.Transparency = selected and 0 or 0.35
		stroke.Thickness = selected and 2 or 1
	end
	card.BackgroundColor3 = selected and accent:Lerp(Color3.new(1, 1, 1), 0.91) or Color3.fromRGB(250, 250, 252)
end

local function makeVisualPicker(form, title, subtitle, options, selectedValue, cardWidth, accent, onChanged, cardHeight)
	local parent = customRow(form, title, subtitle)
	local spacing = 7
	cardHeight = cardHeight or 82
	local holder = make(parent, "Frame", {
		Name = "CascadeVisualPicker",
		AutomaticSize = Enum.AutomaticSize.None,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Size = UDim2.fromOffset(#options * cardWidth + (#options - 1) * spacing, cardHeight + 6),
	})
	make(holder, "UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, spacing),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})

	local cards = {}
	local handle = { Value = selectedValue }

	local function updateSelection(index, fireCallback)
		if not options[index] then
			return
		end
		handle.Value = index
		for i, card in ipairs(cards) do
			refreshCard(card, i == index, accent)
		end
		if fireCallback ~= false and onChanged then
			onChanged(index)
		end
	end

	for index, option in ipairs(options) do
		local card = make(holder, "TextButton", {
			Name = "Choice_" .. tostring(index),
			AutoButtonColor = true,
			BackgroundColor3 = Color3.fromRGB(250, 250, 252),
			BorderSizePixel = 0,
			LayoutOrder = index,
			Size = UDim2.fromOffset(cardWidth, cardHeight),
			Text = "",
		})
		make(card, "UICorner", { CornerRadius = UDim.new(0, 7) })
		make(card, "UIStroke", {
			Color = Color3.fromRGB(210, 212, 216),
			Transparency = 0.35,
			Thickness = 1,
		})

		if option.Glass then
			local tinted = option.Mode == "tinted"
			local preview = make(card, "Frame", {
				Name = "GlassPreview",
				BackgroundColor3 = Color3.fromRGB(233, 238, 246),
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(5, 5),
				Size = UDim2.new(1, -10, 0, cardHeight - 27),
			})
			make(preview, "UICorner", { CornerRadius = UDim.new(0, 5) })
			make(preview, "UIStroke", {
				Color = Color3.fromRGB(205, 211, 220),
				Transparency = 0.2,
				Thickness = 1,
			})
			make(preview, "Frame", {
				Name = "GlassWallpaper",
				BackgroundColor3 = tinted and Color3.fromRGB(122, 158, 211) or Color3.fromRGB(249, 250, 252),
				BackgroundTransparency = tinted and 0.12 or 0.05,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 1),
			})
			local pane = make(preview, "Frame", {
				Name = "GlassPane",
				BackgroundColor3 = tinted and Color3.fromRGB(229, 238, 250) or Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = tinted and 0.12 or 0.28,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 4, 0, 5),
				Size = UDim2.new(0.48, 0, 1, -10),
			})
			make(pane, "UICorner", { CornerRadius = UDim.new(0, 4) })
			make(pane, "UIStroke", {
				Color = tinted and Color3.fromRGB(124, 156, 203) or Color3.fromRGB(255, 255, 255),
				Transparency = 0.15,
				Thickness = 1,
			})
			make(preview, "Frame", {
				Name = "GlassContent",
				BackgroundColor3 = tinted and Color3.fromRGB(51, 77, 119) or Color3.fromRGB(112, 124, 143),
				BackgroundTransparency = 0.35,
				BorderSizePixel = 0,
				Position = UDim2.new(0.58, 0, 0, 10),
				Size = UDim2.new(0.31, 0, 0, 4),
			})
			for lineIndex = 1, 2 do
				make(preview, "Frame", {
					BackgroundColor3 = tinted and Color3.fromRGB(76, 102, 143) or Color3.fromRGB(177, 184, 194),
					BackgroundTransparency = 0.25,
					BorderSizePixel = 0,
					Position = UDim2.new(0.58, 0, 0, 19 + (lineIndex - 1) * 7),
					Size = UDim2.new(0.31, 0, 0, 3),
				})
			end
		elseif option.StylePreview then
			local iconTile = make(card, "Frame", {
				Name = "StyleIconPreview",
				BackgroundColor3 = option.Color or accent,
				BackgroundTransparency = option.Mode == "clear" and 0.28 or 0,
				BorderSizePixel = 0,
				Position = UDim2.new(0.5, -18, 0, 8),
				Size = UDim2.fromOffset(36, 36),
			})
			make(iconTile, "UICorner", { CornerRadius = UDim.new(0, 9) })
			if option.Mode == "clear" then
				make(iconTile, "UIStroke", {
					Color = option.Color or accent,
					Transparency = 0.25,
					Thickness = 1,
				})
			end
			local icon = make(iconTile, "ImageLabel", {
				Name = "StyleSymbol",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = option.Icon,
				ImageColor3 = option.GlyphColor or Color3.new(1, 1, 1),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(21, 21),
			})
			icon.ScaleType = Enum.ScaleType.Fit
		elseif option.Preview then
			local dark = option.Mode == "dark"
			local automatic = option.Mode == "auto"
			local preview = make(card, "Frame", {
				Name = "WindowPreview",
				BackgroundColor3 = dark and Color3.fromRGB(41, 42, 46) or Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(5, 5),
				Size = UDim2.new(1, -10, 0, cardHeight - 27),
			})
			make(preview, "UICorner", { CornerRadius = UDim.new(0, 4) })
			make(preview, "UIStroke", {
				Color = dark and Color3.fromRGB(75, 76, 80) or Color3.fromRGB(225, 226, 230),
				Transparency = 0.2,
				Thickness = 1,
			})
			local topbar = make(preview, "Frame", {
				Name = "PreviewTitlebar",
				BackgroundColor3 = dark and Color3.fromRGB(52, 53, 57) or Color3.fromRGB(244, 245, 248),
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 10),
			})
			for dotIndex, dotColor in ipairs({ Color3.fromRGB(255, 95, 86), Color3.fromRGB(255, 189, 46), Color3.fromRGB(39, 201, 63) }) do
				local dot = make(topbar, "Frame", {
					BackgroundColor3 = dotColor,
					BorderSizePixel = 0,
					Position = UDim2.fromOffset(4 + (dotIndex - 1) * 6, 3),
					Size = UDim2.fromOffset(4, 4),
				})
				make(dot, "UICorner", { CornerRadius = UDim.new(1, 0) })
			end
			local sidebarColor = dark and Color3.fromRGB(48, 49, 53) or Color3.fromRGB(239, 240, 243)
			make(preview, "Frame", {
				Name = "PreviewSidebar",
				BackgroundColor3 = sidebarColor,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(0, 10),
				Size = UDim2.new(0, 20, 1, -10),
			})
			local content = make(preview, "Frame", {
				Name = "PreviewContent",
				BackgroundColor3 = dark and Color3.fromRGB(41, 42, 46) or Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(20, 10),
				Size = UDim2.new(1, -20, 1, -10),
			})
			if automatic then
				make(content, "Frame", {
					Name = "AutomaticDarkPreview",
					BackgroundColor3 = Color3.fromRGB(41, 42, 46),
					BorderSizePixel = 0,
					Position = UDim2.new(0.52, 0, 0, 0),
					Size = UDim2.new(0.48, 0, 1, 0),
				})
			end
			make(preview, "ImageLabel", {
				Name = "PreviewSymbol",
				BackgroundTransparency = 1,
				Image = option.Icon,
				ImageColor3 = accent,
				Position = UDim2.fromOffset(25, 17),
				Size = UDim2.fromOffset(12, 12),
			})
			for lineIndex = 1, 3 do
				make(preview, "Frame", {
					BackgroundColor3 = dark and Color3.fromRGB(105, 106, 112) or Color3.fromRGB(211, 213, 219),
					BorderSizePixel = 0,
					Position = UDim2.fromOffset(25, 33 + (lineIndex - 1) * 5),
					Size = UDim2.new(0.55, 0, 0, 3),
				})
			end
		else
			local icon = make(card, "ImageLabel", {
				Name = "StyleSymbol",
				BackgroundTransparency = 1,
				Image = option.Icon,
				ImageColor3 = option.Color or accent,
				Position = UDim2.new(0.5, -15, 0, 10),
				Size = UDim2.fromOffset(30, 30),
			})
			icon.ScaleType = Enum.ScaleType.Fit
		end

		make(card, "TextLabel", {
			Name = "Caption",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			FontFace = Font.new("rbxassetid://12187365364"),
			Position = UDim2.new(0, 0, 1, -19),
			Size = UDim2.new(1, 0, 0, 15),
			Text = option.Label,
			TextColor3 = Color3.fromRGB(60, 60, 65),
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Center,
		})
		card.Activated:Connect(function()
			updateSelection(index, true)
		end)
		table.insert(cards, card)
	end

	handle.SetValue = function(_, value, fireCallback)
		updateSelection(value, fireCallback)
	end
	handle.SetAccent = function(_, nextAccent)
		accent = nextAccent
		for index, card in ipairs(cards) do
			refreshCard(card, index == handle.Value, accent)
			for _, descendant in ipairs(card:GetDescendants()) do
				if descendant.Name == "PreviewSymbol" then
					descendant.ImageColor3 = accent
				end
			end
		end
	end
	updateSelection(selectedValue, false)
	return handle
end

local function makeAccentSwatches(form, cascade, app, state)
	local parent = customRow(form, "Color", "Choose an accent")
	local palette = {
		{ "Spectrum", Color3.fromRGB(60, 145, 240) },
		{ "Blue", Color3.fromRGB(10, 132, 255) },
		{ "Purple", Color3.fromRGB(191, 90, 242) },
		{ "Pink", Color3.fromRGB(255, 55, 95) },
		{ "Red", Color3.fromRGB(255, 69, 58) },
		{ "Orange", Color3.fromRGB(255, 159, 10) },
		{ "Yellow", Color3.fromRGB(255, 214, 10) },
		{ "Green", Color3.fromRGB(50, 215, 75) },
		{ "Graphite", Color3.fromRGB(142, 142, 147) },
	}
	local holder = make(parent, "Frame", {
		Name = "CascadeAccentSwatches",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Size = UDim2.fromOffset(9 * 25 + 8 * 4, 28),
	})
	make(holder, "UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})

	local swatches = {}
	local handle = { Value = 1 }
	local function select(index, fireCallback)
		if not palette[index] then
			return
		end
		handle.Value = index
		state.Accent = palette[index][1]
		for i, button in ipairs(swatches) do
			local stroke = button:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = i == index and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 135)
				stroke.Thickness = i == index and 2 or 1
				stroke.Transparency = i == index and 0 or 0.55
			end
		end
		if fireCallback ~= false then
			local accentName = palette[index][1] == "Spectrum" and "Blue" or palette[index][1]
			local accent = cascade.Accents[accentName]
			if accent then
				app.Accent = accent
			end
		end
		state.AccentColor = palette[index][2]
		if state.OnAccentChanged then
			state.OnAccentChanged(palette[index][2], index)
		end
	end

	for index, item in ipairs(palette) do
		local button = make(holder, "ImageButton", {
			Name = "Accent_" .. item[1],
			AutoButtonColor = true,
			BackgroundColor3 = item[2],
			BorderSizePixel = 0,
			LayoutOrder = index,
			Size = UDim2.fromOffset(21, 21),
		})
		make(button, "UICorner", { CornerRadius = UDim.new(1, 0) })
		make(button, "UIStroke", {
			Color = Color3.fromRGB(130, 130, 135),
			Transparency = 0.55,
			Thickness = 1,
		})
		if item[1] == "Spectrum" then
			make(button, "UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 70)),
					ColorSequenceKeypoint.new(0.22, Color3.fromRGB(255, 196, 50)),
					ColorSequenceKeypoint.new(0.45, Color3.fromRGB(70, 210, 95)),
					ColorSequenceKeypoint.new(0.68, Color3.fromRGB(45, 170, 255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(186, 92, 240)),
				}),
			})
		end
		button.Activated:Connect(function()
			select(index, true)
		end)
		table.insert(swatches, button)
	end

	handle.SetValue = function(_, value, fireCallback)
		select(value, fireCallback)
	end
	select(5, false)
	return handle
end

function UI.CreateSystemSettings(cascade)
	cascade = cascade or UI.LoadCascade()
	if type(cascade) ~= "table" or type(cascade.New) ~= "function" then
		error("[CascadeStyleUI] CreateSystemSettings expects the official Cascade API.", 2)
	end
	if type(cascade.Symbols) ~= "table" or type(cascade.Themes) ~= "table" or type(cascade.Accents) ~= "table" then
		error("[CascadeStyleUI] Cascade Symbols, Themes, or Accents are missing.", 2)
	end

	local app = cascade.New({
		WindowPill = true,
		Theme = cascade.Themes.Light,
		Accent = cascade.Accents.Red or cascade.Accents.Blue,
		DisplayOrder = 80,
		ResetOnSpawn = false,
	})

	local window = app:Window({
		Title = "Appearance",
		Subtitle = nil,
		Size = UDim2.fromOffset(900, 680),
		Searching = true,
		Draggable = true,
		Resizable = true,
		CanExit = true,
		CanMinimize = true,
		CanZoom = true,
		Dropshadow = true,
		UIBlur = true,
	})
	local searchField = moveSearchIntoSidebar(window)

	local tabs = {}
	local controls = {}
	local state = {
		TextHighlight = 1,
		IconStyle = 1,
		Appearance = 2,
		LiquidGlass = 1,
		FolderColor = 1,
		SidebarIconSize = 2,
		WallpaperTint = true,
	}
	local accountTitleText
	local accountSubtitleText
	local tabIconStyle
	local function applyGlassStyle()
		local dark = state.Appearance == 3
		local base = dark and Color3.fromRGB(49, 50, 54) or Color3.fromRGB(233, 234, 237)
		local accentColor = state.WallpaperTint and state.AccentColor or base
		accentColor = accentColor or Color3.fromRGB(255, 69, 58)
		if state.LiquidGlass == 2 then
			searchField.Body.BackgroundColor3 = base:Lerp(accentColor, 0.2)
			searchField.Body.BackgroundTransparency = 0.12
		else
			searchField.Body.BackgroundColor3 = base
			searchField.Body.BackgroundTransparency = 0.28
		end
		local stroke = searchField.Body:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = state.LiquidGlass == 2 and accentColor or Color3.fromRGB(255, 255, 255)
			stroke.Transparency = state.LiquidGlass == 2 and 0.55 or 0.42
		end
	end
	local function setAppearance(modeIndex)
		state.Appearance = modeIndex
		local dark = modeIndex == 3
		local theme = dark and cascade.Themes.Dark or cascade.Themes.Light
		app.Theme = theme
		applyGlassStyle()
		if accountTitleText then
			accountTitleText.TextColor3 = theme.Text.Primary[1].Value
		end
		if accountSubtitleText then
			accountSubtitleText.TextColor3 = theme.Text.Tertiary[1].Value
		end
	end

	-- The first two entries are direct Window tabs, matching the Sign In and
	-- Software Update rows at the top of the reference sidebar.
	local signIn = window:Tab({
		Title = "Sign In",
		Icon = cascade.Symbols.personCropCircle,
	})
	tabs.SignIn = signIn
	accountTitleText, accountSubtitleText = addAccountSubtitle(signIn, cascade, app)
	local signInForm = pageForm(signIn, "Apple Account", "Sign in to personalize your account settings.")
	rowControl(signInForm, "Sign in to your account", "Your account details are not collected by this UI example.", "Button", {
		Label = "Sign In",
		State = "Primary",
		Pushed = function()
			print("[CascadeStyleUI] Sign In selected. Connect your own safe authentication flow here.")
		end,
	})
	rowControl(signInForm, "Account status", "This example page is visual only; it does not authenticate or store credentials.", "Label", {
		Text = "Not signed in",
	})

	local softwareUpdate = window:Tab({
		Title = "Software Update Available",
		Icon = cascade.Symbols.displayAndArrowDown,
	})
	tabs.SoftwareUpdate = softwareUpdate
	softwareUpdate.Structures.Title.TextSize = 11
	addSoftwareUpdateBadge(softwareUpdate)
	local updateForm = pageForm(softwareUpdate, "Software Update", "An example update is available for this demo interface.")
	rowControl(updateForm, "Update status", "CascadeStyleUI example build", "Label", {
		Text = "Update Available",
	})
	rowControl(updateForm, "Check for Updates", "Run your own update check from this callback.", "Button", {
		Label = "Check for Updates",
		State = "Secondary",
		Pushed = function()
			print("[CascadeStyleUI] Update check button clicked.")
		end,
	})

	local wifi = window:Tab({ Title = "Wi-Fi", Icon = cascade.Symbols.wifi })
	tabs.WiFi = wifi
	local wifiForm = pageForm(wifi, "Wi-Fi", "Manage the sample connection state.")
	controls.WiFi = rowControl(wifiForm, "Wi-Fi", "Example preference only.", "Toggle", {
		Value = true,
		ValueChanged = function(_, value)
			print("[CascadeStyleUI] Wi-Fi sample preference:", value)
		end,
	})
	rowControl(wifiForm, "Known network", nil, "PopUpButton", {
		Options = { "Home network", "Guest network", "Other" },
		Value = 1,
		ValueChanged = function(_, value)
			print("[CascadeStyleUI] Network option:", value)
		end,
	})

	local bluetooth = window:Tab({ Title = "Bluetooth", Icon = cascade.Symbols.antennaRadiowavesLeftAndRight })
	tabs.Bluetooth = bluetooth
	local bluetoothForm = pageForm(bluetooth, "Bluetooth", "Manage the sample connection state.")
	rowControl(bluetoothForm, "Bluetooth", "Example preference only.", "Toggle", {
		Value = true,
		ValueChanged = function(_, value)
			print("[CascadeStyleUI] Bluetooth sample preference:", value)
		end,
	})

	local network = window:Tab({ Title = "Network", Icon = cascade.Symbols.network })
	tabs.Network = network
	local networkForm = pageForm(network, "Network", "A text field and button using Cascade components.")
	rowControl(networkForm, "Profile name", nil, "TextField", {
		Value = "Default",
		Placeholder = "Enter a profile name",
		ValueChanged = function(_, value)
			print("[CascadeStyleUI] Network profile:", value)
		end,
	})
	rowControl(networkForm, "Reconnect", "Example action callback.", "Button", {
		Label = "Reconnect",
		State = "Secondary",
		Pushed = function()
			print("[CascadeStyleUI] Reconnect button clicked.")
		end,
	})

	local vpn = window:Tab({ Title = "VPN", Icon = cascade.Symbols.networkBadgeShieldHalfFilled })
	tabs.VPN = vpn
	local vpnForm = pageForm(vpn, "VPN", "Manage the sample private network connection.")
	controls.VPN = rowControl(vpnForm, "VPN status", "Example preference only.", "Toggle", {
		Value = false,
		ValueChanged = function(_, value)
			print("[CascadeStyleUI] VPN sample preference:", value)
		end,
	})
	rowControl(vpnForm, "Configuration", nil, "PopUpButton", {
		Options = { "Work profile", "Personal profile", "Add configuration" },
		Value = 1,
		ValueChanged = function(_, value)
			print("[CascadeStyleUI] VPN configuration:", value)
		end,
	})
	rowControl(vpnForm, "Connect", "Example action callback.", "Button", {
		Label = "Connect",
		State = "Secondary",
		Pushed = function()
			print("[CascadeStyleUI] VPN connect button clicked.")
		end,
	})

	local battery = window:Tab({ Title = "Battery", Icon = cascade.Symbols.battery100percent })
	tabs.Battery = battery
	local batteryForm = pageForm(battery, "Battery", "Choose a sample power preference.")
	rowControl(batteryForm, "Power mode", nil, "PopUpButton", {
		Options = { "Automatic", "Low Power", "High Performance" },
		Value = 1,
		ValueChanged = function(_, value)
			print("[CascadeStyleUI] Power mode:", value)
		end,
	})

	local system = window:Section({ Title = "System", Expanded = true })
	local general = system:Tab({ Title = "General", Icon = cascade.Symbols.gear })
	tabs.General = general
	local generalForm = pageForm(general, "General", "General preferences for this example.")
	rowControl(generalForm, "Show notifications", "Turn the sample notification preference on or off.", "Toggle", {
		Value = true,
		ValueChanged = function(_, value)
			print("[CascadeStyleUI] Notifications:", value)
		end,
	})
	rowControl(generalForm, "Restore Defaults", "Reset the example preferences.", "Button", {
		Label = "Restore Defaults",
		State = "Secondary",
		Pushed = function()
			print("[CascadeStyleUI] Restore Defaults clicked.")
		end,
	})

	local accessibility = system:Tab({ Title = "Accessibility", Icon = cascade.Symbols.accessibility })
	tabs.Accessibility = accessibility
	local accessibilityForm = pageForm(accessibility, "Display", "Readable controls and motion preferences.")
	rowControl(accessibilityForm, "Increase contrast", "Example preference control.", "Toggle", {
		Value = false,
		ValueChanged = function(_, value)
			print("[CascadeStyleUI] Increase contrast:", value)
		end,
	})
	rowControl(accessibilityForm, "Reduce motion", "Example preference control.", "Toggle", {
		Value = false,
		ValueChanged = function(_, value)
			print("[CascadeStyleUI] Reduce motion:", value)
		end,
	})

	local appearance = system:Tab({
		Title = "Appearance",
		Icon = cascade.Symbols.sunMax,
		Selected = true,
	})
	tabs.Appearance = appearance

	local appearanceForm = pageForm(appearance, "Appearance", "Choose the look and colors for the interface.")
	local appearanceModeOptions = { "Auto", "Light", "Dark" }
	controls.AppearancePreview = makeVisualPicker(
		appearanceForm,
		"Appearance",
		nil,
		{
			{ Label = "Auto", Icon = cascade.Symbols.sunMax, Mode = "auto", Preview = true },
			{ Label = "Light", Icon = cascade.Symbols.sunMax, Mode = "light", Preview = true },
			{ Label = "Dark", Icon = cascade.Symbols.sunMax, Mode = "dark", Preview = true },
		},
		2,
		82,
		Color3.fromRGB(255, 69, 58),
		function(index)
			setAppearance(index)
		end,
		82
	)

	controls.LiquidGlass = makeVisualPicker(
		appearanceForm,
		"Liquid Glass",
		nil,
		{
			{ Label = "Clear", Mode = "clear", Glass = true },
			{ Label = "Tinted", Mode = "tinted", Glass = true },
		},
		1,
		86,
		Color3.fromRGB(255, 69, 58),
		function(index)
			state.LiquidGlass = index
			applyGlassStyle()
		end,
		82
	)

	local themeForm = pageForm(appearance, "Theme", nil)
	controls.Accent = makeAccentSwatches(themeForm, cascade, app, state)

	controls.TextHighlight = rowControl(themeForm, "Text highlight color", nil, "PopUpButton", {
		Options = { "Automatic", "Blue", "Purple", "Pink", "Green", "Orange" },
		Value = 1,
		ValueChanged = function(_, value)
			state.TextHighlight = value
		end,
	})

	controls.IconStyle = makeVisualPicker(
		themeForm,
		"Icon & widget style",
		nil,
		{
			{ Label = "Default", Icon = cascade.Symbols.gearshape, Color = Color3.fromRGB(0, 122, 255), StylePreview = true },
			{ Label = "Dark", Icon = cascade.Symbols.gearshape, Color = Color3.fromRGB(53, 54, 59), Mode = "dark", StylePreview = true },
			{ Label = "Clear", Icon = cascade.Symbols.gearshape, Color = Color3.fromRGB(92, 153, 222), Mode = "clear", StylePreview = true },
			{ Label = "Tinted", Icon = cascade.Symbols.gearshape, Color = Color3.fromRGB(111, 105, 207), Mode = "tinted", StylePreview = true },
		},
		1,
		60,
		Color3.fromRGB(255, 69, 58),
		function(value)
			state.IconStyle = value
			if tabIconStyle then
				tabIconStyle:SetValue(value)
			end
		end,
		82
	)

	controls.FolderColor = rowControl(themeForm, "Folder color", nil, "PopUpButton", {
		Options = { "Automatic", "Blue", "Purple", "Green", "Orange" },
		Value = 1,
		ValueChanged = function(_, value)
			state.FolderColor = value
		end,
	})

	local windowsForm = pageForm(appearance, "Windows", nil)
	controls.SidebarIconSize = rowControl(windowsForm, "Sidebar icon size", nil, "PopUpButton", {
		Options = { "Small", "Medium", "Large" },
		Value = 2,
		ValueChanged = function(_, value)
			state.SidebarIconSize = value
			if tabIconStyle then
				tabIconStyle:SetSize(value)
			end
		end,
	})
	controls.WallpaperTint = rowControl(windowsForm, "Tint window background with wallpaper color", nil, "Toggle", {
		Value = true,
		ValueChanged = function(_, value)
			state.WallpaperTint = value
			applyGlassStyle()
		end,
	})

	rowControl(windowsForm, "Copy settings", "Copy the current demo settings when clipboard access is available.", "Button", {
		Label = "Copy",
		State = "Secondary",
		Pushed = function()
			local value = string.format(
				"Appearance=%s; LiquidGlass=%s; Accent=%s; TextHighlight=%d; IconStyle=%d; FolderColor=%d; SidebarIconSize=%d; WallpaperTint=%s",
				appearanceModeOptions[state.Appearance] or "Light",
				state.LiquidGlass == 2 and "Tinted" or "Clear",
				state.Accent or "Blue",
				state.TextHighlight,
				state.IconStyle,
				state.FolderColor,
				state.SidebarIconSize,
				tostring(state.WallpaperTint)
			)
			if type(setclipboard) == "function" then
				local copied, reason = pcall(setclipboard, value)
				if copied then
					print("[CascadeStyleUI] Settings copied to clipboard.")
				else
					warn("[CascadeStyleUI] Clipboard copy failed:", reason)
				end
			else
				print("[CascadeStyleUI] Clipboard API unavailable; settings:", value)
			end
		end,
	})

	local siri = system:Tab({ Title = "Apple Intelligence & Siri", Icon = cascade.Symbols.sparkles })
	tabs.Siri = siri
	local siriForm = pageForm(siri, "Apple Intelligence & Siri", "Example controls only; no assistant service is connected.")
	rowControl(siriForm, "Enable Siri", "Example preference control.", "Toggle", {
		Value = false,
		ValueChanged = function(_, value)
			print("[CascadeStyleUI] Siri sample preference:", value)
		end,
	})

	local desktop = system:Tab({ Title = "Desktop & Dock", Icon = cascade.Symbols.menubarDockRectangle })
	tabs.DesktopDock = desktop
	local desktopForm = pageForm(desktop, "Desktop & Dock", "Example desktop and dock preferences.")
	rowControl(desktopForm, "Automatically hide the Dock", nil, "Toggle", {
		Value = false,
		ValueChanged = function(_, value)
			print("[CascadeStyleUI] Auto-hide Dock:", value)
		end,
	})

	local displays = system:Tab({ Title = "Displays", Icon = cascade.Symbols.display })
	tabs.Displays = displays
	local displaysForm = pageForm(displays, "Displays", "Choose a sample display scaling option.")
	rowControl(displaysForm, "Resolution", nil, "PopUpButton", {
		Options = { "Default", "More Space", "Larger Text" },
		Value = 1,
		ValueChanged = function(_, value)
			print("[CascadeStyleUI] Display scaling:", value)
		end,
	})

	local menuBar = system:Tab({ Title = "Menu Bar", Icon = cascade.Symbols.menubarRectangle })
	tabs.MenuBar = menuBar
	local menuBarForm = pageForm(menuBar, "Menu Bar", "Example menu bar preferences.")
	rowControl(menuBarForm, "Show in menu bar", "Example preference control.", "Toggle", {
		Value = true,
		ValueChanged = function(_, value)
			print("[CascadeStyleUI] Show in menu bar:", value)
		end,
	})

	local spotlight = system:Tab({ Title = "Spotlight", Icon = cascade.Symbols.magnifyingglass })
	tabs.Spotlight = spotlight
	local spotlightForm = pageForm(spotlight, "Spotlight", "Example search preferences.")
	rowControl(spotlightForm, "Search suggestions", nil, "Toggle", {
		Value = true,
		ValueChanged = function(_, value)
			print("[CascadeStyleUI] Search suggestions:", value)
		end,
	})

	local wallpaper = system:Tab({ Title = "Wallpaper", Icon = cascade.Symbols.photo })
	tabs.Wallpaper = wallpaper
	local wallpaperForm = pageForm(wallpaper, "Wallpaper", "Choose a sample desktop wallpaper.")
	rowControl(wallpaperForm, "Desktop picture", nil, "PopUpButton", {
		Options = { "Dynamic", "Light gradient", "Dark gradient" },
		Value = 1,
		ValueChanged = function(_, value)
			print("[CascadeStyleUI] Wallpaper option:", value)
		end,
	})
	rowControl(wallpaperForm, "Show wallpaper tint", "Tint window chrome with the selected desktop picture.", "Toggle", {
		Value = true,
		ValueChanged = function(_, value)
			state.WallpaperTint = value
			applyGlassStyle()
		end,
	})

	local privacy = window:Section({ Title = "Privacy & Security", Expanded = true })
	local privacyTab = privacy:Tab({ Title = "Privacy & Security", Icon = cascade.Symbols.lock })
	tabs.PrivacySecurity = privacyTab
	local privacyForm = pageForm(privacyTab, "Privacy & Security", "Example privacy controls.")
	rowControl(privacyForm, "Analytics sharing", "Example preference control.", "Toggle", {
		Value = false,
		ValueChanged = function(_, value)
			print("[CascadeStyleUI] Analytics sharing:", value)
		end,
	})

	local locationServices = privacyTab:Tab({ Title = "Location Services", Icon = cascade.Symbols.location })
	tabs.LocationServices = locationServices
	local locationForm = pageForm(locationServices, "Location Services", "Example privacy setting.")
	rowControl(locationForm, "Location Services", nil, "Toggle", {
		Value = true,
		ValueChanged = function(_, value)
			print("[CascadeStyleUI] Location Services:", value)
		end,
	})

	local recording = privacyTab:Tab({ Title = "Screen Recording", Icon = cascade.Symbols.recordCircle })
	tabs.ScreenRecording = recording
	local recordingForm = pageForm(recording, "Screen Recording", "Example privacy setting.")
	rowControl(recordingForm, "Allow Screen Recording", nil, "Toggle", {
		Value = false,
		ValueChanged = function(_, value)
			print("[CascadeStyleUI] Screen Recording:", value)
		end,
	})

	local filesFolders = privacyTab:Tab({ Title = "Files & Folders", Icon = cascade.Symbols.folder })
	tabs.FilesFolders = filesFolders
	local filesForm = pageForm(filesFolders, "Files & Folders", "Example privacy setting.")
	rowControl(filesForm, "Allow file access", nil, "Toggle", {
		Value = false,
		ValueChanged = function(_, value)
			print("[CascadeStyleUI] File access:", value)
		end,
	})

	local automation = window:Section({ Title = "Automation", Expanded = true })
	local farmSettings = automation:Tab({ Title = "Farm Settings", Icon = cascade.Symbols.gearshape })
	tabs.FarmSettings = farmSettings
	local harvest = farmSettings:Tab({ Title = "Harvest", Icon = cascade.Symbols.leaf })
	tabs.Harvest = harvest
	local farmForm = pageForm(
		harvest,
		"Harvest settings",
		"Controls are working Cascade examples. Connect callbacks to your own permitted game logic."
	)
	rowControl(farmForm, "Auto collect", "Sample toggle callback.", "Toggle", {
		Value = false,
		ValueChanged = function(_, value)
			print("[Example] Auto collect:", value)
		end,
	})
	rowControl(farmForm, "Collection radius", "Adjust the sample value from 5 to 100.", "Slider", {
		Minimum = 5,
		Maximum = 100,
		Value = 25,
		ValueChanged = function(_, value)
			print("[Example] Collection radius:", value)
		end,
	})
	rowControl(farmForm, "Target type", nil, "PopUpButton", {
		Options = { "Coins", "Plants", "Eggs" },
		Value = 1,
		ValueChanged = function(_, value)
			print("[Example] Target type:", value)
		end,
	})
	rowControl(farmForm, "Maximum targets", nil, "Stepper", {
		Minimum = 1,
		Maximum = 20,
		Step = 1,
		Fielded = true,
		Value = 5,
		ValueChanged = function(_, value)
			print("[Example] Maximum targets:", value)
		end,
	})
	rowControl(farmForm, "Collection label", nil, "TextField", {
		Value = "Farm route A",
		Placeholder = "Name this route",
		ValueChanged = function(_, value)
			print("[Example] Collection label:", value)
		end,
	})
	rowControl(farmForm, "Toggle key", nil, "KeybindField", {
		Value = Enum.KeyCode.G,
		ValueChanged = function(_, key)
			print("[Example] New key:", key.Name)
		end,
		BindPressed = function(_, key, inputComplete, gameProcessed)
			if inputComplete and not gameProcessed then
				print("[Example] Key pressed:", key.Name)
			end
		end,
	})
	rowControl(farmForm, "Run sample action", "The button only reports that it was clicked.", "Button", {
		Label = "Run",
		State = "Primary",
		Pushed = function()
			print("[Example] Sample farm action clicked.")
		end,
	})

	tabIconStyle = styleTabIcons(tabs)
	tabIconStyle:SetValue(state.IconStyle)
	tabIconStyle:SetSize(state.SidebarIconSize)
	state.OnAccentChanged = function(color)
		if controls.AppearancePreview then
			controls.AppearancePreview:SetAccent(color)
		end
		if controls.LiquidGlass then
			controls.LiquidGlass:SetAccent(color)
		end
		if controls.IconStyle then
			controls.IconStyle:SetAccent(color)
		end
		if tabIconStyle then
			tabIconStyle:SetAccent(color)
		end
		applyGlassStyle()
	end
	state.OnAccentChanged(state.AccentColor or Color3.fromRGB(255, 69, 58))
	applyGlassStyle()

	return app, {
		Window = window,
		Tabs = tabs,
		Controls = controls,
		State = state,
	}
end

return UI
