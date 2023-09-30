--[[   Service dependencies   --]]
local RS = game:GetService("ReplicatedStorage");

--[[   Folder references   --]]
local TBCFolder = RS.TurnBasedCombat;
local moduleFolder = TBCFolder.Modules;
local miscFolder = RS.Misc;

--[[   External dependencies   --]]
--[[   Class dependencies   --]]
local GameObject = require(miscFolder.GameObject);
local Action = GameObject:extend();

--[[   Key variables   --]]


function Action:new(actionName, description, logFlavor, noExtraLineNeeded, mentionTarget, playerOrEnemyParty)
	self.Name = actionName;
	self.Description = description;
	self.LogFlavor = logFlavor;
	self.NoExtraLineNeeded = noExtraLineNeeded;
	self.MentionTarget = mentionTarget;
	self.PlayerOrEnemyParty = playerOrEnemyParty;
end







return Action;