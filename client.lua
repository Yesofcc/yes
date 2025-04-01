local QBCore = exports['qb-core']:GetCoreObject()
local playerBank = 0
local playerCash = 0

-- Prijatie aktualizácie bankového zostatku zo servera
RegisterNetEvent('qb-banka:receiveBalance', function(balance)
    playerBank = balance
    print("DEBUG BANKY: Received bank balance: " .. playerBank)
end)

-- Prijatie kompletnıch informácií o peniazoch (cash + bank)
RegisterNetEvent('qb-banka:receiveMoneyInfo', function(cash, bank)
    playerCash = cash
    playerBank = bank
    print("DEBUG BANKY: Received money info - Cash: " .. playerCash .. ", Bank: " .. playerBank)
end)

-- Definícia bankovıch lokácií
local bankLocations = {
    {name = "Fleeca Bank (Legion Square)", coords = vector3(149.9, -1040.46, 29.37)},
    {name = "Fleeca Bank (Alta)", coords = vector3(314.23, -278.83, 54.17)},
    {name = "Fleeca Bank (Burton)", coords = vector3(-350.8, -49.57, 49.04)},
    {name = "Fleeca Bank (Rockford Hills)", coords = vector3(-1212.98, -330.88, 37.79)},
    {name = "Fleeca Bank (Grand Senora)", coords = vector3(1175.09, 2706.96, 38.09)},
    {name = "Pacific Standard", coords = vector3(246.64, 223.20, 106.29)},
    {name = "Blaine County Savings", coords = vector3(-112.22, 6469.89, 31.63)}
}

-- Vytvoríme blipy na mape
Citizen.CreateThread(function()
    print("DEBUG BANKY: Zacinam vytvaraf blipy pre banky")
    for _, bank in pairs(bankLocations) do
        local blip = AddBlipForCoord(bank.coords.x, bank.coords.y, bank.coords.z)
        SetBlipSprite(blip, 108) -- 108 = ikona ATM, 277 = ikona banky
        SetBlipScale(blip, 0.7)
        SetBlipDisplay(blip, 4)
        SetBlipColour(blip, 2)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(bank.name)
        EndTextCommandSetBlipName(blip)
        print("DEBUG BANKY: Vytvoreny blip pre banku: " .. bank.name)
    end
    print("DEBUG BANKY: Vsetky blipy vytvorene")
end)

-- Funkcia na získanie aktuálnych údajov o peniazoch
function UpdateMoneyInfo()
    local Player = QBCore.Functions.GetPlayerData()
    if Player and Player.money then
        playerCash = Player.money.cash or playerCash
        playerBank = Player.money.bank or playerBank
        print("DEBUG BANKY: Updated local money info - Cash: " .. playerCash .. ", Bank: " .. playerBank)
        return true
    end
    return false
end

-- Hlavná sluèka na vykreslenie markerov
Citizen.CreateThread(function()
    print("DEBUG BANKY: Spustam slucku pre markery")
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local isNearBank = false
        
        for _, bank in pairs(bankLocations) do
            local dist = #(playerCoords - bank.coords)
            if dist < 10.0 then
                isNearBank = true
                -- Vykreslenie markeru
                DrawMarker(
                    2,
                    bank.coords.x, bank.coords.y, bank.coords.z,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    1.0, 1.0, 0.5,
                    0, 255, 0, 100,
                    false, false, 2,
                    nil, nil, false
                )

                -- Ak je hráè naozaj blízko
                if dist < 1.5 then
                    DrawText3D(bank.coords.x, bank.coords.y, bank.coords.z + 1.0, '[E] - OTVORI BANKU')

                    if IsControlJustPressed(0, 38) then
                        print("DEBUG BANKY: Hrac stlacil E pri banke " .. bank.name)
                        
                        -- Aktualizácia údajov o peniazoch
                        if not UpdateMoneyInfo() then
                            -- Ak sa nepodarí získa údaje lokálne, vyiadame ich zo servera
                            TriggerServerEvent('qb-banka:getMoneyInfo')
                            Citizen.Wait(500) -- Poèka, kım príde odpoveï
                        end
                        
                        -- Otvoríme bankové menu
                        OpenBankMenu(bank.name)
                    end
                end
            end
        end
        
        if not isNearBank then
            Citizen.Wait(500) -- Optimalizácia, ak nie je hráè blízko iadnej banky
        end
    end
end)

