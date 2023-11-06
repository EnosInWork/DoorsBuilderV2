local _CreateThread, _Wait, SendNUIMessage = CreateThread, Wait, SendNUIMessage
local showedEntity = nil
local _enabledDoors, _doorState = {}, {}
local DrawTxt = DrawTxt
local pulsed = false
local nearId = ""
local _coordsToShow = nil
local text = ""

if Config['use_Export_ESX'] then 
    ESX = nil 
    ESX = exports[Config['extended_Name']]:getSharedObject()
else
    ESX = nil 
    Citizen.CreateThread(function() 
        while ESX == nil do 
            TriggerEvent(Config['shared_Name'], function(obj) ESX = obj end) 
            Citizen.Wait(250) 
        end 
    end)
end

TriggerEvent('chat:addSuggestion', '/'..Config['command_create_door'], 'Ouvrir le DoorsBuilder')
TriggerEvent('chat:addSuggestion', '/'..Config['command_delete_door'], 'Supprimer une porte')

local function KeyboardInput(TextEntry, ExampleText, MaxStringLenght)
    AddTextEntry('FMMC_KEY_TIP1', TextEntry)
    blockinput = true
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLenght)
    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do 
        Wait(0)
    end 
        
    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Wait(500)
        blockinput = false
        return result
    else
        Wait(500)
        blockinput = false
        return nil
    end
end


local _doorType, _distToDoor, allowedJobs, doorPin, item = "normal", 2, {}, "", ""

_CreateThread(function()
    _Wait(500)
    ESX['TriggerServerCallback']('guille_doorlock:cb:getDoors', function(doors, state)
        _enabledDoors = doors
        _doorState = state
    end)
end)

local IndexType = 1

function OpenDoorlock()
	local door_main = RageUI.CreateMenu("Doors-Builder", "V2")

        RageUI.Visible(door_main, not RageUI.Visible(door_main))
            while door_main do
            Citizen.Wait(0)
            RageUI.IsVisible(door_main, true, true, true, function()

                RageUI.List("→ Type de porte ", {"Double", "Simple", "Coulissante"}, IndexType, nil, {}, true, function(Hovered, Active, Selected, Index)
                    if (Selected) then 
                        if Index == 1 then
                            _doorType = "double"
                            RageUI.CloseAll()
                            ExecuteCommand(Config['command_create_door'])
                            ESX.ShowNotification("[~b~DoorsBuilderV2~s~] - ~g~Double porte")
                        elseif Index == 2 then
                            _doorType = "normal"
                            RageUI.CloseAll()
                            ExecuteCommand(Config['command_create_door'])
                            ESX.ShowNotification("[~b~DoorsBuilderV2~s~] - ~g~Porte simple")
                        elseif Index == 3 then
                            _doorType = "slider"
                            RageUI.CloseAll()
                            ExecuteCommand(Config['command_create_door'])
                            ESX.ShowNotification("[~b~DoorsBuilderV2~s~] - ~g~Porte coulissante")
                            end
                        end
                    IndexType = Index;              
                end)

                RageUI.ButtonWithStyle("→ Disctance d'ouverture", nil, {RightLabel = _distToDoor}, true, function(Hovered, Active, Selected)
                    if Selected then
                        local dist = KeyboardInput('Distance entre 1 et 15', '', 10)
                        if dist == nil or dist == "" then
                            ESX.ShowNotification('[~b~DoorsBuilderV2~s~] - ~r~Distance invalide')
                        else
                            _distToDoor = dist
                            RageUI.CloseAll()
                            ExecuteCommand(Config['command_create_door'])
                        end
                    end
                end)

                RageUI.ButtonWithStyle("→ Accès job/job2", nil, {}, true, function(Hovered, Active, Selected)
                    if Selected then 
                        Job = KeyboardInput("Nom du job", "", 15)
                        if Job == nil or Job == "" then
                            ESX.ShowNotification('[~b~DoorsBuilderV2~s~] - ~r~Job invalide')
                        else
                            table['insert'](allowedJobs, Job)
                            RageUI.CloseAll()
                            ExecuteCommand(Config['command_create_door'])
                        end
                    end
                end)

                if Job ~= nil then 
                    for _, job in pairs(allowedJobs) do 
                        RageUI.Separator("Accès job/job2 → ~g~"..job)
                    end
                end

                RageUI.ButtonWithStyle("→ Code pin", nil, {RightLabel = pin}, true, function(Hovered, Active, Selected)
                    if Selected then 
                        pin = KeyboardInput('Code pin?', '', 15)
                        if pin == nil or pin == "" then
                            ESX.ShowNotification('[~b~DoorsBuilderV2~s~] - ~r~Pin invalide')
                        else
                            doorPin = pin
                            RageUI.CloseAll()
                            ExecuteCommand(Config['command_create_door'])
                        end
                    end
                end)
                RageUI.ButtonWithStyle("→ Item requis", nil, {RightLabel = item}, true, function(Hovered, Active, Selected)
                    if Selected then 
                        item = KeyboardInput('Item?', '', 15)
                        if item == nil or item == "" then
                            ESX.ShowNotification('[~b~DoorsBuilderV2~s~] - ~r~Item invalide')
                        else
                            item = item
                            RageUI.CloseAll()
                            ExecuteCommand(Config['command_create_door'])
                        end
                    end
                end)

                RageUI.ButtonWithStyle("~g~→→ Confirmer la création", nil, {RightLabel = ""}, true, function(Hovered, Active, Selected)
                    if Selected then 
                        addDoor(_doorType, _distToDoor, allowedJobs, doorPin, item)
                        RageUI.CloseAll()
                        _doorType = "normal"
                        _distToDoor = 2
                        doorPin = ""
                        allowedJobs = {}
                        Job = nil
                        pin = nil
                        item = nil
                    end
                end)

            end, function()
            end)

            if not RageUI.Visible(door_main) then
            door_main = RMenu:DeleteType("door_main", true)
        end
    end
