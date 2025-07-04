local SETTINGS = {
	ProfileTemplate = {
		Cash = 0,
	},

	Products = { -- developer_product_id = function(profile)
		[97662780] = function(profile)
			profile.Data.Cash += 100
		end,
		[97663121] = function(profile)
			profile.Data.Cash += 1000
		end,
	},

	PurchaseIdLog = 50, -- Store this amount of purchase id's in MetaTags;
	-- This value must be reasonably big enough so the player would not be able to purchase products faster than individual purchases can be confirmed.
	-- Anything beyond 30 should be good enough.
}

----- Services -----

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

----- Loaded Modules -----

local ProfileService = require(ServerScriptService.ProfileService)

----- Private Variables -----

local GameProfileStore = ProfileService.GetProfileStore("PlayerData", SETTINGS.ProfileTemplate)
local Profiles = {} -- {player = profile, ...}

----- Private Functions -----

local function playerAdded(player)
	local profile = GameProfileStore:LoadProfileAsync("Player_" .. player.UserId, "ForceLoad")

	if profile ~= nil then
		profile:Reconcile() -- Fill in missing variables from ProfileTemplate (optional)
		profile:ListenToRelease(function()
			Profiles[player] = nil
			player:Kick() -- The profile could've been loaded on another Roblox server
		end)

		if player:IsDescendantOf(Players) == true then
			Profiles[player] = profile
		else
			profile:Release() -- Player left before the profile loaded
		end
	else
		-- The profile couldn't be loaded possibly due to other
		--   Roblox servers trying to load this profile at the same time:
		player:Kick()
	end
end

local function purchaseIdCheckAsync(profile, purchase_id, grant_product_callback) --> Enum.ProductPurchaseDecision
	-- Yields until the purchase_id is confirmed to be saved to the profile or the profile is released

	if profile:IsActive() ~= true then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	else
		local meta_data = profile.MetaData
		local local_purchase_ids = meta_data.MetaTags.ProfilePurchaseIds

		if local_purchase_ids == nil then
			local_purchase_ids = {}
			meta_data.MetaTags.ProfilePurchaseIds = local_purchase_ids
		end

		-- Granting product if not received:

		if table.find(local_purchase_ids, purchase_id) == nil then
			while #local_purchase_ids >= SETTINGS.PurchaseIdLog do
				table.remove(local_purchase_ids, 1)
			end

			table.insert(local_purchase_ids, purchase_id)
			task.spawn(grant_product_callback)
		end

		-- Waiting until the purchase is confirmed to be saved:

		local result = nil

		local function check_latest_meta_tags()
			local saved_purchase_ids = meta_data.MetaTagsLatest.ProfilePurchaseIds

			if saved_purchase_ids ~= nil and table.find(saved_purchase_ids, purchase_id) ~= nil then
				result = Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end

		check_latest_meta_tags()

		local release_connection = profile:ListenToRelease(function()
			result = result or Enum.ProductPurchaseDecision.NotProcessedYet
		end)

		local meta_tags_connection = profile.MetaTagsUpdated:Connect(function()
			check_latest_meta_tags()
		end)

		while result == nil do
			RunService.Heartbeat:Wait()
		end

		release_connection:Disconnect()
		meta_tags_connection:Disconnect()

		return result
	end
end

local function getPlayerProfileAsync(player) --> [Profile] / nil
	-- Yields until a Profile linked to a player is loaded or the player leaves
	local profile = Profiles[player]

	while profile == nil and player:IsDescendantOf(Players) == true do
		RunService.Heartbeat:Wait()
		profile = Profiles[player]
	end

	return profile
end

local function grantProduct(player, product_id)
	-- We shouldn't yield during the product granting process!
	local profile = Profiles[player]
	local product_function = SETTINGS.Products[product_id]

	if product_function ~= nil then
		product_function(profile)
	else
		warn("ProductId " .. tostring(product_id) .. " has not been defined in Products table")
	end
end

local function processReceipt(receipt_info)
	local player = Players:GetPlayerByUserId(receipt_info.PlayerId)

	if player == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local profile = getPlayerProfileAsync(player)

	if profile ~= nil then
		return purchaseIdCheckAsync(profile, receipt_info.PurchaseId, function()
			grantProduct(player, receipt_info.ProductId)
		end)
	else
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

----- Initialize -----

for _, player in Players:GetPlayers() do
	task.spawn(playerAdded, player)
end

MarketplaceService.ProcessReceipt = processReceipt

----- Connections -----

Players.PlayerAdded:Connect(playerAdded)

Players.PlayerRemoving:Connect(function(player)
	local profile = Profiles[player]
	if profile ~= nil then
		profile:Release()
	end
end)
