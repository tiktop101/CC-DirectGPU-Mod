# CC-DirectGPU-Mod
High-performance ComputerCraft peripheral for rendering full RGB graphics directly to monitors. Hardware-accelerated pixel manipulation at 164×81 resolution per block. Auto-detects monitors, supports drawing primitives, image loading, and touch input.

# DirectGPU

Forge 1.20.1

A high-performance ComputerCraft peripheral for rendering graphics directly to monitors using OpenGL, bypassing CC's text-based rendering system.

## Features

- **Direct pixel manipulation** - Set individual pixels with RGB colors (0-255)
- **High resolution** - 164×81 pixels per monitor block
- **Hardware accelerated** - Uses OpenGL textures for smooth rendering
- **Touch input support** - Mouse clicks and drags directly on monitor displays
- **Auto-detection** - Automatically finds and configures nearby monitors
- **Multi-size support** - Works with any rectangular monitor array (up to 8×6 blocks)
- **Drawing primitives** - Lines, rectangles, and image loading
- **Thread-safe** - Safe concurrent access from multiple computers

## Installation

1. Download the mod JAR
2. Place in your Minecraft `mods` folder
3. Requires **ComputerCraft** (or CC: Tweaked) and **Minecraft Forge**

## Quick Start

```lua
local gpu = peripheral.find("directgpu")

-- Auto-detect nearest monitor and create display
local id = gpu.createDisplayAuto()

-- Get display info
local info = gpu.getDisplayInfo(id)
print("Resolution: " .. info.pixelWidth .. "×" .. info.pixelHeight)

-- Draw a red pixel at (10, 10)
gpu.setPixel(id, 10, 10, 255, 0, 0)
gpu.updateDisplay(id)

-- Handle touch input
while true do
    if gpu.hasEvent(id) then
        local event = {gpu.pullEvent(id)}
        if event[1] == "mouse_click" then
            local x, y, button = event[2], event[3], event[4]
            print("Clicked at " .. x .. ", " .. y)
        end
    end
    sleep(0.05)
end

-- Clear display when done
gpu.clearDisplay()
```

## API Reference

### Display Management

#### `createDisplayAuto()` → `number`
Auto-detects the nearest monitor and creates a display.
- Returns: Display ID
- Throws: Error if no monitor found

#### `createDisplay(facing, width, height)` → `number`
Creates a display at computer position + 2 blocks up.
- `facing`: "north", "south", "east", "west", "up", "down"
- `width`, `height`: Monitor dimensions in blocks (max 8×6)
- Returns: Display ID

#### `createDisplayAt(x, y, z, facing, width, height)` → `number`
Creates a display at specific world coordinates.

#### `removeDisplay(displayId)` → `boolean`
Removes a specific display.

#### `clearDisplay()`
Removes all displays created by this computer.

#### `listDisplays()` → `table`
Returns array of all display IDs.

#### `getDisplayInfo(displayId)` → `table`
Returns display information:
```lua
{
  x, y, z,           -- World position
  facing,            -- Direction
  width, height,     -- Block dimensions
  pixelWidth,        -- Pixel width (width × 164)
  pixelHeight        -- Pixel height (height × 81)
}
```

### Drawing Functions

#### `setPixel(displayId, x, y, r, g, b)`
Sets a single pixel color (RGB: 0-255).

#### `getPixel(displayId, x, y)` → `table`
Returns `{r, g, b}` color of a pixel.

#### `clear(displayId, r, g, b)`
Fills entire display with a color.

#### `drawRect(displayId, x, y, width, height, r, g, b)`
Draws a filled rectangle.

#### `drawLine(displayId, x1, y1, x2, y2, r, g, b)`
Draws a line using Bresenham's algorithm.

#### `loadImage(displayId, base64Data)`
Loads an image from Base64-encoded PNG/JPG data.

#### `updateDisplay(displayId)`
Marks display as dirty to force a render update.

### Touch Input Functions

#### `pullEvent(displayId)` → `table` or `nil`
Retrieves the next input event from the event queue. Returns `nil` if no events are available.

