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

local API =
    "https://api.github.com/repos/"
    .. USER .. "/"
    .. REPO .. "/commits/"
    .. BRANCH

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

local function getLatestCommit()

    local data = download(API)

    if not data then
        return nil
    end

    local decoded =
        textutils.unserializeJSON(data)

    if decoded and decoded.sha then
        return decoded.sha
    end

    return nil
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
    print()
    print("GlasspaneOS needs HTTP enabled")
    print("to download the installation.")

    return
end

-- ============================================
-- Create root
-- ============================================

fs.makeDir(ROOT)

-- ============================================
-- Install Basalt
-- ============================================

print("Checking Basalt...")

if not fs.exists(ROOT .. "/basalt.lua") then

    print("Installing Basalt 2.5...")
    print()

    local success = shell.run(
        "wget",
        "run",
        "https://basalt.madefor.cc/2.5/install.lua",
        "minified",
        ROOT .. "/basalt.lua"
    )

    if not success
        or not fs.exists(ROOT .. "/basalt.lua")
    then

        print()
        print("Basalt installation failed.")

        return
    end

    print("Basalt installed!")
    print()

else

    print("Basalt already installed.")
    print()
end

-- ============================================
-- Download manifest
-- ============================================

print("Connecting to GlasspaneOS...")

local manifestData, err =
    download(RAW .. "manifest.lua")

if not manifestData then

    print()
    print("Could not download manifest.")
    print(err or "Unknown error")

    return
end

local manifest =
    textutils.unserialize(manifestData)

if not manifest then

    print()
    print("Invalid manifest.lua")

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

    local data, downloadError =
        download(RAW .. filePath)

    if not data then

        print()
        print("FAILED: " .. filePath)
        print(downloadError or "Unknown error")

        return
    end

    local destination =
        fs.combine(ROOT, filePath)

    if not writeFile(destination, data) then

        print()
        print("Could not write:")
        print(destination)

        return
    end
end

-- ============================================
-- User folders
-- These are NOT overwritten by updates
-- ============================================

fs.makeDir(ROOT .. "/apps")
fs.makeDir(ROOT .. "/notes")
fs.makeDir(ROOT .. "/user")
fs.makeDir(ROOT .. "/user/files")

-- ============================================
-- Save installation information
-- ============================================

local commit = getLatestCommit()

writeFile(
    ROOT .. "/installed.lua",
    textutils.serialize({
        version = manifest.version,
        commit = commit
    })
)

-- ============================================
-- Startup
-- ============================================

writeFile(
    "/startup",
    [[
shell.run("/glasspaneos/os.lua")
]]
)

-- ============================================
-- Finished
-- ============================================

term.clear()
term.setCursorPos(1, 1)

print("==============================")
print(" Installation Complete!")
print("==============================")
print()

print(
    "GlasspaneOS "
    .. tostring(manifest.version)
)

print()
print("Basalt 2.5 installed.")
print()
print("Rebooting...")

sleep(2)

os.reboot()
