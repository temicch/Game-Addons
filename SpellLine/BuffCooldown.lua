--------------------------------------------------------------------------------
-- GLOBALS
--------------------------------------------------------------------------------
Global("_gBuffs", {"Отголоски войны", "Ария войны", "Критическая масса", "Регалия Тирана"})
Global("gBuffs", {})

for _, v in pairs(_gBuffs) do
	gBuffs[v] = {}
end

Global("gMs", 2500)
Global("gUnits", {})
Global("BwtLogPanel", mainForm:CreateWidgetByDesc(wtLogPanel:GetWidgetDesc()))

--------------------------------------------------------------------------------
-- EVENT HANDLERS
--------------------------------------------------------------------------------
function OnTimer(params)
	local icon = params._icon
	local name = params._name
	local playerName = params._playerName
	
	local wtNewLog = mainForm:CreateWidgetByDesc(wtLogContainer:GetWidgetDesc())
	local wtNewIcon = mainForm:CreateWidgetByDesc(BwtLogPanel:GetChildChecked("SpellIcon", true):GetWidgetDesc())
	local wtNewText = mainForm:CreateWidgetByDesc(BwtLogPanel:GetChildChecked("SpellText", true):GetWidgetDesc())	
	local wtNewText2 = mainForm:CreateWidgetByDesc(BwtLogPanel:GetChildChecked("SpellText", true):GetWidgetDesc())					
		
	wtNewIcon:SetBackgroundTexture(icon)
	wtNewIcon:Show(true)	
				
	local _pl = wtNewIcon:GetPlacementPlain()
	_pl.sizeX = 38
	_pl.sizeY = 38
	wtNewIcon:SetPlacementPlain(_pl)
			
	wtNewText:SetFormat("<header fontsize=\"28\" fontname=\"AllodsFantasy\" outline = \"1\" shadow = \"1\"><rs class=\"class\"><tip_white>На <tip_green><r name=\"PlayerName\"/></tip_green> заканчивается</tip_white></rs>  </header>")
	common.SetTextValues(wtNewText, {PlayerName = playerName})
	wtNewText:Show(true)
	wtNewText:PlayTextScaleEffect( 0.8, 1.0, 250, EA_MONOTONOUS_INCREASE )
			
	wtNewText2:SetFormat("<header fontsize=\"28\" fontname=\"AllodsFantasy\" outline = \"1\" shadow = \"1\"><rs class=\"class\"><tip_white><tip_blue><r name=\"Buff\"/></tip_blue></tip_white></rs></header>")
	common.SetTextValues(wtNewText2, {Buff = name})
	wtNewText2:Show(true)
	wtNewText2:PlayTextScaleEffect( 0.8, 1.0, 250, EA_MONOTONOUS_INCREASE )

	LC.Push(BwtLogPanel, wtNewLog)
	
	wtNewLog:PushBack(wtNewText)
	wtNewLog:PushBack(wtNewIcon)
	wtNewLog:PushBack(wtNewText2)
	
	wtNewLog:ForceReposition()
end

function OnBuffAdded(params)
	if gBuffs[userMods.FromWString(params.buffName)] == nil then return end
	local buffInfo = object.GetBuffInfo( params.buffId )
	InitTimer(OnTimer, buffInfo.remainingMs > gMs and buffInfo.remainingMs - gMs or 0, true, {_icon = object.GetBuffInfo( buffInfo.buffId ).texture, _name = object.GetBuffInfo( buffInfo.buffId ).name, _playerName = object.GetName( params.objectId )})
end

--------------------------------------------------------------------------------
-- FUNCTIONS
--------------------------------------------------------------------------------

function PushUnit(id)
	if not gUnits[id] then
		gUnits[id] = userMods.FromWString(object.GetName(id))
		common.RegisterEventHandler( OnBuffAdded, "EVENT_OBJECT_BUFF_ADDED", {objectId = id})
	end
end

function PopUnit(id)
	if id == avatar.GetId() then return end
	if gUnits[id] then
		common.UnRegisterEventHandler( OnBuffAdded, "EVENT_OBJECT_BUFF_ADDED", {objectId = id})
		gUnits[id] = nil
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
--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------
function Init()
	for _, v in pairs(avatar.GetUnitList()) do
		PushUnit(v)
	end
	PushUnit(avatar.GetId())
		
	LC.Init( BwtLogPanel, 0)
	
	local pl = BwtLogPanel:GetPlacementPlain()
	pl.posY = pl.posY + 200
	BwtLogPanel:SetPlacementPlain(pl)
	
	common.RegisterEventHandler( OnUnitsChanged, "EVENT_UNITS_CHANGED" )
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if avatar.IsExist() then
	Init()
else
	common.RegisterEventHandler( Init, "EVENT_AVATAR_CREATED" )	
end
--------------------------------------------------------------------------------
