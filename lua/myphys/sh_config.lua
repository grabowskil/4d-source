-- Gemeinsame Konfiguration (shared). Wird bei jedem Refresh neu gesetzt, damit Änderungen sofort greifen.
MyPhys = MyPhys or {}

MyPhys.Config = {
    Gravity = {
        Default = -600,
        Min = -3000,
        Max = 3000,
    },

    -- Mindestabstand zwischen zwei net-Requests desselben Spielers (Sekunden)
    NetCooldown = 0.5,

    -- myphys_float: eigener Auftrieb, weil SetBuoyancyRatio auf x86-64/macOS fehlt
    Float = {
        Lift = 1.3,         -- Vielfaches der Gewichtskraft unter Wasser
        Drag = 0.8,         -- Wasserwiderstand pro Masseneinheit
        MaxForce = 200000,  -- harte Obergrenze gegen Physik-Explosionen
    },

    Tuner = {
        MinMass = 0.1,      -- seit Sept.-2026-Update Engine-Minimum für SetMass
        MaxMass = 50000,
        MaxDamping = 100,
    },
}

MyPhys.Net = {
    SetGravity = "myphys_set_gravity",
}
