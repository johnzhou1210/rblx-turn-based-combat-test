script.Parent.No.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		script.Parent.No.Round.UIGradient.Enabled = false;
	end
end)

script.Parent.No.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		script.Parent.No.Round.UIGradient.Enabled = true;
	end
end)

script.Parent.Yes.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		script.Parent.Yes.Round.UIGradient.Enabled = false;
	end
end)

script.Parent.Yes.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		script.Parent.Yes.Round.UIGradient.Enabled = true;
	end
end)