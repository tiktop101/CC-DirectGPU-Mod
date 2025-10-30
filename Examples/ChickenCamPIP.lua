local gpu = peripheral.find("directgpu")

local MAIN_CAM = "http://213.144.145.239:8090/cam_1.jpg"
local PIP_CAM = "http://213.144.145.239:8090/cam_2.jpg"
local PIP_SCALE = 0.35  -- PiP is 35% of screen size
local RESOLUTION = 2
local MAX_CONCURRENT = 10

print("Picture-in-Picture Viewer - Auto-detecting monitor...")
local display = gpu.autoDetectAndCreateDisplayWithResolution(RESOLUTION)

if not display or display == -1 then
    printError("Failed to create display")
    return
    end

    local info = gpu.getDisplayInfo(display)
    local w, h = info.pixelWidth, info.pixelHeight
    print(string.format("Display: %dx%d", w, h))

    -- Define regions
    local pipW = math.floor(w * PIP_SCALE)
    local pipH = math.floor(h * PIP_SCALE)
    local pipX = w - pipW - 10  -- 10px padding from right
    local pipY = 10  -- 10px padding from top

    local mainRegion = {x = 0, y = 0, w = w, h = h}
    local pipRegion = {x = pipX, y = pipY, w = pipW, h = pipH}

    print(string.format("Main: %dx%d, PiP: %dx%d at (%d,%d)",
                        mainRegion.w, mainRegion.h, pipRegion.w, pipRegion.h, pipX, pipY))

    local stats = {
        main = {frameCount = 0, errorCount = 0},
        pip = {frameCount = 0, errorCount = 0},
        pendingRequests = 0
    }

    local httpHeaders = {
        ["User-Agent"] = "CC/1.0",
        ["Accept"] = "image/jpeg",
        ["Connection"] = "keep-alive"
    }

    local function processFrame(camStats, data, region, isMain)
    local ok = pcall(gpu.loadJPEGRegion, display, data, region.x, region.y, region.w, region.h)
    if not ok then
        camStats.errorCount = camStats.errorCount + 1
        return false
        end

        -- Only update display after processing frame, don't update on every frame
        -- We'll batch updates to avoid flickering
        camStats.frameCount = camStats.frameCount + 1
        return true
        end

        local lastMainFrame = nil
        local lastPipFrame = nil

        local function updateDisplay()
        -- This ensures we always draw main first, then PiP on top
        if lastMainFrame then
            pcall(gpu.loadJPEGRegion, display, lastMainFrame, mainRegion.x, mainRegion.y, mainRegion.w, mainRegion.h)
            end
            if lastPipFrame then
                pcall(gpu.loadJPEGRegion, display, lastPipFrame, pipRegion.x, pipRegion.y, pipRegion.w, pipRegion.h)
                end
                pcall(gpu.updateDisplay, display)
                end

                gpu.clear(display, 0, 0, 0)
                gpu.updateDisplay(display)

                local function printStatus()
                write(string.format(
                    "\rMain: %4d frames (%2d err)  PiP: %4d frames (%2d err)  Pending: %2d",
                                    stats.main.frameCount, stats.main.errorCount,
                                    stats.pip.frameCount, stats.pip.errorCount,
                                    stats.pendingRequests
                ))
                end

                local function streamLoop()
                local pendingFetches = {}
                local lastUi = os.clock()
                local lastUpdate = os.clock()
                local needsUpdate = false

                while true do
                    while stats.pendingRequests < MAX_CONCURRENT do
                        local url, camStats, region, isMain

                        -- Alternate but prioritize main camera (2 main requests per 1 pip)
                        if stats.main.frameCount <= stats.pip.frameCount * 2 then
                            url = MAIN_CAM .. "?t=" .. math.random(1000000, 9999999)
                            camStats = stats.main
                            region = mainRegion
                            isMain = true
                            else
                                url = PIP_CAM .. "?t=" .. math.random(1000000, 9999999)
                                camStats = stats.pip
                                region = pipRegion
                                isMain = false
                                end

                                http.request(url, nil, httpHeaders, true)
                                pendingFetches[url] = {camStats = camStats, region = region, isMain = isMain}
                                stats.pendingRequests = stats.pendingRequests + 1
                                end

                                local event, p1, p2 = os.pullEvent()

                                if event == "http_success" then
                                    local url, h = p1, p2
                                    local fetchInfo = pendingFetches[url]
                                    if fetchInfo then
                                        pendingFetches[url] = nil
                                        stats.pendingRequests = stats.pendingRequests - 1

                                        local data = h.readAll()
                                        local code = h.getResponseCode()
                                        h.close()

                                        if code == 200 and #data >= 100 then
                                            -- Store the frame data
                                            if fetchInfo.isMain then
                                                lastMainFrame = data
                                                else
                                                    lastPipFrame = data
                                                    end
                                                    fetchInfo.camStats.frameCount = fetchInfo.camStats.frameCount + 1
                                                    needsUpdate = true
                                                    else
                                                        fetchInfo.camStats.errorCount = fetchInfo.camStats.errorCount + 1
                                                        end
                                                        end

                                                        elseif event == "http_failure" then
                                                            local url = p1
                                                            if pendingFetches[url] then
                                                                local fetchInfo = pendingFetches[url]
                                                                pendingFetches[url] = nil
                                                                stats.pendingRequests = stats.pendingRequests - 1
                                                                fetchInfo.camStats.errorCount = fetchInfo.camStats.errorCount + 1
                                                                end

                                                                elseif event == "key" and p1 == keys.q then
                                                                    break
                                                                    elseif event == "terminate" then
                                                                        break
                                                                        end

                                                                        -- Update display only when we have new frames and enough time has passed
                                                                        if needsUpdate and (os.clock() - lastUpdate) > 0.05 then
                                                                            updateDisplay()
                                                                            needsUpdate = false
                                                                            lastUpdate = os.clock()
                                                                            end

                                                                            if os.clock() - lastUi > 0.25 then
                                                                                printStatus()
                                                                                lastUi = os.clock()
                                                                                end

                                                                                if stats.pendingRequests == 0 then sleep(0) end
                                                                                    end
                                                                                    end

                                                                                    print("Press Q to quit")
                                                                                    print("Starting streams...")
                                                                                    streamLoop()

                                                                                    print("\nStopping...")
                                                                                    print(string.format("Main: %d frames, %d errors", stats.main.frameCount, stats.main.errorCount))
                                                                                    print(string.format("PiP: %d frames, %d errors", stats.pip.frameCount, stats.pip.errorCount))

                                                                                    gpu.clear(display, 0, 0, 0)
                                                                                    gpu.updateDisplay(display)
                                                                                    gpu.removeDisplay(display)
                                                                                    print("Done")
