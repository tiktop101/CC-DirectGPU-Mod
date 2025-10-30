# DirectGPU

A high-performance ComputerCraft peripheral for Minecraft that enables hardware-accelerated graphics rendering directly to monitors. Stream images, create interactive UIs, or build pixel art - all at up to 656×324 resolution per block with 4x scaling.

## Features

- **True RGB Graphics** - 24-bit color with 164×81 pixels per monitor block (up to 656×324 with 4x resolution multiplier)
- **Hardware Accelerated** - OpenGL rendering bypasses CC's text system for maximum performance
- **Touch Input** - Full mouse click, drag, and keyboard event support with sub-tick latency
- **Auto-Detection** - Automatically finds and configures nearby monitors in any orientation
- **Drawing Primitives** - Fast lines, rectangles, and pixel-perfect rendering
- **Image Support** - Load JPEG images with hardware decoding (~5ms per frame)
- **Dictionary Compression** - Intelligent chunk-based caching reduces bandwidth by 90%+ for video
- **Flexible Sizing** - Works with any monitor array up to 16×16 blocks
- **Multi-Display** - Up to 50 displays with 10 megapixel total limit
- **Thread-Safe** - Safe concurrent access from multiple computers

## Installation

1. Download the latest DirectGPU JAR from releases
2. Place in your Minecraft `mods` folder
3. Ensure you have **Forge** and **CC: Tweaked** installed
4. Craft the DirectGPU block (see recipe below)
5. Launch Minecraft and enjoy!

### Crafting Recipe

```
[Iron] [Gold] [Iron]
[Redstone] [Computer] [Redstone]
[Iron] [Redstone] [Iron]
```

**Materials:**
- 4× Iron Ingots
- 1× Gold Ingot
- 3× Redstone Dust
- 1× ComputerCraft Computer (normal)

## Quick Start

```lua
-- Find the DirectGPU peripheral
local gpu = peripheral.find("directgpu")

-- Auto-detect and create a display on the nearest monitor
local display = gpu.autoDetectAndCreateDisplay()

-- Get display dimensions
local info = gpu.getDisplayInfo(display)
print(string.format("Display: %dx%d pixels", info.pixelWidth, info.pixelHeight))

-- Clear to blue and draw a red square
gpu.clear(display, 0, 100, 200)
gpu.fillRect(display, 10, 10, 50, 50, 255, 0, 0)
gpu.updateDisplay(display)

-- Clean up when done
gpu.clearAllDisplays()
```

## How It Works

DirectGPU creates a peripheral accessible via wired modems. When you call `createDisplay()`, it:

1. Finds monitor blocks in the world at specified coordinates
2. Creates an OpenGL texture matching the monitor array size
3. Renders the texture directly onto the monitor blocks in 3D space
4. Captures mouse clicks via raycasting against the rendered surface

This approach provides dramatically higher resolution and performance compared to CC's built-in text-based rendering.

---

## API Reference

### Display Management

#### `autoDetectMonitor()` → info

Scans for the nearest monitor within 16 blocks and returns its configuration.

```lua
local monitor = gpu.autoDetectMonitor()
if monitor.found then
    print(string.format("Found %dx%d monitor at (%d, %d, %d)", 
        monitor.width, monitor.height, monitor.x, monitor.y, monitor.z))
    print("Facing: " .. monitor.facing)
end
```

**Returns:**
```lua
{
    found = true,      -- Boolean: whether a monitor was found
    x = 100,          -- World X coordinate of bottom-left corner
    y = 64,           -- World Y coordinate of bottom-left corner
    z = 200,          -- World Z coordinate of bottom-left corner
    width = 3,        -- Width in blocks
    height = 2,       -- Height in blocks
    facing = "north"  -- Direction the monitor is facing
}
```

**Notes:**
- Automatically detects monitor orientation (north, south, east, west)
- Finds complete rectangular monitor arrays only
- Returns `{found = false}` if no monitor found

---

#### `autoDetectAndCreateDisplay()` → displayId

Automatically detects the nearest monitor and creates a display at 1x resolution.

```lua
local display = gpu.autoDetectAndCreateDisplay()
print("Created display: " .. display)
```

**Returns:** Display ID (number)  
**Throws:** Error if no monitor is found within 16 blocks

---

#### `autoDetectAndCreateDisplayWithResolution(resolutionMultiplier)` → displayId

Same as above but with custom resolution scaling.

```lua
-- Create a 2x resolution display (328x162 pixels per block)
local display = gpu.autoDetectAndCreateDisplayWithResolution(2)

-- Maximum 4x resolution (656x324 pixels per block)
local display = gpu.autoDetectAndCreateDisplayWithResolution(4)
```

