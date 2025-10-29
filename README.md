DirectGPU

A high-performance ComputerCraft peripheral for Minecraft that enables hardware-accelerated graphics rendering directly to monitors. Stream images, create interactive UIs, or build pixel art - all at 164×81 resolution per block.

Features

    True RGB Graphics - 24-bit color with 164×81 pixels per monitor block

    Hardware Accelerated - OpenGL rendering bypasses CC's text system

    Touch Input - Full mouse and keyboard event support

    Auto-Detection - Automatically finds and configures nearby monitors

    Drawing Primitives - Lines, rectangles, and image loading

    Image Support - Load PNG/JPEG via Base64 or high-performance binary dictionary

    Flexible Sizing - Works with any monitor array up to 8×6 blocks

    Thread-Safe - Safe concurrent access from multiple computers

Installation

    Download the latest DirectGPU JAR from releases

    Place in your Minecraft mods folder

    Ensure you have Forge and ComputerCraft (or CC: Tweaked) installed

    Launch Minecraft and enjoy!

Quick Start

Lua

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

How It Works

DirectGPU creates a peripheral on the bottom side of ComputerCraft computers. When you call createDisplay(), it:

    Finds monitor blocks in the world

    Creates an OpenGL texture matching the monitor array size

    Renders the texture directly onto the monitor blocks in 3D space

    Captures mouse clicks via raycasting against the rendered surface

This approach provides dramatically higher resolution and performance compared to CC's built-in text-based rendering.

API Reference

Display Management

createDisplayAuto() → displayId

Automatically detects the nearest monitor within 16 blocks and creates a display.
Lua

local display = gpu.createDisplayAuto()

Returns: Display ID (number) Throws: Error if no monitor is found

createDisplay(facing, width, height) → displayId

Creates a display 2 blocks above the computer.
Lua

local display = gpu.createDisplay("north", 3, 2)

Parameters:

    facing (string): Direction - "north", "south", "east", "west", "up", "down"

    width (number): Monitor width in blocks (1-8)

    height (number): Monitor height in blocks (1-6)

Returns: Display ID

createDisplayAt(x, y, z, facing, width, height) → displayId

Creates a display at specific world coordinates.
Lua

local display = gpu.createDisplayAt(100, 64, 200, "south", 4, 3)

Parameters:

    x, y, z (number): World coordinates

    facing, width, height: Same as createDisplay()

removeDisplay(displayId) → success

Removes a specific display and frees its resources.
Lua

gpu.removeDisplay(display)

Returns: true if successful, false otherwise

clearDisplay()

Removes all displays created by this computer.
Lua

gpu.clearDisplay()

listDisplays() → displayIds

Returns a list of all display IDs currently active.
Lua

local displays = gpu.listDisplays()
for _, id in ipairs(displays) do
    print("Display: " .. id)
end

getDisplayInfo(displayId) → info

Returns detailed information about a display.
Lua

local info = gpu.getDisplayInfo(display)
print(info.pixelWidth .. "x" .. info.pixelHeight)

Returns:
Lua

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

Drawing Functions

setPixel(displayId, x, y, r, g, b)

Sets a single pixel to the specified RGB color.
Lua

gpu.setPixel(display, 100, 50, 255, 128, 0)

Parameters:

    x, y (number): Pixel coordinates (0-indexed from top-left)

    r, g, b (number): RGB values (0-255)

getPixel(displayId, x, y) → color

Returns the RGB color of a pixel.
Lua

local color = gpu.getPixel(display, 100, 50)
print(string.format("RGB: %d, %d, %d", color.r, color.g, color.b))

Returns: {r, g, b} table

clear(displayId, r, g, b)

Fills the entire display with a solid color.
Lua

gpu.clear(display, 0, 0, 0)  -- Clear to black

drawRect(displayId, x, y, width, height, r, g, b)

Draws a filled rectangle.
Lua

gpu.drawRect(display, 10, 10, 100, 50, 255, 0, 0)

Parameters:

    x, y: Top-left corner position

    width, height: Rectangle dimensions

    r, g, b: Fill color

drawLine(displayId, x1, y1, x2, y2, r, g, b)

