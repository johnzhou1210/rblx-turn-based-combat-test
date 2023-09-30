local RS = game:GetService("ReplicatedStorage");
local CollectionService = game:GetService("CollectionService");

local uiStorage = RS.TurnBasedCombat.UIStorage;
local moduleFolder = RS.TurnBasedCombat.Modules;
local bindableEventsFolder = RS.TurnBasedCombat.BindableEvents;

local util = require(RS.Misc.Util);



bindableEventsFolder.UpdateStatPreviews.Event:Connect(function(plrTeamMembers)
	warn(plrTeamMembers);
	-- first hide all frames
	for a,b in pairs(script.Parent:GetChildren()) do
		if b:IsA("ImageLabel") then
			b.Visible = false;
		end
	end
	
	
	
	for i = 1, #plrTeamMembers do
		if script.Parent:FindFirstChild(tostring(i)) then
			local currFrame = script.Parent:FindFirstChild(tostring(i));
			currFrame.Visible = true;
			local currPartyMember = plrTeamMembers[i];
			local statsFrame = currFrame.StatsFrame;
			local container = statsFrame.ScrollingFrame
			
			if currPartyMember.CURRHP == 0 then
				statsFrame.Outline.DeadGradient.Enabled = true;
			else
				statsFrame.Outline.DeadGradient.Enabled = false;
			end
			
			local function compareWithInnateStat(statName, isMultiplierStat)
				if isMultiplierStat then
					-- using round approx is not good here
					if math.abs(currPartyMember["CURR"..statName] - currPartyMember[statName]) <= .001 then -- close enough
						return "<font color=\"rgb(255,244,155)\">";
					else
						if currPartyMember["CURR"..statName] > currPartyMember[statName] then -- curr stat is greater than innate stat
							return "<font color=\"rgb(255,50,50)\">";
						else -- curr stat is less than innate stat
							return "<font color=\"rgb(50,255,50)\">";
						end
					end
				end
				if util:RoundApprox(currPartyMember["CURR"..statName]) > currPartyMember[statName] then
					return "<font color=\"rgb(50,255,50)\">";
				elseif util:RoundApprox(currPartyMember["CURR"..statName]) < currPartyMember[statName] then
					return "<font color=\"rgb(255,50,50)\">";
				else
					return "<font color=\"rgb(255,244,155)\">";
				end
			end
			
			
			container.Desc.Text = currPartyMember.Description;
			container.LevelNum.Text = currPartyMember.LEVEL;
			
			local stat = container.Stats
			local statContainer = stat.Frame
			statContainer.PATKAmt.Text = compareWithInnateStat("PATK", false)..tostring(util:RoundApprox(currPartyMember.CURRPATK)).."</font>";
			statContainer.MATKAmt.Text = compareWithInnateStat("MATK", false)..tostring(util:RoundApprox(currPartyMember.CURRMATK)).."</font>";
			statContainer.PDEFAmt.Text = compareWithInnateStat("PDEF", false)..tostring(util:RoundApprox(currPartyMember.CURRPDEF)).."</font>";
			statContainer.MDEFAmt.Text = compareWithInnateStat("MDEF", false)..tostring(util:RoundApprox(currPartyMember.CURRMDEF)).."</font>";
			statContainer.SPDAmt.Text = compareWithInnateStat("SPD", false)..tostring(util:RoundApprox(currPartyMember.CURRSPD)).."</font>";
			statContainer.EVAAmt.Text = compareWithInnateStat("EVA", false)..string.format("%.1f", currPartyMember.CURREVA).."%</font>";
			statContainer.CRITRAmt.Text = compareWithInnateStat("CRITRATE", false)..string.format("%.1f", currPartyMember.CURRCRITRATE).."%</font>";
			statContainer.CRITDAmt.Text = compareWithInnateStat("CRITDAMAGE", false)..string.format("%.1f", currPartyMember.CURRCRITDAMAGE).."%</font>";
			
		
			local statusEffectFrame = container.StatusEffectFrame
			statusEffectFrame.StatusEffect.Text = currPartyMember.STATUSEFFECT;
			statusEffectFrame.StatusEffect.TextColor3 = require(moduleFolder.Parent.Classes.PartyMember.Storage.StatusEffectIcons)[currPartyMember.STATUSEFFECT.."COLOR"];
			
			
			local resistFrame = container.Resists
			local resistContainer = resistFrame.Frame
			resistContainer.BINDAmt.Text = compareWithInnateStat("BINDEDRES", false)..string.format("%.1f", currPartyMember.CURRBINDEDRES).."%</font>";
			resistContainer.BLEEDAmt.Text = compareWithInnateStat("BLEEDINGRES", false)..string.format("%.1f", currPartyMember.CURRBLEEDINGRES).."%</font>";
			resistContainer.BLINDAmt.Text = compareWithInnateStat("BLINDEDRES", false)..string.format("%.1f", currPartyMember.CURRBLINDEDRES).."%</font>";
			resistContainer.BURNAmt.Text = compareWithInnateStat("BURNEDRES", false)..string.format("%.1f", currPartyMember.CURRBURNEDRES).."%</font>";
			resistContainer.CHARMAmt.Text = compareWithInnateStat("INFATUATEDRES", false)..string.format("%.1f", currPartyMember.CURRINFATUATEDRES).."%</font>";
			resistContainer.CURSEAmt.Text = compareWithInnateStat("CURSEDRES", false)..string.format("%.1f", currPartyMember.CURRCURSEDRES).."%</font>";
			resistContainer.FREEZEAmt.Text = compareWithInnateStat("FROZENRES", false)..string.format("%.1f", currPartyMember.CURRFROZENRES).."%</font>";
			resistContainer.HEALBLKAmt.Text = compareWithInnateStat("HEALBLOCKEDRES", false)..string.format("%.1f", currPartyMember.CURRHEALBLOCKEDRES).."%</font>";
			resistContainer.INSTDTHAmt.Text = compareWithInnateStat("INSTANTDEATHRES", false)..string.format("%.1f", currPartyMember.CURRINSTANTDEATHRES).."%</font>";
			resistContainer.PANICAmt.Text = compareWithInnateStat("PANICRES", false)..string.format("%.1f", currPartyMember.CURRPANICRES).."%</font>";
			resistContainer.PARALYZAmt.Text = compareWithInnateStat("PARALYZEDRES", false)..string.format("%.1f", currPartyMember.CURRPARALYZEDRES).."%</font>";
			resistContainer.PLAGUEAmt.Text = compareWithInnateStat("PLAGUERES", false)..string.format("%.1f", currPartyMember.CURRPLAGUERES).."%</font>";
			resistContainer.POISONAmt.Text = compareWithInnateStat("POISONEDRES", false)..string.format("%.1f", currPartyMember.CURRPOISONEDRES).."%</font>";
			resistContainer.SLEEPAmt.Text = compareWithInnateStat("SLEEPINGRES", false)..string.format("%.1f", currPartyMember.CURRSLEEPINGRES).."%</font>";
			
			resistContainer.PYROAmt.Text = compareWithInnateStat("PYRORESMULTIPLIER", true)..string.format("%.1f", ((currPartyMember.CURRPYRORESMULTIPLIER * -100) + 100)).."%</font>";
			resistContainer.CRYOAmt.Text = compareWithInnateStat("CRYORESMULTIPLIER", true)..string.format("%.1f", ((currPartyMember.CURRCRYORESMULTIPLIER * -100) + 100)).."%</font>";
			resistContainer.ELECTROAmt.Text = compareWithInnateStat("ELECTRORESMULTIPLIER", true)..string.format("%.1f", ((currPartyMember.CURRELECTRORESMULTIPLIER * -100) + 100)).."%</font>";

			resistContainer.CRUSHAmt.Text = compareWithInnateStat("CRUSHRESMULTIPLIER", true)..string.format("%.1f", ((currPartyMember.CURRCRUSHRESMULTIPLIER * -100) + 100)).."%</font>";
			resistContainer.SLASHAmt.Text = compareWithInnateStat("SLASHRESMULTIPLIER", true)..string.format("%.1f", ((currPartyMember.CURRSLASHRESMULTIPLIER * -100) + 100)).."%</font>";
			resistContainer.PIERCEAmt.Text = compareWithInnateStat("STABRESMULTIPLIER", true)..string.format("%.1f", ((currPartyMember.CURRSTABRESMULTIPLIER * -100) + 100)).."%</font>";


		end
	end	

end)




