--[[   Service dependencies   --]]
local RS = game:GetService("ReplicatedStorage");

--[[   Folder references   --]]
local TBCFolder = RS.TurnBasedCombat;
local moduleFolder = TBCFolder.Modules;
local classesFolder = TBCFolder.Classes;
local miscFolder = RS.Misc;

--[[   External dependencies   --]]
--[[   Class dependencies   --]]
local GameObject = require(miscFolder.GameObject);
local AudioPlayerClient = GameObject:extend();

--[[   Key variables   --]]


function AudioPlayerClient:new(lPlr, sound, startTime, isMusic, endTime, customVolume) -- playOnCreation must be reusable
	local mainGUI = lPlr:WaitForChild("PlayerGui"):WaitForChild("MainGUI");
	self.isMusic = isMusic;
	self.audioSource = sound:Clone();
	self.audioSource.Parent = mainGUI:WaitForChild("SoundDebris");
	self.audioSource.TimePosition = startTime;
	self.audioSource.Volume = sound.Volume or customVolume;
	if not isMusic then
		self.audioSource.TimePosition = startTime; self.audioSource:Play();	
		--print("played",sound,"with volume",self.audioSource.Volume);
		if not self.audioSource.Looped then
			game:GetService("Debris"):AddItem(self.audioSource, self.audioSource.TimeLength + 2);	
		end
	end
	local stopCoro = coroutine.wrap(function()
		while self ~= nil do
			game:GetService("RunService").RenderStepped:Wait();
			-- print(self.audioSource.TimePosition);
			if self.audioSource.TimePosition >= endTime then
				-- warn("in here")
				if isMusic then 
					self.audioSource.TimePosition = startTime;
				else
					self.audioSource:Stop();
				end
			end
		end
	end)
	if endTime ~= nil then stopCoro(); end
end

function AudioPlayerClient:Stop()
	if self.audioSource ~= nil and self.isMusic then
		self.audioSource:Stop();
	end
end

function AudioPlayerClient:Play()
	if self.audioSource ~= nil and self.isMusic then
		self.audioSource:Play();
	end
end

function AudioPlayerClient:Pause()
	if self.audioSource ~= nil and self.isMusic then
		self.audioSource:Pause();
	end
end

function AudioPlayerClient:Resume()
	if self.audioSource ~= nil and self.isMusic then
		self.audioSource:Resume();
	end
end

function AudioPlayerClient:SetVolume(newVal)
	if self.audioSource ~= nil and self.isMusic then
		self.audioSource.Volume = newVal;
	end
end

return AudioPlayerClient;