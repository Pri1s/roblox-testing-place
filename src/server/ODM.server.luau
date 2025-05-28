local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ODMServerHandler = require(ReplicatedStorage.Shared.Modules.Classes.ODM.ServerHandler)

local NewODMGear = ODMServerHandler.new()
NewODMGear:Init(Vector3.new(0, 0, 0)) -- Initialize with a default position
