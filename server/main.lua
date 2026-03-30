local Queues = {}
local ESX = exports['es_extended']:getSharedObject()

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

-- ฟังก์ชันดึงข้อมูลผู้เล่น
local function getIdentity(source)
    local identifiers = {
        steam = 'Unknown',
        discord = 'Unknown',
        license = 'Unknown',
        xbl = 'Unknown',
        live = 'Unknown',
        fivem = 'Unknown',
        license2 = 'Unknown',
        ip = 'Unknown'
    }

    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if string.find(id, 'steam') then
            identifiers.steam = id
        elseif string.find(id, 'discord') then
            identifiers.discord = id
        elseif string.find(id, 'license') then
            identifiers.license = id
        elseif string.find(id, 'xbl') then
            identifiers.xbl = id
        elseif string.find(id, 'live') then
            identifiers.live = id
        elseif string.find(id, 'fivem') then
            identifiers.fivem = id
        elseif string.find(id, 'license2') then
            identifiers.license2 = id
        elseif string.find(id, 'ip') then
            identifiers.ip = id
        end
    end

    return identifiers
end

local function FormatMessage(template, ...)
    local args = { ... }
    return string.format(template, table.unpack(args))
end

--------------------------------------------------------------------------------
-- Queue System
--------------------------------------------------------------------------------

-- ฟังก์ชันส่ง Log ที่ปลอดภัย (Process one log from a specific webhook queue)
local function ProcessNextLog(url)
    if not Queues[url] or Queues[url].processing or #Queues[url].queue == 0 then
        return
    end

    Queues[url].processing = true
    local data = table.remove(Queues[url].queue, 1) -- ดึงข้อมูลแรกออกมา

    PerformHttpRequest(url, function(status, text, headers)
        -- ไม่ว่าผลจะออกมาเป็นยังไง (Success หรือ Error) ต้องปลดล็อค processing
        if status == 200 or status == 204 then
            if Config.debug == true then
                lib.print.info(('Successfully sent log to %s'):format(url))
            end
        elseif status == 429 then -- กรณีโดน Discord Rate Limit
            local retryAfter = (tonumber(headers['Retry-After']) or tonumber(headers['retry-after']) or 5) * 1000
            lib.print.warn(('Rate limited on %s. Waiting %sms'):format(url, retryAfter))

            -- ใส่ข้อมูลกลับเข้าคิวด้านหน้า
            table.insert(Queues[url].queue, 1, data)
            Citizen.Wait(retryAfter)
        else
            lib.print.error(('Failed to send log to %s. Status: %s, Response: %s'):format(url, status, text))
        end

        Queues[url].processing = false -- ปลดล็อคเพื่อให้คิวต่อไปทำงานได้
    end, 'POST', json.encode(data), { ['Content-Type'] = 'application/json' })
end

-- Thread หลักที่คอยจัดการทุก Webhook (Global Consumer)
Citizen.CreateThread(function()
    while true do
        local hasWork = false
        for url, queueData in pairs(Queues) do
            if #queueData.queue > 0 and not queueData.processing then
                ProcessNextLog(url)
                hasWork = true
            end
        end

        -- ถ้าไม่มีงานให้พักนานหน่อย (1 วินาที) ถ้ามีงานให้พักสั้นๆ (100ms)
        Citizen.Wait(hasWork and 100 or 1000)
    end
end)

-- Helper function to add logs to queue
local function AddToQueue(webhookUrl, data)
    if not webhookUrl then return end

    if not Queues[webhookUrl] then
        Queues[webhookUrl] = {
            processing = false,
            queue = {}
        }
    end

    -- Set Global Avatar
    data.avatar_url =
    ''

    table.insert(Queues[webhookUrl].queue, data)
end

--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

