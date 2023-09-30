--[[   Service dependencies   --]]
local RS = game:GetService("ReplicatedStorage");
local PLRS = game:GetService("Players");
local SS = game:GetService("ServerStorage");
local TS = game:GetService("TestService");

--[[   Folder references   --]]
local TBCFolder = RS.TurnBasedCombat;
local moduleFolder = TBCFolder.Modules;
local remoteEventsFolder = TBCFolder.RemoteEvents;
local tempPlayerModels = TBCFolder.TempPlayerModels;
local miscFolder = RS.Misc;
local classesFolder = TBCFolder.Classes;
local remoteFunctionsFolder = TBCFolder.RemoteFunctions;

--[[   External dependencies   --]]
local PlayerActionsList = require(classesFolder.Action.Storage.PlayerActionsList);
local EnemyNPCList = require(classesFolder.PartyMember.EnemyPartyMember.Storage.EnemyNPCList);
local util = require(miscFolder.Util);
local LootPlan = require(moduleFolder.LootPlan);
local EnemyLayouts = require(classesFolder.BattleScene.Storage.EnemyLayouts);
local WeaponsList = require(classesFolder.Item.Weapon.Storage.WeaponsList);
local ArmorList = require(classesFolder.Item.Armor.Storage.ArmorList);
local StatusEffectIcons = require(classesFolder.PartyMember.Storage.StatusEffectIcons);

--[[   Class dependencies   --]]
local BattleSceneServer = require(classesFolder.BattleScene.BattleSceneServer);
local PlayerAction = require(classesFolder.Action.PlayerAction);
local PartyMember = require(classesFolder.PartyMember);
local PlayerPartyMember = require(classesFolder.PartyMember.PlayerPartyMember);
local EnemyPartyMember = require(classesFolder.PartyMember.EnemyPartyMember);
local Party = require(classesFolder.Party);
local PlayerParty = require(classesFolder.Party.PlayerParty);
local EnemyParty = require(classesFolder.Party.EnemyParty);
local Command = require(classesFolder.Command);
local Buff = require(classesFolder.Buff);

--[[   Key variables   --]]
wipeout = false;
battleOver = true;
debounce = false;
fleeSuccessIndx = -1;
local EncounterServer;
local finishInterpretationListener;
--temporary actions for testing
local bobActions = {
	PlayerAction(PlayerActionsList["Attack"]),
	PlayerAction(PlayerActionsList["Defend"]),
	PlayerAction(PlayerActionsList["Flight"]),
	PlayerAction(PlayerActionsList["Heal I"]),
	PlayerAction(PlayerActionsList["YEET"]),
	PlayerAction(PlayerActionsList["War Cry"]),
};
local joeActions = {
	PlayerAction(PlayerActionsList["Attack"]),
	PlayerAction(PlayerActionsList["Defend"]),
	PlayerAction(PlayerActionsList["Flight"]),
	PlayerAction(PlayerActionsList["Iado: Thunder Form"]),
	PlayerAction(PlayerActionsList["Iado: Fire Form"]),
	PlayerAction(PlayerActionsList["Iado: Frost Form"]),
	PlayerAction(PlayerActionsList["Whirlwind Blades"]),
	PlayerAction(PlayerActionsList["Calm Mind"]),
};
local johnActions = {
	PlayerAction(PlayerActionsList["Attack"]),
	PlayerAction(PlayerActionsList["Defend"]),
	PlayerAction(PlayerActionsList["Flight"]),
	PlayerAction(PlayerActionsList["Heal I"]),
	PlayerAction(PlayerActionsList["Multiheal I"]),
	PlayerAction(PlayerActionsList["Ressurect I"]),
	PlayerAction(PlayerActionsList["Divine Barrier"]),
	PlayerAction(PlayerActionsList["Purify"]),
};
local billActions = {
	PlayerAction(PlayerActionsList["Attack"]),
	PlayerAction(PlayerActionsList["Defend"]),
	PlayerAction(PlayerActionsList["Flight"]),
	PlayerAction(PlayerActionsList["Inferno I"]),
	PlayerAction(PlayerActionsList["Conflagration I"]),
	PlayerAction(PlayerActionsList["Fireball I"]),	
	PlayerAction(PlayerActionsList["Accelerate"]),
	PlayerAction(PlayerActionsList["Magic Amplification"]),
	PlayerAction(PlayerActionsList["Icicle Lance I"]),
};
local partyMemberDict = {
	["Bob"] = {
		['NAME'] = 'Bob',
		['DESCRIPTION'] = 'Tank',
		['LEVEL'] = 5,
		['HP'] = 69,
		['MP'] = 24,
		['STR'] = 19,
		['INT'] = 6,
		['RES'] = 32,
		['WIS'] = 11,
		['AGI'] = 4,
		['LUC'] = 5,
		['ARMOR'] = ArmorList['Tweed'],
		['WEAPON'] = WeaponsList['Rusty Mace'],
		['ACCESSORY'] = nil,
		['MODEL'] = tempPlayerModels["Bob"],
		['ACTIONS'] = bobActions,

	},
	["Joe"] = {
		['NAME'] = 'Joe',
		['DESCRIPTION'] = 'Assassin',
		['LEVEL'] = 4,
		['HP'] = 81,
		['MP'] = 17,
		['STR'] = 30,
		['INT'] = 11,
		['RES'] = 17,
		['WIS'] = 5,
		['AGI'] = 18,
		['LUC'] = 27,
		['ARMOR'] = ArmorList['Tweed'],
		['WEAPON'] = WeaponsList['Old Katana'];
		['ACCESSORY'] = nil,
		['MODEL'] = tempPlayerModels["Joe"],
		['ACTIONS'] = joeActions,
	},
	["John"] = {
		['NAME'] = 'John',
		['DESCRIPTION'] = 'Cleric',
		['LEVEL'] = 5,
		['HP'] = 44,
		['MP'] = 65,
		['STR'] = 13,
		['INT'] = 17,
		['RES'] = 23,
		['WIS'] = 33,
		['AGI'] = 12,
		['LUC'] = 13,
		['ARMOR'] = ArmorList['Tweed'],
		['WEAPON'] = WeaponsList['Worn-out Lance'],
		['ACCESSORY'] = nil,
		['MODEL'] = tempPlayerModels["John"],
		['ACTIONS'] = johnActions,
	},
	["Bill"] = {
		['NAME'] = 'Bill',
		['DESCRIPTION'] = 'Mage',
		['LEVEL'] = 4,
		['HP'] = 37,
		['MP'] = 76,
		['STR'] = 7,
		['INT'] = 32,
		['RES'] = 10,
		['WIS'] = 21,
		['AGI'] = 16,
		['LUC'] = 15,
		['ARMOR'] = ArmorList['Tweed'],
		['WEAPON'] = WeaponsList['Novice Staff'],
		['ACCESSORY'] = nil,
		['MODEL'] = tempPlayerModels["Bill"],
		['ACTIONS'] = billActions,
	},
};
--party members should be created on the server side!
--{name, desc, lvl, hp, mp, str, int, res, wis, agi, luc, armor, weapon, accessory, model, actions}
local playerParty = PlayerParty({
	PlayerPartyMember(partyMemberDict['Bob']),
	PlayerPartyMember(partyMemberDict['Joe']),
	PlayerPartyMember(partyMemberDict['John']),
	PlayerPartyMember(partyMemberDict['Bill']),
});
local enemyParty;

function returnDuplicatesOfMonsterInParty(monsterName) --Returns the number of EnemyPartyMember(s) duplicates named monsterName 
	local counter = 0;
	--warn("Object is "..tostring(enemyParty)..". TeamMembers is "..tostring(enemyParty.TeamMembers));
	for i,v in pairs(enemyParty.TeamMembers) do
		if v.Name == monsterName then
			counter = counter + 1;
		end
	end
	return counter;
end

function returnAlphaOfMonster(monsterName) --Returns a letter name according to how much duplicates of EnemyPartyMember monsterName are in the party
	local stringToReturn = "";
	if returnDuplicatesOfMonsterInParty(monsterName) == 0 then 
		stringToReturn = "A";
	elseif returnDuplicatesOfMonsterInParty(monsterName) == 1 then
		stringToReturn = "B";
	elseif returnDuplicatesOfMonsterInParty(monsterName) == 2 then
		stringToReturn = "C";
	elseif returnDuplicatesOfMonsterInParty(monsterName) == 3 then
		stringToReturn = "D";
	elseif returnDuplicatesOfMonsterInParty(monsterName) == 4 then
		stringToReturn = "E";
	elseif returnDuplicatesOfMonsterInParty(monsterName) == 5 then
		stringToReturn = "F";
	elseif returnDuplicatesOfMonsterInParty(monsterName) == 6 then
		stringToReturn = "G";
	elseif returnDuplicatesOfMonsterInParty(monsterName) == 7 then
		stringToReturn = "H";
	elseif returnDuplicatesOfMonsterInParty(monsterName) == 8 then
		stringToReturn = "I";
	end
	return stringToReturn;
end

function createMonster(monsterName) -- Returns an EnemyPartyMember object
	return EnemyPartyMember(EnemyNPCList[monsterName], monsterName.." "..returnAlphaOfMonster(monsterName));
end

--table.insert(enemyParty.TeamMembers, createMonster("Radical Radish"));
--table.insert(enemyParty.TeamMembers, createMonster("Radical Radish"));
--table.insert(enemyParty.TeamMembers, createMonster("Radical Radish"));
--table.insert(enemyParty.TeamMembers, createMonster("Radical Radish"));
--table.insert(enemyParty.TeamMembers, createMonster("Radical Radish"));
--table.insert(enemyParty.TeamMembers, createMonster("Radical Radish"));
--table.insert(enemyParty.TeamMembers, createMonster("Radical Radish"));
--table.insert(enemyParty.TeamMembers, createMonster("Radical Radish"));

--warn (EncounterServer.EnemyParty.TeamMembers[1] == EncounterServer.EnemyParty.TeamMembers[2]);

--[[   Test functions   --]]
function prettyPartyPrint() -- stats displayed are temporary and can be changed by buffs/debuffs
	for i,v in pairs(EncounterServer.PlayerParty.TeamMembers) do
		print("||======== Position",i,":",v.Name,"[Lv.",v.LEVEL.."] : Status Effect Timer is at",v.STATUSEFFECTTIMER,"========||\n\tHP:",v.CURRHP,"/",v.HP,"\tMP:",v.CURRMP,"/",v.MP.."\tSTATUS:",v.STATUSEFFECT,"\n\t\tPATK:",v.CURRPATK.."\t\tMATK:",v.CURRMATK.."\t\tPDEF:",v.CURRPDEF.."\t\tMDEF:",v.CURRMDEF.."\n\t\tEVA:",v.CURREVA.."%\t\tSPD:",v.CURRSPD.."\t\tCRITRATE:",v.CURRCRITRATE.."%\t\tCRITDAMAGE:",v.CURRCRITDAMAGE.."%\n");		
	end
end

remoteEventsFolder.BattleSystem.PrintParty.OnServerEvent:Connect(function(plr)
	prettyPartyPrint();
end)


