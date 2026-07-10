local addonName, addonTable = ...
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local UnitName = UnitName
local UnitExists = UnitExists
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitBuff = UnitBuff
local UnitDebuff = UnitDebuff
local GetSpellCooldown = GetSpellCooldown
local GetSpellInfo = GetSpellInfo
local ipairs = ipairs
local pairs = pairs
local type = type
local tostring = tostring
local tonumber = tonumber

local function ShowPartyFrame()
	Healium_ShowHidePartyFrame(true)
end

local function ShowMeFrame()
	Healium_ShowHideMeFrame(true)
end

local function ShowPetsFrame()
	Healium_ShowHidePetsFrame(true)
end

local function SetButtonCount(info, arg1)
	if InCombatLockdown() then
		Healium_Warn("Can't update button count while in combat!")
		return
	end
	
	Healium_SetButtonCount(arg1)
end

local function HealiumMenu_InitializeDropDown(self,level)
	level = level or 1
	
	local MenuTable = 
	{
		[1] =
		{
			{
				text = addonTable.AddonColor .. addonTable.AddonName .. "|r Menu",
				isTitle = 1,
				notCheckable = 1,
			},
			{
				text = addonTable.AddonName .. " Config Panel",
				func = Healium_ShowConfigPanel,
				notCheckable = 1,
			},
			{
				text = "Set button count",
				hasArrow = 1,
				value = "SetButtonCount",
				notCheckable = 1,
			},
			{
				text = "Show / Hide Frames",
				hasArrow = 1,
				value = "Frames",
				notCheckable = 1,
			},
			{
				text = "Reset all frame positions",
				func = Healium_ResetAllFramePositions,
				notCheckable = 1,
			},
			{
				hasArrow  = nil,
				value  = nil,
				notCheckable = 1,
				text = CLOSE,
				func = CloseDropDownMenus			
			}
		},
		[2] =
		{
			["Frames"] = 
			{
				{
					text = "Toggle Frames",
					notCheckable = 1,
					func = Healium_ToggleAllFrames,
				},
				{
					text = "Show Party",
					notCheckable = 1,
					func = ShowPartyFrame,
				},
				{
					text = "Show Me",
					notCheckable = 1,
					func = ShowMeFrame,
				},
				{
					text = "Show Pets",
					notCheckable = 1,					
					func = ShowPetsFrame,
				},
				{
					text = "Hide All Raid Groups",
					notCheckable = 1,					
					func = Healium_HideAllRaidFrames,
				},
				{
					text = "Show Raid Groups 1 and 2 (10 man)",
					notCheckable = 1,					
					func = Healium_Show10ManRaidFrames,
				},
				{
					text = "Show Raid Groups 1-5 (25 man)",
					notCheckable = 1,					
					func = Healium_Show25ManRaidFrames,
				}, 
				{
					text = "Show Raid Groups 1-8 (40 man)",
					notCheckable = 1,					
					func = Healium_Show40ManRaidFrames,
				}, 
			},
		},
	}

	local sbc = { }
	local Profile = Healium_GetProfile()	
	
	for i=0, addonTable.MaxButtons, 1 do
		local menuItem = { }
		menuItem.text = i
		menuItem.checked = i == Profile.ButtonCount
		menuItem.func = SetButtonCount
		menuItem.arg1 = i
		table.insert(sbc, menuItem)
	end
	
	MenuTable[2].SetButtonCount = sbc
	
	local info = MenuTable[level]
	local menuval = UIDROPDOWNMENU_MENU_VALUE
	
	if (level > 1 and menuval) then
		if info[menuval] then
			info = info[menuval]
		end
	end

	for idx, entry in ipairs(info) do
		UIDropDownMenu_AddButton(entry, level)
	end

end

function Healium_InitMenu()
	HealiumMenu = CreateFrame("Frame", "HealiumOptionsMenu", UIParent, "UIDropDownMenuTemplate") 
	UIDropDownMenu_Initialize(HealiumMenu, HealiumMenu_InitializeDropDown, "MENU");

end


