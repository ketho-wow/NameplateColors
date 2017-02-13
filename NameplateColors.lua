-- Author: Ketho (EU-Boulderfist)
-- License: Public Domain

local NAME, S = ...

local ACR = LibStub("AceConfigRegistry-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local db

local defaults = {
	db_version = 1.1,
	size = 1,
	pvpicon = true,
	
	friendlynameplate = true,
	friendlynameplatecolor = {r=.34, g=.64, b=1},
	friendlynamecolor = {r=1, g=1, b=1},
	
	enemynameplatecolor = {r=.75, g=.05, b=.05},
	enemyname = true,
	enemynamecolor = {r=1, g=0, b=0},
}

-- bad habit of using that variable for the addon name
local nameLower = _G.NAME
if GetLocale() ~= "deDE" then
	nameLower = nameLower:lower()
end

local checkboxNames = {
	friendlynameplate = OPTION_TOOLTIP_UNIT_NAMEPLATES_SHOW_FRIENDS,
	friendlyname = FRIENDLY.." "..nameLower,
	enemynameplate = OPTION_TOOLTIP_UNIT_NAMEPLATES_SHOW_ENEMIES,
	enemyname = ENEMY.." "..nameLower,
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

local function GetName(i)
	return db[i[#i]] and checkboxNames[i[#i]] or format("|cff808080%s|r", checkboxNames[i[#i]])
end

local function ColorHidden(i)
	return db[i[#i]:gsub("color", "")]
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

local options = {
	type = "group",
	name = format("%s |cffADFF2F%s|r", NAME, GetAddOnMetadata(NAME, "Version")),
	args = {
		classcolors = {
			type = "group", order = 1,
			name = " "..CLASS_COLORS,
			inline = true,
			args = {
				friendlynameplate = {
					type = "toggle", order = 1, desc = SHOW_CLASS_COLOR_IN_V_KEY,
					name = GetName,
					get = GetValue,
					set = SetValue,
				},
				friendlynameplatecolor = {
					type = "color", order = 2, descStyle = "",
					name = COLOR,
					get = GetValueColor,
					set = SetValueColor,
					hidden = ColorHidden,
				},
				newline1 = {type = "description", order = 3, name = ""},
				friendlyname = {
					type = "toggle", order = 4, descStyle = "",
					name = GetName,
					get = GetValue,
					set = SetValue,
				},
				friendlynamecolor = {
					type = "color", order = 5, descStyle = "",
					name = COLOR,
					get = GetValueColor,
					set = SetValueColor,
					hidden = ColorHidden,
				},
				header = {type = "header", order = 6, name = ""},
				enemynameplate = {
					type = "toggle", order = 7, desc = SHOW_CLASS_COLOR_IN_V_KEY,
					name = GetName,
					get = GetValue,
					set = SetValue,
				},
				enemynameplatecolor = {
					type = "color", order = 8, descStyle = "",
					name = COLOR,
					get = GetValueColor,
					set = SetValueColor,
					hidden = ColorHidden,
				},
				newline2 = {type = "description", order = 9, name = ""},
				enemyname = {
					type = "toggle", order = 10, descStyle = "",
					name = GetName,
					get = GetValue,
					set = SetValue,
				},
				enemynamecolor = {
					type = "color", order = 11, descStyle = "",
					name = COLOR,
					get = GetValueColor,
					set = SetValueColor,
					hidden = ColorHidden,
				},
			},
		},
		spacing1 = {type = "description", order = 2, name = ""},
		size = {
			type = "range", order = 3,
			width = "double", desc = OPTION_TOOLTIP_UNIT_NAMEPLATES_MAKE_LARGER,
			name = UNIT_NAMEPLATES_MAKE_LARGER,
			get = function(i) return tonumber(GetCVar("NamePlateHorizontalScale")) end,
			set = function(i, v)
				db.size = v
				SetNameplateSize(v)
			end,
			min = .5, softMin = 1, softMax = 1.5, max = 2, step = .05,
		},
		spacing2 = {type = "description", order = 4, name = " "},
		pvpicon = {
			type = "toggle", order = 5, desc = "|TInterface/PVPFrame/PVP-Currency-Alliance:24|t |TInterface/PVPFrame/PVP-Currency-Horde:24|t",
			name = PVP.." "..EMBLEM_SYMBOL,
			get = GetValue,
			set = SetValue,
		},
		reset = {
			type = "execute", order = 6,
			width = "half", descStyle = "",
			name = RESET,
			confirm = true, confirmText = RESET_TO_DEFAULT.."?",
			func = function()
				NameplateColorsDB = CopyTable(defaults)
				db = NameplateColorsDB
				UpdateNamePlates()
				SetNameplateSize(1)
			end,
		},
	},
}

local f = CreateFrame("Frame")

function f:OnEvent(event, addon)
	if addon == NAME then
		if not NameplateColorsDB or NameplateColorsDB.db_version < defaults.db_version then
			NameplateColorsDB = CopyTable(defaults)
		end
		db = NameplateColorsDB
		
		ACR:RegisterOptionsTable(NAME, options)
		ACD:AddToBlizOptions(NAME, NAME)
		ACD:SetDefaultSize(NAME, 420, 340)
		
		self:SetupNameplates()
		self:UnregisterEvent(event)
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
		if ShouldShowName(frame) then
			if frame.optionTable.colorNameBySelection then
				if UnitIsPlayer(frame.unit) then
					local name = GetUnitName(frame.unit)
					local faction = UnitFactionGroup(frame.unit)
					local icon = UnitIsPVP(frame.unit) and db.pvpicon and faction and pvp[faction] or ""
					frame.name:SetText(icon..name)
					
					local _, class = UnitClass(frame.unit)
					local reaction = (UnitIsEnemy("player", frame.unit) and "enemy" or "friendly").."name"
					local color = db[reaction] and CLASS_COLORS[class] or db[reaction.."color"]
					frame.name:SetVertexColor(color.r, color.g, color.b)
				end
			end
		end
	end)
	
	local playerName = UnitName("player")
	
	-- nameplates
	hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
		-- dont color raid frames or Personal Resource Display
		if not strfind(frame.unit, "nameplate") or UnitName(frame.unit) == playerName then return end
		
		if UnitIsPlayer(frame.unit) then
			local _, class = UnitClass(frame.unit)
			local reaction = (UnitIsEnemy("player", frame.unit) and "enemy" or "friendly").."nameplate"
			local color = db[reaction] and CLASS_COLORS[class] or db[reaction.."color"]
			local r, g, b = color.r, color.g, color.b
			frame.healthBar:SetStatusBarColor(r, g, b)
		end
	end)
	
	-- override when set through the Blizzard options
	hooksecurefunc(InterfaceOptionsNamesPanelUnitNameplatesMakeLarger, "setFunc", function(value)
		SetNameplateSize(value == "1" and (db.size>1 and db.size or 1.4) or 1)
	end)
end

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
