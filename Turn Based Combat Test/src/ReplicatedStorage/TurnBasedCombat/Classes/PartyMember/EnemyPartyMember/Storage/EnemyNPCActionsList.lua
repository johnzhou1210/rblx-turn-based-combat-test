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
local EnemyActionsList = require(classesFolder.Action.Storage.EnemyActionsList);

--[[   Key variables   --]]
--[[
["Radical Radish"] = {{move1dict, move1weight}, {move2dict, move2weight}, etc.}

--]]


local EnemyNPCActionsList = {
	["Radical Radish"] = {
		{EnemyActionsList["Attack"], 1.5},
		{EnemyActionsList["Defend"], 1},
		{EnemyActionsList["Stare"], .5},
		{EnemyActionsList["Rolling Rampage"], 1.25},
		{EnemyActionsList["Bite"], 1.25}, 
		{EnemyActionsList["Rot"], 1},
	},
	["Chonk Birb"] = {
		{EnemyActionsList["Birb Pounce"], 1},
		{EnemyActionsList["Slack Off"], 4},
		{EnemyActionsList["Poison Fart"], 1},
	},
	["Chonk Birb Lord"] = {
		{EnemyActionsList["Birb Pounce"], 1},
		{EnemyActionsList["Slack Off"], 5},
		{EnemyActionsList["Poison Fart"], 1},
		{EnemyActionsList["Flamethrower"], 1},
		{EnemyActionsList["Volt Tackle"], 1},
		{EnemyActionsList["Reckless Charge"], 1},
		{EnemyActionsList["Intimidate"], 1},
	},
};




return EnemyNPCActionsList;
