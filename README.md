# Elite Discord Logs

High-performance, rate-limit aware Discord logging for FiveM (ESX).

## Key Features

- **Smart Queue System**: Automatically handles Discord rate limits (429) per webhook channel.
- **High Performance**: Optimized using `ox_lib` for metadata retrieval and efficiency.
- **Detailed Death Logs**: Distinguishes between accidents, suicides, and player kills (including weapon tracking).
- **Vehicle Kill Tracking**: Detects when players are killed or run over by vehicles.
- **Blacklisted Zones**: Define zones where death logging is disabled (e.g., PVP zones).
- **Client Screenshots**: Automatically capture screenshots on death or custom events (requires `screenshot-basic`).

## ความต้องการ
- [ox_lib](https://github.com/overextended/ox_lib)
- [es_extended](https://github.com/esx-framework/esx_core)
- [screenshot-basic](https://github.com/citizenfx/screenshot-basic)

## (Exports)

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
