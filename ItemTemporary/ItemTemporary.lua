-- WIDGETS
Global( "wtMainPanel", nil)
Global( "wtSettingsPanel", nil)
Global( "wtItem", nil)
Global( "wtSeparator", nil)
Global( "wtButton", nil)
Global( "wtContainer", nil)
Global( "wtAddonName", nil)
Global( "wtCheckbox", mainForm:GetChildChecked("Checkbox", true))
Global( "wtUp", mainForm:GetChildChecked("Up", true))
Global( "wtHide", mainForm:GetChildChecked("ShowHideBtn", false))

wtUp:Show(false)

Global( "wtInfoText", mainForm:GetChildChecked("InfoPanelText", true))
Global( "wtInfoPanel", mainForm:GetChildChecked("InfoPanel", true))

Global( "wtButtonTurn", mainForm:GetChildChecked("ButtonTurn", true))

wtInfoPanel:Show(false)

Global( "wtDays", nil)
Global( "wtDaysBag", nil)

Global( "gOffset", 0)
Global( "gCategory", 1)

Global( "gCategories", {"Вещи", "Ремёсла", "Редкости"})
Global( "gDays", 1)
Global( "gDaysBag", 3)

Global( "gDaysVariants", {3, 7, 21, 30, 180, 0})

Global( "gThings", 1)
Global( "gCrafts", 1)
Global( "gRarities", 1)

Global( "gPocket", -1)

Global( "gShow", false)

Global( "gStartNotif", false)
Global( "gPointedSlot", nil)

Global( "gTimer", nil)

Global( "wtItems", {})
Global( "wtItemWidgets", {})

Global( "wtTextItem", {})

Global( "wtCategories", {})

Global( "COLORS", {
[ITEM_QUALITY_JUNK] = "Junk",
[ITEM_QUALITY_GOODS] = "Goods",
[ITEM_QUALITY_COMMON] = "Common",
[ITEM_QUALITY_UNCOMMON] = "Uncommon",
[ITEM_QUALITY_RARE] = "Rare",
[ITEM_QUALITY_EPIC] = "Epic",
[ITEM_QUALITY_LEGENDARY] = "Legendary",
[ITEM_QUALITY_RELIC] = "Relic"
})

local wtTab01 = common.GetAddonMainForm( "ContextBag" ):GetChildChecked("Tab01", true)
local wtTab02 = common.GetAddonMainForm( "ContextBag" ):GetChildChecked("Tab02", true)
local wtTab03 = common.GetAddonMainForm( "ContextBag" ):GetChildChecked("Tab03", true)
local wtBag = 	common.GetAddonMainForm( "ContextBag" ):GetChildChecked("Bag", true)
local wtBagArea = 	common.GetAddonMainForm( "ContextBag" ):GetChildChecked("Bag", true):GetChildChecked("Area", true)

--------------------------------------------------------------------------------
-- EVENT HANDLERS
--------------------------------------------------------------------------------

function ShowPanel(bool)
	if not bool then
		wtMainPanel:Show(false)
		wtSettingsPanel:Show(false)
		DestroyItems()
	else
		wtMainPanel:Show(true)
		aa()
	end
end

-- Реакция на нажатие кнопки 
function ShowHideBtnReaction(params)
	if params.widget:GetParent():GetName() == "SettingsPanel" then
		wtSettingsPanel:Show(false)
		return
	end

	-- Если кнопку передвигаем - блокируем дальнейшее выполнение
	if DnD.IsDragging() then return end
	
	-- Если главная панель уже на экране - скрываем и удаляем все элементы на ней
	ShowPanel(not wtMainPanel:IsVisible())
end

-- Обработчик, реагирующий на изменения в багаже главного игрока
function OnInventoryChanged()
	-- Если главная панель на экране - обновляем ее новыми данными
	mainForm:PlayFadeEffect( 1, 1, 100, EA_SYMMETRIC_FLASH )
end

function OnFormEffect(params)
	if not gStartNotif then
		Notification()
		gStartNotif = true
	end
	if wtMainPanel:IsVisible() then
		DestroyItems()
		aa()
	end
	gPocket = -1
end

function OnInventorySizeChanged(params)
	ResetTextItem()
end

-- Удаление всех элементов на главной панели
function DestroyItems()
	gOffset = wtContainer:GetContainerOffset()
	wtItems = {}
	wtItemWidgets = {}
	wtContainer:RemoveItems()
