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
local Item = require(script.Parent);
local Armor = Item:extend();

--[[   Key variables   --]]


function Armor:new(Name, MoneyValue, CanDiscard, Description, PDEF, MDEF)
	Armor.super.new(self, Name, MoneyValue, CanDiscard, Description);
	self.PDEF = PDEF or 0;
	self.MDEF = MDEF or 0;
end

return Armor;