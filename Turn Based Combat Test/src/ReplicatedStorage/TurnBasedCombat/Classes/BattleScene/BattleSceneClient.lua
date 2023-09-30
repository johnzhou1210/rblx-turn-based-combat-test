--BATTLESCENECLIENT HANDLES THE VISUAL AND AURAL ASPECTS (UI UPDATING, SOUNDS, ETC.)

--[[   Service dependencies   --]]
local RS = game:GetService("ReplicatedStorage");
local RunService = game:GetService("RunService");
local Debris = game:GetService("Debris");
local Players = game:GetService("Players");
local SoundService = game:GetService("SoundService");
local TwnService = game:GetService("TweenService");

--[[   Folder references   --]]
local TBCFolder = RS.TurnBasedCombat;
local moduleFolder = TBCFolder.Modules;
local classesFolder = TBCFolder.Classes;
local miscFolder = RS.Misc;
local remoteEventsFolder = TBCFolder.RemoteEvents;
local BattleSceneFolder = workspace.BattleScene;
local ClientNPCModels = TBCFolder.ClientNPCModels;
local uiStorage = TBCFolder.UIStorage;
local ParticlesStorage = TBCFolder.ParticleEffects;
local bindableEventsFolder = TBCFolder.BindableEvents;

--[[   External dependencies   --]]
local util = require(miscFolder.Util);
local StatusEffectIcons = require(classesFolder.PartyMember.Storage.StatusEffectIcons);

--[[   Class dependencies   --]]
local GameObject = require(miscFolder.GameObject);
local BattleScene = require(classesFolder.BattleScene);
local AudioPlayerClient = require(classesFolder.AudioPlayerClient);
local BattleSceneClient = BattleScene:extend();


--[[   Key variables   --]]
local lPlr = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):wait();
local SFXFolder = lPlr:WaitForChild("PlayerGui"):WaitForChild("LocalSFX");
BattleScene.PartyUIXScaleSpacing = .252;

--[[   Class constructor   --]]
function BattleSceneClient:new(PlayerParty, EnemyParty, MusicID, IsBossFight, EncounterMethod)
	BattleSceneClient.super.new(self, PlayerParty, EnemyParty, MusicID, IsBossFight, EncounterMethod);
	self.Log = "";
	self.PartyFrame = nil;
	self.BattleFrame = nil;
	self.CurrentSelectedPlayerIndex = 1;
	self.CharViewportFrame = nil;
	self.AutoBattle = "OFF";
	self.LogSpeedMult = 1;
end

--[[   Accessor methods   --]]
function BattleSceneClient:CannotAct(PlayerPartyMember)
	return PlayerPartyMember.STATUSEFFECT == "DEAD" or PlayerPartyMember.STATUSEFFECT == "FROZEN" or PlayerPartyMember.STATUSEFFECT == "PARALYZED";
end

function BattleSceneClient:IsDead(PartyMember)
	return PartyMember.CURRHP == 0;
end

function BattleSceneClient:DetermineButDoNotSetPreviousSelectedPlayerIndex()
	local previousAbleIndex = self.CurrentSelectedPlayerIndex;
	local playerPartyArr = self.PlayerParty.TeamMembers;
	--if self.CurrentSelectedIndex == 1 then
	--	--cannot determine previous
	--	return -1;
	--else
	for i = self.CurrentSelectedPlayerIndex - 1, 1, -1 do
		if self:CannotAct(playerPartyArr[i]) then
			--don't return yet
			if i == 1 then
				--cannot determine previous
				return -1;
			end
		else
			return i;
		end
	end
	warn("there is no previous player")
	return -1;
	--end
end

function BattleSceneClient:ReturnArrOfPartyMemberIndexes(teamMembersArr, ignoreDead)
	local resultArr = {};
	for i,v in pairs(teamMembersArr) do
		if self:IsDead(v) and ignoreDead == true then
			--don't add to resulting arr
		else
			--add to resulting arr
			warn("inserting "..i);
			table.insert(resultArr, i);
		end
	end
	return resultArr;
end

function BattleSceneClient:CompileSkills(playerObj)
	local actionsArr = playerObj.ACTIONS;
	warn(actionsArr);
	local resultArr = {};
	for i,v in pairs(actionsArr) do
		local currActionObj = v;
		local isSkill = currActionObj.IsSkill;
		if isSkill == true then
			table.insert(resultArr, currActionObj);
		else
			--warn(currActionObj.Name.." is not skill");
		end
	end
	return resultArr;
end


--[[   Mutator methods   --]]
function BattleSceneClient:DeinitializeUI(partyFrame)
	--access frames and delete everything in PartyFrame
	local battleFrame = partyFrame.Parent;
	partyFrame:ClearAllChildren();
	if battleFrame:FindFirstChild("CurrentCharacterViewport") ~= nil then battleFrame.CurrentCharacterViewport:Destroy(); end
end

function BattleSceneClient:InitializeUI(partyFrame, partyMemberTemplate)
	--spawn parties
	self.PartyFrame = partyFrame;
	self.BattleFrame = self.PartyFrame.Parent;
	if #partyFrame:GetChildren() == 0 then
		self:SpawnPlayerPartyUI(partyFrame, partyMemberTemplate);
	end
	if self.CharViewportFrame then
		self.CharViewportFrame:Destroy();
		self.CharViewportFrame = nil;
		if self.BattleFrame and self.BattleFrame:FindFirstChild("CurrentCharViewport") then self.BattleFrame:FindFirstChild("CurrentCharViewport"):Destroy(); end
		warn("should have destroyed currcharviewportframe");
	end
	--set target to first able player
	print(self:DetermineAndSetFirstAblePlayerIndex()); --returns first able player index and sets the index. otherwise return -1
	self.CharViewportFrame = uiStorage.CurrentCharViewport:Clone();
	self.CharViewportFrame.Parent = self.BattleFrame;	
	self.CharViewportFrame.CharacterViewport.Target.Value = BattleSceneFolder.PlayerControlledCharacters[self.CurrentSelectedPlayerIndex];
	self.CharViewportFrame.CharacterViewport.Disabled = false;
	--highlight the current selected player
	self:HighlightPartyMember(self.PartyFrame:FindFirstChild(""..self.CurrentSelectedPlayerIndex..""));
	--print("highlight initialize", self.CurrentSelectedPlayerIndex);
end

