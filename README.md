# DirectGPU

A high-performance ComputerCraft peripheral for Minecraft that enables hardware-accelerated graphics rendering directly to monitors. Stream images, create interactive UIs, or build pixel art - all at 164×81 resolution per block.
## Features

- **True RGB Graphics** - 24-bit color with 164×81 pixels per monitor block
-  **Hardware Accelerated** - OpenGL rendering bypasses CC's text system
-  **Touch Input** - Full mouse and keyboard event support
-  **Auto-Detection** - Automatically finds and configures nearby monitors
-  **Drawing Primitives** - Lines, rectangles, and image loading
-  **Image Support** - Load PNG/JPEG images via Base64
-  **Flexible Sizing** - Works with any monitor array up to 8×6 blocks
-  **Thread-Safe** - Safe concurrent access from multiple computers

## Installation

1. Download the latest DirectGPU JAR from releases
2. Place in your Minecraft `mods` folder
3. Ensure you have **Forge** and **ComputerCraft** (or CC: Tweaked) installed
4. Launch Minecraft and enjoy!

## Quick Start

```lua
-- Find the DirectGPU peripheral
local gpu = peripheral.find("directgpu")

-- Auto-detect and create a display on the nearest monitor
local display = gpu.createDisplayAuto()

-- Get display dimensions
local info = gpu.getDisplayInfo(display)
print(string.format("Display: %dx%d pixels", info.pixelWidth, info.pixelHeight))

-- Draw a red square
gpu.drawRect(display, 10, 10, 50, 50, 255, 0, 0)
gpu.updateDisplay(display)

-- Clean up when done
gpu.clearDisplay()
```

## How It Works

DirectGPU creates a peripheral on the **bottom side** of ComputerCraft computers. When you call `createDisplay()`, it:

1. Finds monitor blocks in the world
2. Creates an OpenGL texture matching the monitor array size
3. Renders the texture directly onto the monitor blocks in 3D space
4. Captures mouse clicks via raycasting against the rendered surface

This approach provides dramatically higher resolution and performance compared to CC's built-in text-based rendering.

---

## API Reference

### Display Management

#### `createDisplayAuto()` → `displayId`
Automatically detects the nearest monitor within 16 blocks and creates a display.

```lua
local display = gpu.createDisplayAuto()
```

**Returns:** Display ID (number)  
**Throws:** Error if no monitor is found

---

#### `createDisplay(facing, width, height)` → `displayId`
Creates a display 2 blocks above the computer.

```lua
local display = gpu.createDisplay("north", 3, 2)
```

**Parameters:**
- `facing` (string): Direction - `"north"`, `"south"`, `"east"`, `"west"`, `"up"`, `"down"`
- `width` (number): Monitor width in blocks (1-8)
- `height` (number): Monitor height in blocks (1-6)

**Returns:** Display ID

---

#### `createDisplayAt(x, y, z, facing, width, height)` → `displayId`
Creates a display at specific world coordinates.

```lua
local display = gpu.createDisplayAt(100, 64, 200, "south", 4, 3)
```

**Parameters:**
- `x`, `y`, `z` (number): World coordinates
- `facing`, `width`, `height`: Same as `createDisplay()`

---

#### `removeDisplay(displayId)` → `success`
Removes a specific display and frees its resources.

```lua
gpu.removeDisplay(display)
```

**Returns:** `true` if successful, `false` otherwise

---

#### `clearDisplay()`
Removes all displays created by this computer.

```lua
gpu.clearDisplay()
```

---

#### `listDisplays()` → `displayIds`
Returns a list of all display IDs currently active.

```lua
local displays = gpu.listDisplays()
for _, id in ipairs(displays) do
    print("Display: " .. id)
end
```

---

#### `getDisplayInfo(displayId)` → `info`
Returns detailed information about a display.

```lua
local info = gpu.getDisplayInfo(display)
print(info.pixelWidth .. "x" .. info.pixelHeight)
```

**Returns:**
```lua
{
    x = 100,              -- World X coordinate
    y = 64,               -- World Y coordinate  
    z = 200,              -- World Z coordinate
    facing = "north",     -- Direction
    width = 3,            -- Width in blocks
    height = 2,           -- Height in blocks
    pixelWidth = 492,     -- Width in pixels (width * 164)
    pixelHeight = 162     -- Height in pixels (height * 81)
}
```

