-- ============================================
-- GlasspaneOS
-- Definitely not Windows.
-- ============================================

local basalt = require("basalt")
local updater = require("system.updater")

-- ============================================
-- PATHS
-- ============================================

local ROOT = "/glasspaneos"
local APPS = ROOT .. "/apps"
local NOTES = ROOT .. "/notes"
local APP_DB = ROOT .. "/apps.db"

fs.makeDir(ROOT)
fs.makeDir(APPS)
fs.makeDir(NOTES)
fs.makeDir(ROOT .. "/system")

-- ============================================
-- APP DATABASE
-- ============================================

local function loadApps()

    if not fs.exists(APP_DB) then
        return {}
    end

    local file = fs.open(APP_DB, "r")

    local data = textutils.unserialize(
        file.readAll()
    )

    file.close()

    return data or {}
end

local function saveApps(apps)

    local file = fs.open(APP_DB, "w")

    file.write(
        textutils.serialize(apps)
    )

    file.close()
end

local apps = loadApps()

-- ============================================
-- DESKTOP
-- ============================================

local main = basalt.createFrame()

main:setBackground(colors.lightBlue)

main:addLabel()
    :setText(" GlasspaneOS - Definitely not Windows ")
    :setPosition(1, 1)
    :setSize("parent.w", 1)
    :setBackground(colors.blue)
    :setForeground(colors.white)

-- ============================================
-- WINDOW SYSTEM
-- ============================================

local windows = {}

local function createWindow(title, x, y, w, h)

    local window = main:addFrame()
        :setPosition(x, y)
        :setSize(w, h)
        :setBackground(colors.lightGray)

    table.insert(windows, window)

    window.glasspane = {
        title = title,
        x = x,
        y = y,
        w = w,
        h = h,
        minimized = false,
        maximized = false
    }

    window:addLabel()
        :setText(" " .. title)
        :setPosition(1, 1)
        :setSize("parent.w - 6", 1)
        :setBackground(colors.blue)
        :setForeground(colors.white)

    local minimize = window:addButton()
        :setText("_")
        :setPosition("parent.w - 5", 1)
        :setSize(2, 1)

    local maximize = window:addButton()
        :setText("[]")
        :setPosition("parent.w - 3", 1)
        :setSize(2, 1)

    local close = window:addButton()
        :setText("X")
        :setPosition("parent.w - 1", 1)
        :setSize(1, 1)

    close:onClick(function()

        for i, win in ipairs(windows) do
            if win == window then
                table.remove(windows, i)
                break
            end
        end

        window:remove()
    end)

    minimize:onClick(function()

        if window.glasspane.minimized then

            window:setSize(
                window.glasspane.w,
                window.glasspane.h
            )

            window.glasspane.minimized = false

        else

            window.glasspane.w =
                window:getWidth()

            window.glasspane.h =
                window:getHeight()

            window:setSize(
                window.glasspane.w,
                1
            )

            window.glasspane.minimized = true
        end
    end)

    maximize:onClick(function()

        local screenW, screenH =
            term.getSize()

        if window.glasspane.maximized then

            window:setPosition(
                window.glasspane.x,
                window.glasspane.y
            )

            window:setSize(
                window.glasspane.w,
                window.glasspane.h
            )

            window.glasspane.maximized = false

        else

            window.glasspane.x =
                window:getX()

            window.glasspane.y =
                window:getY()

            window.glasspane.w =
                window:getWidth()

            window.glasspane.h =
                window:getHeight()

            window:setPosition(1, 2)

            window:setSize(
                screenW,
                screenH - 1
            )

            window.glasspane.maximized = true
        end
    end)

    return window
end

-- ============================================
-- TEXT / CODE EDITOR
-- ============================================

