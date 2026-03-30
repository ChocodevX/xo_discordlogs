# Elite Discord Logs

High-performance, rate-limit aware Discord logging for FiveM (ESX).

## คุณสมบัติ (Key Features)
- **ระบบคิวอัจฉริยะ**: จัดการข้อจำกัดอัตราของ Discord (429) อัตโนมัติสำหรับแต่ละช่องทาง webhook.
- **มีประสิทธิภาพ**: ใช้ `ox_lib` สำหรับดึงข้อมูลเมตาดาต้าและการเพิ่มประสิทธิภาพ.
- **บันทึกการตายอย่างละเอียด**: แยกแยะระหว่างการตายโดยบังเอิญ, การฆ่าตัวตาย, และการถูกฆ่า (รวมทั้งติดตามอาวุธ).
- **บันทึกการถูกฆ่าโดยยานพาหนะ**: ตรวจจับว่าผู้เล่นถูกฆ่าโดยยานพาหนะ (ถูกรถชน/ถูกพุ่งชน).
- **โซนที่บล็อก**: กำหนดโซนที่ไม่ต้องการให้บันทึกการตาย เช่น โซน PVP.
- **ภาพหน้าจอ**: ถ่ายภาพหน้าจอฝั่งลูกค้าเมื่อเกิดการตายหรือเหตุการณ์ที่กำหนดเอง (ต้องการ `screenshot-basic`).

## ความต้องการ
- [ox_lib](https://github.com/overextended/ox_lib)
- [es_extended](https://github.com/esx-framework/esx_core)
- [screenshot-basic](https://github.com/citizenfx/screenshot-basic)

## การติดตั้ง
1. ดาวน์โหลดและตรวจสอบให้แน่ใจว่าติดตั้งความต้องการทั้งหมดแล้ว.
2. โคลนหรือแตกไฟล์ทรัพยากรนี้ลงในโฟลเดอร์ `resources` ของคุณ.
3. เพิ่ม `ensure elite_discordlogs` ในไฟล์ `server.cfg`.

## การใช้งาน (Exports)

ใช้ export ด้านล่างในสคริปต์ฝั่งเซิร์ฟเวอร์เพื่อส่งบันทึก:

```lua
exports.elite_discordlogs:Discord({
    webhook = 'my_log_channel',       -- กุญแจจาก Config.Webhooks หรือ URL โดยตรง
    xPlayer = xPlayer,                -- (จำเป็น) ออบเจ็กต์ผู้เล่น ESX
    xTarget = xTarget,                -- (ไม่จำเป็น) ออบเจ็กต์ผู้เล่นเป้าหมาย ESX
    title = 'Log Title',              -- ชื่อของ embed
    message = 'Log Message',          -- ข้อความเนื้อหา
    color = 'ff0000',                 -- สีแบบ Hex (ไม่ต้องใส่ #)
    imageURL = 'https://...',         -- URL รูปภาพ (ไม่จำเป็น)
    screenshot = true,                -- (ไม่จำเป็น) ถ่ายภาพหน้าจอของ xPlayer
    fields = {                        -- (ไม่จำเป็น) ฟิลด์ใน Discord Embed
        { name = 'Field 1', value = 'Value 1', inline = true },
        { name = 'Field 2', value = 'Value 2', inline = false }
    }
})
```

### ตัวอย่าง: บันทึกงานแบบกำหนดเอง
```lua
local xPlayer = ESX.GetPlayerFromId(source)
exports.elite_discordlogs:Discord({
    webhook = 'job_logs',
    xPlayer = xPlayer,
    title = 'Job Action',
    message = 'Player started a job task.',
    color = '00ff00',
    fields = {
        { name = 'Job', value = xPlayer.job.name, inline = true },
        { name = 'Grade', value = xPlayer.job.grade_label, inline = true }
    }
})
```
