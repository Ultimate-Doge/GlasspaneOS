-- ============================================
-- GlasspaneOS
-- Definitely not Windows.
-- ============================================

local basalt = require("basalt")

local ROOT = "/glasspaneos"

package.path =
    ROOT .. "/?.lua;"
    .. package.path

local basalt = require("basalt")

local Icons = require("system.icons")
local Updater = require("system.updater")

local USER_FILES =
    ROOT .. "/user/files"

local NOTES =
    ROOT .. "/notes"

local APPS =
    ROOT .. "/apps"

-- ============================================
-- Ensure folders exist
-- ============================================

fs.makeDir(USER_FILES)
fs.makeDir(NOTES)
fs.makeDir(APPS)

-- ============================================
-- Desktop
-- ============================================

local main =
    basalt.getMainFrame()

main.background = colors.lightBlue

local screenW, screenH =
    term.getSize()

-- ============================================
-- Top bar
-- ============================================

main:addFrame({
    x = 1,
    y = 1,
    width = screenW,
    height = 1,
    background = colors.blue
})

main:addLabel({
    x = 2,
    y = 1,
    text = "GlasspaneOS",
    foreground = colors.white,
    background = colors.blue
})

main:addLabel({
    x = 16,
    y = 1,
    text = "Definitely not Windows.",
    foreground = colors.lightGray,
    background = colors.blue
})

-- ============================================
-- Window system
-- ============================================

local windowCount = 0

local function clamp(value, minimum, maximum)

    return math.max(
        minimum,
        math.min(value, maximum)
    )
end

local function createWindow(
    title,
    x,
    y,
    width,
    height
)

    windowCount = windowCount + 1

    local window =
        main:addFrame({
            x = x,
            y = y,
            width = width,
            height = height,
            background = colors.lightGray
        })

    window.glasspane = {
        title = title,
        normalX = x,
        normalY = y,
        normalWidth = width,
        normalHeight = height,
        minimized = false,
        maximized = false,
        lastDragX = nil,
        lastDragY = nil,
        lastResizeX = nil,
        lastResizeY = nil
    }

    -- ========================================
    -- Title bar
    -- ========================================

    local titleBar =
        window:addFrame({
            x = 1,
            y = 1,
            width = width,
            height = 1,
            background = colors.blue
        })

    titleBar:addLabel({
        x = 2,
        y = 1,
        width = width - 10,
        text = title,
        foreground = colors.white,
        background = colors.blue
    })

    -- ========================================
    -- Minimise
    -- ========================================

    local minimize =
        titleBar:addButton({
            x = width - 6,
            y = 1,
            width = 2,
            height = 1,
            text = "_",
            background = colors.blue,
            foreground = colors.white
        })

    -- ========================================
    -- Maximise
    -- ========================================

    local maximize =
        titleBar:addButton({
            x = width - 4,
            y = 1,
            width = 2,
            height = 1,
            text = "+",
            background = colors.blue,
            foreground = colors.white
        })

    -- ========================================
    -- Close
    -- ========================================

    local close =
        titleBar:addButton({
            x = width - 2,
            y = 1,
            width = 2,
            height = 1,
            text = "X",
            background = colors.red,
            foreground = colors.white
        })

    -- ========================================
    -- Window dragging
    -- ========================================

    titleBar:onDrag(
        function(self, button, dragX, dragY)

            if window.glasspane.minimized
                or window.glasspane.maximized
            then
                return
            end

            if not window.glasspane.lastDragX then

                window.glasspane.lastDragX =
                    dragX

                window.glasspane.lastDragY =
                    dragY

                return
            end

            local moveX =
                dragX
                - window.glasspane.lastDragX

            local moveY =
                dragY
                - window.glasspane.lastDragY

            window.x =
                clamp(
                    window.x + moveX,
                    1,
                    math.max(
                        1,
                        screenW - window.width + 1
                    )
                )

            window.y =
                clamp(
                    window.y + moveY,
                    2,
                    math.max(
                        2,
                        screenH - window.height + 1
                    )
                )

            window.glasspane.lastDragX =
                dragX

            window.glasspane.lastDragY =
                dragY
        end
    )

    titleBar:onClickUp(
        function()

            window.glasspane.lastDragX =
                nil

            window.glasspane.lastDragY =
                nil
        end
    )

    -- ========================================
    -- Resize grip
    -- ========================================

    local resizeGrip =
        window:addButton({
            x = function()
                return window.width - 1
            end,

            y = function()
                return window.height
            end,

            width = 2,
            height = 1,
            text = "\\",
            background = colors.gray,
            foreground = colors.white
        })

    resizeGrip:onDrag(
        function(
            self,
            button,
            dragX,
            dragY
        )

            if window.glasspane.minimized
                or window.glasspane.maximized
            then
                return
            end

            if not window.glasspane.lastResizeX then

                window.glasspane.lastResizeX =
                    dragX

                window.glasspane.lastResizeY =
                    dragY

                return
            end

            local addW =
                dragX
                - window.glasspane.lastResizeX

            local addH =
                dragY
                - window.glasspane.lastResizeY

            window.width =
                clamp(
                    window.width + addW,
                    20,
                    screenW
                )

            window.height =
                clamp(
                    window.height + addH,
                    8,
                    screenH - 1
                )

            window.glasspane.lastResizeX =
                dragX

            window.glasspane.lastResizeY =
                dragY
        end
    )

    resizeGrip:onClickUp(
        function()

            window.glasspane.lastResizeX =
                nil

            window.glasspane.lastResizeY =
                nil
        end
    )

    -- ========================================
    -- Close
    -- ========================================

    close:onClick(function()

        window:destroy()

    end)

    -- ========================================
    -- Minimise
    -- ========================================

    minimize:onClick(function()

        if window.glasspane.minimized then

            window.height =
                window.glasspane.normalHeight

            window.glasspane.minimized =
                false

        else

            window.glasspane.normalHeight =
                window.height

            window.height = 1

            window.glasspane.minimized =
                true
        end
    end)

    -- ========================================
    -- Maximise
    -- ========================================

    maximize:onClick(function()

        if window.glasspane.maximized then

            window.x =
                window.glasspane.normalX

            window.y =
                window.glasspane.normalY

            window.width =
                window.glasspane.normalWidth

            window.height =
                window.glasspane.normalHeight

            window.glasspane.maximized =
                false

        else

            window.glasspane.normalX =
                window.x

            window.glasspane.normalY =
                window.y

            window.glasspane.normalWidth =
                window.width

            window.glasspane.normalHeight =
                window.height

            window.x = 1
            window.y = 2

            window.width = screenW
            window.height = screenH - 1

            window.glasspane.maximized =
                true
        end
    end)

    return window
