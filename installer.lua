-- =========================================
-- GlasspaneOS Online Installer
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

    file.write(data)

    file.close()
end

term.clear()
term.setCursorPos(1, 1)

print("================================")
print("     GlasspaneOS Installer")
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

print("Downloading manifest...")

local manifestData, err =
    download(BASE .. "manifest.lua")

if not manifestData then

    print("Download failed:")
    print(err)

    return
end

local manifest =
    textutils.unserialize(manifestData)

if not manifest then

    print("ERROR:")
    print("Invalid manifest.")

    return
end

print()
print("Installing GlasspaneOS " .. manifest.version)
print()

-- Remove old installation

if fs.exists(ROOT) then

    print("Removing old version...")

    fs.delete(ROOT)
end

fs.makeDir(ROOT)

-- Download every file

for _, filePath in ipairs(manifest.files) do

    print("Downloading: " .. filePath)

    local data, downloadError =
        download(BASE .. filePath)

    if not data then

        print()
        print("FAILED:")
        print(downloadError)

        return
    end

    writeFile(
        fs.combine(ROOT, filePath),
        data
    )
end

-- Save installed version

writeFile(
    ROOT .. "/version.lua",
    textutils.serialize({
        version = manifest.version
    })
)

-- Create user folders

fs.makeDir(ROOT .. "/apps")
fs.makeDir(ROOT .. "/notes")

-- Create startup

writeFile(
    "/startup",
    [[
shell.run("/glasspaneos/os.lua")
]]
)

print()
print("================================")
print(" Installation Complete!")
print("================================")
print()
print("Version: " .. manifest.version)
print()
print("Please remove the floppy disk.")
print("Rebooting...")

sleep(3)

os.reboot()