---

### Drawing Functions

#### `setPixel(displayId, x, y, r, g, b)`
Sets a single pixel to the specified RGB color.

```lua
gpu.setPixel(display, 100, 50, 255, 128, 0)
```

**Parameters:**
- `x`, `y` (number): Pixel coordinates (0-indexed from top-left)
- `r`, `g`, `b` (number): RGB values (0-255)

---

#### `getPixel(displayId, x, y)` → `color`
Returns the RGB color of a pixel.

```lua
local color = gpu.getPixel(display, 100, 50)
print(string.format("RGB: %d, %d, %d", color.r, color.g, color.b))
```

**Returns:** `{r, g, b}` table

---

#### `clear(displayId, r, g, b)`
Fills the entire display with a solid color.

```lua
gpu.clear(display, 0, 0, 0)  -- Clear to black
```

---

#### `drawRect(displayId, x, y, width, height, r, g, b)`
Draws a filled rectangle.

```lua
gpu.drawRect(display, 10, 10, 100, 50, 255, 0, 0)
```

**Parameters:**
- `x`, `y`: Top-left corner position
- `width`, `height`: Rectangle dimensions
- `r`, `g`, `b`: Fill color

---

#### `drawLine(displayId, x1, y1, x2, y2, r, g, b)`
Draws a line between two points using Bresenham's algorithm.

```lua
gpu.drawLine(display, 0, 0, 163, 80, 255, 255, 255)
```

---

#### `loadImage(displayId, base64Data)`
Loads a PNG or JPEG image from Base64-encoded data. The image is automatically scaled to fit the display with letterboxing.

```lua
local imageData = "iVBORw0KGgo..."  -- Base64 string
gpu.loadImage(display, imageData)
```

**Note:** The Java backend handles scaling and aspect ratio preservation automatically.

---

#### `updateDisplay(displayId)`
Marks the display as dirty, triggering a render update on the next frame.

```lua
gpu.setPixel(display, 10, 10, 255, 0, 0)
gpu.updateDisplay(display)  -- Force render
```

**Performance Tip:** Batch multiple drawing operations before calling `updateDisplay()`.

---

### Touch Input

Touch input captures mouse clicks and keyboard events when you interact with the physical monitor blocks in the world.

#### `pullEvent(displayId)` → `event` or `nil`
Retrieves the next input event from the queue.

```lua
local event = {gpu.pullEvent(display)}
if event then
    print("Event type: " .. event[1])
end
```

**Returns:** `nil` if no events are available

**Event Types:**

**Mouse Click (Left Button):**
```lua
{"mouse_click", x, y, button}
```

**Mouse Click (Right Button):**
```lua
{"mouse_click_right", x, y, button}
```

**Mouse Drag (Left):**
```lua
{"mouse_drag", x, y, button}
```

**Mouse Drag (Right):**
```lua
{"mouse_drag_right", x, y, button}
```

**Mouse Release (Left):**
```lua
{"mouse_up", x, y, button}
```

**Mouse Release (Right):**
```lua
{"mouse_up_right", x, y, button}
```

**Key Press:**
```lua
{"key", keyName}
```

**Character Typed:**
```lua
{"char", character}
```

**Event Parameters:**
- `x`, `y`: Pixel coordinates (0-indexed, top-left origin)
- `button`: Mouse button (1=left, 2=right, 3=middle)
- `keyName`: CC key name (e.g., `"enter"`, `"space"`, `"a"`)
- `character`: Typed character string

---

#### `hasEvent(displayId)` → `boolean`
Checks if there are pending events without removing them.

```lua
if gpu.hasEvent(display) then
    local event = {gpu.pullEvent(display)}
    -- Process event
end
```

---

#### `clearEvents(displayId)`
Clears all pending events from the queue.

```lua
gpu.clearEvents(display)
```

---

#### `sendKey(displayId, keyName)`
Programmatically injects a key event into the display's event queue.

```lua
gpu.sendKey(display, "enter")
```

---

#### `sendChar(displayId, character)`
Programmatically injects a character event.

```lua
gpu.sendChar(display, "A")
```

---

### Utilities

#### `autoDetectMonitor()` → `info`
Scans for the nearest monitor within 16 blocks.

