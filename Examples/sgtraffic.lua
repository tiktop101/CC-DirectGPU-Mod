local gpu = peripheral.find("directgpu")

-- Singapore LTA Traffic Camera API (FREE - no key required!)
local API_URL = "https://api.data.gov.sg/v1/transport/traffic-images"
local RESOLUTION = 2
local AUTO_CYCLE = true  -- Automatically cycle through cameras
local CYCLE_INTERVAL = 5  -- seconds between camera changes

if not gpu then
    printError("DirectGPU peripheral not found!")
    return
    end

    print("Singapore Traffic Camera Viewer - Loading...")
    local display = gpu.autoDetectAndCreateDisplayWithResolution(RESOLUTION)

    if not display or display == -1 then
        printError("Failed to create display")
        return
        end

        local info = gpu.getDisplayInfo(display)
        local w, h = info.pixelWidth, info.pixelHeight
        print(string.format("Display: %dx%d", w, h))

        gpu.clear(display, 20, 20, 40)
        gpu.updateDisplay(display)

        local cameras = {}
        local currentIndex = 1
        local lastUpdate = 0

        -- Parse JSON manually (simple parser for this specific API)
        local function parseTrafficAPI(jsonData)
        local cams = {}

        -- Extract each camera from the items array
        for cameraBlock in jsonData:gmatch('"camera_id"%s*:%s*"([^"]+)".-"image"%s*:%s*"([^"]+)".-"latitude"%s*:%s*([%d%.%-]+).-"longitude"%s*:%s*([%d%.%-]+)') do
            local id, imageUrl, lat, lon = cameraBlock:match('"camera_id"%s*:%s*"([^"]+)"'),
            cameraBlock:match('"image"%s*:%s*"([^"]+)"'),
            cameraBlock:match('"latitude"%s*:%s*([%d%.%-]+)'),
            cameraBlock:match('"longitude"%s*:%s*([%d%.%-]+)')
            end

            -- Simpler approach - look for image URLs
            local count = 0
            for imageUrl in jsonData:gmatch('"image"%s*:%s*"([^"]+)"') do
                count = count + 1
                -- Get camera ID before this image
                local beforeImage = jsonData:sub(1, jsonData:find(imageUrl, 1, true))
                local cameraId = beforeImage:match('"camera_id"%s*:%s*"([^"]+)"[^}]*$')

                table.insert(cams, {
                    id = cameraId or ("cam_" .. count),
                             imageUrl = imageUrl,
                             index = count
                })
                end

                return cams
                end

                local function fetchCameraList()
                print("Fetching camera list from Singapore LTA...")
                local response = http.get(API_URL)

                if not response then
                    printError("Failed to fetch camera list")
                    return false
                    end

                    local jsonData = response.readAll()
                    response.close()

                    cameras = parseTrafficAPI(jsonData)

                    if #cameras == 0 then
                        printError("No cameras found in API response")
                        return false
                        end

                        print(string.format("Found %d traffic cameras!", #cameras))
                        return true
                        end

                        local function loadAndDisplayCamera(camera)
                        if not camera or not camera.imageUrl then
                            return false
                            end

                            print(string.format("\nCamera %d/%d: %s", camera.index, #cameras, camera.id))
                            print("Fetching image...")

                            local response = http.get(camera.imageUrl, {}, true)

                            if not response then
                                printError("Failed to fetch camera image")
                                return false
                                end

                                local imageData = response.readAll()
                                response.close()

                                if #imageData < 1000 then
                                    printError("Image data too small")
                                    return false
                                    end

                                    print(string.format("Loaded %d KB", math.floor(#imageData / 1024)))

                                    local ok, err = pcall(gpu.loadJPEGRegion, display, imageData, 0, 0, w, h)

                                    if not ok then
                                        printError("Failed to display: " .. tostring(err))
                                        return false
                                        end

                                        gpu.updateDisplay(display)
                                        return true
                                        end

                                        local function displayCurrentCamera()
                                        if #cameras == 0 then
                                            print("No cameras available")
                                            return false
                                            end

                                            -- Wrap around
                                            if currentIndex > #cameras then
                                                currentIndex = 1
                                                elseif currentIndex < 1 then
                                                    currentIndex = #cameras
                                                    end

                                                    return loadAndDisplayCamera(cameras[currentIndex])
                                                    end

                                                    -- Initial load
                                                    if not fetchCameraList() then
                                                        print("Failed to load cameras, retrying in 5 seconds...")
                                                        sleep(5)
                                                        if not fetchCameraList() then
                                                            gpu.removeDisplay(display)
                                                            printError("Could not connect to Singapore LTA API")
                                                            return
                                                            end
                                                            end

                                                            -- Display first camera
                                                            displayCurrentCamera()

                                                            print("\n" .. string.rep("=", 50))
                                                            print("Controls:")
                                                            print("  N - Next camera")
                                                            print("  P - Previous camera")
                                                            print("  R - Refresh current camera")
                                                            print("  A - Toggle auto-cycle (" .. (AUTO_CYCLE and "ON" or "OFF") .. ")")
                                                            print("  U - Update camera list")
                                                            print("  Q - Quit")
                                                            print(string.rep("=", 50))

                                                            local running = true

                                                            parallel.waitForAny(
                                                                -- Auto-cycle thread
                                                                function()
                                                                while running do
                                                                    if AUTO_CYCLE then
                                                                        sleep(CYCLE_INTERVAL)
                                                                        local now = os.epoch("utc") / 1000
                                                                        if now - lastUpdate >= CYCLE_INTERVAL then
                                                                            currentIndex = currentIndex + 1
                                                                            displayCurrentCamera()
                                                                            lastUpdate = now
                                                                            end
                                                                            else
                                                                                sleep(0.5)
                                                                                end
                                                                                end
                                                                                end,

                                                                                -- Keyboard controls
                                                                                function()
                                                                                while true do
                                                                                    local event, key = os.pullEvent("key")

                                                                                    if key == keys.q then
                                                                                        running = false
                                                                                        break

                                                                                        elseif key == keys.n then
                                                                                            currentIndex = currentIndex + 1
                                                                                            displayCurrentCamera()
                                                                                            lastUpdate = os.epoch("utc") / 1000

                                                                                            elseif key == keys.p then
                                                                                                currentIndex = currentIndex - 1
                                                                                                displayCurrentCamera()
                                                                                                lastUpdate = os.epoch("utc") / 1000

                                                                                                elseif key == keys.r then
                                                                                                    print("\nRefreshing current camera...")
                                                                                                    -- Refetch the camera list to get latest images
                                                                                                    fetchCameraList()
                                                                                                    displayCurrentCamera()
                                                                                                    lastUpdate = os.epoch("utc") / 1000

                                                                                                    elseif key == keys.a then
                                                                                                        AUTO_CYCLE = not AUTO_CYCLE
                                                                                                        print("\nAuto-cycle: " .. (AUTO_CYCLE and "ON" or "OFF"))
                                                                                                        lastUpdate = os.epoch("utc") / 1000

                                                                                                        elseif key == keys.u then
                                                                                                            print("\nUpdating camera list...")
                                                                                                            fetchCameraList()
                                                                                                            displayCurrentCamera()
                                                                                                            lastUpdate = os.epoch("utc") / 1000
                                                                                                            end
                                                                                                            end
                                                                                                            end
                                                            )

                                                            -- Cleanup
                                                            print("\nShutting down...")
                                                            gpu.clear(display, 0, 0, 0)
                                                            gpu.updateDisplay(display)
                                                            gpu.removeDisplay(display)
                                                            print("Done!")
