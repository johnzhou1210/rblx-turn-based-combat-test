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
local EnemyPartyMember = require(classesFolder.PartyMember.EnemyPartyMember);

--[[   Key variables   --]]


--[[


--]]

local EnemyNPCDropsList = {
	["Radical Radish"] = {},
};



return EnemyNPCDropsList;
