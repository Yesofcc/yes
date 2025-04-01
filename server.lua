local QBCore = exports['qb-core']:GetCoreObject()

-- Funkcia na z�skanie bank_balance priamo z datab�zy
local function GetUserBankBalance(source, callback)
    local player = source
    local license = QBCore.Functions.GetIdentifier(player, 'license')
    
    -- Najprv sk�s z�ska� �daje z QBCore
    local qbPlayer = QBCore.Functions.GetPlayer(player)
    if qbPlayer then
        print("DEBUG: Using QBCore player data for bank balance")
        callback(qbPlayer.PlayerData.money.bank)
        return
    end
    
    -- Ak QBCore nefunguje, z�skame �daje z datab�zy
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

-- Funkcia na z�skanie inform�ci� o peniazoch hr��a (cash aj bank)
local function GetPlayerMoney(source, callback)
    local player = source
    
    -- Sk�s z�ska� �daje z QBCore
    local qbPlayer = QBCore.Functions.GetPlayer(player)
    if qbPlayer then
        print("DEBUG: Using QBCore player data for money info")
        callback({
            cash = qbPlayer.PlayerData.money.cash,
            bank = qbPlayer.PlayerData.money.bank
        })
        return
    end
    
    -- Ak QBCore nefunguje, z�skame �daje z datab�zy
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

-- Aktualiz�cia zostatku v datab�ze
local function UpdateMoneyInDatabase(username, cashAmount, bankAmount)
    exports.oxmysql:execute("UPDATE users SET cash_balance = ?, bank_balance = ? WHERE username = ?", {cashAmount, bankAmount, username})
end

-- Vklad pe�az�
RegisterNetEvent('qb-banka:deposit', function(amount)
    local src = source
    
    -- Kontrola �i je amount platn� ��slo
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('QBCore:Notify', src, "Neplatn� suma na vklad.", "error")
        return
    end
    
    -- Z�skaj hr��a
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        print("DEBUG: Player not found in QBCore for deposit. Falling back to database.")
        -- Ak nem��eme z�ska� hr��a z QBCore, pou�ijeme priamy pr�stup do datab�zy
        local username = GetPlayerName(src)
        
        -- Zisti aktu�lne zostatky
        GetPlayerMoney(src, function(moneyInfo)
            local currentCash = moneyInfo.cash
            local currentBank = moneyInfo.bank
            
            -- Kontrola �i m� hr�� dostatok hotovosti
            if currentCash < amount then
                TriggerClientEvent('QBCore:Notify', src, "Nem� dostatok hotovosti na vklad.", "error")
                return
            end
            
            -- Aktualizuj zostatky v datab�ze
            local newCash = currentCash - amount
            local newBank = currentBank + amount
            UpdateMoneyInDatabase(username, newCash, newBank)
            
            -- Odo�li nov� zostatky klientovi
            TriggerClientEvent('qb-banka:receiveMoneyInfo', src, newCash, newBank)
            TriggerClientEvent('QBCore:Notify', src, ("Vlo�il si %d$ do banky."):format(amount), "success")
        end)
        return
    end
    
    -- Kontrola �i m� hr�� dostatok hotovosti
    if Player.PlayerData.money.cash < amount then
        TriggerClientEvent('QBCore:Notify', src, "Nem� dostatok hotovosti na vklad.", "error")
        return
    end
    
    -- Vykonaj transakciu
    Player.Functions.RemoveMoney('cash', amount, 'Bank deposit')
    Player.Functions.AddMoney('bank', amount, 'Bank deposit')
    
    -- Notifik�cia
    TriggerClientEvent('QBCore:Notify', src, ("Vlo�il si %d$ do banky."):format(amount), "success")
    
    -- Aktualizuj �daje o peniazoch
    TriggerClientEvent('qb-banka:receiveMoneyInfo', src, Player.PlayerData.money.cash, Player.PlayerData.money.bank)
end)

-- V�ber pe�az�
RegisterNetEvent('qb-banka:withdraw', function(amount)
    local src = source
    
    -- Kontrola �i je amount platn� ��slo
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('QBCore:Notify', src, "Neplatn� suma na v�ber.", "error")
        return
    end
    
    -- Z�skaj hr��a
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        print("DEBUG: Player not found in QBCore for withdraw. Falling back to database.")
        -- Ak nem��eme z�ska� hr��a z QBCore, pou�ijeme priamy pr�stup do datab�zy
        local username = GetPlayerName(src)
        
        -- Zisti aktu�lne zostatky
        GetPlayerMoney(src, function(moneyInfo)
            local currentCash = moneyInfo.cash
            local currentBank = moneyInfo.bank
            
            -- Kontrola �i m� hr�� dostatok pe�az� v banke
            if currentBank < amount then
                TriggerClientEvent('QBCore:Notify', src, "Nem� dostatok pe�az� na ��te na v�ber.", "error")
                return
            end
            
            -- Aktualizuj zostatky v datab�ze
            local newCash = currentCash + amount
            local newBank = currentBank - amount
            UpdateMoneyInDatabase(username, newCash, newBank)
            
            -- Odo�li nov� zostatky klientovi
            TriggerClientEvent('qb-banka:receiveMoneyInfo', src, newCash, newBank)
            TriggerClientEvent('QBCore:Notify', src, ("Vybral si %d$ z banky."):format(amount), "success")
        end)
        return
    end
    
    -- Kontrola �i m� hr�� dostatok pe�az� v banke
    if Player.PlayerData.money.bank < amount then
        TriggerClientEvent('QBCore:Notify', src, "Nem� dostatok pe�az� na ��te na v�ber.", "error")
        return
    end
    
    -- Vykonaj transakciu
    Player.Functions.RemoveMoney('bank', amount, 'Bank withdraw')
    Player.Functions.AddMoney('cash', amount, 'Bank withdraw')
    
    -- Notifik�cia
    TriggerClientEvent('QBCore:Notify', src, ("Vybral si %d$ z banky."):format(amount), "success")
    
    -- Aktualizuj �daje o peniazoch
    TriggerClientEvent('qb-banka:receiveMoneyInfo', src, Player.PlayerData.money.cash, Player.PlayerData.money.bank)
end)

