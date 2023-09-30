--implement InflictStatusEffect() method for this class and enemypartymember class!

--[[   Service dependencies   --]]
local RS = game:GetService("ReplicatedStorage");

--[[   Folder references   --]]
local TBCFolder = RS.TurnBasedCombat;
local moduleFolder = TBCFolder.Modules;
local classesFolder = TBCFolder.Classes;
local miscFolder = RS.Misc;
local remoteEventsFolder = TBCFolder.RemoteEvents;

--[[   External dependencies   --]]
local PlayerActionsList = require(classesFolder.Action.Storage.PlayerActionsList);

--[[   Class dependencies   --]]
local GameObject = require(miscFolder.GameObject);
local PartyMember = require(script.Parent);
local PlayerPartyMember = PartyMember:extend();

--[[   Key variables   --]]


function PlayerPartyMember:new(INFODICT)
	--Name, Description, LEVEL, HP, MP, STR, INT, RES, WIS, AGI, LUC, ARMOR, WEAPON, ACCESSORY, MODEL, ACTIONS
	PlayerPartyMember.super.new(self, INFODICT['NAME'], INFODICT['DESCRIPTION']);
	
	self.LEVEL = INFODICT['LEVEL'] or 1;
	self.HP = INFODICT['HP'] or 20;
	self.MP = INFODICT['MP'] or 10;

	--values capping at 255
	self.STR = INFODICT['STR'] or 10;
	self.INT = INFODICT['INT'] or 10;
	self.RES = INFODICT['RES'] or 10;
	self.WIS = INFODICT['WIS'] or 10;
	self.AGI = INFODICT['AGI'] or 10;
	self.LUC = INFODICT['LUC'] or 10;

	--equipment
	self.ARMOR = INFODICT['ARMOR'] or "NONE";
	self.WEAPON = INFODICT['WEAPON'] or "NONE";
	self.ACCESSORY = INFODICT['ACCESSORY'] or "NONE";
	
	--player model
	self.MODEL = INFODICT['MODEL'] or nil;

	--player default actions
	self.ACTIONS = INFODICT['ACTIONS'];--is of data type Action[] 
	
	-- Elemental Resistances
	self.PYRORESMULTIPLIER = INFODICT['PYRORESMULTIPLIER'] or 1;
	self.CRYORESMULTIPLIER = INFODICT['CRYORESMULTIPLIER'] or 1;
	self.ELECTRORESMULTIPLIER = INFODICT['ELECTRORESMULTIPLIER'] or 1;
	
	-- Status Resistances
	self.INSTANTDEATHRES = INFODICT['INSTANTDEATHRES'] or 0;
	self.CURSEDRES = INFODICT['CURSEDRES'] or 0;
	self.BURNEDRES = INFODICT['BURNEDRES'] or 0;
	self.BLINDEDRES = INFODICT['BLINDEDRES'] or 0;
	self.BLEEDINGRES = INFODICT['BLEEDINGRES'] or 0;
	self.BINDEDRES = INFODICT['BINDEDRES'] or 0;
	self.FROZENRES = INFODICT['FROZENRES'] or 0;
	self.HEALBLOCKEDRES = INFODICT['HEALBLOCKEDRES'] or 0;
	self.INFATUATEDRES = INFODICT['INFATUATEDRES'] or 0;
	self.PANICRES = INFODICT['PANICRES'] or 0;
	self.PARALYZEDRES = INFODICT['PARALYZEDRES'] or 0;
	self.PLAGUERES = INFODICT['PLAGUERES'] or 0;
	self.POISONEDRES = INFODICT['POISONEDRES'] or 0;
	self.SLEEPINGRES = INFODICT['SLEEPINGRES'] or 0;
	
	-- Damage Type Resistances SLASH, CRUSH, STAB, NONE
	self.SLASHRESMULTIPLIER = INFODICT['SLASHRESMULTIPLIER'] or 1;
	self.CRUSHRESMULTIPLIER = INFODICT['CRUSHRESMULTIPLIER'] or 1;
	self.STABRESMULTIPLIER = INFODICT['STABRESMULTIPLIER'] or 1;
	self.EFFECTRESMULTIPLIER = INFODICT['EFFECTRESMULTIPLIER'] or 1;

	
	--actual stats calculated from innate stats and equipment. These are default stats you get at beginning of battle. These stats will be the basis for buffs
	self.PATK = self.STR + (self.WEAPON.PATK or 0);
	self.MATK = self.INT + (self.WEAPON.MATK or 0);
	self.PDEF = self.RES + (self.ARMOR.PDEF or 0);
	self.MDEF = self.WIS + (self.ARMOR.MDEF or 0);
	self.EVA = 5;
	self.SPD = self.AGI;
	self.CRITRATE = 5;
	self.CRITDAMAGE = 50;
	
	--temp stats
	self.CURRHP = self.HP;
	self.CURRMP = self.MP;
	self.STATUSEFFECT = "NONE";
	self.LASTDAMAGETAKEN = 0;
	self.EVADEDATTACK = false;
	
	-- limited to only 4 buffs and 4 debuffs. same buffs or debuffs reset duration.
	-- these two tables hold buff objects
	self.BUFFS = {};
	self.DEBUFFS = {};
	
	
	-- these stats can change during the battle
	self.CURRPATK = self.PATK; self.PATKMOD = 1;
	self.CURRMATK = self.MATK; self.MATKMOD = 1;
	self.CURRPDEF = self.PDEF; self.PDEFMOD = 1;
	self.CURRMDEF = self.MDEF; self.MDEFMOD = 1;
	self.CURREVA = self.EVA; self.EVAMOD = 0; 
	self.CURRSPD = self.SPD; self.SPDMOD = 1;
	self.CURRCRITRATE = self.CRITRATE; self.CRITRATEMOD = 0; 
	self.CURRCRITDAMAGE = self.CRITDAMAGE; self.CRITDAMAGEMOD = 0;
	
	
	
	self.CURRINSTANTDEATHRES = self.INSTANTDEATHRES; self.INSTANTDEATHRESMOD = 0;
	self.CURRCURSEDRES = self.CURSEDRES; self.CURSEDRESMOD = 0;
	self.CURRBURNEDRES = self.BURNEDRES; self.BURNEDRESMOD = 0;
	self.CURRBLINDEDRES = self.BLINDEDRES; self.BLINDEDRESMOD = 0;
	self.CURRBLEEDINGRES = self.BLEEDINGRES; self.BLEEDINGRESMOD = 0;
	self.CURRBINDEDRES = self.BINDEDRES; self.BINDEDRESMOD = 0;
	self.CURRFROZENRES = self.FROZENRES; self.FROZENRESMOD = 0;
	self.CURRHEALBLOCKEDRES = self.HEALBLOCKEDRES; self.HEALBLOCKEDRESMOD = 0;
	self.CURRINFATUATEDRES = self.INFATUATEDRES; self.INFATUATEDRESMOD = 0;
	self.CURRPANICRES = self.PANICRES; self.PANICRESMOD = 0;
	self.CURRPARALYZEDRES = self.PARALYZEDRES; self.PARALYZEDRESMOD = 0;
	self.CURRPLAGUERES = self.PLAGUERES; self.PLAGUERESMOD = 0;
	self.CURRPOISONEDRES = self.POISONEDRES; self.POISONEDRESMOD = 0;
	self.CURRSLEEPINGRES = self.SLEEPINGRES; self.SLEEPINGRESMOD = 0;
	
	-- FOR THESE, a higher res mod means that they will be less resistant 
	self.CURRPYRORESMULTIPLIER = self.PYRORESMULTIPLIER; self.PYRORESMULTIPLIERMOD = 0;
	self.CURRCRYORESMULTIPLIER = self.CRYORESMULTIPLIER; self.CRYORESMULTIPLIERMOD = 0;
	self.CURRELECTRORESMULTIPLIER = self.ELECTRORESMULTIPLIER; self.ELECTRORESMULTIPLIERMOD = 0;
	self.CURRSLASHRESMULTIPLIER = self.SLASHRESMULTIPLIER; self.SLASHRESMULTIPLIERMOD = 0;
	self.CURRCRUSHRESMULTIPLIER = self.CRUSHRESMULTIPLIER; self.CRUSHRESMULTIPLIERMOD = 0;
	self.CURRSTABRESMULTIPLIER = self.STABRESMULTIPLIER; self.STABRESMULTIPLIERMOD = 0;
	
	

	self.STATUSEFFECTTIMER = 0;	
	
	--one-turn round states
	self.ISBEINGDEFENDED = false;
	self.GUARDIANINDEXINPARTY = nil;
	
	
	self.DISPLAYNAME = self.Name;

