--BATTLESCENESERVER HANDLES THE LOGIC BEHIND TURN BASED COMBAT AND MAKES CHANGES TO INSTANCE VARIABLES (CALCULATING TURN SPEED, PROCESSING AND EXECUTING A QUEUE, DEALING DAMAGE, ETC.)

--[[   Service dependencies   --]]
local RS = game:GetService("ReplicatedStorage");

--[[   Folder references   --]]
local TBCFolder = RS.TurnBasedCombat;
local moduleFolder = TBCFolder.Modules;
local classesFolder = TBCFolder.Classes;
local miscFolder = RS.Misc;

--[[   External dependencies   --]]
local StatusEffectIcons = require(classesFolder.PartyMember.Storage.StatusEffectIcons);
local LootPlan = require(moduleFolder.LootPlan);

--[[   Class dependencies   --]]
local GameObject = require(miscFolder.GameObject);
local BattleScene = require(classesFolder.BattleScene);
local EnemyActionsList = require(classesFolder.Action.Storage.EnemyActionsList);
local Command = require(classesFolder.Command);
local EnemyAction = require(classesFolder.Action.EnemyAction)
local PlayerPartyMember = require(classesFolder.PartyMember.PlayerPartyMember);
local EnemyPartyMember = require(classesFolder.PartyMember.EnemyPartyMember);
local BattleSceneServer = BattleScene:extend();

--[[   Key variables   --]]

