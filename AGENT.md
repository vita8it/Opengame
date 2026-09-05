# กฎการเขียนโค้ด — Luau Roblox

เอกสารนี้กำหนดรูปแบบและแนวทางการเขียนโค้ดสำหรับโปรเจกต์ **Roblox Luau**

จุดประสงค์หลักคือให้โค้ดมีความ **อ่านง่าย, เป็นระบบ, สม่ำเสมอ, ดูแลรักษาง่าย และมีประสิทธิภาพ** โดยไม่ลดความสามารถของโค้ดโดยไม่จำเป็น

---

## เอกสารอ้างอิง

* [Roblox Scripting Documentation](https://create.roblox.com/docs/scripting)
* [Project Real Executor Documentation](https://projectreal.gg/th/docs/)

---

# หลักการสำคัญ

เมื่อเขียนหรือแก้ไขโค้ด ให้ยึดหลักตามลำดับนี้:

1. **ความถูกต้อง** — โค้ดต้องทำงานตามที่ต้องการ
2. **ความอ่านง่าย** — คนอื่นควรเข้าใจโค้ดได้โดยไม่ต้องเดา
3. **ความสม่ำเสมอ** — ใช้รูปแบบเดียวกันทั้งโปรเจกต์
4. **การดูแลรักษา** — แก้ไขและต่อยอดได้ง่าย
5. **ประสิทธิภาพ** — หลีกเลี่ยงการทำงานซ้ำหรือค้นหาสิ่งเดิมโดยไม่จำเป็น
6. **ความเรียบง่าย** — อย่าเพิ่มความซับซ้อนหากไม่มีประโยชน์จริง

> อย่า Optimize จนโค้ดอ่านไม่รู้เรื่อง
> Optimization ที่ดีคือการลดงานที่ไม่จำเป็น โดยยังรักษาความชัดเจนของโค้ดไว้

---

# 1. การตั้งชื่อ

ให้ใช้ **PascalCase** เป็นมาตรฐานในการตั้งชื่อ

### ตัวแปร

```lua
local PlayerName = "Example"
local Character = Player.Character
local TargetPlayer = nil
```

### ฟังก์ชัน

ฟังก์ชันที่เป็นส่วนหนึ่งของ Module ให้ประกาศไว้ใน `Module` โดยตรง

```lua
function Module:GetCharacter()
    return self.Character
end
```

ไม่ควรสร้างฟังก์ชันของ Module เป็น `local function`

```lua
-- ❌ ไม่ใช้
local function GetCharacter()
    return Character
end
```

---

# 2. ฟังก์ชันต้องอยู่ภายใน Module

หากฟังก์ชันเป็น Logic ของ Module ให้เก็บฟังก์ชันนั้นไว้ใน `Module`

### ถูกต้อง

```lua
function Module:GetCharacter()
    return self.Character
end

function Module:GetTarget()
    return self.Target
end

function Module:IsAlive()
    return self.Humanoid and self.Humanoid.Health > 0
end
```

เรียกใช้งานผ่าน Module:

```lua
Module:GetCharacter()
Module:GetTarget()
Module:IsAlive()
```

### ไม่ควรใช้

```lua
local function GetCharacter()
    return Character
end

local function GetTarget()
    return Target
end
```

เหตุผลคือ Logic ที่เกี่ยวข้องกันควรถูก **จัดกลุ่มและเป็นเจ้าของโดย Module เดียวกัน** เพื่อให้โครงสร้างโปรเจกต์ชัดเจนและค้นหาโค้ดได้ง่าย

---

# 3. ฟังก์ชันที่ Return Boolean ต้องขึ้นต้นด้วย `Is`

หากฟังก์ชันมีหน้าที่ตรวจสอบเงื่อนไขและผลลัพธ์เป็น `true` หรือ `false` ให้ขึ้นต้นชื่อด้วย **`Is`**

### ถูกต้อง

```lua
function Module:IsAlive()
    return self.Humanoid and self.Humanoid.Health > 0
end

function Module:IsEnemy(Object)
    return Object:IsDescendantOf(Enemies)
end

function Module:IsValidTarget(Target)
    return Target and Target.Parent ~= nil
end
```

ทำให้เวลาอ่านโค้ดสามารถเข้าใจได้ทันทีว่าเป็นการตรวจสอบ:

```lua
if Module:IsAlive() then
    Module:Attack()
end
```

```lua
if Module:IsValidTarget(Target) then
    Module:Attack(Target)
end
```

### ไม่ควรใช้

```lua
function Module:CheckAlive()
    return true
end

function Module:CheckEnemy(Object)
    return true
end
```

`Check` ไม่สื่อความหมายชัดเจนเท่า `Is`

---

# 4. แยกความหมายของ Function Prefix

ชื่อฟังก์ชันควรบอก **เจตนาของฟังก์ชัน** อย่างชัดเจน

| Prefix   | ความหมาย                    |
| -------- | --------------------------- |
| `Is`     | ตรวจสอบและคืนค่า Boolean    |
| `Get`    | ดึงค่าหรือ Object ที่มีอยู่ |
| `Find`   | ค้นหาและคืนค่าผลลัพธ์       |
| `Create` | สร้างสิ่งใหม่               |
| `Set`    | กำหนดค่า                    |
| `Update` | อัปเดตข้อมูลหรือ State      |
| `Remove` | ลบ Object หรือข้อมูล        |
| `Clear`  | ล้างข้อมูลหรือ State        |

### ตัวอย่าง

```lua
function Module:IsAlive()
    -- คืน true / false
end

function Module:GetCharacter()
    -- คืน Character
end

function Module:FindTarget()
    -- ค้นหา Target
end

function Module:CreateConnection()
    -- สร้าง Connection
end

function Module:SetTarget(Target)
    -- กำหนด Target
end

function Module:Update()
    -- อัปเดตข้อมูล
end
```

อย่าใช้ `Is` หากฟังก์ชันไม่ได้คืน Boolean

```lua
-- ❌ ไม่ถูกต้อง
function Module:IsTarget()
    return Target
end

-- ✅ ถูกต้อง
function Module:GetTarget()
    return Target
end
```

---

# 5. การวน Loop

**ห้ามใช้ `pairs()` และ `ipairs()`**

ให้ใช้ Generalized Iteration ของ Luau โดยตรง

### ถูกต้อง

```lua
for Index, Value in List do
    print(Index, Value)
end
```

```lua
for PlayerIndex, Player in Players do
    print(PlayerIndex, Player)
end
```

### ไม่ใช้

```lua
for Index, Value in pairs(List) do
    print(Index, Value)
end
```

```lua
for Index, Value in ipairs(List) do
    print(Index, Value)
end
```

---

# 6. การเข้าถึง Table

เมื่อใช้ตัวแปรหรือ Object เป็น Index ให้เว้นช่องภายใน `[]`

### ถูกต้อง

```lua
Table[ Object ] = 0

local Value = Table[ Object ]
local Data = Cache[ Player ]
local Target = Targets[ Index ]
```

### ไม่ใช้

```lua
Table[Object] = 0

local Value = Table[Object]
local Data = Cache[Player]
```

รูปแบบนี้ต้องใช้ให้สม่ำเสมอทั้งโปรเจกต์

---

# 7. การ Cache

เมื่อมีการค้นหา Object ที่มีโอกาสถูกเรียกใช้งานซ้ำ ให้พิจารณาใช้ Cache

ค่าที่ถูก Cache ให้ใช้ชื่อว่า **`Cached`**

หลักการคือ:

```text
ตรวจ Cache
    ↓
มีข้อมูล?
 ┌──┴──┐
ใช่    ไม่ใช่
 ↓       ↓
คืนค่า   ค้นหา
          ↓
        Cache
          ↓
        คืนค่า
```

### ตัวอย่าง

```lua
function Module:GetChest()
    local Cached = self.Cached

    if Cached then
        return Cached
    end

    for _, Object in workspace:GetChildren() do
        if Object.Name == "Chest" then
            self.Cached = Object

            return Object
        end
    end
end
```

### Pattern ที่ควรจำ

```lua
local Cached = self.Cached

if Cached then
    return Cached
end

-- ค้นหา Object

self.Cached = Object

return Object
```

---

# 8. Cache ไม่ใช่ Source of Truth

อย่าเชื่อ Cache แบบไม่มีเงื่อนไข

หาก Object สามารถถูกลบ, ย้าย, Destroy หรือเปลี่ยนแปลงได้ ต้องตรวจสอบความถูกต้องก่อนนำ Cache กลับมาใช้

### ตัวอย่าง

```lua
function Module:GetTarget()
    local Cached = self.Cached

    if Cached and Cached.Parent then
        return Cached
    end

    self.Cached = nil

    -- ค้นหา Target ใหม่

    if Target then
        self.Cached = Target
    end

    return Target
end
```

หลักสำคัญ:

> **Cache เป็นเพียง Optimization ไม่ใช่ Source of Truth**

หาก Cache ใช้งานไม่ได้ ให้ล้าง Cache และค้นหาใหม่

---

# 9. ใช้ Early Return

เมื่อเงื่อนไขไม่ผ่าน ให้ Return ทันทีเพื่อลด Nested Code

### ควรใช้

```lua
function Module:IsValidTarget(Target)
    if not Target then
        return false
    end

    if not Target.Parent then
        return false
    end

    return true
end
```

แทนที่จะเขียน Nested หลายชั้น:

```lua
function Module:IsValidTarget(Target)
    if Target then
        if Target.Parent then
            return true
        end
    end

    return false
end
```

Early Return ช่วยให้ Flow ของ Function อ่านจากบนลงล่างได้ง่ายกว่า

---

# 10. หลีกเลี่ยงการทำงานซ้ำ

หากสามารถเก็บผลลัพธ์ไว้ใช้ซ้ำได้ ให้เก็บไว้แทนการเรียก API เดิมหลายครั้ง

### ไม่ควร

```lua
if Player.Character then
    local Humanoid = Player.Character:FindFirstChildOfClass("Humanoid")

    if Player.Character:FindFirstChild("HumanoidRootPart") then
        -- ...
    end
end
```

### ควร

```lua
local Character = Player.Character

if not Character then
    return
end

local Humanoid = Character:FindFirstChildOfClass("Humanoid")
local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")

if not Humanoid or not HumanoidRootPart then
    return
end
```

หลักการ:

> **ค้นหาหนึ่งครั้ง เก็บไว้ใช้หลายครั้ง**

---

# 11. Function ควรมีหน้าที่ชัดเจน

หนึ่ง Function ควรมี **ความรับผิดชอบหลักเพียงอย่างเดียว**

### ควร

```lua
function Module:IsAlive()
    -- ตรวจสอบสถานะ
end

function Module:FindTarget()
    -- ค้นหา Target
end

function Module:Attack(Target)
    -- โจมตี Target
end
```

แทนการสร้าง Function ขนาดใหญ่ที่ทำทุกอย่าง:

```lua
function Module:DoEverything()
    -- Find Target
    -- Validate Target
    -- Update UI
    -- Attack
    -- Handle Cooldown
    -- Move
end
```

การแยกหน้าที่ทำให้ Debug และแก้ไขในอนาคตง่ายขึ้น

---

# 12. ใช้ `self` สำหรับ State ของ Module

หากข้อมูลเป็น State ที่เป็นของ Module ให้เข้าถึงผ่าน `self`

### ควร

```lua
function Module:GetCharacter()
    return self.Character
end

function Module:IsAlive()
    local Humanoid = self.Humanoid

    return Humanoid and Humanoid.Health > 0
end
```

วิธีนี้ทำให้ข้อมูลของ Module ถูกจัดการอย่างเป็นระบบและลดการพึ่งพา Global State โดยไม่จำเป็น

---

# 13. อย่าเขียนโค้ดให้สั้นจนอ่านไม่รู้เรื่อง

จำนวนบรรทัดที่น้อยลง **ไม่ได้หมายความว่าโค้ดดีขึ้นเสมอไป**

### อ่านง่าย

```lua
local Character = Player.Character

if not Character then
    return
end

local Humanoid = Character:FindFirstChildOfClass("Humanoid")

if not Humanoid then
    return
end
```

ดีกว่าการบีบ Logic หลายอย่างไว้ใน Expression เดียวจน Debug ยาก

> **ให้ Optimize งานที่โปรแกรมต้องทำ ไม่ใช่ Optimize จำนวนบรรทัด**

---

# 14. รักษา Convention เดียวกันทั้งโปรเจกต์

หากกำหนดรูปแบบใดไว้แล้ว ให้ใช้รูปแบบนั้นอย่างสม่ำเสมอ

### ควร

```lua
Module:IsAlive()
Module:IsValidTarget(Target)
Module:GetTarget()
Module:GetCharacter()
Module:FindEnemy()
```

### ไม่ควรปะปน

```lua
Module:IsAlive()
Module:checkTarget()
getCharacter()
Check_Enemy()
```

เป้าหมายคือทำให้ Developer สามารถคาดเดาชื่อ Function ได้โดยไม่ต้องเปิดดู Implementation

---

# 15. เมื่อแก้ไขโค้ดเดิม

เมื่อได้รับโค้ดที่มีอยู่แล้ว:

1. รักษา Logic เดิมที่ยังถูกต้อง
2. แก้เฉพาะส่วนที่จำเป็น
3. ปรับ Naming ให้ตรงกับ Convention
4. ลดโค้ดซ้ำ
5. เพิ่ม Cache เมื่อเหมาะสม
6. แยก Function หาก Function ใหญ่เกินไป
7. หลีกเลี่ยงการเปลี่ยน Architecture โดยไม่มีเหตุผล
8. อย่าเพิ่มระบบที่ไม่ได้ร้องขอ
9. หากมีหลายวิธี ให้เลือกวิธีที่ **อ่านง่ายและมีประสิทธิภาพที่สุด**
10. ผลลัพธ์สุดท้ายต้องยังคงพฤติกรรมเดิม เว้นแต่ผู้ใช้ต้องการเปลี่ยนพฤติกรรม

---

# สรุป Convention

| หัวข้อ              | มาตรฐาน                            |
| ------------------- | ---------------------------------- |
| ภาษา                | Luau                               |
| Platform            | Roblox                             |
| Variable            | `PascalCase`                       |
| Function            | `Module:PascalCase()`              |
| Boolean Function    | `Module:IsSomething()`             |
| ดึงข้อมูล           | `GetSomething()`                   |
| ค้นหา               | `FindSomething()`                  |
| สร้าง               | `CreateSomething()`                |
| ตั้งค่า             | `SetSomething()`                   |
| วน Loop             | `for Index, Value in List do`      |
| `pairs()`           | ❌ ห้ามใช้                          |
| `ipairs()`          | ❌ ห้ามใช้                          |
| Table Index         | `Table[ Object ]`                  |
| Cache               | `Cached`                           |
| Function ของ Module | เก็บใน `Module`                    |
| Function Boolean    | ขึ้นต้นด้วย `Is`                   |
| Control Flow        | Prefer Early Return                |
| Optimization        | ลดงานซ้ำโดยไม่ลดความอ่านง่าย       |
| Function Design     | หนึ่ง Function มีหน้าที่หลักชัดเจน |

---

# หลักการสุดท้าย

> **เขียนโค้ดให้คนอ่านเข้าใจได้ก่อน แล้วค่อยทำให้เครื่องทำงานได้เร็วขึ้น**
>
> โค้ดที่ดีไม่ใช่โค้ดที่สั้นที่สุด แต่คือโค้ดที่ **ชัดเจน, คาดเดาได้, มีโครงสร้าง, ไม่ทำงานซ้ำโดยไม่จำเป็น และสามารถแก้ไขต่อได้ง่าย**
