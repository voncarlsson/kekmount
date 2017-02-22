local API = {}
kekmount = API
local allMountIDs = C_MountJournal.GetMountIDs()
local MountExtraData = {}
local AmbiguousMounts = {185, 305, 376, 203, 454, 753, 600, 413, 219, 547, 363, 846, 802, 845, 741, 456, 522, 459, 593, 881, 751, 764, 458, 451, 457, 532, 468, 439, 523, 594}
-- See dev_notes.txt for references or use the NameByIndex command in-game
local PlayerFaction = select(1, UnitFactionGroup("player"));
API.PlayerFaction = PlayerFaction == "Horde" and 0 or PlayerFaction == "Alliance" and 1;

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

API.GetMountInfo = setmetatable({}, {
    __index = function(t, k)
        if k == "count" then
            return MountExtraData.count
        end
        if allMountIDs[k] == nil then
            return
        end
        
        k = allMountIDs[k]
        
        if not MountExtraData[k] then
            local _,_,_,_, mountType = C_MountJournal.GetMountInfoExtraByID(k)
            MountExtraData[k] = mountType
            MountExtraData.count = (MountExtraData.count or 0) + 1
        end

        local creatureName, creatureID, icon, active, summonable, source, isFavorite, isFactionSpecific, faction, unknown, owned, mountID = C_MountJournal.GetMountInfoByID(k);
        return {creatureName, creatureID, summonable, isFavorite, isFactionSpecific, faction, owned, mountID, MountExtraData[k]}
    end
})

local function NameByIndex(n)
    for i = 1, #allMountIDs, 1 do
        if API.GetMountInfo[i][8] == n then
            return API.GetMountInfo[i][1]
        end
    end

    return false
end

local function KM_GetUsableMounts()
    local GroundMounts, FlyingMounts, UnderWaterMounts, NoSkillMounts, WaterGroundMounts, AQMounts, FavGround, FavFlying = {}, {}, {}, {}, {}, {}, {}, {}
    local UsableMountCount = 0
    local counters = {1, 1, 1, 1, 1, 1, 1, 1}
    
    for i = 1, #allMountIDs, 1 do
        local creatureName, creatureID, summonable, isFavorite, isFactionSpecific, faction, owned, mountID, mountType = unpack(API.GetMountInfo[i]);

        --typeID = bit.band(3, typeID)
        if owned and (faction == nil or faction == API.PlayerFaction) and (summonable == true or mountType == 232 or mountType == 254) then
            if mountType == 248 then
                if isFavorite == true then
                    FavFlying[counters[1]] = mountID
                    counters[1] = counters[1] + 1
                end
                FlyingMounts[counters[2]] = mountID
                counters[2] = counters[2] + 1
            end

            if mountType == 230 or mountType == 269 or (indexOf(AmbiguousMounts, mountID) ~= -1 and kmountdb["useambiguouslist"] == true) then
                GroundMounts[counters[3]] = mountID
                counters[3] = counters[3] + 1

                if isFavorite == true then
                    FavGround[counters[4]] = mountID
                    counters[4] = counters[4] + 1
                end

                if mountType == 269 then
                    WaterGroundMounts[counters[5]] = mountID
                    counters[5] = counters[5] + 1
                end
            end

            if (mountType == 232 or mountType == 231 or mountType == 254 or creatureID == 98718) and creatureID ~= 75207 then
                UnderWaterMounts[counters[6]] = mountID
                counters[6] = counters[6] + 1
            end

            if mountType == 241 then
                if creatureID == 26656 then
                    GroundMounts[counters[3]] = mountID
                    counters[3] = counters[3] + 1

                    if isFavorite == true then
                        FavGround[counters[4]] = mountID
                        counters[4] = counters[4] + 1
                    end
                end

                AQMounts[counters[7]] = mountID
                counters[7] = counters[7] + 1
            end

            -- Since the seahorse and reins of Poseidus is faster than sea turtle we can't just pick a underwater mount at random
            -- so we have to manually check for them.

            if creatureID == 75207 then
                hasSeahorse = mountID
            end

            if mountType == 284 or creatureID == 30174 then
                if isFavorite == true then
                    FavGround[counters[4]] = mountID
                    counters[4] = counters[4] + 1
                end

                NoSkillMounts[counters[8]] = mountID
                counters[8] = counters[8] + 1
            end
            UsableMountCount = UsableMountCount + 1
        end
    end
    
    return {GroundMounts, FlyingMounts, UnderWaterMounts, NoSkillMounts, WaterGroundMounts, AQMounts, FavGround, FavFlying, hasSeahorse, UsableMountCount}
end

API.GetUsableMounts = KM_GetUsableMounts
API.IndexOf = indexOf
API.NameByIndex = NameByIndex