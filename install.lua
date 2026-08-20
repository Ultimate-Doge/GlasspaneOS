-- =========================================
-- GlasspaneOS Installer
-- Definitely not Windows.
-- Installs Basalt automatically.
-- =========================================

local USER = "Ultimate-Doge"
local REPO = "GlasspaneOS"
local BRANCH = "main"

local ROOT = "/glasspaneos"

local BASE =
    "https://raw.githubusercontent.com/"
    .. USER .. "/"
    .. REPO .. "/"
    .. BRANCH .. "/"

-- =========================================
-- Download helper
-- =========================================

local function downloadURL(url)
    local response, err = http.get(url)

    if not response then
        return nil, err
    end

    local data = response.readAll()
    response.close()

    return data
end

local function download(path)
    return downloadURL(BASE .. path)
end

local function writeFile(path, data)

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

    file.write(data)
    file.close()

    return true
end

-- =========================================
-- Start installer
-- =========================================

term.clear()
term.setCursorPos(1, 1)

print("================================")
print("      GlasspaneOS Installer")
print("================================")
print()
print("Definitely not Windows.")
print()

if not http then
    print("ERROR: HTTP API is disabled.")
    print()
    print("Enable HTTP in CC:Tweaked config.")
    return
end

-- =========================================
-- Install Basalt
-- =========================================

print("Checking for Basalt...")

if not fs.exists("/basalt") then

    print("Basalt not found.")
    print("Installing Basalt...")
    print()

    -- Official Basalt installer
    local basaltURL =
        "https://basalt.madefor.cc/install.lua"

    local basaltCode, basaltError =
        downloadURL(basaltURL)

    if not basaltCode then

        print("Failed to download Basalt.")
        print(basaltError or "Unknown error")

        return
    end

    local basaltInstaller,
        loadError =
        load(
            basaltCode,
            "Basalt Installer"
        )

    if not basaltInstaller then

        print("Could not load Basalt installer.")
        print(loadError or "")

        return
    end

    local success, err =
        pcall(basaltInstaller)

    if not success then

        print()
        print("Basalt installation failed:")
        print(err)

        return
    end

    print()
    print("Basalt installed!")
    sleep(1)

else

    print("Basalt already installed.")
    sleep(1)
end

-- =========================================
-- Download GlasspaneOS manifest
-- =========================================

print()
print("Connecting to GitHub...")

local manifestData, err =
    download("manifest.lua")

if not manifestData then

    print()
    print("Could not download manifest:")
    print(err or "Unknown error")

    return
end

local manifest =
    textutils.unserialize(manifestData)

if not manifest then

    print()
    print("ERROR: Invalid manifest.lua")

    return
end

print()
print(
    "Found GlasspaneOS "
    .. manifest.version
)

print()

-- =========================================
-- Create folders
-- =========================================

fs.makeDir(ROOT)
fs.makeDir(ROOT .. "/apps")
fs.makeDir(ROOT .. "/notes")
fs.makeDir(ROOT .. "/system")

-- =========================================
-- Download GlasspaneOS files
-- =========================================

print("Installing GlasspaneOS...")
print()

for _, filePath in ipairs(manifest.files) do

    print("Downloading: " .. filePath)

    local data, downloadError =
        download(filePath)

    if not data then

        print()
        print("FAILED: " .. filePath)
        print(
            downloadError
            or "Unknown error"
        )

        return
    end

    local destination =
        fs.combine(
            ROOT,
            filePath
        )

    if not writeFile(
        destination,
        data
    ) then

        print(
            "Could not write: "
            .. destination
        )

        return
    end
end

-- =========================================
-- Save installed version
-- =========================================

writeFile(
    ROOT .. "/version.lua",
    textutils.serialize({
        version = manifest.version
    })
)

-- =========================================
-- Create startup
-- =========================================

writeFile(
    "/startup",
    [[
shell.run("/glasspaneos/os.lua")
]]
)

-- =========================================
-- Finished
-- =========================================

term.clear()
term.setCursorPos(1, 1)

print("================================")
print(" Installation Complete!")
print("================================")
print()
print(
    "GlasspaneOS "
    .. manifest.version
)
print()
print("Basalt: Installed")
print()
print("Rebooting...")

sleep(3)

os.reboot()
