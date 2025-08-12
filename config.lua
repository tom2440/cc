Config = {}

-- Vitesse minimale pour activer le régulateur (en km/h)
Config.MinActivationSpeed = 30

-- Touche par défaut pour activer/désactiver le régulateur (117 = Touche Entrée du pavé numérique)
Config.DefaultKey = 117

-- Liste noire des plaques d'immatriculation
Config.BlacklistedPlates = {
    --"RALLY",
}

-- Liste noire des types de véhicules (classes)
Config.BlacklistedVehicleClasses = {
    8,  -- Motos
    13, -- Vélos
    14, -- Bateaux
    15, -- Hélicoptères
    16, -- Avions
    21  -- Trains
}

-- Liste noire des modèles de véhicules
Config.BlacklistedVehicleModels = {
    --"deluxo",
}