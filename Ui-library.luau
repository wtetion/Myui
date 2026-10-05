-- CascadeStyleUI executor-ready adapter for the official Cascade UI library.
-- Load this file as a chunk; it returns the reusable UI API table.

local UI = {
	CascadeVersion = "v1.4.0",
	Version = "1.4.0",
	BuildId = "1.4.0-colored-search-icons-fix5",
}

local RELEASE_URL = "https://github.com/cascadeui/Cascade/releases/download/v1.4.0/dist.luau"
local CASCADE_CACHE_KEY = "__CascadeStyleUI_Cascade_v1_4_0"
local DEFAULT_SIGN_IN_IMAGE = "rbxassetid://86949082023913"
local SYSTEM_BLUE = Color3.fromRGB(0, 122, 255)

UI.CascadeURL = RELEASE_URL

local function isCascadeApi(value)
	return type(value) == "table"
		and type(value.New) == "function"
		and type(value.Symbols) == "table"
		and type(value.Themes) == "table"
		and type(value.Accents) == "table"
end

local function getExecutorEnvironment()
	if type(getgenv) == "function" then
		local ok, environment = pcall(getgenv)
		if ok and type(environment) == "table" then
			return environment
		end
	end
	return _G
end

local function fetchCascadeSource(url)
	local lastError = "No HTTP method is available."
	local requestMethods = {
		function()
			return game:HttpGetAsync(url)
		end,
		function()
			return game:HttpGet(url)
		end,
	}

	for _, request in ipairs(requestMethods) do
		local ok, source = pcall(request)
		if ok and type(source) == "string" and #source > 0 then
			return source
		end
		lastError = tostring(source)
	end

	error("Could not download Cascade v1.4.0 from " .. url .. ": " .. lastError, 3)
end

function UI.LoadCascade(url)
	local environment = getExecutorEnvironment()
	local cached = environment[CASCADE_CACHE_KEY]
	if isCascadeApi(cached) then
		return cached
	end

	if type(loadstring) ~= "function" then
		error("[CascadeStyleUI] This runner needs an executor that provides loadstring.", 2)
	end

	url = url or UI.CascadeURL or RELEASE_URL
	local source = fetchCascadeSource(url)
	local compileOk, chunkOrError, compileError = pcall(loadstring, source, "@Cascade-v1.4.0")
	if not compileOk or type(chunkOrError) ~= "function" then
		error("[CascadeStyleUI] Cascade v1.4.0 could not be compiled: " .. tostring(compileError or chunkOrError), 2)
	end

	local runOk, cascade = pcall(chunkOrError)
	if not runOk then
		error("[CascadeStyleUI] Cascade v1.4.0 failed during initialization: " .. tostring(cascade), 2)
	end
	if not isCascadeApi(cascade) then
		error("[CascadeStyleUI] The official release did not return a valid Cascade API.", 2)
	end

	pcall(function()
		environment[CASCADE_CACHE_KEY] = cascade
	end)
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
	if typeof(parent) ~= "Instance" then
		local ok, instance = pcall(function()
			return parent and parent.__instance
		end)
		if ok and typeof(instance) == "Instance" then
			parent = instance
		else
			error("[CascadeStyleUI] Expected an Instance parent for " .. className .. ".", 3)
		end
	end
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
	local sidebar = window.Structures.Sidebar
	local sidebarList = window.Structures.SidebarList

	-- Keep Cascade's own search listener and move its actual TextField to the
	-- fixed sidebar area below the traffic-light controls. Keeping it outside the
	-- ScrollingFrame prevents its focus glow from being clipped at the top edge.
	search.Body.AutomaticSize = Enum.AutomaticSize.None
	search.Body.Position = UDim2.fromOffset(8, 52)
	search.Body.Size = UDim2.new(1, -16, 0, 32)
	search.Body.LayoutOrder = -1000
	search.Body.ClipsDescendants = false
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
		stroke.Name = "SearchBaseStroke"
		stroke.Transparency = 1
	end
	search.Body.Parent = sidebar
	sidebarList.Position = UDim2.fromOffset(0, 92)
	sidebarList.Size = UDim2.new(1, 0, 1, -92)
	return search
end

