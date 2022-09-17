---@param time string|integer
---@param n integer
---@return string
function TimeGSUB(time, n)
    time = tonumber(time)
    seconds = math.floor(time)
    miliseconds = time - seconds
    timeFormated = tostring(seconds) .. string.sub(tostring(miliseconds), 2, n + 2)
    return timeFormated
end

-- Round to n Decimal places
function round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Set Color (to work with PowerToy's color picker)
function rgb(r, g, b, a)
    love.graphics.setColor(r / 255, g / 255, b / 255, a or 1)
end

-- Used to format tables to print them
function tprint(tbl, indent)
    if not indent then
        indent = 0
    end
    local toprint = string.rep(" ", indent) .. "{\r\n"
    indent = indent + 2
    for k, v in pairs(tbl) do
        toprint = toprint .. string.rep(" ", indent)
        if (type(k) == "number") then
            toprint = toprint .. "[" .. k .. "] = "
        elseif (type(k) == "string") then
            toprint = toprint .. k .. "= "
        end
        if (type(v) == "number") then
            toprint = toprint .. v .. ",\r\n"
        elseif (type(v) == "string") then
            toprint = toprint .. "\"" .. v .. "\",\r\n"
        elseif (type(v) == "table") then
            toprint = toprint .. tprint(v, indent + 2) .. ",\r\n"
        else
            toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
        end
    end
    toprint = toprint .. string.rep(" ", indent - 2) .. "}"
    print(toprint)
end
-- return formated tables to print them
function tprintR(tbl, indent)
    if not indent then
        indent = 0
    end
    local toprint = string.rep(" ", indent) .. "{\r\n"
    indent = indent + 2
    for k, v in pairs(tbl) do
        toprint = toprint .. string.rep(" ", indent)
        if (type(k) == "number") then
            toprint = toprint .. "[" .. k .. "] = "
        elseif (type(k) == "string") then
            toprint = toprint .. k .. "= "
        end
        if (type(v) == "number") then
            toprint = toprint .. v .. ",\r\n"
        elseif (type(v) == "string") then
            toprint = toprint .. "\"" .. v .. "\",\r\n"
        elseif (type(v) == "table") then
            toprint = toprint .. tprint(v, indent + 2) .. ",\r\n"
        else
            toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
        end
    end
    toprint = toprint .. string.rep(" ", indent - 2) .. "}"
    return toprint
end

-- Split stings with "sep"
function Split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

function table.removekeyIndexOfPlaying(tabl_, index)
    for _, v in ipairs(tabl_) do
        if v.indexOfPlaying == index then
            table.remove(tabl_, _)
        end 
    end
end

function table.removekey(tabl_, value)
    for _, v in ipairs(tabl_) do
        if v == key then
            table.remove(tabl_, _)
            return
        end
    end
end

function getAngle(x1, y1, x2, y2)
    return math.atan2(y2 - y1, x2 - x1)
end

function GetDistance(x1, y1, x2, y2)
    return math.sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2)
end

function IsInTable(value, table)
    for i, v in ipairs(table) do
        if v == value then
            return i
        end
    end
    return false
end

function math.sign(number)
    if number > 0 then
        return 1
    elseif number < 0 then
        return -1
    else
        return 0
    end
end


-- https://stackoverflow.com/questions/10386672/reading-whole-files-in-lua
function readAll(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end