end

RegisterNetEvent("guille_doorlock:client:setUpDoor", function()
    OpenDoorlock()
end)

RegisterNetEvent("guille_doorlock:client:deleteDoor", function()
    _CreateThread(function()
        while true do
            local _wait = 0
            local _ped = PlayerPedId()
            local _coords = GetEntityCoords(_ped)
            local hit, coords, entity = RayCastGamePlayCamera(5000.0)
            local _found = false

            DrawLine(_coords, coords, 255, 0, 0, 255)

            ESX.ShowHelpNotification("Appuyez sur ~input_context~ pour retirer la porte\nAppuyez sur ~INPUT_DETONATE~ pour annuler")

            for k, v in pairs(_enabledDoors) do
                if v['_type'] ~= "double" then
                    local _doorCoords = vector3(v['doorCoords']['x'], v['doorCoords']['y'], v['doorCoords']['z'])
                    DrawMarker(28, _doorCoords, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.18, 0.18, 0.18, 255, 0, 0, 255, false, true, 2, nil, nil, false)
                else
                    local _doorCoords = vector3(v['_textCoords']['x'], v['_textCoords']['y'], v['_textCoords']['z'])
                    DrawMarker(28, _doorCoords, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.18, 0.18, 0.18, 255, 0, 0, 255, false, true, 2, nil, nil, false)
                end
            end

            if IsControlJustPressed(1, 38) then
                for k, v in pairs(_enabledDoors) do
                    if v['_type'] ~= "double" then
                        local _doorCoords = vector3(v['doorCoords']['x'], v['doorCoords']['y'], v['doorCoords']['z'])
                        local _distTo = #(coords - _doorCoords)
                        if _distTo < 1 then
                            TriggerServerEvent("guille_doorlock:server:syncRemove", k)
                            _found = true
                        end
                    else
                        local _doorCoords = vector3(v['_textCoords']['x'], v['_textCoords']['y'], v['_textCoords']['z'])
                        local _distTo = #(coords - _doorCoords)
                        if _distTo < 1 then
                            TriggerServerEvent("guille_doorlock:server:syncRemove", k)
                            _found = true
                        end
                    end
                end
                if _found then
                    ESX.ShowNotification("[~b~DoorsBuilderV2~s~] - ~g~La porte a été supprimer avec succès")
                    break
                else
                    ESX.ShowNotification("[~b~DoorsBuilderV2~s~] - ~r~La porte n'existe pas")
                end
            end

            if IsControlJustPressed(1, 47) then
                ESX.ShowNotification("[~b~DoorsBuilderV2~s~] - ~r~Opération annulé")
                break
            end

            _Wait(_wait)
        end
    end)
end)

