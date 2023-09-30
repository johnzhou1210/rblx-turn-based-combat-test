-- Spawn a new firefly from the center when one flew too far

local Model = script.Parent

local Fly = Model.FireFly:Clone() -- Clone a fly from the start

Model.ChildRemoved:connect(function() -- When a fly got removed when he flew too far, paste a clone to spawn a new one
	local newFly = Fly:Clone()
	newFly.Position = Model.Center.CenterPart.Position
	newFly.Parent = Model
end)