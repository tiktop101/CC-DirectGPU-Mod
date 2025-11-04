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
3. Ensure you have **Forge** Or **Fabric** and **CC: Tweaked** installed
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
- Automatically detects monitor orientation (north, south, east, west, up, down)
- Finds complete rectangular monitor arrays only
- Returns `{found = false}` if no monitor found
- Detection range: 16 blocks in all directions

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
**Throws:** Error if parameters are invalid

**Important:** The facing direction should be the direction the monitor is facing (where the screen points), NOT the direction you're looking at it from.

---

#### `createDisplayAt(x, y, z, facing, width, height)` → displayId

Alias for `createDisplay()`. Identical functionality.

```lua
local display = gpu.createDisplayAt(100, 64, 200, "south", 4, 3)
```

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

**Note:** Also cleans up associated OpenGL textures automatically.

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
- `displayId` (number): Target display ID
- `x, y` (number): Pixel coordinates (0-indexed from top-left)
- `r, g, b` (number): RGB color values (0-255)

**Note:** Does not automatically update the display. Call `updateDisplay()` to render changes to the screen.

**Coordinate System:** (0, 0) is top-left corner. X increases right, Y increases down.

---

#### `getPixel(displayId, x, y)` → color

Returns the RGB color of a pixel.

```lua
local r, g, b = table.unpack(gpu.getPixel(display, 100, 50))
print(string.format("RGB: %d, %d, %d", r, g, b))
```

**Parameters:**
- `displayId` (number): Target display ID
- `x, y` (number): Pixel coordinates

**Returns:** Array `{r, g, b}` with values 0-255

**Note:** Returns `{0, 0, 0}` if coordinates are out of bounds.

---

#### `clear(displayId, r, g, b)`

Fills the entire display with a solid color.

```lua
gpu.clear(display, 0, 0, 0)  -- Clear to black
gpu.clear(display, 255, 255, 255)  -- Clear to white
gpu.clear(display, 64, 128, 192)  -- Clear to custom color
```

**Parameters:**
- `displayId` (number): Target display ID
- `r, g, b` (number): RGB fill color (0-255)

**Note:** Marks display as dirty but you still need to call `updateDisplay()` to render.

---

#### `fillRect(displayId, x, y, width, height, r, g, b)`

Draws a filled rectangle.

```lua
-- Draw a 100x50 red rectangle at (10, 10)
gpu.fillRect(display, 10, 10, 100, 50, 255, 0, 0)

-- Draw a yellow bar across the top
gpu.fillRect(display, 0, 0, info.pixelWidth, 20, 255, 255, 0)
```

**Parameters:**
- `displayId` (number): Target display ID
- `x, y` (number): Top-left corner position
- `width, height` (number): Rectangle dimensions in pixels
- `r, g, b` (number): Fill color (0-255)

**Note:** Automatically clips to display bounds.

---

#### `drawLine(displayId, x1, y1, x2, y2, r, g, b)`

Draws a line between two points using Bresenham's algorithm.

```lua
-- Draw white diagonal line
gpu.drawLine(display, 0, 0, 163, 80, 255, 255, 255)

-- Draw a cross
gpu.drawLine(display, 0, 0, 163, 80, 255, 0, 0)
gpu.drawLine(display, 163, 0, 0, 80, 255, 0, 0)
```

**Parameters:**
- `displayId` (number): Target display ID
- `x1, y1` (number): Start point coordinates
- `x2, y2` (number): End point coordinates
- `r, g, b` (number): Line color (0-255)

**Performance:** Efficient single-pixel-wide line drawing.

---

#### `updateDisplay(displayId)`

Marks the display as dirty, triggering a render update on the next frame.

```lua
gpu.setPixel(display, 10, 10, 255, 0, 0)
gpu.setPixel(display, 11, 10, 255, 0, 0)
gpu.setPixel(display, 12, 10, 255, 0, 0)
gpu.updateDisplay(display)  -- Render all changes at once
```

**Performance Tips:** 
- Batch multiple drawing operations before calling `updateDisplay()`
- The renderer automatically limits updates to ~60 FPS for smooth performance
- No need to call this more than once per frame

---

