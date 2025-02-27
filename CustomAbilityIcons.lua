CustomAbilityIcons = {}

--- @class (partial) CustomAbilityIcons
local CustomAbilityIcons = CustomAbilityIcons

local FAB = FancyActionBar or nil;

------------------
-- Declarations --
------------------

local ADDON_VERSION = "1.0"
local EVENT_MANAGER = EVENT_MANAGER
local GetActiveHotbarCategory = GetActiveHotbarCategory
local GetSlotTexture = GetSlotTexture
local HOTBAR_CATEGORY_PRIMARY = HOTBAR_CATEGORY_PRIMARY
local HOTBAR_CATEGORY_BACKUP = HOTBAR_CATEGORY_BACKUP
local HOTBAR_CATEGORY_WEREWOLF = HOTBAR_CATEGORY_WEREWOLF

CustomAbilityIcons.version = ADDON_VERSION
CustomAbilityIcons.name = "CustomAbilityIcons"

---------------
-- Functions --
---------------

--- Initializes the saved variables and replaces mismatched base skill icons, if the saved variables dictate it.
function CustomAbilityIcons.Initialize()
    CustomAbilityIcons.InitializeSettings()
    CustomAbilityIcons.ReplaceMismatchedIcons()
end

function CustomAbilityIcons.GetFAB()
    return FAB;
end

--- Helper function to apply skill styles for all relevant slots.
--- @param hotbarCategory number The category of the hotbar to apply styles to.
function CustomAbilityIcons.ApplySkillStyles(hotbarCategory)
    for index = CustomAbilityIcons.MIN_INDEX, CustomAbilityIcons.MAX_INDEX do
        CustomAbilityIcons.ApplySkillStyle(index, hotbarCategory)
    end
end

function CustomAbilityIcons.AddCustomIconPack( PackDirectory, PackIcons )
    CustomAbilityIcons.ICON_PACKS[PackDirectory] = PackIcons
    CustomAbilityIcons.GenerateReplacementLists()
end

------------
-- Events --
------------

--- Triggered on initial player load, or reloadUI.
--- @param _ any
--- @param isFirstLoad boolean True if it's the first time the UI loads, false otherwise.
function CustomAbilityIcons.OnPlayerActivated(_, isFirstLoad)
    CustomAbilityIcons.ApplySkillStyles(GetActiveHotbarCategory())
    FAB = FancyActionBar
end

--- Triggered when the player switches hotbars, after the "GetSlotTexture" SecurePostHook.
--- @param _ any
--- @param slotIndex number The index of a given skill in the action bar.
--- @param hotbarCategory number The category of the hotbar that triggered the event.
function CustomAbilityIcons.OnHotbarSlotStateUpdated(_, slotIndex, hotbarCategory)
    if slotIndex >= CustomAbilityIcons.MIN_INDEX and slotIndex <= CustomAbilityIcons.MAX_INDEX then
        local activeHotbarCategory = GetActiveHotbarCategory()
        if hotbarCategory == activeHotbarCategory and (hotbarCategory == HOTBAR_CATEGORY_PRIMARY or hotbarCategory == HOTBAR_CATEGORY_BACKUP or hotbarCategory == HOTBAR_CATEGORY_WEREWOLF) then
            CustomAbilityIcons.ApplySkillStyle(slotIndex, hotbarCategory)
        end
    end
end

--- Triggered when hotbars are updated, after the "GetSlotTexture" SecurePostHook.
function CustomAbilityIcons.OnAllHotbarsUpdated()
    CustomAbilityIcons.ApplySkillStyles(GetActiveHotbarCategory())
end

--- To be used in any event when the skill icons need to be refreshed.
--- @param _ any
--- @param collectibleId any
function CustomAbilityIcons.OnCollectibleUpdated(_, collectibleId)
    CustomAbilityIcons.ApplySkillStyles(GetActiveHotbarCategory())
end

--- Local alias for GetSlotTexture, introduced to avoid overflowing the stack due to mutual recursion between
--- GetSlotTexture and its SecurePostHook.
local originalGetSlotTexture = GetSlotTexture
SecurePostHook("GetSlotTexture", function(slotIndex, hotbarCategory)
    if hotbarCategory and slotIndex >= CustomAbilityIcons.MIN_INDEX and slotIndex <= CustomAbilityIcons.MAX_INDEX and (hotbarCategory == HOTBAR_CATEGORY_PRIMARY or hotbarCategory == HOTBAR_CATEGORY_BACKUP or hotbarCategory == HOTBAR_CATEGORY_WEREWOLF) then
        local newIcon = CustomAbilityIcons.GetSkillStyleIcon(slotIndex, hotbarCategory) or CustomAbilityIcons.GetCustomAbilityIcon(slotIndex, hotbarCategory)
        local icon, weaponIcon, activationAnimation = originalGetSlotTexture(slotIndex, hotbarCategory)
        if newIcon then
            icon = newIcon
        end
        return icon, weaponIcon, activationAnimation
    end
    return originalGetSlotTexture(slotIndex, hotbarCategory)
end)

--- To be used during game initialization. Code contained in this method needs to run conditionally, for this addon only.
--- @param eventCode any
--- @param addOnName any
function CustomAbilityIcons.OnAddOnLoaded(eventCode, addOnName)
    if addOnName == CustomAbilityIcons.name then
        EVENT_MANAGER:RegisterForEvent(CustomAbilityIcons.name, EVENT_COLLECTIBLE_UPDATED, CustomAbilityIcons.OnCollectibleUpdated)
        EVENT_MANAGER:RegisterForEvent(CustomAbilityIcons.name, EVENT_HOTBAR_SLOT_STATE_UPDATED, CustomAbilityIcons.OnHotbarSlotStateUpdated)
        EVENT_MANAGER:RegisterForEvent(CustomAbilityIcons.name, EVENT_PLAYER_ACTIVATED, CustomAbilityIcons.OnPlayerActivated)
        EVENT_MANAGER:RegisterForEvent(CustomAbilityIcons.name, EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED, CustomAbilityIcons.OnAllHotbarsUpdated)

        -- Unregister the event as our addon was loaded and we do not need it to be run for every other addon that will load
        EVENT_MANAGER:UnregisterForEvent(CustomAbilityIcons.name, EVENT_ADD_ON_LOADED)

        CustomAbilityIcons.CreateSlashCommands()
        CustomAbilityIcons.Initialize()
    end
end

----------
-- Main --
----------

EVENT_MANAGER:RegisterForEvent(CustomAbilityIcons.name, EVENT_ADD_ON_LOADED, CustomAbilityIcons.OnAddOnLoaded)