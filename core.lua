local KM_GroundMounts, KM_WaterGroundMounts, KM_UnderWaterMounts, KM_NoSkillMounts, KM_FlyingMounts, KM_AQMounts, MMFavGround, MMFavFlying, hasSeahorse
local KM_QueueCheck, KMDebug = false, false
local PlayerFaction = select(1, UnitFactionGroup("player"));
local KMname = "\124c0c5f94ffKMount: \124cffffffff";
local KMnamedb = "\124c9021cfffKMount debug: \124cffffffff";
local KMVer = "1.5.0";
local KMlastuse, UsableMountCount = 0, 0
local underwaterSpells = {76377, 196344, 7179, 22808, 11789, 40621, 44235, 116271}
local MountFrame, LoginFrame = CreateFrame("Frame"), CreateFrame("Frame")
PlayerFaction = PlayerFaction == "Horde" and 0 or PlayerFaction == "Alliance" and 1;

MountFrame.time = 0
MountFrame:RegisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")
MountFrame:SetScript("OnEvent",
    function(self,event) 
        -- Always check if usability changes
        KM_QueueCheck = true
        
        -- Vashj'ir surface check courtesy of Banknorris
        if not IsSubmerged() then
            MountFrame.time = GetTime();
            if KMDebug == true then
                print(KMnamedb .. "Resurfacing/Submerging detected.")
            end
        end
    end
)

local function indexOf(t, object)
    if type(t) == "table" then
        for i = 1, #t do
            if object == t[i] then
                return i
            end
        end
        return -1
    end
end

local function UpdateMountList()
    KM_GroundMounts, KM_FlyingMounts, KM_UnderWaterMounts, KM_NoSkillMounts, KM_WaterGroundMounts, KM_AQMounts, MMFavGround, MMFavFlying, hasSeahorse, UsableMountCount = unpack(KM_GetUsableMounts())
    KM_QueueCheck = false
    
    if KMDebug == true then
        print(KMnamedb .. "Updated mount list. ")
    end
end