end

-- ============================================
-- Draw icon
-- ============================================

local function drawIcon(
    parent,
    icon,
    x,
    y
)

    for row, line
        in ipairs(icon.lines)
    do

        for column = 1, #line do

            local char =
                line:sub(column, column)

            local colour =
                Icons.getColour(
                    icon,
                    char
                )

            if colour then

                parent:addLabel({
                    x = x + column - 1,
                    y = y + row - 1,
                    text = " ",
                    background = colour
                })
            end
        end
    end
end

-- ============================================
-- Lua syntax colours
-- ============================================

local function setupLuaSyntax(editor)

    editor:addSyntaxPattern(
        "%-%-.-$",
        colors.gray
    )

    editor:addSyntaxPattern(
        "\".-\"",
        colors.yellow
    )

    editor:addSyntaxPattern(
        "'.-'",
        colors.yellow
    )

    editor:addSyntaxPattern(
        "%f[%a](function|local|return|if|then|end|for|while|do|repeat|until)%f[%A]",
        colors.lightBlue
    )

    editor:addSyntaxPattern(
        "%f[%a](true|false|nil)%f[%A]",
        colors.orange
    )
end

-- ============================================
-- Text / Code Editor
-- ============================================

local function openEditor(filePath)

    local window =
        createWindow(
            "Glass Editor",
            4,
            3,
            42,
            18
        )

    local pathInput =
        window:addInput({
            x = 2,
            y = 2,
            width = function()
                return window.width - 4
            end,

            text = filePath or "",
            placeholder = "File path..."
        })

    local editor =
        window:addTextBox({
            x = 2,
            y = 4,

            width = function()
                return window.width - 4
            end,

            height = function()
                return window.height - 7
            end,

            background = colors.black,
            foreground = colors.white
        })

    -- ========================================
    -- Load file
    -- ========================================

    if filePath
        and fs.exists(filePath)
        and not fs.isDir(filePath)
    then

        local file =
            fs.open(filePath, "r")

        editor:setText(
            file.readAll()
        )

        file.close()
    end

    -- ========================================
    -- Syntax highlighting
    -- ========================================

    local function updateSyntax()

        editor:clearSyntaxPatterns()

        local path =
            pathInput.text or ""

        if path:sub(-4) == ".lua" then
            setupLuaSyntax(editor)
        end
    end

    updateSyntax()

    pathInput:onChange(
        function()
            updateSyntax()
        end
    )

    -- ========================================
    -- Save helper
    -- ========================================

    local function save()

        local path =
            pathInput.text

        if not path
            or path == ""
        then
            return false
        end

        local folder =
            fs.getDir(path)

        if folder ~= ""
            and not fs.exists(folder)
        then

            fs.makeDir(folder)
        end

        local file =
            fs.open(path, "w")

        if not file then
            return false
        end

        file.write(
            editor:getText()
        )

        file.close()

        return true
    end

    -- ========================================
    -- Save
    -- ========================================

    window:addButton({
        x = 2,

        y = function()
            return window.height - 2
        end,

        width = 8,
        text = "Save"
    }):onClick(
        function()
            save()
        end
    )

    -- ========================================
    -- Run Lua
    -- ========================================

    window:addButton({
        x = 11,

        y = function()
            return window.height - 2
        end,

        width = 8,
        text = "Run"
    }):onClick(
        function()

            local path =
                pathInput.text

            if path
                and path:sub(-4) == ".lua"
            then

                if save() then

                    local runWindow =
                        createWindow(
                            "Running: "
                            .. fs.getName(path),
                            5,
                            4,
                            40,
                            16
                        )

                    local program =
                        runWindow:addProgram({
                            x = 2,
                            y = 3,

                            width = function()
                                return runWindow.width - 4
                            end,

                            height = function()
                                return runWindow.height - 5
                            end
                        })

                    program:execute(path)
                end
            end
        end
    )

    editor:focus()