local function addAccountSubtitle(tab, cascade, app, options)
	local structures = tab.Structures
	local body = structures.Body
	local leading = structures.Leading
	local title = structures.Title
	local symbol = structures.Symbol

	body.Size = UDim2.new(1, 0, 0, 50)
	leading.Size = UDim2.new(1, -34, 0, 0)
	symbol.Visible = true
	symbol.Size = UDim2.fromOffset(30, 30)
	title.Visible = false

	local logoImage = options.SignInLogo
	local logoImageLabel
	if logoImage == false then
		symbol.Image = cascade.Symbols.personCropCircle
		symbol.ImageColor3 = Color3.fromRGB(130, 130, 135)
	else
		logoImage = logoImage or DEFAULT_SIGN_IN_IMAGE
		symbol.Name = "SignInProfileImage"
		symbol.Image = logoImage
		symbol.ImageColor3 = Color3.new(1, 1, 1)
		symbol.ImageTransparency = 0
		symbol.BackgroundTransparency = 1
		symbol.ScaleType = Enum.ScaleType.Fit
		symbol.ClipsDescendants = true
		local avatarCorner = symbol:FindFirstChildOfClass("UICorner")
		if avatarCorner then
			avatarCorner.CornerRadius = UDim.new(1, 0)
		else
			make(symbol, "UICorner", { CornerRadius = UDim.new(1, 0) })
		end
		symbol:GetPropertyChangedSignal("ImageColor3"):Connect(function()
			if symbol.Image == logoImage and symbol.ImageColor3 ~= Color3.new(1, 1, 1) then
				symbol.ImageColor3 = Color3.new(1, 1, 1)
			end
		end)
		symbol:GetPropertyChangedSignal("ImageTransparency"):Connect(function()
			if symbol.Image == logoImage and symbol.ImageTransparency ~= 0 then
				symbol.ImageTransparency = 0
			end
		end)
		logoImageLabel = symbol
	end

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
	return titleText, subtitleText, logoImageLabel
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
	-- Keep Cascade's SF Symbols as the foreground glyphs, using the colored,
	-- rounded icon tiles shown in Cascade's Gallery navigation examples.
	local colors = {
		SoftwareUpdate = Color3.fromRGB(78, 122, 218),
		WiFi = Color3.fromRGB(0, 122, 255),
		Bluetooth = Color3.fromRGB(0, 122, 255),
		Network = Color3.fromRGB(0, 122, 255),
		VPN = Color3.fromRGB(80, 112, 206),
		Battery = Color3.fromRGB(52, 199, 89),
		General = Color3.fromRGB(135, 137, 143),
		Accessibility = Color3.fromRGB(0, 122, 255),
		Appearance = Color3.fromRGB(70, 72, 82),
		MenuBar = Color3.fromRGB(99, 99, 102),
		Siri = Color3.fromRGB(113, 81, 219),
		DesktopDock = Color3.fromRGB(48, 49, 54),
		Displays = Color3.fromRGB(0, 122, 255),
		Spotlight = Color3.fromRGB(54, 120, 246),
		Wallpaper = Color3.fromRGB(90, 200, 250),
		PrivacySecurity = Color3.fromRGB(255, 59, 48),
		LocationServices = Color3.fromRGB(0, 122, 255),
		ScreenRecording = Color3.fromRGB(255, 59, 48),
		FilesFolders = Color3.fromRGB(10, 132, 255),
		FarmSettings = Color3.fromRGB(48, 166, 101),
		Harvest = Color3.fromRGB(52, 199, 89),
	}
	local entries = {}
	local iconTitleGap = 7

	for key, tab in pairs(tabs) do
		local structures = tab.Structures
		local symbol = structures and structures.Symbol
		if symbol and key ~= "SignIn" then
			local tileColor = colors[key] or Color3.fromRGB(0, 122, 255)
			local leading = structures.Leading
			local leadingLayout = leading and leading:FindFirstChildOfClass("UIListLayout")
			if leadingLayout then
				leadingLayout.Padding = UDim.new(0, iconTitleGap)
			end
			local tile = make(leading, "Frame", {
				Name = "CascadeColorIconTile",
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				LayoutOrder = symbol.LayoutOrder,
				Size = UDim2.fromOffset(26, 26),
				ZIndex = 3,
			})
			tile:SetAttribute("CascadeIconColor", tileColor)
			local corner = make(tile, "UICorner", { CornerRadius = UDim.new(0, 8) })
			local tileGradient = make(tile, "UIGradient", {
				Name = "CascadeIconDepth",
				Rotation = 90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, tileColor:Lerp(Color3.new(1, 1, 1), 0.28)),
					ColorSequenceKeypoint.new(0.48, tileColor),
					ColorSequenceKeypoint.new(1, tileColor:Lerp(Color3.new(0, 0, 0), 0.2)),
				}),
			})
			local stroke = make(tile, "UIStroke", {
				Name = "AccentIconOutline",
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = tileColor,
				Thickness = 1.8,
				Transparency = 0,
			})
			local gloss = make(tile, "Frame", {
				Name = "CascadeIconGloss",
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.58,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(1, 1),
				Size = UDim2.new(1, -2, 0, 15),
				ZIndex = 4,
			})
			make(gloss, "UICorner", { CornerRadius = UDim.new(0, 7) })
			make(gloss, "UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)),
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.18),
					NumberSequenceKeypoint.new(0.58, 0.68),
					NumberSequenceKeypoint.new(1, 1),
				}),
			})
			local glint = make(gloss, "Frame", {
				Name = "IconGlint",
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.45,
				BorderSizePixel = 0,
				Position = UDim2.new(0.5, 0, 0, 2),
				Size = UDim2.new(0.65, 0, 0, 1),
				ZIndex = 5,
			})
			make(glint, "UICorner", { CornerRadius = UDim.new(1, 0) })
			local hasMulticolorGradient = key == "Siri"
			symbol.Parent = tile
			symbol.AnchorPoint = Vector2.new(0.5, 0.5)
			symbol.Position = UDim2.fromScale(0.5, 0.5)
			symbol.Size = UDim2.fromOffset(16, 16)
			symbol.ZIndex = 6
			symbol.LayoutOrder = 1
			symbol.ImageTransparency = 0
			structures.Body.Size = UDim2.new(1, 0, 0, 36)
			structures.Title.Size = UDim2.new(1, -(26 + iconTitleGap), 0, 20)

			local entry = {
				Key = key,
				Tile = tile,
				Stroke = stroke,
				Corner = corner,
				TileGradient = tileGradient,
				Gloss = gloss,
				Symbol = symbol,
				Title = structures.Title,
				Body = structures.Body,
				HasMulticolorGradient = hasMulticolorGradient,
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
		if typeof(accent) == "Color3" then
			self.Accent = accent
			self:SetValue(self.Value)
		end
	end
	function style:SetOutlineColor(color)
		if typeof(color) ~= "Color3" then
			return
		end
		self.OutlineColor = color
		for _, entry in ipairs(entries) do
			if entry.Stroke.Parent then
				entry.Stroke.Color = color
				entry.Stroke.Transparency = 0
			end
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
				local accent = self.Accent or SYSTEM_BLUE
				local glyphColor = Color3.new(1, 1, 1)
				local backgroundColor = entry.BaseColor
				if value == 1 then
					backgroundColor = entry.BaseColor
				elseif value == 2 then
					backgroundColor = Color3.fromRGB(53, 54, 59)
				elseif value == 3 then
					backgroundColor = entry.BaseColor:Lerp(Color3.new(1, 1, 1), 0.55)
					glyphColor = entry.BaseColor
				else
					backgroundColor = entry.BaseColor:Lerp(accent, 0.36)
				end
				tile:SetAttribute("CascadeIconColor", backgroundColor)
				tile.BackgroundColor3 = Color3.new(1, 1, 1)
				tile.BackgroundTransparency = 0
				if entry.HasMulticolorGradient and value == 1 then
					entry.TileGradient.Rotation = 35
					entry.TileGradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 84, 151)),
						ColorSequenceKeypoint.new(0.34, Color3.fromRGB(148, 91, 239)),
						ColorSequenceKeypoint.new(0.68, Color3.fromRGB(61, 163, 255)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 132, 89)),
					})
				else
					entry.TileGradient.Rotation = 90
					entry.TileGradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, backgroundColor:Lerp(Color3.new(1, 1, 1), value == 3 and 0.18 or 0.3)),
						ColorSequenceKeypoint.new(0.48, backgroundColor),
						ColorSequenceKeypoint.new(1, backgroundColor:Lerp(Color3.new(0, 0, 0), value == 2 and 0.12 or 0.2)),
					})
				end
				entry.Stroke.Color = self.OutlineColor or accent
				entry.Stroke.Thickness = value == 4 and 2.2 or 1.8
				entry.Stroke.Transparency = 0
				entry.Gloss.BackgroundTransparency = value == 2 and 0.76 or value == 3 and 0.68 or 0.58
				entry.GlyphColor = glyphColor
				symbol.ImageColor3 = glyphColor
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
				entry.Title.Size = UDim2.new(1, -(iconSize + iconTitleGap), 0, 20)
				entry.Corner.CornerRadius = UDim.new(0, math.max(6, math.floor(iconSize * 0.27)))
			end
		end
	end
	style:SetValue(1)
	style:SetSize(2)
	return style
end