RegisterNetEvent("guille_doorlock:client:removeGlobDoor", function(id)
    table['remove'](_enabledDoors, id)
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        SetEntityDrawOutline(showedEntity, false)
    end
end)

addDoor = function(type, dist, jobs, pin, item)
    dist = tonumber(dist)
    if not dist then
        dist = 2
    end
    if type ~= "double" then 
        _CreateThread(function()
            while true do
                local _wait = 0
                local _ped = PlayerPedId()
                local _coords = GetEntityCoords(_ped)
                local hit, coords, entity = RayCastGamePlayCamera(5000.0)   
                if IsEntityAnObject(entity) then
                    ESX.ShowHelpNotification("Appuyez sur ~input_context~ pour ajouter la porte")
                    DrawLine(_coords, coords, 0, 255, 34, 255)
                    if showedEntity ~= entity then
                        SetEntityDrawOutline(showedEntity, false)
                        showedEntity = entity
                    end
                    if IsControlJustPressed(1, 38) then
                        local _doorCoords = GetEntityCoords(entity)
                        local _doorModel = GetEntityModel(entity)
                        local _heading = GetEntityHeading(entity)
                        local _textCoords = coords
                        TriggerServerEvent("guille_doorlock:server:addDoor", _doorCoords, _doorModel, _heading, type, _textCoords, dist, jobs, pin, item)
                        SetEntityDrawOutline(entity, false)
                        break
                    end
                    SetEntityDrawOutline(entity, true)
                else
                    if showedEntity ~= entity then
                        SetEntityDrawOutline(showedEntity, false)
                        showedEntity = entity
                    end
                end
                _Wait(_wait)
            end
        end)
    else
        local _doorsDobule, entities = {}, {}
        _CreateThread(function()
            while true do
                local _wait = 0
                local _ped = PlayerPedId()
                local _coords = GetEntityCoords(_ped)
                local hit, coords, entity = RayCastGamePlayCamera(5000.0)   
                if IsEntityAnObject(entity) then
                    for k, v in pairs(entities) do
                        SetEntityDrawOutline(v, true)
                    end
                    if #_doorsDobule ~= 2 then
                        DrawLine(_coords, coords, 0, 255, 34, 255)
                        ESX.ShowHelpNotification("Appuyez sur ~input_context~ pour ajouter la porte")
                    else
                        DrawLine(_coords, coords, 0, 255, 34, 255)
                        ESX.ShowHelpNotification("Appuyez sur ~input_context~ pour confirmer la porte")
                    end
                    showedEntity = entity
                    if IsControlJustPressed(1, 38) then
                        local _doorCoords = GetEntityCoords(entity)
                        local _doorModel = GetEntityModel(entity)
                        local _heading = GetEntityHeading(entity)
                        local _textCoords = coords
                        if #_doorsDobule == 2 then
                            for k, v in pairs(entities) do
                                SetEntityDrawOutline(v, false)
                            end
                            entities = {}
                            TriggerServerEvent("guille_doorlock:server:addDoubleDoor", _doorsDobule, type, _textCoords, dist, jobs, pin, item)
                            _doorsDobule = {}
                            break
                        else
                            table['insert'](_doorsDobule, {coords = _doorCoords, model = _doorModel, heading = _heading})
                            table['insert'](entities, entity)
                        end
                    end
                end
                _Wait(_wait)
            end
        end)
    end
end

RegisterNetEvent("guille_doorlock:client:refreshDoors", function(tableToIns)
    table['insert'](_enabledDoors, tableToIns)
end)

local _selectedDoorJobs, pin, object = {}, nil, nil

