local DEBUG = false

local PREFIX = "[WeaponGlamLua]"
local LOG_CANDIDATES = {
    "ue4ss/Mods/WeaponGlamLua/weaponglamlua.log",
    "Mods/WeaponGlamLua/weaponglamlua.log",
    "weaponglamlua.log",
}
local log_path = nil
local log_broken = false

local PANEL_CLASS = "/Game/UI/Widgets/InGame_Menu/WeaponPanel/WBP_Panel_Weapon.WBP_Panel_Weapon_C"
local LIST_CLASS = "/Game/UI/Widgets/InGame_Menu/WeaponPanel/WBP_WeaponsList.WBP_WeaponsList_C"
local HIDE_TOOLTIP_EVT = PANEL_CLASS
    .. ":BndEvt__WBP_Panel_Weapon_WBP_CommonBoundActionButton_HideTooltip_K2Node_ComponentBoundEvent_0_CommonButtonBaseClicked__DelegateSignature"
local NAVIGATE_EVT = PANEL_CLASS
    .. ":BndEvt__WBP_Panel_Weapon_WeaponsList_K2Node_ComponentBoundEvent_1_OnWeaponItemNavigated__DelegateSignature"
local ELEMENT_CLASS =
    "/Game/UI/Widgets/InGame_Menu/WeaponPanel/WBP_Panel_WeaponElement.WBP_Panel_WeaponElement_C"
local SHOW_TOOLTIP = LIST_CLASS .. ":ShowWeaponTooltip"
local LIST_ITEM_SET = ELEMENT_CLASS .. ":OnListItemObjectSet"
local PANEL_DEACT = PANEL_CLASS .. ":BP_OnDeactivated"
local PANEL_ACT = PANEL_CLASS .. ":BP_OnActivated"
local REBUILD_EVT = PANEL_CLASS .. ":RebuildActionBarButtons"
local LABEL_EQUIP = "Equip Weapon Skin"
local LABEL_REMOVE = "Remove Weapon Skin"
local LABEL_RETAIL = "Hide Tooltip"
local MENU_CLASS = "/Game/Gameplay/GameMenu/BP_GameMenuScene.BP_GameMenuScene_C"
local CINE_CLASS = "/Game/Characters/Heros/Cinematics/BP_CineCharacter_Main.BP_CineCharacter_Main_C"
local BATTLE_CLASS =
    "/Game/jRPGTemplate/Blueprints/Basics/BP_jRPG_Character_Battle_Base.BP_jRPG_Character_Battle_Base_C"
local BATTLE_SPAWN = BATTLE_CLASS .. ":SpawnWeaponAndSetSkin"
local CLIENT_RESTART = "/Script/Engine.PlayerController:ClientRestart"
local BATTLE_READY =
    "/Game/jRPGTemplate/Blueprints/Components/AC_jRPG_BattleManager.AC_jRPG_BattleManager_C:OnBattleDependenciesFullyLoaded"
local VIS_COLLAPSED = 1
local VIS_SHOWN = 4
local KTEXT_CDO = "/Script/Engine.Default__KismetTextLibrary"
local GS_CDO = "/Script/Engine.Default__GameplayStatics"
local UIHELPERS_CDO = "/Game/UI/FL_UIHelpers.Default__FL_UIHelpers_C"
local EQUIP_SOUND_PATH =
    "/Game/Audio/MetaSound/SFX/UI/RestMenu/SFX_UI_RestMenu_Skill_Equip.SFX_UI_RestMenu_Skill_Equip"
local HIDE_ACTION_ROW = "CommonUI_GameMenu_HideTooltip"
local APPLY_DELAY_MS = 0
local RESOLVE_RETRY_MS = 0

