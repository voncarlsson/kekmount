local KM_GroundMounts, KM_WaterGroundMounts, KM_UnderWaterMounts, KM_NoSkillMounts, KM_FlyingMounts, KM_AQMounts, MMFavGround, MMFavFlying, hasSeahorse
local KM_QueueCheck, KMDebug, KM_nofly = true, false, false
local KMname = "\124c0c5f94ffKMount: \124cffffffff";
local KMnamedb = "\124c9021cfffKMount debug: \124cffffffff";
local KMVer = "1.7.0";
local KM_FPtime = GetTime();
local KMlastuse, UsableMountCount = 0, 0
local NoMountZones = {}
local underwaterSpells = {76377, 196344, 7179, 22808, 11789, 40621, 44235, 116271, 188042, 1066}
local WaterWalkingBlacklist = {1014, 480, 29, 28, 17, 281, 261, 1035}
local MountFrame, LoginFrame = CreateFrame("Frame"), CreateFrame("Frame")

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

local function IsAtMapID(mapID)
    local tempMapID, currentMapID = GetCurrentMapAreaID();
    local out = false
    
    SetMapToCurrentZone();
    
    currentMapID = GetCurrentMapAreaID();
    
    if type(mapID) == "number" then
        mapID = {mapID}
    end
    
    if type(mapID) == "table" then
        for i = 1, #mapID do
            if mapID[i] == currentMapID then
                out = true
            end
        end
    end
    
    SetMapByID(tempMapID);
    
    return out
end

local function UpdateMountList()
    if UnitAffectingCombat("player") then
        return false
    end

    KM_GroundMounts, KM_FlyingMounts, KM_UnderWaterMounts, KM_NoSkillMounts, KM_WaterGroundMounts, KM_AQMounts, MMFavGround, MMFavFlying, hasSeahorse, UsableMountCount = unpack(kekmount.GetUsableMounts())
    KM_QueueCheck = false
    
    if KMDebug == true then
        print(KMnamedb .. "Updated mount list. ")
    end
end

