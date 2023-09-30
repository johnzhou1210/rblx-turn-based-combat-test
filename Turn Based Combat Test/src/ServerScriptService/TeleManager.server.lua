local RS = game:GetService("ReplicatedStorage");
local TeleS = game:GetService("TeleportService");
local safeTele = require(RS.Misc.SafeTeleport);
local soloTeleportOptions = Instance.new("TeleportOptions");

soloTeleportOptions.ShouldReserveServer = true


RS.TurnBasedCombat.RemoteEvents.Teleportation.TelePlayer.OnServerEvent:Connect(function(plr, place)
	if place == "Title" then
		safeTele(6357293380, {plr}, soloTeleportOptions);
	end
end)