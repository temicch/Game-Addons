--------------------------------------------------------------------------------
-- GLOBALS
--------------------------------------------------------------------------------
Global( "LC", {} )

local 	PHASE_START,
		PHASE_MIDDLE,
		PHASE_END = 0, 1, 2
local	INDEX_TOP = 1
--------------------------------------------------------------------------------
-- EVENT HANDLERS
--------------------------------------------------------------------------------
function LC.AllocateWidget( wtWidget )
	return common.RequestIntegerByInstanceId(wtWidget:GetInstanceId())
end

function LC.Init(wtPanel, wtOffset, wtIndex)
	if not LC.Widgets then
		LC.Widgets = {}
	end
	local ID_Panel = LC.AllocateWidget(wtPanel)
	
	local _pl = wtPanel:GetPlacementPlain()
	
	LC.Widgets[ID_Panel] = {}
	LC.Widgets[ID_Panel].Offset = wtOffset or 0
	LC.Widgets[ID_Panel].Elements = {}
	LC.Widgets[ID_Panel].ElementsBuffer = {}
	LC.Widgets[ID_Panel].TimerStarted = false
	LC.Widgets[ID_Panel].SizeY = _pl.sizeY
	LC.Widgets[ID_Panel].Index = wtIndex or nil
	LC.Widgets[ID_Panel].IndexMain = true
	
	if not LC.Elements then
		LC.Elements = {}
	end
	
	common.RegisterEventHandler( function(params) LC.OnTimer(params, wtPanel, ID_Panel) end, "EVENT_EFFECT_FINISHED", {wtOwner = wtPanel, effectType = ET_FADE})
	
	if LC.Widgets[ID_Panel].Index then
		LC.SetNewMain(wtPanel)
	else
		common.RegisterEventHandler( LC.OnReceive , "LIB_CONTAINER_RECEIVE", {wtPanel = wtPanel})
	end
end

function LC.GetWidgetTreePath( wtWidget )
	local components = {}
	while wtWidget do
		table.insert( components, 1, wtWidget:GetName() )
		wtWidget = wtWidget:GetParent()
	end
	return table.concat( components, '.' )
end

function LC.SetNewMain(wtPanel)
	local ID_Panel = LC.AllocateWidget(wtPanel)
	
	if not LC.Widgets then return end
	if not LC.Widgets[ID_Panel] then return end
	
	LC.Widgets[ID_Panel].IndexMain = true
	common.RegisterEventHandler( LC.OnReceive , "LIB_CONTAINER_RECEIVE", {wtIndex = LC.Widgets[ID_Panel].Index})
	userMods.SendEvent( "LIB_CONTAINER_NEW_PANEL", { wtPanel = wtPanel, addonName = common.GetAddonName(), wtIndex = LC.Widgets[ID_Panel].Index } )
end


function LC.OnReceive(params)
	local wtPanel, wtNewElement = params.wtPanel, params.wtNewElement
	if not LC.Widgets then return end
	
	local ID_Panel = LC.AllocateWidget(wtPanel)
	local ID_Element = LC.AllocateWidget(wtNewElement)
	
	LC.Elements[ID_Element] = {}
	LC.Elements[ID_Element].Phase = PHASE_START
	LC.Elements[ID_Element].Parent = ID_Panel
	LC.Elements[ID_Element].self = wtNewElement
	
	if not LC.Widgets[ID_Panel] then return end
	
	if LC.Widgets[ID_Panel].TimerStarted == false then
		wtPanel:PlayFadeEffect( 1.0, 1.0, 250, EA_MONOTONOUS_INCREASE )
		LC.Widgets[ID_Panel].TimerStarted = true
	end
	
	wtNewElement:Show(false)
	table.insert(LC.Widgets[ID_Panel].ElementsBuffer, wtNewElement)
end

function LC.Push(wtPanel, wtNewElement)
	local ID_Panel = LC.AllocateWidget(wtPanel)
	userMods.SendEvent( "LIB_CONTAINER_RECEIVE", { wtPanel = wtPanel, wtNewElement = wtNewElement, wtIndex = LC.Widgets[ID_Panel].Index } )
end

function LC.PushTable(wtPanel, wtNewElements)
	if wtNewElements == nil then return end
	if table.maxn(wtNewElements) == 0 then return end
	if not LC.Widgets then return end
	
	local ID_Panel = LC.AllocateWidget(wtPanel)
	
	if not LC.Widgets[ID_Panel] then return end

	--for i, v in pairs(wtNewElements) do
	for i = 1, #wtNewElements do
		local ID_Element = LC.AllocateWidget(wtNewElements[i])
		
		LC.Elements[ID_Element] = {}
		LC.Elements[ID_Element].Phase = PHASE_START
		LC.Elements[ID_Element].Parent = ID_Panel
		LC.Elements[ID_Element].self = wtNewElements[i]

		local wtNewElement = wtNewElements[i]
		
		wtNewElement:Show(true)
		
		common.RegisterEventHandler( LC.OnWidgetEffect, "EVENT_EFFECT_FINISHED", {wtOwner = wtNewElement, effectType = ET_FADE})
		
		wtNewElement:PlayFadeEffect( 0.0, 1.0, 250, EA_MONOTONOUS_INCREASE )
		
		table.insert(LC.Widgets[ID_Panel].Elements, 1, wtNewElement)						
		wtPanel:AddChild(wtNewElement)
	end
	LC.MoveWidgets(wtPanel, ID_Panel)
end

