

local _settings = { enabled = true } 

local function Initialise()

	local _inCombat
	local _handler
	
	local function ReticleContainerInteractShow(...)
		-- block in combat
		if _inCombat == false and _handler ~= nil then 
			_handler(...)
		end 
	end
	
	EVENT_MANAGER:RegisterForEvent("CombatAutoLoot_CombatStateChanged",EVENT_PLAYER_COMBAT_STATE,function(eventCode, inCombat)
		
		
		if _inCombat == nil then 
			_inCombat = inCombat
			
			-- ensure recticle handler is ReticleContainerInteractShow
			
			local curHandler = ZO_ReticleContainerInteract:GetHandler("OnShow")
		
			if curHandler ~= ReticleContainerInteractShow then 
				_handler = curHandler -- keep original handler
				ZO_ReticleContainerInteract:SetHandler("OnShow",ReticleContainerInteractShow)
			end
			
		end
		
		_inCombat = inCombat
		
		if _settings.enabled == false then return end
		
		-- enable disable auto loot based on whether in combat
		if _inCombat == true then 
			-- get the original setting value
			_origAutoLoot = GetSetting(SETTING_TYPE_LOOT, LOOT_SETTING_AUTO_LOOT)
			 
			 SetSetting(SETTING_TYPE_LOOT, LOOT_SETTING_AUTO_LOOT, 1)
			 
		elseif _origAutoLoot ~= nil then 
			-- restore original
			SetSetting(SETTING_TYPE_LOOT, LOOT_SETTING_AUTO_LOOT, _origAutoLoot)
			_origAutoLoot = nil 
		end
			
		
	end)

end 


EVENT_MANAGER:RegisterForEvent("CombatAutoLoot_Loaded", EVENT_ADD_ON_LOADED, function(eventCode, addOnName)

	if addOnName ~= "CombatAutoLoot" then return end 
	
	_settings = ZO_SavedVars:New("CombatAutoLoot_SavedVariables", "1", "", _settings, nil)
	
	Initialise()
	
end)