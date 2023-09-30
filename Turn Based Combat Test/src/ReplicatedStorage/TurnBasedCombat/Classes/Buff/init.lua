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
local Buff = GameObject:extend();


--[[
EFFECTSTR FORMAT:
example (this one debuffs physical attack by 25% and buffs crit rate by 50%):
PATK|-25,CRITRATE|+50

--]]


--[[   Key variables   --]]


function Buff:new(effectName, isDebuff, duration, strCode) -- string effectName, bool isBuff, PartyMember victimObj, int duration, string strCode
	self.ISDEBUFF = isDebuff or false;
	self.NAME = effectName;
	self.DURATION = duration;
	self.EFFECTSTR = strCode;
end




return Buff;