end
--------------------------------------------------------------------------------
-- FUNCTIONS
--------------------------------------------------------------------------------
-- Определение активного кармана в сумке
function GetActiveTab()
	if wtTab01:GetVariant() == 1 then
		return 0
	end
	if wtTab02:GetVariant() == 1 then
		return 1
	end
	if wtTab03:GetVariant() == 1 then
		return 2
	end
end

-- Метод перерисовки надписей срока жизни в сумке
function ResetTextItem()
	for _, v in pairs(wtTextItem) do
		v:DestroyWidget()
		v = nil
	end
	local slotLine, item = 0, 1
	for i = 0, avatar.GetInventorySize() / 3 - 1 do
		if i % 6 == 0 then
			slotLine = slotLine + 1
			item = 1
		end
		local txt = mainForm:CreateWidgetByDesc(mainForm:GetChildChecked("TextItem", true):GetWidgetDesc())
		wtBagArea:GetChildChecked("SlotLine"..userMods.FromWString(common.FormatInt( slotLine, "%02d" )), true):GetChildChecked("Item"..userMods.FromWString(common.FormatInt( item, "%02d" )), true):GetChildChecked("Frame", true):AddChild(txt)		
		wtBagArea:GetChildChecked("SlotLine"..userMods.FromWString(common.FormatInt( slotLine, "%02d" )), true):GetChildChecked("Item"..userMods.FromWString(common.FormatInt( item, "%02d" )), true):GetChildChecked("Frame", true):AddChild(wtBagArea:GetChildChecked("SlotLine"..userMods.FromWString(common.FormatInt( slotLine, "%02d" )), true):GetChildChecked("Item"..userMods.FromWString(common.FormatInt( item, "%02d" )), true):GetChildChecked("Link", true))
		wtTextItem[i] = txt
		item = item + 1
	end
end

function RefreshItemTime()
	if wtBag:IsVisible() == false then
		return
	end
	if gPocket == GetActiveTab() then
		return
	end
	for i = 0, avatar.GetInventorySize() / 3 - 1 do
		local _i = i + avatar.GetInventorySize() / 3 * GetActiveTab()
		wtTextItem[i]:Show(false)
		if avatar.GetInventoryItemId( _i ) then
			local itemTInfo = itemLib.GetTemporaryInfo( avatar.GetInventoryItemId( _i ) )
			if itemTInfo and math.floor(itemTInfo.remainingMs/ 60/ 60/ 24/ 1000) <= gDaysVariants[gDaysBag] then
				common.SetTextValues( wtTextItem[i], {val = userMods.ToWString(FromMillisecondsToString(itemTInfo.remainingMs, true))})
				wtTextItem[i]:Show(true)
			end
		end
	end
	gPocket = GetActiveTab()
end

function ClearItemTime()
	for i = 0, avatar.GetInventorySize() / 3 - 1 do
		wtTextItem[i]:Show(false)
	end
end

-- Метод преобразования миллисекунд в удобный формат
function FromMillisecondsToString(mill, isItemText)
	local FullSecond = mill / 1000
	local days =  math.floor(FullSecond/ 60/ 60/ 24)
	FullSecond = FullSecond - days * 86400
	local hours = math.floor(FullSecond/ 60/ 60)
	FullSecond = FullSecond - hours * 60*60
	local minutes = math.floor(FullSecond/ 60)
	FullSecond = FullSecond - minutes * 60
	local seconds = math.floor(FullSecond)
	return isItemText and (days > 0 and days.."д" or (hours > 0 and hours.."ч" or (minutes > 0 and "<1ч" or "<1м"))) or (days > 0 and days.."д " or "")..(hours > 0 and hours.."ч " or "")..(minutes > 0 and minutes.."м " or "")
end

-- Пользовательский компаратор для сортировки. Сортировка по двум ключам - номер кармана и оставшееся время
function Comparison(a, b)
	if(avatar.InventoryGetItemPocket(a.a) < avatar.InventoryGetItemPocket(b.a)) then
		return true
	elseif(avatar.InventoryGetItemPocket(a.a) > avatar.InventoryGetItemPocket(b.a)) then
		return false
	else
		if(itemLib.GetTemporaryInfo(a.a).remainingMs < itemLib.GetTemporaryInfo(b.a).remainingMs) then
			return true
		else
			return false
		end		
	end
end

