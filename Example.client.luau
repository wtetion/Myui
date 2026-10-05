-- Example entry point for the reusable CascadeStyleUI module.
-- Place Ui-library.luau in ReplicatedStorage as a ModuleScript named Ui-library.

local replicatedStorage = game:GetService("ReplicatedStorage")
local libraryModule = replicatedStorage:WaitForChild("Ui-library", 10)

assert(
	libraryModule and libraryModule:IsA("ModuleScript"),
	"CascadeStyleUI example: put Ui-library.luau in ReplicatedStorage as a ModuleScript named 'Ui-library'. "
		.. "For a single-file runner, use Ui-library.client.luau instead."
)

local CascadeStyleUI = require(libraryModule)
local app, handles = CascadeStyleUI.CreateSystemSettings()

-- Keep references available while the UI is open for custom integration.
print("[CascadeStyleUI] Example loaded:", app, handles.Window)