Draws a line between two points using Bresenham's algorithm.
Lua

gpu.drawLine(display, 0, 0, 163, 80, 255, 255, 255)

loadImage(displayId, base64Data)

Loads a PNG or JPEG image from Base64-encoded data. The image is automatically scaled to fit the display with letterboxing.
Lua

local imageData = "iVBORw0KGgo..."  -- Base64 string
gpu.loadImage(display, imageData)

Note: The Java backend handles scaling and aspect ratio preservation automatically. Use this for single, static images. For video, see loadJPEGDict.

loadJPEGDict(displayId, binaryData) → stats

Loads a JPEG image from binary data using dictionary compression. This is highly efficient for video streams, as it only transmits the 8x8 pixel blocks that have changed from the previous frame.
Lua

-- Assumes 'imageData' is a binary string from http.get(..., ..., true)
local success, stats = pcall(function()
    return gpu.loadJPEGDict(display, imageData)
end)

if success then
    print("Cache hit: " .. string.format("%.1f%%", stats.compressionRatio * 100))
end

Parameters:

    displayId (number): The display to load the image onto.

    binaryData (string): The raw binary JPEG data (not Base64).

Returns (stats): A table containing compression statistics.
Lua

{
    totalChunks = 1440,   -- Total 8x8 blocks in the image
    newChunks = 120,      -- Blocks that were different and sent
    cachedChunks = 1320,  -- Blocks that were unchanged (reused from cache)
    compressionRatio = 0.916 -- (cachedChunks / totalChunks)
}

Note: This is the preferred method for streaming video. It dramatically reduces bandwidth and improves performance.

updateDisplay(displayId)

Marks the display as dirty, triggering a render update on the next frame.
Lua

gpu.setPixel(display, 10, 10, 255, 0, 0)
gpu.updateDisplay(display)  -- Force render

Performance Tip: Batch multiple drawing operations before calling updateDisplay().

Touch Input

Touch input captures mouse clicks and keyboard events when you interact with the physical monitor blocks in the world.

pullEvent(displayId) → event or nil

Retrieves the next input event from the queue.
Lua

local event = {gpu.pullEvent(display)}
if event then
    print("Event type: " .. event[1])
end

Returns: nil if no events are available

Event Types:

Mouse Click (Left Button):
Lua

{"mouse_click", x, y, button}

Mouse Click (Right Button):
Lua

{"mouse_click_right", x, y, button}

Mouse Drag (Left):
Lua

{"mouse_drag", x, y, button}

Mouse Drag (Right):
Lua

{"mouse_drag_right", x, y, button}

Mouse Release (Left):
Lua

{"mouse_up", x, y, button}

Mouse Release (Right):
Lua

{"mouse_up_right", x, y, button}

Key Press:
Lua

{"key", keyName}

Character Typed:
Lua

{"char", character}

Event Parameters:

    x, y: Pixel coordinates (0-indexed, top-left origin)

    button: Mouse button (1=left, 2=right, 3=middle)

    keyName: CC key name (e.g., "enter", "space", "a")

    character: Typed character string

hasEvent(displayId) → boolean

Checks if there are pending events without removing them.
Lua

if gpu.hasEvent(display) then
    local event = {gpu.pullEvent(display)}
    -- Process event
end

clearEvents(displayId)

Clears all pending events from the queue.
Lua

gpu.clearEvents(display)

sendKey(displayId, keyName)

Programmatically injects a key event into the display's event queue.
Lua

gpu.sendKey(display, "enter")

sendChar(displayId, character)

Programmatically injects a character event.
Lua

gpu.sendChar(display, "A")

Utilities

autoDetectMonitor() → info

Scans for the nearest monitor within 16 blocks.
Lua

local monitor = gpu.autoDetectMonitor()
if monitor.found then
    print(string.format("Found %dx%d monitor at (%d, %d, %d)", 
        monitor.width, monitor.height, monitor.x, monitor.y, monitor.z))
end

Returns:
Lua

{
    found = true,
    x = 100,
    y = 64,
    z = 200,
    width = 3,
    height = 2,
    facing = "north"
}

