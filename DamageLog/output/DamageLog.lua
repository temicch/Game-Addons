-- WIDGETS
Global( "wtContainerLeft", mainForm:GetChildChecked("ContainerL", true))
Global( "wtContainerRight", mainForm:GetChildChecked("ContainerR", true))

Global( "wtPanelLeft", mainForm:GetChildChecked("MainPanel", true))
Global( "wtPanelRight", mainForm:GetChildChecked("MainPanelRight", true))

Global( "wtText", mainForm:GetChildChecked("Text", true))
Global( "wtNumber", mainForm:GetChildChecked("Number", true))
Global( "wtIcon", mainForm:GetChildChecked("Icon", true))

Global( "wtBarrier", mainForm:GetChildChecked("Barrier", true))

Global( "PANEL_LEFT", 0)
Global( "PANEL_RIGHT", 1)

Global( "TYPE_RECEIVE_DAMAGE", 0)
Global( "TYPE_DAMAGE", 1)
Global( "TYPE_RECEIVE_HEAL", 2)
Global( "TYPE_HEAL", 3)

--Global( "gMinDamage", 1500)
--Global( "gMinRcveDamage", 1000)
--Global( "gMinHeal", 700)
--Global( "gMinRcveHeal", 700)

Global( "gMinDamage", 100)
Global( "gMinRcveDamage", 100)
Global( "gMinHeal", 100)
Global( "gMinRcveHeal", 100)

Global( "gUnits", {})

Global( "gTimer", 0)

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

local spells = {}
spells[TYPE_DAMAGE] = {}
spells[TYPE_RECEIVE_DAMAGE] = {}
spells[TYPE_HEAL] = {}
spells[TYPE_RECEIVE_HEAL] = {}
--------------------------------------------------------------------------------
-- FUNCTIONS
--------------------------------------------------------------------------------
function CreateWidget(widget)
	return mainForm:CreateWidgetByDesc(widget:GetWidgetDesc())
end

function Pack(spell, amount, isFall, isDodge)
	local spellIcon, spellName = nil, nil
	--+++++++++++++++++++++++++++++++++++++++++++++++++++++
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
	--+++++++++++++++++++++++++++++++++++++++++++++++++++++
	if not spell then
		spellName = "Барьер"
	end
	if isFall then
		spellName = "Падение"		
	end	
	return {spellIcon = spellIcon, spellName = spellName, amount = amount}
end

function OnDamageReceived(params)
	local _absorb = params.overallAbsorbedDamage or 0
	if params.isDodge ~= true and params.amount + _absorb < gMinRcveDamage or params.amount + _absorb == 0 then return end
	local _temp = Pack(params.spellId or params.abilityId or params.buffId, params.amount, params.isFall, params.isDodge)
	AddToPanel(PANEL_RIGHT, TYPE_RECEIVE_DAMAGE, _temp.spellName, _temp.spellIcon, _temp.amount, params.isDodge, _absorb, params.spellId or params.abilityId or params.buffId)
	
end

function OnShipDamage(params)
	local attackerName = userMods.ToWString("Неизвестный враг")
	if params.attackerPlayer ~= nil then
		attackerName = object.GetName(params.attackerPlayer)
	end
	if params.defender == avatar.GetBindedTransport() then
		local _temp = Pack(params.spellId or params.abilityId or params.buffId, params.hullDamage, false, false)
		if params.attackerPlayer == nil and params.attacker ~= nil then
			attackerName = object.GetName(params.attacker)
		end
		AddToPanel(PANEL_RIGHT, TYPE_RECEIVE_DAMAGE, attackerName, _temp.spellIcon, _temp.amount, params.isCritical, params.shieldDamage, params.spellId or params.abilityId or params.buffId)
		return
	end

	if not params.attackerPlayer then return end
	local _temp = Pack(params.spellId or params.abilityId or params.buffId, params.hullDamage, false, false)
	AddToPanel(PANEL_LEFT, TYPE_DAMAGE, userMods.FromWString(attackerName).." -> "..userMods.FromWString(common.GetShortString( object.GetName(params.defender) )), _temp.spellIcon, _temp.amount, params.isCritical, params.shieldDamage, params.spellId or params.abilityId or params.buffId)
end

function OnHeal(params)
	if params.heal < gMinHeal or params.heal == 0 then return end
	if not params.healerId or (params.healerId ~= avatar.GetId() and avatar.GetId() ~= unit.GetFollowerMaster( params.healerId )) then return end
	local _temp = Pack(params.spellId or params.abilityId or params.buffId, params.heal, params.isFall, params.isCritical )
	if params.healerId and unit.GetFollowerMaster(params.healerId) then
		_temp.spellName = "["..fromWString(_temp.spellName).."]"
	end
	AddToPanel(PANEL_LEFT, TYPE_HEAL, _temp.spellName, _temp.spellIcon, _temp.amount, params.overload, 0, params.spellId or params.abilityId or params.buffId)
end

