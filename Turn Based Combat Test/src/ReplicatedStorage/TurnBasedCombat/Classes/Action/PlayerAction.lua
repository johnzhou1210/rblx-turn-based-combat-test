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
local Action = require(classesFolder.Action);
local PlayerAction = Action:extend();

--[[   Key variables   --]]

function PlayerAction:new(INFODICT)
	--actionName, description, logFlavor, noExtraLineNeeded, mentionTarget, playerOrEnemyParty, targetType, speedPriority, mpCost, hpCost, canUseIfBinded, damageMultiplier, accuracy, imbuedElement, damageType, hpHealingAmount, mpHealingAmount, buffs, critRateModifier, isRevivalSkill, isSkill, image, damageWaitDelay, isSupportSpell
	PlayerAction.super.new(self, INFODICT['NAME'], INFODICT['DESCRIPTION'], INFODICT['LOGFLAVOR'], INFODICT['NOEXTRALINENEEDED'], INFODICT['MENTIONTARGET'], INFODICT['PLAYERORENEMYPARTY']);
	self.TargetType = INFODICT['TARGETTYPE'];
	self.SpeedPriority = INFODICT['SPEEDPRIORITY'];
	self.HPCost = INFODICT['HPCOST'];
	self.MPCost = INFODICT['MPCOST'];
	self.CanUseIfBinded = INFODICT['CANUSEIFBINDED'];
	self.DamageMultiplier = INFODICT['DAMAGEMULTIPLIER'];
	self.Accuracy = INFODICT['ACCURACY'];
	self.ImbuedElement = INFODICT['IMBUEDELEMENT'];
	self.DamageType = INFODICT['DAMAGETYPE'];
	self.HPHealingAmount = INFODICT['HPHEALINGAMOUNT'];
	self.MPHealingAmount = INFODICT['MPHEALINGAMOUNT'];
	self.CritRateModifier = INFODICT['CRITRATEMODIFIER'];
	self.IsRevivalSkill = INFODICT['ISREVIVALSKILL'];
	self.IsSkill = INFODICT['ISSKILL'];
	self.Image = INFODICT['IMAGE'] or nil;
	self.DamageWaitDelay = INFODICT['DAMAGEWAITDELAY'];
	self.IsSupportSpell = INFODICT['ISSUPPORTSPELL'];
	self.StatusEffect = INFODICT['STATUSEFFECT'] or "NONE";
	self.MinStatusEffectDuration = INFODICT['MINSTATUSEFFECTDURATION'] or 2;
	self.MaxStatusEffectDuration = INFODICT['MAXSTATUSEFFECTDURATION'] or 4;
	
	self.IsCrit = false;
	
	self.SupportSpellFlavor = INFODICT['SUPPORTSPELLFLAVOR'] or nil;
	
	self.Buffs = INFODICT['BUFFS'] or "NONE";
	self.BuffsDuration = INFODICT['BUFFSDURATION'] or 3;

	self.Debuffs = INFODICT['DEBUFFS'] or "NONE";
	self.DebuffsDuration = INFODICT['DEBUFFSDURATION'] or 3;
	
	self.RemoveStatusEffect = INFODICT['REMOVESTATUSEFFECT'] or false;
	
end


return PlayerAction;