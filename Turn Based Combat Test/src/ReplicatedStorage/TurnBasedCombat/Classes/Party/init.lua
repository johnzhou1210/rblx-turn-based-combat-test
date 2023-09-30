--[[   Service dependencies   --]]
local RS = game:GetService("ReplicatedStorage");

--[[   Folder references   --]]
local TBCFolder = RS.TurnBasedCombat;
local moduleFolder = TBCFolder.Modules;
local classesFolder = TBCFolder.Classes;
local miscFolder = RS.Misc;

--[[   External dependencies   --]]
--[[   Class dependencies   --]]
local GameObject = require(miscFolder.GameObject);
local Party = GameObject:extend();

--[[   Key variables   --]]
Party.PlayerMemberLimit = 4;
Party.EnemyMemberLimit = 6;



function Party:new(TeamMembers)--takes in array of type party
	self.TeamMembers = TeamMembers or {};
end

function Party:GetPartyTurnOrder() 
	local partyArr = self.TeamMembers;
	local partyTurnSpeeds = self:ReturnPartyTurnSpeedsArray();
	local turnOrderArr = {};
	for i = 1, #partyArr, 1 do
		turnOrderArr[i] = {};
		for j = 1, 2, 1 do
			if j == 1 then -- is partymember object
				turnOrderArr[i][j] = partyArr[i];
			elseif j == 2 then -- is turnspeed int
				turnOrderArr[i][j] = partyTurnSpeeds[i];
			end
		end
	end
	return turnOrderArr;--is a 2d array. Example: {{partymember, turnspeed}{partymember, turnspeed},...}
end

function Party:ReturnPartyTurnSpeedsArray() 
	local partyArr = self.TeamMembers;
	local partyTurnSpeeds = {};--order of members is same
	for i = 1, #partyArr, 1 do
		local currentMember  = partyArr[i]; -- returns partymember class object
		partyTurnSpeeds[i] = currentMember:GetTurnSpeed();
	end
	return partyTurnSpeeds
end

return Party;