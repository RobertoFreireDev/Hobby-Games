require("libs/luaes")

local isServer = false
local serverIp = "192.168.100.86:6789"
local ip = ""
local logs = {}
local clientPeer = nil

local function log(msg)
    font(2)
    if #logs > 6 then table.remove(logs) end
    table.insert(logs, 1, os.date("[%H:%M:%S] ") .. tostring(msg))
end

function _init()
    ip = stat(11)
    if isServer then
        local ok, err = createserver(ip..":6789")
        if ok then log("Server started: " .. ip) else log("Error: " .. tostring(err)) end
    else
        local ok, err = connecttoserver(serverIp)
        if ok then 
            clientPeer = ok
            log("Client started: " .. serverIp) 
        else 
            log("Error: " .. tostring(err)) 
        end
    end
end

function _netevent(event)
    if event.type == "connect" then
        log("Connected: " .. tostring(event.peer))
        if isServer then
            event.peer:send("Ping Server")
        else
            clientPeer = event.peer
            clientPeer:send("Ping Client")
        end
    elseif event.type == "receive" then
        log("Received: " .. tostring(event.data))
        if isServer then event.peer:send("Eco: " .. tostring(event.data)) end
    elseif event.type == "disconnect" then
        log("Disconnect: " .. tostring(event.peer))
    end
end

function _update(dt)
    if btnp(4) then
        local msg = "Hi"
        if not isServer and clientPeer then
            clientPeer:send(msg)
            log("Sent: " .. msg)
        end
    end
end

function _draw()
    print("Mode: " .. (isServer and "Server" or "Client"), 0, 0, 1)
    print("Server IP: " .. serverIp, 0, 10, 1)
    print("Local IP: " .. ip, 0, 20, 1)
    print("LOGS:", 0, 30, 1)
    for i, message in ipairs(logs) do
        print(message, 0, 30 + (i * 10), 1)
    end
end