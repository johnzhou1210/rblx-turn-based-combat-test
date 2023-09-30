local EnemyLayouts = {};

EnemyLayouts['Twilight Forest'] = {
	["Area 1"] = {
		{ {'Radical Radish'} , 1},
		{ {'Radical Radish', 'Radical Radish'} , 2.5},
		{ {'Radical Radish', 'Radical Radish', 'Radical Radish'} , 1.25},
		{ {'Radical Radish', 'Radical Radish', 'Radical Radish', 'Radical Radish', 'Radical Radish', 'Radical Radish'} , .45},
		{ {'Radical Radish', 'Radical Radish', 'Radical Radish', 'Radical Radish', 'Chonk Birb', 'Radical Radish', 'Radical Radish', 'Radical Radish', 'Radical Radish'} , .35},
		{ {'Chonk Birb'} , 1},
		--{ {'Radical Radish','Radical Radish','Chonk Birb','Radical Radish','Radical Radish'} , 1000000000},
		{ {'Radical Radish', 'Chonk Birb', 'Radical Radish'} , 1.25},
		{ {'Chonk Birb', 'Chonk Birb'} , .45},
		{ {'Chonk Birb', 'Chonk Birb', 'Chonk Birb', 'Chonk Birb'} ,  .1}, -- nightmare scenario
		
	},
	["Boss"] = {
		{{'Chonk Birb', 'Chonk Birb Lord', 'Chonk Birb'} , 1},
	},
};

	


return EnemyLayouts;