function LC.OnTimer(params, wtPanel, ID_Panel)
	if params.wtOwner:IsValid() == nil then
		return
	end
	local buffer = LC.Widgets[ID_Panel].ElementsBuffer
	LC.Widgets[ID_Panel].ElementsBuffer = {}
	for i = 1, #buffer do
	--for i, element in pairs(buffer) do
		if i > 10 then
			LC.Elements[LC.AllocateWidget(buffer[i])] = nil
			buffer[i]:DestroyWidget()
		else			
			buffer[i]:Show(true)
			
			common.RegisterEventHandler( LC.OnWidgetEffect, "EVENT_EFFECT_FINISHED", {wtOwner = buffer[i], effectType = ET_FADE})
			
			buffer[i]:PlayFadeEffect( 0.0, 1.0, 200, EA_MONOTONOUS_INCREASE )
			
			table.insert(LC.Widgets[ID_Panel].Elements, 1, buffer[i])						
			wtPanel:AddChild(buffer[i])
		end
	end
	LC.MoveWidgets(wtPanel, ID_Panel)
	LC.Widgets[ID_Panel].TimerStarted = false
end

function CopyTable(t)
	local result = { }
	for k, v in pairs( t ) do
		result[k] = v
	end
	return result
end

function LC.MoveWidgets( wtPanel, ID_Panel )
	if LC.Widgets[ID_Panel].Elements and GetTableSize(LC.Widgets[ID_Panel].Elements) > 0 then
		--for j, element in pairs(LC.Widgets[ID_Panel].Elements) do
		for j = 1, #LC.Widgets[ID_Panel].Elements do
			LC.Widgets[ID_Panel].Elements[j]:FinishMoveEffect()
			
			local pl1 = LC.Widgets[ID_Panel].Elements[j]:GetPlacementPlain()
			local pl2 = CopyTable(pl1)
			
			pl1.posY = (pl1.sizeY + LC.Widgets[ID_Panel].Offset) * (j - 2)
			pl2.posY = (pl1.sizeY + LC.Widgets[ID_Panel].Offset) * (j - 1)
			LC.Widgets[ID_Panel].Elements[j]:PlayMoveEffect( pl1, pl2, 400, EA_MONOTONOUS_INCREASE )
				
			if pl2.posY + pl2.sizeY > LC.Widgets[ID_Panel].SizeY then
				LC.Widgets[ID_Panel].Elements[j]:FinishFadeEffect()
				LC.Elements[LC.AllocateWidget(LC.Widgets[ID_Panel].Elements[j])].Phase = PHASE_END
				LC.Widgets[ID_Panel].Elements[j]:PlayFadeEffect( 1.0, 0.0, 100, EA_MONOTONOUS_INCREASE )
			end
		end
	end
end

function LC.GetElementsCount( wtPanel )
	local ID_Panel = LC.AllocateWidget(wtPanel)
	return GetTableSize(LC.Widgets[ID_Panel].Elements)
end

function LC.FindIndex( wtWidget )
	local ID_Panel = LC.AllocateWidget(wtWidget:GetParent())
	local wtID = wtWidget:GetInstanceId()
	if LC.Widgets[ID_Panel] == nil then return nil end

	--for i, v in pairs(LC.Widgets[ID_Panel].Elements) do
	for i = 1, #LC.Widgets[ID_Panel].Elements do
		if LC.Widgets[ID_Panel].Elements[i]:GetInstanceId() == wtID then
			return i
		end
	end
	return nil
end

function LC.KillElement( wtWidget )
	local ID_Element = LC.AllocateWidget(wtWidget)
	local index = LC.FindIndex( wtWidget )
	table.remove(LC.Widgets[LC.Elements[ID_Element].Parent].Elements, index)
	LC.Elements[ID_Element] = nil
	common.UnRegisterEventHandler( LC.OnWidgetEffect, "EVENT_EFFECT_FINISHED", {wtOwner = wtWidget, effectType = ET_FADE})
	wtWidget:FinishFadeEffect()
	wtWidget:FinishMoveEffect()
	wtWidget:DestroyWidget()		
end

function LC.OnWidgetEffect(params)
	if params.wtOwner:IsValid() == nil then
		return
	end
	
	local ID_Element = LC.AllocateWidget(params.wtOwner)

	if LC.Elements[ID_Element].Phase == PHASE_START then
		params.wtOwner:PlayFadeEffect( 1.0, 1.0, 7000, EA_MONOTONOUS_INCREASE  )
		LC.Elements[ID_Element].Phase = PHASE_MIDDLE
	elseif LC.Elements[ID_Element].Phase == PHASE_MIDDLE then
		params.wtOwner:PlayFadeEffect( 1.0, 0.0, 1000, EA_MONOTONOUS_INCREASE	)
		LC.Elements[ID_Element].Phase = PHASE_END
	elseif LC.Elements[ID_Element].Phase == PHASE_END then
		--userMods.SendEvent( "LC_WIDGET_DISAPPEARED", { wtOwner = params.wtOwner } )
		LC.KillElement(params.wtOwner, ID_Element)
	end
end




--[[
local aa = {}
table.insert(aa, {addonName = "Zffff", wtPanel = "rewq"})
table.insert(aa, {addonName = "AZffff", wtPanel = "ttrewq"})
table.insert(aa, {addonName = "FZffff", wtPanel = "zzrewq"})

table.sort(aa, function(a, b) return a.addonName < b.addonName end)

for _, v in pairs(aa) do
	for q, w in pairs(v) do
		LogInfo(q..": "..w)
	end
end
]]--


