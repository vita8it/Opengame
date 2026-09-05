local _ENV = (getgenv or getrenv or getfenv)()

local Owner = "vita8it"
local Repository = "Next.js"

local Module, Settings = {}, {}
local Errors = _ENV.Errors or {}
local CachedOperators = {}

local Session = os.clock() do
    _ENV.Errors = Errors
    _ENV.Session = Session
    _ENV.Settings = Settings
end

local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local PlaceId = game.PlaceId
local Player = Players.LocalPlayer

local RenderStepped = RunService.RenderStepped
local Heartbeat = RunService.Heartbeat
local Stepped = RunService.Stepped

function Module:CreateModule(Name, Factory)
    Module[ Name ] = Factory(Module)

    return Module[ Name ]
end

function Module:Import(Path)
    local Url = string.format(
        "https://raw.githubusercontent.com/%s/%s/main/%s.luau",
        Owner, Repository, Path
    )

    local Success, Result = pcall(function()
        return game:HttpGet(Url)
    end)

    if not Success or not Result then
        return nil
    end

    return loadstring(Result)
end

function Module:Color(Text, Color)
    if type(Text) ~= "string" or typeof(Color) ~= "Color3" then
        return Text
    end

    local Red = math.floor(Color.R * 255)
    local Green = math.floor(Color.G * 255)
    local Blue = math.floor(Color.B * 255)

    return string.format(
        '<font color="rgb(%d, %d, %d)">%s</font>',
        Red, Green, Blue, Text
    )
end

function Module:FormatValue(Value)
    if typeof(Value) == "Instance" then
        return Value:GetFullName()
    end

    if type(Value) == "string" then
        return string.format("%q", Value)
    end

    return tostring(Value)
end

function Module:TableToString(Value, Indent, Seen)
    Indent = Indent or 0
    Seen = Seen or {}

    if type(Value) ~= "table" then
        return self:FormatValue(Value)
    end

    if Seen[ Value ] then
        return "<recursive>"
    end

    Seen[ Value ] = true

    local Space = string.rep("    ", Indent)
    local Result = { "{\n" }

    for Key, Object in Value do
        local KeyString = self:TableToString(Key, 0, Seen)
        local ObjectString = self:TableToString(Object, Indent + 1, Seen)

        table.insert(Result, string.format(
            "%s    [%s] = %s,\n",
            Space, KeyString, ObjectString
        ))
    end

    table.insert(Result, Space .. "}")

    return table.concat(Result)
end

Module:CreateModule("Connections", function()
    local Connections = _ENV.Connections or {}

    do
        _ENV.Connections = Connections

        for Index = 1, #Connections do
            Connections[ Index ]:Disconnect()
        end

        table.clear(Connections)
    end

    function Connections.Connect(Instance, Callback)
        local Connection = Instance:Connect(Callback)

        table.insert(Connections, Connection)

        return Connection
    end

    return Connections
end)

Module:CreateModule("Configurations", function()
    local Configurations = {}
    Configurations.__index = Configurations

    local FunctionNames = {
        "makefolder", "writefile", "isfolder",
        "readfile", "isfile", "delfile", "setclipboard",
    }

    for Index, FunctionName in FunctionNames do
        CachedOperators[ FunctionName ] = _ENV[ FunctionName ]
    end

    function Configurations:CreateFolder()
        for Index, Path in self.Paths do
            if not CachedOperators.isfolder(Path) then
                CachedOperators.makefolder(Path)
            end
        end
    end

    function Configurations:SetDefault(Index, Value)
        if rawget(self.Data, Index) ~= nil then
            return
        end

        rawset(self.Data, Index, Value)

        self:Save()
    end

    function Configurations:Save(Index, Value)
        if Index ~= nil then
            rawset(self.Data, Index, Value)
        end

        self:CreateFolder()

        local Json = HttpService:JSONEncode(self.Data)

        return CachedOperators.writefile(self.JsonPath, Json)
    end

    function Configurations:Load()
        if not CachedOperators.isfile(self.JsonPath) then
            self:Save()
        end

        local Success, Result = pcall(function()
            return HttpService:JSONDecode(
                CachedOperators.readfile(self.JsonPath)
            )
        end)

        if not Success or typeof(Result) ~= "table" then
            return
        end

        table.clear(self.Data)

        for Index, Value in Result do
            self.Data[ Index ] = Value
        end
    end

    function Configurations:Create(Folder)
        local NewConfig = setmetatable({}, Configurations)

        Folder = Folder or "Unknown"

        NewConfig.Files = Folder
        NewConfig.SettingsPath = string.format("%s/settings", Folder)
        NewConfig.JsonPath = string.format("%s/%s.json", NewConfig.SettingsPath, tostring(PlaceId))
        NewConfig.Paths = { NewConfig.Files, NewConfig.SettingsPath }
        NewConfig.Data = {}

        NewConfig:CreateFolder()
        NewConfig:Load()
        NewConfig:SetDefault("Success", true)

        Settings = setmetatable({}, {
            __index = function(_, Index)
                return NewConfig.Data[ Index ]
            end,
            __newindex = function(_, Index, Value)
                if NewConfig.Data[ Index ] ~= Value then
                    NewConfig.Data[ Index ] = Value

                    NewConfig:Save()
                end
            end,
        })

        _ENV.Settings = Settings

        return NewConfig
    end

    return Configurations
end)

