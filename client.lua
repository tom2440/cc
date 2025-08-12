local ESX = exports["es_extended"]:getSharedObject()
local cruiseControl = {
    enabled = false,
    speed = 0
}

local function isVehicleBlacklisted(vehicle)
    -- Vérifier la plaque d'immatriculation
    local plate = GetVehicleNumberPlateText(vehicle)
    plate = string.gsub(plate, "^%s*(.-)%s*$", "%1") -- Supprimer les espaces
    
    for _, blacklistedPlate in ipairs(Config.BlacklistedPlates) do
        if string.upper(plate) == string.upper(blacklistedPlate) then
            return true
        end
    end
    
    -- Vérifier la classe du véhicule
    local vehicleClass = GetVehicleClass(vehicle)
    
    for _, blacklistedClass in ipairs(Config.BlacklistedVehicleClasses) do
        if vehicleClass == blacklistedClass then
            return true
        end
    end
    
    -- Vérifier le modèle du véhicule
    local vehicleModel = GetEntityModel(vehicle)
    
    for _, blacklistedModel in ipairs(Config.BlacklistedVehicleModels) do
        if vehicleModel == GetHashKey(blacklistedModel) then
            return true
        end
    end
    
    return false
end

-- Fonction pour vérifier si le véhicule est en marche arrière
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

-- Fonction commune pour activer/désactiver le régulateur
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
        local minSpeedMs = Config.MinActivationSpeed / 3.6 -- Conversion km/h -> m/s
        
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
    
    -- Vérifier si le véhicule est trop incliné
    local roll = GetEntityRoll(vehicle)
    if math.abs(roll) > 20.0 then
        return false
    end
    
    -- Vérifier si le véhicule a récemment heurté quelque chose
    if HasEntityCollidedWithAnything(vehicle) then
        return false
    end
    
    -- Vérifier si le véhicule est en l'air
    if not IsVehicleOnAllWheels(vehicle) then
        return false
    end
    
    -- Vérifier si le véhicule est en marche arrière
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
            -- Activation/désactivation avec la touche configurée
            if IsControlJustPressed(0, Config.DefaultKey) then
                toggleCruiseControl(vehicle)
            end
            
            -- Désactiver si le joueur freine, utilise le frein à main ou appuie sur F (touche 75)
            if cruiseControl.enabled and (IsControlPressed(0, 72) or IsControlPressed(0, 76) or IsControlPressed(0, 75)) then
                disableCruiseControl()
            end
            
            -- Maintenir la vitesse si le régulateur est activé
            if cruiseControl.enabled then
                if not checkVehicleState() then
                    disableCruiseControl()
                    Citizen.Wait(500) -- Ajouter un délai pour éviter les désactivations répétées
                else
                    -- Gestion de l'accélération temporaire
                    if IsControlPressed(0, 71) then
                        -- Laisser le joueur accélérer au-delà de la vitesse de croisière
                    else
                        local currentSpeed = GetEntitySpeed(vehicle)
                        -- Si la vitesse actuelle est trop différente de la vitesse de croisière (sauf accélération)
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

-- Permet de configurer la touche via le menu des raccourcis de FiveM
RegisterCommand('+cruisecontrol', function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle and DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == playerPed then
        toggleCruiseControl(vehicle)
    end
end)

RegisterCommand('-cruisecontrol', function()
    -- Cette fonction est nécessaire pour l'enregistrement de la commande mais ne fait rien
end)

RegisterKeyMapping('+cruisecontrol', 'Activer/Désactiver le régulateur de vitesse', 'keyboard', 'NUMPADENTER')