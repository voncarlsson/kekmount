local KM_GroundMounts = {};
local KM_WaterGroundMounts = {};
local KM_UnderWaterMounts = {};
local KM_NoSkillMounts = {};
local KM_FlyingMounts = {};
local KM_AQMounts = {};
local KM_LastCheck = GetTime();
local KM_PreferWaterGroundMount = true;
local hasSeahorse, hasPoseidus = false, false
local PlayerFaction = select(1, UnitFactionGroup("player"));
local DesiredGroundMount, DesiredFlyingMount = nil, nil;
local KM_option_WaterMount = true;
PlayerFaction = PlayerFaction == "Horde" and 0 or PlayerFaction == "Alliance" and 1;

function KM_GetMounts()
    KM_GroundMounts = {};
    KM_FlyingMounts = {};
    KM_UnderWaterMounts = {};
    KM_NoSkillMounts = {};
    KM_WaterGroundMounts = {};

    KM_LastCheck = GetTime();
    
    for i = 1, C_MountJournal.GetNumMounts(), 1 do
        local creatureName, creatureID, icon, active, summonable, source, isFavorite, isFactionSpecific, faction, unknown, owned = C_MountJournal.GetMountInfo(i);
        local _,_,_,_, mountType = C_MountJournal.GetMountInfoExtra(i)

        --typeID = bit.band(3, typeID)
        if owned and (faction == nil or faction == PlayerFaction) and summonable == true then
            if mountType == 248 then
                table.insert(KM_FlyingMounts, i);
            end
            
            if mountType == 230 or mountType == 269 then
                table.insert(KM_GroundMounts, i);
                if mountType == 269 then
                    table.insert(KM_WaterGroundMounts, i);
                end
            end

            if (mountType == 232 or mountType == 231 or mountType == 254) and creatureID ~= 75207 and creatureID ~= 98718 then
                table.insert(KM_UnderWaterMounts, i);
            end
            
            if mountType == 241 then
                table.insert(KM_AQMounts, i);
            end
            
            -- Since the seahorse and reins of Poseidus is faster than sea turtle we can't just pick a underwater mount at random
            -- so we have to manually check for them.
            
            if creatureID == 75207 then
                hasSeahorse = i
            end

            if creatureID == 98718 then
                hasPoseidus = i
            end
            
            if mountType == 284 or creatureID == 30174 then
                table.insert(KM_NoSkillMounts, i);
            end
        end
    end
end