local function openEditor(filePath)

    local window = createWindow(
        "Glass Editor",
        3, 3, 40, 18
    )

    window:addLabel()
        :setText("Path:")
        :setPosition(2, 2)

    local pathInput = window:addInput()
        :setPosition(8, 2)
        :setSize("parent.w - 10", 1)

    pathInput:setValue(filePath or "")

    local editor = window:addTextfield()
        :setPosition(2, 4)
        :setSize(
            "parent.w - 4",
            "parent.h - 7"
        )

    if filePath
        and fs.exists(filePath)
        and not fs.isDir(filePath)
    then

        local file = fs.open(filePath, "r")

        editor:setText(file.readAll())

        file.close()
    end

    local saveButton = window:addButton()
        :setText("Save")
        :setPosition(2, "parent.h - 2")
        :setSize(8, 1)

    local saveAsButton = window:addButton()
        :setText("Save As")
        :setPosition(11, "parent.h - 2")
        :setSize(10, 1)

    local runButton = window:addButton()
        :setText("Run")
        :setPosition(22, "parent.h - 2")
        :setSize(8, 1)

    local function saveFile(path)

        if path == "" then
            return false
        end

        local folder = fs.getDir(path)

        if folder ~= ""
            and not fs.exists(folder)
        then
            fs.makeDir(folder)
        end

        local file = fs.open(path, "w")

        if not file then
            return false
        end

        file.write(editor:getText())
        file.close()

        return true
    end

    saveButton:onClick(function()

        saveFile(
            pathInput:getValue()
        )
    end)

    saveAsButton:onClick(function()

        local popup = createWindow(
            "Save As",
            7, 6, 30, 8
        )

        popup:addLabel()
            :setText("New path:")
            :setPosition(2, 2)

        local input = popup:addInput()
            :setPosition(2, 4)
            :setSize(26, 1)

        popup:addButton()
            :setText("Save")
            :setPosition(2, 6)
            :setSize(10, 1)
            :onClick(function()

                local path = input:getValue()

                if saveFile(path) then
                    pathInput:setValue(path)
                    popup:remove()
                end
            end)
    end)

    runButton:onClick(function()

        local path =
            pathInput:getValue()

        if path:sub(-4) == ".lua" then

            if saveFile(path) then

                window:hide()

                shell.run(path)

                window:show()
            end
        end
    end)

    return window
end

-- ============================================
-- FILE EXPLORER
-- ============================================

