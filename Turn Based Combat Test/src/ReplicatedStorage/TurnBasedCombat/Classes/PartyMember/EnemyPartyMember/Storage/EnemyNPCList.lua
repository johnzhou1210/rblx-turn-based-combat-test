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

--[[ NOTE: THE LOWER THE RESMULTIPLIER, THE MORE RESISTANT THEY ARE TO THE ELEMENT. 1 is neutral, 0 is immune, (1,inf) is weak, (0,1) is resistant
EnemyPartyMember(String name,
				 string desc,
				 int hp, int pAtk, int mAtk, int pDef, int mDef, int agi, int exp, int[] drops, int eva,
				 int pyroResMultiplier, int cryoResMultiplier, int electroResMultiplier, String[] immunities, int critRate)

--]]

local EnemyNPCList = {
	["Radical Radish"] = 
		{
			["NAME"] = "Radical Radish",
			["DESCRIPTION"] = "An agressive root vegetable that haunts the outskirts of the Twilight Forest. Adventurers often meet this creature in their very first battle in the Abyss.", 
			["HP"] = 55,
			["PATK"] = 11,
			["MATK"] = 3,
			["PDEF"] = 10,
			["MDEF"] = 3,
			["AGI"] = 9,
			["EXP"] = 7,
			["DROPS"] = {},
			["EVA"] = 5,
			["PYRORESMULTIPLIER"] = 2,
			["CRYORESMULTIPLIER"] = 2,
			["ELECTRORESMULTIPLIER"] = 1,
			["IMMUNITIES"] = {},
			["CRITRATE"] = 5,
			
			['INSTANTDEATHRES'] = 25,
			['CURSEDRES'] = 0,
			['BURNEDRES'] = 0,
			['BLINDEDRES'] = 0,
			['BLEEDINGRES'] = 0,
			['BINDEDRES'] = 25,
			['FROZENRES'] = 0,
			['HEALBLOCKEDRES'] = 0,
			['INFATUATEDRES'] = 75,
			['PANICRES'] = 100,
			['PARALYZEDRES'] = 50,
			['POISONEDRES'] = 100,
			
			['SLASHRESMULTIPLIER'] = 1.5,
			['CRUSHRESMULTIPLIER'] = 1,
			['STABRESMULTIPLIER'] = 1,
			['EFFECTRESMULTIPLIER'] = 1,
		},
	["Chonk Birb"] = 
		{
			["NAME"] = "Chonk Birb",
			["DESCRIPTION"] = "An obeese human-eating bird that haunts the lower floors of the Twilight Forest. Most of the time, it loafs around. But beware, this does mean you're safe!", 
			["HP"] = 145,
			["PATK"] = 24,
			["MATK"] = 8,
			["PDEF"] = 12,
			["MDEF"] = 10,
			["AGI"] = 3,
			["EXP"] = 21,
			["DROPS"] = {},
			["EVA"] = 2,
			["PYRORESMULTIPLIER"] = .5,
			["CRYORESMULTIPLIER"] = .5,
			["ELECTRORESMULTIPLIER"] = 2,
			["IMMUNITIES"] = {},
			["CRITRATE"] = 40,
			
			['INSTANTDEATHRES'] = 50,
			['CURSEDRES'] = 50,
			['BURNEDRES'] = 0,
			['BLINDEDRES'] = 0,
			['BLEEDINGRES'] = 0,
			['BINDEDRES'] = 0,
			['FROZENRES'] = 50,
			['HEALBLOCKEDRES'] = 0,
			['INFATUATEDRES'] = 50,
			['PANICRES'] = 50,
			['PARALYZEDRES'] = 50,
			['POISONEDRES'] = 50,
			
			['SLASHRESMULTIPLIER'] = 1,
			['CRUSHRESMULTIPLIER'] = .5,
			['STABRESMULTIPLIER'] = 1.5,
			['EFFECTRESMULTIPLIER'] = 1,
		},
	["Chonk Birb Lord"] = 
		{
			["NAME"] = "Chonk Birb Lord",
			["DESCRIPTION"] = "The overseer of Twilight Forest's chonk birbs. Like other chonk birbs, the chonk birb lord loafs around most of the time. You know what to look out for...", 
			["HP"] = 1800,
			["PATK"] = 36,
			["MATK"] = 20,
			["PDEF"] = 16,
			["MDEF"] = 14,
			["AGI"] = 5,
			["EXP"] = 200,
			["DROPS"] = {},
			["EVA"] = 2,
			["PYRORESMULTIPLIER"] = 0,
			["CRYORESMULTIPLIER"] = .5,
			["ELECTRORESMULTIPLIER"] = 2,
			["IMMUNITIES"] = {},
			["CRITRATE"] = 40,

			['INSTANTDEATHRES'] = 100,
			['CURSEDRES'] = 100,
			['BURNEDRES'] = 100,
			['BLINDEDRES'] = 0,
			['BLEEDINGRES'] = 0,
			['BINDEDRES'] = 0,
			['FROZENRES'] = 50,
			['HEALBLOCKEDRES'] = 0,
			['INFATUATEDRES'] = 75,
			['PANICRES'] = 100,
			['PARALYZEDRES'] = 50,
			['POISONEDRES'] = 50,

			['SLASHRESMULTIPLIER'] = 1,
			['CRUSHRESMULTIPLIER'] = .5,
			['STABRESMULTIPLIER'] = 1.5,
			['EFFECTRESMULTIPLIER'] = 1,

	

			
		},
};



return EnemyNPCList;
