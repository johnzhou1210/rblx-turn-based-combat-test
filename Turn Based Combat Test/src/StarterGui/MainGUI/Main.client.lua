--[[   Service dependencies   --]]
local RS = game:GetService("ReplicatedStorage");
local PLRS = game:GetService("Players");
local CS = game:GetService("CollectionService");
local RunService = game:GetService("RunService");
local TwnService = game:GetService("TweenService");
local UIS = game:GetService("UserInputService");
local TestService = game:GetService("TestService");
local SoundService = game:GetService("SoundService");
local CAS = game:GetService("ContextActionService");

--[[   Folder references   --]]
local TBCFolder = RS.TurnBasedCombat;
local classesFolder = TBCFolder.Classes;
local moduleFolder = TBCFolder.Modules;
local uiStorageFolder = TBCFolder.UIStorage;
local remoteEventsFolder = TBCFolder.RemoteEvents;
local battleSceneFolder = workspace.BattleScene;
local battleSceneEnemiesFolder = battleSceneFolder.Enemies;
local battleSceneInvisComponents = battleSceneFolder.InvisComponents;
local battleSceneMap = battleSceneFolder.SceneMap;
local PPEFolder = TBCFolder.PostProcessingEffects;
local musicFolder = TBCFolder.Music;
local battleSceneFolder = workspace.BattleScene;
local miscFolder = RS.Misc;
local classesFolder = TBCFolder.Classes;
local remoteFunctionsFolder = TBCFolder.RemoteFunctions;
local bindableEventsFolder = TBCFolder.BindableEvents;

--[[   External dependencies   --]]
local mouse = require(moduleFolder.mouse);
local PlayerActionsList = require(classesFolder.Action.Storage.PlayerActionsList);
local EnemyActionsList = require(classesFolder.Action.Storage.EnemyActionsList);
local util = require(miscFolder.Util);
local StatusEffectIcons = require(classesFolder.PartyMember.Storage.StatusEffectIcons);


--[[   Class dependencies   --]]
local Party = require(classesFolder.Party);
local PlayerParty = require(classesFolder.Party.PlayerParty);
local EnemyParty = require(classesFolder.Party.EnemyParty);
local BattleSceneClient = require(classesFolder.BattleScene.BattleSceneClient);
local PartyMember = require(classesFolder.PartyMember);
local PlayerPartyMember = require(classesFolder.PartyMember.PlayerPartyMember);
local EnemyPartyMember = require(classesFolder.PartyMember.EnemyPartyMember);
local Command = require(classesFolder.Command);
local PlayerAction = require(classesFolder.Action.PlayerAction);
local audioPlayerClient = require(classesFolder.AudioPlayerClient);

--[[   Key variables   --]]
local viewportSize = workspace.CurrentCamera.ViewportSize;
local plrGUI = PLRS.LocalPlayer:WaitForChild("PlayerGui");
local battleCamSubject = battleSceneInvisComponents.BattleCameraSubject;
local tweenInfoIn = TweenInfo.new(.25);
local tweenInfoOut = TweenInfo.new(1);
mouse.TargetFilter = {};
UIS.MouseBehavior = Enum.MouseBehavior.Default;
local lPlr = PLRS.LocalPlayer or PLRS:GetPropertyChangedSignal("LocalPlayer"):wait();
local plrGui = lPlr.PlayerGui;
local localSFXFolder = plrGui:WaitForChild("LocalSFX");
local battleFrame = script.Parent.BattleFrame;
local actionsFrame = battleFrame.Actions;
local partyFrame = battleFrame.PartyFrame;
local modalThingy = script.Parent.ModalThingy;
local fieldFrame = script.Parent.FieldFrame;
local encounterBarFrame = fieldFrame.EncounterBarFrame;
local encounterBar = encounterBarFrame.Bar;
local skillsFrame = battleFrame.SkillsFrame;
local skillsListScrollingFrame = skillsFrame.SkillsListFrame.List.ScrollingFrame;
local fightButtonFrame = actionsFrame.FightAction;
local skillsButtonFrame = actionsFrame.SkillsAction;
local defendButtonFrame = actionsFrame.DefendAction;
local itemsButtonFrame = actionsFrame.ItemsAction;
local burstButtonFrame = actionsFrame.BurstAction;
local fleeButtonFrame = actionsFrame.FleeAction;
local backButtonFrame = actionsFrame.BackAction;
local startTurnConfirmationFrame = battleFrame.StartTurnConfirmation;
local clockFrame = script.Parent.ClockFrame;
local clockScrollingText = clockFrame.Line.Frame.ScrollingText;
local turnPrepLogText = battleFrame.TurnPrep.LogFrame.Log;
local turnOngoingText = battleFrame.TurnOngoing.Log;
local UniquePlayerModelsFolder = plrGui:WaitForChild("UniquePlayerModels");
local rng = Random.new();
debounce = false;
handleActionDebounce = false;
viewingBuffs = false;
viewingStats = false;
autoBattleDebounce = false;
battleOverBool = true;
inTurnConfirmation = false;
fleeSuccessIndx = -1;

--[[   Variables initialized later   --]]
local EncounterClient;
local plrPlatform;
local initializeBattleCameraConnection;
local enemySelectConnectionBegan;
local defaultColorCorrection; local defaultBlur;
local battleMenuActionIconGradientAnim;
local mouseCheckTargetEnemyConnection;
local tempCommandArr;
local tempDefendedArr;
local partyMemberFrameMouseEnterConnectionsArr;
local partyMemberFrameMouseLeaveConnectionsArr;
local partyMemberFrameInputBeganConnectionsArr;
local skillFrameInputBeganConnectionsArr; 
local skillFrameMouseEnterConnectionsArr;
local skillFrameMouseLeaveConnectionsArr;
local yesStartTurnConnection; local noStartTurnConnection;
local startTime;
--regular
local battleMusic = audioPlayerClient(lPlr, musicFolder.BattleMusic, 0, true);
--regular2
--local battleMusic = audioPlayerClient(lPlr, musicFolder.BattleMusic2, .25, true, 144);
-- op
local opBossMusic = audioPlayerClient(lPlr, musicFolder.OPFiendMusic, 0, true, 176);
-- weak
--local battleMusic = audioPlayerClient(lPlr, musicFolder.FiendMusicEasy, 0, true, 139.5);
-- medium
--local battleMusic = audioPlayerClient(lPlr, musicFolder.FiendMusic, .5, true, 135);
-- strong
--local battleMusic = audioPlayerClient(lPlr, musicFolder.FiendMusicMedium, 0, true, 54);
local worldMusic = audioPlayerClient(lPlr, musicFolder.TwilightForest, 0, true); worldMusic:Play(); 

local createTouchButton = false;
if plrPlatform == "Mobile" then createTouchButton = true; end

--[[   Key functions   --]]
function createTeleGui(img)
	local gui = Instance.new("ScreenGui");
	gui.IgnoreGuiInset = true;
	local imgLabel = Instance.new("ImageLabel");
	imgLabel.Parent = gui;
	imgLabel.Image = img;
	imgLabel.AnchorPoint = Vector2.new(.5,.5);
	imgLabel.Position = UDim2.new(.5,0,.5,0);
	imgLabel.Size = UDim2.new(1,0,1,0);
	return gui;
end

function telePlr(place, img)
	game:GetService("TeleportService"):SetTeleportGui(createTeleGui(img));
	remoteEventsFolder.Teleportation.TelePlayer:FireServer(place);
end

function getPlatform()
	if (game:GetService("GuiService"):IsTenFootInterface()) then
		return "Console"
	elseif (game:GetService("UserInputService").TouchEnabled and not game:GetService("UserInputService").MouseEnabled) then
		return "Mobile";
	end
	return "Desktop";
end

