local RS = game:GetService("ReplicatedStorage");
local CollectionService = game:GetService("CollectionService");

local uiStorage = RS.TurnBasedCombat.UIStorage;
local moduleFolder = RS.TurnBasedCombat.Modules;
local bindableEventsFolder = RS.TurnBasedCombat.BindableEvents;

local mouse = require(moduleFolder.mouse);
local util = require(RS.Misc.Util);


local MouseOverModule = require(moduleFolder.MouseHover);




local tipFrame = uiStorage.EffectTooltip:Clone();
tipFrame.Parent = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("TooltipGui");
tipFrame.Visible = false;


bindableEventsFolder.UpdateBuffEntries.Event:Connect(function(plrTeamMembers)
	warn(plrTeamMembers);
	-- first hide all frames
	for a,b in pairs(script.Parent:GetChildren()) do
		if b:IsA("ImageLabel") then
			b.Visible = false;
		end
	end
	
	for i = 1, #plrTeamMembers do
		if script.Parent:FindFirstChild(tostring(i)) then
			local currFrame = script.Parent[tostring(i)];
			currFrame.Visible = true;
			local buffFrame = currFrame.BuffFrame;
			local debuffFrame = currFrame.DebuffFrame;

			local function generateTipTxt(buffCode)
				local result = "";
				-- extract csv
				local effectsArr = util:ExtractCSV(buffCode);
				for j,k in pairs(effectsArr) do
					local separatorIndx = string.find(k, "|");
					print(k, separatorIndx);
					local stat = string.sub(k, 1, separatorIndx - 1);
					local posNegSymbol = string.sub(k, separatorIndx + 1, separatorIndx + 1);
					local changePercent = string.sub(k, separatorIndx + 2);
					result =  result..stat.." "..posNegSymbol..changePercent.."%";
					if posNegSymbol == "+" then -- rich text it with green
						if string.find(stat, "MULTIPLIER") ~= nil then
							result = "<font color=\"rgb(255,50,50)\">"..result.."</font>";
						else
							result = "<font color=\"rgb(50,255,50)\">"..result.."</font>";	
						end
					elseif posNegSymbol == "-" then -- rich text it with red
						if string.find(stat, "MULTIPLIER") ~= nil then
							result = "<font color=\"rgb(50,255,50)\">"..result.."</font>";	
						else
							result = "<font color=\"rgb(255,50,50)\">"..result.."</font>";	
						end	
					else
						error("could not find plus or minus symbol!");
					end
					if j ~= #effectsArr then
						result = result.."<br />";	
					end
				end
				return result;
			end

			-- render buffs/debuffs
			-- first clear all buffs/debuffs renders first
			for j = 1, 4 do
				buffFrame.Container.List[tostring(j)]:SetAttribute("Effect", "");
				buffFrame.Container.List[tostring(j)].Round.ImageColor3 = buffFrame.Container.List[tostring(j)]:GetAttribute("InactiveColor");
				buffFrame.Container.List[tostring(j)].Highlight.Visible = false; 
				buffFrame.Container.List[tostring(j)].Dur.Text = ""; 
				buffFrame.Container.List[tostring(j)].Val.Text = ""; 
				debuffFrame.Container.List[tostring(j)]:SetAttribute("Effect", "");
				debuffFrame.Container.List[tostring(j)].Round.ImageColor3 = buffFrame.Container.List[tostring(j)]:GetAttribute("InactiveColor");
				debuffFrame.Container.List[tostring(j)].Highlight.Visible = false; 
				debuffFrame.Container.List[tostring(j)].Dur.Text = ""; 
				debuffFrame.Container.List[tostring(j)].Val.Text = ""; 	
			end

			-- get player party member at index i
			local currPlayerMember = plrTeamMembers[i];
			
			if currPlayerMember.CURRHP == 0 then
				buffFrame.Outline.DeadGradient.Enabled = true;
				debuffFrame.Outline.DeadGradient.Enabled = true;
			else
				buffFrame.Outline.DeadGradient.Enabled = false;
				debuffFrame.Outline.DeadGradient.Enabled = false;
			end
			
			-- get their buffs table
			local currPlayerBuffs = currPlayerMember.BUFFS;
			local currPlayerDebuffs = currPlayerMember.DEBUFFS;
			warn(currPlayerBuffs)

			for j,k in pairs(currPlayerBuffs) do
				local currBuffCode = k.EFFECTSTR;
				local currEntry = buffFrame.Container.List[tostring(j)];
				local tipTxt = generateTipTxt(currBuffCode);
				currEntry:SetAttribute("Effect", tipTxt);
				currEntry.Round.ImageColor3 = currEntry:GetAttribute("ActiveColor");
				currEntry.Dur.Text = k.DURATION;
				currEntry.Val.Text = k.NAME;
				print(tipTxt);
			end
			for j,k in pairs(currPlayerDebuffs) do
				
				local currBuffCode = k.EFFECTSTR;
				local currEntry = debuffFrame.Container.List[tostring(j)];
				warn(k); warn(currBuffCode);
				local tipTxt = generateTipTxt(currBuffCode);
				currEntry:SetAttribute("Effect", tipTxt);
				currEntry.Round.ImageColor3 = currEntry:GetAttribute("ActiveColor");
				currEntry.Dur.Text = k.DURATION;
				currEntry.Val.Text = k.NAME;
			end


		end
	end	

end)


local mouseEnterConnections = {};
local mouseMovedConnections = {};
local mouseLeaveConnections = {};

for i,v in pairs(script.Parent:GetDescendants()) do
	if tonumber(v.Name) ~= nil and v:IsA("TextButton") then
		local mouseEnterConnection, mouseLeaveConnection = MouseOverModule.MouseEnterLeaveEvent(v);
		mouseEnterConnection:Connect(function()
			if v.Round.ImageColor3 == v:GetAttribute("ActiveColor") then
				tipFrame.Visible = true;
				tipFrame.Tip.Text = v:GetAttribute("Effect");
				v.Highlight.Visible = true;	
			end
		end)
		mouseLeaveConnection:Connect(function()
			tipFrame.Visible = false;
			v.Highlight.Visible = false;
		end)
		local mouseMovedConnection = v.MouseMoved:Connect(function()
			if v.Round.ImageColor3 == v:GetAttribute("ActiveColor") then
				tipFrame.Position = UDim2.new(0, mouse.X + (tipFrame.Size.X.Offset / 6), 0, mouse.Y + (tipFrame.Size.Y.Offset / 2));	
				--print(mouse.X, mouse.Y);
			end
		end)
		table.insert(mouseEnterConnections, mouseEnterConnection); table.insert(mouseMovedConnections, mouseMovedConnection); table.insert(mouseLeaveConnections, mouseLeaveConnection);
	end
end

