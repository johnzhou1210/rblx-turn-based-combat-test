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
local Item = GameObject:extend();

--[[   Key variables   --]]



function Item:new(Name, MoneyValue, CanDiscard, Description)
	self.Name = Name;
	self.MoneyValue = MoneyValue;
	self.CanDiscard = CanDiscard;
	self.Description = Description;
end

return Item;