function CheckItem(itemId)
	if itemId == nil then
		return false
	end
	local temporaryInfo = itemLib.GetTemporaryInfo( itemId )
	if temporaryInfo == nil then
		return false
	end
	local pocket = avatar.InventoryGetItemPocket( itemId )
	if pocket == -1 and gThings ~= 1 or pocket == 0 and gCrafts ~= 1 or pocket == 1 and gRarities ~= 1 then
		return false
	end
	return true
end

-- Метод создания главной панели
function aa()
	-- Получаем все предметы из багажа игрока
	local itemIds = avatar.GetInventoryItemIds()
	-- Проход циклом, добавление в таблицу предметов, имеющих срок годности
	for i, v in pairs(itemIds) do
		if CheckItem(v) then
			table.insert(wtItems, {a = v, b = i})
		end
	end
	if table.maxn(wtItems) == 0 then
		local _wtText = mainForm:CreateWidgetByDesc(mainForm:GetChildChecked("Text2", true):GetWidgetDesc())	
		_wtText:SetAlignY( 1 )	
		local pl = _wtText:GetPlacementPlain()
		pl.posX = 0
		pl.posY = 0
		pl.sizeY = wtContainer:GetPlacementPlain().sizeY/2
		pl.alignX = 3
		pl.alignY = 1
		_wtText:SetPlacementPlain(pl)
		_wtText:Show(true)
		_wtText:SetFormat("<header alignx = \"center\" aligny = \"center\" fontsize=\"20\"><rs class=\"class\"><html outline=\"1\" shadow=\"0\" outlinecolor=\"0xFF000000\"><b>Не найдено ничего подходящего</b></html></rs></header>")
		wtContainer:PushBack(_wtText)
		return
	end
	-- Сортируем вещи по сроку годности
	table.sort(wtItems, Comparison )
	-- Текущий карман. Бывают следующие: Вещи, Ремесло, Редкости. Будем добавлять в сумку по очередности
	local currentBag = -10
	local pl = nil	
	local itemPocket = nil
	
	wtSeparator:Show(false)
	gCategory = 2
	-- Проход циклом по таблице предметов
	for _, z in pairs(wtItems) do
		local v = z.a
		itemPocket = avatar.InventoryGetItemPocket( v )
		if avatar.InventoryGetItemPocket( v ) ~= gCategory then
			local _wtSeparator = mainForm:CreateWidgetByDesc(wtSeparator:GetWidgetDesc())
			wtContainer:PushBack(_wtSeparator)
			common.SetTextValues( _wtSeparator:GetChildChecked("SeparatorText", true), {val = userMods.ToWString(gCategories[itemPocket + 2])})
			gCategory = itemPocket
		end
		-- Добавляем кнопку
		local _wtItem = mainForm:CreateWidgetByDesc(wtItem:GetWidgetDesc())	
		local wtIcon = _wtItem:GetChildChecked("Button", true)
		-- Назначаем изображение
		wtItemWidgets[wtIcon:GetInstanceId()] = z
		wtIcon:SetBackgroundTexture(itemLib.GetItemInfo( v ).icon)
		-- Если предмет возможно активировать - делаем кнопку "юзабельной" (на нее можно нажать)
		if 	itemLib.IsUsable( v ) == false and
			itemLib.GetBoxInfo( v ) == nil and
			itemLib.IsUseItemAndTakeActions( v ) == false and
			itemLib.CanActivateForUseItem( v ) == false then
				wtIcon:Enable(false)
		end
		-- Добавляем к кнопке количество предметов
		local wtCount = wtIcon:GetChildChecked("Count", true)	
		common.SetTextValues( wtCount, {val = common.FormatInt(itemLib.GetStackInfo( v ).count , "%dK5" )})
		-- Добавляем название предмета
		local wtName = _wtItem:GetChildChecked("Name", true)
		common.SetTextValues( wtName, {val = itemLib.GetItemInfo( v ).name})
		local quality = itemLib.GetQuality( v ).quality
		wtName:SetClassVal("class", COLORS[quality])
		-- Добавляем виджет для отображения времени
		local wtTemporary = _wtItem:GetChildChecked("Time", true)
		common.SetTextValues( wtTemporary, {val = userMods.ToWString(FromMillisecondsToString(itemLib.GetTemporaryInfo( v ).remainingMs))})
		-- Добавление виджетов на главную панель
		wtContainer:PushBack(_wtItem)
	end
	wtContainer:SetContainerOffset(gOffset)