-- Regenerate rather than hand edit; an item missing here must never reach GetAsset, which
-- crashes on a package that doesnt exist
local SKIN_CLASS = {
    ["03_Weapon_Placeholder"] = "/Game/Characters/Weapons/BP_WeaponSkin_Maelle_Base.BP_WeaponSkin_Maelle_Base_C",
    Abysseram = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Abysseram.BP_WeaponSkin_Noah_Abysseram_C",
    Algueron = "/Game/Characters/Weapons/Sciel/BP_WeaponSkin_Sciel_Algueron.BP_WeaponSkin_Sciel_Algueron_C",
    Angerim = "/Game/Characters/Weapons/Lune/BP_WeaponSkin_Lune_Angerim.BP_WeaponSkin_Lune_Angerim_C",
    Baguettaro = "/Game/Characters/Weapons/Monoco/BP_WeaponSkin_Monoco_Baguette.BP_WeaponSkin_Monoco_Baguette_C",
    Battlum = "/Game/Characters/Weapons/Maelle/BP_WeaponSkin_Maelle_Battlum.BP_WeaponSkin_Maelle_Battlum_C",
    Benisim = "/Game/Characters/Weapons/Lune/BP_WeaponSkin_Lune_Benisim.BP_WeaponSkin_Lune_Benisim_C",
    Betelim = "/Game/Characters/Weapons/Lune/BP_WeaponSkin_Lune_Betelim.BP_WeaponSkin_Lune_Betelim_C",
    Blizzon = "/Game/Characters/Weapons/Sciel/BP_WeaponSkin_Sciel_Blizzon.BP_WeaponSkin_Sciel_Blizzon_C",
    Blodam = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Blodam.BP_WeaponSkin_Noah_Blodam_C",
    Boucharo = "/Game/Characters/Weapons/Monoco/BP_WeaponSkin_Monoco_Chapelim.BP_WeaponSkin_Monoco_Chapelim_C",
    Bourgelon = "/Game/Characters/Weapons/Sciel/BP_WeaponSkin_Sciel_Bourgelon.BP_WeaponSkin_Sciel_Bourgelon_C",
    Braselim = "/Game/Characters/Weapons/Lune/BP_WeaponSkin_Lune_Braselim.BP_WeaponSkin_Lune_Braselim_C",
    Brulerum = "/Game/Characters/Weapons/Maelle/BP_WeaponSkin_Maelle_Brulerum.BP_WeaponSkin_Maelle_Brulerum_C",
    Brumaro = "/Game/Characters/Weapons/Monoco/BP_WeaponSkin_Monoco_Brumaro.BP_WeaponSkin_Monoco_Brumaro_C",
    Chainebum = "/Game/Characters/Weapons/Maelle/BP_WeaponSkin_Maelle_BarrierBreaker.BP_WeaponSkin_Maelle_BarrierBreaker_C",
    Chaliso = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Dualim.BP_WeaponSkin_Noah_Dualim_C",
    Chapelim = "/Game/Characters/Weapons/Lune/BP_WeaponSkin_Lune_Boucharo.BP_WeaponSkin_Lune_Boucharo_C",
    Charnon = "/Game/Characters/Weapons/Sciel/BP_WeaponSkin_Sciel_Charnon.BP_WeaponSkin_Sciel_Charnon_C",
    Chation = "/Game/Characters/Weapons/Sciel/BP_WeaponSkin_Sciel_Chation.BP_WeaponSkin_Sciel_Chation_C",
    Chevalam = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Chevalam.BP_WeaponSkin_Noah_Chevalam_C",
    Chromaro = "/Game/Characters/Weapons/Monoco/BP_WeaponSkin_Monoco_Chromaro.BP_WeaponSkin_Monoco_Chromaro_C",
    Clierum = "/Game/Characters/Weapons/Maelle/BP_WeaponSkin_Maelle_Clierum.BP_WeaponSkin_Maelle_Clierum_C",
    Coldum = "/Game/Characters/Weapons/Maelle/BP_WeaponSkin_Maelle_Coldum.BP_WeaponSkin_Maelle_Coldum_C",
    Confuso = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Confuso.BP_WeaponSkin_Noah_Confuso_C",
    Contorson = "/Game/Characters/Weapons/Sciel/BP_WeaponSkin_Sciel_Moissoso.BP_WeaponSkin_Sciel_Moissoso_C",
    Coralim = "/Game/Characters/Weapons/Lune/BP_WeaponSkin_Lune_Coralim.BP_WeaponSkin_Lune_Coralim_C",
    Corderon = "/Game/Characters/Weapons/Sciel/BP_WeaponSkin_Sciel_Corderon.BP_WeaponSkin_Sciel_Corderon_C",
    Corpeso = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Corpeso.BP_WeaponSkin_Noah_Corpeso_C",
    Cruleram = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Cruleram.BP_WeaponSkin_Noah_Cruleram_C",
    Cultam = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Cultam.BP_WeaponSkin_Noah_Cultam_C",
    Danseso = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Danseso.BP_WeaponSkin_Noah_Danseso_C",
    DebugLune = "/Game/Characters/Weapons/Lune/BP_WeaponSkin_Lune_Debug.BP_WeaponSkin_Lune_Debug_C",
    DebugMaelle = "/Game/Characters/Weapons/Maelle/BP_WeaponSkin_Maelle_Debug.BP_WeaponSkin_Maelle_Debug_C",
    DebugMonoco = "/Game/Characters/Weapons/Monoco/BP_WeaponSkin_Monoco_Debug.BP_WeaponSkin_Monoco_Debug_C",
    DebugSciel = "/Game/Characters/Weapons/Sciel/BP_WeaponSkin_Sciel_Debug.BP_WeaponSkin_Sciel_Debug_C",
    DebugVerso = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Debug.BP_WeaponSkin_Noah_Debug_C",
    Delaram = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Delaram.BP_WeaponSkin_Noah_Delaram_C",
    Deminerim = "/Game/Characters/Weapons/Lune/BP_WeaponSkin_Lune_Deminerim.BP_WeaponSkin_Lune_Deminerim_C",
    Demonam = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Demonam.BP_WeaponSkin_Noah_Demonam_C",
    Direton = "/Game/Characters/Weapons/Sciel/BP_WeaponSkin_Sciel_Direton.BP_WeaponSkin_Sciel_Direton_C",
    Dualim = "/Game/Characters/Weapons/Lune/BP_WeaponSkin_Lune_Troubadum.BP_WeaponSkin_Lune_Troubadum_C",
    Duenum = "/Game/Characters/Weapons/Maelle/BP_WeaponSkin_Maelle_Duenum.BP_WeaponSkin_Maelle_Duenum_C",
    Duollison = "/Game/Characters/Weapons/Sciel/BP_WeaponSkin_Sciel_Duollison.BP_WeaponSkin_Sciel_Duollison_C",
    Elerim = "/Game/Characters/Weapons/Lune/BP_WeaponSkin_Lune_Elerim.BP_WeaponSkin_Lune_Elerim_C",
    Facesum = "/Game/Characters/Weapons/Maelle/BP_WeaponSkin_Maelle_Facesum.BP_WeaponSkin_Maelle_Facesum_C",
    GDC_Weapon_Lune = "/Game/Characters/Weapons/BP_WeaponSkin_Lune_Base.BP_WeaponSkin_Lune_Base_C",
    GDC_Weapon_Maelle = "/Game/Characters/Weapons/BP_WeaponSkin_Maelle_Base.BP_WeaponSkin_Maelle_Base_C",
    GDC_Weapon_Monoco = "/Game/Characters/Weapons/BP_WeaponSkin_Monoco_Base.BP_WeaponSkin_Monoco_Base_C",
    GDC_Weapon_Sciel = "/Game/Characters/Weapons/BP_WeaponSkin_Sciel_Base.BP_WeaponSkin_Sciel_Base_C",
    GDC_Weapon_Verso = "/Game/Characters/Weapons/BP_WeaponSkin_Noah_Base.BP_WeaponSkin_Noah_Base_C",
    Garganon = "/Game/Characters/Weapons/Sciel/BP_WeaponSkin_Sciel_Garganon.BP_WeaponSkin_Sciel_Garganon_C",
    Gaulteram = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Gaulteram.BP_WeaponSkin_Noah_Gaulteram_C",
    Gelerim = "/Game/Characters/Weapons/BP_WeaponSkin_Lune_Base.BP_WeaponSkin_Lune_Base_C",
    Gesam = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Gesam.BP_WeaponSkin_Noah_Gesam_C",
    Glaceso = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Glaceso.BP_WeaponSkin_Noah_Glaceso_C",
    Glaisum = "/Game/Characters/Weapons/Maelle/BP_WeaponSkin_Maelle_Glaisum.BP_WeaponSkin_Maelle_Glaisum_C",
    Gobluson = "/Game/Characters/Weapons/Sciel/BP_WeaponSkin_Sciel_Gobluson.BP_WeaponSkin_Sciel_Gobluson_C",
    Grandaro = "/Game/Characters/Weapons/Monoco/BP_WeaponSkin_Monoco_Grandaro.BP_WeaponSkin_Monoco_Grandaro_C",
    Hevason = "/Game/Characters/Weapons/Sciel/BP_WeaponSkin_Sciel_Hevason.BP_WeaponSkin_Sciel_Hevason_C",
    Jarum = "/Game/Characters/Weapons/Maelle/BP_WeaponSkin_Maelle_Jarum.BP_WeaponSkin_Maelle_Jarum_C",
    Joyaro = "/Game/Characters/Weapons/Monoco/BP_WeaponSkin_Monoco_Joyaro.BP_WeaponSkin_Monoco_Joyaro_C",
    Lanceram = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Lanceram.BP_WeaponSkin_Noah_Lanceram_C",
    Lighterim = "/Game/Characters/Weapons/Lune/BP_WeaponSkin_Lune_Lighterim.BP_WeaponSkin_Lune_Lighterim_C",
    Lunerim = "/Game/Characters/Weapons/Lune/BP_WeaponSkin_Lune_Lunerim.BP_WeaponSkin_Lune_Lunerim_C",
    Lusteson = "/Game/Characters/Weapons/Sciel/BP_WeaponSkin_Sciel_Lusteson.BP_WeaponSkin_Sciel_Lusteson_C",
    Maellum = "/Game/Characters/Weapons/Maelle/BP_WeaponSkin_Maelle_Maellum.BP_WeaponSkin_Maelle_Maellum_C",
    Medalum = "/Game/Characters/Weapons/Maelle/BP_WeaponSkin_Maelle_Medalum.BP_WeaponSkin_Maelle_Medalum_C",
    Melarum = "/Game/Characters/Weapons/Maelle/BP_WeaponSkin_Maelle_Melarum.BP_WeaponSkin_Maelle_Melarum_C",
    Minason = "/Game/Characters/Weapons/Sciel/BP_WeaponSkin_Sciel_Minason.BP_WeaponSkin_Sciel_Minason_C",
    MitigatedPerfection = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Gun_Velokan.BP_WeaponSkin_Noah_Gun_Velokan_C",
    Moissoso = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Contorson.BP_WeaponSkin_Noah_Contorson_C",
    Monocaro = "/Game/Characters/Weapons/BP_WeaponSkin_Monoco_Base.BP_WeaponSkin_Monoco_Base_C",
    Nibalum = "/Game/Characters/Weapons/BP_WeaponSkin_Maelle_Base.BP_WeaponSkin_Maelle_Base_C",
    Noahram = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Noahram.BP_WeaponSkin_Noah_Noahram_C",
    Nosaram = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Nosaram.BP_WeaponSkin_Noah_Nosaram_C",
    Painerim = "/Game/Characters/Weapons/Lune/BP_WeaponSkin_Lune_Painerim.BP_WeaponSkin_Lune_Painerim_C",
    Potierim = "/Game/Characters/Weapons/Lune/BP_WeaponSkin_Lune_Potierim.BP_WeaponSkin_Lune_Potierim_C",
    Ramasson = "/Game/Characters/Weapons/Sciel/BP_WeaponSkin_Sciel_Ramasson.BP_WeaponSkin_Sciel_Ramasson_C",
    Rangeson = "/Game/Characters/Weapons/Sciel/BP_WeaponSkin_Sciel_Rangeson.BP_WeaponSkin_Sciel_Rangeson_C",
    Reacharo_1 = "/Game/Characters/Weapons/Monoco/BP_WeaponSkin_Monoco_Reachearo_1.BP_WeaponSkin_Monoco_Reachearo_1_C",
    Reacharo_2 = "/Game/Characters/Weapons/Monoco/BP_WeaponSkin_Monoco_Reacharo_2.BP_WeaponSkin_Monoco_Reacharo_2_C",
    Reacherim_1 = "/Game/Characters/Weapons/Lune/BP_WeaponSkin_Lune_Reacherim_1.BP_WeaponSkin_Lune_Reacherim_1_C",
    Reacherim_2 = "/Game/Characters/Weapons/Lune/BP_WeaponSkin_Lune_Reacherim.BP_WeaponSkin_Lune_Reacherim_C",
    Reacheron_1 = "/Game/Characters/Weapons/Sciel/BP_WeaponSkin_Sciel_Reacheron_1.BP_WeaponSkin_Sciel_Reacheron_1_C",
    Reacheron_2 = "/Game/Characters/Weapons/Sciel/BP_WeaponSkin_Sciel_Reacheron_2.BP_WeaponSkin_Sciel_Reacheron_2_C",
    Reacheso_1 = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Reacheso_2.BP_WeaponSkin_Noah_Reacheso_2_C",
    Reacheso_2 = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Reacheso_1.BP_WeaponSkin_Noah_Reacheso_1_C",
    Reachum_1 = "/Game/Characters/Weapons/Maelle/BP_WeaponSkin_Maelle_Reachum_1.BP_WeaponSkin_Maelle_Reachum_1_C",
    Reachum_2 = "/Game/Characters/Weapons/Maelle/BP_WeaponSkin_Maelle_Reachum_2.BP_WeaponSkin_Maelle_Reachum_2_C",
    Redalim = "/Game/Characters/Weapons/Lune/BP_WeaponSkin_Lune_Redalim.BP_WeaponSkin_Lune_Redalim_C",
    Sadon = "/Game/Characters/Weapons/Sciel/BP_WeaponSkin_Sciel_Sadon.BP_WeaponSkin_Sciel_Sadon_C",
    Sakaram = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Sakaram.BP_WeaponSkin_Noah_Sakaram_C",
    Saperim = "/Game/Characters/Weapons/Lune/BP_WeaponSkin_Lune_Saperim.BP_WeaponSkin_Lune_Saperim_C",
    Scaverim = "/Game/Characters/Weapons/Lune/BP_WeaponSkin_Lune_Scaverim.BP_WeaponSkin_Lune_Scaverim_C",
    Scieleson = "/Game/Characters/Weapons/Sciel/BP_WeaponSkin_Sciel_Scieleson.BP_WeaponSkin_Sciel_Scieleson_C",
    Seashelum = "/Game/Characters/Weapons/Maelle/BP_WeaponSkin_Maelle_Seashelum.BP_WeaponSkin_Maelle_Seashelum_C",
    Seeram = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Seeram.BP_WeaponSkin_Noah_Seeram_C",
    Sekarum = "/Game/Characters/Weapons/Maelle/BP_WeaponSkin_Maelle_Sekarum.BP_WeaponSkin_Maelle_Sekarum_C",
    Sidaro = "/Game/Characters/Weapons/Monoco/BP_WeaponSkin_Monoco_Sidaro_TwilightSanctuary.BP_WeaponSkin_Monoco_Sidaro_TwilightSanctuary_C",
    Simonim = "/Game/Characters/Weapons/Lune/BP_WeaponSkin_Lune_Simonim.BP_WeaponSkin_Lune_Simonim_C",
    Simoso = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Simon.BP_WeaponSkin_Noah_Simon_C",
    Sirenaro_1 = "/Game/Characters/Weapons/Monoco/BP_WeaponSkin_Monoco_Sirenaro_1.BP_WeaponSkin_Monoco_Sirenaro_1_C",
    Sirenaro_2 = "/Game/Characters/Weapons/Monoco/BP_WeaponSkin_Monoco_Sirenaro_2.BP_WeaponSkin_Monoco_Sirenaro_2_C",
    Sirenim_1 = "/Game/Characters/Weapons/Lune/BP_WeaponSkin_Lune_Sirenim_1.BP_WeaponSkin_Lune_Sirenim_1_C",
    Sirenim_2 = "/Game/Characters/Weapons/Lune/BP_WeaponSkin_Lune_Sirenim_2.BP_WeaponSkin_Lune_Sirenim_2_C",
    Sirenon_1 = "/Game/Characters/Weapons/Sciel/BP_WeaponSkin_Sciel_Sirenon_1.BP_WeaponSkin_Sciel_Sirenon_1_C",
    Sirenon_2 = "/Game/Characters/Weapons/Sciel/BP_WeaponSkin_Sciel_Sirenon_2.BP_WeaponSkin_Sciel_Sirenon_2_C",
    Sirenum_1 = "/Game/Characters/Weapons/Maelle/BP_WeaponSkin_Maelle_Sirenum_1.BP_WeaponSkin_Maelle_Sirenum_1_C",
    Sirenum_2 = "/Game/Characters/Weapons/Maelle/BP_WeaponSkin_Maelle_Sirenum_2.BP_WeaponSkin_Maelle_Sirenum_2_C",
    Sireso_1 = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Sireso_1.BP_WeaponSkin_Noah_Sireso_1_C",
    Sireso_2 = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Sireso_2.BP_WeaponSkin_Noah_Sireso_2_C",
    Snowim = "/Game/Characters/Weapons/Lune/BP_WeaponSkin_Lune_Snowim.BP_WeaponSkin_Lune_Snowim_C",
    Stalum = "/Game/Characters/Weapons/Maelle/BP_WeaponSkin_Maelle_Stalum.BP_WeaponSkin_Maelle_Stalum_C",
    Trebuchim = "/Game/Characters/Weapons/Lune/BP_WeaponSkin_Lune_Trebuchim.BP_WeaponSkin_Lune_Trebuchim_C",
    Troubadum = "/Game/Characters/Weapons/Maelle/BP_WeaponSkin_Maelle_Chaliso.BP_WeaponSkin_Maelle_Chaliso_C",
    VD_Lune_1 = "/Game/Characters/Weapons/Lune/BP_WeaponSkin_Lune_Candy.BP_WeaponSkin_Lune_Candy_C",
    VD_Lune_2 = "/Game/Characters/Weapons/Lune/BP_WeaponSkin_Lune_Esquie.BP_WeaponSkin_Lune_Esquie_C",
    VD_Maelle_1 = "/Game/Characters/Weapons/Maelle/BP_WeaponSkin_Maelle_Candy.BP_WeaponSkin_Maelle_Candy_C",
    VD_Maelle_2 = "/Game/Characters/Weapons/Maelle/BP_WeaponSkin_Maelle_Esquie.BP_WeaponSkin_Maelle_Esquie_C",
    VD_Monoco_1 = "/Game/Characters/Weapons/Monoco/BP_WeaponSkin_Monoco_Candy.BP_WeaponSkin_Monoco_Candy_C",
    VD_Monoco_2 = "/Game/Characters/Weapons/Monoco/BP_WeaponSkin_Monoco_Esquie.BP_WeaponSkin_Monoco_Esquie_C",
    VD_Sciel_1 = "/Game/Characters/Weapons/Sciel/BP_WeaponSkin_Sciel_Candy.BP_WeaponSkin_Sciel_Candy_C",
    VD_Sciel_2 = "/Game/Characters/Weapons/Sciel/BP_WeaponSkin_Sciel_Esquie.BP_WeaponSkin_Sciel_Esquie_C",
    VD_Verso_1 = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Candy.BP_WeaponSkin_Noah_Candy_C",
    VD_Verso_2 = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Esquie.BP_WeaponSkin_Noah_Esquie_C",
    VD_Verso_3 = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Esquie.BP_WeaponSkin_Noah_Esquie_C",
    Velokan = "/Game/Characters/Weapons/Noah/BP_WeaponSkin_Noah_Gun_Velokan.BP_WeaponSkin_Noah_Gun_Velokan_C",
    Veremum = "/Game/Characters/Weapons/Maelle/BP_WeaponSkin_Maelle_Veremum.BP_WeaponSkin_Maelle_Veremum_C",
    Verleso = "/Game/Characters/Weapons/BP_WeaponSkin_Noah_Base.BP_WeaponSkin_Noah_Base_C",
    Volesterum = "/Game/Characters/Weapons/Maelle/BP_WeaponSkin_Maelle_Volesterum.BP_WeaponSkin_Maelle_Volesterum_C",
    Yeverum = "/Game/Characters/Weapons/Maelle/BP_WeaponSkin_Maelle_Yeverum.BP_WeaponSkin_Maelle_Yeverum_C",
}

