$files = @('HealiumUnitFrames.lua', 'HealiumHealButton.lua', 'HealiumMenu.lua', 'HealiumSpells.lua', 'HealiumConfigPanel.lua')
$upvalues = 'local CreateFrame = CreateFrame
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
'
foreach ($f in $files) {
    if (Test-Path $f) {
        $content = Get-Content $f -Raw
        $content = $content -replace 'local addonName, addonTable = \.\.\.', ("local addonName, addonTable = ..." + [Environment]::NewLine + $upvalues)
        Set-Content -Path $f -Value $content
        Write-Host "Added upvalues to $f"
    }
}
