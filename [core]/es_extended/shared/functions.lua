local Charset = {}

for i = 48, 57 do
    table.insert(Charset, string.char(i))
end
for i = 65, 90 do
    table.insert(Charset, string.char(i))
end
for i = 97, 122 do
    table.insert(Charset, string.char(i))
end

local weaponsByName = {}
local weaponsByHash = {}

CreateThread(function()
    for index, weapon in pairs(Config.Weapons) do
        weaponsByName[weapon.name] = index
        weaponsByHash[joaat(weapon.name)] = weapon
    end
end)

---@param length number
---@return string
function ESX.GetRandomString(length)
    math.randomseed(GetGameTimer())

    return length > 0 and ESX.GetRandomString(length - 1) .. Charset[math.random(1, #Charset)] or ""
end

---@return table
function ESX.GetConfig()
    return Config
end

---@param weaponName string
---@return number, table
function ESX.GetWeapon(weaponName)
    weaponName = string.upper(weaponName)

    assert(weaponsByName[weaponName], "Invalid weapon name!")

    local index = weaponsByName[weaponName]
    return index, Config.Weapons[index]
end

---@param weaponHash number
---@return table
function ESX.GetWeaponFromHash(weaponHash)
    weaponHash = type(weaponHash) == "string" and joaat(weaponHash) or weaponHash

    return weaponsByHash[weaponHash]
end

---@param byHash boolean
---@return table
function ESX.GetWeaponList(byHash)
    return byHash and weaponsByHash or Config.Weapons
end

---@param weaponName string
---@return string
function ESX.GetWeaponLabel(weaponName)
    weaponName = string.upper(weaponName)

    assert(weaponsByName[weaponName], "Invalid weapon name!")

    local index = weaponsByName[weaponName]
    return Config.Weapons[index].label or ""
end

---@param weaponName string
---@param weaponComponent string
---@return table | nil
function ESX.GetWeaponComponent(weaponName, weaponComponent)
    weaponName = string.upper(weaponName)

    assert(weaponsByName[weaponName], "Invalid weapon name!")
    local weapon = Config.Weapons[weaponsByName[weaponName]]

    for _, component in ipairs(weapon.components) do
        if component.name == weaponComponent then
            return component
        end
    end
end

---@param table table
---@param nb? number
---@return string
function ESX.DumpTable(table, nb)
    if nb == nil then
        nb = 0
    end

    if type(table) == "table" then
        local s = ""
        for _ = 1, nb + 1, 1 do
            s = s .. "    "
        end

        s = "{\n"
        for k, v in pairs(table) do
            if type(k) ~= "number" then
                k = '"' .. k .. '"'
            end
            for _ = 1, nb, 1 do
                s = s .. "    "
            end
            s = s .. "[" .. k .. "] = " .. ESX.DumpTable(v, nb + 1) .. ",\n"
        end

        for _ = 1, nb, 1 do
            s = s .. "    "
        end

        return s .. "}"
    else
        return tostring(table)
    end
end

---@param value any
---@param numDecimalPlaces? number
---@return number
function ESX.Round(value, numDecimalPlaces)
    return ESX.Math.Round(value, numDecimalPlaces)
end

---@param value string
---@param ... any
---@return boolean, string?
function ESX.ValidateType(value, ...)
    local types = { ... }
    if #types == 0 then return true end

    local mapType = {}
    for i = 1, #types, 1 do
        local validateType = types[i]
        assert(type(validateType) == "string", "bad argument types, only expected string") -- should never use anyhing else than string
        mapType[validateType] = true
    end

    local valueType = type(value)

    local matches = mapType[valueType] ~= nil

    if not matches then
        local requireTypes = table.concat(types, " or ")
        local errorMessage = ("bad value (%s expected, got %s)"):format(requireTypes, valueType)

        return false, errorMessage
    end

    return true
end

---@param ... any
---@return boolean
function ESX.AssertType(...)
    local matches, errorMessage = ESX.ValidateType(...)

    assert(matches, errorMessage)

    return matches
end

---@param val unknown
function ESX.IsFunctionReference(val)
    local typeVal = type(val)

    return typeVal == "function" or (typeVal == "table" and type(getmetatable(val)?.__call) == "function")
end

---@param conditionFunc function A function that returns a boolean indicating whether the condition is met.
---@param errorMessage? string The error message to print if the condition is not met within the timeout period.
---@param timeout? number The maximum time (in milliseconds) to wait for the condition to be met.
---@return boolean, number: Returns success status and the time taken
ESX.Await = function(conditionFunc, errorMessage, timeout)
    timeout = timeout or 1000
    
    if timeout < 0 then
        error('Timeout should be a positive number.')
    end

    local isFunctionReference = ESX.IsFunctionReference(conditionFunc)

    if not isFunctionReference then
        error('Condition Function should be a function reference.')
    end

    -- since errorMessage is optional, we only validate it if the user provided it.
    if errorMessage then
        ESX.AssertType(errorMessage, 'string', 'errorMessage should be a string.')
    end

    local startTime = GetGameTimer()
    local prefix = ('[%s] -> '):format(GetInvokingResource())

    while GetGameTimer() - startTime < timeout do
        local result = conditionFunc()

        if result then
            local elapsedTime = GetGameTimer() - startTime
            return true, elapsedTime
        end

        Wait(0)
    end

    if errorMessage then
        local formattedErrorMessage = ('%s %s'):format(prefix, errorMessage)
        error(formattedErrorMessage)
    end

    return false, timeout
end