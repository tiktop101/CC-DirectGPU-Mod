#        DirectGPU

<div align="center">

**High-Performance Graphics for ComputerCraft**

[![Minecraft](https://img.shields.io/badge/Minecraft-1.20.1-green.svg)](https://www.minecraft.net/)
[![CC: Tweaked](https://img.shields.io/badge/CC%3A%20Tweaked-1.20.1-blue.svg)](https://tweaked.cc/)
[![License](https://img.shields.io/badge/License-ARR-red.svg)](LICENSE)

Transform ComputerCraft monitors into powerful graphics displays with hardware-accelerated 2D/3D rendering, image decoding, and real-time input support.

[Download](https://github.com/tiktop101/CC-DirectGPU-Mod/releases/) • [Examples](https://github.com/tiktop101/CC-DirectGPU-Mod/tree/main/Examples) • [Discord](https://discord.gg/zr2CScq7Gf)

</div>

---

## ✨ Features

### 🎨 2D Graphics
- **True RGB Color** - 24-bit color depth (16.7M colors)
- **High Resolution** - Up to 656×324 pixels per block (4x scaling)
- **Drawing Primitives** - Lines, rectangles, circles, ellipses, polygons, bezier curves
- **Text Rendering** - System fonts with anti-aliasing and multiple styles
- **Hardware JPEG Decoding** - ~5ms per frame with compression support

### 🎮 3D Graphics
- **Full 3D Pipeline** - Camera, projection, depth testing
- **OBJ Model Loading** - Import industry-standard 3D models
- **Texture Mapping** - UV-mapped textures with hardware acceleration
- **Dynamic Lighting** - Directional and ambient lights with diffuse/phong shading
- **Primitives** - Cubes, spheres, pyramids with rotation and scaling

### 🕹️ Input & Interaction
- **Touch Input** - Mouse clicks, drags, and hover events
- **Controller Support** - Xbox, PlayStation, Switch, racing wheels, flight sticks
- **Auto-Profiling** - Named button/axis mapping across controller types
- **Multiplayer** - Server-side controller state access

### 🌍 World Integration
- **World Data** - Time, weather, moon phase, biome information
- **Auto-Detection** - Automatically find and configure nearby monitors
- **Multi-Display** - Up to 50 displays with 10MP total limit

## 📦 Installation

1. **Download** the latest DirectGPU JAR from [releases](https://github.com/tiktop101/CC-DirectGPU-Mod/releases/)
2. **Place** in your Minecraft `mods` folder
3. **Ensure** you have **Forge** and **CC: Tweaked** installed
4. **Craft** the DirectGPU block:

```
[Iron]     [Gold]      [Iron]
[Redstone] [Computer]  [Redstone]
[Iron]     [Redstone]  [Iron]
```

**Required:**
- 4× Iron Ingots
- 1× Gold Ingot
- 3× Redstone Dust
- 1× ComputerCraft Computer (normal)

**Versions:**
- Minecraft: 1.20.1
- Forge: 47.3.0+
- CC: Tweaked: 1.20.1 (1.116.1 recommended)

## 🚀 Quick Start

### 2D Graphics Example

```lua
-- Find the DirectGPU peripheral
local gpu = peripheral.find("directgpu")

-- Auto-create display on nearest monitor
local display = gpu.autoDetectAndCreateDisplay()

-- Get display info
local info = gpu.getDisplayInfo(display)
print(string.format("Display: %dx%d pixels", info.pixelWidth, info.pixelHeight))

-- Clear to blue and draw a red square
gpu.clear(display, 0, 100, 200)
gpu.fillRect(display, 10, 10, 50, 50, 255, 0, 0)
gpu.updateDisplay(display)

-- Draw text
gpu.drawText(display, "Hello DirectGPU!", 10, 70,
    255, 255, 255, "Arial", 20, "bold")
gpu.updateDisplay(display)
```

### 3D Graphics Example

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplay()

-- Setup 3D camera
gpu.setupCamera(display, 60, 0.1, 1000)
gpu.setCameraPosition(display, 0, 2, 5)
gpu.addDirectionalLight(display, 0, -1, 0, 255, 255, 255, 0.8)

-- Render loop
local rotation = 0
while true do
    gpu.clear(display, 0, 0, 0)
    gpu.clearZBuffer(display)

    -- Draw rotating cube
    gpu.drawCube(display, 0, 0, 0, 2, rotation, rotation, 0, 255, 100, 100)

    gpu.updateDisplay(display)
    rotation = rotation + 2
    sleep(0.05)
end
```

## 📚 API Reference

### Table of Contents

- [Display Management](#display-management) (13 functions)
- [2D Drawing](#2d-drawing) (10 functions)
- [Text Rendering](#text-rendering) (5 functions)
- [Image & JPEG](#image--jpeg) (10 functions)
- [Dictionary Compression](#dictionary-compression) (6 functions)
- [3D Camera](#3d-camera) (7 functions)
- [3D Primitives](#3d-primitives) (4 functions)
- [3D Models](#3d-models) (7 functions)
- [3D Lighting](#3d-lighting) (5 functions)
- [Textures](#textures) (4 functions)
- [Input Events](#input-events) (3 functions)
- [World Data](#world-data) (6 functions)
- [Controller Input](#controller-input) (13 functions)
- [Controller Mapping](#controller-mapping) (8 functions)
- [Controller Profiles](#controller-profiles) (11 functions)
- [Server-Side Controllers](#server-side-controllers) (9 functions)
- [Vector Graphics](#vector-graphics) (4 functions)
- [Metaballs](#metaballs) (11 functions)
- [Calibration](#calibration) (2 functions)

---

## API Documentation

### Display Management

#### `autoDetectAndCreateDisplay()` → number

**Example:**
```lua
local result = gpu.autoDetectAndCreateDisplay()
```

#### `autoDetectAndCreateDisplayWithResolution(resolutionMultiplier)` → number

**Parameters:**
- `resolutionMultiplier` (number)

**Example:**
```lua
local result = gpu.autoDetectAndCreateDisplayWithResolution(0)
```

#### `autoDetectMonitor()` → string

**Example:**
```lua
local result = gpu.autoDetectMonitor()
```

#### `clearAllDisplays()`

**Example:**
```lua
gpu.clearAllDisplays()
```

#### `createDisplay(x, y, z, facing, width, height)` → number

**Parameters:**
- `x` (number)
- `y` (number)
- `z` (number)
- `facing` (string)
- `width` (number)
- `height` (number)

**Example:**
```lua
local result = gpu.createDisplay(0, 0, 0, "", 0, 0)
```

#### `createDisplayAt(x, y, z, facing, width, height)` → number

**Parameters:**
- `x` (number)
- `y` (number)
- `z` (number)
- `facing` (string)
- `width` (number)
- `height` (number)

**Example:**
```lua
local result = gpu.createDisplayAt(0, 0, 0, "", 0, 0)
```

#### `createDisplayWithResolution(x, y, z, facing, width, height, resolutionMultiplier)` → number

**Parameters:**
- `x` (number)
- `y` (number)
- `z` (number)
- `facing` (string)
- `width` (number)
- `height` (number)
- `resolutionMultiplier` (number)

**Example:**
```lua
local result = gpu.createDisplayWithResolution(0, 0, 0, "", 0, 0, 0)
```

#### `getDisplayInfo(displayId)` → string

**Parameters:**
- `displayId` (number)

**Example:**
```lua
local result = gpu.getDisplayInfo(0)
```

#### `getResourceStats()` → string

**Example:**
```lua
local result = gpu.getResourceStats()
```

#### `listDisplays()` → table

**Example:**
```lua
local result = gpu.listDisplays()
```

#### `removeDisplay(displayId)` → boolean

**Parameters:**
- `displayId` (number)

**Example:**
```lua
local result = gpu.removeDisplay(0)
```

#### `setDisplayPersistent(displayId, persistent)`

**Parameters:**
- `displayId` (number)
- `persistent` (boolean)

**Example:**
```lua
gpu.setDisplayPersistent(0, true)
```

#### `updateDisplay(displayId)`

**Parameters:**
- `displayId` (number)

**Example:**
```lua
gpu.updateDisplay(0)
```


### 2D Drawing

#### `clear(displayId, r, g, b)`

**Parameters:**
- `displayId` (number)
- `r` (number)
- `g` (number)
- `b` (number)

**Example:**
```lua
gpu.clear(0, 0, 0, 0)
```

#### `drawCircle(displayId, cx, cy, radius, r, g, b, filled)`

**Parameters:**
- `displayId` (number)
- `cx` (number)
- `cy` (number)
- `radius` (number)
- `r` (number)
- `g` (number)
- `b` (number)
- `filled` (boolean)

**Example:**
```lua
gpu.drawCircle(0, 0, 0, 0, 0, 0, 0, true)
```

#### `drawEllipse(displayId, cx, cy, rx, ry, r, g, b, filled)`

**Parameters:**
- `displayId` (number)
- `cx` (number)
- `cy` (number)
- `rx` (number)
- `ry` (number)
- `r` (number)
- `g` (number)
- `b` (number)
- `filled` (boolean)

**Example:**
```lua
gpu.drawEllipse(0, 0, 0, 0, 0, 0, 0, 0, true)
```

#### `drawLine(displayId, x1, y1, x2, y2, r, g, b)`

**Parameters:**
- `displayId` (number)
- `x1` (number)
- `y1` (number)
- `x2` (number)
- `y2` (number)
- `r` (number)
- `g` (number)
- `b` (number)

**Example:**
```lua
gpu.drawLine(0, 0, 0, 0, 0, 0, 0, 0)
```

#### `drawPolygon(displayId, pointsObj, r, g, b)`

**Parameters:**
- `displayId` (number)
- `pointsObj` (any)
- `r` (number)
- `g` (number)
- `b` (number)

**Example:**
```lua
gpu.drawPolygon(0, value, 0, 0, 0)
```

#### `drawPolylines(displayId, pointsObj, r, g, b)`

**Parameters:**
- `displayId` (number)
- `pointsObj` (any)
- `r` (number)
- `g` (number)
- `b` (number)

**Example:**
```lua
gpu.drawPolylines(0, value, 0, 0, 0)
```

#### `fillEllipse(displayId, cx, cy, rx, ry, r, g, b)`

**Parameters:**
- `displayId` (number)
- `cx` (number)
- `cy` (number)
- `rx` (number)
- `ry` (number)
- `r` (number)
- `g` (number)
- `b` (number)

**Example:**
```lua
gpu.fillEllipse(0, 0, 0, 0, 0, 0, 0, 0)
```

#### `fillRect(displayId, x, y, w, h, r, g, b)`

**Parameters:**
- `displayId` (number)
- `x` (number)
- `y` (number)
- `w` (number)
- `h` (number)
- `r` (number)
- `g` (number)
- `b` (number)

**Example:**
```lua
gpu.fillRect(0, 0, 0, 0, 0, 0, 0, 0)
```

#### `getPixel(displayId, x, y)` → table

**Parameters:**
- `displayId` (number)
- `x` (number)
- `y` (number)

**Example:**
```lua
local result = gpu.getPixel(0, 0, 0)
```

#### `setPixel(displayId, x, y, r, g, b)`

**Parameters:**
- `displayId` (number)
- `x` (number)
- `y` (number)
- `r` (number)
- `g` (number)
- `b` (number)

**Example:**
```lua
gpu.setPixel(0, 0, 0, 0, 0, 0)
```


### Text Rendering

#### `clearFontCache()`

**Example:**
```lua
gpu.clearFontCache()
```

#### `drawText(displayId, text, x, y, r, g, b, fontName, fontSize, style)` → string

**Parameters:**
- `displayId` (number)
- `text` (string)
- `x` (number)
- `y` (number)
- `r` (number)
- `g` (number)
- `b` (number)
- `fontName` (string)
- `fontSize` (number)
- `style` (string)

**Example:**
```lua
local result = gpu.drawText(0, "", 0, 0, 0, 0, 0, "", 0, "")
```

#### `drawTextWithBg(displayId, text, x, y, fgR, fgG, fgB, bgR, bgG, bgB, padding, fontName, fontSize, style)` → string

**Parameters:**
- `displayId` (number)
- `text` (string)
- `x` (number)
- `y` (number)
- `fgR` (number)
- `fgG` (number)
- `fgB` (number)
- `bgR` (number)
- `bgG` (number)
- `bgB` (number)
- `padding` (number)
- `fontName` (string)
- `fontSize` (number)
- `style` (string)

**Example:**
```lua
local result = gpu.drawTextWithBg(0, "", 0, 0, 0, 0, 0, 0, 0, 0, 0, "", 0, "")
```

#### `drawTextWrapped(displayId, text, x, y, maxWidth, r, g, b, lineSpacing, fontName, fontSize, style)` → string

**Parameters:**
- `displayId` (number)
- `text` (string)
- `x` (number)
- `y` (number)
- `maxWidth` (number)
- `r` (number)
- `g` (number)
- `b` (number)
- `lineSpacing` (number)
- `fontName` (string)
- `fontSize` (number)
- `style` (string)

**Example:**
```lua
local result = gpu.drawTextWrapped(0, "", 0, 0, 0, 0, 0, 0, 0, "", 0, "")
```

#### `measureText(text, fontName, fontSize, style)` → string

**Parameters:**
- `text` (string)
- `fontName` (string)
- `fontSize` (number)
- `style` (string)

**Example:**
```lua
local result = gpu.measureText("", "", 0, "")
```


### Image & JPEG

#### `clearJPEGCache()`

**Example:**
```lua
gpu.clearJPEGCache()
```

#### `decodeAndScaleJPEG(base64JpegData, targetWidth, targetHeight)` → string

**Parameters:**
- `base64JpegData` (string)
- `targetWidth` (number)
- `targetHeight` (number)

**Example:**
```lua
local result = gpu.decodeAndScaleJPEG("", 0, 0)
```

#### `decodeJPEG(base64JpegData)` → string

**Parameters:**
- `base64JpegData` (string)

**Example:**
```lua
local result = gpu.decodeJPEG("")
```

#### `getJPEGDimensions(base64JpegData)` → string

**Parameters:**
- `base64JpegData` (string)

**Example:**
```lua
local result = gpu.getJPEGDimensions("")
```

#### `getJPEGNetworkStats()` → string

**Example:**
```lua
local result = gpu.getJPEGNetworkStats()
```

#### `getRecommendedJPEGSettings(targetWidth, targetHeight)` → string

**Parameters:**
- `targetWidth` (number)
- `targetHeight` (number)

**Example:**
```lua
local result = gpu.getRecommendedJPEGSettings(0, 0)
```

#### `loadJPEGFullscreen(displayId, base64JpegData)`

**Parameters:**
- `displayId` (number)
- `base64JpegData` (string)

**Example:**
```lua
gpu.loadJPEGFullscreen(0, "")
```

#### `loadJPEGRegion(displayId, jpegBinaryData, x, y, w, h)`

**Parameters:**
- `displayId` (number)
- `jpegBinaryData` (string)
- `x` (number)
- `y` (number)
- `w` (number)
- `h` (number)

**Example:**
```lua
gpu.loadJPEGRegion(0, "", 0, 0, 0, 0)
```

#### `loadJPEGRegionBytes(displayId, base64JpegData, x, y, w, h)`

**Parameters:**
- `displayId` (number)
- `base64JpegData` (string)
- `x` (number)
- `y` (number)
- `w` (number)
- `h` (number)

**Example:**
```lua
gpu.loadJPEGRegionBytes(0, "", 0, 0, 0, 0)
```

#### `preloadJPEGSequence(displayId, jpegSequence)`

**Parameters:**
- `displayId` (number)
- `jpegSequence` (any)

**Example:**
```lua
gpu.preloadJPEGSequence(0, value)
```


### Dictionary Compression

#### `clearDictionary()`

**Example:**
```lua
gpu.clearDictionary()
```

#### `compressWithDict(base64Data)` → string

**Parameters:**
- `base64Data` (string)

**Example:**
```lua
local result = gpu.compressWithDict("")
```

#### `decompressFromDict(hashMap)` → string

**Parameters:**
- `hashMap` (any)

**Example:**
```lua
local result = gpu.decompressFromDict(value)
```

#### `getChunk(hash)` → string

**Parameters:**
- `hash` (number)

**Example:**
```lua
local result = gpu.getChunk(value)
```

#### `getDictionaryStats()` → string

**Example:**
```lua
local result = gpu.getDictionaryStats()
```

#### `hasChunk(hash)` → boolean

**Parameters:**
- `hash` (number)

**Example:**
```lua
local result = gpu.hasChunk(value)
```


### 3D Camera

#### `clearZBuffer(displayId)`

**Parameters:**
- `displayId` (number)

**Example:**
```lua
gpu.clearZBuffer(0)
```

#### `getCameraInfo(displayId)` → string

**Parameters:**
- `displayId` (number)

**Example:**
```lua
local result = gpu.getCameraInfo(0)
```

#### `lookAt(displayId, targetX, targetY, targetZ)`

**Parameters:**
- `displayId` (number)
- `targetX` (number)
- `targetY` (number)
- `targetZ` (number)

**Example:**
```lua
gpu.lookAt(0, 0, 0, 0)
```

#### `setCameraPosition(displayId, x, y, z)`

**Parameters:**
- `displayId` (number)
- `x` (number)
- `y` (number)
- `z` (number)

**Example:**
```lua
gpu.setCameraPosition(0, 0, 0, 0)
```

#### `setCameraRotation(displayId, pitch, yaw, roll)`

**Parameters:**
- `displayId` (number)
- `pitch` (number)
- `yaw` (number)
- `roll` (number)

**Example:**
```lua
gpu.setCameraRotation(0, 0, 0, 0)
```

#### `setCameraTarget(displayId, x, y, z)`

**Parameters:**
- `displayId` (number)
- `x` (number)
- `y` (number)
- `z` (number)

**Example:**
```lua
gpu.setCameraTarget(0, 0, 0, 0)
```

#### `setupCamera(displayId, fov, near, far)` → string

**Parameters:**
- `displayId` (number)
- `fov` (number)
- `near` (number)
- `far` (number)

**Example:**
```lua
local result = gpu.setupCamera(0, 0, 0, 0)
```


### 3D Primitives

#### `clear3D(displayId)`

**Parameters:**
- `displayId` (number)

**Example:**
```lua
gpu.clear3D(0)
```

#### `drawCube(displayId, x, y, z, size, rotX, rotY, rotZ, r, g, b)`

**Parameters:**
- `displayId` (number)
- `x` (number)
- `y` (number)
- `z` (number)
- `size` (number)
- `rotX` (number)
- `rotY` (number)
- `rotZ` (number)
- `r` (number)
- `g` (number)
- `b` (number)

**Example:**
```lua
gpu.drawCube(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
```

#### `drawPyramid(displayId, x, y, z, size, rotX, rotY, rotZ, r, g, b)`

**Parameters:**
- `displayId` (number)
- `x` (number)
- `y` (number)
- `z` (number)
- `size` (number)
- `rotX` (number)
- `rotY` (number)
- `rotZ` (number)
- `r` (number)
- `g` (number)
- `b` (number)

**Example:**
```lua
gpu.drawPyramid(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
```

#### `drawSphere(displayId, x, y, z, radius, segments, r, g, b, textureNameObj)`

**Parameters:**
- `displayId` (number)
- `x` (number)
- `y` (number)
- `z` (number)
- `radius` (number)
- `segments` (number)
- `r` (number)
- `g` (number)
- `b` (number)
- `textureNameObj` (any)

**Example:**
```lua
gpu.drawSphere(0, 0, 0, 0, 0, 0, 0, 0, 0, value)
```


### 3D Models

#### `clearAll3DModels()`

**Example:**
```lua
gpu.clearAll3DModels()
```

#### `draw3DModel(displayId, modelId, x, y, z, rotX, rotY, rotZ, scale, r, g, b)`

**Parameters:**
- `displayId` (number)
- `modelId` (number)
- `x` (number)
- `y` (number)
- `z` (number)
- `rotX` (number)
- `rotY` (number)
- `rotZ` (number)
- `scale` (number)
- `r` (number)
- `g` (number)
- `b` (number)

**Example:**
```lua
gpu.draw3DModel(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
```

#### `draw3DModelTextured(displayId, modelId, x, y, z, rotX, rotY, rotZ, scale, textureId)`

**Parameters:**
- `displayId` (number)
- `modelId` (number)
- `x` (number)
- `y` (number)
- `z` (number)
- `rotX` (number)
- `rotY` (number)
- `rotZ` (number)
- `scale` (number)
- `textureId` (number)

**Example:**
```lua
gpu.draw3DModelTextured(0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
```

#### `get3DModelInfo(modelId)` → string

**Parameters:**
- `modelId` (number)

**Example:**
```lua
local result = gpu.get3DModelInfo(0)
```

#### `load3DModel(objData)` → number

**Parameters:**
- `objData` (string)

**Example:**
```lua
local result = gpu.load3DModel("")
```

#### `load3DModelFromBytes(base64ObjData)` → number

**Parameters:**
- `base64ObjData` (string)

**Example:**
```lua
local result = gpu.load3DModelFromBytes("")
```

#### `unload3DModel(modelId)` → boolean

**Parameters:**
- `modelId` (number)

**Example:**
```lua
local result = gpu.unload3DModel(0)
```


### 3D Lighting

#### `addAmbientLight(displayId, r, g, b, intensity)`

**Parameters:**
- `displayId` (number)
- `r` (number)
- `g` (number)
- `b` (number)
- `intensity` (number)

**Example:**
```lua
gpu.addAmbientLight(0, 0, 0, 0, 0)
```

#### `addDirectionalLight(displayId, dirX, dirY, dirZ, r, g, b, intensity)`

**Parameters:**
- `displayId` (number)
- `dirX` (number)
- `dirY` (number)
- `dirZ` (number)
- `r` (number)
- `g` (number)
- `b` (number)
- `intensity` (number)

**Example:**
```lua
gpu.addDirectionalLight(0, 0, 0, 0, 0, 0, 0, 0)
```

#### `clearLights(displayId)`

**Parameters:**
- `displayId` (number)

**Example:**
```lua
gpu.clearLights(0)
```

#### `setBackfaceCulling(displayId, enabled)`

**Parameters:**
- `displayId` (number)
- `enabled` (boolean)

**Example:**
```lua
gpu.setBackfaceCulling(0, true)
```

#### `setPhongShading(displayId, enabled)`

**Parameters:**
- `displayId` (number)
- `enabled` (boolean)

**Example:**
```lua
gpu.setPhongShading(0, true)
```


### Textures

#### `getTextureInfo(textureId)` → string

**Parameters:**
- `textureId` (number)

**Example:**
```lua
local result = gpu.getTextureInfo(0)
```

#### `loadTexture(width, height, base64PixelData)` → number

**Parameters:**
- `width` (number)
- `height` (number)
- `base64PixelData` (string)

**Example:**
```lua
local result = gpu.loadTexture(0, 0, "")
```

#### `loadTextureFromImage(imageData)` → number

**Parameters:**
- `imageData` (any)

**Example:**
```lua
local result = gpu.loadTextureFromImage(value)
```

#### `unloadTexture(textureId)` → boolean

**Parameters:**
- `textureId` (number)

**Example:**
```lua
local result = gpu.unloadTexture(0)
```


### Input Events

#### `clearEvents(displayId)`

**Parameters:**
- `displayId` (number)

**Example:**
```lua
gpu.clearEvents(0)
```

#### `hasEvents(displayId)` → boolean

**Parameters:**
- `displayId` (number)

**Example:**
```lua
local result = gpu.hasEvents(0)
```

#### `pollEvent(displayId)` → string

**Parameters:**
- `displayId` (number)

**Example:**
```lua
local result = gpu.pollEvent(0)
```


### World Data

#### `getBiomeAt(x, y, z)` → string

**Parameters:**
- `x` (number)
- `y` (number)
- `z` (number)

**Example:**
```lua
local result = gpu.getBiomeAt(0, 0, 0)
```

#### `getDimension()` → string

**Example:**
```lua
local result = gpu.getDimension()
```

#### `getMoonInfo()` → string

**Example:**
```lua
local result = gpu.getMoonInfo()
```

#### `getTimeInfo()` → string

**Example:**
```lua
local result = gpu.getTimeInfo()
```

#### `getWeather()` → string

**Example:**
```lua
local result = gpu.getWeather()
```

#### `getWorldInfo()` → string

**Example:**
```lua
local result = gpu.getWorldInfo()
```


### Controller Input

#### `clearControllerEvents(controllerId)`

**Parameters:**
- `controllerId` (number)

**Example:**
```lua
gpu.clearControllerEvents(0)
```

#### `getAxes(controllerId)` → table

**Parameters:**
- `controllerId` (number)

**Example:**
```lua
local result = gpu.getAxes(0)
```

#### `getAxis(controllerId, axisIndex)` → number

**Parameters:**
- `controllerId` (number)
- `axisIndex` (number)

**Example:**
```lua
local result = gpu.getAxis(0, 0)
```

#### `getButton(controllerId, buttonIndex)` → boolean

**Parameters:**
- `controllerId` (number)
- `buttonIndex` (number)

**Example:**
```lua
local result = gpu.getButton(0, 0)
```

#### `getButtons(controllerId)` → table

**Parameters:**
- `controllerId` (number)

**Example:**
```lua
local result = gpu.getButtons(0)
```

#### `getControllerCount()` → number

**Example:**
```lua
local result = gpu.getControllerCount()
```

#### `getControllerDeadzone()` → number

**Example:**
```lua
local result = gpu.getControllerDeadzone()
```

#### `getControllerInfo(controllerId)` → string

**Parameters:**
- `controllerId` (number)

**Example:**
```lua
local result = gpu.getControllerInfo(0)
```

#### `hasControllerEvents(controllerId)` → boolean

**Parameters:**
- `controllerId` (number)

**Example:**
```lua
local result = gpu.hasControllerEvents(0)
```

#### `pollControllerEvent(controllerId)` → string

**Parameters:**
- `controllerId` (number)

**Example:**
```lua
local result = gpu.pollControllerEvent(0)
```

#### `scanForControllers()`

**Example:**
```lua
gpu.scanForControllers()
```

#### `setControllerDeadzone(deadzone)`

**Parameters:**
- `deadzone` (number)

**Example:**
```lua
gpu.setControllerDeadzone(0)
```

#### `updateControllerState(controllerId)`

**Parameters:**
- `controllerId` (number)

**Example:**
```lua
gpu.updateControllerState(0)
```


### Controller Mapping

#### `exportRawControllerState(controllerId)` → string

**Parameters:**
- `controllerId` (number)

**Example:**
```lua
local result = gpu.exportRawControllerState(0)
```

#### `getControllerMapping(controllerId)` → string

**Parameters:**
- `controllerId` (number)

**Example:**
```lua
local result = gpu.getControllerMapping(0)
```

#### `getMappedAxis(controllerId, axisName)` → number

**Parameters:**
- `controllerId` (number)
- `axisName` (string)

**Example:**
```lua
local result = gpu.getMappedAxis(0, "")
```

#### `getMappedButton(controllerId, buttonName)` → boolean

**Parameters:**
- `controllerId` (number)
- `buttonName` (string)

**Example:**
```lua
local result = gpu.getMappedButton(0, "")
```

#### `resetControllerMapping(controllerId)`

**Parameters:**
- `controllerId` (number)

**Example:**
```lua
gpu.resetControllerMapping(0)
```

#### `saveControllerMappings()`

**Example:**
```lua
gpu.saveControllerMappings()
```

#### `setAxisMapping(controllerId, axisName, rawAxis, inverted)`

**Parameters:**
- `controllerId` (number)
- `axisName` (string)
- `rawAxis` (number)
- `inverted` (boolean)

**Example:**
```lua
gpu.setAxisMapping(0, "", 0, true)
```

#### `setButtonMapping(controllerId, buttonName, rawButton)`

**Parameters:**
- `controllerId` (number)
- `buttonName` (string)
- `rawButton` (number)

**Example:**
```lua
gpu.setButtonMapping(0, "", 0)
```


### Controller Profiles

#### `getControllerAxisNames(controllerId)` → string

**Parameters:**
- `controllerId` (number)

**Example:**
```lua
local result = gpu.getControllerAxisNames(0)
```

#### `getControllerButtonNames(controllerId)` → string

**Parameters:**
- `controllerId` (number)

**Example:**
```lua
local result = gpu.getControllerButtonNames(0)
```

#### `getControllerInputs(controllerId)` → table

**Parameters:**
- `controllerId` (number)

**Example:**
```lua
local result = gpu.getControllerInputs(0)
```

#### `getControllerProfile(controllerId)` → string

**Parameters:**
- `controllerId` (number)

**Example:**
```lua
local result = gpu.getControllerProfile(0)
```

#### `getControllerType(controllerId)` → string

**Parameters:**
- `controllerId` (number)

**Example:**
```lua
local result = gpu.getControllerType(0)
```

#### `getNamedAxesActive(controllerId, threshold)` → string

**Parameters:**
- `controllerId` (number)
- `threshold` (number)

**Example:**
```lua
local result = gpu.getNamedAxesActive(0, 0)
```

#### `getNamedAxis(controllerId, axisName)` → number

**Parameters:**
- `controllerId` (number)
- `axisName` (string)

**Example:**
```lua
local result = gpu.getNamedAxis(0, "")
```

#### `getNamedButton(controllerId, buttonName)` → boolean

**Parameters:**
- `controllerId` (number)
- `buttonName` (string)

**Example:**
```lua
local result = gpu.getNamedButton(0, "")
```

#### `getNamedButtonsPressed(controllerId)` → string

**Parameters:**
- `controllerId` (number)

**Example:**
```lua
local result = gpu.getNamedButtonsPressed(0)
```

#### `hasInput(controllerId, inputName)` → boolean

**Parameters:**
- `controllerId` (number)
- `inputName` (string)

**Example:**
```lua
local result = gpu.hasInput(0, "")
```

#### `refreshControllerProfile(controllerId)`

**Parameters:**
- `controllerId` (number)

**Example:**
```lua
gpu.refreshControllerProfile(0)
```


### Server-Side Controllers

#### `getPlayerUUID()` → string

**Example:**
```lua
local result = gpu.getPlayerUUID()
```

#### `getServerControllerAxes(playerUUID, localControllerId)` → table

**Parameters:**
- `playerUUID` (string)
- `localControllerId` (number)

**Example:**
```lua
local result = gpu.getServerControllerAxes("", 0)
```

#### `getServerControllerAxis(playerUUID, controllerId, axisIndex)` → number

**Parameters:**
- `playerUUID` (string)
- `controllerId` (number)
- `axisIndex` (number)

**Example:**
```lua
local result = gpu.getServerControllerAxis("", 0, 0)
```

#### `getServerControllerButton(playerUUID, controllerId, buttonIndex)` → boolean

**Parameters:**
- `playerUUID` (string)
- `controllerId` (number)
- `buttonIndex` (number)

**Example:**
```lua
local result = gpu.getServerControllerButton("", 0, 0)
```

#### `getServerControllerButtons(playerUUID, localControllerId)` → table

**Parameters:**
- `playerUUID` (string)
- `localControllerId` (number)

**Example:**
```lua
local result = gpu.getServerControllerButtons("", 0)
```

#### `getServerControllerCount(playerUUID)` → number

**Parameters:**
- `playerUUID` (string)

**Example:**
```lua
local result = gpu.getServerControllerCount("")
```

#### `getServerControllerInfo(playerUUID, localControllerId)` → string

**Parameters:**
- `playerUUID` (string)
- `localControllerId` (number)

**Example:**
```lua
local result = gpu.getServerControllerInfo("", 0)
```

#### `getServerControllerState(playerUUID, controllerId)` → string

**Parameters:**
- `playerUUID` (string)
- `controllerId` (number)

**Example:**
```lua
local result = gpu.getServerControllerState("", 0)
```

#### `hasServerController(playerUUID, localControllerId)` → boolean

**Parameters:**
- `playerUUID` (string)
- `localControllerId` (number)

**Example:**
```lua
local result = gpu.hasServerController("", 0)
```


### Vector Graphics

#### `drawBezierCurve(displayId, pointsObj, r, g, b, segmentsObj)`

**Parameters:**
- `displayId` (number)
- `pointsObj` (any)
- `r` (number)
- `g` (number)
- `b` (number)
- `segmentsObj` (any)

**Example:**
```lua
gpu.drawBezierCurve(0, value, 0, 0, 0, value)
```

#### `drawRoundedRect(displayId, x, y, w, h, radius, r, g, b, filled)`

**Parameters:**
- `displayId` (number)
- `x` (number)
- `y` (number)
- `w` (number)
- `h` (number)
- `radius` (number)
- `r` (number)
- `g` (number)
- `b` (number)
- `filled` (boolean)

**Example:**
```lua
gpu.drawRoundedRect(0, 0, 0, 0, 0, 0, 0, 0, 0, true)
```

#### `drawSVGPath(displayId, pathData, x, y, scale, r, g, b)`

**Parameters:**
- `displayId` (number)
- `pathData` (string)
- `x` (number)
- `y` (number)
- `scale` (number)
- `r` (number)
- `g` (number)
- `b` (number)

**Example:**
```lua
gpu.drawSVGPath(0, "", 0, 0, 0, 0, 0, 0)
```

#### `drawStar(displayId, cx, cy, points, outerRadius, innerRadius, r, g, b, filled)`

**Parameters:**
- `displayId` (number)
- `cx` (number)
- `cy` (number)
- `points` (number)
- `outerRadius` (number)
- `innerRadius` (number)
- `r` (number)
- `g` (number)
- `b` (number)
- `filled` (boolean)

**Example:**
```lua
gpu.drawStar(0, 0, 0, 0, 0, 0, 0, 0, 0, true)
```


### Metaballs

#### `addMetaball(systemId, x, y, radius, strength)` → number

**Parameters:**
- `systemId` (number)
- `x` (number)
- `y` (number)
- `radius` (number)
- `strength` (number)

**Example:**
```lua
local result = gpu.addMetaball(0, 0, 0, 0, 0)
```

#### `clearMetaballs(systemId)`

**Parameters:**
- `systemId` (number)

**Example:**
```lua
gpu.clearMetaballs(0)
```

#### `createMetaballSystem(displayId)` → number

**Parameters:**
- `displayId` (number)

**Example:**
```lua
local result = gpu.createMetaballSystem(0)
```

#### `getMetaballCount(systemId)` → number

**Parameters:**
- `systemId` (number)

**Example:**
```lua
local result = gpu.getMetaballCount(0)
```

#### `getMetaballInfo(systemId, ballId)` → string

**Parameters:**
- `systemId` (number)
- `ballId` (number)

**Example:**
```lua
local result = gpu.getMetaballInfo(0, 0)
```

#### `removeMetaballSystem(systemId)`

**Parameters:**
- `systemId` (number)

**Example:**
```lua
gpu.removeMetaballSystem(0)
```

#### `renderMetaballs(systemId, threshold, renderMode)`

**Parameters:**
- `systemId` (number)
- `threshold` (number)
- `renderMode` (number)

**Example:**
```lua
gpu.renderMetaballs(0, 0, 0)
```

#### `setMetaballColor(systemId, ballId, r, g, b)`

**Parameters:**
- `systemId` (number)
- `ballId` (number)
- `r` (number)
- `g` (number)
- `b` (number)

**Example:**
```lua
gpu.setMetaballColor(0, 0, 0, 0, 0)
```

#### `setMetaballPhysics(systemId, enabled, gravity, drag)`

**Parameters:**
- `systemId` (number)
- `enabled` (boolean)
- `gravity` (number)
- `drag` (number)

**Example:**
```lua
gpu.setMetaballPhysics(0, true, 0, 0)
```

#### `setMetaballVelocity(systemId, ballId, vx, vy)`

**Parameters:**
- `systemId` (number)
- `ballId` (number)
- `vx` (number)
- `vy` (number)

**Example:**
```lua
gpu.setMetaballVelocity(0, 0, 0, 0)
```

#### `updateMetaballs(systemId, deltaTime)`

**Parameters:**
- `systemId` (number)
- `deltaTime` (number)

**Example:**
```lua
gpu.updateMetaballs(0, 0)
```


### Calibration

#### `getCalibrationValues()` → string

**Example:**
```lua
local result = gpu.getCalibrationValues()
```

#### `setCalibrationMode(enabled, divisor, subtract)`

**Parameters:**
- `enabled` (boolean)
- `divisor` (number)
- `subtract` (number)

**Example:**
```lua
gpu.setCalibrationMode(true, 0, 0)
```


---

## 💡 Examples

### Interactive Drawing Board

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplay()

gpu.clear(display, 20, 20, 30)

local drawing = false
local points = {}

print("Draw with your mouse! Press Q to quit")

local running = true
parallel.waitForAny(
    function()
        while running do
            if gpu.hasEvents(display) then
                local event = gpu.pollEvent(display)

                if event.type == "mouse_click" then
                    drawing = true
                    points = {{event.x, event.y}}
                elseif event.type == "mouse_drag" and drawing then
                    table.insert(points, {event.x, event.y})

                    -- Draw the line
                    gpu.drawPolylines(display, points, 0, 255, 255)
                    gpu.updateDisplay(display)
                elseif event.type == "mouse_up" then
                    drawing = false
                end
            end
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

### 3D Model Viewer

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplay()

-- Load OBJ model
local modelData = [[
v -1 -1 -1
v 1 -1 -1
v 1 1 -1
v -1 1 -1
-- ... more vertices ...
f 1 2 3 4
-- ... more faces ...
]]

local modelId = gpu.load3DModel(modelData)

-- Setup camera
gpu.setupCamera(display, 60, 0.1, 1000)
gpu.setCameraPosition(display, 0, 0, 5)
gpu.addDirectionalLight(display, 0, -1, 0, 255, 255, 255, 0.8)

-- Render loop
local rotation = 0
while true do
    gpu.clear(display, 0, 0, 0)
    gpu.clearZBuffer(display)

    gpu.draw3DModel(display, modelId, 0, 0, 0,
        20, rotation, 0, 1.0, 200, 200, 255)

    gpu.updateDisplay(display)
    rotation = rotation + 1
    sleep(0.05)
end
```

### Controller-Based Game

```lua
local gpu = peripheral.find("directgpu")
local display = gpu.autoDetectAndCreateDisplay()

gpu.scanForControllers()
if gpu.getControllerCount() == 0 then
    print("No controller found!")
    return
end

local playerX, playerY = 320, 240
local speed = 5

while true do
    -- Get input
    local moveX = gpu.getNamedAxis(0, "LEFT_STICK_X")
    local moveY = gpu.getNamedAxis(0, "LEFT_STICK_Y")

    -- Update position
    playerX = playerX + (moveX * speed)
    playerY = playerY + (moveY * speed)

    -- Render
    gpu.clear(display, 20, 20, 40)
    gpu.drawCircle(display, playerX, playerY, 10, 255, 255, 0, true)

    -- Show button state
    if gpu.getNamedButton(0, "A") then
        gpu.drawText(display, "A Pressed!", 10, 10,
            255, 255, 0, "Arial", 16, "bold")
    end

    gpu.updateDisplay(display)
    sleep(0.05)
end
```

More examples: [DirectGPU-Projects Repository](https://github.com/tiktop101/CCDirectGPU-Projects/tree/main)

---

## 📊 Technical Specifications

| Specification | Value |
|---------------|-------|
| **Max Resolution** | 656×324 pixels per block (4x multiplier) |
| **Color Depth** | 24-bit RGB (16.7M colors) |
| **Max Monitor Size** | 16×16 blocks |
| **Max Displays** | 50 per world |
| **Total Pixel Limit** | 10 megapixels |
| **Render Distance** | 64 blocks |
| **Max Frame Rate** | 60 FPS |
| **Input Latency** | <50ms |
| **JPEG Decode Time** | 5-15ms (hardware accelerated) |

## 🤝 Support

- **Issues:** [GitHub Issues](https://github.com/tiktop101/CCDirectGPU-Projects/issues)
- **Discord:** [Join Server](https://discord.gg/zr2CScq7Gf)
- **Documentation:** This README + in-game examples

## 📜 License

This project is licensed under **All Rights Reserved (ARR)**.

**You may:**
- ✅ Use this mod in personal gameplay
- ✅ Use this mod on servers
- ✅ Create content (videos, streams) featuring this mod

**You may not:**
- ❌ Redistribute or reupload this mod
- ❌ Modify and redistribute this mod
- ❌ Use code from this mod in other projects without permission

## 👏 Credits

**Author:** Tom
**Special Thanks:**
- Minecraft Forge team
- CC: Tweaked developers
- DirectGPU community testers

---

<div align="center">

Made with ❤️ for the ComputerCraft community

[⬆ Back to Top](#directgpu)

</div>
