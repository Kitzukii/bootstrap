local lib = {}
local uri = "https://raw.githubusercontent.com/Kitzukii/apioframe-cores/refs/heads/main/"
local version_ext = "__version__"

fs=fs
http=http

-- needed files for updating
-- (weirdly, you need to update to update/add more files to download;
--  since this is inside the code)
local needed_files = {
    "__data__", "__version__",
    "agent.lua", "bootstrap.lua",
    "startup.lua", "update.lua",
    "LISENCE"
}

local function splitVersion(v)
    local t = {}
    for part in string.gmatch(v, "%d+") do
        table.insert(t, tonumber(part))
    end
    return t
end;local function compareVersions(a, b)
    local va = splitVersion(a)
    local vb = splitVersion(b)

    local len = math.max(#va, #vb)
    for i = 1, len do
        local x = va[i] or 0
        local y = vb[i] or 0

        if x > y then return 1 end
        if x < y then return -1 end
    end

    return 0
end

local function getLocalVer()
    local ver_file = fs.open("__version__", "r")
    if not ver_file then return nil end

    local ver_data = ver_file.readLine()
    ver_file.close()

    if ver_data then
        ver_data = ver_data:match("%S+")
    end

    return ver_data
end

function lib.update(bootstrap)
    local git_version = ""
    local local_version = getLocalVer()

    local ok, handle = pcall(http.get, uri..version_ext)
    if ok and handle then
        git_version = handle.readAll() or ""
        git_version = git_version:match("%S+") or ""
    else
        bootstrap.error("Error retrieving remote version: "..tostring(handle))
        return
    end

    bootstrap.clog(
        "Github Version: "..tostring(git_version)
       .."\nLocal Version: "..tostring(local_version),
        colors.yellow
    )

    if compareVersions(local_version, git_version) < 0 then
        bootstrap.clog("Updating...", colors.green)

        -- create temp directory
        local tmp = "__update_tmp"
        if fs.exists(tmp) then fs.delete(tmp) end
        fs.makeDir(tmp)

        -- download all files to temp
        for _, file in ipairs(needed_files) do
            bootstrap.clog("Downloading "..file.."...", colors.lightGray)
            local ok, handle = pcall(http.get, uri..file)

            if not ok or not handle then
                bootstrap.error("Failed to download: "..file)
                fs.delete(tmp)
                return
            end

            local data = handle.readAll() or ""
            handle.close()

            -- write to temporary file
            local out = fs.open(tmp.."/"..file, "w")
            if not out then
                bootstrap.error("Failed to write temp file: "..file)
                fs.delete(tmp)
                return
            end

            out.write(data)
            out.close()
        end

        -- backup old files
        local backup = "__update_backup"
        if fs.exists(backup) then fs.delete(backup) end
        fs.makeDir(backup)

        for _, file in ipairs(needed_files) do
            if fs.exists(file) then
                fs.copy(file, backup.."/"..file)
            end
        end

        -- move new files into place
        for _, file in ipairs(needed_files) do
            if fs.exists(file) then fs.delete(file) end
            fs.copy(tmp.."/"..file, file)
        end

        -- update version file
        do
            local vfile = fs.open("__version__", "w")
            if not vfile then
                bootstrap.error("Failed to update version file. Rolling back to previous data.")
                -- rollback
                for _, f in ipairs(needed_files) do
                    if fs.exists(backup.."/"..f) then
                        fs.copy(backup.."/"..f, f)
                    end
                end
                return
            end
            vfile.write(git_version)
            vfile.close()
        end

        -- cleanup
        fs.delete(tmp)
        fs.delete(backup)

        bootstrap.clog("Update complete. Restarting...", colors.green)
        os.sleep(2)
        os.reboot()
    end
end

return lib