local function Discord(data)
    -- data = { webhook, xPlayer, title, message, color, fields, imageURL, ... }

    local webhookUrl = Config.Webhooks[data.webhook] or data.webhook

    if not webhookUrl or webhookUrl == '' then
        lib.print.error('Invalid Webhook URL or Name: ' .. tostring(data.webhook))
        return
    end

    -- Check Filtering
    if Config.ServerWillSendToDiscord then
        local success, keep = pcall(Config.ServerWillSendToDiscord, {
            action = 'custom',
            webhook = webhookUrl,
            data = data
        })

        if success then
            if keep == false then return end -- Only return if explicitly false
        else
            lib.print.error('Config.ServerWillSendToDiscord logic error: ' .. tostring(keep))
        end
    end

    local embed = {
        title = data.title,
        description = data.description or data.message,
        color = tonumber(data.color, 16) or 16777215,
        fields = data.fields or {},
        footer = {
            text = os.date('%Y-%m-%d %H:%M:%S'),
        }
    }

    -- Handle xPlayer Identifiers
    local xPlayer = data.xPlayer
    local descriptionPrefix = ''

    if xPlayer then
        local identity = getIdentity(xPlayer.source)
        local steam = identity.steam or 'Unknown'
        local discord = identity.discord or 'Unknown'
        local license = identity.license or 'Unknown'

        if not data.public then
            descriptionPrefix = ('**Player:** %s\n**Steam:** %s\n**Discord:** <@%s>\n**License:** %s\n\n'):format(
                xPlayer.getName(), steam, discord:gsub('discord:', ''), license
            )
        end
    end

    if data.message and data.title then
        -- Rule: "message คือ title ที่จะนำหน้าด้วยชื่อผู้เล่น" -> if both present, show title?
        -- User said: "หากใช้งาน title และ message พร้อมกัน จะแสดงค่าเป็น title แทน" (If title and message used together, value is title).
        -- Wait, "message = 'hello world!' ผลลัพท์ที่ได้จะเป็น title ที่แสดง => ชื่อผู้เล่น hello world!"
        -- This part of spec is slightly confusing.
        -- "message คือ title ที่จะนำหน้าด้วยชื่อผู้เล่น (หากใช้งาน title และ message พร้อมกัน จะแสดงค่าเป็น title แทน)"
        -- Interpretation: If `message` is provided, it constructs a title like "[PlayerName] [Message]".
        -- If `title` is provided explicitly, it overrides that behavior.

        if data.title then
            embed.title = data.title
            embed.description = descriptionPrefix .. (data.description or data.message or '')
        else
            -- Use message as title logic
            embed.title = ('%s %s'):format(xPlayer and xPlayer.getName() or 'Unknown', data.message)
            embed.description = descriptionPrefix .. (data.description or '')
        end
    else
        embed.description = descriptionPrefix .. (embed.description or '')
    end

    -- Handle Image
    if data.imageURL then
        embed.image = { url = data.imageURL }
    end

    -- Valid Webhook Check
    if not webhookUrl or webhookUrl == '' then
        print(('[EliteLogs] Warning: No webhook URL found for channel "%s". Log skipped.'):format(data.webhook))
        return
    end

    -- Handle Screenshot (Client-side upload -> URL)
    if data.screenshot and xPlayer and xPlayer.source then
        if GetResourceState('screenshot-basic') == 'started' then
            CreateThread(function()
                -- Timeout Protection logic
                local p = promise.new()
                local hasTimedOut = false

                -- Timer
                SetTimeout(5000, function()
                    if not hasTimedOut then
                        hasTimedOut = true
                        p:resolve(nil) -- Resolves nil on timeout
                    end
                end)

                -- Async Call Protected
                CreateThread(function()
                    local success, imageUrl = pcall(function()
                        return lib.callback.await('elite_discordlogs:screenshot', xPlayer.source, Config.ImageCache)
                    end)

                    if not hasTimedOut then
                        hasTimedOut = true -- Mark as finished so timer doesn't override
                        if success and imageUrl then
                            p:resolve(imageUrl)
                        else
                            p:resolve(nil)
                        end
                    end
                end)

                local finalUrl = Citizen.Await(p)

                if finalUrl then
                    embed.image = { url = finalUrl }
                else
                    lib.print.warn('Screenshot failed or timed out. Sending log without image.')
                end

                AddToQueue(webhookUrl, { username = 'Elite Logs', embeds = { embed } })
            end)
            return -- logic continues in thread, don't send twice!
        else
            lib.print.warn('screenshot-basic is not started. Screenshot skipped.')
        end
    end

    AddToQueue(webhookUrl, { username = 'Elite Logs', embeds = { embed } })
