-- Run this example directly in an executor.
-- The library builds the tabs, icons, controls, and Search suggestions from
-- the UI reference; this file only loads it and opens the window.

local LIBRARY_URL = "https://raw.githubusercontent.com/wtetion/Myui/refs/heads/main/Ui-library.luau"
local SIGN_IN_IMAGE = "rbxassetid://86949082023913"

if type(loadstring) ~= "function" then
	error("[Myui Example] This executor must provide loadstring.", 0)
end

local function fetchLibrary()
	local requests = {
		function()
			return game:HttpGet(LIBRARY_URL)
		end,
		function()
			return game:HttpGetAsync(LIBRARY_URL)
		end,
	}
	local lastError = "No HTTP method is available."
	for _, request in ipairs(requests) do
		local ok, source = pcall(request)
		if ok and type(source) == "string" and #source > 0 then
			return source
		end
		lastError = tostring(source)
	end
	error("[Myui Example] Could not fetch Ui-library.luau: " .. lastError, 0)
end

local source = fetchLibrary()
local libraryChunk, compileError = loadstring(source, "@Myui/Ui-library.luau")
if type(libraryChunk) ~= "function" then
	error("[Myui Example] Library compile failed: " .. tostring(compileError), 0)
end

local ok, UI = pcall(libraryChunk)
if not ok then
	error("[Myui Example] Library initialization failed: " .. tostring(UI), 0)
end
if type(UI) ~= "table" or type(UI.CreateSystemSettings) ~= "function" then
	error("[Myui Example] Ui-library.luau returned an incompatible API.", 0)
end

-- Creates Sign In, Software Update, Connectivity, System,
-- Privacy & Security, Automation, and the Appearance controls shown in the
-- reference. The Library supplies the tab icons and Search suggestions.
local app, handles = UI.CreateSystemSettings({
	SignInLogo = SIGN_IN_IMAGE,
})

local environment = _G
if type(getgenv) == "function" then
	local envOk, executorEnvironment = pcall(getgenv)
	if envOk and type(executorEnvironment) == "table" then
		environment = executorEnvironment
	end
end

pcall(function()
	environment.Myui = UI
	environment.MyuiApp = app
	environment.MyuiHandles = handles
end)

print("[Myui] Loaded", UI.Version, "with Cascade", UI.CascadeVersion)