end

-- ============================================
-- Simple popup
-- ============================================

local function inputPopup(
    title,
    labelText,
    callback
)

    local popup =
        createWindow(
            title,
            8,
            6,
            32,
            9
        )

    popup:addLabel({
        x = 2,
        y = 3,
        text = labelText
    })

    local input =
        popup:addInput({
            x = 2,
            y = 5,
            width = 28
        })

    popup:addButton({
        x = 2,
        y = 7,
        width = 10,
        text = "OK"
    }):onClick(
        function()

            callback(input.text)

            popup:destroy()
        end
    )

    popup:addButton({
        x = 14,
        y = 7,
        width = 10,
        text = "Cancel"
    }):onClick(
        function()

            popup:destroy()
        end
    )

    input:focus()
end

-- ============================================
-- File Explorer
-- ============================================

local function openExplorer(
    startPath
)

    local currentPath =
        startPath or USER_FILES

    local window =
        createWindow(
            "Glass Explorer",
            3,
            3,
            46,
            20
        )

    local pathLabel =
        window:addLabel({
            x = 2,
            y = 2,

            width = function()
                return window.width - 4
            end,

            text = currentPath,
            foreground = colors.gray
        })

    local list =
        window:addList({
            x = 7,
            y = 4,

            width = function()
                return window.width - 9
            end,

            height = function()
                return window.height - 7
            end,

            scrollbar = "auto"
        })

    -- ========================================
    -- Get icon
    -- ========================================

    local function getIcon(path)

        if fs.isDir(path) then
            return Icons.folder
        end

        if path:sub(-4) == ".lua" then
            return Icons.lua
        end

        if path:sub(-4) == ".txt" then
            return Icons.note
        end

        return Icons.file
    end

    -- ========================================
    -- Refresh
    -- ========================================

    local function refresh()

        list:clear()

        pathLabel.text =
            currentPath

        local files =
            fs.list(currentPath)

        table.sort(
            files,
            function(a, b)

                local pathA =
                    fs.combine(
                        currentPath,
                        a
                    )

                local pathB =
                    fs.combine(
                        currentPath,
                        b
                    )

                if fs.isDir(pathA)
                    ~= fs.isDir(pathB)
                then

                    return fs.isDir(pathA)
                end

                return a:lower()
                    < b:lower()
            end
        )

        for _, name
            in ipairs(files)
        do

            local path =
                fs.combine(
                    currentPath,
                    name
                )

            list:addItem({
                text = name,
                value = path
            })
        end
    end

    -- ========================================
    -- Open
    -- ========================================

    local function openSelected()

        local item =
            list:getSelectedItem()

        if not item then
            return
        end

        local path =
            item.value

        if fs.isDir(path) then

            currentPath = path
            refresh()

        else

            openEditor(path)
        end
    end

    list:onSelect(
        function()
            openSelected()
        end
    )

    -- ========================================
    -- Icon preview
    -- ========================================

    local iconArea =
        window:addFrame({
            x = 2,
            y = 5,
            width = 4,
            height = 5,
            background = colors.lightGray
        })

    list:onChange(
        function(
            self,
            index,
            item
        )

            for _, child
                in pairs(iconArea.children or {})
            do
                child:destroy()
            end

            if item then

                local icon =
                    getIcon(item.value)

                drawIcon(
                    iconArea,
                    icon,
                    1,
                    1
                )
            end
        end
    )

    -- ========================================
    -- Back
    -- ========================================

    window:addButton({
        x = 2,

        y = function()
            return window.height - 2
        end,

        width = 5,
        text = "< Back"
    }):onClick(
        function()

            if currentPath ~= USER_FILES then

                local parent =
                    fs.getDir(
                        currentPath
                    )

                if parent == ""
                    or parent == "/"
                then

                    currentPath =
                        USER_FILES

                else

                    currentPath = parent
                end

                refresh()
            end
        end
    )

    -- ========================================
    -- New file
    -- ========================================

    window:addButton({
        x = 8,

        y = function()
            return window.height - 2
        end,

        width = 9,
        text = "New File"
    }):onClick(
        function()

            inputPopup(
                "New File",
                "File name:",
                function(name)

                    if name == ""
                        or not name
                    then
                        return
                    end

                    local path =
                        fs.combine(
                            currentPath,
                            name
                        )

                    if not fs.exists(path) then

                        local file =
                            fs.open(
                                path,
                                "w"
                            )

                        file.write("")
                        file.close()

                        refresh()

                        openEditor(path)
                    end
                end
            )
        end
    )

    -- ========================================
    -- New folder
    -- ========================================

    window:addButton({
        x = 18,

        y = function()
            return window.height - 2
        end,

        width = 11,
        text = "New Folder"
    }):onClick(
        function()

            inputPopup(
                "New Folder",
                "Folder name:",
                function(name)

                    if name == ""
                        or not name
                    then
                        return
                    end

                    local path =
                        fs.combine(
                            currentPath,
                            name
                        )

                    if not fs.exists(path) then

                        fs.makeDir(path)

                        refresh()
                    end
                end
            )
        end
    )

    -- ========================================
    -- Delete
    -- ========================================

    window:addButton({
        x = 31,

        y = function()
            return window.height - 2
        end,

        width = 8,
        text = "Delete"
    }):onClick(
        function()

            local item =
                list:getSelectedItem()

            if item
                and fs.exists(item.value)
            then

                fs.delete(item.value)

                refresh()
            end
        end
    )

    refresh()
