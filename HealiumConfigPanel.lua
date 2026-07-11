local ClassIcon = {
	DRUID       = "Interface/Icons/INV_Misc_MonsterClaw_04",
	MAGE        = "Interface/Icons/INV_Staff_13",
	PRIEST      = "Interface/Icons/INV_Staff_30",
	SHAMAN      = "Interface/Icons/Spell_Nature_BloodLust",
	PALADIN     = "Interface/Icons/Ability_ThunderBolt",
	DEATHKNIGHT = "Interface/Icons/Spell_Deathknight_ClassIcon",
}

-- Factory: creates a labelled checkbox anchored relative to another frame.
-- anchor  : parent frame to anchor BOTTOMLEFT → TOPLEFT; pass nil to position manually after.
-- offsetX : horizontal offset from anchor (default 0)
-- offsetY : vertical offset from anchor (default 0)
local function CreateOptionCheckButton(parent, anchor, label, tooltip, onClick, offsetX, offsetY)
	local cb = CreateFrame("CheckButton", nil, parent, "OptionsCheckButtonTemplate")
	if anchor then
		cb:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", offsetX or 0, offsetY or 0)
	end
	cb.Text = cb:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	cb.Text:SetPoint("LEFT", cb, "RIGHT", 0)
	cb.Text:SetText(label)
	cb.tooltipText = tooltip
	cb:SetScript("OnClick", onClick)
	return cb
end

-- ── Handler functions ────────────────────────────────────────────────────────

function Healium_SetButtonCount(count)
	HealiumMaxButtonSlider.Text:SetText("Show |cFFFFFFFF" .. count .. "|r Buttons")
	Healium_GetProfile().ButtonCount = count
	Healium_UpdateButtonVisibility()
end

local function MaxButtonSlider_Update(self)
	Healium_SetButtonCount(self:GetValue())
end

local function TooltipsCheck_OnClick(self)
	Healium.ShowToolTips = self:GetChecked() or false
end

local function PercentageCheck_OnClick(self)
	Healium.ShowPercentage = self:GetChecked() or false
	Healium_UpdatePercentageVisibility()
end

local function ClassColorCheck_OnClick(self)
	Healium.UseClassColors = self:GetChecked() or false
	Healium_UpdateClassColors()
end

local function HideCloseButtonCheck_OnClick(self)
	Healium.HideCloseButton = self:GetChecked() or false
	Healium_UpdateCloseButtons()
end

local function HideCaptionsCheck_OnClick(self)
	Healium.HideCaptions = self:GetChecked() or false
	Healium_UpdateHideCaptions()
end

local function LockFramePositionsCheck_OnClick(self)
	Healium.LockFrames = self:GetChecked() or false
end

local function ShowManaCheck_OnClick(self)
	Healium.ShowMana = self:GetChecked() or false
	Healium_UpdateShowMana()
end

local function UpdateEnableDebuffsControls(self)
	local color = self:GetChecked() and NORMAL_FONT_COLOR or GRAY_FONT_COLOR
	for _, j in ipairs(self.children) do
		j:SetTextColor(color.r, color.g, color.b)
	end
end

local function EnableDebuffsCheck_OnClick(self)
	UpdateEnableDebuffsControls(self)
	Healium.EnableDebufs = self:GetChecked() or false
	Healium_UpdateEnableDebuffs()
end

local function EnableDebuffHealthbarHighlightingCheck_OnClick(self)
	Healium.EnableDebufHealthbarHighlighting = self:GetChecked() or false
	Healium_UpdateEnableDebuffs()
end

local function EnableDebuffButtonHighlightingCheck_OnClick(self)
	Healium.EnableDebufButtonHighlighting = self:GetChecked() or false
	Healium_UpdateEnableDebuffs()
end

local function EnableDebuffHealthbarColoringCheck_OnClick(self)
	Healium.EnableDebufHealthbarColoring = self:GetChecked() or false
	Healium_UpdateEnableDebuffs()
end

