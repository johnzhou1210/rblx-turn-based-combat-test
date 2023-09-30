colors = {Color3.new(1*255,0,1*255), Color3.new(1*255,1*255,1*255), Color3.new(0,1*255,1*255)};

-- ReplicatedStorage --
function CircleClick(Button, X, Y)
	coroutine.resume(coroutine.create(function()
		
		--Button.ClipsDescendants = true
		
		local Circle = script:WaitForChild("Circle"):Clone()
			Circle.Parent = Button
			local NewX = X - Circle.AbsolutePosition.X
			local NewY = Y - Circle.AbsolutePosition.Y
			Circle.Position = UDim2.new(0, NewX, 0, NewY)
			Circle.ImageColor3 = colors[Random.new():NextInteger(1,#colors)];
		local Size = 0
			if Button.AbsoluteSize.X > Button.AbsoluteSize.Y then
				 Size = Button.AbsoluteSize.X*1.5
			elseif Button.AbsoluteSize.X < Button.AbsoluteSize.Y then
				 Size = Button.AbsoluteSize.Y*1.5
			elseif Button.AbsoluteSize.X == Button.AbsoluteSize.Y then																										Size = Button.AbsoluteSize.X*1.5
			end
		
		local Time = 0.5
			Circle:TweenSizeAndPosition(UDim2.new(0, Size, 0, Size), UDim2.new(0.5, -Size/2, 0.5, -Size/2), "Out", "Quad", Time, false, nil)
			for i=1,10 do
				Circle.ImageTransparency = Circle.ImageTransparency + 0.05
				wait(Time/10)
			end
			Circle:Destroy()
			
	end))
end

return CircleClick