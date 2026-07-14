local gpu = peripheral.find("directgpu") or error("DirectGPU not found!")
local displayId = gpu.autoDetectAndCreateDisplay()
local info = gpu.getDisplayInfo(displayId)
local width, height = info.pixelWidth, info.pixelHeight
print("Display: "..width.."x"..height)

local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function base64_encode(data)
local result, len = {}, #data
for i = 1, len, 3 do
  local a = string.byte(data, i)
  local b, c = string.byte(data, i+1) or 0, string.byte(data, i+2) or 0
  local n = a*0x10000 + b*0x100 + c
  table.insert(result, b64chars:sub(math.floor(n/0x40000)%64+1, math.floor(n/0x40000)%64+1))
  table.insert(result, b64chars:sub(math.floor(n/0x1000)%64+1, math.floor(n/0x1000)%64+1))
  table.insert(result, i+1<=len and b64chars:sub(math.floor(n/0x40)%64+1, math.floor(n/0x40)%64+1) or "=")
  table.insert(result, i+2<=len and b64chars:sub(n%64+1, n%64+1) or "=")
  if i%3000==0 then sleep(0) end
    end
    return table.concat(result)
    end

    local function playGIF(filename, targetFps)
    targetFps = targetFps or 11
    local frameTime = 1.0/targetFps
    if not fs.exists(filename) then filename = filename..".gif" end
      if not fs.exists(filename) then error("File not found: "..filename) end
        local f = fs.open(filename, "rb")
        local gifBytes = f.readAll()
        f.close()
        local b64gif = base64_encode(gifBytes)
        local ok, frameInfo = pcall(function() return gpu.getGIFFrameInfo(b64gif) end)
        if not ok then print("ERROR: "..tostring(frameInfo)) return end
          print(frameInfo.width.."x"..frameInfo.height.." | "..frameInfo.frameCount.." frames")
          if frameInfo.frameCount == 0 then print("No frames!") return end
            local ok, err = pcall(function() gpu.loadGIFFrame(displayId, b64gif, 0, 0, 0, width, height) end)
            if not ok then print("ERROR: "..tostring(err)) return end
              gpu.updateDisplay(displayId)
              sleep(0.1)
              if frameInfo.frameCount == 1 then read() return end

                local running, frameIdx, framesDisplayed, frameDrops = true, 0, 0, 0
                local startTime = os.epoch("utc")/1000
                local totalFrameTime, maxFrameTime = 0, 0

                parallel.waitForAny(
                  function()
                  while running do
                    local frameStart = os.epoch("utc")/1000
                    local ok, err = pcall(function() gpu.loadGIFFrame(displayId, b64gif, frameIdx, 0, 0, width, height) end)
                    if ok then gpu.updateDisplay(displayId) else print("Frame "..frameIdx.." error: "..tostring(err)) end
                      framesDisplayed = framesDisplayed + 1
                      local now = os.epoch("utc")/1000
                      local elapsed = now - frameStart
                      totalFrameTime, maxFrameTime = totalFrameTime+elapsed, math.max(maxFrameTime, elapsed)
                      if framesDisplayed%60==0 then
                        print(string.format("Frame %d/%d | %.1f FPS | drops: %d", frameIdx, frameInfo.frameCount-1, framesDisplayed/(now-startTime), frameDrops))
                        end
                        local sleepTime = startTime + (framesDisplayed*frameTime) - (os.epoch("utc")/1000)
                        if sleepTime < -frameTime then
                          local skip = math.floor(math.abs(sleepTime)/frameTime)
                          frameIdx = (frameIdx+skip)%frameInfo.frameCount
                          framesDisplayed = framesDisplayed+skip
                          frameDrops = frameDrops+skip
                          sleepTime = 0.001
                          elseif sleepTime < 0 then sleepTime = 0.001 end
                            if sleepTime > 0 then os.sleep(sleepTime) end
                              frameIdx = (frameIdx+1)%frameInfo.frameCount
                              end
                              end,
                              function() os.pullEvent("key") running = false end
                )

                local elapsed = (os.epoch("utc")/1000)-startTime
                print(string.format("Done | %.1fs | %.1f FPS | %d dropped", elapsed, framesDisplayed/elapsed, frameDrops))
                end

                local ok, err = pcall(function() playGIF("linkclick.gif", 11) end)
                if not ok then print("ERROR: "..tostring(err)) end
                  gpu.removeDisplay(displayId)
