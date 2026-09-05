local Saves, Cached = {}, {}

local HttpService = game:GetService( "HttpService" )
local Players = game:GetService( "Players" )

local LocalPlayer = Players.LocalPlayer
local FolderName = "Dump-" .. HttpService:GenerateGUID( false )

local Blacklist = {
    -- ["Camera"] = true,
    -- ["Terrain"] = true,
}

local Allowed = {
    workspace,
    game.ReplicatedStorage,
    game.ReplicatedFirst,
    game.Lighting,
    game.StarterPlayer,
    game.StarterGui,
    game.Players,
}

function Saves:IsAllowed( Object )
    for _, AllowedObject in Allowed do
        if Object == AllowedObject then
            return true
        end

        if Object:IsDescendantOf( AllowedObject ) then
            return true
        end
    end

    return false
end

function Saves:IsBlacklisted( Object )
    return Blacklist[ Object.Name ] == true
end

function Saves:IsScript( Object )
    return Object:IsA( "LocalScript" )
        or Object:IsA( "ModuleScript" )
end

function Saves:IsOwnScript( Object )
    if not self:IsScript( Object ) then
        return false
    end

    if not LocalPlayer then
        return false
    end

    if not Object:IsDescendantOf( Players ) then
        return true
    end

    return Object:IsDescendantOf( LocalPlayer )
end

function Saves:SanitizeName( Name )
    Name = tostring( Name )

    Name = Name:gsub(
        '[<>:"/\\|?*]',
        "_"
    )

    Name = Name:gsub(
        "[%c]",
        "_"
    )

    Name = Name:gsub(
        "[%. ]+$",
        ""
    )

    if Name == "" then
        Name = "_"
    end

    local Reserved = {
        CON = true,
        PRN = true,
        AUX = true,
        NUL = true,

        COM1 = true,
        COM2 = true,
        COM3 = true,
        COM4 = true,
        COM5 = true,
        COM6 = true,
        COM7 = true,
        COM8 = true,
        COM9 = true,

        LPT1 = true,
        LPT2 = true,
        LPT3 = true,
        LPT4 = true,
        LPT5 = true,
        LPT6 = true,
        LPT7 = true,
        LPT8 = true,
        LPT9 = true,
    }

    if Reserved[ Name:upper() ] then
        Name = "_" .. Name
    end

    return Name
end

function Saves:CreateFolder( Path )
    if isfolder( Path ) then
        return true
    end

    local Success, Result = pcall(
        makefolder,
        Path
    )

    if not Success then
        warn(
            "[CreateFolder] Failed:",
            Path,
            Result
        )

        return false
    end

    return true
end

function Saves:HasScript( Object )
    if self:IsBlacklisted( Object ) then
        return false
    end

    if self:IsScript( Object ) then
        return self:IsOwnScript( Object )
    end

    for _, Child in Object:GetChildren() do
        if self:HasScript( Child ) then
            return true
        end
    end

    return false
end

function Saves:BuildTree( Object )
    if self:IsBlacklisted( Object ) then
        return nil
    end

    local Node = {
        Name = Object.Name,
        ClassName = Object.ClassName,
        Source = Object:GetFullName(),
        Children = {}
    }

    for _, Child in Object:GetChildren() do
        if not self:IsAllowed( Child ) then
            continue
        end

        local ChildNode = self:BuildTree( Child )

        if ChildNode then
            Node.Children[
                #Node.Children + 1
            ] = ChildNode
        end
    end

    return Node
end