### Image Loading

#### `loadImage(displayId, imageData)`

Loads an image from a Lua table in nested or flat pixel format. Automatically scales to fit display with aspect ratio preservation.

```lua
local imageData = {
    width = 100,
    height = 100,
    pixels = {
        {{255, 0, 0}, {0, 255, 0}, {0, 0, 255}, ...},  -- Row 1
        {{0, 255, 0}, {0, 0, 255}, {255, 0, 0}, ...},  -- Row 2
        ...
    }
}

gpu.loadImage(display, imageData)
gpu.updateDisplay(display)
```

**Supported Formats:**

1. **Nested List Format (recommended):**
```lua
pixels = {
    {{r, g, b}, {r, g, b}, ...},  -- Row 1
    {{r, g, b}, {r, g, b}, ...},  -- Row 2
    ...
}
```

2. **Flat Array Format:**
```lua
pixels = {r, g, b, r, g, b, r, g, b, ...}  -- Single linear array
```

3. **Lua Table Format (1-indexed):**
```lua
pixels = {
    [1] = {[1] = {r, g, b}, [2] = {r, g, b}, ...},
    [2] = {[1] = {r, g, b}, [2] = {r, g, b}, ...},
    ...
}
```

**Parameters:**
- `displayId` (number): Target display ID
- `imageData` (table): Image data structure with `width`, `height`, and `pixels` fields

**Note:** Does not call `updateDisplay()` automatically. Always call it after loading.

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

**Important:** The `pixels` field is a binary string in flat RGB format: `RGBRGBRGB...`

---

#### `decodeAndScaleJPEG(jpegData, targetWidth, targetHeight)` → result

Decodes and scales a JPEG in one optimized operation. Much faster than decode + scale separately.

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

**Performance:** Faster than decode + scale separately. Use for real-time video streaming.

---

#### `getJPEGDimensions(jpegData)` → dimensions

Gets JPEG dimensions without full decode (very fast, <1ms).

```lua
local dims = gpu.getJPEGDimensions(jpegData)
print(string.format("Image: %dx%d", dims.width, dims.height))

-- Useful for deciding whether to scale before decoding
if dims.width > 1000 then
    print("Image too large, will scale down")
end
```

**Parameters:**
- `jpegData` (string): Binary JPEG data

**Returns:** `{width = number, height = number}`

**Use Case:** Check image size before expensive decode operations.

---

#### `loadJPEGRegion(displayId, jpegData, x, y, width, height)`

Decodes a JPEG and blits it to a specific region of the display. Does NOT call `updateDisplay()`.

```lua
-- Load webcam frame into top-left corner
gpu.loadJPEGRegion(display, jpegData, 0, 0, 320, 240)

-- Load thumbnail into bottom-right
local info = gpu.getDisplayInfo(display)
gpu.loadJPEGRegion(display, thumbnailData, 
    info.pixelWidth - 80, info.pixelHeight - 60, 80, 60)

gpu.updateDisplay(display)  -- Must call this to render
```

**Parameters:**
- `displayId` (number): Target display ID
- `jpegData` (string): Binary JPEG data
- `x, y` (number): Destination position on display
- `width, height` (number): Region size (JPEG will be scaled to fit)

**Use Case:** 
- Compositing multiple images on one display
- Picture-in-picture video windows
- Thumbnail grids

**Performance:** Combines decode, scale, and blit in one optimized operation.

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

**Parameters:**
- `data` (string): Binary data to compress

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
4. Only stores new/changed chunks
5. Returns array of hashes to reconstruct data

**Result:** 90%+ bandwidth reduction for video after first frame!

**Important:** The dictionary is global and shared across all displays. This makes compression even more efficient when streaming similar content to multiple displays.

---

#### `decompressFromDict(hashes)` → data

Reconstructs data from chunk hashes.

```lua
local stats = gpu.compressWithDict(jpegData)
-- ... send hashes to another computer or store them ...

-- Later, reconstruct the original data
local originalData = gpu.decompressFromDict(stats.hashes)
```

**Parameters:**
- `hashes` (array): Array of chunk hashes from `compressWithDict()`

