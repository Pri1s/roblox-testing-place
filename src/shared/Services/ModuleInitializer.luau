local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Services
local ClientServices = Services.Client
local ServerServices = Services.Server

local Modules = {
	["Client"] = {
		{
			["Name"] = "AnimationHandler",
			["Reference"] = ClientServices.AnimationHandler,
		},
	},
	["Server"] = {
		{
			["Name"] = "PlayerHandler",
			["Reference"] = ServerServices.PlayerHandler,
		},
	},
}

local ModuleInitializer = {}

function ModuleInitializer.InitializeModules(ModuleType: string)
	for _, Module in Modules[ModuleType] do
		local Success, Result = pcall(function()
			return require(Module.Reference)
		end)

		if Success then
			print("Module Required: " .. Module.Name)

			-- Check if the module has an Initialize method
			if typeof(Result) == "table" and typeof(Result.Init) == "function" then
				local InitSuccess, InitError = pcall(function()
					Result.Init()
				end)

				if InitSuccess then
					print("Initialized module: " .. Module.Name)
				else
					warn("Failed to initialize module: " .. Module.Name .. " | Error: " .. tostring(InitError))
				end
			end
		else
			warn("Failed to require module: " .. Module.Name .. " | Error: " .. tostring(Result))
		end
	end
end

function ModuleInitializer.RetrieveModule(ModuleType: string, ModuleName: string)
	if not Modules[ModuleType][ModuleName] then
		return nil
	end
	return require(Modules[ModuleType][ModuleName].Reference)
end

return ModuleInitializer