Module:CreateModule("GoodQueue", function()
    local GoodQueue = {}
    GoodQueue.__index = GoodQueue

    function GoodQueue:ReportError(Message)
        _ENV.OnFarm = false

        local Option = _ENV.RunningOption or "Unknown"
        local Text = string.format("error [ %s ] %s", Option, Message)

        Errors[ Option ] = Errors[ Option ] or {}
        table.insert(Errors[ Option ], Message)

        local ExistingError = _ENV.Error

        if ExistingError and ExistingError.Parent then
            ExistingError.Text ..= string.format("\n\n%s", Text)

            return
        end

        ExistingError = Instance.new("Message")
        ExistingError.Parent = workspace
        ExistingError.Text = Text

        _ENV.Error = ExistingError
    end

    function GoodQueue:ResetQueue()
        if self.Resetting then
            return
        end

        self.Resetting = true

        local ExistingError = _ENV.Error
        local Option = _ENV.RunningOption
        local Fallback = self.Fallback

        if ExistingError and ExistingError.Parent then
            ExistingError.Text = "Start Refresh Options."

            task.wait(2)

            local Value = Option and Fallback[ Option ]

            if Value then
                pcall(Value.SetValue, Value, false)
                ExistingError.Text = string.format("Disabled : %s", Option)
            end

            task.wait(2)

            if ExistingError.Parent then
                ExistingError:Destroy()
            end

            if _ENV.Error == ExistingError then
                _ENV.Error = nil
            end
        end

        self.Resetting = false

        if _ENV.Session == Session then
            self:StartQueue()
        end
    end

    function GoodQueue:GetNextTask()
        for Index, Option in self.FarmFunctions do
            if type(Option) ~= "table" or type(Option.Function) ~= "function" then
                continue
            end

            local Name = Option.Name or "Unknown"

            _ENV.RunningOption = Name

            local Success, Result = pcall(Option.Function)

            if not Success then
                error(Result, 0)
            end

            if Result then
                _ENV.RunningMethod = type(Result) == "string" and Result or nil

                return Result
            end
        end

        _ENV.RunningOption = nil
        _ENV.RunningMethod = nil
    end

    function GoodQueue:StartQueue()
        if self.Running then
            return
        end

        self.Running = true

        task.spawn(function()
            local Success, Error = xpcall(function()
                while _ENV.Session == Session do
                    local Result = self:GetNextTask()

                    _ENV.OnFarm = Result ~= nil

                    Heartbeat:Wait()
                end

                _ENV.RunningOption = nil
                _ENV.RunningMethod = nil
                _ENV.OnFarm = false
            end, debug.traceback)

            self.Running = false

            if not Success and _ENV.Session == Session then
                self:ReportError(Error)

                task.delay(3, function()
                    if _ENV.Session == Session then
                        self:ResetQueue()
                    end
                end)
            end
        end)
    end

    function GoodQueue:UpdateOptions()
        table.clear(self.FarmFunctions)

        for Index, Value in self.NewValues do
            self.Cloneables[ Index ] = Value or nil
            self.NewValues[ Index ] = nil
        end

        for Index, Function in self.Functions do
            if self.Cloneables[ Function.Name ] then
                table.insert(self.FarmFunctions, Function)
            end
        end
    end

    function GoodQueue:WhileEnabled(Value, Interval, Callback, Break)
        Interval = Interval or 0.1

        while Value and _ENV.Session == Session do
            local StartTime = os.clock()

            if Callback then
                local Success, Error = pcall(Callback)

                if not Success then
                    error(Error, 0)
                end
            end

            if Break and Break() then
                break
            end

            repeat
                Heartbeat:Wait()
            until os.clock() - StartTime >= Interval or _ENV.Session ~= Session
        end
    end

    function GoodQueue:CreateOption(Flag, Function, Interval)
        if type(Flag) ~= "string" or type(Function) ~= "function" then
            return
        end

        if Interval then
            self.Threads[ Flag ] = function(Value)
                self:WhileEnabled(Value, Interval, Function, function()
                    return not Value or _ENV.Session ~= Session
                end)
            end

            return
        end

        self.Indexable[ Flag ] = Function

        table.insert(self.Functions, {
            Name = Flag,
            Function = Function,
        })
    end

    function GoodQueue:Create(Running)
        local NewQueue = setmetatable({}, GoodQueue)

        NewQueue.Fallback = {}
        NewQueue.NewValues = {}
        NewQueue.Cloneables = {}
        NewQueue.Threads = {}
        NewQueue.Indexable = {}
        NewQueue.Running = false
        NewQueue.Resetting = false

        NewQueue.Functions = _ENV.Functions or {}
        NewQueue.FarmFunctions = _ENV.FarmFunctions or {}

        NewQueue.Enableds = _ENV.Enableds or setmetatable({}, {
            __newindex = function(_, Index, Value)
                NewQueue.NewValues[ Index ] = Value or false

                NewQueue:UpdateOptions()
            end,
            __index = NewQueue.Cloneables,
        })

        _ENV.Functions = NewQueue.Functions
        _ENV.FarmFunctions = NewQueue.FarmFunctions
        _ENV.Enableds = NewQueue.Enableds

        if Running then
            NewQueue:StartQueue()
        end

        table.clear(NewQueue.Functions)

        return NewQueue
    end

    return GoodQueue
end)