**Mouse Events:**
```lua
-- Mouse click (left button)
{"mouse_click", x, y, button}

-- Mouse click (right button)
{"mouse_click_right", x, y, button}

-- Mouse drag (left button held)
{"mouse_drag", x, y, button}

-- Mouse drag (right button held)
{"mouse_drag_right", x, y, button}

-- Mouse button release (left)
{"mouse_up", x, y, button}

-- Mouse button release (right)
{"mouse_up_right", x, y, button}
```

**Keyboard Events:**
```lua
-- Key press
{"key", keyName}

-- Character typed
{"char", character}
```

**Parameters:**
- `x`, `y`: Pixel coordinates (0-indexed, 0,0 is top-left)
- `button`: Mouse button number (1=left, 2=right, 3=middle)
- `keyName`: CC key name (e.g., "enter", "space", "a")
- `character`: Typed character string

#### `hasEvent(displayId)` → `boolean`
Returns `true` if there are pending events in the queue.

#### `clearEvents(displayId)`
Clears all pending events from the queue.

#### `sendKey(displayId, keyName)`
Programmatically sends a key event to the display (useful for forwarding keyboard input from CC computers).
- `keyName`: CC key name string

#### `sendChar(displayId, character)`
Programmatically sends a character event to the display.
- `character`: Single character string

### Monitor Detection

#### `autoDetectMonitor()` → `table`
Finds the nearest monitor within 16 blocks.
```lua
{
  found,             -- boolean
  x, y, z,           -- Position
  width, height,     -- Dimensions
  facing             -- Direction
}
```

### Statistics

#### `getStats()` → `table`
Returns `{displays, totalPixels}`.

## Examples

### Drawing a Gradient
```lua
local gpu = peripheral.find("directgpu")
local id = gpu.createDisplayAuto()
local info = gpu.getDisplayInfo(id)

for y = 0, info.pixelHeight - 1 do
    for x = 0, info.pixelWidth - 1 do
        local r = math.floor((x / info.pixelWidth) * 255)
        local g = math.floor((y / info.pixelHeight) * 255)
        local b = 128
        gpu.setPixel(id, x, y, r, g, b)
    end
    if y % 20 == 0 then
        gpu.updateDisplay(id)
    end
end
gpu.updateDisplay(id)
```

### Drawing Shapes
```lua
local gpu = peripheral.find("directgpu")
local id = gpu.createDisplayAuto()

-- Red rectangle
gpu.drawRect(id, 10, 10, 50, 30, 255, 0, 0)

-- Blue line
gpu.drawLine(id, 0, 0, 100, 100, 0, 0, 255)

gpu.updateDisplay(id)
```

### Loading an Image
```lua
local gpu = peripheral.find("directgpu")
local id = gpu.createDisplayAuto()

-- Load Base64-encoded image
local imageData = "iVBORw0KGgoAAAANS..." -- Your Base64 data
gpu.loadImage(id, imageData)
gpu.updateDisplay(id)
```

### Interactive Drawing with Touch Input
```lua
local gpu = peripheral.find("directgpu")
local id = gpu.createDisplayAuto()
local info = gpu.getDisplayInfo(id)

-- Clear to white
gpu.clear(id, 255, 255, 255)
gpu.updateDisplay(id)

print("Draw on the monitor! (Close this terminal first)")
print("Press Ctrl+T to exit")

local lastX, lastY = nil, nil
local running = true

parallel.waitForAny(
    function()
        while running do
            if gpu.hasEvent(id) then
                local event = {gpu.pullEvent(id)}
                
                if event[1] == "mouse_click" then
                    local x, y = event[2], event[3]
                    -- Draw a dot
                    gpu.drawRect(id, x-2, y-2, 5, 5, 0, 0, 0)
                    lastX, lastY = x, y
                    gpu.updateDisplay(id)
                    
                elseif event[1] == "mouse_drag" then
                    local x, y = event[2], event[3]
                    -- Draw line from last position
                    if lastX and lastY then
                        gpu.drawLine(id, lastX, lastY, x, y, 0, 0, 0)
                    end
                    lastX, lastY = x, y
                    gpu.updateDisplay(id)
                    
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

### Button Example
```lua
local gpu = peripheral.find("directgpu")
local id = gpu.createDisplayAuto()

