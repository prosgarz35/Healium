$u = Get-Content 'HealiumUnitFrames.lua' -Raw

# 1. Debuff Cache
$u = $u -replace 'local debuffTypes = \{ \}', 'table.wipe(debuffTypesCache)'
$u = $u -replace 'local UnitFrames = \{ \}', "local UnitFrames = { }`nlocal debuffTypesCache = {}"
$u = $u -replace 'debuffTypes\[debuffType\] = true', 'debuffTypesCache[debuffType] = true'
$u = $u -replace 'Healium_ShowDebuffButtons\(Profile, frame, debuffTypes\)', 'Healium_ShowDebuffButtons(Profile, frame, debuffTypesCache)'

# 2. InCombatLockdown
$funcs = @(
	"Healium_ShowHidePartyFrame",
	"Healium_ShowHidePetsFrame",
	"Healium_ShowHideMeFrame",
	"Healium_ShowHideGroupFrame",
	"Healium_HideAllRaidFrames",
	"Healium_Show10ManRaidFrames",
	"Healium_Show25ManRaidFrames",
	"Healium_Show40ManRaidFrames"
)

foreach ($f in $funcs) {
	# Some have 0 params, some have 1, some have 2
	$u = $u -replace "(function $f\([^)]*\))`r?`n", "`$1`n`tif InCombatLockdown() then Healium_Warn('Cannot change frame visibility during combat.') return end`n"
}

Set-Content -Path 'HealiumUnitFrames.lua' -Value $u
Write-Host "UnitFrames patched"