--[[   Key functions   --]]
function processBuffCode(victimObj, code, revert, applyStats) -- a void mutator function
	if applyStats == false then return; end
	--- break down buff code into table	
	-- example code: PATK|-25,CRITRATE|+50
	if code == "NONE" then return; end
	local arr = util:ExtractCSV(code);
	for i,v in pairs(arr) do
		local separatorIndx = string.find(v, "|");
		local currStatToModify = string.sub(v, 1, separatorIndx - 1);
		local posNegSymbol = string.sub(v, separatorIndx + 1, separatorIndx + 1);
		local buffVal = (tonumber(string.sub(v, separatorIndx + 2)) / 100);

		local function addOrSubtract(a,b, reverse)
			if posNegSymbol == "+" then
				if reverse then return a-b; end
				return a+b;
			end
			if reverse then return a+b; end
			return a-b;
		end


		if currStatToModify == "PATK" then
			if not revert then victimObj.PATKMOD = addOrSubtract(victimObj.PATKMOD, buffVal, false); else victimObj.PATKMOD = addOrSubtract(victimObj.PATKMOD, buffVal, true); end
			victimObj.CURRPATK = victimObj.PATK * victimObj.PATKMOD;
		elseif currStatToModify == "MATK" then
			if not revert then victimObj.MATKMOD = addOrSubtract(victimObj.MATKMOD, buffVal, false); else victimObj.MATKMOD = addOrSubtract(victimObj.MATKMOD, buffVal, true); end
			victimObj.CURRMATK = victimObj.MATK * victimObj.MATKMOD;
		elseif currStatToModify == "PDEF" then
			if not revert then victimObj.PDEFMOD = addOrSubtract(victimObj.PDEFMOD, buffVal, false); else victimObj.PDEFMOD = addOrSubtract(victimObj.PDEFMOD, buffVal, true); end
			victimObj.CURRPDEF = victimObj.PDEF * victimObj.PDEFMOD;
		elseif currStatToModify == "MDEF" then
			if not revert then victimObj.MDEFMOD = addOrSubtract(victimObj.MDEFMOD, buffVal, false); else victimObj.MDEFMOD = addOrSubtract(victimObj.MDEFMOD, buffVal, true); end
			victimObj.CURRMDEF = victimObj.MDEF * victimObj.MDEFMOD;
		elseif currStatToModify == "EVA" then
			if not revert then victimObj.EVAMOD = addOrSubtract(victimObj.EVAMOD, buffVal * 100, false); else victimObj.EVAMOD = addOrSubtract(victimObj.EVAMOD, buffVal * 100, true); end
			victimObj.CURREVA = victimObj.EVA + victimObj.EVAMOD;
		elseif currStatToModify == "SPD" then
			if not revert then victimObj.SPDMOD = addOrSubtract(victimObj.SPDMOD, buffVal, false); else victimObj.SPDMOD = addOrSubtract(victimObj.SPDMOD, buffVal, true); end
			victimObj.CURRSPD = victimObj.SPD * victimObj.SPDMOD;
		elseif currStatToModify == "CRITRATE" then
			if not revert then victimObj.CRITRATEMOD = addOrSubtract(victimObj.CRITRATEMOD, buffVal * 100, false); else victimObj.CRITRATEMOD = addOrSubtract(victimObj.CRITRATEMOD, buffVal * 100, true); end
			victimObj.CURRCRITRATE = victimObj.CRITRATE + victimObj.CRITRATEMOD;
		elseif currStatToModify == "CRITDAMAGE" then
			if not revert then victimObj.CRITDAMAGEMOD = addOrSubtract(victimObj.CRITDAMAGEMOD, buffVal * 100, false); else victimObj.CRITDAMAGEMOD = addOrSubtract(victimObj.CRITDAMAGEMOD, buffVal * 100, true); end
			victimObj.CURRCRITDAMAGE = victimObj.CRITDAMAGE + victimObj.CRITDAMAGEMOD;
		elseif string.find(currStatToModify, "RES") ~= nil then
			if string.find(currStatToModify, "MULTIPLIER") ~= nil then -- it is a elemental or damage type res stat
				if not revert then victimObj[currStatToModify.."MOD"] = addOrSubtract(victimObj[currStatToModify.."MOD"], buffVal * 100, false); else victimObj[currStatToModify.."MOD"] = addOrSubtract(victimObj[currStatToModify.."MOD"], buffVal * 100, true); end
				victimObj["CURR"..currStatToModify] = math.clamp(victimObj[currStatToModify] + victimObj[currStatToModify.."MOD"], 0, math.huge);
			else -- for stat res
				if not revert then victimObj[currStatToModify.."MOD"] = addOrSubtract(victimObj[currStatToModify.."MOD"], buffVal * 100, false); else victimObj[currStatToModify.."MOD"] = addOrSubtract(victimObj[currStatToModify.."MOD"], buffVal * 100, true); end
				victimObj["CURR"..currStatToModify] = victimObj[currStatToModify] + victimObj[currStatToModify.."MOD"];
			end
		else
			error("invalid currStatToModify: "..currStatToModify);
		end
	end
	--sync();
end

function cleanseBuff(mem, buff)
	if not buff.ISDEBUFF then
		for i,v in pairs(mem.BUFFS) do
			local buffName = buff.NAME;
			if v.NAME == buffName then
				processBuffCode(mem, v.EFFECTSTR, true, true);
				-- remove it
				-- get index of this buff and remove it
				local removed = table.remove(mem.BUFFS, i);
				--print("inhere1",removed.NAME, removed.DURATION);
				return;
			end
		end
	else
		for i,v in pairs(mem.DEBUFFS) do
			local buffName = buff.NAME;
			if v.NAME == buffName then
				processBuffCode(mem, v.EFFECTSTR, true, true);
				-- remove it
				-- get index of this buff and remove it
				local removed = table.remove(mem.DEBUFFS, i);
				return;
			end
		end
	end
	return;
end

function cleanseBuffs(mem) -- cleanse all buffs and debuffs for chosen party member
	while #mem.BUFFS > 0 do
		local currBuff = mem.BUFFS[1];
		-- break down buff and revert it
		processBuffCode(mem, currBuff.EFFECTSTR, true, true);
		-- then remove it
		local removed = table.remove(mem.BUFFS, 1);
		--print("inhere11",removed.NAME, removed.DURATION);
	end
	while #mem.DEBUFFS > 0 do
		local currBuff = mem.DEBUFFS[1];
		-- break down buff and revert it
		processBuffCode(mem, currBuff.EFFECTSTR, true, true);
		-- then remove it
		local removed = table.remove(mem.DEBUFFS, 1);
	end

end	

function deinit()
	if finishInterpretationListener then finishInterpretationListener:Disconnect(); end
	for i,v in pairs(EncounterServer.PlayerParty.TeamMembers) do
		cleanseBuffs(v);
	end
	-- if they flee or wipe or win before turn ends,
	--make all party members have no guardian and set being defend to false
	for i,v in pairs(EncounterServer.PlayerParty.TeamMembers) do
		v.ISBEINGDEFENDED = false;
		v.GUARDIANINDEXINPARTY = nil;
	end
	--do same thing for enemy party
	for i,v in pairs(EncounterServer.EnemyParty.TeamMembers) do
		v.ISBEINGDEFENDED = false;
		v.GUARDIANINDEXINPARTY = nil;
	end

	-- get rid of temporary status effects on the player party
	for i,v in pairs(playerParty.TeamMembers) do
		if v.STATUSEFFECT ~= "DEAD" then
			v.STATUSEFFECT = "NONE";
		end
		v.STATUSEFFECTTIMER = 0;
	end
	fleeSuccessIndx = -1;
	EncounterServer = nil; -- might not want to do this
	-- clear enemy party
	enemyParty = nil; -- might not want to do this
	-- also deinit client
	remoteEventsFolder.BattleSystem.DeinitClient:FireAllClients() -- might want to pass in client id
	workspace.EncounterTrigger.Color = Color3.new(1,1,0);
	workspace.BossEncounterTrigger.Color = Color3.new(1,1,0);
	workspace.EncounterTrigger.BillboardGui.TextLabel.Text = "ON COOLDOWN";
	workspace.BossEncounterTrigger.BillboardGui.TextLabel.Text = "ON COOLDOWN";
	wait(5);
	debounce = false;
	workspace.EncounterTrigger.BillboardGui.TextLabel.Text = "TOUCH TO ENTER BATTLE";
	workspace.BossEncounterTrigger.BillboardGui.TextLabel.Text = "TOUCH TO ENTER BOSS BATTLE";
	workspace.EncounterTrigger.Color = Color3.new(0,1,0);
	workspace.BossEncounterTrigger.Color = Color3.new(0,1,0);
	print("ready")
end

function init()
	print("initializing battlescene");
	local function loadEnemyLayout(dungeonName, areaName)
		local sing = LootPlan.new("single");
		for i,v in pairs(EnemyLayouts[dungeonName][areaName]) do
			local layout = v[1];
			local weight = v[2];
			sing:AddLoot(layout, weight);
		end
		local randLayout = sing:GetRandomLoot();
		for i,v in pairs(randLayout) do
			table.insert(enemyParty.TeamMembers, createMonster(v));
		end
	end
	enemyParty = EnemyParty();
	EncounterServer = BattleSceneServer(playerParty, enemyParty);
	loadEnemyLayout("Twilight Forest", "Area 1")
	remoteEventsFolder.BattleSystem.InitializeBattleSceneClient:FireAllClients(EncounterServer); -- later when implementing multiplayer you want to change fireallclients to specific clients
end

function sync()
	remoteEventsFolder.BattleSystem.InvokePartyInfoChangeToClient:FireAllClients(EncounterServer);
end

function initBoss()
	print("initializing battlescene");
	local function loadEnemyLayout(dungeonName, areaName)
		local sing = LootPlan.new("single");
		for i,v in pairs(EnemyLayouts[dungeonName][areaName]) do
			local layout = v[1];
			local weight = v[2];
			sing:AddLoot(layout, weight);
		end
		local randLayout = sing:GetRandomLoot();
		for i,v in pairs(randLayout) do
			table.insert(enemyParty.TeamMembers, createMonster(v));
		end
	end
	enemyParty = EnemyParty();
	EncounterServer = BattleSceneServer(playerParty, enemyParty, nil, true);
	loadEnemyLayout("Twilight Forest", "Boss");
	remoteEventsFolder.BattleSystem.InitializeBattleSceneClient:FireAllClients(EncounterServer); -- later when implementing multiplayer you want to change fireallclients to specific clients
end

remoteEventsFolder.BattleSystem.FleeSuccess.OnServerEvent:Connect(function()
	if battleOver then
		deinit();	
	end

end)

function InflictStatus(partyMember, action)
	if action and action.StatusEffect ~= "NONE" then -- if action is capable of inflicting status effect
		local percentStartIndx = string.find(action.StatusEffect, "@");
		local inflictChance = 0;
		if percentStartIndx ~= nil then
			inflictChance = tonumber(string.sub(action.StatusEffect, percentStartIndx + 1)) / 100;	
		end	
		local atSymbolIndx = string.find(action.StatusEffect, "@");
		local newStatus = string.sub(action.StatusEffect, 1, atSymbolIndx - 1);
		local resistanceStat = 0;
		if newStatus == "DEATH" then
			resistanceStat = partyMember.CURRINSTANTDEATHRES;
		else
			resistanceStat = partyMember["CURR"..newStatus.."RES"];
		end
		if Random.new():NextNumber() < inflictChance and partyMember.STATUSEFFECT ~= "DEAD" and Random.new():NextNumber() >= (resistanceStat / 100) then -- this might interfere with reviving
			-- get duration of new status effect
			local duration = Random.new():NextInteger(action.MinStatusEffectDuration, action.MaxStatusEffectDuration);
			-- if new status effect is the same as the old one, prolong the timer. This amplifies dot damage too!
			local oldStatus = partyMember.STATUSEFFECT;
			if oldStatus == newStatus then
				partyMember.STATUSEFFECTTIMER = partyMember.STATUSEFFECTTIMER + duration;
			else
				partyMember.STATUSEFFECTTIMER = duration;	
			end
			partyMember.STATUSEFFECT = newStatus;			
			return partyMember.STATUSEFFECT;
		end
	end
	--sync();
	return "NONE";