local function ScaleSlider_OnValueChanged(self)
	Healium.Scale = self:GetValue()
	Healium_SetScale()
	self.Text:SetText("Scale: |cFFFFFFFF" .. format("%.1f", Healium.Scale))
end

-- ── Public API ───────────────────────────────────────────────────────────────

function Healium_ShowConfigPanel()
	if InterfaceOptionsFrame:IsVisible() then
		InterfaceOptionsFrame:Hide()
	else
		InterfaceOptionsFrame_OpenToCategory(Healium_AddonName)
	end
end

function Healium_Update_ConfigPanel()
	HealiumMaxButtonSlider:SetValue(Healium_GetProfile().ButtonCount)
end

function Healium_CreateConfigPanel(Class, Version)
	local panel = CreateFrame("Frame", nil, UIParent)
	panel.name   = Healium_AddonName
	panel.okay   = function() end
	panel.cancel = function() end
	InterfaceOptions_AddCategory(panel)

	local scrollframe = CreateFrame("ScrollFrame", "HealiumPanelScrollFrame", panel, "UIPanelScrollFrameTemplate")
	local framewidth  = InterfaceOptionsFramePanelContainer:GetWidth()
	local frameheight = InterfaceOptionsFramePanelContainer:GetHeight()
	scrollframe:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -25)
	scrollframe:SetWidth(framewidth - 45)
	scrollframe:SetHeight(frameheight - 45)
	scrollframe:Show()

	scrollframe.scrollbar = _G["HealiumPanelScrollFrameScrollBar"]
	scrollframe.scrollbar:SetBackdrop({
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeSize = 8,
		tileSize = 32,
		insets   = { left = 0, right = 0, top = 5, bottom = 5 },
	})

	local scrollchild = CreateFrame("Frame", "$parentScrollChild", scrollframe)
	scrollframe:SetScrollChild(scrollchild)
	-- Width controls class icon placement (attaches to TOPRIGHT of scrollchild)
	scrollchild:SetHeight(frameheight - 45)
	scrollchild:SetWidth(framewidth - 45)
	scrollchild:Show()

	-- ── Title ────────────────────────────────────────────────────────────────
	local TitleText = scrollchild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	TitleText:SetJustifyH("LEFT")
	TitleText:SetPoint("TOPLEFT", 10, -10)
	TitleText:SetText(Healium_AddonColoredName .. Version)

	local TitleSubText = scrollchild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	TitleSubText:SetJustifyH("LEFT")
	TitleSubText:SetPoint("TOPLEFT", 10, -30)
	TitleSubText:SetText("Welcome to the " .. Healium_AddonColoredName .. "  options screen.|nUse the scrollbar to access more options.")
	TitleSubText:SetTextColor(1, 1, 1, 1)

	-- ── Class icon ───────────────────────────────────────────────────────────
	local HealiumClassIcon = CreateFrame("Frame", "HealiumClassIcon", scrollchild)
	HealiumClassIcon:SetPoint("TOPRIGHT", -20, 0)
	HealiumClassIcon:SetHeight(60)
	HealiumClassIcon:SetWidth(60)
	HealiumClassIconTexture = HealiumClassIcon:CreateTexture(nil, "BACKGROUND")
	HealiumClassIconTexture:SetAllPoints()
	HealiumClassIconTexture:SetTexture(ClassIcon[Class])
	HealiumClassIcon.Text = HealiumClassIcon:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	HealiumClassIcon.Text:SetText(strupper(Class))
	HealiumClassIcon.Text:SetPoint("CENTER", 0, -38)
	HealiumClassIcon.Text:SetTextColor(1, 1, 0.2, 1)

	-- ── Checkboxes (via factory) ──────────────────────────────────────────────
	local TooltipsCheck = CreateOptionCheckButton(scrollchild, nil,
		"Show Button ToolTips",
		"Shows spell tooltips when hovering the mouse over the " .. Healium_AddonColoredName .. " buttons.",
		TooltipsCheck_OnClick)
	TooltipsCheck:SetPoint("TOPLEFT", 5, -70)

	local ShowManaCheck = CreateOptionCheckButton(scrollchild, TooltipsCheck,
		"Show Mana", "Shows the unit's mana.", ShowManaCheck_OnClick)

	local PercentageCheck = CreateOptionCheckButton(scrollchild, ShowManaCheck,
		"Show Health Percentage",
		"Shows the unit's health as a percentage on the right side of the health bar.",
		PercentageCheck_OnClick)

	local ClassColorCheck = CreateOptionCheckButton(scrollchild, PercentageCheck,
		"Use Class Colors",
		"Colors the healthbar based on the unit's class instead of green/yellow/red based on it's current health.",
		ClassColorCheck_OnClick)

	local HideCloseButtonCheck = CreateOptionCheckButton(scrollchild, ClassColorCheck,
		"Hide Close Buttons",
		"Hides the X (close) button on the upper-right of the " .. Healium_AddonColoredName .. " caption bar.",
		HideCloseButtonCheck_OnClick)

	local HideCaptionsCheck = CreateOptionCheckButton(scrollchild, HideCloseButtonCheck,
		"Hide Captions",
		"Automatically hides the caption bar of " .. Healium_AddonColoredName .. " frames when the mouse leaves the caption.",
		HideCaptionsCheck_OnClick)

	local LockFramePositionsCheck = CreateOptionCheckButton(scrollchild, HideCaptionsCheck,
		"Lock Frame Positions",
		"Prevents dragging of any " .. Healium_AddonColoredName .. " frames.",
		LockFramePositionsCheck_OnClick)

	-- ── Button count slider ───────────────────────────────────────────────────
	HealiumMaxButtonSlider = CreateFrame("Slider", "$parentMaxButtonSlider", scrollchild, "OptionsSliderTemplate")
	HealiumMaxButtonSlider:SetWidth(128)
	HealiumMaxButtonSlider:SetHeight(16)
	HealiumMaxButtonSlider:SetPoint("TOPLEFT", 220, -110)
	HealiumMaxButtonSlider:SetMinMaxValues(0, Healium_MaxButtons)
	HealiumMaxButtonSlider:SetValueStep(1)
	HealiumMaxButtonSlider:SetValue(Healium_GetProfile().ButtonCount)
	HealiumMaxButtonSlider.tooltipText = "How many " .. Healium_AddonColoredName .. " buttons to show."
	HealiumMaxButtonSlider.Text = HealiumMaxButtonSlider:CreateFontString(nil, "BACKGROUND", "GameFontNormalLarge")
	HealiumMaxButtonSlider.Text:SetPoint("CENTER", 0, 17)
	HealiumMaxButtonSlider.Text:SetText("Show |cFFFFFFFF" .. HealiumMaxButtonSlider:GetValue() .. "|r Buttons")
	_G[HealiumMaxButtonSlider:GetName() .. "Low"]:SetText("0")
	_G[HealiumMaxButtonSlider:GetName() .. "High"]:SetText(Healium_MaxButtons)
	HealiumMaxButtonSlider:SetScript("OnValueChanged", MaxButtonSlider_Update)
	HealiumMaxButtonSlider:Show()

	-- ── Scale slider ─────────────────────────────────────────────────────────
	local ScaleSlider = CreateFrame("Slider", "HealiumScaleSlider", scrollchild, "OptionsSliderTemplate")
	ScaleSlider:SetWidth(100)
	ScaleSlider:SetHeight(16)
	ScaleSlider:SetMinMaxValues(0.6, 1.5)
	ScaleSlider:SetValueStep(0.1)
	ScaleSlider:SetValue(Healium.Scale)
	ScaleSlider:SetPoint("TOPLEFT", HealiumMaxButtonSlider, "BOTTOMLEFT", 0, -30)
	_G[ScaleSlider:GetName() .. "Low"]:SetText("Small")
	_G[ScaleSlider:GetName() .. "High"]:SetText("Large")
	ScaleSlider.Text = ScaleSlider:CreateFontString(nil, "BACKGROUND", "GameFontNormalLarge")
	ScaleSlider.Text:SetPoint("CENTER", -5, 17)
	ScaleSlider.Text:SetText("Scale: |cFFFFFFFF" .. format("%.1f", ScaleSlider:GetValue()))
	ScaleSlider:SetScript("OnValueChanged", ScaleSlider_OnValueChanged)
	ScaleSlider.tooltipText = "Sets the scale of all " .. Healium_AddonColoredName .. " frames."

	-- ── Show Frames section ───────────────────────────────────────────────────
	local ShowFramesTitleText = scrollchild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	ShowFramesTitleText:SetJustifyH("LEFT")
	ShowFramesTitleText:SetPoint("TOPLEFT", LockFramePositionsCheck, "BOTTOMLEFT", 0, -30)
	ShowFramesTitleText:SetText("Show Frames")

	local ShowFramesTitleSubText = scrollchild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	ShowFramesTitleSubText:SetJustifyH("LEFT")
	ShowFramesTitleSubText:SetPoint("TOPLEFT", ShowFramesTitleText, "BOTTOMLEFT", 0, 0)
	ShowFramesTitleSubText:SetText("Check each frame to show.")
	ShowFramesTitleSubText:SetTextColor(1, 1, 1, 1)

	-- Party check (global, referenced from HealiumUnitFrames.lua)
	Healium_ShowPartyCheck = CreateOptionCheckButton(scrollchild, ShowFramesTitleSubText,
		"Party",
		"Shows the Party " .. Healium_AddonColoredName .. " frame.",
		function(self)
			Healium.ShowPartyFrame = self:GetChecked() or false
			Healium_ShowHidePartyFrame()
		end,
		0, -10)

	-- Group checkboxes; stored in _G so HealiumUnitFrames can find them by name
	local prevCheck = Healium_ShowPartyCheck
	for i = 1, 8 do
		local check = CreateOptionCheckButton(scrollchild, prevCheck,
			"Group " .. i,
			"Shows the Group " .. i .. " " .. Healium_AddonColoredName .. " frame.",
			function(self)
				Healium.ShowGroupFrames[i] = self:GetChecked() or false
				Healium_ShowHideGroupFrame(i)
			end)
		_G["Healium_ShowGroup" .. i .. "Check"] = check
		prevCheck = check
	end
	-- prevCheck now holds the Group 8 checkbox (used as anchor below)

	-- ── Debuff Warnings section ───────────────────────────────────────────────
	local DebuffWarningsTitleText = scrollchild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	DebuffWarningsTitleText:SetJustifyH("LEFT")
	DebuffWarningsTitleText:SetPoint("TOPLEFT", prevCheck, "BOTTOMLEFT", 0, -30)
	DebuffWarningsTitleText:SetText("Debuff Warnings")

	local DebuffWarningsSubText = scrollchild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	DebuffWarningsSubText:SetJustifyH("LEFT")
	DebuffWarningsSubText:SetPoint("TOPLEFT", DebuffWarningsTitleText, "BOTTOMLEFT", 0, 0)
	DebuffWarningsSubText:SetText("Debuff warnings are audible and visual indicators that|nnotify you when you can cure a debuff on a player.")
	DebuffWarningsSubText:SetTextColor(1, 1, 1, 1)

	-- EnableDebuffsCheck needs a .children table for its sub-options
	local EnableDebuffsCheck = CreateOptionCheckButton(scrollchild, DebuffWarningsSubText,
		"Enable Debuff Warnings", "Enables debuff warnings",
		EnableDebuffsCheck_OnClick, 0, -10)
	EnableDebuffsCheck.children = {}

	-- Sub-options (indented X=20 from EnableDebuffsCheck, then chained vertically)
	local EnableDebufHealthbarColoringCheck = CreateOptionCheckButton(scrollchild, EnableDebuffsCheck,
		"Healthbar Coloring",
		"Enables coloring of the healthbar of a player that has a debuff which you can cure",
		EnableDebuffHealthbarColoringCheck_OnClick, 20)
	table.insert(EnableDebuffsCheck.children, EnableDebufHealthbarColoringCheck.Text)

	local EnableDebuffHealthbarHighlightingCheck = CreateOptionCheckButton(scrollchild, EnableDebufHealthbarColoringCheck,
		"Healthbar Highlight Warning",
		"Enables highlighting of the healthbar of a player that has a debuff which you can cure",
		EnableDebuffHealthbarHighlightingCheck_OnClick)
	table.insert(EnableDebuffsCheck.children, EnableDebuffHealthbarHighlightingCheck.Text)

	local EnableDebuffButtonHighlightingCheck = CreateOptionCheckButton(scrollchild, EnableDebuffHealthbarHighlightingCheck,
		"Button Highlight Warning",
		"Enables highlighting of buttons which have been assigned a spell that can cure a debuff on a player",
		EnableDebuffButtonHighlightingCheck_OnClick)
	table.insert(EnableDebuffsCheck.children, EnableDebuffButtonHighlightingCheck.Text)

	-- ── About section ─────────────────────────────────────────────────────────
	local AboutTitle = CreateFrame("Frame", "", scrollchild)
	AboutTitle:SetFrameStrata("TOOLTIP")
	AboutTitle:SetWidth(160)
	AboutTitle:SetHeight(20)
	AboutTitle.Text = AboutTitle:CreateFontString(nil, "BACKGROUND", "GameFontNormalLarge")
	AboutTitle.Text:SetPoint("TOPLEFT", EnableDebuffButtonHighlightingCheck, "BOTTOMLEFT", 0, -30)
	AboutTitle.Text:SetText("About " .. Healium_AddonColoredName)

	local AboutFrame = CreateFrame("Frame", "AboutHealium", scrollchild)
	AboutFrame:SetWidth(340)
	AboutFrame:SetHeight(80)
	AboutFrame:SetPoint("TOPLEFT", AboutTitle.Text, "BOTTOMLEFT", 0, 0)
	AboutFrame:SetBackdrop({
		bgFile   = "",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile     = true, tileSize = 16, edgeSize = 16,
		insets   = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	AboutFrame.Text = AboutFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	AboutFrame.Text:SetWidth(330)
	AboutFrame.Text:SetJustifyH("LEFT")
	AboutFrame.Text:SetPoint("TOPLEFT", 7, -10)
	AboutFrame.Text:SetText(Healium_AddonColoredName .. Version ..
		" |cFFFFFFFFCreated by Engy of Area 52.|n|n|cFFFFFFFFOriginally based on FB Heal Box, which was created by Dourd of Argent Dawn EU.")

	-- ── Apply saved values ────────────────────────────────────────────────────
	Healium_Update_ConfigPanel()

	TooltipsCheck:SetChecked(Healium.ShowToolTips)
	ShowManaCheck:SetChecked(Healium.ShowMana)
	PercentageCheck:SetChecked(Healium.ShowPercentage)
	ClassColorCheck:SetChecked(Healium.UseClassColors)
	HideCloseButtonCheck:SetChecked(Healium.HideCloseButton)
	HideCaptionsCheck:SetChecked(Healium.HideCaptions)
	LockFramePositionsCheck:SetChecked(Healium.LockFrames)
	EnableDebuffsCheck:SetChecked(Healium.EnableDebufs)
	EnableDebuffHealthbarHighlightingCheck:SetChecked(Healium.EnableDebufHealthbarHighlighting)
	EnableDebuffButtonHighlightingCheck:SetChecked(Healium.EnableDebufButtonHighlighting)
	EnableDebufHealthbarColoringCheck:SetChecked(Healium.EnableDebufHealthbarColoring)

	Healium_ShowPartyCheck:SetChecked(Healium.ShowPartyFrame)
	for i = 1, 8 do
		_G["Healium_ShowGroup" .. i .. "Check"]:SetChecked(Healium.ShowGroupFrames[i])
	end

	ScaleSlider:SetValue(Healium.Scale)
	UpdateEnableDebuffsControls(EnableDebuffsCheck)
end