function InitializeBattleCamera()
	local currCam = workspace.CurrentCamera;
	currCam.CameraType = Enum.CameraType.Scriptable;
	local fov = 56 + (30 * math.sqrt(#(EncounterClient.EnemyParty.TeamMembers)));
	currCam.FieldOfView = fov;
	initializeBattleCameraConnection = RunService.RenderStepped:Connect(function()
		currCam.CFrame = battleCamSubject.CFrame;
	end)
	local zoomInCoro = coroutine.wrap(function()
		wait(.25);
		for i = fov, fov / 2, -1 do
			RunService.Heartbeat:Wait();
			currCam.FieldOfView = i;
		end
		currCam.FieldOfView = fov / 2;
	end)
	zoomInCoro();
end

function ResetCamera()
	if initializeBattleCameraConnection then
		initializeBattleCameraConnection:Disconnect();
		print("disconnected battle cam connection")
	end
	workspace.CurrentCamera.CameraSubject = lPlr.Character.Humanoid;
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom;
	workspace.CurrentCamera.FieldOfView = 70;
end

function ShowBattleUI()
	battleFrame.Visible = true;
	--modalThingy.Visible = true;
	battleMenuActionIconGradientAnim();
	partyMemberFrameHighlightGradientAnim();
end

function HideBattleUI()
	battleFrame.Visible = false;
	--modalThingy.Visible = false;
end

function SetClockScrollingText(newText)
	clockScrollingText.Text = newText;
end

function BattleFadeIn()
	local distort = coroutine.wrap(function()
		local resize = require(moduleFolder.Distort);
		local blur = Instance.new("BlurEffect"); blur.Parent = workspace.CurrentCamera; blur.Name = "DistortionBlur"
		resize:Start();
		for i = 1, 128, 2 do
			RunService.RenderStepped:Wait();
			blur.Size = ((i / 128) * 46) + 1;
			resize.Size = UDim2.new(i / 128, 0, i / 128, 0)
		end	
		blur:Destroy();
		resize.Stop();
	end)
	local coro = coroutine.wrap(function()
		for i = 1, -.05, -.05 do
			defaultColorCorrection.TintColor = Color3.new(i, i, i);
			RunService.RenderStepped:Wait();
		end	
	end)
	distort();
	wait(.75);
	coro();
end

function BattleFadeOut()
	local coro = coroutine.wrap(function()
		for i = 0, 1.1, .1 do
			defaultColorCorrection.TintColor = Color3.new(i, i, i);
			RunService.RenderStepped:Wait();
		end	
	end)
	coro();
end

function BlurIn()
	coroutine.wrap(function()
		for i = defaultBlur.Size, 24 do
			defaultBlur.Size = i;
			RunService.RenderStepped:Wait();
		end
	end)();
end

function BlurOut()
	coroutine.wrap(function()
		for i = defaultBlur.Size, 0, -1 do
			defaultBlur.Size = i;
			RunService.RenderStepped:Wait();
		end
	end)();
end

function bindPlrBuffsDebuffs()
	CAS:BindAction("PLRBUFFSDEBUFFS",handleAction, true, Enum.KeyCode.Q);
	CAS:SetImage("PLRBUFFSDEBUFFS", "rbxassetid://10369292512");
	CAS:SetPosition("PLRBUFFSDEBUFFS", UDim2.new(.5,0,.375,0)); 
end

function bindPlrStats()
	CAS:BindAction("PLRBATTLESTATS", handleAction, true, Enum.KeyCode.E);
	CAS:SetImage("PLRBATTLESTATS", "rbxassetid://10369292512");
	CAS:SetPosition("PLRBATTLESTATS", UDim2.new(0,0,.375,0)); 
end

function tweenInActionFrame()
	BlurOut();
	local goal = {};
	goal.Position = UDim2.new(.935, 0, .075, 0);
	TwnService:Create(actionsFrame, tweenInfoIn, goal):Play();
	bindPlrBuffsDebuffs()
	bindPlrStats();
end

function tweenOutActionFrame()
	local goal = {};
	goal.Position = UDim2.new(.935+1.5, 0, .075, 0);
	TwnService:Create(actionsFrame, tweenInfoOut, goal):Play();
end

function tweenInPartyFrame()
	local goal = {};
	goal.Position = UDim2.new(.005, 0, .865, 0);
	TwnService:Create(partyFrame, tweenInfoIn, goal):Play();
end

function tweenOutPartyFrame()
	local goal = {};
	goal.Position = UDim2.new(.005, 0, 1.865, 0);
	TwnService:Create(partyFrame, tweenInfoOut, goal):Play();
end

function tweenInCurrCharViewportFrame()
	if battleFrame:FindFirstChild("CurrentCharViewport") ~= nil then
		local goal = {};
		goal.Position = UDim2.new(-.1337, 0, .108, 0);
		TwnService:Create(battleFrame:FindFirstChild("CurrentCharViewport"), tweenInfoIn, goal):Play();
	end
end

function tweenOutCurrCharViewportFrame()
	if battleFrame:FindFirstChild("CurrentCharViewport") ~= nil then
		local goal = {};
		goal.Position = UDim2.new(-1.1337, 0, .108, 0);
		TwnService:Create(battleFrame:FindFirstChild("CurrentCharViewport"), tweenInfoOut, goal):Play();	
	end
end

function tweenInSkillsFrame()
	BlurIn();
	local goal = {};
	goal.Position = UDim2.new(0, 0, 0, 0);
	TwnService:Create(battleFrame:FindFirstChild("SkillsFrame"), tweenInfoIn, goal):Play();
	local canvas = skillsFrame.SkillsListFrame.List.ScrollingFrame;
	local constraint = canvas.UIListLayout;
	EncounterClient:UpdateSkillsListCanvasSize(canvas, constraint);
end

function tweenOutSkillsFrame()
	--BlurOut();
	local goal = {};
	goal.Position = UDim2.new(-1, 0, 0, 0);
	TwnService:Create(battleFrame:FindFirstChild("SkillsFrame"), tweenInfoIn, goal):Play();--tweenInfoIn because it goes back so slowly
end

function tweenInPartyEffectsFrame()
	--BlurIn();
	local goal = {};
	goal.Position = UDim2.new(.019, 0, .139, 0);
	TwnService:Create(battleFrame:FindFirstChild("PartyEffectsFrame"), tweenInfoIn, goal):Play();
end

function tweenOutPartyEffectsFrame()
	--BlurOut();
	local goal = {};
	goal.Position = UDim2.new(1.019, 0, .139, 0);
	TwnService:Create(battleFrame:FindFirstChild("PartyEffectsFrame"), tweenInfoIn, goal):Play();
end

function tweenInPartyStatsFrame()
	--BlurIn();
	local goal = {};
	goal.Position = UDim2.new(.019, 0, .139, 0);
	TwnService:Create(battleFrame:FindFirstChild("PartyStatsFrame"), tweenInfoIn, goal):Play();
end

function tweenOutPartyStatsFrame()
	--BlurIn();
	local goal = {};
	goal.Position = UDim2.new(1.019, 0, .139, 0);
	TwnService:Create(battleFrame:FindFirstChild("PartyStatsFrame"), tweenInfoIn, goal):Play();
end

function playBeepSFX()
	audioPlayerClient(lPlr, localSFXFolder.Beep, 0, false);
end

function playDenySFX()
	audioPlayerClient(lPlr, localSFXFolder.Deny, 0, false);
end

function enemyModelAlive(model)
	local function extractLeftHPPortion(str)
		local slashIndx = string.find(str, "/");
		if slashIndx == nil then error("invalid hp txt!"); end
		local leftPart = string.sub(str, 1, slashIndx-1);
		--warn(leftPart);
		return leftPart;
	end
	if tonumber(extractLeftHPPortion(model.Head.HP.HPBar.Val.Text)) ~= nil and tonumber(extractLeftHPPortion(model.Head.HP.HPBar.Val.Text)) > 0 then
		return true;
	end
	return false;
end

function getParentThatIsDirectChildOfEnemiesFolder(mouseTarget)
	--	warn(mouseTarget);
	if mouseTarget.Parent.Name == "Enemies" then return mouseTarget; end
	if mouseTarget.Parent.Parent.Name == "Enemies" then return mouseTarget.Parent; end
	if mouseTarget.Parent.Parent.Parent.Name == "Enemies" then return mouseTarget.Parent.Parent; end
	if mouseTarget.Parent.Parent.Parent.Parent.Name == "Enemies" then return mouseTarget.Parent.Parent.Parent; end
	if mouseTarget.Parent.Parent.Parent.Parent.Parent.Name == "Enemies" then return mouseTarget.Parent.Parent.Parent.Parent; end
	if mouseTarget.Parent.Parent.Parent.Parent.Parent.Parent.Name == "Enemies" then return mouseTarget.Parent.Parent.Parent.Parent.Parent; end
	if mouseTarget.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Name == "Enemies" then return mouseTarget.Parent.Parent.Parent.Parent.Parent.Parent; end
	if mouseTarget.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Name == "Enemies" then return mouseTarget.Parent.Parent.Parent.Parent.Parent.Parent.Parent; end
	if mouseTarget.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Name == "Enemies" then return mouseTarget.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent; end
	if mouseTarget.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Name == "Enemies" then return mouseTarget.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent; end
	error("mouseTarget IS TOO DEEP IN HIERARCHY!");
end

function showEnemyHealthBars()
	for i,v in pairs(battleSceneFolder.Enemies:GetChildren()) do
		if enemyModelAlive(v) then
			v:WaitForChild("Head").HP.Enabled = true;
		else
			-- don't show
		end
	end 
end

function hideEnemyHealthBars()
	for i,v in pairs(battleSceneFolder.Enemies:GetChildren()) do
		v:WaitForChild("Head").HP.Enabled = false;
	end 
end

function hideEnemySelectionPointers()
	for i,v in pairs(battleSceneFolder.Enemies:GetChildren()) do
		v:WaitForChild("Head").SelectionPointer.Enabled = false;
		v:WaitForChild("Head").LightAttachment.SelectionLight.Enabled = false;
	end
end

function updateLogText(newText)
	EncounterClient:UpdateLogText(newText);
end

function hideTurnPrepFrame()
	battleFrame.TurnPrep.Visible = false;
end

function showTurnPrepFrame()
	battleFrame.TurnPrep.Visible = true;
end

function hideTurnOngoingFrame()
	battleFrame.TurnOngoing.Visible = false;
end

function showTurnOngoingFrame()
	battleFrame.TurnOngoing.Visible = true;
end

function cleanUpSkillScrollingFrameContents()
	for i,v in pairs(skillsListScrollingFrame:GetChildren()) do
		if v:GetAttribute("IsSkillFrame") and v:GetAttribute("IsSkillFrame") == true then
			v:Destroy();
		end
	end
end

function executeTurn()
	SetClockScrollingText("6 AM  |  IN BATTLE  |  TURN "..EncounterClient.TurnNumber.."  |  AUTO "..EncounterClient.AutoBattle);
	--get rid of current character viewportframe
	if battleFrame:FindFirstChild("CurrentCharViewport") then battleFrame:FindFirstChild("CurrentCharViewport"):Destroy(); end
	CAS:UnbindAction("AUTOBATTLE"); CAS:UnbindAction("PLRBUFFSDEBUFFS"); CAS:UnbindAction("PLRBATTLESTATS");
end

function findEnemyModelFromIndex(index)
	if index == nil then return nil; end
	for i,v in pairs(battleSceneEnemiesFolder:GetChildren()) do
		if v:WaitForChild("Humanoid").IndexInTeamMembersArr.Value == index then
			return v;
		end
	end 
	return nil;
end

function findPlayerObjFromIndex(index)--use this only for client stuff
	return EncounterClient.PlayerParty.TeamMembers[index];
end

function turnConfirmation(isAuto)
	debounce = true;
	inTurnConfirmation = true;
	-- blur the screen 
	--repeat wait()
		BlurIn();
	--	print ("in here")
	--until defaultBlur.Size == 24;
	-- show start turn confirmation
	startTurnConfirmationFrame.Visible = true;
	updateLogText("");
	hideTurnOngoingFrame();
	-- connect button events
	yesStartTurnConnection = startTurnConfirmationFrame.ConfirmationFrame.Yes.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			playBeepSFX();
			print("sending primitive command arr to server:");
			hideTurnPrepFrame();
			showTurnOngoingFrame();
			battleFrame.TurnOngoing.Log.TextYAlignment = Enum.TextYAlignment.Top;
			--get ready to visually display turn by connecting a remote event that listens for log changes and visual effect cues
			if isAuto then
				
				-- build the command arr.
				-- first get the current party member index because the temp command array could already be somewhat filled up
				-- starting from the current party member index, fill the rest with a simple attack command
				for i = EncounterClient.CurrentSelectedPlayerIndex, #EncounterClient.PlayerParty.TeamMembers do
					local currPartyMember = EncounterClient.PlayerParty.TeamMembers[i];
					local currPlayerFrame = partyFrame:FindFirstChild(tostring(i));
					if currPlayerFrame then
						EncounterClient:UnhighlightPartyMember(currPlayerFrame);
					end
					if EncounterClient:CannotAct(currPartyMember) then
						-- skip
					else
						local primitiveCommand = {i, "Attack", {1}, "EnemyParty"}; -- just default to attack first enemy. later we will skip dead enemies
						table.insert(tempCommandArr, primitiveCommand);
					end
				end
				
				warn(tempCommandArr);
				
				EncounterClient.AutoBattle = "ON";
				EncounterClient.LogSpeedMult = 2.6;
				
				
					
			else
				-- tempcommandarray is already stacked!
			end
			
			warn(tempCommandArr);
			remoteEventsFolder.BattleSystem.SendCommandToServer:FireServer(tempCommandArr);--also pass battle id
			CAS:UnbindAction("PLRBUFFSDEBUFFS"); CAS:UnbindAction("PLRBATTLESTATS");
			executeTurn();
			
			BlurOut();
			tweenOutActionFrame();
			startTurnConfirmationFrame.Visible = false;
			coroutine.wrap(function()
				viewingBuffs = false;
				viewingStats = false;
				wait(.5);
				inTurnConfirmation = false;
				debounce = false;
				actionsFrame.Visible = true;
				handleActionDebounce = false;
				
			end)();
			noStartTurnConnection:Disconnect();
			yesStartTurnConnection:Disconnect();
		end
	end)
	noStartTurnConnection = startTurnConfirmationFrame.ConfirmationFrame.No.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			
			if not isAuto then
				-- get rid of the last element from the primitive command arr
				table.remove(tempCommandArr, #tempCommandArr);
				
			end
			
			
			warn(tempCommandArr);
			hideTurnOngoingFrame();
			battleFrame.TurnOngoing.Log.TextYAlignment = Enum.TextYAlignment.Center;
			playBeepSFX();
			BlurOut();
			startTurnConfirmationFrame.Visible = false;
			updateLogText("What will you do?");

			local coro = coroutine.wrap(function()
				wait(.35);
				showTurnPrepFrame();
				EncounterClient:DetermineAndSetPreviousSelectedPlayerIndex(true);
				warn("Went back. Index is now "..EncounterClient.CurrentSelectedPlayerIndex);
				EncounterClient:HighlightPartyMember(partyFrame[tostring(EncounterClient.CurrentSelectedPlayerIndex)]);
				--print("highlightedmain", EncounterClient.CurrentSelectedPlayerIndex)
				--check to see if the undoed index matches with any first string letter from the tempdefendedarr
				for i = 1, #tempDefendedArr, 1 do -- might want to change this to a while loop
					local currStringCode = tempDefendedArr[i];
					warn("current string code: "..currStringCode);
					local defenderIndex = tonumber(string.sub(currStringCode, 1, 1));
					local defendedIndex = tonumber(string.sub(currStringCode, 2, 2));
					if defenderIndex == EncounterClient.CurrentSelectedPlayerIndex then
						warn("removing the following string code: "..currStringCode);
						table.remove(tempDefendedArr, i);
						--make the isbeingdefended value false. but first you need to access the defended's player object
						local defendedPlayerObj = findPlayerObjFromIndex(defendedIndex);
						defendedPlayerObj.ISBEINGDEFENDED = false;
						i = i - 1;--account for the array shift. 
					end
				end
				if EncounterClient:DetermineButDoNotSetPreviousSelectedPlayerIndex() ~= -1 then
					backButtonFrame.Visible = true;
					warn("Visible. "..EncounterClient:DetermineButDoNotSetPreviousSelectedPlayerIndex());
				else
					backButtonFrame.Visible = false;
					warn("Invisible. "..EncounterClient:DetermineButDoNotSetPreviousSelectedPlayerIndex());
				end
				tweenInActionFrame();
				tweenInCurrCharViewportFrame();	
				debounce = false;
				bindPlrBuffsDebuffs();
				bindPlrStats();
			end)
			coro();
			coroutine.wrap(function()
				viewingBuffs = false;
				viewingStats = false;
				wait(.5);
				inTurnConfirmation = false;
				debounce = false;
				actionsFrame.Visible = true;
				handleActionDebounce = false;
				
			end)();
			yesStartTurnConnection:Disconnect();
			noStartTurnConnection:Disconnect();
		end
	end)
end

function goToNextPlayerAndStartTurnIfNeeded() -- still need to work on self target type
	--BlurOut();
	local startBattlePhaseOrNot = EncounterClient:DetermineAndSetNextSelectedPlayerIndex();
	if startBattlePhaseOrNot == true then --send primitive command arr to server
		turnConfirmation(false);
	else --go to the next team member who can act
		--warn(tempCommandArr);
		print("going to next able team member. Currmemberindex is now "..EncounterClient.CurrentSelectedPlayerIndex);
		showTurnPrepFrame();
		hideTurnOngoingFrame();
		tweenInActionFrame(); 
		EncounterClient:UpdateLogText("What will you do?");
		tweenInCurrCharViewportFrame()--change the object value as well
		if EncounterClient:DetermineButDoNotSetPreviousSelectedPlayerIndex() ~= -1 then
			backButtonFrame.Visible = true;
			warn("Visible. "..EncounterClient:DetermineButDoNotSetPreviousSelectedPlayerIndex());
		else
			backButtonFrame.Visible = false;
			warn("Invisible. "..EncounterClient:DetermineButDoNotSetPreviousSelectedPlayerIndex());
		end
	end
	if enemySelectConnectionBegan then enemySelectConnectionBegan:Disconnect(); end
	if mouseCheckTargetEnemyConnection then mouseCheckTargetEnemyConnection:Disconnect(); end
	if partyMemberFrameMouseEnterConnectionsArr then
		for i,v in pairs(partyMemberFrameMouseEnterConnectionsArr) do
			v:Disconnect();
		end	
	end
	if partyMemberFrameMouseLeaveConnectionsArr then
		for i,v in pairs(partyMemberFrameMouseLeaveConnectionsArr) do
			v:Disconnect();
		end	
	end
	if partyMemberFrameInputBeganConnectionsArr then
		for i,v in pairs(partyMemberFrameInputBeganConnectionsArr) do
			v:Disconnect();
		end	
	end
	hideEnemyHealthBars();
	hideEnemySelectionPointers();
	battleFrame.CancelChooseTarget.Visible = false;
end

function SingleParty(actionName)
	hideTurnPrepFrame();
	showTurnOngoingFrame();
	EncounterClient:UpdateLogText("Choose an ally target.");
	BlurIn();
	local partyMemberFramesArr = partyFrame:GetChildren();
	partyMemberFrameMouseEnterConnectionsArr = {};
	partyMemberFrameMouseLeaveConnectionsArr = {};
	partyMemberFrameInputBeganConnectionsArr = {};
	for i,v in pairs(partyMemberFramesArr) do -- add connections for the partymemberframes that will be disconnected later
		local partyMemberFrameMouseEnterConnection = v.Round.MouseEnter:Connect(function()
			if v.Round.SelectionHighlight.Visible == false then
				v.Round.SelectionHighlight.Visible = true;
			end
		end)
		table.insert(partyMemberFrameMouseEnterConnectionsArr, partyMemberFrameMouseEnterConnection);
		local partyMemberFrameMouseLeaveConnection = v.Round.MouseLeave:Connect(function()
			v.Round.SelectionHighlight.Visible = false; 
		end)
		table.insert(partyMemberFrameMouseLeaveConnectionsArr, partyMemberFrameMouseLeaveConnection);
		local partyMemberFrameInputBeganConnection =  v.Round.InputBegan:Connect(function(input, GPE)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local selectedPlayerIndex = tonumber(v.Name);
				local selectedPlayerObj = EncounterClient.PlayerParty.TeamMembers[selectedPlayerIndex];
				--find the action and check if IsRevivalSkill is true or false
				local action = PlayerActionsList[actionName] -- is dictionary
				if (selectedPlayerObj.STATUSEFFECT == "DEAD" and action["ISREVIVALSKILL"] == false) or (selectedPlayerObj.STATUSEFFECT ~= "DEAD" and action["ISREVIVALSKILL"] == true) then
					playDenySFX();
					--do nothing
				else
					v.Round.SelectionHighlight.Visible = false;
					playBeepSFX();
					local primitiveCommand = {EncounterClient.CurrentSelectedPlayerIndex, actionName, {selectedPlayerIndex}, "PlayerParty"};
					table.insert(tempCommandArr, primitiveCommand);
					goToNextPlayerAndStartTurnIfNeeded();
				end
			end
		end)
		table.insert(partyMemberFrameInputBeganConnectionsArr, partyMemberFrameInputBeganConnection);
	end	
end

function Self(actionName)
	local primitiveCommand = {EncounterClient.CurrentSelectedPlayerIndex, actionName, {EncounterClient.CurrentSelectedPlayerIndex}, "PlayerParty"};
	table.insert(tempCommandArr, primitiveCommand);
	goToNextPlayerAndStartTurnIfNeeded();
end

function DefendAction()
	hideTurnPrepFrame();
	showTurnOngoingFrame();
	EncounterClient:UpdateLogText("Choose an ally to defend.");
	BlurIn();
	local partyMemberFramesArr = partyFrame:GetChildren();
	partyMemberFrameMouseEnterConnectionsArr = {};
	partyMemberFrameMouseLeaveConnectionsArr = {};
	partyMemberFrameInputBeganConnectionsArr = {};
	for i,v in pairs(partyMemberFramesArr) do -- add connections for the partymemberframes that will be disconnected later
		local partyMemberFrameMouseEnterConnection = v.Round.MouseEnter:Connect(function()
			if v.Round.SelectionHighlight.Visible == false then
				v.Round.SelectionHighlight.Visible = true;
			end
		end)
		table.insert(partyMemberFrameMouseEnterConnectionsArr, partyMemberFrameMouseEnterConnection);
		local partyMemberFrameMouseLeaveConnection = v.Round.MouseLeave:Connect(function()
			v.Round.SelectionHighlight.Visible = false; 
		end)
		table.insert(partyMemberFrameMouseLeaveConnectionsArr, partyMemberFrameMouseLeaveConnection);
		local partyMemberFrameInputBeganConnection =  v.Round.InputBegan:Connect(function(input, GPE)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local selectedPlayerIndex = tonumber(v.Name);
				local selectedPlayerObj = EncounterClient.PlayerParty.TeamMembers[selectedPlayerIndex];
				--find the action and check if IsRevivalSkill is true or false
				local action = PlayerActionsList["Defend"] -- is dictionary
				if (selectedPlayerObj.STATUSEFFECT == "DEAD" and action["ISREVIVALSKILL"] == false) or selectedPlayerObj.ISBEINGDEFENDED == true then
					playDenySFX();
					--do nothing
				else
					--print(selectedPlayerObj.STATUSEFFECT); print(action["ISREVIVALSKILL"]);
					--print(action["ISREVIVALSKILL"]);
					--add defended player index to defendedarr in the following string format: defenderIndex..defendedIndex
					local stringCode = EncounterClient.CurrentSelectedPlayerIndex..selectedPlayerIndex;
					--warn(stringCode);
					table.insert(tempDefendedArr, stringCode);
					v.Round.SelectionHighlight.Visible = false;
					playBeepSFX();
					selectedPlayerObj.ISBEINGDEFENDED = true;--only for the client side

					local primitiveCommand = {EncounterClient.CurrentSelectedPlayerIndex, "Defend", {selectedPlayerIndex}, "PlayerPartyGuardIndex"..selectedPlayerIndex};
					table.insert(tempCommandArr, primitiveCommand);
					goToNextPlayerAndStartTurnIfNeeded();
				end
			end
		end)
		table.insert(partyMemberFrameInputBeganConnectionsArr, partyMemberFrameInputBeganConnection);
	end	
end

function SingleEnemy(actionName)
	
	
	showEnemyHealthBars();
	hideTurnPrepFrame();
	showTurnOngoingFrame();
	EncounterClient:UpdateLogText("Choose an enemy target.");
	BlurOut();
	startTime = tick();
	enemySelectConnectionBegan = UIS.InputBegan:Connect(function(input, GPE)
		--print(input.UserInputType);
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local mouseTarget = mouse.Target;
			--print(tostring(mouse.Target));
			if mouseTarget and mouseTarget:FindFirstAncestor("Enemies") and debounce == false then
				local enemyModel = getParentThatIsDirectChildOfEnemiesFolder(mouseTarget);
				local enemyIndexInTeamMembersArr = enemyModel:WaitForChild("Humanoid").IndexInTeamMembersArr.Value;
				if enemyModel ~= nil and enemyModel:FindFirstChild("Head") and enemyModel.Head:FindFirstChild("HP") and enemyModelAlive(enemyModel) then
					debounce = true
					local coro = coroutine.wrap(function()
						wait(.25);
						debounce = false;
					end)
					coro();
					playBeepSFX();
					--add to target array for the command thingy now and continue!
					local primitiveCommand = {EncounterClient.CurrentSelectedPlayerIndex, actionName, {enemyIndexInTeamMembersArr}, "EnemyParty"};
					table.insert(tempCommandArr, primitiveCommand);
					warn("added primitivecommand to tempcommandarr");
					goToNextPlayerAndStartTurnIfNeeded();
				else
					print("target is dead!");
				end 
			end
		end
	end)
	local lastFrameTarget;
	mouseCheckTargetEnemyConnection = UIS.InputChanged:Connect(function()
		local mouseTarget = mouse.Target;
		if mouseTarget and mouseTarget:FindFirstAncestor("Enemies") then
			local enemyModel = getParentThatIsDirectChildOfEnemiesFolder(mouseTarget);
			if enemyModelAlive(enemyModel) then
				if lastFrameTarget and lastFrameTarget ~= enemyModel then
					lastFrameTarget:WaitForChild("Head").SelectionPointer.Enabled = false;
					lastFrameTarget:WaitForChild("Head").LightAttachment.SelectionLight.Enabled = false;
				end
				enemyModel:WaitForChild("Head").SelectionPointer.Enabled = true;
				enemyModel:WaitForChild("Head").LightAttachment.SelectionLight.Enabled = true;
				local enemyIndexInTeamMembersArr = enemyModel:WaitForChild("Humanoid").IndexInTeamMembersArr.Value;
				local EnemyObj = EncounterClient.EnemyParty.TeamMembers[enemyIndexInTeamMembersArr];
				EncounterClient:UpdateLogText(EnemyObj.DISPLAYNAME);
				lastFrameTarget = enemyModel;
			end 

		elseif lastFrameTarget then
			EncounterClient:UpdateLogText("Choose an enemy target.");
			lastFrameTarget:WaitForChild("Head").SelectionPointer.Enabled = false;
			lastFrameTarget:WaitForChild("Head").LightAttachment.SelectionLight.Enabled = false;
		end	
	end)	
end

function FleeAction()
	local actionObj = PlayerActionsList['Flight'];
	local enemyPartyArr = EncounterClient.EnemyParty.TeamMembers;
	local primitiveCommand;
	primitiveCommand = {EncounterClient.CurrentSelectedPlayerIndex, "Flight", {}, "PlayerParty"};
	--add to target array for the command thingy now and continue!
	--warn(primitiveCommand);
	table.insert(tempCommandArr, primitiveCommand);
	warn("added primitivecommand to tempcommandarr");
	goToNextPlayerAndStartTurnIfNeeded();
end

function AllEnemy(actionName)
	local actionObj = PlayerActionsList[actionName];
	local isRevivalSkill = actionObj.IsRevivalSkill;
	local isSupportSpell = actionObj.IsSupportSpell;
	local enemyPartyArr = EncounterClient.EnemyParty.TeamMembers;
	local primitiveCommand;
	if isRevivalSkill or isSupportSpell then
		primitiveCommand = {EncounterClient.CurrentSelectedPlayerIndex, actionName, EncounterClient:ReturnArrOfPartyMemberIndexes(enemyPartyArr, false), "EnemyParty"};
	else
		primitiveCommand = {EncounterClient.CurrentSelectedPlayerIndex, actionName, EncounterClient:ReturnArrOfPartyMemberIndexes(enemyPartyArr, true), "EnemyParty"};
	end
	--add to target array for the command thingy now and continue!
	--warn(primitiveCommand);
	table.insert(tempCommandArr, primitiveCommand);
	warn("added primitivecommand to tempcommandarr");
	goToNextPlayerAndStartTurnIfNeeded();
end

function AllParty(actionName)
	local actionObj = PlayerActionsList[actionName];
	local isRevivalSkill = actionObj.IsRevivalSkill;
	local isSupportSpell = actionObj.IsSupportSpell;
	local playerPartyArr = EncounterClient.PlayerParty.TeamMembers;
	local primitiveCommand;
	if isRevivalSkill or isSupportSpell then
		primitiveCommand = {EncounterClient.CurrentSelectedPlayerIndex, actionName, EncounterClient:ReturnArrOfPartyMemberIndexes(playerPartyArr, false), "PlayerParty"};
	else
		primitiveCommand = {EncounterClient.CurrentSelectedPlayerIndex, actionName, EncounterClient:ReturnArrOfPartyMemberIndexes(playerPartyArr, true), "PlayerParty"};
	end
	--add to target array for the command thingy now and continue!
	--warn(primitiveCommand);
	table.insert(tempCommandArr, primitiveCommand);
	warn("added primitivecommand to tempcommandarr");
	goToNextPlayerAndStartTurnIfNeeded();
end

function SplashEnemy(actionName)
	showEnemyHealthBars();
	local ignoreDead = true;
	if PlayerActionsList[actionName].IsRevivalSkill == true then ignoreDead = false; end
	local function returnTargetIndexIfThere(arr, index, ignoreDead)
		if arr[index] then
			if arr[index].CURRHP <= 0 and ignoreDead == true then
				--do nothing
				return nil;
			else
				return index;	
			end
		end
		return nil;
	end
	hideTurnPrepFrame();
	showTurnOngoingFrame();
	EncounterClient:UpdateLogText("Choose an enemy target.");
	BlurOut();
	enemySelectConnectionBegan = UIS.InputBegan:Connect(function(input, GPE)
		--print(input.UserInputType);
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local mouseTarget = mouse.Target;
			--print(tostring(mouse.Target));
			if mouseTarget and mouseTarget:FindFirstAncestor("Enemies") and debounce == false then
				local enemyModel = getParentThatIsDirectChildOfEnemiesFolder(mouseTarget);
				local enemyIndexInTeamMembersArr = enemyModel:WaitForChild("Humanoid").IndexInTeamMembersArr.Value;
				if enemyModel ~= nil and enemyModel:FindFirstChild("Head") and enemyModel.Head:FindFirstChild("HP") and enemyModelAlive(enemyModel) then
					debounce = true
					local coro = coroutine.wrap(function()
						wait(.25);
						debounce = false;
					end)
					coro();
					playBeepSFX();
					--add to target array for the command thingy now and continue!
					local targetIndices = {enemyIndexInTeamMembersArr};
					if returnTargetIndexIfThere(EncounterClient.EnemyParty.TeamMembers, enemyIndexInTeamMembersArr - 1, ignoreDead) ~= nil then
						table.insert(targetIndices, returnTargetIndexIfThere(EncounterClient.EnemyParty.TeamMembers, enemyIndexInTeamMembersArr - 1, ignoreDead));
					end
					if returnTargetIndexIfThere(EncounterClient.EnemyParty.TeamMembers, enemyIndexInTeamMembersArr + 1, ignoreDead) ~= nil then
						table.insert(targetIndices, returnTargetIndexIfThere(EncounterClient.EnemyParty.TeamMembers, enemyIndexInTeamMembersArr + 1, ignoreDead));
					end
					local primitiveCommand = {
						EncounterClient.CurrentSelectedPlayerIndex, actionName, 
						targetIndices, 
						"EnemyParty",
					};
					table.insert(tempCommandArr, primitiveCommand);
					warn("added primitivecommand to tempcommandarr");
					goToNextPlayerAndStartTurnIfNeeded();
				else
					print("target is dead!");
				end
			end
		end
	end)
	local lastFrameTarget;
	local lastFrameTargetLeft;
	local lastFrameTargetRight;
	local function findEnemyModelTargetLeftIfExisting(hoveredMainTarget)
		local mainTargetIndex = hoveredMainTarget.Humanoid.IndexInTeamMembersArr.Value;
		local resultIndex = returnTargetIndexIfThere(EncounterClient.EnemyParty.TeamMembers, mainTargetIndex - 1, ignoreDead);
		if resultIndex then 
			return resultIndex;
		end
		return nil;
	end
	local function findEnemyModelTargetRightIfExisting(hoveredMainTarget)
		local mainTargetIndex = hoveredMainTarget.Humanoid.IndexInTeamMembersArr.Value;
		local resultIndex = returnTargetIndexIfThere(EncounterClient.EnemyParty.TeamMembers, mainTargetIndex + 1, ignoreDead);
		if resultIndex then 
			return resultIndex;
		end
		return nil;
	end
	mouseCheckTargetEnemyConnection = UIS.InputChanged:Connect(function()
		local mouseTarget = mouse.Target;
		if mouseTarget and mouseTarget:FindFirstAncestor("Enemies") then
			local enemyModel = getParentThatIsDirectChildOfEnemiesFolder(mouseTarget);
			if enemyModelAlive(enemyModel) then
				if lastFrameTarget and lastFrameTarget ~= enemyModel then
					lastFrameTargetLeft = findEnemyModelFromIndex(findEnemyModelTargetLeftIfExisting(lastFrameTarget));
					lastFrameTargetRight = findEnemyModelFromIndex(findEnemyModelTargetRightIfExisting(lastFrameTarget));
					if lastFrameTargetLeft then
						lastFrameTargetLeft:WaitForChild("Head").SelectionPointer.Enabled = false;
					end
					if lastFrameTargetRight then
						lastFrameTargetRight:WaitForChild("Head").SelectionPointer.Enabled = false;
					end
					lastFrameTarget:WaitForChild("Head").SelectionPointer.Enabled = false;
					lastFrameTarget:WaitForChild("Head").LightAttachment.SelectionLight.Enabled = false;
				end
				local enemyModelLeftTarget = findEnemyModelFromIndex(findEnemyModelTargetLeftIfExisting(enemyModel));
				local enemyModelRightTarget = findEnemyModelFromIndex(findEnemyModelTargetRightIfExisting(enemyModel));
				if enemyModelLeftTarget and enemyModelAlive(enemyModelLeftTarget) then
					enemyModelLeftTarget:WaitForChild("Head").SelectionPointer.Enabled = true;
				end
				if enemyModelRightTarget and enemyModelAlive(enemyModelRightTarget) then
					enemyModelRightTarget:WaitForChild("Head").SelectionPointer.Enabled = true;
				end
				enemyModel:WaitForChild("Head").SelectionPointer.Enabled = true;
				enemyModel:WaitForChild("Head").LightAttachment.SelectionLight.Enabled = true;
				local enemyIndexInTeamMembersArr = enemyModel:WaitForChild("Humanoid").IndexInTeamMembersArr.Value;
				local EnemyObj = EncounterClient.EnemyParty.TeamMembers[enemyIndexInTeamMembersArr];
				EncounterClient:UpdateLogText(EnemyObj.DISPLAYNAME);
				lastFrameTarget = enemyModel;
			end
		elseif lastFrameTarget then
			EncounterClient:UpdateLogText("Choose an enemy target.");
			hideEnemySelectionPointers();
		end	
	end)	
end

function doAutoBattle() -- create a filled up tempcommandarr and fire it
	if inTurnConfirmation == false and debounce == false then
		debounce = true;
		CAS:UnbindAction("PLRBUFFSDEBUFFS"); CAS:UnbindAction("PLRBATTLESTATS");
		
		playBeepSFX();	
		if enemySelectConnectionBegan then enemySelectConnectionBegan:Disconnect(); end
		if mouseCheckTargetEnemyConnection then mouseCheckTargetEnemyConnection:Disconnect(); end
		if partyMemberFrameMouseEnterConnectionsArr then
			for i,v in pairs(partyMemberFrameMouseEnterConnectionsArr) do
				v:Disconnect();
			end	
		end
		if partyMemberFrameMouseLeaveConnectionsArr then
			for i,v in pairs(partyMemberFrameMouseLeaveConnectionsArr) do
				v:Disconnect();
			end	
		end
		if partyMemberFrameInputBeganConnectionsArr then
			for i,v in pairs(partyMemberFrameInputBeganConnectionsArr) do
				v:Disconnect();
			end	
		end
		for i,v in pairs(partyFrame:GetDescendants()) do
			if v.Name == "SelectionHighlight" and v:IsA("ImageLabel") then
				v.Visible = false;
			end
		end
		hideEnemyHealthBars();
		hideEnemySelectionPointers();
		battleFrame.CancelChooseTarget.Visible = false;

		tweenOutActionFrame();
		actionsFrame.Visible = false;
		
		tweenOutSkillsFrame();
		tweenOutPartyStatsFrame();
		tweenOutCurrCharViewportFrame();
		hideTurnPrepFrame();
		
		BlurIn();
		turnConfirmation(true);

		--remoteEventsFolder.BattleSystem.SendCommandToServer:FireServer(tempCommandArr);--also pass battle id

		--showTurnOngoingFrame();
		--battleFrame.TurnOngoing.Log.TextYAlignment = Enum.TextYAlignment.Top;
		----get ready to visually display turn by connecting a remote event that listens for log changes and visual effect cues
		--executeTurn();

		
	end
end

function handleAction(actionName, inputState, inputObj)
	if actionName == "AUTOBATTLE" and inputState == Enum.UserInputState.Begin and handleActionDebounce == false then
		handleActionDebounce = true;
		tweenOutPartyEffectsFrame();
		--BlurIn();
		doAutoBattle();
		coroutine.wrap(function()
			wait(.25);
			handleActionDebounce = false;
		end)();
	elseif actionName == "PLRBUFFSDEBUFFS" and inputState == Enum.UserInputState.Begin and handleActionDebounce == false then
		handleActionDebounce = true;
		-- show/hide plr buffs debuffs screen
		if not viewingBuffs then
			BlurIn();
			playBeepSFX();	
			viewingBuffs = true;
			viewingStats = false;
			tweenOutPartyStatsFrame();
			updateLogText("Hover over the buffs and debuffs to view their effects.");
			tweenOutActionFrame();
			tweenInPartyEffectsFrame();
			print("opening player buffs debuffs screen")
			bindableEventsFolder.UpdateBuffEntries:Fire(EncounterClient.PlayerParty.TeamMembers);	
		else
			playBeepSFX();	
			viewingBuffs = false;
			updateLogText("What will you do?");
			tweenOutPartyEffectsFrame();
			print("closing player buffs debuffs screen")
			tweenInActionFrame();
			BlurOut();
		end
		coroutine.wrap(function()
			wait(.25);
			handleActionDebounce = false;
		end)();
	elseif actionName == "PLRBATTLESTATS" and inputState == Enum.UserInputState.Begin and handleActionDebounce == false then
		handleActionDebounce = true;
		if not viewingStats then
			BlurIn();
			playBeepSFX();
			viewingStats = true;
			viewingBuffs = false;
			updateLogText("Viewing party stats");
			tweenOutActionFrame();
			tweenOutPartyEffectsFrame();
			tweenInPartyStatsFrame();
			print("opening player stats screen")
			bindableEventsFolder.UpdateStatPreviews:Fire(EncounterClient.PlayerParty.TeamMembers);
		else
			
			playBeepSFX();
			viewingStats = false;
			updateLogText("What will you do?");
			tweenOutPartyStatsFrame();
			print("closing player stats screen")
			tweenInActionFrame();
			BlurOut();
		end
		coroutine.wrap(function()
			wait(.25);
			handleActionDebounce = false;
		end)();
	end
	
end

function bindAuto()
	CAS:BindAction("AUTOBATTLE",handleAction, true, Enum.KeyCode.P);
	CAS:SetImage("AUTOBATTLE", "rbxassetid://8470850505");
	CAS:SetPosition("AUTOBATTLE", UDim2.new(.25, 0, .375, 0)); 
end



--[[   Key events   --]]
--HANDLE ACTION HOVER EVENTS------
local actionFramesArr = actionsFrame:GetChildren();
for i,v in pairs(actionFramesArr) do
	--print(v.Name);
	v.Button.MouseEnter:Connect(function()
		if v.ButtonExtend.Visible == false then
			v.ButtonExtend.Visible = true; 
		end
	end)
	v.Button.MouseLeave:Connect(function()
		v.ButtonExtend.Visible = false; 
	end)
	v.ButtonExtend.MouseButton1Down:Connect(function()
		playBeepSFX();
	end)
	v.ButtonExtend.TouchTap:Connect(function()
		playBeepSFX();
	end)
	v.ButtonExtend.MouseLeave:Connect(function()
		v.ButtonExtend.Visible = false; 
	end)
end

battleFrame.CancelChooseTarget.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		battleFrame.CancelChooseTarget.Round.UIGradient.Enabled = false;
	end
end)

