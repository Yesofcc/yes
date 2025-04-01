local QBCore = exports['qb-core']:GetCoreObject()

-- Funkcia na zÌskanie bank_balance priamo z datab·zy
local function GetUserBankBalance(source, callback)
    local player = source
    local license = QBCore.Functions.GetIdentifier(player, 'license')
    
    -- Najprv sk˙s zÌskaù ˙daje z QBCore
    local qbPlayer = QBCore.Functions.GetPlayer(player)
    if qbPlayer then
        print("DEBUG: Using QBCore player data for bank balance")
        callback(qbPlayer.PlayerData.money.bank)
        return
    end
    
    -- Ak QBCore nefunguje, zÌskame ˙daje z datab·zy
    local username = GetPlayerName(player)
    
    print("DEBUG: Getting balance from database for: " .. username)
    
    exports.oxmysql:execute("SELECT bank_balance FROM users WHERE username = ?", {username}, function(result)
        if result and result[1] then
            callback(result[1].bank_balance)
        else
            callback(0)
        end
    end)
end

-- Funkcia na zÌskanie inform·ciÌ o peniazoch hr·Ëa (cash aj bank)
local function GetPlayerMoney(source, callback)
    local player = source
    
    -- Sk˙s zÌskaù ˙daje z QBCore
    local qbPlayer = QBCore.Functions.GetPlayer(player)
    if qbPlayer then
        print("DEBUG: Using QBCore player data for money info")
        callback({
            cash = qbPlayer.PlayerData.money.cash,
            bank = qbPlayer.PlayerData.money.bank
        })
        return
    end
    
    -- Ak QBCore nefunguje, zÌskame ˙daje z datab·zy
    local username = GetPlayerName(player)
    
    print("DEBUG: Getting money info from database for: " .. username)
    
    exports.oxmysql:execute("SELECT bank_balance, cash_balance FROM users WHERE username = ?", {username}, function(result)
        if result and result[1] then
            callback({
                cash = result[1].cash_balance or 0,
                bank = result[1].bank_balance or 0
            })
        else
            callback({
                cash = 0,
                bank = 0
            })
        end
    end)
end

-- Aktualiz·cia zostatku v datab·ze
local function UpdateMoneyInDatabase(username, cashAmount, bankAmount)
    exports.oxmysql:execute("UPDATE users SET cash_balance = ?, bank_balance = ? WHERE username = ?", {cashAmount, bankAmount, username})
end

-- Vklad peÚazÌ
RegisterNetEvent('qb-banka:deposit', function(amount)
    local src = source
    
    -- Kontrola Ëi je amount platnÈ ËÌslo
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('QBCore:Notify', src, "Neplatn· suma na vklad.", "error")
        return
    end
    
    -- ZÌskaj hr·Ëa
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        print("DEBUG: Player not found in QBCore for deposit. Falling back to database.")
        -- Ak nemÙûeme zÌskaù hr·Ëa z QBCore, pouûijeme priamy prÌstup do datab·zy
        local username = GetPlayerName(src)
        
        -- Zisti aktu·lne zostatky
        GetPlayerMoney(src, function(moneyInfo)
            local currentCash = moneyInfo.cash
            local currentBank = moneyInfo.bank
            
            -- Kontrola Ëi m· hr·Ë dostatok hotovosti
            if currentCash < amount then
                TriggerClientEvent('QBCore:Notify', src, "Nem·ö dostatok hotovosti na vklad.", "error")
                return
            end
            
            -- Aktualizuj zostatky v datab·ze
            local newCash = currentCash - amount
            local newBank = currentBank + amount
            UpdateMoneyInDatabase(username, newCash, newBank)
            
            -- Odoöli novÈ zostatky klientovi
            TriggerClientEvent('qb-banka:receiveMoneyInfo', src, newCash, newBank)
            TriggerClientEvent('QBCore:Notify', src, ("Vloûil si %d$ do banky."):format(amount), "success")
        end)
        return
    end
    
    -- Kontrola Ëi m· hr·Ë dostatok hotovosti
    if Player.PlayerData.money.cash < amount then
        TriggerClientEvent('QBCore:Notify', src, "Nem·ö dostatok hotovosti na vklad.", "error")
        return
    end
    
    -- Vykonaj transakciu
    Player.Functions.RemoveMoney('cash', amount, 'Bank deposit')
    Player.Functions.AddMoney('bank', amount, 'Bank deposit')
    
    -- Notifik·cia
    TriggerClientEvent('QBCore:Notify', src, ("Vloûil si %d$ do banky."):format(amount), "success")
    
    -- Aktualizuj ˙daje o peniazoch
    TriggerClientEvent('qb-banka:receiveMoneyInfo', src, Player.PlayerData.money.cash, Player.PlayerData.money.bank)
end)

