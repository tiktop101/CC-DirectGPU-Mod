local gpu = peripheral.find("directgpu")

local IMAGES = {
    "https://i.guim.co.uk/img/media/c6f7b43fa821d06fe1ab4311e558686529931492/180_92_1046_628/master/1046.jpg?width=465&dpr=1&s=none&crop=none",
    "https://wallpapers.com/images/hd/minecraft-shaders-1920-x-965-ifep35n93dhu1uzw.jpg",
    "https://wallpapers.com/images/hd/minecraft-shaders-1920-x-1080-dxnqfhk4rnysfhx5.jpg"
}
local SLIDE_DURATION = 5  -- seconds per image
local RESOLUTION = 2

print("Image Slideshow - Auto-detecting monitor...")
local display = gpu.autoDetectAndCreateDisplayWithResolution(RESOLUTION)

if not display or display == -1 then
    printError("Failed to create display")
    return
    end

    local info = gpu.getDisplayInfo(display)
    local w, h = info.pixelWidth, info.pixelHeight
    print(string.format("Display: %dx%d", w, h))

    local function loadAndDisplayImage(url)
    print("Loading: " .. url)
    local response = http.get(url, {}, true)

    if not response then
        printError("Failed to fetch: " .. url)
        return false
        end

        local data = response.readAll()
        response.close()

        if #data < 100 then
            printError("Invalid image data")
            return false
            end

            local ok, err = pcall(gpu.loadJPEGRegion, display, data, 0, 0, w, h)
            if not ok then
                printError("Failed to load image: " .. tostring(err))
                return false
                end

                gpu.updateDisplay(display)
                return true
                end

                print("Starting slideshow... (Press Q to quit)")
                local currentIndex = 1
                local running = true

                parallel.waitForAny(
                    function()
                    while running do
                        if loadAndDisplayImage(IMAGES[currentIndex]) then
                            sleep(SLIDE_DURATION)
                            currentIndex = currentIndex + 1
                            if currentIndex > #IMAGES then
                                currentIndex = 1
                                end
                                else
                                    sleep(1)
                                    end
                                    end
                                    end,
                                    function()
                                    while true do
                                        local event, key = os.pullEvent("key")
                                        if key == keys.q then
                                            running = false
                                            break
                                            end
                                            end
                                            end
                )

                gpu.removeDisplay(display)
                print("Done")