battleFrame.CancelChooseTarget.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		battleFrame.CancelChooseTarget.Round.UIGradient.Enabled = true;
	end
end)

--Action events--------------------
battleFrame.CancelChooseTarget.InputBegan:Connect(function(input)
	if debounce == false and (input.UserInputType == Enum.UserInputType.MouseButton1 or
		(input.UserInputType == Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseMovement)) then
		playBeepSFX();
		debounce = true;
		hideTurnOngoingFrame();
		showTurnPrepFrame();
		BlurOut();
		if enemySelectConnectionBegan then enemySelectConnectionBegan:Disconnect(); end
		if mouseCheckTargetEnemyConnection then mouseCheckTargetEnemyConnection:Disconnect(); end
		if partyMemberFrameMouseEnterConnectionsArr then
			for i,v in pairs(partyMemberFrameMouseEnterConnectionsArr) do
				v:Disconnect();
			end	
		end
		if partyMemberFrameMouseLeaveConnectionsArr then
			for i,v in pairs(partyMemberFrameMouseLeaveConnectionsArr) do
				v:Disconnect();
			end	
		end
		if partyMemberFrameInputBeganConnectionsArr then
			for i,v in pairs(partyMemberFrameInputBeganConnectionsArr) do
				v:Disconnect();
			end	
		end
		if skillFrameMouseEnterConnectionsArr then
			for i,v in pairs(skillFrameMouseEnterConnectionsArr) do
				v:Disconnect();
				warn("skillframemouseenterconnections disconnected");
			end	
		end
		if skillFrameMouseLeaveConnectionsArr then
			for i,v in pairs(skillFrameMouseLeaveConnectionsArr) do
				v:Disconnect();
				warn("skillframemouseleaveconnections disconnected");
			end	
		end
		if skillFrameInputBeganConnectionsArr then
			for i,v in pairs(skillFrameInputBeganConnectionsArr) do
				v:Disconnect();
				warn("skillframeinputbeganconnections disconnected");
			end	
		end
		cleanUpSkillScrollingFrameContents();
		tweenInActionFrame();
		tweenInCurrCharViewportFrame();
		if skillsButtonFrame.Position ~= UDim2.new(-1, 0, 0, 0) then
			tweenOutSkillsFrame();
		end
		battleFrame.CancelChooseTarget.Visible = false;
		if EncounterClient:DetermineButDoNotSetPreviousSelectedPlayerIndex() ~= -1 then
			backButtonFrame.Visible = true;
			warn("Visible. "..EncounterClient:DetermineButDoNotSetPreviousSelectedPlayerIndex());
		else
			backButtonFrame.Visible = false;
			warn("Invisible. "..EncounterClient:DetermineButDoNotSetPreviousSelectedPlayerIndex());
		end
		hideEnemyHealthBars();
		hideEnemySelectionPointers();
		EncounterClient:UpdateLogText("What will you do?");
		debounce = false;
	end	
end)