getStats() → stats

Returns system statistics.
Lua

local stats = gpu.getStats()
print("Active displays: " .. stats.displays)
print("Total pixels: " .. stats.totalPixels)

Examples

Gradient Background

Lua

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

Interactive Paint Program

Lua

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

Button UI

Lua

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

Webcam Streamer (High-Performance)

This example uses http.get in binary mode and loadJPEGDict for maximum performance. For high-FPS streaming, see the async dictionary-compressed example in your dict.lua script.
Lua

local gpu = peripheral.find("directgpu")
local display = gpu.createDisplayAuto()
local info = gpu.getDisplayInfo(display)

print("Webcam Viewer - " .. info.pixelWidth .. "x" .. info.pixelHeight)

local CAMERA_URL = "http://213.144.145.239:8090/cam_2.jpg"
local TARGET_FPS = 10

local function fetchFrame()
    -- Add a random param to bypass server/client cache
    local url = CAMERA_URL .. "?t=" .. math.random(1, 1000000)
    
    -- Make a blocking, binary HTTP request
    local handle = http.get(url, {}, true)  -- true = binary mode
    
    if not handle then return false end
    
    local imageData = handle.readAll()
    handle.close()
    
    if #imageData < 100 then return false end
    
    -- Load the binary data using dictionary compression
    local success, stats = pcall(function()
        return gpu.loadJPEGDict(display, imageData)
    end)
    
    if success then
        gpu.updateDisplay(display)
        -- Optional: print cache hit rate
        -- print(string.format("Cache: %.1f%%", stats.compressionRatio * 100))
    end
    
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

Touch Input Usage

Important: Touch input only works when not in any GUI:

    Run your Lua script in the CC computer

    Close the terminal (press E or Esc)

    Look at the physical monitor blocks in the world

    Click directly on the monitor to interact

Touch events use 3D raycasting against the rendered display surface. The input system automatically handles:

    Left and right mouse buttons

    Click, drag, and release events

    Coordinate translation to pixel space

    Event queuing per display

Coordinate System:

    Origin (0, 0) is at the top-left corner

    X increases to the right

    Y increases downward

    Coordinates are in pixels, not blocks

Performance Tips

    Batch drawing operations - Call updateDisplay() once after multiple changes

    Use primitives - drawRect() and drawLine() are faster than individual pixels

    Limit updates - Don't call updateDisplay() more than 60 times per second

    Clear efficiently - Use clear() instead of drawing black pixels

    Event polling - Add sleep() between event checks to reduce CPU usage

    Keep displays nearby - Maximum render distance is 64 blocks

    Clean up - Always call clearDisplay() when done

Technical Specifications

Specification	Value
Resolution per block	164×81 pixels
Color depth	24-bit RGB (8 bits/channel)
Maximum monitor size	8×6 blocks
Maximum total displays	50
Maximum total pixels	10 megapixels
Render distance	64 blocks
Memory per 1×1 display	~40 KB
Texture update rate	Limited to 60 FPS
Input latency	Sub-tick (<50ms)

Troubleshooting

"Display not found" error

    Ensure the monitor exists at the specified coordinates

    Use autoDetectMonitor() to verify monitor detection

    Check that monitors form a complete rectangle

Touch input not working

    Close the CC computer terminal first

    Make sure you're clicking on the physical monitor blocks in world

    Verify the display ID is correct

    Check hasEvent() returns true before calling pullEvent()

Low FPS or stuttering

    Reduce update frequency in your script

    Use smaller monitor arrays

    Batch drawing operations

    Check CPU usage with /forge tps

Image not loading

    Verify image data is valid (e.g., correct Base64 for loadImage or binary for loadJPEGDict)

    Check image format is PNG or JPEG

    Ensure image data isn't truncated

    Try a smaller test image first

Credits

Author: Tom (GitHub: @tiktop101) Minecraft Version: 1.20.1 Forge Version: 47.x.x ComputerCraft: CC: Tweaked

License

This project is licensed under the ARR License.

Support

    Issues: Report bugs on GitHub Issues

    Discord: Join the Minecraft Computer Mods Discord Server
