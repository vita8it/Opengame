# Luau Roblox Coding Style Guide

เอกสารนี้เป็นมาตรฐานสำหรับการเขียนโค้ด **Luau / Roblox** ภายในโปรเจกต์

## References

* [Roblox Scripting Documentation](https://create.roblox.com/docs/scripting)
* [Project Real Executor Documentation](https://projectreal.gg/th/docs/)
* [Framework — `utils/package.luau`](https://github.com/vita8it/Opengame/blob/main/utils/package.luau)
* [Icon — `Components/Lucide.lua`](https://github.com/vita8it/Turbopack/blob/main/Components/Lucide.lua)

---

# ตัวอย่างการใช้งาน Framework

แยกเป็น Block ให้ชัดเจน โดยใช้ `do ... end` เปิดและปิด Block

- **UI** อยู่ส่วน UI
- **Queue** อยู่ส่วน Queue
- **Module** อยู่ส่วน Module

เมื่อจะสร้างฟังก์ชันให้ใช้รูปแบบ `Module:FunctionName`

เมื่อจะ Connect อะไรก็ตามให้ใช้:

```lua
Connect(Signal, Action)
```

Framework หลักถูกโหลดจาก `package.luau` และคืนค่า `Module` กับ `Settings`

```lua
local Module, Settings = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/vita8it/Opengame/main/utils/package.luau"
))()
```

> `package.luau` ใน source ปัจจุบันกำหนด `Repository = "Next.js"` สำหรับระบบ `Import()` ดังนั้น `Module:Import()` จะโหลดไฟล์จาก repository `vita8it/Next.js`

---

## Module

### CreateModule

ใช้สำหรับสร้าง Module ใหม่และเก็บไว้ใน `Module`

```lua
Module:CreateModule("Example", function(Module)
    local Example = {}

    function Example:GetValue()
        return true
    end

    return Example
end)
```

จากนั้นสามารถเข้าถึง Module ได้ผ่าน:

```lua
local Example = Module.Example
```

### Import

ใช้สำหรับโหลด Module จาก Repository ที่ Framework กำหนดไว้

```lua
local Library = Module:Import("Utils/Library")()
```

`Import()` จะคืนค่า `loadstring` ที่สามารถเรียกใช้เพื่อสร้าง Module หรือ Object ได้

---

# Connections

Framework มี `Connections` สำหรับจัดการ `RBXScriptConnection`

```lua
local Connections = Module.Connections

Connections.Connect(
    game:GetService("RunService").Heartbeat,
    function()
        print("Running")
    end
)
```

> `Connections.Connect()` เป็น function แบบ `.` ไม่ใช่ `:`

---

# Configurations

ใช้สำหรับจัดการ Settings และบันทึก Configuration ลงไฟล์

```lua
local Configurations = Module.Configurations
local Configurable = Configurations:Create("Example")
```

กำหนดค่าเริ่มต้น:

```lua
Configurable:SetDefault("Enabled", false)
```

โหลด Configuration:

```lua
Configurable:Load()
```

บันทึกค่า:

```lua
Configurable:Save("Enabled", true)
```

## Settings

เมื่อสร้าง Configuration แล้ว Framework จะสร้าง `Settings` ให้ใช้งาน

```lua
Settings.Enabled = true
```

การเปลี่ยนค่าใน `Settings` จะถูกบันทึกลง Configuration โดยอัตโนมัติ

---

# GoodQueue

`GoodQueue` เป็นระบบสำหรับจัดลำดับการทำงานของระบบ Farm

Queue ทำงานในรูปแบบ **Layer จากด้านบนลงด้านล่าง**

```
Layer 1
   ↓
Layer 2
   ↓
Layer 3
   ↓
Layer 4
```

แต่ละ Layer จะถูกตรวจสอบตามลำดับ

ถ้า Layer ใด `return true` ระบบจะ **หยุด Queue ที่ Layer นั้นทันที**

ดังนั้น Layer ด้านบนจะมี Priority สูงกว่า Layer ด้านล่าง

## Queue

การสร้าง Queue ต้องใช้ `CreateOption()` โดย **ไม่ใส่ Interval**

```lua
Queue:CreateOption("Layer 1", function()
    if IsSomething() then
        return true
    end
end)
```

Layer ถัดไป:

```lua
Queue:CreateOption("Layer 2", function()
    if IsSomethingElse() then
        return true
    end
end)
```

และ Layer ถัดไป:

```lua
Queue:CreateOption("Layer 3", function()
    print("Layer 3")
end)
```

ลำดับการทำงาน:

```
Layer 1
  │
  ├── return true ──> STOP
  │
  └── ไม่ return true
          ↓
Layer 2
  │
  ├── return true ──> STOP
  │
  └── ไม่ return true
          ↓
Layer 3
```

## Queue Example

```lua
Queue:CreateOption("Collect Chest", function()
    if IsChestAvailable() then
        CollectChest()

        return true
    end
end)

Queue:CreateOption("Kill Enemy", function()
    if IsEnemyAvailable() then
        KillEnemy()

        return true
    end
end)

Queue:CreateOption("Move To Farm", function()
    MoveToFarm()
end)
```

ลำดับ:

```
Collect Chest
     │
     ├── เจอกล่อง → Collect → STOP
     │
     └── ไม่เจอ
          ↓
     Kill Enemy
          │
          ├── เจอ Enemy → Kill → STOP
          │
          └── ไม่เจอ
               ↓
          Move To Farm
```

---

# Interval Thread

ถ้า `CreateOption()` มีตัวเลข `Interval` อยู่ท้ายสุด จะ **ไม่ใช่ Queue**

ตัวอย่าง:

```lua
Queue:CreateOption("Example", function()
    print("Example is running")
end, 0.1)
```

`0.1` คือ Interval

Option นี้จะถูกจัดเป็น **Thread** แทน Queue Layer

```
CreateOption()
│
├── ไม่มี Interval
│      ↓
│    Queue Layer
│
└── มี Interval
       ↓
     Thread
```

ตัวอย่าง:

```lua
Queue:CreateOption("Auto Collect", function()
    CollectItems()
end, 0.1)
```

Thread จะทำงานตาม Interval ที่กำหนด

---

# Queue vs Thread

| รูปแบบ | ประเภท | การทำงาน |
| --- | --- | --- |
| `CreateOption("A", Function)` | Queue | Layer บน → ล่าง |
| `CreateOption("A", Function, 0.1)` | Thread | ทำงานตาม Interval |
| Queue Layer `return true` | Stop | หยุดที่ Layer ปัจจุบัน |
| Queue Layer ไม่ `return true` | Continue | ไป Layer ถัดไป |

---

# StartQueue

ใช้สำหรับเริ่มระบบ Queue:

```lua
Queue:StartQueue()
```

Queue จะตรวจสอบ Layer ตามลำดับที่ถูกสร้างไว้

```
StartQueue
    ↓
Layer 1
    ↓
Layer 2
    ↓
Layer 3
    ↓
...
```

---

# EachOthers

`EachOthers` เป็น Module สำหรับระบบ Server และ Optimization

```lua
local EachOthers = Module.EachOthers
```

## JoinServer

```lua
EachOthers:JoinServer(JobId)
```

## GetServers

```lua
local Servers = EachOthers:GetServers(Cursor)
```

## RejoinServer

```lua
EachOthers:RejoinServer()
```

## ChangeServer

```lua
EachOthers:ChangeServer()
```

## Set3DEnabled

```lua
EachOthers:Set3DEnabled(Value)
```

## SetLowGraphics

```lua
EachOthers:SetLowGraphics()
```

---

# Plugins

`Plugins` เป็น Layer สำหรับสร้าง UI และเชื่อม UI เข้ากับระบบ Queue / Settings

```lua
local Plugins = Module.Plugins
```

## Window

```lua
local Queue = Module.GoodQueue:Create()

local Window = Plugins:Window(
    Queue,
    {
        "Example",
        "Made by vita8it"
    }
)
```

สามารถกำหนด:

```lua
Plugins:Window(
    Queue,
    {
        "Title",
        "Footer",
        Logo
    }
)
```

## CreateTab

```lua
local Tab = Plugins:CreateTab({
    "Main",
    "Main Features"
})
```

## Section

```lua
Tab:Section("Farm", function(Section)
    -- UI
end)
```

## Paragraph

```lua
Plugins:Paragraph(
    Section,
    {
        "Title",
        "Description"
    }
)
```

สามารถกำหนด Type:

```lua
Plugins:Paragraph(
    Section,
    {
        "Title",
        "Description"
    },
    {
        "Icon",
        "Text",
        "Status"
    }
)
```

## Button

```lua
Plugins:Button(
    Section,
    {
        "Test",
        "Run Example"
    },
    function()
        print("Clicked")
    end
)
```

สามารถกำหนด Type:

```lua
Plugins:Button(
    Section,
    {
        "Test",
        "Run Example",
        "Primary"
    },
    function()
        print("Running")
    end
)
```

## Toggle

Toggle สามารถใช้ร่วมกับ Thread ที่สร้างด้วย `CreateOption(..., Interval)`

สร้าง Thread:

```lua
Queue:CreateOption("Auto Farm", function()
    print("Farming")
end, 0.1)
```

จากนั้นสร้าง Toggle โดยใช้ Flag เดียวกัน:

```lua
Plugins:Toggle(
    Section,
    {
        "Auto Farm",
        "Automatically farm"
    },
    "Auto Farm",
    function(Value)
        print(Value)
    end
)
```

เมื่อเปิด Toggle:

```
Toggle
  ↓
Enabled
  ↓
Queue.Threads["Auto Farm"]
  ↓
Thread เริ่มทำงาน
```

เมื่อปิด Toggle:

```
Toggle
  ↓
Disabled
  ↓
Thread ถูกหยุด
```

## Slider

```lua
Plugins:Slider(
    Section,
    {
        "Distance",
        "Set distance"
    },
    {
        1,
        100,
        1
    },
    "Distance",
    function(Value)
        print(Value)
    end
)
```

รูปแบบ:

```
Values = {
    Minimum,
    Maximum,
    Rounding
}
```

## Dropdown

```lua
Plugins:Dropdown(
    Section,
    "Select Mode",
    {
        "Mode 1",
        "Mode 2",
        "Mode 3"
    },
    "Mode",
    function(Value)
        print(Value)
    end
)
```

## Textbox

```lua
Plugins:Textbox(
    Section,
    {
        "Username",
        "Enter username"
    },
    "Username",
    function(Value)
        print(Value)
    end
)
```

## Notify

```lua
Plugins:Notify(
    {
        "Success",
        "Action completed"
    }
)
```

กำหนด Duration:

```lua
Plugins:Notify(
    {
        "Success",
        "Action completed"
    },
    5
)
```

## Dialog

```lua
Plugins:Dialog(
    {
        "Confirmation",
        "Are you sure?"
    },
    function()
        print("Confirmed")
    end
)
```

---

# ตัวอย่าง Framework แบบรวม

```lua
local Module, Settings = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/vita8it/Opengame/main/utils/package.luau"
))()

local Queue = Module.GoodQueue:Create()
local Plugins = Module.Plugins

Plugins:Window(
    Queue,
    {
        "Example",
        "Made by vita8it"
    }
)

local Tab = Plugins:CreateTab({
    "Main",
    "Example"
})

Tab:Section("Farm", function(Section)

    Queue:CreateOption("Collect Chest", function()
        if IsChestAvailable() then
            CollectChest()

            return true
        end
    end)

    Queue:CreateOption("Kill Enemy", function()
        if IsEnemyAvailable() then
            KillEnemy()

            return true
        end
    end)

    Queue:CreateOption("Move To Farm", function()
        MoveToFarm()
    end)

    Queue:CreateOption("Auto Farm", function()
        AutoFarm()
    end, 0.1)

    Plugins:Toggle(
        Section,
        {
            "Auto Farm",
            "Enable Auto Farm"
        },
        "Auto Farm",
        function(Value)
            print("Auto Farm:", Value)
        end
    )

end)

Queue:StartQueue()
```

ในตัวอย่างนี้:

```
Collect Chest
      ↓
Kill Enemy
      ↓
Move To Farm
```

เป็น **Queue Layers**

ส่วน:

```
Auto Farm + 0.1
```

เป็น **Thread** และไม่ใช่ Queue Layer

---

# หลักการสำคัญ

## 1. ใช้ PascalCase

ตัวแปร:

```lua
local PlayerName = "Example"
local TargetPlayer = nil
```

Function:

```lua
function GetTarget()
end
```

Module:

```lua
local CombatManager = {}
```

---

## 2. Module Function ต้องใช้ Method

Function ที่เป็น Logic ของ Module ต้องประกาศเป็น Method:

```lua
function Module:GetTarget()
end
```

เรียกใช้:

```lua
Module:GetTarget()
```

ไม่ควรเขียน:

```lua
local function GetTarget()
end
```

ถ้า Function นั้นเป็น Logic ของ Module

---

## 3. Boolean Function ต้องขึ้นต้นด้วย Is

Function ที่คืนค่า Boolean ต้องใช้ `Is`

```lua
function IsAlive(Character)
    return Character ~= nil
end
```

ตัวอย่าง:

```lua
IsAlive()
IsEnemy()
IsValidTarget()
IsEnabled()
IsAvailable()
```

---

## 4. Prefix ของ Function

| Prefix | ความหมาย |
| --- | --- |
| `Is` | ตรวจสอบ Boolean |
| `Get` | ดึงค่าหรือ Object ที่มีอยู่ |
| `Find` | ค้นหาและคืนผลลัพธ์ |
| `Create` | สร้าง Object |
| `Set` | กำหนดค่า |
| `Update` | อัปเดต State |
| `Remove` | ลบ Object |
| `Clear` | ล้างข้อมูล |

---

## 5. ห้ามใช้ pairs / ipairs

ใช้ Generalized Iteration

ไม่ใช้:

```lua
for Index, Value in pairs(List) do
end
```

ไม่ใช้:

```lua
for Index, Value in ipairs(List) do
end
```

ให้ใช้:

```lua
for Index, Value in List do
end
```

---

## 6. เว้นวรรคใน Table Index

ใช้:

```lua
Table[ Object ]
Cache[ Player ]
Settings[ Flag ]
```

ไม่ใช้:

```lua
Table[Object]
Cache[Player]
Settings[Flag]
```

---

## 7. Cache

ตัวแปร Cache ต้องใช้ชื่อ `Cached`

```lua
local CachedCharacter = nil
local CachedTarget = nil
local CachedHumanoid = nil
```

ถ้าเป็น Table:

```lua
local Cached = {}
```

ตัวอย่าง:

```lua
Cached[ Player ] = Character
```

---

## 8. Cache ไม่ใช่ Source of Truth

Cache มีไว้เพิ่มความเร็วเท่านั้น

ต้อง Validate Object ก่อนนำกลับมาใช้

```lua
local Character = Cached[ Player ]

if not Character or not Character.Parent then
    Cached[ Player ] = nil

    Character = Player.Character
end

if not Character then
    return
end
```

หลักการ:

```
Cache
  ↓
Validate
  ↓
Valid?
 ├─ Yes → ใช้ต่อ
 └─ No  → Clear → Find ใหม่
```

---

## 9. Early Return

ควรใช้ Early Return เพื่อลด Nested Condition

ไม่ควร:

```lua
if Character then
    if Humanoid then
        if Humanoid.Health > 0 then
            Attack()
        end
    end
end
```

ควร:

```lua
if not Character then
    return
end

if not Humanoid then
    return
end

if Humanoid.Health <= 0 then
    return
end

Attack()
```

---

## 10. หลีกเลี่ยงงานซ้ำ

ไม่ควรเรียก API เดิมหลายครั้งโดยไม่จำเป็น

ควร:

```lua
local Character = Player.Character

if not Character then
    return
end

local Humanoid = Character:FindFirstChild("Humanoid")
local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
```

หลักการ:

```
Get ครั้งเดียว
    ↓
เก็บไว้ใน Variable
    ↓
ใช้ซ้ำ
```

---

## 11. Function ต้องมี Responsibility เดียว

หนึ่ง Function ควรมีหน้าที่หลักเพียงอย่างเดียว

ควรแยก:

```lua
function FindTarget()
end

function TeleportToTarget()
end

function AttackTarget()
end

function CollectItem()
end
```

แล้วให้ Function หลักเป็นตัวจัดลำดับ:

```lua
function UpdateFarm()
    local Target = FindTarget()

    if not Target then
        return
    end

    TeleportToTarget(Target)
    AttackTarget(Target)
end
```

---

## 12. ใช้ self สำหรับ Module State

ถ้า State เป็นของ Module ให้ใช้ `self`

```lua
local Manager = {}

function Manager:Create()
    self.Target = nil
end

function Manager:SetTarget(Target)
    self.Target = Target
end

function Manager:GetTarget()
    return self.Target
end

return Manager
```

---

## 13. อ่านง่ายสำคัญกว่าสั้น

อย่าทำ Code ให้สั้นจนอ่านยาก

ควร:

```lua
local Character = Player.Character

if not Character then
    return
end

local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")

if not HumanoidRootPart then
    return
end
```

---

## 14. Consistency

Code ใน Project เดียวกันต้องใช้รูปแบบเดียวกัน

```lua
local Player = Players.LocalPlayer
local Character = Player.Character
local Humanoid = Character:FindFirstChild("Humanoid")
```

ไม่ควรสลับเป็น:

```lua
local player = ...
local Char = ...
local humanoid = ...
```

---

## 15. การแก้ไข Code เดิม

เมื่อแก้ Code ที่มีอยู่แล้ว:

- Preserve Logic เดิม
- Preserve Architecture เดิม
- แก้เฉพาะส่วนที่จำเป็น
- ไม่สร้างระบบใหม่โดยไม่ได้ขอ
- ไม่เปลี่ยนชื่อสิ่งต่าง ๆ โดยไม่มีเหตุผล
- ไม่ Refactor ขนาดใหญ่ถ้าไม่ได้ร้องขอ

---

## 16. Queue Layer ต้องเรียงตาม Priority

สำหรับระบบ Farm ให้เรียง Layer จาก **สำคัญที่สุด → สำคัญน้อยที่สุด**

```lua
Queue:CreateOption("Emergency", function()
    if IsEmergency() then
        HandleEmergency()

        return true
    end
end)

Queue:CreateOption("Collect", function()
    if IsCollectable() then
        Collect()

        return true
    end
end)

Queue:CreateOption("Farm", function()
    Farm()
end)
```

ลำดับ:

```
Emergency
    ↓
Collect
    ↓
Farm
```

ถ้า `Emergency` ทำงานสำเร็จและ `return true`:

```
Emergency
   ↓
return true
   ↓
STOP
```

จะไม่ลงไปทำ `Collect` หรือ `Farm` ในรอบนั้น

---

## 17. Queue ไม่ควรใช้ Interval

ถ้าต้องการสร้าง Layer:

```lua
Queue:CreateOption("Farm", function()
    Farm()
end)
```

ไม่ใช่:

```lua
Queue:CreateOption("Farm", function()
    Farm()
end, 0.1)
```

เพราะแบบหลังเป็น Thread

```
ไม่มี Interval
    ↓
Queue Layer

มี Interval
    ↓
Thread
```

---

## 18. Summary Convention

เมื่อสรุป Code หรืออธิบายระบบ ให้เน้น:

1. หน้าที่ของระบบ
2. ลำดับการทำงาน
3. Input / Output
4. เงื่อนไขสำคัญ
5. จุดที่ต้องระวัง

ตัวอย่าง:

```
GoodQueue

1. CreateOption ไม่มี Interval = Queue Layer
2. Layer ทำงานจากบนลงล่าง
3. Layer ที่อยู่ด้านบนมี Priority สูงกว่า
4. return true = หยุด Queue ที่ Layer ปัจจุบัน
5. CreateOption ที่มี Interval = Thread
6. Thread ทำงานตาม Interval และไม่ใช่ Queue Layer
```

---

## 19. ลด Path ซ้ำใน require()

ถ้ามี `require()` หลายตัวที่ใช้ Path เดิมซ้ำกัน ให้สร้าง Reference ไว้ก่อน

ไม่ควร:

```lua
local PlaceUtil = require(ReplicatedStorage.Shared.Universe.Place.PlaceUtil)
local GameModes = require(ReplicatedStorage.Shared.Universe.GameMode.GameModes)
local Remotes = require(ReplicatedStorage.Shared.Universe.Remotes)
```

ควร:

```lua
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Universe = Shared:WaitForChild("Universe")

local PlaceUtil = require(Universe.Place.PlaceUtil)
local GameModes = require(Universe.GameMode.GameModes)
local Remotes = require(Universe.Remotes)
```

หลักการ:

```
Path ที่ซ้ำกัน
    ↓
ตัด Path ส่วนที่ซ้ำออกมาเป็น Variable
    ↓
require() จาก Variable แทน
```

> ใช้ `WaitForChild()` เสมอเพื่อป้องกัน Race Condition ในฝั่ง Client

---

## 20. ห้ามใช้ local function นอก CreateModule

`local function` ทุกตัวต้องอยู่ภายใน `CreateModule` เท่านั้น

ไม่ควร:

```lua
local function GetTarget()
    return nil
end

Module:CreateModule("Combat", function(Module)
    local Combat = {}
    return Combat
end)
```

ควร:

```lua
Module:CreateModule("Combat", function(Module)
    local Combat = {}

    local function GetTarget()
        return nil
    end

    function Combat:Attack()
        local Target = GetTarget()
    end

    return Combat
end)
```

หลักการ:

```
local function
    ↓
ต้องอยู่ใน CreateModule เสมอ
    ↓
ถ้าเป็น Logic ของ Module → ใช้ Method แทน
```

---

## 21. เรียก _ENV ทุกครั้งที่สร้างสคริปต์

ทุกสคริปต์ต้องเริ่มต้นด้วย:

```lua
local _ENV = (getgenv or getrenv or getfenv)()
```

บรรทัดนี้ต้องอยู่บนสุดเสมอ ไม่มีข้อยกเว้น

---

## 22. ห้ามเขียน Comment

ไม่ควร:

```lua
-- Get the player character
local Character = Player.Character

-- Check if humanoid exists
local Humanoid = Character:FindFirstChild("Humanoid")
```

ควร:

```lua
local Character = Player.Character
local Humanoid = Character:FindFirstChild("Humanoid")
```

ให้ใช้ Naming ที่ชัดเจนแทน Comment

---

## 23. โครงสร้างการสร้าง UI

ทุกสคริปต์ที่สร้าง UI ต้องทำตามลำดับนี้เสมอ

**ขั้นที่ 1 — ล้าง UI เดิม:**

```lua
local Folder = gethui and gethui()

for Index, Value in Folder:GetChildren() do
    if Value.Name:find("Next.js") then
        Value:Destroy()
    end
end
```

**ขั้นที่ 2 — สร้าง Window:**

```lua
Window:Community()
```

**ขั้นที่ 3 — สร้าง Tab และ Section ด้วย `do ... end`:**

```lua
local Tab = Plugins:CreateTab({ "Main", "Description", IconId }) do
    Tab:Section("Section Name", function(Section)

    end)
end
```

**ขั้นที่ 4 — ปิดท้ายด้วย Managers:**

```lua
Window:Managers()
```

ลำดับรวม:

```
ล้าง UI เดิม
    ↓
Window:Community()
    ↓
CreateTab + Section
    ↓
Window:Managers()
```

---

## 24. SetDefault ต้องอยู่บนสุดของ Section

`Plugins:SetDefault()` ของ Toggle, Dropdown, Slider หรือ Textbox ต้องประกาศบนสุดใน Section ก่อนสร้าง UI Element

ไม่ควร:

```lua
Tab:Section("Settings", function(Section)
    Plugins:Toggle(Section, { "Auto Farm", "Enable" }, "AutoFarm", function(Value) end)
    Plugins:SetDefault("AutoFarm", false)
end)
```

ควร:

```lua
Tab:Section("Settings", function(Section)
    Plugins:SetDefault("AutoFarm", false)
    Plugins:SetDefault("Mode", "Normal")

    Plugins:Toggle(Section, { "Auto Farm", "Enable" }, "AutoFarm", function(Value) end)
    Plugins:Dropdown(Section, "Select Mode", { "Normal", "Hard" }, "Mode", function(Value) end)
end)
```

หลักการ:

```
Section
  ↓
SetDefault ทั้งหมดก่อน
  ↓
UI Elements
```

---

# Final Principle

Code ที่ดีใน Project นี้ต้อง:

- อ่านง่าย
- Consistent
- ใช้ Naming ที่ชัดเจน
- ใช้ PascalCase
- ใช้ `Is` สำหรับ Boolean
- ใช้ Prefix ให้ตรงกับหน้าที่
- ไม่ใช้ `pairs()` / `ipairs()`
- เว้นวรรคใน Table Index
- ใช้ Cache อย่างถูกต้อง
- Validate Cache ก่อนใช้
- ใช้ Early Return
- หลีกเลี่ยงงานซ้ำ
- แยก Responsibility ของ Function
- ใช้ `self` สำหรับ Module State
- Preserve Architecture เดิม
- ไม่เพิ่มระบบที่ไม่ได้ร้องขอ
- ให้ความสำคัญกับ Readability มากกว่าการเขียนให้สั้น
- ลด Path ซ้ำใน `require()` ด้วย `WaitForChild()`
- ห้ามใช้ `local function` นอก `CreateModule`
- เรียก `_ENV` บนสุดทุกสคริปต์
- ห้ามเขียน Comment
- ทำตามโครงสร้าง UI ตามลำดับ
- `SetDefault` ต้องอยู่บนสุดของ Section เสมอ

สำหรับระบบ Farm:

> **Queue คือการทำงานแบบ Layer จากด้านบนลงล่าง โดย Layer ที่ `return true` จะเป็น Layer ที่จัดการงานในรอบนั้นและหยุด Queue ทันที ส่วน `CreateOption` ที่มี Interval จะเป็น Thread ไม่ใช่ Queue Layer**
