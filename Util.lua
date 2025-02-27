--- @class (partial) CustomAbilityIcons
local CustomAbilityIcons = CustomAbilityIcons

--- Retrieves the base ability id of the skill with the specified ability id.
--- @param slotIndex number The index of a given skill in the action bar.
--- @param hotbarCategory number The category of the hotbar in question.
--- @return number? baseAbilityId The base ability id of the specified skill.
function CustomAbilityIcons.GetBaseAbilityId(slotIndex, hotbarCategory)
    local abilityId = CustomAbilityIcons.GetAbilityId(slotIndex, hotbarCategory)
    if not abilityId then return nil end

    local actionType = GetSlotType(slotIndex, hotbarCategory)
    if actionType == ACTION_TYPE_CRAFTED_ABILITY then
        return GetAbilityIdForCraftedAbilityId(abilityId)
    end

    local progressionData = SKILLS_DATA_MANAGER:GetProgressionDataByAbilityId(abilityId)
    if not progressionData then return abilityId end

    local skillData = progressionData:GetSkillData()
    if not skillData.GetMorphData then return abilityId end

    local baseMorphData = skillData:GetMorphData(MORPH_SLOT_BASE)
    return baseMorphData and baseMorphData:GetAbilityId() or abilityId
end

--- Retrieves the ability id of the skill found in the specified slotIndex.
--- @param slotIndex number The index of a given skill in the action bar.
--- @param hotbarCategory number The category of the hotbar in question.
--- @return number? abilityId The ability id that corresponds to the skill in question.
function CustomAbilityIcons.GetAbilityId(slotIndex, hotbarCategory)
    local index = tonumber(slotIndex) or 0
    if index < CustomAbilityIcons.MIN_INDEX or index > CustomAbilityIcons.MAX_INDEX then
        return nil
    end
    return GetSlotBoundId(slotIndex, hotbarCategory)
end

--- Retrieves the path of the selected collectible icon for the skill found in the specified slotIndex.
--- @param slotIndex number The index of a given skill in the action bar.
--- @param hotbarCategory number The category of the hotbar in question.
--- @return string? collectibleIcon The path of the icon that corresponds to the selected skill style.
function CustomAbilityIcons.GetSkillStyleIcon(slotIndex, hotbarCategory)
    if not CustomAbilityIcons.GetSettings().showSkillStyleIcons then return nil end

    local abilityId = CustomAbilityIcons.GetAbilityId(slotIndex, hotbarCategory)
    if not abilityId then return nil end

    local baseAbilityId = CustomAbilityIcons.GetBaseAbilityId(slotIndex, hotbarCategory)
    local skillType, skillLineIndex, skillIndex = GetSpecificSkillAbilityKeysByAbilityId(baseAbilityId)
    local progressionId = GetProgressionSkillProgressionId(skillType, skillLineIndex, skillIndex)
    local collectibleId = GetActiveProgressionSkillAbilityFxOverrideCollectibleId(progressionId)
    
    -- Return the collectible icon if available, otherwise return the default ability icon
    return collectibleId and GetCollectibleIcon(collectibleId) or CustomAbilityIcons.GetDefaultAbilityIcon(slotIndex, hotbarCategory)
end

--- Retrieves the custom made icons for crafted abilities.
--- @param slotIndex number The index of a given skill in the action bar.
--- @param hotbarCategory number The category of the hotbar in question.
--- @return string? abilityIcon The path of the icon to be applied to the skill in question.
function CustomAbilityIcons.GetCustomAbilityIcon(slotIndex, hotbarCategory)
    if not CustomAbilityIcons.GetSettings().showCustomScribeIcons then return nil end

    local abilityId = CustomAbilityIcons.GetAbilityId(slotIndex, hotbarCategory)
    if not abilityId then return nil end

    local primaryScriptId = GetCraftedAbilityActiveScriptIds(abilityId)
    if primaryScriptId == 0 then return nil end

    local scriptName = GetCraftedAbilityScriptDisplayName(primaryScriptId)
    local defaultIcon = CustomAbilityIcons.GetDefaultAbilityIcon(slotIndex, hotbarCategory)
    return defaultIcon and MapScriptToIcon(scriptName, defaultIcon) or nil
