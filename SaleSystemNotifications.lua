-- Name: SaleSystemNotifications
-- Author: IvanCodeRepo
-- GitHub: https://github.com/ivancoderepo
-- Version: 1.0.0.0
-- Date: Aug. 2024

--[[
Known Bugs:
]]--

SaleSystemNotifications = {}
SaleSystemNotifications.dir = g_currentModDirectory
SaleSystemNotifications.Settings = {}
SaleSystemNotifications.oldOffers = {}


function SaleSystemNotifications:loadMap(name)
    SaleSystemNotifications.readXml()

    if SaleSystemNotifications.Settings.NotifyNewSales ~= nil and SaleSystemNotifications.Settings.NotifyNewSales then
        SaleSystemNotifications.AppendFunctions()
    end
end

function SaleSystemNotifications.readXml()
    local xmlFilename = "settings.xml"
    local path = SaleSystemNotifications.dir .. "settings.xml"
    local object = "SaleSystemNotifications"
    local key = "SaleSystemNotifications.Settings"

    local xmlFileId = loadXMLFile(object, path)

    SaleSystemNotifications.Settings.NotifyNewSales = getXMLBool(xmlFileId, key.."#NotifyNewSales")
    SaleSystemNotifications.Settings.PlaySound = getXMLBool(xmlFileId, key.."#PlaySound")
    SaleSystemNotifications.Settings.SoundVolume = getXMLFloat(xmlFileId, key.."#SoundVolume")

    local sound = createSample("NewSaleSound")
    loadSample(sound, "data/sounds/ui/uiCollectable.wav", false)
	SaleSystemNotifications.Settings.sound = sound
end

function SaleSystemNotifications.init()
    if g_currentMission.vehicleSaleSystem.items ~= nil then
        local currentOffers = {}
        for _,Item in pairs(g_currentMission.vehicleSaleSystem.items) do
            SaleSystemNotifications.addNotification(Item)
            local message = SaleSystemNotifications.itemToMessage(Item)
            table.insert(currentOffers, message)
        end
        SaleSystemNotifications.oldOffers = currentOffers
    end
end

function SaleSystemNotifications.itemToMessage(Item)
    local offerPrice = Item.price
    local storeItem = g_storeManager:getItemByXMLFilename(Item.xmlFilename)
    local itemName = storeItem.name
    local brandName = storeItem.brandNameRaw
    local categoryTitle = g_storeManager:getCategoryByName(storeItem.categoryName).title
    local originalPrice = storeItem.price
    local discount = math.floor((1 - (offerPrice/originalPrice)) * 100)

    local originalPriceFormatted = g_i18n:formatMoney(originalPrice, 0, true, true)
    local offerPriceFormatted = g_i18n:formatMoney(offerPrice, 0, true, true)
    return string.format(
        "%s %s (%s): %s -> %s (- %d%%)",
        brandName, itemName, categoryTitle, originalPriceFormatted, offerPriceFormatted, discount
    )
end

function SaleSystemNotifications.addNotification(Item)
    if Item.isGenerated then
        local message = SaleSystemNotifications.itemToMessage(Item)

        local function has_value(tab, val)
            for index, value in ipairs(tab) do
                if value == val then
                    return true
                end
            end
            return false
        end

        local alreadyNotified = has_value(SaleSystemNotifications.oldOffers, message)

        if alreadyNotified ~= true then
            g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, message)
            if SaleSystemNotifications.Settings.PlaySound then
                playSample(SaleSystemNotifications.Settings.sound, 1, (SaleSystemNotifications.Settings.SoundVolume/100), 1, 0, 0)
            end
        end
    end
end

function SaleSystemNotifications.OnAddItem()
    if g_currentMission.vehicleSaleSystem.items ~= nil then
        local currentOffers = {}
        for _,Item in pairs(g_currentMission.vehicleSaleSystem.items) do
            SaleSystemNotifications.addNotification(Item)
            local message = SaleSystemNotifications.itemToMessage(Item)
            table.insert(currentOffers, message)
        end
        SaleSystemNotifications.oldOffers = currentOffers
    end
end

function SaleSystemNotifications.AppendFunctions()
    FSBaseMission.onFinishedLoading = Utils.appendedFunction(FSBaseMission.onFinishedLoading, SaleSystemNotifications.init)
    VehicleSaleSystem.addSale = Utils.appendedFunction(VehicleSaleSystem.addSale, SaleSystemNotifications.OnAddItem)
end

addModEventListener(SaleSystemNotifications)