**Parameters:**
- `resolutionMultiplier` (number): Resolution scale factor (1-4)
  - `1` = 164×81 per block (default)
  - `2` = 328×162 per block
  - `3` = 492×243 per block
  - `4` = 656×324 per block

**Returns:** Display ID  
**Throws:** Error if multiplier is out of range or no monitor found

**Performance Note:** Higher resolutions consume more memory and bandwidth. Use 2x for HD content, 4x only for small displays.

---

#### `createDisplay(x, y, z, facing, width, height)` → displayId

Creates a display at specific world coordinates with 1x resolution.

```lua
local display = gpu.createDisplay(100, 64, 200, "south", 4, 3)
```

**Parameters:**
- `x, y, z` (number): World coordinates of bottom-left corner
- `facing` (string): Direction - "north", "south", "east", "west", "up", "down"
- `width` (number): Monitor width in blocks (1-16)
- `height` (number): Monitor height in blocks (1-16)

**Returns:** Display ID

---

#### `createDisplayAt(x, y, z, facing, width, height)` → displayId

Alias for `createDisplay()`. Identical functionality.

---

#### `createDisplayWithResolution(x, y, z, facing, width, height, resolutionMultiplier)` → displayId

Creates a display with custom resolution scaling.

```lua
-- 3x2 monitor array at 2x resolution
local display = gpu.createDisplayWithResolution(100, 64, 200, "south", 3, 2, 2)
```

**Parameters:**
- `x, y, z, facing, width, height`: Same as `createDisplay()`
- `resolutionMultiplier` (number): Resolution scale (1-4)

**Returns:** Display ID  
**Throws:** Error if parameters are invalid or resource limits exceeded

---

#### `removeDisplay(displayId)` → success

Removes a specific display and frees its resources.

```lua
local success = gpu.removeDisplay(display)
if success then
    print("Display removed")
end
```

**Returns:** `true` if successful, `false` if display doesn't exist

---

#### `clearAllDisplays()`

Removes all displays created by this DirectGPU block.

```lua
gpu.clearAllDisplays()
```

**Note:** Automatically called when the DirectGPU block is broken.

---

#### `listDisplays()` → displayIds

Returns a list of all active display IDs.

```lua
local displays = gpu.listDisplays()
for _, id in ipairs(displays) do
    print("Display: " .. id)
end
```

**Returns:** Array of display IDs (numbers)

---

#### `getDisplayInfo(displayId)` → info

Returns detailed information about a display.

```lua
local info = gpu.getDisplayInfo(display)
print(string.format("%dx%d pixels (%dx resolution)", 
    info.pixelWidth, info.pixelHeight, info.resolutionMultiplier))
```

**Returns:**
```lua
{
    id = 0,                  -- Display ID
    x = 100,                 -- World X coordinate
    y = 64,                  -- World Y coordinate  
    z = 200,                 -- World Z coordinate
    facing = "north",        -- Direction
    width = 3,               -- Width in blocks
    height = 2,              -- Height in blocks
    pixelWidth = 492,        -- Width in pixels (width * 164 * multiplier)
    pixelHeight = 162,       -- Height in pixels (height * 81 * multiplier)
    resolutionMultiplier = 1 -- Resolution scale factor (1-4)
}
```

---

#### `getResourceStats()` → stats

Returns system resource usage statistics.

```lua
local stats = gpu.getResourceStats()
print(string.format("Displays: %d/%d", stats.displays, stats.maxDisplays))
print(string.format("Pixels: %.1fM / %.1fM (%.1f%%)", 
    stats.totalPixels/1e6, stats.maxTotalPixels/1e6, stats.pixelUsagePercent))
```

