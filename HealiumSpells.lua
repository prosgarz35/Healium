local CanCureMagic   = false
local CanCureDisease = false
local CanCurePoison  = false
local CanCureCurse   = false

local Cures      = {}
local CuresCount = 0

local CuresConfig = {
	[2782] = { CanCureCurse = true },
	[2893] = { CanCurePoison = true },
	[8946] = { CanCurePoison = true },
	[552] = { CanCureDisease = true },
	[528] = { CanCureDisease = true },
	[527] = { CanCureMagic = true },
	[526]   = { CanCurePoison = true, CanCureDisease = true },
	[51886] = { CanCurePoison = true, CanCureDisease = true, CanCureCurse = true },
	[1152] = { CanCurePoison = true, CanCureDisease = true },
	[4987] = { CanCurePoison = true, CanCureDisease = true, CanCureMagic = true },
	[475] = { CanCureCurse = true },
}

function Healium_InitSpells()
	for spellID, cureData in pairs(CuresConfig) do
		local name = (GetSpellInfo(spellID))
		if name then
			Cures[name] = cureData
			CuresCount  = CuresCount + 1
		end
	end
end

function Healium_UpdateCures()
	local Profile = Healium_GetProfile()

	CanCureMagic   = false
	CanCureDisease = false
	CanCurePoison  = false
	CanCureCurse   = false

	if CuresCount > 0 then
		for i = 1, Profile.ButtonCount do
			local cure = Cures[Profile.SpellNames[i]]
			if cure then
				CanCureMagic   = CanCureMagic   or cure.CanCureMagic
				CanCureDisease = CanCureDisease  or cure.CanCureDisease
				CanCurePoison  = CanCurePoison   or cure.CanCurePoison
				CanCureCurse   = CanCureCurse    or cure.CanCureCurse
			end
		end
	end
end
function Healium_CanCureDebuff(debuffType)
	return (debuffType == "Curse"   and CanCureCurse)   or
	       (debuffType == "Disease" and CanCureDisease)  or
	       (debuffType == "Magic"   and CanCureMagic)    or
	       (debuffType == "Poison"  and CanCurePoison)
end
local DEBUFF_PRIORITY = { "Curse", "Disease", "Magic", "Poison" }
local CURE_FLAG = {
	Curse   = "CanCureCurse",
	Disease = "CanCureDisease",
	Magic   = "CanCureMagic",
	Poison  = "CanCurePoison",
}

function Healium_ShowDebuffButtons(Profile, frame, debuffTypes)
	for i = 1, Profile.ButtonCount do
		local button = frame.buttons[i]
		if button then
			local cure = Cures[Profile.SpellNames[i]]
			local flag, debuffColor

			if cure then
				for _, dtype in ipairs(DEBUFF_PRIORITY) do
					if debuffTypes[dtype] and cure[CURE_FLAG[dtype]] then
						flag        = true
						debuffColor = DebuffTypeColor[dtype]
						break
					end
				end
			end

			local curseBar = button.CurseBar
			if flag then
				curseBar:SetBackdropBorderColor(debuffColor.r, debuffColor.g, debuffColor.b)
				curseBar:SetAlpha(1)
				curseBar.hasDebuf = true
			elseif curseBar.hasDebuf then
				curseBar:SetAlpha(0)
				curseBar.hasDebuf = nil
			end
		end
	end
end