**Returns:** Binary string (reconstructed data)  
**Throws:** Error if any chunk is missing from dictionary

**Note:** All chunks must exist in the dictionary. If a chunk was evicted (dictionary holds max 10,000 chunks), decompression will fail.

---

#### `hasChunk(hash)` → boolean

Checks if a chunk exists in the dictionary.

```lua
if gpu.hasChunk(12345) then
    print("Chunk cached")
else
    print("Need to send chunk")
end
```

**Parameters:**
- `hash` (number): Chunk hash

**Returns:** `true` if chunk exists, `false` otherwise

**Use Case:** Network optimization - only send chunks that aren't cached.

---

#### `getChunk(hash)` → data

Retrieves a chunk by its hash.

```lua
local chunkData = gpu.getChunk(12345)
print("Chunk size: " .. #chunkData .. " bytes")
```

**Parameters:**
- `hash` (number): Chunk hash

**Returns:** Binary string (up to 8KB)  
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

**Note:** When dictionary reaches 10,000 chunks, oldest chunks are automatically evicted.

---

#### `clearDictionary()`

Clears all chunks from the dictionary.

```lua
gpu.clearDictionary()
print("Dictionary cleared")
```

**Use Cases:** 
- Free memory when done streaming
- Reset compression state between sessions
- Clear cache when switching content types

---

### Touch Input

Touch input captures mouse events when you interact with the physical monitor blocks in the world.

**Important:** Touch input only works when NOT in any GUI. Close the CC terminal and click directly on the monitor blocks.

#### `hasEvents(displayId)` → boolean

Checks if there are pending input events.

```lua
while true do
    if gpu.hasEvents(display) then
        local event = gpu.pollEvent(display)
        -- Process event
    else
        sleep(0.05)  -- Don't busy-wait
    end
end
```

**Parameters:**
- `displayId` (number): Target display ID

**Returns:** `true` if events are queued, `false` otherwise

---

#### `pollEvent(displayId)` → event

Retrieves and removes the next input event from the queue.

```lua
local event = gpu.pollEvent(display)
if event then
    print("Event type: " .. event.type)
    print("Position: (" .. event.x .. ", " .. event.y .. ")")
    print("Button: " .. event.button)
end
```

**Parameters:**
- `displayId` (number): Target display ID

**Returns:** Event table or `nil` if no events available

**Event Object:**
```lua
{
    type = "mouse_click",  -- Event type (see below)
    x = 50,                -- Pixel X coordinate (0-indexed)
    y = 30,                -- Pixel Y coordinate (0-indexed)
    button = 1,            -- Mouse button (1=left, 2=right, 3=middle)
    timestamp = 1234567890 -- System time in milliseconds
}
```

**Event Types:**

| Type | Description | When Fired | Fields |
|------|-------------|------------|--------|
| `mouse_click` | Mouse button pressed | On button down | `x, y, button, timestamp` |
| `mouse_drag` | Mouse moved while button held | While dragging (throttled to 50ms) | `x, y, button, timestamp` |
| `mouse_up` | Mouse button released | On button up | `x, y, button, timestamp` |

**Button Values:**
- `1` = Left mouse button
- `2` = Right mouse button
- `3` = Middle mouse button

**Important Notes:**
- Events are queued (max 100 events)
- Drag events are throttled to every 50ms for performance
- Coordinates are in pixel space relative to display
- Y-axis is flipped: (0, 0) is top-left
- You must close the CC terminal to receive events

---

#### `clearEvents(displayId)`

Clears all pending events from the queue.

```lua
-- Switching UI states
currentScreen = "menu"
gpu.clearEvents(display)  -- Discard old events

-- New interaction loop
while currentScreen == "menu" do
    if gpu.hasEvents(display) then
        handleMenuClick(gpu.pollEvent(display))
    end
    sleep(0.05)
end
```

**Parameters:**
- `displayId` (number): Target display ID

**Use Case:** Prevent stale events when changing UI states or screens.

---

## Examples

### Example 1: Gradient Background

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplay()
local info = gpu.getDisplayInfo(display)

print("Drawing gradient...")

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
        print(string.format("Progress: %.1f%%", (y / info.pixelHeight) * 100))
    end
