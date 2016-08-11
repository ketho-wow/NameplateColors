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
local pvp = {
	Alliance = "\124TInterface/PVPFrame/PVP-Currency-Alliance:16\124t",
	Horde = "\124TInterface/PVPFrame/PVP-Currency-Horde:16\124t",
}

-- friendly/enemy nameplate name colors
hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
	if not ShouldShowName(frame) then
		frame.name:Hide()
	else
		-- dont include realm name asterisk for players from the same connected realm
		local name = GetUnitName(frame.unit)
		frame.name:SetText(name)

		if CompactUnitFrame_IsTapDenied(frame) then
			-- Use grey if not a player and can't get tap on unit
			frame.name:SetVertexColor(.5, .5, .5)
		elseif frame.optionTable.colorNameBySelection then
			-- color players without somehow affecting anything else
			if UnitIsPlayer(frame.unit) then
				local isPVP = UnitIsPVP(frame.unit) -- flagged for pvp
				local faction = UnitFactionGroup(frame.unit)
				frame.name:SetText((isPVP and faction) and pvp[faction]..name or name)
				-- an enemy could also be from the same faction in ffa/arena/duel
				if UnitIsEnemy("player", frame.unit) then
					local _, class = UnitClass(frame.unit)
					local color = CLASS_COLORS[class]
					frame.name:SetVertexColor(color.r, color.g, color.b) -- enemy, class colors
				else
					frame.name:SetVertexColor(1, 1, 1) -- friendly, white
				end
			elseif frame.optionTable.considerSelectionInCombatAsHostile and CompactUnitFrame_IsOnThreatListWithPlayer(frame.displayedUnit) then
				frame.name:SetVertexColor(1, 0, 0)
			else
				frame.name:SetVertexColor(UnitSelectionColor(frame.unit, frame.optionTable.colorNameWithExtendedColors))
			end
		end
	end
end)