-- Prevod pe�az�
RegisterNetEvent('qb-banka:transfer', function(targetId, amount)
    local src = source
    local target = tonumber(targetId)
    
    -- Kontrola �i je amount platn� ��slo
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('QBCore:Notify', src, "Neplatn� suma na prevod.", "error")
        return
    end
    
    -- Kontrola �i cie�ov� hr�� existuje
    if not target then
        TriggerClientEvent('QBCore:Notify', src, "Neplatn� ID hr��a.", "error")
        return
    end
    
    -- Z�skaj hr��a a cie�
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(target)
    
    if not Player then
        TriggerClientEvent('QBCore:Notify', src, "Nepodarilo sa z�ska� �daje o hr��ovi.", "error")
        return
    end
    
    if not Target then
        TriggerClientEvent('QBCore:Notify', src, "Cie�ov� hr�� nie je online.", "error")
        return
    end
    
    -- Kontrola �i m� hr�� dostatok pe�az� v banke
    if Player.PlayerData.money.bank < amount then
        TriggerClientEvent('QBCore:Notify', src, "Nem� dostatok pe�az� na ��te na prevod.", "error")
        return
    end
    
    -- Vykonaj transakciu
    Player.Functions.RemoveMoney('bank', amount, 'Bank transfer to ' .. targetId)
    Target.Functions.AddMoney('bank', amount, 'Bank transfer from ' .. src)
    
    -- Notifik�cie
    TriggerClientEvent('QBCore:Notify', src, ("Poslal si %d$ hr��ovi [%s]."):format(amount, targetId), "success")
    TriggerClientEvent('QBCore:Notify', target, ("Obdr�al si %d$ od hr��a [%s]."):format(amount, src), "success")
    
    -- Aktualizuj �daje o peniazoch pre odosielate�a
    TriggerClientEvent('qb-banka:receiveMoneyInfo', src, Player.PlayerData.money.cash, Player.PlayerData.money.bank)
    
    -- Aktualizuj �daje o peniazoch pre pr�jemcu
    TriggerClientEvent('qb-banka:receiveMoneyInfo', target, Target.PlayerData.money.cash, Target.PlayerData.money.bank)
end)

-- Z�skanie zostatku
RegisterNetEvent('qb-banka:getBalance', function()
    local src = source
    
    GetUserBankBalance(src, function(balance)
        TriggerClientEvent('qb-banka:receiveBalance', src, balance)
    end)
end)

-- Z�skanie kompletn�ch inform�ci� o peniazoch (cash + bank)
RegisterNetEvent('qb-banka:getMoneyInfo', function()
    local src = source
    
    -- Najprv sk�sime z�ska� hr��a priamo z QBCore
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        print("DEBUG: Player found in qb-banka:getMoneyInfo")
        TriggerClientEvent('qb-banka:receiveMoneyInfo', src, Player.PlayerData.money.cash, Player.PlayerData.money.bank)
        return
    end
    
    -- Ak hr�� nie je dostupn�, pou�ijeme z�lo�n� funkciu
    print("DEBUG: Using fallback method in qb-banka:getMoneyInfo")
    GetPlayerMoney(src, function(moneyInfo)
        TriggerClientEvent('qb-banka:receiveMoneyInfo', src, moneyInfo.cash, moneyInfo.bank)
    end)
end)

-- Volanie na z�skanie zostatku pri otvoren� banky
RegisterNetEvent('qb-banka:requestBalanceUpdate', function()
    local src = source
    
    -- Najprv sk�sime z�ska� hr��a priamo z QBCore
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        print("DEBUG: Player found in requestBalanceUpdate")
        TriggerClientEvent('qb-banka:receiveMoneyInfo', src, Player.PlayerData.money.cash, Player.PlayerData.money.bank)
        return
    end
    
    -- Ak hr�� nie je dostupn�, pou�ijeme z�lo�n� funkciu
    print("DEBUG: Using fallback method in requestBalanceUpdate")
    GetPlayerMoney(src, function(moneyInfo)
        TriggerClientEvent('qb-banka:receiveMoneyInfo', src, moneyInfo.cash, moneyInfo.bank)
    end)
end)