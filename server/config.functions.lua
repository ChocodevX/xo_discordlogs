Config = Config or {}

Config.ServerWillSendToDiscord = function(options)
    -- options.action จะถูกส่งค่ามาเป็น 'chat|login|logout|death' เมื่อระบบส่ง Log การพิมพ์ Chat, เข้า/ออก Server และ Log การหมดสติ
    -- options.webhook จะถูกส่งค่ามาเป็น WebhookURL
    return true -- return true เมื่อต้องการให้ Log ถูกส่งไปยัง Discord
end