function OnDamage(params)
	local _absorb = params.overallAbsorbedDamage or 0
	if params.amount + _absorb < gMinDamage or params.amount + _absorb == 0 then return end
	if params.source == nil then return end
	if params.source ~= avatar.GetId() and avatar.GetId() ~= unit.GetFollowerMaster( params.source ) then return end
	local _temp = Pack(params.spellId or params.abilityId or params.buffId, params.amount, params.isFall, params.isCritical, params.barrier)
	if params.source and unit.GetFollowerMaster(params.source) then
		_temp.spellName = "["..fromWString(_temp.spellName).."]"
	end
	AddToPanel(PANEL_LEFT, TYPE_DAMAGE, _temp.spellName, _temp.spellIcon, _temp.amount, params.isCritical, _absorb, params.spellId or params.abilityId or params.buffId)
	
	--[[
	if params.sourceTags ~= nil then
		for i, v in pairs(params.sourceTags) do
			local info = v:GetInfo()
			Chat(userMods.FromWString(info.name).." "..userMods.FromWString(info.description)..(info.isHelpful == true and " true" or " false"))
		end
	end
	if params.targetTags == nil then return end
	for i, v in pairs(params.targetTags) do
		local info = v:GetInfo()
		Chat(userMods.FromWString(info.name).." "..userMods.FromWString(info.description)..(info.isHelpful == true and " true" or " false"))
	end
	]]--
end

function OnHealReceived(params)
	if params.heal < gMinRcveHeal or params.heal == 0 then return end
	local _temp = Pack(params.spellId or params.abilityId or params.buffId, params.heal, params.isFall, params.isCritical)
	if params.healerId and unit.GetFollowerMaster(params.healerId) then
		_temp.spellName = fromWString(_temp.spellName).." (ѕитомец)"
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

Global("gTimerStarted", false)
Global("panelBufferLeft", {})
Global("panelBufferRight", {})


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
	--LC.Push(_panel, _wtContainer)
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
		--Chat("Add: "..gUnits[id])
		common.RegisterEventHandler( OnDamage, "EVENT_UNIT_DAMAGE_RECEIVED", {target = id})
		common.RegisterEventHandler( OnHeal, "EVENT_HEALING_RECEIVED", {unitId = id})	
	end
end

function PopUnit(id)
	if gUnits[id] then
		--Chat("Remove: "..gUnits[id])
		common.UnRegisterEventHandler( OnDamage, "EVENT_UNIT_DAMAGE_RECEIVED", {target = id})
		common.UnRegisterEventHandler( OnHeal, "EVENT_HEALING_RECEIVED", {unitId = id})
		gUnits[id] = nil
	end
end

function OnFollower(params)
	for _, v in pairs(unit.GetFollowers( avatar.GetId() )) do
		PushUnit(v)
	end
end

function OnTimer()
	gTimer = gTimer > 10 and 0 or gTimer + 1
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------
function Init()
	common.StateUnloadManagedAddon( "ContextDamageVisualization" )
	LC.Init(wtPanelLeft, 0)
	LC.Init(wtPanelRight, 0)
	
	DnD:Init( wtPanelLeft, nil, true)	
	DnD:Enable( wtPanelLeft, false)
	
	DnD:Init( wtPanelRight, nil, true)	
	DnD:Enable( wtPanelRight, false)
	
	wtPanelLeft:SetBackgroundColor( {r=0.0;g=0.0;b=0.0;a=0.0} )
	wtPanelRight:SetBackgroundColor( {r=0.0;g=0.0;b=0.0;a=0.0} )
	
	mainForm:SetPriority(0)
	
	common.RegisterEventHandler( OnDamageReceived, "EVENT_UNIT_DAMAGE_RECEIVED", {target = avatar.GetId()})
	common.RegisterEventHandler( OnHealReceived, "EVENT_HEALING_RECEIVED", {unitId = avatar.GetId()})
	common.RegisterEventHandler( OnSlash, "EVENT_UNKNOWN_SLASH_COMMAND" )
	
	common.RegisterEventHandler( OnFollower, "EVENT_UNIT_FOLLOWERS_LIST_CHANGED", {id = avatar.GetId()})
	
	common.RegisterEventHandler( OnShipDamage, "EVENT_SHIP_DAMAGE_RECEIVED")
	
	
	for _, v in pairs(avatar.GetUnitList()) do
		PushUnit(v)
	end
	
	common.RegisterEventHandler( OnUnitsChanged, "EVENT_UNITS_CHANGED" )
end


 --local wgc=stateMainForm:GetChildUnchecked("ContextShipPlate", false):GetChildUnchecked("Plate", false):GetChildUnchecked("Name", false)
 --local wgc2=wgc:GetChildUnchecked("Name", false)
 --wgc:SetVal("value","УнылаяНастя")
 
 
 local myStr = userMods.ToWString("Гудзоро топ")
 local valuedText = common.CreateValuedText()
local format = "<html ><r name='my'/></html>"
valuedText:SetFormat(userMods.ToWString(format))
valuedText:SetVal("my", myStr)
 
 
 function pp(wdg)
	local widgets = wdg:GetNamedChildren(  )
	for _, v in pairs(widgets) do
		if (common.GetApiType(v)=="TextViewSafe") then
			--v:SetVal("value","УнылаяНастя")
			--v:SetValuedText( valuedText )
			local vlText = v:GetValuedText()
			vlText:SetPlainText(myStr)
			v:SetValuedText(vlText)
			v:SetVal( "value", myStr )
			v:SetVal( "text", myStr )
		end
		if (common.GetApiType(v)=="ButtonSafe") then
			v:SetVal( "value", myStr )
			v:SetVal( "text", myStr )
		end
		pp(v)
	end
 end

 --pp(stateMainForm)
 
--------------------------------------------------------------------------------
if avatar.IsExist() then
	Init()
else
	common.RegisterEventHandler( Init, "EVENT_AVATAR_CREATED" )	
end
--------------------------------------------------------------------------------