-- FUNKCIA: Otvorenie menu (qb-menu)
function OpenBankMenu(bankName)
    -- Ešte raz skontrolujeme údaje o peniazoch pre istotu
    UpdateMoneyInfo()
    
    print("DEBUG BANKY: Opening bank menu at " .. bankName .. ", cash: " .. playerCash .. ", bank: " .. playerBank)

    exports['qb-menu']:openMenu({
        {
            header = bankName,
            isMenuHeader = true
        },
        {
            header = ("Máš pri sebe: %d$, v banke: %d$"):format(playerCash, playerBank),
            txt = "",
            isMenuHeader = true
        },
        {
            header = "Vloi peniaze",
            txt = "Vloi hotovos do banky",
            params = {
                event = "qb-banka:clientDeposit"
            }
        },
        {
            header = "Vybra peniaze",
            txt = "Vybra peniaze z banky",
            params = {
                event = "qb-banka:clientWithdraw"
            }
        },
        {
            header = "Posla peniaze",
            txt = "Posla peniaze inému hráèovi",
            params = {
                event = "qb-banka:clientTransfer"
            }
        },
        {
            header = "Zavrie",
            params = {
                event = "qb-menu:closeMenu"
            }
        },
    })
end

-- Funkcia na vykreslenie 3D textu
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())

    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextCentre(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(_x, _y)

        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.015, 0.015 + factor, 0.03, 0, 0, 0, 120)
    end
end

-- Registrácia eventov pre bankové menu
RegisterNetEvent('qb-banka:clientDeposit', function()
    local dialog = exports['qb-input']:ShowInput({
        header = "Vloi peniaze",
        submitText = "Vloi",
        inputs = {
            {
                type = 'number',
                name = 'amount',
                text = 'Suma na vloenie'
            }
        }
    })
    if dialog then
        local amount = tonumber(dialog.amount)
        if amount and amount > 0 then
            -- Aktualizácia údajov o peniazoch pre najnovšie hodnoty
            UpdateMoneyInfo()
            
            if amount > playerCash then
                QBCore.Functions.Notify("Nemáš dostatok hotovosti na vloenie!", "error")
                return
            end
            
            TriggerServerEvent('qb-banka:deposit', amount)
            -- Po chvíli získame aktualizované údaje o peniazoch
            Citizen.Wait(500)
            TriggerServerEvent('qb-banka:getMoneyInfo')
        else
            QBCore.Functions.Notify("Nesprávna suma!", "error")
        end
    end
end)

RegisterNetEvent('qb-banka:clientWithdraw', function()
    local dialog = exports['qb-input']:ShowInput({
        header = "Vybra peniaze",
        submitText = "Vybra",
        inputs = {
            {
                type = 'number',
                name = 'amount',
                text = 'Suma na vıber'
            }
        }
    })
    if dialog then
        local amount = tonumber(dialog.amount)
        if amount and amount > 0 then
            -- Aktualizácia údajov o peniazoch pre najnovšie hodnoty
            UpdateMoneyInfo()
            
            if amount > playerBank then
                QBCore.Functions.Notify("Nemáš dostatok peòazí na úète!", "error")
                return
            end
            
            TriggerServerEvent('qb-banka:withdraw', amount)
            -- Po chvíli získame aktualizované údaje o peniazoch
            Citizen.Wait(500)
            TriggerServerEvent('qb-banka:getMoneyInfo')
        else
            QBCore.Functions.Notify("Nesprávna suma!", "error")
        end
    end
end)

RegisterNetEvent('qb-banka:clientTransfer', function()
    local dialog = exports['qb-input']:ShowInput({
        header = "Posla peniaze",
        submitText = "Posla",
        inputs = {
            {
                type = 'text',
                name = 'targetId',
                text = 'ID hráèa'
            },
            {
                type = 'number',
                name = 'amount',
                text = 'Suma'
            }
        }
    })
    if dialog then
        local targetId = dialog.targetId
        local amount = tonumber(dialog.amount)
        if targetId and amount and amount > 0 then
            -- Aktualizácia údajov o peniazoch pre najnovšie hodnoty
            UpdateMoneyInfo()
            
            if amount > playerBank then
                QBCore.Functions.Notify("Nemáš dostatok peòazí na úète!", "error")
                return
            end
            
            TriggerServerEvent('qb-banka:transfer', targetId, amount)
            -- Po chvíli získame aktualizované údaje o peniazoch
            Citizen.Wait(500)
            TriggerServerEvent('qb-banka:getMoneyInfo')
        else
            QBCore.Functions.Notify("Nesprávne údaje!", "error")
        end
    end
end)

-- Príkaz na zistenie bankového zostatku a hotovosti
RegisterCommand('penize', function()
    -- Skúsime najprv získa údaje lokálne
    if not UpdateMoneyInfo() then
        -- Ak sa nepodarí, vyiadame ich zo servera
        TriggerServerEvent('qb-banka:getMoneyInfo')
        Citizen.Wait(500) -- Poèka na odpoveï servera
    end
    
    -- Potom zobraz notifikáciu s aktuálnymi hodnotami
    QBCore.Functions.Notify("Hotovos: $" .. playerCash .. ", Bankovı zostatok: $" .. playerBank, "primary", 5000)
end, false)