local function WeightedRandom(weights, list)
    local wsum, sum, rnum = 0, 0, 0
    
    for i = 1, #weights do
        wsum = wsum + weights[i][2]
    end
    
    sum = #list + wsum
    rnum = math.floor(math.random() * sum) + 1
    
    if rnum <= wsum then
        local count = 0
        for i = 1, #weights do
            if rnum >= count and rnum <= count + weights[i][2] then
                return weights[i][1]
            end
            count = count + weights[i][2]
        end
    end
    
    return list[(rnum - wsum)]
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

    if IsMounted() and IsFlying() and kmountdb["fdismount"] == true then
        if kmountdb["fdismountmethod"] == 2 and GetTime() - KM_FPtime > 1.5 then
            KM_FPtime = GetTime()
            UIErrorsFrame:AddMessage("KMount: Tap again to dismount.", 1.0, 0.0, 0.0, 53, 5);
            return
        elseif kmountdb["fdismountmethod"] == 1 then
            UIErrorsFrame:AddMessage("KMount: Dismounting while flying disallowed by setting.", 1.0, 0.0, 0.0, 53, 5);
            return;
        end
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
            if kekmount.IndexOf(underwaterSpells, spellID) ~= -1 then
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

    -- Master 90265, Artisan 34091, Expert 34090, Journeyman 33391, Apprentice 33388
    
    if not IsSpellKnown(90265) and not IsSpellKnown(34091) and not IsSpellKnown(34090) and not IsSpellKnown(33391) and not IsSpellKnown(33388) then
        if #KM_NoSkillMounts > 0 then
            -- Mounts requiring no riding skill. I.e. Riding Turtle and Chauffeured Mekgineer's Chopper/Mechano-Hog
            C_MountJournal.SummonByID(KM_NoSkillMounts[math.floor(math.random()*#KM_NoSkillMounts) + 1]);
            return
        else
            UIErrorsFrame:AddMessage("KMount: You don't have any riding skill.", 1.0, 0.0, 0.0, 53, 5);
            return;
        end
    end

    if IsAtMapID({610, 613, 614, 615}) and IsUnderwater == true and hasSeahorse ~= false and GetTime() - MountFrame.time > 2 then
        -- While in waters of Vashj'ir
        C_MountJournal.SummonByID(hasSeahorse);

        return;
    end

    if IsUnderwater == true and #KM_UnderWaterMounts > 0 and kmountdb["wmount"] == true and GetTime() - MountFrame.time > 2 then
        -- While in water
        C_MountJournal.SummonByID(KM_UnderWaterMounts[math.floor(math.random()*#KM_UnderWaterMounts)  + 1]);
        return;
    end

    if IsAtMapID({772}) and #KM_AQMounts > 0 then
        -- Ahn'Qiraj
        C_MountJournal.SummonByID(KM_AQMounts[math.floor(math.random()*#KM_AQMounts) + 1]);
        return;
    end

    local tempMapID = GetCurrentMapAreaID();
    
    SetMapToCurrentZone();
    
    if GetCurrentMapContinent() == 1 or GetCurrentMapContinent() == 2 or GetCurrentMapAreaID() == 640 and IsSpellKnown(90267) then
        -- Kalimdor, Eastern Kingdoms and Deepholm
        -- Flight Master's License 90267
        CanFly = true
    elseif GetCurrentMapContinent() == 3 and (IsSpellKnown(34090) or IsSpellKnown(34091) or IsSpellKnown(90265)) then
        -- Outland
        CanFly = true
    elseif GetCurrentMapContinent() == 4 and IsSpellKnown(54197) then
        -- Northrend
        -- Cold Weather Flying 54197
        CanFly = true
    elseif GetCurrentMapContinent() == 6 and IsSpellKnown(115913) then
        -- Pandaria
        -- Wisdom of the Four Winds 115913
        CanFly = true
    elseif GetCurrentMapContinent() == 7 and IsSpellKnown(191645) then
        -- Draenor
        -- 191645 is hidden passive from "Draenor Pathfinder"
        CanFly = true
    elseif GetCurrentMapContinent() == 8 and IsSpellKnown(233368) then
        -- Broken Isles
        -- 233368 is hidden passive from part 2 of "Broken Isles Pathfinder"
        CanFly = true
    end
    
    SetMapByID(tempMapID);

    if KM_nofly == true then
        CanFly = false
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
        local areaBlacklisted = false
        if kmountdb["usewwblacklist"] then
            if kekmount.IndexOf(WaterWalkingBlacklist, GetCurrentMapAreaID()) ~= -1 and not IsSwimming() then
                areaBlacklisted = true
                if KMDebug then
                    print(KMnamedb .. "Map ID is blacklisted.")
                end
            end
        end
        -- Regular mount
        if #KM_WaterGroundMounts > 0 and kmountdb["preferwmount"] == true and not areaBlacklisted and GetNumBattlefieldScores() == 0 then
            -- Unless player is Death Knight we prioritize mounts that can walk on water as they're more convenient
            -- Also turn off the function if the player is in a battleground or arena since water walking mounts don't work there
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

kekmount.summon = KM_Mount

local function isValidMount(n, t)
    -- t is type of mount. 1 = Ground, 2 = Flying

    n = tonumber(n);

    if C_MountJournal.GetMountInfoByID(n) == nil then
        print(KMname .. "Invalid mount index.");
        return false;
    end

    if select(9, C_MountJournal.GetMountInfoByID(n)) ~= nil and select(9, C_MountJournal.GetMountInfoByID(n)) ~= kekmount.PlayerFaction then
        -- Wrong faction
        print(KMname .. "'" .. select(1, C_MountJournal.GetMountInfoByID(n)) .. "' is not usable by " .. select(1, UnitFactionGroup("player")) .. " characters.");
        return false;
    end
    
    if not select(11, C_MountJournal.GetMountInfoByID(n)) then
        -- Isn't owned
        print(KMname .. "You do not own '" .. select(1, C_MountJournal.GetMountInfoByID(n)) .. "'.");
        return false;
    end

    if t == 1 and kekmount.IndexOf(KM_GroundMounts, n) == -1 and kekmount.IndexOf(KM_NoSkillMounts, n) == -1 then
        -- Check if mount is in array of valid ground mounts
        print(KMname .. "'" .. select(1, C_MountJournal.GetMountInfoByID(n)) .. "' is not available as a ground mount for this character.");
        return false;
    end

    if t == 2 and kekmount.IndexOf(KM_FlyingMounts, n) == -1 then
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
        -- Underwater Mounts
        kmountdb["wmount"] = true;
    end

    if kmountdb["fdismount"] == nil then
        -- In-flight dismount protection
        kmountdb["fdismount"] = false;
    end

    if kmountdb["UseBlizFav"] == nil then
        kmountdb["UseBlizFav"] = true;
    end

    if kmountdb["fdismountmethod"] == nil then
        kmountdb["fdismountmethod"] = 1;
    end

    if kmountdb["usewwblacklist"] == nil then
        kmountdb["usewwblacklist"] = false;
    end
    
    if kmountdb["useambiguouslist"] == nil then
        -- Treat ground mount look-alikes as ground mounts
        kmountdb["useambiguouslist"] = true;
    end

    if select(3, UnitClass("player")) ~= 6 and kmountdb["preferwmount"] == nil then
        kmountdb["preferwmount"] = true;
    elseif kmountdb["preferwmount"] == nil then
        -- Death Knight
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
        
        for i = 1, kekmount.GetMountInfo.count, 1 do
            local creatureName, creatureID, summonable, isFavorite, isFactionSpecific, faction, owned, mountID, mountType = unpack(kekmount.GetMountInfo[i])

            if owned and summonable and(faction == nil or faction == kekmount.PlayerFaction) then
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
    elseif command == "indexbyname" or command == "ibn" then
        for i = 1, kekmount.GetMountInfo.count, 1 do
            local creatureName = kekmount.GetMountInfo[i][1];
            if creatureName ~= nil then
                if strlower(strsub(creatureName, 1, strlen(rest))) == strlower(rest) then
                    local MInfo = kekmount.GetMountInfo[i]
                    print(KMname .. "Index of \124c0c5f94ff" .. creatureName .. "\124cffffffff is \124c0c5f94ff" .. MInfo[8] .. "\124cffffffff (Internal: " .. i .. ").");
                    if KMDebug then
                        print(KMnamedb .. "Internal: " .. i .. " | CID: " .. MInfo[2] .. " | Type: " .. MInfo[9] .. " | Summonable: " .. (MInfo[3] and "True" or "False") .. ".")
                    end
                    return
                end
            end
        end
        print(KMname .. " '" .. rest .. "' did not match any mounts.");
    elseif command == "namebyindex" or command == "nbi" then
        rest = tonumber(rest)
        if rest == nil then
            print(KMname .. "No index or invalid index format provided. Index must be a number.");
            return
        end

        local name = kekmount.NameByIndex(rest)
        
        if not name then
            print(KMname .. "No mount at index " .. rest .. " found.")
            return
        end

        print(KMname .. "Mount at index \124c0c5f94ff" .. rest .. "\124cffffffff is \124c0c5f94ff" .. name .. "\124cffffffff.");
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
            print(KMname .. "In-flight dismount protection \124cFFFF0000TURNED OFF\124cFFFFFFFF.");
        else
            kmountdb["fdismount"] = true;
            print(KMname .. "In-flight dismount protection is now active. See '/kmount info' for what method is used.");
        end
    elseif command == "togglew" then
        if kmountdb["wmount"] == true then
            kmountdb["wmount"] = false;
            print(KMname .. "Will \124cFFFF0000NO LONGER\124cFFFFFFFF prefer underwater mounts while underwater.");
        else
            kmountdb["wmount"] = true;
            print(KMname .. "Will now prefer underwater mounts while underwater.");
        end
    elseif command == "togglepw" then
        if kmountdb["preferwmount"] == true then
            kmountdb["preferwmount"] = false;
            print(KMname .. "Will \124cFFFF0000NO LONGER\124cFFFFFFFF prefer water walking mounts.");
        else
            kmountdb["preferwmount"] = true;
            print(KMname .. "Will now prefer water walking mounts.");
        end
    elseif command == "setfd" then
        if rest == "1" then
            kmountdb["fdismountmethod"] = 1;
        elseif rest == "2" then
            kmountdb["fdismountmethod"] = 2;
        else
            print(KMname .. "In-flight dismount protection methods are:\n1 - Completely turns off ability to dismount in-flight (default).\n2 - Double tap within 1.5 seconds to dismount in-flight.");
        end
    elseif command == "toggleam" then
        if kmountdb["useambiguouslist"] == true then
            kmountdb["useambiguouslist"] = false;
            print(KMname .. "Will \124cFFFF0000NO LONGER\124cFFFFFFFF add ground mount look-alikes to ground mount list.");
        else
            kmountdb["useambiguouslist"] = true;
            print(KMname .. "Will now add ground mount look-alikes to ground mount list.");
        end
    elseif command == "info" then
        local GStatus = (kmountdb["PreferredGMount"] ~= nil and select(1, C_MountJournal.GetMountInfoByID(kmountdb["PreferredGMount"])) or "None (random until set)")
        local FStatus = (kmountdb["PreferredFMount"] ~= nil and select(1, C_MountJournal.GetMountInfoByID(kmountdb["PreferredFMount"])) or "None (random until set)")

        if kmountdb["UseBlizFav"] then
            GStatus = "\124cff999999Overriden by blizzard mount manager\124cFFFFFFFF"
            FStatus = GStatus
        elseif not kmountdb["UseBlizFav"] and (kmountdb["preferwmount"] and #KM_WaterGroundMounts > 0) then
            GStatus = "\124cff999999Overriden by \124c0c5f94fftogglepw\124cFFFFFFFF"
        end

        print("\124c06418affKek\124c34ec7900Mount\124cFFFFFFFF " .. KMVer)
        print("\124c0c5f94ffPreferred Ground Mount: \124cffffffff" .. GStatus);
        print("\124c0c5f94ffPreferred Flying Mount: \124cffffffff" .. FStatus);
        print("\124c0c5f94ffIn-flight dismount protection: \124cffffffff" .. (kmountdb["fdismount"] == true and "\124cFF00FF00Yes\124cFFFFFFFF" or "\124cFFFF0000No\124cFFFFFFFF"));
        if kmountdb["fdismount"] == true then
            print("\124c0c5f94ffIn-flight dismount protection method: \124cffffffff" .. (kmountdb["fdismountmethod"] == 1 and "No dismount allowed." or "Double tap to dismount."));
        end
        print("\124c0c5f94ffPrefer Underwater Mount(s): \124cffffffff" .. (kmountdb["wmount"] == true and "\124cFF00FF00Yes\124cFFFFFFFF" or "\124cFFFF0000No\124cFFFFFFFF"));
        print("\124c0c5f94ffPrefer Blizzard's mount manager favorite(s): \124cffffffff" .. (kmountdb["UseBlizFav"] == true and "\124cFF00FF00Yes\124cFFFFFFFF" or "\124cFFFF0000No\124cFFFFFFFF"));
        print("\124c0c5f94ffPrefer water walking mount(s): \124cffffffff" .. (kmountdb["preferwmount"] == true and "\124cFF00FF00Yes\124cFFFFFFFF" or "\124cFFFF0000No\124cFFFFFFFF"));
        print("\124c0c5f94ffUse ambiguous flying mounts as ground mount(s): \124cffffffff" .. (kmountdb["useambiguouslist"] == true and "\124cFF00FF00Yes\124cFFFFFFFF" or "\124cFFFF0000No\124cFFFFFFFF"));
        print("\124c0c5f94ffUse water walking blacklist: \124cffffffff" .. (kmountdb["usewwblacklist"] == true and "\124cFF00FF00Yes\124cFFFFFFFF" or "\124cFFFF0000No\124cFFFFFFFF"));
        print("\124c0c5f94ffSession no-fly: \124cffffffff" .. (KM_nofly and "\124cFF00FF00Yes\124cFFFFFFFF" or "\124cFFFF0000No\124cFFFFFFFF"));
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
            print(KMname .. "Will \124cFFFF0000NO LONGER\124cFFFFFFFF prefer favorite(s) in mount manager.");
        else
            kmountdb["UseBlizFav"] = true;
            print(KMname .. "Will now prefer favorite(s) in mount manager.");
        end
    elseif command == "togglewb" then
        if kmountdb["usewwblacklist"] == true then
            kmountdb["usewwblacklist"] = false;
            print(KMname .. "Will \124cFFFF0000NO LONGER\124cFFFFFFFF use waterwalking region blacklist.");
        else
            kmountdb["usewwblacklist"] = true;
            print(KMname .. "Will now not prefer waterwalking mounts in blacklisted regions.");
        end
    elseif command == "update" then
        UpdateMountList()
        print(KMname .. "Updated mount list.");
    elseif command == "nofly" then
        KM_nofly = not KM_nofly
        print(KMname .. "Session no-fly now " .. (KM_nofly and "\124cFF00FF00Active\124cFFFFFFFF" or "\124cFFFF0000TURNED OFF\124cFFFFFFFF"));
    elseif command == "mountcount" then
        local GroundMounts, FlyingMounts, UnderWaterMounts, NoSkillMounts, WaterGroundMounts, AQMounts, FavGround, FavFlying = unpack(kekmount.GetUsableMounts())
        print(KMname .. "Mount count:\nGround: " .. #GroundMounts .. "\nFlying: " .. #FlyingMounts .. "\nUnderwater: " .. #UnderWaterMounts .. "\nSkill-less: " .. #NoSkillMounts .. "\nWaterwalking: " .. #WaterGroundMounts .. "\nAQ: " .. #AQMounts .. "\nFav Ground: " .. #FavGround .. "\nFav Flying: " .. #FavFlying);
    elseif command == "help" then
        print("\124c06418affKek\124c34ec7900Mount")
        print("\124c0c5f94ffGet <type> - \124cffffffffPrints all owned, usable mounts. Usefull to find the index for specific mounts.");
        print("\124c0c5f94ffIndexByName|ibn <query> - \124cffffffffSearch through all mounts (even unavailable) and returns an index number if a match is found (and more with debug toggled).");
        print("\124c0c5f94ffNameByIndex|nbi <query> - \124cffffffffReturn the name of mount at specified index, if it exists.");
        print("\124c0c5f94ffSetg - \124cffffffffSet the desired ground mount.");
        print("\124c0c5f94ffUsetg - \124cffffffffUnsets the desired ground mount.");
        print("\124c0c5f94ffSetf - \124cffffffffSet the desired flying mount.");
        print("\124c0c5f94ffUsetf - \124cffffffffUnsets the desired flying mount.");
        print("\124c0c5f94ffTogglew - \124cffffffffToggles water mounts (except Vashj'ir specific mounts).");
        print("\124c0c5f94ffTogglepw - \124cffffffffToggles preference for ground mounts that can walk on water.");
        print("\124c0c5f94ffTogglefd - \124cffffffffToggles dismount preference while flying.");
        print("\124c0c5f94ffTogglebf - \124cffffffffToggles use of mount manager favorite(s).");
        print("\124c0c5f94ffTogglewb - \124cffffffffToggles use of water walking blacklist.");
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
    updateSettings(false);
    UpdateMountList();
    SetMapToCurrentZone()
end)

do
    -- Slash Handler
    SLASH_KekMount1 = "/kmount"
    SlashCmdList.KekMount = handler
    LoginFrame:RegisterEvent("PLAYER_LOGIN")
end