Module:CreateModule("EachOthers", function()
    local EachOthers = {}

    function EachOthers:JoinServer(JobId)
        return TeleportService:TeleportToPlaceInstance(PlaceId, JobId, Player)
    end

    function EachOthers:GetServers(Cursor)
        local Url = string.format(
            "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100",
            tostring(PlaceId)
        )

        if Cursor then
            Url ..= string.format("&cursor=%s", Cursor)
        end

        local Result = game:HttpGet(Url)

        return HttpService:JSONDecode(Result)
    end

    function EachOthers:RejoinServer()
        if #Players:GetPlayers() <= 1 then
            Player:Kick("\nRejoining")

            task.wait()

            return TeleportService:Teleport(PlaceId, Player)
        end

        return self:JoinServer(game.JobId)
    end

    function EachOthers:ChangeServer()
        local Server, Next

        repeat
            local Servers = self:GetServers(Next)
            local Data = Servers and Servers.data

            Server = Data and Data[ 1 ]
            Next = Servers and Servers.nextPageCursor
        until Server

        if not Server or not Server.id then
            return
        end

        return self:JoinServer(Server.id)
    end

    function EachOthers:Set3DEnabled(Value)
        RunService:Set3dRenderingEnabled(not Value)
    end

    function EachOthers:SetLowGraphics()
        local Terrain = workspace:FindFirstChildOfClass("Terrain")

        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 0

        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9

        settings().Rendering.QualityLevel = 1
    end

    return EachOthers
end)

