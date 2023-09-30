--[[   Service dependencies   --]]
local RS = game:GetService("ReplicatedStorage");

--[[   Folder references   --]]
local TBCFolder = RS.TurnBasedCombat;
local moduleFolder = TBCFolder.Modules;
local classesFolder = TBCFolder.Classes;
local miscFolder = RS.Misc;

--[[   External dependencies   --]]
local util = require(miscFolder.Util);

--[[   Class dependencies   --]]
local Weapon = require(classesFolder.Item.Weapon);



--[[   Key variables   --]]

--WIP
local WeaponsList = {
	["Old Katana"] = {
		['NAME'] = 'Old Katana',
		['MONEYVALUE'] = 5,
		['CANDISCARD'] = true,
		['DESCRIPTION'] = 'An invaluable old and worn-out katana.';
		['PATK'] = 8,
		['MATK'] = 0,
		['TARGETTYPE'] = 'SINGLE',
		['SPEEDPRIORITY'] = 'NONE',
		['HPCOST'] = 0,
		['IMBUEDELEMENT'] = 'NONE',
		['DAMAGETYPE'] = 'SLASH',
		['BUFFS'] = {},
		['CRITRATEMODIFIER'] = 0,
		['NUMUSES'] = math.huge,
		['USEFLAVOR'] = '...but nothing happened!'
	},
	["Rusty Mace"] = {
		['NAME'] = 'Rusty Mace',
		['MONEYVALUE'] = 5,
		['CANDISCARD'] = true,
		['DESCRIPTION'] = 'An invaluable old and worn-out mace.';
		['PATK'] = 6,
		['MATK'] = 0,
		['TARGETTYPE'] = 'SINGLE',
		['SPEEDPRIORITY'] = 'NONE',
		['HPCOST'] = 0,
		['IMBUEDELEMENT'] = 'NONE',
		['DAMAGETYPE'] = 'CRUSH',
		['BUFFS'] = {},
		['CRITRATEMODIFIER'] = 0,
		['NUMUSES'] = math.huge,
		['USEFLAVOR'] = '...but nothing happened!'
	},
	["Worn-out Lance"] = {
		['NAME'] = 'Worn-out Lance',
		['MONEYVALUE'] = 5,
		['CANDISCARD'] = true,
		['DESCRIPTION'] = 'An invaluable old and worn-out lance.';
		['PATK'] = 11,
		['MATK'] = 0,
		['TARGETTYPE'] = 'SINGLE',
		['SPEEDPRIORITY'] = 'NONE',
		['HPCOST'] = 0,
		['IMBUEDELEMENT'] = 'NONE',
		['DAMAGETYPE'] = 'STAB',
		['BUFFS'] = {},
		['CRITRATEMODIFIER'] = 0,
		['NUMUSES'] = math.huge,
		['USEFLAVOR'] = '...but nothing happened!'
	},
	["Novice Staff"] = {
		['NAME'] = 'Novice Staff',
		['MONEYVALUE'] = 5,
		['CANDISCARD'] = true,
		['DESCRIPTION'] = 'An invaluable old and worn-out staff once used by a beginner.';
		['PATK'] = 3,
		['MATK'] = 10,
		['TARGETTYPE'] = 'SINGLE',
		['SPEEDPRIORITY'] = 'NONE',
		['HPCOST'] = 0,
		['IMBUEDELEMENT'] = 'NONE',
		['DAMAGETYPE'] = 'CRUSH',
		['BUFFS'] = {},
		['CRITRATEMODIFIER'] = 0,
		['NUMUSES'] = math.huge,
		['USEFLAVOR'] = '...but nothing happened!'
	},
	
	
};

return WeaponsList;


