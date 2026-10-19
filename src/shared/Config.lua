--!strict
-- Test balance only. No Robux or commerce integrations.
return {
    Version = "0.1.0",
    Locale = "ko",
    StudioPersistence = false, -- Explicit opt-in; separate Studio datastore namespace.
    StudioDebug = true, -- Also gated by RunService:IsStudio() on the server.
    DataStoreName = "FILAMENT_Fishing_v1",
    SchemaVersion = 1,
    StartingCoins = 100,
    InventoryLimit = 200,
    SaveAttempts = 3,
    LeaseSeconds = 180,
    RenewSeconds = 40,
    StationRadius = 18,
    Fishing = {
        ChargeSeconds = 1.8,
        MinDistance = 8,
        MaxDistance = 38,
        FlightSeconds = 0.7,
        BiteMin = 3,
        BiteMax = 7,
        ProgressPerSecond = 0.17,
        ResistanceAt = 0.5,
        ResistanceSeconds = 4,
        ResistanceTaps = 9,
        MinTapInterval = 0.075,
        HoldLease = 0.5,
        SessionTimeout = 45,
        MaxChargeSeconds = 8,
        Cooldown = 1,
        DockX = 0, DockZ = 19, DockHalfX = 7, DockHalfZ = 15,
        PondZ = -4, WaterY = 0.2,
    },
    CatchTable = {
        {id = "silver", weight = 55},
        {id = "sunny", weight = 28},
        {id = "azure", weight = 12},
        {id = "tideEgg", weight = 5},
    },
    HatchSeconds = 60,
    Feed = {
        none = {duration = 60, rare = 0, legendary = 0},
        basic = {duration = 50, rare = 5, legendary = 0.5},
        premium = {duration = 40, rare = 12, legendary = 1.5},
    },
    -- Rarity rolls use these weights, not percentages added after normalization.
    HatchWeights = {common = 90, rare = 9, legendary = 1},
    HatchLevelBonus = {rare = 5, legendary = 1},
    HatchTimeBonus = {rare = 4, legendary = 0.5}, -- full 60s incubation vs sped-up egg
    Aquarium = {
        {capacity = 4, nextCost = 100},
        {capacity = 7, nextCost = 250},
        {capacity = 10, nextCost = 0},
    },
}
