local QBCore = exports['qb-core']:GetCoreObject()
local playerBank = 0
local playerCash = 0

-- Prijatie aktualiz�cie bankov�ho zostatku zo servera
RegisterNetEvent('qb-banka:receiveBalance', function(balance)
    playerBank = balance
    print("DEBUG BANKY: Received bank balance: " .. playerBank)
end)

-- Prijatie kompletn�ch inform�ci� o peniazoch (cash + bank)
RegisterNetEvent('qb-banka:receiveMoneyInfo', function(cash, bank)
    playerCash = cash
    playerBank = bank
    print("DEBUG BANKY: Received money info - Cash: " .. playerCash .. ", Bank: " .. playerBank)
end)

-- Defin�cia bankov�ch lok�ci�
local bankLocations = {
    {name = "Fleeca Bank (Legion Square)", coords = vector3(149.9, -1040.46, 29.37)},
    {name = "Fleeca Bank (Alta)", coords = vector3(314.23, -278.83, 54.17)},
    {name = "Fleeca Bank (Burton)", coords = vector3(-350.8, -49.57, 49.04)},
    {name = "Fleeca Bank (Rockford Hills)", coords = vector3(-1212.98, -330.88, 37.79)},
    {name = "Fleeca Bank (Grand Senora)", coords = vector3(1175.09, 2706.96, 38.09)},
    {name = "Pacific Standard", coords = vector3(246.64, 223.20, 106.29)},
    {name = "Blaine County Savings", coords = vector3(-112.22, 6469.89, 31.63)}
}

-- Vytvor�me blipy na mape
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

-- Funkcia na z�skanie aktu�lnych �dajov o peniazoch
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

-- Hlavn� slu�ka na vykreslenie markerov
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

                -- Ak je hr�� naozaj bl�zko
                if dist < 1.5 then
                    DrawText3D(bank.coords.x, bank.coords.y, bank.coords.z + 1.0, '[E] - OTVORI� BANKU')

                    if IsControlJustPressed(0, 38) then
                        print("DEBUG BANKY: Hrac stlacil E pri banke " .. bank.name)
                        
                        -- Aktualiz�cia �dajov o peniazoch
                        if not UpdateMoneyInfo() then
                            -- Ak sa nepodar� z�ska� �daje lok�lne, vy�iadame ich zo servera
                            TriggerServerEvent('qb-banka:getMoneyInfo')
                            Citizen.Wait(500) -- Po�ka�, k�m pr�de odpove�
                        end
                        
                        -- Otvor�me bankov� menu
                        OpenBankMenu(bank.name)
                    end
                end
            end
        end
        
        if not isNearBank then
            Citizen.Wait(500) -- Optimaliz�cia, ak nie je hr�� bl�zko �iadnej banky
        end
    end
end)

