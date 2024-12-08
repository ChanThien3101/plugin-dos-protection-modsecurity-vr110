local M = require 'posix.fcntl'
local S = require 'posix.sys.stat'
local U = require 'posix.unistd'

-- File path
local file_path = "/etc/apache2/modsecurity.d/owasp-crs/plugins/plugin-dos-protection-modsecurity/plugins/blockListIP.txt"

-- IP to add
local ip_to_add = "192.168.1.100"

-- Open the file
local fd = M.open(
    file_path,
    M.O_CREAT + M.O_RDWR,
    S.S_IRUSR + S.S_IWUSR + S.S_IRGRP + S.S_IROTH
)

if not fd then
    print("Failed to open the file: " .. file_path)
    return
end

-- Set lock on file
local lock = {
    l_type = M.F_WRLCK,     -- Exclusive lock
    l_whence = M.SEEK_SET,  -- Relative to beginning of file
    l_start = 0,            -- Start from 1st byte
    l_len = 0               -- Lock whole file
}

local max_retries = 5
local retry_interval = 2 -- Seconds

local success = false

print("Trying to lock the file...")
for attempt = 1, max_retries do
    if M.fcntl(fd, M.F_SETLK, lock) ~= nil then
        print("File is locked successfully on attempt " .. attempt .. ".")
        success = true
        break
    else
        print("Attempt " .. attempt .. ": File is locked by another process. Retrying in " .. retry_interval .. " seconds...")
        os.execute("sleep " .. retry_interval)
    end
end

if success then
    -- Read the file content to check if IP already exists
    local current_size = U.lseek(fd, 0, U.SEEK_END) -- Move to the end of the file
    U.lseek(fd, 0, U.SEEK_SET) -- Reset position to the beginning of the file

    local content = U.read(fd, current_size or 0) -- Read the whole file
    if content and content:find(ip_to_add, 1, true) then
        print("IP " .. ip_to_add .. " already exists in the file.")
    else
        -- Write IP to the file
        print("Writing IP to the file: " .. ip_to_add)
        U.lseek(fd, 0, U.SEEK_END) -- Move to the end of the file again
        U.write(fd, ip_to_add .. "\n") -- Append the IP address to the file
    end

    -- Simulate some processing (optional)
    print("Simulating file processing for 5 seconds...")
    os.execute("sleep 5")
else
    print("Failed to lock the file after " .. max_retries .. " attempts.")
end

-- Release the lock
lock.l_type = M.F_UNLCK
M.fcntl(fd, M.F_SETLK, lock)
print("Lock released.")

-- Close the file
U.close(fd)
