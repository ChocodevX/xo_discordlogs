local function Screenshot(imageCacheWebhook)
    local p = promise.new()

    -- อัปโหลดรูปไปที่ ImageCache Webhook
    exports['screenshot-basic']:requestScreenshotUpload(imageCacheWebhook, 'files[]', function(data)
        local resp = json.decode(data)
        if resp and resp.attachments and resp.attachments[1] then
            -- ส่ง URL ของรูปกลับไปให้ Server
            p:resolve(resp.attachments[1].url)
        else
            p:resolve(nil)
        end
    end)

    return Citizen.Await(p)
end

lib.callback.register('elite_discordlogs:screenshot', function(imageCacheWebhook)
    return Screenshot(imageCacheWebhook)
end)