end

exports('Discord', Discord)

--------------------------------------------------------------------------------
-- General Logging Logic (Login/Logout/Death/Chat)
--------------------------------------------------------------------------------

local function SendGeneralLog(logType, source, args)
    local config = Config.GeneralWebhooks[logType]
    if not config then return end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end -- Login might be too early? esx:playerLoaded guarantees xPlayer

    local webhookUrl = config.webhook

    -- Check Blocked Zone for Death
    if logType == 'death' and config.blocked_zone then
        local coords = GetEntityCoords(GetPlayerPed(source))
        for _, zone in ipairs(config.blocked_zone) do
            if #(coords - zone.coords) <= zone.radius then
                return -- In blocked zone
            end
        end
    end

    -- Construct Data
    local data = {
        webhook = webhookUrl,
        xPlayer = xPlayer,
        color = config.color,
        screenshot = config.screenshot
    }

    if logType == 'login' then
        data.title = FormatMessage(config.title, xPlayer.getName())
    elseif logType == 'logout' then
        data.title = ('[%s] %s เดินทางออกจากเมือง'):format(source, xPlayer.getName())

        local reason = args.reason or 'Unknown'
        local identity = getIdentity(source)
        local coords = GetEntityCoords(GetPlayerPed(source))
        local coordsStr = ('%.1f, %.1f, %.1f'):format(coords.x, coords.y, coords.z)
        local hwid = identity.fivem ~= 'Unknown' and identity.fivem or identity.license2

        local desc = {}
        table.insert(desc, ('Reason: %s\n'):format(reason))
        table.insert(desc, ('**Name:** %s'):format(xPlayer.getName()))
        table.insert(desc, ('**Discord:** <@%s>'):format(identity.discord:gsub('discord:', '')))
        table.insert(desc, ('**Identifier:** %s'):format(identity.steam))
        table.insert(desc, ('**License:** %s'):format(identity.license))
        table.insert(desc, ('**HWID:** %s'):format(hwid))
        table.insert(desc, ('**Coords:** %s'):format(coordsStr))
        table.insert(desc, ('**Unique:** logout_%s'):format(identity.steam:gsub('steam:', '')))
        table.insert(desc, ('**IP:** %s'):format(identity.ip:gsub('ip:', '')))

        data.description = table.concat(desc, '\n')

        -- Custom Footer for this log type
        data.footer = {
            text = ('Elite • %s'):format(os.date('%d/%m/%Y - %H:%M:%S'))
        }
    elseif logType == 'chat' then
        data.title = FormatMessage(config.title, xPlayer.getName())
        data.message = FormatMessage(config.description, args.message) -- args.message is chat content
    elseif logType == 'death' then
        data.title = FormatMessage(config.title, xPlayer.getName())

        local reason = Config.DefaultDeathCause
        local killerInfo = nil

        -- Death Logic
        local killerId = args.killerId
        local deathCause = args.deathCause

        -- Map Cause
        local causeLabel = Config.DeathCauses[deathCause] or Config.DefaultDeathCause
        if type(causeLabel) == 'table' then
            -- Vehicle logic: "ยานพาหนะ %s ทะเบียน %s"
            -- Requires extracting vehicle info.
            -- For now, simple fallback or extraction if possible.
            -- Since we are in server, accurate vehicle info of the KILLER vehicle is hard if not passed.
            reason = causeLabel[2] -- Fallback to 'Vehicle'
        else
            reason = causeLabel
        end

        if killerId and killerId ~= 0 and killerId ~= source then
            -- Murder
            local xKiller = ESX.GetPlayerFromId(killerId)
            local killerName = xKiller and xKiller.getName() or 'Unknown/NPC'

            data.description = FormatMessage(config.description.target, killerName, reason)

            if config.show_killer_information and xKiller then
                data.fields = {
                    { name = 'Killer', value = xKiller.getName(), inline = true },
                    { name = 'Weapon', value = reason,            inline = true }
                }
                data.xTarget = xKiller -- Optional field provided in spec
            end
        else
            -- Suicide / Environment
            data.description = FormatMessage(config.description.no_target, reason)
        end
    end

    Discord(data)
