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

local ClassIcon = {
        DRUID = "Interface/Icons/INV_Misc_MonsterClaw_04",
        WARLOCK = "Interface/Icons/Spell_Nature_FaerieFire",
        HUNTER = "Interface/Icons/INV_Weapon_Bow_07",
        MAGE = "Interface/Icons/INV_Staff_13",
        PRIEST = "Interface/Icons/INV_Staff_30",
        WARRIOR = "Interface/Icons/INV_Sword_27",
        SHAMAN = "Interface/Icons/Spell_Nature_BloodLust",
        PALADIN = "Interface/Icons/Ability_ThunderBolt",
        ROGUE = "Interface/AddOns/ChatIcons/images/UI-CharacterCreate-Classes_Rogue",
		DEATHKNIGHT = "Interface/Icons/Spell_Deathknight_ClassIcon",
		STARCALLER = "Interface/Icons/Spell_Nature_StarFall"
}






local function UpdateRangeCheckSliderText(self)
    self.Text:SetText("Range Check Frequency: |cFFFFFFFF".. format("%.1f",self:GetValue()) .. " Hz")
end

function Healium_SetButtonCount(count)
  HealiumMaxButtonSlider.Text:SetText("Show |cFFFFFFFF"..count.. "|r Buttons")
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

local function ShowBuffsCheck_OnClick(self)
	Healium.ShowBuffs = self:GetChecked() or false
	Healium_UpdateShowBuffs()
end

local function RangeCheckCheck_OnClick(self)
	Healium.DoRangeChecks = self:GetChecked() or false
end

local function EnableCooldownsCheck_OnClick(self)
	Healium.EnableCooldowns = self:GetChecked() or false
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
	local color 
	if self:GetChecked() then
		color = NORMAL_FONT_COLOR
	else
		color = GRAY_FONT_COLOR
	end
	
	for _,j in ipairs(self.children) do
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
	self.Text:SetText("Scale: |cFFFFFFFF".. format("%.1f",Healium.Scale))
end

local function RangeCheckSlider_OnValueChanged(self)
	Healium.RangeCheckPeriod = 1.0 / self:GetValue()
	UpdateRangeCheckSliderText(self)
end

function Healium_ShowConfigPanel()
    if (InterfaceOptionsFrame:IsVisible()) then
      InterfaceOptionsFrame:Hide()
     else
	  InterfaceOptionsFrame_OpenToCategory(addonTable.AddonName)
    end
end


function Healium_Update_ConfigPanel()
	if HealiumMaxButtonSlider then
		HealiumMaxButtonSlider:SetValue(Healium_GetProfile().ButtonCount)
	end
end

function Healium_CreateConfigPanel(Class, Version)
	local Profile = Healium_GetProfile()
	