end

-- Реакция на нажатия кнопки с предметом. Различные методы для различных видов предмета
function OnPressButtonDown(params)
	if avatar.IsInspectAllowed() == false then
		return
	end
	local vItem = wtItemWidgets[params.widget:GetInstanceId()]
	local v = vItem.a
	if itemLib.IsUsable( v ) then
		avatar.UseItem( v )
		return;
	end
	if itemLib.GetBoxInfo( v ) ~= nil then
		avatar.OpenBox( v )
		return;
	end
	if itemLib.IsUseItemAndTakeActions( v ) then
		avatar.UseItemAndTakeActions( v )
		return;
	end
	if itemLib.CanActivateForUseItem( v ) then
		avatar.UseItemAndTakeActions( v )
		return;
	end
end

function OnPointingButton(params)
	if gPointedSlot ~= nil then
		gPointedSlot:PlayFadeEffect( 0.5, 0.0, 200, EA_MONOTONOUS_INCREASE )
		gPointedSlot = nil
		return
	end
	local v = wtItemWidgets[params.widget:GetInstanceId()].b
	local slotId = v % (avatar.GetInventorySize() / 3)
	local pocketNum = math.floor(v / (avatar.GetInventorySize() / 3))
	if pocketNum ~= GetActiveTab() then
		return
	end
	
	local slotLine = common.FormatInt( 1 + math.floor(slotId / 6), "%02d" )
	local item = 1 + slotId - math.floor(slotId / 6) * 6
	
	gPointedSlot = wtBagArea:GetChildChecked("SlotLine"..userMods.FromWString(slotLine), true):GetChildChecked("Item"..userMods.FromWString(common.FormatInt( item, "%02d" )), true):GetChildChecked("Autocast", true)
	gPointedSlot:Show( true )
	gPointedSlot:PlayFadeEffect( 0.5, 1.0, 500, EA_MONOTONOUS_INCREASE )
end

