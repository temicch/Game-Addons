-- WIDGETS
Global( "wtContainerLeft", mainForm:GetChildChecked("ContainerL", true))
Global( "wtContainerRight", mainForm:GetChildChecked("ContainerR", true))

Global( "wtPanelLeft", mainForm:GetChildChecked("MainPanel", true))
Global( "wtPanelRight", mainForm:GetChildChecked("MainPanelRight", true))

Global( "wtText", mainForm:GetChildChecked("Text", true))
Global( "wtNumber", mainForm:GetChildChecked("Number", true))
Global( "wtIcon", mainForm:GetChildChecked("Icon", true))
Global( "wtButtonObservable", mainForm:GetChildChecked("ButtonObservable", true))
Global( "wtName", nil)

Global( "wtBarrier", mainForm:GetChildChecked("Barrier", true))

Global( "PANEL_LEFT", 0)
Global( "PANEL_RIGHT", 1)

Global("gMaxHealth", 0)

Global( "avatarId", nil)

Global( "TYPE_RECEIVE_DAMAGE", 0)
Global( "TYPE_DAMAGE", 1)
Global( "TYPE_RECEIVE_HEAL", 2)
Global( "TYPE_HEAL", 3)

Global( "gMinDamage", 1)
Global( "gMinRcveDamage", 1)
Global( "gMinHeal", 1)
Global( "gMinRcveHeal", 1)

Global( "gMinDamagePercent", 0.100)
Global( "gMinRcveDamagePercent", 0.10)
Global( "gMinHealPercent", 0.100)
Global( "gMinRcveHealPercent", 0.100)

Global( "gObservable", nil)

Global( "gUnits", {})

Global("gTimerStarted", false)
Global("panelBufferLeft", {})
Global("panelBufferRight", {})

Global("spells", {})

local wtFormat = userMods.ToWString("<header fontsize=\"18\" fontname=\"AllodsFantasy\" outline = \"1\" shadow = \"1\"><rs class = \"color\"><r name=\"plus\"/><r name=\"text\"/>\t</rs></header>")
local wtFormatLeft = userMods.ToWString("<header fontsize=\"18\" alignx = \"right\" fontname=\"AllodsFantasy\" outline = \"1\" shadow = \"1\"><rs class = \"color\"><r name=\"plus\"/><r name=\"text\"/>\t</rs></header>")
local wtFormatBarrier = userMods.ToWString("<header fontsize=\"16\" fontname=\"AllodsFantasy\" outline = \"1\" shadow = \"1\"><rs class = \"color\"><r name=\"text\"/>\t</rs></header>")

--------------------------------------------------------------------------------
-- FUNCTIONS
--------------------------------------------------------------------------------
function Chat(message)
	local textFormat = string.format("<html fontsize='18'><rs class='class'>[%s]</rs></html>",message)
	local VT = common.CreateValuedText()
	VT:SetFormat(userMods.ToWString(textFormat))
	VT:SetClassVal("class", "LogColorYellow")
	local chatContainer = stateMainForm:GetChildUnchecked("ChatLog", false):GetChildUnchecked("Area", false):GetChildUnchecked("Panel02",false):GetChildUnchecked("Container", false)
	chatContainer:PushFrontValuedText(VT)

end

function fromWString(msg)
	if common.IsWString( msg ) then
		return userMods.FromWString(msg)
	else
		return msg
	end
end

--------------------------------------------------------------------------------
-- FUNCTIONS
--------------------------------------------------------------------------------
function CreateWidget(widget)
	return mainForm:CreateWidgetByDesc(widget:GetWidgetDesc())
end

