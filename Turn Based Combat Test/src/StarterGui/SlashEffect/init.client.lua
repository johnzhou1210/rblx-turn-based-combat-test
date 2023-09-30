local RunService = game:GetService("RunService");
local RS = game:GetService("ReplicatedStorage");
local PLRS = game:GetService("Players");
local Tween = require(script.Tween);
local effectsFolder = RS.TurnBasedCombat.ParticleEffects;
local bindableEventsFolder = RS.TurnBasedCombat.BindableEvents;
local classesFolder = RS.TurnBasedCombat.Classes;
local audioPlayerClient = require(classesFolder.AudioPlayerClient);
local lPlr = PLRS.LocalPlayer or PLRS:GetPropertyChangedSignal("LocalPlayer"):wait();
local localSFXFolder = lPlr.PlayerGui:WaitForChild("LocalSFX");


function TweenRotation(Obj,Rotation,Time,Style) -- gotta do this to rotate the slash because tweening is weird
	local Value = Instance.new("NumberValue")
	local Tween = Tween(Value,{"Value"},Rotation,Time,Style)
	local Changed = 0
	local C1 C1= RunService.RenderStepped:Connect(function()
		Obj.CFrame = Obj.CFrame * CFrame.Angles(0,math.rad(Value.Value-Changed),0)
		Changed = Value.Value
	end)
	local C2 C2 = Tween.Completed:Connect(function()
		C1:Disconnect()
		C2:Disconnect()
		Value:Destroy()
	end)
end

function PlayFlipbook(Decal,Folder, endIndx)
	if endIndx == nil then endIndx = #Folder:GetChildren(); end
	for i=1, endIndx do
		Decal.Texture = Folder[tostring(i)].Texture
		RunService.RenderStepped:Wait();
		RunService.RenderStepped:Wait();
	end
end