**Returns:**
```lua
{
    displays = 3,              -- Current number of displays
    maxDisplays = 50,          -- Maximum allowed displays
    totalPixels = 2500000,     -- Total pixels across all displays
    maxTotalPixels = 10000000, -- Maximum total pixels allowed
    pixelUsagePercent = 25.0   -- Percentage of pixel budget used
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
- `x, y` (number): Pixel coordinates (0-indexed from top-left)
- `r, g, b` (number): RGB color values (0-255)

**Note:** Does not automatically update the display. Call `updateDisplay()` to render.

---

#### `getPixel(displayId, x, y)` → color

Returns the RGB color of a pixel.

```lua
local r, g, b = table.unpack(gpu.getPixel(display, 100, 50))
print(string.format("RGB: %d, %d, %d", r, g, b))
```

**Returns:** Array `{r, g, b}` with values 0-255

---

#### `clear(displayId, r, g, b)`

Fills the entire display with a solid color.

```lua
gpu.clear(display, 0, 0, 0)  -- Clear to black
gpu.clear(display, 255, 255, 255)  -- Clear to white
```

**Parameters:**
- `r, g, b` (number): RGB fill color (0-255)

**Note:** Automatically marks display as dirty. Still need to call `updateDisplay()`.

---

#### `fillRect(displayId, x, y, width, height, r, g, b)`

Draws a filled rectangle.

```lua
-- Draw a 100x50 red rectangle at (10, 10)
gpu.fillRect(display, 10, 10, 100, 50, 255, 0, 0)
```

**Parameters:**
- `x, y` (number): Top-left corner position
- `width, height` (number): Rectangle dimensions in pixels
- `r, g, b` (number): Fill color (0-255)

---

#### `drawLine(displayId, x1, y1, x2, y2, r, g, b)`

Draws a line between two points using Bresenham's algorithm.

```lua
-- Draw white diagonal line
gpu.drawLine(display, 0, 0, 163, 80, 255, 255, 255)
```

**Parameters:**
- `x1, y1` (number): Start point coordinates
- `x2, y2` (number): End point coordinates
- `r, g, b` (number): Line color (0-255)

---

#### `updateDisplay(displayId)`

Marks the display as dirty, triggering a render update on the next frame.

```lua
gpu.setPixel(display, 10, 10, 255, 0, 0)
gpu.setPixel(display, 11, 10, 255, 0, 0)
gpu.updateDisplay(display)  -- Render all changes
```

**Performance Tip:** Batch multiple drawing operations before calling `updateDisplay()`. The renderer limits updates to ~60 FPS for smooth performance.

---

### Image Loading

#### `loadImage(displayId, imageData)`

Loads an image from a Lua table in nested or flat pixel format. Automatically scales to fit display with aspect ratio preservation.

```lua
local imageData = {
    width = 100,
    height = 100,
    pixels = {
        {{255, 0, 0}, {0, 255, 0}, ...},  -- Row 1
        {{0, 0, 255}, {255, 255, 0}, ...}, -- Row 2
        ...
    }
}

gpu.loadImage(display, imageData)
gpu.updateDisplay(display)
```

**Supported Formats:**

1. **Nested List Format:**
```lua
pixels = {
    {{r, g, b}, {r, g, b}, ...},  -- Row 1
    {{r, g, b}, {r, g, b}, ...},  -- Row 2
    ...
}
```

2. **Flat Array Format:**
```lua
pixels = {r, g, b, r, g, b, r, g, b, ...}  -- Single array
```

3. **Lua Table Format (1-indexed):**
```lua
pixels = {
    [1] = {[1] = {r, g, b}, [2] = {r, g, b}, ...},
    [2] = {[1] = {r, g, b}, [2] = {r, g, b}, ...},
    ...
}
```

**Note:** Does not call `updateDisplay()` automatically.

---

#### `decodeJPEG(jpegData)` → result

Decodes a JPEG image from binary data. Returns pixel data for manual processing.

```lua
local handle = http.get("http://example.com/image.jpg", {}, true)
local jpegData = handle.readAll()
handle.close()

local result = gpu.decodeJPEG(jpegData)
print(string.format("Decoded: %dx%d in %dms", 
    result.width, result.height, result.decodeTime))

-- result.pixels is a byte array (flat RGB format)
```

**Parameters:**
- `jpegData` (string): Binary JPEG data (use `http.get(..., {}, true)` for binary mode)

**Returns:**
```lua
{
    width = 640,           -- Image width in pixels
    height = 480,          -- Image height in pixels
    pixels = "\xFF\x00...", -- Flat RGB byte array (width * height * 3 bytes)
    decodeTime = 5         -- Decode time in milliseconds
}
```

**Performance:** ~5-15ms for typical webcam images (640×480)

---

#### `decodeAndScaleJPEG(jpegData, targetWidth, targetHeight)` → result

Decodes and scales a JPEG in one optimized operation.

```lua
local info = gpu.getDisplayInfo(display)
local result = gpu.decodeAndScaleJPEG(jpegData, info.pixelWidth, info.pixelHeight)

print(string.format("Scaled %dx%d -> %dx%d in %dms",
    result.originalWidth, result.originalHeight,
    result.width, result.height,
    result.decodeTime))
