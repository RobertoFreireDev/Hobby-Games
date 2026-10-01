local tablesexample = {
    title = "Table example"
}

local systemlogsTable = {}
local tablePos = {
    x = 10,
    y = 10
}

function printTable(tbl, x, y)
    x = x or tablePos.x
    y = y or tablePos.y

    if #tbl == 0 then
        _print("No data", x, y, 1)
        return
    end

    local headers = {}
    for k, _ in pairs(tbl[1]) do
        table.insert(headers, k)
    end

    local colWidths = {}
    for i, h in ipairs(headers) do
        colWidths[i] = h
    end
    for _, row in ipairs(tbl) do
        for i, h in ipairs(headers) do
            local cellLength = #(tostring(row[h] or ""))
            if cellLength > colWidths[i] then
                colWidths[i] = cellLength
            end
        end
    end

    local function pad(str, width)
        str = tostring(str or "")
        return str .. string.rep(" ", width - #str)
    end

    local sepLine = {}
    for i, w in ipairs(colWidths) do
        table.insert(sepLine, string.rep("-", w))
    end
    _print(table.concat(sepLine, "-+-"), x, y, 1)
    y = y + 10

    for _, row in ipairs(tbl) do
        local rowLine = {}
        for i, h in ipairs(headers) do
            table.insert(rowLine, pad(row[h], colWidths[i]))
        end
        _print(table.concat(rowLine, " | "), x, y, 1)
        y = y + 10
    end
end

function tablesexample:init()
    systemlogsTable = _tbra("systemlogs")
end

function tablesexample:update() 
    if _btn(_keys.Left)  and tablePos.x < 10 then
        tablePos.x = tablePos.x + 2
    end

    if _btn(_keys.Right) then
        tablePos.x = tablePos.x - 2
    end
end

function tablesexample:draw()
    printTable(systemlogsTable)
end

return tablesexample