local ITEM_STATIC = "ItemStaticData_9_59CF465348F5D7696BDFE68CB4071486"
local ITEM_NAME = "Item_HardcodedName_90_C7F763B74AAB28EF890A66854D7D95AA"

local SLOT_BY_CHAR = {
    Frey = "ChildActor_Gustave",
    Maelle = "ChildActor_Maelle",
    Lune = "ChildActor_Lune",
    Sciel = "ChildActor_Sciel",
    Verso = "ChildActor_Verso",
    Monoco = "ChildActor_Monoco",
}

local CINE_NEEDLES = {
    { "BP_GameMenu_Maelle_C", "Maelle" },
    { "BP_GameMenu_Lune_C", "Lune" },
    { "BP_GameMenu_Sciel_C", "Sciel" },
    { "BP_GameMenu_Verso_C", "Verso" },
    { "BP_GameMenu_Monoco_C", "Monoco" },
    { "BP_GameMenu_Noah_C", "Frey" },
}

local BATTLE_NEEDLES = {
    { "BP_Maelle_Battle_C", "Maelle" },
    { "BP_Lune_Battle_C", "Lune" },
    { "BP_Sciel_Battle_C", "Sciel" },
    { "BP_Verso_Battle2_C", "Verso" },
    { "BP_Verso_Battle_C", "Verso" },
    { "BP_Monoco_Battle_C", "Monoco" },
    { "BP_Noah_Battle_C", "Frey" },
    { "BP_Gustave_Battle_C", "Frey" },
}

local last = {
    char = nil,
    item = nil,
    hide_n = 0,
    nav_n = 0,
    spawn_n = 0,
    skin_n = 0,
    battle_n = 0,
}
local glam = {}
-- item id -> { cls_path }. A resolved skin class path, not the UClass: a cached UClass goes
-- stale when its package unloads
local class_cache = {}
local apply_ok = {}
local equipped_path = {}
local last_scene = nil
local last_panel = nil
local retry_pending = {}
local tooltip_suppressed = false
local tooltip_hide_n = 0
local retarget_n = 0
local label_n = 0
local last_label = nil
local label_scan_n = 0
local sound_n = 0
local corner_n = 0

local function log_to_file(line)
    if log_broken then
        return
    end
    if log_path == nil then
        for _, cand in ipairs(LOG_CANDIDATES) do
            local ok, f = pcall(io.open, cand, "a")
            if ok and f then
                log_path = cand
                f:flush()
                f:close()
                break
            end
        end
        if log_path == nil then
            log_broken = true
            return
        end
    end
    local ok, f = pcall(io.open, log_path, "a")
    if not ok or f == nil then
        log_broken = true
        return
    end
    f:write(line, "\n")
    f:flush()
    f:close()
end

local function say(msg)
    local line = PREFIX .. " " .. tostring(msg)
    print(line .. "\n")
    if DEBUG then
        log_to_file(line)
    end
end

local function log(msg)
    if not DEBUG then
        return
    end
    say(msg)
end