function CreateSettings()
	wtSettingsPanel =  mainForm:CreateWidgetByDesc(wtMainPanel:GetWidgetDesc())
	--wtSettingsPanel:Show(true)
	DnD.Init( wtSettingsPanel, nil, false)
	wtSettingsPanel:SetName("SettingsPanel")
	wtSettingsPanel:GetChildChecked("ButtonSettings", true):DestroyWidget()
	wtSettingsPanel:GetChildChecked("ButtonTurn", true):DestroyWidget()
	wtSettingsPanel:GetChildChecked("ButtonRefresh", true):DestroyWidget()
	wtSettingsPanel:GetChildChecked("Button", true):Show(false)
	wtSettingsPanel:GetChildChecked("Separator", true):Show(false)
	
	local wtSettingsCorner = mainForm:CreateWidgetByDesc(mainForm:GetChildChecked("Text2", true):GetWidgetDesc())
	local pl = wtSettingsCorner:GetPlacementPlain()
	wtSettingsCorner:	SetVal("val", "Настройки")
	pl.alignX = 3
	pl.alignY = 0
	pl.posY = 10
	wtSettingsCorner:	SetFormat("<header alignx = \"center\" fontsize=\"18\"><rs class=\"class\"><r name=\"val\"/></rs></header>")
	wtSettingsCorner:SetPlacementPlain(pl)
	wtSettingsCorner:Show(true)
	wtSettingsPanel:AddChild(wtSettingsCorner)
	
	local _wtSeparator = mainForm:CreateWidgetByDesc(wtSeparator:GetWidgetDesc())
	_wtSeparator:SetName("Отображение")
	wtSettingsPanel:GetChildChecked("Container", true):PushBack(_wtSeparator)
	_wtSeparator:Show(true)
	_wtSeparator:GetChildChecked("SeparatorText", true):SetVal("val", "Отображение")
			
	
	local budges = {"Вещи", "Ремёсла", "Редкости"}
	
	for _, v in pairs(budges) do
		local _wtItem = mainForm:CreateWidgetByDesc(mainForm:GetChildChecked("Item", true):GetWidgetDesc())
		_wtItem:GetChildChecked("Button", true):DestroyWidget()
		_wtItem:SetBackgroundColor({a = 0.0, r = 0, g = 0, b = 0})
		_wtItem:Show(true)	
		
		pl = _wtItem:GetPlacementPlain()
		pl.sizeY = pl.sizeY - 15
		_wtItem:SetPlacementPlain(pl)
		
		local _wtCheckbox = mainForm:CreateWidgetByDesc(wtCheckbox:GetWidgetDesc())
		wtCategories[v] = _wtCheckbox
		pl = _wtCheckbox:GetPlacementPlain()
		pl.posX = 17
		pl.posY = 5
		_wtCheckbox:SetPlacementPlain(pl)
		_wtCheckbox:Show(true)
		_wtCheckbox:SetName(v)
		_wtItem:AddChild(_wtCheckbox)
		
		local wtText = mainForm:CreateWidgetByDesc(mainForm:GetChildChecked("Text2", true):GetWidgetDesc())		
		wtText:SetVal("val", userMods.ToWString(v))
		
		wtText:SetFormat("<header  alignx = \"left\" fontsize=\"14\"><rs class=\"class\"><html outline=\"1\" shadow=\"1\" outlinecolor=\"0x000000\"><b>Вывод предметов из кармана \"<r name=\"val\"/>\"</b></html></rs></header>")
		pl = wtText:GetPlacementPlain()
		pl.posX = 46+5
		pl.posY = 5
		wtText:SetPlacementPlain(pl)
		wtText:Show(true)		
		_wtItem:AddChild(wtText)
		
		wtSettingsPanel:GetChildChecked("Container", true):PushBack(_wtItem)
	end
	
	-- УВЕДОМЛЕНИЕ
	_wtSeparator = mainForm:CreateWidgetByDesc(wtSeparator:GetWidgetDesc())
	_wtSeparator:SetName("Уведомление")
	wtSettingsPanel:GetChildChecked("Container", true):PushBack(_wtSeparator)
	_wtSeparator:Show(true)
	_wtSeparator:GetChildChecked("SeparatorText", true):SetVal("val", "Уведомление")
	
	local _wtItem = mainForm:CreateWidgetByDesc(mainForm:GetChildChecked("Item", true):GetWidgetDesc())
	_wtItem:SetBackgroundColor({a = 0.0, r = 0, g = 0, b = 0})
	_wtItem:Show(true)	
	_wtItem:GetChildChecked("Button", true):DestroyWidget()

	pl = _wtItem:GetPlacementPlain()
	pl.sizeY = pl.sizeY-5
	_wtItem:SetPlacementPlain(pl)

	local wtText = mainForm:CreateWidgetByDesc(mainForm:GetChildChecked("Text2", true):GetWidgetDesc())		
	wtText:SetFormat("<header  alignx = \"left\" fontsize=\"14\"><rs class=\"class\"><html outline=\"1\" shadow=\"1\" outlinecolor=\"0x000000\"><b> Сообщать о предметах, которым осталось менее (дн.):</b></html></rs></header>")
	wtText:SetMultiline( true )
	wtText:SetWrapText( true )
	pl = wtText:GetPlacementPlain()
	pl.posX = 17
	pl.posY = 4
	pl.sizeX = 250
	pl.sizeY = 50
	wtText:SetPlacementPlain(pl)
	wtText:Show(true)		
	_wtItem:AddChild(wtText)

	wtDays = mainForm:CreateWidgetByDesc(mainForm:GetChildChecked("Text2", true):GetWidgetDesc())		
	wtDays:SetFormat("<header  alignx = \"center\" fontsize=\"20\"><rs class=\"class\"><html outline=\"1\" shadow=\"1\" outlinecolor=\"0x000000\"><b><r name=\"val\"/></b></html></rs></header>")
	wtDays:SetVal("val", tostring(gDaysVariants[gDays]))
	pl = wtDays:GetPlacementPlain()
	pl.posX = 160
	pl.posY = 6
	wtDays:SetPlacementPlain(pl)
	wtDays:Show(true)		
	_wtItem:AddChild(wtDays)
	
	local _wtUp = mainForm:CreateWidgetByDesc(wtUp:GetWidgetDesc())
	_wtUp:SetName("DayUp")
	pl = _wtUp:GetPlacementPlain()
	pl.posX = 355
	pl.posY = 8
	pl.alignX = 0
	pl.alignY = 0
	_wtUp:SetPlacementPlain(pl)
	_wtUp:Show(true)
	_wtItem:AddChild(_wtUp)

	wtSettingsPanel:GetChildChecked("Container", true):PushBack(_wtItem)
	--|||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||
	-- СУМКА
	_wtSeparator = mainForm:CreateWidgetByDesc(wtSeparator:GetWidgetDesc())
	_wtSeparator:SetName("Сумка")
	wtSettingsPanel:GetChildChecked("Container", true):PushBack(_wtSeparator)
	_wtSeparator:Show(true)
	_wtSeparator:GetChildChecked("SeparatorText", true):SetVal("val", "Сумка")
	
	local _wtItem = mainForm:CreateWidgetByDesc(mainForm:GetChildChecked("Item", true):GetWidgetDesc())
	_wtItem:SetBackgroundColor({a = 0.0, r = 0, g = 0, b = 0})
	_wtItem:Show(true)	
	_wtItem:GetChildChecked("Button", true):DestroyWidget()

	pl = _wtItem:GetPlacementPlain()
	pl.sizeY = pl.sizeY + 15
	_wtItem:SetPlacementPlain(pl)

	local wtText = mainForm:CreateWidgetByDesc(mainForm:GetChildChecked("Text2", true):GetWidgetDesc())		
	wtText:SetFormat("<header  alignx = \"left\" fontsize=\"14\"><rs class=\"class\"><html outline=\"1\" shadow=\"1\" outlinecolor=\"0x000000\"><b> Показывать срок жизни в сумке у предметов, которым осталось менее (дн.):</b></html></rs></header>")
	wtText:SetMultiline( true )
	wtText:SetWrapText( true )
	pl = wtText:GetPlacementPlain()
	pl.posX = 17
	pl.posY = 4
	pl.sizeX = 250
	pl.sizeY = 100
	wtText:SetPlacementPlain(pl)
	wtText:Show(true)		
	_wtItem:AddChild(wtText)

	wtDaysBag = mainForm:CreateWidgetByDesc(mainForm:GetChildChecked("Text2", true):GetWidgetDesc())		
	wtDaysBag:SetFormat("<header  alignx = \"center\" fontsize=\"20\"><rs class=\"class\"><html outline=\"1\" shadow=\"1\" outlinecolor=\"0x000000\"><b><r name=\"val\"/></b></html></rs></header>")
	wtDaysBag:SetVal("val", tostring(gDaysVariants[gDaysBag]))
	pl = wtDaysBag:GetPlacementPlain()
	pl.posX = 160
	pl.posY = 6 + 5
	wtDaysBag:SetPlacementPlain(pl)
	wtDaysBag:Show(true)		
	_wtItem:AddChild(wtDaysBag)
	
	local _wtUp = mainForm:CreateWidgetByDesc(wtUp:GetWidgetDesc())
	_wtUp:SetName("DayBagUp")
	pl = _wtUp:GetPlacementPlain()
	pl.posX = 355
	pl.posY = 8 + 5
	pl.alignX = 0
	pl.alignY = 0
	_wtUp:SetPlacementPlain(pl)
	_wtUp:Show(true)
	_wtItem:AddChild(_wtUp)

	wtSettingsPanel:GetChildChecked("Container", true):PushBack(_wtItem)
	
