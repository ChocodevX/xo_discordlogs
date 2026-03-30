Config = Config or {}

Config.ImageCache =
'' -- Webhook สำหรับเก็บรูปภาพทั้งหมด

Config.Webhooks = {                                                                                                         -- Discord Webhook ที่ต้องการจะใช้งาน => ['ชื่อ webhook'] = 'discord webhook'
    ['die'] = '',
}

Config.EventRoute = {
    ['getSharedObject'] = 'esx:getSharedObject', -- Default: 'esx:getSharedObject' *รองรับการใส่ชื่อ Event และ Function (exports.es_extended.getSharedObject)
    ['playerLoaded'] = 'esx:playerLoaded',       -- Default: 'esx:playerLoaded'
    ['playerDropped'] = 'esx:playerDropped'      -- Default: 'esx:playerDropped'
}