end

gpu.updateDisplay(display)
print("Done!")
sleep(5)
gpu.clearAllDisplays()
```

---

### Example 2: Interactive Paint Program

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplay()

-- Clear to white canvas
gpu.clear(display, 255, 255, 255)
gpu.updateDisplay(display)

print("Draw on the monitor! Press Ctrl+T to exit")
print("Close this terminal and click the monitor blocks")

local lastX, lastY = nil, nil
local running = true

parallel.waitForAny(
    -- Event loop
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
                end
            else
                sleep(0.05)
            end
        end
    end,
    
    -- Exit handler
    function()
        os.pullEvent("terminate")
        running = false
    end
)

gpu.clearAllDisplays()
print("Goodbye!")
```

---

### Example 3: Button UI

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

-- Helper: Check if point is inside button
local function isInside(x, y)
    return x >= button.x and x < button.x + button.width and
           y >= button.y and y < button.y + button.height
end

-- Draw function
local function drawButton(color)
    gpu.clear(display, 220, 220, 220)
    gpu.fillRect(display, button.x, button.y, button.width, button.height, 
                 color[1], color[2], color[3])
    
    -- Draw border
    gpu.drawLine(display, button.x, button.y, button.x + button.width, button.y, 0, 0, 0)
    gpu.drawLine(display, button.x, button.y + button.height, button.x + button.width, button.y + button.height, 0, 0, 0)
    gpu.drawLine(display, button.x, button.y, button.x, button.y + button.height, 0, 0, 0)
    gpu.drawLine(display, button.x + button.width, button.y, button.x + button.width, button.y + button.height, 0, 0, 0)
    
    gpu.updateDisplay(display)
end

-- Initial draw
drawButton(button.color)
print("Click the blue button!")
print("Close terminal and click the monitor")

-- Event loop
while true do
    if gpu.hasEvents(display) then
        local event = gpu.pollEvent(display)
        
        if event.type == "mouse_click" and isInside(event.x, event.y) then
            print("Button clicked at (" .. event.x .. ", " .. event.y .. ")")
            
            -- Flash animation
            drawButton(button.clickColor)
            sleep(0.15)
            drawButton(button.color)
        end
    end
    sleep(0.05)
end
```

---

### Example 4: Webcam Streamer

**Simple Version (HTTP + JPEG):**

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplayWithResolution(2)  -- 2x for better quality
local info = gpu.getDisplayInfo(display)

print("Webcam Viewer - " .. info.pixelWidth .. "x" .. info.pixelHeight)

local CAMERA_URL = "http://192.168.1.100:8080/shot.jpg"
local TARGET_FPS = 10

local function fetchFrame()
    -- Add timestamp to prevent caching
    local url = CAMERA_URL .. "?t=" .. os.epoch("utc")
    local handle = http.get(url, {}, true)  -- Binary mode
    
    if not handle then 
        print("Failed to fetch frame")
        return false 
    end
    
    local jpegData = handle.readAll()
    handle.close()
    
    if #jpegData < 100 then 
        print("Invalid frame data")
        return false 
    end
    
    -- Load directly to display (auto-scales)
    gpu.loadJPEGRegion(display, jpegData, 0, 0, info.pixelWidth, info.pixelHeight)
    gpu.updateDisplay(display)
    
    return true
end

print("Streaming... Press Q to quit")

local running = true
local frameCount = 0
local startTime = os.epoch("utc")

parallel.waitForAny(
    -- Stream loop
    function()
        while running do
            local frameStart = os.epoch("utc")
            
            if fetchFrame() then
                frameCount = frameCount + 1
                
                -- Show FPS every second
                if frameCount % 30 == 0 then
                    local elapsed = (os.epoch("utc") - startTime) / 1000
                    print(string.format("FPS: %.1f", frameCount / elapsed))
                end
            end
            
            local frameTime = (os.epoch("utc") - frameStart) / 1000
            sleep(math.max(0, (1/TARGET_FPS) - frameTime))
        end
    end,
    
    -- Exit handler
    function()
        while running do
            local event, key = os.pullEvent("key")
            if key == keys.q then 
                running = false 
            end
        end
    end
)

gpu.clearAllDisplays()
print("Stream stopped. Total frames: " .. frameCount)
```

