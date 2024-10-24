Vector3.zero = Vector3(0, 0, 0)

-- Cache copied tables in `__copies`, indexed by original table.
function deepcopy(orig, __copies)
    __copies = __copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if __copies[orig] then
            copy = __copies[orig]
        else
            copy = {}
            __copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[deepcopy(orig_key, __copies)] = deepcopy(orig_value, __copies)
            end
            setmetatable(copy, deepcopy(getmetatable(orig), __copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local function getLogStamp()
    return os.date("%H:%M:%S") .. " [" .. MTA_PLATFORM .. "]"
end

function iprintd(...)
    if not DEBUG then return end
    return iprint((SERVER and "localhost@" or getPlayerName(localPlayer) .. "@") .. getLogStamp(), ...)
end

function tstr(...)
    return tostring(...)
end

function isFlagSet( val, flag )
    return (bitAnd( val, flag ) == flag)
end

function getVehicleHandlingFlags(vehicle)
    local retFlags = {}
    local flags = getVehicleHandling(vehicle)["handlingFlags"]

    for name, flag in pairs(VEH_HANDLING_FLAGS) do
        if isFlagSet(flags, flag) then
            retFlags[name] = true
        end
    end

    return retFlags
end

function findRotation( x1, y1, x2, y2 ) 
    local t = -math.deg( math.atan2( x2 - x1, y2 - y1 ) )
    return t < 0 and t + 360 or t
end

function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
  end