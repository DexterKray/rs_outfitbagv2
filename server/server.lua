local ESX, QBCore, framework

function ServerDebugPrint(text)
    if Config.Debug then print("[RS Outfit Bag | DEBUG] "..text) end
end

CreateThread(function()
    while Config.Framework == 'auto' do
        Wait(100)

        if GetResourceState("es_extended") == "started" then
            Config.Framework = "esx"
        elseif GetResourceState("qb-core") == "started" then
            Config.Framework = "qb"
        end
    end
    

    if Config.Framework == "esx" then
        local src = source
        while ESX == nil do
            ESX = exports["es_extended"]:getSharedObject()
            Wait(100)
        end
        framework = 'esx'
        ServerDebugPrint("[Outfit Bag] ESX loaded")

        ESX.RegisterServerCallback("rs_outfitbag:getOutfits", function(src, cb)
            local player = ESX.GetPlayerFromId(src)
            if not player then cb({}) return end

            local identifier = player.getIdentifier()
            exports.oxmysql:execute('SELECT id, name FROM user_outfits WHERE identifier = ?', {identifier}, function(results)
                cb(results)
            end)
        end)

        ESX.RegisterServerCallback("rs_outfitbag:getOutfitCount", function(src, cb)
            local player = ESX.GetPlayerFromId(src)
            if not player then cb(0) return end

            local identifier = player.getIdentifier()
            exports.oxmysql:scalar("SELECT COUNT(*) FROM user_outfits WHERE identifier = ?", {identifier}, function(count)
                cb(count or 0)
            end)
        end)

        ESX.RegisterUsableItem('outfit_bag', function(source)
            if source then
                TriggerClientEvent('rs_outfitbag:place', source)
            else
                print("[Outfit Bag] Error: source is nil when using outfit_bag.")
            end
        end)
        
    elseif Config.Framework == "qb" then
        while QBCore == nil do
            QBCore = exports['qb-core']:GetCoreObject()
            Wait(100)
        end
        framework = 'qb'
        ServerDebugPrint("[Outfit Bag] QBCore loaded")

        QBCore.Functions.CreateCallback("rs_outfitbag:getOutfits", function(src, cb)
            local player = QBCore.Functions.GetPlayer(src)
            if not player then cb({}) return end

            local identifier = player.PlayerData.citizenid
            exports.oxmysql:execute('SELECT id, name FROM user_outfits WHERE identifier = ?', {identifier}, function(results)
                cb(results)
            end)
        end)

        QBCore.Functions.CreateCallback("rs_outfitbag:getOutfitCount", function(src, cb)
            local player = QBCore.Functions.GetPlayer(src)
            if not player then cb(0) return end

            local identifier = player.PlayerData.citizenid
            exports.oxmysql:scalar("SELECT COUNT(*) FROM user_outfits WHERE identifier = ?", {identifier}, function(count)
                cb(count or 0)
            end)
        end)

        QBCore.Functions.CreateUseableItem("outfit_bag", function(src, item)
            TriggerClientEvent("rs_outfitbag:place", src)
        end)

    elseif Config.Framework == "custom" then
        framework = 'custom'
        ServerDebugPrint("[Outfit Bag] Custom framework loaded (manual handling required)")
    else
        ServerDebugPrint("[Outfit Bag] Invalid framework configuration: " .. tostring(Config.Framework))
    end
end)

local function GetPlayer(source)
    if Config.Framework == "esx" then
        return ESX.GetPlayerFromId(source)
    elseif Config.Framework == "qb" then
        return QBCore.Functions.GetPlayer(source)
    end
end


local function GetIdentifier(player)
    if Config.Framework == "esx" then
        return player.getIdentifier()
    elseif Config.Framework == "qb" then
        return player.PlayerData.citizenid
    end
end


RegisterServerEvent('rs_outfitbag:placedBag') 
AddEventHandler('rs_outfitbag:placedBag', function()
    if Config.Inventory == 'ox' then
        exports.ox_inventory:RemoveItem(source, Config.Item.item, 1, nil, nil, nil)
    elseif Config.Inventory == 'qs' then
        exports['qs-inventory']:RemoveItem(source, Config.Item.item, 1)
    elseif Config.Inventory == 'codem' then
        exports['codem-inventory']:RemoveItem(source, Config.Item.item, 1)
    elseif Config.Inventory == 'custom' then
        -- Add your custom removal logic
        ServerDebugPrint("^3[WARNING]^0 RemoveItem called, but custom inventory is not defined.")
    else
        ServerDebugPrint("^1[ERROR]^0 Invalid Config.Inventory: " .. tostring(Config.Inventory))
    end
end)

RegisterServerEvent('rs_outfitbag:pickedupBag')
AddEventHandler('rs_outfitbag:pickedupBag', function()
    if Config.Inventory == 'ox' then
        exports.ox_inventory:AddItem(source, Config.Item.item, 1, nil, nil, nil)
    elseif Config.Inventory == 'qs' then
        exports['qs-inventory']:AddItem(source, Config.Item.item, 1)
    elseif Config.Inventory == 'codem' then
        exports['codem-inventory']:AddItem(source, Config.Item.item, 1)
    elseif Config.Inventory == 'custom' then
        -- Add your custom add logic
        ServerDebugPrint("^3[WARNING]^0 AddItem called but custom inventory is not defined.")
    else
        ServerDebugPrint("^1[ERROR]^0 Invalid Config.Inventory: " .. tostring(Config.Inventory))
    end
end)





RegisterNetEvent("rs_outfitbag:saveOutfit", function(label, outfit)
    local src = source
    local player = GetPlayer(src)
    if not player then return end

    local identifier = GetIdentifier(player)
    local outfitJson = json.encode(outfit)

    exports.oxmysql:insert('INSERT INTO user_outfits (identifier, name, skin) VALUES (?, ?, ?)', {
        identifier, label, outfitJson
    }, function()
        ServerDebugPrint("[Outfit Bag] Outfit saved: " .. label)
    end)
end)

RegisterNetEvent("rs_outfitbag:deleteOutfit", function(id)
    exports.oxmysql:execute('DELETE FROM user_outfits WHERE id = ?', {id})
end)

RegisterNetEvent("rs_outfitbag:renameOutfit", function(id, newName)
    exports.oxmysql:execute('UPDATE user_outfits SET name = ? WHERE id = ?', {newName, id})
end)

RegisterNetEvent("rs_outfitbag:wearOutfit", function(id)
    local src = source
    exports.oxmysql:execute('SELECT skin FROM user_outfits WHERE id = ?', {id}, function(result)
        if result[1] then
            local skin = json.decode(result[1].skin)
            TriggerClientEvent("rs_outfitbag:applyOutfit", src, skin)
        end
    end)
end)
