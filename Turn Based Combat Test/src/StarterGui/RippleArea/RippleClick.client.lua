local Mouse = game.Players.LocalPlayer:GetMouse()
local CircleClick = require(game.ReplicatedStorage:WaitForChild("Misc"):WaitForChild("CircleClick")); 

game:GetService("UserInputService").InputBegan:connect(function(input, gpe)
	--if gpe then return; end
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		-- create a small frame on that area
		coroutine.wrap(function()
			local frame = Instance.new("ImageButton");
			frame.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("RippleArea");
			frame.Size = UDim2.new(0,80,0,80);
			frame.Active = false;
			frame.Selectable = false;
			frame.Modal = true;
			frame.BackgroundTransparency = 1;
			frame.Position = UDim2.new(0,Mouse.X,0,Mouse.Y);
			frame.AnchorPoint = Vector2.new(.5,.5);
			frame.ImageTransparency = 1;
			CircleClick(frame, Mouse.X, Mouse.Y) 
			game:GetService("Debris"):AddItem(frame, 1);
			--print("clicked")	
		end)()
		
	end 
end)