local function configureSearchSuggestions(window, search, tabs)
	local rootStructure = window.Structures.Body
	local root = typeof(rootStructure) == "Instance" and rootStructure or rootStructure and rootStructure.__instance
	local bodyStructure = search.Body
	local body = typeof(bodyStructure) == "Instance" and bodyStructure or bodyStructure and bodyStructure.__instance
	if not root or not body then
		error("[CascadeStyleUI] Cascade v1.4.0 did not expose the window and search instances.", 2)
	end
	local tweenService = game:GetService("TweenService")
	local focusBlue = Color3.fromRGB(72, 133, 255)
	local isFocused = false
	local choosingSuggestion = false

	search.Field.PlaceholderText = "Search"
	search.Field.TextXAlignment = Enum.TextXAlignment.Left
	local searchIcon = body:FindFirstChild("ImageLabel")
	if searchIcon then
		searchIcon.LayoutOrder = 0
		searchIcon.Size = UDim2.fromOffset(14, 14)
		searchIcon.ImageColor3 = Color3.fromRGB(128, 132, 139)
	end

	local focusStroke = body:FindFirstChild("SearchFocusStroke")
	if not focusStroke then
		focusStroke = make(body, "UIStroke", {
			Name = "SearchFocusStroke",
			Color = focusBlue,
			Thickness = 2,
			Transparency = 1,
		})
	end
	focusStroke.Color = focusBlue
	focusStroke.Thickness = 2
	focusStroke.Transparency = 1

	local glowStroke = body:FindFirstChild("SearchFocusGlow")
	if not glowStroke then
		glowStroke = make(body, "UIStroke", {
			Name = "SearchFocusGlow",
			Color = focusBlue,
			Thickness = 7,
			Transparency = 1,
		})
	end

	local shadow = make(root, "Frame", {
		Name = "SearchSuggestionsShadow",
		BackgroundColor3 = Color3.fromRGB(20, 24, 32),
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(190, 250),
		Visible = false,
		ZIndex = 199,
	})
	make(shadow, "UICorner", { CornerRadius = UDim.new(0, 12) })

	local panel = make(root, "Frame", {
		Name = "SearchSuggestions",
		BackgroundColor3 = Color3.fromRGB(247, 247, 249),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(190, 250),
		Visible = false,
		ZIndex = 200,
	})
	make(panel, "UICorner", { CornerRadius = UDim.new(0, 12) })
	local panelScale = make(panel, "UIScale", { Scale = 0.94 })
	make(panel, "UIStroke", {
		Color = Color3.fromRGB(190, 193, 200),
		Transparency = 0.18,
		Thickness = 1,
	})

	local header = make(panel, "TextLabel", {
		Name = "SuggestionsHeader",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		FontFace = Font.new("rbxassetid://12187365364"),
		Position = UDim2.fromOffset(14, 7),
		Size = UDim2.new(1, -28, 0, 21),
		Text = "Suggestions",
		TextColor3 = Color3.fromRGB(147, 149, 155),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 202,
	})

	local list = make(panel, "ScrollingFrame", {
		Name = "SuggestionList",
		Active = true,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		Position = UDim2.fromOffset(8, 29),
		ScrollBarThickness = 0,
		Size = UDim2.new(1, -16, 1, -36),
		ZIndex = 201,
	})
	make(list, "UIListLayout", {
		Name = "SuggestionLayout",
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local suggestedKeys = { "Displays", "Battery", "PrivacySecurity", "Bluetooth", "DesktopDock" }
	local popupShown = false
	local function updatePosition(resultCount)
		local rootPosition = root.AbsolutePosition
		local searchPosition = body.AbsolutePosition
		local searchSize = body.AbsoluteSize
		local x = math.max(7, searchPosition.X - rootPosition.X)
		local y = searchPosition.Y - rootPosition.Y + searchSize.Y + 3
		local width = math.max(190, searchSize.X + 18)
		local widthLimit = math.max(190, root.AbsoluteSize.X - x - 8)
		width = math.min(width, widthLimit)
		local rows = math.min(math.max(resultCount, 1), 6)
		local height = 38 + rows * 42

		shadow.Position = UDim2.fromOffset(x + 1, y + 3)
		shadow.Size = UDim2.fromOffset(width, height)
		panel.Position = UDim2.fromOffset(x, y)
		panel.Size = UDim2.fromOffset(width, height)
	end

	local function showDropdown()
		if popupShown then
			panel.Visible = true
			shadow.Visible = true
			return
		end
		popupShown = true
		local targetPosition = panel.Position
		local shadowTarget = shadow.Position
		panel.Visible = true
		shadow.Visible = true
		panel.Position = UDim2.new(targetPosition.X.Scale, targetPosition.X.Offset, targetPosition.Y.Scale, targetPosition.Y.Offset - 9)
		shadow.Position = UDim2.new(shadowTarget.X.Scale, shadowTarget.X.Offset, shadowTarget.Y.Scale, shadowTarget.Y.Offset - 7)
		panel.BackgroundTransparency = 1
		shadow.BackgroundTransparency = 1
		panelScale.Scale = 0.94
		local tweenInfo = TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		tweenService:Create(panel, tweenInfo, {
			Position = targetPosition,
			BackgroundTransparency = 0.02,
		}):Play()
		tweenService:Create(shadow, tweenInfo, {
			Position = shadowTarget,
			BackgroundTransparency = 0.88,
		}):Play()
		tweenService:Create(panelScale, tweenInfo, { Scale = 1 }):Play()
	end

	local function hideDropdown()
		if not popupShown then
			panel.Visible = false
			shadow.Visible = false
			return
		end
		popupShown = false
		local currentPosition = panel.Position
		local currentShadowPosition = shadow.Position
		local targetPosition = UDim2.new(currentPosition.X.Scale, currentPosition.X.Offset, currentPosition.Y.Scale, currentPosition.Y.Offset - 7)
		local shadowTarget = UDim2.new(currentShadowPosition.X.Scale, currentShadowPosition.X.Offset, currentShadowPosition.Y.Scale, currentShadowPosition.Y.Offset - 5)
		local tweenInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tweenService:Create(panel, tweenInfo, {
			Position = targetPosition,
			BackgroundTransparency = 1,
		}):Play()
		tweenService:Create(shadow, tweenInfo, {
			Position = shadowTarget,
			BackgroundTransparency = 1,
		}):Play()
		tweenService:Create(panelScale, tweenInfo, { Scale = 0.96 }):Play()
		task.delay(0.13, function()
			if not popupShown then
				panel.Visible = false
				shadow.Visible = false
			end
		end)
	end

	local function setFocusVisual(active)
		local focusGoals = active and {
			Color = focusBlue,
			Thickness = 2,
			Transparency = 0.02,
		} or {
			Color = Color3.fromRGB(190, 193, 200),
			Thickness = 1,
			Transparency = 0.28,
		}
		local glowGoals = active and {
			Color = focusBlue,
			Thickness = 7,
			Transparency = 0.78,
		} or {
			Color = focusBlue,
			Thickness = 7,
			Transparency = 1,
		}
		local tweenInfo = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		pcall(function()
			tweenService:Create(focusStroke, tweenInfo, focusGoals):Play()
			tweenService:Create(glowStroke, tweenInfo, glowGoals):Play()
		end)
	end

	local function clearResults()
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("GuiButton") or child.Name == "NoResults" then
				child:Destroy()
			end
		end
	end

	local function readTabTitle(tab)
		local title = tab and tab.Structures and tab.Structures.Title
		return title and tostring(title.Text) or "Settings"
	end

	local function buildResult(key, tab, order)
		local title = readTabTitle(tab)
		local structures = tab.Structures
		local symbol = structures and structures.Symbol
		local tileColor = Color3.fromRGB(0, 122, 255)
		local iconImage = ""
		if symbol then
			iconImage = symbol.Image or ""
			local iconTile = symbol.Parent
			if iconTile and iconTile:IsA("GuiObject") then
				local savedColor = iconTile:GetAttribute("CascadeIconColor")
				if typeof(savedColor) == "Color3" then
					tileColor = savedColor
				else
					tileColor = iconTile.BackgroundColor3
				end
			end
		end

		local button = make(list, "TextButton", {
			Name = "Suggestion_" .. key,
			AutoButtonColor = false,
			BackgroundColor3 = Color3.fromRGB(232, 235, 240),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 39),
			Text = "",
			ZIndex = 203,
		})
		make(button, "UICorner", { CornerRadius = UDim.new(0, 7) })
		local iconTile = make(button, "Frame", {
			Name = "IconTile",
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(8, 6),
			Size = UDim2.fromOffset(27, 27),
			ZIndex = 204,
		})
		make(iconTile, "UICorner", { CornerRadius = UDim.new(0, 7) })
		make(iconTile, "UIGradient", {
			Name = "CascadeSuggestionIconDepth",
			Rotation = 90,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, tileColor:Lerp(Color3.new(1, 1, 1), 0.28)),
				ColorSequenceKeypoint.new(0.48, tileColor),
				ColorSequenceKeypoint.new(1, tileColor:Lerp(Color3.new(0, 0, 0), 0.2)),
			}),
		})
		if iconImage ~= "" then
			local icon = make(iconTile, "ImageLabel", {
				Name = "Icon",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = iconImage,
				ImageColor3 = Color3.new(1, 1, 1),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(17, 17),
				ZIndex = 205,
			})
			icon.ScaleType = Enum.ScaleType.Fit
		end
		make(button, "TextLabel", {
			Name = "Title",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			FontFace = Font.new("rbxassetid://12187365364"),
			Position = UDim2.fromOffset(47, 0),
			Size = UDim2.new(1, -55, 1, 0),
			Text = title,
			TextColor3 = Color3.fromRGB(35, 36, 39),
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 205,
		})

		button.MouseEnter:Connect(function()
			button.BackgroundTransparency = 0.35
		end)
		button.MouseLeave:Connect(function()
			button.BackgroundTransparency = 1
		end)
		button.Activated:Connect(function()
			choosingSuggestion = true
			isFocused = false
			hideDropdown()
			search.Field.Text = ""
			tab.Selected = true
			choosingSuggestion = false
			setFocusVisual(false)
		end)
	end

	local function renderSuggestions()
		clearResults()
		local query = tostring(search.Field.Text or ""):lower()
		query = query:match("^%s*(.-)%s*$") or query
		local results = {}

		if query == "" then
			for _, key in ipairs(suggestedKeys) do
				if tabs[key] then
					table.insert(results, { Key = key, Tab = tabs[key] })
				end
			end
		else
			for key, tab in pairs(tabs) do
				local title = readTabTitle(tab)
				if title:lower():find(query, 1, true) then
					table.insert(results, { Key = key, Tab = tab, Title = title })
				end
			end
			table.sort(results, function(left, right)
				return left.Title:lower() < right.Title:lower()
			end)
		end

		if #results == 0 then
			make(list, "TextLabel", {
				Name = "NoResults",
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxassetid://12187365364"),
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, 36),
				Text = "No Results",
				TextColor3 = Color3.fromRGB(147, 149, 155),
				TextSize = 14,
				ZIndex = 203,
			})
		end
		for index, result in ipairs(results) do
			buildResult(result.Key, result.Tab, index)
		end
		updatePosition(#results)
		if isFocused then
			showDropdown()
		else
			hideDropdown()
		end
	end

	search.Field.Focused:Connect(function()
		isFocused = true
		setFocusVisual(true)
		renderSuggestions()
	end)
	search.Field.FocusLost:Connect(function()
		isFocused = false
		setFocusVisual(false)
		task.delay(0.16, function()
			if not choosingSuggestion then
				hideDropdown()
			end
		end)
	end)
	search.Field:GetPropertyChangedSignal("Text"):Connect(function()
		if isFocused then
			renderSuggestions()
		end
	end)
	body:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
		updatePosition(5)
	end)
	body:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		updatePosition(5)
	end)
	root:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
		updatePosition(5)
	end)
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		updatePosition(5)
	end)
	updatePosition(5)
