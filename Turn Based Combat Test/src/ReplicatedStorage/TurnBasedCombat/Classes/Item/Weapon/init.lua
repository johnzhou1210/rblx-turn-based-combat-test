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
local Weapon = Item:extend();

--[[   Key variables   --]]


function Weapon:new(Name, MoneyValue, CanDiscard, Description, PATK, MATK)
	Weapon.super.new(self, Name, MoneyValue, CanDiscard, Description);
	self.ATK = PATK or 0;
	self.MATK = MATK or 0;
end

return Weapon;