**Advanced Version (Dictionary Compression):**

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplay()
local info = gpu.getDisplayInfo(display)

local CAMERA_URL = "http://192.168.1.100:8080/shot.jpg"
local frameCount = 0
local totalCacheHits = 0

print("Webcam with Dictionary Compression")

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
    gpu.loadJPEGRegion(display, decompressed, 0, 0, info.pixelWidth, info.pixelHeight)
    gpu.updateDisplay(display)
    
    frameCount = frameCount + 1
    totalCacheHits = totalCacheHits + cacheHitRate
    
    if frameCount % 30 == 0 then
        print(string.format("Frame %d | Cache hit: %.1f%% | New chunks: %d", 
            frameCount, totalCacheHits / frameCount, stats.newChunks))
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

local dictStats = gpu.getDictionaryStats()
print(string.format("Dictionary: %d chunks (%.1f MB)", 
    dictStats.dictionarySize, dictStats.totalMB))

gpu.clearAllDisplays()
```

---

### Example 5: Image Slideshow

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplayWithResolution(2)
local info = gpu.getDisplayInfo(display)

local images = {
    "http://example.com/photo1.jpg",
    "http://example.com/photo2.jpg",
    "http://example.com/photo3.jpg"
}

print("Slideshow starting...")
print("Display: " .. info.pixelWidth .. "x" .. info.pixelHeight)

for i, url in ipairs(images) do
    print("Loading image " .. i .. " of " .. #images .. "...")
    
    local handle = http.get(url, {}, true)
    if handle then
        local jpegData = handle.readAll()
        handle.close()
        
        -- Load and scale to display
        gpu.loadJPEGRegion(display, jpegData, 0, 0, info.pixelWidth, info.pixelHeight)
        gpu.updateDisplay(display)
        
        print("Showing for 5 seconds...")
        sleep(5)
    else
        print("Failed to load: " .. url)
    end
end

print("Slideshow complete!")
gpu.clearAllDisplays()
```

---

### Example 6: Multi-Display Dashboard

```lua
local gpu = peripheral.find("directgpu")

-- Create 2x2 grid of displays
local displays = {}
print("Creating 2x2 display grid...")

for row = 0, 1 do
    for col = 0, 1 do
        local x = 100 + col * 3  -- 3 blocks apart
        local y = 64 + row * 2   -- 2 blocks apart
        local z = 200
        
        local id = gpu.createDisplay(x, y, z, "south", 3, 2)
        table.insert(displays, id)
        print("Created display " .. id .. " at (" .. x .. ", " .. y .. ", " .. z .. ")")
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
    
    -- Draw a pattern
    local info = gpu.getDisplayInfo(display)
    gpu.fillRect(display, 10, 10, info.pixelWidth - 20, info.pixelHeight - 20, 
        255 - color[1], 255 - color[2], 255 - color[3])
    
    gpu.updateDisplay(display)
end

print("Multi-display dashboard running!")
print("Press any key to exit...")
os.pullEvent("key")

-- Clean up all displays
gpu.clearAllDisplays()
print("Displays cleared")
```

---

### Example 7: Real-Time Drawing Board

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplayWithResolution(2)
local info = gpu.getDisplayInfo(display)

-- Canvas state
local canvas = {
    brushSize = 5,
    brushColor = {0, 0, 0},
    backgroundColor = {255, 255, 255},
    drawing = false,
    lastX = nil,
    lastY = nil
}

-- Color palette (bottom of screen)
local palette = {
    {255, 0, 0},     -- Red
    {0, 255, 0},     -- Green
    {0, 0, 255},     -- Blue
    {255, 255, 0},   -- Yellow
    {255, 0, 255},   -- Magenta
    {0, 255, 255},   -- Cyan
    {0, 0, 0},       -- Black
    {255, 255, 255}  -- White (eraser)
}

local paletteY = info.pixelHeight - 30
local paletteItemWidth = info.pixelWidth / #palette