_CreateThread(function()
    while true do
        local isNearToDoor = false
        local _wait = 800
        for k, v in pairs(_enabledDoors) do
            local _doorHash = GetHashKey(v["_doorModel"])
            local _ped = PlayerPedId()
            local _coords = GetEntityCoords(_ped)
            
            if v['_type'] == "normal" then
                local _doorCoords = vector3(v['doorCoords']['x'], v['doorCoords']['y'], v['doorCoords']['z'])
                local _distTo = #(_coords - _doorCoords)
                if _distTo < 30 then
                    door = GetClosestObjectOfType(v['doorCoords']['x'], v['doorCoords']['y'], v['doorCoords']['z'], 1.0, v["_doorModel"], false, false, false)
                    if _doorState[k] ~= nil then
                        FreezeEntityPosition(door, false)
                    else
                        FreezeEntityPosition(door, true)
                    end
                end
                if _distTo < v['dist'] then
                    door = GetClosestObjectOfType(v['doorCoords']['x'], v['doorCoords']['y'], v['doorCoords']['z'], 1.0, v["_doorModel"], false, false, false)
                    _coordsToShow = vector3(v['_textCoords']['x'], v['_textCoords']['y'], v['_textCoords']['z'])
                    isNearToDoor = true
                    _selectedDoorJobs = v['jobs']
                    if v['usePin'] then
                        pin = v['pin']
                    else
                        pin = nil
                    end
                    if v['useitem'] then
                        object = v['item']
                    else
                        object = nil
                    end
                    if _doorState[k] ~= nil then
                        text = Config["strings"]['close']
                        FreezeEntityPosition(door, false)
                        if pulsed then
                            TriggerServerEvent("guille_doorlock:server:updateDoor", k, nil)
                            animatePlyDoor()
                            pulsed = false
                        end
                    else
                        FreezeEntityPosition(door, true)
                        text = Config["strings"]['open']
                        if pulsed then
                            TriggerServerEvent("guille_doorlock:server:updateDoor", k, "locked")
                            animatePlyDoor()
                            pulsed = false
                        end
                        if v['_type'] == "normal" then
                            SetEntityHeading(door, v['_heading'])
                        end
                    end
                    _wait = 120
                end
            elseif v['_type'] == "double" then
                local _doorCoords = vector3(v['_doorsDouble'][1]['coords']['x'], v['_doorsDouble'][1]['coords']['y'], v['_doorsDouble'][1]['coords']['z'])
                local _doorCoords2 = vector3(v['_doorsDouble'][2]['coords']['x'], v['_doorsDouble'][2]['coords']['y'], v['_doorsDouble'][2]['coords']['z'])
                local _distTo = #(_coords - vector3(v['_textCoords']['x'], v['_textCoords']['y'], v['_textCoords']['z']))
                if _distTo < 30 then
                    _coordsToShow = vector3(v['_textCoords']['x'], v['_textCoords']['y'], v['_textCoords']['z'])
                    door1 = GetClosestObjectOfType(_doorCoords, 1.0, v['_doorsDouble'][1]['model'], false, false, false)
                    door2 = GetClosestObjectOfType(_doorCoords2, 1.0, v['_doorsDouble'][2]['model'], false, false, false)
                    if _doorState[k] ~= nil then
                        FreezeEntityPosition(door1, false)
                        FreezeEntityPosition(door2, false)
                    else
                        FreezeEntityPosition(door1, true)
                        FreezeEntityPosition(door2, true)
                        SetEntityHeading(door1, v['_doorsDouble'][1]['heading'])
                        SetEntityHeading(door2, v['_doorsDouble'][2]['heading'])
                    end
                    if _distTo < v['dist'] then
                        if v['usePin'] then
                            pin = v['pin']
                        else
                            pin = nil
                        end
                        if v['useitem'] then
                            object = v['item']
                        else
                            object = nil
                        end
                        _selectedDoorJobs = v['jobs']
                        if _doorState[k] ~= nil then
                            isNearToDoor = true
                            text = Config["strings"]['close']
                            FreezeEntityPosition(door1, false)
                            FreezeEntityPosition(door2, false)
                            if pulsed then
                                TriggerServerEvent("guille_doorlock:server:updateDoor", k, nil)
                                animatePlyDoor()
                                pulsed = false
                                pin = nil
                            end
                        else
                            isNearToDoor = true
                            FreezeEntityPosition(door1, true)
                            FreezeEntityPosition(door2, true)
                            text = Config["strings"]['open']
                            if pulsed then
                                TriggerServerEvent("guille_doorlock:server:updateDoor", k, "locked")
                                animatePlyDoor()
                                pulsed = false
                                pin = nil
                            end
                            SetEntityHeading(door1, v['_doorsDouble'][1]['heading'])
                            SetEntityHeading(door2, v['_doorsDouble'][2]['heading'])
                        end
                        _wait = 120
                    end
                end
            else 
                local _doorCoords = vector3(v['doorCoords']['x'], v['doorCoords']['y'], v['doorCoords']['z'])
                local _distTo = #(_coords - _doorCoords)
                if _distTo < 30 then
                    door = GetClosestObjectOfType(v['doorCoords']['x'], v['doorCoords']['y'], v['doorCoords']['z'], 1.0, v["_doorModel"], false, false, false)
                    if not IsDoorRegisteredWithSystem(v['_doorModel'].. "door"..k) then
                        AddDoorToSystem(v['_doorModel'].. "door"..k, v['_doorModel'], _doorCoords, false, false, false)
                        print(k.. " - Slider Registered")
                    end
                    if _doorState[k] ~= nil then
                        DoorSystemSetDoorState(v['_doorModel'].. "door"..k, 0, false, false) 
                        DoorSystemSetAutomaticDistance(v['_doorModel'].. "door"..k, 30.0, false, false)
                    else
                        DoorSystemSetAutomaticDistance(v['_doorModel'].. "door"..k, 0.0, false, false)
                        DoorSystemSetDoorState(v['_doorModel'].. "door"..k, 4, false, false)
                    end
                end
                if _distTo < v['dist'] then
                    door = GetClosestObjectOfType(v['doorCoords']['x'], v['doorCoords']['y'], v['doorCoords']['z'], 1.0, v["_doorModel"], false, false, false)
                    _coordsToShow = vector3(v['_textCoords']['x'], v['_textCoords']['y'], v['_textCoords']['z'])
                    isNearToDoor = true
                    _selectedDoorJobs = v['jobs']
                    if v['usePin'] then
                        pin = v['pin']
                    else
                        pin = nil
                    end
                    if v['useitem'] then
                        object = v['item']
                    else
                        object = nil
                    end
                    if _doorState[k] ~= nil then
                        text = Config["strings"]['close']
                        DoorSystemSetDoorState(v['_doorModel'].. "door"..k, 0, false, false) 
                        DoorSystemSetAutomaticDistance(v['_doorModel'].. "door"..k, 30.0, false, false)
                        if pulsed then
                            TriggerServerEvent("guille_doorlock:server:updateDoor", k, nil)
                            animatePlyDoor()
                            pulsed = false
                        end
                    else
                        DoorSystemSetDoorState(v['_doorModel'].. "door"..k, 4, false, false)
                        DoorSystemSetAutomaticDistance(v['_doorModel'].. "door"..k, 0.0, false, false)
                        text = Config["strings"]['open']
                        if pulsed then
                            TriggerServerEvent("guille_doorlock:server:updateDoor", k, "locked")
                            animatePlyDoor()
                            pulsed = false
                        end
                    end

                    _wait = 120
                end
            end
        end
        if isNearToDoor then
            show = true
        else
            show = false
        end
        _Wait(_wait)
    end
end)