function Pack(spell, amount, isFall, isDodge)
	local spellIcon, spellName = nil, userMods.ToWString("NaN")
	
	local _string = common.GetApiType( spell )
	if _string == "SpellId" then
		spellIcon = spellLib.GetIcon( spell )
		spellName = spellLib.GetDescription( spell ).name
	elseif _string == "AbilityId" then
		spellIcon = avatar.GetAbilityInfo( spell ).texture	
		spellName = avatar.GetAbilityInfo( spell ).name
	elseif _string == "BuffId" then
		spellIcon = object.GetBuffInfo( spell ).texture
		spellName = object.GetBuffInfo( spell ).name
	end
	
	if not spell then
		spellName = userMods.ToWString("Барьер")
	end
	if isFall then
		spellName = userMods.ToWString("Падение")
	end	
	return {spellIcon = spellIcon, spellName = spellName, amount = amount}
end

function OnDamageReceived(params)
	local _absorb = params.overallAbsorbedDamage or 0
	if params.isDodge ~= true and params.amount + _absorb < gMinRcveDamage or params.amount + _absorb == 0 then return end
	local _temp = Pack(params.spellId or params.abilityId or params.buffId, params.amount, params.isFall, params.isDodge)
	AddToPanel(PANEL_RIGHT, TYPE_RECEIVE_DAMAGE, _temp.spellName, _temp.spellIcon, _temp.amount, params.isDodge, _absorb, params.spellId or params.abilityId or params.buffId)
	
end

function asd(str, inStr)
	if common.IsWString(inStr) then
		inStr = userMods.FromWString(inStr)
	end
	return str..inStr
end

function OnShipDamage(params)
	local attackerName = userMods.ToWString("*Атакующий*")
	local defenderName = userMods.ToWString("*Мишень*")
	if params.attackerPlayer ~= nil then
		attackerName = object.GetName(params.attackerPlayer)
	end
	if params.defender ~= nil then
		if object.IsExist( params.defender ) then
			defenderName = object.GetName(params.defender)
		end
	end
	if params.defender == avatar.GetBindedTransport() then
		local _temp = Pack(params.spellId or params.abilityId or params.buffId, params.hullDamage, false, false)
		if params.attackerPlayer == nil and params.attacker ~= nil then
			attackerName = object.GetName(params.attacker)
		end
		LogInfo(userMods.FromWString(attackerName).." ("..userMods.FromWString(_temp.spellName)..") - "..asd("Total: ", params.totalDamage).."; "..asd("Ship: ", params.hullDamage).."; "..asd("Shield: ", params.shieldDamage))
		AddToPanel(PANEL_RIGHT, TYPE_RECEIVE_DAMAGE, attackerName, _temp.spellIcon, _temp.amount, params.isCritical, params.shieldDamage, params.spellId or params.abilityId or params.buffId)
		return
	end

	if not params.attackerPlayer then return end
	local _temp = Pack(params.spellId or params.abilityId or params.buffId, params.hullDamage, false, false)

	AddToPanel(PANEL_LEFT, TYPE_DAMAGE, userMods.FromWString(attackerName).." -> "..userMods.FromWString( defenderName ), _temp.spellIcon, _temp.amount, params.isCritical, params.shieldDamage, params.spellId or params.abilityId or params.buffId)
end

function OnHeal(params)
	if params.healerId == params.unitId then return end
	if avatarId == params.unitId then return end
	if params.heal < gMinHeal or params.heal == 0 then return end
	if not params.healerId or (params.healerId ~= gObservable and gObservable ~= unit.GetFollowerMaster( params.healerId )) then return end
	local _temp = Pack(params.spellId or params.abilityId or params.buffId, params.heal, params.isFall, params.isCritical )
	if params.healerId and unit.GetFollowerMaster(params.healerId) then
		_temp.spellName = "["..fromWString(_temp.spellName).."]"
	end
	AddToPanel(PANEL_LEFT, TYPE_HEAL, _temp.spellName, _temp.spellIcon, _temp.amount, params.overload, 0, params.spellId or params.abilityId or params.buffId)
end

