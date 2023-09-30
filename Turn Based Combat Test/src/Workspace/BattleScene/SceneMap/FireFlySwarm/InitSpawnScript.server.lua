-- Spawn up to a amount of flies at the beginning

local Model = script.Parent
local Amount = Model.Configuration.Amount

local Fly = Model.FireFly:Clone() -- Clone a fly from the start
Model.Center.CenterPart.Transparency = 1 -- Make the center part invisible. It has no purpose when the game runs

if Amount.Value > 1 then
	for i = 1, Amount.Value-1 do -- Spawn up to Amount new flies
		newFly = Fly:Clone()
		newFly.Position = Model.Center.CenterPart.Position
		newFly.Parent = Model
	end
end