end

function OnUpPress(params)
	if params.sender == "DayUp" then
		gDays = gDays == table.maxn(gDaysVariants) and 1 or gDays + 1
		wtDays:SetVal("val", tostring(gDaysVariants[gDays]))
	elseif params.sender == "DayBagUp" then
		gDaysBag = gDaysBag == table.maxn(gDaysVariants) and 1 or gDaysBag + 1
		wtDaysBag:SetVal("val", tostring(gDaysVariants[gDaysBag]))
	end
	SaveConfig()
end

function OnSettingsPress(params)
	wtSettingsPanel:Show(not wtSettingsPanel:IsVisible())
	if wtSettingsPanel:IsVisible() then
		local posConverter = widgetsSystem:GetPosConverterParams()
		local pl1, pl2 = wtMainPanel:GetPlacementPlain(), wtSettingsPanel:GetPlacementPlain()
		pl2.posX = (pl1.posX - pl1.sizeX <= 0) and pl1.posX + pl1.sizeX or pl1.posX - pl1.sizeX
		pl2.posY = pl1.posY
		wtSettingsPanel:SetPlacementPlain(pl2)
	end		
end

function OnCheckboxPress(params)
	params.widget:SetVariant(1 - params.widget:GetVariant())
	SaveConfig()
end

function OnSeparatorPointing(params)
	if params.active == false then
		wtInfoPanel:Show(false)
		return
	end
	--Chat(params.sender)
	if params.sender == "Отображение" then
		wtInfoText:SetFormat("<tip_white>Выберите карманы, из которых следует добавлять предметы в окно аддона.<br/>Предметы из неотмеченных карманов не будут отображены, уведомления по этим предметам не будут выведены в игровой чат.</tip_white>")
		wtInfoPanel:Show(true)
	elseif params.sender == "Уведомление" then
		wtInfoText:SetFormat("<tip_white>При запуске аддона, в игровой чат будет выведена информация о предметах, чей срок жизни меньше заданного игроком лимита.<br/></tip_white>")
		wtInfoPanel:Show(true)
	elseif params.sender == "Сумка" then
		wtInfoText:SetFormat("<tip_white>В сумке будет отображаться срок жизни на иконке предмета.<br/>Работает во всех карманах сумки, независимо от настроек выше.</tip_white>")
		wtInfoPanel:Show(true)
	end
	local pl = wtInfoPanel:GetPlacementPlain()
	local plInfoPanel = params.widget:GetParent():GetParent():GetParent():GetParent():GetPlacementPlain()
	pl.posX = plInfoPanel.posX + plInfoPanel.sizeX
	pl.posY = plInfoPanel.posY
	wtInfoPanel:SetPlacementPlain(pl)
