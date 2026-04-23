# DirectGPU , VS Compatible

<div align="center">

**High-Performance Graphics for ComputerCraft**

[![Minecraft](https://img.shields.io/badge/Minecraft-1.20.1-green.svg)](https://www.minecraft.net/)
[![CC: Tweaked](https://img.shields.io/badge/CC%3A%20Tweaked-1.20.1-blue.svg)](https://tweaked.cc/)
[![License](https://img.shields.io/badge/License-ARR-red.svg)](LICENSE)

Turn ComputerCraft monitors into high-resolution RGB displays with fast 2D drawing, 3D rendering, JPEG loading, input events, controller support, and extra world data.

[Download](https://github.com/tiktop101/CC-DirectGPU-Mod/releases/) • [Examples](https://github.com/tiktop101/CC-DirectGPU-Mod/tree/main/Examples) • [Discord](https://discord.gg/zr2CScq7Gf)

</div>

---

## What this mod is

DirectGPU is a ComputerCraft peripheral that lets Lua draw directly to monitor-backed displays in full RGB instead of the normal terminal palette.

You can use it for:

- high-resolution 2D UI
- images and JPEG viewers
- 3D scenes and OBJ models
- controller-driven programs and games
- touch input
- custom dashboards and world displays

It works with normal monitors, supports Valkyrien Skies compatibility, and is meant for cases where vanilla monitor text is too limited.

---

## Quick answers to common questions

### What is a `displayId`?

A `displayId` is the number returned when you create a display.
You use that number in later calls so DirectGPU knows **which display** to draw to.

```lua
local displayId = gpu.autoDetectAndCreateDisplay()
gpu.clear(displayId, 0, 0, 0)
gpu.updateDisplay(displayId)
```

### What is a `textureId`?

A `textureId` is the number returned by `loadTexture()` or `loadTextureFromImage()`.
It is just a handle for a loaded texture.

You do **not** pass the raw image every frame after that. You load it once, get a `textureId`, and then reference that texture later.

```lua
local textureId = gpu.loadTexture(width, height, base64PixelData)
print(textureId)
```

### What is `base64PixelData`?

It is your raw image pixel bytes encoded as a Base64 string.

For textures, that usually means the pixel bytes for the image packed into a string, then Base64 encoded so it can be passed through Lua more easily.

Think of it like this:

1. you have raw pixel bytes
2. you encode them as Base64
3. you send that string to DirectGPU
4. DirectGPU decodes it and stores it as a texture

### What is `imageData`?

`imageData` is a table containing:

- `width`
- `height`
- `pixels`

The code expects all 3 to exist.

```lua
local imageData = {
    width = 64,
    height = 64,
    pixels = someByteArray
}
```

`loadTextureFromImage(imageData)` uses that table to create a texture.

### What is `pointsObj`?

`pointsObj` is a Lua table of points used by polygon, polyline, and bezier functions.

Use it like this:

```lua
local points = {
    {10, 10},
    {50, 20},
    {80, 60},
    {20, 90}
}

gpu.drawPolylines(displayId, points, 255, 255, 255)
```

For most cases, just treat it as:

```lua
{{x1, y1}, {x2, y2}, {x3, y3}}
```

### What fonts are supported?

Text rendering uses your **system fonts**.
So if your PC has a font installed, DirectGPU can usually use it.

You can also ask DirectGPU for the available font list:

```lua
local fonts = gpu.getAvailableFonts()
for i = 1, math.min(#fonts, 20) do
    print(fonts[i])
end
```

### In multiplayer, do other players need the same font installed?

Normally no for the final display output itself, because what ends up on the display is rendered pixels.
The display shows the result, not the other player's local font list.

### Why do I need `updateDisplay()`?

Most drawing functions modify the display buffer.
`updateDisplay(displayId)` pushes that finished frame to the actual display.

A common pattern is:

```lua
gpu.clear(displayId, 0, 0, 0)
-- draw stuff
gpu.updateDisplay(displayId)
```

---

## Features

### 2D graphics

- 24-bit RGB color
- high resolution displays
- lines, rectangles, circles, ellipses, polygons, stars, rounded rects, bezier curves, SVG-like paths
- text rendering with system fonts
- pixel reads and writes

### 3D graphics

- camera setup and positioning
- z-buffer support
- cubes, spheres, pyramids
- OBJ model loading
- textured models
- ambient and directional lighting
- optional phong shading and backface culling

### Images

- JPEG decoding
- scaled JPEG decoding
- fullscreen and region JPEG loading
- texture loading from raw image data
- cache and network helper functions

### Input and interaction

- display mouse/touch events
- controller input and mappings
- server-side controller queries
- calibration helpers

### Other extras

- world info queries
- map reader peripheral
- metaballs
- vector graphics helpers

---

## Installation

1. Download the latest DirectGPU jar from [releases](https://github.com/tiktop101/CC-DirectGPU-Mod/releases/)
2. Put it in your Minecraft `mods` folder
3. Make sure you also have:
   - Minecraft `1.20.1`
   - Forge `47.3.0+`
   - CC: Tweaked `1.20.1` (`1.116.1` recommended)
4. Launch the game and place/craft the DirectGPU block

### Recipe

```text
[Iron]     [Gold]      [Iron]
[Redstone] [Computer]  [Redstone]
[Iron]     [Redstone]  [Iron]
```

Required:

- 4× Iron Ingots
- 1× Gold Ingot
- 3× Redstone Dust
- 1× normal ComputerCraft computer

---

## Quick start

### Minimal 2D example

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplay()

gpu.clear(display, 20, 20, 30)
gpu.fillRect(display, 10, 10, 80, 40, 255, 0, 0)
gpu.drawText(display, "Hello DirectGPU", 12, 65, 255, 255, 255, "Arial", 18, "bold")
gpu.updateDisplay(display)
```

### Minimal 3D example

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplay()

gpu.setupCamera(display, 60, 0.1, 1000)
gpu.setCameraPosition(display, 0, 2, 5)
gpu.addAmbientLight(display, 60, 60, 60, 0.3)
gpu.addDirectionalLight(display, 0, -1, 0, 255, 255, 255, 0.8)

local rot = 0
while true do
    gpu.clear(display, 0, 0, 0)
    gpu.clearZBuffer(display)
    gpu.drawCube(display, 0, 0, 0, 2, rot, rot, 0, 255, 120, 120)
    gpu.updateDisplay(display)
    rot = rot + 2
    sleep(0.05)
end
```

---

### 1. Create a display

You either auto-detect a monitor or manually create a display.

### 2. Draw into its buffer

Functions like `clear`, `fillRect`, `drawText`, `drawCube`, and `loadJPEGFullscreen` write to that display's internal framebuffer.

### 3. Push the frame

Call `updateDisplay(displayId)` when you want the current frame shown.

### 4. Reuse loaded resources

Things like textures and models return ids. Keep those ids and reuse them instead of reloading constantly.

---

## Data formats and terminology

### Colors

Most color parameters are standard RGB integer values:

```lua
r, g, b
```

Each channel is usually `0` to `255`.

Examples:

- red = `255, 0, 0`
- green = `0, 255, 0`
- blue = `0, 0, 255`
- white = `255, 255, 255`
- black = `0, 0, 0`

### Coordinates

For 2D drawing, positions are pixel coordinates on the display.

```lua
x, y
```

Top-left is the usual starting point.

### Point lists

Functions using `pointsObj` expect a Lua table of point tables.

```lua
local pts = {
    {0, 0},
    {20, 30},
    {40, 10}
}
```

### Image pixel data

For textures and map/image style operations, image data is raw pixel bytes plus width/height metadata.

### Model ids and texture ids

If a function loads something and returns a number, that number is usually an id you store and use later.

---

## API reference

## Display management

### `autoDetectAndCreateDisplay()` → `number`

Finds a nearby monitor automatically, creates a DirectGPU display for it, and returns the new `displayId`.

```lua
local displayId = gpu.autoDetectAndCreateDisplay()
```

### `autoDetectAndCreateDisplayWithResolution(resolutionMultiplier)` → `number`

Same as above, but lets you pick the resolution multiplier when creating the display.

```lua
local displayId = gpu.autoDetectAndCreateDisplayWithResolution(0)
```

### `autoDetectMonitor()` → `string`

Returns the detected monitor peripheral name.
Useful if you want to know what monitor would be used.

```lua
local monitorName = gpu.autoDetectMonitor()
```

### `clearAllDisplays()`

Removes every DirectGPU display owned by this GPU block.

```lua
gpu.clearAllDisplays()
```

### `createDisplay(x, y, z, facing, width, height)` → `number`

Creates a display manually at a specific position and facing.
Returns the new `displayId`.

```lua
local displayId = gpu.createDisplay(0, 64, 0, "north", 3, 2)
```

### `createDisplayAt(x, y, z, facing, width, height)` → `number`

Manual display creation helper. Use it the same way as `createDisplay` if you want to specify exact placement.

```lua
local displayId = gpu.createDisplayAt(0, 64, 0, "north", 3, 2)
```

### `createDisplayWithResolution(x, y, z, facing, width, height, resolutionMultiplier)` → `number`

Manual display creation with a custom resolution multiplier.
Higher settings mean more pixels.

```lua
local displayId = gpu.createDisplayWithResolution(0, 64, 0, "north", 3, 2, 1)
```

### `getDisplayInfo(displayId)` → `table`

Returns info about a display.
This includes values like:

- `id`
- `x`, `y`, `z`
- `facing`
- `width`, `height`
- `pixelWidth`, `pixelHeight`
- `resolutionMultiplier`

```lua
local info = gpu.getDisplayInfo(displayId)
print(info.pixelWidth, info.pixelHeight)
```

### `getResourceStats()` → `string`

Returns current resource stats for DirectGPU.
Use it to inspect limits/usage.

```lua
local stats = gpu.getResourceStats()
print(stats)
```

### `listDisplays()` → `table`

Returns a list of display ids currently owned by this block.

```lua
local displays = gpu.listDisplays()
```

### `removeDisplay(displayId)` → `boolean`

Deletes one display.
Returns `true` if it was removed.

```lua
local ok = gpu.removeDisplay(displayId)
```

### `setDisplayPersistent(displayId, persistent)`

Marks whether the display should persist.

```lua
gpu.setDisplayPersistent(displayId, true)
```

### `updateDisplay(displayId)`

Pushes the current framebuffer to the display.
Call this after drawing.

```lua
gpu.updateDisplay(displayId)
```

---

## 2D drawing

### `clear(displayId, r, g, b)`

Fills the whole display with one color.

```lua
gpu.clear(displayId, 0, 0, 0)
```

### `drawCircle(displayId, cx, cy, radius, r, g, b, filled)`

Draws a circle. Set `filled` to `true` for a solid circle.

```lua
gpu.drawCircle(displayId, 100, 80, 30, 255, 0, 0, true)
```

### `drawEllipse(displayId, cx, cy, rx, ry, r, g, b, filled)`

Draws an ellipse. Set `filled` to `true` for a solid ellipse.

```lua
gpu.drawEllipse(displayId, 100, 80, 40, 20, 255, 255, 0, false)
```

### `drawLine(displayId, x1, y1, x2, y2, r, g, b)`

Draws a line between two points.

```lua
gpu.drawLine(displayId, 0, 0, 100, 100, 255, 255, 255)
```

### `drawPolygon(displayId, pointsObj, r, g, b)`

Draws a polygon from a point table.
`pointsObj` should be like `{{x1, y1}, {x2, y2}, {x3, y3}}`.

```lua
gpu.drawPolygon(displayId, {
    {20, 20},
    {80, 20},
    {50, 70}
}, 0, 255, 0)
```

### `drawPolylines(displayId, pointsObj, r, g, b)`

Draws connected line segments through the given points.
Needs at least 2 points.

```lua
gpu.drawPolylines(displayId, {
    {10, 10},
    {20, 30},
    {50, 40},
    {90, 10}
}, 255, 255, 255)
```

### `fillEllipse(displayId, cx, cy, rx, ry, r, g, b)`

Draws a filled ellipse.

```lua
gpu.fillEllipse(displayId, 100, 80, 40, 20, 0, 200, 255)
```

### `fillRect(displayId, x, y, w, h, r, g, b)`

Draws a filled rectangle.

```lua
gpu.fillRect(displayId, 10, 10, 60, 30, 255, 0, 0)
```

### `getPixel(displayId, x, y)` → `table`

Reads one pixel and returns its color.

```lua
local pixel = gpu.getPixel(displayId, 10, 10)
```

### `setPixel(displayId, x, y, r, g, b)`

Sets one pixel.

```lua
gpu.setPixel(displayId, 10, 10, 255, 255, 255)
```

---

## Text rendering

### `clearFontCache()`

Clears cached font renderers.
Useful if you changed fonts/styles a lot and want to reset font cache state.

```lua
gpu.clearFontCache()
```

### `drawText(displayId, text, x, y, r, g, b, fontName, fontSize, style)` → `table`

Draws text with the given system font, size, and style.
Useful styles depend on the font setup, but common ones are things like `"plain"`, `"bold"`, or `"italic"`.

```lua
gpu.drawText(displayId, "Hello", 10, 20, 255, 255, 255, "Arial", 18, "bold")
```

### `drawTextWithBg(displayId, text, x, y, fgR, fgG, fgB, bgR, bgG, bgB, padding, fontName, fontSize, style)` → `table`

Draws text with a background box behind it.

```lua
gpu.drawTextWithBg(displayId, "Button", 20, 20,
    255, 255, 255,
    40, 40, 40,
    4,
    "Arial", 16, "bold")
```

### `drawTextWrapped(displayId, text, x, y, maxWidth, r, g, b, lineSpacing, fontName, fontSize, style)` → `table`

Draws wrapped text constrained to `maxWidth`.
Returns a table containing:

- `width`
- `height`
- `lines`

```lua
local info = gpu.drawTextWrapped(displayId, longText, 10, 10, 200,
    255, 255, 255, 2, "Arial", 16, "plain")
print(info.lines)
```

### `measureText(text, fontName, fontSize, style)` → `table`

Measures text size without drawing it.
Useful for layout.

```lua
local size = gpu.measureText("Hello", "Arial", 18, "bold")
```

### `getAvailableFonts()` → `table`

Returns available system font family names.

```lua
local fonts = gpu.getAvailableFonts()
```

---

## Image and JPEG

### `clearJPEGCache()`

Clears cached JPEG decode data.

```lua
gpu.clearJPEGCache()
```

### `decodeAndScaleJPEG(base64JpegData, targetWidth, targetHeight)` → `table`

Decodes a JPEG from Base64 and scales it to the given size.
Useful when you want image data first instead of drawing directly.

```lua
local image = gpu.decodeAndScaleJPEG(base64JpegData, 128, 128)
```

### `decodeJPEG(base64JpegData)` → `table`

Decodes a Base64 JPEG and returns image data.

```lua
local image = gpu.decodeJPEG(base64JpegData)
```

### `getJPEGDimensions(base64JpegData)` → `table`

Returns the width and height of a Base64 JPEG without fully drawing it.

```lua
local dims = gpu.getJPEGDimensions(base64JpegData)
```

### `getJPEGNetworkStats()` → `string`

Returns JPEG/network related stats.

```lua
print(gpu.getJPEGNetworkStats())
```

### `getRecommendedJPEGSettings(targetWidth, targetHeight)` → `table`

Returns suggested JPEG settings for a target size.
Useful when you are trying to optimize transfer size or decode cost.

```lua
local settings = gpu.getRecommendedJPEGSettings(320, 180)
```

### `loadJPEGFullscreen(displayId, base64JpegData)`

Decodes a Base64 JPEG and fills the entire display with it.

```lua
gpu.loadJPEGFullscreen(displayId, base64JpegData)
gpu.updateDisplay(displayId)
```

### `loadJPEGRegion(displayId, jpegBinaryData, x, y, w, h)`

Loads JPEG binary data into only part of the display.
Use this when updating a sub-region.

```lua
gpu.loadJPEGRegion(displayId, jpegBinaryData, 0, 0, 100, 100)
```

### `loadJPEGRegionBytes(displayId, base64JpegData, x, y, w, h)`

Same idea as `loadJPEGRegion`, but accepts Base64 JPEG data.

```lua
gpu.loadJPEGRegionBytes(displayId, base64JpegData, 50, 50, 128, 128)
```

### `preloadJPEGSequence(displayId, jpegSequence)`

Preloads a sequence of JPEG frames or images for later use.
Useful for slideshows, animations, or video-like playback.

```lua
gpu.preloadJPEGSequence(displayId, jpegSequence)
```

---

## Dictionary compression

These functions help reduce repeated Base64/image transfer overhead by storing and reusing chunks.

### `clearDictionary()`

Clears the compression dictionary.

```lua
gpu.clearDictionary()
```

### `compressWithDict(base64Data)` → `table`

Compresses Base64 data using the current dictionary.

```lua
local packed = gpu.compressWithDict(base64Data)
```

### `decompressFromDict(hashMap)` → `string`

Decompresses dictionary-compressed data back into the original form.

```lua
local data = gpu.decompressFromDict(hashMap)
```

### `getChunk(hash)` → `string`

Returns a stored dictionary chunk by hash.

```lua
local chunk = gpu.getChunk(hash)
```

### `getDictionaryStats()` → `string`

Returns dictionary usage stats.

```lua
print(gpu.getDictionaryStats())
```

### `hasChunk(hash)` → `boolean`

Checks whether a given chunk hash exists.

```lua
if gpu.hasChunk(hash) then
    print("chunk exists")
end
```

---

## 3D camera

### `clearZBuffer(displayId)`

Clears the depth buffer for the display.
Call this before drawing a new 3D frame.

```lua
gpu.clearZBuffer(displayId)
```

### `getCameraInfo(displayId)` → `table`

Returns current camera settings for the display.

```lua
local info = gpu.getCameraInfo(displayId)
```

### `lookAt(displayId, targetX, targetY, targetZ)`

Points the camera toward a world/render target point.

```lua
gpu.lookAt(displayId, 0, 0, 0)
```

### `setCameraPosition(displayId, x, y, z)`

Moves the camera.

```lua
gpu.setCameraPosition(displayId, 0, 2, 5)
```

### `setCameraRotation(displayId, pitch, yaw, roll)`

Sets camera rotation directly.

```lua
gpu.setCameraRotation(displayId, 10, 30, 0)
```

### `setCameraTarget(displayId, x, y, z)`

Sets a camera target point.

```lua
gpu.setCameraTarget(displayId, 0, 0, 0)
```

### `setupCamera(displayId, fov, near, far)` → `table`

Initializes the camera projection.
Typical values are something like `60, 0.1, 1000`.

```lua
gpu.setupCamera(displayId, 60, 0.1, 1000)
```

---

## 3D primitives

### `clear3D(displayId)`

Clears 3D-related state for the display.

```lua
gpu.clear3D(displayId)
```

### `drawCube(displayId, x, y, z, size, rotX, rotY, rotZ, r, g, b)`

Draws a cube.

```lua
gpu.drawCube(displayId, 0, 0, 0, 2, 0, 45, 0, 255, 100, 100)
```

### `drawPyramid(displayId, x, y, z, size, rotX, rotY, rotZ, r, g, b)`

Draws a pyramid.

```lua
gpu.drawPyramid(displayId, 0, 0, 0, 2, 0, 45, 0, 255, 255, 0)
```

### `drawSphere(displayId, x, y, z, radius, segments, r, g, b, textureNameObj)`

Draws a sphere.
`segments` controls detail level.
The last argument is texture-related if supported by your use case.

```lua
gpu.drawSphere(displayId, 0, 0, 0, 1, 16, 100, 180, 255, nil)
```

---

## 3D models

### `clearAll3DModels()`

Clears all loaded 3D models.

```lua
gpu.clearAll3DModels()
```

### `draw3DModel(displayId, modelId, x, y, z, rotX, rotY, rotZ, scale, r, g, b)`

Draws a loaded model using a flat color.

```lua
gpu.draw3DModel(displayId, modelId, 0, 0, 0, 0, 45, 0, 1.0, 255, 255, 255)
```

### `draw3DModelTextured(displayId, modelId, x, y, z, rotX, rotY, rotZ, scale, textureId)`

Draws a loaded model with a previously loaded texture.

```lua
gpu.draw3DModelTextured(displayId, modelId, 0, 0, 0, 0, 45, 0, 1.0, textureId)
```

### `get3DModelInfo(modelId)` → `table`

Returns info about a loaded model.

```lua
local info = gpu.get3DModelInfo(modelId)
```

### `load3DModel(objData)` → `number`

Loads OBJ model data from a normal string and returns a `modelId`.

```lua
local modelId = gpu.load3DModel(objData)
```

### `load3DModelFromBytes(base64ObjData)` → `number`

Loads OBJ model data from Base64 and returns a `modelId`.

```lua
local modelId = gpu.load3DModelFromBytes(base64ObjData)
```

### `unload3DModel(modelId)` → `boolean`

Removes a loaded model.

```lua
gpu.unload3DModel(modelId)
```

---

## 3D lighting

### `addAmbientLight(displayId, r, g, b, intensity)`

Adds ambient light affecting the whole scene evenly.

```lua
gpu.addAmbientLight(displayId, 40, 40, 40, 0.3)
```

### `addDirectionalLight(displayId, dirX, dirY, dirZ, r, g, b, intensity)`

Adds a directional light shining in the given direction.

```lua
gpu.addDirectionalLight(displayId, 0, -1, 0, 255, 255, 255, 0.8)
```

### `clearLights(displayId)`

Removes all lights from the display's 3D scene.

```lua
gpu.clearLights(displayId)
```

### `setBackfaceCulling(displayId, enabled)`

Turns backface culling on or off.
Useful for performance and cleaner solid models.

```lua
gpu.setBackfaceCulling(displayId, true)
```

### `setPhongShading(displayId, enabled)`

Turns phong shading on or off.
Use it if you want smoother lighting on supported geometry.

```lua
gpu.setPhongShading(displayId, true)
```

---

## Textures

This was one of the most confusing parts before, so here is the plain version.

A texture is an image that gets stored by DirectGPU and then referenced by id.

### Basic texture flow

1. load image pixels into DirectGPU
2. get a `textureId`
3. use that texture id when drawing textured things
4. unload it when done if needed

### `getTextureInfo(textureId)` → `table`

Returns info about a texture.
Currently this includes:

- `id`
- `width`
- `height`

```lua
local info = gpu.getTextureInfo(textureId)
print(info.width, info.height)
```

### `loadTexture(width, height, base64PixelData)` → `number`

Loads a texture from raw pixel bytes encoded as Base64.
Returns a new `textureId`.

Use this when **you already have the pixel bytes** and know the width and height.

```lua
local textureId = gpu.loadTexture(64, 64, base64PixelData)
```

### `loadTextureFromImage(imageData)` → `number`

Loads a texture from an image table.
The image table must contain:

- `width`
- `height`
- `pixels`

Returns a new `textureId`.

```lua
local textureId = gpu.loadTextureFromImage({
    width = 64,
    height = 64,
    pixels = pixelBytes
})
```

### `unloadTexture(textureId)` → `boolean`

Deletes a loaded texture from DirectGPU.
Call this if you no longer need it.

```lua
gpu.unloadTexture(textureId)
```

### Texture notes

- `textureId` is just the texture handle returned by DirectGPU
- `base64PixelData` is not a file path, it is the actual pixel data encoded as Base64
- `imageData` is a table of width/height/pixels
- loading a texture does **not** draw it by itself
- you load textures first, then reference them in textured rendering functions

---

## Input events

### `clearEvents(displayId)`

Clears queued display input events.

```lua
gpu.clearEvents(displayId)
```

### `hasEvents(displayId)` → `boolean`

Checks whether the display has pending input events.

```lua
if gpu.hasEvents(displayId) then
    print("input waiting")
end
```

### `pollEvent(displayId)` → `table | nil`

Returns the next queued input event for that display, or `nil` if there is none.

Typical use:

```lua
if gpu.hasEvents(displayId) then
    local event = gpu.pollEvent(displayId)
    print(event.type)
end
```

---

## World data

### `getBiomeAt(x, y, z)` → `string`

Returns the biome at the given coordinates.

```lua
print(gpu.getBiomeAt(0, 64, 0))
```

### `getDimension()` → `string`

Returns the current dimension.

```lua
print(gpu.getDimension())
```

### `getMoonInfo()` → `table`

Returns current moon-related info.

```lua
local moon = gpu.getMoonInfo()
```

### `getTimeInfo()` → `table`

Returns current world time info.

```lua
local t = gpu.getTimeInfo()
```

### `getWeather()` → `table`

Returns weather info.

```lua
local weather = gpu.getWeather()
```

### `getWorldInfo()` → `table`

Returns a broader set of world information.

```lua
local info = gpu.getWorldInfo()
```

---

## Controller input

### `clearControllerEvents(controllerId)`

Clears queued controller events.

```lua
gpu.clearControllerEvents(0)
```

### `getAxes(controllerId)` → `table`

Returns all raw axis values for the controller.

```lua
local axes = gpu.getAxes(0)
```

### `getAxis(controllerId, axisIndex)` → `number`

Returns one raw axis value.

```lua
local x = gpu.getAxis(0, 0)
```

### `getButton(controllerId, buttonIndex)` → `boolean`

Returns whether one raw button is pressed.

```lua
if gpu.getButton(0, 0) then print("pressed") end
```

### `getButtons(controllerId)` → `table`

Returns all raw button states.

```lua
local buttons = gpu.getButtons(0)
```

### `getControllerCount()` → `number`

Returns how many controllers are currently visible to DirectGPU.

```lua
print(gpu.getControllerCount())
```

### `getControllerDeadzone()` → `number`

Returns the current controller deadzone.

```lua
print(gpu.getControllerDeadzone())
```

### `getControllerInfo(controllerId)` → `table`

Returns info about a controller.

```lua
local info = gpu.getControllerInfo(0)
```

### `hasControllerEvents(controllerId)` → `boolean`

Checks whether the controller has queued events.

```lua
if gpu.hasControllerEvents(0) then print("controller events") end
```

### `pollControllerEvent(controllerId)` → `table | nil`

Returns the next queued controller event.

```lua
local event = gpu.pollControllerEvent(0)
```

### `scanForControllers()`

Scans for connected controllers.
Run this before trying to use them.

```lua
gpu.scanForControllers()
```

### `setControllerDeadzone(deadzone)`

Sets the controller deadzone.

```lua
gpu.setControllerDeadzone(0.12)
```

### `updateControllerState(controllerId)`

Refreshes controller state.

```lua
gpu.updateControllerState(0)
```

---

## Controller mapping

### `exportRawControllerState(controllerId)` → `string`

Exports raw controller state for debugging or mapping work.

```lua
print(gpu.exportRawControllerState(0))
```

### `getControllerMapping(controllerId)` → `table`

Returns the current raw mapping for a controller.

```lua
local mapping = gpu.getControllerMapping(0)
```

### `getMappedAxis(controllerId, axisName)` → `number`

Returns a mapped axis by name.

```lua
local lx = gpu.getMappedAxis(0, "LEFT_STICK_X")
```

### `getMappedButton(controllerId, buttonName)` → `boolean`

Returns a mapped button by name.

```lua
if gpu.getMappedButton(0, "A") then print("A") end
```

### `resetControllerMapping(controllerId)`

Resets a controller's custom mapping.

```lua
gpu.resetControllerMapping(0)
```

### `saveControllerMappings()`

Saves mappings.

```lua
gpu.saveControllerMappings()
```

### `setAxisMapping(controllerId, axisName, rawAxis, inverted)`

Maps a named axis to a raw axis id.

```lua
gpu.setAxisMapping(0, "LEFT_STICK_X", 0, false)
```

### `setButtonMapping(controllerId, buttonName, rawButton)`

Maps a named button to a raw button id.

```lua
gpu.setButtonMapping(0, "A", 0)
```

---

## Controller profiles

### `getControllerAxisNames(controllerId)` → `table`

Returns named axis labels known for that controller/profile.

```lua
local names = gpu.getControllerAxisNames(0)
```

### `getControllerButtonNames(controllerId)` → `table`

Returns named button labels.

```lua
local names = gpu.getControllerButtonNames(0)
```

### `getControllerInputs(controllerId)` → `table`

Returns the available named inputs.

```lua
local inputs = gpu.getControllerInputs(0)
```

### `getControllerProfile(controllerId)` → `table`

Returns the profile for the controller.

```lua
local profile = gpu.getControllerProfile(0)
```

### `getControllerType(controllerId)` → `string`

Returns the detected controller type.

```lua
print(gpu.getControllerType(0))
```

### `getNamedAxesActive(controllerId, threshold)` → `table`

Returns named axes currently active above a threshold.

```lua
local active = gpu.getNamedAxesActive(0, 0.2)
```

### `getNamedAxis(controllerId, axisName)` → `number`

Returns a named axis value.

```lua
local lx = gpu.getNamedAxis(0, "LEFT_STICK_X")
```

### `getNamedButton(controllerId, buttonName)` → `boolean`

Returns a named button state.

```lua
if gpu.getNamedButton(0, "A") then print("A down") end
```

### `getNamedButtonsPressed(controllerId)` → `table`

Returns named buttons currently pressed.

```lua
local pressed = gpu.getNamedButtonsPressed(0)
```

### `hasInput(controllerId, inputName)` → `boolean`

Checks if a named input exists on that controller/profile.

```lua
print(gpu.hasInput(0, "RIGHT_TRIGGER"))
```

### `refreshControllerProfile(controllerId)`

Refreshes the controller profile detection.

```lua
gpu.refreshControllerProfile(0)
```

---

## Server-side controllers

These let server-side Lua query controller state linked to a specific player.

### `getPlayerUUID()` → `string`

Returns your current player UUID.

```lua
local uuid = gpu.getPlayerUUID()
```

### `getServerControllerAxes(playerUUID, localControllerId)` → `table`

Gets all controller axes for a player's controller.

```lua
local axes = gpu.getServerControllerAxes(uuid, 0)
```

### `getServerControllerAxis(playerUUID, controllerId, axisIndex)` → `number`

Gets one raw axis from a player's controller.

```lua
local axis = gpu.getServerControllerAxis(uuid, 0, 0)
```

### `getServerControllerButton(playerUUID, controllerId, buttonIndex)` → `boolean`

Gets one raw button from a player's controller.

```lua
local pressed = gpu.getServerControllerButton(uuid, 0, 0)
```

### `getServerControllerButtons(playerUUID, localControllerId)` → `table`

Gets all raw button states from a player's controller.

```lua
local buttons = gpu.getServerControllerButtons(uuid, 0)
```

### `getServerControllerCount(playerUUID)` → `number`

Gets how many controllers that player currently has available.

```lua
print(gpu.getServerControllerCount(uuid))
```

### `getServerControllerInfo(playerUUID, localControllerId)` → `table`

Gets info about one of that player's controllers.

```lua
local info = gpu.getServerControllerInfo(uuid, 0)
```

### `getServerControllerState(playerUUID, controllerId)` → `table`

Gets broader state for a player's controller.

```lua
local state = gpu.getServerControllerState(uuid, 0)
```

### `hasServerController(playerUUID, localControllerId)` → `boolean`

Checks if the player has that controller id available.

```lua
print(gpu.hasServerController(uuid, 0))
```

---

## Vector graphics

### `drawBezierCurve(displayId, pointsObj, r, g, b, segmentsObj)`

Draws a bezier curve from a point table.
If `segmentsObj` is omitted, it uses a default segment count.

```lua
gpu.drawBezierCurve(displayId, {
    {10, 80},
    {40, 10},
    {90, 10},
    {120, 80}
}, 255, 255, 255, 50)
```

### `drawRoundedRect(displayId, x, y, w, h, radius, r, g, b, filled)`

Draws a rounded rectangle.

```lua
gpu.drawRoundedRect(displayId, 10, 10, 100, 40, 8, 0, 200, 255, true)
```

### `drawSVGPath(displayId, pathData, x, y, scale, r, g, b)`

Draws a path from SVG-style path data.
Useful for icons or vector shapes.

```lua
gpu.drawSVGPath(displayId, "M 0 0 L 10 0 L 10 10 Z", 50, 50, 4, 255, 255, 255)
```

### `drawStar(displayId, cx, cy, points, outerRadius, innerRadius, r, g, b, filled)`

Draws a star.

```lua
gpu.drawStar(displayId, 80, 80, 5, 30, 15, 255, 255, 0, true)
```

---

## Metaballs

### `addMetaball(systemId, x, y, radius, strength)` → `number`

Adds one metaball to a metaball system.

```lua
local ballId = gpu.addMetaball(systemId, 50, 50, 20, 1.0)
```

### `clearMetaballs(systemId)`

Removes all metaballs from a system.

```lua
gpu.clearMetaballs(systemId)
```

### `createMetaballSystem(displayId)` → `number`

Creates a metaball system for a display and returns `systemId`.

```lua
local systemId = gpu.createMetaballSystem(displayId)
```

### `getMetaballCount(systemId)` → `number`

Returns the number of metaballs in a system.

```lua
print(gpu.getMetaballCount(systemId))
```

### `getMetaballInfo(systemId, ballId)` → `table`

Returns info for one metaball.

```lua
local info = gpu.getMetaballInfo(systemId, ballId)
```

### `removeMetaballSystem(systemId)`

Deletes a metaball system.

```lua
gpu.removeMetaballSystem(systemId)
```

### `renderMetaballs(systemId, threshold, renderMode)`

Renders the metaballs to the display.

```lua
gpu.renderMetaballs(systemId, 1.0, 0)
```

### `setMetaballColor(systemId, ballId, r, g, b)`

Sets the color of one metaball.

```lua
gpu.setMetaballColor(systemId, ballId, 0, 255, 255)
```

### `setMetaballPhysics(systemId, enabled, gravity, drag)`

Turns metaball physics on or off and sets gravity/drag.

```lua
gpu.setMetaballPhysics(systemId, true, 0.1, 0.01)
```

### `setMetaballVelocity(systemId, ballId, vx, vy)`

Sets one metaball's velocity.

```lua
gpu.setMetaballVelocity(systemId, ballId, 2, -1)
```

### `updateMetaballs(systemId, deltaTime)`

Advances metaball simulation.

```lua
gpu.updateMetaballs(systemId, 0.05)
```

---

## Calibration

### `getCalibrationValues()` → `table`

Returns current calibration settings/values.

```lua
local values = gpu.getCalibrationValues()
```

### `setCalibrationMode(enabled, divisor, subtract)`

Sets calibration mode values.

```lua
gpu.setCalibrationMode(true, 2, 10)
```

---

## Map reader peripheral

The map reader is a separate peripheral type: `map_reader`

It reads Minecraft map items from its internal 9-slot inventory.
It can return map ids, metadata, decorations, and full pixel data.

### Basic usage

```lua
local reader = peripheral.find("map_reader")
local maps = reader.scanAll()
```

### `scanAll()` → `table`

Scans all map items in the internal inventory.
Returns a list of map entries.

```lua
local maps = reader.scanAll()
```

### `scanInternal()` → `table`

Alias of `scanAll()`.

```lua
local maps = reader.scanInternal()
```

### `scanAdjacent()` → `table`

Currently returns an empty list.
Adjacent container scanning is not supported anymore.

```lua
local maps = reader.scanAdjacent()
```

### `getMapCounts()` → `table`

Returns counts of found maps.

```lua
local counts = reader.getMapCounts()
```

### `getAdjacentContainers()` → `table`

Currently returns an empty list.

```lua
local containers = reader.getAdjacentContainers()
```

### `readMap(mapId)` → `table`

Reads one map by **map id**, not slot number.
Returns map data such as:

- `scale`
- `dimension`
- `centerX`, `centerZ`
- `locked`
- `pixels`
- `decorations`

`pixels` is Base64-encoded RGB pixel data for the map image.

```lua
local mapData = reader.readMap(mapId)
print(mapData.dimension)
print(#mapData.decorations)
```

### Full example

```lua
local reader = peripheral.find("map_reader")
local maps = reader.scanAll()

print("Found " .. #maps .. " maps")

for _, mapInfo in ipairs(maps) do
    print(string.format("Map #%d in slot %d: %s",
        mapInfo.mapId, mapInfo.slot, mapInfo.displayName))
end

if #maps > 0 then
    local mapId = maps[1].mapId
    local mapData = reader.readMap(mapId)

    print("Scale:", mapData.scale)
    print("Dimension:", mapData.dimension)
    print("Center:", mapData.centerX, mapData.centerZ)
    print("Locked:", mapData.locked)
    print("Decorations:", #mapData.decorations)
end
```

---

## Examples

### Interactive drawing board

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplay()

gpu.clear(display, 20, 20, 30)

local drawing = false
local points = {}
local running = true

parallel.waitForAny(
    function()
        while running do
            if gpu.hasEvents(display) then
                local event = gpu.pollEvent(display)

                if event and event.type == "mouse_click" then
                    drawing = true
                    points = {{event.x, event.y}}
                elseif event and event.type == "mouse_drag" and drawing then
                    table.insert(points, {event.x, event.y})
                    gpu.drawPolylines(display, points, 0, 255, 255)
                    gpu.updateDisplay(display)
                elseif event and event.type == "mouse_up" then
                    drawing = false
                end
            end
            sleep(0.05)
        end
    end,
    function()
        while running do
            local _, key = os.pullEvent("key")
            if key == keys.q then running = false end
        end
    end
)
```

### 3D model viewer

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplay()

local objData = [[
v -1 -1 -1
v 1 -1 -1
v 1 1 -1
v -1 1 -1
f 1 2 3 4
]]

local modelId = gpu.load3DModel(objData)

gpu.setupCamera(display, 60, 0.1, 1000)
gpu.setCameraPosition(display, 0, 0, 5)
gpu.addDirectionalLight(display, 0, -1, 0, 255, 255, 255, 0.8)

local rotation = 0
while true do
    gpu.clear(display, 0, 0, 0)
    gpu.clearZBuffer(display)
    gpu.draw3DModel(display, modelId, 0, 0, 0, 20, rotation, 0, 1.0, 200, 200, 255)
    gpu.updateDisplay(display)
    rotation = rotation + 1
    sleep(0.05)
end
```

### Controller test

```lua
local gpu = peripheral.find("directgpu")
gpu.scanForControllers()

if gpu.getControllerCount() == 0 then
    print("No controller found")
    return
end

while true do
    local lx = gpu.getNamedAxis(0, "LEFT_STICK_X")
    local ly = gpu.getNamedAxis(0, "LEFT_STICK_Y")
    local a = gpu.getNamedButton(0, "A")

    print("LX:", lx, "LY:", ly, "A:", a)
    sleep(0.05)
end
```

---

## Technical specs

| Specification | Value |
|---|---:|
| Minecraft version | 1.20.1 |
| Forge | 47.3.0+ |
| CC: Tweaked | 1.20.1 |
| Max displays | 50 per world |
| Total pixel limit | 10 megapixels |
| Max monitor size | 16×16 blocks |
| Max resolution | up to 656×324 pixels per block |
| Color depth | 24-bit RGB |
| Render distance | 64 blocks |
| Target frame rate | up to 60 FPS |

---

## Tips

- load models and textures once, then reuse ids
- clear + draw + `updateDisplay()` is the normal frame pattern
- clear z-buffer each 3D frame
- use `measureText()` for layout instead of guessing text width
- use `hasEvents()` before `pollEvent()`
- use `scanForControllers()` before reading controllers

---

## Support

- **Issues:** [GitHub Issues](https://github.com/tiktop101/CC-DirectGPU-Mod/issues)
- **Discord:** [Join Server](https://discord.gg/zr2CScq7Gf)
- **Docs:** this README and the example scripts

---

## License

This project is licensed under **All Rights Reserved (ARR)**.

You may:

- use this mod in personal gameplay
- use this mod on servers
- create videos or streams featuring it

You may not:

- redistribute or reupload the mod
- modify and redistribute the mod
- reuse code from this mod in other projects without permission

---

## Credits

**Author:** Tom

Special thanks:

- Minecraft Forge team
- CC: Tweaked developers
- DirectGPU testers and community users

---

<div align="center">

Made for the ComputerCraft community

[Back to top](#directgpu--vs-compatible)

</div>
