-- Executor example. Run this as a normal executor script.
-- It loads Ui-library.luau from the executor workspace first, or from the
-- public raw URL below, then creates the UI and its tab icons.

local LIBRARY_FILE = "Ui-library.luau"
local LIBRARY_URL = "https://raw.githubusercontent.com/wtetion/Myui/refs/heads/main/Ui-library.luau" -- Optional: paste the public raw URL for Ui-library.luau.
local SIGN_IN_LOGO = nil -- Keep nil for Cascade's Apple logo; set an rbxassetid:// URL for a custom logo.

local function readLibrarySource()
	if type(readfile) == "function" then
		local ok, source = pcall(readfile, LIBRARY_FILE)
		if ok and type(source) == "string" and #source > 0 then
			return source
		end
	end

	if type(LIBRARY_URL) == "string" and LIBRARY_URL:match("https://raw.githubusercontent.com/wtetion/Myui/refs/heads/main/Ui-library.luau") then
		local requests = {
			function()
				return game:HttpGetAsync(LIBRARY_URL)
			end,
			function()
				return game:HttpGet(LIBRARY_URL)
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
		error("[CascadeStyleUI Example] Could not download Ui-library.luau: " .. lastError, 0)
	end

	error(
		"[CascadeStyleUI Example] Put Ui-library.luau in the executor workspace, "
			.. "or set LIBRARY_URL to its public raw URL at the top of this example.",
		0
	)
end

if type(loadstring) ~= "function" then
	error("[CascadeStyleUI Example] This runner needs an executor that provides loadstring.", 0)
end

local source = readLibrarySource()
local libraryChunk, compileError = loadstring(source, "@Ui-library.luau")
if type(libraryChunk) ~= "function" then
	error("[CascadeStyleUI Example] Ui-library.luau could not be compiled: " .. tostring(compileError), 0)
end

local UI = libraryChunk()
if type(UI) ~= "table" or type(UI.CreateSystemSettings) ~= "function" then
	error("[CascadeStyleUI Example] Ui-library.luau did not return the expected UI API.", 0)
end

local options = {}
if type(SIGN_IN_LOGO) == "string" and SIGN_IN_LOGO ~= "" then
	options.SignInLogo = SIGN_IN_LOGO
end

local app, handles = UI.CreateSystemSettings(options)

local environment = _G
if type(getgenv) == "function" then
	local ok, executorEnvironment = pcall(getgenv)
	if ok and type(executorEnvironment) == "table" then
		environment = executorEnvironment
	end
end

pcall(function()
	environment.CascadeStyleUI = UI
	environment.CascadeStyleUIApp = app
	environment.CascadeStyleUIHandles = handles
end)

print("[CascadeStyleUI] Loaded", UI.Version, "with Cascade", UI.CascadeVersion)