backButtonFrame.ButtonExtend.InputBegan:Connect(function(input)
	if debounce == false and (input.UserInputType == Enum.UserInputType.MouseButton1 or
		(input.UserInputType == Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseMovement)) then
		CAS:UnbindAction("PLRBUFFSDEBUFFS"); CAS:UnbindAction("PLRBATTLESTATS");
		debounce = true;
		--remove latest element from table and search for last able player. if there is no last able player
		local canDeterminePreviousIndex = EncounterClient:DetermineButDoNotSetPreviousSelectedPlayerIndex()
		if canDeterminePreviousIndex ~= -1 then
			local lastCommand = tempCommandArr[#tempCommandArr];
			local lastCommandTargets = lastCommand[3];
			local playerOrEnemyParty = lastCommand[4];
			if #lastCommandTargets == 1 and playerOrEnemyParty == "PlayerParty" then
				local targetIndex = lastCommandTargets[1];
				EncounterClient.PlayerParty.TeamMembers[targetIndex].ISBEINGDEFENDED = false;
			end
			table.remove(tempCommandArr, #tempCommandArr);
			tweenOutActionFrame();
			tweenOutCurrCharViewportFrame();
			local coro = coroutine.wrap(function()
				wait(.35);
				EncounterClient:DetermineAndSetPreviousSelectedPlayerIndex(false);
				warn("Went back. Index is now "..EncounterClient.CurrentSelectedPlayerIndex);
				--check to see if the undoed index matches with any first string letter from the tempdefendedarr
				for i = 1, #tempDefendedArr, 1 do -- might want to change this to a while loop
					local currStringCode = tempDefendedArr[i];
					warn("current string code: "..currStringCode);
					local defenderIndex = tonumber(string.sub(currStringCode, 1, 1));
					local defendedIndex = tonumber(string.sub(currStringCode, 2, 2));
					if defenderIndex == EncounterClient.CurrentSelectedPlayerIndex then
						warn("removing the following string code: "..currStringCode);
						table.remove(tempDefendedArr, i);
						--make the isbeingdefended value false. but first you need to access the defended's player object
						local defendedPlayerObj = findPlayerObjFromIndex(defendedIndex);
						defendedPlayerObj.ISBEINGDEFENDED = false;
						i = i - 1;--account for the array shift. 
					end
				end
				if EncounterClient:DetermineButDoNotSetPreviousSelectedPlayerIndex() ~= -1 then
					backButtonFrame.Visible = true;
					warn("Visible. "..EncounterClient:DetermineButDoNotSetPreviousSelectedPlayerIndex());
				else
					backButtonFrame.Visible = false;
					warn("Invisible. "..EncounterClient:DetermineButDoNotSetPreviousSelectedPlayerIndex());
				end
				tweenInActionFrame();
				tweenInCurrCharViewportFrame();	
				debounce = false;
				bindPlrBuffsDebuffs()
				bindPlrStats();
			end)
			coro();
		else
			--shouldn't be visible in the first place
			error("BACK BUTTON IS VISIBLE AND SHOULDN'T BE!");
		end
	end
end)

fightButtonFrame.ButtonExtend.InputBegan:Connect(function(input)
	if debounce == false and (input.UserInputType == Enum.UserInputType.MouseButton1 or
		(input.UserInputType == Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseMovement)) then
		debounce = true;
		CAS:UnbindAction("PLRBUFFSDEBUFFS");
		CAS:UnbindAction("PLRBATTLESTATS");
		tweenOutActionFrame();
		tweenOutCurrCharViewportFrame();
		local coro = coroutine.wrap(function()
			wait(.25);
			debounce = false;
			battleFrame.CancelChooseTarget.Visible = true;
		end)
		coro();
		SingleEnemy("Attack");
	end
end)

defendButtonFrame.ButtonExtend.InputBegan:Connect(function(input)--I WANT TO MAKE THE DEFEND BE TO CHOOSE TO DEFEND ONE PLAYER OR ONESELF
	if debounce == false and (input.UserInputType == Enum.UserInputType.MouseButton1 or
		(input.UserInputType == Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseMovement)) then
		debounce = true;
		CAS:UnbindAction("PLRBUFFSDEBUFFS");
		CAS:UnbindAction("PLRBATTLESTATS");
		tweenOutActionFrame();
		tweenOutCurrCharViewportFrame();
		local coro = coroutine.wrap(function()
			wait(.25);
			debounce = false;
			battleFrame.CancelChooseTarget.Visible = true;
		end)
		coro();
		DefendAction();
	end
end)

fleeButtonFrame.ButtonExtend.InputBegan:Connect(function(input)
	if debounce == false and (input.UserInputType == Enum.UserInputType.MouseButton1 or
		(input.UserInputType == Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseMovement)) then
		debounce = true;
		CAS:UnbindAction("PLRBUFFSDEBUFFS");
		CAS:UnbindAction("PLRBATTLESTATS");
		tweenOutActionFrame();
		tweenOutCurrCharViewportFrame();
		local coro = coroutine.wrap(function()
			warn("flee")
			wait(.35);
			FleeAction();
			--tweenInActionFrame();
			--tweenInCurrCharViewportFrame();
			debounce = false;
		end)
		coro();
	end
end)

skillsButtonFrame.ButtonExtend.InputBegan:Connect(function(input)
	if debounce == false and (input.UserInputType == Enum.UserInputType.MouseButton1 or
		(input.UserInputType == Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseMovement)) then
		debounce = true;
		CAS:UnbindAction("PLRBUFFSDEBUFFS");
		CAS:UnbindAction("PLRBATTLESTATS");
		tweenOutActionFrame();
		EncounterClient:UpdateLogText("Choose a skill.");
		local coro = coroutine.wrap(function()
			wait(.25);
			debounce = false;
			battleFrame.CancelChooseTarget.Visible = true;
		end)
		coro();
		local currentPlayerObj = EncounterClient.PlayerParty.TeamMembers[EncounterClient.CurrentSelectedPlayerIndex];
		local skillsArr = EncounterClient:CompileSkills(currentPlayerObj);
		cleanUpSkillScrollingFrameContents();--clean the scrollingframe up first
		skillFrameInputBeganConnectionsArr = {};
		skillFrameMouseEnterConnectionsArr = {};
		skillFrameMouseLeaveConnectionsArr = {};
		--warn(skillsArr);
		for i,v in pairs(skillsArr) do--fill up the scrollingframe with skillframes
			local descText = skillsFrame.SkillDescFrame.Frame.Description;
			local currAction = v;
			local newSkillFrame = uiStorageFolder:WaitForChild("SkillFrame"):Clone();
			newSkillFrame.Name = tostring(i);
			newSkillFrame.IconFrame.Icon.Image = currAction.Image;
			newSkillFrame.SkillText.Text = currAction.Name;
			newSkillFrame.MPCostFrame.MPCostText.Text = tostring(currAction.MPCost);
			newSkillFrame.Parent = skillsListScrollingFrame;
			local skillFrameGradientCoro = coroutine.wrap(function()
				while newSkillFrame:FindFirstChild("Highlight") do
					for i = -.5, .25, .01 do
						if newSkillFrame:FindFirstChild("Highlight") and newSkillFrame:WaitForChild("Highlight").UIGradient:GetAttribute("GradientAnimPlaying") == true then
							--update desc text
							descText.Text = currAction.Description;
							newSkillFrame:WaitForChild("Highlight").Visible = true;
							newSkillFrame:WaitForChild("Highlight").UIGradient.Offset = Vector2.new(i, 0);
						else
							if newSkillFrame:FindFirstChild("Highlight") == nil then
							else
								newSkillFrame.Highlight.Visible = false;	
							end
							break;
						end
						RunService.Heartbeat:Wait();	
					end
					RunService.Heartbeat:Wait();
					for i = .25, -.5, -.01 do
						if newSkillFrame:FindFirstChild("Highlight") and newSkillFrame:WaitForChild("Highlight").UIGradient:GetAttribute("GradientAnimPlaying") == true then
							--update desc text
							descText.Text = currAction.Description;
							newSkillFrame:WaitForChild("Highlight").Visible = true;
							newSkillFrame:WaitForChild("Highlight").UIGradient.Offset = Vector2.new(i, 0);
						else
							if newSkillFrame:FindFirstChild("Highlight") == nil then
							else
								newSkillFrame.Highlight.Visible = false;	
							end
							break;
						end
						RunService.Heartbeat:Wait();	
					end
					RunService.Heartbeat:Wait();
				end
			end)
			skillFrameGradientCoro();
			local skillFrameMouseEnterConnection = newSkillFrame.MouseEnter:Connect(function()
				newSkillFrame:WaitForChild("Highlight").UIGradient:SetAttribute("GradientAnimPlaying", true); 
				warn("set gradientanimplaying to true");
			end)
			table.insert(skillFrameMouseEnterConnectionsArr, skillFrameMouseEnterConnection);
			local skillFrameMouseLeaveConnection = newSkillFrame.MouseLeave:Connect(function()
				newSkillFrame:WaitForChild("Highlight").UIGradient:SetAttribute("GradientAnimPlaying", false); 
				descText.Text = "Hover over a skill for more info.";
				warn("set gradientanimplaying to false");
			end)
			table.insert(skillFrameMouseLeaveConnectionsArr, skillFrameMouseLeaveConnection);
			local skillFrameInputBeganConnection = newSkillFrame.InputBegan:Connect(function(input, GPE)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch and debounce == false then
					--determine if currentselectedplayer has enough mp for the skill
					local currPlayer = EncounterClient.PlayerParty.TeamMembers[EncounterClient.CurrentSelectedPlayerIndex];
					local currPlayerMP = currPlayer.CURRMP;
					local currActionMPReq = currAction.MPCost;
					if currPlayerMP - currActionMPReq >= 0 then -- can choose target
						debounce = true;
						playBeepSFX();	
						tweenOutCurrCharViewportFrame();
						tweenOutSkillsFrame();
						--determine action's target type
						local targetType = currAction.TargetType;
						if targetType == "SINGLEENEMY" then
							SingleEnemy(currAction.Name);
						elseif targetType == "SPLASHENEMY" then
							SplashEnemy(currAction.Name);
						elseif targetType == "ALLENEMY" then
							AllEnemy(currAction.Name);
						elseif targetType == "SINGLEPARTY" then
							SingleParty(currAction.Name);
						elseif targetType == "ALLPARTY" then
							AllParty(currAction.Name);
						elseif targetType == "SELF" then
							Self(currAction.Name);
						end
						local coro = coroutine.wrap(function()
							wait(.25);
							debounce = false;
						end)
						coro();
					else -- not enough mp
						playDenySFX();
					end
				end
			end)
			table.insert(skillFrameInputBeganConnectionsArr, skillFrameInputBeganConnection);
		end
		tweenInSkillsFrame();
	end
end)

--remote event connections---------------------------------------------------------------------------------------------------------------------
remoteEventsFolder.BattleSystem.InvokePartyInfoChangeToClient.OnClientEvent:Connect(function(EncounterServer)
	--print(EncounterClient.PlayerParty.TeamMembers);
	EncounterClient:UpdateInfo(EncounterServer);
	--print(EncounterClient.PlayerParty.TeamMembers);
end)

remoteEventsFolder.BattleSystem.SendFleeResult.OnClientEvent:Connect(function(bool, initIndx)
	battleOverBool = bool;
	fleeSuccessIndx = initIndx;
end)

remoteEventsFolder.BattleSystem.BeginClientInterpretation.OnClientEvent:Connect(function(EncounterServer, clientInterpretation) -- clientInterpretation is an array of long strings. might want to make this a coroutine
	--print(clientInterpretation); -- verify that intepretation data is proper
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
					- ~POINTTARGETS<(targetPartyIndex#isPlayerParty...)>: the targets to put pointers on
					- ~ICMD<actionName,(targetPartyIndex#isPlayerParty#dmgAmnt#isCrit...),isHealing,isSupportSpell,imbuedElement,damageType>: Initiator Command. Attack miss if dmgAmnt == "MISS" if not applicable, dmgAmnt is NONE
					- ~LTXT<logTxt>: Log Text
					- ~ACOST<amount(HP/MP)>: Action Cost (select either HP or MP) or NONE
					- ~AFTERMATH<(true/false),hpAmnt>: Aftermath damage or NONE
					- ~DUR<seconds>: How long you have to wait for it to automatically continue
					- ~SFX<soundName,vol,timePos>: Looks for soundName in LocalPlayer.PlayerGui.LocalSFX folder
					- ~SFXFROMACTION<actionName,int>: Plays appropriate hit or cast SFX given action name. 0 is cast while 1 is hit
					- ~AFMTH<targetPartyIndex#isPlayerParty#dmgAmnt>: aftermath damage for one party member
				Example:
					- "~IID<2,true>~ICMD<Attack,(3#false#4),false,false,false,WEAPON,WEAPON>~LTXT<Bob attacks! Radical Radish C takes 4 damage!>~ACOST<NONE>~AFTERMATH<false,NONE>~DUR<1>~SFX<Hit,.8,0>"
				
		--]]

	-- 2542,sgf,2534,23
	-- 342,421


	local function extractCommaSeperatedValuesParenthesis(str)
		local result = {};
		local i = 1;
		local lastCutPoint = 1;
		local insideParenthesis = false;
		while i <= string.len(str) do
			local currChar = string.sub(str, i, i);
			if currChar == "(" then insideParenthesis = true; end if currChar == ")" then insideParenthesis = false; end
			if currChar == "," and insideParenthesis == false then -- append all values before the comma into the result arr
				local thingToAppend = string.sub(str, lastCutPoint, i-1);
				table.insert(result, thingToAppend);
				lastCutPoint = i + 1;
			end
			i = i + 1;
		end
		local lastThingToAppend = string.sub(str, lastCutPoint, string.len(str));
		table.insert(result, lastThingToAppend)
		return result;
	end
	local function extractHashSeperatedValues(str)
		local result = {};
		local i = 1;
		local lastCutPoint = 1;
		while i <= string.len(str) do
			local currChar = string.sub(str, i, i);
			if currChar == "#" then -- append all values before the comma into the result arr
				local thingToAppend = string.sub(str, lastCutPoint, i-1);
				table.insert(result, thingToAppend);
				lastCutPoint = i + 1;
			end
			i = i + 1;
		end
		local lastThingToAppend = string.sub(str, lastCutPoint, string.len(str));
		table.insert(result, lastThingToAppend)
		return result;
	end
	local function extractContents(interpretationElem, lookFor)
		-- look for lookFor if exists
		local txtStart, txtEnd = string.find(interpretationElem, lookFor);
		if txtStart and txtEnd then
			-- get contents of angle bracket
			local contentStart = txtEnd + 2;
			local contentEnd = string.find(interpretationElem, ">", contentStart) - 1;
			local contents = string.sub(interpretationElem, contentStart, contentEnd);
			if lookFor == "~ACOST" then
				-- separate the number portion from the MP portion
				local start = string.find(contents, "MP");
				if start then
					local numberPortion = string.sub(contents, 1, start - 1);
					local strPortion = string.sub(contents, start, string.len(contents));
					--warn(strPortion)
					return table.pack(numberPortion, strPortion);
				end
				--print("~ACOST found but start not found");
			elseif lookFor == "~AFMTH" then -- this one has 3 params: target party index, isplayerparty bool, and dmg amount
				--separate hashes from and return as table.pack
				return extractHashSeperatedValues(contents); -- this function table.packs it
			elseif lookFor == "~IID" or lookFor == "~SFXFROMACTION" or lookFor == "~POINTTARGETS" or lookFor == "~ENDEATH" or lookFor == "~DOT" or lookFor == "~UPDTPLRFRMSTATUS" then
				--separate commas from and return as table.pack
				return util:ExtractCSV(contents); -- this function table.packs it
			elseif lookFor == "~ICMD" then -- separate commas BUT ignore the ones that have a parenthesis to the left and right
				return extractCommaSeperatedValuesParenthesis(contents);				
			end
			--print(contents)
			return contents;
		end
		-- print("txtStart is "..tostring(txtStart)); print("txtEnd is "..tostring(txtEnd)); print("lookFor is "..tostring(lookFor));
		return nil;
	end
	-- iterate through client interpretation
	for i,v in pairs(clientInterpretation) do
		local currInterpretation = v;
		--now for comma separated ones
		local initIndex, isPlrParty;
		if extractContents(currInterpretation, "~IID") then
			initIndex, isPlrParty = unpack(extractContents(currInterpretation, "~IID"));
			--print(initIndex..isPlrParty);
		end	
		local defeatedEnemyIndices = extractContents(currInterpretation, "~ENDEATH");
		if defeatedEnemyIndices then
			--print(defeatedEnemyIndices);
			-- ashify enemy models at these indices
			for i,v in pairs(defeatedEnemyIndices) do
				local currEnemyIndex = tonumber(v);
				local currEnemyModel = findEnemyModelFromIndex(currEnemyIndex);
				if currEnemyModel and currEnemyModel:GetAttribute("Ashified") == false then
					currEnemyModel:SetAttribute("Ashified", true);
					EncounterClient:EnemyDeathEffect(currEnemyModel);
				else
					error("Cannot find enemy model to ashify from index!");
				end
			end
		end
		-- look for action cost if exists
		--print(extractContents(currInterpretation, "~ACOST"))
		local actionCostIntTxt, MPTxt;
		if extractContents(currInterpretation, "~ACOST") then -- since it is mp only, it is only for player party members
			actionCostIntTxt, MPTxt = table.unpack(extractContents(currInterpretation, "~ACOST"));
			--print(actionCostIntTxt.." of "..MPTxt); 
			-- do damage indication
			-- but first lets turn the intendedTargets string into an array
			-- ~ACOST interpretation string should also have ~IID
			local playerFrame = partyFrame:WaitForChild(tostring(initIndex));
			if isPlrParty == "false" then error("Enemy party member cannot have ~ACOST!"); end
			EncounterClient:ApplyPlayerFrameDamageIndication(playerFrame, actionCostIntTxt, false, false, "MP", false, false, "NONE"); -- take care of HPORMP in ACOST
		end
		--now for hash separated ones
		-- look for aftermath damage if exists
		local aftermthInitIndex, aftermthInitIsPlrParty, aftermthDmg;
		local aftermthTxt = extractContents(currInterpretation, "~AFMTH");
		if aftermthTxt then
			aftermthInitIndex, aftermthInitIsPlrParty, aftermthDmg = table.unpack(aftermthTxt); print(aftermthInitIndex..aftermthInitIsPlrParty..aftermthDmg);
			if util:DestringifyBool(aftermthInitIsPlrParty) == true then -- initiator is player party member
				local playerFrame = partyFrame:WaitForChild(aftermthInitIndex);
				EncounterClient:ApplyPlayerFrameDamageIndication(playerFrame, tonumber(aftermthDmg), false, false, "HP", false, false, "NONE"); -- take care of HPORMP in ACOST
			elseif util:DestringifyBool(aftermthInitIsPlrParty) == false then -- initiator is enemy party member
				local enemyModel = findEnemyModelFromIndex(tonumber(aftermthInitIndex));
				EncounterClient:ApplyEnemyModelDamageIndication(enemyModel, tonumber(aftermthDmg), false, false, false, "NONE"); -- will add in imbued element in the future for cool effects
			else
				error("aftermthInitIsPlrParty is not a bool!");
			end	
			audioPlayerClient(lPlr, localSFXFolder:WaitForChild("Hit"), 0, false);
		end
		if extractContents(currInterpretation, "~UPDTPLRFRMSTATUS") then
			local plrFrmIndx = extractContents(currInterpretation, "~UPDTPLRFRMSTATUS")[1];
			local stat = extractContents(currInterpretation, "~UPDTPLRFRMSTATUS")[2];
			partyFrame:WaitForChild(plrFrmIndx).StatusEffect.Value = stat;
			partyFrame[plrFrmIndx].StatusFrame.LevelFrame.Visible = false;
			partyFrame[plrFrmIndx].StatusFrame.StatusEffect.Visible = true;
			partyFrame[plrFrmIndx].StatusFrame.StatusEffect.Image = StatusEffectIcons[stat];
			partyFrame[plrFrmIndx].StatusFrame.StatusEffect.ImageColor3 = StatusEffectIcons[stat.."COLOR"];
		end
		--now for ICMD (don't get rid of hash for ease of use)
		local actionName, hitTargets, intendedTargets, isHealing, imbuedElement;

		local cmdContents = extractContents(currInterpretation, "~ICMD");
		if cmdContents then
			actionName, hitTargets, intendedTargets, isHealing, imbuedElement = unpack(cmdContents);
			local hitTargetsArr = util:ExtractCSV(hitTargets);
			-- get rid of the parenthesis for hitTargets and intendedTargets
			if hitTargets == "()" then hitTargets = ""; 
			else
				hitTargets = string.sub(hitTargets,2,#hitTargets - 1);
			end
			if intendedTargets == "()" then intendedTargets = ""; 
			else
				intendedTargets = string.sub(intendedTargets,2,#intendedTargets - 1);
			end
			print(actionName.." | "..hitTargets.." | "..intendedTargets.." | "..isHealing.." | "..imbuedElement);
			-- do damage indication
			-- but first lets turn the intendedTargets string into an array
			intendedTargets = util:ExtractCSV(intendedTargets);
			for x,y in pairs(intendedTargets) do
				local currElem = y; -- example of what it looks like: 8#false#MISS#false#POISONED
				local indexOfFirstHash = string.find(currElem, "#", 1);
				local indexOfSecondHash = string.find(currElem, "#", indexOfFirstHash + 1);
				local indexOfThirdHash = string.find(currElem, "#", indexOfSecondHash + 1);
				local indexOfFourthHash = string.find(currElem, "#", indexOfThirdHash + 1);
				local indexInfo = string.sub(currElem, 1, indexOfFirstHash - 1);
				local isPlrPartyInfo = util:DestringifyBool(string.sub(currElem, indexOfFirstHash + 1, indexOfSecondHash - 1));
				local dmgInfo = string.sub(currElem, indexOfSecondHash + 1, indexOfThirdHash - 1); -- keep this as string for now
				local critBoolInfo = util:DestringifyBool(string.sub(currElem, indexOfThirdHash + 1, indexOfFourthHash - 1));
				local statusEffectInfo = string.sub(currElem, indexOfFourthHash + 1, #currElem); 
				local actionsModuleToSearch; -- determined by whether initiator is player or enemy
				print(statusEffectInfo)

				-- check for guardian in index info
				local guardianInfo;
				local ampersandIndex = string.find(indexInfo, "&");
				if ampersandIndex ~= nil then -- if guardian exists
					--print(ampersandIndex);
					guardianInfo = string.sub(indexInfo, ampersandIndex+1, #indexInfo);
					--replace intended target with guardian if initiator is opposite party
					local targetIsPlrParty = isPlrPartyInfo;
					local initiatorPartyBool = util:DestringifyBool(isPlrParty);
					if (targetIsPlrParty == true and initiatorPartyBool == true) or (targetIsPlrParty == false and initiatorPartyBool == false) then -- target and initiator are same party 
						-- don't replace indexInfo. Instead get rid of everything from the ampersand onwards. This is to prevent an ally taking the buffs/heals
						indexInfo = string.sub(indexInfo, 1, ampersandIndex - 1);	
					else
						-- check if guardian is dead. Let's make it such that only players can be guardians
						if partyFrame:WaitForChild(tostring(guardianInfo)).StatusEffect.Value == "DEAD" or partyFrame:WaitForChild(tostring(guardianInfo)).StatusEffect.Value == "FROZEN" then							
							indexInfo = string.sub(indexInfo, 1, ampersandIndex - 1);
							print("Index",indexInfo,"not changed because guardian at index",guardianInfo,"is dead");
						else
							print(partyFrame:WaitForChild(tostring(guardianInfo)).StatusEffect.Value);
							-- replace indexInfo
							print("Index",indexInfo,"to be replaced with",guardianInfo);
							indexInfo = guardianInfo;	

						end 
					end
				end
				indexInfo = tonumber(indexInfo);
				--print(tostring(indexInfo).."="..util:StringifyBool(isPlrPartyInfo).."="..dmgInfo.."="..util:StringifyBool(critBoolInfo));
				local damageMethod;
				local isSupport;
				local removeStatusEffect;
				local damageWaitDelay;
				if isPlrParty == "false" then 
					actionsModuleToSearch = EnemyActionsList; 
				elseif isPlrParty == "true" then
					actionsModuleToSearch = PlayerActionsList;  
				else error("isPlrParty is a bool!"); end
				--print(actionsModuleToSearch)
				damageWaitDelay = actionsModuleToSearch[actionName]["DAMAGEWAITDELAY"];
				isSupport = actionsModuleToSearch[actionName]["ISSUPPORTSPELL"];
				removeStatusEffect = actionsModuleToSearch[actionName]["REMOVESTATUSEFFECT"]
				if isPlrPartyInfo == true and (dmgInfo ~= "IGNORE" and dmgInfo ~= "ABORTED") then -- target is player, search in enemy actions unless initiator is player
					local playerFrame = partyFrame:WaitForChild(tostring(indexInfo));
					EncounterClient:ApplyPlayerFrameDamageIndication(playerFrame, dmgInfo, critBoolInfo, isHealing, "HP", isSupport, actionsModuleToSearch[actionName]['ISREVIVALSKILL'], statusEffectInfo); -- take care of HPORMP in ACOST
				elseif isPlrPartyInfo == false and (dmgInfo ~= "IGNORE" and dmgInfo ~= "ABORTED") then -- target is enemy, search in player actions
					local enemyModel = findEnemyModelFromIndex(indexInfo)
					-- before showing damage indication, add delay to show attack effect before damaging
					local attackAction = actionsModuleToSearch[actionName];
					--print(attackAction);
					damageMethod = attackAction['DAMAGETYPE']
					local imbuedElement = attackAction['IMBUEDELEMENT']
					-- implement changing damageMethod based on weapon type later
					-- get initator's weapon if existent
					if damageMethod == "WEAPON" then
						local initPlr = EncounterClient.PlayerParty.TeamMembers[tonumber(initIndex)];
						--print(initPlr, EncounterClient.PlayerParty.TeamMembers, EncounterClient.PlayerParty);
						damageMethod = initPlr.WEAPON['DAMAGETYPE'];
					end
					coroutine.wrap(function() -- be careful of this coro
						--print("slash")
						bindableEventsFolder.AttackEffect:Fire(damageMethod, enemyModel, imbuedElement);

						wait(.25/EncounterClient.LogSpeedMult);
						EncounterClient:ApplyEnemyModelDamageIndication(enemyModel, dmgInfo, critBoolInfo, util:DestringifyBool(isHealing), isSupport, statusEffectInfo); -- will add in imbued element in the future for cool effects. Remember to add statusEffectName later!
					end)()
				else
					-- error("isPlrPartyInfo is not a bool!");
				end	
				if tonumber(dmgInfo) ~=nil and tonumber(dmgInfo) ~= 0 then -- successful hit
					--set volume values
					local adjustedVolume = .5;
					if actionsModuleToSearch[actionName]['DAMAGEWAITDELAY'] == 0 and #hitTargetsArr > 1 then
						--look at number of targets and decrease volume accordingly to avoid earrape from amplified sounds
						adjustedVolume = adjustedVolume / ((#hitTargetsArr * .1) + 1) ;
					end
					--warn(adjustedVolume.." "..tostring(actionsModuleToSearch[actionName]['DAMAGEWAITDELAY']).." "..tostring(#hitTargetsArr));
					local impactSound;
					local action = actionsModuleToSearch[actionName];
					if util:DestringifyBool(isHealing) == false and not isSupport then -- non crit damage hit
						if damageMethod == "CRUSH" then
							impactSound = localSFXFolder.CrushSound;
						elseif damageMethod == "SLASH" then
							impactSound = localSFXFolder.SlashHit;
						elseif damageMethod == "STAB" then
							impactSound = localSFXFolder.StabSound;
						else
							impactSound = localSFXFolder.Hit;
						end
						if critBoolInfo == true then -- if crit then play crit sound too
							local critSound = localSFXFolder.Crit;
							--critSound.Volume = adjustedVolume;
							audioPlayerClient(lPlr, critSound, 0, false);
						end	
					elseif util:DestringifyBool(isHealing) == true then -- healing hit
						impactSound = localSFXFolder.Recover;
					else--recoil damage or support spell
						if action and isSupport then -- support spells provide buffs to allies
							-- leave blank for now. play buff grant sound
							impactSound = localSFXFolder.NONE; -- sound is played elsewhere
						else
							print(action, isSupport);
							impactSound = localSFXFolder.Hit; -- for all other unknown cases...
						end
					end
					if impactSound then
						if isSupport == true and util:DestringifyBool(isHealing) == false then
						else
							impactSound.Volume = adjustedVolume;
							audioPlayerClient(lPlr, impactSound, 0, false);	
						end
					end
				elseif (isPlrPartyInfo == true and util:DestringifyBool(isPlrParty) == true) or (isPlrPartyInfo == false and util:DestringifyBool(isPlrParty) == false) then -- target and initiator are same party, do nothing. otherwise, miss
					if util:DestringifyBool(isHealing) == true then -- healing hit guardian, redirected hit
						audioPlayerClient(lPlr, localSFXFolder:WaitForChild("Recover"), 0, false);
						-- add is support elseif in the future
					end
				else
					if dmgInfo == "IGNORE" or dmgInfo == "ABORTED" then
					else
						audioPlayerClient(lPlr, localSFXFolder:WaitForChild("ATK12MISS12"), 3.5, false);
						--warn("PLAYED EVADE SOUND");
					end
				end

				if dmgInfo == "IGNORE" or dmgInfo == "ABORTED" then
					-- don't wait
				elseif damageWaitDelay > 0 and x ~= #intendedTargets then 
					wait(damageWaitDelay);
				end
			end
		end
		--this one is comma and hash separated, but don't get rid of hash for ease of use!
		local pointTargetsArr; -- example elem: 2#true (index 2 of player party)
		local pointTargetsContents = extractContents(currInterpretation, "~POINTTARGETS");
		if pointTargetsContents then
			pointTargetsArr = pointTargetsContents;
			--print(pointTargetsArr);
			for i,v in pairs(pointTargetsArr) do
				local hashIndex = string.find(v, "#");
				local pointIndex = tonumber(string.sub(v, 1, hashIndex - 1));
				local pointBool = util:DestringifyBool(string.sub(v, hashIndex + 1, #v));
				if pointBool then
					--access the partyframe
					local playerMemberFrame = partyFrame:WaitForChild(tostring(pointIndex));
					EncounterClient:ShowPlayerModelTargetPointer(playerMemberFrame, util:DestringifyBool(isPlrParty));
				elseif pointBool == false then
					--access enemy model
					local enemyModel = findEnemyModelFromIndex(pointIndex);
					EncounterClient:ShowEnemyModelTargetPointer(enemyModel, util:DestringifyBool(isPlrParty));	
				end
			end
			if isPlrParty == "false" then -- show initiator enemy red circle thing
				EncounterClient:ShowEnemyModelInitiatorPointer(findEnemyModelFromIndex(tonumber(initIndex)));
				--warn("showing enemy init ring");
			else
				-- do nothing
			end
		end
		local dotArr;
		local dotContents = extractContents(currInterpretation, "~DOT");
		if dotContents then
			dotArr = dotContents;
			for key,value in pairs(dotArr) do
				local firstHashIndx = string.find(value, "#");
				local secondHashIndx = string.find(string.sub(value, firstHashIndx + 1), "#") + firstHashIndx;
				local thirdHashIndx = string.find(string.sub(value, secondHashIndx + 1), "#") + secondHashIndx;
				local currMemberIndx = tonumber(string.sub(value, 1, firstHashIndx - 1));
				local currBool = util:DestringifyBool(string.sub(value, firstHashIndx + 1, secondHashIndx - 1)); -- bool for whether victim is from player party	
				local currDmg = tonumber(string.sub(value, secondHashIndx + 1, thirdHashIndx - 1));
				if currBool == true then -- is player
					local playerFrame = partyFrame:WaitForChild(tostring(currMemberIndx));
					EncounterClient:ApplyPlayerFrameDamageIndication(playerFrame, tostring(currDmg), false, "false", "HP", false, false, "NONE"); 
				else -- is enemy
					local enemyModel = findEnemyModelFromIndex(tonumber(currMemberIndx));
					EncounterClient:ApplyEnemyModelDamageIndication(enemyModel, tonumber(currDmg), false, false, false, "NONE"); 
				end

				-- sound effects
				local adjustedVolume = .5;
				if #dotArr > 1 then
					--look at number of targets and decrease volume accordingly to avoid earrape from amplified sounds
					adjustedVolume = adjustedVolume / ((#dotArr * .1) + 1) ;
				end				
				local impactSound = localSFXFolder.Hit;
				impactSound.Volume = adjustedVolume;
				audioPlayerClient(lPlr, impactSound, 0, false);
			end
		end

		local actionName, soundTypeInt;
		local sfxFromActionContents = extractContents(currInterpretation, "~SFXFROMACTION");
		if sfxFromActionContents then
			actionName, soundTypeInt = unpack(sfxFromActionContents);
			--print(actionName..soundTypeInt);
			-- play sound given action name and sound type. But first decide which module to search
			local actionModuleToSearch;
			if isPlrParty == "true" then 
				actionModuleToSearch = PlayerActionsList; 
			elseif isPlrParty == "false" then
				actionModuleToSearch = EnemyActionsList;
			else
				error("isPlrParty is not a string!");
			end	
			if actionName == "YEET" then
				-- add a bit of delay
				local coro = coroutine.wrap(function()
					wait(.5 / EncounterClient.LogSpeedMult);
					audioPlayerClient(lPlr, localSFXFolder:WaitForChild('YEET'), 0, false);
					warn("YEET!");
				end)
				coro();
			elseif actionName == "Poison Fart" then
				coroutine.wrap(function()
					wait(.5 / EncounterClient.LogSpeedMult);
					audioPlayerClient(lPlr, localSFXFolder:WaitForChild('Fart'), 0, false);
				end)()
			elseif actionName == "Defend" then
				audioPlayerClient(lPlr, localSFXFolder:WaitForChild('DefendSound'), 0, false);
			end
			if soundTypeInt == "0" then -- casting sound
				if actionModuleToSearch[actionName]['ISSKILL'] == true then
					-- play cast sfx
					audioPlayerClient(lPlr, localSFXFolder:WaitForChild("Skill"), 0, false);
					warn("play sfx")
				else
					-- play nothing
				end
				-- this is actually problematic. do the hit sounds in ~ICMD
			end
		end
		-- look for log text if exists
		local logTxt = extractContents(currInterpretation, "~LTXT"); -- will be nil if  ~LTXT not found
		if logTxt then
			-- display log text
			updateLogText(logTxt);
			-- search iniator model for action anim
			if isPlrParty == "false" then
				local enemyModel = findEnemyModelFromIndex(tonumber(initIndex));
				if enemyModel and actionName then
					EncounterClient:PlayEnemyActionAnim(enemyModel, actionName)					
				end
			end
			-- if log text displays flee text, then send flee request to server
			if string.find(logTxt, PlayerActionsList['Flight']['LOGFLAVOR']) then
				audioPlayerClient(lPlr, localSFXFolder:WaitForChild('Run'), 0, false);
				if battleOverBool == true and tonumber(initIndex) == tonumber(fleeSuccessIndx) then
					remoteEventsFolder.BattleSystem.FleeSuccess:FireServer();
					return;
				else
					--print(battleOverBool == true, tonumber(initIndex) == tonumber(fleeSuccessIndx))
					-- fail flee. log flee failure
					wait(tonumber(.9) / EncounterClient.LogSpeedMult);
					updateLogText("But the party could not escape!");
					wait(tonumber(.6) / EncounterClient.LogSpeedMult);
				end
			end
			--print(logTxt);
		end
		-- look for wait time last because it should be last
		local durTxt = extractContents(currInterpretation, "~DUR");
		if durTxt then
			-- yield for the client
			wait(tonumber(durTxt) / EncounterClient.LogSpeedMult);
			--print(durTxt); 
		end
	end
	wait(.5);
	-- send signal back to server that client has finished watching
	remoteEventsFolder.BattleSystem.FinishClientInterpretation:FireServer();
end)

remoteEventsFolder.BattleSystem.InitializeBattleSceneClient.OnClientEvent:Connect(function(EncounterServer)--might want a battleid in future	
	battleOverBool = false;
	fleeSuccessIndx = -1;
	-- coroutines need to be initialized every time they are used
	battleMenuActionIconGradientAnim = coroutine.wrap(function()
		while battleFrame.Visible do
			for i = -.8, 1, .01 do
				actionsFrame.BurstAction.ButtonExtend.Round.Icon.UIGradient.Offset = Vector2.new(i, 0);
				actionsFrame.DefendAction.ButtonExtend.Round.Icon.UIGradient.Offset = Vector2.new(i, 0);
				actionsFrame.FightAction.ButtonExtend.Round.Icon.UIGradient.Offset = Vector2.new(i, 0);
				actionsFrame.FleeAction.ButtonExtend.Round.Icon.UIGradient.Offset = Vector2.new(i, 0);
				actionsFrame.BackAction.ButtonExtend.Round.Icon.UIGradient.Offset = Vector2.new(i, 0);
				actionsFrame.ItemsAction.ButtonExtend.Round.Icon.UIGradient.Offset = Vector2.new(i, 0);
				actionsFrame.SkillsAction.ButtonExtend.Round.Icon.UIGradient.Offset = Vector2.new(i, 0);
				RunService.Heartbeat:Wait();	
			end
			RunService.Heartbeat:Wait();
		end
	end)

	partyMemberFrameHighlightGradientAnim = coroutine.wrap(function()
		for j,k in pairs(partyFrame:GetChildren()) do
			local playerHighlightCoro = coroutine.wrap(function()
				while battleFrame.Visible do
					for i = -1, 1, .01 do
						k.Round.Highlight.UIGradient.Offset = Vector2.new(0, i);
						RunService.Heartbeat:Wait();
					end	
				end
			end)
			local playerTargetPointerHighlightCoro = coroutine.wrap(function()
				while battleFrame.Visible do
					for i = -.8, 1, .01 do
						k.SwordIcon.UIGradient.Offset = Vector2.new(0, i);
						RunService.Heartbeat:Wait();	
					end	
				end
			end)
			playerTargetPointerHighlightCoro();
			playerHighlightCoro();
		end
	end)


	defaultColorCorrection = PPEFolder.DefaultColorCorrection:Clone();
	defaultBlur = PPEFolder.DefaultBlur:Clone();
	defaultColorCorrection.Parent = workspace.CurrentCamera;
	defaultBlur.Parent = workspace.CurrentCamera;

	tempCommandArr = {};
	tempDefendedArr = {};

	EncounterClient = BattleSceneClient();
	print(EncounterServer.IsBossFight);
	EncounterClient:UpdateInfo(EncounterServer); -- loads in info from server
	worldMusic:Pause();

	if EncounterClient.IsBossFight then
		opBossMusic:Play()
	else
		battleMusic:Play();
		print(EncounterClient.IsBossFight)
	end

	--warn(EncounterClient.PlayerParty.TeamMembers);
	EncounterClient.AutoBattle = "OFF";
	EncounterClient.LogSpeedMult = 1;
	--prespawn enemies so player can see them. server side wont see them.
	EncounterClient:SpawnEnemies(mouse);
	EncounterClient:SpawnPlayerParty();
	BattleFadeIn();
	wait(1);
	BattleFadeOut();
	EncounterClient:InitializeUI(partyFrame, uiStorageFolder.PartyMemberFrame);
	SetClockScrollingText("6 AM  |  IN BATTLE  |  TURN "..EncounterClient.TurnNumber.."  |  AUTO "..EncounterClient.AutoBattle);
	EncounterClient:UpdateLogText("Monsters appear!");
	InitializeBattleCamera();
	ShowBattleUI();
	EncounterClient:UpdatePartyUIInfo(); 
	wait(2);
	tweenInActionFrame(); tweenInPartyFrame(); tweenInCurrCharViewportFrame();
	EncounterClient:UpdateLogText("What will you do?");
	battleFrame.TurnOngoing.Log.TextYAlignment = Enum.TextYAlignment.Center;
	bindAuto();
end)

remoteEventsFolder.BattleSystem.DeinitClient.OnClientEvent:Connect(function() -- do deinit here
	CAS:UnbindAction("AUTOBATTLE"); CAS:UnbindAction("PLRBUFFSDEBUFFS");
	CAS:UnbindAction("PLRBATTLESTATS");
	-- cleanse stat effects in player frame
	for i,v in pairs(partyFrame:GetChildren()) do
		if v:WaitForChild("StatusEffect").Value ~= "DEAD" then
			v.StatusEffect.Value = "NONE";
		end
	end
	fleeSuccessIndx = -1;
	BattleFadeIn();
	hideTurnOngoingFrame();
	tweenOutPartyFrame();
	wait(1);
	battleMusic:Stop(); opBossMusic:Stop();
	worldMusic:Resume();
	BattleFadeOut();
	HideBattleUI();
	ResetCamera();
	SetClockScrollingText("6 AM  |  IN TWILIGHT FOREST  |  PARTY MORALE: 100 (EXCELLENT)  |  PRESS M FOR MENU");
	actionsFrame.BackAction.Visible = false;
	hideTurnOngoingFrame();
	showTurnPrepFrame();
	tweenOutPartyFrame();
	EncounterClient:ClearEnemyModels();
	EncounterClient:ClearPlayerModels();
	EncounterClient = nil; -- might not want to do this
	debounce = false;
	handleActionDebounce = false;
	autoBattleDebounce = false;
	mouse.TargetFilter = {};
	tempCommandArr = nil;
	tempDefendedArr = nil;

	initializeBattleCameraConnection = nil;
	enemySelectConnectionBegan = nil;
	defaultColorCorrection:Destroy();
	battleMenuActionIconGradientAnim = nil;
	mouseCheckTargetEnemyConnection = nil;
	partyMemberFrameMouseEnterConnectionsArr = nil;
	partyMemberFrameMouseLeaveConnectionsArr = nil;
	partyMemberFrameInputBeganConnectionsArr = nil;
	skillFrameInputBeganConnectionsArr = nil; 
	skillFrameMouseEnterConnectionsArr = nil;
	skillFrameMouseLeaveConnectionsArr = nil;


end)

remoteEventsFolder.BattleSystem.UpdateBattleLogText.OnClientEvent:Connect(function(newText)
	EncounterClient:UpdateLogText(newText);
end)

remoteEventsFolder.BattleSystem.PlayAppropriateInitiateAttackSFX.OnClientEvent:Connect(function(action)
	if action and action.IsSkill and action.IsSkill == true then
		audioPlayerClient(lPlr, localSFXFolder.Skill, 0, false);
	elseif action and action.Name == "Defend" then
		audioPlayerClient(lPlr, localSFXFolder.DefendSound, 0, false);
	end
end)

remoteEventsFolder.BattleSystem.UpdateClientStatusEffect.OnClientEvent:Connect(function(partyIndx, isPlayerParty, newStatusName)
	if isPlayerParty then
		partyFrame:WaitForChild(tostring(partyIndx)):WaitForChild("StatusEffect").Value = newStatusName;
	else
		local effects = findEnemyModelFromIndex(partyIndx):WaitForChild("Head"):WaitForChild("StatusAttachment"):GetChildren();
		for i,v in pairs(effects) do
			v.Enabled = false;
		end
		if newStatusName ~= "NONE" then
			findEnemyModelFromIndex(partyIndx).Head.StatusAttachment[newStatusName].Enabled = true;
		end
	end
end)

remoteEventsFolder.BattleSystem.EndBattle.OnClientEvent:Connect(function(isVictory)
	wait(1);
	battleMusic:Stop(); opBossMusic:Stop();
	if isVictory then
		local phrases = {"The enemies are defeated","The threat was neutralized","The party is victorious","The party emerges victorious"};
		local punctuations = {".","!"};
		EncounterClient:UpdateLogText(util:Choice(phrases)..util:Choice(punctuations));
		audioPlayerClient(lPlr, localSFXFolder.Victory, 0, false);
		wait(2);
	else
		local phrases = {"The party was wiped out","The enemy is victorious","All party members are unable to fight","The enemy emerges victorious"};
		local punctuations = {"...","!"};
		EncounterClient:UpdateLogText(util:Choice(phrases)..util:Choice(punctuations));
		audioPlayerClient(lPlr, localSFXFolder.GameOver, 0, false);
		wait(24.5);
		-- teleport player back to title
		telePlr("Title", "rbxassetid://9803690756");
	end
end)

remoteEventsFolder.BattleSystem.AdvanceTurn.OnClientEvent:Connect(function()
	EncounterClient.AutoBattle = "OFF";
	EncounterClient.LogSpeedMult = 1;
	for i,v in pairs(EncounterClient.PlayerParty.TeamMembers) do
		v.ISBEINGDEFENDED = false;
	end
	--warn(EncounterClient.PlayerParty); 
	EncounterClient:UpdatePartyUIInfo(); 
	EncounterClient:UpdateEnemyHPBars();
	tempCommandArr = {};
	tempDefendedArr = {};
	EncounterClient.CurrentSelectedPlayerIndex = 1;
	EncounterClient:InitializeUI(partyFrame, uiStorageFolder.PartyMemberFrame);
	if EncounterClient:DetermineButDoNotSetPreviousSelectedPlayerIndex() ~= -1 then
		backButtonFrame.Visible = true;
		warn("Visible. "..EncounterClient:DetermineButDoNotSetPreviousSelectedPlayerIndex());
	else
		backButtonFrame.Visible = false;
		warn("Invisible. "..EncounterClient:DetermineButDoNotSetPreviousSelectedPlayerIndex());
	end
	wait(.5);
	hideTurnOngoingFrame(); showTurnPrepFrame();
	SetClockScrollingText("6 AM  |  IN BATTLE  |  TURN "..EncounterClient.TurnNumber.."  |  AUTO "..EncounterClient.AutoBattle);
	EncounterClient:UpdateLogText("What will you do?");
	battleFrame.TurnOngoing.Log.TextYAlignment = Enum.TextYAlignment.Center;
	tweenInActionFrame(); tweenInPartyFrame(); tweenInCurrCharViewportFrame();
	bindAuto();
end)


--RUNSERVICE BACKGROUND STUFF---------------------
local i = 0;
RunService.Heartbeat:Connect(function()
	clockScrollingText.Position = UDim2.new(i, 0, .073, 0)
	i = i + 1 / 512;
	if i >= 1 then
		local stringLength = string.len(clockScrollingText.Text)
		i = -1 * stringLength / 110;
	end
end)



--INITIAL "SET"TINGS--------
encounterBar.Visible = true;
encounterBar.Size = UDim2.new(0, viewportSize.X, 1, 0);
battleCamSubject.Transparency = 1; battleCamSubject.Decal.Transparency = 1;
plrPlatform = getPlatform();

--[[
what to include in transition:
transition seems to distort the screen
after battle, the enemy has fallen!
show battle result
if boss:
party drawing weapons
battle end: show character who dealt kiling blow and other characters in background
--]]

remoteEventsFolder.BattleSystem.SendQueueToClient.OnClientEvent:Connect(function(queue)
	--warn(queue);
end)

