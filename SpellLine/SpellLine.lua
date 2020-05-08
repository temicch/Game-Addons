--------------------------------------------------------------------------------
-- GLOBALS
--------------------------------------------------------------------------------
Global("wtLogPanel", mainForm:GetChildChecked( "LogPanel", true ))
Global("wtLogContainer", mainForm:GetChildChecked( "SpellContainer", true ))

local 	PHASE_FADE,
		PHASE_MOVE,
		PHASE_WAIT,
		PHASE_CARETTE = 0, 1, 2, 3
		
local wtMainPanel = mainForm:GetChildChecked( "SpellLine", true )

wtMainPanel:SetClipContent( false )
local wtSpell = mainForm:GetChildChecked( "SpellIcon", true )
local wtTimeText = mainForm:GetChildChecked( "TimeText", true )

local wtLogContainers = {}

local wtPanelSize = {x = 700, y = 50}
local wtSpellSize = {x = wtPanelSize.y * 0.7, y = wtPanelSize.y * 0.7}
local wtPanelPos = {x = 0, y = 779}

local wtMainPanelInactive = 0.6
local wtMainPanelVisible = false

local wtSpellDefaultPl = wtSpell:GetPlacementPlain()

local wtPhases = {}

local spells = {}

local times = {
	{sec = 0, pos = 3+5+5, show = true},
	{sec = 1, pos = 12+5, show = false},
	{sec = 10, pos = 22+5, show = true},
	{sec = 30, pos = 45, show = true},
	{sec = 60, pos = 70-5, show = true},
	{sec = 60*5, pos = 90-5-5, show = true},
	{sec = 60*10, pos = 90, show = false},
}

table.sort(times, function(a, b) return a.sec > b.sec end)
--------------------------------------------------------------------------------
-- EVENT HANDLERS
--------------------------------------------------------------------------------
function OnSpellEffect(params)
	if params.effect == EFFECT_TYPE_COOLDOWN_STARTED and params.remaining > 20000 then
		local spellId = common.RequestIntegerByInstanceId( params.id:GetInstanceId() )
		local i = 1
		while params.remaining < times[i].sec * 1000 do
			i = i + 1
		end
		local wtNewSpell
		if spells[spellId] then
			wtNewSpell = spells[spellId].widget
			wtNewSpell:FinishFadeEffect()
			wtNewSpell:SetFade(1.0)
		else
			spells[spellId] = {}
			wtNewSpell = mainForm:CreateWidgetByDesc(wtSpell:GetWidgetDesc())
						
			wtNewSpell:SetBackgroundTexture(spellLib.GetIcon( params.id ))
			
			wtNewSpell:Show(true)
			wtSpellDefaultPl.sizeX = wtSpellSize.x
			wtSpellDefaultPl.sizeY = wtSpellSize.y
			
			wtNewSpell:SetPlacementPlain(wtSpellDefaultPl)
			
			wtNewSpell:PlayFadeEffect( 1.0, 0.5, 1000, EA_SYMMETRIC_FLASH )	
			
			wtMainPanel:AddChild(wtNewSpell)
		end
		
		spells[spellId].idTimes = i
		
		local pl = wtNewSpell:GetPlacementPlain()
				
		pl.posX = (i == 1 and times[i].pos / 100 * wtPanelSize.x or times[i].pos / 100 * wtPanelSize.x + ((times[i].pos - times[i - 1].pos) / 100 * wtPanelSize.x)*(params.remaining - times[i].sec *1000)/((times[i].sec - times[i - 1].sec) * 1000))
		
		wtSpellDefaultPl.posX = times[i].pos / 100 * wtPanelSize.x
		wtNewSpell:PlayMoveEffect( pl, wtSpellDefaultPl, 1 + params.remaining - times[i].sec * 1000, EA_MONOTONOUS_INCREASE )
		
		spells[spellId].widget = wtNewSpell
		
		wtPhases[common.RequestIntegerByInstanceId( wtNewSpell:GetInstanceId() )] = {}
		
		wtPhases[common.RequestIntegerByInstanceId( wtNewSpell:GetInstanceId() )].phase = PHASE_CARETTE
		wtPhases[common.RequestIntegerByInstanceId( wtNewSpell:GetInstanceId() )].extra = i
	end
	
	if params.effect == EFFECT_TYPE_COOLDOWN_FINISHED then
		local spellId = common.RequestIntegerByInstanceId( params.id:GetInstanceId() )
		if spells[spellId] then
				
			local wtNewLog = mainForm:CreateWidgetByDesc(wtLogContainer:GetWidgetDesc())
			local wtNewIcon = mainForm:CreateWidgetByDesc(wtLogPanel:GetChildChecked("SpellIcon", true):GetWidgetDesc())
			local wtNewText = mainForm:CreateWidgetByDesc(wtLogPanel:GetChildChecked("SpellText", true):GetWidgetDesc())					
			wtNewIcon:SetBackgroundTexture(spellLib.GetIcon( params.id ))
			wtNewIcon:Show(true)	
												
			common.SetTextValues(wtNewText, {Time = spellLib.GetDescription(params.id).name})
			wtNewText:Show(true)
			wtNewText:PlayTextScaleEffect( 0.8, 1.0, 750, EA_MONOTONOUS_INCREASE )
		
			LC.Push(wtLogPanel, wtNewLog)
			
			wtNewLog:PushBack(wtNewIcon)
			wtNewLog:PushBack(wtNewText)
			
			wtNewLog:ForceReposition()
			
			spells[spellId].widget:FinishMoveEffect()
			spells[spellId].widget:FinishFadeEffect()
			spells[spellId].widget:DestroyWidget()
			spells[spellId] = nil
		end
	end