```lua
local monitor = gpu.autoDetectMonitor()
if monitor.found then
    print(string.format("Found %dx%d monitor at (%d, %d, %d)", 
        monitor.width, monitor.height, monitor.x, monitor.y, monitor.z))
end
```

**Returns:**
```lua
{
    found = true,
    x = 100,
    y = 64,
    z = 200,
    width = 3,
    height = 2,
    facing = "north"
}
```

---

#### `getStats()` → `stats`
Returns system statistics.

```lua
local stats = gpu.getStats()
print("Active displays: " .. stats.displays)
print("Total pixels: " .. stats.totalPixels)
```

---

## Examples

### Gradient Background

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.createDisplayAuto()
local info = gpu.getDisplayInfo(display)

for y = 0, info.pixelHeight - 1 do
    for x = 0, info.pixelWidth - 1 do
        local r = math.floor((x / info.pixelWidth) * 255)
        local g = math.floor((y / info.pixelHeight) * 255)
        local b = 128
        gpu.setPixel(display, x, y, r, g, b)
    end
    
    -- Update every 20 rows for smoother rendering
    if y % 20 == 0 then
        gpu.updateDisplay(display)
    end
end

gpu.updateDisplay(display)
```

---

### Interactive Paint Program

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.createDisplayAuto()

-- Clear to white canvas
gpu.clear(display, 255, 255, 255)
gpu.updateDisplay(display)

print("Draw on the monitor!")
print("Close this terminal and click on the monitor blocks")
print("Press Ctrl+T in terminal to exit")

local lastX, lastY = nil, nil
local running = true

parallel.waitForAny(
    function()
        while running do
            if gpu.hasEvent(display) then
                local event = {gpu.pullEvent(display)}
                
                if event[1] == "mouse_click" then
                    local x, y = event[2], event[3]
                    -- Draw dot
                    gpu.drawRect(display, x-3, y-3, 7, 7, 0, 0, 0)
                    lastX, lastY = x, y
                    gpu.updateDisplay(display)
                    
                elseif event[1] == "mouse_drag" then
                    local x, y = event[2], event[3]
                    -- Draw line from last position
                    if lastX and lastY then
                        gpu.drawLine(display, lastX, lastY, x, y, 0, 0, 0)
                        gpu.updateDisplay(display)
                    end
                    lastX, lastY = x, y
                    
                elseif event[1] == "mouse_up" then
                    lastX, lastY = nil, nil
                end
            else
                sleep(0.05)
            end
        end
    end,
    function()
        os.pullEvent("terminate")
        running = false
    end
)

gpu.clearDisplay()
```

---

### Button UI

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.createDisplayAuto()

-- Define button
local button = {
    x = 50, y = 50,
    width = 120, height = 50,
    color = {100, 150, 255},
    hoverColor = {120, 170, 255},
    clickColor = {255, 200, 100}
}

-- Draw function
local function drawButton(color)
    gpu.clear(display, 220, 220, 220)
    gpu.drawRect(display, button.x, button.y, button.width, button.height, 
                 color[1], color[2], color[3])
    gpu.updateDisplay(display)
end

-- Initial draw
drawButton(button.color)
print("Click the blue button on the monitor!")

-- Event loop
while true do
    if gpu.hasEvent(display) then
        local event = {gpu.pullEvent(display)}
        
        if event[1] == "mouse_click" then
            local x, y = event[2], event[3]
            
            -- Check if click is inside button
            if x >= button.x and x < button.x + button.width and
               y >= button.y and y < button.y + button.height then
                
                print("Button clicked!")
                
                -- Flash animation
                drawButton(button.clickColor)
                sleep(0.15)
                drawButton(button.color)
            end
        end
    end
    sleep(0.05)
