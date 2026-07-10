$h = Get-Content 'Healium.lua' -Raw

$debounce = "local spellUpdateTimer = nil`nlocal function DoSpellUpdate()`n`tHealium_UpdateSpells()`n`tHealium_UpdateButtons()`n`tHealium_Update_ConfigPanel()`n`tspellUpdateTimer = nil`nend`n`nlocal function DebounceSpellUpdate()`n`tif not spellUpdateTimer then`n`t`tlocal C_Timer = _G.C_Timer`n`t`tif C_Timer then`n`t`t`tspellUpdateTimer = C_Timer.After(0.5, DoSpellUpdate)`n`t`telse`n`t`t`tDoSpellUpdate()`n`t`tend`n`tend`nend`n"

$h = $h -replace '(?s)function addonTable\.Events\.PLAYER_TALENT_UPDATE\(self, arg1, arg2\).*?function addonTable\.Events\.SPELLS_CHANGED\(self, arg1, arg2\).*?function addonTable\.Events\.PLAYER_ENTERING_WORLD\(self, arg1, arg2\).*?end',
($debounce + "function addonTable.Events.PLAYER_TALENT_UPDATE(self, arg1, arg2)`n`tHealium_DebugPrint('PLAYER_TALENT_UPDATE')`n`tself.Respecing = nil`n`tDebounceSpellUpdate()`nend`n`nfunction addonTable.Events.SPELLS_CHANGED(self, arg1, arg2)`n`tif (not self.Respecing) then`n`t`tHealium_DebugPrint('SPELLS_CHANGED')`n`t`tDebounceSpellUpdate()`n`tend`nend`n`nfunction addonTable.Events.PLAYER_ENTERING_WORLD(self, arg1, arg2)`n`tif (not self.Respecing) then`n`t`tHealium_DebugPrint('PLAYER_ENTERING_WORLD')`n`t`tDebounceSpellUpdate()`n`tend`nend")

Set-Content -Path 'Healium.lua' -Value $h
Write-Host "Healium patched"