-- Types are 1 for ground mount and 2 for flying mount
local function KM_Mount(forceType)
    local CanFly, IsUnderwater = false, false;
    local underwaterBreathing = false

    if KMlastuse + 0.2 > GetTime() then
        return;
    else
        KMlastuse = GetTime()
    end

    if IsMounted() == true and forceType == nil then
        Dismount();
        return;
    end
    
    if UnitAffectingCombat("player") == true then
        UIErrorsFrame:AddMessage("KMount: You are in combat.", 1.0, 0.0, 0.0, 53, 5);
        return;
    end
    
    if UnitIsDeadOrGhost("player") == true then
        UIErrorsFrame:AddMessage("KMount: You are dead.", 1.0, 0.0, 0.0, 53, 5);
        return;
    end
    
    if IsFalling() or IsPlayerMoving() then
        UIErrorsFrame:AddMessage("KMount: Player is moving.", 1.0, 0.0, 0.0, 53, 5);
        return;
    end
    
    if IsMounted() and IsFlying() and kmountdb["fdismount"] ~= true then
        UIErrorsFrame:AddMessage("KMount: Dismounting while flying disallowed by setting.", 1.0, 0.0, 0.0, 53, 5);
        return;
    end
    
    if KM_QueueCheck or (#KM_FlyingMounts == 0 or #KM_GroundMounts == 0) then
        UpdateMountList();
    end
    
    if UsableMountCount == 0 then
        UIErrorsFrame:AddMessage("KMount: Found no usable mount.", 1.0, 0.0, 0.0, 53, 5);
        KM_QueueCheck = true
        return;
    end
    
    local i = 1
    
    if IsSubmerged() == true then
        -- Underwater breathing spells will interfere with the underwater check so make sure if any are active
        while UnitBuff("player", i) ~= nil do
            local _, _, _, _, _, _, _, _, _, _, spellID = UnitBuff("player", i)
            if indexOf(underwaterSpells, spellID) ~= -1 then
                underwaterBreathing = true
                break
            end
            i = i + 1
        end
        
        if select(1, GetMirrorTimerInfo(2)) == "BREATH" or underwaterBreathing == true then
            -- I.e. if player is swimming and breath timer is active we assume they are underwater.
            IsUnderwater = true;
        end
    end
    
    if IsIndoors() == true then
        -- IsIndoors() returns nil if it is possible to mount, even if the location is indoors.
        UIErrorsFrame:AddMessage("KMount: You are indoors.", 1.0, 0.0, 0.0, 53, 5);
        return;
    end

    if HasFullControl() ~= true then
        -- Fear, cut scenes and so on
        UIErrorsFrame:AddMessage("KMount: Player not in full controll.", 1.0, 0.0, 0.0, 53, 5);
        return;
    end

    if GetSpellBookItemInfo("Apprentice Riding") == nil and GetSpellBookItemInfo("Journeyman Riding") == nil and GetSpellBookItemInfo("Expert Riding") == nil and GetSpellBookItemInfo("Artisan Riding") == nil and GetSpellBookItemInfo("Master Riding") == nil then
        if #KM_NoSkillMounts > 0 then
            -- Mounts requiring no riding skill. I.e. Riding Turtle and Chauffeured Mekgineer's Chopper/Mechano-Hog
            C_MountJournal.SummonByID(KM_NoSkillMounts[math.floor(math.random()*#KM_NoSkillMounts)]);
        else
            UIErrorsFrame:AddMessage("KMount: You don't have any riding skill.", 1.0, 0.0, 0.0, 53, 5);
            return;
        end
    end

    -- GetSpellBookItemInfo

    -- Map has to be set to current location or be closed for GetCurrentMapContinent() to actually return the player's location
    -- Otherwise it will return the continent index of whatever continent the player is looking at on the map
    SetMapToCurrentZone();

    if (GetCurrentMapAreaID() == 610 or GetCurrentMapAreaID() == 613 or GetCurrentMapAreaID() == 614 or GetCurrentMapAreaID() == 615) and IsUnderwater == true and hasSeahorse ~= false and GetTime() - MountFrame.time > 2 then
        -- While in waters of Vashj'ir
        C_MountJournal.SummonByID(hasSeahorse);

        return;
    end

    if IsUnderwater == true and #KM_UnderWaterMounts > 0 and kmountdb["wmount"] == true and GetTime() - MountFrame.time > 2 then
        -- While in water
        C_MountJournal.SummonByID(KM_UnderWaterMounts[math.floor(math.random()*#KM_UnderWaterMounts)  + 1]);
        return;
    end

    if GetCurrentMapAreaID() == 772 and #KM_AQMounts > 0 then
        -- Ahn'Qiraj
        C_MountJournal.SummonByID(KM_AQMounts[math.floor(math.random()*#KM_AQMounts) + 1]);
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

    if ((CanFly == true and IsFlyableArea() == true) or forceType == 2) and forceType ~= 1 then
        -- Flying mount
        
        if forceType == 2 and #KM_FlyingMounts == 0 then
            print(KMname .. "Tried forcing flying mount, but no such mount available.");
            return;
        end
        
        if kmountdb["UseBlizFav"] == true and #MMFavFlying > 0 then
            C_MountJournal.SummonByID(MMFavFlying[math.floor(math.random()*#MMFavFlying) + 1]);
        elseif kmountdb["PreferredFMount"] ~= nil then
            C_MountJournal.SummonByID(kmountdb["PreferredFMount"]);
        else
            C_MountJournal.SummonByID(KM_FlyingMounts[math.floor(math.random()*#KM_FlyingMounts) + 1]);
        end
    else
        -- Regular mount
        if #KM_WaterGroundMounts > 0 and kmountdb["preferwmount"] == true then
            -- Unless player is Death Knight we prioritize mounts that can walk on water as they're more convenient
            C_MountJournal.SummonByID(KM_WaterGroundMounts[math.floor(math.random()*#KM_WaterGroundMounts) + 1]);
        elseif kmountdb["UseBlizFav"] == true and #MMFavGround > 0 then
            C_MountJournal.SummonByID(MMFavGround[math.floor(math.random()*#MMFavGround) + 1]);
        elseif kmountdb["PreferredGMount"] ~= nil then
            C_MountJournal.SummonByID(kmountdb["PreferredGMount"]);
        else
            C_MountJournal.SummonByID(KM_GroundMounts[math.floor(math.random()*#KM_GroundMounts) + 1]);
        end
    end
end

local function isValidMount(n, t)
    -- t is type of mount. 1 = Ground, 2 = Flying

    n = tonumber(n);

    if C_MountJournal.GetMountInfoByID(n) == nil then
        print(KMname .. "Invalid mount index.");
        return false;
    end

    if select(9, C_MountJournal.GetMountInfoByID(n)) ~= nil and select(9, C_MountJournal.GetMountInfoByID(n)) ~= PlayerFaction then
        -- Wrong faction
        print(KMname .. "'" .. select(1, C_MountJournal.GetMountInfoByID(n)) .. "' is not usable by " .. select(1, UnitFactionGroup("player")) .. " characters.");
        return false;
    end
    
    if not select(11, C_MountJournal.GetMountInfoByID(n)) then
        -- Isn't owned
        print(KMname .. "You do not own '" .. select(1, C_MountJournal.GetMountInfoByID(n)) .. "'.");
        return false;
    end

    if t == 1 and indexOf(KM_GroundMounts, n) == -1 and indexOf(KM_NoSkillMounts, n) == -1 then
        -- Check if mount is in array of valid ground mounts
        print(KMname .. "'" .. select(1, C_MountJournal.GetMountInfoByID(n)) .. "' is not available as a ground mount for this character.");
        return false;
    end

    if t == 2 and indexOf(KM_FlyingMounts, n) == -1 then
        -- Check if mount is in array of valid flying mounts
        print(KMname .. "'" .. select(1, C_MountJournal.GetMountInfoByID(n)) .. "' is not available as a flying mount for this character.");
        return false;
    end

    return true;
end

local function updateSettings(reset)
    if reset then
        kmountdb = {};
    end
    
    if kmountdb == nil then
        kmountdb = {};
    end

    if kmountdb["wmount"] == nil then
        kmountdb["wmount"] = true;
    end

    if kmountdb["fdismount"] == nil then
        kmountdb["fdismount"] = true;
    end

    if kmountdb["UseBlizFav"] == nil then
        kmountdb["UseBlizFav"] = true;
    end

    if select(3, UnitClass("player")) ~= 6 and kmountdb["preferwmount"] == nil then
        kmountdb["preferwmount"] = true;
    elseif kmountdb["preferwmount"] == nil then
        kmountdb["preferwmount"] = false;
    end
end

local function handler(msg, editbox)
    local command, rest = msg:match("^(%S*)%s*(.-)$");
    
    command = string.lower(command);

    if command == "get" then
        if rest == nil then
            print(KMname .. "Missing type. Valid types are 'ground' and 'flying'.");
            return;
        end

        local mtype = rest == "ground" and 1 or rest == "flying" and 2 or false;

        if mtype == false then
            print(KMname .. "Valid types are 'ground' and 'flying'.");
            return;
        end

        local count = 0;
        
        for i = 1, KM_GetMountInfo.count, 1 do
            local creatureName, creatureID, summonable, isFavorite, isFactionSpecific, faction, owned, mountID, mountType = unpack(KM_GetMountInfo[i])

            if owned and summonable and(faction == nil or faction == PlayerFaction) then
                if mountType == 248 and mtype == 2 then
                    count = count + 1;
                    print("\124c0c5f94ff" .. creatureName .. "\124cffffffff: " .. mountID .. (isFavorite == true and " *" or isFavorite == false and ""));
                elseif (mountType == 230 or mountType == 269) and mtype == 1 then
                    count = count + 1;
                    print("\124c0c5f94ff" .. creatureName .. "\124cffffffff: " .. mountID .. (isFavorite == true and " *" or isFavorite == false and ""));
                end
            end
        end
        
        if count == 0 then
            print(KMname .. "No mounts available in that category.");
        end
    elseif command == "getbyname" then
        for i = 1, KM_GetMountInfo.count, 1 do
            local creatureName = KM_GetMountInfo[i][1];
            if creatureName ~= nil then
                if strlower(strsub(creatureName, 1, strlen(rest))) == strlower(rest) then
                    print(KMname .. "Index of \124c0c5f94ff" .. creatureName .. "\124cffffffff is \124c0c5f94ff" .. KM_GetMountInfo[i][8] .. "\124cffffffff.");
                    return;
                end
            end
        end
        print(KMname .. " '" .. rest .. "' did not match any mounts.");
    elseif command == "setg" then
        if isValidMount(rest, 1) then
            kmountdb["PreferredGMount"] = rest;
            print(KMname .. "Ground mount preference set to " .. select(1, C_MountJournal.GetMountInfoByID(kmountdb["PreferredGMount"])) .. ".");
        end
    elseif command == "setf" then
        if isValidMount(rest, 2) then
            kmountdb["PreferredFMount"] = rest;
            print(KMname .. "Flying mount preference set to " .. select(1, C_MountJournal.GetMountInfoByID(kmountdb["PreferredFMount"])) .. ".");
        end
    elseif command == "usetf" then
        kmountdb["PreferredFMount"] = nil;
        print(KMname .. "Unset preferred flying mount.");
    elseif command == "usetg" then
        kmountdb["PreferredGMount"] = nil;
        print(KMname .. "Unset preferred ground mount.");
    elseif command == "togglefd" then
        if kmountdb["fdismount"] == true then
            kmountdb["fdismount"] = false;
            print(KMname .. "Will \124cFFFF0000no longer\124cFFFFFFFF dismount if player is flying.");
        else
            kmountdb["fdismount"] = true;
            print(KMname .. "Will dismount even if player is flying.");
        end
    elseif command == "togglew" then
        if kmountdb["wmount"] == true then
            kmountdb["wmount"] = false;
            print(KMname .. "Will \124cFFFF0000no longer\124cFFFFFFFF prefer underwater mounts while underwater.");
        else
            kmountdb["wmount"] = true;
            print(KMname .. "Will now prefer underwater mounts while underwater.");
        end
    elseif command == "togglepw" then
        if kmountdb["preferwmount"] == true then
            kmountdb["preferwmount"] = false;
            print(KMname .. "Will \124cFFFF0000no longer\124cFFFFFFFF prefer water walking mounts.");
        else
            kmountdb["preferwmount"] = true;
            print(KMname .. "Will now prefer water walking mounts.");
        end
    elseif command == "info" then
        print("\124c06418affKek\124c34ec7900Mount\124cFFFFFFFF " .. KMVer)
        print("\124c0c5f94ffPreferred Ground Mount: \124cffffffff" .. (kmountdb["PreferredGMount"] ~= nil and select(1, C_MountJournal.GetMountInfoByID(kmountdb["PreferredGMount"])) or "None"));
        print("\124c0c5f94ffPreferred Flying Mount: \124cffffffff" .. (kmountdb["PreferredFMount"] ~= nil and select(1, C_MountJournal.GetMountInfoByID(kmountdb["PreferredFMount"])) or "None"));
        print("\124c0c5f94ffDismount in flight: \124cffffffff" .. (kmountdb["fdismount"] == true and "\124cFF00FF00Yes\124cFFFFFFFF" or "\124cFFFF0000No\124cFFFFFFFF"));
        print("\124c0c5f94ffPrefer Underwater Mount(s): \124cffffffff" .. (kmountdb["wmount"] == true and "\124cFF00FF00Yes\124cFFFFFFFF" or "\124cFFFF0000No\124cFFFFFFFF"));
        print("\124c0c5f94ffPrefer Blizzard's mount manager favorite(s): \124cffffffff" .. (kmountdb["UseBlizFav"] == true and "\124cFF00FF00Yes\124cFFFFFFFF" or "\124cFFFF0000No\124cFFFFFFFF"));
        print("\124c0c5f94ffPrefer water walking mount(s): \124cffffffff" .. (kmountdb["preferwmount"] == true and "\124cFF00FF00Yes\124cFFFFFFFF" or "\124cFFFF0000No\124cFFFFFFFF"));
    elseif command == "reset" then
        updateSettings(true);
        print("\124c0c5f94ffKMount:\124cffffffff Settings for '" .. UnitName("player") .. "' have been reset.");
    elseif command == "g" then
        KM_Mount(1);
    elseif command == "f" then
        KM_Mount(2);
    elseif command == "debug" then
        if KMDebug == true then
            KMDebug = false;
            print(KMname .. "Debug mode deactivated");
        else
            KMDebug = true;
            print(KMname .. "Debug mode activated");
        end
    elseif command == "togglebf" then
        if kmountdb["UseBlizFav"] == true then
            kmountdb["UseBlizFav"] = false;
            print(KMname .. "Will \124cFFFF0000no longer\124cFFFFFFFF prefer favorite(s) in mount manager.");
        else
            kmountdb["UseBlizFav"] = true;
            print(KMname .. "Will now prefer favorite(s) in mount manager.");
        end
    elseif command == "update" then
        UpdateMountList()
        print(KMname .. "Updated mount list.");
    elseif command == "mountcount" then
        local GroundMounts, FlyingMounts, UnderWaterMounts, NoSkillMounts, WaterGroundMounts, AQMounts, FavGround, FavFlying = unpack(KM_GetUsableMounts())
        print(KMname .. "Mount count:\nGround: " .. #GroundMounts .. "\nFlying: " .. #FlyingMounts .. "\nUnderwater: " .. #UnderWaterMounts .. "\nSkill-less: " .. #NoSkillMounts .. "\nWaterwalking: " .. #WaterGroundMounts .. "\nAQ: " .. #AQMounts .. "\nFav Ground: " .. #FavGround .. "\nFav Flying: " .. #FavFlying);
    elseif command == "help" then
        print("\124c06418affKek\124c34ec7900Mount")
        print("\124c0c5f94ffGet <type> - \124cffffffffPrints all owned, usable mounts. Usefull to find the index for specific mounts.");
        print("\124c0c5f94ffGetbyname <query> - \124cffffffffSearch through all mounts (even unavailable) and returns an index number if a match is found.");
        print("\124c0c5f94ffSetg - \124cffffffffSet the desired ground mount.");
        print("\124c0c5f94ffUsetg - \124cffffffffUnsets the desired ground mount.");
        print("\124c0c5f94ffSetf - \124cffffffffSet the desired flying mount.");
        print("\124c0c5f94ffUsetf - \124cffffffffUnsets the desired flying mount.");
        print("\124c0c5f94ffTogglew - \124cffffffffToggles water mounts (except Vashj'ir specific mounts).");
        print("\124c0c5f94ffTogglepw - \124cffffffffToggles preference for ground mounts that can walk on water.");
        print("\124c0c5f94ffTogglefd - \124cffffffffToggles dismount preference while flying.");
        print("\124c0c5f94ffTogglebf - \124cffffffffToggles use of mount manager favorite(s).");
        print("\124c0c5f94ffF - \124cffffffffForce summon flying mount.");
        print("\124c0c5f94ffG - \124cffffffffForce summon ground mount.");
        print("\124c0c5f94ffInfo - \124cffffffffDisplays settings for current character.");
        print("\124c0c5f94ffReset - \124cffffffffReset settings for current character.");
        print("\124c0c5f94ffHelp - \124cffffffffShow this list.");
        print("\124cffffffffFor more info visit curse.");
    elseif command ~= "" then
        print(KMname .. "'" .. command .. "' is not a valid command.");
    else
        KM_Mount();
    end
end

local function KM_mountJournalHook(self, e, ...)
    if e == "ADDON_LOADED" and select(1,...) == "Blizzard_Collections" then
        self:UnregisterEvent("ADDON_LOADED")
        MountJournal:HookScript("OnHide", function(self)
            KM_QueueCheck = true
        end)
    elseif e == "PLAYER_LOGIN" then
        if IsAddOnLoaded("Blizzard_Collections") then
            OnEvent(self, "ADDON_LOADED", "Blizzard_Collections")
        else
            self:RegisterEvent("ADDON_LOADED")
        end
    end
end

-- Courtsey of Ro/US
LoginFrame:SetScript("OnEvent", function(self, e, ...) 
    KM_mountJournalHook(self, e, ...)
    UpdateMountList();
end)

do
    -- Slash Handler
    SLASH_KekMount1 = "/kmount"
    SlashCmdList.KekMount = handler
    updateSettings(false);
    LoginFrame:RegisterEvent("PLAYER_LOGIN")
end