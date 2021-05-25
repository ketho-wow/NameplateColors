local NAME, S = ...

local ACR = LibStub("AceConfigRegistry-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local db
local isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)

local defaults = {
	db_version = 1.3,
	
	nameplatesize = 1,
	namesize = 10,
	pvpicon = true,
	
	friendlynameplate = 1,
	friendlynameplatecolor = {r=.34, g=.64, b=1},
	friendlyname = 2,
	friendlynamecolor = {r=1, g=1, b=1},
	
	enemynameplate = 2,
	enemynameplatecolor = {r=.75, g=.05, b=.05},
	enemyname = 1,
	enemynamecolor = {r=1, g=0, b=0},
}

-- 7.2: protected friendly nameplates dungeons/raids
local instanceType
local restricted = {
	party = true,
	raid = true,
}

-- only the fixed size fonts seem to be used
-- dont see any blizzard options for controlling useFixedSizeFont
local fonts = {
	SystemFont_NamePlate,
	SystemFont_LargeNamePlate,
	SystemFont_NamePlateFixed,
	SystemFont_LargeNamePlateFixed,
}

local function UpdateNamePlates()
	for i, frame in ipairs(C_NamePlate.GetNamePlates()) do
		NamePlateDriverFrame:ApplyFrameOptions(frame, frame.namePlateUnitToken)
		CompactUnitFrame_UpdateAll(frame.UnitFrame)
	end
end

