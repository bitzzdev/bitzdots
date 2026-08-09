hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "catppuccin-mocha-dark-cursors")
-- Do NOT set QT_STYLE_OVERRIDE: it overrides qt6ct and forces the light
-- Breeze style, breaking the dark theme. qt6ct applies Breeze-Dark + palette
-- via QT_QPA_PLATFORMTHEME=qt6ct (see environment.d/qt.conf).
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
