local gpu = peripheral.find("directgpu")

local CAMERA_BASE = "http://82.130.141.93/-wvhttp-01-/GetOneShot"
local RESOLUTION = 2
local MAX_CONCURRENT = 10

print("Single Camera Viewer - Auto-detecting monitor...")
local display = gpu.autoDetectAndCreateDisplayWithResolution(RESOLUTION)

if not display or display == -1 then
    printError("Failed to create display")
    return
    end

    local info = gpu.getDisplayInfo(display)
    local w, h = info.pixelWidth, info.pixelHeight
    print(string.format("Display: %dx%d", w, h))

    local region = {x = 0, y = 0, w = w, h = h}

    local stats = {
        frameCount = 0,
        errorCount = 0,
        pendingRequests = 0
    }

    local httpHeaders = {
        ["User-Agent"] = "CC/1.0",
        ["Accept"] = "image/jpeg",
        ["Connection"] = "keep-alive"
    }

    local function printStatus()
    write(string.format(
        "\rFrames: %4d  Errors: %2d  Pending: %2d",
        stats.frameCount, stats.errorCount, stats.pendingRequests
    ))
    end

    -- Clear display initially
    gpu.clear(display, 0, 0, 0)
    gpu.updateDisplay(display)

    local function streamLoop()
    local pendingFetches = {}
    local lastUi = os.clock()
    local lastUpdate = os.clock()
    local frameData = nil
    local needsUpdate = false

    while true do
        -- Queue up requests up to MAX_CONCURRENT
        while stats.pendingRequests < MAX_CONCURRENT do
            -- GetOneShot returns a single JPEG frame
            local url = CAMERA_BASE .. "?frame_count=1&rand=" .. math.random(100000, 999999)
            http.request(url, nil, httpHeaders, true)
            pendingFetches[url] = true
            stats.pendingRequests = stats.pendingRequests + 1
            end

            local event, p1, p2 = os.pullEvent()

            if event == "http_success" then
                local url, h = p1, p2
                if pendingFetches[url] then
                    pendingFetches[url] = nil
                    stats.pendingRequests = stats.pendingRequests - 1

                    local data = h.readAll()
                    local code = h.getResponseCode()
                    h.close()

                    if code == 200 and #data >= 100 then
                        frameData = data
                        stats.frameCount = stats.frameCount + 1
                        needsUpdate = true

                        -- Debug first few frames
                        if stats.frameCount <= 3 then
                            print("\nReceived frame " .. stats.frameCount .. ": " .. #data .. " bytes")
                            end
                            else
                                stats.errorCount = stats.errorCount + 1
                                print("\nBad response: code=" .. code .. ", size=" .. #data)
                                end
                                end

                                elseif event == "http_failure" then
                                    local url = p1
                                    if pendingFetches[url] then
                                        pendingFetches[url] = nil
                                        stats.pendingRequests = stats.pendingRequests - 1
                                        stats.errorCount = stats.errorCount + 1
                                        end

                                        elseif event == "key" and p1 == keys.q then
                                            break
                                            elseif event == "terminate" then
                                                break
                                                end

                                                -- Update display when we have a new frame and enough time has passed
                                                if needsUpdate and frameData and (os.clock() - lastUpdate) > 0.04 then
                                                    local ok = pcall(gpu.loadJPEGRegion, display, frameData, region.x, region.y, region.w, region.h)
                                                    if ok then
                                                        pcall(gpu.updateDisplay, display)
                                                        end
                                                        needsUpdate = false
                                                        lastUpdate = os.clock()
                                                        end

                                                        -- Update UI periodically
                                                        if os.clock() - lastUi > 0.25 then
                                                            printStatus()
                                                            lastUi = os.clock()
                                                            end

                                                            -- Small sleep if no pending requests
                                                            if stats.pendingRequests == 0 then
                                                                sleep(0)
                                                                end
                                                                end
                                                                end

                                                                print("Press Q to quit")
                                                                print("Starting stream...")
                                                                streamLoop()

                                                                print("\nStopping...")
                                                                print(string.format("Total frames: %d, errors: %d", stats.frameCount, stats.errorCount))

                                                                gpu.clear(display, 0, 0, 0)
                                                                gpu.updateDisplay(display)
                                                                gpu.removeDisplay(display)
                                                                print("Done")
