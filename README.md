# DirectGPU

A high-performance ComputerCraft peripheral for Minecraft that enables hardware-accelerated 2D and 3D graphics rendering directly to monitors. Stream images, create interactive UIs, render 3D models, or build pixel art - all at up to 656×324 resolution per block with 4x scaling.

## Features

### 2D Graphics
- **True RGB Graphics** - 24-bit color with 164×81 pixels per monitor block (up to 656×324 with 4x resolution multiplier)
- **Hardware Accelerated** - OpenGL rendering bypasses CC's text system for maximum performance
- **Drawing Primitives** - Fast lines, rectangles, circles, and pixel-perfect rendering
- **Built-in Font Rendering** - Multiple system fonts with anti-aliasing, styles, and sizes
- **Image Support** - Load JPEG images with hardware decoding (~5ms per frame)
- **Dictionary Compression** - Intelligent chunk-based caching reduces bandwidth by 90%+ for video

### 3D Graphics
- **3D Camera System** - Full perspective projection with position, rotation, and look-at
- **3D Primitives** - Cubes, spheres, pyramids with rotation and scaling
- **OBJ Model Loading** - Load and render .obj 3D models with texture support
- **Z-Buffer Depth Testing** - Proper depth sorting for complex 3D scenes
- **Texture Mapping** - UV-mapped textures on 3D models
- **Dynamic Lighting** - Directional lights with diffuse shading

### Interaction & Data
- **Touch Input** - Full mouse click, drag, hover, and keyboard event support with sub-tick latency
- **World Data Access** - Query time, weather, moon phase, biome, and game rules
- **Auto-Detection** - Automatically finds and configures nearby monitors in any orientation
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

### 2D Graphics
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

### 3D Graphics
```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplay()

-- Setup 3D camera
gpu.setupCamera(display, 60, 0.1, 1000)  -- FOV, near, far
gpu.setCameraPosition(display, 0, 0, 5)
gpu.setCameraRotation(display, 0, 0, 0)

-- Clear and draw a rotating cube
gpu.clear(display, 0, 0, 0)
gpu.clearZBuffer(display)

local rotation = 0
while true do
    gpu.clear(display, 0, 0, 0)
    gpu.clearZBuffer(display)
    
    -- Draw cube at origin with rotation
    gpu.drawCube(display, 0, 0, 0, 2, rotation, rotation, 0, 255, 100, 100)
    
    gpu.updateDisplay(display)
    rotation = rotation + 2
    sleep(0.05)
end
```

---

## API Reference

