--------------------------------------------------------------------------------
-- GLOBALS
--------------------------------------------------------------------------------
-- WIDGETS
Global( "IsFinish", true)
Global( "gQuest", 0)
Global( "questsToSkip", {})
local wtCheckBox = mainForm:GetChildChecked("Checkbox", true)
local wtText = mainForm:GetChildChecked("Text", true)
local wtButton = mainForm:GetChildChecked("Button", true)
local wtQuest = mainForm:GetChildChecked("Quest", true)
local wtOnce = mainForm:GetChildChecked("Once", true)

local wtCount = mainForm:GetChildChecked("Count", true)
wtCount:Show(true)
local wtCountText = mainForm:CreateWidgetByDesc(wtText:GetWidgetDesc())
wtCountText:Show(true)
wtCountText:SetFormat("<header alignx = \"center\" color=\"0xFFFFFF00\" fontsize=\"14\" fontname='AllodsWest' shadow=\"0\"><rs class=\"class\"><tip_black><r name=\"val\"/></tip_black></rs></header>")
wtCountText:SetTextColor(nil, "ff000000", ENUM_ColorType_TEXT)
wtCount:AddChild(wtCountText)

local qq = wtCount:GetPlacementPlain()
qq.sizeX = 16
qq.sizeY = 16
qq.posX = 138-4
qq.posY = -5
wtCount:SetPlacementPlain(qq)

qq = wtCountText:GetPlacementPlain()
qq.posY = qq.posY - 1
qq.sizeX = 18
qq.sizeY = 16
wtCountText:SetPlacementPlain(qq)
--------------------------------------------------------------------------------
-- EVENT HANDLERS
--------------------------------------------------------------------------------

function OnCheckboxChanged(params)
	local a = params.widget:GetVariant()
	params.widget:SetVariant(1 - a)
	if (1 - a) == 0 then
		IsFinish = false
		userMods.SetAvatarConfigSection( "IsFinishNeed" , {Finish = false, Quest = wtQuest:GetVariant()})		
	else
		IsFinish = true
		userMods.SetAvatarConfigSection( "IsFinishNeed" , {Finish = true, Quest = wtQuest:GetVariant()})	
	end
end

function OnButtonPressed()
	local quests = avatar.GetAvailableQuests()
	local questState
	local gQuest2 = wtQuest:GetVariant()
	for _, v in pairs(quests) do
	
		if not avatar.GetQuestInfo( v ).isLowPriority and not avatar.GetQuestInfo( v ).isRepeatable then
			questState = 0
		end
		if avatar.GetQuestInfo( v ).isLowPriority and not avatar.GetQuestInfo( v ).isRepeatable then
			questState = 1
		end
		if avatar.GetQuestInfo( v ).isRepeatable then
			questState = 2
		end
				
		if gQuest2 == 0 then 
			if questState == gQuest2 then
				if avatar.GetQuestInfo( v ).canBeSkipped and IsFinish then
					table.insert(questsToSkip, avatar.GetQuestInfo( v ).sysName)
				end
				avatar.AcceptQuest( v )
			end
		elseif gQuest2 == 1 then
			if questState == gQuest2 then
				if avatar.GetQuestInfo( v ).canBeSkipped and IsFinish then
					table.insert(questsToSkip, avatar.GetQuestInfo( v ).sysName)
				end
				avatar.AcceptQuest( v )
			end		
		else
			if questState == gQuest2 then
				if avatar.GetQuestInfo( v ).canBeSkipped and IsFinish then
					table.insert(questsToSkip, avatar.GetQuestInfo( v ).sysName)
				end
				avatar.AcceptQuest( v )
			end	
		end
	end
end

function OnQuestChanged(params)
	local i = params.widget:GetVariant()
	i = i + 1
	if i > 2 then
		i = 0
	end
	params.widget:SetVariant(i)
	if i == 0 then
		Chat("Фильтр: Важные задания")
	elseif i == 1 then
		Chat("Фильтр: Второстепенные задания")
	else
		Chat("Фильтр: Дейлики")
	end
	userMods.SetAvatarConfigSection( "IsFinishNeed" , {Finish = IsFinish, Quest = i})	
	gQuest = i
	wtOnce:Show(false)
	CheckSkips(gQuest)
end

function OnQuestRCChanged(params)
	local i = params.widget:GetVariant()
	i = i - 1
	if i < 0 then
		i = 2
	end
	params.widget:SetVariant(i)
	if i == 0 then
		Chat("Фильтр: Важные задания")
	elseif i == 1 then
		Chat("Фильтр: Второстепенные задания")
	else
		Chat("Фильтр: Дейлики")
	end
	userMods.SetAvatarConfigSection( "IsFinishNeed" , {Finish = IsFinish, Quest = i})	
	gQuest = i
	wtOnce:Show(false)
	CheckSkips(gQuest)
end

function OnQuestReceive(params)
	for _, v in pairs(questsToSkip) do
		if v == avatar.GetQuestInfo( params.questId ).sysName then
			avatar.SkipQuest( params.questId )
			return
		end
	end
end