-- Draw a button
local buttonX, buttonY = 50, 50
local buttonW, buttonH = 100, 40

gpu.clear(id, 200, 200, 200)
gpu.drawRect(id, buttonX, buttonY, buttonW, buttonH, 100, 150, 255)
gpu.updateDisplay(id)

print("Click the blue button!")

while true do
    if gpu.hasEvent(id) then
        local event = {gpu.pullEvent(id)}
        
        if event[1] == "mouse_click" then
            local x, y = event[2], event[3]
            
            -- Check if click is inside button
            if x >= buttonX and x < buttonX + buttonW and
               y >= buttonY and y < buttonY + buttonH then
                print("Button clicked!")
                
                -- Flash button
                gpu.drawRect(id, buttonX, buttonY, buttonW, buttonH, 255, 200, 100)
                gpu.updateDisplay(id)
                sleep(0.2)
                gpu.drawRect(id, buttonX, buttonY, buttonW, buttonH, 100, 150, 255)
                gpu.updateDisplay(id)
            end
        end
    end
    sleep(0.05)
end
```

### Forwarding Keyboard Input
```lua
local gpu = peripheral.find("directgpu")
local id = gpu.createDisplayAuto()

-- Forward CC computer keyboard events to the display
parallel.waitForAny(
    function()
        while true do
            local event, param = os.pullEvent()
            
            if event == "key" then
                gpu.sendKey(id, keys.getName(param))
            elseif event == "char" then
                gpu.sendChar(id, param)
            end
        end
    end,
    function()
        -- Process display events
        while true do
            if gpu.hasEvent(id) then
                local event = {gpu.pullEvent(id)}
                
                if event[1] == "key" then
                    print("Key pressed: " .. event[2])
                elseif event[1] == "char" then
                    print("Character typed: " .. event[2])
                end
            end
            sleep(0.05)
        end
    end
)
```

## Touch Input Usage Notes

**Important:** Touch input only works when **not** viewing any GUI screen:

1. Start your Lua script in the computer terminal
2. **Close the terminal** (press E or Esc)
3. Look directly at the physical monitor in the world
4. Click and drag on the monitor blocks to interact

Touch events are captured by raycasting against the 3D rendered display in the world, not through the computer terminal interface. The input handler automatically handles clicks, drags, and releases for both left and right mouse buttons.

**Event Queue Behavior:**
- Events are queued per-display and processed in order
- Use `hasEvent()` to check before calling `pullEvent()` to avoid blocking
- Call `clearEvents()` to discard old events if needed
- Drag events are only fired when the mouse position changes

**Coordinate System:**
- Coordinates are in pixels, 0-indexed
- (0, 0) is at the top-left corner
- X increases to the right, Y increases downward

## Technical Details

- **Resolution**: 164×81 pixels per monitor block
- **Color depth**: 24-bit RGB (8 bits per channel)
- **Render distance**: 64 blocks maximum
- **Thread safety**: All operations are synchronized
- **Texture updates**: Automatic dirty checking for performance
- **Memory**: ~40KB per 1×1 monitor display
- **Input latency**: Sub-tick response time for mouse events
- **Event queue**: Thread-safe concurrent queues per display

## Performance Tips

1. **Batch updates**: Call `updateDisplay()` after multiple pixel changes, not after each one
2. **Use primitives**: `drawRect()` and `drawLine()` are faster than individual pixels
3. **Clear wisely**: Use `clear()` instead of setting each pixel
4. **Limit range**: Keep displays within 64 blocks for best performance
5. **Event polling**: Use `sleep()` between event checks to reduce CPU usage
6. **Queue management**: Clear old events with `clearEvents()` if they accumulate

## Compatibility

- Minecraft 1.20.1 (Forge)
- ComputerCraft / CC: Tweaked
- Works with any CC monitor size/configuration
- Touch input works with all monitor orientations (north, south, east, west, up, down)
