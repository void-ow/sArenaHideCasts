local sahFrame = CreateFrame("Frame")

local whitelistedAOEClasses = {
	["MAGE"] = true,
	["WARLOCK"] = true,
	["PALADIN"] = true,
}

-- Check for "whitelisted" AOE spellclasses - MAGE, WARLOCK and PALADIN to catch Ring of Frost, Frost Wall, Shadowfury and Searing Glare
local function isWhiteListedAOE(unitToken)
	
	local currentSpellTarget = UnitSpellTargetName(unitToken)
	-- If the target is nil, its an AOE spelL
	-- We ignore every AOE spell from other classes
	if currentSpellTarget == nil then
		local class = UnitClassBase(unitToken)
		-- Since currentSpellTarget is only nil for AOE spells, we then know that if its whitelisted classes then it's the useful aoe spells
		if class == nil then
			return false
		end
		
		if (class and whitelistedAOEClasses[class]) then
			return true
		end
	end
		
	-- If it's not nil, its an actual spell with target
	return false
end

-- Function that returns two (possible) secret booleans - if the spell being cast is targeting player and if that spell is a CC spell
local function isCastedSpellTargetingPlayerAndOrCC(castBar, hideNonCCSpells)
	
	local unitToken = castBar.unit
	
	if unitToken == nil then
		return false, false
	end
	
	if castBar.spellID == nil then
		return false, false
	end
	
	if not castBar.casting and not castBar.channeling then
		return false, false
	end
	
	if isWhiteListedAOE(unitToken) then
		return true, true
	end
	
	local targetsPlayer = PlayerIsSpellTarget(unitToken)
	
	-- Only do the C_Spell call if its actually necessary to save resources
	if hideNonCCSpells then
		return targetsPlayer, C_Spell.IsSpellCrowdControl(castBar.spellID)
	end
	
	-- If we don't need to calculate the CC spell boolean due to config, just returns false
	return targetsPlayer, false
end

-- Main hooked function that handles the castbar hiding, triggered after the sArena function of the same name
local function hideUnimportantCasts(self, castBar, event)
	
	local hideNonCC = sahConfig.hideNonCCSpells
	
	local targetsPlayer, isCCSpell = isCastedSpellTargetingPlayerAndOrCC(castBar, hideNonCC)
	
	-- Only handle hiderFrame if hideNonCC option is enabled
	if hideNonCC and castBar.hiderFrame then
		castBar.hiderFrame:SetAlphaFromBoolean(isCCSpell, 1, 0)
	end
	-- Hide castBar based on targetsPlayer secret boolean
	castBar:SetAlphaFromBoolean(targetsPlayer, 1, 0)
	-- Making castbar text a little bit bigger
	castBar.Text:SetScale(1.75)
end

-- Setting up an intermediate "hider" frame for sArena castbar to handle logic through the SetIgnoreParentAlpha(false)
local function handleHiderSetupForSArenaFrame(mainFrame)
	
	local castBar = mainFrame.CastBar
	local parentFrame = castBar:GetParent()
	
	local castbarHider = CreateFrame("Frame", parentFrame)
	castbarHider:SetAllPoints(parentFrame, true)
	castbarHider.CastbarOnEvent = parentFrame.CastbarOnEvent
	castbarHider.UpdateCastbarTargetOnEvent = parentFrame.UpdateCastbarTargetOnEvent
	
	castBar.hiderFrame = castbarHider
	
	local point, relativeTo, relativePoint, offsetX, offsetY = castBar:GetPoint(1)
	
	castBar:ClearAllPoints()
	castBar:SetParent(castbarHider)
	castBar:SetPoint(point, castbarHider, relativePoint, offsetX, offsetY)
	
	castBar:SetIgnoreParentAlpha(false)
	
	castbarHider:SetAlpha(1)
	castBar:SetAlpha(1)
end

-- General initialization function, called once on login
local function initialize()

	-- First initialization of config values from SavedVariables, putting defaults
	if sahConfig == nil then
		sahConfig = {}
		sahConfig.hideNonCCSpells = false
	end

	-- If we need to hide the non-CC spells, setup the hider frames for every sArena frame
	if (sahConfig.hideNonCCSpells) then
		handleHiderSetupForSArenaFrame(sArenaEnemyFrame1)
		handleHiderSetupForSArenaFrame(sArenaEnemyFrame2)
		handleHiderSetupForSArenaFrame(sArenaEnemyFrame3)
	end
	
	-- And hook to the sArena function
	hooksecurefunc(sArena, "CastbarOnEvent", hideUnimportantCasts)
end

sahFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
sahFrame:HookScript("OnEvent", function(self)
	
	C_Timer.After(2, initialize);
	
	-- Do the hooking only once, since PLAYER_ENTERING_WORLD gets called on every location change and hooksecurefunc would just add more hooks over and over
	sahFrame:UnregisterAllEvents();
	sahFrame:Hide();
	sahFrame:SetScript("OnEvent", nil);
end)