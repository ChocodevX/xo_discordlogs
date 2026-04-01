Config = Config or {}

Config.Debug = false

Config.GeneralWebhooks = {
    login = {              -- แสดงคนเข้าเมือง
        webhook = 'login', -- ใช้ Config.Webhooks['vault']
        title = '%s เดินทางเข้าเมือง',
        color =
        '0b9e68'            -- สีของ Embed เป็น Hex Code | Default: 'ffffff'
    },
    logout = {              -- แสดงคนออกจากเมือง
        webhook = 'logout', -- ใช้ Config.Webhooks['vault']
        title = '%s เดินทางออกจากเมือง',
        color =
        '0b9e68' -- สีของ Embed เป็น Hex Code | Default: 'ffffff'
    },
    -- *login, logout จะแสดงชื่อผู้เล่นเป็นชื่อ Steam เสมอ
    death = {
        webhook = 'die', -- ใช้ Config.Webhooks['vault']
        title = '%s เสียชีวิต',
        description = {
            target = 'ถูก %s สังหารด้วย %s',
            no_target = 'เสียชีวิตด้วย %s'
        },
        color = '0b9e68',               -- สีของ Embed เป็น Hex Code | Default: 'ffffff'
        screenshot = true,
        show_killer_information = true, -- แสดงข้อมูลผู้สังหาร
        short_description = true,       -- แสดงข้อมูลแบบสั้น
        blocked_zone = {                -- Block Zone ที่ไม่ต้องการให้แจ้ง Log
            { coords = vector3(0, 0, 0), radius = 0.0 },
        }
    },
    chat = {
        webhook = 'chat', -- ใช้ Config.Webhooks['vault']
        title = '%s พิมพ์ข้อความในช่องสนทนา',
        description = '%s',
        color = 'ffffff' -- สีของ Embed เป็น Hex Code | Default: 'ffffff'
    }
}