local panel = CreateFrame("Frame", nil, UIParent)
	panel.name = addonTable.AddonName
	panel.refresh = function (self) self.originalValue = Healium_DeepCopy(Healium) end
	panel.okay = function (self) self.originalValue = Healium_DeepCopy(Healium) end 
	panel.cancel = function (self) 
		if self.originalValue then
			Healium = Healium_DeepCopy(self.originalValue)
		end
	end
	
	InterfaceOptions_AddCategory(panel)

	local scrollframe = CreateFrame("ScrollFrame", "HealiumPanelScrollFrame", panel, "UIPanelScrollFrameTemplate") 
	local framewidth = InterfaceOptionsFramePanelContainer:GetWidth()
	local frameheight = InterfaceOptionsFramePanelContainer:GetHeight() 
	scrollframe:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -25)
	scrollframe:SetWidth(framewidth-45)
	scrollframe:SetHeight(frameheight-45)
	scrollframe:Show()
	
    scrollframe.scrollbar = _G["HealiumPanelScrollFrameScrollBar"]   
    scrollframe.scrollbar:SetBackdrop({   
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",   
        edgeSize = 8,   
        tileSize = 32,   
        insets = { left = 0, right =0, top =5, bottom = 5 }})   
	
	
	local scrollchild = CreateFrame("Frame", "$parentScrollChild", scrollframe)
	scrollframe:SetScrollChild(scrollchild)	


	scrollchild:SetHeight(frameheight - 45)	
	scrollchild:SetWidth(framewidth - 45)
	scrollchild:Show()
	

	local TitleText = scrollchild:CreateFontString(nil, "OVERLAY","GameFontNormalLarge")
	TitleText:SetJustifyH("LEFT")
	TitleText:SetPoint("TOPLEFT", 10, -10)
	TitleText:SetText(addonTable.AddonColoredName .. Version)

	local TitleSubText = scrollchild:CreateFontString(nil, "OVERLAY","GameFontNormalSmall")
	TitleSubText:SetJustifyH("LEFT")
	TitleSubText:SetPoint("TOPLEFT", 10, -30)
	TitleSubText:SetText("Welcome to the " .. addonTable.AddonColoredName .. "  options screen.|nUse the scrollbar to access more options.")
	TitleSubText:SetTextColor(1,1,1,1) 
  

  	local HealiumClassIcon = CreateFrame("Frame", "HealiumClassIcon" ,scrollchild)
	HealiumClassIcon:SetPoint("TOPRIGHT",-20,0)
	HealiumClassIconTexture = HealiumClassIcon:CreateTexture(nil, "BACKGROUND")
	HealiumClassIconTexture:SetAllPoints()
	HealiumClassIconTexture:SetTexture(ClassIcon[Class])
	HealiumClassIcon:SetHeight(60)
	HealiumClassIcon:SetWidth(60)
	HealiumClassIcon.Text = HealiumClassIcon:CreateFontString(nil, "OVERLAY","GameFontNormalLarge")
	HealiumClassIcon.Text:SetText(strupper(Class))
	HealiumClassIcon.Text:SetPoint("CENTER",0,-38)
	HealiumClassIcon.Text:SetTextColor(1,1,0.2,1)

 	

    local TooltipsCheck = CreateFrame("CheckButton","$parentShowTooltipCheckButton",scrollchild,"OptionsCheckButtonTemplate")
	TooltipsCheck:SetPoint("TOPLEFT",5,-70)	
    
    TooltipsCheck.Text = TooltipsCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
	TooltipsCheck.Text:SetPoint("LEFT", TooltipsCheck, "RIGHT", 0)
    TooltipsCheck.Text:SetText("Show Button ToolTips")
	
    TooltipsCheck:SetScript("OnClick", TooltipsCheck_OnClick)
	TooltipsCheck.tooltipText = "Shows spell tooltips when hovering the mouse over the " .. addonTable.AddonColoredName .. " buttons."


    local ShowManaCheck = CreateFrame("CheckButton","$parentShowManaButton",scrollchild,"OptionsCheckButtonTemplate")
    ShowManaCheck:SetPoint("TOPLEFT", TooltipsCheck, "BOTTOMLEFT", 0, 0)
    
    ShowManaCheck.Text = ShowManaCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
	ShowManaCheck.Text:SetPoint("LEFT", ShowManaCheck, "RIGHT", 0)
    ShowManaCheck.Text:SetText("Show Mana")
	
	ShowManaCheck:SetScript("OnClick", ShowManaCheck_OnClick)
	ShowManaCheck.tooltipText = "Shows the unit's mana."

	

    local PercentageCheck = CreateFrame("CheckButton","$parentShowTooltipCheckButton",scrollchild,"OptionsCheckButtonTemplate")
    PercentageCheck:SetPoint("TOPLEFT", ShowManaCheck, "BOTTOMLEFT", 0, 0)
    
    PercentageCheck.Text = PercentageCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
	PercentageCheck.Text:SetPoint("LEFT", PercentageCheck, "RIGHT", 0)
    PercentageCheck.Text:SetText("Show Health Percentage")
	
	PercentageCheck:SetScript("OnClick", PercentageCheck_OnClick)
	PercentageCheck.tooltipText = "Shows the unit's health as a percentage on the right side of the health bar."
	

    local ClassColorCheck = CreateFrame("CheckButton","$parentClassColorCheckButton",scrollchild,"OptionsCheckButtonTemplate")
    ClassColorCheck:SetPoint("TOPLEFT", PercentageCheck, "BOTTOMLEFT", 0, 0)
    
    ClassColorCheck.Text = ClassColorCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
	ClassColorCheck.Text:SetPoint("LEFT", ClassColorCheck, "RIGHT", 0)
    ClassColorCheck.Text:SetText("Use Class Colors")
	
    ClassColorCheck:SetScript("OnClick", ClassColorCheck_OnClick)
	ClassColorCheck.tooltipText = "Colors the healthbar based on the unit's class instead of green/yellow/red based on it's current health."
	

    local HideCloseButtonCheck = CreateFrame("CheckButton","$parentHideCloseCheckButton",scrollchild,"OptionsCheckButtonTemplate")
    HideCloseButtonCheck:SetPoint("TOPLEFT", ClassColorCheck, "BOTTOMLEFT", 0, 0)
    
    HideCloseButtonCheck.Text = HideCloseButtonCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
	HideCloseButtonCheck.Text:SetPoint("LEFT", HideCloseButtonCheck, "RIGHT", 0)
    HideCloseButtonCheck.Text:SetText("Hide Close Buttons")

	HideCloseButtonCheck:SetScript("OnClick", HideCloseButtonCheck_OnClick)	
	HideCloseButtonCheck.tooltipText = "Hides the X (close) button on the upper-right of the " .. addonTable.AddonColoredName ..	" caption bar."


    local HideCaptionsCheck = CreateFrame("CheckButton","$parentHideCaptionsCheckButton",scrollchild,"OptionsCheckButtonTemplate")
    HideCaptionsCheck:SetPoint("TOPLEFT", HideCloseButtonCheck, "BOTTOMLEFT", 0, 0)
    
    HideCaptionsCheck.Text = HideCaptionsCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
	HideCaptionsCheck.Text:SetPoint("LEFT", HideCaptionsCheck, "RIGHT", 0)
    HideCaptionsCheck.Text:SetText("Hide Captions")

	HideCaptionsCheck:SetScript("OnClick", HideCaptionsCheck_OnClick)	
	HideCaptionsCheck.tooltipText = "Automatically hides the caption bar of "  .. addonTable.AddonColoredName .. " frames when the mouse leaves the caption."
	

    local LockFramePositionsCheck = CreateFrame("CheckButton","$parentLockFramePositionsCheckButton",scrollchild,"OptionsCheckButtonTemplate")
    LockFramePositionsCheck:SetPoint("TOPLEFT", HideCaptionsCheck, "BOTTOMLEFT", 0, 0)
    
    LockFramePositionsCheck.Text = LockFramePositionsCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
	LockFramePositionsCheck.Text:SetPoint("LEFT", LockFramePositionsCheck, "RIGHT", 0)
    LockFramePositionsCheck.Text:SetText("Lock Frame Positions")

	LockFramePositionsCheck:SetScript("OnClick", LockFramePositionsCheck_OnClick)	
	LockFramePositionsCheck.tooltipText = "Prevents dragging of any " .. addonTable.AddonColoredName .. " frames."	
	





    HealiumMaxButtonSlider = CreateFrame("Slider","$parentMaxButtonSlider",scrollchild,"OptionsSliderTemplate")
    HealiumMaxButtonSlider:SetWidth(128)
    HealiumMaxButtonSlider:SetHeight(16)
          
    HealiumMaxButtonSlider:SetPoint("TOPLEFT", 220, -110)
      
    HealiumMaxButtonSlider:SetMinMaxValues(0,addonTable.MaxButtons)
    HealiumMaxButtonSlider:SetValueStep(1)
    HealiumMaxButtonSlider:SetValue(Healium_GetProfile().ButtonCount)
	HealiumMaxButtonSlider.tooltipText = "How many " .. addonTable.AddonColoredName .. " buttons to show."
      
    HealiumMaxButtonSlider.Text = HealiumMaxButtonSlider:CreateFontString(nil, "BACKGROUND","GameFontNormalLarge")
    HealiumMaxButtonSlider.Text:SetPoint("CENTER", 0, 17)
    HealiumMaxButtonSlider.Text:SetText("Show |cFFFFFFFF"..HealiumMaxButtonSlider:GetValue().. "|r Buttons")
      
    _G[HealiumMaxButtonSlider:GetName().."Low"]:SetText("0")
    _G[HealiumMaxButtonSlider:GetName().."High"]:SetText(addonTable.MaxButtons)
      
    HealiumMaxButtonSlider:SetScript("OnValueChanged",MaxButtonSlider_Update)
    HealiumMaxButtonSlider:Show()
  

    local ScaleSlider = CreateFrame("Slider","HealiumScaleSlider",scrollchild,"OptionsSliderTemplate")
    ScaleSlider:SetWidth(100)
    ScaleSlider:SetHeight(16)
    
    _G[ScaleSlider:GetName().."Low"]:SetText("Small")
    _G[ScaleSlider:GetName().."High"]:SetText("Large")
    
    ScaleSlider:SetMinMaxValues(0.6,1.5)
    ScaleSlider:SetValueStep(0.1)
    ScaleSlider:SetValue(Healium.Scale)
    
    ScaleSlider:SetPoint("TOPLEFT", HealiumMaxButtonSlider, "BOTTOMLEFT", 0, -30)
    
    ScaleSlider.Text = ScaleSlider:CreateFontString(nil, "BACKGROUND","GameFontNormalLarge")
    ScaleSlider.Text:SetPoint("CENTER", -5, 17)
    ScaleSlider.Text:SetText("Scale: |cFFFFFFFF".. format("%.1f",ScaleSlider:GetValue()))
 
    ScaleSlider:SetScript("OnValueChanged", ScaleSlider_OnValueChanged)
	ScaleSlider.tooltipText = "Sets the scale of all " .. addonTable.AddonColoredName .. " frames."


	local ShowFramesTitleText = scrollchild:CreateFontString(nil, "OVERLAY","GameFontNormalLarge")
	ShowFramesTitleText:SetJustifyH("LEFT")
	ShowFramesTitleText:SetPoint("TOPLEFT", LockFramePositionsCheck, "BOTTOMLEFT", 0, -30)
	ShowFramesTitleText:SetText("Show Frames")	
	
	local ShowFramesTitleSubText = scrollchild:CreateFontString(nil, "OVERLAY","GameFontNormalSmall")
	ShowFramesTitleSubText:SetJustifyH("LEFT")
	ShowFramesTitleSubText:SetPoint("TOPLEFT", ShowFramesTitleText, "BOTTOMLEFT", 0, 0)
	ShowFramesTitleSubText:SetText("Check each frame to show.")
	ShowFramesTitleSubText:SetTextColor(1,1,1,1) 
	

    Healium_ShowPartyCheck = CreateFrame("CheckButton","$parentShowPartyCheckButton",scrollchild,"OptionsCheckButtonTemplate")
    Healium_ShowPartyCheck:SetPoint("TOPLEFT",ShowFramesTitleSubText, "BOTTOMLEFT", 0, -10)
	Healium_ShowPartyCheck.tooltipText = "Shows the Party " .. addonTable.AddonColoredName .. " frame."
    Healium_ShowPartyCheck.Text = Healium_ShowPartyCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
    Healium_ShowPartyCheck.Text:SetPoint("LEFT", Healium_ShowPartyCheck, "RIGHT", 0)
    Healium_ShowPartyCheck.Text:SetText("Party")
    
    Healium_ShowPartyCheck:SetScript("OnClick",function()
        Healium.ShowPartyFrame = Healium_ShowPartyCheck:GetChecked() or false
		Healium_ShowHidePartyFrame()
    end)


    Healium_ShowPetsCheck = CreateFrame("CheckButton","$parentShowPetsCheckButton",scrollchild,"OptionsCheckButtonTemplate")
    Healium_ShowPetsCheck:SetPoint("TOPLEFT",Healium_ShowPartyCheck, "BOTTOMLEFT", 0, 0)
	Healium_ShowPetsCheck.tooltipText = "Shows the Pets " .. addonTable.AddonColoredName .. " frame."	
    Healium_ShowPetsCheck.Text = Healium_ShowPetsCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
    Healium_ShowPetsCheck.Text:SetPoint("LEFT", Healium_ShowPetsCheck, "RIGHT", 0)
    Healium_ShowPetsCheck.Text:SetText("Pets")
    
    Healium_ShowPetsCheck:SetScript("OnClick",function()
        Healium.ShowPetsFrame = Healium_ShowPetsCheck:GetChecked() or false
		Healium_ShowHidePetsFrame()
    end)


    Healium_ShowMeCheck = CreateFrame("CheckButton","$parentShowMeCheckButton",scrollchild,"OptionsCheckButtonTemplate")
    Healium_ShowMeCheck:SetPoint("TOPLEFT",Healium_ShowPetsCheck, "BOTTOMLEFT", 0, 0)
	Healium_ShowMeCheck.tooltipText = "Shows the Me " .. addonTable.AddonColoredName .. " frame."		
    Healium_ShowMeCheck.Text = Healium_ShowMeCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
    Healium_ShowMeCheck.Text:SetPoint("LEFT", Healium_ShowMeCheck, "RIGHT", 0)
    Healium_ShowMeCheck.Text:SetText("Me")
    
    Healium_ShowMeCheck:SetScript("OnClick",function()
        Healium.ShowMeFrame = Healium_ShowMeCheck:GetChecked() or false
		Healium_ShowHideMeFrame()
    end)
	

	local lastGroupCheck = Healium_ShowMeCheck
	for i = 1, 8 do
		local check = CreateFrame("CheckButton","$parentShowGroup"..i.."CheckButton",scrollchild,"OptionsCheckButtonTemplate")
		check:SetPoint("TOPLEFT", lastGroupCheck, "BOTTOMLEFT", 0, 0)
		check.tooltipText = "Shows the Group " .. i .. " " .. addonTable.AddonColoredName .. " frame."
		check.Text = check:CreateFontString(nil, "BACKGROUND","GameFontNormal")
		check.Text:SetPoint("LEFT", check, "RIGHT", 0)
		check.Text:SetText("Group " .. i)
		
		check:SetScript("OnClick",function()
			Healium.ShowGroupFrames[i] = check:GetChecked() or false
			Healium_ShowHideGroupFrame(i)
		end)
		
		_G["Healium_ShowGroup"..i.."Check"] = check
		lastGroupCheck = check
	end


	local DebuffWarningsTitleText = scrollchild:CreateFontString(nil, "OVERLAY","GameFontNormalLarge")
	DebuffWarningsTitleText:SetJustifyH("LEFT")
	DebuffWarningsTitleText:SetPoint("TOPLEFT", Healium_ShowGroup8Check, "BOTTOMLEFT", 0, -30)
	DebuffWarningsTitleText:SetText("Debuff Warnings")
	
	local DebuffWarningsSubText = scrollchild:CreateFontString(nil, "OVERLAY","GameFontNormalSmall")
	DebuffWarningsSubText:SetJustifyH("LEFT")
	DebuffWarningsSubText:SetPoint("TOPLEFT", DebuffWarningsTitleText, "BOTTOMLEFT", 0, 0)
	DebuffWarningsSubText:SetText("Debuff warnings are audible and visual indicators that|nnotify you when you can cure a debuff on a player.")
	DebuffWarningsSubText:SetTextColor(1,1,1,1) 

	

    local EnableDebuffsCheck = CreateFrame("CheckButton","$parentEnableDebuffsCheckButton",scrollchild,"OptionsCheckButtonTemplate")
	EnableDebuffsCheck.children = { }
    EnableDebuffsCheck:SetPoint("TOPLEFT", DebuffWarningsSubText, "BOTTOMLEFT", 0, -10)
    
    EnableDebuffsCheck.Text = EnableDebuffsCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
	EnableDebuffsCheck.Text:SetPoint("LEFT", EnableDebuffsCheck, "RIGHT", 0)
    EnableDebuffsCheck.Text:SetText("Enable Debuff Warnings")

	EnableDebuffsCheck:SetScript("OnClick", EnableDebuffsCheck_OnClick)	
	EnableDebuffsCheck.tooltipText = "Enables debuff warnings"


	
	local EnableDebufHealthbarColoringCheck	= CreateFrame("CheckButton","$parentEnableDebuffHealthbarColoringCheckButton",scrollchild,"OptionsCheckButtonTemplate")
    EnableDebufHealthbarColoringCheck:SetPoint("TOPLEFT", EnableDebuffsCheck, "BOTTOMLEFT", 20, 0)
    
    EnableDebufHealthbarColoringCheck.Text = EnableDebufHealthbarColoringCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
	EnableDebufHealthbarColoringCheck.Text:SetPoint("LEFT", EnableDebufHealthbarColoringCheck, "RIGHT", 0)
    EnableDebufHealthbarColoringCheck.Text:SetText("Healthbar Coloring")
	table.insert(EnableDebuffsCheck.children, EnableDebufHealthbarColoringCheck.Text)
	
	EnableDebufHealthbarColoringCheck:SetScript("OnClick", EnableDebuffHealthbarColoringCheck_OnClick)	
	EnableDebufHealthbarColoringCheck.tooltipText = "Enables coloring of the healthbar of a player that has a debuff which you can cure"
	
	

    local EnableDebuffHealthbarHighlightingCheck = CreateFrame("CheckButton","$parentEnableDebuffHealthbarHighlightingCheck",scrollchild,"OptionsCheckButtonTemplate")
    EnableDebuffHealthbarHighlightingCheck:SetPoint("TOPLEFT", EnableDebufHealthbarColoringCheck, "BOTTOMLEFT", 0, 0)
    
    EnableDebuffHealthbarHighlightingCheck.Text = EnableDebuffHealthbarHighlightingCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
	EnableDebuffHealthbarHighlightingCheck.Text:SetPoint("LEFT", EnableDebuffHealthbarHighlightingCheck, "RIGHT", 0)
    EnableDebuffHealthbarHighlightingCheck.Text:SetText("Healthbar Highlight Warning")
	table.insert(EnableDebuffsCheck.children, EnableDebuffHealthbarHighlightingCheck.Text)
	
	EnableDebuffHealthbarHighlightingCheck:SetScript("OnClick", EnableDebuffHealthbarHighlightingCheck_OnClick)	
	EnableDebuffHealthbarHighlightingCheck.tooltipText = "Enables highlighting of the healthbar of a player that has a debuff which you can cure"



    local EnableDebuffButtonHighlightingCheck = CreateFrame("CheckButton","$parentEnableDebuffButtonHighlightingCheck",scrollchild,"OptionsCheckButtonTemplate")
    EnableDebuffButtonHighlightingCheck:SetPoint("TOPLEFT", EnableDebuffHealthbarHighlightingCheck, "BOTTOMLEFT", 0, 0)
    
    EnableDebuffButtonHighlightingCheck.Text = EnableDebuffButtonHighlightingCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
	EnableDebuffButtonHighlightingCheck.Text:SetPoint("LEFT", EnableDebuffButtonHighlightingCheck, "RIGHT", 0)
    EnableDebuffButtonHighlightingCheck.Text:SetText("Button Highlight Warning")
	table.insert(EnableDebuffsCheck.children, EnableDebuffButtonHighlightingCheck.Text)
	
	EnableDebuffButtonHighlightingCheck:SetScript("OnClick", EnableDebuffButtonHighlightingCheck_OnClick)	
	EnableDebuffButtonHighlightingCheck.tooltipText = "Enables highlighting of buttons which have been assigned a spell that can cure a debuff on a player"


	local UpdatingTitleText = scrollchild:CreateFontString(nil, "OVERLAY","GameFontNormalLarge")
	UpdatingTitleText:SetJustifyH("LEFT")
	UpdatingTitleText:SetPoint("TOPLEFT", EnableDebuffButtonHighlightingCheck, "BOTTOMLEFT", -20, -30)
	UpdatingTitleText:SetText("CPU Intensive Settings")

	local UpdatingTitleSubText = scrollchild:CreateFontString(nil, "OVERLAY","GameFontNormalSmall")
	UpdatingTitleSubText:SetJustifyH("LEFT")
	UpdatingTitleSubText:SetPoint("TOPLEFT", UpdatingTitleText, "BOTTOMLEFT", 0, 0)
	UpdatingTitleSubText:SetText("Enabling these settings may cause extra lag.")
	UpdatingTitleSubText:SetTextColor(1,1,1,1) 
	

    local EnableCooldownsCheck = CreateFrame("CheckButton","$parentEnableCooldownsCheckButton",scrollchild,"OptionsCheckButtonTemplate")
    EnableCooldownsCheck:SetPoint("TOPLEFT", UpdatingTitleSubText, "BOTTOMLEFT", 0, -10)
    EnableCooldownsCheck.tooltipText = "Enables cooldown animations on the " .. addonTable.AddonColoredName .. " buttons."
	
    EnableCooldownsCheck.Text = EnableCooldownsCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
    EnableCooldownsCheck.Text:SetPoint("LEFT", EnableCooldownsCheck, "RIGHT", 0)
    EnableCooldownsCheck.Text:SetText("Enable Cooldowns")
    EnableCooldownsCheck:SetScript("OnClick", EnableCooldownsCheck_OnClick)
	


    local RangeCheckCheck = CreateFrame("CheckButton","$parentRangeCheckButton",scrollchild,"OptionsCheckButtonTemplate")
    RangeCheckCheck:SetPoint("TOPLEFT",EnableCooldownsCheck, "BOTTOMLEFT", 0, 0)
    RangeCheckCheck.tooltipText = "Enables range checks on the " .. addonTable.AddonColoredName .. " buttons."
	
    RangeCheckCheck.Text = RangeCheckCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
    RangeCheckCheck.Text:SetPoint("LEFT", RangeCheckCheck, "RIGHT", 0)
    RangeCheckCheck.Text:SetText("Enable Range Checks")
    RangeCheckCheck:SetScript("OnClick",RangeCheckCheck_OnClick)
	

	local RangeCheckSlider = CreateFrame("Slider","$parentRangeCheckSlider",scrollchild,"OptionsSliderTemplate")
    RangeCheckSlider:SetWidth(180)
    RangeCheckSlider:SetHeight(16)
    
    _G[RangeCheckSlider:GetName().."Low"]:SetText("Slower\n(Less CPU)")
    _G[RangeCheckSlider:GetName().."High"]:SetText("Faster\n(More CPU)")
    
    RangeCheckSlider:SetMinMaxValues(.5,5.0)
    RangeCheckSlider:SetValueStep(0.1)
    RangeCheckSlider:SetValue(1.0/Healium.RangeCheckPeriod)
    
    RangeCheckSlider:SetPoint("TOPLEFT", RangeCheckCheck.Text, "TOPRIGHT", 15, 0)
    RangeCheckSlider.tooltipText = "Controls how often to do range cheks.  The further to the right, the more often range checks are performed and the more CPU it will use."
	
    RangeCheckSlider.Text = RangeCheckSlider:CreateFontString(nil, "BACKGROUND","GameFontNormalSmall")
    RangeCheckSlider.Text:SetPoint("CENTER", -5, 17)
    UpdateRangeCheckSliderText(RangeCheckSlider)
    
    RangeCheckSlider:SetScript("OnValueChanged", RangeCheckSlider_OnValueChanged)
	

	local ShowBuffsCheck = CreateFrame("CheckButton","$parentShowBuffsCheckButton",scrollchild,"OptionsCheckButtonTemplate")
    ShowBuffsCheck:SetPoint("TOPLEFT",RangeCheckCheck, "BOTTOMLEFT", 0, 0)
    ShowBuffsCheck.tooltipText = "Shows the buffs and HOTs you have personally cast on the player to the left of the healthbar.  It will only show spells that are configured in " .. addonTable.AddonColoredName .. "."
	
    ShowBuffsCheck.Text = ShowBuffsCheck:CreateFontString(nil, "BACKGROUND","GameFontNormal")
    ShowBuffsCheck.Text:SetPoint("LEFT", ShowBuffsCheck, "RIGHT", 0)
    ShowBuffsCheck.Text:SetText("Show Buffs")
	ShowBuffsCheck:SetScript("OnClick", ShowBuffsCheck_OnClick);


    local AboutTitle = CreateFrame("Frame","",scrollchild)
    AboutTitle:SetFrameStrata("TOOLTIP")
    AboutTitle:SetWidth(160)
    AboutTitle:SetHeight(20)
    
    AboutTitle.Text = AboutTitle:CreateFontString(nil, "BACKGROUND","GameFontNormalLarge")
    AboutTitle.Text:SetPoint("TOPLEFT",ShowBuffsCheck, "BOTTOMLEFT", 0, -30)
    AboutTitle.Text:SetText("About " .. addonTable.AddonColoredName)
    
    local AboutFrame = CreateFrame("Frame","AboutHealium",scrollchild)
    AboutFrame:SetWidth(340)
    AboutFrame:SetHeight(80)
    AboutFrame:SetPoint("TOPLEFT", AboutTitle.Text, "BOTTOMLEFT", 0, 0)

    AboutFrame:SetBackdrop({bgFile = "",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }})

    AboutFrame.Text = AboutFrame:CreateFontString(nil, "BACKGROUND","GameFontNormal")
    AboutFrame.Text:SetWidth(330)
    AboutFrame.Text:SetJustifyH("LEFT")
    AboutFrame.Text:SetPoint("TOPLEFT", 7,-10)
    AboutFrame.Text:SetText(addonTable.AddonColoredName .. Version .. " |cFFFFFFFFCreated by Engy of Area 52.|n|n|cFFFFFFFFOriginally based on FB Heal Box, which was created by Dourd of Argent Dawn EU.")


	Healium_Update_ConfigPanel()
	
	TooltipsCheck:SetChecked(Healium.ShowToolTips)		
	ShowManaCheck:SetChecked(Healium.ShowMana)
	PercentageCheck:SetChecked(Healium.ShowPercentage)
	ClassColorCheck:SetChecked(Healium.UseClassColors)
	ShowBuffsCheck:SetChecked(Healium.ShowBuffs)
	RangeCheckCheck:SetChecked(Healium.DoRangeChecks)
	EnableCooldownsCheck:SetChecked(Healium.EnableCooldowns)	
	HideCloseButtonCheck:SetChecked(Healium.HideCloseButton)
	HideCaptionsCheck:SetChecked(Healium.HideCaptions)
	LockFramePositionsCheck:SetChecked(Healium.LockFrames)
	EnableDebuffsCheck:SetChecked(Healium.EnableDebufs)
	EnableDebuffHealthbarHighlightingCheck:SetChecked(Healium.EnableDebufHealthbarHighlighting)
	EnableDebuffButtonHighlightingCheck:SetChecked(Healium.EnableDebufButtonHighlighting)
	EnableDebufHealthbarColoringCheck:SetChecked(Healium.EnableDebufHealthbarColoring)
	
	Healium_ShowPartyCheck:SetChecked(Healium.ShowPartyFrame)
	Healium_ShowPetsCheck:SetChecked(Healium.ShowPetsFrame)
	Healium_ShowMeCheck:SetChecked(Healium.ShowMeFrame)
	for i = 1, 8 do
		_G["Healium_ShowGroup"..i.."Check"]:SetChecked(Healium.ShowGroupFrames[i])
	end
	
	ScaleSlider:SetValue(Healium.Scale)
	RangeCheckSlider:SetValue(1.0/Healium.RangeCheckPeriod)
	
	UpdateEnableDebuffsControls(EnableDebuffsCheck)

end