local function openExplorer()

    local currentPath = "/"

    local window = createWindow(
        "Glass Explorer",
        2, 3, 42, 18
    )

    local pathLabel = window:addLabel()
        :setPosition(2, 2)
        :setSize("parent.w - 4", 1)

    local fileList = window:addList()
        :setPosition(2, 4)
        :setSize(
            "parent.w - 4",
            "parent.h - 7"
        )

    local function refresh()

        fileList:clear()

        pathLabel:setText(currentPath)

        local files = fs.list(currentPath)

        table.sort(files, function(a, b)

            local pathA =
                fs.combine(currentPath, a)

            local pathB =
                fs.combine(currentPath, b)

            if fs.isDir(pathA)
                ~= fs.isDir(pathB)
            then
                return fs.isDir(pathA)
            end

            return a:lower()
                < b:lower()
        end)

        for _, name in ipairs(files) do

            local path =
                fs.combine(currentPath, name)

            if fs.isDir(path) then
                fileList:addItem(
                    "[DIR] " .. name
                )
            else
                fileList:addItem(name)
            end
        end
    end

    local function getSelected()

        local item =
            fileList:getItem()

        if not item then
            return nil
        end

        local name = item.text

        if name:sub(1, 6)
            == "[DIR] "
        then
            name = name:sub(7)
        end

        return fs.combine(
            currentPath,
            name
        )
    end

    local function openSelected()

        local path = getSelected()

        if not path then
            return
        end

        if fs.isDir(path) then

            currentPath = path
            refresh()

        else

            openEditor(path)
        end
    end

    local back = window:addButton()
        :setText("<")
        :setPosition(2, "parent.h - 2")
        :setSize(4, 1)

    local open = window:addButton()
        :setText("Open")
        :setPosition(7, "parent.h - 2")
        :setSize(7, 1)

    local newFile = window:addButton()
        :setText("New File")
        :setPosition(15, "parent.h - 2")
        :setSize(10, 1)

    local newFolder = window:addButton()
        :setText("Folder")
        :setPosition(26, "parent.h - 2")
        :setSize(8, 1)

    local deleteButton = window:addButton()
        :setText("Del")
        :setPosition(
            "parent.w - 5",
            "parent.h - 2"
        )
        :setSize(4, 1)

    back:onClick(function()

        if currentPath ~= "/" then

            currentPath =
                fs.getDir(currentPath)

            if currentPath == "" then
                currentPath = "/"
            end

            refresh()
        end
    end)

    open:onClick(openSelected)

    fileList:onSelect(openSelected)

    newFile:onClick(function()

        local popup = createWindow(
            "Create File",
            8, 6, 30, 8
        )

        popup:addLabel()
            :setText("File name:")
            :setPosition(2, 2)

        local input = popup:addInput()
            :setPosition(2, 4)
            :setSize(26, 1)

        popup:addButton()
            :setText("Create")
            :setPosition(2, 6)
            :setSize(10, 1)
            :onClick(function()

                local name = input:getValue()

                if name ~= "" then

                    local path =
                        fs.combine(
                            currentPath,
                            name
                        )

                    if not fs.exists(path) then

                        local file =
                            fs.open(path, "w")

                        file.write("")
                        file.close()

                        refresh()

                        popup:remove()

                        openEditor(path)
                    end
                end
            end)
    end)

    newFolder:onClick(function()

        local popup = createWindow(
            "Create Folder",
            8, 6, 30, 8
        )

        popup:addLabel()
            :setText("Folder name:")
            :setPosition(2, 2)

        local input = popup:addInput()
            :setPosition(2, 4)
            :setSize(26, 1)

        popup:addButton()
            :setText("Create")
            :setPosition(2, 6)
            :setSize(10, 1)
            :onClick(function()

                local name = input:getValue()

                if name ~= "" then

                    local path =
                        fs.combine(
                            currentPath,
                            name
                        )

                    if not fs.exists(path) then

                        fs.makeDir(path)

                        refresh()

                        popup:remove()
                    end
                end
            end)
    end)

    deleteButton:onClick(function()

        local path = getSelected()

        if not path
            or not fs.exists(path)
        then
            return
        end

        local popup = createWindow(
            "Delete?",
            10, 7, 26, 7
        )

        popup:addLabel()
            :setText("Delete selected item?")
            :setPosition(2, 2)

        popup:addButton()
            :setText("Yes")
            :setPosition(2, 5)
            :setSize(8, 1)
            :onClick(function()

                fs.delete(path)

                refresh()

                popup:remove()
            end)

        popup:addButton()
            :setText("No")
            :setPosition(12, 5)
            :setSize(8, 1)
            :onClick(function()

                popup:remove()
            end)
    end)

    refresh()

    return window
end

-- ============================================
-- APP MANAGER
-- ============================================