--[[   Class constructor   --]]
function BattleSceneServer:new(PlayerParty, EnemyParty, MusicID, IsBossFight, EncounterMethod)
	BattleSceneServer.super.new(self, PlayerParty, EnemyParty, MusicID, IsBossFight, EncounterMethod);
	--local enemyCommandArr = self:GenerateEnemyCommandArr();
	--warn("enemyCommandArrLength = "..#enemyCommandArr);
	--for i,v in pairs(enemyCommandArr) do
	--	--print("Initiator: "..tostring(v.INITIATOR.DISPLAYNAME)..", Action: "..tostring(v.ACTION.Name)..", Targets: ");
	--	self:PrintTableElements(v.TARGETS);
	--	--print("===========================")
	--end
end


--[[   Accessor methods   --]]
function BattleSceneServer:GetCurrentPartyMemberCommand(currentPartyMemberObject, CommandsArr)
	for j,k in pairs(CommandsArr) do
		print("================");
		print(j);
		print(k.ACTION.Name);
	end
	for i,v in pairs(CommandsArr) do
		local currentCommandInitiator = v.INITIATOR;
		if (currentPartyMemberObject == currentCommandInitiator) then
			return v;
		else
			print("================");
			print("currentPartyMemberObject is "..currentPartyMemberObject.Name);
			print("currentCommandInitiator is "..currentCommandInitiator.Name);
		end
	end
	error("CURRENTPARTYMEMBEROBJECT DID NOT EQUAL ANY OF THE INITIATOR VARIABLES OF THE INDIVIDUAL PLAYERCOMMANDSARR ELEMENTS!");
end



--[[   Mutator methods   --]]
function BattleSceneServer:PrintTableElements(arr)
	for i,v in pairs(arr) do
		print(tostring(i),"-",tostring(v.Name));
	end
end

function BattleSceneServer:InvokeChangeOntoClient(BattleSceneClient)
	BattleSceneClient:UpdateInfo(self);
end

function BattleSceneServer:AssembleQueue(playerCommandsArr)--returns an array with execute-ready commands with proper turn order
	local resultingQueue = {};
	local enemyCommandsArr = self:GenerateEnemyCommandArr();
	local sortedTurnOrderArr = self:CombinePartyTurnOrdersAndSortFromFastestToSlowest(self.PlayerParty:GetPartyTurnOrder(), self.EnemyParty:GetPartyTurnOrder());--parameters have to be obtained from using Party:GetPartyTurnOrder()
	--the sortedTurnOrderArr looks like: { {P, TS}, {E, TS}, {P, TS}, {E, TS}, {P, TS}, {P, TS}, {E, TS}, {E, TS} }
	--the enemyCommandsArr looks like: {Command C1, Command C2, Command C3, Command C4};
	--the playerCommandsArr looks like: {Command C1, Command C2, Command C3, Command C4};
	
	-- loop through sortedTurnOrderArr and rearrange it such that the first elements prioritize the players whose commands have an action with a speed priority as GOFIRST
	local function getActionAssociatedWithPartyMember(obj)
		-- first see if obj is plr or enemy
		local plrOrEnemy = "";
		local arrToSearchThrough;
		if obj:is(PlayerPartyMember) then
			plrOrEnemy = "Player";
			arrToSearchThrough = playerCommandsArr;
		elseif obj:is(EnemyPartyMember) then
			plrOrEnemy = "Enemy";
			arrToSearchThrough = enemyCommandsArr;
		else
			print("problem with is function!");
		end
		-- now decide which commandsArr to search through
		for i,v in pairs(arrToSearchThrough) do
			if v.INITIATOR == obj then
				return v.ACTION;
			end
		end
		print(arrToSearchThrough, plrOrEnemy, arrToSearchThrough)
	end
	-- account for speed priorities
	for i,v in pairs(sortedTurnOrderArr) do
		local acti = getActionAssociatedWithPartyMember(v[1]);	
		print(acti);
		if acti and acti.SpeedPriority == "GOFIRST" then
			-- move this elem to the beginning of the table
			local removedElem = table.remove(sortedTurnOrderArr, i);
			table.insert(sortedTurnOrderArr, 1, removedElem);
		end
	end
	--take out the people who cannot act
	local function cannotAct(PlayerPartyMember)
		return PlayerPartyMember.STATUSEFFECT == "DEAD" or PlayerPartyMember.STATUSEFFECT == "FROZEN" or PlayerPartyMember.STATUSEFFECT == "PARALYZED";
	end
	for i,v in pairs(sortedTurnOrderArr) do
		local currentPartyMemberObject = v[1];
		--check if alive first
		if cannotAct(currentPartyMemberObject) == false then
			if (currentPartyMemberObject:is(PlayerPartyMember)) then
				warn(resultingQueue);
				warn(self:GetCurrentPartyMemberCommand(currentPartyMemberObject, playerCommandsArr));
				table.insert(resultingQueue, self:GetCurrentPartyMemberCommand(currentPartyMemberObject, playerCommandsArr));--search in playerCommandsArr
			elseif (currentPartyMemberObject:is(EnemyPartyMember)) then
				table.insert(resultingQueue, self:GetCurrentPartyMemberCommand(currentPartyMemberObject, enemyCommandsArr));--search in enemyCommandsArr
			else
				error("CURRENTPARTYMEMBEROBJECT IS NOT PLAYERPARTYMEMBER OR ENEMYPARTYMEMBER!");
			end
		else
			print(currentPartyMemberObject.DISPLAYNAME, currentPartyMemberObject.STATUSEFFECT, "this partymember is dead. skipping it..."); -- it predicted the future if you didn't flee
		end
	end
	return resultingQueue;
end

function BattleSceneServer:GenerateEnemyCommandArr()
	local function returnArrWithLiveEnemies()
		local resultArr = {};
		for i,v in pairs(self.EnemyParty.TeamMembers) do
			if v.CURRHP > 0 then 
				table.insert(resultArr, v);
			end
		end
		return resultArr;
	end
	local resultingArray = {};
	local enemyParty = self.EnemyParty;
	local aliveEnemies = returnArrWithLiveEnemies();
	for i,v in pairs(aliveEnemies) do
		local enemyPartyMemberActionsArr = v.ACTIONS;--what it looks like: { {ActionDict, 1}, {Action2Dict, .1}, {Action3Dict, .5}, etc.},		
		local randomChooser = LootPlan.new("single");
		--warn(enemyPartyMemberActionsArr[5][1].Name);
		for j,k in pairs(enemyPartyMemberActionsArr) do
			warn(tostring(k[1])..", "..tostring(k[2]));
			randomChooser:AddLoot(k[1]['NAME'], k[2]);--k[1] is the first entry in subarray (e.g. "Attack", etc.). k[2] is the weight value.
			warn("Added "..tostring(k[1]['NAME'])..", "..tostring(k[2]));
		end
		--randomChooser is ready to get random action!
		local chosenAction = EnemyAction(EnemyActionsList[""..randomChooser:GetRandomLoot()..""]); -- parameter is a dictionary
		local command = Command(v, chosenAction, chosenAction:ChooseTarget(v, self.PlayerParty.TeamMembers, self.EnemyParty.TeamMembers, chosenAction));
		table.insert(resultingArray, command);
	end
	return resultingArray;
end

function BattleSceneServer:CalculateDamage(initiatorPartyMember, targetPartyMember, isCrit, isElemental, damageMultiplier, damageElement, damageType, critDmg)
	if isCrit then warn("crit!"); end
	local targetDefense;
	local initiatorAttack;
	local plink = false;
	local softPlink = false;
	local bonusElementalModifier = 1;
	warn("bonusElementalModifier: "..tostring(bonusElementalModifier));
	--determine target's elemental resistances/weaknesses if target is enemy
	if targetPartyMember:is(EnemyPartyMember) then
		local electroResMultiplier = targetPartyMember.CURRELECTRORESMULTIPLIER;
		local cryoResMultiplier = targetPartyMember.CURRCRYORESMULTIPLIER;
		local pyroResMultiplier = targetPartyMember.CURRPYRORESMULTIPLIER;
		if damageElement == "PYRO" then
			bonusElementalModifier = pyroResMultiplier;
		elseif damageElement == "CRYO" then
			bonusElementalModifier = cryoResMultiplier;
		elseif damageElement == "ELECTRO" then
			bonusElementalModifier = electroResMultiplier;
		end
	end
	if isElemental == true then
		initiatorAttack = initiatorPartyMember.CURRMATK;
		targetDefense = targetPartyMember.CURRMDEF;
	else
		initiatorAttack = initiatorPartyMember.CURRPATK;
		targetDefense = targetPartyMember.CURRPDEF;
	end
	if isCrit then
		initiatorAttack = initiatorAttack * (1 + (critDmg / 100));
	end
	if initiatorAttack <= targetDefense/2  then
		plink = true;
	end
	if initiatorAttack <= targetDefense and initiatorAttack > targetDefense/2 then
		softPlink = true
	end
	-- attack*(100/(100+defense))
	local damage = initiatorAttack * (100 / (100 + targetDefense));
	--local damage = ((initiatorAttack)/(targetDefense+1))*2;
	damage = damage * (damageMultiplier / 100) * bonusElementalModifier * Random.new():NextNumber(.95,1.05);
	if plink then 
		warn("HARD PLINK!");
		if Random.new():NextInteger(1,4) <= 3 then 
			damage = 0;
		else damage = 1;
		end
	elseif softPlink then
		damage = damage / 1.5;
		warn("SOFT PLINK! Damage: "..damage);
	end
	if targetPartyMember.ISBEINGDEFENDED == true then
		damage = damage / 2;
	end
	local function getRelevantDamageTypeMult() -- SLASH, CRUSH, STAB, WEAPON, NONE
		if damageType == "STAB" then
			return targetPartyMember['CURRSTABRESMULTIPLIER'];
		elseif damageType == "SLASH" then
			return targetPartyMember['CURRSLASHRESMULTIPLIER'];
		elseif damageType == "CRUSH" then
			return targetPartyMember['CURRCRUSHRESMULTIPLIER'];
		else
			return targetPartyMember['EFFECTRESMULTIPLIER'];
		end
	end
	warn(targetPartyMember.Name.."'s defense is "..targetDefense..". Damage is "..damage..". TargetDefending is "..tostring(targetPartyMember.ISBEINGDEFENDED)..". SoftPlink is "..tostring(softPlink)..". HardPlink is "..tostring(plink)..". Initiator's attack is "..initiatorAttack..". DamageTypeMult is "..tostring(getRelevantDamageTypeMult())..". isElemental is "..tostring(isElemental)..". damage element is "..damageElement);
	return math.floor(math.clamp(damage * getRelevantDamageTypeMult(), 0, 999999) + .5);
end

function BattleSceneServer:CalculateHeal(initiatorPartyMember, targetPartyMember, damageMultiplier)--damageMultiplier will be negative
	local healingStrength = (initiatorPartyMember.CURRMATK + initiatorPartyMember.CURRMDEF) / 2;
	local rngAdditive = ((healingStrength) * Random.new():NextInteger(0, 255)) / 1024;
	local healAmount = ((healingStrength) + rngAdditive);
	healAmount = healAmount * (damageMultiplier / -100);
	local targetPartyMemberMissingHP = targetPartyMember.HP - targetPartyMember.CURRHP; -- 5 missing hp, heal 50 -> heal 5 actual
	local actualHealAmount;
	if targetPartyMemberMissingHP <= healAmount then
		actualHealAmount = targetPartyMemberMissingHP;
		warn("missinghp is less than or equal to heal amount. missinghp = "..targetPartyMemberMissingHP.." and healamount is "..healAmount);
	else
		actualHealAmount = healAmount;
		warn("missinghp is greater than healing amount. missinghp = "..targetPartyMemberMissingHP.." and healamount is "..healAmount);
	end
	warn("Healing for "..math.floor(actualHealAmount + .5));
	return math.floor(actualHealAmount + .5);
end

return BattleSceneServer;