local gpu = peripheral.find("directgpu")

-- NASA APOD API (free, no key needed for low usage, but get one at https://api.nasa.gov)
local NASA_API_KEY = "DEMO_KEY"  -- Replace with your own key for better rate limits
local APOD_API = "https://api.nasa.gov/planetary/apod"
local RESOLUTION = 3  -- High quality for space photos!
local UPDATE_INTERVAL = 3600  -- Check for new image every hour (in seconds)

if not gpu then
    printError("DirectGPU peripheral not found!")
    return
    end

    print("NASA APOD Viewer - Auto-detecting monitor...")
    local display = gpu.autoDetectAndCreateDisplayWithResolution(RESOLUTION)

    if not display or display == -1 then
        printError("Failed to create display")
        return
        end

        local info = gpu.getDisplayInfo(display)
        local w, h = info.pixelWidth, info.pixelHeight
        print(string.format("Display: %dx%d", w, h))

        gpu.clear(display, 0, 0, 20)  -- Dark blue background
        gpu.updateDisplay(display)

        local currentApod = nil

        local function fetchAPOD(date)
        local url = APOD_API .. "?api_key=" .. NASA_API_KEY
        if date then
            url = url .. "&date=" .. date
            end

            print("Fetching NASA APOD data...")
            local response = http.get(url)

            if not response then
                printError("Failed to fetch APOD API")
                return nil
                end

                local jsonData = response.readAll()
                response.close()

                -- Parse JSON manually (simple parser)
                local function extractField(json, field)
                local pattern = '"' .. field .. '"%s*:%s*"([^"]*)"'
                return json:match(pattern)
                end

                local apod = {
                    title = extractField(jsonData, "title"),
                    date = extractField(jsonData, "date"),
                    explanation = extractField(jsonData, "explanation"),
                    url = extractField(jsonData, "url"),
                    hdurl = extractField(jsonData, "hdurl"),
                    media_type = extractField(jsonData, "media_type")
                }

                -- Use HD URL if available, otherwise regular URL
                apod.imageUrl = apod.hdurl or apod.url

                return apod
                end

                local function loadAndDisplayImage(url)
                print("Downloading image...")
                print("URL: " .. url)

                -- Check if it's an image URL
                if not url:match("%.jpg$") and not url:match("%.jpeg$") and not url:match("%.png$") then
                    printError("Not a direct image URL (might be a video)")
                    return false
                    end

                    local response = http.get(url, {}, true)

                    if not response then
                        printError("Failed to download image")
                        return false
                        end

                        local imageData = response.readAll()
                        response.close()

                        print(string.format("Downloaded %d bytes", #imageData))

                        if #imageData < 1000 then
                            printError("Image data too small")
                            return false
                            end

                            print("Rendering to display...")
                            local ok, err = pcall(gpu.loadJPEGRegion, display, imageData, 0, 0, w, h)

                            if not ok then
                                printError("Failed to render image: " .. tostring(err))
                                return false
                                end

                                gpu.updateDisplay(display)
                                return true
                                end

                                local function displayAPOD(apod)
                                if not apod then
                                    print("No APOD data available")
                                    return false
                                    end

                                    print("\n" .. string.rep("=", 50))
                                    print("NASA Astronomy Picture of the Day")
                                    print(string.rep("=", 50))
                                    print("Date: " .. (apod.date or "Unknown"))
                                    print("Title: " .. (apod.title or "Unknown"))
                                    print(string.rep("=", 50))

                                    if apod.explanation then
                                        -- Word wrap the explanation
                                        local maxWidth = 70
                                        local words = {}
                                        for word in apod.explanation:gmatch("%S+") do
                                            table.insert(words, word)
                                            end

                                            local line = ""
                                            for _, word in ipairs(words) do
                                                if #line + #word + 1 > maxWidth then
                                                    print(line)
                                                    line = word
                                                    else
                                                        if #line > 0 then
                                                            line = line .. " " .. word
                                                            else
                                                                line = word
                                                                end
                                                                end
                                                                end
                                                                if #line > 0 then
                                                                    print(line)
                                                                    end
                                                                    end
                                                                    print(string.rep("=", 50) .. "\n")

                                                                    if apod.media_type ~= "image" then
                                                                        printError("Today's APOD is a " .. (apod.media_type or "video") .. ", not an image")
                                                                        print("You can view it at: " .. (apod.url or "nasa.gov"))
                                                                        return false
                                                                        end

                                                                        return loadAndDisplayImage(apod.imageUrl)
                                                                        end

                                                                        local function drawTextOverlay(text, y, size)
                                                                        -- Simple text overlay at bottom of screen
                                                                        -- Draw a semi-transparent dark bar
                                                                        for py = y, y + size do
                                                                            for px = 0, w - 1 do
                                                                                gpu.setPixel(display, px, py, 0, 0, 0, 180)  -- Semi-transparent black
                                                                                end
                                                                                end
                                                                                gpu.updateDisplay(display)
                                                                                end

                                                                                -- Main loop
                                                                                print("Loading today's Astronomy Picture of the Day...")
                                                                                local running = true
                                                                                local lastUpdate = 0

                                                                                local function updateAPOD()
                                                                                local apod = fetchAPOD()
                                                                                if apod and apod ~= currentApod then
                                                                                    currentApod = apod
                                                                                    if displayAPOD(apod) then
                                                                                        print("\n✓ APOD displayed successfully!")
                                                                                        print("Image will auto-update every hour")
                                                                                        end
                                                                                        end
                                                                                        lastUpdate = os.epoch("utc") / 1000
                                                                                        end

                                                                                        -- Load initial image
                                                                                        updateAPOD()

                                                                                        print("\nControls:")
                                                                                        print("  N - Load next random past APOD")
                                                                                        print("  R - Reload today's APOD")
                                                                                        print("  Q - Quit")

                                                                                        parallel.waitForAny(
                                                                                            function()
                                                                                            while running do
                                                                                                sleep(UPDATE_INTERVAL)
                                                                                                local now = os.epoch("utc") / 1000
                                                                                                if now - lastUpdate >= UPDATE_INTERVAL then
                                                                                                    print("\nChecking for updated APOD...")
                                                                                                    updateAPOD()
                                                                                                    end
                                                                                                    end
                                                                                                    end,
                                                                                                    function()
                                                                                                    while true do
                                                                                                        local event, key = os.pullEvent("key")

                                                                                                        if key == keys.q then
                                                                                                            running = false
                                                                                                            break

                                                                                                            elseif key == keys.r then
                                                                                                                print("\nReloading today's APOD...")
                                                                                                                updateAPOD()

                                                                                                                elseif key == keys.n then
                                                                                                                    -- Load a random date from the past year
                                                                                                                    local daysAgo = math.random(1, 365)
                                                                                                                    local secondsAgo = daysAgo * 24 * 60 * 60
                                                                                                                    local timestamp = os.epoch("utc") / 1000 - secondsAgo

                                                                                                                    -- Format date as YYYY-MM-DD
                                                                                                                    local date = os.date("!%Y-%m-%d", timestamp)
                                                                                                                    print("\nLoading APOD from " .. date .. "...")

                                                                                                                    local apod = fetchAPOD(date)
                                                                                                                    if apod then
                                                                                                                        currentApod = apod
                                                                                                                        displayAPOD(apod)
                                                                                                                        end
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
