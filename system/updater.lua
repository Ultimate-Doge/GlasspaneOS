-- =========================================
-- GlasspaneOS Update System
-- =========================================

local USER = "YOUR_GITHUB_USERNAME"
local REPO = "GlasspaneOS"
local BRANCH = "main"

local ROOT = "/glasspaneos"

local BASE =
    "https://raw.githubusercontent.com/"
    .. USER .. "/"
    .. REPO .. "/"
    .. BRANCH .. "/"

local function download(url)

    local response = http.get(url)

    if not response then
        return nil
    end

    local data = response.readAll()

    response.close()

    return data
end

local function getInstalledVersion()

    local path =
        ROOT .. "/version.lua"

    if not fs.exists(path) then
        return "unknown"
    end

    local file =
        fs.open(path, "r")

    local data =
        textutils.unserialize(
            file.readAll()
        )

    file.close()

    if data then
        return data.version
    end

    return "unknown"
end

local function getOnlineManifest()

    local data =
        download(BASE .. "manifest.lua")

    if not data then
        return nil
    end

    return textutils.unserialize(data)
end

return {

    check = function()

        if not http then
            return false
        end

        local installed =
            getInstalledVersion()

        local online =
            getOnlineManifest()

        if not online then
            return false
        end

        if installed ~= online.version then

            return true,
                installed,
                online.version
        end

        return false,
            installed,
            online.version
    end,

    update = function()

        local manifest =
            getOnlineManifest()

        if not manifest then
            return false,
                "Could not download manifest."
        end

        for _, filePath in ipairs(manifest.files) do

            local data =
                download(BASE .. filePath)

            if not data then

                return false,
                    "Failed to download "
                    .. filePath
            end

            local localPath =
                fs.combine(
                    ROOT,
                    filePath
                )

            local folder =
                fs.getDir(localPath)

            if not fs.exists(folder) then
                fs.makeDir(folder)
            end

            local file =
                fs.open(
                    localPath,
                    "w"
                )

            file.write(data)

            file.close()
        end

        local version =
            fs.open(
                ROOT .. "/version.lua",
                "w"
            )

        version.write(
            textutils.serialize({
                version = manifest.version
            })
        )

        version.close()

        return true
    end
}
