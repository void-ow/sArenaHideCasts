-- NOTES:
-- We can check for CC, but this is a secret data since spellId is secret data, which, i guess, is fair
-- local isCCSpell = C_Spell.IsSpellCrowdControl(spellId)

local sah_Frame = CreateFrame("Frame")

local function isTargetingPlayer(unitToken)

	local currentSpellTarget = UnitSpellTargetName(unitToken)
	
	-- If the target is nil, its an AOE spell - and we show AOE spells for MAGE and WARLOCK to cover Ring of Frost, Frost Wall and Shadowfury
	-- We ignore every AOE spell from other classes (for some reason, evoker spells are fucked though)
	if currentSpellTarget == nil then
		local class = UnitClassBase(unitToken)
		-- Since currentSpellTarget is only nil for AOE spells, we then know that if its MAGE or WARLOCK its the useful aoe spells
		if (class and (class == "MAGE" or class == "WARLOCK")) then
			return true
		end
		return false
	end
	
	-- If it's not nil, its an actual spell with target
	
	-- Lastly, check if it's actually targeting the player (secret data)
	return PlayerIsSpellTarget(unitToken)

end

local function hideUnimportantCasts(self, castBar, event)
	local unitToken = castBar.unit
	
	local targetsPlayer = false
	
	if PlayerIsSpellTarget and unitToken then
		if (castBar.casting or castBar.channeling) and castBar.spellID ~= nil then
			targetsPlayer = isTargetingPlayer(unitToken)
		end
	end
	
	castBar:SetAlphaFromBoolean(targetsPlayer, 1, 0)
	-- Making castbar text a little bit bigger
	castBar.Text:SetScale(1.75)
	
end

local function eventHandler()
	hooksecurefunc(sArena, "CastbarOnEvent", hideUnimportantCasts)
end

sah_Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
sah_Frame:HookScript("OnEvent", function(self)
	C_Timer.After(2, eventHandler);
	
	-- Do the hooking only once, since PLAYER_ENTERING_WORLD gets called on every location change and hooksecurefunc would just add more hooks over and over
	sah_Frame:UnregisterAllEvents();
	sah_Frame:Hide();
	sah_Frame:SetScript("OnEvent", nil);
end)