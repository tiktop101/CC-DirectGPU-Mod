local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplay()

local info = gpu.getDisplayInfo(display)
local W, H = info.pixelWidth, info.pixelHeight

gpu.clear(display, 25, 30, 45)
gpu.drawText(display, "touchscreen :3", 20, 20, 255, 255, 255, "SansSerif", 24, "plain")
gpu.fillRect(display, 20, 70, W - 40, 60, 60, 120, 220)
gpu.drawText(display, "Touch here!", 35, 90, 255, 255, 255, "SansSerif", 18, "plain")
gpu.updateDisplay(display)

local timer = os.startTimer(0.05)

while true do
  local event, id = os.pullEventRaw()

  if event == "timer" and id == timer then
    timer = os.startTimer(0.05)

    for _ = 1, 64 do
      local ok, e = pcall(gpu.pollEvent, display)

      if not ok or not e then
        break
        end

        if e.type == "mouse_click" then
          print("Click:", e.x, e.y, "Button:", e.button)

          if e.x >= 20 and e.x < W - 20
            and e.y >= 70 and e.y < 130 then
            gpu.clear(display, 30, 100, 60)
            gpu.drawText(display, "Touched!", 20, 20, 255, 255, 255, "SansSerif", 24, "plain")
            gpu.updateDisplay(display)
            end
            end
            end
            end
            end
