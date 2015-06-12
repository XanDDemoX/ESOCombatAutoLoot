
local _prefix = "[CombatAutoLoot]: "
local _debug = false 
local _settings = { enabled = true, timeout = 0 } 

local function trim(str)
	if str == nil or str == "" then return str end 
	return (str:gsub("^%s*(.-)%s*$", "%1"))
end 

local function TryParseOnOff(str)
	local on = (str == "+" or str == "on")
	local off = (str == "-" or str == "off")
	if on == false and off == false then return nil end
	return on
end

local function println(...)
	local args = {...}
	if #args == 0 then return end
	for i,v in ipairs(args) do 
		args[i] = tostring(v)
	end 
	table.insert(args,1,_prefix)
	d(table.concat(args))
end

local function debugln(...)
	if _debug == false then return end 
	println(...)
end

local _debugTimes = {}
local function debugtime(key,text)
	if _debug == false then return end
	
	local t = _debugTimes[key] 
	
	if t == nil then 
		t = GetGameTimeMilliseconds()
		_debugTimes[key] = t
		println(text," Start ",key," ",t)
	else
		_debugTimes[key] = nil
		local tt = GetGameTimeMilliseconds()
		println(text," Stop ", key," ",t, " : ", tt, " : ", tt - t)
	end 
end

local function Initialise()

	local _inCombat
	local _handler
	
	local _origAutoLoot
	
	local function ReticleContainerInteractShow(...)
		-- block in combat
		if _settings.enabled == false and _handler ~= nil then
			_handler(...)
		end 
		if _origAutoLoot == nil and _inCombat == false and _handler ~= nil then 
			_handler(...)
		end 
	end
	
	local function Enable()
		if _origAutoLoot ~= nil then return end
		
		
		
		-- get the original setting value
		_origAutoLoot = GetSetting(SETTING_TYPE_LOOT, LOOT_SETTING_AUTO_LOOT)
		 
		SetSetting(SETTING_TYPE_LOOT, LOOT_SETTING_AUTO_LOOT, 1)
		
		debugln("Auto-Loot: Enabled")
	end
	
	local DEBUG_TIME_KEY_RESTORE = "restore"
	
	local function Restore()
		if _origAutoLoot == nil then return end
		
		
			-- restore original
		SetSetting(SETTING_TYPE_LOOT, LOOT_SETTING_AUTO_LOOT, _origAutoLoot)
		_origAutoLoot = nil 
		
		debugtime(DEBUG_TIME_KEY_RESTORE, "Auto-Loot: Restored")
	end
	
	EVENT_MANAGER:RegisterForEvent("CombatAutoLoot_CombatStateChanged",EVENT_PLAYER_COMBAT_STATE,function(eventCode, inCombat)
		
		
		if _inCombat == nil and _settings.enabled == true then 
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
		
			Enable()
			 
		elseif _origAutoLoot ~= nil then
			
			debugtime(DEBUG_TIME_KEY_RESTORE, "Combat Ended ")
			
			local timeout = _settings.timeout 

			if timeout > 0 then 
				zo_callLater(function() if _inCombat == false then Restore() end end ,timeout)
			else
				
				Restore()
			end
			
		end
		
	end)
	
	local _maxTimeout = 10000
	
	SLASH_COMMANDS["/cal"] = function(args)
		args = trim(args)
		
		if args == nil or args == "" then return end 
		
		local timeout = tonumber(args)
		
		if timeout ~= nil then
		
			if timeout >= 0 and timeout <= _maxTimeout then
				_settings.timeout = timeout
				println("Restore delay ",timeout,"ms")
			else
				println("Restore delay ",timeout," out of range (0-",_maxTimeout,"ms)")
			end
			
		else
			
			local onoff = TryParseOnOff(args)
			
			if onoff == nil then return end 
			
			_settings.enabled = onoff
			
			println((_settings.enabled and "Enabled") or "Disabled")
			
		end
	
	end

end 


EVENT_MANAGER:RegisterForEvent("CombatAutoLoot_Loaded", EVENT_ADD_ON_LOADED, function(eventCode, addOnName)

	if addOnName ~= "CombatAutoLoot" then return end 
	
	_settings = ZO_SavedVars:New("CombatAutoLoot_SavedVariables", "1", "", _settings, nil)
	
	Initialise()
	
end)