end

function PlayerPartyMember:LoseHP(HPLOST)--things like this change for server only. you need to update it for the client as well.
	if HPLOST == -6667331 or HPLOST == -420420420 or HPLOST == -4207331 then
		return;
	end
	self.LASTDAMAGETAKEN = HPLOST;
	local actualHPLOST;
	if HPLOST >= self.CURRHP then actualHPLOST = self.CURRHP;
	else
		actualHPLOST = HPLOST;
	end
	self.CURRHP = math.clamp(self.CURRHP - actualHPLOST, 0, 999);
	if self.CURRHP == 0 then
		self.STATUSEFFECT = "DEAD";
		warn(self.Name.." has died! Their statuseffect is now "..self.STATUSEFFECT);
	end
end

function PlayerPartyMember:LoseMP(MPLOST)
	self.CURRMP = math.clamp(self.CURRMP - MPLOST, 0, 999);
end

function PlayerPartyMember:GetTurnSpeed()
	--invovles only agility
	local turnSpeed = math.floor(Random.new():NextNumber(self.CURRSPD/1.5, self.CURRSPD*1.5) * 100)/100;
	return turnSpeed;
end

function PlayerPartyMember:AddAction(Action)
	if self:HasAction(Action.Name) == false then
		warn("Player does not have "..Action.Name..". Adding the action...");
		table.insert(self.ACTIONS, Action);
		
	else
		warn("Player already has the action "..Action.Name.."!");
	end
end

function PlayerPartyMember:HasAction(ActionName)
	if self.ACTIONS == nil then
		self.ACTIONS = {};
		return false;
	end
	for i,v in pairs(self.ACTIONS) do
		if v[""..ActionName..""] then--if actionname exists in actions array
			return true;
		end
	end
	return false;
end

return PlayerPartyMember;