end
```

---

### Webcam Streamer

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.createDisplayAuto()
local info = gpu.getDisplayInfo(display)

print("Webcam Viewer - " .. info.pixelWidth .. "x" .. info.pixelHeight)

local CAMERA_URL = "http://example.com/camera.jpg"
local TARGET_FPS = 5

-- Base64 encoding function
local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function encodeBase64(data)
    local result = {}
    for i = 1, #data, 3 do
        local b1, b2, b3 = data:byte(i, i+2)
        b2 = b2 or 0
        b3 = b3 or 0
        local n = b1 * 65536 + b2 * 256 + b3
        table.insert(result, b64chars:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1))
        table.insert(result, b64chars:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1))
        table.insert(result, b64chars:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1))
        table.insert(result, b64chars:sub(n%64+1, n%64+1))
    end
    local padding = (3 - (#data % 3)) % 3
    for i = 1, padding do
        result[#result - i + 1] = "="
    end
    return table.concat(result)
end

local function fetchFrame()
    local url = CAMERA_URL .. "?t=" .. os.epoch("utc")
    local handle = http.get(url, {}, true)  -- Binary mode
    
    if not handle then return false end
    
    local imageData = handle.readAll()
    handle.close()
    
    if #imageData < 100 then return false end
    
    local base64Data = encodeBase64(imageData)
    gpu.loadImage(display, base64Data)
    gpu.updateDisplay(display)
    
    return true
end

print("Streaming... Press Q to quit")

local running = true
parallel.waitForAny(
    function()
        while running do
            local start = os.epoch("utc") / 1000
            fetchFrame()
            local elapsed = (os.epoch("utc") / 1000) - start
            local wait = math.max(0, (1 / TARGET_FPS) - elapsed)
            sleep(wait)
        end
    end,
    function()
        while running do
            local event, key = os.pullEvent("key")
            if key == keys.q then
                running = false
            end
        end
    end
)

gpu.clearDisplay()
```

---

## Touch Input Usage

**Important:** Touch input only works when **not** in any GUI:

1. Run your Lua script in the CC computer
2. **Close the terminal** (press E or Esc)
3. Look at the physical monitor blocks in the world
4. Click directly on the monitor to interact

Touch events use 3D raycasting against the rendered display surface. The input system automatically handles:
- Left and right mouse buttons
- Click, drag, and release events
- Coordinate translation to pixel space
- Event queuing per display

**Coordinate System:**
- Origin (0, 0) is at the **top-left** corner
- X increases to the **right**
- Y increases **downward**
- Coordinates are in pixels, not blocks

---

## Performance Tips

1. **Batch drawing operations** - Call `updateDisplay()` once after multiple changes
2. **Use primitives** - `drawRect()` and `drawLine()` are faster than individual pixels
3. **Limit updates** - Don't call `updateDisplay()` more than 60 times per second
4. **Clear efficiently** - Use `clear()` instead of drawing black pixels
5. **Event polling** - Add `sleep()` between event checks to reduce CPU usage
6. **Keep displays nearby** - Maximum render distance is 64 blocks
7. **Clean up** - Always call `clearDisplay()` when done

---

## Technical Specifications

| Specification | Value |
|--------------|-------|
| Resolution per block | 164×81 pixels |
| Color depth | 24-bit RGB (8 bits/channel) |
| Maximum monitor size | 8×6 blocks |
| Maximum total displays | 50 |
| Maximum total pixels | 10 megapixels |
| Render distance | 64 blocks |
| Memory per 1×1 display | ~40 KB |
| Texture update rate | Limited to 60 FPS |
| Input latency | Sub-tick (<50ms) |

---

## Troubleshooting

### "Display not found" error
- Ensure the monitor exists at the specified coordinates
- Use `autoDetectMonitor()` to verify monitor detection
- Check that monitors form a complete rectangle

### Touch input not working
- Close the CC computer terminal first
- Make sure you're clicking on the physical monitor blocks in world
- Verify the display ID is correct
- Check `hasEvent()` returns true before calling `pullEvent()`

### Low FPS or stuttering
- Reduce update frequency in your script
- Use smaller monitor arrays
- Batch drawing operations
- Check CPU usage with `/forge tps`

### Image not loading
- Verify Base64 data is valid
- Check image format is PNG or JPEG
- Ensure image data isn't truncated
- Try a smaller test image first

---

## Credits

**Author:** Tom (GitHub: @tiktop101)  
**Minecraft Version:** 1.20.1  
**Forge Version:** 47.x.x  
**ComputerCraft:** CC: Tweaked

## License

This project is licensed under the ARR License.

---

## Support

- **Issues:** Report bugs on GitHub Issues
- **Discord:** Join the Minecraft Computer Mods Discord Server

**Enjoy creating amazing graphics in ComputerCraft!** 🎨
