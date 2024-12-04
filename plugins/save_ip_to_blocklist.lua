-- Get the blocklist file path from ModSecurity configuration
local blocklist_file = m.getvar("tx.blocklist_file")

function main()
    local ip = m.getvar("REMOTE_ADDR")
    if ip then
        local file = io.open(blocklist_file, "a")
        if file then
            file:write(ip .. "\n")
            file:close()
            print("IP written to blocklist: " .. ip)
        end
    end
    return nil
end