-- FUNKCIA: Otvorenie menu (qb-menu)
function OpenBankMenu(bankName)
    -- E�te raz skontrolujeme �daje o peniazoch pre istotu
    UpdateMoneyInfo()
    
    print("DEBUG BANKY: Opening bank menu at " .. bankName .. ", cash: " .. playerCash .. ", bank: " .. playerBank)

    exports['qb-menu']:openMenu({
        {
            header = bankName,
            isMenuHeader = true
        },
        {
            header = ("M� pri sebe: %d$, v banke: %d$"):format(playerCash, playerBank),
            txt = "",
            isMenuHeader = true
        },
        {
            header = "Vlo�i� peniaze",
            txt = "Vlo�i� hotovos� do banky",
            params = {
                event = "qb-banka:clientDeposit"
            }
        },
        {
            header = "Vybra� peniaze",
            txt = "Vybra� peniaze z banky",
            params = {
                event = "qb-banka:clientWithdraw"
            }
        },
        {
            header = "Posla� peniaze",
            txt = "Posla� peniaze in�mu hr��ovi",
            params = {
                event = "qb-banka:clientTransfer"
            }
        },
        {
            header = "Zavrie�",
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

-- Registr�cia eventov pre bankov� menu
RegisterNetEvent('qb-banka:clientDeposit', function()
    local dialog = exports['qb-input']:ShowInput({
        header = "Vlo�i� peniaze",
        submitText = "Vlo�i�",
        inputs = {
            {
                type = 'number',
                name = 'amount',
                text = 'Suma na vlo�enie'
            }
        }
    })
    if dialog then
        local amount = tonumber(dialog.amount)
        if amount and amount > 0 then
            -- Aktualiz�cia �dajov o peniazoch pre najnov�ie hodnoty
            UpdateMoneyInfo()
            
            if amount > playerCash then
                QBCore.Functions.Notify("Nem� dostatok hotovosti na vlo�enie!", "error")
                return
            end
            
            TriggerServerEvent('qb-banka:deposit', amount)
            -- Po chv�li z�skame aktualizovan� �daje o peniazoch
            Citizen.Wait(500)
            TriggerServerEvent('qb-banka:getMoneyInfo')
        else
            QBCore.Functions.Notify("Nespr�vna suma!", "error")
        end
    end
end)

RegisterNetEvent('qb-banka:clientWithdraw', function()
    local dialog = exports['qb-input']:ShowInput({
        header = "Vybra� peniaze",
        submitText = "Vybra�",
        inputs = {
            {
                type = 'number',
                name = 'amount',
                text = 'Suma na v�ber'
            }
        }
    })
    if dialog then
        local amount = tonumber(dialog.amount)
        if amount and amount > 0 then
            -- Aktualiz�cia �dajov o peniazoch pre najnov�ie hodnoty
            UpdateMoneyInfo()
            
            if amount > playerBank then
                QBCore.Functions.Notify("Nem� dostatok pe�az� na ��te!", "error")
                return
            end
            
            TriggerServerEvent('qb-banka:withdraw', amount)
            -- Po chv�li z�skame aktualizovan� �daje o peniazoch
            Citizen.Wait(500)
            TriggerServerEvent('qb-banka:getMoneyInfo')
        else
            QBCore.Functions.Notify("Nespr�vna suma!", "error")
        end
    end
end)

RegisterNetEvent('qb-banka:clientTransfer', function()
    local dialog = exports['qb-input']:ShowInput({
        header = "Posla� peniaze",
        submitText = "Posla�",
        inputs = {
            {
                type = 'text',
                name = 'targetId',
                text = 'ID hr��a'
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
            -- Aktualiz�cia �dajov o peniazoch pre najnov�ie hodnoty
            UpdateMoneyInfo()
            
            if amount > playerBank then
                QBCore.Functions.Notify("Nem� dostatok pe�az� na ��te!", "error")
                return
            end
            
            TriggerServerEvent('qb-banka:transfer', targetId, amount)
            -- Po chv�li z�skame aktualizovan� �daje o peniazoch
            Citizen.Wait(500)
            TriggerServerEvent('qb-banka:getMoneyInfo')
        else
            QBCore.Functions.Notify("Nespr�vne �daje!", "error")
        end
    end
end)

-- Pr�kaz na zistenie bankov�ho zostatku a hotovosti
RegisterCommand('penize', function()
    -- Sk�sime najprv z�ska� �daje lok�lne
    if not UpdateMoneyInfo() then
        -- Ak sa nepodar�, vy�iadame ich zo servera
        TriggerServerEvent('qb-banka:getMoneyInfo')
        Citizen.Wait(500) -- Po�ka� na odpove� servera
    end
    
    -- Potom zobraz notifik�ciu s aktu�lnymi hodnotami
    QBCore.Functions.Notify("Hotovos�: $" .. playerCash .. ", Bankov� zostatok: $" .. playerBank, "primary", 5000)
end, false)

RegisterCommand('vklad', function(source, args)
    if not args[1] then
        QBCore.Functions.Notify("Zadaj sumu na vklad. Pou�itie: /vklad [suma]", "error")
        return
    end
    
    local amount = tonumber(args[1])
    if not amount or amount <= 0 then
        QBCore.Functions.Notify("Zadaj platn� sumu na vklad", "error")
        return
    end
    
    -- Aktualiz�cia �dajov o peniazoch pre najnov�ie hodnoty
    UpdateMoneyInfo()
    
    -- Kontrola, �i m� hr�� dostatok hotovosti
    if amount > playerCash then
        QBCore.Functions.Notify("Nem� dostatok hotovosti na vlo�enie!", "error")
        return
    end
    
    TriggerServerEvent('qb-banka:deposit', amount)
    -- Po chv�li aktualizuj �daje o peniazoch
    Citizen.Wait(500)
    TriggerServerEvent('qb-banka:getMoneyInfo')
end, false)

RegisterCommand('vyber', function(source, args)
    if not args[1] then
        QBCore.Functions.Notify("Zadaj sumu na v�ber. Pou�itie: /vyber [suma]", "error")
        return
    end
    
    local amount = tonumber(args[1])
    if not amount or amount <= 0 then
        QBCore.Functions.Notify("Zadaj platn� sumu na v�ber", "error")
        return
    end
    
    -- Aktualiz�cia �dajov o peniazoch pre najnov�ie hodnoty
    UpdateMoneyInfo()
    
    -- Kontrola, �i m� hr�� dostatok pe�az� v banke
    if amount > playerBank then
        QBCore.Functions.Notify("Nem� dostatok pe�az� na ��te!", "error")
        return
    end
    
    TriggerServerEvent('qb-banka:withdraw', amount)
    -- Po chv�li aktualizuj �daje o peniazoch
    Citizen.Wait(500)
    TriggerServerEvent('qb-banka:getMoneyInfo')
end, false)

RegisterCommand('prevod', function(source, args)
    if not args[1] or not args[2] then
        QBCore.Functions.Notify("Nespr�vne parametre. Pou�itie: /prevod [ID hr��a] [suma]", "error")
        return
    end
    
    local targetId = args[1]
    local amount = tonumber(args[2])
    if not amount or amount <= 0 then
        QBCore.Functions.Notify("Zadaj platn� sumu na prevod", "error")
        return
    end
    
    -- Aktualiz�cia �dajov o peniazoch pre najnov�ie hodnoty
    UpdateMoneyInfo()
    
    -- Kontrola, �i m� hr�� dostatok pe�az� v banke
    if amount > playerBank then
        QBCore.Functions.Notify("Nem� dostatok pe�az� na ��te!", "error")
        return
    end
    
    TriggerServerEvent('qb-banka:transfer', targetId, amount)
    -- Po chv�li aktualizuj �daje o peniazoch
    Citizen.Wait(500)
    TriggerServerEvent('qb-banka:getMoneyInfo')
end, false)

-- Z�skame aktu�lne �daje o peniazoch pri na��tan� hr��a
Citizen.CreateThread(function()
    -- Po�k�me dlh�� �as, aby sa hr�� spr�vne na��tal v QBCore
    Citizen.Wait(10000) -- Pred�enie �akania na 10 sek�nd
    
    -- Sk�sime najprv z�ska� �daje lok�lne
    if not UpdateMoneyInfo() then
        -- Ak sa nepodar�, vy�iadame ich zo servera
        print("DEBUG BANKY: Initial money info not available locally, requesting from server")
        TriggerServerEvent('qb-banka:getMoneyInfo')
    end
end)

-- Prid�me listener na QBCore event, ktor� sa spust�, ke� sa hr�� na��ta
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    print("DEBUG BANKY: Player loaded event received, updating money info")
    -- Po�k�me chv�u, aby sa �daje spr�vne nastavili
    Citizen.Wait(1000)
    
    -- Sk�sime z�ska� �daje lok�lne
    if not UpdateMoneyInfo() then
        -- Ak sa nepodar�, vy�iadame ich zo servera
        TriggerServerEvent('qb-banka:getMoneyInfo')
    end
end)

-- Listener na aktualiz�ciu pe�az�
RegisterNetEvent('QBCore:Client:OnMoneyChange', function(moneyType, amount, reason)
    print("DEBUG BANKY: Money changed - Type: " .. moneyType .. ", Amount: " .. amount .. ", Reason: " .. (reason or "unknown"))
    
    -- Aktualizujeme lok�lne �daje
    UpdateMoneyInfo()
end)