end

function InflictStatusNoAction(partyMember, newStatus, minDuration, maxDuration)
	if partyMember.STATUSEFFECT ~= "DEAD" then -- this might interfere with reviving
		-- get duration of new status effect
		local duration = Random.new():NextInteger(minDuration, maxDuration);
		-- if new status effect is the same as the old one, prolong the timer.
		local oldStatus = partyMember.STATUSEFFECT;
		if oldStatus == newStatus then
			partyMember.STATUSEFFECTTIMER = partyMember.STATUSEFFECTTIMER + duration;
		else
			partyMember.STATUSEFFECTTIMER = duration;	
		end
		partyMember.STATUSEFFECT = newStatus;
	end
	--sync();
end


function LoseStat(partyMember, HPorMP, amount, isCrit, isHeal, actionIfPresent)
	--[[
	Inflicts HP or MP damage to PartyMember partymember by int amount. 
	If bool crit is true, inflict critical damage.
	If bool isHeal is true, do healing.
	Action actionIfPresent is the Action object
	--]]	

	if HPorMP == "HP" and amount < 0 and partyMember.CURRHP == 0 then--make it such that dead people can't be healed back to life by just heal spells
		if actionIfPresent and actionIfPresent.IsRevivalSkill == true then--is revival skill
			partyMember:LoseHP(amount);
			--remove dead status effect
			partyMember.STATUSEFFECT = "NONE";
		elseif actionIfPresent and actionIfPresent.IsSupportSpell == true and actionIfPresent.RemoveStatusEffect == false then
			if actionIfPresent.Buffs ~= "NONE" then
				amount = -6667331
				print(actionIfPresent.Name, amount);
			elseif actionIfPresent.Debuffs ~= "NONE" then
				amount = -4207331
				print(actionIfPresent.Name, amount);
			else
				amount = -6667331;	
				print(actionIfPresent.Name, amount);
			end
			partyMember:LoseHP(amount);--heal but heal nothing	
		end
	elseif HPorMP == "HP" then
		if actionIfPresent and actionIfPresent.IsSupportSpell == true and actionIfPresent.RemoveStatusEffect == true then
			amount = -420420420;
			partyMember:LoseHP(-420420420);--heal but heal nothing
			partyMember.STATUSEFFECT = "NONE";
		end
		partyMember:LoseHP(amount);
		if partyMember.CURRHP <= 0 then
			partyMember.STATUSEFFECT = "DEAD";
		end
	elseif HPorMP == "MP" then
		partyMember:LoseMP(amount);
	end
	--sync change to client. dont do this here.
	--sync();
end

function addActionsToPlayerActionsList(list, listOfActionDicts)
	for i,v in pairs(listOfActionDicts) do
		table.insert(list, PlayerAction(v));
	end
end

function checkPartyMemberType(pm)
	if pm:is(PlayerPartyMember) then
		return "Player";
	elseif pm:is(EnemyPartyMember) then
		return "Enemy";
	end
	error("PartyMember given is neither Player or Enemy!");
end



workspace.EncounterTrigger.Touched:Connect(function(hit)
	if hit.Parent:FindFirstChild("Humanoid") and debounce == false and wipeout == false then
		debounce = true;
		battleOver = false;
		workspace.EncounterTrigger.Color = Color3.new(0,0,1);
		workspace.EncounterTrigger.BillboardGui.TextLabel.Text = "IN BATTLE";
		workspace.BossEncounterTrigger.Color = Color3.new(0,0,1);
		workspace.BossEncounterTrigger.BillboardGui.TextLabel.Text = "IN BATTLE";
		--do init!
		init();
	elseif wipeout == true then
		workspace.EncounterTrigger.Color = Color3.new(1,0,0);
		workspace.EncounterTrigger.BillboardGui.TextLabel.Text = "PARTY WIPED OUT. REJOIN TO TEST AGAIN!";
		workspace.BossEncounterTrigger.Color = Color3.new(1,0,0);
		workspace.BossEncounterTrigger.BillboardGui.TextLabel.Text = "PARTY WIPED OUT. REJOIN TO TEST AGAIN!";
	end
end)

workspace.BossEncounterTrigger.Touched:Connect(function(hit)
	if hit.Parent:FindFirstChild("Humanoid") and debounce == false and wipeout == false then
		debounce = true;
		battleOver = false;
		workspace.BossEncounterTrigger.Color = Color3.new(0,0,1);
		workspace.BossEncounterTrigger.BillboardGui.TextLabel.Text = "IN BATTLE";
		workspace.EncounterTrigger.Color = Color3.new(0,0,1);
		workspace.EncounterTrigger.BillboardGui.TextLabel.Text = "IN BATTLE";
		--do init!
		initBoss();
	elseif wipeout == true then
		workspace.BossEncounterTrigger.Color = Color3.new(1,0,0);
		workspace.BossEncounterTrigger.BillboardGui.TextLabel.Text = "PARTY WIPED OUT. REJOIN TO TEST AGAIN!";
		workspace.EncounterTrigger.Color = Color3.new(1,0,0);
		workspace.EncounterTrigger.BillboardGui.TextLabel.Text = "PARTY WIPED OUT. REJOIN TO TEST AGAIN!";
	end
end)


