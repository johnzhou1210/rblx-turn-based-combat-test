
local RunService = game:GetService("RunService");

local Util = {}

function Util:Dist2D(x1, y1, x2, y2)
	return math.sqrt(math.pow(x1 - x2, 2) + math.pow(y1 - y2, 2));
end

function Util:TableCopy(arr)
	local result = {};
	for i,v in pairs(arr) do
		table.insert(result, v);
	end
	return result;
end

function Util:IndexOf(arr, elem)
	for i,v in pairs(arr) do
		if v == elem then
			return i;
		end
	end
	return -1;
end

function Util:RandBias(low, high, bias) -- higher bias favors low number and vice versa where 1 is neutral
	local rng = Random.new():NextNumber(0,1);
	rng = math.pow(rng, bias);
	return low + (high - low) * rng;
end

function Util:GetFirstExistingElement(arr)
	for i,v in pairs(arr) do
		if arr[i] then
			return v;
		end
	end
	return nil;
end

function Util:RgbTo255(color3)
	return math.floor(color3.R * 255)..","..math.floor(color3.G * 255)..","..math.floor(color3.B * 255);
end

function Util:Sleep(seconds, bool)
	if bool then
		seconds = seconds or 0;
		local start = tick();
		repeat
			RunService.Stepped:Wait();
		until
		(tick() - start) >= seconds;
	end
end

function Util:TableSlice(tbl, first, last, step)
	if last > #tbl then warn("tableSlice index out of bounds (right bound)! Returning nil..."); return nil; end
	if first > #tbl then warn("tableSlice index out of bounds (left bound)! Returning nil..."); return nil; end
	local sliced = {};
	for i = first or 1, last or #tbl, step or 1 do
		sliced[#sliced+1] = tbl[i];
	end
	return sliced;
end

function Util:StringifyBool(bool)
	if type(bool) == type("string") then error("Invalid stringifyBool parameter! (The parameter is a string)"); end
	if bool == true then
		return "true";
	end
	return "false";
end

function Util:DestringifyBool(str)
	if type(str) == type(true) then error("Invalid destringifyBool parameter! (The parameter is a bool)"); end
	if str == "true" then
		return true;
	elseif str == "false" then
		return false;
	end
	error("Canot destringify! Parameter is "..tostring(str));
end

function Util:Choice(arr)
	return arr[Random.new():NextInteger(1, #arr)];
end

function Util:ExtractCSV(str)
	local result = {};
	local i = 1;
	local lastCutPoint = 1;
	if str == "" then return result; end
	while i <= string.len(str) do
		local currChar = string.sub(str, i, i);
		if currChar == "," then -- append all values before the comma into the result arr
			local thingToAppend = string.sub(str, lastCutPoint, i-1);
			table.insert(result, thingToAppend);
			lastCutPoint = i + 1;
		end
		i = i + 1;
	end
	local lastThingToAppend = string.sub(str, lastCutPoint, string.len(str));
	table.insert(result, lastThingToAppend)
	return result;
end

function Util:ConvertArrToCSVStr(arr)
	local resultString = "";
	for i,v in pairs(arr) do
		if i + 1 ~= #arr and #arr >= 3 and i ~= #arr then
			resultString = resultString..v..", ";
		elseif i + 1 == #arr and #arr == 2 then
			resultString = resultString..v.." and ";
		elseif i + 1 == #arr and #arr > 2 then
			resultString = resultString..v..", and ";
		elseif #arr == 1 or i == #arr then
			resultString = resultString..v;
		else
			error("WE HAVE A PROBLEM IN CONVERTARRTOCSVSTR() METHOD!");
		end
	end
	return resultString;
end

function Util:RoundApprox(num)
	return math.floor(num+.5);
end

return Util;