-- V˝ber peÚazÌ
RegisterNetEvent('qb-banka:withdraw', function(amount)
    local src = source
    
    -- Kontrola Ëi je amount platnÈ ËÌslo
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('QBCore:Notify', src, "Neplatn· suma na v˝ber.", "error")
        return
    end
    
    -- ZÌskaj hr·Ëa
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        print("DEBUG: Player not found in QBCore for withdraw. Falling back to database.")
        -- Ak nemÙûeme zÌskaù hr·Ëa z QBCore, pouûijeme priamy prÌstup do datab·zy
        local username = GetPlayerName(src)
        
        -- Zisti aktu·lne zostatky
        GetPlayerMoney(src, function(moneyInfo)
            local currentCash = moneyInfo.cash
            local currentBank = moneyInfo.bank
            
            -- Kontrola Ëi m· hr·Ë dostatok peÚazÌ v banke
            if currentBank < amount then
                TriggerClientEvent('QBCore:Notify', src, "Nem·ö dostatok peÚazÌ na ˙Ëte na v˝ber.", "error")
                return
            end
            
            -- Aktualizuj zostatky v datab·ze
            local newCash = currentCash + amount
            local newBank = currentBank - amount
            UpdateMoneyInDatabase(username, newCash, newBank)
            
            -- Odoöli novÈ zostatky klientovi
            TriggerClientEvent('qb-banka:receiveMoneyInfo', src, newCash, newBank)
            TriggerClientEvent('QBCore:Notify', src, ("Vybral si %d$ z banky."):format(amount), "success")
        end)
        return
    end
    
    -- Kontrola Ëi m· hr·Ë dostatok peÚazÌ v banke
    if Player.PlayerData.money.bank < amount then
        TriggerClientEvent('QBCore:Notify', src, "Nem·ö dostatok peÚazÌ na ˙Ëte na v˝ber.", "error")
        return
    end
    
    -- Vykonaj transakciu
    Player.Functions.RemoveMoney('bank', amount, 'Bank withdraw')
    Player.Functions.AddMoney('cash', amount, 'Bank withdraw')
    
    -- Notifik·cia
    TriggerClientEvent('QBCore:Notify', src, ("Vybral si %d$ z banky."):format(amount), "success")
    
    -- Aktualizuj ˙daje o peniazoch
    TriggerClientEvent('qb-banka:receiveMoneyInfo', src, Player.PlayerData.money.cash, Player.PlayerData.money.bank)
end)

-- Prevod peÚazÌ
RegisterNetEvent('qb-banka:transfer', function(targetId, amount)
    local src = source
    local target = tonumber(targetId)
    
    -- Kontrola Ëi je amount platnÈ ËÌslo
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('QBCore:Notify', src, "Neplatn· suma na prevod.", "error")
        return
    end
    
    -- Kontrola Ëi cieæov˝ hr·Ë existuje
    if not target then
        TriggerClientEvent('QBCore:Notify', src, "NeplatnÈ ID hr·Ëa.", "error")
        return
    end
    
    -- ZÌskaj hr·Ëa a cieæ
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(target)
    
    if not Player then
        TriggerClientEvent('QBCore:Notify', src, "Nepodarilo sa zÌskaù ˙daje o hr·Ëovi.", "error")
        return
    end
    
    if not Target then
        TriggerClientEvent('QBCore:Notify', src, "Cieæov˝ hr·Ë nie je online.", "error")
        return
    end
    
    -- Kontrola Ëi m· hr·Ë dostatok peÚazÌ v banke
    if Player.PlayerData.money.bank < amount then
        TriggerClientEvent('QBCore:Notify', src, "Nem·ö dostatok peÚazÌ na ˙Ëte na prevod.", "error")
        return
    end
    
    -- Vykonaj transakciu
    Player.Functions.RemoveMoney('bank', amount, 'Bank transfer to ' .. targetId)
    Target.Functions.AddMoney('bank', amount, 'Bank transfer from ' .. src)
    
    -- Notifik·cie
    TriggerClientEvent('QBCore:Notify', src, ("Poslal si %d$ hr·Ëovi [%s]."):format(amount, targetId), "success")
    TriggerClientEvent('QBCore:Notify', target, ("Obdrûal si %d$ od hr·Ëa [%s]."):format(amount, src), "success")
    
    -- Aktualizuj ˙daje o peniazoch pre odosielateæa
    TriggerClientEvent('qb-banka:receiveMoneyInfo', src, Player.PlayerData.money.cash, Player.PlayerData.money.bank)
    
    -- Aktualizuj ˙daje o peniazoch pre prÌjemcu
    TriggerClientEvent('qb-banka:receiveMoneyInfo', target, Target.PlayerData.money.cash, Target.PlayerData.money.bank)
end)

-- ZÌskanie zostatku
RegisterNetEvent('qb-banka:getBalance', function()
    local src = source
    
    GetUserBankBalance(src, function(balance)
        TriggerClientEvent('qb-banka:receiveBalance', src, balance)
    end)
end)

-- ZÌskanie kompletn˝ch inform·ciÌ o peniazoch (cash + bank)
RegisterNetEvent('qb-banka:getMoneyInfo', function()
    local src = source
    
    -- Najprv sk˙sime zÌskaù hr·Ëa priamo z QBCore
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        print("DEBUG: Player found in qb-banka:getMoneyInfo")
        TriggerClientEvent('qb-banka:receiveMoneyInfo', src, Player.PlayerData.money.cash, Player.PlayerData.money.bank)
        return
    end
    
    -- Ak hr·Ë nie je dostupn˝, pouûijeme z·loûn˙ funkciu
    print("DEBUG: Using fallback method in qb-banka:getMoneyInfo")
    GetPlayerMoney(src, function(moneyInfo)
        TriggerClientEvent('qb-banka:receiveMoneyInfo', src, moneyInfo.cash, moneyInfo.bank)
    end)
end)

-- Volanie na zÌskanie zostatku pri otvorenÌ banky
RegisterNetEvent('qb-banka:requestBalanceUpdate', function()
    local src = source
    
    -- Najprv sk˙sime zÌskaù hr·Ëa priamo z QBCore
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        print("DEBUG: Player found in requestBalanceUpdate")
        TriggerClientEvent('qb-banka:receiveMoneyInfo', src, Player.PlayerData.money.cash, Player.PlayerData.money.bank)
        return
    end
    
    -- Ak hr·Ë nie je dostupn˝, pouûijeme z·loûn˙ funkciu
    print("DEBUG: Using fallback method in requestBalanceUpdate")
    GetPlayerMoney(src, function(moneyInfo)
        TriggerClientEvent('qb-banka:receiveMoneyInfo', src, moneyInfo.cash, moneyInfo.bank)
    end)
end)