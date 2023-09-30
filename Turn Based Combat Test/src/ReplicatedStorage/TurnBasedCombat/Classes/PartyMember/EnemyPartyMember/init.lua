--[[   Service dependencies   --]]
local RS = game:GetService("ReplicatedStorage");

--[[   Folder references   --]]
local TBCFolder = RS.TurnBasedCombat;
local moduleFolder = TBCFolder.Modules;
local classesFolder = TBCFolder.Classes;
local miscFolder = RS.Misc;

--[[   External dependencies   --]]
local EnemyActionsList = require(classesFolder.Action.Storage.EnemyActionsList);
local EnemyNPCActionsList = require(classesFolder.PartyMember.EnemyPartyMember.Storage.EnemyNPCActionsList);

--[[   Class dependencies   --]]
local GameObject = require(miscFolder.GameObject);
local PartyMember = require(classesFolder.PartyMember);
local EnemyPartyMember = PartyMember:extend();


--[[   Key variables   --]]


--Name, Description, HP, PATK, MATK, PDEF, MDEF, AGI, EXP, DROPS, EVA, PYRORESMULTIPLIER, CRYORESMULTIPLIER, ELECTRORESMULTIPLIER, IMMUNITIES, CRITRATE, DISPLAYNAME

function EnemyPartyMember:new(INFODICT, DISPLAYNAME)
	EnemyPartyMember.super.new(self, INFODICT['NAME'], INFODICT['DESCRIPTION']);
	self.HP = INFODICT['HP'] or 10;
	self.PATK = INFODICT['PATK'] or 5;
	self.MATK = INFODICT['MATK'] or 5;
	self.PDEF = INFODICT['PDEF'] or 5;
	self.MDEF = INFODICT['MDEF'] or 5;
	self.AGI = INFODICT['AGI'] or 5; self.SPD = self.AGI;
	self.EXP = INFODICT['EXP'] or 5;
	self.DROPS = INFODICT['DROPS'] or {};
	self.EVA = INFODICT['EVA'] or 5;
	
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
	self.POISONEDRES = INFODICT['POISONEDRES'] or 0;
	self.SLEEPINGRES = INFODICT['SLEEPINGRES'] or 0;
	
	-- Pseudo weapon
	self.WEAPON = INFODICT['WEAPON'] or nil;
	
	-- Damage Type Resistances SLASH, CRUSH, STAB, NONE
	self.SLASHRESMULTIPLIER = INFODICT['SLASHRESMULTIPLIER'] or 1;
	self.CRUSHRESMULTIPLIER = INFODICT['CRUSHRESMULTIPLIER'] or 1;
	self.STABRESMULTIPLIER = INFODICT['STABRESMULTIPLIER'] or 1;
	self.EFFECTRESMULTIPLIER = INFODICT['EFFECTRESMULTIPLIER'] or 1;	
	
	self.IMMUNITIES = INFODICT['IMMUNITIES'] or {};
	self.CRITRATE = INFODICT['CRITRATE'] or 5;
	self.CRITDAMAGE = INFODICT['CRITDAMAGE'] or 50;
	self.DISPLAYNAME = DISPLAYNAME or INFODICT['NAME'] or 'Unknown';
	
	self.CURRHP = self.HP;
	self.STATUSEFFECT = "NONE";
	self.EVADEDATTACK = false;
	self.ISBEINGDEFENDED = false;
	
	
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
	
	--enemy default actions
	self.ACTIONS = EnemyNPCActionsList[self.Name];--is a 2d array that looks like this: { {EnemyActionsList["Attack"], 1}, {EnemyActionsList["Defend"], .1}, etc.},
end

function EnemyPartyMember:LoseHP(HPLOST)
	if HPLOST == -6667331 or HPLOST == -420420420 or HPLOST == -4207331 then
		return;
	end
	local actualHPLOST;
	if HPLOST >= self.CURRHP then actualHPLOST = self.CURRHP;
	else
		actualHPLOST = HPLOST;
	end
	self.CURRHP = math.floor(math.clamp(self.CURRHP - actualHPLOST, 0, math.huge)+ .5);
	if self.CURRHP == 0 then 
		self.STATUSEFFECT = "DEAD";
	end
end

function EnemyPartyMember:GetTurnSpeed()
	--involves only agility
	local turnSpeed = math.floor(Random.new():NextNumber(self.CURRSPD/1.5, self.CURRSPD*1.5) * 100)/100;
	return turnSpeed;
end

function EnemyPartyMember:AddAction(Action)
	if self:HasAction(Action.Name) == false then
		warn("Enemy does not have "..Action.Name..". Adding the action...");
		table.insert(self.ACTIONS, Action);
	else
		warn("Enemy already has the action "..Action.Name.."!");
	end
end

function EnemyPartyMember:HasAction(ActionName)
	for i,v in pairs(self.ACTIONS) do
		if v[""..ActionName..""] then--if actionname exists in actions array
			return true;
		end
	end
	return false;
end

return EnemyPartyMember;
