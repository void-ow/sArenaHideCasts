local sah_Frame = CreateFrame("Frame")
sah_Frame:RegisterEvent("PLAYER_ENTERING_WORLD")

local function hideUnimportantCasts(self, castBar, event)
	local unitToken = castBar.unit
	
	local targetsPlayer = false
	
	if PlayerIsSpellTarget and unitToken then
		if (castBar.casting or castBar.channeling) and castBar.spellID ~= nil then
			targetsPlayer = PlayerIsSpellTarget(unitToken)
			castBar.Text:SetScale(2)
			local currentSpellTarget = UnitSpellTargetName(unitToken)
			if currentSpellTarget == nil then
				targetsPlayer = true
			end
		end
	end
	
	castBar:SetAlphaFromBoolean(targetsPlayer, 1, 0)
end

local function eventHandler()
	hooksecurefunc(sArena, "CastbarOnEvent", hideUnimportantCasts)
end

sah_Frame:HookScript("OnEvent", function(self)
	C_Timer.After(2, eventHandler);
end)