local function GetValue(i)
	return db[i[#i]]
end

local function SetValue(i, v)
	db[i[#i]] = v
	UpdateNamePlates()
end

local function GetValueColor(i)
	local c = db[i[#i]]
	return c.r, c.g, c.b
end

local function SetValueColor(i, r, g, b)
	local c = db[i[#i]]
	c.r, c.g, c.b = r, g, b
	UpdateNamePlates()
end

local function ColorHidden(i)
	return db[i[#i]:gsub("color", "")] ~= 2
end

local function SetNameplateSize(v)
	if not InCombatLockdown() then
		SetCVar("NamePlateHorizontalScale", v)
		SetCVar("NamePlateVerticalScale", v > 1 and (v*4.25 - 3.25) or v) -- {1;1}, {1.4;2.7}
		-- make sure this corresponds to our option, otherwise our option gets reset
		InterfaceOptionsNamesPanelUnitNameplatesMakeLarger.value = v > 1 and "1" or "0"
		NamePlateDriverFrame:UpdateNamePlateOptions() -- taints
	end
end

local function SetFontSize(v)
	for _, fontobject in pairs(fonts) do
		fontobject:SetFont("Fonts/FRIZQT__.TTF", v)
	end
end

local options = {
	type = "group",
	name = format("%s |cffADFF2F%s|r", NAME, GetAddOnMetadata(NAME, "Version")),
	args = {
		friendly = {
			type = "group", order = 1,
			name = "|cff57A3FF"..FRIENDLY,
			inline = true,
			args = {
				friendlynameplate = {
					type = "select", order = 1,
					descStyle = "",
					name = OPTION_TOOLTIP_UNIT_NAMEPLATES_SHOW_FRIENDS,
					values = {
						CLASS_COLORS,
						FRIENDLY.." "..COLORS,
						"|cffFF0000"..ADDON_DISABLED,
					},
					get = GetValue,
					set = SetValue,
				},
				friendlynameplatecolor = {
					type = "color", order = 2,
					desc = FRIENDLY.." "..COLORS, width = "half",
					name = " ",
					get = GetValueColor,
					set = SetValueColor,
					hidden = ColorHidden,
				},
				spacing1 = {type = "description", order = 3, name = ""},
				friendlyname = {
					type = "select", order = 4,
					descStyle = "",
					name = FRIENDLY.." "..NAMES_LABEL,
					values = {
						CLASS_COLORS,
						FRIENDLY.." "..COLORS,
					},
					get = GetValue,
					set = SetValue,
				},
				friendlynamecolor = {
					type = "color", order = 5,
					desc = FRIENDLY.." "..COLORS, width = "half",
					name = " ",
					get = GetValueColor,
					set = SetValueColor,
					hidden = ColorHidden,
				},
				spacing2 = {type = "description", order = 6, name = " "},
			},
		},
		spacing1 = {type = "description", order = 2, name = ""},
		enemy = {
			type = "group", order = 3,
			name = "|cffBF0D0D"..ENEMY,
			inline = true,
			args = {
				enemynameplate = {
					type = "select", order = 1,
					descStyle = "",
					name = OPTION_TOOLTIP_UNIT_NAMEPLATES_SHOW_ENEMIES,
					values = {
						CLASS_COLORS,
						HOSTILE.." "..COLORS,
						"|cffFF0000"..ADDON_DISABLED,
					},
					get = GetValue,
					set = SetValue,
				},
				enemynameplatecolor = {
					type = "color", order = 2,
					desc = HOSTILE.." "..COLORS, width = "half",
					name = " ",
					get = GetValueColor,
					set = SetValueColor,
					hidden = ColorHidden,
				},
				spacing1 = {type = "description", order = 3, name = ""},
				enemyname = {
					type = "select", order = 4,
					descStyle = "",
					name = ENEMY.." "..NAMES_LABEL,
					values = {
						CLASS_COLORS,
						HOSTILE.." "..COLORS,
					},
					get = GetValue,
					set = SetValue,
				},
				enemynamecolor = {
					type = "color", order = 5,
					desc = HOSTILE.." "..COLORS, width = "half",
					name = " ",
					get = GetValueColor,
					set = SetValueColor,
					hidden = ColorHidden,
				},
				spacing2 = {type = "description", order = 6, name = " "},
			},
		},
		spacing2 = {type = "description", order = 4, name = ""},
		nameplatesize = {
			type = "range", order = 5, hidden = not isRetail,
			width = "double", desc = OPTION_TOOLTIP_UNIT_NAMEPLATES_MAKE_LARGER,
			name = UNIT_NAMEPLATES_MAKE_LARGER,
			get = function(i) return tonumber(GetCVar("NamePlateHorizontalScale")) end,
			set = function(i, v)
				db.nameplatesize = v
				SetNameplateSize(v)
			end,
			min = .5, softMin = 1, softMax = 1.5, max = 2, step = .05,
		},
		spacing3 = {type = "description", order = 6, name = " "},
		namesize = {
			type = "range", order = 7,
			width = "double",
			name = FONT_SIZE,
			get = GetValue,
			set = function(i, v)
				db.namesize = v
				SetFontSize(v)
			end,
			min = 1, softMin = 8, softMax = 24, max = 32, step = 1,
		},
		spacing4 = {type = "description", order = 8, name = "\n"},
		pvpicon = {
			type = "toggle", order = 9,
			desc = "|TInterface/PVPFrame/PVP-Currency-Alliance:24|t |TInterface/PVPFrame/PVP-Currency-Horde:24|t",
			name = PVP.." "..EMBLEM_SYMBOL,
			get = GetValue,
			set = SetValue,
		},
		reset = {
			type = "execute", order = 10,
			width = "half", descStyle = "",
			name = RESET,
			confirm = true, confirmText = RESET_TO_DEFAULT.."?",
			func = function()
				NameplateColorsDB = CopyTable(defaults)
				db = NameplateColorsDB
				if isRetail then
					SetNameplateSize(defaults.nameplatesize)
				end
				SetFontSize(defaults.namesize)
				UpdateNamePlates()
			end,
		},
	},
}

local f = CreateFrame("Frame")

function f:OnEvent(event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		instanceType = select(2, IsInInstance())
	elseif event == "ZONE_CHANGED_NEW_AREA" then
		C_Timer.After(4, function() instanceType = select(2, IsInInstance()) end)
	elseif event == "ADDON_LOADED" then
		if ... == NAME then
			if not NameplateColorsDB or NameplateColorsDB.db_version < defaults.db_version then
				NameplateColorsDB = CopyTable(defaults)
			end
			db = NameplateColorsDB
			
			ACR:RegisterOptionsTable(NAME, options)
			ACD:AddToBlizOptions(NAME, NAME)
			ACD:SetDefaultSize(NAME, 400, 530)
			
			-- need to be able to toggle bars, dirty hack because lazy af at the moment
			C_Timer.After(1, function()
				if GetCVar("nameplateShowOnlyNames") == "1" then
					SetCVar("nameplateShowOnlyNames", 0)
					if not InCombatLockdown() then
						NamePlateDriverFrame:UpdateNamePlateOptions() -- taints
					end
				end
			end)
			
			self:SetupNameplates()
			self:UnregisterEvent(event)
		end
	end
end

function f:SetupNameplates()
	local CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
	
	local pvp = {
		Alliance = "|TInterface/PVPFrame/PVP-Currency-Alliance:16|t",
		Horde = "|TInterface/PVPFrame/PVP-Currency-Horde:16|t",
	}
	
	-- names
	hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
		if restricted[instanceType] then return end
		
		if ShouldShowName(frame) then
			-- not sure anymore what colorNameBySelection is for in retail and why its disabled in classic
			if not isRetail or frame.optionTable.colorNameBySelection then
				if UnitIsPlayer(frame.unit) then
					local name = GetUnitName(frame.unit)
					local faction = UnitFactionGroup(frame.unit)
					local icon = UnitIsPVP(frame.unit) and db.pvpicon and faction and pvp[faction] or ""
					frame.name:SetText(icon..name)
					
					local _, class = UnitClass(frame.unit)
					local reaction = (UnitIsEnemy("player", frame.unit) and "enemy" or "friendly").."name"
					local color = db[reaction] == 1 and CLASS_COLORS[class] or db[reaction.."color"]
					frame.name:SetVertexColor(color.r, color.g, color.b)
				end
			end
		end
	end)
	
	local playerName = UnitName("player")
	
	-- nameplates
	hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
		if restricted[instanceType] then return end
		-- dont color raid frames or Personal Resource Display
		if not strfind(frame.unit, "nameplate") or UnitName(frame.unit) == playerName then return end
		
		local flag = UnitIsFriend("player", frame.unit) and "friendly" or "enemy"
		
		if UnitIsPlayer(frame.unit) then
			local _, class = UnitClass(frame.unit)
			local reaction = flag.."nameplate"
			local color = db[reaction] == 1 and CLASS_COLORS[class] or db[reaction.."color"]
			local r, g, b = color.r, color.g, color.b	
			frame.healthBar:SetStatusBarColor(r, g, b)
		end
		
		-- can use nameplateShowOnlyNames but it controls both enemy and friendly
		local alpha = db[flag.."nameplate"] == 3 and 0 or 1
		frame.healthBar:SetAlpha(alpha) -- name-only option
		if isRetail then
			frame.ClassificationFrame:SetAlpha(alpha) -- also hide that elite dragon icon
		end
	end)
	
	-- override when set through the Blizzard options
	if isRetail then
		hooksecurefunc(InterfaceOptionsNamesPanelUnitNameplatesMakeLarger, "setFunc", function(value)
			SetNameplateSize(value == "1" and (db.nameplatesize>1 and db.nameplatesize or 1.4) or 1)
		end)
	end
	SetFontSize(db.namesize)
end

f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", f.OnEvent)

for i, v in pairs({"nc", "namecolors", "nameplatecolors"}) do
	_G["SLASH_NAMEPLATECOLORS"..i] = "/"..v
end

function SlashCmdList.NAMEPLATECOLORS()
	if not ACD.OpenFrames.NamePlateColors then
		ACD:Open(NAME)
	end
end
