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

function ModuleInitializer.InitializeModules(Type: string)
	for _, Module in Modules[Type] do
		require(Module.Reference)
		print("Module Required: " .. Module.Name)
	end
end

function ModuleInitializer.RetrieveModule(Type: string, Name: string)
	if not Modules[Type][Name] then
		return nil
	end
	return require(Modules[Type][Name].Reference)
end

return ModuleInitializer