animatePlyDoor = function()
	_CreateThread(function()
        while not HasAnimDictLoaded("anim@heists@keycard@") do
            RequestAnimDict("anim@heists@keycard@")
            _Wait(1)
        end
        TaskPlayAnim(PlayerPedId(), "anim@heists@keycard@", "exit", 8.0, 1.0, -1, 16, 0, 0, 0, 0)
        _Wait(200)
        ClearPedTasks(PlayerPedId())
	end)
end

local _nuiDone = false

_CreateThread(function()
    while true do
        local _wait = 800
        if show then
            if Config['enableNuiIndicator'] then
                SendNUIMessage({
                    show = true;
                    text = replaceColorText(text);
                })
                _nuiDone = false
                _wait = 500
            else
                _wait = 3
                DrawTxt(_coordsToShow, text, 0.7, 8)
            end
        else
            if Config['enableNuiIndicator'] then
                if not _nuiDone then
                    SendNUIMessage({
                        show = false;
                    })
                    _nuiDone = true
                end
            end
        end
        _Wait(_wait)
    end
end)

DrawTxt = function(coords, text, size, font)
    local coords = vector3(coords.x, coords.y, coords.z)

    local camCoords = GetGameplayCamCoords()
    local distance = #(coords - camCoords)

    if not size then size = 1 end
    if not font then font = 0 end

    local scale = (size / distance) * 1
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    SetTextScale(0.0 * scale, 0.55 * scale)
    SetTextFont(font)
    SetTextColour(255, 255, 255, 215)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(true)

    SetDrawOrigin(coords, 0)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