end

-- ============================================
-- App Manager
-- ============================================

local function getApps()

    local apps = {}

    if not fs.exists(APPS) then
        return apps
    end

    for _, folder
        in ipairs(fs.list(APPS))
    do

        local appPath =
            fs.combine(
                APPS,
                folder
            )

        local manifestPath =
            fs.combine(
                appPath,
                "app.lua"
            )

        if fs.isDir(appPath)
            and fs.exists(manifestPath)
        then

            local appFile =
                fs.open(
                    manifestPath,
                    "r"
                )

            local data =
                textutils.unserialize(
                    appFile.readAll()
                )

            appFile.close()

            if data then

                data.id = folder

                table.insert(
                    apps,
                    data
                )
            end
        end
    end

    return apps
end

local function openAppManager()

    local window =
        createWindow(
            "Programs",
            5,
            4,
            40,
            18
        )

    local list =
        window:addList({
            x = 7,
            y = 3,

            width = function()
                return window.width - 9
            end,

            height = function()
                return window.height - 7
            end,

            scrollbar = "auto"
        })

    local selectedApp = nil

    local function refresh()

        list:clear()

        for _, app
            in ipairs(getApps())
        do

            list:addItem({
                text = app.name,
                value = app
            })
        end
    end

    list:onChange(
        function(
            self,
            index,
            item
        )

            selectedApp =
                item
                and item.value
                or nil
        end
    )

    -- ========================================
    -- Run
    -- ========================================

    window:addButton({
        x = 2,

        y = function()
            return window.height - 2
        end,

        width = 7,
        text = "Run"
    }):onClick(
        function()

            if not selectedApp then
                return
            end

            local path =
                fs.combine(
                    APPS,
                    selectedApp.id
                )

            path =
                fs.combine(
                    path,
                    selectedApp.program
                )

            if fs.exists(path) then

                local runWindow =
                    createWindow(
                        selectedApp.name,
                        6,
                        4,
                        40,
                        16
                    )

                local program =
                    runWindow:addProgram({
                        x = 2,
                        y = 3,

                        width = function()
                            return runWindow.width - 4
                        end,

                        height = function()
                            return runWindow.height - 5
                        end
                    })

                program:execute(path)
            end
        end
    )

    -- ========================================
    -- Install
    -- ========================================

    window:addButton({
        x = 10,

        y = function()
            return window.height - 2
        end,

        width = 9,
        text = "Install"
    }):onClick(
        function()

            inputPopup(
                "Install Program",
                "Path to Lua program:",
                function(source)

                    if not source
                        or not fs.exists(source)
                        or fs.isDir(source)
                    then
                        return
                    end

                    inputPopup(
                        "Program Name",
                        "Name:",
                        function(name)

                            if name == ""
                                or not name
                            then
                                return
                            end

                            local id =
                                name:lower()
                                    :gsub(
                                        "[^%w]",
                                        "_"
                                    )

                            local destination =
                                fs.combine(
                                    APPS,
                                    id
                                )

                            fs.makeDir(
                                destination
                            )

                            local programPath =
                                fs.combine(
                                    destination,
                                    "main.lua"
                                )

                            fs.copy(
                                source,
                                programPath
                            )

                            local manifest =
                                fs.open(
                                    fs.combine(
                                        destination,
                                        "app.lua"
                                    ),
                                    "w"
                                )

                            manifest.write(
                                textutils.serialize({
                                    name = name,
                                    program = "main.lua",

                                    icon = {
                                        "###",
                                        "#.#",
                                        "###"
                                    },

                                    primary =
                                        colors.cyan,

                                    secondary =
                                        colors.lightBlue
                                })
                            )

                            manifest.close()

                            refresh()
                        end
                    )
                end
            )
        end
    )

    -- ========================================
    -- Delete
    -- ========================================

    window:addButton({
        x = 20,

        y = function()
            return window.height - 2
        end,

        width = 9,
        text = "Uninstall"
    }):onClick(
        function()

            if selectedApp
                and selectedApp.id
            then

                fs.delete(
                    fs.combine(
                        APPS,
                        selectedApp.id
                    )
                )

                selectedApp = nil

                refresh()
            end
        end
    )

    refresh()