Module:CreateModule("Plugins", function()
    local Plugins = {}

    local Nodes = Module:Import("Utils/Library")()

    local Configurations = Module.Configurations
    local EachOthers = Module.EachOthers

    local Configurable = Configurations:Create("Next-js")

    Plugins.ParagraphTypes = {
        Icon = function(Paragraph, Value)
            return Paragraph:Icon(Value)
        end,
        Text = function(Paragraph, Value)
            return Paragraph:Typography(Value)
        end,
        Status = function(Paragraph, Value)
            return Paragraph:Status(Value)
        end,
    }

    function Plugins:SetDefault(...)
        Configurable:SetDefault(...)
    end

    function Plugins:CreateProxy(Tab)
        local Proxy = {}

        function Proxy:Section(Name, Callback)
            local Element = Tab[ Name ]

            if not Element then
                Element = Tab:Section(Name)
                rawset(Tab, Name, Element)
            end

            if Callback then
                Callback(Element)
            end

            return Element
        end

        setmetatable(Proxy, {
            __index = function(_, Index)
                return Tab[ Index ]
            end,
            __newindex = function(_, Index, Value)
                rawset(Tab, Index, Value)
            end,
        })

        return Proxy
    end

    function Plugins:Window(Queueable, Args)
        Args = Args or {}

        self.Nodes = Nodes
        self.Enableds = Queueable.Enableds
        self.Fallback = Queueable.Fallback
        self.Threads = Queueable.Threads

        self.Library = Nodes.Application("Next.js", {
            Title = Args[ 1 ] or "Xynapse",
            Footer = Args[ 2 ] or "Made by vita8it",
            Logo = Args[ 3 ] or 124715602753920,
        })

        return self.Library
    end

    function Plugins:Notify(Args, Duration)
        return self.Library:Notification({
            Title = Args[ 1 ],
            Description = Args[ 2 ],
            Icon = Args[ 3 ] or 107131709546324,
            Duration = Duration or 5,
        })
    end

    function Plugins:Dialog(Args, Callback)
        return self.Library:Dialog({
            Title = Args[ 1 ],
            Description = "Are you sure?",
            Content = Args[ 2 ],
            Icon = Args[ 3 ] or 107131709546324,
            Callback = function(State)
                if State then
                    task.spawn(pcall, Callback)
                end
            end,
        })
    end

    function Plugins:CreateTab(Args)
        local NewTab = self.Library:MakeTab({
            Title = Args[ 1 ],
            Description = Args[ 2 ] or "Automatically",
            Icon = Args[ 3 ],
        })

        return self:CreateProxy(NewTab)
    end

    function Plugins:Paragraph(Section, Args, Types)
        local Paragraph = Section:Paragraph({
            Title = Args[ 1 ],
            Description = Args[ 2 ],
        })

        if not Types then
            return Paragraph
        end

        local Handler = Plugins.ParagraphTypes[ Types[ 1 ] ]

        if Handler then
            return Handler(Paragraph, Types[ 2 ])
        end

        return Paragraph
    end

    function Plugins:Button(Section, Args, Callback)
        return Section:Button({
            Title = Args[ 1 ],
            Description = Args[ 2 ],
            Type = Args[ 3 ] or "Primary",
            Callback = Callback,
        })
    end

    function Plugins:Toggle(Section, Args, Flag, Callback)
        local CurrentThread = nil

        self.Fallback[ Flag ] = Section:Toggle({
            Title = Args[ 1 ],
            Description = Args[ 2 ],
            Value = Settings[ Flag ],
            Callback = function(_, Value)
                Settings[ Flag ] = Value
                self.Enableds[ Flag ] = Value

                if Value and self.Threads[ Flag ] then
                    CurrentThread = task.spawn(self.Threads[ Flag ], Value)
                elseif CurrentThread then
                    task.cancel(CurrentThread)
                end

                if Callback then
                    Callback(Value)
                end
            end,
        })

        return self.Fallback[ Flag ]
    end

    function Plugins:Slider(Section, Args, Values, Flag, Callback)
        return Section:Slider({
            Title = Args[ 1 ],
            Description = Args[ 2 ],
            Min = Values[ 1 ],
            Max = Values[ 2 ],
            Rounding = Values[ 3 ],
            Value = Settings[ Flag ],
            Callback = function(_, Value)
                Settings[ Flag ] = Value

                if Callback then
                    Callback(Value)
                end
            end,
        })
    end

    function Plugins:Dropdown(Section, Title, List, Flag, Callback)
        return Section:Dropdown({
            Title = Title,
            Value = Settings[ Flag ] or "None",
            List = List,
            Callback = function(_, Value)
                Settings[ Flag ] = Value

                if Callback then
                    Callback(Value)
                end
            end,
        })
    end

    function Plugins:Textbox(Section, Args, Flag, Callback)
        return Section:Textbox({
            Title = Args[ 1 ],
            Description = Args[ 2 ],
            Value = Settings[ Flag ] or "None",
            Callback = function(_, Value)
                Settings[ Flag ] = Value

                if Callback then
                    Callback(Value)
                end
            end,
        })
    end

    function Plugins:Community()
        local Community = self:CreateTab({
            "Community", "Integration", 115960025411300
        })

        Community:Section("Community", function(Section)
            Plugins:Paragraph(Section, {
                "Welcome",
                string.format("%s, What would you like to do today?", os.date("%d/%m/%Y")),
            }, { "Icon", 107131709546324 })

            local Members = Plugins:Paragraph(Section, {
                "Members",
                "All member in our discord.",
            }, { "Text", "N/A" })

            Plugins:Button(Section, {
                "Discord",
                "Join our community.",
            }, function()
                pcall(CachedOperators.setclipboard, "https://discord.gg/Q2jyDsT9yv")

                Plugins:Notify({
                    "Copy Discord", "Copy success.", 116378866141355
                })
            end)

            task.defer(function()
                local InviteCode = "nb6xyzwngH"
                local Url = string.format(
                    "https://discord.com/api/v10/invites/%s?with_counts=true&with_expiration=true",
                    InviteCode
                )

                local Request = request({
                    Url = Url,
                    Method = "GET",
                    Headers = {
                        ["User-Agent"] = "WindUI/Example",
                        ["Accept"] = "application/json",
                    },
                })

                local Response = HttpService:JSONDecode(Request and Request.Body or "{}")

                if Response and Response.guild then
                    local OnlineCount = Response.approximate_presence_count or 0
                    local MemberCount = Response.approximate_member_count or 0

                    Members.Text = Module:Color(tostring(OnlineCount), Color3.fromRGB(255, 255, 255)) .. " | " .. MemberCount
                end
            end)
        end)

        return Community
    end

    function Plugins:Managers()
        local Managers = self:CreateTab({
            "Managers", "Extension", 127866486547434
        })

        Managers:Section("Developing", function(Section)
            Plugins:Button(Section, {
                "Copy Error",
                "Copy all errors that have occurred.",
                "Secondary"
            }, function()
                pcall(CachedOperators.setclipboard, Module:TableToString(Errors))

                Plugins:Notify({
                    "Copy Error", "Copy success.", 116378866141355
                })
            end)

            Plugins:Button(Section, {
                "Remove WorkSpace",
                "Reset save setting file to default value.",
                "Danger"
            }, function()
                local JsonPath = Configurable.JsonPath

                if JsonPath and CachedOperators.isfile(JsonPath) then
                    pcall(CachedOperators.delfile, JsonPath)
                end
            end)
        end)

        Managers:Section("Server", function(Section)
            Configurable:SetDefault("JobId", game.JobId)

            Plugins:Textbox(Section, {
                "JobId",
                "Put the job id.",
            }, "JobId")

            Plugins:Button(Section, {
                "Join",
                "Connect to the server using the provided JobId.",
            }, function()
                EachOthers:JoinServer(Settings.JobId)
            end)

            Plugins:Button(Section, {
                "Change",
                "Teleport to a different public server instance.",
                "Secondary"
            }, function()
                task.spawn(function()
                    Plugins:Notify({
                        "Server", "Wait for hopping .", 105706502741449
                    })

                    EachOthers:ChangeServer()
                end)
            end)

            Plugins:Button(Section, {
                "Rejoin",
                "Reconnect to the current server instance.",
                "Secondary"
            }, function()
                EachOthers:RejoinServer()
            end)
        end)

        Managers:Section("Optimize", function(Section)
            Plugins:Toggle(Section, {
                "White Screen",
                "Disabled 3D Rendering to improve performance."
            }, "White Screen", function(Value)
                EachOthers:Set3DEnabled(Value)
            end)

            Plugins:Button(Section, {
                "Fast Mode",
                "Set graphics quality to low."
            }, function()
                EachOthers:SetLowGraphics()

                Plugins:Notify({
                    "Fast Mode", "Has been enabled.", 140109651313859
                })
            end)
        end)

        return Managers
    end

    return Plugins
end)

return Module, Settings
