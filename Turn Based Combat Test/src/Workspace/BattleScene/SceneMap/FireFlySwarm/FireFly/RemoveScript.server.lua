-- Remove the fly when it flew too far from the center.

local Fly = script.Parent
local Model = script.Parent.Parent
local Range = Model.Configuration.FlyRange

while true do
	wait(5)
	if (Fly.Position - Model.Center.CenterPart.Position).magnitude > Range.Value then 
		Fly.GlowScript.Disabled = true
		Fly.MoveScript.Disabled = true
		Fly:destroy()
		break
	end
end