function OnDamage(params)
	local _absorb = params.overallAbsorbedDamage or 0
	if params.source == params.target then return end
	if params.amount + _absorb < gMinDamage or params.amount + _absorb == 0 then return end
	if params.source == nil then return end
	if params.source ~= gObservable and gObservable ~= unit.GetFollowerMaster( params.source ) then return end
	local _temp = Pack(params.spellId or params.abilityId or params.buffId, params.amount, params.isFall, params.isCritical, params.barrier)
	if params.source and unit.GetFollowerMaster(params.source) then
		_temp.spellName = "["..fromWString(_temp.spellName).."]"
	end
	--if fromWString(_temp.spellName) ~= "Сожжение" then return end
	AddToPanel(PANEL_LEFT, TYPE_DAMAGE, _temp.spellName, _temp.spellIcon, _temp.amount, params.isCritical, _absorb, params.spellId or params.abilityId or params.buffId)
end

function OnHealReceived(params)
	if params.heal < gMinRcveHeal or params.heal == 0 then return end
	local _temp = Pack(params.spellId or params.abilityId or params.buffId, params.heal, params.isFall, params.isCritical)
	if params.healerId and unit.GetFollowerMaster(params.healerId) then
		_temp.spellName = fromWString(_temp.spellName).." (питомец)"
	end
	AddToPanel(PANEL_RIGHT, TYPE_RECEIVE_HEAL, _temp.spellName, _temp.spellIcon, _temp.amount, params.overload, 0, params.spellId or params.abilityId or params.buffId)
end

function SetAmount(_wtContainer, typeof, side, amount, extra)
	local _wtAmount = CreateWidget(wtNumber)
	_wtContainer:PushBack(_wtAmount)	
	_wtAmount:Show(false)
	
	if amount > 0 then	
		local text = common.FormatNumber( amount or extra, ".2A4" )
		local color, plus = userMods.ToWString("")
		if typeof == TYPE_DAMAGE then
			if extra then
				color = "tip_red"
			else
				color = "tip_golden"
			end
		elseif typeof == TYPE_RECEIVE_DAMAGE then
			color = "tip_red"
			plus = userMods.ToWString("-")
		elseif typeof == TYPE_HEAL then
			color = "tip_green"
		elseif typeof == TYPE_RECEIVE_HEAL	 then
			color = "tip_green"
			plus = userMods.ToWString("+")
		end
		common.SetTextValues(_wtAmount, {
			text = text,
			plus = plus,
			color = color,
			format = side == PANEL_RIGHT and wtFormat or wtFormatLeft
		})
		_wtAmount:Show(true)
	end
	return _wtAmount
end

function SetIcon(_wtContainer, typeof, spellIcon)
	local _wtIcon = CreateWidget(wtIcon)	
	if spellIcon then
		_wtIcon:SetForegroundTexture( spellIcon )
	end
	if not spellIcon and (typeof == TYPE_HEAL or typeof == TYPE_RECEIVE_HEAL) then
		_wtIcon:SetForegroundColor({r = 0, g = 0, b = 0, a = 0})
	end	
	
	local __pl = _wtIcon:GetPlacementPlain()
	__pl.sizeX = 22
	__pl.sizeY = 22
	_wtIcon:SetPlacementPlain(__pl)
	
	_wtContainer:PushBack(_wtIcon)
	_wtIcon:Show(true)
	return _wtIcon
end

function SetSpell(_wtContainer, typeof, name, isCritical)
	local _wtSpell = CreateWidget(wtText)

	common.SetTextValues(_wtSpell, {
	text = common.IsWString(name) and name or userMods.ToWString(name),
	format = wtFormat,
	color = isCritical and "tip_red" or "tip_white"
	})
	_wtContainer:PushBack(_wtSpell)	
	_wtSpell:Show(true)
end