```

**Parameters:**
- `jpegData` (string): Binary JPEG data
- `targetWidth, targetHeight` (number): Target dimensions

**Returns:**
```lua
{
    width = 164,            -- Scaled width
    height = 81,            -- Scaled height
    pixels = "...",         -- Scaled RGB byte array
    originalWidth = 640,    -- Original image width
    originalHeight = 480,   -- Original image height
    decodeTime = 8          -- Total decode+scale time (ms)
}
```

**Performance:** Faster than decode + scale separately. Use for real-time video.

---

#### `getJPEGDimensions(jpegData)` → dimensions

Gets JPEG dimensions without full decode (very fast, <1ms).

```lua
local dims = gpu.getJPEGDimensions(jpegData)
print(string.format("Image: %dx%d", dims.width, dims.height))
```

**Returns:** `{width = number, height = number}`

---

#### `loadJPEGRegion(displayId, jpegData, x, y, width, height)`

Decodes a JPEG and blits it to a specific region of the display. Does NOT call `updateDisplay()`.

```lua
-- Load webcam frame into top-left corner
gpu.loadJPEGRegion(display, jpegData, 0, 0, 320, 240)
gpu.updateDisplay(display)  -- Must call this to render
```

**Parameters:**
- `jpegData` (string): Binary JPEG data
- `x, y` (number): Destination position on display
- `width, height` (number): Region size (JPEG will be scaled to this size)

**Use Case:** Compositing multiple images or video windows on one display.

---

### Dictionary Compression

DirectGPU includes a high-performance dictionary compression system that caches 8KB chunks by hash. This is **extremely efficient for video streaming** - typically 90%+ cache hit rate after the first frame.

#### `compressWithDict(data)` → stats

Compresses binary data using dictionary-based chunking.

```lua
local handle = http.get("http://example.com/image.jpg", {}, true)
local jpegData = handle.readAll()
handle.close()

local stats = gpu.compressWithDict(jpegData)
print(string.format("Chunks: %d total, %d new, %d cached (%.1f%% savings)",
    stats.totalChunks, stats.newChunks, stats.cachedChunks,
    (stats.cachedChunks / stats.totalChunks) * 100))
```

**Returns:**
```lua
{
    hashes = {12345, 67890, ...},  -- Array of chunk hashes
    totalChunks = 120,              -- Total 8KB chunks
    newChunks = 12,                 -- New chunks added to dictionary
    cachedChunks = 108,             -- Chunks already in dictionary
    chunkSize = 8192                -- Bytes per chunk
}
```

**How It Works:**
1. Splits data into 8KB chunks
2. Computes CRC32 hash for each chunk
3. Checks if chunk exists in dictionary
4. Only sends new/changed chunks
5. Reconstructs full data from hashes

**Result:** 90%+ bandwidth reduction for video after first frame!

---

#### `decompressFromDict(hashes)` → data

Reconstructs data from chunk hashes.

```lua
local originalData = gpu.decompressFromDict(stats.hashes)
```

**Parameters:**
- `hashes` (array): Array of chunk hashes from `compressWithDict()`

**Returns:** Binary string (reconstructed data)  
**Throws:** Error if any chunk is missing from dictionary

---

#### `hasChunk(hash)` → boolean

Checks if a chunk exists in the dictionary.

```lua
if gpu.hasChunk(12345) then
    print("Chunk cached")
end
```

---

#### `getChunk(hash)` → data

Retrieves a chunk by its hash.

```lua
local chunkData = gpu.getChunk(12345)
```

**Returns:** Binary string (8KB or less)  
**Throws:** Error if chunk doesn't exist

---

#### `getDictionaryStats()` → stats

Returns dictionary statistics.

```lua
local stats = gpu.getDictionaryStats()
print(string.format("Dictionary: %d/%d chunks (%.1f MB)",
    stats.dictionarySize, stats.maxDictionarySize, stats.totalMB))
```

**Returns:**
```lua
{
    dictionarySize = 5000,      -- Current chunks in dictionary
    maxDictionarySize = 10000,  -- Maximum chunks (then LRU eviction)
    chunkSize = 8192,           -- Bytes per chunk
    totalBytes = 40960000,      -- Total bytes cached
    totalMB = 39.1              -- Total MB cached
}
```

---

#### `clearDictionary()`

Clears all chunks from the dictionary.

```lua
gpu.clearDictionary()
```

**Use Case:** Free memory or reset compression state.

---

### Touch Input

Touch input captures mouse and keyboard events when you interact with the physical monitor blocks in the world.

**Important:** Touch input only works when NOT in any GUI. Close the CC terminal and click directly on the monitor blocks.

#### `hasEvents(displayId)` → boolean

Checks if there are pending input events.

```lua
if gpu.hasEvents(display) then
    local event = gpu.pollEvent(display)
    -- Process event
end
```

---

#### `pollEvent(displayId)` → event

Retrieves and removes the next input event from the queue.

```lua
local event = gpu.pollEvent(display)
if event then
    print("Event type: " .. event.type)
    print("Position: " .. event.x .. ", " .. event.y)
