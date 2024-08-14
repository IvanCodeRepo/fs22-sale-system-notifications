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
SaleSystemNotifications.lastNotifiedId = 0


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
end

function SaleSystemNotifications.init()
    if g_currentMission.vehicleSaleSystem.items ~= nil then
        for _,Item in pairs(g_currentMission.vehicleSaleSystem.items) do
            SaleSystemNotifications.addNotification(Item)
        end
    end
end

function SaleSystemNotifications.addNotification(Item)
    if Item.isGenerated and SaleSystemNotifications.lastNotifiedId < Item.id then
        local offerPrice = Item.price
        local storeItem = g_storeManager:getItemByXMLFilename(Item.xmlFilename)
        local itemName = storeItem.name
        local brandName = storeItem.brandNameRaw
        local categoryTitle = g_storeManager:getCategoryByName(storeItem.categoryName).title
        local originalPrice = storeItem.price
        local discount = math.floor((1 - (offerPrice/originalPrice)) * 100)

        local originalPriceFormatted = g_i18n:formatMoney(originalPrice, 0, true, true)
        local offerPriceFormatted = g_i18n:formatMoney(offerPrice, 0, true, true)

        local message = string.format(
            "%s %s (%s): %s -> %s (- %d%%)",
            brandName, itemName, categoryTitle, originalPriceFormatted, offerPriceFormatted, discount
        )

        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, message)

        SaleSystemNotifications.lastNotifiedId = Item.id
    end
end

function SaleSystemNotifications.OnAddItem()
    if g_currentMission.vehicleSaleSystem.items ~= nil then
        for _,Item in pairs(g_currentMission.vehicleSaleSystem.items) do
            SaleSystemNotifications.addNotification(Item)
        end
    end
end

function SaleSystemNotifications.AppendFunctions()
    FSBaseMission.onFinishedLoading = Utils.appendedFunction(FSBaseMission.onFinishedLoading, SaleSystemNotifications.init)
    VehicleSaleSystem.addSale = Utils.appendedFunction(VehicleSaleSystem.addSale, SaleSystemNotifications.OnAddItem)
end

addModEventListener(SaleSystemNotifications)