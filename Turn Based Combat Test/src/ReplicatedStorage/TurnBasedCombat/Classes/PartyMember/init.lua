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
local Item = require(classesFolder.Item);
local Weapon = require(classesFolder.Item.Weapon);
local Armor = require(classesFolder.Item.Armor);
local PartyMember = GameObject:extend();

--[[   Key variables   --]]


function PartyMember:new(Name, Description, TurnSpeed)
	self.Name = Name or "Party Member";
	self.Description = Description or "No description";
	
end

function PartyMember:ToString()
	return self.Name;
end

function PartyMember:CreateQueueEntry(action)--return a table like this: {actionPerformer, action, {target1, target2,...}}
	return {self, action, action};
end

return PartyMember;