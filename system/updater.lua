-- GlasspaneOS Updater

local updater = {}

local USER = "Ultimate-Doge"
local REPO = "GlasspaneOS"
local BRANCH = "main"

local ROOT = "/glasspaneos"

local BASE =
    "https://raw.githubusercontent.com/"
    .. USER .. "/"
    .. REPO .. "/"
    .. BRANCH .. "/"

local function download(path)
    local response, err = http.get(BASE .. path)

    if not response then
        return nil, err
    end

    local data = response.readAll()
    response.close()

    return data
end

local function getLocalManifest()
    local path = ROOT .. "/version.lua"

    if not fs.exists(path) then
        return {
            version = "unknown"
        }
    end

    local file = fs.open(path, "r")
    local data = textutils.unserialize(file.readAll())

    file.close()

    return data or {
        version = "unknown"
    }
end

function updater.check()

    if not http then
        return false
    end

    local data = download("manifest.lua")

    if not data then
        return false
    end

    local online = textutils.unserialize(data)

    if not online then
        return false
    end

    local installed = getLocalManifest()

    if installed.version ~= online.version then
        return true, installed.version, online.version
    end

    return false, installed.version, online.version
end

function updater.update()

    local manifestData, err = download("manifest.lua")

    if not manifestData then
        return false, err
    end

    local manifest = textutils.unserialize(manifestData)

    if not manifest then
        return false, "Invalid manifest"
    end

    for _, filePath in ipairs(manifest.files) do

        local data, downloadError = download(filePath)

        if not data then
            return false,
                "Could not download "
                .. filePath
                .. ": "
                .. (downloadError or "unknown error")
        end

        local destination =
            fs.combine(ROOT, filePath)

        local folder =
            fs.getDir(destination)

        if folder ~= "" and not fs.exists(folder) then
            fs.makeDir(folder)
        end

        local file =
            fs.open(destination, "w")

        if not file then
            return false,
                "Could not write "
                .. destination
        end

        file.write(data)
        file.close()
    end

    local versionFile =
        fs.open(ROOT .. "/version.lua", "w")

    versionFile.write(
        textutils.serialize({
            version = manifest.version
        })
    )

    versionFile.close()

    return true
end

return updater
