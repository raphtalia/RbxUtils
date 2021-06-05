type List = {any}
type Array<T> = {T}
type Dictionary<A, B> = {[A]: B}

local TableUtils = {}

function TableUtils.shallowCopy(tab: Dictionary<any, any>): Dictionary<any, any>
    local copy = {}
    for i, v in pairs(tab) do
        copy[i] = v
    end
    return copy
end

function TableUtils.deepCopy(tab: Dictionary<any, any>): Dictionary<any, any>
    local copy = {}
    for i, v in pairs(tab) do
        if type(v) == "table" then
            v = TableUtils.deepCopy(v)
        end
        copy[i] = v
    end
    return copy
end

function TableUtils.keys(tab: Dictionary<any, any>): Array<string>
    local keys = {}
    for i in pairs(tab) do
        table.insert(keys, i)
    end
    return keys
end

function TableUtils.values(tab: Dictionary<any, any>): List
    local values = {}
    for _,v in pairs(tab) do
        table.insert(values, v)
    end
    return values
end

function TableUtils.isEmpty(tab: Dictionary<any, any>): boolean
    for _ in pairs(tab) do
        return false
    end
    return true
end

-- Behaves differently from table.create(), if the value is a empty table then the tables will not share the same memory address
function TableUtils.create(count: number, value: any): Dictionary<any, any>
    if type(value) == "table" and TableUtils.isEmpty(value) then
        local tab = {}
        for _ = 1, count do
            table.insert(tab, {})
        end
        return tab
    else
        return table.create(count, value)
    end
end

-- Merges dictionaries together, for merging arrays use {TableUtils.unpack(...)}
function TableUtils.merge(...): Dictionary<any, any>
    local mergedTab = {}
    for _,tab in pairs({...}) do
        for i,v in pairs(tab) do
            mergedTab[i] = v
        end
    end
    return mergedTab
end

-- Allows unpacking of multiple tables
function TableUtils.unpack(...)
    local packedTab = {}
    for _,tab in pairs({...}) do
        for _,v in pairs(tab) do
            table.insert(packedTab, v)
        end
    end
    return unpack(packedTab)
end

function TableUtils.remove(tab: List, index: number): nil
    if type(index) == "number" then
        tab[index] = nil
    else
        local i = table.find(tab, index)
        if i then
            table.remove(tab, i)
        end
    end
end

function TableUtils.select(tab: List, indexStart: number, indexEnd: number): List
    indexEnd = indexEnd or #tab
    local output = {}

    for i = indexStart, indexEnd do
        table.insert(output, tab[i])
    end

    return output
end

-- Returns the sum of a array of numbers
function TableUtils.sum(tab: List): number
    local sum = tab[1]
    for i = 2, #tab do
        sum += tab[i]
    end
    return sum
end

-- Returns the average of a array of numbers
function TableUtils.avg(tab: List): number
    return TableUtils.sum(tab) / #tab
end

return TableUtils