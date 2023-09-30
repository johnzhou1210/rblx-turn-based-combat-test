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
local Party = require(script.Parent);
local EnemyParty = Party:extend();

--[[   Key variables   --]]






function EnemyParty:new(TeamMembers)
	EnemyParty.super.new(self, TeamMembers);
end

return EnemyParty;