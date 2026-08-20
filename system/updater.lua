-- ============================================
-- GlasspaneOS Updater
-- ============================================

local Updater = {}

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
-- Download
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

-- ============================================
-- Installed information
-- ============================================

function Updater.getInstalled()

    local path =
        ROOT .. "/installed.lua"

    if not fs.exists(path) then

        return {
            version = "unknown",
            commit = nil
        }
    end

    local file = fs.open(path, "r")

    local data =
        textutils.unserialize(
            file.readAll()
        )

    file.close()

    return data or {
        version = "unknown",
        commit = nil
    }
end

-- ============================================
-- Latest GitHub commit
-- ============================================

function Updater.getLatestCommit()

    local data, err = download(API)

    if not data then
        return nil, err
    end

    local decoded =
        textutils.unserializeJSON(data)

    if decoded
        and decoded.sha
    then

        return decoded.sha
    end

    return nil, "Invalid GitHub response"
end

-- ============================================
-- Check for update
-- ============================================

function Updater.check()

    if not http then
        return false
    end

    local installed =
        Updater.getInstalled()

    local latest =
        Updater.getLatestCommit()

    if not latest then
        return false
    end

    if installed.commit ~= latest then

        return true,
            installed,
            latest
    end

    return false,
        installed,
        latest
end

-- ============================================
-- Update
-- ============================================

function Updater.update()

    local manifestData, err =
        download(RAW .. "manifest.lua")

    if not manifestData then
        return false, err
    end

    local manifest =
        textutils.unserialize(manifestData)

    if not manifest then
        return false, "Invalid manifest"
    end

    for _, filePath
        in ipairs(manifest.files)
    do

        local data, downloadError =
            download(RAW .. filePath)

        if not data then

            return false,
                "Failed: "
                .. filePath
                .. " - "
                .. tostring(downloadError)
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

            return false,
                "Could not write "
                .. destination
        end
    end

    local latest =
        Updater.getLatestCommit()

    writeFile(
        ROOT .. "/installed.lua",
        textutils.serialize({
            version = manifest.version,
            commit = latest
        })
    )

    return true
end

return Updater