end

local function animateSearchEntrance(search)
	local bodyStructure = search and search.Body
	local body = typeof(bodyStructure) == "Instance" and bodyStructure or bodyStructure and bodyStructure.__instance
	if not body or not body.Parent then
		return
	end
	local tweenService = game:GetService("TweenService")
	local targetPosition = body.Position
	local targetTransparency = body.BackgroundTransparency
	local startPosition = UDim2.new(targetPosition.X.Scale, targetPosition.X.Offset, targetPosition.Y.Scale, targetPosition.Y.Offset - 10)
	local scale = body:FindFirstChild("SearchEntranceScale") or make(body, "UIScale", {
		Name = "SearchEntranceScale",
		Scale = 0.96,
	})
	body.Position = startPosition
	body.BackgroundTransparency = math.max(targetTransparency, 0.58)
	tweenService:Create(body, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = targetPosition,
		BackgroundTransparency = targetTransparency,
	}):Play()
	tweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Scale = 1,
	}):Play()
end

local function configureTitlebarNavigation(window)
	local titlebar = window.Structures.Titlebar
	local group = titlebar and titlebar.NavigationButtons
	local back = titlebar and titlebar.Back
	local forward = titlebar and titlebar.Forward
	if not group or not back or not forward then
		return function() end
	end

	group.AutomaticSize = Enum.AutomaticSize.None
	group.Size = UDim2.fromOffset(66, 32)
	group.BackgroundTransparency = 0
	group.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	group.BorderSizePixel = 0
	local corner = group:FindFirstChildOfClass("UICorner")
	if corner then
		corner.CornerRadius = UDim.new(1, 0)
	else
		make(group, "UICorner", { CornerRadius = UDim.new(1, 0) })
	end
	local outline = group:FindFirstChildOfClass("UIStroke")
	if not outline then
		outline = make(group, "UIStroke", {
			Color = Color3.fromRGB(222, 224, 230),
			Transparency = 0.15,
			Thickness = 1,
		})
	end
	local layout = group:FindFirstChildOfClass("UIListLayout")
	if not layout then
		layout = make(group, "UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
		})
	end
	layout.Padding = UDim.new(0, 0)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	back.LayoutOrder = 1
	forward.LayoutOrder = 3
	for _, button in ipairs({ back, forward }) do
		button.AutoButtonColor = false
		button.BackgroundTransparency = 1
		button.Size = UDim2.fromOffset(32, 28)
		button.ZIndex = 4
		for _, descendant in ipairs(button:GetDescendants()) do
			if descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
				descendant.ZIndex = 6
			end
		end
	end
	local divider = group:FindFirstChild("HistoryDivider")
	if not divider then
		divider = make(group, "Frame", {
			Name = "HistoryDivider",
			BackgroundColor3 = Color3.fromRGB(211, 213, 218),
			BorderSizePixel = 0,
			LayoutOrder = 2,
			Size = UDim2.fromOffset(1, 15),
			ZIndex = 6,
		})
	end
	local function setDark(dark)
		group.BackgroundColor3 = dark and Color3.fromRGB(62, 63, 68) or Color3.fromRGB(255, 255, 255)
		outline.Color = dark and Color3.fromRGB(104, 106, 112) or Color3.fromRGB(222, 224, 230)
		divider.BackgroundColor3 = dark and Color3.fromRGB(107, 109, 115) or Color3.fromRGB(211, 213, 218)
	end
	setDark(false)
	return setDark
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

