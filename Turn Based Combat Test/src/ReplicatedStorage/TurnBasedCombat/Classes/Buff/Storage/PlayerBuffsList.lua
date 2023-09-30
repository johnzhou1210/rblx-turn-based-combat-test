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

THESE STATS CAN BE MODIFIED:
CURRPATK
CURRMATK
CURRPDEF
CURRMDEF
CURREVA
CURRSPD
CURRCRITRATE
CURRCRITDAMAGE

CURRINSTANTDEATHRES
CURRCURSEDRES
CURRBURNEDRES
CURRBLINDEDRES
CURRBLEEDINGRES
CURRBINDEDRES
CURRFROZENRES
CURRHEALBLOCKEDRES
CURRINFATUATEDRES
CURRPANICRES
CURRPARALYZEDRES
CURRPLAGUERES
CURRPOISONEDRES
CURRSLEEPINGRES
CURRPYRORESMULTIPLIER
CURRCRYORESMULTIPLIER
CURRELECTRORESMULTIPLIER
CURRSLASHRESMULTIPLIER
CURRCRUSHRESMULTIPLIER
CURRSTABRESMULTIPLIER

log flavor based on intensity
FOR NON PERCENT STATS (ATTACK, DEFENCE, AND SPEED) CRIT DAMAGE uses this instead of the one below:
+/- 1-5%: [DISPLAYNAME]'s [STAT] increased/decreased by a tiny bit! 
+/- 6-20% [DISPLAYNAME]'s [STAT] increased/decreased slightly!
+/- 21-40% [DISPLAYNAME]'s [STAT] increased/decreased moderately!
+/- 41-70% [DISPLAYNAME]'s [STAT] increased/decreased significantly!
+/- 71-99% [DISPLAYNAME]'s [STAT] increased/decreased greatly!
+/- >99% [DISPLAYNAME]'s [STAT] increased/decreased massively!

FOR PERCENT STATS (EVASION AND CRIT RATE) Exception with CRIT DAMAGE:

+/- 1-4%: [DISPLAYNAME]'s [STAT] increased/decreased by a tiny bit! 
+/- 5-11% [DISPLAYNAME]'s [STAT] increased/decreased slightly!
+/- 12-24% [DISPLAYNAME]'s [STAT] increased/decreased moderately!
+/- 25-45% [DISPLAYNAME]'s [STAT] increased/decreased significantly!
+/- 46-75% [DISPLAYNAME]'s [STAT] increased/decreased greatly!
+/- >75% [DISPLAYNAME]'s [STAT] increased/decreased massively!
	
--]]



local BuffsList = {


	["War Cry"] = 'PATK|+25,MATK|+25',
	["Divine Barrier"] = 'PDEF|+360,MDEF|+360,PYRORESMULTIPLIER|-.5,CRYORESMULTIPLIER|-.5,ELECTRORESMULTIPLIER|-.5',
	["Accelerate"] = 'SPD|+50,EVA|+25',
	["Calm Mind"] = 'CRITRATE|+50,CRITDAMAGE|+100,PDEF|-80',
	["Magic Amplification"] = 'MATK|+80',



}
return BuffsList;
