local gpu = peripheral.find("directgpu")

local objData = [[
    v -1 -1 -1
    v 1 -1 -1
    v 1 1 -1
    v -1 1 -1
    v -1 -1 1
    v 1 -1 1
    v 1 1 1
    v -1 1 1

    f 1 2 3 4
    f 5 8 7 6
    f 1 5 6 2
    f 4 3 7 8
    f 1 4 8 5
    f 2 6 7 3
]]

local args = { ... }
local imagePath = args[1] or "image.jpg"
local RESOLUTION = tonumber(args[2]) or 1

if not fs.exists(imagePath) then
    error("Image file not found: " .. imagePath, 0)
    end

    local file = fs.open(imagePath, "rb")
    local raw = file.readAll()
    file.close()

    os.sleep(0.2)

    local id
    local ok, err = pcall(function()
    id = gpu.autoDetectAndCreateDisplayWithResolution(RESOLUTION)
    end)

    if not ok or not id or id < 0 then
        error("gpu.createDisplay failed: " .. tostring(err), 0)
        end

        local info = gpu.getDisplayInfo(id)
        local w = info.pixelWidth
        local h = info.pixelHeight

        gpu.clear(id, 255, 255, 255)

        gpu.loadBlurredImage(
            id,
            raw,
            {
                x = 0,
                y = 0,
                w = w,
                h = h,
                percent = false,
                blur = 0,
                brightness = 1.0,
                saturation = 1.0,
                zoom = 1.0,
                focusX = 0.5,
                focusY = 0.5,
                bottomDim = 0.0
            }
        )

        gpu.drawText(
            id,
            "Create : Coasters",
            1,
            1,
            255,
            255,
            255,
            "Arial",
            30,
            "bold"
        )

        local modelId = gpu.load3DModel(objData)

        gpu.setupCamera(id, 60, 0.1, 1000)
        gpu.setCameraPosition(id, 0, 0, 5)

        gpu.addDirectionalLight(
            id,
            0,
            -1,
            0,
            255,
            255,
            255,
            0.8
        )

        gpu.updateDisplay(id)

        local rotation = 0

        while true do
            gpu.clearZBuffer(id)

            gpu.draw3DModel(
                id,
                modelId,
                0,
                0,
                0,
                rotation,
                rotation,
                0,
                1.0,
                200,
                200,
                255
            )

            gpu.updateDisplay(id)

            rotation = rotation + 2

            sleep(0.05)
            end