local function openAppManager()

    local window = createWindow(
        "Installed Programs",
        4, 4, 34, 16
    )

    local list = window:addList()
        :setPosition(2, 3)
        :setSize(
            "parent.w - 4",
            "parent.h - 7"
        )

    local function refresh()

        list:clear()

        local names = {}

        for name in pairs(apps) do
            table.insert(names, name)
        end

        table.sort(names)

        for _, name in ipairs(names) do
            list:addItem(name)
        end
    end

    local install = window:addButton()
        :setText("Install")
        :setPosition(2, "parent.h - 2")
        :setSize(9, 1)

    local run = window:addButton()
        :setText("Run")
        :setPosition(12, "parent.h - 2")
        :setSize(7, 1)

    local deleteApp = window:addButton()
        :setText("Delete")
        :setPosition(20, "parent.h - 2")
        :setSize(8, 1)

    install:onClick(function()

        local popup = createWindow(
            "Install Program",
            7, 6, 32, 11
        )

        popup:addLabel()
            :setText("App name:")
            :setPosition(2, 3)

        local name = popup:addInput()
            :setPosition(2, 4)
            :setSize(28, 1)

        popup:addLabel()
            :setText("Lua file path:")
            :setPosition(2, 6)

        local path = popup:addInput()
            :setPosition(2, 7)
            :setSize(28, 1)

        popup:addButton()
            :setText("Install")
            :setPosition(2, 9)
            :setSize(10, 1)
            :onClick(function()

                local appName =
                    name:getValue()

                local source =
                    path:getValue()

                if appName ~= ""
                    and fs.exists(source)
                    and not fs.isDir(source)
                then

                    local destination =
                        fs.combine(
                            APPS,
                            appName .. ".lua"
                        )

                    fs.copy(
                        source,
                        destination
                    )

                    apps[appName] =
                        destination

                    saveApps(apps)

                    refresh()

                    popup:remove()
                end
            end)
    end)

    run:onClick(function()

        local item = list:getItem()

        if item
            and apps[item.text]
        then

            window:hide()

            shell.run(
                apps[item.text]
            )

            window:show()
        end
    end)

    deleteApp:onClick(function()

        local item = list:getItem()

        if item
            and apps[item.text]
        then

            fs.delete(
                apps[item.text]
            )

            apps[item.text] = nil

            saveApps(apps)

            refresh()
        end
    end)

    refresh()
end

-- ============================================
-- DESKTOP BUTTONS
-- ============================================

local explorerButton = main:addButton()
    :setText("File Explorer")
    :setPosition(2, 4)
    :setSize(16, 3)

local editorButton = main:addButton()
    :setText("New Text / Code File")
    :setPosition(2, 8)
    :setSize(20, 3)

local appsButton = main:addButton()
    :setText("Programs")
    :setPosition(2, 12)
    :setSize(16, 3)

local noteButton = main:addButton()
    :setText("Quick Note")
    :setPosition(2, 16)
    :setSize(16, 3)

explorerButton:onClick(function()
    openExplorer()
end)

editorButton:onClick(function()
    openEditor("")
end)

appsButton:onClick(function()
    openAppManager()
end)

noteButton:onClick(function()

    openEditor(
        NOTES .. "/note.txt"
    )
end)

-- ============================================
-- UPDATE POPUP
-- ============================================

local function checkForUpdates()

    local hasUpdate,
        installed,
        online =
        updater.check()

    if not hasUpdate then
        return
    end

    local popup = createWindow(
        "Update Available",
        7, 5, 32, 10
    )

    popup:addLabel()
        :setText("A new GlasspaneOS")
        :setPosition(2, 3)

    popup:addLabel()
        :setText("update is available!")
        :setPosition(2, 4)

    popup:addLabel()
        :setText(
            tostring(installed)
            .. " -> "
            .. tostring(online)
        )
        :setPosition(2, 6)

    popup:addButton()
        :setText("Update")
        :setPosition(2, 8)
        :setSize(12, 1)
        :onClick(function()

            local success, err =
                updater.update()

            if success then

                term.clear()
                term.setCursorPos(1, 1)

                print("GlasspaneOS updated!")
                print("Rebooting...")

                sleep(2)

                os.reboot()

            else

                popup:addLabel()
                    :setText(
                        "Update failed: "
                        .. tostring(err)
                    )
                    :setPosition(2, 7)
            end
        end)

    popup:addButton()
        :setText("Later")
        :setPosition(16, 8)
        :setSize(12, 1)
        :onClick(function()

            popup:remove()
        end)
end

-- ============================================
-- START
-- ============================================

checkForUpdates()

basalt.autoUpdate()