function Saves:TreeToString( Node, Prefix, IsLast )
    Prefix = Prefix or ""
    IsLast = IsLast == nil and true or IsLast

    local Result = {}

    if Node.Name == "game" then
        Result[ #Result + 1 ] =
            Node.Name
            .. " : ("
            .. Node.ClassName
            .. ")"
    else
        local Branch =
            IsLast and "└── " or "├── "

        Result[ #Result + 1 ] =
            Prefix
            .. Branch
            .. Node.Name
            .. " : ("
            .. Node.ClassName
            .. ")"
    end

    local Children = Node.Children
    local Count = #Children

    for Index, Child in Children do
        local Last = Index == Count

        local ChildPrefix

        if Node.Name == "game" then
            ChildPrefix = ""
        elseif IsLast then
            ChildPrefix = Prefix .. "    "
        else
            ChildPrefix = Prefix .. "│   "
        end

        local ChildResult = self:TreeToString(
            Child,
            ChildPrefix,
            Last
        )

        for Line in string.gmatch(
            ChildResult,
            "[^\n]+"
        ) do
            Result[ #Result + 1 ] = Line
        end
    end

    return table.concat(
        Result,
        "\n"
    )
end

function Saves:GetFolderPath( Object )
    local Parts = {}
    local Current = Object

    while Current and Current ~= game do
        Parts[ #Parts + 1 ] =
            self:SanitizeName( Current.Name )

        Current = Current.Parent
    end

    local Path = FolderName

    for Index = #Parts, 1, -1 do
        Path ..= "\\" .. Parts[ Index ]
    end

    return Path
end

function Saves:CreateObjectFolder( Object )
    local Parts = {}
    local Current = Object

    while Current and Current ~= game do
        Parts[ #Parts + 1 ] =
            self:SanitizeName( Current.Name )

        Current = Current.Parent
    end

    local Path = FolderName

    if not self:CreateFolder( Path ) then
        return nil
    end

    for Index = #Parts, 1, -1 do
        Path ..= "\\" .. Parts[ Index ]

        if not self:CreateFolder( Path ) then
            return nil
        end
    end

    return Path
end

function Saves:SaveScript( Object )
    if not self:IsScript( Object ) then
        return
    end

    if not self:IsAllowed( Object ) then
        return
    end

    if not self:IsOwnScript( Object ) then
        return
    end

    if self:IsBlacklisted( Object ) then
        return
    end

    local Parent = Object.Parent

    if not Parent then
        return
    end

    local FolderPath =
        self:CreateObjectFolder( Parent )

    if not FolderPath then
        return
    end

    local FileName =
        self:SanitizeName( Object.Name )
        .. ".lua"

    local FilePath =
        FolderPath
        .. "\\"
        .. FileName

    task.spawn( function()
        local Success, Source = pcall(
            decompile,
            Object
        )

        if not Success then
            warn(
                "[Decompile] Failed:",
                Object:GetFullName(),
                Source
            )

            return
        end

        if type( Source ) ~= "string" then
            warn(
                "[Decompile] Invalid source:",
                Object:GetFullName()
            )

            return
        end

        local WriteSuccess, WriteError = pcall(
            writefile,
            FilePath,
            Source
        )

        if not WriteSuccess then
            warn(
                "[WriteFile] Failed:",
                FilePath,
                WriteError
            )

            return
        end

        print(
            "[Decompile] Saved:",
            Object:GetFullName()
        )
    end )

    return FilePath
end

function Saves:BuildFilesystem( Object )
    if self:IsBlacklisted( Object ) then
        return
    end

    if self:IsScript( Object ) then
        self:SaveScript( Object )
        return
    end

    if not self:HasScript( Object ) then
        return
    end

    local FolderPath =
        self:CreateObjectFolder( Object )

    if not FolderPath then
        return
    end

    for _, Child in Object:GetChildren() do
        if not self:IsAllowed( Child ) then
            continue
        end

        self:BuildFilesystem( Child )
    end
end

function Saves:SaveExplorer()
    Cached.Tree = {
        Name = "game",
        ClassName = "DataModel",
        Source = "game",
        Children = {}
    }

    for _, Object in Allowed do
        local Node = self:BuildTree( Object )

        if Node then
            Cached.Tree.Children[
                #Cached.Tree.Children + 1
            ] = Node
        end
    end

    Saves.Tree = self:TreeToString(
        Cached.Tree
    )

    local Success, Error = pcall(
        writefile,
        FolderName .. "\\Explorer.txt",
        Saves.Tree
    )

    if not Success then
        warn(
            "[Explorer] Failed:",
            Error
        )
    end
end

function Saves:CollectScripts()
    Cached.Builder.Scripts = {}

    for _, Object in game:GetDescendants() do
        if not self:IsScript( Object ) then
            continue
        end

        if not self:IsAllowed( Object ) then
            continue
        end

        if not self:IsOwnScript( Object ) then
            continue
        end

        if self:IsBlacklisted( Object ) then
            continue
        end

        local Parent = Object.Parent

        if not Parent then
            continue
        end

        local FilePath =
            self:GetFolderPath( Parent )
            .. "\\"
            .. self:SanitizeName( Object.Name )
            .. ".lua"

        Cached.Builder.Scripts[
            #Cached.Builder.Scripts + 1
        ] = {
            Name = Object.Name,
            ClassName = Object.ClassName,
            Path = Object:GetFullName(),
            File = FilePath
        }
    end
end

function Saves:Build()
    Cached.Builder = {
        Name = FolderName,
        Explorer = nil,
        Scripts = {}
    }

    if not self:CreateFolder( FolderName ) then
        error(
            "Unable to create dump folder: "
            .. FolderName
        )
    end

    print(
        "[Dump] Folder:",
        FolderName
    )

    self:SaveExplorer()

    Cached.Builder.Explorer =
        Saves.Tree

    for _, Object in Allowed do
        self:BuildFilesystem( Object )
    end

    self:CollectScripts()

    return Cached.Builder
end

local Builder = Saves:Build()

print( "================================" )
print( "        Xynapse Dumper" )
print( "================================" )
print( "Folder:", FolderName )
print( "Scripts:", #Builder.Scripts )
print( "Explorer: Saved" )
print( "================================" )
