local RS = game:GetService("ReplicatedStorage");
local CollectionService = game:GetService("CollectionService");

local uiStorage = RS.TurnBasedCombat.UIStorage;
local moduleFolder = RS.TurnBasedCombat.Modules;
local bindableEventsFolder = RS.TurnBasedCombat.BindableEvents;

local util = require(RS.Misc.Util);


local currEnemyTeamData = {};
local mainFrame = script.Parent.Frame;
local descFrame = mainFrame.DescFrame;
local effectsFrame = mainFrame.EffectsFrame;
local nxtButton = descFrame.Container.Nxt;
local prevButton = descFrame.Container.Prev;

local inspectingIndx = 1;

function getFirstAlivePartyMemberIndx()
	for i,v in pairs(currEnemyTeamData) do
		if v.CURRHP > 0 then return i; end
	end
	return -1;
end

bindableEventsFolder.UpdateEnemyInspect.Event:Connect(function(enemyTeamMembers)
	currEnemyTeamData = enemyTeamMembers;
	inspectingIndx = getFirstAlivePartyMemberIndx();
end)


function getAlivePartyMembers()
	local result = {};
	for i,v in pairs(currEnemyTeamData) do
		if v.CURRHP > 0 then
			table.insert(result, v);
		end
	end
	return result;
end

function findIndxInAlivePartyMembers(actualCurrIndx, alivePartyMembersArr)
	return util:IndexOf(alivePartyMembersArr, currEnemyTeamData[actualCurrIndx]);
end

function getNextPartyMemberIndx(currIndx, reverse)
	-- first get all alive party members
	local arr = getAlivePartyMembers();
	if #arr == 1 then return nil; end
	local indexInAlive = findIndxInAlivePartyMembers(currIndx, arr);
	if not reverse then
		if indexInAlive == #arr then return util:IndexOf(currEnemyTeamData, arr[1]); end
		return util:IndexOf(currEnemyTeamData, arr[indexInAlive + 1]);
	end
	if indexInAlive == 1 then return util:IndexOf(currEnemyTeamData, arr[#arr]); end
	return util:IndexOf(currEnemyTeamData, arr[indexInAlive - 1]);
end

nxtButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		local nxtIndx = getNextPartyMemberIndx(inspectingIndx, false);
		print("press next", inspectingIndx, currEnemyTeamData[inspectingIndx].DISPLAYNAME, nxtIndx, currEnemyTeamData[nxtIndx].DISPLAYNAME);
	end
end)


prevButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		local nxtIndx = getNextPartyMemberIndx(inspectingIndx, true);
		print("press prev", inspectingIndx, currEnemyTeamData[inspectingIndx].DISPLAYNAME, nxtIndx, currEnemyTeamData[nxtIndx].DISPLAYNAME);
	end
end)


