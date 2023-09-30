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


--[[   Key variables   --]]
local rng = Random.new();

local EnemyAction = Action:extend();

function EnemyAction:new(INFODICT)
	EnemyAction.super.new(self, INFODICT['NAME'], INFODICT['DESCRIPTION'], INFODICT['LOGFLAVOR'], INFODICT['NOEXTRALINENEEDED'], INFODICT['MENTIONTARGET'], INFODICT['PLAYERORENEMYPARTY']);
	self.TargetType = INFODICT['TARGETTYPE'];
	self.SpeedPriority = INFODICT['SPEEDPRIORITY'];
	self.HPCost = INFODICT['HPCOST'];
	self.CanUseIfBinded = INFODICT['CANUSEIFBINDED'];
	self.DamageMultiplier = INFODICT['DAMAGEMULTIPLIER'];
	self.Accuracy = INFODICT['ACCURACY'];
	self.ImbuedElement = INFODICT['IMBUEDELEMENT'];
	self.DamageType = INFODICT['DAMAGETYPE'];
	self.HPHealingAmount = INFODICT['HPHEALINGAMOUNT'];
	self.CritRateModifier = INFODICT['CRITRATEMODIFIER'];
	self.IsRevivalSkill = INFODICT['ISREVIVALSKILL'];
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

function EnemyAction:ChooseTarget(Chooser, PlayerTeamArr, EnemyTeamArr, chosenAction)--make sure to chose one that is alive
	local function returnArrWithPartyMembers(arr, ignoreDead)
		local resultArr = {};
		for i,v in pairs(arr) do
			if v.CURRHP < 0 and ignoreDead == true then
				--do nothing
				warn(v.DISPLAYNAME.." not added to resultArr because they are dead and action ignores dead");
			else
				table.insert(resultArr, v);
			end
		end
		return resultArr;
	end
	local function returnTargetIfThere(arr, index, ignoreDead)
		if arr[index] then
			if arr[index].CURRHP < 0 and ignoreDead == true then
				return nil;
			else
				return arr[index];	
			end
		end
		return nil;
	end
	local function returnArrWithNoNilValues(targetArr)
		local resultArr = {};
		for i,v in pairs(targetArr) do
			if v ~= nil then
				table.insert(resultArr, v);
			end
		end
		return resultArr;
	end
	local TargetType = chosenAction.TargetType;
	local ignoreDead = false;
	if chosenAction.IsRevivalSkill == false then ignoreDead = true; end
	warn(TargetType);
	if TargetType == "SINGLEPARTY" then--SINGLEPARTY is the player's party
		local chosenTarget;
		repeat
			chosenTarget = PlayerTeamArr[rng:NextInteger(1, #PlayerTeamArr)];
		until chosenTarget.CURRHP > 0
		return {chosenTarget};
	elseif TargetType == "SINGLEENEMY" then --SINGLEENEMY is the npc enemy's own party
		local chosenTarget;
		repeat
			chosenTarget = EnemyTeamArr[rng:NextInteger(1, #EnemyTeamArr)];
		until chosenTarget.CURRHP > 0
		return {chosenTarget};
	elseif TargetType == "SELF" then
		return {Chooser};
	elseif TargetType == "ALLPARTY" then
		return returnArrWithPartyMembers(PlayerTeamArr, ignoreDead);
	elseif TargetType == "ALLENEMY" then
		return returnArrWithPartyMembers(EnemyTeamArr, ignoreDead);
	elseif TargetType == "SPLASHPARTY" then
		local chosenMainTarget;
		local rngNumber = rng:NextInteger(1, #PlayerTeamArr);
		repeat
			rngNumber = rng:NextInteger(1, #PlayerTeamArr);
			chosenMainTarget = PlayerTeamArr[rngNumber];
		until chosenMainTarget.CURRHP > 0
		return returnArrWithNoNilValues({returnTargetIfThere(PlayerTeamArr, rngNumber - 1, ignoreDead), chosenMainTarget, returnTargetIfThere(PlayerTeamArr, rngNumber + 1, ignoreDead)});
	elseif TargetType == "SPLASHENEMY" then
		local chosenMainTarget;
		local rngNumber = rng:NextInteger(1, #EnemyTeamArr);
		repeat
			rngNumber = rng:NextInteger(1, #EnemyTeamArr);
			chosenMainTarget = EnemyTeamArr[rngNumber];
		until chosenMainTarget.CURRHP > 0
		return returnArrWithNoNilValues({returnTargetIfThere(EnemyTeamArr, rngNumber - 1, ignoreDead), chosenMainTarget, returnTargetIfThere(EnemyTeamArr, rngNumber + 1, ignoreDead)});
	elseif TargetType == "NONE" then
		return {};
	else
		error("INVALID TARGETTYPE!");
	end	
	--return nil;
end


return EnemyAction;