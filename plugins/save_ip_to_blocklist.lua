-- Get the blocklist file path from ModSecurity configuration
local blocklist_file = m.getvar("tx.blocklist_file")
local max_retries = 5  -- Max retries if lock cannot be acquired
local retry_delay = 0.1  -- Delay (in seconds) between retries

function main()
    -- Get the client IP address from ModSecurity
    local ip = m.getvar("REMOTE_ADDR")
    if not ip then
        return nil -- No IP to process
    end

    local lockfile = nil
    local retries = 0

    -- Attempt to acquire the lock with retry mechanism
    while retries < max_retries do
        lockfile = io.open(blocklist_file .. ".lock", "w") -- Try to open the lock file in write mode

        if lockfile then
            -- If lockfile is successfully opened, proceed to write data to the blocklist file
            break  -- Exit the loop once we acquire the lock
        else
            -- If unable to acquire lock, increment retry count and wait before retrying
            retries = retries + 1
            os.execute("sleep " .. retry_delay)  -- Delay for a short period before retrying
        end
    end

    -- If we failed to acquire the lock after max_retries, return early
    if retries == max_retries then
        return nil -- Could not acquire lock, exit gracefully
    end

    -- Open the blocklist file in read/write mode to check for duplicates and add the IP
    local file = io.open(blocklist_file, "r+")
    local ip_exists = false
    if file then
        -- Check if the IP already exists in the blocklist
        for line in file:lines() do
            if line == ip then
                ip_exists = true
                break
            end
        end

        -- If the IP is not found, append it at the end of the file
        if not ip_exists then
            file:write(ip .. "\n") -- Add the IP to the file
            file:flush() -- Ensure immediate write to disk
        end

        -- Close the file after reading and writing
        file:close()
    end

    -- Release the lock by closing the lockfile
    lockfile:close()

    -- Return nil to indicate successful execution
    return nil
end