RegisterCommand('vklad', function(source, args)
    if not args[1] then
        QBCore.Functions.Notify("Zadaj sumu na vklad. Pouitie: /vklad [suma]", "error")
        return
    end
    
    local amount = tonumber(args[1])
    if not amount or amount <= 0 then
        QBCore.Functions.Notify("Zadaj platnú sumu na vklad", "error")
        return
    end
    
    -- Aktualizácia údajov o peniazoch pre najnovšie hodnoty
    UpdateMoneyInfo()
    
    -- Kontrola, èi má hráè dostatok hotovosti
    if amount > playerCash then
        QBCore.Functions.Notify("Nemáš dostatok hotovosti na vloenie!", "error")
        return
    end
    
    TriggerServerEvent('qb-banka:deposit', amount)
    -- Po chvíli aktualizuj údaje o peniazoch
    Citizen.Wait(500)
    TriggerServerEvent('qb-banka:getMoneyInfo')
end, false)

RegisterCommand('vyber', function(source, args)
    if not args[1] then
        QBCore.Functions.Notify("Zadaj sumu na vıber. Pouitie: /vyber [suma]", "error")
        return
    end
    
    local amount = tonumber(args[1])
    if not amount or amount <= 0 then
        QBCore.Functions.Notify("Zadaj platnú sumu na vıber", "error")
        return
    end
    
    -- Aktualizácia údajov o peniazoch pre najnovšie hodnoty
    UpdateMoneyInfo()
    
    -- Kontrola, èi má hráè dostatok peòazí v banke
    if amount > playerBank then
        QBCore.Functions.Notify("Nemáš dostatok peòazí na úète!", "error")
        return
    end
    
    TriggerServerEvent('qb-banka:withdraw', amount)
    -- Po chvíli aktualizuj údaje o peniazoch
    Citizen.Wait(500)
    TriggerServerEvent('qb-banka:getMoneyInfo')
end, false)

RegisterCommand('prevod', function(source, args)
    if not args[1] or not args[2] then
        QBCore.Functions.Notify("Nesprávne parametre. Pouitie: /prevod [ID hráèa] [suma]", "error")
        return
    end
    
    local targetId = args[1]
    local amount = tonumber(args[2])
    if not amount or amount <= 0 then
        QBCore.Functions.Notify("Zadaj platnú sumu na prevod", "error")
        return
    end
    
    -- Aktualizácia údajov o peniazoch pre najnovšie hodnoty
    UpdateMoneyInfo()
    
    -- Kontrola, èi má hráè dostatok peòazí v banke
    if amount > playerBank then
        QBCore.Functions.Notify("Nemáš dostatok peòazí na úète!", "error")
        return
    end
    
    TriggerServerEvent('qb-banka:transfer', targetId, amount)
    -- Po chvíli aktualizuj údaje o peniazoch
    Citizen.Wait(500)
    TriggerServerEvent('qb-banka:getMoneyInfo')
end, false)

-- Získame aktuálne údaje o peniazoch pri naèítaní hráèa
Citizen.CreateThread(function()
    -- Poèkáme dlhší èas, aby sa hráè správne naèítal v QBCore
    Citizen.Wait(10000) -- Predåenie èakania na 10 sekúnd
    
    -- Skúsime najprv získa údaje lokálne
    if not UpdateMoneyInfo() then
        -- Ak sa nepodarí, vyiadame ich zo servera
        print("DEBUG BANKY: Initial money info not available locally, requesting from server")
        TriggerServerEvent('qb-banka:getMoneyInfo')
    end
end)

-- Pridáme listener na QBCore event, ktorı sa spustí, keï sa hráè naèíta
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    print("DEBUG BANKY: Player loaded event received, updating money info")
    -- Poèkáme chví¾u, aby sa údaje správne nastavili
    Citizen.Wait(1000)
    
    -- Skúsime získa údaje lokálne
    if not UpdateMoneyInfo() then
        -- Ak sa nepodarí, vyiadame ich zo servera
        TriggerServerEvent('qb-banka:getMoneyInfo')
    end
end)

-- Listener na aktualizáciu peòazí
RegisterNetEvent('QBCore:Client:OnMoneyChange', function(moneyType, amount, reason)
    print("DEBUG BANKY: Money changed - Type: " .. moneyType .. ", Amount: " .. amount .. ", Reason: " .. (reason or "unknown"))
    
    -- Aktualizujeme lokálne údaje
    UpdateMoneyInfo()
end)