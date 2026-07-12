

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

-- Factory: creates a configured slider
local function CreateOptionSlider(name, parent, width, min, max, step, initialValue, lowText, highText, tooltip, onValueChanged)
	local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
	slider:SetWidth(width)
	slider:SetHeight(16)
	slider:SetMinMaxValues(min, max)
	slider:SetValueStep(step)
	slider:SetValue(initialValue)
	slider.tooltipText = tooltip
	
	slider.Text = slider:CreateFontString(nil, "BACKGROUND", "GameFontNormalLarge")
	slider.Text:SetPoint("CENTER", 0, 17)
	
	_G[slider:GetName() .. "Low"]:SetText(lowText)
	_G[slider:GetName() .. "High"]:SetText(highText)
	
	slider:SetScript("OnValueChanged", onValueChanged)
	return slider
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

function Healium_CreateConfigPanel()
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
	scrollchild:SetHeight(frameheight - 45)
	scrollchild:SetWidth(framewidth - 45)
	scrollchild:Show()

	-- ── Checkboxes (via factory) ──────────────────────────────────────────────
	local TooltipsCheck = CreateOptionCheckButton(scrollchild, nil,
		"Show Button ToolTips",
		"Shows spell tooltips when hovering the mouse over the " .. Healium_AddonColoredName .. " buttons.",
		TooltipsCheck_OnClick)
	TooltipsCheck:SetPoint("TOPLEFT", 5, -10)

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
	HealiumMaxButtonSlider = CreateOptionSlider("$parentMaxButtonSlider", scrollchild, 128, 0, Healium_MaxButtons, 1, 
		Healium_GetProfile().ButtonCount, "0", Healium_MaxButtons, 
		"How many " .. Healium_AddonColoredName .. " buttons to show.", MaxButtonSlider_Update)
	HealiumMaxButtonSlider:SetPoint("TOPLEFT", 220, -50)
	HealiumMaxButtonSlider.Text:SetText("Show |cFFFFFFFF" .. HealiumMaxButtonSlider:GetValue() .. "|r Buttons")

	-- ── Scale slider ─────────────────────────────────────────────────────────
	local ScaleSlider = CreateOptionSlider("HealiumScaleSlider", scrollchild, 100, 0.6, 1.5, 0.1, 
		Healium.Scale, "Small", "Large", 
		"Sets the scale of all " .. Healium_AddonColoredName .. " frames.", ScaleSlider_OnValueChanged)
	ScaleSlider:SetPoint("TOPLEFT", HealiumMaxButtonSlider, "BOTTOMLEFT", 0, -30)
	ScaleSlider.Text:SetText("Scale: |cFFFFFFFF" .. format("%.1f", ScaleSlider:GetValue()))

	-- Party check (global, referenced from HealiumUnitFrames.lua)
	Healium_ShowPartyCheck = CreateOptionCheckButton(scrollchild, LockFramePositionsCheck,
		"Party",
		"Shows the Party " .. Healium_AddonColoredName .. " frame.",
		function(self)
			Healium.ShowPartyFrame = self:GetChecked() or false
			Healium_ShowHidePartyFrame()
		end,
		0, -30)

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

	-- ── Apply saved values ────────────────────────────────────────────────────
	Healium_Update_ConfigPanel()

	TooltipsCheck:SetChecked(Healium.ShowToolTips)
	ShowManaCheck:SetChecked(Healium.ShowMana)
	PercentageCheck:SetChecked(Healium.ShowPercentage)
	ClassColorCheck:SetChecked(Healium.UseClassColors)
	HideCloseButtonCheck:SetChecked(Healium.HideCloseButton)
	HideCaptionsCheck:SetChecked(Healium.HideCaptions)
	LockFramePositionsCheck:SetChecked(Healium.LockFrames)

	Healium_ShowPartyCheck:SetChecked(Healium.ShowPartyFrame)
	for i = 1, 8 do
		_G["Healium_ShowGroup" .. i .. "Check"]:SetChecked(Healium.ShowGroupFrames[i])
	end

	ScaleSlider:SetValue(Healium.Scale)
end