function SetBarrier(_wtContainer, barrier)
	local _wtBarrierText = CreateWidget(wtNumber)
	
	local _wtBarrierIcon = CreateWidget(wtBarrier)	
	_wtContainer:PushBack(_wtBarrierIcon)
	
	local __pl = _wtBarrierIcon:GetPlacementPlain()
	__pl.sizeX = 24
	__pl.sizeY = 24
	_wtBarrierIcon:SetPlacementPlain(__pl)
	
	common.SetTextValues(_wtBarrierText, {
	format = wtFormatBarrier,
	color = "tip_blue",
	text = userMods.ToWString(string.format("(%s)", userMods.FromWString(common.FormatNumber( barrier, ".2A4" ))))
	})
	_wtContainer:PushBack(_wtBarrierText)	
	
	if barrier and barrier > 0 then
		_wtBarrierText:Show(true)
		_wtBarrierIcon:Show(true)
	end
end

function AddToPanel(side, typeof, name, spellIcon, amount, isCritical, barrier, id)
	if side == PANEL_LEFT then
		table.insert(panelBufferLeft, 1, {side = side, typeof = typeof, name = name, spellIcon = spellIcon, amount = amount, isCritical = isCritical, barrier = barrier, id = id})
	else
		table.insert(panelBufferRight, 1, {side = side, typeof = typeof, name = name, spellIcon = spellIcon, amount = amount, isCritical = isCritical, barrier = barrier, id = id})	
	end
	if gTimerStarted == false then
		mainForm:PlayFadeEffect( 1.0, 1.0, 400, EA_MONOTONOUS_INCREASE )
		gTimerStarted = true
	end
end

function onMainformEffect(params)
	local LCBuffer = {}
	for i, v in pairs(panelBufferLeft) do
		if i > 8 then break end
		table.insert(LCBuffer, 1, Trigger(v))
	end
	LC.PushTable(wtPanelLeft, LCBuffer)
	LCBuffer = {}
	for i, v in pairs(panelBufferRight) do
		if i > 8 then break end
		table.insert(LCBuffer, 1, Trigger(v))
	end
	LC.PushTable(wtPanelRight, LCBuffer)
	
	panelBufferLeft = {}
	panelBufferRight = {}
	gTimerStarted = false
end

common.RegisterEventHandler( onMainformEffect, "EVENT_EFFECT_FINISHED", {wtOwner = mainForm, effectType = ET_FADE})

function Trigger(params)
	local side, typeof, name, spellIcon, amount, isCritical, barrier, id = params.side, params.typeof, params.name, params.spellIcon, params.amount, params.isCritical, params.barrier, params.id
	
	local _panel = side == PANEL_LEFT and wtPanelLeft or wtPanelRight
	
	local _wtContainer = CreateWidget(side == PANEL_RIGHT and wtContainerRight or wtContainerLeft)
	
	if side == PANEL_LEFT then
		local _pl = _wtContainer:GetPlacementPlain()
		_pl.alignX = ENUM_AlignX_LEFT
		_wtContainer:SetPlacementPlain(_pl)
	end
		
	local _wtIcon = SetIcon(_wtContainer, typeof, spellIcon)
	local _wtAmount = SetAmount(_wtContainer, typeof, side, amount, isCritical)
	local _wtSpell = SetSpell(_wtContainer, typeof, name, false)
	local _wtBarrierText = SetBarrier(_wtContainer, barrier)
	
	return _wtContainer
end

function OnSlash(p)
	local m = userMods.FromWString(p.text)
	if m == "/dldnd" then
		if not DnD:IsEnabled( wtPanelLeft ) then
			wtPanelLeft:SetBackgroundColor( {r=0.0;g=0.0;b=0.0;a=0.2} )
			DnD:Enable( wtPanelLeft, true )
			wtPanelLeft:SetTransparentInput( false )
			
			wtPanelRight:SetBackgroundColor( {r=0.0;g=0.0;b=0.0;a=0.2} )
			DnD:Enable( wtPanelRight, true )
			wtPanelRight:SetTransparentInput( false )
		else
			wtPanelLeft:SetBackgroundColor( {r=1.0;g=1.0;b=1.0;a=0.0} )
			DnD:Enable( wtPanelLeft, false )
			wtPanelLeft:SetTransparentInput( true )	

			wtPanelRight:SetBackgroundColor( {r=1.0;g=1.0;b=1.0;a=0.0} )
			DnD:Enable( wtPanelRight, false )
			wtPanelRight:SetTransparentInput( true )				
		end
	elseif m == "/c" then
		Chat("wtPanelLeft: "..LC.GetElementsCount(wtPanelLeft))
		Chat("wtPanelRight: "..LC.GetElementsCount(wtPanelRight))
	elseif m == "/cc" then
		for i, v in pairs(gUnits) do
			Chat(i..": "..v)
		end
	end