local function table_dump()
    local bits = {}
    for k, v in pairs(glam) do
        bits[#bits + 1] = tostring(k) .. "=" .. tostring(v)
    end
    if #bits == 0 then
        return "(empty)"
    end
    return table.concat(bits, " ")
end

local function unwrap(param)
    if param == nil then
        return nil
    end
    local ok, val = pcall(function()
        return param:get()
    end)
    if ok and val ~= nil then
        return val
    end
    return param
end

local function is_live(obj)
    if obj == nil then
        return false
    end
    local ok, valid = pcall(function()
        return obj:IsValid()
    end)
    return ok and valid == true
end

local function safe_call(obj, method)
    if not obj then
        return nil
    end
    local ok, result = pcall(function()
        return obj[method](obj)
    end)
    if ok then
        return result
    end
    return nil
end

local function safe_get(obj, prop)
    if obj == nil then
        return nil
    end
    local ok, v = pcall(function()
        return obj[prop]
    end)
    if ok then
        return v
    end
    return nil
end

local function fname_str(obj, prop)
    local v = obj
    if prop ~= nil then
        v = safe_get(obj, prop)
    end
    if v == nil then
        return nil
    end
    if type(v) == "string" then
        return v
    end
    local ts = safe_call(v, "ToString")
    if type(ts) == "string" and ts ~= "" then
        return ts
    end
    local fn = safe_call(v, "GetFName")
    if fn ~= nil then
        local s = safe_call(fn, "ToString")
        if type(s) == "string" and s ~= "" then
            return s
        end
    end
    return nil
end

local function obj_label(obj)
    if not DEBUG then
        return ""
    end
    if not is_live(obj) then
        return "INVALID"
    end
    local full = safe_call(obj, "GetFullName")
    if type(full) == "string" and full ~= "" then
        return full
    end
    return tostring(fname_str(obj, nil) or "?")
end

local function try_find(path)
    if type(StaticFindObject) ~= "function" or type(path) ~= "string" then
        return nil
    end
    local ok, obj = pcall(StaticFindObject, path)
    if ok and is_live(obj) then
        return obj
    end
    return nil
end

-- UClass: live if GetFullName contains /. Never GetFName.
local function as_class(v)
    if v == nil then
        return nil
    end
    local ok, name = pcall(function()
        return v:GetFullName()
    end)
    if ok and type(name) == "string" and name:find("/", 1, true) ~= nil then
        return v
    end
    local ok2, got = pcall(function()
        return v:get()
    end)
    if ok2 and got ~= nil then
        local ok3, n2 = pcall(function()
            return got:GetFullName()
        end)
        if ok3 and type(n2) == "string" and n2:find("/", 1, true) ~= nil then
            return got
        end
    end
    return nil
end

local function class_label(v)
    if not DEBUG then
        return ""
    end
    local cls = as_class(v)
    if cls then
        return obj_label(cls)
    end
    if v == nil then
        return "nil"
    end
    return "unreadable (" .. tostring(v) .. ")"
end

-- Cache the path, not the UClass.
local function class_path_only(v)
    local cls = as_class(v)
    if cls == nil then
        return nil
    end
    local ok, name = pcall(function()
        return cls:GetFullName()
    end)
    if not ok or type(name) ~= "string" then
        return nil
    end
    return name:match("(/Game/.+_C)$") or name:match("(/Game/.+)$")
end

local function remember_equipped(char, cls)
    if not char then
        return
    end
    local path = class_path_only(cls)
    if path then
        equipped_path[char] = path
    end
end

local function item_static(view)
    if not is_live(view) then
        return nil
    end
    local dyn = safe_get(view, "ItemDynamicData")
    local static = safe_get(dyn, ITEM_STATIC) or safe_get(dyn, "ItemStaticData")
    if static == nil then
        static = safe_get(view, ITEM_STATIC) or safe_get(view, "ItemStaticData")
    end
    return static
end

local function item_hardcoded(obj)
    if not is_live(obj) then
        return nil
    end
    local static = item_static(obj)
    local from_static = fname_str(static, ITEM_NAME) or fname_str(static, "Item_HardcodedName")
    if from_static then
        return from_static
    end
    return fname_str(obj, ITEM_NAME) or fname_str(obj, "Item_HardcodedName")
end

local function character_id(panel)
    local char_data = safe_get(panel, "CurrentCharacterData")
    if not is_live(char_data) then
        return nil, char_data
    end
    return fname_str(char_data, "HardcodedNameID"), char_data
end

local function try_find_class(path)
    if type(StaticFindObject) ~= "function" or type(path) ~= "string" then
        return nil
    end
    local ok, obj = pcall(StaticFindObject, path)
    if not ok then
        return nil
    end
    return as_class(obj)
end

local ue_helpers_cached = nil
local ue_helpers_tried = false

local function ue_helpers()
    if not ue_helpers_tried then
        ue_helpers_tried = true
        pcall(function()
            ue_helpers_cached = require("UEHelpers")
        end)
    end
    return ue_helpers_cached
end

-- GetAsset of a missing package crashes.
local function try_asset_registry(package_name, asset_name)
    local helpers = try_find("/Script/AssetRegistry.Default__AssetRegistryHelpers")
    if not helpers then
        return nil
    end
    local uh = ue_helpers()
    if not uh or type(uh.FindOrAddFName) ~= "function" then
        return nil
    end
    local ok, obj = pcall(function()
        local data = {
            ["PackageName"] = uh.FindOrAddFName(package_name),
            ["AssetName"] = uh.FindOrAddFName(asset_name),
        }
        return helpers:GetAsset(data)
    end)
    if not ok then
        log("  GetAsset threw " .. tostring(obj) .. " pkg=" .. tostring(package_name))
        return nil
    end
    return obj
end

local function load_guessed_class(path)
    local pkg, cls = path:match("^(.+)%.(.+)$")
    if not pkg or not cls then
        return nil
    end
    local asset = cls:gsub("_C$", "")
    log("  GetAsset pkg=" .. pkg .. " asset=" .. asset)
    try_asset_registry(pkg, asset)
    local found = try_find_class(path)
    if found then
        return found
    end
    if type(FindFirstOf) == "function" then
        local ok, inst = pcall(FindFirstOf, cls)
        if ok and inst ~= nil then
            local via = as_class(inst)
            if via then
                return via
            end
            local via_g = as_class(safe_call(inst, "GetClass"))
            if via_g then
                return via_g
            end
        end
    end
    return nil
end

local function class_path_of(cls)
    local ok, name = pcall(function()
        return cls:GetFullName()
    end)
    if not ok or type(name) ~= "string" then
        return nil
    end
    return name:match("%s(/Game/.+)$") or name:match("(/Game/.+)$")
end

local function cache_class(item, cls, via)
    if not item or cls == nil then
        return
    end
    local rec = class_cache[item]
    if rec == nil then
        rec = {}
        class_cache[item] = rec
    end
    rec.cls_path = class_path_of(cls) or rec.cls_path
    log(
        "  class cached item="
            .. tostring(item)
            .. " via="
            .. tostring(via)
            .. " path="
            .. tostring(rec.cls_path)
            .. " "
            .. class_label(cls)
    )
end

local function skin_for_item(item)
    local mapped = SKIN_CLASS[item]
    local rec = class_cache[item]
    local cached_path = (rec and rec.cls_path) or mapped
    if cached_path then
        local cls = try_find_class(cached_path)
        if cls then
            if rec then
                rec.cls_path = cached_path
            end
            return cls, "cached-path"
        end
        if rec then
            rec.cls_path = nil
        end
    end
    if not mapped then
        return nil, "unmapped"
    end
    local found = load_guessed_class(mapped)
    if found then
        cache_class(item, found, "getasset")
        return found, "getasset " .. mapped
    end
    return nil, "unresolved"
end

local function char_from_cine(cine)
    local full = safe_call(cine, "GetFullName") or ""
    for _, pair in ipairs(CINE_NEEDLES) do
        if full:find(pair[1], 1, true) then
            return pair[2]
        end
    end
    return nil
end

local function char_from_battle(pawn)
    local stats = safe_get(pawn, "AC_jRPG_CharacterStats")
    local n = fname_str(stats, "CharacterHardcodedName")
    if type(n) == "string" and n ~= "" then
        return n, "stats"
    end
    n = fname_str(pawn, "CharacterHardcodedName")
    if type(n) == "string" and n ~= "" then
        return n, "pawn"
    end
    local data = safe_get(pawn, "CharacterData") or safe_get(pawn, "CurrentCharacterData")
    n = fname_str(data, "HardcodedNameID")
    if type(n) == "string" and n ~= "" then
        return n, "data"
    end
    local full = safe_call(pawn, "GetFullName") or ""
    for _, pair in ipairs(BATTLE_NEEDLES) do
        if full:find(pair[1], 1, true) then
            return pair[2], "needle"
        end
    end
    return nil, "none"
end

local function cine_from_scene(scene, char_id)
    local slot = SLOT_BY_CHAR[char_id]
    if slot and is_live(scene) then
        local comp = safe_get(scene, slot)
        local cine = safe_get(comp, "ChildActor")
        if is_live(cine) then
            return cine, slot
        end
    end
    return nil, "none"
end

local function classes_equal(a, b)
    if a == nil or b == nil then
        return false
    end
    if type(EqualsObjects) == "function" then
        local ok, eq = pcall(EqualsObjects, a, b)
        if ok then
            return eq == true
        end
    end
    local fa, fb
    pcall(function()
        fa = a:GetFullName()
    end)
    pcall(function()
        fb = b:GetFullName()
    end)
    return type(fa) == "string" and fa ~= "" and fa == fb
end

local function describe_skin(skin, tag)
    if not DEBUG then
        return
    end
    if not is_live(skin) then
        log("    " .. tag .. " INVALID")
        return
    end
    local hidden = safe_call(skin, "IsHidden")
    local parent = safe_call(skin, "GetAttachParentActor")
    log(
        "    "
            .. tag
            .. " "
            .. obj_label(skin)
            .. " hidden="
            .. tostring(hidden)
            .. " attached="
            .. obj_label(parent)
    )
end

local function attach_skin(cine, skin)
    if not is_live(cine) or not is_live(skin) then
        return false
    end
    local ok, err = pcall(function()
        cine:AttachWeaponToHands(skin)
    end)
    if not ok then
        log("  AttachWeaponToHands threw: " .. tostring(err))
        return false
    end
    pcall(function()
        skin:SetActorHiddenInGame(false)
    end)
    describe_skin(skin, "after-attach")
    return true
end

local function apply_class_on_cine(cine, cls, char, why)
    local weapons = safe_get(cine, "Weapons_Base")
    if not is_live(weapons) then
        log("  apply FAIL Weapons_Base INVALID")
        return false
    end
    local before = safe_get(weapons, "ChildActorClass")
    local skin = safe_get(weapons, "ChildActor")
    log("  ChildActorClass before: " .. class_label(before))
    describe_skin(skin, "before")
    if classes_equal(before, cls) then
        local parent = safe_call(skin, "GetAttachParentActor")
        if is_live(parent) then
            log("  skip SetChildActorClass, already that class and attached")
            return true
        end
        log("  class already set, attaching only")
        attach_skin(cine, skin)
        return true
    end
    local ok_set, err = pcall(function()
        weapons:SetChildActorClass(cls)
    end)
    if not ok_set then
        log("  SetChildActorClass threw: " .. tostring(err))
        return false
    end
    log("  ChildActorClass after : " .. class_label(safe_get(weapons, "ChildActorClass")))
    skin = safe_get(weapons, "ChildActor")
    log("  ChildActor after      : " .. obj_label(skin))
    describe_skin(skin, "after-set")
    attach_skin(cine, skin)
    log("  apply OK (" .. tostring(why) .. ") char=" .. tostring(char))
    return true
end

local function apply_cine(cine, char, why)
    log("  apply enter (" .. tostring(why) .. ") char=" .. tostring(char) .. " cine=" .. obj_label(cine))
    if not is_live(cine) then
        log("  apply skip cine INVALID")
        return false
    end
    local item = glam[char]
    if not item then
        log("  apply skip no glam")
        return false
    end
    local cls, how = skin_for_item(item)
    log("  resolve item=" .. tostring(item) .. " class=" .. class_label(cls) .. " how=" .. tostring(how))
    if cls == nil then
        apply_ok[char] = false
        return false
    end
    local ok = apply_class_on_cine(cine, cls, char, why)
    apply_ok[char] = ok
    return ok
end

local function actor_class(obj)
    if not is_live(obj) then
        return nil
    end
    return as_class(safe_call(obj, "GetClass"))
end

local function call_vfn(obj, name, arg)
    if not is_live(obj) then
        return false, "dead"
    end
    local ok, err = pcall(function()
        local fn = obj[name]
        return fn(obj, arg)
    end)
    return ok, err
end

local function spawn_glam_weapon(pawn, cls)
    local gs = try_find(GS_CDO)
    if gs == nil then
        return nil, "no GameplayStatics CDO"
    end
    local old = safe_get(pawn, "Weapons")
    local tf = nil
    if is_live(old) then
        pcall(function()
            tf = old:GetTransform()
        end)
    end
    if tf == nil then
        pcall(function()
            tf = pawn:GetTransform()
        end)
    end
    if tf == nil then
        return nil, "no transform"
    end
    local ok_d, deferred = pcall(function()
        return gs:BeginDeferredActorSpawnFromClass(pawn, cls, tf, 1, pawn, 2)
    end)
    if not ok_d then
        return nil, "deferred-threw:" .. tostring(deferred)
    end
    if deferred == nil then
        return nil, "deferred-nil"
    end
    local ok_f, spawned = pcall(function()
        return gs:FinishSpawningActor(deferred, tf, 2)
    end)
    if not ok_f then
        return nil, "finish-threw:" .. tostring(spawned)
    end
    if not is_live(spawned) then
        return nil, "spawned-dead " .. tostring(spawned)
    end
    return spawned, nil
end

local function apply_battle(pawn, char, why)
    log(
        "  battle apply enter ("
            .. tostring(why)
            .. ") char="
            .. tostring(char)
            .. " pawn="
            .. obj_label(pawn)
    )
    if not is_live(pawn) then
        log("  battle apply skip pawn INVALID")
        return false
    end
    local item = glam[char]
    if not item then
        log("  battle apply skip no glam")
        return false
    end
    local cls, how = skin_for_item(item)
    log(
        "  battle resolve item="
            .. tostring(item)
            .. " class="
            .. class_label(cls)
            .. " how="
            .. tostring(how)
    )
    if cls == nil then
        return false
    end
    local old = safe_get(pawn, "Weapons")
    local old_cls = actor_class(old)
    log("  Weapons before: " .. obj_label(old) .. " class=" .. class_label(old_cls))
    if is_live(old) and classes_equal(old_cls, cls) then
        log("  skip spawn, Weapons already glam class")
        call_vfn(pawn, "RegisterExternalActor", old)
        call_vfn(pawn, "Attach Weapons to Hands", old)
        return true
    end
    local spawned, err = spawn_glam_weapon(pawn, cls)
    if not is_live(spawned) then
        log("  battle spawn FAIL " .. tostring(err))
        return false
    end
    log("  spawned " .. obj_label(spawned))
    local ok_r, err_r = call_vfn(pawn, "RegisterExternalActor", spawned)
    log("  RegisterExternalActor ok=" .. tostring(ok_r) .. (ok_r and "" or (" err=" .. tostring(err_r))))
    local ok_a, err_a = call_vfn(pawn, "Attach Weapons to Hands", spawned)
    log("  Attach Weapons to Hands ok=" .. tostring(ok_a) .. (ok_a and "" or (" err=" .. tostring(err_a))))
    pcall(function()
        pawn.Weapons = spawned
    end)
    if is_live(old) and not classes_equal(old, spawned) then
        pcall(function()
            old:K2_DestroyActor()
        end)
    end
    log(
        "  battle apply OK ("
            .. tostring(why)
            .. ") char="
            .. tostring(char)
            .. " Weapons="
            .. obj_label(safe_get(pawn, "Weapons"))
    )
    return true
end

local function apply_restore(cine, char, why)
    log("  restore enter (" .. tostring(why) .. ") char=" .. tostring(char) .. " cine=" .. obj_label(cine))
    if not is_live(cine) then
        log("  restore skip cine INVALID")
        return false
    end
    local path = equipped_path[char]
    if not path then
        log("  restore skip no equipped path char=" .. tostring(char))
        return false
    end
    log("  restore path=" .. path)
    local cls = try_find_class(path)
    if cls == nil then
        log("  restore FAIL class not resident path=" .. path)
        return false
    end
    return apply_class_on_cine(cine, cls, char, why)
end

local function thread_tag()
    if type(IsInGameThread) == "function" then
        local ok, v = pcall(IsInGameThread)
        if ok then
            return tostring(v)
        end
    end
    return "unknown"
end

-- Engine work must run on the game thread. ExecuteWithDelay alone dispatches to a UE4SS
-- worker thread and faults probabilistically inside SetChildActorClass.
local function schedule(delay_ms, body)
    if type(ExecuteInGameThreadWithDelay) == "function" then
        ExecuteInGameThreadWithDelay(delay_ms, body)
        return true
    end
    if type(ExecuteWithDelay) == "function" and type(ExecuteInGameThread) == "function" then
        ExecuteWithDelay(delay_ms, function()
            ExecuteInGameThread(body)
        end)
        return true
    end
    log("  schedule FAIL no API")
    return false
end

local function weapons_list_from(obj)
    if not is_live(obj) then
        return nil
    end
    local list = safe_get(obj, "WeaponsList")
    if is_live(list) then
        return list
    end
    if is_live(safe_get(obj, "TooltipGrid")) then
        return obj
    end
    return nil
end

local function set_widget_vis(widget, vis)
    if not is_live(widget) then
        return false, nil, nil, "dead", "INVALID"
    end
    local before = safe_call(widget, "IsVisible")
    local ok, err = pcall(function()
        widget:SetVisibility(vis)
    end)
    local via = "SetVisibility"
    if not ok then
        ok, err = pcall(function()
            widget:SetIsVisible(vis == VIS_SHOWN)
        end)
        via = "SetIsVisible"
    end
    local after = safe_call(widget, "IsVisible")
    return ok, before, after, via, err
end

local function hide_tooltip_grid(from, why)
    if not tooltip_suppressed then
        return
    end
    local list = weapons_list_from(from)
    local grid = is_live(list) and safe_get(list, "TooltipGrid") or nil
    local nav = is_live(list) and safe_get(list, "NavigatedWeaponTooltip") or nil
    local g_ok, g_before, g_after, g_via, g_err = set_widget_vis(grid, VIS_COLLAPSED)
    local n_ok, _, _, _, n_err = set_widget_vis(nav, VIS_COLLAPSED)
    tooltip_hide_n = tooltip_hide_n + 1
    if not g_ok then
        log(
            "  tooltip hide why="
                .. tostring(why)
                .. " n="
                .. tostring(tooltip_hide_n)
                .. " grid ok="
                .. tostring(g_ok)
                .. " via="
                .. tostring(g_via)
                .. " vis="
                .. tostring(g_before)
                .. "->"
                .. tostring(g_after)
                .. (g_ok and "" or (" grid_err=" .. tostring(g_err)))
                .. (n_ok and "" or (" nav_err=" .. tostring(n_err)))
        )
    end
end

local function restore_tooltip_grid(from, why)
    local list = weapons_list_from(from)
    local grid = is_live(list) and safe_get(list, "TooltipGrid") or nil
    local ok, before, after, via, err = set_widget_vis(grid, VIS_SHOWN)
    if not ok then
        log(
            "  tooltip restore why="
                .. tostring(why)
                .. " ok=false via="
                .. tostring(via)
                .. " vis="
                .. tostring(before)
                .. "->"
                .. tostring(after)
                .. " err="
                .. tostring(err)
        )
    end
end

local function clear_tooltip_suppress(from, why)
    if not tooltip_suppressed then
        return
    end
    log("=== tooltip suppress clear (" .. tostring(why) .. ") ===")
    restore_tooltip_grid(from, why)
    tooltip_suppressed = false
end

local function live_object(v)
    if v == nil then
        return nil
    end
    local u = unwrap(v)
    if is_live(u) then
        return u
    end
    return nil
end

local function gear_instance_from_view(view)
    if not is_live(view) then
        return nil
    end
    local out = {}
    local ok, ret = pcall(function()
        return view:GetGearWeaponInstance(out)
    end)
    if not ok then
        log("  GetGearWeaponInstance threw: " .. tostring(ret))
        return nil
    end
    local keys = {
        "Gear Weapon Instance ",
        "Gear Weapon Instance",
        "Gear_Weapon_Instance_",
        "GearWeaponInstance",
    }
    local cand = live_object(ret)
    for i = 1, #keys do
        if cand == nil then
            cand = live_object(out[keys[i]])
        end
    end
    if cand == nil then
        for k, v in pairs(out) do
            cand = live_object(v)
            if cand then
                log("  instance via out[" .. tostring(k) .. "]")
                break
            end
        end
    end
    if cand then
        log("  instance " .. obj_label(cand))
        return cand
    end
    log("  GetGearWeaponInstance no live instance ret=" .. tostring(ret))
    return nil
end

local function retarget_equipped_tooltip(panel, view)
    if not is_live(panel) or not is_live(view) then
        return
    end
    if safe_get(panel, "IsBlacksmithMode") == true then
        return
    end
    local tip = safe_get(panel, "EquippedWeaponTooltip")
    local char_data = safe_get(panel, "CurrentCharacterData")
    if not is_live(tip) then
        log("  retarget skip EquippedWeaponTooltip INVALID")
        return
    end
    local inst = gear_instance_from_view(view)
    if not is_live(inst) then
        return
    end
    if not is_live(char_data) then
        log("  retarget skip CurrentCharacterData INVALID")
        return
    end
    local ok, err = pcall(function()
        tip:LoadWeapon(inst, char_data)
    end)
    retarget_n = retarget_n + 1
    if not ok then
        log(
            "  retarget n="
                .. tostring(retarget_n)
                .. " ok=false tip="
                .. obj_label(tip)
                .. " err="
                .. tostring(err)
        )
    end
end

local function hide_tooltip_button(panel)
    if not is_live(panel) then
        return nil
    end
    return safe_get(panel, "WBP_CommonBoundActionButton_HideTooltip")
end

local function kismet_text()
    local obj = try_find(KTEXT_CDO)
    if obj ~= nil then
        return obj
    end
    if type(StaticFindObject) ~= "function" then
        return nil
    end
    local ok, found = pcall(StaticFindObject, KTEXT_CDO)
    if ok and found ~= nil then
        return found
    end
    return nil
end

local function as_ftext(s)
    local lib = kismet_text()
    if lib == nil then
        log("  Conv_StringToText skip: KismetTextLibrary CDO not found")
        return nil
    end
    local ok, t = pcall(function()
        return lib:Conv_StringToText(s)
    end)
    if not ok then
        log("  Conv_StringToText threw: " .. tostring(t))
        return nil
    end
    if t == nil then
        log("  Conv_StringToText returned nil")
        return nil
    end
    return t
end

local function ftext_to_str(t)
    if t == nil then
        return nil
    end
    if type(t) == "string" then
        if t == "" then
            return nil
        end
        return t
    end
    local lib = kismet_text()
    if lib ~= nil then
        local ok, s = pcall(function()
            return lib:Conv_TextToString(t)
        end)
        if ok and type(s) == "string" and s ~= "" then
            return s
        end
    end
    local s = safe_call(t, "ToString")
    if type(s) == "string" and s ~= "" then
        return s
    end
    return nil
end

local function button_caption(btn)
    if not is_live(btn) then
        return nil
    end
    local named = safe_get(btn, "ActionNameText")
    local s = ftext_to_str(safe_call(named, "GetText"))
    if s then
        return s
    end
    s = ftext_to_str(safe_call(btn, "GetButtonText"))
    if s then
        return s
    end
    return ftext_to_str(safe_call(btn, "GetText"))
end

local function caption_is_hide(s)
    if type(s) ~= "string" then
        return false
    end
    if s:find("Hide Tooltip", 1, true) then
        return true
    end
    if s:find("Show Tooltip", 1, true) then
        return true
    end
    if s:find("Equip Weapon Skin", 1, true) then
        return true
    end
    if s:find("Remove Weapon Skin", 1, true) then
        return true
    end
    return false
end

local function triggering_row(btn)
    if not is_live(btn) then
        return nil
    end
    local h = safe_get(btn, "TriggeringInputAction")
    if h == nil then
        return nil
    end
    local rn = fname_str(h, "RowName")
    if type(rn) == "string" and rn ~= "" then
        return rn
    end
    return fname_str(btn, "TriggeringInputAction")
end

local function each_tarray(arr, fn)
    if arr == nil then
        return 0
    end
    local n = 0
    local ok_fe = pcall(function()
        arr:ForEach(function(_, elem)
            local v = unwrap(elem)
            if v == nil then
                v = elem
            end
            n = n + 1
            fn(v)
        end)
    end)
    if ok_fe and n > 0 then
        return n
    end
    local num = safe_call(arr, "GetArrayNum")
    if type(num) ~= "number" or num < 1 then
        return n
    end
    for i = 1, num do
        local v = arr[i]
        fn(unwrap(v) or v)
    end
    return num
end

local function ui_helpers_cdo()
    local obj = try_find(UIHELPERS_CDO)
    if obj ~= nil then
        return obj
    end
    if type(StaticFindObject) ~= "function" then
        return nil
    end
    local ok, found = pcall(StaticFindObject, UIHELPERS_CDO)
    if ok and found ~= nil then
        return found
    end
    return nil
end

local function play_equip_sound(panel)
    if not is_live(panel) then
        log("  PlaySound2D skip: panel dead")
        return
    end
    local gs = try_find(GS_CDO)
    if gs == nil then
        log("  PlaySound2D skip: GameplayStatics CDO not found")
        return
    end
    local snd = try_find(EQUIP_SOUND_PATH)
    if not is_live(snd) then
        log("  PlaySound2D skip: sound not resident path=" .. EQUIP_SOUND_PATH)
        return
    end
    sound_n = sound_n + 1
    local ok, err = pcall(function()
        gs:PlaySound2D(panel, snd, 1.0, 1.0, 0.0, nil, nil, true)
    end)
    if not ok then
        log("  PlaySound2D ok=false err=" .. tostring(err))
    else
        log("  PlaySound2D pcall returned ok=true")
    end
end

local function weapons_list_view(panel)
    local list = weapons_list_from(panel)
    if not is_live(list) then
        return nil
    end
    return safe_get(list, "WeaponsListView")
end

local function is_weapon_element(el)
    if not is_live(el) then
        return false
    end
    local full = safe_call(el, "GetFullName")
    return type(full) == "string" and full:find("WBP_Panel_WeaponElement", 1, true) ~= nil
end

local function walk_widget_array(arr, fn)
    local n = each_tarray(arr, fn)
    if n > 0 then
        return n
    end
    if type(arr) ~= "table" then
        return 0
    end
    for i = 1, #arr do
        local v = unwrap(arr[i]) or arr[i]
        n = n + 1
        fn(v)
    end
    return n
end

local function corner_vis(el)
    local c = safe_get(el, "LeftUpgradeCorner")
    return safe_call(c, "GetVisibility")
end

local function element_char_item(el)
    local wv = safe_get(el, "WeaponViewItem")
    local item = item_hardcoded(wv)
    local char_data = nil
    if is_live(wv) then
        char_data = safe_get(wv, "CurrentCharacterData")
    end
    local char = fname_str(char_data, "HardcodedNameID")
    return char, item
end

local function want_row_mark(el)
    local char, item = element_char_item(el)
    return char ~= nil and item ~= nil and glam[char] == item
end

local function vis_matches_mark(vis, marked)
    if type(vis) ~= "number" then
        return false
    end
    if marked then
        return vis == VIS_SHOWN
    end
    return vis == VIS_COLLAPSED
end

local function set_element_upgraded(el, marked, why)
    if not is_weapon_element(el) then
        return false
    end
    local vis_before = corner_vis(el)
    if vis_matches_mark(vis_before, marked) then
        return true
    end
    corner_n = corner_n + 1
    local ok, err = pcall(function()
        el:SetIsBeingUpgraded(marked)
    end)
    if not ok then
        log(
            "  SetIsBeingUpgraded ok=false marked="
                .. tostring(marked)
                .. " why="
                .. tostring(why)
                .. " err="
                .. tostring(err)
        )
    end
    return ok
end

local function collect_weapon_elements(panel)
    local out = {}
    local seen = {}
    local function add(el)
        if not is_weapon_element(el) then
            return
        end
        if not is_live(safe_get(el, "WeaponViewItem")) then
            return
        end
        local key = safe_call(el, "GetFullName") or tostring(el)
        if seen[key] then
            return
        end
        seen[key] = true
        out[#out + 1] = el
    end
    local lv = weapons_list_view(panel)
    if is_live(lv) then
        local ok, widgets = pcall(function()
            return lv:GetDisplayedEntryWidgets()
        end)
        if ok then
            walk_widget_array(widgets, add)
        elseif widgets then
            log("  GetDisplayedEntryWidgets threw: " .. tostring(widgets))
        end
    end
    return out
end

local function sync_row_corners(panel, why)
    local els = collect_weapon_elements(panel)
    local n_true, n_false, n_fail = 0, 0, 0
    for i = 1, #els do
        local el = els[i]
        local marked = want_row_mark(el)
        local ok = set_element_upgraded(el, marked, why)
        if not ok then
            n_fail = n_fail + 1
        elseif marked then
            n_true = n_true + 1
        else
            n_false = n_false + 1
        end
    end
    log(
        "  corners sync why="
            .. tostring(why)
            .. " n="
            .. tostring(#els)
            .. " on="
            .. tostring(n_true)
            .. " off="
            .. tostring(n_false)
            .. " fail="
            .. tostring(n_fail)
            .. " table "
            .. table_dump()
    )
end

local function action_bar_from(panel, maybe_bar)
    local bar = live_object(maybe_bar)
    if is_live(bar) then
        return bar
    end
    if not is_live(panel) then
        return nil
    end
    local lib = ui_helpers_cdo()
    if lib == nil then
        return nil
    end
    local ok, ret = pcall(function()
        return lib:GetGameMenuActionBarFromPanel(panel, panel)
    end)
    if not ok then
        ok, ret = pcall(function()
            return lib:GetGameMenuActionBarFromPanel(panel)
        end)
    end
    if not ok then
        if label_n < 4 then
            log("  GetGameMenuActionBarFromPanel failed: " .. tostring(ret))
        end
        return nil
    end
    return live_object(ret)
end

local function collect_action_buttons(bar)
    local seen = {}
    local out = {}
    local function add(v)
        if not is_live(v) then
            return
        end
        local key = safe_call(v, "GetFullName") or tostring(v)
        if seen[key] then
            return
        end
        seen[key] = true
        out[#out + 1] = v
    end
    if not is_live(bar) then
        return out
    end
    each_tarray(safe_get(bar, "ActionButtons"), add)
    local bound = safe_get(bar, "CommonBoundActionBar")
    if is_live(bound) then
        local ok, entries = pcall(function()
            return bound:GetAllEntries()
        end)
        if ok then
            each_tarray(entries, add)
        end
    end
    return out
end

local function is_hide_caption_btn(btn)
    local row = triggering_row(btn)
    if row == HIDE_ACTION_ROW then
        return true
    end
    if caption_is_hide(button_caption(btn)) then
        return true
    end
    local full = safe_call(btn, "GetFullName")
    return type(full) == "string" and full:find("HideTooltip", 1, true) ~= nil
end

local function live_out_object(ret, out)
    local cand = live_object(ret)
    if cand then
        return cand, "ret"
    end
    if type(out) ~= "table" then
        return nil, "none"
    end
    cand = live_object(out.CommonButtonBase)
    if cand then
        return cand, "CommonButtonBase"
    end
    cand = live_object(out[1])
    if cand then
        return cand, "out[1]"
    end
    for k, v in pairs(out) do
        cand = live_object(v)
        if cand then
            return cand, tostring(k)
        end
    end
    return nil, "none"
end

local function find_clone_from_src(bar, src)
    if not is_live(bar) or not is_live(src) then
        return nil, "no bar/src"
    end
    local out = {}
    local ok, ret = pcall(function()
        return bar:FindActionButtonFromButton(src, out)
    end)
    if not ok then
        log("  FindActionButtonFromButton threw: " .. tostring(ret))
        return nil, "threw"
    end
    local found, via = live_out_object(ret, out)
    if found then
        return found, "FromButton:" .. via
    end
    return nil, "empty"
end

local function label_for_row(panel)
    local char = character_id(panel)
    if char and last.item and glam[char] == last.item then
        return LABEL_REMOVE
    end
    return LABEL_EQUIP
end

local function set_text_override(btn, text)
    if not is_live(btn) then
        return false, "dead"
    end
    local ftext = as_ftext(text)
    if ftext == nil then
        return false, "no FText"
    end
    local ok, err = pcall(function()
        btn:SetTextOverride(ftext)
    end)
    log("  SetTextOverride returned ok=" .. tostring(ok))
    pcall(function()
        btn:SetText(ftext)
    end)
    local named = safe_get(btn, "ActionNameText")
    if is_live(named) then
        pcall(function()
            named:SetText(ftext)
        end)
    end
    return ok, err
end

local function apply_hide_button_text(panel, text, why, maybe_bar)
    if not is_live(panel) then
        return
    end
    local bar = action_bar_from(panel, maybe_bar)
    local src = hide_tooltip_button(panel)
    local found, via = find_clone_from_src(bar, src)
    local candidates = {}
    local targets = {}
    local how = via
    if is_live(found) then
        targets[1] = found
    else
        candidates = collect_action_buttons(bar)
        local want = triggering_row(src) or HIDE_ACTION_ROW
        for i = 1, #candidates do
            local row = triggering_row(candidates[i])
            if row == want or is_hide_caption_btn(candidates[i]) then
                targets[#targets + 1] = candidates[i]
            end
        end
        how = "fallback matches"
    end
    label_scan_n = label_scan_n + 1
    if label_scan_n <= 4 then
        log(
            "  label scan why="
                .. tostring(why)
                .. " how="
                .. tostring(how)
                .. " find="
                .. tostring(via)
                .. " bar="
                .. obj_label(bar)
                .. " src="
                .. obj_label(src)
                .. " candidates="
                .. tostring(#candidates)
                .. " hits="
                .. tostring(#targets)
        )
        if is_live(found) then
            local named = safe_get(found, "ActionNameText")
            log(
                "    find btn="
                    .. obj_label(found)
                    .. " named_live="
                    .. tostring(is_live(named))
                    .. " named_vis="
                    .. tostring(safe_call(named, "GetVisibility"))
                    .. " cap="
                    .. tostring(button_caption(found))
            )
        end
    end
    if #targets == 0 then
        if label_scan_n <= 4 then
            log(
                "  label skip Find empty and no HideTooltip among clones why="
                    .. tostring(why)
                    .. " bar="
                    .. obj_label(bar)
                    .. " n="
                    .. tostring(#candidates)
            )
        end
        return
    end
    local ok, err = true, nil
    local last_btn = nil
    for i = 1, #targets do
        last_btn = targets[i]
        local one_ok, one_err = set_text_override(last_btn, text)
        if not one_ok then
            ok, err = one_ok, one_err
        end
    end
    label_n = label_n + 1
    local changed = text ~= last_label
    last_label = text
    if (not ok) or changed or label_n <= 8 then
        log(
            "  label why="
                .. tostring(why)
                .. " n="
                .. tostring(label_n)
                .. " how="
                .. tostring(how)
                .. " text="
                .. tostring(text)
                .. " ok="
                .. tostring(ok)
                .. " hits="
                .. tostring(#targets)
                .. " post_cap="
                .. tostring(button_caption(last_btn))
                .. " btn="
                .. obj_label(last_btn)
                .. " game_thread="
                .. thread_tag()
                .. (ok and "" or (" err=" .. tostring(err)))
        )
    end
end

local function relabel_hide_button(panel, why, maybe_bar)
    if safe_get(panel, "IsBlacksmithMode") == true then
        return
    end
    apply_hide_button_text(panel, label_for_row(panel), why, maybe_bar)
end

local function restore_hide_button_label(panel, why)
    apply_hide_button_text(panel, LABEL_RETAIL, why)
end

local function queue_apply(char, why)
    if not char or not glam[char] then
        return
    end
    local key = tostring(char)
    if retry_pending[key] then
        return
    end
    retry_pending[key] = true
    log(
        "  queue apply in "
            .. tostring(APPLY_DELAY_MS)
            .. "ms ("
            .. tostring(why)
            .. ") char="
            .. tostring(char)
    )
    local queued = schedule(APPLY_DELAY_MS, function()
        log("  deferred body running, game_thread=" .. thread_tag())
        retry_pending[key] = nil
        if not glam[char] then
            log("  deferred apply skipped, glam cleared")
            return
        end
        local scene = last_scene
        if not is_live(scene) then
            local ok, found = pcall(FindFirstOf, "BP_GameMenuScene_C")
            if ok and is_live(found) then
                scene = found
                last_scene = found
            end
        end
        local cine, via = cine_from_scene(scene, char)
        if not is_live(cine) then
            cine = nil
            via = "none"
        end
        log("  deferred cine via=" .. tostring(via) .. " -> " .. obj_label(cine))
        local ok = apply_cine(cine, char, why .. "-deferred")
        if not ok then
            local retry_key = tostring(char) .. "@retry"
            if not retry_pending[retry_key] then
                retry_pending[retry_key] = true
                log("  load-then-resolve retry in " .. tostring(RESOLVE_RETRY_MS) .. "ms")
                local requeued = schedule(RESOLVE_RETRY_MS, function()
                    retry_pending[retry_key] = nil
                    local cine2 = cine_from_scene(last_scene, char)
                    apply_cine(cine2, char, why .. "-retry")
                end)
                if not requeued then
                    retry_pending[retry_key] = nil
                end
            end
        end
    end)
    if not queued then
        retry_pending[key] = nil
        say("WARN no game-thread scheduler; refusing apply on the hook stack")
    end
end

local function live_menu_scene()
    local scene = last_scene
    if is_live(scene) then
        return scene
    end
    local ok, found = pcall(FindFirstOf, "BP_GameMenuScene_C")
    if ok and is_live(found) then
        last_scene = found
        return found
    end
    return nil
end

local function queue_restore(char, why)
    if not char or glam[char] then
        return
    end
    local key = "restore:" .. tostring(char)
    if retry_pending[key] then
        return
    end
    retry_pending[key] = true
    log(
        "  queue restore in "
            .. tostring(APPLY_DELAY_MS)
            .. "ms ("
            .. tostring(why)
            .. ") char="
            .. tostring(char)
            .. " path="
            .. tostring(equipped_path[char])
    )
    local queued = schedule(APPLY_DELAY_MS, function()
        log("  restore body running, game_thread=" .. thread_tag())
        retry_pending[key] = nil
        if glam[char] then
            log("  restore skipped, glam set again")
            return
        end
        local cine, via = cine_from_scene(live_menu_scene(), char)
        log("  restore cine via=" .. tostring(via) .. " -> " .. obj_label(cine))
        apply_restore(cine, char, why .. "-deferred")
    end)
    if not queued then
        retry_pending[key] = nil
        say("WARN no game-thread scheduler; refusing restore on the hook stack")
    end
end

local function queue_battle_apply(pawn, char, why)
    if not char or not glam[char] then
        return
    end
    local key = "battle:" .. tostring(char)
    if retry_pending[key] then
        return
    end
    retry_pending[key] = true
    log(
        "  queue battle apply in "
            .. tostring(APPLY_DELAY_MS)
            .. "ms ("
            .. tostring(why)
            .. ") char="
            .. tostring(char)
    )
    local queued = schedule(APPLY_DELAY_MS, function()
        log("  battle body running, game_thread=" .. thread_tag())
        retry_pending[key] = nil
        if not glam[char] then
            log("  battle apply skipped, glam cleared")
            return
        end
        if not is_live(pawn) then
            log("  battle apply skipped, pawn dead")
            return
        end
        apply_battle(pawn, char, why .. "-deferred")
    end)
    if not queued then
        retry_pending[key] = nil
        say("WARN no game-thread scheduler; refusing battle apply on the hook stack")
    end
end

local function on_hide_tooltip(ctx)
    last.hide_n = last.hide_n + 1
    local panel = unwrap(ctx)
    last_panel = panel
    local char, char_data = character_id(panel)
    last.char = char
    log("=== HideTooltip #" .. last.hide_n .. " ===")
    log(
        "  game_thread="
            .. thread_tag()
            .. " HardcodedNameID="
            .. tostring(char)
            .. " last.item="
            .. tostring(last.item)
    )
    local bs = safe_get(panel, "IsBlacksmithMode")
    if bs == true then
        log("  skip blacksmith mode")
        return
    end
    tooltip_suppressed = true
    hide_tooltip_grid(panel, "HideTooltip")
    if not char or not last.item then
        log("  skip: need character + highlighted item")
        relabel_hide_button(panel, "HideTooltip-skip")
        log("  HideTooltip skip exit")
        return
    end
    if glam[char] == last.item then
        if apply_ok[char] then
            glam[char] = nil
            apply_ok[char] = nil
            log("  CLEAR " .. char .. " (was " .. tostring(last.item) .. ")")
            log("  table " .. table_dump())
            play_equip_sound(panel)
            queue_restore(char, "HideTooltip-clear")
            relabel_hide_button(panel, "HideTooltip-clear")
            sync_row_corners(panel, "HideTooltip-clear")
            log("  HideTooltip CLEAR exit")
            return
        end
        log("  previous apply did not resolve; retry not clear item=" .. tostring(last.item))
        queue_apply(char, "HideTooltip-reresolve")
        relabel_hide_button(panel, "HideTooltip-reresolve")
        sync_row_corners(panel, "HideTooltip-reresolve")
        log("  HideTooltip reresolve exit")
        return
    end
    apply_ok[char] = false
    glam[char] = last.item
    log("  SET " .. char .. " -> " .. tostring(last.item))
    log("  table " .. table_dump())
    play_equip_sound(panel)
    queue_apply(char, "HideTooltip")
    relabel_hide_button(panel, "HideTooltip-set")
    sync_row_corners(panel, "HideTooltip-set")
    log("  HideTooltip SET exit")
end

local function on_weapon_navigated(ctx, p_item)
    last.nav_n = last.nav_n + 1
    local panel = unwrap(ctx)
    last_panel = panel
    local char = character_id(panel)
    last.char = char
    local item_obj = unwrap(p_item)
    local item = item_hardcoded(item_obj)
    if item then
        last.item = item
    end
    if is_live(item_obj) then
        retarget_equipped_tooltip(panel, item_obj)
    end
    relabel_hide_button(panel, "navigate")
    if last.nav_n <= 4 or (item and last.nav_n % 8 == 0) then
        log(
            "nav #"
                .. last.nav_n
                .. " char="
                .. tostring(char)
                .. " item="
                .. tostring(item or last.item)
                .. " live="
                .. tostring(is_live(item_obj))
        )
    end
    if tooltip_suppressed then
        hide_tooltip_grid(panel, "navigate")
    end
end

local function on_show_weapon_tooltip(ctx)
    if not tooltip_suppressed then
        return
    end
    hide_tooltip_grid(unwrap(ctx), "ShowWeaponTooltip")
end

local function on_panel_deactivated(ctx)
    local panel = unwrap(ctx)
    restore_hide_button_label(panel, "BP_OnDeactivated")
    clear_tooltip_suppress(panel, "BP_OnDeactivated")
end

local function on_panel_activated(ctx)
    local panel = unwrap(ctx)
    log("=== BP_OnActivated enter game_thread=" .. thread_tag())
    clear_tooltip_suppress(panel, "BP_OnActivated")
    relabel_hide_button(panel, "BP_OnActivated")
    log("  relabel returned (activated)")
    sync_row_corners(panel, "BP_OnActivated")
    log("=== BP_OnActivated exit")
end

local function on_list_item_object_set(ctx)
    local el = unwrap(ctx)
    if not is_weapon_element(el) then
        return
    end
    set_element_upgraded(el, want_row_mark(el), "OnListItemObjectSet")
end

local function on_rebuild_action_bar(ctx, p_bar)
    log("=== RebuildActionBarButtons enter game_thread=" .. thread_tag())
    relabel_hide_button(unwrap(ctx), "RebuildActionBarButtons", unwrap(p_bar))
    log("=== RebuildActionBarButtons exit")
end

local function on_update_weapon_skin(ctx, p_skin_class, p_char_data)
    last.skin_n = last.skin_n + 1
    local scene = unwrap(ctx)
    if is_live(scene) then
        last_scene = scene
    end
    local char_data = unwrap(p_char_data)
    local char = fname_str(char_data, "HardcodedNameID")
    remember_equipped(char, unwrap(p_skin_class))
    if not char or not glam[char] then
        return
    end
    log(
        "=== UpdateWeaponSkin #"
            .. last.skin_n
            .. " char="
            .. tostring(char)
            .. " glam="
            .. tostring(glam[char])
            .. " ==="
    )
    log("  incoming equipped class: " .. class_label(unwrap(p_skin_class)))
    queue_apply(char, "UpdateWeaponSkin")
end

local function on_spawn_weapon(ctx)
    last.spawn_n = last.spawn_n + 1
    local cine = unwrap(ctx)
    local char = char_from_cine(cine)
    local weapons = safe_get(cine, "Weapons_Base")
    remember_equipped(char, safe_get(weapons, "ChildActorClass"))
    if not char or not glam[char] then
        return
    end
    log(
        "=== cine SpawnWeaponAndSetSkin #"
            .. last.spawn_n
            .. " char="
            .. tostring(char)
            .. " glam="
            .. tostring(glam[char])
            .. " ==="
    )
    log("  cine=" .. obj_label(cine))
    queue_apply(char, "SpawnWeaponAndSetSkin")
end

local function on_battle_spawn(ctx)
    last.battle_n = last.battle_n + 1
    local pawn = unwrap(ctx)
    local char, via = char_from_battle(pawn)
    if last.battle_n <= 8 or (char and glam[char]) then
        log(
            "=== battle SpawnWeaponAndSetSkin #"
                .. last.battle_n
                .. " char="
                .. tostring(char)
                .. " via="
                .. tostring(via)
                .. " glam="
                .. tostring(char and glam[char])
                .. " pawn="
                .. obj_label(pawn)
                .. " ==="
        )
    end
    if not char or not glam[char] then
        return
    end
    queue_battle_apply(pawn, char, "battle-spawn")
end

local HOOKS = {
    { path = HIDE_TOOLTIP_EVT, fn = on_hide_tooltip },
    { path = NAVIGATE_EVT, fn = on_weapon_navigated },
    { path = SHOW_TOOLTIP, fn = on_show_weapon_tooltip },
    { path = PANEL_DEACT, fn = on_panel_deactivated },
    { path = PANEL_ACT, fn = on_panel_activated },
    { path = LIST_ITEM_SET, fn = on_list_item_object_set },
    { path = REBUILD_EVT, fn = on_rebuild_action_bar },
    { path = MENU_CLASS .. ":UpdateWeaponSkin", fn = on_update_weapon_skin },
    { path = CINE_CLASS .. ":SpawnWeaponAndSetSkin", fn = on_spawn_weapon },
}

local registered = {}
local attempts = 0
local hook_retry_pending = false
local MAX_ATTEMPTS = 400
local RETRY_MS = 3000

local function register_hooks()
    hook_retry_pending = false
    attempts = attempts + 1
    local missing = 0
    for _, h in ipairs(HOOKS) do
        if not registered[h.path] then
            local ok = pcall(RegisterHook, h.path, h.fn)
            if ok then
                registered[h.path] = true
                log("hook OK   " .. h.path)
            else
                missing = missing + 1
            end
        end
    end
    if missing == 0 then
        say("v2 ready, " .. #HOOKS .. " hooks")
        return
    end
    if attempts >= MAX_ATTEMPTS then
        say("WARN gave up with " .. missing .. " hook(s) unregistered after " .. attempts .. " attempts")
        for _, h in ipairs(HOOKS) do
            if not registered[h.path] then
                say("  never registered: " .. h.path)
            end
        end
        return
    end
    if attempts % 20 == 0 then
        log("still waiting on " .. missing .. " hook(s) after " .. attempts .. " attempts")
    end
    if type(ExecuteWithDelay) == "function" and not hook_retry_pending then
        hook_retry_pending = true
        ExecuteWithDelay(RETRY_MS, register_hooks)
    end
end

register_hooks()

local battle_spawn_registered = false
local battle_ready_registered = false
local battle_attempts = 0

local function register_battle_spawn()
    if battle_spawn_registered then
        return
    end
    battle_attempts = battle_attempts + 1
    local ok = pcall(RegisterHook, BATTLE_SPAWN, on_battle_spawn)
    if ok then
        battle_spawn_registered = true
        log("hook OK   " .. BATTLE_SPAWN)
        return
    end
    if battle_attempts <= 3 or battle_attempts % 20 == 0 then
        log("battle spawn hook not resident yet attempt=" .. tostring(battle_attempts))
    end
end

local function arm_battle_ready()
    if not battle_ready_registered then
        local ok = pcall(RegisterHook, BATTLE_READY, function()
            log("OnBattleDependenciesFullyLoaded -> battle spawn hook")
            register_battle_spawn()
        end)
        if ok then
            battle_ready_registered = true
            log("hook OK   " .. BATTLE_READY)
        end
    end
    register_battle_spawn()
end

local ok_cr = pcall(RegisterHook, CLIENT_RESTART, function()
    log("ClientRestart -> battle spawn registration")
    arm_battle_ready()
end)
if ok_cr then
    log("hook OK   " .. CLIENT_RESTART)
else
    log("ClientRestart hook failed; trying battle spawn now")
    arm_battle_ready()
end
if type(ExecuteWithDelay) == "function" then
    ExecuteWithDelay(RETRY_MS, arm_battle_ready)
end

if type(RegisterConsoleCommandHandler) == "function" then
    RegisterConsoleCommandHandler("glamlua_status", function()
        say(
            "status char="
                .. tostring(last.char)
                .. " item="
                .. tostring(last.item)
                .. " hide="
                .. last.hide_n
                .. " nav="
                .. last.nav_n
                .. " spawn="
                .. last.spawn_n
                .. " battle="
                .. last.battle_n
                .. " skin="
                .. last.skin_n
                .. " tooltip_suppressed="
                .. tostring(tooltip_suppressed)
                .. " retarget="
                .. tostring(retarget_n)
                .. " label="
                .. tostring(last_label)
                .. " table "
                .. table_dump()
        )
        return true
    end)
end
