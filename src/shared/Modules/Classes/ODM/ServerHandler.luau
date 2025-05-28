local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ODM = {}
ODM.__index = ODM

function ODM.new()
	local self = setmetatable({}, ODM)
	self.Model = ReplicatedStorage.Assets.ODM:Clone()
	self.Owner = nil -- Placeholder for owner, can be set later
	return self
end

function ODM:Init(Position: Vector3)
	self.Model.PrimaryPart.Position = Position or Vector3.new(0, 0, 0)
	self.Model.Parent = workspace
	self:Connections()
	print("ODM Gear Initialized")
end

function ODM:Connections()
	local function ProximityPromptConnection(PlayerWhoTriggered: Player)
		self:SetOwner(PlayerWhoTriggered)
		self.Model.PrimaryPart.ProximityPrompt.Enabled = false
		print("ODM gear grabbed by: " .. PlayerWhoTriggered.Name)
	end

	self.Model.PrimaryPart.ProximityPrompt.Enabled = true
	self.Model.PrimaryPart.ProximityPrompt.Triggered:Connect(ProximityPromptConnection)
end

function ODM:SetOwner(Owner)
	self.Owner = Owner
end

return ODM
