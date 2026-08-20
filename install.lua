-- ============================================
-- GlasspaneOS Installer
-- Definitely not Windows.
-- ============================================

local USER = "Ultimate-Doge"
local REPO = "GlasspaneOS"
local BRANCH = "main"

local ROOT = "/glasspaneos"

local RAW =
    "https://raw.githubusercontent.com/"
    .. USER .. "/"
    .. REPO .. "/"
    .. BRANCH .. "/"

-- ============================================
-- Helpers
-- ============================================

local function download(url)
    local response, err = http.get(url)

    if not response then
        return nil, err
    end

    local data = response.readAll()
    response.close()

    return data
end

local function writeFile(path, data)
    local folder = fs.getDir(path)

    if folder ~= "" and not fs.exists(folder) then
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

local function loadLuaTable(code, name)
    local fn, err = load(code, name)

    if not fn then
        return nil, err
    end

    local ok, result = pcall(fn)

    if not ok then
        return nil, result
    end

    return result
end

-- ============================================
-- Start
-- ============================================

term.clear()
term.setCursorPos(1, 1)

print("==============================")
print("    GlasspaneOS Installer")
print("==============================")
print()
print("Definitely not Windows.")
print()

if not http then
    print("ERROR: HTTP is disabled.")
    return
end

fs.makeDir(ROOT)

-- ============================================
-- Install Basalt
-- ============================================

local basaltPath = ROOT .. "/basalt.lua"

if not fs.exists(basaltPath) then

    print("Downloading Basalt installer...")

    local installerCode, err = download(
        "https://basalt.madefor.cc/2.5/install.lua"
    )

    if not installerCode then
        print("Failed to download Basalt:")
        print(err or "Unknown error")
        return
    end

    -- Save temporarily
    local tempInstaller = ROOT .. "/basalt_install.lua"

    writeFile(tempInstaller, installerCode)

    print("Installing Basalt 2.5...")

    -- Run the installer normally through CraftOS
    local oldDir = shell.dir()

    shell.setDir(ROOT)

    local success = shell.run(
        tempInstaller,
        "minified",
        "basalt.lua"
    )

    shell.setDir(oldDir)

    if fs.exists(tempInstaller) then
        fs.delete(tempInstaller)
    end

    if not success or not fs.exists(basaltPath) then
        print()
        print("Basalt installation failed.")
        return
    end

    print("Basalt installed!")

else
    print("Basalt already installed.")
end

print()

-- ============================================
-- Download manifest
-- ============================================

print("Downloading manifest...")

local manifestCode, err = download(
    RAW .. "manifest.lua"
)

if not manifestCode then
    print("Failed to download manifest:")
    print(err or "Unknown error")
    return
end

local manifest, manifestError = loadLuaTable(
    manifestCode,
    "GlasspaneOS manifest"
)

if not manifest then
    print("Invalid manifest.lua:")
    print(manifestError or "Unknown error")
    return
end

print(
    "Installing GlasspaneOS "
    .. tostring(manifest.version)
)

print()

-- ============================================
-- Download system files
-- ============================================

for _, filePath in ipairs(manifest.files) do

    print("Downloading: " .. filePath)

    local data, downloadError = download(
        RAW .. filePath
    )

    if not data then
        print("FAILED: " .. filePath)
        print(downloadError or "Unknown error")
        return
    end

    local destination = fs.combine(
        ROOT,
        filePath
    )

    if not writeFile(destination, data) then
        print("Could not write:")
        print(destination)
        return
    end
end

-- ============================================
-- User folders
-- ============================================

fs.makeDir(ROOT .. "/apps")
fs.makeDir(ROOT .. "/notes")
fs.makeDir(ROOT .. "/user")
fs.makeDir(ROOT .. "/user/files")

-- ============================================
-- Installation information
-- ============================================

writeFile(
    ROOT .. "/installed.lua",
    textutils.serialize({
        version = manifest.version
    })
)

-- ============================================
-- Startup
-- ============================================

writeFile(
    "/startup",
    [[
dofile("/glasspaneos/os.lua")
]]
)

-- ============================================
-- Finished
-- ============================================

print()
print("==============================")
print(" Installation Complete!")
print("==============================")
print()
print("Rebooting...")

sleep(2)
os.reboot()