function BattleSceneClient:UpdatePartyUIInfo2(partyMemberIndex, damageInstance, isHeal, HPorMP, isRevivalSkill, newStatusEffect)--assumes that gui already exists
	if damageInstance == "-6667331" or damageInstance == "-4207331" then return; end
	local plrTeamArr = self.PlayerParty.TeamMembers;
	local currPlayer = plrTeamArr[partyMemberIndex];--class type is PlayerPartyMember
	local currMemberFrame = self.PartyFrame[""..partyMemberIndex..""];
	local HPBarBack = currMemberFrame.HPBarBack; local HPBarFront = HPBarBack.HPBarFront;
	local MPBarBack = currMemberFrame.MPBarBack; local MPBarFront = MPBarBack.MPBarFront;
	local Highlight = currMemberFrame.Round.Highlight;
	local StatusFrame = currMemberFrame.StatusFrame;
	local PartyMemberName = currMemberFrame.PartyMemberName;
	local HPTitle = HPBarBack.Title; local HPVal = HPBarBack.Val;
	local MPTitle = MPBarBack.Title; local MPVal = MPBarBack.Val;
	local currHPEndIndex = string.find(HPBarBack.Val.Text, " ");
	local currHP = tonumber(string.sub(HPBarBack.Val.Text, 1, currHPEndIndex - 1));
	local currMaxHP = tonumber(string.sub(HPBarBack.Val.Text, currHPEndIndex + 3, #HPBarBack.Val.Text));
	local currMPEndIndex = string.find(MPBarBack.Val.Text, " ");
	local currMP = tonumber(string.sub(MPBarBack.Val.Text, 1, currMPEndIndex - 1));
	local currMaxMP = tonumber(string.sub(MPBarBack.Val.Text, currMPEndIndex + 3, #MPBarBack.Val.Text));
	-- adjust numbers to reflect damage taken
	if tonumber(damageInstance) ~= nil and damageInstance ~= "-420420420" then
		if HPorMP == "HP" then
			if isHeal then
				currHP = math.clamp(currHP + tonumber(damageInstance), 0, currMaxHP);
			else
				currHP = math.clamp(currHP - tonumber(damageInstance), 0, currMaxHP);
			end
		elseif HPorMP == "MP" then -- don't clamp lower bound to catch bugs
			if isHeal then
				currMP = math.clamp(currMP + tonumber(damageInstance), math.huge * -1, currMaxMP);
			else
				currMP = math.clamp(currMP - tonumber(damageInstance), math.huge * -1, currMaxMP); 
			end
		else
			error("Did not specifiy HP or MP!");
		end
	end
	print("isHeal is "..util:StringifyBool(isHeal)..'. damageInstance is '..tostring(damageInstance))
	if isHeal == false and tonumber(damageInstance) ~= nil and tonumber(damageInstance) > 0 and HPorMP == "HP" then--player took hp damage
		print("player took damage")
		local HPLOST = damageInstance;
		local numShakes = 1;
		local maxAngle = 12;
		local angle = (HPLOST / currMaxHP) * maxAngle;
		local shakeCoroutine = coroutine.wrap(function()
			for i = 1, numShakes * 2, 1 do
				currMemberFrame.Rotation = -1 * angle;
				wait(.05 / self.LogSpeedMult);
				currMemberFrame.Rotation = angle;
				wait(.05 / self.LogSpeedMult);
			end
			currMemberFrame.Rotation = 0;	
		end)
		shakeCoroutine();
	elseif isHeal == false and (damageInstance == "MISS" or damageInstance == "IGNORE") then --player got hit but took no damage. include ignore in here for now 
	else--player either took MP damage or healed
	end
	local healthyNameColor = Color3.new(0/255, 227/255, 189/255);
	local healthyTextColor = Color3.new(255/255, 244/255, 155/255);
	local unhealthyTextColor = Color3.new(1, 0, 0);
	local HPPercentage = currHP / currMaxHP;
	local MPPercentage = currMP / currMaxMP;
	local StatusEffect = currMemberFrame.StatusEffect; -- this one is temporary


	if currHP == 0 then StatusEffect.Value = "DEAD";
		print(newStatusEffect);
	elseif newStatusEffect == nil or isRevivalSkill then
		StatusEffect.Value = "NONE";
	elseif StatusEffect.Value ~= "DEAD" and newStatusEffect ~= "NONE" then
		StatusEffect.Value = newStatusEffect;
	end

	if isRevivalSkill and StatusEffect.Value == "DEAD" then StatusEffect.Value = "NONE"; end

	if damageInstance == "-420420420" then
		-- remove status effect
		StatusEffect.Value = "NONE";
	end

	if plrTeamArr then--update ui elements
		PartyMemberName.Text = currPlayer.Name;


		HPBarFront.Size = UDim2.new(HPPercentage, 0, 1, 0);
		MPBarFront.Size = UDim2.new(MPPercentage, 0, 1, 0);
		HPVal.Text = currHP.." / "..currMaxHP;
		MPVal.Text = currMP.." / "..currMaxMP;	

		StatusFrame.LevelFrame.LevelNum.Text = currPlayer.LEVEL;
		if StatusEffect.Value ~= "NONE" then--if player has status effect
			StatusFrame.LevelFrame.Visible = false;
			StatusFrame.StatusEffect.Visible = true;
			StatusFrame.StatusEffect.Image = StatusEffectIcons[StatusEffect.Value];
			StatusFrame.StatusEffect.ImageColor3 = StatusEffectIcons[StatusEffect.Value.."COLOR"];
		else
			StatusFrame.LevelFrame.Visible = true;
			StatusFrame.StatusEffect.Visible = false;
		end
		--adjust color of text based on hp/mp percentange
		if HPPercentage >= .25 then
			HPVal.TextColor3 = healthyTextColor;
			HPTitle.TextColor3 = healthyTextColor;
			PartyMemberName.TextColor3 = healthyNameColor;
			currMemberFrame.Round.DeadGradient.Enabled = false; currMemberFrame.Round.Outline.DeadGradient.Enabled = false;
		else
			HPVal.TextColor3 = unhealthyTextColor;
			HPTitle.TextColor3 = unhealthyTextColor;
			PartyMemberName.TextColor3 = healthyNameColor;
			currMemberFrame.Round.DeadGradient.Enabled = false; currMemberFrame.Round.Outline.DeadGradient.Enabled = false;
			if HPPercentage == 0 then
				PartyMemberName.TextColor3 = unhealthyTextColor;
				currMemberFrame.Round.DeadGradient.Enabled = true; currMemberFrame.Round.Outline.DeadGradient.Enabled = true;
				if currMemberFrame.LastHP.Value > 0 then
					AudioPlayerClient(lPlr, SFXFolder.PlayerDeath, 0, false);	
				else
					--warn("lasthp value was "..currMemberFrame.LastHP.Value.." so sound was not triggered");
				end	 
			end
		end
		if MPPercentage >= .25 then
			MPVal.TextColor3 = healthyTextColor;
			MPTitle.TextColor3 = healthyTextColor;
		else
			MPVal.TextColor3 = unhealthyTextColor;
			MPTitle.TextColor3 = unhealthyTextColor;
		end
	else
	end
	currMemberFrame.LastHP.Value = currHP;
end

function BattleSceneClient:UpdatePartyUIInfo()--assumes that gui already exists
	print("Turn", self.TurnNumber);
	local plrTeamArr = self.PlayerParty.TeamMembers;
	for i,v in pairs(plrTeamArr) do
		local currPlayer = v;--class type is PlayerPartyMember
		local currMemberFrame = self.PartyFrame[""..i..""];
		local HPBarBack = currMemberFrame.HPBarBack; local HPBarFront = HPBarBack.HPBarFront;
		local MPBarBack = currMemberFrame.MPBarBack; local MPBarFront = MPBarBack.MPBarFront;
		local Highlight = currMemberFrame.Round.Highlight;
		local StatusFrame = currMemberFrame.StatusFrame;
		local PartyMemberName = currMemberFrame.PartyMemberName;
		local HPTitle = HPBarBack.Title; local HPVal = HPBarBack.Val;
		local MPTitle = MPBarBack.Title; local MPVal = MPBarBack.Val;
		if currMemberFrame.LastHP.Value > currPlayer.CURRHP then--player took damage
			local HPLOST = currPlayer.LASTDAMAGETAKEN;
			--warn("lastdamagetaken is "..currPlayer.LASTDAMAGETAKEN);
			local numShakes = 1;
			local maxAngle = 12;
			local angle = (HPLOST / currPlayer.HP) * maxAngle;
			local shakeCoroutine = coroutine.wrap(function()
				for i = 1, numShakes * 2, 1 do
					currMemberFrame.Rotation = -1 * angle;
					wait(.05 / self.LogSpeedMult);
					currMemberFrame.Rotation = angle;
					wait(.05 / self.LogSpeedMult);
				end
				currMemberFrame.Rotation = 0;	
			end)
			shakeCoroutine();
		elseif currMemberFrame.LastHP.Value == currPlayer.CURRHP then --player took no damage
		else--player healed
		end
		local healthyNameColor = Color3.new(0/255, 227/255, 189/255);
		local healthyTextColor = Color3.new(255/255, 244/255, 155/255);
		local unhealthyTextColor = Color3.new(1, 0, 0);
		local HPPercentage = currPlayer.CURRHP / currPlayer.HP;
		local MPPercentage = currPlayer.CURRMP / currPlayer.MP;
		local StatusEffect = currPlayer.STATUSEFFECT;
		if plrTeamArr then--update ui elements
			PartyMemberName.Text = currPlayer.Name;
			HPBarFront.Size = UDim2.new(HPPercentage, 0, 1, 0);
			MPBarFront.Size = UDim2.new(MPPercentage, 0, 1, 0);
			HPVal.Text = currPlayer.CURRHP.." / "..currPlayer.HP;
			MPVal.Text = currPlayer.CURRMP.." / "..currPlayer.MP;
			StatusFrame.LevelFrame.LevelNum.Text = currPlayer.LEVEL;
			if StatusEffect ~= "NONE" then--if player has status effect
				StatusFrame.LevelFrame.Visible = false;
				StatusFrame.StatusEffect.Visible = true;
				StatusFrame.StatusEffect.Image = StatusEffectIcons[StatusEffect];
				StatusFrame.StatusEffect.ImageColor3 = StatusEffectIcons[StatusEffect.."COLOR"];
			else
				StatusFrame.LevelFrame.Visible = true;
				StatusFrame.StatusEffect.Visible = false;
			end
			--adjust color of text based on hp/mp percentange
			if HPPercentage >= .25 then
				HPVal.TextColor3 = healthyTextColor;
				HPTitle.TextColor3 = healthyTextColor;
				PartyMemberName.TextColor3 = healthyNameColor;
				currMemberFrame.Round.DeadGradient.Enabled = false; currMemberFrame.Round.Outline.DeadGradient.Enabled = false;
			else
				HPVal.TextColor3 = unhealthyTextColor;
				HPTitle.TextColor3 = unhealthyTextColor;
				PartyMemberName.TextColor3 = healthyNameColor;
				currMemberFrame.Round.DeadGradient.Enabled = false; currMemberFrame.Round.Outline.DeadGradient.Enabled = false;
				if HPPercentage == 0 then
					PartyMemberName.TextColor3 = unhealthyTextColor;
					currMemberFrame.Round.DeadGradient.Enabled = true; currMemberFrame.Round.Outline.DeadGradient.Enabled = true;
					if currMemberFrame.LastHP.Value > 0 then
						AudioPlayerClient(lPlr, SFXFolder.PlayerDeath, 0, false);	
					else
						--warn("lasthp value was "..currMemberFrame.LastHP.Value.." so sound was not triggered");
					end	 
				end
			end
			if MPPercentage >= .25 then
				MPVal.TextColor3 = healthyTextColor;
				MPTitle.TextColor3 = healthyTextColor;
			else
				MPVal.TextColor3 = unhealthyTextColor;
				MPTitle.TextColor3 = unhealthyTextColor;
			end
		end
		currMemberFrame.LastHP.Value = currPlayer.CURRHP;
	end
end

function BattleSceneClient:SpawnPlayerPartyUI(partyFrame, partyMemberTemplate)
	local plrTeamArr = self.PlayerParty.TeamMembers;
	local currXScalePos = 0;
	for i,v in pairs(plrTeamArr) do
		local currPlayer = v;--class type is PlayerPartyMember
		local currMemberFrame = partyMemberTemplate:Clone();
		local HPBarBack = currMemberFrame.HPBarBack; local HPBarFront = HPBarBack.HPBarFront;
		local MPBarBack = currMemberFrame.MPBarBack; local MPBarFront = MPBarBack.MPBarFront;
		local Highlight = currMemberFrame.Round.Highlight;
		local StatusFrame = currMemberFrame.StatusFrame;
		local PartyMemberName = currMemberFrame.PartyMemberName;
		local HPTitle = HPBarBack.Title; local HPVal = HPBarBack.Val;
		local MPTitle = MPBarBack.Title; local MPVal = MPBarBack.Val;
		currMemberFrame.LastHP.Value = currPlayer.CURRHP;
		currMemberFrame.Name = i;
		currMemberFrame.Parent = partyFrame;
		currMemberFrame.Position = UDim2.new((i - 1) * (BattleScene.PartyUIXScaleSpacing), 0, -.566, 0);
		--update ui initially
		local healthyNameColor = Color3.new(0/255, 227/255, 189/255);
		local healthyTextColor = Color3.new(255/255, 244/255, 155/255);
		local unhealthyTextColor = Color3.new(1, 0, 0);
		--one time change b/c it is initial
		local HPPercentage = currPlayer.CURRHP / currPlayer.HP;
		local MPPercentage = currPlayer.CURRMP / currPlayer.MP;
		local StatusEffect = currPlayer.STATUSEFFECT;
		if plrTeamArr then--update ui elements
			PartyMemberName.Text = currPlayer.Name;
			HPBarFront.Size = UDim2.new(HPPercentage, 0, 1, 0);
			MPBarFront.Size = UDim2.new(MPPercentage, 0, 1, 0);
			HPVal.Text = currPlayer.CURRHP.." / "..currPlayer.HP;
			MPVal.Text = currPlayer.CURRMP.." / "..currPlayer.MP;
			StatusFrame.LevelFrame.LevelNum.Text = currPlayer.LEVEL;
			if StatusEffect ~= "NONE" then--if player has status effect
				StatusFrame.LevelFrame.Visible = false;
				StatusFrame.StatusEffect.Visible = true;
				StatusFrame.StatusEffect.Image = StatusEffectIcons[StatusEffect];
				StatusFrame.StatusEffect.ImageColor3 = StatusEffectIcons[StatusEffect.."COLOR"];
			else
				StatusFrame.LevelFrame.Visible = true;
				StatusFrame.StatusEffect.Visible = false;
			end
			--adjust color of text based on hp/mp percentange
			if HPPercentage >= .25 then
				HPVal.TextColor3 = healthyTextColor;
				HPTitle.TextColor3 = healthyTextColor;
				PartyMemberName.TextColor3 = healthyNameColor;
				currMemberFrame.Round.DeadGradient.Enabled = false; currMemberFrame.Round.Outline.DeadGradient.Enabled = false;
			else
				HPVal.TextColor3 = unhealthyTextColor;
				HPTitle.TextColor3 = unhealthyTextColor;
				PartyMemberName.TextColor3 = healthyNameColor;
				currMemberFrame.Round.DeadGradient.Enabled = false; currMemberFrame.Round.Outline.DeadGradient.Enabled = false;
				if HPPercentage == 0 then
					PartyMemberName.TextColor3 = unhealthyTextColor;
					currMemberFrame.Round.DeadGradient.Enabled = true; currMemberFrame.Round.Outline.DeadGradient.Enabled = true;
				end
			end
			if MPPercentage >= .25 then
				MPVal.TextColor3 = healthyTextColor;
				MPTitle.TextColor3 = healthyTextColor;
			else
				MPVal.TextColor3 = unhealthyTextColor;
				MPTitle.TextColor3 = unhealthyTextColor;
			end
		end
	end
end

function BattleSceneClient:InstantiateEnemy(indexInTeamMembersArr, mouse, enemyClone, position)
	enemyClone.Humanoid.IndexInTeamMembersArr.Value = indexInTeamMembersArr;
	table.insert(mouse.TargetFilter, enemyClone);--make sure to clear target filter when enemyClone is gone
	enemyClone.Parent = BattleSceneFolder.Enemies;
	local correctOrientation = Vector3.new(0,0,0);
	if enemyClone.Humanoid:FindFirstChild("CorrectOrientation") ~= nil then
		correctOrientation = enemyClone.Humanoid.CorrectOrientation.Value;
	end
	enemyClone:SetPrimaryPartCFrame(CFrame.new(position) * CFrame.Angles( math.rad(correctOrientation.X) , math.rad(correctOrientation.Y) , math.rad(correctOrientation.Z) ));
	local hpBar = enemyClone:WaitForChild("Head"):WaitForChild("HP");
	local enemyPartyMember = self.EnemyParty.TeamMembers[indexInTeamMembersArr];
	hpBar.HPBar.HPBarBack.HPBarFront.Size = UDim2.new(enemyPartyMember.HP / enemyPartyMember.CURRHP, 0, 1, 0);
	hpBar.HPBar.Val.Text = enemyPartyMember.HP.." / "..enemyPartyMember.CURRHP;
	local enemyHumanoid = enemyClone:WaitForChild("Humanoid");
	enemyHumanoid:SetAttribute("HP", enemyPartyMember.HP); enemyHumanoid:SetAttribute("CURRHP", enemyPartyMember.CURRHP); enemyHumanoid:SetAttribute("LASTHP", enemyPartyMember.CURRHP);
	local selectionPointerGradientAnim = coroutine.wrap(function()
		while enemyClone and enemyClone:FindFirstChild("HumanoidRootPart") and enemyClone:FindFirstChild("Head") do
			for i = -.8, 1, .01 do
				if enemyClone.Head.SelectionPointer.Enabled and enemyClone and enemyClone.Head and enemyClone.Head.SelectionPointer then
					enemyClone.Head.SelectionPointer.Frame.ImageLabel.UIGradient.Offset = Vector2.new(0, i);
					RunService.Heartbeat:Wait();	
				end	
			end

			for i = -.8, 1, .01 do
				if enemyClone and enemyClone.Head and enemyClone.Head.TargetPointer and enemyClone.Head.TargetPointer.Enabled then
					enemyClone.Head.TargetPointer.Frame.SwordIcon.UIGradient.Offset = Vector2.new(0, i);
					RunService.Heartbeat:Wait();	
				end	
			end
			RunService.Heartbeat:Wait();
		end
	end)
	selectionPointerGradientAnim();	
	self:PlayEnemyAnimations(enemyClone.Humanoid);
end

function BattleSceneClient:PlayEnemyAnimations(enemyHumanoid)
	if enemyHumanoid then
		local coro = coroutine.wrap(function()
			local enemyAnimFolder = enemyHumanoid:WaitForChild("Animations");
			local idleAnimTrack = enemyHumanoid:LoadAnimation(enemyAnimFolder.Idle);
			idleAnimTrack:Play();
			--handle other anims here
		end)
		coro();
	else
		error("CANNOT FIND ENEMYHUMANOID TO PLAY ANIMATIONS!");
	end
end

function BattleSceneClient:SpawnEnemies(mouse)
	local lBoundPart = BattleSceneFolder.InvisComponents.EnemyPositionTemplates.LBound;
	local rBoundPart = BattleSceneFolder.InvisComponents.EnemyPositionTemplates.RBound;
	local numEnemies = #(self.EnemyParty.TeamMembers);
	local boundLength = math.abs(lBoundPart.Position.X - rBoundPart.Position.X); 
	local enemySpacing = (boundLength / (numEnemies + 1));
	local initPos = lBoundPart.Position;
	for i,v in pairs(self.EnemyParty.TeamMembers) do
		--warn(v.Name);
		self:InstantiateEnemy(i, mouse, ClientNPCModels:WaitForChild("Enemy"):WaitForChild(v.Name):Clone(), Vector3.new(initPos.X + (enemySpacing * i), initPos.Y, initPos.Z));
	end
end

function BattleSceneClient:ClearEnemyModels()
	for i,v in pairs(BattleSceneFolder.Enemies:GetChildren()) do
		v:Remove();
	end
end

function BattleSceneClient:ClearPlayerModels()
	for i,v in pairs(BattleSceneFolder.PlayerControlledCharacters:GetChildren()) do
		v:Remove();
	end
end

function BattleSceneClient:InstantiatePlayer(arrIndex, playerClone, position)
	playerClone.Name = ""..arrIndex.."";
	playerClone.Parent = BattleSceneFolder.PlayerControlledCharacters;
	playerClone:SetPrimaryPartCFrame(CFrame.new(position));
	self:PlayPlayerAnimations(playerClone.Humanoid);
end

function BattleSceneClient:PlayPlayerAnimations(playerHumanoid)
	if playerHumanoid then
		local coro = coroutine.wrap(function()
			local playerAnimFolder = playerHumanoid:WaitForChild("Animations");
			local idleAnimTrack = playerHumanoid:LoadAnimation(playerAnimFolder.Idle);
			idleAnimTrack:Play();
		end)
		coro();
	else
		error("CANNOT FIND PLAYERHUMANOID TO PLAY ANIMATIONS!");
	end
end

function BattleSceneClient:SpawnPlayerParty()
	local lBoundPart = BattleSceneFolder.InvisComponents.PlayerPositionTemplates.LBound;
	local rBoundPart = BattleSceneFolder.InvisComponents.PlayerPositionTemplates.RBound;
	local numPlayers = #(self.PlayerParty.TeamMembers);
	local boundLength = math.abs(lBoundPart.Position.X - rBoundPart.Position.X);
	local playerSpacing = (boundLength / (numPlayers + 1));
	local initPos = lBoundPart.Position;
	for i,v in pairs(self.PlayerParty.TeamMembers) do
		--warn(tostring(v.MODEL));
		self:InstantiatePlayer(i, v.MODEL:Clone(), Vector3.new(initPos.X + (playerSpacing * i), initPos.Y, initPos.Z));
	end
end

function BattleSceneClient:UpdateLogText(newString)
	self.Log = newString;
	self.BattleFrame.TurnOngoing.Log.Text = self.Log;
	self.BattleFrame.TurnPrep.LogFrame.Log.Text = self.Log;	
end

function BattleSceneClient:UpdateHotkeyText(newString)
	self.BattleFrame.TurnPrep.HotkeyFrame.HotKeyInfo.Text = newString;
end

function BattleSceneClient:DetermineAndSetPreviousSelectedPlayerIndex(cancelTurnStart)--return whether or not can determine previous selectedplayerindex
	local previousAbleIndex = self.CurrentSelectedPlayerIndex;
	local playerPartyArr = self.PlayerParty.TeamMembers;
	--if self.CurrentSelectedIndex == 1 then
	--	--cannot determine previous
	--	return false;
	--else
	for i = self.CurrentSelectedPlayerIndex - 1, 1, -1 do
		if self:CannotAct(playerPartyArr[i]) then
			--don't return yet
			if i == 1 then
				--cannot determine previous
				return false;
			end
		else
			self:UnhighlightPartyMember(self.PartyFrame:FindFirstChild(""..previousAbleIndex..""));			
			print("unhighlighted", previousAbleIndex);
			
			if cancelTurnStart then
				-- do nothing
			else
				self.CurrentSelectedPlayerIndex = i;
			end
			self.CharViewportFrame:Destroy();
			self.CharViewportFrame = nil;
			self.CharViewportFrame = uiStorage.CurrentCharViewport:Clone();
			self.CharViewportFrame.Parent = self.BattleFrame;
			self.CharViewportFrame.CharacterViewport.Target.Value = BattleSceneFolder.PlayerControlledCharacters[self.CurrentSelectedPlayerIndex];
			self.CharViewportFrame.CharacterViewport.Disabled = false;
			self:HighlightPartyMember(self.PartyFrame:FindFirstChild(""..self.CurrentSelectedPlayerIndex..""));
			--print("highlighted", self.CurrentSelectedPlayerIndex);
			return true;
		end
	end
	--end
end

function BattleSceneClient:DetermineAndSetNextSelectedPlayerIndex()--return whether or not to start the battle phase
	local previousAbleIndex = self.CurrentSelectedPlayerIndex;
	self:UnhighlightPartyMember(self.PartyFrame:FindFirstChild(""..previousAbleIndex..""));
	print("unhighlighted2", previousAbleIndex);
	local playerPartyArr = self.PlayerParty.TeamMembers; -- example, {p1, p2(dead), p3, p4(frozen)}
	if self.CurrentSelectedPlayerIndex == #playerPartyArr then
		--ready to send primitive command array to server to check for validity and execute!	
		return true;	
	else
		for i = self.CurrentSelectedPlayerIndex + 1, #playerPartyArr, 1 do 
			if self:CannotAct(playerPartyArr[i]) then
				--dont return yet
				if i == #playerPartyArr then
					--ready to send primitive command array to server to check for validity and execute!
					return true;
				end
				--go through another iteration
			else
				self.CurrentSelectedPlayerIndex = i;
				--destroy current charviewport and create new one
				self.CharViewportFrame:Destroy();
				self.CharViewportFrame = nil;
				self.CharViewportFrame = uiStorage.CurrentCharViewport:Clone();
				self.CharViewportFrame.Parent = self.BattleFrame;
				self.CharViewportFrame.CharacterViewport.Target.Value = BattleSceneFolder.PlayerControlledCharacters[self.CurrentSelectedPlayerIndex];
				self.CharViewportFrame.CharacterViewport.Disabled = false;
				self:HighlightPartyMember(self.PartyFrame:FindFirstChild(""..self.CurrentSelectedPlayerIndex..""));
				--print("highlightnext",self.CurrentSelectedPlayerIndex);
				--go back to tweening in actions frame and characterviewport frame
				return false;
			end
		end	
	end
	error("WE HAVE A PROBLEM IN BattleSceneClient:DetermineAndSetNextSelectedPlayerIndex()!");
end

function BattleSceneClient:DetermineAndSetFirstAblePlayerIndex()
	self.CurrentSelectedPlayerIndex = 1;
	local playerPartyArr = self.PlayerParty.TeamMembers;
	for i = self.CurrentSelectedPlayerIndex, #playerPartyArr, 1 do
		if self:CannotAct(playerPartyArr[i]) then
			--continue iteration
		elseif self:CannotAct(playerPartyArr[i]) == false then
			self.CurrentSelectedPlayerIndex = i;
			warn("value returned by determinenadsetfirstableplayerindex method is "..i);
			return i;
		else
			error("AN ERROR OCCURED OR THERE ARE NO ABLE PLAYERS LEFT!");
		end
	end
end

function BattleSceneClient:HighlightPartyMember(partyMemberFrame)
	partyMemberFrame.Round.Highlight.Visible = true;
end
function BattleSceneClient:UnhighlightPartyMember(partyMemberFrame)
	partyMemberFrame.Round.Highlight.Visible = false;
end
function BattleSceneClient:UpdateSkillsListCanvasSize(canvas, constraint)
	canvas.CanvasSize = UDim2.new(0, constraint.AbsoluteContentSize.X, 0, constraint.AbsoluteContentSize.Y);
end

function BattleSceneClient:UpdateEnemyHPBars()
	for i,v in pairs(BattleSceneFolder.Enemies:GetChildren()) do
		local currEnemyModel = v;
		local hpBillboard = currEnemyModel:WaitForChild("Head").HP;
		local monsterIndex = currEnemyModel:WaitForChild("Humanoid").IndexInTeamMembersArr.Value;
		local currEnemyObj = self.EnemyParty.TeamMembers[monsterIndex];
		hpBillboard.HPBar.HPBarBack.HPBarFront.Size = UDim2.new(currEnemyObj.CURRHP / currEnemyObj.HP, 0, 1, 0);
		hpBillboard.HPBar.Val.Text = currEnemyObj.CURRHP.." / "..currEnemyObj.HP;
		game:GetService("TestService"):Message(currEnemyObj.DISPLAYNAME.."'s CURRHP is "..currEnemyObj.CURRHP);
	end
end

function BattleSceneClient:EnemyDeathEffect(enemyModel)
	local anchorEnemyModelCoro = coroutine.wrap(function()
		-- also get rid of any status effect particles
		for i,v in pairs(enemyModel:WaitForChild("Head"):WaitForChild("StatusAttachment"):GetChildren()) do
			v.Enabled = false;
		end
		--play death animation and freeze enemy in place after 3 seconds of playing
		local deathAnim = enemyModel:WaitForChild("Humanoid"):WaitForChild("Animations"):WaitForChild("Die");
		local animTrack = enemyModel:WaitForChild("Humanoid"):LoadAnimation(deathAnim);
		animTrack:AdjustSpeed(self.LogSpeedMult);
		animTrack:Play();
		game:GetService("Debris"):AddItem(animTrack, animTrack.Length);
		wait(1);
		for i,v in pairs(enemyModel:GetDescendants()) do
			if v and v:IsA("BasePart") or v:IsA("UnionOperation") then
				v.Anchored = true;	
			end
		end
		AudioPlayerClient(lPlr, SFXFolder:WaitForChild("EnemyVanish"), 0, false);
		for i,v in pairs(enemyModel:GetDescendants()) do
			if (v:IsA("BasePart") or v:IsA("UnionOperation")) and v.Transparency < 1 then
				local ashParticle = ParticlesStorage.Ash:Clone();
				ashParticle.Parent = v;
				local particleCleanupCoro = coroutine.wrap(function()
					wait(1.5 / (self.LogSpeedMult) );
					ashParticle.Enabled = false;
					Debris:AddItem(ashParticle , 6);
				end)
				particleCleanupCoro();
				local fadeModelCoro = coroutine.wrap(function()
					for x,y in pairs(enemyModel:GetDescendants()) do
						if (y:IsA("BasePart") or y:IsA("UnionOperation") or y:IsA("Decal") or y:IsA("Texture")) and y.Transparency < 1 and y.Name ~= "HumanoidRootPart" then
							local coro = coroutine.wrap(function()
								for i = 0, 1.05, .05 do
									if y:IsA("UnionOperation") then
										y.UsePartColor = true;
									end
									y.Transparency = i;
									if not (y:IsA("Decal") or y:IsA("Texture")) then
										y.Color = Color3.new((y.Color.r)/1.1,(y.Color.g)/1.1,(y.Color.b)/1.1);
									else
										y.Color3 = Color3.new((y.Color3.r)/1.1,(y.Color3.g)/1.1,(y.Color3.b)/1.1);
									end
									wait(.1 / (self.LogSpeedMult) );
								end	
							end)
							coro();	
						end
					end
				end)
				fadeModelCoro();
			end
			if v:IsA("ParticleEmitter") then
				v.Enabled = false;
			end
		end
	end)
	anchorEnemyModelCoro();
end

function BattleSceneClient:ApplyEnemyModelDamageIndication(enemyModel, damageAmount, isCrit, isHeal, isSupport, statusEffect)
	if enemyModel then
		local enemyHead = enemyModel:WaitForChild("Head");
		if statusEffect ~= "NONE" then
			-- disable all other effects first
			for i,v in pairs(enemyHead:WaitForChild("StatusAttachment"):GetChildren()) do
				v.Enabled = false;
			end
			enemyHead:WaitForChild("StatusAttachment"):WaitForChild(statusEffect).Enabled = true;
		end

		local enemyHumanoid = enemyModel:WaitForChild("Humanoid");
		local damageIndicatorCoro = coroutine.wrap(function()
			if isHeal ~= nil then
				local dmgIndicator = uiStorage:WaitForChild("DmgIndicator"):Clone();
				local billboardDmgTxt = dmgIndicator.BillboardDmgTxt;
				local gradientToUse;
				local particleAttachmentToUse;
				if damageAmount == "MISS" or damageAmount == "EVADED" or damageAmount == "0" then--if action missed, evaded, or 0 hit damage
					gradientToUse = dmgIndicator:WaitForChild("Gradients"):WaitForChild("MissGradient"):Clone();
					billboardDmgTxt.TextColor3 = billboardDmgTxt:GetAttribute("HealColor");
					billboardDmgTxt.Text = damageAmount;
					if damageAmount == "EVADED" then billboardDmgTxt.Text = "EVADE"; end
				else--if not miss
					if isHeal == true then
						gradientToUse = dmgIndicator:WaitForChild("Gradients"):WaitForChild("HealGradient"):Clone();
						billboardDmgTxt.TextColor3 = billboardDmgTxt:GetAttribute("HealColor");
						billboardDmgTxt.Text = damageAmount;
						particleAttachmentToUse = ParticlesStorage.HitParticles.HealParticle:Clone();
					else --hit target and will now damage
						gradientToUse = dmgIndicator:WaitForChild("Gradients"):WaitForChild("DamageGradient"):Clone();
						billboardDmgTxt.TextColor3 = billboardDmgTxt:GetAttribute("DamageColor");
						billboardDmgTxt.Text = damageAmount;
						if isCrit then 
							particleAttachmentToUse = ParticlesStorage.HitParticles.CritParticle:Clone(); 
						else
							particleAttachmentToUse = ParticlesStorage.HitParticles.HitParticle:Clone();
						end
						--play hurt animations
						local enemyAnimsFolder = enemyHumanoid:WaitForChild("Animations");
						local takeDmgAnim = enemyAnimsFolder:WaitForChild("TakeDamage");
						local animTrack = enemyHumanoid:LoadAnimation(takeDmgAnim);
						animTrack:AdjustSpeed(self.LogSpeedMult);
						animTrack:Play();
						game:GetService("Debris"):AddItem(animTrack, animTrack.Length);
					end		
					particleAttachmentToUse.Parent = enemyHead;
					local hitParticleCoroutine = coroutine.wrap(function()
						wait((1/3) / self.LogSpeedMult);
						for i,v in pairs(particleAttachmentToUse:GetChildren()) do
							if v:IsA("ParticleEmitter") then
								v.Enabled = false;
								Debris:AddItem(v, 5/3);
							end
						end
					end)
					if tonumber(damageAmount) ~= nil and tonumber(damageAmount) > 0 then
						hitParticleCoroutine();		
					end
				end
				if isCrit then
					dmgIndicator.Size = UDim2.new(5,0,5,0);
					gradientToUse = dmgIndicator:WaitForChild("Gradients"):WaitForChild("CritGradient"):Clone();
				end
				dmgIndicator.Parent = enemyHead;
				gradientToUse.Parent = billboardDmgTxt;
				--time for the tweening
				local tweenDuration = 1.5 / self.LogSpeedMult;
				local tweenInfo = TweenInfo.new(tweenDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0);
				local goal = {};
				goal.StudsOffset = Vector3.new(0, 2, 0);
				TwnService:Create(dmgIndicator, tweenInfo, goal):Play();
				local goal2 = {};
				goal2.TextTransparency = 1;
				goal2.TextStrokeTransparency = 1;
				TwnService:Create(billboardDmgTxt, tweenInfo, goal2):Play();
				Debris:AddItem(dmgIndicator, tweenDuration);
			else
				error("ISHEAL (A BOOL VALUE) IS NIL!");
			end
		end)
		damageIndicatorCoro();
	else
		error("ENEMYMODEL NOT FOUND!");
	end
end
function BattleSceneClient:ApplyPlayerFrameDamageIndication(playerFrame, damageAmount, isCrit, isHeal, HPorMP, isSupport, isRevivalSkill, statusEffect) -- add non death status effect inflicted in param in the future
	if type(isCrit) == "string" then isCrit = util:DestringifyBool(isCrit); end
	if type(isHeal) == "string" then isHeal = util:DestringifyBool(isHeal); end
	if type(isSupport) == "string" then isSupport = util:DestringifyBool(isSupport); end
	if playerFrame then
		coroutine.wrap(function()
			print("attempting to do damageCoro on partyMember frame",playerFrame);
			if playerFrame.StatusEffect.Value == "DEAD" and isHeal == true and isRevivalSkill == false then damageAmount = 0; end
			self:UpdatePartyUIInfo2(tonumber(playerFrame.Name), damageAmount, isHeal, HPorMP, isRevivalSkill, statusEffect);
			if isHeal ~= nil then
				--print("outer here")
				local dmgIndicator = uiStorage:WaitForChild("PlayerDmgIndicator"):Clone();
				local gradientToUse gradientToUse = playerFrame:WaitForChild("Gradients"):WaitForChild("MissGradient"):Clone();	
				if damageAmount == "MISS" or damageAmount == "EVADED" or (damageAmount == "0" and HPorMP == "HP")  then--if action missed or evaded or no hit damage
					--print("in if")
					dmgIndicator.TextColor3 = dmgIndicator:GetAttribute("HealColor");
					dmgIndicator.Text = damageAmount;
					dmgIndicator.Visible = true;
					if damageAmount == "EVADED" then dmgIndicator.Text = "EVADE"; end
				elseif damageAmount == "-420420420" then -- this is purify
					dmgIndicator.Visible = false;
					AudioPlayerClient(lPlr, SFXFolder.Recover, 0, false);	
				elseif damageAmount == "-666666666" then -- this is dispel
					dmgIndicator.Visible = false;
				elseif damageAmount == "-6667331" then -- this is a buff
					-- buff effect
					dmgIndicator.Visible = false;
					AudioPlayerClient(lPlr, SFXFolder.Buff, 0, false);	
					coroutine.wrap(function()
						local buff1 = playerFrame.Round.Buff;
						buff1.Size = buff1:GetAttribute("StartSize");
						buff1.ImageTransparency = .5;
						buff1.ImageColor3 = buff1:GetAttribute("StartColor");

						local tweenInfo = TweenInfo.new (
							.75, -- Time
							Enum.EasingStyle.Quart, -- EasingStyle
							Enum.EasingDirection.Out, -- EasingDirection
							0, -- RepeatCount (when less than zero the tween will loop indefinitely)
							false, -- Reverses (tween will reverse once reaching it's goal)
							0 -- DelayTime
						)
						local goal = {};
						goal.Size = buff1:GetAttribute("EndSize");
						goal.ImageTransparency = -.5; 
						TwnService:Create(buff1, tweenInfo, goal):Play();
						wait(.2);

						local tweenInfo2 = TweenInfo.new (
							.75, -- Time
							Enum.EasingStyle.Quart, -- EasingStyle
							Enum.EasingDirection.Out, -- EasingDirection
							0, -- RepeatCount (when less than zero the tween will loop indefinitely)
							false, -- Reverses (tween will reverse once reaching it's goal)
							0 -- DelayTime
						)
						local goal2 = {};
						goal2.ImageTransparency = 1; 
						goal2.ImageColor3 = buff1:GetAttribute("EndColor");
						TwnService:Create(buff1, tweenInfo, goal2):Play();
					end)();
					coroutine.wrap(function() -- second white thing
						local buff1 = playerFrame.Round.BuffBack;
						buff1.Size = buff1:GetAttribute("StartSize");
						buff1.ImageTransparency = .5;
						buff1.ImageColor3 = buff1:GetAttribute("StartColor");

						local tweenInfo = TweenInfo.new (
							.75, -- Time
							Enum.EasingStyle.Quart, -- EasingStyle
							Enum.EasingDirection.Out, -- EasingDirection
							0, -- RepeatCount (when less than zero the tween will loop indefinitely)
							false, -- Reverses (tween will reverse once reaching it's goal)
							0 -- DelayTime
						)
						local goal = {};
						goal.Size = buff1:GetAttribute("EndSize");
						goal.ImageTransparency = -.5; 
						TwnService:Create(buff1, tweenInfo, goal):Play();
						wait(.2);

						local tweenInfo2 = TweenInfo.new (
							.75, -- Time
							Enum.EasingStyle.Quart, -- EasingStyle
							Enum.EasingDirection.Out, -- EasingDirection
							0, -- RepeatCount (when less than zero the tween will loop indefinitely)
							false, -- Reverses (tween will reverse once reaching it's goal)
							0 -- DelayTime
						)
						local goal2 = {};
						goal2.ImageTransparency = 1; 
						goal2.ImageColor3 = buff1:GetAttribute("EndColor");
						TwnService:Create(buff1, tweenInfo, goal2):Play();
					end)();
				elseif damageAmount == "-4207331" then -- this is a debuff
					--debuff effect
					dmgIndicator.Visible = false;
					AudioPlayerClient(lPlr, SFXFolder.Debuff, 0, false);	
					coroutine.wrap(function()
						local buff1 = playerFrame.Round.Debuff;
						buff1.Size = buff1:GetAttribute("StartSize");
						buff1.ImageTransparency = .35;
						buff1.ImageColor3 = buff1:GetAttribute("StartColor");

						local tweenInfo = TweenInfo.new (
							.25, -- Time
							Enum.EasingStyle.Back, -- EasingStyle
							Enum.EasingDirection.In, -- EasingDirection
							0, -- RepeatCount (when less than zero the tween will loop indefinitely)
							false, -- Reverses (tween will reverse once reaching it's goal)
							0 -- DelayTime
						)
						local goal = {};
						goal.Size = buff1:GetAttribute("EndSize");
						goal.ImageTransparency = 1; 
						TwnService:Create(buff1, tweenInfo, goal):Play();
						wait(.1);

						local tweenInfo2 = TweenInfo.new (
							.75, -- Time
							Enum.EasingStyle.Back, -- EasingStyle
							Enum.EasingDirection.In, -- EasingDirection
							0, -- RepeatCount (when less than zero the tween will loop indefinitely)
							false, -- Reverses (tween will reverse once reaching it's goal)
							0 -- DelayTime
						)
						local goal2 = {};
						goal2.ImageTransparency = 1; 
						goal2.ImageColor3 = buff1:GetAttribute("EndColor");
						TwnService:Create(buff1, tweenInfo2, goal2):Play();
					end)();
				else--action landed on target
					--print("in else")
					dmgIndicator.Visible = true;
					if isHeal == true then -- is heal
						--print("in isHeal")
						if HPorMP == "HP" then
							gradientToUse = playerFrame:WaitForChild("Gradients"):WaitForChild("HealGradient"):Clone();	
							dmgIndicator.TextColor3 = dmgIndicator:GetAttribute("HealColor");
						elseif HPorMP == "MP" then
							gradientToUse = playerFrame:WaitForChild("Gradients"):WaitForChild("MPHealGradient"):Clone();
							dmgIndicator.TextColor3 = dmgIndicator:GetAttribute("MPHealColor");
						else
							error("HPorMP IS NOT EQUAL TO HP OR MP!");
						end
						dmgIndicator.Text = tonumber(damageAmount); 
					else -- is either hp or mp damage
						--print("in isHeal else")
						if HPorMP == "HP" then
							gradientToUse = playerFrame:WaitForChild("Gradients"):WaitForChild("DamageGradient"):Clone();	
							dmgIndicator.TextColor3 = dmgIndicator:GetAttribute("DamageColor");
						elseif HPorMP == "MP" and tonumber(damageAmount) > 0 then
							gradientToUse = playerFrame:WaitForChild("Gradients"):WaitForChild("MPDamageGradient"):Clone();
							dmgIndicator.TextColor3 = dmgIndicator:GetAttribute("MPDamageColor");
						else -- potential logical error OR action costed no MP
							gradientToUse = playerFrame:WaitForChild("Gradients"):WaitForChild("MPDamageGradient"):Clone(); -- just here to prevent error
							dmgIndicator.Visible = false;
						end
						dmgIndicator.Text = damageAmount;	
					end
				end
				if isCrit then
					dmgIndicator.Size = UDim2.new(.9,0,.9,0);
					gradientToUse = playerFrame:WaitForChild("Gradients"):WaitForChild("CritGradient"):Clone();	
				end
				dmgIndicator.Parent = playerFrame;
				gradientToUse.Parent = dmgIndicator;
				--time for the tweening
				--set default position of text based on how many indicators there are in the frame
				local function getSameSpotIndicators()
					local result = {};
					for i,v in pairs(playerFrame:GetChildren()) do
						if v.Name == "PlayerDmgIndicator" then
							table.insert(result, v);
						end
					end
					return result;
				end
				if #getSameSpotIndicators() > 1 then
					local array = getSameSpotIndicators();
					for i,v in pairs(array) do
						if i > 1 then
							local previousIndicator = array[i - 1];
							v.Position = UDim2.new(.5, 0, previousIndicator.Size.Y.Scale - 1, 0);
							v:SetAttribute("GoalPosition", UDim2.new(.5, 0, v.Position.Y.Scale - .5, 0));
						end
					end
				end
				local tweenDuration = 1.5 / self.LogSpeedMult;
				local tweenInfo = TweenInfo.new(tweenDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0);
				local goal = {};
				goal.Position = UDim2.new(.5, 0, .5 - 1, 0);
				goal.TextTransparency = 1;
				goal.TextStrokeTransparency = 1;
				TwnService:Create(dmgIndicator, tweenInfo, goal):Play();
				Debris:AddItem(dmgIndicator, tweenDuration);
			else
				error("ISHEAL (A BOOL VALUE) IS NIL!");
			end
		end)();
	else
		error("ENEMYMODEL NOT FOUND!");
	end
end

function BattleSceneClient:PlayEnemyActionAnim(enemyModel, actionName)
	if enemyModel and actionName then
		local enemyAnimFolder = enemyModel:WaitForChild("Humanoid"):WaitForChild("Animations");
		local wantedAction = enemyAnimFolder:FindFirstChild(actionName);
		if wantedAction then
			warn("action found")
			local animTrack = enemyModel:WaitForChild("Humanoid"):LoadAnimation(wantedAction);
			animTrack:AdjustSpeed(self.LogSpeedMult);
			animTrack:Play();
			game:GetService("Debris"):AddItem(animTrack, animTrack.Length);
		else
			print(actionName, "not found");
		end
	else
		error("ENEMYMODEL NOT FOUND OR ACTIONOBJ IS NIL!");
	end
end

function BattleSceneClient:ShowEnemyModelTargetPointer(enemyModel, attackerIsPlayer)
	if enemyModel then
		local targetPointer = enemyModel:WaitForChild("Head"):WaitForChild("TargetPointer");
		local gradient = targetPointer.Frame.SwordIcon.UIGradient;
		local attributeName;
		if attackerIsPlayer then 
			attributeName = "PlayerColor";
		else
			attributeName = "EnemyColor";
		end
		gradient.Color = ColorSequence.new {
			ColorSequenceKeypoint.new(0, gradient:GetAttribute(attributeName)),
			ColorSequenceKeypoint.new(.5, Color3.new(1,1,1)),
			ColorSequenceKeypoint.new(1, gradient:GetAttribute(attributeName))
		};
		targetPointer.Enabled = true;
		local coro = coroutine.wrap(function()
			wait(1 / self.LogSpeedMult);
			BattleSceneClient:HideEnemyModelTargetPointer(enemyModel);
		end)
		coro();
	end
end

function BattleSceneClient:HideEnemyModelTargetPointer(enemyModel)
	if enemyModel then
		local targetPointer = enemyModel:WaitForChild("Head"):WaitForChild("TargetPointer");
		targetPointer.Enabled = false;
	end
end

function BattleSceneClient:ShowPlayerModelTargetPointer(playerPartyMemberFrame, attackerIsPlayer)
	if playerPartyMemberFrame then
		local targetPointer = playerPartyMemberFrame:WaitForChild("SwordIcon");
		local gradient = targetPointer.UIGradient;
		local attributeName;
		if attackerIsPlayer then 
			attributeName = "PlayerColor";
		else
			attributeName = "EnemyColor";
		end
		gradient.Color = ColorSequence.new {
			ColorSequenceKeypoint.new(0, gradient:GetAttribute(attributeName)),
			ColorSequenceKeypoint.new(.5, Color3.new(1,1,1)),
			ColorSequenceKeypoint.new(1, gradient:GetAttribute(attributeName))
		};
		targetPointer.Visible = true;
		local coro = coroutine.wrap(function()
			wait(1 / self.LogSpeedMult);
			BattleSceneClient:HidePlayerModelTargetPointer(playerPartyMemberFrame);
		end)
		coro();
	end
end

function BattleSceneClient:HidePlayerModelTargetPointer(playerPartyMemberFrame)
	if playerPartyMemberFrame then
		local targetPointer = playerPartyMemberFrame:WaitForChild("SwordIcon");
		targetPointer.Visible = false;
	end
end

function BattleSceneClient:ShowEnemyModelInitiatorPointer(enemyModel)
	if enemyModel then
		local initPointer = enemyModel:WaitForChild("HumanoidRootPart"):WaitForChild("EnemyInitiator"); -- not head because or else circle would move funny
		initPointer.Shockwave.Enabled = true;
		local coro = coroutine.wrap(function()
			wait(.5 / self.LogSpeedMult);
			BattleSceneClient:HideEnemyModelInitiatorPointer(enemyModel);
		end)
		coro();
	end
end

function BattleSceneClient:HideEnemyModelInitiatorPointer(enemyModel)
	if enemyModel then
		local initPointer = enemyModel:WaitForChild("HumanoidRootPart"):WaitForChild("EnemyInitiator");
		initPointer.Shockwave.Enabled = false;
	end
end

return BattleSceneClient;