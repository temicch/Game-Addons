-- +=================================+
-- |LibTimer                         |
-- |Emulate a simple timer function  |
-- |Author: Zurion/Cristi Mirt       |
-- |Version: 1.0.0                   |
-- |Last update: 01-11-2016          |
-- +=================================+

Global("timerWidgetDesc",nil)
Global("timerFunctions",{})
Global("timerFunctionsTime",{})
Global("timerWidgets", {})

function InitTimer0()
    --Need to get a widget description
    --local stateAddons = common.GetStateManagedAddons()
    --for k,v in pairs(stateAddons) do
    --    if v.isLoaded then
	--		Chat(v.name)
            local wtAddonMainForm = mainForm
			if wtAddonMainForm ~= nil then
				local wtChild = wtAddonMainForm:GetNamedChildren()
				if table.maxn(wtChild) > 0 then
					timerWidgetDesc = wtChild[0]:GetWidgetDesc()
					--break;
				end
			end
        --end
    --end
end

function ExecuteTimerFunction(params)
    local widgetName = params.wtOwner:GetName()
    if timerFunctions[widgetName] ~= nil then
        local func = timerFunctions[widgetName]
        func()
		timerWidgets[widgetName]:PlayFadeEffect( 1.0, 1.0, timerFunctionsTime[widgetName], EA_MONOTONOUS_INCREASE )
    end
end

function StartTimer(timerWidgetName)
	local wt = timerWidgets[timerWidgetName]
	if wt ~= nil then
		wt:PlayFadeEffect( 1.0, 1.0, timerFunctionsTime[timerWidgetName], EA_MONOTONOUS_INCREASE )
	end
end

function StopTimer(timerWidgetName)
	local wt = timerWidgets[timerWidgetName]
	if wt ~= nil then
		wt:FinishFadeEffect()
	end
end

function InitTimer(func,time)
    local wtTimerWidget = mainForm:CreateWidgetByDesc( timerWidgetDesc )
    wtTimerWidget:Show(false)
    local timerWidgetName = "TimerWidget" .. tostring(common.GetRandFloat( 10000.0, 100000.0 ))
    wtTimerWidget:SetName(timerWidgetName)
    timerFunctions[timerWidgetName] = func
	timerFunctionsTime[timerWidgetName] = time
	timerWidgets[timerWidgetName] = wtTimerWidget
	return timerWidgetName
end

common.RegisterEventHandler( ExecuteTimerFunction , "EVENT_EFFECT_FINISHED")

InitTimer0()