function CheckSkips(filter)
	if not avatar.IsTalking() then
		return
	end		
	local quests = avatar.GetAvailableQuests()
	local valueToSkip = 0
	local questState
	for _, v in pairs(quests) do
		if not avatar.GetQuestInfo( v ).isLowPriority and not avatar.GetQuestInfo( v ).isRepeatable then
			questState = 0
		end
		if avatar.GetQuestInfo( v ).isLowPriority and not avatar.GetQuestInfo( v ).isRepeatable then
			questState = 1
		end
		if avatar.GetQuestInfo( v ).isRepeatable then
			questState = 2
		end
		if filter == questState and avatar.GetQuestInfo( v ).canBeSkipped then
			valueToSkip = valueToSkip + 1
		end
	end
	if valueToSkip > 0 then
		wtCount:Show(true)
		wtCountText:SetVal("val", ""..valueToSkip)
		wtCount:PlayFadeEffect( 1.0, 0.2, 1200, EA_SYMMETRIC_FLASH )
		return 
	end
	wtCount:Show(false)
end

function OnInteractionStarted()
	if not avatar.IsTalking() then
		return
	end
	questsToSkip = {}
	local quests = avatar.GetAvailableQuests()
	if GetTableSize(quests) == 0 then
		ShowAddon(false)
		wtCount:Show(false)
		return
	end
	ShowAddon(true)
	wtQuest:SetVariant(gQuest)
	
	local once = -1
	local questState
	local starShow = true	
	wtCount:Show(false)
	for _, v in pairs(quests) do
		if not avatar.GetQuestInfo( v ).isLowPriority and not avatar.GetQuestInfo( v ).isRepeatable then
			questState = 0
		end
		if avatar.GetQuestInfo( v ).isLowPriority and not avatar.GetQuestInfo( v ).isRepeatable then
			questState = 1
		end
		if avatar.GetQuestInfo( v ).isRepeatable then
			questState = 2
		end
		if once == -1 then
			once = questState
		else 
			if once ~= questState then
				wtOnce:Show(false)
				CheckSkips(gQuest)
				return
			end
		end	
	end
	wtQuest:SetVariant(questState)
	CheckSkips(questState)
end

--------------------------------------------------------------------------------
-- FUNCTIONS
--------------------------------------------------------------------------------

function ShowAddon(bool)
	wtButton:Show(bool)
	wtCheckBox:Show(bool)
	wtText:Show(bool)
	wtQuest:Show(bool)
	wtOnce:Show(bool)
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------
function Init()
	common.RegisterReactionHandler( OnCheckboxChanged, "checkbox_pressed" )
	common.RegisterReactionHandler( OnQuestChanged, "quest_pressed" )
	common.RegisterReactionHandler( OnQuestRCChanged, "quest_rc_pressed" )
	common.RegisterReactionHandler( OnButtonPressed, "execute" )
		
	common.RegisterEventHandler( OnInteractionStarted, "EVENT_INTERACTION_STARTED" )
	common.RegisterEventHandler( OnQuestReceive, "EVENT_QUEST_RECEIVED" )
	
	local wtNPCMainForm = common.GetAddonMainForm( "NpcTalk" ):GetChildChecked("TalkPanel", false):GetChildChecked("ButtonsPanel", false)
	wtNPCMainForm:SetClipContent( false )
	
	wtNPCMainForm:AddChild(wtCheckBox)
	wtNPCMainForm:AddChild(wtText)
	wtNPCMainForm:AddChild(wtButton)
	wtNPCMainForm:AddChild(wtQuest)
	wtQuest:AddChild(wtOnce)
	wtNPCMainForm:AddChild(wtCount)
	
	local pl = wtText:GetPlacementPlain()
	pl.posX = 25-1
	pl.posY = 4
	pl.sizeX = 320
	pl.sizeY = 24
	wtText:SetPlacementPlain(pl)
	
	wtOnce:Show(true)
	
	wtOnce:SetPriority(5)

	if userMods.GetAvatarConfigSection( "IsFinishNeed" ) == nil then
		userMods.SetAvatarConfigSection( "IsFinishNeed" , {Finish = true, Quest = 0})
	else
		local loadedFinish = userMods.GetAvatarConfigSection( "IsFinishNeed" ).Finish
		local loadedQuest = userMods.GetAvatarConfigSection( "IsFinishNeed" ).Quest
		if loadedFinish == nil or loadedFinish ~= true and loadedFinish ~= false then
			loadedFinish = true
		end
		if loadedQuest == nil or loadedQuest < 0 or loadedQuest > 3 then
			loadedQuest = 0
		end
		IsFinish = loadedFinish
		gQuest = loadedQuest
		wtQuest:SetVariant(loadedQuest)
		userMods.SetAvatarConfigSection( "IsFinishNeed" , {Finish = IsFinish, Quest = gQuest})
	end
	
	if IsFinish then
		wtCheckBox:SetVariant(1)
	else
		wtCheckBox:SetVariant(0)
	end
end

--------------------------------------------------------------------------------
if avatar.IsExist() then
	Init()
else
	common.RegisterEventHandler( Init, "EVENT_AVATAR_CREATED" )
end
--------------------------------------------------------------------------------