end

function OnCombatStatusChanged(params)
	if params.objectId ~= avatar.GetId() then
		return
	end
	if params.inCombat then
		wtMainPanel:PlayFadeEffect( wtMainPanelInactive, 1.0, 100, EA_MONOTONOUS_INCREASE  )
		wtMainPanelVisible = true
	else
		wtMainPanel:PlayFadeEffect( 1.0, wtMainPanelInactive, 500, EA_MONOTONOUS_INCREASE  )	
		wtMainPanelVisible = false
	end
end

function OnMouseOver(params)
	if wtMainPanelVisible then
		return
	end
	if params.active then
		wtMainPanel:PlayFadeEffect( wtMainPanelInactive, 1.0, 100, EA_MONOTONOUS_INCREASE  )
	else
		wtMainPanel:PlayFadeEffect( 1.0, wtMainPanelInactive, 500, EA_MONOTONOUS_INCREASE  )
	end
end

function OnWidgetEffect(params)
	if params.wtOwner == nil then
		return
	end
	if params.wtOwner:IsValid() == false then
		return
	end

	local instanceId = params.wtOwner:GetInstanceId()
	if instanceId == nil then
		return
	end
	local wId = common.RequestIntegerByInstanceId( instanceId )
	if params.effectType == ET_MOVE then
		if wtPhases[wId] and wtPhases[wId].phase == PHASE_CARETTE and wtPhases[wId].extra < GetTableSize(times) then
			wtSpellDefaultPl.posX = times[wtPhases[wId].extra].pos / 100 * wtPanelSize.x
			local pl = params.wtOwner:GetPlacementPlain()
			local remaining = (times[wtPhases[wId].extra].sec - times[wtPhases[wId].extra + 1].sec) * 1000
			pl.posX = times[wtPhases[wId].extra + 1].pos / 100 * wtPanelSize.x
			
			params.wtOwner:PlayMoveEffect( wtSpellDefaultPl, pl, remaining, EA_MONOTONOUS_INCREASE )
			if(wtPhases[wId].extra == GetTableSize(times) - 1) then
				params.wtOwner:PlayFadeEffect( 1.0, 0.0, remaining, EA_MONOTONOUS_INCREASE  )
			end
			
			wtPhases[wId].extra = wtPhases[wId].extra + 1
		end
	end
end
--------------------------------------------------------------------------------
-- FUNCTIONS
--------------------------------------------------------------------------------
function ConvertSecToString(sec)
	if sec < 60 then
		return tostring(sec).."ñ"
	else
		return math.floor(sec / 60).."ì"..((sec % 60 > 0) and (tostring(sec - math.floor(sec / 60) * 60).."ñ") or "")
	end
end

function SetPanelPlacement(posX, posY, sizeX, sizeY)
	local pl = wtMainPanel:GetPlacementPlain()
	pl.sizeX = sizeX
	pl.sizeY = sizeY
	pl.posX = posX
	pl.posY = posY
	wtMainPanel:SetPlacementPlain(pl)
	wtPanelPos.x, wtPanelPos.y = posX, posY
	wtPanelSize.x, wtPanelSize.y = sizeX, sizeY
end

function ReloadTimeText()
	for _, v in pairs(wtMainPanel:GetNamedChildren()) do
		if v:GetName() == "TimeText" then
			v:DestroyWidget()
		end
	end

	for i, v in pairs(times) do
		if v.show then
			local wtTText = mainForm:CreateWidgetByDesc( wtTimeText:GetWidgetDesc() )
			local pl = wtTText:GetPlacementPlain()
			pl.sizeY = wtPanelSize.y
			pl.posX = wtPanelSize.x * v.pos / 100 -4
			pl.posY = -2
			wtTText:SetPlacementPlain(pl)
			
			wtTText:SetFormat("<header  alignx = \"center\" fontsize=\""..(wtPanelSize.y * 0.35).."\" outline = \"1\"><rs class=\"class\"><r name=\"Time\"/></rs></header>")
			
			wtTText:SetVal("Time", ConvertSecToString(v.sec))
			
			wtTText:SetTextColor( nil, "FFFFFFFF", ENUM_ColorType_TEXT )
			wtTText:SetTextColor( nil, "FF000000", ENUM_ColorType_OUTLINE )
			
			wtTText:Show(true)
			wtMainPanel:AddChild(wtTText)
			wtMainPanel:SetFade(wtMainPanelInactive)
		end
	end
end
--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------
function Init()
	wtMainPanel:Show(true)

	SetPanelPlacement(wtPanelPos.x, wtPanelPos.y, wtPanelSize.x, wtPanelSize.y)
	
	wtMainPanel:SetTransparentInput( false )
	
	DnD.Init( wtMainPanel, nil, true)	
	LC.Init( wtLogPanel, 0 )
	
	common.RegisterEventHandler( OnSpellEffect, "EVENT_SPELLBOOK_ELEMENT_EFFECT")
	common.RegisterEventHandler( OnCombatStatusChanged, "EVENT_OBJECT_COMBAT_STATUS_CHANGED" )
	common.RegisterEventHandler( OnWidgetEffect, "EVENT_EFFECT_FINISHED" )
	
	common.RegisterReactionHandler( OnMouseOver, "mouse_over" )
	
	ReloadTimeText()
	wtSpellDefaultPl.sizeX = wtPanelSize.y
	wtSpellDefaultPl.sizeY = wtPanelSize.y
	wtSpell:SetPlacementPlain(wtSpellDefaultPl)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if avatar.IsExist() then
	Init()
else
	common.RegisterEventHandler( Init, "EVENT_AVATAR_CREATED" )	
end
--------------------------------------------------------------------------------
