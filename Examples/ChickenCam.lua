local gpu = peripheral.find("directgpu")

-- Configuration
local CAMERA_URL = "http://213.144.145.239:8090/cam_1.jpg"
local MAX_CONCURRENT = 12
local RESOLUTION_MULTIPLIER = 2  -- Change this to 1, 2, 3, or 4 for different quality levels

local function formatTime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    if h > 0 then
        return string.format("%dh %dm %ds", h, m, s)
    elseif m > 0 then
        return string.format("%dm %ds", m, s)
    else
        return string.format("%ds", s)
    end
end

print("Single Webcam Viewer - Auto-detecting monitor...")

-- Auto-detect monitor and create display with custom resolution
local display = gpu.autoDetectAndCreateDisplayWithResolution(RESOLUTION_MULTIPLIER)

if not display or display == -1 then
    printError("Failed to create display - no monitor found or resource limits exceeded")
    return
end

local info = gpu.getDisplayInfo(display)
print(("Display created: %dx%d pixels (%dx resolution)"):format(
    info.pixelWidth, info.pixelHeight, RESOLUTION_MULTIPLIER))

local w, h = info.pixelWidth, info.pixelHeight

local stats = {
    frameCount = 0,
    errorCount = 0,
    totalFetchTime = 0,
    totalDrawTime = 0,
    currentFps = 0,
    lastFpsTime = os.epoch("utc") / 1000,
    startTime = os.epoch("utc") / 1000,
    consecutiveErrors = 0,
    pendingRequests = 0
}

local httpHeaders = {
    ["User-Agent"] = "CC/1.0",
    ["Accept"] = "image/jpeg",
    ["Connection"] = "keep-alive",
    ["Cache-Control"] = "no-cache"
}

local function processFrame(data, fetchTime)
    local drawStart = os.epoch("utc")
    
    -- Use loadJPEGRegion to decode and draw in one step
    local ok, err = pcall(gpu.loadJPEGRegion, display, data, 0, 0, w, h)
    
    if not ok then
        stats.errorCount = stats.errorCount + 1
        print("loadJPEGRegion failed: " .. tostring(err))
        return false
    end
    
    -- Must manually call updateDisplay after loadJPEGRegion
    local updOk, updErr = pcall(gpu.updateDisplay, display)
    
    if not updOk then
        stats.errorCount = stats.errorCount + 1
        print("updateDisplay failed: " .. tostring(updErr))
        return false
    end
    
    local drawTime = os.epoch("utc") - drawStart
    stats.totalFetchTime = stats.totalFetchTime + fetchTime
    stats.totalDrawTime = stats.totalDrawTime + drawTime
    stats.frameCount = stats.frameCount + 1
    stats.consecutiveErrors = 0
    
    -- Update FPS counter
    local now = os.epoch("utc") / 1000
    local elapsed = now - stats.lastFpsTime
    if elapsed > 1.0 then
        local framesInPeriod = stats.frameCount - (stats.lastFrameCount or 0)
        stats.currentFps = framesInPeriod / elapsed
        stats.lastFpsTime = now
        stats.lastFrameCount = stats.frameCount
    end
    return true
end

-- Clear the screen once at the start
gpu.clear(display, 0, 0, 0)
gpu.updateDisplay(display)

local function printStatus()
    write(string.format(
        "\rFPS:%5.1f  Frames:%6d  Errors:%3d  Pending:%2d  Fetch:%4dms  Draw:%4dms",
        stats.currentFps,
        stats.frameCount,
        stats.errorCount,
        stats.pendingRequests,
        math.floor(stats.totalFetchTime / math.max(stats.frameCount, 1)),
        math.floor(stats.totalDrawTime / math.max(stats.frameCount, 1))
    ))
end

local function streamLoop()
    local pendingFetches = {}
    local lastUi = os.clock()
    local running = true
    
    while running do
        -- Queue requests up to MAX_CONCURRENT
        while stats.pendingRequests < MAX_CONCURRENT do
            local url = CAMERA_URL .. "?t=" .. math.random(1000000, 9999999)
            local startT = os.epoch("utc")
            http.request(url, nil, httpHeaders, true)
            pendingFetches[url] = startT
            stats.pendingRequests = stats.pendingRequests + 1
        end
        
        -- Handle events
        local event, p1, p2 = os.pullEvent()
        
        if event == "http_success" then
            local url, h = p1, p2
            local fetchStart = pendingFetches[url]
            if fetchStart then
                local fetchTime = os.epoch("utc") - fetchStart
                pendingFetches[url] = nil
                stats.pendingRequests = stats.pendingRequests - 1
                
                local data = h.readAll()
                local code = h.getResponseCode()
                h.close()
                
                if code == 200 and #data >= 100 then
                    processFrame(data, fetchTime)
                else
                    stats.errorCount = stats.errorCount + 1
                end
            end
            
        elseif event == "http_failure" then
            local url = p1
            if pendingFetches[url] then
                pendingFetches[url] = nil
                stats.pendingRequests = stats.pendingRequests - 1
                stats.errorCount = stats.errorCount + 1
                stats.consecutiveErrors = stats.consecutiveErrors + 1
                
                if stats.consecutiveErrors > 5 then
                    stats.consecutiveErrors = 0
                    sleep(1)
                end
            end
            
        elseif event == "key" and p1 == keys.q then
            break
            
        elseif event == "terminate" then
            break
        end
        
        -- Update UI periodically
        if os.clock() - lastUi > 0.25 then
            printStatus()
            lastUi = os.clock()
        end
        
        if stats.pendingRequests == 0 then sleep(0) end
    end
end

print("Press Q to quit")
print("Starting stream...")
streamLoop()

print("\nStopping...")
local runSecs = (os.epoch("utc") / 1000) - stats.startTime
if runSecs <= 0 then runSecs = 1 end

print(string.format("Total Frames: %d  Errors: %d  AvgFPS: %.2f", 
    stats.frameCount, stats.errorCount, stats.frameCount / runSecs))
print(string.format("Average fetch: %.1fms  Average draw: %.1fms  Runtime: %s",
    stats.totalFetchTime / math.max(stats.frameCount, 1),
    stats.totalDrawTime / math.max(stats.frameCount, 1),
    formatTime(runSecs)))

gpu.clear(display, 0, 0, 0)
gpu.updateDisplay(display)
gpu.removeDisplay(display)
print("Done")