end

--- Retrieves the icon path of the skill found in the specified slotIndex.
--- @param slotIndex number The index of a given skill in the action bar.
--- @param hotbarCategory number The category of the hotbar in question.
--- @return string? abilityIcon The path of the icon that corresponds to the skill in question.
function CustomAbilityIcons.GetDefaultAbilityIcon(slotIndex, hotbarCategory)
    local abilityId = CustomAbilityIcons.GetAbilityId(slotIndex, hotbarCategory)
    if not abilityId then return nil end

    local actionType = GetSlotType(slotIndex, hotbarCategory)
    if actionType == ACTION_TYPE_CRAFTED_ABILITY then
        abilityId = GetAbilityIdForCraftedAbilityId(abilityId)
    end
    return GetAbilityIcon(abilityId)
end

--- Maps the given scriptName and defaultIcon to their corresponding custom icon.
--- @param scriptName string The name of the focus script based on which the custom icon will be applied.
--- @param defaultIcon string The path of the base game icon to be replaced with our own.
--- @return string? abilityIcon The path of the icon to be applied to the skill in question.
function MapScriptToIcon(scriptName, defaultIcon)
    local customIcons = CustomAbilityIcons.CUSTOM_ABILITY_ICONS[defaultIcon]
    if not customIcons then return nil end

    scriptName = string.lower(scriptName)
    for key, value in pairs(customIcons) do
        if string.find(scriptName, key) then
            return value
        end
    end
    return customIcons[CustomAbilityIcons.DEFAULT]
end

--- Applies the active skill style (if any) to the skill found in the specified slotIndex.
--- @param slotIndex number The index of a given skill in the action bar.
--- @param hotbarCategory number The category of the hotbar in question.
function CustomAbilityIcons.ApplySkillStyle(slotIndex, hotbarCategory)
    CustomAbilityIcons.ApplySkillStyleActive(slotIndex, hotbarCategory)

    local inactiveBar = hotbarCategory == HOTBAR_CATEGORY_PRIMARY and HOTBAR_CATEGORY_BACKUP or HOTBAR_CATEGORY_PRIMARY
    CustomAbilityIcons.ApplySkillStyleInactiveFAB(slotIndex, inactiveBar)
end

--- Retrieves the active skill style for the skill found in the specified slotIndex and applies it.
--- @param slotIndex number The index of a given skill in the action bar.
--- @param hotbarCategory number The category of the hotbar in question.
function CustomAbilityIcons.ApplySkillStyleActive(slotIndex, hotbarCategory)
    local icon = CustomAbilityIcons.GetSkillStyleIcon(slotIndex, hotbarCategory)
                 or CustomAbilityIcons.GetCustomAbilityIcon(slotIndex, hotbarCategory)
                 or CustomAbilityIcons.GetDefaultAbilityIcon(slotIndex, hotbarCategory)
    if icon then
        CustomAbilityIcons.ReplaceAbilityBarIcon(slotIndex, hotbarCategory, icon)
    end
end

--- Calls SetTexture to replace the icon of the skill found in the specified slotIndex.
--- @param slotIndex number The index of a given skill in the action bar.
--- @param hotbarCategory number The category of the hotbar in question.
--- @param icon string The path of the icon that will be assigned to the skill in question.
function CustomAbilityIcons.ReplaceAbilityBarIcon(slotIndex, hotbarCategory, icon)
    local btn = CustomAbilityIcons.GetInactiveBarButtonFAB(slotIndex) or ZO_ActionBar_GetButton(slotIndex, hotbarCategory)
    if btn and btn.icon then
        btn.icon:SetTexture(icon)
    end
end

--- Calls RedirectTexture to replace an existing skill icon with a different one.
function CustomAbilityIcons.ReplaceMismatchedIcons()
    for key, value in pairs(CustomAbilityIcons.BASE_GAME_ICONS_TO_REPLACE) do
        local iconName = string.match(key, "/([^/]+)$")
        if CustomAbilityIcons.GetSettings().replaceMismatchedBaseIcons and CustomAbilityIcons:GetSettings().mismatchedIcons[iconName] then
            RedirectTexture(key, value)
        else
            RedirectTexture(key, key)
        end
    end
end