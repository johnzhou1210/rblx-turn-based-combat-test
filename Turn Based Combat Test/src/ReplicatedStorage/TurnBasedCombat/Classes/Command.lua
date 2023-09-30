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
local Command = GameObject:extend();

--[[   Key variables   --]]


function Command:new(initiator, action, targetArr)
	self.INITIATOR = initiator;--of type PartyMember in general
	self.ACTION = action;--of type action in general
	self.TARGETS = targetArr;--an PartyMember[] in general
end

function Command:ValidateAction(PlayerPartyMember)
end


return Command;