-- Put CascadeStyleUI as a ModuleScript beside this LocalScript, then run the
-- LocalScript from StarterPlayerScripts (or another client-only container).

local UI = require(script.Parent:WaitForChild("CascadeStyleUI"))

local app = UI.new({
    Title = "System Settings",
    Subtitle = "Personalize your experience",
})

local favorites = app:Section({
    Title = "Favorites",
    Expanded = true,
})

local home = favorites:Tab({
    Title = "Home",
    Icon = "⌂",
    IconColor = Color3.fromRGB(255, 255, 255),
    IconBackground = Color3.fromRGB(91, 151, 245),
    Subtitle = "Your settings at a glance",
})

local homeSummary = home:PageSection({
    Title = "Welcome",
    Subtitle = "This example shows the nested sidebar, colored tab icons, and working controls.",
})
homeSummary:Notice({
    Title = "Ready to customize",
    Description = "Use the search box or expand a category in the sidebar to move between pages.",
})
homeSummary:Button({
    Title = "Window controls",
    Description = "The three buttons at the top left hide, resize, or close this window.",
    Label = "Got it",
    Secondary = true,
    Callback = function()
        print("[Example] Button callback fired")
    end,
})

local farm = favorites:Tab({
    Title = "Farm settings",
    Icon = "✿",
    IconColor = Color3.fromRGB(41, 143, 79),
    IconBackground = Color3.fromRGB(222, 246, 228),
    Expanded = true,
})

local farmOverview = farm:Tab({
    Title = "Overview",
    Icon = "◉",
    Selected = false,
    Subtitle = "Example controls for a farming page",
})
local farmControls = farmOverview:PageSection({
    Title = "Farm controls",
    Subtitle = "These callbacks only demonstrate the UI. Connect your own allowed game logic.",
})
farmControls:Toggle({
    Title = "Auto collect",
    Description = "Example toggle callback; it does not interact with a game.",
    Value = false,
    Callback = function(enabled)
        print("[Example] Auto collect:", enabled)
    end,
})
farmControls:Slider({
    Title = "Collection radius",
    Description = "A sample slider value",
    Min = 5,
    Max = 100,
    Step = 5,
    Value = 25,
    Suffix = " studs",
    Callback = function(value)
        print("[Example] Collection radius:", value)
    end,
})
farmControls:Button({
    Title = "Collect item",
    Description = "Example action button",
    Label = "Run",
    Callback = function()
        print("[Example] Action button callback fired")
    end,
})

local targetTab = farm:Tab({
    Title = "Targets",
    Icon = "◎",
    Subtitle = "Choose what a farm page should display",
})
local targetOptions = targetTab:PageSection({ Title = "Target preferences" })
targetOptions:SegmentedControl({
    Title = "Target type",
    Options = { "Coins", "Plants", "Eggs" },
    Value = "Coins",
    Callback = function(value)
        print("[Example] Target type:", value)
    end,
})
targetOptions:ColorSwatches({
    Title = "Target marker",
    Callback = function(color)
        print("[Example] Selected marker color:", color)
    end,
})

local system = app:Section({
    Title = "System",
    Expanded = true,
})

local general = system:Tab({
    Title = "General",
    Icon = "⚙",
    Expanded = true,
    Subtitle = "Core preferences",
})
local generalPage = general:PageSection({
    Title = "General",
    Subtitle = "Basic options for the interface.",
})
generalPage:Toggle({
    Title = "Show search",
    Description = "The sidebar search filters nested tabs.",
    Value = true,
    Callback = function(enabled)
        app.SearchBox.Visible = enabled
        print("[Example] Search visible:", enabled)
    end,
})
generalPage:Button({
    Title = "Reset preferences",
    Description = "A sample confirmation action",
    Label = "Reset",
    Secondary = true,
    Callback = function()
        print("[Example] Reset callback fired")
    end,
})

local appearance = general:Tab({
    Title = "Appearance",
    Icon = "☼",
    IconColor = Color3.fromRGB(221, 105, 0),
    IconBackground = Color3.fromRGB(255, 238, 215),
    Selected = true,
    Subtitle = "Choose how the interface looks",
})

