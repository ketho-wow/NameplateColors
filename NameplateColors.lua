-- Author: Ketho (EU-Boulderfist)
-- License: Public Domain

-- friendly nameplate healthbar class colors
DefaultCompactNamePlateFriendlyFrameOptions.useClassColors = true

-- enemy nameplate healthbar hostile colors
SetCVar("ShowClassColorInNameplate", 0)
C_Timer.After(.1, function() -- wait and override any enabled cvar
	DefaultCompactNamePlateEnemyFrameOptions.useClassColors = false
end)

local CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS

-- friendly/enemy nameplate name colors
hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
	if not ShouldShowName(frame) then
		frame.name:Hide()
	else
		frame.name:SetText(GetUnitName(frame.unit, true))

		if CompactUnitFrame_IsTapDenied(frame) then
			-- Use grey if not a player and can't get tap on unit
			frame.name:SetVertexColor(0.5, 0.5, 0.5)
		elseif frame.optionTable.colorNameBySelection then
			-- color players without somehow affecting anything else
			if UnitIsPlayer(frame.unit) then
				if UnitIsEnemy("player", frame.unit) then
					local _, class = UnitClass(frame.unit)
					local color = CLASS_COLORS[class]
					frame.name:SetVertexColor(color.r, color.g, color.b) -- enemy, class color
				else
					frame.name:SetVertexColor(1.0, 1.0, 1.0) -- friendly, white
				end
			elseif frame.optionTable.considerSelectionInCombatAsHostile and CompactUnitFrame_IsOnThreatListWithPlayer(frame.displayedUnit) then
				frame.name:SetVertexColor(1.0, 0.0, 0.0)
			else
				frame.name:SetVertexColor(UnitSelectionColor(frame.unit, frame.optionTable.colorNameWithExtendedColors))
			end
		end

		frame.name:Show()
	end
end)
