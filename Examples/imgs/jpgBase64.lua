local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function base64_encode(data)
local res = {}
for i = 1, #data, 3 do
    local a, b, c = string.byte(data, i, i + 2)
    local v = (a * 65536) + ((b or 0) * 256) + (c or 0)
    table.insert(res, string.sub(b64chars, math.floor(v / 262144) + 1, math.floor(v / 262144) + 1))
    table.insert(res, string.sub(b64chars, math.floor(v / 4096) % 64 + 1, math.floor(v / 4096) % 64 + 1))
    table.insert(res, b and string.sub(b64chars, math.floor(v / 64) % 64 + 1, math.floor(v / 64) % 64 + 1) or "=")
    table.insert(res, c and string.sub(b64chars, v % 64 + 1, v % 64 + 1) or "=")
    end
    return table.concat(res)
    end

    local gpu = peripheral.find("directgpu")
    if not gpu then
        print("Error: DirectGPU block not found!")
        return
        end
        print("DirectGPU connected.")

        print("Auto-detecting monitor...")
        local displayId
        local success, err = pcall(function()
        displayId = gpu.autoDetectAndCreateDisplay()
        end)

        if not success or not displayId then
            print("Error: Could not detect a valid monitor nearby.")
            print(err or "")
            return
            end
            print("Created display with ID: " .. tostring(displayId))

            local fileName = "image.jpg"
            if not fs.exists(fileName) then
                print("Error: " .. fileName .. " does not exist.")
                return
                end

                print("Reading " .. fileName .. "...")
                local file = fs.open(fileName, "rb")
                local bytes = {}
                while true do
                    local byte = file.read()
                    if not byte then break end
                        table.insert(bytes, string.char(byte))
                        end
                        file.close()

                        local rawData = table.concat(bytes)
                        local b64String = ""

                        if #rawData >= 2 and string.byte(rawData, 1) == 0xFF and string.byte(rawData, 2) == 0xD8 then
                            print("Raw JPEG file detected. Encoding to Base64...")
                            b64String = base64_encode(rawData)
                            else
                                print("Assuming image.jpg is already a Base64 string...")
                                b64String = rawData
                                end

                                print("Sending image to display...")
                                local ok, drawErr = pcall(function()
                                gpu.loadJPEGFullscreen(displayId, b64String)
                                end)

                                if not ok then
                                    print("Error drawing image: " .. tostring(drawErr))
                                    else
                                        print("Successfully drew image to monitor!")
                                        end