-- Draw UI
local function drawUI()
    -- Clear canvas
    gpu.clear(display, canvas.backgroundColor[1], canvas.backgroundColor[2], canvas.backgroundColor[3])
    
    -- Draw palette at bottom
    for i, color in ipairs(palette) do
        local x = math.floor((i - 1) * paletteItemWidth)
        gpu.fillRect(display, x, paletteY, math.floor(paletteItemWidth), 30, color[1], color[2], color[3])
        
        -- Draw border
        gpu.drawLine(display, x, paletteY, x, info.pixelHeight, 128, 128, 128)
    end
    
    gpu.updateDisplay(display)
end

-- Draw brush stroke
local function drawBrush(x, y)
    local halfSize = math.floor(canvas.brushSize / 2)
    gpu.fillRect(display, x - halfSize, y - halfSize, canvas.brushSize, canvas.brushSize,
        canvas.brushColor[1], canvas.brushColor[2], canvas.brushColor[3])
end

drawUI()

print("Drawing Board Ready!")
print("Close terminal and draw on the monitor")
print("Click palette at bottom to change colors")
print("Press Ctrl+T to exit")

local running = true

parallel.waitForAny(
    function()
        while running do
            if gpu.hasEvents(display) then
                local event = gpu.pollEvent(display)
                
                if event.type == "mouse_click" then
                    -- Check if clicking palette
                    if event.y >= paletteY then
                        local colorIndex = math.floor(event.x / paletteItemWidth) + 1
                        if colorIndex >= 1 and colorIndex <= #palette then
                            canvas.brushColor = palette[colorIndex]
                            print("Color changed to: " .. colorIndex)
                        end
                    else
                        -- Start drawing
                        canvas.drawing = true
                        drawBrush(event.x, event.y)
                        canvas.lastX, canvas.lastY = event.x, event.y
                        gpu.updateDisplay(display)
                    end
                    
                elseif event.type == "mouse_drag" and canvas.drawing then
                    if event.y < paletteY then  -- Don't draw on palette
                        -- Draw line from last position for smooth strokes
                        if canvas.lastX and canvas.lastY then
                            gpu.drawLine(display, canvas.lastX, canvas.lastY, event.x, event.y,
                                canvas.brushColor[1], canvas.brushColor[2], canvas.brushColor[3])
                        end
                        drawBrush(event.x, event.y)
                        canvas.lastX, canvas.lastY = event.x, event.y
                        gpu.updateDisplay(display)
                    end
                end
            else
                sleep(0.02)
            end
        end
    end,
    
    function()
        os.pullEvent("terminate")
        running = false
    end
)

gpu.clearAllDisplays()
print("Drawing board closed")
```

---

## Performance Tips

### Drawing Optimization

1. **Batch operations** - Call `updateDisplay()` once after multiple drawing calls:
```lua
-- Bad: 1000 updates
for i = 1, 1000 do
    gpu.setPixel(display, i, 10, 255, 0, 0)
    gpu.updateDisplay(display)  -- Too many!
end

-- Good: 1 update
for i = 1, 1000 do
    gpu.setPixel(display, i, 10, 255, 0, 0)
end
gpu.updateDisplay(display)  -- Once at the end
```

2. **Use primitives** - `fillRect()` and `drawLine()` are faster than individual `setPixel()` calls:
```lua
-- Slower
for x = 0, 100 do
    for y = 0, 50 do
        gpu.setPixel(display, x, y, 255, 0, 0)
    end
end

-- Much faster
gpu.fillRect(display, 0, 0, 100, 50, 255, 0, 0)
```

3. **Limit update rate** - Don't call `updateDisplay()` more than 60 times per second:
```lua
local lastUpdate = 0
local UPDATE_INTERVAL = 1/60  -- 60 FPS max

while running do
    -- Draw stuff...
    
    local now = os.clock()
    if now - lastUpdate >= UPDATE_INTERVAL then
        gpu.updateDisplay(display)
        lastUpdate = now
    end
end
```

4. **Progressive rendering** - Update display periodically during long operations:
```lua
for y = 0, info.pixelHeight - 1 do
    for x = 0, info.pixelWidth - 1 do
        gpu.setPixel(display, x, y, r, g, b)
    end
    
    -- Update every 20 rows
    if y % 20 == 0 then
        gpu.updateDisplay(display)
    end
