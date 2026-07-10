$h = Get-Content 'Healium.lua' -Raw
$u = Get-Content 'HealiumUnitFrames.lua' -Raw

# 1. Profile.SpellSet in Healium_UpdateButtonSpells
$oldSpells = '(?s)function Healium_UpdateButtonSpells\(\)\s*local Profile = Healium_GetProfile\(\)\s*for i=1, addonTable\.MaxButtons, 1 do\s*local spell = Profile\.SpellNames\[i\]'
$newSpells = "function Healium_UpdateButtonSpells()`n`tlocal Profile = Healium_GetProfile()`n`tProfile.SpellSet = {}`n`n`tfor i=1, addonTable.MaxButtons, 1 do`n`t`tlocal spell = Profile.SpellNames[i]`n`t`tif spell then Profile.SpellSet[spell] = true end"
$h = $h -replace $oldSpells, $newSpells

# 1b. Update Healium_UpdateUnitBuffs in HealiumUnitFrames.lua
$oldBuffs = '(?s)local armed = false\s*for j=1, Profile\.ButtonCount, 1 do\s*if Profile\.SpellNames\[j\] == name then\s*armed = true\s*break\s*end\s*end\s*if armed == true then'
$newBuffs = 'if Profile.SpellSet and Profile.SpellSet[name] then'
$u = $u -replace $oldBuffs, $newBuffs

# 2. OnUpdate reduction in Healium.lua
$oldOnUpdate = '(?s)for _, frame in ipairs\(addonTable\.Frames\) do\s*if frame:IsShown\(\) and frame\.TargetUnit and UnitIsVisible\(frame\.TargetUnit\) then'
$newOnUpdate = 'for _, frame in pairs(addonTable.ShownFrames) do
				if frame.TargetUnit and UnitIsVisible(frame.TargetUnit) then'
$h = $h -replace $oldOnUpdate, $newOnUpdate

# 3. Scope Pollution: addonTable.CanCureDebuff
$h = $h -replace 'function Healium_CanCureDebuff\(debuffType\)', 'function addonTable.CanCureDebuff(debuffType)'
$u = $u -replace 'Healium_CanCureDebuff\(debuffType\)', 'addonTable.CanCureDebuff(debuffType)'

# 4. Garbage Collection in PopulateSpellCache
$oldPopulate = '(?s)local spellCache = nil\s*local function PopulateSpellCache\(\)\s*spellCache = \{\}'
$newPopulate = "local spellCache = {}`n`nlocal function PopulateSpellCache()`n`ttable.wipe(spellCache)"
$h = $h -replace $oldPopulate, $newPopulate

$h = $h -replace 'spellCache = nil', 'table.wipe(spellCache)'
$h = $h -replace 'if not spellCache then', 'if not next(spellCache) then'

# 5. Unregister UNIT_HEALTH logic in OnHide and OnShow
$oldOnShow = '(?s)function HealiumUnitFrames_Button_OnShow\(self\)\s*addonTable\.ShownFrames\[self\] = self'
$newOnShow = "function HealiumUnitFrames_Button_OnShow(self)`n`taddonTable.ShownFrames[self] = self`n`tHealiumFrame:RegisterEvent('UNIT_HEALTH')"
$u = $u -replace $oldOnShow, $newOnShow

$oldOnHide = '(?s)function HealiumUnitFrames_Button_OnHide\(self\)\s*addonTable\.ShownFrames\[self\] = nil'
$newOnHide = "function HealiumUnitFrames_Button_OnHide(self)`n`n`taddonTable.ShownFrames[self] = nil`n`tif not next(addonTable.ShownFrames) then HealiumFrame:UnregisterEvent('UNIT_HEALTH') end"
$u = $u -replace $oldOnHide, $newOnHide

Set-Content -Path 'Healium.lua' -Value $h
Set-Content -Path 'HealiumUnitFrames.lua' -Value $u

Write-Host "Patched successfully"