function slashEffect(enemyModel, color3)
	local enemyHead = enemyModel:FindFirstChild("HumanoidRootPart");
	if enemyHead == nil then warn("enemy root not found!"); end
	local Slash =  effectsFolder.Slash:Clone()
	Slash.Decal.Color3 = color3;
	Slash.PointLight.Color = color3;
	Slash.Parent = workspace.BattleScene.ClientEffects;
	Slash.CFrame = (enemyHead.CFrame + Vector3.new(0, enemyHead.Size.Y / 2, enemyHead.Size.Z * 1.5)) * CFrame.Angles(math.rad(180),math.rad(180),math.rad(55))
	audioPlayerClient(lPlr, localSFXFolder.SlashSound, 0, false);
	TweenRotation(Slash,-190,.3,Enum.EasingStyle.Quad)
	--coroutine.wrap(function()
	--	wait(.1)
	--	HitEffect(workspace.Dummy.HumanoidRootPart.CFrame * CFrame.Angles(0,math.rad(Rng:NextInteger(-30,30)),math.rad(Rng:NextInteger(-10,-30))),workspace.Dummy)
	--end)()
	local endIndx = math.ceil(#script.Flipbook:GetChildren() / 3);
	PlayFlipbook(Slash.Decal,script.Flipbook, endIndx)
	Slash:Destroy()
end

bindableEventsFolder.AttackEffect.Event:Connect(function(weaponType, enemyModel, imbuedElement)
	if enemyModel == nil then return; end
	local effectColor = Color3.new(1,1,1);
	if imbuedElement == "PYRO" then
		effectColor = Color3.new(1000,.5,0);
	elseif imbuedElement == "ELECTRO" then
		effectColor = Color3.new(1000,120,0);
	elseif imbuedElement == "CRYO" then
		effectColor = Color3.new(1,2,1000);
	end
	if weaponType == "SLASH" then
		coroutine.wrap(function()
			slashEffect(enemyModel, effectColor);
			print(effectColor);
		end)();
		
	elseif weaponType == "WEAPON" then
		audioPlayerClient(lPlr, localSFXFolder.SwingSound, 0, false);
	end
end)

--spawn(function()
--	while wait(1) do
--		local effectColor = Color3.new(1000,.5,0);	
--		local Slash =  effectsFolder.Slash:Clone()
--		Slash.Decal.Color3 = effectColor;
--		Slash.PointLight.Color = effectColor;
--		Slash.Parent = workspace.BattleScene.ClientEffects;
--		Slash.CFrame = (workspace["Radical Radish"].Head.CFrame + Vector3.new(0 ,workspace['Radical Radish'].Head.Size.Y/2 , workspace['Radical Radish'].Head.Size.Z * 1.5)) * CFrame.Angles(math.rad(45*4),math.rad(180),math.rad(55))
--		audioPlayerClient(lPlr, localSFXFolder.SlashSound, 0, false);
--		TweenRotation(Slash,-190,.3,Enum.EasingStyle.Quad)
--		--coroutine.wrap(function()
--		--	wait(.1)
--		--	HitEffect(workspace.Dummy.HumanoidRootPart.CFrame * CFrame.Angles(0,math.rad(Rng:NextInteger(-30,30)),math.rad(Rng:NextInteger(-10,-30))),workspace.Dummy)
--		--end)()
--		local endIndx = #script.Flipbook:GetChildren() / 2;
--		PlayFlipbook(Slash.Decal,script.Flipbook, endIndx)
--		Slash:Destroy()
		
--		local effectColor = Color3.new(1000,120,0);	
--		local Slash =  effectsFolder.Slash:Clone()
--		Slash.Parent = workspace.BattleScene.ClientEffects;
--		Slash.Decal.Color3 = effectColor;
--		Slash.PointLight.Color = effectColor;
--		Slash.CFrame = (workspace["Radical Radish"].Head.CFrame + Vector3.new(0 ,workspace['Radical Radish'].Head.Size.Y/2 , workspace['Radical Radish'].Head.Size.Z * 1.5)) * CFrame.Angles(math.rad(45*4),math.rad(180),math.rad(55))
--		audioPlayerClient(lPlr, localSFXFolder.SlashSound, 0, false);
--		TweenRotation(Slash,-190,.3,Enum.EasingStyle.Quad)
--		--coroutine.wrap(function()
--		--	wait(.1)
--		--	HitEffect(workspace.Dummy.HumanoidRootPart.CFrame * CFrame.Angles(0,math.rad(Rng:NextInteger(-30,30)),math.rad(Rng:NextInteger(-10,-30))),workspace.Dummy)
--		--end)()
--		local endIndx = #script.Flipbook:GetChildren() / 2;
--		PlayFlipbook(Slash.Decal,script.Flipbook, endIndx)
--		Slash:Destroy()
		
--		local effectColor = Color3.new(1,2,1000);	
--		local Slash =  effectsFolder.Slash:Clone()
--		Slash.Parent = workspace.BattleScene.ClientEffects;
--		Slash.Decal.Color3 = effectColor;
--		Slash.PointLight.Color = effectColor;
--		Slash.CFrame = (workspace["Radical Radish"].Head.CFrame + Vector3.new(0 ,workspace['Radical Radish'].Head.Size.Y/2 , workspace['Radical Radish'].Head.Size.Z * 1.5)) * CFrame.Angles(math.rad(45*4),math.rad(180),math.rad(55))
--		audioPlayerClient(lPlr, localSFXFolder.SlashSound, 0, false);
--		TweenRotation(Slash,-190,.3,Enum.EasingStyle.Quad)
--		--coroutine.wrap(function()
--		--	wait(.1)
--		--	HitEffect(workspace.Dummy.HumanoidRootPart.CFrame * CFrame.Angles(0,math.rad(Rng:NextInteger(-30,30)),math.rad(Rng:NextInteger(-10,-30))),workspace.Dummy)
--		--end)()
--		local endIndx = #script.Flipbook:GetChildren() / 2;
--		PlayFlipbook(Slash.Decal,script.Flipbook, endIndx)
--		Slash:Destroy()
--	end	
--end)