end
gpu.updateDisplay(display)  -- Final update
```

### Memory Management

1. **Clean up displays** - Always call `clearAllDisplays()` when done:
```lua
local display = gpu.autoDetectAndCreateDisplay()

-- Your code here...

gpu.clearAllDisplays()  -- Important!
```

2. **Monitor pixel budget** - Use `getResourceStats()` to track usage:
```lua
local stats = gpu.getResourceStats()
if stats.pixelUsagePercent > 80 then
    print("Warning: High pixel usage!")
end
```

3. **Use appropriate resolution** - Higher multipliers consume more memory:
```lua
-- Memory per monitor block:
-- 1x: ~40 KB   (164x81 pixels)
-- 2x: ~160 KB  (328x162 pixels)
-- 4x: ~640 KB  (656x324 pixels)

-- For general use, 1x or 2x is recommended
local display = gpu.autoDetectAndCreateDisplayWithResolution(2)
```

### Image/Video Streaming

1. **Use JPEG for photos** - Smaller file size, hardware-accelerated decode
2. **Use dictionary compression for video** - 90%+ bandwidth reduction after first frame:
```lua
-- First frame: ~100KB
-- Subsequent frames: ~10KB (90% cache hit)
local stats = gpu.compressWithDict(jpegData)
```

3. **Binary HTTP mode** - Always use for images:
```lua
-- Correct
local handle = http.get(url, {}, true)  -- Binary mode

-- Wrong
local handle = http.get(url)  -- Text mode corrupts binary data
```

4. **Cache-busting** - Add random query params to prevent caching:
```lua
local url = CAMERA_URL .. "?t=" .. os.epoch("utc")
```

5. **Target 10-15 FPS** - Good balance between smooth video and performance:
```lua
local TARGET_FPS = 10
sleep(1 / TARGET_FPS)
```

6. **Scale on decode** - Use `decodeAndScaleJPEG()` instead of separate operations:
```lua
-- Faster
local result = gpu.decodeAndScaleJPEG(jpegData, targetW, targetH)

-- Slower
local decoded = gpu.decodeJPEG(jpegData)
-- ... then manually scale ...
```

### Input Handling

1. **Add sleep() in event loops** - Prevent CPU overload:
```lua
while running do
    if gpu.hasEvents(display) then
        local event = gpu.pollEvent(display)
        -- Handle event
    end
    sleep(0.05)  -- Important!
end
```

2. **Use hasEvents()** - Check before calling `pollEvent()`:
```lua
-- Good
if gpu.hasEvents(display) then
    local event = gpu.pollEvent(display)
end

-- Bad
local event = gpu.pollEvent(display)  -- Returns nil often
```

3. **Clear old events** - When switching UI states:
```lua
currentScreen = "menu"
gpu.clearEvents(display)  -- Prevent stale events
```

---

## Troubleshooting

### "Display not found" or "No monitor found"

**Causes:**
- Monitors not forming a complete rectangle
- Monitors too far away (>16 blocks)
- Wrong monitor type (must be CC monitors)

**Solutions:**
```lua
-- Test auto-detection
local info = gpu.autoDetectMonitor()
if not info.found then
    print("No monitor detected within 16 blocks")
else
    print("Found: " .. info.width .. "x" .. info.height)
    print("At: " .. info.x .. ", " .. info.y .. ", " .. info.z)
    print("Facing: " .. info.facing)
end
```

### "Failed to create display - check resource limits"

**Causes:**
- Hit 50 display limit
- Hit 10 megapixel total limit

**Solutions:**
```lua
-- Check current usage
local stats = gpu.getResourceStats()
print("Displays: " .. stats.displays .. "/" .. stats.maxDisplays)
print("Pixels: " .. stats.totalPixels .. "/" .. stats.maxTotalPixels)

-- Clean up unused displays
gpu.clearAllDisplays()