end
```

**Returns:** `nil` if no events available

**Event Object:**
```lua
{
    type = "mouse_click",  -- Event type (see below)
    x = 50,                -- Pixel X coordinate (0-indexed)
    y = 30,                -- Pixel Y coordinate (0-indexed)
    button = 1,            -- Mouse button (1=left, 2=right)
    key = "enter",         -- Key name (for key events)
    character = "A"        -- Character (for char events)
}
```

**Event Types:**

| Type | Description | Fields |
|------|-------------|--------|
| `mouse_click` | Left mouse button pressed | `x, y, button` |
| `mouse_click_right` | Right mouse button pressed | `x, y, button` |
| `mouse_drag` | Left button dragged | `x, y, button` |
| `mouse_drag_right` | Right button dragged | `x, y, button` |
| `mouse_up` | Left button released | `x, y, button` |
| `mouse_up_right` | Right button released | `x, y, button` |
| `key` | Keyboard key pressed | `key` |
| `char` | Character typed | `character` |

---

#### `clearEvents(displayId)`

Clears all pending events from the queue.

```lua
gpu.clearEvents(display)
```

---

#### `sendKeyEvent(displayId, type, key, character)`

Programmatically injects a keyboard event into the display's queue.

```lua
-- Send "enter" key press
gpu.sendKeyEvent(display, "key", "enter", nil)

-- Send character
gpu.sendKeyEvent(display, "char", nil, "A")
```

**Parameters:**
- `type` (string): "key" or "char"
- `key` (string): CC key name (e.g., "enter", "space", "a")
- `character` (string): Typed character

---

## Examples

### Gradient Background

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplay()
local info = gpu.getDisplayInfo(display)

for y = 0, info.pixelHeight - 1 do
    for x = 0, info.pixelWidth - 1 do
        local r = math.floor((x / info.pixelWidth) * 255)
        local g = math.floor((y / info.pixelHeight) * 255)
        local b = 128
        gpu.setPixel(display, x, y, r, g, b)
    end
    
    -- Update every 20 rows for smooth rendering
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
local display = gpu.autoDetectAndCreateDisplay()

-- Clear to white canvas
gpu.clear(display, 255, 255, 255)
gpu.updateDisplay(display)

print("Draw on the monitor! Press Ctrl+T to exit")

local lastX, lastY = nil, nil
local running = true

parallel.waitForAny(
    function()
        while running do
            if gpu.hasEvents(display) then
                local event = gpu.pollEvent(display)
                
                if event.type == "mouse_click" then
                    -- Draw dot
                    gpu.fillRect(display, event.x-3, event.y-3, 7, 7, 0, 0, 0)
                    lastX, lastY = event.x, event.y
                    gpu.updateDisplay(display)
                    
                elseif event.type == "mouse_drag" then
                    -- Draw line from last position
                    if lastX and lastY then
                        gpu.drawLine(display, lastX, lastY, event.x, event.y, 0, 0, 0)
                        gpu.updateDisplay(display)
                    end
                    lastX, lastY = event.x, event.y
                    
                elseif event.type == "mouse_up" then
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

gpu.clearAllDisplays()
```

---

### Button UI

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplay()

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
    gpu.fillRect(display, button.x, button.y, button.width, button.height, 
                 color[1], color[2], color[3])
    gpu.updateDisplay(display)
end

-- Initial draw
drawButton(button.color)
print("Click the blue button!")

-- Event loop
while true do
    if gpu.hasEvents(display) then
        local event = gpu.pollEvent(display)
        
        if event.type == "mouse_click" then
            -- Check if click is inside button
            if event.x >= button.x and event.x < button.x + button.width and
               event.y >= button.y and event.y < button.y + button.height then
                
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

### High-Performance Webcam Streamer

**Simple Version (HTTP + JPEG):**

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplayWithResolution(2)  -- 2x for better quality
local info = gpu.getDisplayInfo(display)

print("Webcam Viewer - " .. info.pixelWidth .. "x" .. info.pixelHeight)

local CAMERA_URL = "http://example.com/webcam.jpg"
local TARGET_FPS = 10

local function fetchFrame()
    local url = CAMERA_URL .. "?t=" .. os.epoch("utc")
    local handle = http.get(url, {}, true)  -- Binary mode
    
    if not handle then return false end
    
    local jpegData = handle.readAll()
    handle.close()
    
    if #jpegData < 100 then return false end
    
    -- Decode and scale in one operation
    local result = gpu.decodeAndScaleJPEG(jpegData, info.pixelWidth, info.pixelHeight)
    
    -- Load to display
    gpu.loadJPEGRegion(display, jpegData, 0, 0, info.pixelWidth, info.pixelHeight)
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
            sleep(math.max(0, (1/TARGET_FPS) - elapsed))
        end
    end,
    function()
        while running do
            local event, key = os.pullEvent("key")
            if key == keys.q then running = false end
        end
    end
)