function KM_Mount()
    local CanFly, IsUnderwater = false, false;

    if IsSwimming() == true and select(1, GetMirrorTimerInfo(2)) == "BREATH" then
        -- I.e. if player is swimming and breath timer is active we assume they are underwater. Of course using underwater potions and so on messes this up.
        IsUnderwater = true;
    end
    
    if IsMounted() == true then
        Dismount();
        return;
    end
    
    if GetTime() > KM_LastCheck + 30 then
        KM_GetMounts();
    end
    
    if IsIndoors() == true then
        -- IsIndoors() returns nil if it is possible to mount, even if the location is indoors.
        UIErrorsFrame:AddMessage("KMount: You are indoor.", 1.0, 0.0, 0.0, 53, 5);
        return;
    end
    
    if HasFullControl() ~= true then
        -- Fear, cut scenes and so on
        UIErrorsFrame:AddMessage("KMount: Player is not in full controll.", 1.0, 0.0, 0.0, 53, 5);
        return;
    end

    if UnitAffectingCombat("player") == true then
        UIErrorsFrame:AddMessage("KMount: You are in combat.", 1.0, 0.0, 0.0, 53, 5);
        return;
    end
    
    if GetSpellBookItemInfo("Apprentice Riding") == nil and GetSpellBookItemInfo("Journeyman Riding") == nil and GetSpellBookItemInfo("Expert Riding") == nil and GetSpellBookItemInfo("Artisan Riding") == nil and GetSpellBookItemInfo("Master Riding") == nil then
        if #KM_NoSkillMounts > 0 then
            -- Mounts requiring no riding skill. I.e. Riding Turtle and Chauffeured Mekgineer's Chopper/Mechano-Hog
            C_MountJournal.Summon(KM_NoSkillMounts[math.floor(math.random()*#KM_NoSkillMounts)]);
        else
            UIErrorsFrame:AddMessage("KMount: You don't have any riding skill.", 1.0, 0.0, 0.0, 53, 5);
            return;
        end
    end
    
    -- GetSpellBookItemInfo
    
    -- Map has to be set to current location or be closed for GetCurrentMapContinent() to actually return the player's location
    -- Otherwise it will return the continent index of whatever continent the player is looking at on the map
    SetMapToCurrentZone();
    
    if (GetCurrentMapAreaID() == 610 or GetCurrentMapAreaID() == 613 or GetCurrentMapAreaID() == 614 or GetCurrentMapAreaID() == 615) and IsUnderwater == true and (hasPoseidus ~= false or hasSeahorse ~= false) then
        -- While in waters of Vashj'ir
        if hasPoseidus ~= false then
            C_MountJournal.Summon(hasPoseidus);
        elseif hasSeahorse ~= false then
            C_MountJournal.Summon(hasSeahorse);
        end

        return;
    end
    
    if IsUnderwater == true and #KM_UnderWaterMounts > 0 and KM_option_WaterMount == true then
        -- While in water
        C_MountJournal.Summon(KM_UnderWaterMounts[math.floor(math.random()*#KM_UnderWaterMounts)  + 1]);
        return;
    end
    
    if GetCurrentMapAreaID() == 772 and #KM_AQMounts > 0 then
        -- Ahn'Qiraj
        C_MountJournal.Summon(KM_AQMounts[math.floor(math.random()*#KM_AQMounts) + 1]);
        return;
    end
    
    if GetCurrentMapContinent() == 1 or GetCurrentMapContinent() == 2 or GetCurrentMapAreaID() == 640 and GetSpellBookItemInfo("Flight Master's License") ~= nil then
        -- Kalimdor, Eastern Kingdoms and Deepholm
        CanFly = true;
    elseif GetCurrentMapContinent() == 3 and (GetSpellBookItemInfo("Expert Riding") ~= nil or GetSpellBookItemInfo("Artisan Riding") ~= nil or GetSpellBookItemInfo("Master Riding") ~= nil) then
        -- Outland
        CanFly = true;
    elseif GetCurrentMapContinent() == 4 and GetSpellBookItemInfo("Cold Weather Flying") ~= nil then
        -- Northrend
        CanFly = true;
    elseif GetCurrentMapContinent() == 6 and GetSpellBookItemInfo("Wisdom of The Four Winds") ~= nil then
        -- Pandaria
        CanFly = true;
    elseif GetCurrentMapContinent() == 7 and select(4, GetAchievementInfo(10018)) == true then
        -- Draenor
        CanFly = true;
    end
    
    if GetSpellBookItemInfo("Apprentice Riding") ~= nil or GetSpellBookItemInfo("Journeyman Riding") ~= nil then
        CanFly = false;
    end
    
    if CanFly == true and IsFlyableArea() == true and IsUnderwater ~= true then
        -- Flying mount
        if DesiredFlyingMount ~= nil then
            C_MountJournal.Summon(DesiredFlyingMount);
        else
            C_MountJournal.Summon(KM_FlyingMounts[math.floor(math.random()*#KM_FlyingMounts) + 1]);
        end
    else
        -- Regular mount
        if DesiredGroundMount ~= nil then
            C_MountJournal.Summon(DesiredGroundMount);
        else
            if #KM_WaterGroundMounts > 0 and select(3, UnitClass("player")) ~= 6 and KM_PreferWaterGroundMount == true then
                -- Unless player is Death Knight we prioritize mounts that can walk on water as they're more convenient
                C_MountJournal.Summon(KM_WaterGroundMounts[math.floor(math.random()*#KM_WaterGroundMounts) + 1]);
            else
                C_MountJournal.Summon(KM_GroundMounts[math.floor(math.random()*#KM_GroundMounts) + 1]);
            end
        end
    end
end

local function handler(msg, editbox)
    local command, rest = msg:match("^(%S*)%s*(.-)$");
    
    if command == "get" then
        if rest == nil then
            print("Missing type. Valid types are 'ground' and 'flying'.");
            return;
        end
        
        local mtype = rest == "ground" and 0 or rest == "flying" and 1 or false;

        if mtype == false then
            print("Valid types are 'ground' and 'flying'.");
            return;
        end

        for i = 1, C_MountJournal.GetNumMounts(), 1 do
            local creatureName, _,_,_,_,_, isFavorite,_, faction,_, owned = C_MountJournal.GetMountInfo(i);
            local _,_,_,_, mountType = C_MountJournal.GetMountInfoExtra(i)

            --typeID = bit.band(3, typeID)
            if owned and (faction == nil or faction == PlayerFaction) then
                if mountType == 248 and mtype == 1 then
                    print(i .. ": " .. creatureName .. (isFavorite == true and " *" or isFavorite == false and ""));
                elseif mountType == 230 or mountType == 269 and mtype == 0 then
                    print(i .. ": " .. creatureName .. (isFavorite == true and " *" or isFavorite == false and ""));
                end
            end
        end
    elseif command == "setg" then
        if rest == nil then
            print("Missing mount index.");
            return;
        end
        DesiredGroundMount = rest;
    elseif command == "setf" then
        if rest == nil then
            print("Missing mount index.");
            return;
        end
        DesiredFlyingMount = rest;
    elseif command == "usetf" then
        DesiredFlyingMount = nil;
    elseif command == "usetg" then
        DesiredGroundMount = nil;
    elseif command == "togglew" then
        if KM_option_WaterMount == true then
            KM_option_WaterMount = false;
            print("Use Water Mount: false");
        else
            KM_option_WaterMount = true;
            print("Use Water Mount: true");
        end
    elseif command == "togglepw" then
        if KM_PreferWaterGroundMount == true then
            KM_PreferWaterGroundMount = false;
            print("Prefer Water Ground Mount: false");
        else
            KM_PreferWaterGroundMount = true;
            print("Prefer Water Ground Mount: true");
        end
    elseif command == "help" then
        print("\124c06418affKek\124c34ec7900Mount")
        print("\124c0c5f94ffGet <type> - \124cffffffffPrints all owned, usable mounts. Usefull to find the index for specific mounts.");
        print("\124c0c5f94ffSetg - \124cffffffffSet the desired ground mount.");
        print("\124c0c5f94ffUsetg - \124cffffffffUnsets the desired ground mount.");
        print("\124c0c5f94ffSetf - \124cffffffffSet the desired flying mount.");
        print("\124c0c5f94ffUsetf - \124cffffffffUnsets the desired flying mount.");
        print("\124c0c5f94ffTogglew - \124cffffffffToggles water mounts (except Vashj'ir specific mounts).");
        print("\124c0c5f94ffTogglepw - \124cffffffffToggles preference for ground mounts that can walk on water.");
        print("\124c0c5f94ffHelp - \124cffffffffShows this list of available commands.");
    else
        KM_Mount();
    end
end

do
    KM_GetMounts();
    -- Slash Handler
    SLASH_KekMount1 = "/kmount"
    SlashCmdList.KekMount = handler
end