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


--[[   Key variables   --]]

--[[ 
NOTE: If all players are either dead or frozen, game over.

	DEAD: Target is dead and cannot act. 
	CURSED: Target speed reduced by 50% and take double damage. 
	BURNED: Players takes 30% of MAXHP at the end of each turn. Enemies take 7% of MAXHP at the end of each turn. 
	BLINDED: Action accuracy is 20% of original accuracy.
	BLEEDING: Players take 12% of MAXHP at the end of each turn. Enemies take 3% of MAXHP at the end of each turn. 
	BINDED: Unable to do certain actions and take 15% more damage.
	FROZEN: Unable to act.
	HEALBLOCKED: Unable to recover HP.
	INFATUATED: May refuse to take orders.
	PANIC: Uncontrollable. 
	PARALYZED: May be be unable to act. SPD reduced by 90%.
	PLAGUE: Player takes 25% of MAXHP at the end of each turn and has a 50% chance to spread to another player in the party, inflicting PLAGUE for 2-4 turns. Enemies are immune.
	POISONED: Player takes 15% of MAXHP at the end of each turn. Enemies take 5% of MAXHP at the end of each turn.	
	SLEEPING: Unable to act.
	
	
--]]


-- ADD SLEEP EFFECT!

local StatusEffectIcons = {
	["DEAD"] = "rbxassetid://6380142502",
	["CURSED"] = "rbxassetid://6380142567",
	["BURNED"] = "rbxassetid://6380142636",
	["BLINDED"] = "rbxassetid://6380142703",
	["BLEEDING"] = "rbxassetid://6380142790",
	["BINDED"] = "rbxassetid://6380142862",
	["FROZEN"] = "rbxassetid://6380142431",
	["HEALBLOCKED"] = "rbxassetid://6380142370",
	["INFATUATED"] = "rbxassetid://6380142293",
	["PANIC"] = "rbxassetid://6380142240",
	["PARALYZED"] = "rbxassetid://6380142163",
	["PLAGUE"] = "rbxassetid://6383962905",
	["POISONED"] = "rbxassetid://6380141972",
	["SLEEPING"] = "rbxassetid://10409675410",
	

	["CURSEDLOGFLAVOR"] = "is cursed!", ["CURSEDLOGFLAVOR2"] = "is cursed for longer!",
	["BURNEDLOGFLAVOR"] = "is burning!", ["BURNEDLOGFLAVOR2"] = "will burn for longer!", 
	["BLINDEDLOGFLAVOR"] = "is blinded!", ["BLINDEDLOGFLAVOR2"] = "is blinded for longer!", 
	["BLEEDINGLOGFLAVOR"] = "is bleeding!", ["BLEEDINGLOGFLAVOR2"] = "is bleeding for longer!",
	["BINDEDLOGFLAVOR"] = "is binded!", ["BINDEDLOGFLAVOR2"] = "is binded for longer!", 
	["FROZENLOGFLAVOR"] = "is frozen solid!", ["FROZENLOGFLAVOR2"] = "is frozen solid for longer!", 
	["HEALBLOCKEDLOGFLAVOR"] = "cannot recover HP!", ["HEALBLOCKEDLOGFLAVOR2"] = "cannot recover HP for longer!",
	["INFATUATEDLOGFLAVOR"] = "is infatuated!", ["INFATUATEDLOGFLAVOR2"] = "is infatuated for longer!",
	["PANICLOGFLAVOR"] = "is panicking!", ["PANICLOGFLAVOR2"] = "is panicking for longer!", 
	["PARALYZEDLOGFLAVOR"] = "is paralyzed!", ["PARALYZEDLOGFLAVOR2"] = "is paralyzed for longer!",
	["PLAGUELOGFLAVOR"] = "caught the plague!", ["PLAGUELOGFLAVOR2"] = "caught the plague for longer!", 
	["POISONEDLOGFLAVOR"] = "is poisoned!", ["POISONEDLOGFLAVOR2"] = "is poisoned for longer!", 
	["SLEEPINGLOGFLAVOR"] = "fell asleep!", ["SLEEPINGLOGFLAVOR2"] = "fell asleep for longer!", 
	
	
	
	
	
	
	["DEADCOLOR"] = Color3.new(1, 0, 0),
	["CURSEDCOLOR"] = Color3.new(140/255, 0, 1),
	["BURNEDCOLOR"] = Color3.new(255/255, 65/255, 0/255),
	["BLINDEDCOLOR"] = Color3.new(255/255, 100/255, 255/255),
	["BLEEDINGCOLOR"] = Color3.new(1, 0, 0),
	["BINDEDCOLOR"] = Color3.new(0, 0, 1),
	["FROZENCOLOR"] = Color3.new(0, 1, 1),
	["HEALBLOCKEDCOLOR"] = Color3.new(1, 0, 0),
	["INFATUATEDCOLOR"] = Color3.new(255/255, 102/255, 204/255),
	["PANICCOLOR"] = Color3.new(255/255, 170/255, 0/255),
	["PARALYZEDCOLOR"] = Color3.new(1, .75, 0),
	["PLAGUECOLOR"] = Color3.new(0, 1, 0),
	["POISONEDCOLOR"] = Color3.new(0, .5, 0),
	["NONECOLOR"] = Color3.new(1,1,1),
	["SLEEPINGCOLOR"] = Color3.new(1, 1, 0),
}
return StatusEffectIcons;