local function createHSVColorPicker(window, anchor, initialColor, title, onApply)
	local rootStructure = window.Structures.Body
	local root = typeof(rootStructure) == "Instance" and rootStructure or rootStructure and rootStructure.__instance
	if not root or not anchor then
		return
	end

	local width, height = 276, 270
	local rootPosition = root.AbsolutePosition
	local anchorPosition = anchor.AbsolutePosition
	local rootSize = root.AbsoluteSize
	local x = math.clamp(anchorPosition.X - rootPosition.X, 8, math.max(8, rootSize.X - width - 8))
	local y = anchorPosition.Y - rootPosition.Y + anchor.AbsoluteSize.Y + 6
	if y + height > rootSize.Y - 8 then
		y = math.max(8, anchorPosition.Y - rootPosition.Y - height - 6)
	end

	local tweenService = game:GetService("TweenService")
	local userInputService = game:GetService("UserInputService")
	local connections = {}
	local hue, saturation, value = Color3.toHSV(initialColor or SYSTEM_BLUE)
	local dragging = nil
	local closed = false

	local backdrop = make(root, "TextButton", {
		Name = "WindUIColorPickerBackdrop",
		Active = true,
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		ZIndex = 299,
	})
	local panel = make(root, "Frame", {
		Name = "WindUIColorPicker",
		BackgroundColor3 = Color3.fromRGB(250, 250, 252),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(x, math.max(0, y - 8)),
		Size = UDim2.fromOffset(width, height),
		ZIndex = 300,
	})
	make(panel, "UICorner", { CornerRadius = UDim.new(0, 12) })
	make(panel, "UIStroke", {
		Color = Color3.fromRGB(205, 207, 213),
		Transparency = 0.12,
		Thickness = 1,
	})
	local panelScale = make(panel, "UIScale", { Scale = 0.94 })

	local heading = make(panel, "TextLabel", {
		BackgroundTransparency = 1,
		FontFace = Font.new("rbxassetid://12187365364"),
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -28, 0, 23),
		Text = title or "Choose Colour",
		TextColor3 = Color3.fromRGB(38, 39, 43),
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 302,
	})
	local wheel = make(panel, "Frame", {
		Name = "ColorWheel",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(14, 42),
		Size = UDim2.fromOffset(174, 174),
		ZIndex = 302,
	})
	local wheelCenter = 87
	local wheelRadius = 80
	local wheelDots = 56
	local wheelSelector = make(wheel, "Frame", {
		Name = "WheelSelector",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(wheelCenter, wheelCenter - wheelRadius),
		Size = UDim2.fromOffset(18, 18),
		ZIndex = 306,
	})
	make(wheelSelector, "UICorner", { CornerRadius = UDim.new(1, 0) })
	make(wheelSelector, "UIStroke", { Color = Color3.fromRGB(55, 57, 63), Thickness = 1.5 })
	local wheelSelectorInner = make(wheelSelector, "Frame", {
		Name = "WheelSelectorInner",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(14, 14),
		ZIndex = 307,
	})
	make(wheelSelectorInner, "UICorner", { CornerRadius = UDim.new(1, 0) })
	make(wheelSelectorInner, "UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 })

	local surface = make(wheel, "ImageLabel", {
		Name = "SaturationValueSurface",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
		BorderSizePixel = 0,
		Image = "rbxassetid://4155801252",
		Position = UDim2.fromOffset(wheelCenter, wheelCenter),
		Size = UDim2.fromOffset(96, 96),
		ZIndex = 303,
	})
	make(surface, "UICorner", { CornerRadius = UDim.new(0, 8) })
	make(surface, "UIStroke", {
		Color = Color3.fromRGB(205, 207, 213),
		Transparency = 0.25,
		Thickness = 1,
	})
	local surfaceInput = make(surface, "TextButton", {
		Name = "SurfaceInput",
		Active = true,
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		ZIndex = 304,
	})
	local selector = make(surfaceInput, "Frame", {
		Name = "ColorSelector",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = SYSTEM_BLUE,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(saturation, 1 - value),
		Size = UDim2.fromOffset(13, 13),
		ZIndex = 305,
	})
	make(selector, "UICorner", { CornerRadius = UDim.new(1, 0) })
	make(selector, "UIStroke", {
		Color = Color3.new(1, 1, 1),
		Thickness = 2,
		Transparency = 0.05,
	})

	local updateColor, setWheelHue, isPointerInput
	for index = 0, wheelDots - 1 do
		local dotHue = index / wheelDots
		local angle = dotHue * math.pi * 2 - math.pi / 2
		local dot = make(wheel, "ImageButton", {
			Name = "Hue_" .. tostring(index + 1),
			AutoButtonColor = false,
			BackgroundColor3 = Color3.fromHSV(dotHue, 1, 1),
			BorderSizePixel = 0,
			Image = "",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(wheelCenter + math.cos(angle) * wheelRadius, wheelCenter + math.sin(angle) * wheelRadius),
			Size = UDim2.fromOffset(12, 12),
			ZIndex = 304,
		})
		make(dot, "UICorner", { CornerRadius = UDim.new(1, 0) })
		dot.InputBegan:Connect(function(input)
			if isPointerInput(input) then
				dragging = "wheel"
				setWheelHue(Vector2.new(input.Position.X, input.Position.Y))
			end
		end)
		dot.Activated:Connect(function()
			hue = dotHue
			updateColor()
		end)
	end

	local preview = make(panel, "Frame", {
		Name = "ColorPreview",
		BackgroundColor3 = initialColor or SYSTEM_BLUE,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(207, 54),
		Size = UDim2.fromOffset(42, 42),
		ZIndex = 302,
	})
	make(preview, "UICorner", { CornerRadius = UDim.new(1, 0) })
	make(preview, "UIStroke", { Color = Color3.fromRGB(205, 207, 213), Thickness = 1 })
	local hex = make(panel, "TextLabel", {
		BackgroundTransparency = 1,
		FontFace = Font.new("rbxassetid://12187365364"),
		Position = UDim2.fromOffset(198, 106),
		Size = UDim2.fromOffset(68, 23),
		Text = "#007AFF",
		TextColor3 = Color3.fromRGB(78, 80, 86),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 302,
	})

	local cancel = make(panel, "TextButton", {
		Name = "Cancel",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(238, 239, 242),
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(130, 231),
		Size = UDim2.fromOffset(62, 27),
		Text = "Cancel",
		TextColor3 = Color3.fromRGB(52, 53, 58),
		TextSize = 12,
		ZIndex = 303,
	})
	make(cancel, "UICorner", { CornerRadius = UDim.new(0, 7) })
	local apply = make(panel, "TextButton", {
		Name = "Apply",
		AutoButtonColor = false,
		BackgroundColor3 = SYSTEM_BLUE,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(198, 231),
		Size = UDim2.fromOffset(64, 27),
		Text = "Apply",
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 12,
		ZIndex = 303,
	})
	make(apply, "UICorner", { CornerRadius = UDim.new(0, 7) })

	local function disconnectAll()
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		table.clear(connections)
	end
	local function close()
		if closed then
			return
		end
		closed = true
		dragging = nil
		disconnectAll()
		tweenService:Create(panelScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.95 }):Play()
		tweenService:Create(panel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.fromOffset(x, y - 8),
			BackgroundTransparency = 1,
		}):Play()
		task.delay(0.13, function()
			if backdrop.Parent then backdrop:Destroy() end
			if panel.Parent then panel:Destroy() end
		end)
	end
	local function updateWheelSelector()
		local angle = hue * math.pi * 2 - math.pi / 2
		wheelSelector.Position = UDim2.fromOffset(wheelCenter + math.cos(angle) * wheelRadius, wheelCenter + math.sin(angle) * wheelRadius)
	end
	updateColor = function()
		local color = Color3.fromHSV(hue, saturation, value)
		surface.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
		selector.Position = UDim2.new(saturation, 0, 1 - value, 0)
		selector.BackgroundColor3 = color
		wheelSelectorInner.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
		updateWheelSelector()
		preview.BackgroundColor3 = color
		hex.Text = "#" .. color:ToHex():upper()
	end
	local function setSurface(position)
		local size = surface.AbsoluteSize
		if size.X <= 0 or size.Y <= 0 then return end
		local origin = surface.AbsolutePosition
		saturation = math.clamp((position.X - origin.X) / size.X, 0, 1)
		value = 1 - math.clamp((position.Y - origin.Y) / size.Y, 0, 1)
		updateColor()
	end
	setWheelHue = function(position)
		local center = wheel.AbsolutePosition + Vector2.new(wheelCenter, wheelCenter)
		local dx, dy = position.X - center.X, position.Y - center.Y
		local angle = math.atan2(dy, dx) + math.pi / 2
		hue = (angle / (math.pi * 2)) % 1
		updateColor()
	end
	isPointerInput = function(input)
		return input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
	end
	connections[#connections + 1] = surfaceInput.InputBegan:Connect(function(input)
		if isPointerInput(input) then
			dragging = "surface"
			setSurface(Vector2.new(input.Position.X, input.Position.Y))
		end
	end)
	connections[#connections + 1] = userInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local position = Vector2.new(input.Position.X, input.Position.Y)
			if dragging == "surface" then
				setSurface(position)
			elseif dragging == "wheel" then
				setWheelHue(position)
			end
		end
	end)
	connections[#connections + 1] = userInputService.InputEnded:Connect(function(input)
		if isPointerInput(input) then dragging = nil end
	end)
	backdrop.Activated:Connect(close)
	cancel.Activated:Connect(close)
	apply.Activated:Connect(function()
		if onApply then onApply(Color3.fromHSV(hue, saturation, value)) end
		close()
	end)
	updateColor()
	tweenService:Create(panelScale, TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	tweenService:Create(panel, TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.fromOffset(x, y),
		BackgroundTransparency = 0.03,
	}):Play()
	return { Close = close, Panel = panel }
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
			local iconTile = card:FindFirstChild("StyleIconPreview")
			local iconStroke = iconTile and iconTile:FindFirstChild("StyleIconOutline")
			if iconStroke then
				iconStroke.Color = accent
				iconStroke.Transparency = i == index and 0 or 1
				iconStroke.Thickness = i == index and 2 or 1
			end
		end
		if fireCallback ~= false and onChanged then
			onChanged(index)
		end
	end

	for index, option in ipairs(options) do
		local card = make(holder, "TextButton", {
			Name = "Choice_" .. tostring(index),
			AutoButtonColor = false,
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
			make(iconTile, "UIStroke", {
				Name = "StyleIconOutline",
				Color = Color3.fromRGB(0, 122, 255),
				Transparency = 1,
				Thickness = 2,
			})
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
		card.MouseEnter:Connect(function()
			local stroke = card:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = accent
				stroke.Transparency = 0
				stroke.Thickness = 2
			end
			local iconTile = card:FindFirstChild("StyleIconPreview")
			local iconStroke = iconTile and iconTile:FindFirstChild("StyleIconOutline")
			if iconStroke then
				iconStroke.Color = accent
				iconStroke.Transparency = 0
				iconStroke.Thickness = 2
			end
		end)
		card.MouseLeave:Connect(function()
			refreshCard(card, index == handle.Value, accent)
			local iconTile = card:FindFirstChild("StyleIconPreview")
			local iconStroke = iconTile and iconTile:FindFirstChild("StyleIconOutline")
			if iconStroke then
				iconStroke.Color = accent
				iconStroke.Transparency = index == handle.Value and 0 or 1
				iconStroke.Thickness = index == handle.Value and 2 or 1
			end
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

local function makeAccentSwatches(form, cascade, app, state, window)
	local parent = customRow(form, "Color", "Choose an accent color or Multicolor.")
	local palette = {
		{ "Multicolor", SYSTEM_BLUE },
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
		Size = UDim2.fromOffset(322, 32),
	})
	make(holder, "UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 5),
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
				stroke.Color = i == index and SYSTEM_BLUE or Color3.fromRGB(130, 130, 135)
				stroke.Thickness = i == index and 3 or 1
				stroke.Transparency = i == index and 0 or 0.68
			end
		end
		if fireCallback ~= false then
			local accentName = palette[index][1] == "Multicolor" and "Blue" or palette[index][1]
			local accent = cascade.Accents[accentName]
			if palette[index][1] == "Graphite" then
				accent = cascade.Accents.Gray or cascade.Accents.Graphite or accent
			end
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
			AutoButtonColor = false,
			BackgroundColor3 = item[2],
			BorderSizePixel = 0,
			LayoutOrder = index == 1 and 1 or index + 1,
			Size = UDim2.fromOffset(index == 1 and 28 or 22, index == 1 and 28 or 22),
		})
		make(button, "UICorner", { CornerRadius = UDim.new(1, 0) })
		make(button, "UIStroke", {
			Color = Color3.fromRGB(130, 130, 135),
			Transparency = 0.68,
			Thickness = 1,
		})
		if item[1] == "Multicolor" then
			make(button, "UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 61, 73)),
					ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 188, 54)),
					ColorSequenceKeypoint.new(0.4, Color3.fromRGB(60, 199, 89)),
					ColorSequenceKeypoint.new(0.6, Color3.fromRGB(32, 163, 255)),
					ColorSequenceKeypoint.new(0.8, Color3.fromRGB(113, 101, 255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(238, 70, 205)),
				}),
			})
			make(holder, "TextLabel", {
				Name = "MulticolorLabel",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				FontFace = Font.new("rbxassetid://12187365364"),
				LayoutOrder = 2,
				Size = UDim2.fromOffset(68, 24),
				Text = "Multicolor",
				TextColor3 = Color3.fromRGB(62, 63, 68),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
		end
		button.MouseEnter:Connect(function()
			local stroke = button:FindFirstChildOfClass("UIStroke")
			if stroke and index ~= handle.Value then
				stroke.Color = SYSTEM_BLUE
				stroke.Transparency = 0.15
				stroke.Thickness = 1.5
			end
		end)
		button.MouseLeave:Connect(function()
			local stroke = button:FindFirstChildOfClass("UIStroke")
			if stroke and index ~= handle.Value then
				stroke.Color = Color3.fromRGB(130, 130, 135)
				stroke.Transparency = 0.68
				stroke.Thickness = 1
			end
		end)
		button.Activated:Connect(function()
			select(index, true)
			if index == 1 then
				createHSVColorPicker(window, button, state.CustomAccentColor or state.AccentColor, "Choose Accent Colour", function(color)
					state.Accent = "Custom"
					state.AccentColor = color
					state.CustomAccentColor = color
					local bestIndex, bestDistance = 2, math.huge
					for candidate = 2, #palette do
						local optionColor = palette[candidate][2]
						local dr = color.R - optionColor.R
						local dg = color.G - optionColor.G
						local db = color.B - optionColor.B
						local distance = dr * dr + dg * dg + db * db
						if distance < bestDistance then
							bestDistance = distance
							bestIndex = candidate
						end
					end
					local accentName = palette[bestIndex][1]
					local nearestAccent = cascade.Accents[accentName]
					if accentName == "Graphite" then
						nearestAccent = cascade.Accents.Gray or cascade.Accents.Graphite or nearestAccent
					end
					if nearestAccent then app.Accent = nearestAccent end
					if state.OnAccentChanged then state.OnAccentChanged(color, 1) end
				end)
			end
		end)
		table.insert(swatches, button)
	end

	handle.SetValue = function(_, value, fireCallback)
		select(value, fireCallback)
	end
	select(1, false)
	return handle
end

local function makeFolderColorPicker(form, window, state)
	local parent = customRow(form, "Icon, widget & folder colour", nil)
	local palette = {
		{ "Automatic", SYSTEM_BLUE },
		{ "Red", Color3.fromRGB(255, 69, 58) },
		{ "Orange", Color3.fromRGB(255, 159, 10) },
		{ "Yellow", Color3.fromRGB(255, 214, 10) },
		{ "Green", Color3.fromRGB(50, 215, 75) },
		{ "Blue", Color3.fromRGB(10, 132, 255) },
		{ "Purple", Color3.fromRGB(191, 90, 242) },
		{ "Pink", Color3.fromRGB(255, 55, 95) },
		{ "Graphite", Color3.fromRGB(142, 142, 147) },
	}
	local button = make(parent, "TextButton", {
		Name = "FolderColorMenuButton",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(244, 245, 247),
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Size = UDim2.fromOffset(174, 30),
		Text = "",
	})
	make(button, "UICorner", { CornerRadius = UDim.new(0, 8) })
	make(button, "UIStroke", {
		Color = Color3.fromRGB(215, 217, 222),
		Transparency = 0.25,
		Thickness = 1,
	})
	local dot = make(button, "Frame", {
		Name = "SelectedColorDot",
		BackgroundColor3 = palette[state.FolderColor or 1][2],
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(9, 8),
		Size = UDim2.fromOffset(14, 14),
	})
	make(dot, "UICorner", { CornerRadius = UDim.new(1, 0) })
	local label = make(button, "TextLabel", {
		Name = "SelectedColorLabel",
		BackgroundTransparency = 1,
		FontFace = Font.new("rbxassetid://12187365364"),
		Position = UDim2.fromOffset(31, 0),
		Size = UDim2.new(1, -56, 1, 0),
		Text = "Automatic",
		TextColor3 = Color3.fromRGB(43, 45, 49),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	make(button, "TextLabel", {
		Name = "MenuChevron",
		BackgroundTransparency = 1,
		FontFace = Font.new("rbxassetid://12187365364"),
		Position = UDim2.new(1, -27, 0, 0),
		Size = UDim2.fromOffset(20, 30),
		Text = "⌄",
		TextColor3 = Color3.fromRGB(103, 105, 111),
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	local handle = { Value = state.FolderColor or 1 }
	local function selectedFolderColor()
		if handle.Value == #palette + 1 then
			return state.FolderCustomColor or state.AccentColor or SYSTEM_BLUE
		end
		local option = palette[handle.Value] or palette[1]
		if option[1] == "Automatic" then
			return state.AccentColor or SYSTEM_BLUE
		end
		return option[2]
	end
	local function notifyFolderColorChanged()
		state.IconFrameColor = selectedFolderColor()
		if state.OnFolderColorChanged then
			state.OnFolderColorChanged(state.IconFrameColor)
		end
	end
	local activeBackdrop
	local activeMenu
	local activeScale
	local menuTween
	local function updateButton()
		if handle.Value == #palette + 1 then
			label.Text = "Custom"
			dot.BackgroundColor3 = state.FolderCustomColor or SYSTEM_BLUE
		else
			local option = palette[handle.Value] or palette[1]
			label.Text = option[1]
			dot.BackgroundColor3 = option[2]
		end
		state.IconFrameColor = selectedFolderColor()
	end
	local function closeMenu()
		if not activeMenu then return end
		local menu = activeMenu
		local backdrop = activeBackdrop
		local scale = activeScale
		activeMenu, activeBackdrop, activeScale = nil, nil, nil
		if menuTween then menuTween:Cancel() end
		menuTween = game:GetService("TweenService"):Create(scale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.95 })
		menuTween:Play()
		game:GetService("TweenService"):Create(menu, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
		}):Play()
		task.delay(0.11, function()
			if menu.Parent then menu:Destroy() end
			if backdrop.Parent then backdrop:Destroy() end
		end)
	end
	local function chooseOption(index)
		handle.Value = index
		state.FolderColor = index
		state.FolderCustomColor = nil
		updateButton()
		notifyFolderColorChanged()
		closeMenu()
	end
	local function openMenu()
		if activeMenu then
			closeMenu()
			return
		end
		local rootStructure = window.Structures.Body
		local root = typeof(rootStructure) == "Instance" and rootStructure or rootStructure and rootStructure.__instance
		if not root then return end
		local menuWidth, menuHeight = 208, 286
		local rootPosition, rootSize = root.AbsolutePosition, root.AbsoluteSize
		local buttonPosition = button.AbsolutePosition
		local x = math.clamp(buttonPosition.X - rootPosition.X + button.AbsoluteSize.X - menuWidth, 8, math.max(8, rootSize.X - menuWidth - 8))
		local y = buttonPosition.Y - rootPosition.Y + button.AbsoluteSize.Y + 5
		if y + menuHeight > rootSize.Y - 8 then
			y = math.max(8, buttonPosition.Y - rootPosition.Y - menuHeight - 5)
		end
		local dark = state.Appearance == 3
		local backdrop = make(root, "TextButton", {
			Name = "FolderColorMenuBackdrop",
			Active = true,
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			Text = "",
			ZIndex = 389,
		})
		local menu = make(root, "Frame", {
			Name = "FolderColorMenu",
			BackgroundColor3 = dark and Color3.fromRGB(48, 49, 53) or Color3.fromRGB(250, 250, 252),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(x, math.max(0, y - 8)),
			Size = UDim2.fromOffset(menuWidth, menuHeight),
			ZIndex = 390,
		})
		activeBackdrop, activeMenu = backdrop, menu
		make(menu, "UICorner", { CornerRadius = UDim.new(0, 11) })
		make(menu, "UIStroke", {
			Color = dark and Color3.fromRGB(99, 101, 108) or Color3.fromRGB(206, 208, 214),
			Transparency = 0.14,
			Thickness = 1,
		})
		local scale = make(menu, "UIScale", { Scale = 0.95 })
		activeScale = scale
		for index, option in ipairs(palette) do
			local selected = handle.Value == index
			local row = make(menu, "TextButton", {
				Name = "ColorOption_" .. option[1],
				AutoButtonColor = false,
				BackgroundColor3 = SYSTEM_BLUE,
				BackgroundTransparency = selected and 0.86 or 1,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(6, 6 + (index - 1) * 26),
				Size = UDim2.new(1, -12, 0, 24),
				Text = "",
				ZIndex = 392,
			})
			make(row, "UICorner", { CornerRadius = UDim.new(0, 6) })
			local optionDot = make(row, "Frame", {
				BackgroundColor3 = option[2],
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(8, 6),
				Size = UDim2.fromOffset(12, 12),
				ZIndex = 393,
			})
			make(optionDot, "UICorner", { CornerRadius = UDim.new(1, 0) })
			if index == 1 then
				make(optionDot, "UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 75, 75)),
						ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 206, 65)),
						ColorSequenceKeypoint.new(0.66, Color3.fromRGB(53, 194, 110)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 112, 255)),
					}),
				})
			end
			make(row, "TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxassetid://12187365364"),
				Position = UDim2.fromOffset(29, 0),
				Size = UDim2.new(1, -58, 1, 0),
				Text = option[1],
				TextColor3 = dark and Color3.fromRGB(240, 240, 243) or Color3.fromRGB(39, 40, 44),
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 393,
			})
			if selected then
				make(row, "TextLabel", {
					BackgroundTransparency = 1,
					FontFace = Font.new("rbxassetid://12187365364"),
					Position = UDim2.new(1, -27, 0, 0),
					Size = UDim2.fromOffset(18, 24),
					Text = "✓",
					TextColor3 = SYSTEM_BLUE,
					TextSize = 14,
					ZIndex = 393,
				})
			end
			row.MouseEnter:Connect(function()
				row.BackgroundTransparency = 0.84
			end)
			row.MouseLeave:Connect(function()
				row.BackgroundTransparency = selected and 0.86 or 1
			end)
			row.Activated:Connect(function()
				chooseOption(index)
			end)
		end
		make(menu, "Frame", {
			BackgroundColor3 = dark and Color3.fromRGB(97, 99, 105) or Color3.fromRGB(218, 220, 225),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(12, 242),
			Size = UDim2.new(1, -24, 0, 1),
			ZIndex = 392,
		})
		local choose = make(menu, "TextButton", {
			Name = "ChooseColour",
			AutoButtonColor = false,
			BackgroundColor3 = SYSTEM_BLUE,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(6, 248),
			Size = UDim2.new(1, -12, 0, 30),
			Text = "",
			ZIndex = 392,
		})
		make(choose, "UICorner", { CornerRadius = UDim.new(0, 6) })
		make(choose, "TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.new("rbxassetid://12187365364"),
			Position = UDim2.fromOffset(9, 0),
			Size = UDim2.new(1, -18, 1, 0),
			Text = "Choose Colour…",
			TextColor3 = SYSTEM_BLUE,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 393,
		})
		choose.MouseEnter:Connect(function() choose.BackgroundTransparency = 0.86 end)
		choose.MouseLeave:Connect(function() choose.BackgroundTransparency = 1 end)
		backdrop.Activated:Connect(closeMenu)
		choose.Activated:Connect(function()
			closeMenu()
			task.delay(0.12, function()
				createHSVColorPicker(window, button, state.FolderCustomColor or state.AccentColor, "Choose Folder Colour", function(color)
					handle.Value = #palette + 1
					state.FolderColor = handle.Value
					state.FolderCustomColor = color
					updateButton()
					notifyFolderColorChanged()
				end)
			end)
		end)
		game:GetService("TweenService"):Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		game:GetService("TweenService"):Create(menu, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(x, y),
			BackgroundTransparency = 0.02,
		}):Play()
	end
	button.Activated:Connect(openMenu)
	handle.SetValue = function(_, index)
		if type(index) == "number" and index >= 1 and index <= #palette + 1 then
			handle.Value = index
			state.FolderColor = index
			state.FolderCustomColor = nil
			updateButton()
			notifyFolderColorChanged()
		end
	end
	handle.GetColor = selectedFolderColor
	updateButton()
	return handle
