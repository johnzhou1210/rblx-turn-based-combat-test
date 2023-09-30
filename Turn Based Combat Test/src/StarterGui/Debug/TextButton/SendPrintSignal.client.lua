script.Parent.Activated:Connect(function()
	game:GetService("ReplicatedStorage").TurnBasedCombat.RemoteEvents.BattleSystem.PrintParty:FireServer();
end)