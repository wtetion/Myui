# CascadeStyleUI

ตัวอย่างหน้าต่าง **System Settings** ที่ใช้คอมโพเนนต์จาก Cascade รุ่นทางการ `v1.4.0` โดยตรง แล้วปรับให้ตามภาพอ้างอิง: Search อยู่ใน sidebar ซ้าย, Sign In มีไอคอนรูปบัญชีและข้อความรอง, มีจุดแจ้ง Software Update, ไอคอนแท็บเป็นสัญลักษณ์ iOS สีบนพื้นหลังสี่เหลี่ยมมุมมน และหน้า Appearance มีการ์ดภาพ Auto/Light/Dark กับ Clear/Tinted ตัวอย่างเปิดหน้า Appearance ด้วยธีมสว่างและเลือก accent สีแดง

## รันไฟล์เดียว

ใช้ `Ui-library.client.luau` เป็น LocalScript หากสภาพแวดล้อมที่รันอนุญาต `loadstring` และ `game:HttpGetAsync` สคริปต์จะโหลด Cascade v1.4.0 จาก release ทางการที่ระบุเวอร์ชันไว้ แล้วสร้าง UI ให้ทันที ไฟล์นี้ไม่อ้างถึง `script.Parent` และไม่ต้องมี ModuleScript ของตัวอย่างเพิ่ม

เอกสาร Cascade ระบุว่าการโหลดผ่าน HTTP ต้องใช้สภาพแวดล้อมที่รองรับ `loadstring` หากรันใน Roblox Studio ปกติ ให้ติดตั้งแบบ local ตามขั้นตอนถัดไปแทน

## ติดตั้งใน Roblox Studio

1. ดาวน์โหลด `dist.luau` จาก [Cascade v1.4.0 release](https://github.com/cascadeui/Cascade/releases/download/v1.4.0/dist.luau)
2. วางเนื้อหาของ release เป็น **ModuleScript** ชื่อ `Cascade` ใน `ReplicatedStorage`
3. วาง `Ui-library.luau` เป็น **ModuleScript** ชื่อ `Ui-library` ใน `ReplicatedStorage`
4. วาง `Example.client.luau` เป็น **LocalScript** ใต้ `StarterPlayer > StarterPlayerScripts`
5. กด Play

`Ui-library.luau` เป็น adapter สำหรับเรียก API ของ Cascade ส่วน `Example.client.luau` เป็น entry point ที่สร้าง UI จริง หากมี `ReplicatedStorage.Cascade` อยู่แล้ว adapter จะใช้โมดูลนั้นก่อน และไม่พึ่งตำแหน่งของ LocalScript

## ใช้ในสคริปต์ของตัวเอง

```luau
local UI = require(game:GetService("ReplicatedStorage"):WaitForChild("Ui-library"))
local app, handles = UI.CreateSystemSettings()

-- handles.Tabs.Appearance และ handles.Controls.WallpaperTint เป็นต้น
```

หากโหลด Cascade เองอยู่แล้ว ส่ง API เข้าไปได้โดยตรง:

```luau
local UI = require(game:GetService("ReplicatedStorage"):WaitForChild("Ui-library"))
local app, handles = UI.CreateSystemSettings(Cascade)
```

## มีอะไรในตัวอย่าง

- โครงสร้าง Cascade `App → Window → Section → Tab → PageSection → Form → Row` พร้อมแท็บย่อย, กลุ่ม System/Privacy & Security/Automation และไอคอนสีแบบภาพอ้างอิง
- Search ใช้ TextField และระบบค้นหาของ Cascade แต่ย้ายจาก titlebar มาวางไว้ด้านบนของรายการใน sidebar
- แถว Sign In ใช้สัญลักษณ์รูปบัญชีแบบวงกลม พร้อมข้อความ `Set up your Apple Account`
- หน้า Appearance มีภาพตัวอย่างหน้าต่างสำหรับ Auto/Light/Dark, ตัวอย่าง Liquid Glass แบบ Clear/Tinted, ปุ่มเลือกสีแบบวงกลม และการ์ด Icon & widget style แบบ Default/Dark/Clear/Tinted
- หน้า Sign In แบบตัวอย่าง, Software Update, Connectivity, System, Privacy & Security และ Farm Settings
- ปุ่ม, Toggle, Slider, PopUpButton, TextField, Stepper, KeybindField และ Label จาก Cascade
- เลือก Light/Dark และสี accent จะเปลี่ยนธีมและ `app.Accent` จริง; เลือก Icon & widget style และ Sidebar icon size จะปรับไอคอนใน sidebar ส่วน Liquid Glass จะปรับพื้นผิว Search ตัวอย่าง
- ตัวอย่างมีแท็บ Wi-Fi, Bluetooth, Network, VPN, Battery, Wallpaper และหน้า System, Privacy & Security, Farm Settings ตามโครงตัวอย่าง
- ปุ่ม Copy ใช้ `setclipboard` เมื่อสภาพแวดล้อมมี API นี้ มิฉะนั้นจะแสดงค่าที่ Output

ส่วน Sign In เป็นหน้า UI สาธิตเท่านั้น ไม่เชื่อมต่อบริการบัญชีและไม่เก็บรหัสผ่าน ส่วนการตั้งค่าเชื่อมต่อและ Farm Settings เป็นตัวอย่าง callback ที่พิมพ์ค่าไป Output ให้เชื่อมต่อกับ logic ของเกมที่ต้องการเอง

## โครงไฟล์

- `Ui-library.luau` — adapter ModuleScript สำหรับนำไปใช้ซ้ำ
- `Example.client.luau` — ตัวอย่าง LocalScript ที่ require adapter
- `Ui-library.client.luau` — ตัวเลือกไฟล์เดียวที่โหลด Cascade และเปิดหน้าต่างทันที
- `default.project.json` — mapping สำหรับ Rojo; ติดตั้ง Cascade ModuleScript ตามขั้นตอน Roblox Studio ก่อนรันใน Studio

Cascade เป็นโปรเจกต์แยกต่างหากภายใต้ MIT License: [cascadeui/Cascade](https://github.com/cascadeui/Cascade)