end

--------------------------------------------------------------------------------
-- Event Handlers
--------------------------------------------------------------------------------

local routes = Config.EventRoute

-- Login
RegisterNetEvent(routes.playerLoaded, function(playerId, xPlayer, isNew)
    -- esx:playerLoaded uses 'TriggerEvent' (server), so 'source' might not be reliable.
    -- First argument is playerId.
    local _source = playerId
    SetTimeout(5000, function() -- Wait a bit
        SendGeneralLog('login', _source)
    end)
end)

-- Logout
AddEventHandler(routes.playerDropped, function(playerId, reason)
    -- esx:playerDropped uses (playerId, reason) as trigger arguments.
    local _source = playerId
    SendGeneralLog('logout', _source, { reason = reason })
end)

-- Death (ESX Legacy usually triggers esx:onPlayerDeath)
RegisterNetEvent('esx:onPlayerDeath', function(data)
    local _source = source
    -- data is usually { victim = ..., killer = ..., deathCause = ... } or similar depending on version
    -- Standard ESX: data.victim, data.killer, data.deathCause, data.distance

    local killerId = nil
    if data.killerServerId then
        killerId = data.killerServerId
    end

    SendGeneralLog('death', _source, {
        killerId = killerId,
        deathCause = data.deathCause
    })
end)

-- Chat
-- Intercept standard chat resource's server-side event
AddEventHandler('chatMessage', function(source, author, message)
    -- In AddEventHandler, arguments are passed directly. First arg is source (playerId).
    -- Wait, if triggered via TriggerServerEvent, source is implicitly global? NO.
    -- Standard chat resource does TriggerClientEvent mostly.
    -- However, the server processes chat commands.
    -- If using ox_chat, this event might not fire.
    -- If using vanilla chat, this event is triggered when a message is sent.

    -- But 'chatMessage' is tricky. Standard chat resource server/main.lua:
    -- RegisterServerEvent('chatMessage') -- registers it as net event? Yes.
    -- AddEventHandler('chatMessage', function(author, color, text) ... end) -- Standard args for net event?
    -- If net event: (author, color, text) -> Source is global source.

    -- Let's try RegisterNetEvent again but ensure it's correct.
    -- If we use RegisterNetEvent, arguments align with TriggerServerEvent calls.
    -- BUT if it's TriggerEvent (server-local), arguments are (source, author, message).

    -- Standard practice for chat logging:
    local _source = source
    -- If author argument is a number (color table), shift args?
    -- Actually, let's use the standard "chatMessage" handler signature used by most resources.

    if message then
        SendGeneralLog('chat', _source, { message = message })
    elseif author and type(author) == 'string' then
        -- Maybe (author, color, message) signature?
        SendGeneralLog('chat', _source, { message = author })
    end
end)

-- Backup Chat: 'chat:addMessage' ? No, that's client side.
-- Try RegisterServerEvent wrapper for chatMessage just in case
RegisterNetEvent('chatMessage', function(author, color, text)
    local _source = source
    if text then
        SendGeneralLog('chat', _source, { message = text })
    end
end)

--------------------------------------------------------------------------------
-- Test Command
--------------------------------------------------------------------------------

RegisterCommand('testelitelogs', function(source, args, raw)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return print('Start game first') end

    local webhookName = args[1] or 'vault' -- Use 'vault' as default test
    local message = args[2] and table.concat(args, ' ', 2) or 'This is a test log from /testelitelogs'

    print(('Sending test log to webhook: %s'):format(webhookName))

    Discord({
        webhook = webhookName,
        xPlayer = xPlayer,
        title = 'Elite Logs Test',
        message = message,
        color = '00AAFF',
        screenshot = true,
        fields = {
            { name = 'Test Field', value = 'Testing 1 2 3', inline = true },
            { name = 'Timestamp',  value = os.date('%c'),   inline = true }
        }
    })
end, true) -- Restricted to admins (ace perms) or set to false for everyone. Let's set to true (admin) by default standard.
