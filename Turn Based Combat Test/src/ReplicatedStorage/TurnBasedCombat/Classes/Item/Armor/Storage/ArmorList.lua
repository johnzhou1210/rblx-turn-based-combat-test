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
	["Tweed"] = {
		['NAME'] = 'Tweed',
		['MONEYVALUE'] = 5,
		['CANDISCARD'] = true,
		['DESCRIPTION'] = 'An invaluable old and worn-out peasant clothing.';
		['PDEF'] = 3,
		['MDEF'] = 2,
		['NUMUSES'] = math.huge,
		['USEFLAVOR'] = '...but nothing happened!'
	},
	
	
};

return WeaponsList;


