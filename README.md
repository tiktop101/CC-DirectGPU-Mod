# CC-DirectGPU-Mod
High-performance ComputerCraft peripheral for rendering full RGB graphics directly to monitors. Hardware-accelerated pixel manipulation at 164×81 resolution per block. Auto-detects monitors, supports drawing primitives and image loading.

# DirectGPU

Forge 1.20.1

A high-performance ComputerCraft peripheral for rendering graphics directly to monitors using OpenGL, bypassing CC's text-based rendering system.

## Features

- **Direct pixel manipulation** - Set individual pixels with RGB colors (0-255)
- **High resolution** - 164×81 pixels per monitor block
- **Hardware accelerated** - Uses OpenGL textures for smooth rendering
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

## Technical Details

- **Resolution**: 164×81 pixels per monitor block
- **Color depth**: 24-bit RGB (8 bits per channel)
- **Render distance**: 64 blocks maximum
- **Thread safety**: All operations are synchronized
- **Texture updates**: Automatic dirty checking for performance
- **Memory**: ~40KB per 1×1 monitor display

## Performance Tips

1. **Batch updates**: Call `updateDisplay()` after multiple pixel changes, not after each one
2. **Use primitives**: `drawRect()` and `drawLine()` are faster than individual pixels
3. **Clear wisely**: Use `clear()` instead of setting each pixel
4. **Limit range**: Keep displays within 64 blocks for best performance

## Compatibility

- Minecraft 1.20.1 (Forge)
- ComputerCraft / CC: Tweaked
- Works with any CC monitor size/configuration