## Table of Contents
- [Display Management](#display-management)
- [2D Drawing Functions](#2d-drawing-functions)
- [Font Rendering](#font-rendering)
- [Image Loading](#image-loading)
- [Dictionary Compression](#dictionary-compression)
- [3D Rendering](#3d-rendering)
- [3D Models (OBJ Files)](#3d-models-obj-files)
- [Textures](#textures)
- [Lighting](#lighting)
- [Touch Input](#touch-input)
- [World Data](#world-data)
- [Examples](#examples)

---

## Display Management

### `autoDetectMonitor()` → info

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

---

### `autoDetectAndCreateDisplay()` → displayId

Automatically detects the nearest monitor and creates a display at 1x resolution.

```lua
local display = gpu.autoDetectAndCreateDisplay()
```

**Returns:** Display ID (number)  
**Throws:** Error if no monitor is found within 16 blocks

---

### `autoDetectAndCreateDisplayWithResolution(resolutionMultiplier)` → displayId

Same as above but with custom resolution scaling.

```lua
-- Create a 2x resolution display (328x162 pixels per block)
local display = gpu.autoDetectAndCreateDisplayWithResolution(2)
```

**Parameters:**
- `resolutionMultiplier` (number): 1-4 (1=164×81, 2=328×162, 3=492×243, 4=656×324 per block)

---

### `createDisplay(x, y, z, facing, width, height)` → displayId
### `createDisplayAt(x, y, z, facing, width, height)` → displayId

Creates a display at specific world coordinates with 1x resolution.

```lua
local display = gpu.createDisplay(100, 64, 200, "south", 4, 3)
```

**Parameters:**
- `x, y, z` (number): World coordinates of bottom-left corner
- `facing` (string): "north", "south", "east", "west", "up", "down"
- `width, height` (number): Monitor size in blocks (1-16)

---

### `createDisplayWithResolution(x, y, z, facing, width, height, resolutionMultiplier)` → displayId

Creates a display with custom resolution scaling.

```lua
local display = gpu.createDisplayWithResolution(100, 64, 200, "south", 3, 2, 2)
```

---

### `removeDisplay(displayId)` → success
### `clearAllDisplays()`
### `listDisplays()` → displayIds
### `getDisplayInfo(displayId)` → info
### `getResourceStats()` → stats

Standard display management functions. See original README for details.

---

## 2D Drawing Functions

### `setPixel(displayId, x, y, r, g, b)`

Sets a single pixel to RGB color (0-255).

```lua
gpu.setPixel(display, 100, 50, 255, 128, 0)
```

---

### `getPixel(displayId, x, y)` → {r, g, b}

Returns the RGB color of a pixel.

```lua
local r, g, b = table.unpack(gpu.getPixel(display, 100, 50))
```

---

### `clear(displayId, r, g, b)`

Fills entire display with solid color.

```lua
gpu.clear(display, 0, 0, 0)  -- Black
```

---

### `fillRect(displayId, x, y, width, height, r, g, b)`

Draws a filled rectangle.

```lua
gpu.fillRect(display, 10, 10, 100, 50, 255, 0, 0)
```

---

### `drawLine(displayId, x1, y1, x2, y2, r, g, b)`

Draws a line using Bresenham's algorithm.

```lua
gpu.drawLine(display, 0, 0, 163, 80, 255, 255, 255)
```

---

### `drawCircle(displayId, cx, cy, radius, r, g, b, filled)`

Draws a circle (filled or outline).

```lua
-- Filled red circle
gpu.drawCircle(display, 100, 100, 50, 255, 0, 0, true)

-- White circle outline
gpu.drawCircle(display, 100, 100, 50, 255, 255, 255, false)
```

**Parameters:**
- `cx, cy` (number): Center coordinates
- `radius` (number): Circle radius in pixels
- `r, g, b` (number): RGB color (0-255)
- `filled` (boolean): true for filled circle, false for outline

---

### `drawEllipse(displayId, cx, cy, rx, ry, r, g, b, filled)`

Draws an ellipse (filled or outline).

```lua
-- Filled blue ellipse
gpu.drawEllipse(display, 100, 100, 80, 40, 0, 0, 255, true)
```

**Parameters:**
- `cx, cy` (number): Center coordinates
- `rx, ry` (number): X and Y radii in pixels
- `r, g, b` (number): RGB color
- `filled` (boolean): true for filled, false for outline

---

### `updateDisplay(displayId)`

Marks display as dirty to trigger render update.

```lua
gpu.setPixel(display, 10, 10, 255, 0, 0)
gpu.updateDisplay(display)  -- Render changes
```

---

## Font Rendering

DirectGPU includes built-in system font rendering with anti-aliasing, multiple fonts, sizes, and styles.

### `drawText(displayId, text, x, y, r, g, b, fontName, fontSize, style)` → result

Renders text to the display with anti-aliasing.

```lua
local result = gpu.drawText(display, "Hello World!", 10, 10, 
    255, 255, 255,  -- White text
    "Arial", 24, "plain")

print(string.format("Text size: %dx%d", result.width, result.height))
```

**Parameters:**
- `displayId` (number): Target display
- `text` (string): Text to render
- `x, y` (number): Top-left position
- `r, g, b` (number): Text color (0-255)
- `fontName` (string): Font name (e.g., "Arial", "Times New Roman", "Courier New")
- `fontSize` (number): Font size in points
- `style` (string): "plain", "bold", "italic", or "bold_italic"

**Returns:**
```lua
{
    width = 120,     -- Rendered text width
    height = 24,     -- Rendered text height
    success = true
}
```

**Note:** Does not call `updateDisplay()`. Call it after rendering text.

---

### `measureText(text, fontName, fontSize, style)` → metrics

Measures text dimensions without rendering.

```lua
local metrics = gpu.measureText("Hello World!", "Arial", 24, "plain")
print(string.format("Text will be %dx%d pixels", metrics.width, metrics.height))
```

**Returns:**
```lua
{
    width = 120,     -- Text width in pixels
    height = 24,     -- Text height in pixels
    ascent = 20,     -- Distance from baseline to top
    descent = 4,     -- Distance from baseline to bottom
    success = true
}
```

**Use Case:** Layout calculation before rendering.

---

### `drawTextWithBg(displayId, text, x, y, fgR, fgG, fgB, bgR, bgG, bgB, padding, fontName, fontSize, style)` → result

Draws text with a background rectangle.

```lua
-- White text on dark blue background with 5px padding
gpu.drawTextWithBg(display, "Status: OK", 10, 10,
    255, 255, 255,  -- White foreground
    0, 0, 128,      -- Dark blue background
    5,              -- 5px padding
    "Arial", 16, "bold")
```

**Parameters:**
- First 7 parameters: Same as `drawText`
- `bgR, bgG, bgB` (number): Background color
- `padding` (number): Padding around text in pixels
- Last 3 parameters: Font settings

---

### `drawTextWrapped(displayId, text, x, y, maxWidth, r, g, b, lineSpacing, fontName, fontSize, style)` → result

Draws multi-line text with word wrapping.

```lua
local longText = "This is a long paragraph that will automatically wrap to fit within the specified width constraint."

local result = gpu.drawTextWrapped(display, longText, 
    10, 10,         -- Start position
    300,            -- Max width (will wrap at this width)
    255, 255, 255,  -- White text
    5,              -- 5px line spacing
    "Arial", 14, "plain")

print("Drew " .. result.linesDrawn .. " lines")
```

**Parameters:**
- `maxWidth` (number): Maximum width before wrapping
- `lineSpacing` (number): Vertical spacing between lines

**Returns:**
```lua
{
    linesDrawn = 4,  -- Number of lines rendered
    success = true
}
```

---

### `getAvailableFonts()` → fontNames

Returns list of all available system fonts.

```lua
local fonts = gpu.getAvailableFonts()
for i, font in ipairs(fonts) do
    print(i .. ": " .. font)
end
```

**Returns:** Array of font name strings

**Common Fonts:** "Arial", "Courier New", "Times New Roman", "Comic Sans MS", "Verdana", "Georgia", "Trebuchet MS"

---

### `clearFontCache()`

Clears the font rendering cache to free memory.

```lua
gpu.clearFontCache()
```

**Use Case:** Call after rendering many different font combinations to free memory.

---

## Image Loading

### `loadImage(displayId, imageData)`

Loads an image from Lua table format.

```lua
local imageData = {
    width = 100,
    height = 100,
    pixels = {
        {{255, 0, 0}, {0, 255, 0}, ...},  -- Row 1
        {{0, 0, 255}, {255, 255, 0}, ...},  -- Row 2
        ...
    }
}

gpu.loadImage(display, imageData)
gpu.updateDisplay(display)
```

---

### `decodeJPEG(jpegData)` → result

Decodes JPEG from binary data.

```lua
local handle = http.get("http://example.com/image.jpg", {}, true)
local jpegData = handle.readAll()
handle.close()

local result = gpu.decodeJPEG(jpegData)
print(string.format("Decoded: %dx%d in %dms", 
    result.width, result.height, result.decodeTime))
```

---

### `decodeAndScaleJPEG(jpegData, targetWidth, targetHeight)` → result

Decodes and scales JPEG in one operation (faster).

```lua
local info = gpu.getDisplayInfo(display)
local result = gpu.decodeAndScaleJPEG(jpegData, info.pixelWidth, info.pixelHeight)
```

---

### `getJPEGDimensions(jpegData)` → dimensions

Gets JPEG dimensions without full decode (<1ms).

```lua
local dims = gpu.getJPEGDimensions(jpegData)
print(string.format("Image: %dx%d", dims.width, dims.height))
```

---

### `loadJPEGRegion(displayId, jpegData, x, y, width, height)`

Decodes JPEG and blits to specific region.

```lua
gpu.loadJPEGRegion(display, jpegData, 0, 0, 320, 240)
gpu.updateDisplay(display)
```

---

## Dictionary Compression

### `compressWithDict(data)` → stats
### `decompressFromDict(hashes)` → data
### `hasChunk(hash)` → boolean
### `getChunk(hash)` → data
### `getDictionaryStats()` → stats
### `clearDictionary()`

See original README for dictionary compression details.

---

## 3D Rendering

DirectGPU includes a full 3D rendering engine with camera projection, primitives, and depth testing.

### `setupCamera(displayId, fov, near, far)` → result

Initializes the 3D camera for a display.

```lua
local result = gpu.setupCamera(display, 60, 0.1, 1000)
print("Aspect ratio: " .. result.aspect)
```

**Parameters:**
- `displayId` (number): Target display
- `fov` (number): Field of view in degrees (typically 45-90)
- `near` (number): Near clipping plane (typically 0.1)
- `far` (number): Far clipping plane (typically 100-1000)

**Returns:**
```lua
{
    success = true,
    aspect = 2.024  -- Calculated aspect ratio
}
```

**Note:** Must be called before any 3D drawing. Automatically calculates aspect ratio from display dimensions.

---

### `setCameraPosition(displayId, x, y, z)`

Sets the 3D camera position in world space.

```lua
gpu.setCameraPosition(display, 0, 2, 5)  -- 5 units back, 2 units up
```

**Parameters:**
- `x, y, z` (number): Camera position in 3D space

**Coordinate System:**
- X: Right (+) / Left (-)
- Y: Up (+) / Down (-)
- Z: Forward (-) / Back (+)

---

### `setCameraRotation(displayId, pitch, yaw, roll)`

Sets camera rotation angles in degrees.

```lua
gpu.setCameraRotation(display, -15, 45, 0)  -- Look down 15°, turn right 45°
```

**Parameters:**
- `pitch` (number): Rotation around X axis (look up/down)
- `yaw` (number): Rotation around Y axis (look left/right)
- `roll` (number): Rotation around Z axis (tilt)

**Angles:**
- Pitch: -90 (down) to 90 (up)
- Yaw: 0-360 (0=north, 90=east, 180=south, 270=west)
- Roll: -180 to 180

---

### `lookAt(displayId, targetX, targetY, targetZ)`

Points camera at a specific 3D point.

```lua
-- Look at origin from current position
gpu.lookAt(display, 0, 0, 0)

-- Look at a specific object
gpu.lookAt(display, objectX, objectY, objectZ)
```

**Parameters:**
- `targetX, targetY, targetZ` (number): Point to look at

**Note:** Automatically calculates pitch and yaw. Roll remains unchanged.

---

### `getCameraInfo(displayId)` → info

Returns current camera state.

```lua
local cam = gpu.getCameraInfo(display)
print(string.format("Camera at (%.1f, %.1f, %.1f)", cam.posX, cam.posY, cam.posZ))
print(string.format("Rotation: pitch=%.1f, yaw=%.1f", cam.pitch, cam.yaw))
```

**Returns:**
```lua
{
    posX = 0, posY = 2, posZ = 5,     -- Camera position
    pitch = -15, yaw = 45, roll = 0,  -- Camera rotation
    fov = 60,                          -- Field of view
    near = 0.1, far = 1000,           -- Clipping planes
    aspect = 2.024                     -- Aspect ratio
}
```

---

### `clearZBuffer(displayId)`

Clears the depth buffer for a new frame.

```lua
-- Typical 3D rendering loop
gpu.clear(display, 0, 0, 0)          -- Clear color
gpu.clearZBuffer(display)             -- Clear depth
-- ... draw 3D objects ...
gpu.updateDisplay(display)
```

**Important:** Call this at the start of each 3D frame to prevent depth artifacts.

---

### `drawCube(displayId, x, y, z, size, rotX, rotY, rotZ, r, g, b)`

Draws a 3D cube with rotation.

```lua
-- Draw a red cube at origin, rotated 45° on Y axis
gpu.drawCube(display, 0, 0, 0, 2, 0, 45, 0, 255, 0, 0)
```

**Parameters:**
- `x, y, z` (number): Cube center position
- `size` (number): Cube edge length
- `rotX, rotY, rotZ` (number): Rotation angles in degrees
- `r, g, b` (number): Cube color (0-255)

---

### `drawSphere(displayId, x, y, z, radius, segments, r, g, b)`

Draws a 3D sphere.

```lua
-- Draw a blue sphere with 16 segments (smoother)
gpu.drawSphere(display, 0, 0, 0, 1.5, 16, 0, 100, 255)
```

**Parameters:**
- `x, y, z` (number): Sphere center
- `radius` (number): Sphere radius
- `segments` (number): Detail level (8-32, higher = smoother but slower)
- `r, g, b` (number): Sphere color

**Performance:** 8-12 segments for real-time, 16-24 for quality, 32+ for screenshots.

---

### `drawPyramid(displayId, x, y, z, size, rotX, rotY, rotZ, r, g, b)`

Draws a 3D pyramid.

```lua
-- Draw a yellow pyramid
gpu.drawPyramid(display, 0, -1, 0, 2, 0, 0, 0, 255, 255, 0)
```

**Parameters:**
- `x, y, z` (number): Pyramid base center
- `size` (number): Base edge length
- `rotX, rotY, rotZ` (number): Rotation angles
- `r, g, b` (number): Pyramid color

---

### `clear3D(displayId)`

Clears all 3D state for a display (camera, z-buffer).

```lua
gpu.clear3D(display)
```

---

## 3D Models (OBJ Files)

DirectGPU can load and render industry-standard .obj 3D model files.

### `load3DModel(objData)` → modelId

Loads an OBJ model from string data.

```lua
local objFile = [[
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
...
]]

local modelId = gpu.load3DModel(objFile)
print("Loaded model: " .. modelId)
```

**Parameters:**
- `objData` (string): OBJ file content as string

**Returns:** Model ID (number)

**Supported OBJ Features:**
- Vertices (v)
- Normals (vn)
- Texture coordinates (vt)
- Faces (f) - triangles, quads, and polygons
- Groups (g) and objects (o)

---

### `load3DModelFromBytes(objData)` → modelId

Loads OBJ model from byte array.

```lua
local handle = http.get("http://example.com/model.obj", {}, true)
local objBytes = handle.readAll()
handle.close()

local modelId = gpu.load3DModelFromBytes(objBytes)
```

---

### `draw3DModel(displayId, modelId, x, y, z, rotX, rotY, rotZ, scale, r, g, b)`

Renders a loaded 3D model.

```lua
-- Draw model at origin, scaled 0.5x, with rotation
gpu.draw3DModel(display, modelId, 
    0, 0, 0,        -- Position
    0, 45, 0,       -- Rotation
    0.5,            -- Scale
    200, 200, 200)  -- Color
```

**Parameters:**
- `displayId` (number): Target display
- `modelId` (number): Model ID from `load3DModel`
- `x, y, z` (number): Model position
- `rotX, rotY, rotZ` (number): Rotation in degrees
- `scale` (number): Uniform scale factor
- `r, g, b` (number): Model color (modulates texture if present)

---

### `unload3DModel(modelId)` → success

Removes model from memory.

```lua
if gpu.unload3DModel(modelId) then
    print("Model unloaded")
end
```

**Returns:** true if model existed and was removed

---

### `get3DModelInfo(modelId)` → info

Returns model statistics.

```lua
local info = gpu.get3DModelInfo(modelId)
print(string.format("Model: %d vertices, %d faces", info.vertexCount, info.faceCount))
print("Has textures: " .. tostring(info.hasTexCoords))
```

**Returns:**
```lua
{
    name = "unnamed",        -- Model name from OBJ
    vertexCount = 1234,      -- Number of vertices
    faceCount = 678,         -- Number of faces
    hasNormals = true,       -- Has normal data
    hasTexCoords = false     -- Has UV coordinates
}
```

---

### `clearAll3DModels()`

Unloads all models from memory.

```lua
gpu.clearAll3DModels()
```

---

## Textures

Textures can be applied to 3D models for realistic rendering.

### `loadTexture(width, height, pixelData)` → textureId

Loads a texture from RGB byte array.

```lua
-- Create 2x2 checkerboard texture
local pixels = string.char(
    255, 0, 0,    0, 255, 0,   -- Red, Green
    0, 0, 255,    255, 255, 0  -- Blue, Yellow
)

local textureId = gpu.loadTexture(2, 2, pixels)
```

**Parameters:**
- `width, height` (number): Texture dimensions (power of 2 recommended)
- `pixelData` (string): Flat RGB byte array (width × height × 3 bytes)

**Returns:** Texture ID (number)

---

### `loadTextureFromImage(imageData)` → textureId

Loads texture from image data table.

```lua
local imageData = {
    width = 64,
    height = 64,
    pixels = "\xFF\x00\x00..."  -- RGB byte array
}

local textureId = gpu.loadTextureFromImage(imageData)
```

---

### `unloadTexture(textureId)` → success

Removes texture from memory.

```lua
gpu.unloadTexture(textureId)
```

---

### `getTextureInfo(textureId)` → info

Returns texture details.

```lua
local info = gpu.getTextureInfo(textureId)
print(string.format("Texture: %dx%d", info.width, info.height))
```

---

### `draw3DModelTextured(displayId, modelId, x, y, z, rotX, rotY, rotZ, scale, textureId)`

Renders a model with texture mapping.

```lua
-- Load model and texture
local modelId = gpu.load3DModel(objData)
local textureId = gpu.loadTextureFromImage(imageData)

-- Draw textured model
gpu.draw3DModelTextured(display, modelId,
    0, 0, 0,        -- Position
    0, 45, 0,       -- Rotation
    1.0,            -- Scale
    textureId)      -- Texture
```

**Note:** Model must have UV coordinates (vt in OBJ file).

---

## Lighting

Add realistic lighting to 3D scenes with directional lights.

### `addDirectionalLight(displayId, dirX, dirY, dirZ, r, g, b, intensity)`

Adds a directional light source (like the sun).

```lua
-- Add white light from above
gpu.addDirectionalLight(display, 
    0, -1, 0,       -- Direction (down)
    255, 255, 255,  -- White light
    0.8)            -- 80% intensity
```

**Parameters:**
- `displayId` (number): Target display
- `dirX, dirY, dirZ` (number): Light direction (automatically normalized)
- `r, g, b` (number): Light color (0-255)
- `intensity` (number): Light strength (0.0-1.0)

**Tips:**
- Direction points WHERE light is going (not where it comes from)
- Use intensity 0.6-1.0 for main lights
- Use intensity 0.2-0.4 for ambient/fill lights
- Multiple lights are additive

---

### `clearLights(displayId)`

Removes all lights from a display.

```lua
gpu.clearLights(display)
```

---

## Touch Input

### `hasEvents(displayId)` → boolean
### `pollEvent(displayId)` → event
### `clearEvents(displayId)`

Mouse and keyboard event handling. See original README for details.

**Event Types:**
- `mouse_click` - Button pressed
- `mouse_drag` - Mouse moved while button held
- `mouse_up` - Button released
- `mouse_enter` - Mouse entered display area
- `mouse_leave` - Mouse left display area
- `mouse_move` - Mouse moved (no button)

---

## World Data

Query Minecraft world information directly from Lua.

### `getWorldInfo()` → info

Returns comprehensive world state.

```lua
local world = gpu.getWorldInfo()
print("Time: " .. world.timeOfDay)
print("Weather: " .. (world.isRaining and "Rain" or "Clear"))
print("Moon: " .. world.moonPhaseName)
print("Dimension: " .. world.dimension)
```

**Returns:**
```lua
{
    -- Time
    worldTime = 24000,           -- Total ticks since world creation
    dayTime = 6000,              -- Time of current day (0-24000)
    isDay = true,                -- Is it daytime?
    isNight = false,             -- Is it nighttime?
    timeOfDay = "12:00",         -- Human-readable time
    
    -- Weather
    isRaining = false,           -- Is it raining?
    isThundering = false,        -- Is there a thunderstorm?
    rainLevel = 0.0,             -- Rain intensity (0.0-1.0)
    thunderLevel = 0.0,          -- Thunder intensity (0.0-1.0)
    
    -- Moon
    moonPhase = 0,               -- Moon phase (0-7)
    moonPhaseName = "Full Moon", -- Human-readable phase
    
    -- Dimension
    dimension = "minecraft:overworld",
    isOverworld = true,
    isNether = false,
    isEnd = false,
    
    -- Game Settings
    difficulty = "normal",       -- easy/normal/hard/peaceful
    difficultyLocked = false,
    doDaylightCycle = true,      -- Game rule
    doWeatherCycle = true,       -- Game rule
    doMobSpawning = true         -- Game rule
}
```

**Use Cases:**
- Display current time/date
- Weather-based effects
- Moon phase tracker
- Dimension-aware programs

---

### `getWeather()` → weather

Returns current weather state.

```lua
local weather = gpu.getWeather()
if weather.state == "thundering" then
    print("Take shelter!")
elseif weather.state == "raining" then
    print("Bring an umbrella")
end
```

**Returns:**
```lua
{
    isRaining = true,
    isThundering = false,
    rainLevel = 0.8,        -- 0.0-1.0
    thunderLevel = 0.0,     -- 0.0-1.0
    state = "raining"       -- "clear", "raining", "thundering"
}
```

---

### `getTimeInfo()` → timeInfo

Returns detailed time information.

```lua
local time = gpu.getTimeInfo()
print(string.format("Day %d, %s", time.dayCount, time.timeString))
```

**Returns:**
```lua
{
    worldTime = 48000,      -- Total ticks
    dayTime = 6000,         -- Current day time (0-24000)
    dayCount = 2,           -- Days elapsed
    isDay = true,
    isNight = false,
    hours = 12,             -- 0-23
    minutes = 0,            -- 0-59
    timeString = "12:00"
}
```

**Note:** Minecraft day cycle: 0=6am, 6000=noon, 12000=6pm, 18000=midnight

---

### `getMoonInfo()` → moonInfo

Returns moon phase information.

```lua
local moon = gpu.getMoonInfo()
print("Tonight's moon: " .. moon.phaseName)
```

**Returns:**
```lua
{
    phase = 0,                  -- 0-7
    phaseName = "Full Moon",    -- Name string
    brightness = 1.0            -- Light level (0.25-1.0)
}
```

**Moon Phases:** Full Moon (0), Waning Gibbous (1), Last Quarter (2), Waning Crescent (3), New Moon (4), Waxing Crescent (5), First Quarter (6), Waxing Gibbous (7)

---

### `getDimension()` → dimensionName

Returns current dimension ID.

```lua
local dim = gpu.getDimension()
if dim == "minecraft:the_nether" then
    print("We're in the Nether!")
end
```

**Common Values:**
- `"minecraft:overworld"`
- `"minecraft:the_nether"`
- `"minecraft:the_end"`

---

### `getBiomeAt(x, y, z)` → biomeInfo

Returns biome information at specific coordinates.

```lua
local biome = gpu.getBiomeAt(100, 64, 200)
print("Biome: " .. biome.name)
print("Temperature: " .. biome.temperature)
```

**Parameters:**
- `x, y, z` (number): World coordinates

**Returns:**
```lua
{
    name = "minecraft:plains",           -- Biome ID
    temperature = 0.8,                   -- Temperature value
    hasPrecipitation = true,             -- Can rain/snow here?
    precipitationType = "rain"           -- "rain", "snow", or "none"
}
```

**Use Cases:**
- Biome-specific displays
- Weather prediction
- Environmental monitoring stations

---

## Examples

### Example 1: 3D Spinning Cube

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplay()

-- Setup 3D
gpu.setupCamera(display, 60, 0.1, 1000)
gpu.setCameraPosition(display, 0, 0, 5)

-- Add lighting
gpu.addDirectionalLight(display, 0, -1, 0, 255, 255, 255, 0.8)

local rotation = 0
print("Press Q to stop")

local running = true
parallel.waitForAny(
    function()
        while running do
            -- Clear frame
            gpu.clear(display, 20, 20, 40)
            gpu.clearZBuffer(display)
            
            -- Draw spinning cube
            gpu.drawCube(display, 0, 0, 0, 2, rotation, rotation * 1.5, 0, 
                255, 100, 100)
            
            gpu.updateDisplay(display)
            rotation = rotation + 2
            sleep(0.05)
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

---

### Example 2: Text Display with Fonts

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplay()

-- Clear to dark background
gpu.clear(display, 30, 30, 30)

-- Title
gpu.drawText(display, "DirectGPU Demo", 10, 10, 
    255, 200, 100, "Arial", 32, "bold")

-- Body text with wrapping
local text = "DirectGPU brings hardware-accelerated graphics to ComputerCraft. "..
    "Render 2D graphics, 3D models, and interactive UIs at high resolution."

gpu.drawTextWrapped(display, text, 10, 60, 450,
    200, 200, 200, 8, "Arial", 16, "plain")

-- Status box
gpu.drawTextWithBg(display, "Status: Ready", 10, 150,
    0, 255, 0,      -- Green text
    0, 50, 0,       -- Dark green background
    8,              -- Padding
    "Courier New", 14, "bold")

gpu.updateDisplay(display)

print("Press any key to continue...")
os.pullEvent("key")
gpu.clearAllDisplays()
```

---

### Example 3: 3D Model Viewer

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplay()

-- Load your OBJ model
local modelData = [[
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
f 2 6 7 3
f 3 7 8 4
f 4 8 5 1
]]

local modelId = gpu.load3DModel(modelData)
local info = gpu.get3DModelInfo(modelId)
print(string.format("Loaded: %d vertices, %d faces", info.vertexCount, info.faceCount))

-- Setup 3D
gpu.setupCamera(display, 60, 0.1, 1000)
gpu.setCameraPosition(display, 0, 0, 5)

-- Add two lights
gpu.addDirectionalLight(display, 0, -1, -0.5, 255, 255, 255, 0.8)  -- Main
gpu.addDirectionalLight(display, 1, 0, 0, 100, 100, 150, 0.3)      -- Fill

local rotation = 0
print("Model viewer - Press Q to quit")

local running = true
parallel.waitForAny(
    function()
        while running do
            gpu.clear(display, 0, 0, 0)
            gpu.clearZBuffer(display)
            
            gpu.draw3DModel(display, modelId,
                0, 0, 0,            -- Position
                20, rotation, 0,    -- Rotation
                1.0,                -- Scale
                200, 200, 255)      -- Color
            
            gpu.updateDisplay(display)
            rotation = rotation + 1
            sleep(0.05)
        end
    end,
    function()
        while running do
            local event, key = os.pullEvent("key")
            if key == keys.q then running = false end
        end
    end
)

gpu.unload3DModel(modelId)
gpu.clearAllDisplays()
```

---

### Example 4: Weather Display

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplay()
local info = gpu.getDisplayInfo(display)

local function drawWeatherDisplay()
    local world = gpu.getWorldInfo()
    local time = gpu.getTimeInfo()
    local weather = gpu.getWeather()
    
    -- Background based on time
    local bgColor
    if time.isDay then
        bgColor = weather.isRaining and {100, 100, 120} or {135, 206, 235}
    else
        bgColor = {20, 20, 40}
    end
    
    gpu.clear(display, table.unpack(bgColor))
    
    -- Time
    gpu.drawTextWithBg(display, "Time: " .. time.timeString, 10, 10,
        255, 255, 255, 0, 0, 0, 8, "Arial", 24, "bold")
    
    -- Date
    gpu.drawText(display, "Day " .. time.dayCount, 10, 50,
        220, 220, 220, "Arial", 18, "plain")
    
    -- Weather
    local weatherText = "Weather: " .. weather.state:gsub("^%l", string.upper)
    local weatherColor = weather.isThundering and {255, 255, 0} or 
                        weather.isRaining and {100, 150, 255} or {255, 255, 255}
    
    gpu.drawText(display, weatherText, 10, 90,
        weatherColor[1], weatherColor[2], weatherColor[3],
        "Arial", 20, "bold")
    
    -- Moon phase
    gpu.drawText(display, "Moon: " .. world.moonPhaseName, 10, 130,
        200, 200, 200, "Arial", 16, "plain")
    
    -- Biome at GPU block
    local biome = gpu.getBiomeAt(info.x, info.y, info.z)
    local biomeName = biome.name:match("minecraft:(.+)") or biome.name
    gpu.drawText(display, "Biome: " .. biomeName:gsub("_", " "), 10, 160,
        180, 255, 180, "Arial", 16, "plain")
    
    gpu.updateDisplay(display)
end

print("Weather Display - Press Ctrl+T to exit")

while true do
    drawWeatherDisplay()
    sleep(1)  -- Update every second
end
```

---

### Example 5: Interactive 3D Scene with Mouse

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplay()

-- Setup 3D
gpu.setupCamera(display, 60, 0.1, 1000)
gpu.setCameraPosition(display, 0, 2, 8)
gpu.addDirectionalLight(display, 0, -1, 0, 255, 255, 255, 0.8)

-- Scene objects
local objects = {
    {type="cube", x=-2, y=0, z=0, size=1.5, color={255,100,100}},
    {type="sphere", x=0, y=0, z=0, size=1, color={100,255,100}},
    {type="pyramid", x=2, y=0, z=0, size=1.5, color={100,100,255}}
}

local selectedIndex = nil
local rotation = 0

local function drawScene()
    gpu.clear(display, 20, 20, 30)
    gpu.clearZBuffer(display)
    
    for i, obj in ipairs(objects) do
        local rot = (selectedIndex == i) and rotation or 0
        local col = obj.color
        
        -- Highlight selected object
        if selectedIndex == i then
            col = {math.min(255, col[1] + 50), 
                   math.min(255, col[2] + 50), 
                   math.min(255, col[3] + 50)}
        end
        
        if obj.type == "cube" then
            gpu.drawCube(display, obj.x, obj.y, obj.z, obj.size, 
                rot, rot, 0, col[1], col[2], col[3])
        elseif obj.type == "sphere" then
            gpu.drawSphere(display, obj.x, obj.y, obj.z, obj.size, 
                12, col[1], col[2], col[3])
        elseif obj.type == "pyramid" then
            gpu.drawPyramid(display, obj.x, obj.y, obj.z, obj.size, 
                rot, rot, 0, col[1], col[2], col[3])
        end
    end
    
    -- Instructions
    gpu.drawTextWithBg(display, "Click objects to select", 10, 10,
        255, 255, 255, 0, 0, 0, 5, "Arial", 14, "plain")
    
    if selectedIndex then
        gpu.drawTextWithBg(display, "Selected: " .. objects[selectedIndex].type, 
            10, 40, 255, 255, 100, 50, 50, 0, 5, "Arial", 14, "bold")
    end
    
    gpu.updateDisplay(display)
end

print("Interactive 3D Scene")
print("Close terminal and click objects")
print("Press Q to quit")

local running = true

parallel.waitForAny(
    -- Render loop
    function()
        while running do
            drawScene()
            if selectedIndex then
                rotation = rotation + 2
            end
            sleep(0.05)
        end
    end,
    
    -- Input loop
    function()
        while running do
            if gpu.hasEvents(display) then
                local event = gpu.pollEvent(display)
                if event.type == "mouse_click" then
                    -- Simple object selection (normally you'd do ray-object intersection)
                    local info = gpu.getDisplayInfo(display)
                    local clickX = event.x / info.pixelWidth
                    
                    if clickX < 0.33 then
                        selectedIndex = 1
                        print("Selected: Cube")
                    elseif clickX < 0.66 then
                        selectedIndex = 2
                        print("Selected: Sphere")
                    else
                        selectedIndex = 3
                        print("Selected: Pyramid")
                    end
                end
            end
            sleep(0.05)
        end
    end,
    
    -- Exit handler
    function()
        while running do
            local event, key = os.pullEvent("key")
            if key == keys.q then running = false end
        end
    end
)

gpu.clearAllDisplays()
```

---

### Example 6: Real-Time Clock with Graphics

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplayWithResolution(2)
local info = gpu.getDisplayInfo(display)

local centerX = info.pixelWidth / 2
local centerY = info.pixelHeight / 2
local clockRadius = math.min(centerX, centerY) - 20

local function drawClock()
    local time = gpu.getTimeInfo()
    local world = gpu.getWorldInfo()
    
    -- Background (sky color based on time)
    local bgR, bgG, bgB
    if time.isDay then
        bgR, bgG, bgB = 135, 206, 235  -- Day sky
    else
        bgR, bgG, bgB = 20, 20, 40     -- Night sky
    end
    gpu.clear(display, bgR, bgG, bgB)
    
    -- Clock face
    gpu.drawCircle(display, centerX, centerY, clockRadius, 255, 255, 255, true)
    gpu.drawCircle(display, centerX, centerY, clockRadius, 0, 0, 0, false)
    
    -- Hour marks
    for i = 0, 11 do
        local angle = math.rad(i * 30 - 90)
        local x1 = centerX + math.cos(angle) * (clockRadius - 15)
        local y1 = centerY + math.sin(angle) * (clockRadius - 15)
        local x2 = centerX + math.cos(angle) * (clockRadius - 5)
        local y2 = centerY + math.sin(angle) * (clockRadius - 5)
        gpu.drawLine(display, x1, y1, x2, y2, 0, 0, 0)
    end
    
    -- Hour hand
    local hourAngle = math.rad((time.hours % 12) * 30 + time.minutes * 0.5 - 90)
    local hourX = centerX + math.cos(hourAngle) * (clockRadius * 0.5)
    local hourY = centerY + math.sin(hourAngle) * (clockRadius * 0.5)
    gpu.drawLine(display, centerX, centerY, hourX, hourY, 0, 0, 0)
    
    -- Minute hand
    local minAngle = math.rad(time.minutes * 6 - 90)
    local minX = centerX + math.cos(minAngle) * (clockRadius * 0.7)
    local minY = centerY + math.sin(minAngle) * (clockRadius * 0.7)
    gpu.drawLine(display, centerX, centerY, minX, minY, 255, 0, 0)
    
    -- Center dot
    gpu.drawCircle(display, centerX, centerY, 5, 0, 0, 0, true)
    
    -- Digital time display
    gpu.drawTextWithBg(display, time.timeString, centerX - 40, 
        info.pixelHeight - 50, 255, 255, 255, 0, 0, 0, 8, 
        "Arial", 24, "bold")
    
    -- Date and weather
    local dateStr = string.format("Day %d - %s", time.dayCount, world.moonPhaseName)
    gpu.drawText(display, dateStr, centerX - 80, info.pixelHeight - 20,
        200, 200, 200, "Arial", 14, "plain")
    
    gpu.updateDisplay(display)
end

print("Minecraft Clock - Press Ctrl+T to exit")

while true do
    drawClock()
    sleep(0.5)  -- Update twice per second
end
```

---

## Performance Tips

### 2D Graphics Optimization

1. **Batch drawing operations:**
```lua
-- Good: 1 update
for i = 1, 1000 do
    gpu.setPixel(display, x, y, r, g, b)
end
gpu.updateDisplay(display)

-- Bad: 1000 updates
for i = 1, 1000 do
    gpu.setPixel(display, x, y, r, g, b)
    gpu.updateDisplay(display)  -- Too many!
end
```

2. **Use primitives over pixels:**
```lua
-- Faster
gpu.fillRect(display, x, y, 100, 50, r, g, b)

-- Slower
for py = y, y + 50 do
    for px = x, x + 100 do
        gpu.setPixel(display, px, py, r, g, b)
    end
end
```

3. **Limit frame rate:**
```lua
local lastUpdate = 0
while running do
    -- ... drawing code ...
    
    local now = os.clock()
    if now - lastUpdate >= 1/60 then  -- Max 60 FPS
        gpu.updateDisplay(display)
        lastUpdate = now
    end
end
```

### 3D Graphics Optimization

1. **Use appropriate detail levels:**
```lua
-- Close objects: high detail
gpu.drawSphere(display, x, y, z, radius, 24, r, g, b)

-- Far objects: low detail
gpu.drawSphere(display, x, y, z, radius, 8, r, g, b)
```

2. **Minimize state changes:**
```lua
-- Good: Group by type
for _, cube in ipairs(cubes) do
    gpu.drawCube(display, ...)
end
for _, sphere in ipairs(spheres) do
    gpu.drawSphere(display, ...)
end

-- Less efficient: Mixed types
for _, obj in ipairs(objects) do
    if obj.type == "cube" then gpu.drawCube(...)
    elseif obj.type == "sphere" then gpu.drawSphere(...) end
end
```

3. **Always clear Z-buffer:**
```lua
-- Required at start of each 3D frame
gpu.clear(display, 0, 0, 0)
gpu.clearZBuffer(display)
```

### Resolution and Memory

```lua
-- Memory usage per block:
-- 1x: ~40 KB   (164×81)
-- 2x: ~160 KB  (328×162) - Recommended for HD
-- 4x: ~640 KB  (656×324) - Only for small displays

-- Use appropriate resolution
local display = gpu.autoDetectAndCreateDisplayWithResolution(2)
```

### Video Streaming

```lua
-- Use dictionary compression for >90% bandwidth reduction
local stats = gpu.compressWithDict(jpegData)
-- First frame: ~100 KB
-- Subsequent: ~10 KB (90% cache hit)

-- Target 10-15 FPS for smooth video
sleep(1 / 10)
```

---

## Troubleshooting

### Common Issues

**"Display not found" or "No monitor found"**
- Monitors must form complete rectangle
- Maximum 16 blocks away
- Must be CC monitors

```lua
local info = gpu.autoDetectMonitor()
print("Found: " .. tostring(info.found))
```

**"Resource limits exceeded"**
- Max 50 displays
- Max 10 megapixels total

```lua
local stats = gpu.getResourceStats()
print(string.format("Usage: %.1f%%", stats.pixelUsagePercent))
gpu.clearAllDisplays()  -- Free resources
```

**Touch input not working**
- Close CC terminal (press E)
- Click physical monitor blocks
- Verify display exists

**Low FPS / Stuttering**
- Reduce resolution multiplier
- Use smaller monitors
- Limit update rate
- Reduce 3D detail level

**3D objects not rendering**
- Call `setupCamera()` first
- Call `clearZBuffer()` each frame
- Check camera position (not inside objects)
- Verify objects are in view frustum

**Textures not loading**
- Model must have UV coordinates (vt in OBJ)
- Texture dimensions should be power of 2
- Use `getTextureInfo()` to verify load

---

## Technical Specifications

| Specification | Value |
|---------------|-------|
| **Resolution (1x-4x)** | 164×81 to 656×324 pixels/block |
| **Color depth** | 24-bit RGB (16.7M colors) |
| **Max monitor size** | 16×16 blocks |
| **Max displays** | 50 per world |
| **Max total pixels** | 10 megapixels |
| **Render distance** | 64 blocks |
| **Update rate** | 60 FPS (hardware limited) |
| **Input latency** | <50ms |
| **JPEG decode** | 5-15ms (hardware accelerated) |
| **3D primitives** | Cube, Sphere, Pyramid |
| **3D file format** | OBJ (with textures) |
| **Lighting** | Directional lights, diffuse shading |
| **Font rendering** | System fonts with anti-aliasing |

---

## Credits

**Author:** Tom  
**Minecraft Version:** 1.20.1  
**Forge Version:** 47.3.0+  
**CC: Tweaked Version:** 1.20.1  

**Special Thanks:**
- Minecraft Forge team
- CC: Tweaked developers
- DirectGPU community testers

---

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

## Support & Community

- **Issues:** Report bugs on GitHub
- **Discord:** https://discord.gg/DHbQ7Xurpv
- **Documentation:** This README + in-game examples

---