RegisterNetEvent("guille_doorlock:client:updateDoorState", function(id, type, h)
    _doorState[id] = type
end)

RegisterCommand("lockdoor", function()
    if show then
        local _allowed = false
        for k, v in pairs(_selectedDoorJobs) do
            if v == ESX['GetPlayerData']()['job']['name'] then
                _allowed = true
            end
        end
        if _allowed then
            pulsed = true
            return
        end


        if not allowed then

            if pin then
                if Config['CodePin_With_Menu'] then 
                    PinDoor()
                else
                    Wait(20)
                    local pinIntr = KeyboardInput('Code de la porte', '', 20)
                    if pinIntr ~= pin then
                        ESX.ShowNotification("[~b~Porte~s~] - ~r~Code invalide")
                    else
                        pulsed = true   
                        pin = nil            
                    end
                end
            end

            if object then
                ESX.TriggerServerCallback('guille_doorlock:cb:hasObj', function(has)
                    if has then
                        pulsed = true
                        object = nil
                    else
                        ESX.ShowNotification("~r~Vous avez besoin d'un objet pour ouvrir cette porte.")
                    end
                end, object)
            end

        end

    end
end)

function PinDoor()
	local door_pin = RageUI.CreateMenu("Porte", "Code")

        RageUI.Visible(door_pin, not RageUI.Visible(door_pin))
            while door_pin do
            Citizen.Wait(0)
            RageUI.IsVisible(door_pin, true, true, true, function()

                RageUI.Separator("~r~Cette porte est verouiller par un code")

                RageUI.ButtonWithStyle("→ Entrer le code", nil, {RightLabel = pinIntr}, true, function(Hovered, Active, Selected)
                    if Selected then
                        pinIntr = KeyboardInput('Code de la porte', '', 20)
                        if pinIntr == pin then
                            pulsed = true 
                            pin = nil   
                            pinIntr = nil   
                            RageUI.CloseAll()
                        else
                            pin = nil   
                            pinIntr = nil   
                            ESX.ShowNotification("[~b~Porte(s)~s~] - ~r~Code inccorect")
                            RageUI.CloseAll()     
                        end
                    end
                end)

            end, function()
            end)

            if not RageUI.Visible(door_pin) then
            door_pin = RMenu:DeleteType(door_pin, true)
        end
    end
end

RegisterKeyMapping("lockdoor", "Vérouiller/Dévérouiller une porte", 'keyboard', Config['KeyForOpenCloseDoor'])

RayCastGamePlayCamera = function(distance)
    local cameraRotation = GetGameplayCamRot()
	local cameraCoord = GetGameplayCamCoord()
	local direction = RotationToDirection(cameraRotation)
	local destination =
	{
		x = cameraCoord.x + direction.x * distance,
		y = cameraCoord.y + direction.y * distance,
		z = cameraCoord.z + direction.z * distance
	}
	local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
	return b, c, e
end


replaceColorText = function(text)
    text = text:gsub("~r~", "<span class='red'>") 
    text = text:gsub("~b~", "<span class='blue'>")
    text = text:gsub("~g~", "<span class='green'>")
    text = text:gsub("~y~", "<span class='yellow'>")
    text = text:gsub("~p~", "<span class='purple'>")
    text = text:gsub("~c~", "<span class='grey'>")
    text = text:gsub("~m~", "<span class='darkgrey'>")
    text = text:gsub("~u~", "<span class='black'>")
    text = text:gsub("~o~", "<span class='gold'>")
    text = text:gsub("~s~", "</span>")
    text = text:gsub("~w~", "</span>")
    text = text:gsub("~b~", "<b>")
    text = text:gsub("~n~", "<br>")
    text = "<span>" .. text .. "</span>"
    return text
end

RotationToDirection = function(rotation)
	local adjustedRotation =
	{
		x = (math.pi / 180) * rotation.x,
		y = (math.pi / 180) * rotation.y,
		z = (math.pi / 180) * rotation.z
	}
	local direction =
	{
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		z = math.sin(adjustedRotation.x)
	}
	return direction
end