gpu.clearAllDisplays()
```

**Advanced Version (Dictionary Compression):**

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplay()

local CAMERA_URL = "http://example.com/webcam.jpg"
local frameCount = 0
local totalCacheHits = 0

local function fetchFrame()
    local handle = http.get(CAMERA_URL .. "?t=" .. os.epoch("utc"), {}, true)
    if not handle then return false end
    
    local jpegData = handle.readAll()
    handle.close()
    
    -- Compress with dictionary
    local stats = gpu.compressWithDict(jpegData)
    local cacheHitRate = (stats.cachedChunks / stats.totalChunks) * 100
    
    -- Decompress and load
    local decompressed = gpu.decompressFromDict(stats.hashes)
    gpu.loadJPEGRegion(display, decompressed, 0, 0, 
        gpu.getDisplayInfo(display).pixelWidth,
        gpu.getDisplayInfo(display).pixelHeight)
    gpu.updateDisplay(display)
    
    frameCount = frameCount + 1
    totalCacheHits = totalCacheHits + cacheHitRate
    
    if frameCount % 30 == 0 then
        print(string.format("Avg cache hit: %.1f%%", totalCacheHits / frameCount))
    end
    
    return true
end

-- Stream loop
local running = true
parallel.waitForAny(
    function()
        while running do
            fetchFrame()
            sleep(0.1)  -- 10 FPS
        end
    end,
    function()
        os.pullEvent("terminate")
        running = false
    end
)

gpu.clearAllDisplays()
```

---

### Multi-Display Dashboard

```lua
local gpu = peripheral.find("directgpu")

-- Create 2x2 grid of displays
local displays = {}
for y = 0, 1 do
    for x = 0, 1 do
        local id = gpu.createDisplay(100 + x*3, 64 + y*2, 200, "south", 3, 2)
        table.insert(displays, id)
    end
end

-- Draw different content on each
local colors = {
    {255, 0, 0},    -- Red
    {0, 255, 0},    -- Green
    {0, 0, 255},    -- Blue
    {255, 255, 0}   -- Yellow
}

for i, display in ipairs(displays) do
    local color = colors[i]
    gpu.clear(display, color[1], color[2], color[3])
    gpu.updateDisplay(display)
end

print("Multi-display dashboard running!")
sleep(10)

-- Clean up all displays
gpu.clearAllDisplays()
```

---

### Image Slideshow

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplayWithResolution(2)

local images = {
    "http://example.com/image1.jpg",
    "http://example.com/image2.jpg",
    "http://example.com/image3.jpg"
}

print("Slideshow starting...")

for i, url in ipairs(images) do
    print("Loading image " .. i .. "...")
    
    local handle = http.get(url, {}, true)
    if handle then
        local jpegData = handle.readAll()
        handle.close()
        
        local info = gpu.getDisplayInfo(display)
        gpu.loadJPEGRegion(display, jpegData, 0, 0, info.pixelWidth, info.pixelHeight)
        gpu.updateDisplay(display)
        
        sleep(3)  -- Show for 3 seconds
    end
end

gpu.clearAllDisplays()
```

---

### Real-Time FPS Counter

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplay()

local frameCount = 0
local lastTime = os.epoch("utc")
local fps = 0

-- Simple animation loop
while true do
    -- Clear and draw frame number
    gpu.clear(display, 0, 0, 0)
    
    -- Draw FPS text (simple pixel art)
    local text = string.format("FPS: %.1f", fps)
    -- (You'd implement text rendering here)
    
    gpu.updateDisplay(display)
    
    -- Calculate FPS
    frameCount = frameCount + 1
    local now = os.epoch("utc")
    if now - lastTime >= 1000 then
        fps = frameCount
        frameCount = 0
        lastTime = now
        print("Current FPS: " .. fps)
    end
    
    sleep(0)  -- Yield to system
end
```

---

## Performance Tips

### Drawing Optimization

- **Batch operations** - Call `updateDisplay()` once after multiple drawing calls
- **Use primitives** - `fillRect()` and `drawLine()` are faster than individual `setPixel()` calls
- **Limit update rate** - Don't call `updateDisplay()` more than 60 times per second (renderer enforces this)
- **Clear efficiently** - Use `clear()` instead of drawing individual black pixels

### Memory Management

- **Clean up displays** - Always call `clearAllDisplays()` when done
- **Monitor pixel budget** - Use `getResourceStats()` to track usage
- **Use appropriate resolution** - Higher multipliers consume more memory and bandwidth
  - 1x: ~40 KB per monitor block
  - 2x: ~160 KB per monitor block
  - 4x: ~640 KB per monitor block

### Image/Video Streaming

- **Use JPEG for photos** - Smaller file size, hardware-accelerated decode
- **Use dictionary compression for video** - 90%+ bandwidth reduction after first frame
- **Binary HTTP mode** - Always use `http.get(url, {}, true)` for images
- **Cache-busting** - Add random query params to prevent server caching: `url .. "?t=" .. os.epoch("utc")`
- **Scale on server** - Pre-scale images to target resolution before streaming
- **Target 10-15 FPS** - Good balance between smooth video and performance

### Input Handling