end

function LoadConfig()
	local loadConfig = userMods.GetGlobalConfigSection( "Settings" )
	if loadConfig ~= nil then
		gThings = loadConfig.gThings or 1
		gCrafts = loadConfig.gCrafts or 1
		gRarities = loadConfig.gRarities or 1
		
		gDays = loadConfig.gDays or 1
		gDaysBag = loadConfig.gDaysBag or 3
		gShow = loadConfig.gShow or false
	end
	
	wtCategories[gCategories[1]]:SetVariant(gThings)
	wtCategories[gCategories[2]]:SetVariant(gCrafts)
	wtCategories[gCategories[3]]:SetVariant(gRarities)
	
	wtHide:Show(not gShow)
	
	wtButtonTurn:SetForegroundColor({r = 1, g = 1, b = 1, a = gShow and 1 or 0})
	
	wtDays:SetVal("val", tostring(gDaysVariants[gDays]))
	wtDaysBag:SetVal("val", tostring(gDaysVariants[gDaysBag]))
	SaveConfig()
end

function SaveConfig()
	local saveConfig = {}
	
	saveConfig.gThings = wtCategories[gCategories[1]]:GetVariant()
	saveConfig.gCrafts = wtCategories[gCategories[2]]:GetVariant()
	saveConfig.gRarities = wtCategories[gCategories[3]]:GetVariant()
	
	gThings = wtCategories[gCategories[1]]:GetVariant()
	gCrafts = wtCategories[gCategories[2]]:GetVariant()
	gRarities = wtCategories[gCategories[3]]:GetVariant()
		
	saveConfig.gDays = gDays
	saveConfig.gDaysBag = gDaysBag
	saveConfig.gShow = gShow
	userMods.SetGlobalConfigSection( "Settings", saveConfig )
end

function OnRefreshPress(params)
	DestroyItems()
	aa()
end

function Notification()
	local itemIds = avatar.GetInventoryItemIds()
	local notif = {}
	for _, v in pairs(itemIds) do
		if CheckItem(v) and math.floor(itemLib.GetTemporaryInfo( v ).remainingMs/ 60/ 60/ 24/ 1000) <= gDaysVariants[gDays] then
			table.insert(notif, {a = v})
		end
	end
	if table.maxn(notif) > 0 then
		table.sort(notif, function(a,b) return itemLib.GetTemporaryInfo(a.a).remainingMs < itemLib.GetTemporaryInfo(b.a).remainingMs end )
		Chat("Обратите внимание на срок жизни предметов в сумке:", "LogColorWhite", 18)
		for _, v in pairs(notif) do
			ChatItem(v.a, 16)
		end
	end
end

function OnBagShow(params)
	if params.widget:IsVisible() then
		if gShow then
			ShowPanel(true)
		end		
		if gDaysVariants[gDaysBag] == 0 then
			return
		end
		gPocket = -1
		RefreshItemTime()
		StartTimer(gTimer)
	else
		StopTimer(gTimer)
		ClearItemTime()
		if gShow then
			ShowPanel(false)
		end
	end
end

