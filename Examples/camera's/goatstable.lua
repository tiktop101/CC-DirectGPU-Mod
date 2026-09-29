local gpu = peripheral.find("directgpu")
local CAM_URL = "https://nexusapi-us1.camera.home.nest.com/get_image?uuid=bcb4249ac7e64e4d8ffe8948d4a59d18&width=540&public=CicGaHojwa"
local REFRESH_INTERVAL = 0.2
local RESOLUTION = 1
print("Single Cam Viewer - Auto-detecting monitor...")
local display = gpu.autoDetectAndCreateDisplayWithResolution(RESOLUTION)
if not display or display == -1 then
    printError("Failed to create display")
    return
    end
    local info = gpu.getDisplayInfo(display)
    local w, h = info.pixelWidth, info.pixelHeight
    print(string.format("Display: %dx%d", w, h))
    local region = {x = 0, y = 0, w = w, h = h}
    local httpHeaders = {
        ["User-Agent"] = "CC/1.0",
        ["Accept"] = "image/jpeg",
    }
    local stats = { frameCount = 0, errorCount = 0 }
    gpu.clear(display, 0, 0, 0)
    gpu.updateDisplay(display)
    local function printStatus()
    write(string.format("\rFrames: %4d  Errors: %2d", stats.frameCount, stats.errorCount))
    end
    local function fetchFrame()
    local url = CAM_URL .. "&t=" .. math.random(1000000, 9999999)
    local h = http.get(url, httpHeaders, true)
    if not h then
        stats.errorCount = stats.errorCount + 1
        return
        end
        local data = h.readAll()
        local code = h.getResponseCode()
        h.close()
        if code == 200 and data and #data >= 100 then
            local ok = pcall(gpu.loadJPEGRegion, display, data, region.x, region.y, region.w, region.h)
            if ok then
                pcall(gpu.updateDisplay, display)
                stats.frameCount = stats.frameCount + 1
                else
                    stats.errorCount = stats.errorCount + 1
                    end
                    else
                        stats.errorCount = stats.errorCount + 1
                        end
                        end
                        print("Press Q to quit")
                        print("Starting stream...")
                        local running = true
                        while running do
                            fetchFrame()
                            printStatus()
                            local timer = os.startTimer(REFRESH_INTERVAL)
                            while true do
                                local event, p1 = os.pullEvent()
                                if event == "timer" and p1 == timer then
                                    break
                                    elseif event == "key" and p1 == keys.q then
                                        running = false
                                        break
                                        elseif event == "terminate" then
                                            running = false
                                            break
                                            end
                                            end
                                            end
                                            print(string.format("\nStopping... %d frames, %d errors", stats.frameCount, stats.errorCount))
                                            gpu.clear(display, 0, 0, 0)
                                            gpu.updateDisplay(display)
                                            gpu.removeDisplay(display)
                                            print("Done")
