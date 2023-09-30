-- Controls the glow of a firefly

local Configurations = script.Parent.Parent.Configuration -- Variables for configurations
local Brightness = Configurations.Brightness
local glowTime = Configurations.GlowTime
local notGlowTime = Configurations.NotGlowTime
local glowSpeed = Configurations.GlowSpeed
local glowRange = Configurations.GlowRange
local lightColor = Configurations.Color

local Fly = script.Parent

Fly.PointLight.Color = lightColor.Value -- Initialize light and collor settings
Fly.PointLight.Range = glowRange.Value
Fly.PointLight.Enabled = true

while true do
	Fly.BrickColor = BrickColor.new(lightColor.Value) -- Change color of the fly to make it properly visible when the light will glow
	for i = 1, Brightness.Value*10 do -- Slowly build strength of the light
		Fly.PointLight.Brightness = 0 + i*0.1
		Fly.Transparency = 0.5 - (0.5 * i)/(Brightness.Value*10)
		wait(1/(glowSpeed.Value*Brightness.Value*10))
	end
	wait(glowTime.Value+math.random(-10,10)*0.1) -- Wait for light to glow for some time
	for i = 1, Brightness.Value*10 do -- Slowly drop strength of the light
		Fly.PointLight.Brightness = Brightness.Value - i*0.1
		Fly.Transparency = (0.5 * i)/(Brightness.Value*10)
		wait(1/(glowSpeed.Value*Brightness.Value*10))
	end
	Fly.BrickColor = BrickColor.new("Really black") -- Make the fly dark, as it's dark without a light
	wait(notGlowTime.Value+math.random(-10,10)*0.1) -- Wait for light to be off for some time
end