- **Add sleep() in event loops** - Prevent CPU overload: `sleep(0.05)` between checks
- **Use hasEvents()** - Check before calling `pollEvent()` to avoid unnecessary calls
- **Clear old events** - Call `clearEvents()` when switching UI states
- **Batch event processing** - Process multiple events per frame for responsiveness

### Network Optimization

- **Use WebSockets** - For real-time streaming (if available in your CC version)
- **Compress before sending** - Use dictionary compression for repeated data
- **Parallel downloads** - Use `parallel.waitForAny()` for multiple concurrent requests
- **Local caching** - Store frequently used images on disk

---

## Technical Specifications

| Specification | Value |
|---------------|-------|
| **Resolution (1x)** | 164×81 pixels per block |
| **Resolution (2x)** | 328×162 pixels per block |
| **Resolution (4x)** | 656×324 pixels per block |
| **Color depth** | 24-bit RGB (8 bits/channel) |
| **Maximum monitor size** | 16×16 blocks |
| **Maximum displays** | 50 per world |
| **Maximum total pixels** | 10 megapixels across all displays |
| **Render distance** | 64 blocks |
| **Texture update rate** | 60 FPS (hardware limited) |
| **Input latency** | <50ms (sub-tick) |
| **JPEG decode time** | 5-15ms (hardware accelerated) |
| **Dictionary chunk size** | 8 KB |
| **Dictionary capacity** | 10,000 chunks (~80 MB) |
| **Memory per 1×1 block (1x)** | ~40 KB |
| **Memory per 1×1 block (4x)** | ~640 KB |

---

## Coordinate System

DirectGPU uses a standard 2D pixel coordinate system:

- **Origin (0, 0)** is at the **top-left corner**
- **X axis** increases to the **right**
- **Y axis** increases **downward**
- All coordinates are in **pixels**, not blocks
- Coordinates are **0-indexed**

**Example:** For a 164×81 display:
- Top-left corner: (0, 0)
- Top-right corner: (163, 0)
- Bottom-left corner: (0, 80)
- Bottom-right corner: (163, 80)

---

## Troubleshooting

### "Display not found" or "No monitor found"

**Solution:**
- Ensure monitors form a complete rectangle (no gaps)
- Use `autoDetectMonitor()` to verify detection
- Check that monitors are within 16 blocks
- Verify monitors are properly placed (facing direction matters)

### "Failed to create display - check resource limits"

**Solution:**
- Check current usage: `gpu.getResourceStats()`
- You've hit either:
  - 50 display limit, or
  - 10 megapixel total limit
- Remove unused displays: `gpu.clearAllDisplays()`
- Use lower resolution multipliers

### Touch input not working

**Solution:**
- Close the CC computer terminal (press E or Esc)
- Click directly on the physical monitor blocks in the world
- Verify display exists: `gpu.listDisplays()`
- Check event queue: `gpu.hasEvents(displayId)`

### Peripheral not detected

**Solution:**
- Connect a wired modem to the DirectGPU block
- Right-click the modem to activate it
- Check peripheral list: `peripheral.getNames()`
- Verify CC: Tweaked version is 1.20.1 compatible

### Low FPS or stuttering

**Solution:**
- Reduce resolution multiplier (use 1x or 2x)
- Use smaller monitor arrays
- Batch drawing operations
- Limit `updateDisplay()` calls (max 60 FPS)
- Check server TPS: `/forge tps`
- Reduce number of concurrent displays

### JPEG decode errors

**Solution:**
- Verify image data is valid JPEG format
- Use binary HTTP mode: `http.get(url, {}, true)`
- Check image isn't corrupted or truncated
- Try a smaller test image first
- Verify HTTP response is successful

### Images not loading / blank display

**Solution:**
- Call `updateDisplay()` after drawing
- Check image format is supported (JPEG recommended)
- Verify display ID is correct
- Use `getDisplayInfo()` to check display state
- Clear display first: `gpu.clear(displayId, 0, 0, 0)`

### Dictionary compression not working

**Solution:**
- Ensure you're calling `decompressFromDict()` after `compressWithDict()`
- Check chunk exists: `gpu.hasChunk(hash)`
- Clear and rebuild dictionary: `gpu.clearDictionary()`
- Verify binary data is unchanged between compress/decompress

---

## Best Practices

### Display Lifecycle

```lua
-- Good: Always clean up
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplay()

-- Your code here

gpu.clearAllDisplays()  -- Clean up when done
```

### Error Handling

```lua
-- Good: Handle errors gracefully
local success, display = pcall(function()
    return gpu.autoDetectAndCreateDisplay()
end)

if not success then
    print("Error: " .. display)
    return
end

-- Use display safely
```

### Event Loop Structure