function OnTurnPress(params)
	if not gShow then
		wtMainPanel:Show(wtBag:IsVisible())
	end	
	gShow = not gShow
	wtHide:Show(not gShow)
	wtButtonTurn:SetForegroundColor({r = 1, g = 1, b = 1, a = gShow and 1 or 0})
	SaveConfig()
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------
function Init()
	wtItem = mainForm:GetChildChecked("Item", true)
	wtSeparator = mainForm:GetChildChecked("Separator", true)
	wtContainer = mainForm:GetChildChecked("Container", true)
	
	wtItem:Show(false)
	
	wtMainPanel = mainForm:GetChildChecked("panel", true)
	-- local mt = getmetatable( wtMainPanel )
	-- if not mt._Show then
		-- mt._Show = mt.Show
		-- mt.Show = function ( self, show )
			-- self:_Show( show ); if self == wtMainPanel then Chat(self:GetName()) end
		-- end
	-- end
	wtMainPanel:SetClipContent(false)

	-- Добавляем DragAndDrop главной панели
	DnD.Init( wtMainPanel, nil, true)
	DnD.Init( wtHide, nil, true)
	
	--DnD.Resizer( mainForm:GetChildChecked("ResizeCorner", true), nil, true)
	--mainForm:GetChildChecked("ResizeCorner", true):SetBackgroundColor( { r = 1.0; g = 1.0; b = 1.0; a = 0.0 } )
	--mainForm:GetChildChecked("ResizeCorner", true):Show(true)

	-- Подписываем обработчик аддона на реакции нажатия на главную кнопку аддона, а также кнопки предметов
	common.RegisterReactionHandler( ShowHideBtnReaction, "ShowHideBtnReaction" )
	common.RegisterReactionHandler( ShowHideBtnReaction, "close_pressed" )
	common.RegisterReactionHandler( OnPressButtonDown, "slot_pressed" )
	common.RegisterReactionHandler( OnPointingButton, "slot_pointing" )
	common.RegisterReactionHandler( OnSettingsPress, "settings_pressed" )
	common.RegisterReactionHandler( OnCheckboxPress, "checkbox_pressed" )
	common.RegisterReactionHandler( OnRefreshPress, "refresh_pressed" )
	common.RegisterReactionHandler( OnUpPress, "up_pressed" )
	common.RegisterReactionHandler( OnSeparatorPointing, "separator_pointing" )
	common.RegisterReactionHandler( OnTurnPress, "turn_pressed" )
	
	common.RegisterEventHandler( OnFormEffect, "EVENT_EFFECT_FINISHED", { wtOwner = mainForm, effectType = ET_FADE } )
	
	--common.RegisterReactionHandler( OnPressButtonDown, "slot_pressed" )
	--common.GetAddonMainForm( "ContextBag" ):GetChildChecked("Bag", true)
	
	-- Подписываем обработчик аддона на события изменения в багаже игрока
	common.RegisterEventHandler( OnInventoryChanged, "EVENT_INVENTORY_CHANGED" )
	common.RegisterEventHandler( OnInventoryChanged, "EVENT_INVENTORY_SLOT_CHANGED" )
	
	local pl
	
	-- Добавляем название аддона на главную панель
	wtAddonName = mainForm:CreateWidgetByDesc(mainForm:GetChildChecked("Text2", true):GetWidgetDesc())
	pl = wtAddonName:GetPlacementPlain()
	wtAddonName:	SetVal("val", common.GetAddonName())
	pl.alignX = 3
	pl.alignY = 0
	pl.posY = 10
	wtAddonName:	SetFormat("<header alignx = \"center\" fontsize=\"18\"><rs class=\"class\"><r name=\"val\"/></rs></header>")
	wtAddonName:SetPlacementPlain(pl)
	wtAddonName:Show(true)
	
	wtBag:SetOnShowNotification(true)
	
	common.RegisterEventHandler( OnBagShow, "EVENT_WIDGET_SHOW_CHANGED", {widget = wtBag})
	
	wtMainPanel:AddChild(wtAddonName)
	
	ResetTextItem()
	
	CreateSettings()
	
	LoadConfig()
	
	mainForm:PlayFadeEffect( 1, 1, 500, EA_SYMMETRIC_FLASH )
	
	gTimer = InitTimer(RefreshItemTime, 250)
end

--------------------------------------------------------------------------------
if avatar.IsExist() then
	Init()
else
	common.RegisterEventHandler( Init, "EVENT_AVATAR_CREATED" )	
end
--------------------------------------------------------------------------------
