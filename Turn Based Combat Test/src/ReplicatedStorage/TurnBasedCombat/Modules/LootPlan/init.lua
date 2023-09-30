-- Original Module can be found at - roblox.com/library/4710697524/LootPlan
-- API Documentation can be found at - https://devforum.roblox.com/t/lootplan-random-loot-generation-made-easy/463702
-- Two example scripts can be found within the explorer, inside this module

local LootPlan = {}

--> SingleLootPlan Class <--

local SingleLootPlan = {}
SingleLootPlan.__index = SingleLootPlan

function SingleLootPlan.new(seed)
	local SingleLootPlan = setmetatable({},SingleLootPlan)
	SingleLootPlan.Randomizer = Random.new()
	SingleLootPlan.Loot = {}
	SingleLootPlan.TotalChance = 0
	return SingleLootPlan
end

function SingleLootPlan:AddLoot(name, chance)
	self.TotalChance = self.TotalChance + chance
	local newLoot = {
		name = name;
		chance = chance;
	}
	self.Loot[name] = newLoot
	return newLoot
end

function SingleLootPlan:GetLootChance(name)
	local loot = self.Loot[name]
	if loot then
		return loot.chance
	else
		error("Loot with name '"..tostring(name).."' does not exist")
	end
end

function SingleLootPlan:GetTrueLootChance(name)
	return (self.Loot[name]/self.TotalChance)*100
end

function SingleLootPlan:RemoveLoot(name)
	self.TotalChance = self.TotalChance - self.Loot[name].chance
	self.Loot[name]=nil
end

function SingleLootPlan:ChangeLootChance(name, chance)
	self:RemoveLoot(name)
	return self:AddLoot(name,chance)
end

function SingleLootPlan:GetRandomLoot()
	local result = self.Randomizer:NextNumber()
	local aggregate = 0
	for name,loot in pairs(self.Loot) do
		if result < (loot.chance + aggregate)/self.TotalChance then
			return name
		end
		aggregate = aggregate + loot.chance
	end
end

--> MultiLootPlan Class <--

local MultiLootPlan = {}
MultiLootPlan.__index = MultiLootPlan

function MultiLootPlan.new(seed)
	local MultiLootPlan = setmetatable({},MultiLootPlan)
	MultiLootPlan.Randomizer = Random.new(seed or tick())
	MultiLootPlan.Loot = {}
	return MultiLootPlan
end

function MultiLootPlan:AddLoot(name, chance) 
	local newLoot = {
		name = name;
		chance = chance;
	}
	self.Loot[name]=newLoot
	return newLoot
end

function MultiLootPlan:GetLootChance(name)
	local loot = self.Loot[name]
	if loot then
		return loot.chance
	else
		error("Loot with name '"..tostring(name).."' does not exist")
	end
end

function MultiLootPlan:RemoveLoot(name)
	self.Loot[name]=nil
end

function MultiLootPlan:ChangeLootChance(name, newChance)
	self.Loot[name].chance = newChance
end

function MultiLootPlan:GetRandomLoot(iterations) -- iterations optional, defaults to 1 when not provided
	local LootTable = {}
	for i = 1,iterations or 1 do
		for name,loot in pairs(self.Loot) do 
			local result = self.Randomizer:NextNumber()
			if result < loot.chance/100 then
				LootTable[name] = LootTable[name] and LootTable[name]+1 or 1
			end
		end
	end
	return LootTable
end

--> LootPlan Creator <--

function LootPlan.new(class, seed)
	if not class or class == "single" then -- class defaults to "single" if no class provided
		return SingleLootPlan.new(seed)
	elseif class == "multi" then
		return MultiLootPlan.new(seed)
	end
end

return LootPlan