```lua
-- Good: Efficient event loop
local running = true

parallel.waitForAny(
    -- Main loop
    function()
        while running do
            if gpu.hasEvents(display) then
                local event = gpu.pollEvent(display)
                -- Handle event
            end
            sleep(0.05)  -- Prevent CPU overload
        end
    end,
    
    -- Exit handler
    function()
        os.pullEvent("terminate")
        running = false
    end
)

gpu.clearAllDisplays()
```

### Batch Drawing

```lua
-- Bad: Update after every pixel
for i = 1, 1000 do
    gpu.setPixel(display, i, 10, 255, 0, 0)
    gpu.updateDisplay(display)  -- 1000 updates!
end

-- Good: Update once after batch
for i = 1, 1000 do
    gpu.setPixel(display, i, 10, 255, 0, 0)
end
gpu.updateDisplay(display)  -- 1 update
```

---

## Advanced Topics

### Custom Text Rendering

DirectGPU doesn't include built-in text rendering, but you can implement it:

```lua
-- Simple 5x7 pixel font (example for letter 'A')
local font = {
    A = {
        {0,1,1,1,0},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {1,1,1,1,1},
        {1,0,0,0,1},
        {1,0,0,0,1},
        {1,0,0,0,1}
    }
    -- Add more letters...
}

function drawChar(display, char, x, y, r, g, b)
    local pattern = font[char]
    if not pattern then return end
    
    for row = 1, #pattern do
        for col = 1, #pattern[row] do
            if pattern[row][col] == 1 then
                gpu.setPixel(display, x + col - 1, y + row - 1, r, g, b)
            end
        end
    end
end

-- Usage
drawChar(display, "A", 10, 10, 255, 255, 255)
gpu.updateDisplay(display)
```

### Double Buffering

For complex animations, implement double buffering:

```lua
local backBuffer = {}  -- Store pixel data

function setPixelBuffer(x, y, r, g, b)
    local key = x .. "," .. y
    backBuffer[key] = {r, g, b}
end

function flushBuffer(display)
    for key, color in pairs(backBuffer) do
        local x, y = key:match("(%d+),(%d+)")
        gpu.setPixel(display, tonumber(x), tonumber(y), 
            color[1], color[2], color[3])
    end
    gpu.updateDisplay(display)
    backBuffer = {}
end
```

### Sprite System

```lua
local Sprite = {}
Sprite.__index = Sprite

function Sprite.new(pixels, width, height)
    local self = setmetatable({}, Sprite)
    self.pixels = pixels
    self.width = width
    self.height = height
    return self
end

function Sprite:draw(display, x, y)
    for py = 0, self.height - 1 do
        for px = 0, self.width - 1 do
            local i = (py * self.width + px) * 3 + 1
            local r = self.pixels[i]
            local g = self.pixels[i + 1]
            local b = self.pixels[i + 2]
            gpu.setPixel(display, x + px, y + py, r, g, b)
        end
    end
end

-- Usage
local sprite = Sprite.new({255,0,0, 0,255,0, 0,0,255}, 3, 1)
sprite:draw(display, 10, 10)
gpu.updateDisplay(display)
```

---

## FAQ

**Q: Can I use DirectGPU with regular CC monitors?**  
A: Yes! DirectGPU renders directly onto CC monitor blocks. Any rectangular array of monitors will work.

**Q: Does this work in multiplayer?**  
A: Yes, DirectGPU is fully multiplayer compatible. Each computer can have its own displays.

**Q: Can multiple computers control the same display?**  
A: No, each display is owned by the DirectGPU block that created it. However, you can network computers to coordinate.

**Q: What's the difference between 1x and 4x resolution?**  
A: 1x = 164×81 pixels/block, 4x = 656×324 pixels/block. Higher resolution uses more memory and bandwidth but looks sharper.

**Q: Can I play videos?**  
A: Yes! Use dictionary compression for efficient streaming. See the webcam example. Expect 10-15 FPS for good quality.

**Q: Does this work with CC: Restitched or other forks?**  
A: DirectGPU is designed for CC: Tweaked 1.20.1. Other forks may work but aren't officially supported.

**Q: How do I save/load images from disk?**  
A: Use CC's `fs.open()` with binary mode. Store pixel data as a table and serialize with `textutils.serialize()`.

**Q: Can I use this for games?**  
A: Absolutely! DirectGPU is perfect for games. See the paint program and button examples for UI patterns.

---

## Credits

**Author:** Tom (GitHub: [@tiktop101])  
**Minecraft Version:** 1.20.1  
**Forge Version:** 47.3.0+  
**CC: Tweaked Version:** 1.20.1  

## License

This project is licensed under the **All Rights Reserved (ARR)** license.

**You may:**
- Use this mod in personal gameplay
- Use this mod on servers
- Create content (videos, streams) featuring this mod

## Support & Community

- **Issues:** Report bugs on GitHub Issues
- **Discord:** Join the Minecraft Computer Mods Discord
