--BATTLESCENE ACTS AS THE BRIDGE THAT CONNECTS BATTLESCENESERVER AND BATTLESCENE CLIENT WITH INFORMATION BOTH SIDES NEED TO KNOW. 

--[[   Service dependencies   --]]
local RS = game:GetService("ReplicatedStorage");

--[[   Folder references   --]]
local TBCFolder = RS.TurnBasedCombat;
local moduleFolder = TBCFolder.Modules;
local classesFolder = TBCFolder.Classes;
local miscFolder = RS.Misc;

--[[   External dependencies   --]]
local StatusEffectIcons = require(classesFolder.PartyMember.Storage.StatusEffectIcons);

--[[   Class dependencies   --]]
local GameObject = require(miscFolder.GameObject);
local BattleScene = GameObject:extend();

--[[   Key variables   --]]

function BattleScene:new(PlayerParty, EnemyParty, MusicID, IsBossFight, EncounterMethod)
	self.PlayerParty = PlayerParty or nil;--this is not array but a playerparty class
	self.EnemyParty = EnemyParty or nil;--same for this
	self.MusicID = MusicID or nil;
	self.IsBossFight = IsBossFight or false;
	self.EncounterMethod = EncounterMethod or 0;-- -1 = blindsided, 0 = normal, 1 = preemptive
	self.TurnNumber = 1;
	--for i,v in pairs(PlayerParty.TeamMembers) do
	--	print(PlayerParty.TeamMembers[i]:ToString());--this only returns 
	--end
end

--[[   Accessor methods   --]]
function BattleScene:CombinePartyTurnOrdersAndSortFromFastestToSlowest(playerParty, enemyParty)--playerparty and enemyparty are arrays returned by Party:GetPartyTurnOrder()
	local combinedPartyTurnOrders = {};
	for i = 1, #playerParty, 1 do
		table.insert(combinedPartyTurnOrders, i, playerParty[i]);
	end
	for i = #playerParty + 1, #playerParty + #enemyParty, 1 do
		table.insert(combinedPartyTurnOrders, i, enemyParty[i - #playerParty]);
	end
	--turn orders are now combined Ex: {{P, TS}, {P, TS}, {P, TS}, {P, TS}, {E, TS}, {E, TS}, {E, TS}, {E, TS},}	
	--you want to sort the combinedPartyTurnOrders array. Lets use selection sort!
	for i = 1, #combinedPartyTurnOrders - 1, 1 do
		local maxIndex = i;
		for j = i + 1, #combinedPartyTurnOrders, 1 do 
			if combinedPartyTurnOrders[j][2] > combinedPartyTurnOrders[maxIndex][2] then
				maxIndex = j;
			end
		end	
		local temp = combinedPartyTurnOrders[maxIndex];
		combinedPartyTurnOrders[maxIndex] = combinedPartyTurnOrders[i];
		combinedPartyTurnOrders[i] = temp;
	end
	--combinedPartyTurnOrders is now sorted!
	return combinedPartyTurnOrders;--this should look like:  {{P, TS}, {P, TS}, {P, TS}, {P, TS}, {E, TS}, {E, TS}, {E, TS}, {E, TS},}
end

--[[   Mutator methods   --]]
function BattleScene:UpdateInfo(otherBattleSceneServerOrClient)
	self.PlayerParty = otherBattleSceneServerOrClient.PlayerParty;
	self.EnemyParty = otherBattleSceneServerOrClient.EnemyParty;
	self.MusicID = otherBattleSceneServerOrClient.MusicID;
	self.IsBossFight = otherBattleSceneServerOrClient.IsBossFight;
	self.EncounterMethod = otherBattleSceneServerOrClient.EncounterMethod;
	self.TurnNumber = otherBattleSceneServerOrClient.TurnNumber;
end


return BattleScene;