local appearanceOptions = appearance:PageSection({
    Title = "Appearance",
    Subtitle = "Preview themes and set the accent color for your app.",
})
appearanceOptions:SegmentedControl({
    Title = "Theme",
    Options = { "Light", "Dark", "Auto" },
    Value = "Light",
    Preview = true,
    Callback = function(value)
        print("[Example] Theme:", value)
    end,
})
appearanceOptions:ColorSwatches({
    Title = "Accent color",
    Value = Color3.fromRGB(0, 122, 255),
    Callback = function(color)
        print("[Example] Accent color:", color)
    end,
})
appearanceOptions:SegmentedControl({
    Title = "Highlight color",
    Options = { "Blue", "Purple", "Green", "Orange" },
    Value = "Blue",
    Callback = function(value)
        print("[Example] Highlight color:", value)
    end,
})
appearanceOptions:Toggle({
    Title = "Tint windows with wallpaper",
    Description = "Preview row for a common appearance preference.",
    Value = false,
    Callback = function(enabled)
        print("[Example] Wallpaper tint:", enabled)
    end,
})

local accessibility = general:Tab({
    Title = "Accessibility",
    Icon = "◉",
    IconColor = Color3.fromRGB(44, 125, 210),
    IconBackground = Color3.fromRGB(226, 241, 255),
    Subtitle = "Readable controls and motion preferences",
})
local accessibilityOptions = accessibility:PageSection({
    Title = "Display",
    Subtitle = "An additional nested page to demonstrate the tree layout.",
})
accessibilityOptions:Toggle({
    Title = "Increase contrast",
    Value = false,
    Callback = function(enabled)
        print("[Example] Increase contrast:", enabled)
    end,
})
accessibilityOptions:Slider({
    Title = "Interface scale",
    Min = 80,
    Max = 120,
    Step = 5,
    Value = 100,
    Suffix = "%",
    Callback = function(value)
        print("[Example] Interface scale:", value)
    end,
})

local connectivity = app:Section({
    Title = "Connectivity",
    Expanded = false,
})
local wifi = connectivity:Tab({
    Title = "Wi-Fi",
    Icon = "⌁",
    IconColor = Color3.fromRGB(0, 122, 255),
    IconBackground = Color3.fromRGB(225, 239, 255),
})
wifi:PageSection({ Title = "Wi-Fi" }):Toggle({
    Title = "Wi-Fi",
    Description = "Example only. Connect this to your own settings.",
    Value = true,
    Callback = function(enabled)
        print("[Example] Wi-Fi preference:", enabled)
    end,
})

local bluetooth = connectivity:Tab({
    Title = "Bluetooth",
    Icon = "ᛒ",
    IconColor = Color3.fromRGB(48, 112, 232),
    IconBackground = Color3.fromRGB(228, 237, 255),
})
bluetooth:PageSection({ Title = "Bluetooth" }):Toggle({
    Title = "Bluetooth",
    Value = true,
    Callback = function(enabled)
        print("[Example] Bluetooth preference:", enabled)
    end,
})

local personalization = app:Section({
    Title = "Personalization",
    Expanded = false,
})
local wallpaper = personalization:Tab({
    Title = "Wallpaper",
    Icon = "▧",
    IconColor = Color3.fromRGB(76, 151, 118),
    IconBackground = Color3.fromRGB(228, 247, 237),
})
wallpaper:PageSection({ Title = "Wallpaper" }):Button({
    Title = "Choose wallpaper",
    Description = "Example button row",
    Label = "Choose",
    Callback = function()
        print("[Example] Choose wallpaper callback fired")
    end,
})

local notifications = personalization:Tab({
    Title = "Notifications",
    Icon = "◉",
    IconColor = Color3.fromRGB(241, 75, 83),
    IconBackground = Color3.fromRGB(255, 232, 233),
})
notifications:PageSection({ Title = "Notifications" }):Toggle({
    Title = "Allow notifications",
    Value = true,
    Callback = function(enabled)
        print("[Example] Notifications preference:", enabled)
    end,
})

-- The Appearance page starts selected. Show the app after all pages are added.
app:Show()