end

function OnObserveRightPressed(params)
	local targetId = avatar.GetTarget()
	--if gObservable == targetId then return end
	
	if gObservable ~= avatarId then
		common.UnRegisterEvent( "EVENT_UNIT_DESPAWNED")	
	end
	if targetId == nil or targetId == avatarId then
		wtButtonObservable:SetVariant(0)
		ReloadObservable(avatarId)
		return
	end
	wtButtonObservable:SetVariant(1)
	ReloadObservable(targetId)
	common.RegisterEventHandler( function() ReloadObservable(avatarId) end, "EVENT_UNIT_DESPAWNED", {unitId = targetId})
end

function OnTargetChanged(params)
	TargetTrigger()
end

function TargetTrigger()
	local targetId = avatar.GetTarget()
	if targetId then
		wtButtonObservable:GetParent():Show(true)
		if targetId == avatarId and gObservable == avatarId then
			wtButtonObservable:SetVariant(0)
		elseif targetId == gObservable then
			wtButtonObservable:SetVariant(1)
		elseif targetId ~= gObservable and gObservable ~= avatarId then
			wtButtonObservable:SetVariant(2)
		end
		return
	end
	if gObservable == avatarId then
		wtButtonObservable:GetParent():Show(false)
	end
end

function OnObservePressed(params)
	if gObservable ~= avatarId then
		avatar.SelectTarget( gObservable )
	end
end

function OnUnitsChanged(params)
	for _, v in pairs(params.spawned) do
		PushUnit(v)
	end
	for _, v in pairs(params.despawned) do
		PopUnit(v)
	end
end

function PushUnit(id)
	if not gUnits[id] then
		gUnits[id] = userMods.FromWString(object.GetName(id))	
		common.RegisterEventHandler( OnDamage, "EVENT_UNIT_DAMAGE_RECEIVED", {target = id})
		common.RegisterEventHandler( OnHeal, "EVENT_HEALING_RECEIVED", {unitId = id})	
	end
end

function PopUnit(id)
	if id == avatarId then return end
	if gUnits[id] then
		common.UnRegisterEventHandler( OnDamage, "EVENT_UNIT_DAMAGE_RECEIVED", {target = id})
		common.UnRegisterEventHandler( OnHeal, "EVENT_HEALING_RECEIVED", {unitId = id})
		gUnits[id] = nil
	end
end

function OnFollower(params)
	for _, v in pairs(unit.GetFollowers( avatarId )) do
		PushUnit(v)
	end
end

function ReloadObservable(param)
	if gObservable then
		common.UnRegisterEventHandler( OnDamageReceived, "EVENT_UNIT_DAMAGE_RECEIVED", {target = gObservable})
		common.UnRegisterEventHandler( OnHealReceived, "EVENT_HEALING_RECEIVED", {unitId = gObservable})	
	end
	if gObservable == param then
		param = avatarId
	end
	gObservable = param
	common.RegisterEventHandler( OnDamageReceived, "EVENT_UNIT_DAMAGE_RECEIVED", {target = gObservable})
	common.RegisterEventHandler( OnHealReceived, "EVENT_HEALING_RECEIVED", {unitId = gObservable})
	wtButtonObservable:SetVariant(gObservable == avatarId and 0 or 1)
	if gObservable == avatarId then
		wtName:SetVal("val", userMods.ToWString(""))
	else
		wtName:SetVal("val", object.GetName(gObservable))
	end
	TargetTrigger()
