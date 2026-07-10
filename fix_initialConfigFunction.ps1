$u = Get-Content 'HealiumUnitFrames.lua' -Raw

$oldFunc = '(?s)local function initialConfigFunction\(frame\).*?if InCombatLockdown\(\) then'
$newFunc = "local function initialConfigFunction(frame)`n`tframe.buttons = {}`n`tframe:RegisterForClicks('AnyUp')`n`ttable.insert(addonTable.Frames, frame)`n`tframe.buffs = {}`n`tfor i=1, MaxBuffs, 1 do`n`t`tlocal buffFrame = CreateFrame('Frame', frame:GetName()..'_Buff'..i, frame, 'HealiumBuffTemplate')`n`t`tif i == 1 then`n`t`t`tbuffFrame:SetPoint('RIGHT', frame, 'LEFT', -2, 0)`n`t`telse`n`t`t`tbuffFrame:SetPoint('RIGHT', frame.buffs[i-1], 'LEFT', -2, 0)`n`t`tend`n`t`tlocal name = buffFrame:GetName()`n`t`tbuffFrame.icon = _G[name..'Icon']`n`t`tbuffFrame.cooldown = _G[name..'Cooldown']`n`t`tbuffFrame.count = _G[name..'Count']`n`t`tbuffFrame.border = _G[name..'Border']`n`t`tbuffFrame.id = i`n`t`tframe.buffs[i] = buffFrame`n`tend`n`n`tif InCombatLockdown() then"

$u = $u -replace $oldFunc, $newFunc
Set-Content -Path 'HealiumUnitFrames.lua' -Value $u
