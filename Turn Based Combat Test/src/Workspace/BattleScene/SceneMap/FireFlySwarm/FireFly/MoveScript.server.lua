-- Adjust the movement of the firefly, allowing them to roam around.

local Fly = script.Parent

while true do -- Alter the flies movement direction every once a while to make it roam around
	Fly.BodyVelocity.velocity = Vector3.new(math.random(-20,20)*0.1,math.random(-20,20)*0.1,math.random(-20,20)*0.1)
	wait(math.random(10,25)*0.1)
end