end

-- ============================================
-- Notes
-- ============================================

local function openNotes()

    openExplorer(NOTES)

end

-- ============================================
-- Desktop icons
-- ============================================

local function desktopButton(
    text,
    icon,
    x,
    y,
    callback
)

    local holder =
        main:addFrame({
            x = x,
            y = y,
            width = 14,
            height = 6,
            background = colors.lightBlue
        })

    drawIcon(
        holder,
        icon,
        6,
        1
    )

    holder:addButton({
        x = 1,
        y = 5,
        width = 14,
        height = 1,
        text = text,
        background = colors.lightBlue,
        foreground = colors.black
    }):onClick(callback)
end

desktopButton(
    "Files",
    Icons.folder,
    3,
    3,
    function()
        openExplorer()
    end
)

desktopButton(
    "New Note",
    Icons.note,
    18,
    3,
    function()

        local path =
            fs.combine(
                NOTES,
                "note_"
                .. tostring(
                    os.epoch("utc")
                )
                .. ".txt"
            )

        openEditor(path)
    end
)

desktopButton(
    "Programs",
    Icons.program,
    3,
    10,
    function()
        openAppManager()
    end
)

desktopButton(
    "Code",
    Icons.lua,
    18,
    10,
    function()

        openEditor(
            fs.combine(
                USER_FILES,
                "program.lua"
            )
        )
    end
)

-- ============================================
-- Update popup
-- ============================================

local function checkForUpdates()

    local hasUpdate,
        installed,
        latest =
        Updater.check()

    if not hasUpdate then
        return
    end

    local popup =
        createWindow(
            "GlasspaneOS Update",
            8,
            5,
            34,
            11
        )

    popup:addLabel({
        x = 2,
        y = 3,
        text =
            "An update is available!"
    })

    popup:addLabel({
        x = 2,
        y = 5,
        text =
            "GitHub has changed."
    })

    popup:addButton({
        x = 2,
        y = 8,
        width = 12,
        text = "Update"
    }):onClick(
        function()

            local success, err =
                Updater.update()

            if success then

                term.clear()
                term.setCursorPos(1, 1)

                print(
                    "GlasspaneOS updated!"
                )

                sleep(1)

                os.reboot()

            else

                popup:addLabel({
                    x = 2,
                    y = 7,
                    text =
                        "Update failed: "
                        .. tostring(err),

                    foreground = colors.red
                })
            end
        end
    )

    popup:addButton({
        x = 16,
        y = 8,
        width = 12,
        text = "Later"
    }):onClick(
        function()

            popup:destroy()
        end
    )
end

-- ============================================
-- Start
-- ============================================

checkForUpdates()

basalt.run()
