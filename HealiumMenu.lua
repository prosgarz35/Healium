local function SetButtonCount(info, arg1)
	if InCombatLockdown() then
		Healium_Warn("Can't update button count while in combat!")
		return
	end
	Healium_SetButtonCount(arg1)
end
local MenuTable = {
	[1] =
	{
		{
			text = Healium_AddonColor .. Healium_AddonName .. "|r Menu",
			isTitle = 1,
			notCheckable = 1,
		},
		{
			text = Healium_AddonName .. " Config Panel",
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
				func = function() Healium_ShowHidePartyFrame(true) end,
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
	}
}

local function HealiumMenu_InitializeDropDown(self, level)
	level = level or 1
	if level == 1 then
		local closeEntry = MenuTable[1][6]
		if not closeEntry then
			MenuTable[1][6] = {
				hasArrow     = nil,
				value        = nil,
				notCheckable = 1,
				text         = CLOSE,
				func         = self.HideMenu,
			}
		else
			closeEntry.func = self.HideMenu
		end
	end
	local Profile = Healium_GetProfile()
	local sbc = {}
	for i = 0, Healium_MaxButtons do
		sbc[i + 1] = {
			text    = i,
			checked = (i == Profile.ButtonCount),
			func    = SetButtonCount,
			arg1    = i,
		}
	end
	MenuTable[2].SetButtonCount = sbc

	local info    = MenuTable[level]
	local menuval = UIDROPDOWNMENU_MENU_VALUE

	if level > 1 and menuval and info[menuval] then
		info = info[menuval]
	end

	if info then
		for _, entry in ipairs(info) do
			UIDropDownMenu_AddButton(entry, level)
		end
	end
end

function Healium_InitMenu()
	HealiumMenu = CreateFrame("Frame", "HealiumOptionsMenu", UIParent, "UIDropDownMenuTemplate")
	UIDropDownMenu_Initialize(HealiumMenu, HealiumMenu_InitializeDropDown, "MENU")
end