-- Use lower resolution
local display = gpu.autoDetectAndCreateDisplayWithResolution(1)  -- Instead of 4
```

### Touch input not working

**Solutions:**
1. Close the CC computer terminal (press E or Esc)
2. Click directly on the physical monitor blocks in the world
3. Verify display exists:
```lua
local displays = gpu.listDisplays()
print("Active displays: " .. #displays)
```

4. Check event queue:
```lua
if gpu.hasEvents(display) then
    print("Events available!")
else
    print("No events - try clicking the monitor blocks")
end
```

### Peripheral not detected

**Solutions:**
1. Connect a wired modem to the DirectGPU block
2. Right-click the modem to activate it (should turn red)
3. Check peripheral list:
```lua
local peripherals = peripheral.getNames()
for _, name in ipairs(peripherals) do
    print(name .. ": " .. peripheral.getType(name))
end
```

4. Try wrapping directly:
```lua
local gpu = peripheral.wrap("right")  -- or whichever side
if gpu then
    print("Type: " .. peripheral.getType("right"))
end
```

### Low FPS or stuttering

**Solutions:**
1. Reduce resolution multiplier:
```lua
local display = gpu.autoDetectAndCreateDisplayWithResolution(1)  -- Lower res
```

2. Use smaller monitor arrays (3x2 instead of 8x6)

3. Limit update calls:
```lua
local lastUpdate = os.clock()
if os.clock() - lastUpdate > 0.016 then  -- Max 60 FPS
    gpu.updateDisplay(display)
    lastUpdate = os.clock()
end
```

4. Check server TPS:
```
/forge tps
```

### JPEG decode errors

**Solutions:**
```lua
-- Verify binary mode
local handle = http.get(url, {}, true)  -- Third parameter must be true
if not handle then
    print("HTTP request failed")
    return
end

local data = handle.readAll()
handle.close()

-- Check data size
if #data < 100 then
    print("Data too small: " .. #data .. " bytes")
    return
end

-- Try decode with error handling
local success, result = pcall(function()
    return gpu.decodeJPEG(data)
end)

if not success then
    print("Decode failed: " .. result)
else
    print("Decoded: " .. result.width .. "x" .. result.height)
end
```

### Images not loading / blank display

**Checklist:**
```lua
-- 1. Verify display exists
local displays = gpu.listDisplays()
print("Displays: " .. #displays)

-- 2. Check display info
local info = gpu.getDisplayInfo(display)
print("Size: " .. info.pixelWidth .. "x" .. info.pixelHeight)

-- 3. Try simple draw test
gpu.clear(display, 255, 0, 0)  -- Red
gpu.updateDisplay(display)
sleep(1)

-- 4. If that works, problem is with image loading
```

---

## Technical Specifications

| Specification | Value |
|---------------|-------|
| **Resolution (1x)** | 164×81 pixels per block |
| **Resolution (2x)** | 328×162 pixels per block |
| **Resolution (3x)** | 492×243 pixels per block |
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
| **Memory per 1×1 block (2x)** | ~160 KB |
| **Memory per 1×1 block (4x)** | ~640 KB |
| **Mouse event queue** | 100 events max |
| **Drag event throttle** | 50ms (20 events/sec) |

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
- Center: (82, 40)

---

## Best Practices

### Display Lifecycle

```lua
-- Always use error handling and cleanup
local gpu = peripheral.find("directgpu")
if not gpu then
    error("DirectGPU peripheral not found")
end

local success, display = pcall(function()
    return gpu.autoDetectAndCreateDisplay()
end)

if not success then
    print("Error: " .. display)
    return
end

-- Your code here...

-- Always clean up
gpu.clearAllDisplays()
```

### Event Loop Structure

```lua
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

---

## Credits

**Author:** Tom  
**Minecraft Version:** 1.20.1  
**Forge Version:** 47.3.0+  
**CC: Tweaked Version:** 1.20.1  

## License

This project is licensed under **All Rights Reserved (ARR)**.

**You may:**
- Use this mod in personal gameplay
- Use this mod on servers
- Create content (videos, streams) featuring this mod

**You may not:**
- Redistribute or reupload this mod
- Modify and redistribute this mod
- Use code from this mod in other projects without permission

---

## Support

- **Issues:** Report bugs on GitHub
- **Documentation:** This README
- **Community:** https://discord.gg/DHbQ7Xurpv