remoteEventsFolder.BattleSystem.SendCommandToServer.OnServerEvent:Connect(function(player, primitiveCommandArr)
	--print("inhere6 sent command to server");
	local clientInterpretation;
	--print(primitiveCommandArr);--you want to turn this into a dictionary
	local finalQueue;
	local function determineBattleStatus()
		--victory if all enemies are dead, game over if all players are dead
		-- -1 for game over, 1 for victory, 0 for neither
		local function getNumberDeadEnemies()
			local counter = 0;
			for i,v in pairs(EncounterServer.EnemyParty.TeamMembers) do
				if v.CURRHP == 0 or v.STATUSEFFECT == "DEAD" then
					counter += 1;
				end
			end
			return counter;
		end
		local function getNumberDeadPlayers()
			local counter = 0;
			for i,v in pairs(EncounterServer.PlayerParty.TeamMembers) do
				if v.CURRHP == 0 or v.STATUSEFFECT == "DEAD" or v.STATUSEFFECT == "FROZEN" then
					counter += 1;
				end
			end
			return counter;
		end
		local numEnemiesInParty = #(EncounterServer.EnemyParty.TeamMembers);
		local numPlayersInParty = #(EncounterServer.PlayerParty.TeamMembers);
		--prioritize player wipe out over enemy wipe out
		if getNumberDeadPlayers() == numPlayersInParty then 
			return -1;
		elseif getNumberDeadEnemies() == numEnemiesInParty then
			return 1;
		end
		return 0;
	end
	--update battle status every time someone dies
	local function checkBattleStatus()
		warn("checking battle status");
		if determineBattleStatus() ~= 0 then
			battleOver = true;
		end
	end
	local function updateBattleStatus() -- should be a void method that does things
		if determineBattleStatus() == 0 then -- neither (advance turn)
			TS:Message("STILL IN BATTLE!");
			remoteEventsFolder.BattleSystem.AdvanceTurn:FireAllClients();
			--if finalQueue then remoteEventsFolder.BattleSystem.SendQueueToClient:FireAllClients(finalQueue); end -- just for testing purposes; see what the queue looks like
		elseif determineBattleStatus() == -1 then -- game over
			battleOver = true;
			TS:Message("GAME OVER!")
			remoteEventsFolder.BattleSystem.EndBattle:FireAllClients(false);
			wipeout = true;
			wait(25.5);
			-- deinitialize battlescenes for server and client
			deinit();
		elseif determineBattleStatus() == 1 then -- victory!
			battleOver = true;
			TS:Message("VICTORY!")
			remoteEventsFolder.BattleSystem.EndBattle:FireAllClients(true);
			wait(3);
			-- deinitialize battlescenes for server and client
			deinit();
		else
			error("determineBattleStatus() returned something unexpected!");
		end
	end
	--turn the primitiveCommandArr into an actual Command[] array
	--what primitivecommandarr looks like: { {initiatorIndex, actionName, {index1, index2,...}, playerOrEnemyParty}, {initiatorIndex, actionName, {index1, index2,...}, playerOrEnemyParty}, {initiatorIndex, actionName, {index1, index2,...}, playerOrEnemyParty}, {initiatorIndex, actionName, {index1, index2,...}, playerOrEnemyParty}  }
	local result = {};
	for i,v in pairs(primitiveCommandArr) do
		local currentPrimitiveCommand = v;
		local initiatorIndex = currentPrimitiveCommand[1];
		local actionName = currentPrimitiveCommand[2];
		local arrWithTargetIndexes = currentPrimitiveCommand[3];
		local playerOrEnemyParty = currentPrimitiveCommand[4];
		local initiatorPlayerPartyMemberObject = EncounterServer.PlayerParty.TeamMembers[initiatorIndex];
		local targetArr;
		local arrWithTargetPartyMemberObjects = {};
		--print(playerOrEnemyParty);
		if playerOrEnemyParty == "EnemyParty" then
			targetArr = EncounterServer.EnemyParty.TeamMembers;
		elseif playerOrEnemyParty == "PlayerParty" then
			targetArr = EncounterServer.PlayerParty.TeamMembers;
		elseif string.find(playerOrEnemyParty, "PlayerParty") ~= nil and string.len(playerOrEnemyParty) == 22 then --then it is a guarding action, PlayerPartyGuardIndex#
			targetArr = EncounterServer.PlayerParty.TeamMembers;
			local indexToGuard = tonumber(string.sub(playerOrEnemyParty, 22));
			local isGuardingSelf;
			if indexToGuard then
				local playerToGuard = EncounterServer.PlayerParty.TeamMembers[indexToGuard];
				if playerToGuard == initiatorPlayerPartyMemberObject then--is guarding self
					isGuardingSelf = true;
					playerToGuard.GUARDIANINDEXINPARTY = indexToGuard;
					warn(playerToGuard.Name.."'s Guardianindex set to "..indexToGuard);
				else--is guarding someone else
					isGuardingSelf = false;
					playerToGuard.GUARDIANINDEXINPARTY = initiatorIndex;
					warn(playerToGuard.Name.."'s Guardianindex set to "..initiatorIndex);
				end
			else
				error("INDEXTOGUARD IS NOT A NUMBER! INDEXTOGUARD IS "..tostring(indexToGuard));
			end
		else
			error("INVALID PARTYTYPE! ".." PARTYTYPE IS "..tostring(playerOrEnemyParty));
		end
		for j,k in pairs(arrWithTargetIndexes) do--what arr with target indexes looks like example: {1, 2, 3, 4}
			table.insert(arrWithTargetPartyMemberObjects, targetArr[k]);
		end
		local commandResult = Command(initiatorPlayerPartyMemberObject, PlayerAction(PlayerActionsList[actionName]), arrWithTargetPartyMemberObjects);
		table.insert(result, commandResult);
	end
	finalQueue = EncounterServer:AssembleQueue(result);
	--try sending over the finalQueue to the client
	--remoteEventsFolder.BattleSystem.SendQueueToClient:FireAllClients(finalQueue);
	local function simulateTurn()
		clientInterpretation = {};
		local proceed = false;
		local function cannotAct(partyMember)
			return partyMember.STATUSEFFECT == "DEAD" or partyMember.STATUSEFFECT == "FROZEN";
		end
		local function convertArrayToCommas(arr, noExtraLineNeeded)
			local resultString = "";
			if noExtraLineNeeded then return resultString; end
			for i,v in pairs(arr) do
				if i + 1 ~= #arr and #arr >= 3 and i ~= #arr then
					resultString = resultString..v.DISPLAYNAME..", ";
				elseif i + 1 == #arr and #arr == 2 then
					resultString = resultString..v.DISPLAYNAME.." and ";
				elseif i + 1 == #arr and #arr > 2 then
					resultString = resultString..v.DISPLAYNAME..", and ";
				elseif #arr == 1 or i == #arr then
					resultString = resultString..v.DISPLAYNAME;
				else
					error("WE HAVE A PROBLEM IN CONVERTARRAYTOCOMMAS() METHOD!");
				end
			end
			return resultString;
		end
		local function convertArrayToCommasConsiderMentionTarget(arr, mentionTarget, initiator)
			local resultString = " ";
			if mentionTarget == false then return ""; end
			for i,v in pairs(arr) do
				local targetObj = v;
				if initiator == targetObj then return "."; end
				if i + 1 ~= #arr and #arr >= 3 and i ~= #arr then
					resultString = resultString..v.DISPLAYNAME..", ";
				elseif i + 1 == #arr and #arr >= 2 then
					resultString = resultString..v.DISPLAYNAME..", and ";
				elseif #arr == 1 or i == #arr then
					resultString = resultString..v.DISPLAYNAME;
				else
					error("WE HAVE A PROBLEM IN CONVERTARRAYTOCOMMASIGNORENOEXTRALINENEEDED() METHOD!");
				end
			end
			return resultString..".";--add period
		end
		local function extractDamageFromDamageInstance(dmgInstance)
			local sepIndx = string.find(dmgInstance, "*");
			if sepIndx == nil then return tonumber(dmgInstance); end
			return tonumber(string.sub(dmgInstance, 1, sepIndx - 1));
		end
		local function calcAvgOfIntElemsInArr(damageArr, isHealing)
			local avg = 0;
			for i,v in pairs(damageArr) do
				local w = extractDamageFromDamageInstance(v);
				if w == -1337666 then w = 0; end
				avg = avg + w;
			end
			return math.floor((avg / #damageArr) + .5);
		end
		local function considerAndAdjustHPChangeTextIfAOE(arr, damage, noExtraLineNeeded, isHeal, isRevive, isSupportSpell, supportFlavor)--damage is an array of int[]. order of elements is not important. #arr should equal #damage.
			for i,v in pairs(arr) do
				if isRevive == false and isHeal == true and v.CURRHP == 0 then
					--determine if partymember is player or enemy
					local isPlayer;
					if v:is(PlayerPartyMember) then
						isPlayer = true;
					elseif v:is(EnemyPartyMember) then
						isPlayer = false;
					else
						error("PARTYMEMBER IS NOT PLAYER OR ENEMY!");
					end
					local partyMemberIndexInTargetsArr = util:IndexOf(arr, v);
					damage[partyMemberIndexInTargetsArr] = -0;--makes their heal insignificant if dead
				end
			end
			local resultString = "";
			if damage == nil or #damage == 0 or noExtraLineNeeded then
				return resultString;
			elseif isHeal then--is healing. is initially false because it first assumes that it is not healing
				if #arr >= 2 and damage then
					resultString = " recover an average of "..calcAvgOfIntElemsInArr(damage, true).." HP!";
				elseif damage then
					resultString = " recovers "..calcAvgOfIntElemsInArr(damage, true).." HP!";
				end
			elseif isSupportSpell and supportFlavor ~= nil then
				-- get support spell flavor
				resultString = supportFlavor;
			elseif isSupportSpell and supportFlavor == nil then
				error("a support spell is missing support flavor!");
			else
				if #arr >= 2 and damage then
					resultString = " take an average of "..calcAvgOfIntElemsInArr(damage, false).." damage!";
				elseif damage then
					resultString = " takes "..calcAvgOfIntElemsInArr(damage, false).." damage!";
				end	
			end
			return resultString;
		end
		local function critMissOrNoDamage(action, damageArr, noExtraLineNeeded, isHeal)
			if isHeal then return ""; end
			--warn("#damageArr is "..#damageArr.." and calcAvgOfIntElemsInArr(damageArr, false) is "..calcAvgOfIntElemsInArr(damageArr, false));
			local resultString = "";
			if noExtraLineNeeded then return resultString; end
			if damageArr and calcAvgOfIntElemsInArr(damageArr, false) == 0 then--target evade/miss
				local possiblePhrases = {""};
				resultString = util:Choice(possiblePhrases);
				return resultString;
			end
			if damageArr and #damageArr == 1 then
				if action.IsCrit == true then
					local possiblePhrases = {"Critical hit! ", "Terrific blow! ", "Savage strike!  ", "Damn! "};
					resultString = util:Choice(possiblePhrases);	
					return resultString;
				end
			else
			end
			return resultString;
		end
		for n, m in pairs(finalQueue) do -- take care of moves that move first without dialog (defending)
			local action = m.ACTION;
			local initiator = m.INITIATOR;
			if action.Name == "Defend" then
				initiator.ISBEINGDEFENDED = true;
			end
		end
		local function getIndexFromPartyMember(partyMember)
			local arrToSearch;
			if partyMember:is(EnemyPartyMember) then
				arrToSearch = EncounterServer.EnemyParty.TeamMembers;
			elseif partyMember:is(PlayerPartyMember) then
				arrToSearch = EncounterServer.PlayerParty.TeamMembers;
			else
				error("INITIATORPARTYMEMBER IS NOT ENEMYPARTYMEMBER OR PLAYERPARTYMEMBER!");
			end
			return util:IndexOf(arrToSearch, partyMember);
		end
		local function determineIfEnemyOrPlayerPartyMember(partyMember)
			if partyMember:is(EnemyPartyMember) then
				return false;
			elseif partyMember:is(PlayerPartyMember) then
				return true;
			end
			error("INITIATORPARTYMEMBER IS NOT ENEMYPARTYMEMBER OR PLAYERPARTYMEMBER!");
		end
		local function isOrAreDefeated(deadTargetArr) -- can be arr of partymembers or just displaynames
			local punctuations = {".", "!"};
			local singularPhrases = {"perishes", "dies", "meets their demise", "has fallen", "rests in peace", "succumbs to the damage", "is mortally wounded", "receives a fatal injury", "drops dead", "bites the dust", "is defeated", "is eliminated", "is annihilated","ceases to exist","kicked the bucket","is destroyed","is decimated"};
			local pluralPhrases = {"perish", "die", "met their demise", "have fallen", "rest in peace", "succumb to the damage", "are mortally wounded", "receive a fatal injury", "drop dead", "bite the dust", "are defeated", "are eliminated", "are annihilated","cease to exist","kicked the bucket","are destroyed","are decimated"};
			local wordToUse = util:Choice(singularPhrases);
			if #deadTargetArr > 1 then
				wordToUse = util:Choice(pluralPhrases);
			end
			return wordToUse..util:Choice(punctuations);
		end
		local function formatDefeatedEnemyTargetsArrIntoString(defeatedTargetsArr) -- takes defeated targets and keeps only enemy party members. Then formats into string containing killed enemy indices
			local subResult = {};
			local result = "";
			if #defeatedTargetsArr == 0 then return result; end
			for i,v in pairs(defeatedTargetsArr) do
				local currPartyMember = v;
				if determineIfEnemyOrPlayerPartyMember(currPartyMember) == false then -- if enemy party member
					table.insert(subResult, v);
				end
			end
			for i,v in pairs(subResult) do
				result = result..getIndexFromPartyMember(v);
				if i ~= #subResult then result = result..","; end
			end
			return result;
		end
		--[[
			What the client does:
				- display damage indication
				- update health bars
				- show/hide markers
				- update ui elements (log text, other text, images, colors, etc.)
				- play sounds 
			What info the client needs in order to do this:
				- log text
				- Unique IDs for all player and enemy party members
				- data needs to be in chronological order for it to play out correctly
			A possible format (as a string): ~IID<index,isPlayerParty>~ICMD<actionName,(targetPartyIndex#isPlayerParty#dmgAmnt...),isCrit,isHealing,isSupportSpell,imbuedElement>~LTXT<logTxt>~ACOST<amount(HP/MP)>~AFTERMATH<(true/false),hpAmnt>~DUR<seconds>~SFX<soundName,vol,timePos>
			- The ... represents that you can list this with a comma separator
			- They don't have to be in order! We can just use a find function when accessing the string for important info on the client.
				Key: 
					- ~IID<index,isPlayerParty>: index is the initiator's index in their party arr
					- ~POINTTARGETS<targetPartyIndex#isPlayerParty...>: the targets to put pointers on
					- ~ICMD<actionName,(targetPartyIndex#isPlayerParty#dmgAmnt#isCrit#inflictStatus...),isHealing,imbuedElement,damageType>: Initiator Command. Attack miss if dmgAmnt == "MISS" if not applicable, dmgAmnt is NONE
						- When guarded, looks like this. Example: 1 is defender, 4 is target to defend. Assume both indices are in same party:
							- 4&1#true#1#false will appear in intended targets list
					- ~LTXT<logTxt>: Log Text
					- ~ACOST<amount(MP)>: Action Cost in MP
					- ~DUR<seconds>: How long you have to wait for it to automatically continue
					- ~SFX<soundName,vol,timePos>: Looks for soundName in LocalPlayer.PlayerGui.LocalSFX folder
					- ~SFXFROMACTION<actionName,int>: Plays appropriate hit or cast SFX given action name. 0 is cast while 1 is hit
					- ~AFMTH<targetPartyIndex#isPlayerParty#dmgAmnt>: aftermath damage for one party member
					- ~ENDEATH<(index1, index2, index3, ...)>: ashifies enemy at indices. Used when they die. Always paired with ~ICMD.
					- ~UPDTPLRFRMSTATUS<index, statusEffectName>: updates player visual status effect on player frame.
				Example:
					- "~IID<2,true>~ICMD<Attack,(3#false#4),false,false,false,WEAPON,WEAPON>~LTXT<Bob attacks! Radical Radish C takes 4 damage!>~ACOST<NONE>~AFTERMATH<false,NONE>~DUR<1>~SFX<Hit,.8,0>"
				
		--]]
		for a,b in pairs(finalQueue) do -- b is the command object. this is where we do the real shit.
			local startTime = tick();
			local initiator = b.INITIATOR;
			local action = b.ACTION;
			local logFlavor = action.LogFlavor;
			local targetClassObjects = b.TARGETS;
			local noExtraLineNeeded = action.NoExtraLineNeeded;
			local isHealing = false;
			local mentionTarget = action.MentionTarget;
			local currActionDefeatedTargets = {};
			local currActionStatusInflictions = {};
			local currActionActualHitEnemies = {};
			local currActionCritHitEnemies = {}; -- example element: targetIndex#isPlayerParty
			local resultsArr2 = {}; -- intended targets resulting damage arr. resultArr is actual hit targets resulting damage arr.
			local initiatorIsPlayerPartyMember = determineIfEnemyOrPlayerPartyMember(initiator);
			local aftermathDamageTaken = false;
			local targetType = action.TargetType;
			local isRevivalSkill = action.IsRevivalSkill;
			local targetPartyArr; 
			local function onSameParty(m1, m2) -- if returns true, then m1 and m2 are of same party
				local m1BoolStr = util:StringifyBool(determineIfEnemyOrPlayerPartyMember(m1));
				local m2BoolStr = util:StringifyBool(determineIfEnemyOrPlayerPartyMember(m1));
				return m1BoolStr == m2BoolStr; 
			end

			if action.Name == "Flight" then 
				-- see if the flight was successful first 
				--print("in here")
				local function fleeSuccess()
					-- get average speed of both player and enemy parties and then factor in player party average luck and enemy count
					local enemyAvgSpeed; local plrAvgSpeed;
					local enemySpdSum = 0; local plrSpdSum = 0;
					local enemiesAlive = 0; local plrsAlive = 0;
					for i,v in pairs(EncounterServer.PlayerParty.TeamMembers) do
						-- only look at the ones alive
						local currAgi = v.CURRSPD;
						local currLuck = v.LUC;
						if v.CURRHP > 0 then
							plrsAlive = plrsAlive + 1;
							plrSpdSum = math.floor(plrSpdSum + currAgi + (currLuck / 7));
						end
					end
					for i,v in pairs(EncounterServer.EnemyParty.TeamMembers) do
						-- only look at the ones alive
						local currAgi = v.CURRSPD;
						if v.CURRHP > 0 then
							enemiesAlive = enemiesAlive + 1;
							enemySpdSum = enemySpdSum + currAgi;
						end
					end
					enemySpdSum = enemySpdSum * (1 + (enemiesAlive/8));
					plrAvgSpeed = plrSpdSum / plrsAlive;
					enemyAvgSpeed = enemySpdSum / enemiesAlive;
					plrAvgSpeed = plrAvgSpeed + Random.new():NextNumber(plrAvgSpeed/-5, plrAvgSpeed/5);
					enemyAvgSpeed = enemyAvgSpeed + math.ceil(Random.new():NextNumber(enemyAvgSpeed/-5, enemyAvgSpeed/5));
					print(initiator.DISPLAYNAME, "party spd:", plrAvgSpeed,"| Enemy party spd:", enemyAvgSpeed);
					if plrAvgSpeed > enemyAvgSpeed then
						-- flee success
						return true;	
					end
					-- flee failure
					return false;
				end
				if fleeSuccess() == true then
					battleOver = true;
					if fleeSuccessIndx == -1 then
						fleeSuccessIndx = getIndexFromPartyMember(initiator);
					end
				end
				remoteEventsFolder.BattleSystem.SendFleeResult:FireAllClients(battleOver, fleeSuccessIndx);
			end
			-- before creating damage array, check to see if any targets are dead after checking if the action is a revival skill
			-- check whether the target party is player or enemy party
			if string.find(targetType, "PARTY") then
				targetPartyArr = EncounterServer.PlayerParty.TeamMembers;
			elseif string.find(targetType, "ENEMY") then
				targetPartyArr = EncounterServer.EnemyParty.TeamMembers;
			elseif string.find(targetType, "SELF") or string.find(targetType, "NONE") then
				if initiatorIsPlayerPartyMember then
					targetPartyArr = EncounterServer.PlayerParty.TeamMembers;
				elseif initiatorIsPlayerPartyMember == false then
					targetPartyArr = EncounterServer.EnemyParty.TeamMembers;
				end
			end
			local function atLeast1Alive(arr, start, en, reverseBool)
				--warn(arr); warn(start); warn(en) warn(reverseBool)
				if arr[start] == nil or arr[en] == nil then return -1; end
				local increment = 1;
				if reverseBool then 
					increment = -1;
				end
				for n = start, en, increment do
					local cE = arr[n];
					if cE.CURRHP ~= 0 then
						return n;
					end
				end
				return -1;
			end
			-- if there is only 1 target, check if target is dead. If they are dead, change the party member to the closest alive party member of their same team.
			if #targetClassObjects == 1 and string.find(targetType, "SINGLE") and isRevivalSkill == false then
				local replacementMember;
				if targetClassObjects[1].CURRHP == 0 then
					local tIndx = getIndexFromPartyMember(targetClassObjects[1]);
					local leftSearch = atLeast1Alive(targetPartyArr, tIndx - 1, 1, true);
					local rightSearch = atLeast1Alive(targetPartyArr, tIndx + 1, #targetPartyArr, false);
					--warn(util:TableSlice(targetPartyArr, tIndx + 1, #targetPartyArr, 1))
					if leftSearch and leftSearch ~= -1 then
						warn("attack redirected to index "..leftSearch);
						replacementMember = targetPartyArr[leftSearch];
						b.TARGETS = {replacementMember};
					elseif rightSearch and rightSearch ~= -1 then
						warn("attack redirected to index "..rightSearch);
						replacementMember = targetPartyArr[rightSearch];
						b.TARGETS = {replacementMember};
					end
					-- there must be at least one other one alive, or else the battle would end.
				end
			end

			if not isRevivalSkill then -- get rid of targets that are dead if it is not revival skill
				local ptr = 1;
				while ptr <= #targetClassObjects do
					if targetClassObjects[ptr].CURRHP <= 0 then
						table.remove(targetClassObjects, ptr);
						ptr -= 1;
					end
					ptr += 1;
				end
			end

			-- update targetClassObjects
			targetClassObjects = b.TARGETS;

			local function createDamageArr(initiatorPartyMember, action, isHeal)
				local waitDelay = action.DamageWaitDelay;
				local resultArr = {}; -- resultArr is actual hit targets resulting damage arr.
				local adjustedVolume = 1;
				if waitDelay == 0 and #targetClassObjects > 1 then
					--look at number of targets and decrease volume accordingly to avoid earrape from amplified sounds
					adjustedVolume = 1 / ((#targetClassObjects * .3) + 1) ;
				end
				--TS:Message("=============================================");
				for i,v in pairs(targetClassObjects) do	
					local isCrit;
					if battleOver then -- don't return yet. fill in resultArr2 with targets not yet processed with "ABORTED" before returning
						local currIndex = i;
						for m = currIndex, #targetClassObjects do
							table.insert(resultsArr2, "ABORTED");
						end
						return resultArr; 
					end
					--check if the target is dead and if the action ignores dead if it does ignore dead and target is dead, skip it.
					local ignoreDead = not isRevivalSkill;
					if v.CURRHP == 0 and ignoreDead == true then -- this is for attacking and healing moves
						--skip it, but make sure to add it to resultsArr2
						--print("in here1. Ignored target:", v.DISPLAYNAME);
						table.insert(resultsArr2, "IGNORE");	
					elseif v.CURRHP == 0 and (string.find(action.TargetType, "SPLASH") or string.find(action.TargetType, "ALL")) and action.IsSupportSpell == false then
						--skip it, but make sure to add it to resultsArr2
						--print("in here2. Ignored target:",v.DISPLAYNAME);
						table.insert(resultsArr2, "IGNORE");
					else
						--print("in here3. Continuing with:", v.DISPLAYNAME, "first conditional not met:", v.CURRHP, ignoreDead);
						local allTargetMembersArr;
						if initiatorPartyMember:is(EnemyPartyMember) then
							if string.find(action.TargetType, "SELF") or string.find(action.TargetType, "ENEMY") then
								allTargetMembersArr = EncounterServer.EnemyParty.TeamMembers;
							else
								allTargetMembersArr = EncounterServer.PlayerParty.TeamMembers;
							end
						elseif initiatorPartyMember:is(PlayerPartyMember) then
							if string.find(action.TargetType, "SELF") or string.find(action.TargetType, "PARTY") then
								allTargetMembersArr = EncounterServer.PlayerParty.TeamMembers;
							else
								allTargetMembersArr = EncounterServer.EnemyParty.TeamMembers;
							end
						end
						--print(allTargetMembersArr)
						local currTargetIndexInPartyMembersArr = util:IndexOf(allTargetMembersArr, v);
						if currTargetIndexInPartyMembersArr == -1 then error("DISPLAYNAME IN THAT PARTY NOT FOUND!"); end
						--TS:Message(initiatorPartyMember.DISPLAYNAME.." attacking "..v.DISPLAYNAME.." :index "..currTargetIndexInPartyMembersArr);
						local initiatorBaseCritRate = initiatorPartyMember.CURRCRITRATE;
						local currentTargetMember = v;
						currentTargetMember.EVADEDATTACK = false;
						local damageMultiplier = action.DamageMultiplier;
						--warn(damageMultiplier);
						local critRateModifier = action.CritRateModifier;
						local isElemental;
						local targetEvasion = currentTargetMember.CURREVA;
						local actionAccuracy = action.Accuracy;
						local wasAlive = true;
						if currentTargetMember.CURRHP == 0 then
							wasAlive = false;
						end
						action.IsCrit = false;
						isCrit = false;
						--make sure to check the guardianindex. if guardianindex isn't self index, then change currentTargetMember into getplrobj(guardianindex) which returns guardian plrobj.
						if isHeal == false and action.IsSupportSpell == false then--so that healing won't be blocked as well
							if v:is(PlayerPartyMember) and v.GUARDIANINDEXINPARTY and v.GUARDIANINDEXINPARTY ~= currTargetIndexInPartyMembersArr then
								local playerPartyMembersArr = EncounterServer.PlayerParty.TeamMembers;
								if playerPartyMembersArr[v.GUARDIANINDEXINPARTY].CURRHP > 0 then
									currentTargetMember = playerPartyMembersArr[v.GUARDIANINDEXINPARTY];
									--warn(currentTargetMember.DISPLAYNAME.." takes damage in place of "..v.DISPLAYNAME.."!");--v and currentTargetMember are now different!	
								else--guardian is dead
								end
							else
								--is either defending self or not player
							end	
						end
						--evasion check first
						if isHeal == false and action.IsSupportSpell == false then

							--make sure that if done to own party, cannot miss
							local targetPartyMemberType = action.PlayerOrEnemyParty;
							if Random.new():NextInteger(0, 100) < targetEvasion then -- if dodges
								currentTargetMember.EVADEDATTACK = true;
								table.insert(resultsArr2, "EVADED"); -- indicates attack was evaded
								--remoteEventsFolder.BattleSystem.PlayAppropriateHitSFX:FireAllClients(action, isCrit, false, currentTargetMember.EVADEDATTACK, 0, adjustedVolume);	
								--determine if current target is player or enemy
								local targetIsPlayer;	
								if currentTargetMember:is(PlayerPartyMember) then
									targetIsPlayer = true;
									-- remoteEventsFolder.BattleSystem.ApplyDamageIndicationOfPlayerFrame:FireAllClients(util:IndexOf(EncounterServer.PlayerParty.TeamMembers, currentTargetMember), nil, false, false, "HP");--also pass battle id?. This is damage indication when attack misses
								elseif currentTargetMember:is(EnemyPartyMember) then
									targetIsPlayer = false;
									-- remoteEventsFolder.BattleSystem.ApplyDamageIndicationOfEnemyModel:FireAllClients(util:IndexOf(EncounterServer.EnemyParty.TeamMembers, currentTargetMember), nil, false, false);--also pass battle id?. This is damage indication when attack misses	
								else
									error("TARGET IS NOT PLAYER NOR ENEMY!");
								end	
								--play evasion animation/sound?	
							else -- failed to dodge. now see if attack is successfully executed?
								if Random.new():NextInteger(0, 100) < actionAccuracy then--if it executes successfully
									-- handle crit rate
									--warn("initiatorBaseCritRate is "..tostring(initiatorBaseCritRate)..", critRateModifier is "..tostring(critRateModifier));
									local totalCritRate = initiatorBaseCritRate + critRateModifier;
									totalCritRate = math.clamp(totalCritRate, 0, 100);
									if Random.new():NextInteger(0, 100) < totalCritRate then
										action.IsCrit = true;
										isCrit = true;
									end 
									-- handle imbued elements
									if action.ImbuedElement == "PYRO" or action.ImbuedElement == "CRYO" or action.ImbuedElement == "ELECTRO" then
										isElemental = true;
									else
										if action.ImbuedElement == "WEAPON" then
											if initiator['WEAPON'] then
												action.ImbuedElement = initiator['WEAPON']['IMBUEDELEMENT'];
												if action.ImbuedElement ~= "NONE" then isElemental = true; else isElemental = false; end;
											else
												action.ImbuedElement = "NONE";
												isElemental = false;
											end
										end	
									end
									currentTargetMember.EVADEDATTACK = false;
									-- handle damage types
									local damageType = action.DamageType;
									if damageType == "WEAPON" then
										if initiator['WEAPON'] then
											damageType = initiator['WEAPON']['DAMAGETYPE'];
										else
											damageType = "NONE";
										end
									end

									local damageInstance = EncounterServer:CalculateDamage(initiatorPartyMember, currentTargetMember, action.IsCrit, isElemental, damageMultiplier, action.ImbuedElement, damageType, initiatorPartyMember.CURRCRITDAMAGE);
									LoseStat(currentTargetMember, "HP", damageInstance, isCrit, isHeal, action);
									local statusBefore = currentTargetMember.STATUSEFFECT;
									local statusToInflict = InflictStatus(currentTargetMember, action); -- changes the server player status data and shows client what status to inflict
									if statusToInflict ~= "NONE" and currentTargetMember.CURRHP > 0 then
										table.insert(currActionStatusInflictions, currentTargetMember.DISPLAYNAME.."#"..statusToInflict.."#"..statusBefore);
									end
									damageInstance = tostring(damageInstance).."*"..statusToInflict; -- * will be used as separator for status effects

									table.insert(resultArr, damageInstance);
									table.insert(resultsArr2, damageInstance)

									table.insert(currActionActualHitEnemies, currentTargetMember);
									if isCrit then table.insert(currActionCritHitEnemies, getIndexFromPartyMember(currentTargetMember)..util:StringifyBool(determineIfEnemyOrPlayerPartyMember(currentTargetMember))); end
									if wasAlive == true and currentTargetMember.CURRHP == 0 then--this was the killing blow
										table.insert(currActionDefeatedTargets, currentTargetMember);
									end
									--remoteEventsFolder.BattleSystem.PlayAppropriateHitSFX:FireAllClients(action, isCrit, false, currentTargetMember.EVADEDATTACK, damageInstance, adjustedVolume);	
									--warn(currentTargetMember:is(EnemyPartyMember));
									if currentTargetMember.CURRHP == 0 then--the target died from the blow
										cleanseBuffs(currentTargetMember);
										if wasAlive == true and currentTargetMember:is(EnemyPartyMember) then--this blow killed the enemy
											--enemy death
											-- remoteEventsFolder.BattleSystem.AshifyEnemyModel:FireAllClients(currTargetIndexInPartyMembersArr);
										elseif wasAlive == true and currentTargetMember:is(PlayerPartyMember) then--this blow killed the player
											currentTargetMember.STATUSEFFECTTIMER = 0;
											--player death
											--warn("IN HERERERERRE!!");
										else
											--this is for when the target was already dead before
										end
										--check for victory or wipe after someone dies	
										checkBattleStatus();	
									end

								else -- target did not dodge but initiator missed the attack 
									currentTargetMember.EVADEDATTACK = true;
									table.insert(resultsArr2, "MISS"); -- indicates attack did not hit
									--table.insert(resultArr, -1337666);
									--remoteEventsFolder.BattleSystem.PlayAppropriateHitSFX:FireAllClients(action, isCrit, false, currentTargetMember.EVADEDATTACK, 0, adjustedVolume);	
									--play evasion animation/sound?	
									--determine if current target is player or enemy
									local targetIsPlayer;
									if currentTargetMember:is(PlayerPartyMember) then
										targetIsPlayer = true;
										--remoteEventsFolder.BattleSystem.ApplyDamageIndicationOfPlayerFrame:FireAllClients(util:IndexOf(EncounterServer.PlayerParty.TeamMembers, currentTargetMember), nil, false, false, "HP");--also pass battle id?. This is damage indication when attack misses	
									elseif currentTargetMember:is(EnemyPartyMember) then
										targetIsPlayer = false;
										--remoteEventsFolder.BattleSystem.ApplyDamageIndicationOfEnemyModel:FireAllClients(util:IndexOf(EncounterServer.EnemyParty.TeamMembers, currentTargetMember), nil, false, false);--also pass battle id?. This is damage indication when attack misses	
									else
										error("TARGET IS NOT PLAYER NOR ENEMY!");
									end
								end
							end	
						elseif action.IsSupportSpell == true and action.Name ~= "Defend" and isHealing == false then
							-- do buff effect check
							local function applyBuff(victimObj, isDebuff)
								
								local buffCode = action.Buffs;
								if isDebuff then buffCode = action.Debuffs; end
								local newBuff = Buff(action.Name, isDebuff, action.BuffsDuration, buffCode);
								-- before inserting, change the curr stat of the player according to the buff
								-- now insert into victim's buff table
								-- but first search if this buff already exists in the table
								local function buffAlreadyExists()
									if isDebuff then
										for i,v in pairs(victimObj.DEBUFFS) do
											if v.NAME == action.Name then
												v.DURATION = action.DebuffsDuration; -- refresh duration
												return true;
											end
										end
										return false;
									else
										for i,v in pairs(victimObj.BUFFS) do
											if v.NAME == action.Name then
												v.DURATION = action.BuffsDuration; -- refresh duration
												return true;
											end
										end
										return false;
									end
								end

								if not isDebuff then
									if buffAlreadyExists() then
										--print("inhere3",buffCode);
									elseif #victimObj.BUFFS == 4 then -- get rid of the oldest buff and add the new one
										local removedBuff = table.remove(victimObj.BUFFS, 1); 
										processBuffCode(victimObj, removedBuff.EFFECTSTR, true, true); -- remove buff
										table.insert(victimObj.BUFFS, newBuff);
										--print("inhere2",action.Name, "with duration", newBuff.DURATION);
										processBuffCode(victimObj, buffCode, false, true); -- add buff
									elseif #victimObj.BUFFS < 4 then
										table.insert(victimObj.BUFFS, newBuff);
										--print("inhere22",action.Name, newBuff.DURATION);
										processBuffCode(victimObj, buffCode, false, true); -- add buff
									else
										error("unknown error with buff insertion!");
									end
								else
									if buffAlreadyExists() then
										--print("inhere3",buffCode);
									elseif #victimObj.DEBUFFS == 4 then -- get rid of the oldest debuff and add the new one
										local removedBuff = table.remove(victimObj.DEBUFFS, 1); 
										processBuffCode(victimObj, removedBuff.EFFECTSTR, true, true); -- remove debuff
										table.insert(victimObj.DEBUFFS, newBuff);
										processBuffCode(victimObj, buffCode, false, true); -- add debuff
									elseif #victimObj.DEBUFFS < 4 then
										table.insert(victimObj.DEBUFFS, newBuff);
										processBuffCode(victimObj, buffCode, false, true); -- add debuff
									else
										error("unknown error with debuff insertion!");
									end
								end
							end
							if v.CURRHP > 0 and action.Buffs ~= "NONE" then
								applyBuff(v, false);
							elseif v.CURRHP > 0 and action.Debuffs ~= "NONE" then
								applyBuff(v, true)
							end
							-- is purify?
							if action.RemoveStatusEffect then
								local healInstance = -420420420;
								LoseStat(currentTargetMember, "HP", -420420420, false, false, action);
								local statusToInflict = "NONE"; -- changes the server player status data and shows client what status to inflict
								healInstance = tostring(healInstance).."*"..statusToInflict; -- * will be used as separator for status effects
								table.insert(resultArr, healInstance);	
								table.insert(resultsArr2, healInstance); -- indicates attack did not hit
								table.insert(currActionActualHitEnemies, currentTargetMember);
							else
								-- obligatory shit. We wil use specific number to indicate buff (-6667331)
								local healInstance = -6667331;
								if action.Debuffs ~= "NONE" then healInstance = -4207331; end
								LoseStat(currentTargetMember, "HP", healInstance, false, false, action);
								local statusToInflict = "NONE"; -- changes the server player status data and shows client what status to inflict
								healInstance = tostring(healInstance).."*"..statusToInflict; -- * will be used as separator for status effects
								table.insert(resultArr, healInstance);	
								table.insert(resultsArr2, healInstance); -- indicates attack did not hit
								table.insert(currActionActualHitEnemies, currentTargetMember);
								--remoteEventsFolder.BattleSystem.PlayAppropriateHitSFX:FireAllClients(action, isCrit, true, currentTargetMember.EVADEDATTACK, 0, adjustedVolume);		
							end





						else --isHeal is true?
							local healInstance = EncounterServer:CalculateHeal(initiatorPartyMember, currentTargetMember, damageMultiplier);
							LoseStat(currentTargetMember, "HP", healInstance * -1, false, isHeal, action);
							local statusToInflict = "NONE"; -- changes the server player status data and shows client what status to inflict
							healInstance = tostring(healInstance).."*"..statusToInflict; -- * will be used as separator for status effects
							table.insert(resultArr, healInstance);	
							table.insert(resultsArr2, healInstance); -- indicates attack did not hit

							table.insert(currActionActualHitEnemies, currentTargetMember);
							--remoteEventsFolder.BattleSystem.PlayAppropriateHitSFX:FireAllClients(action, isCrit, true, currentTargetMember.EVADEDATTACK, 0, adjustedVolume);	
						end 
					end
				end
				return resultArr;
			end--end of createdmgArrfunc
			--check if the initiator is still able to act. if not, skip it!
			if cannotAct(initiator) then
				--do nothing
			else
				--action is the action dictionary
				if action.DamageMultiplier < 0 then isHealing = true; end
				--warn(convertArrayToCommas(targetClassObjects, noExtraLineNeeded));
				local msgString = "boop";
				--print(initiator);
				msgString = tostring(initiator.DISPLAYNAME.." "..logFlavor..convertArrayToCommasConsiderMentionTarget(targetClassObjects, mentionTarget, initiator));--displays who is attacking
				--remoteEventsFolder.BattleSystem.UpdateBattleLogText:FireAllClients(msgString);
				TS:Message(msgString);
				local vol = 0;
				local timePos = 0;
				local function formatTargetsArrIntoStr()
					local result = "";
					for i,v in pairs(targetClassObjects) do
						local index = getIndexFromPartyMember(v);
						local isPlayerParty = determineIfEnemyOrPlayerPartyMember(v);
						result = result..index.."#"..util:StringifyBool(isPlayerParty);
						if i ~= #targetClassObjects then result = result..","; end
					end
					return result;
				end
				local currInterpretation;
				if action.MPCost ~= nil and action.MPCost > 0 then
					currInterpretation = "~ACOST<"..action.MPCost.."MP>~SFXFROMACTION<"..action.Name..",".."0"..">~POINTTARGETS<"..formatTargetsArrIntoStr()..">~LTXT<"..msgString..">~DUR<1>~IID<"..getIndexFromPartyMember(initiator)..","..util:StringifyBool(determineIfEnemyOrPlayerPartyMember(initiator))..">"; -- since damage is not calculated yet, no need to put in damage info
				else
					currInterpretation = "~SFXFROMACTION<"..action.Name..",".."0"..">~POINTTARGETS<"..formatTargetsArrIntoStr()..">~LTXT<"..msgString..">~DUR<.6>~IID<"..getIndexFromPartyMember(initiator)..","..util:StringifyBool(determineIfEnemyOrPlayerPartyMember(initiator))..">"; -- since damage is not calculated yet, no need to put in damage info
				end
				table.insert(clientInterpretation, currInterpretation);
				--remoteEventsFolder.BattleSystem.PlayAppropriateInitiateAttackSFX:FireAllClients(action); -- do this client side
				--show billboard sword pointers if target is enemy and gui pointers if target is player
				for i,v in pairs(targetClassObjects) do
					local currTarget = v;
					local isPlayer;
					local indexInPartyArr;
					local attackerIsPlayer;
					if initiator:is(EnemyPartyMember) then
						attackerIsPlayer = false;
					elseif initiator:is(PlayerPartyMember) then
						attackerIsPlayer = true;
					else
						error("ATTACK IS NEITHER ENEMY OR PLAYER!");
					end
					if currTarget:is(EnemyPartyMember) then
						--find enemy index from class object
						isPlayer = false;
						indexInPartyArr =  util:IndexOf(EncounterServer.EnemyParty.TeamMembers, currTarget);
					elseif currTarget:is(PlayerPartyMember) then
						isPlayer = true;
						indexInPartyArr = util:IndexOf(EncounterServer.PlayerParty.TeamMembers, currTarget);
					else
						error("CURRTARGET IS UNKNOWN!");
					end
					if (currTarget.CURRHP == 0 and (action.IsRevivalSkill == true or action.IsSupportSpell == true)) or currTarget.CURRHP > 0 then
						--remoteEventsFolder.BattleSystem.AdjustVisibilityOfTargetPointerDuringBattle:FireAllClients(isPlayer, indexInPartyArr, attackerIsPlayer)--also pass battle id if multiplayer. true third param means that the visibility is set to true. do this client side!
					end	
				end
				--consume mp if spell consumes mp
				local mpCost = action.MPCost;
				if mpCost and mpCost > 0 then
					LoseStat(initiator, "MP", mpCost, false, false, action); -- indicator effect will be on client side
				end
				--yieldForClient(.15);
				--play animation if initiator is enemy and enemy model has that action animation inside its animation folder. do this client side!
				if initiator:is(EnemyPartyMember) then
					local enemyIndex = util:IndexOf(EncounterServer.EnemyParty.TeamMembers, initiator);
					--remoteEventsFolder.BattleSystem.PlayEnemyActionAnim:FireAllClients(enemyIndex, action)--also pass battle id? do this client side!
				end
				local damageArr; --damage targets
				damageArr = createDamageArr(initiator, action, isHealing);
				--warn(currActionCritHitEnemies);
				if noExtraLineNeeded == false then
					local function hitOrMiss(currActionActualHitEnemies, noExtraLineNeeded)
						local function miss()
							local punctuations = {".", "!", "..."};
							local missPhrases = {"But the attack missed", "But it was an epic fail", "But the hit failed to land", "But the attack failed to connect", "Miss! No damage was dealt"};
							return util:Choice(missPhrases)..util:Choice(punctuations);
						end
						if #currActionActualHitEnemies > 0 then
							local isRevive = action.IsRevivalSkill;
							return convertArrayToCommas(currActionActualHitEnemies, noExtraLineNeeded)..considerAndAdjustHPChangeTextIfAOE(currActionActualHitEnemies, damageArr, noExtraLineNeeded, isHealing, isRevive, action.IsSupportSpell, action.SupportSpellFlavor);
						end
						return miss();
					end
					msgString = msgString.."\n"..critMissOrNoDamage(action, damageArr, noExtraLineNeeded, isHealing)..hitOrMiss(currActionActualHitEnemies, noExtraLineNeeded);	
					print(msgString);
					--remoteEventsFolder.BattleSystem.UpdateBattleLogText:FireAllClients(msgString);
					TS:Message(msgString);
					local waitTime = 1.5;
					if #currActionDefeatedTargets > 0 then waitTime = 2; end
					--warn(damageArr); -- damageArr is an array! It does not preserve order!
					--warn(currActionActualHitEnemies); -- just hope that damageArr and currActionActualHitEnemies are aligned
					local function formatDmgArrIntoStr()
						local result = "";
						for i,v in pairs(currActionActualHitEnemies) do
							local indexInRelativeParty = getIndexFromPartyMember(v);
							local isPlrParty = determineIfEnemyOrPlayerPartyMember(v);
							local statusSeparatorIndx = string.find(damageArr[i], "*");
							local dmgAmnt; local statusEffect;
							if statusSeparatorIndx == nil then
								dmgAmnt = tonumber(damageArr[i]);
								statusEffect = "NONE";
							else
								dmgAmnt = tonumber(string.sub(damageArr[i], 1, statusSeparatorIndx - 1)); -- get the damage portion and the status effect portion
								statusEffect = string.sub(damageArr[i], statusSeparatorIndx + 1); -- the statuseffect also has the chance part	
							end



							if #currActionActualHitEnemies ~= #damageArr then error("currActionActualHitEnemies and damageArr are not the same length!"); end
							local isCrit = false;
							if util:IndexOf(currActionCritHitEnemies, indexInRelativeParty..util:StringifyBool(isPlrParty)) ~= -1 then -- potential crit bug
								isCrit = true;
							end
							result = result..indexInRelativeParty.."#"..util:StringifyBool(isPlrParty).."#"..tostring(dmgAmnt).."#"..util:StringifyBool(isCrit).."#"..statusEffect;
							if i ~= #currActionActualHitEnemies then result = result..","; end
						end
						return result;
					end
					local function formatDmgArrIntoStr2() -- this is for all damage elements including the ones with "MISS" and "IGNORED" and "EVADED" (this is intended targets)
						local result = "";
						for i,v in pairs(targetClassObjects) do
							local indexInRelativeParty = getIndexFromPartyMember(v);
							local isPlrParty = determineIfEnemyOrPlayerPartyMember(v);
							local dmgAmnt = resultsArr2[i]; -- hope this works! 
							-- if dmgAmnt has an asterisk, break it down further.
							local statusSeparatorIndx = string.find(resultsArr2[i], "*");
							local statusEffect = "NONE"; -- the statuseffect also has the chance part
							if statusSeparatorIndx ~= nil then
								dmgAmnt = tonumber(string.sub(resultsArr2[i], 1, statusSeparatorIndx - 1)); -- get the damage portion and the status effect portion
								statusEffect = string.sub(resultsArr2[i], statusSeparatorIndx + 1);
							end

							--warn(targetClassObjects);
							--warn(resultsArr2);
							if #targetClassObjects ~= #resultsArr2 then error("targetClassObjects and resultsArr2 are not the same length! Length of targetClassObjects: "..tostring(#targetClassObjects).." | length of resultsArr2: "..tostring(#resultsArr2)); end
							local isCrit = false;
							if util:IndexOf(currActionCritHitEnemies, indexInRelativeParty..util:StringifyBool(isPlrParty)) ~= -1 then -- potential crit bug
								isCrit = true;
							end
							local function considerGuardian(victimObj)
								local function guardianIsDead(indx)
									local guardianObj = EncounterServer.PlayerParty.TeamMembers[indx];
									if guardianObj and guardianObj.CURRHP <= 0 then
										return true;
									end
									return false;
								end
								local guardianIndexInParty = victimObj.GUARDIANINDEXINPARTY;
								if guardianIndexInParty == nil then return ""; end -- or guardianIsDead(guardianIndexInParty)
								return "&"..guardianIndexInParty;
							end
							result = result..indexInRelativeParty..considerGuardian(v).."#"..util:StringifyBool(isPlrParty).."#"..tostring(dmgAmnt).."#"..util:StringifyBool(isCrit).."#"..statusEffect;
							if i ~= #targetClassObjects then result = result..","; end
						end
						return result;
					end

					currInterpretation = "~LTXT<"..msgString..">~DUR<"..waitTime..">~ICMD<"..action.Name..",("..formatDmgArrIntoStr().."),("..formatDmgArrIntoStr2().."),"..util:StringifyBool(isHealing)..","..action.ImbuedElement..">~IID<"..getIndexFromPartyMember(initiator)..","..util:StringifyBool(determineIfEnemyOrPlayerPartyMember(initiator))..">~ENDEATH<"..formatDefeatedEnemyTargetsArrIntoString(currActionDefeatedTargets)..">"; -- put in damage info here
					table.insert(clientInterpretation, currInterpretation);



					-- do status effect check
					if #currActionStatusInflictions > 0 then
						print(currActionStatusInflictions);
						for aye,vee in pairs(currActionStatusInflictions) do
							local hashIndx = string.find(vee, "#");
							local hashIndx2 = string.find(string.sub(vee, hashIndx + 1), "#") + hashIndx;
							local dspName = string.sub(vee, 1, hashIndx - 1);
							local statEffect = string.sub(vee, hashIndx + 1, hashIndx2 - 1);
							local beforeStatEffect = string.sub(vee, hashIndx2 + 1);
							if beforeStatEffect == statEffect then
								msgString = dspName.." "..StatusEffectIcons[statEffect..'LOGFLAVOR2'];
							else
								msgString = dspName.." "..StatusEffectIcons[statEffect..'LOGFLAVOR'];	
							end
							TS:Message(msgString);
							currInterpretation = "~LTXT<"..msgString..">~DUR<".."1"..">";
							table.insert(clientInterpretation, currInterpretation);
						end
					end

					--do aftermatch check
					--deduct hp if action costed hp
					local hpCost = action.HPCost;
					if hpCost and hpCost > 0 then
						aftermathDamageTaken = true;
						LoseStat(initiator, "HP", hpCost, false, false, action);
						--remoteEventsFolder.BattleSystem.PlayAppropriateHitSFX:FireAllClients(nil, false, true, false, hpCost, 1);
						if initiator:is(EnemyPartyMember) and initiator.CURRHP == 0 then
							--enemy death
							-- remoteEventsFolder.BattleSystem.AshifyEnemyModel:FireAllClients(getIndexFromPartyMember(initiator));
							table.insert(currActionDefeatedTargets, initiator);
							checkBattleStatus();
						end
					end					
					if aftermathDamageTaken then
						local aftermathMsg = initiator.DISPLAYNAME.." takes aftermath damage!"
						currInterpretation = "~LTXT<"..aftermathMsg..">~DUR<".."1.5"..">~AFMTH<"..getIndexFromPartyMember(initiator).."#"..util:StringifyBool(determineIfEnemyOrPlayerPartyMember(initiator)).."#"..Random.new():NextInteger(hpCost - math.floor(hpCost / 5), hpCost + math.floor(hpCost / 5))..">~ENDEATH<"..formatDefeatedEnemyTargetsArrIntoString(currActionDefeatedTargets)..">"; -- put in aftermath damage info here
						table.insert(clientInterpretation, currInterpretation);
					end
					if #currActionDefeatedTargets > 0 then
						msgString = convertArrayToCommas(currActionDefeatedTargets, false).." "..isOrAreDefeated(currActionDefeatedTargets);
						TS:Message(msgString);
						currInterpretation = "~DUR<".."1.5"..">~LTXT<"..msgString..">"; -- just saying who died
						table.insert(clientInterpretation, currInterpretation);
					end
					if battleOver then return; end
				end	
			end
			--onto next iteration!
			--TS:Message("Code took "..tick() - startTime.." seconds to run");
		end --end of doing real shit.

		-- deal DOT damage from status effects
		-- string looks like this: ~DOT<1#true#13#POISONED,2#true#11#BLEEDING,3#true#31#BURNED>
		local function getDOTArr()
			local currInterpret = "~DOT<"
			for i,v in pairs(EncounterServer.PlayerParty.TeamMembers) do
				local dotDmg = 0;				
				if v.STATUSEFFECT == "POISONED" or v.STATUSEFFECT == "BURNED" or v.STATUSEFFECT == "BLEEDING" or v.STATUSEFFECT == "PLAGUE" then
					-- get partyMember maxHP
					local maxHealth = v.HP;					
					if v.STATUSEFFECT == "POISONED" then
						dotDmg = math.ceil(maxHealth * .15); 
					elseif v.STATUSEFFECT == "BURNED" then
						dotDmg = math.ceil(maxHealth * .3);
					elseif v.STATUSEFFECT == "BLEEDING" then
						dotDmg = math.ceil(maxHealth * .12);
					elseif v.STATUSEFFECT == "PLAGUE" then
						dotDmg = math.ceil(maxHealth * .25);
					end
					currInterpret = currInterpret..tostring(i).."#true#"..tostring(dotDmg).."#".."NONE"..",";
				end
			end

			for i,v in pairs(EncounterServer.EnemyParty.TeamMembers) do
				local dotDmg = 0;
				if v.STATUSEFFECT == "POISONED" or v.STATUSEFFECT == "BURNED" or v.STATUSEFFECT == "BLEEDING" then
					-- get partyMember maxHP
					local maxHealth = v.HP;
					if v.STATUSEFFECT == "POISONED" then
						dotDmg = math.ceil(maxHealth * .05); 
					elseif v.STATUSEFFECT == "BURNED" then
						dotDmg = math.ceil(maxHealth * .1);
					elseif v.STATUSEFFECT == "BLEEDING" then
						dotDmg = math.ceil(maxHealth * .04);
					end
					currInterpret = currInterpret..tostring(i).."#false#"..tostring(dotDmg).."#".."NONE"..",";
				end
			end
			-- remove comma if there is one at the end
			if string.sub(currInterpret, #currInterpret, #currInterpret) == "," then
				currInterpret = string.sub(currInterpret, 1, #currInterpret - 1);
			end
			return currInterpret..">";	
		end

		-- get dot arr
		local dArr = getDOTArr();
		print(getDOTArr());
		-- get partymember names that have dots example: ~DOT<2#true#17#POISONED,3#true#9#POISONED> 
		local function getPartyMemberFromIndexAndBool(indx, bool)
			if bool then -- is player
				return EncounterServer.PlayerParty.TeamMembers[indx];			
			end
			return EncounterServer.EnemyParty.TeamMembers[indx];
		end
		local function processDOTString()
			local startIndx = string.find(dArr, "<") + 1;
			local endIndx = string.find(dArr, ">") - 1;
			local strToProcess = string.sub(dArr, startIndx, endIndx);
			local dotArr = util:ExtractCSV(strToProcess);
			local dotNamesArr = {};
			for f,g in pairs(dotArr) do
				local firstHashIndx = string.find(g, "#");
				local secondHashIndx = string.find(string.sub(g, firstHashIndx + 1), "#") + firstHashIndx;
				local currMemberIndx = tonumber(string.sub(g, 1, firstHashIndx - 1));
				local currBool = util:DestringifyBool(string.sub(g, firstHashIndx + 1, secondHashIndx - 1));					
				local currDisplayName = getPartyMemberFromIndexAndBool(currMemberIndx, currBool).DISPLAYNAME;
				table.insert(dotNamesArr, currDisplayName);
			end
			return dotNamesArr;
		end
		local dotArr = util:ExtractCSV(string.sub(dArr, string.find(dArr, "<") + 1, string.find(dArr, ">") - 1));
		local msgString = "";
		if #processDOTString() > 1 then
			msgString = util:ConvertArrToCSVStr(processDOTString()).." suffer from their status effect!";	
		elseif #processDOTString() == 1 then
			msgString = util:ConvertArrToCSVStr(processDOTString()).." suffers from their status effect!";
		end

		warn(dotArr);
		local dotCasualties = {}; -- an arr of string displaynames
		local enemyDotCasualties = {}; -- an arr of enemy partymembers who died from the dot
		for h,e in pairs(dotArr) do -- inflict DOT damage
			local firstHashIndx = string.find(e, "#");
			local secondHashIndx = string.find(string.sub(e, firstHashIndx + 1), "#") + firstHashIndx;
			local thirdHashIndx = string.find(string.sub(e, secondHashIndx + 1), "#") + secondHashIndx;
			local currMemberIndx = tonumber(string.sub(e, 1, firstHashIndx - 1));
			local currBool = util:DestringifyBool(string.sub(e, firstHashIndx + 1, secondHashIndx - 1));		
			local currDmg = tonumber(string.sub(e, secondHashIndx + 1, thirdHashIndx - 1));
			local currMember = getPartyMemberFromIndexAndBool(currMemberIndx, currBool);
			local wasAlive = true;
			if currMember.CURRHP <= 0 then wasAlive = false; end
			LoseStat(currMember, "HP", currDmg, false, false, nil) -- LoseStat(partyMember, HPorMP, amount, isCrit, isHeal, actionIfPresent)
			if wasAlive == true and currMember.CURRHP <= 0 then -- this dot was the killing blow
				table.insert(dotCasualties, currMember.DISPLAYNAME); 
				if currBool == false then
					table.insert(enemyDotCasualties, currMember);
				end
			end
		end
		if #processDOTString() > 0 then
			TS:Message(msgString);
			local currInterpretation = "~LTXT<"..msgString..">~DUR<".."1.5"..">"..dArr.."~ENDEATH<"..formatDefeatedEnemyTargetsArrIntoString(enemyDotCasualties)..">";
			table.insert(clientInterpretation, currInterpretation);	
		end		
		-- display casualties
		if #dotCasualties > 0 then
			msgString = util:ConvertArrToCSVStr(dotCasualties).." "..isOrAreDefeated(dotCasualties);
			TS:Message(msgString);
			local currInterpretation = "~DUR<".."1.5"..">~LTXT<"..msgString..">"; -- just saying who died
			table.insert(clientInterpretation, currInterpretation);
		end

		--make all party members have no guardian and set being defend to false
		for i,v in pairs(EncounterServer.PlayerParty.TeamMembers) do
			v.ISBEINGDEFENDED = false;
			v.GUARDIANINDEXINPARTY = nil;
			-- check for plague
			if v.STATUSEFFECT == "PLAGUE" then
				-- indx distance 1 then 50%, 2 then 25%, 3 then 16.7%
				local function calculatePlagueChance(indxDistance)
					return (50 / indxDistance) / 100;
				end
				-- spread plague to a random partymember excluding themselves and any other plagued partymembers if there are any partymembers who are alive
				for j,k in pairs(EncounterServer.PlayerParty.TeamMembers) do

					if k.CURRHP > 0 and j ~= i and k.STATUSEFFECT ~= "PLAGUE" and Random.new():NextNumber() < calculatePlagueChance(math.abs(i - j)) then
						InflictStatusNoAction(k, "PLAGUE", 2, 4);
						msgString = k.DISPLAYNAME.." "..StatusEffectIcons['PLAGUELOGFLAVOR'];
						TS:Message(msgString);
						local currInterpretation = "~DUR<".."1"..">~LTXT<"..msgString..">".."~UPDTPLRFRMSTATUS<"..j..",PLAGUE>";
						table.insert(clientInterpretation, currInterpretation);
					end
				end
			end
		end
		--do same thing for enemy party
		for i,v in pairs(EncounterServer.EnemyParty.TeamMembers) do
			v.ISBEINGDEFENDED = false;
			v.GUARDIANINDEXINPARTY = nil;
		end
	end
	simulateTurn();
	--now the client interpretation is stacked. Now let's send it to the client for interpretation!
	--warn(clientInterpretation);
	remoteEventsFolder.BattleSystem.BeginClientInterpretation:FireAllClients(EncounterServer, clientInterpretation); 


	finishInterpretationListener = remoteEventsFolder.BattleSystem.FinishClientInterpretation.OnServerEvent:Connect(function(player)
		-- reduce DOT and BUFF/DEBUFF timers at the beginning of each turn
		for i,v in pairs(EncounterServer.PlayerParty.TeamMembers) do
			if v.STATUSEFFECTTIMER > 0 and (v.STATUSEFFECT ~= "DEAD" or v.STATUSEFFECT ~= "NONE") then
				v.STATUSEFFECTTIMER = v.STATUSEFFECTTIMER - 1;
				print(v.DISPLAYNAME.."'s statuseffecttimer is now",v.STATUSEFFECTTIMER);
				if v.STATUSEFFECTTIMER == 0 and v.STATUSEFFECT ~= "DEAD" then -- cleanse status effect
					v.STATUSEFFECT = "NONE";
					remoteEventsFolder.BattleSystem.UpdateClientStatusEffect:FireAllClients(i, true, "NONE");
				end
			else
				v.STATUSEFFECTTIMER = 0;
			end	
			local j = 1;
			while j <= #v.BUFFS do
				v.BUFFS[j].DURATION -= 1;
				--print("inhere4",v.BUFFS[j].NAME," duration is now",v.BUFFS[j].DURATION);
				if v.BUFFS[j].DURATION == 0 or v.CURRHP == 0 then -- cleanse that buff
					cleanseBuff(v, v.BUFFS[j]);
					j -= 1;
				end
				j += 1;
			end
			local k = 1;
			while k <= #v.DEBUFFS do
				v.DEBUFFS[k].DURATION -= 1;
				if v.DEBUFFS[k].DURATION == 0 or v.CURRHP == 0 then -- cleanse that debuff
					cleanseBuff(v, v.DEBUFFS[k]);
					k -= 1;
				end
				k += 1;
			end
		end
		for i,v in pairs(EncounterServer.EnemyParty.TeamMembers) do
			if v.STATUSEFFECTTIMER > 0 and (v.STATUSEFFECT ~= "DEAD" or v.STATUSEFFECT ~= "NONE") then
				v.STATUSEFFECTTIMER = v.STATUSEFFECTTIMER - 1;
				print(v.DISPLAYNAME.."'s statuseffecttimer is now",v.STATUSEFFECTTIMER);
				if v.STATUSEFFECTTIMER == 0 and v.STATUSEFFECT ~= "DEAD" then -- cleanse status effect
					v.STATUSEFFECT = "NONE";
					remoteEventsFolder.BattleSystem.UpdateClientStatusEffect:FireAllClients(i, false, "NONE");
				end
			else
				v.STATUSEFFECTTIMER = 0;
			end	
		end
		--sync change to client
		--once turn finished, repeat process if battle is still ongoing
		--determine if victory or game over or neither
		EncounterServer.TurnNumber += 1;
		--print("inhere5 advanced turn number to",EncounterServer.TurnNumber);

		for i,v in pairs(EncounterServer.PlayerParty.TeamMembers) do
			for j,k in pairs(v.BUFFS) do
				warn(k);
			end
		end
		remoteEventsFolder.BattleSystem.InvokePartyInfoChangeToClient:FireAllClients(EncounterServer);
		updateBattleStatus();
		finishInterpretationListener:Disconnect();
	end)









end)

--have a onserverevent remote event that takes the commands array and sends it to BattleSceneServer
--remoteEventsFolder.BattleSystem.SendCommandToServer.OnServerEvent:Connect(function(player, playerCommandArr)
--	local enemyCommandArr = EncounterServer:GenerateEnemyCommandArr();
--	EncounterServer:AssembleQueue(playerCommandArr);
--end)