end

function ReloadHealth()
	local newMaxHealth = object.GetHealthInfo( avatar.GetId() ).limit 
	if gMaxHealth == newMaxHealth then return end
	gMaxHealth = newMaxHealth
	gMinDamage = gMinDamagePercent * newMaxHealth 
	gMinRcveDamage = gMinRcveDamagePercent * newMaxHealth 
	gMinHeal = gMinHealPercent * newMaxHealth 
	gMinRcveHeal = gMinRcveHealPercent * newMaxHealth 
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------
function Init()
	avatarId = avatar.GetId()
	
	spells[TYPE_DAMAGE] = {}
	spells[TYPE_RECEIVE_DAMAGE] = {}
	spells[TYPE_HEAL] = {}
	spells[TYPE_RECEIVE_HEAL] = {}

	common.StateUnloadManagedAddon( "ContextDamageVisualization" )
	LC.Init(wtPanelLeft, 0)
	LC.Init(wtPanelRight, 0)
	
	DnD:Init( wtPanelLeft, nil, true)	
	DnD:Enable( wtPanelLeft, false)
	
	DnD:Init( wtPanelRight, nil, true)	
	DnD:Enable( wtPanelRight, false)
	
	wtPanelLeft:SetBackgroundColor( {r=0.0;g=0.0;b=0.0;a=0.0} )
	wtPanelRight:SetBackgroundColor( {r=0.0;g=0.0;b=0.0;a=0.0} )
		
	common.RegisterEventHandler( OnSlash, "EVENT_UNKNOWN_SLASH_COMMAND" )
	
	ReloadHealth()
	
	common.RegisterEventHandler( OnFollower, "EVENT_UNIT_FOLLOWERS_LIST_CHANGED", {id = avatarId})
	
	common.RegisterEventHandler( OnShipDamage, "EVENT_SHIP_DAMAGE_RECEIVED")
	
	common.RegisterEventHandler( function(params) LogInfo("(*)"..userMods.FromWString(object.GetName(params.id)).." - "..params.sysType) end, "EVENT_TRANSPORT_CRITICAL_MALFUNCTION")
	
	common.RegisterEventHandler( OnTargetChanged, "EVENT_AVATAR_TARGET_CHANGED")
	
	for _, v in pairs(avatar.GetUnitList()) do
		PushUnit(v)
	end
	PushUnit(avatarId)
	
	common.RegisterEventHandler( OnUnitsChanged, "EVENT_UNITS_CHANGED" )
	
	common.RegisterReactionHandler( OnObservePressed, "observable_pressed" )
	common.RegisterReactionHandler( OnObserveRightPressed, "observable_pressed_right" )
		
	wtName = mainForm:CreateWidgetByDesc(stateMainForm:GetChildChecked("Plates", true):GetChildChecked("Target", true):GetChildChecked("Label", true):GetWidgetDesc())
	
	wtName:SetFormat( "<header fontsize = '14'><html shadow = '1' outlinecolor = '0x000000'><r name = 'val'/></html></header>" )
	wtName:SetVal("val", userMods.ToWString(""))
	local pl = wtName:GetPlacementPlain()
	pl.alignX = 9
	pl.alignY = 3
	pl.sizeX = 150
	pl.posX = 30
	wtName:SetPlacementPlain(pl)
	
	wtButtonObservable:GetParent():AddChild(wtName)
	wtButtonObservable:GetParent():SetClipContent(false)
	
	wtButtonObservable:GetParent():Show(false)
		
	DnD:Init( wtButtonObservable:GetParent(), wtButtonObservable, true)	
	
	ReloadObservable(avatarId)

end
--------------------------------------------------------------------------------
if avatar.IsExist() then
	Init()
else
	common.RegisterEventHandler( Init, "EVENT_AVATAR_CREATED" )	
end
--------------------------------------------------------------------------------