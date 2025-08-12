local ESX = exports["es_extended"]:getSharedObject()
local cruiseControl = {
    enabled = false,
    speed = 0
}

local function isVehicleBlacklisted(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)
    plate = string.gsub(plate, "^%s*(.-)%s*$", "%1")
    
    for _, blacklistedPlate in ipairs(Config.BlacklistedPlates) do
        if string.upper(plate) == string.upper(blacklistedPlate) then
            return true
        end
    end
    
    local vehicleClass = GetVehicleClass(vehicle)
    for _, blacklistedClass in ipairs(Config.BlacklistedVehicleClasses) do
        if vehicleClass == blacklistedClass then
            return true
        end
    end
    
    local vehicleModel = GetEntityModel(vehicle)
    for _, blacklistedModel in ipairs(Config.BlacklistedVehicleModels) do
        if vehicleModel == GetHashKey(blacklistedModel) then
            return true
        end
    end
    
    return false
end

local function isVehicleReversing(vehicle)
    return GetEntitySpeedVector(vehicle, true).y < -0.1
end

local function disableCruiseControl()
    if cruiseControl.enabled then
        cruiseControl.enabled = false
        cruiseControl.speed = 0
        ESX.ShowNotification("Régulateur de vitesse: Désactivé", 2000)
    end
end

local function toggleCruiseControl(vehicle)
    if isVehicleBlacklisted(vehicle) then
        ESX.ShowNotification("Le régulateur de vitesse ne fonctionne pas sur ce véhicule", 2000)
        return
    end
    
    if isVehicleReversing(vehicle) then
        ESX.ShowNotification("Le régulateur ne peut pas être activé en marche arrière", 2000)
        return
    end
    
    if not cruiseControl.enabled then
        local speed = GetEntitySpeed(vehicle)
        local minSpeedMs = Config.MinActivationSpeed / 3.6
        if speed > minSpeedMs then
            cruiseControl.enabled = true
            cruiseControl.speed = speed
            ESX.ShowNotification("Régulateur de vitesse: Activé à " .. math.floor(cruiseControl.speed * 3.6) .. " km/h", 2000)
        else
            ESX.ShowNotification("Vitesse trop basse pour activer le régulateur (minimum " .. Config.MinActivationSpeed .. " km/h)", 5000)
        end
    else
        disableCruiseControl()
    end
end

local function checkVehicleState()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if not vehicle or not DoesEntityExist(vehicle) or GetPedInVehicleSeat(vehicle, -1) ~= playerPed then
        return false
    end
    
    local roll = GetEntityRoll(vehicle)
    if math.abs(roll) > 20.0 then
        return false
    end
    
    if HasEntityCollidedWithAnything(vehicle) then
        return false
    end
    
    if not IsVehicleOnAllWheels(vehicle) then
        return false
    end
    
    if isVehicleReversing(vehicle) then
        return false
    end
    
    return true
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        
        if vehicle and DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == playerPed then
            if IsControlJustPressed(0, Config.DefaultKey) then
                toggleCruiseControl(vehicle)
            end
            
            if cruiseControl.enabled and (IsControlPressed(0, 72) or IsControlPressed(0, 76) or IsControlPressed(0, 75)) then
                disableCruiseControl()
            end
            
            if cruiseControl.enabled then
                if not checkVehicleState() then
                    disableCruiseControl()
                    Citizen.Wait(500)
                else
                    if not IsControlPressed(0, 71) then
                        local currentSpeed = GetEntitySpeed(vehicle)
                        if currentSpeed < (cruiseControl.speed - 0.5) then
                            SetVehicleForwardSpeed(vehicle, cruiseControl.speed)
                        end
                    end
                end
            end
        elseif cruiseControl.enabled then
            disableCruiseControl()
        end
    end
end)

RegisterCommand('+cruisecontrol', function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle and DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == playerPed then
        toggleCruiseControl(vehicle)
    end
end)

RegisterCommand('-cruisecontrol', function()
end)

RegisterKeyMapping('+cruisecontrol', 'Activer/Désactiver le régulateur de vitesse', 'keyboard', 'NUMPADENTER')