end

function UI.CreateSystemSettings(cascade, options)
	if cascade ~= nil and type(cascade) == "table" and type(cascade.New) ~= "function" then
		options = cascade
		cascade = nil
	end
	options = options or {}
	if type(options) ~= "table" then
		error("[CascadeStyleUI] CreateSystemSettings options must be a table.", 2)
	end
	if options.SignInLogo ~= nil and options.SignInLogo ~= false and type(options.SignInLogo) ~= "string" then
		error("[CascadeStyleUI] SignInLogo must be an image asset ID string or false.", 2)
	end
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
		Accent = cascade.Accents.Blue or cascade.Accents.Red,
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
	local styleNavigationPill = configureTitlebarNavigation(window)

	local tabs = {}
	local controls = {}
	local state = {
		TextHighlight = 1,
		IconStyle = 1,
		Appearance = 2,
		LiquidGlass = 1,
		Accent = "Multicolor",
		AccentColor = SYSTEM_BLUE,
		FolderColor = 1,
		SidebarIconSize = 2,
		WallpaperTint = true,
	}
	local accountTitleText
	local accountSubtitleText
	local signInLogoImage
	local tabIconStyle
	local function applyGlassStyle()
		local dark = state.Appearance == 3
		local base = dark and Color3.fromRGB(49, 50, 54) or Color3.fromRGB(233, 234, 237)
		local accentColor = state.WallpaperTint and state.AccentColor or base
		accentColor = accentColor or SYSTEM_BLUE
		if state.LiquidGlass == 2 then
			searchField.Body.BackgroundColor3 = base:Lerp(accentColor, 0.2)
			searchField.Body.BackgroundTransparency = 0.12
		else
			searchField.Body.BackgroundColor3 = base
			searchField.Body.BackgroundTransparency = 0.28
		end
		local stroke = searchField.Body:FindFirstChild("SearchBaseStroke")
		if stroke then
			stroke.Color = dark and Color3.fromRGB(104, 106, 112) or Color3.fromRGB(194, 197, 204)
			stroke.Thickness = 1
			stroke.Transparency = state.LiquidGlass == 2 and 0.3 or 0.45
		end
		styleNavigationPill(dark)
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
	accountTitleText, accountSubtitleText, signInLogoImage = addAccountSubtitle(signIn, cascade, app, options)
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

	local network = window:Tab({ Title = "Network", Icon = cascade.Symbols.globe })
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
		Icon = cascade.Symbols.circleLefthalfFilled,
		Selected = true,
	})
	tabs.Appearance = appearance

	local appearanceForm = pageForm(appearance, "Appearance", "Choose the look and colors for the interface.")
	local appearanceModeOptions = { "Auto", "Light", "Dark" }
	controls.AppearancePreview = makeVisualPicker(
		appearanceForm,
		"Appearance",
		"Choose a light or dark appearance.",
		{
			{ Label = "Auto", Icon = cascade.Symbols.sunMax, Mode = "auto", Preview = true },
			{ Label = "Light", Icon = cascade.Symbols.sunMax, Mode = "light", Preview = true },
			{ Label = "Dark", Icon = cascade.Symbols.sunMax, Mode = "dark", Preview = true },
		},
		2,
		82,
		SYSTEM_BLUE,
		function(index)
			setAppearance(index)
		end,
		82
	)

	controls.LiquidGlass = makeVisualPicker(
		appearanceForm,
		"Liquid Glass",
		"Choose how translucent surfaces appear.",
		{
			{ Label = "Clear", Mode = "clear", Glass = true },
			{ Label = "Tinted", Mode = "tinted", Glass = true },
		},
		1,
		86,
		SYSTEM_BLUE,
		function(index)
			state.LiquidGlass = index
			applyGlassStyle()
		end,
		82
	)

	local themeForm = pageForm(appearance, "Theme", nil)
	controls.Accent = makeAccentSwatches(themeForm, cascade, app, state, window)

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
		"Choose how app icons and widgets look.",
		{
			{ Label = "Default", Icon = cascade.Symbols.cloudSunFill, Color = Color3.fromRGB(0, 122, 255), StylePreview = true },
			{ Label = "Dark", Icon = cascade.Symbols.cloudSunFill, Color = Color3.fromRGB(53, 54, 59), Mode = "dark", StylePreview = true },
			{ Label = "Clear", Icon = cascade.Symbols.cloudSunFill, Color = Color3.fromRGB(92, 153, 222), Mode = "clear", StylePreview = true },
			{ Label = "Tinted", Icon = cascade.Symbols.cloudSunFill, Color = Color3.fromRGB(111, 105, 207), Mode = "tinted", StylePreview = true },
		},
		1,
		60,
		SYSTEM_BLUE,
		function(value)
			state.IconStyle = value
			if tabIconStyle then
				tabIconStyle:SetValue(value)
			end
		end,
		82
	)

	controls.FolderColor = makeFolderColorPicker(themeForm, window, state)

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

	local siri = system:Tab({ Title = "Apple Intelligence & Siri", Icon = cascade.Symbols.appleIntelligence })
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

	local wallpaper = system:Tab({ Title = "Wallpaper", Icon = cascade.Symbols.cameraAperture })
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
			local folderColor = controls.FolderColor and controls.FolderColor.GetColor and controls.FolderColor.GetColor()
			tabIconStyle:SetOutlineColor(folderColor or color)
		end
		applyGlassStyle()
	end
	state.OnFolderColorChanged = function(color)
		if tabIconStyle then
			tabIconStyle:SetOutlineColor(color)
		end
	end
	state.OnAccentChanged(state.AccentColor or SYSTEM_BLUE)
	applyGlassStyle()
	configureSearchSuggestions(window, searchField, tabs)
	animateSearchEntrance(searchField)

	return app, {
		Window = window,
		Tabs = tabs,
		Controls = controls,
		State = state,
		SignInLogo = signInLogoImage,
	}
end

return UI
