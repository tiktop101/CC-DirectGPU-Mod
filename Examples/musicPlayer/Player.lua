-- music folder: "." is the computer's root, or e.g. "disk/songs"

local MUSIC_DIR = "."
local SPEAKER_TYPE = "speaker"

local FALLBACK_W, FALLBACK_H = 328, 328

local BLUR_PERCENT  = 18
local BG_BRIGHTNESS = 0.27
local BG_SATURATION = 1.05
local BG_ZOOM       = 1.20
local BG_FOCUS_X    = 0.50
local BG_FOCUS_Y    = 0.40
local BG_BOTTOM_DIM = 0.48

local args = { ... }
local MONITOR_NAME = args[1]

local gpu = peripheral.find("directgpu")
if not gpu then
    error("No DirectGPU peripheral attached to this computer.", 0)
end

local speakers = { peripheral.find(SPEAKER_TYPE) }
if #speakers == 0 then
    error("No '" .. SPEAKER_TYPE .. "' peripheral found.", 0)
end

local speaker = speakers[1]

local HAS_ALL = speaker.speakerPlayAll ~= nil

local ok, displayId = pcall(function()
    os.sleep(0.2)
    if MONITOR_NAME then
        return gpu.autoDetectAndCreateDisplay(MONITOR_NAME)
    end
    return gpu.autoDetectAndCreateDisplay()
end)

if not ok then
    if MONITOR_NAME then
        error("autoDetectAndCreateDisplay failed for '" .. MONITOR_NAME .. "': " .. tostring(displayId), 0)
    end
    error("autoDetectAndCreateDisplay failed: " .. tostring(displayId), 0)
end

local info = gpu.getDisplayInfo(displayId)
local W = info.pixelWidth or FALLBACK_W
local H = info.pixelHeight or FALLBACK_H

local function readFile(path)
    local f = fs.open(path, "rb")
    if not f then return nil end

    local data = f.readAll()
    f.close()

    return data
end

local function eachSpeaker(method, ...)
    local any = false

    for _, s in ipairs(speakers) do
        local fn = s[method]

        if fn and pcall(fn, ...) then
            any = true
        end
    end

    return any
end

local function speakerPlay(data, volume)
    if not data then return false end

    volume = volume or 1

    if HAS_ALL then
        return pcall(function()
            speaker.speakerStopAll()
            speaker.speakerPlayAll(data, volume)
        end)
    end

    eachSpeaker("speakerStop")

    return eachSpeaker("speakerPlay", data, volume)
end

local function speakerStop()
    if HAS_ALL then
        pcall(speaker.speakerStopAll)
    else
        eachSpeaker("speakerStop")
    end
end

local function speakerPause()
    if HAS_ALL then
        return pcall(speaker.speakerPauseAll)
    end

    return eachSpeaker("speakerPause")
end

local function speakerResume()
    if HAS_ALL then
        return pcall(speaker.speakerResumeAll)
    end

    return eachSpeaker("speakerResume")
end

local function speakerSeek(delta)
    if HAS_ALL then
        return pcall(speaker.speakerSeekAll, delta)
    end

    return eachSpeaker("speakerSeek", delta)
end

local function speakerProgress()
    local fallback = nil

    for _, s in ipairs(speakers) do
        local ok2, prog = pcall(s.speakerProgress)

        if ok2 and prog then
            if not prog.stale then
                return prog
            end

            fallback = fallback or prog
        end
    end

    return fallback
end

local function u32be(s, i)
    local b1, b2, b3, b4 = s:byte(i, i + 3)

    if not (b1 and b2 and b3 and b4) then
        return nil
    end

    return b1 * 0x1000000
         + b2 * 0x10000
         + b3 * 0x100
         + b4
end

local function synchsafe(s, i)
    local b1, b2, b3, b4 = s:byte(i, i + 3)

    if not (b1 and b2 and b3 and b4) then
        return nil
    end

    return b1 * 0x200000
         + b2 * 0x4000
         + b3 * 0x80
         + b4
end

local function decodeID3Text(data, pos, size)
    if size < 2 then
        return nil
    end

    local str = data:sub(pos + 1, pos + size - 1)

    str = str
        :gsub("%z", "")
        :gsub("\255\254", "")
        :gsub("\254\255", "")

    return str:match("^%s*(.-)%s*$")
end

local function extractMetadata(data)
    if not data or #data < 10 or data:sub(1, 3) ~= "ID3" then
        return {}
    end

    local verMajor = data:byte(4)
    local tagSize = synchsafe(data, 7)

    if not tagSize then
        return {}
    end

    local tagEnd = 10 + tagSize
    local pos = 11
    local meta = {}

    while pos < tagEnd and pos + 10 <= #data + 1 do
        local frameId = data:sub(pos, pos + 3)

        if #frameId < 4 or frameId == "\0\0\0\0" then
            break
        end

        local frameSize

        if verMajor >= 4 then
            frameSize = synchsafe(data, pos + 4)
        else
            frameSize = u32be(data, pos + 4)
        end

        if not frameSize or frameSize < 0 then
            break
        end

        local frameStart = pos + 10
        local frameEnd = frameStart + frameSize - 1

        if frameId == "APIC" and frameSize > 4 and frameEnd <= #data then
            local fp = frameStart
            local encoding = data:byte(fp)

            fp = fp + 1

            local mimeEnd = data:find("\0", fp, true)

            if mimeEnd and mimeEnd <= frameEnd then
                local mime = data:sub(fp, mimeEnd - 1)

                fp = mimeEnd + 2

                local descTerm

                if encoding == 1 or encoding == 2 then
                    local i = fp

                    while i + 1 <= frameEnd do
                        if data:byte(i) == 0 and data:byte(i + 1) == 0 then
                            descTerm = i + 1
                            break
                        end

                        i = i + 2
                    end
                else
                    descTerm = data:find("\0", fp, true)
                end

                if descTerm and descTerm <= frameEnd then
                    local picData = data:sub(descTerm + 1, frameEnd)

                    if #picData > 0 then
                        meta.art = { mime = mime:lower(), data = picData }
                    end
                end
            end

        elseif frameId == "TIT2" and frameSize > 1 and frameEnd <= #data then
            meta.title = decodeID3Text(data, frameStart, frameSize)

        elseif frameId == "TPE1" and frameSize > 1 and frameEnd <= #data then
            meta.artist = decodeID3Text(data, frameStart, frameSize)
        end

        pos = frameEnd + 1
    end

    return meta
end

local function loadAlbumArt(art, x, y, w, h)
    if not art or not art.data or #art.data == 0 then
        return false
    end

    local c = art.crop

    return (pcall(
        gpu.loadCoverImageRegion,
        displayId,
        art.data,
        x, y, w, h,
        c and c.zoom or 1,
        c and c.fx or 0.5,
        c and c.fy or 0.5
    ))
end

local function u16le(s, i)
    local a, b = s:byte(i, i + 1)

    if not b then
        return nil
    end

    return a + b * 256
end

local function jpegSize(d)
    local n = #d
    local i = 3

    while i + 8 <= n do
        if d:byte(i) ~= 0xFF then
            i = i + 1

        else
            local m = d:byte(i + 1)

            if m == 0xFF then
                i = i + 1

            elseif m == 0xD8 or m == 0x01
               or (m >= 0xD0 and m <= 0xD7) then
                i = i + 2

            elseif m == 0xD9 or m == 0xDA then
                return nil

            else
                if m >= 0xC0 and m <= 0xCF
                   and m ~= 0xC4 and m ~= 0xC8 and m ~= 0xCC then

                    local h = d:byte(i + 5) * 256 + d:byte(i + 6)
                    local w = d:byte(i + 7) * 256 + d:byte(i + 8)

                    return w, h
                end

                i = i + 2 + (d:byte(i + 2) * 256 + d:byte(i + 3))
            end
        end
    end

    return nil
end

local function pngSize(d)
    if #d < 24 then
        return nil
    end

    return u32be(d, 17), u32be(d, 21)
end

local function webpSize(d)
    if #d < 30 then
        return nil
    end

    local kind = d:sub(13, 16)

    if kind == "VP8X" then
        local w = d:byte(25) + d:byte(26) * 256 + d:byte(27) * 65536
        local h = d:byte(28) + d:byte(29) * 256 + d:byte(30) * 65536

        return w + 1, h + 1

    elseif kind == "VP8 " then
        return u16le(d, 27) % 16384, u16le(d, 29) % 16384

    elseif kind == "VP8L" then
        local b1, b2, b3, b4 = d:byte(22, 25)

        if not b4 then
            return nil
        end

        local v = b1 + b2 * 256 + b3 * 65536 + b4 * 16777216

        return v % 16384 + 1,
               math.floor(v / 16384) % 16384 + 1
    end

    return nil
end

local function imageSize(art)
    if not (art and art.data and #art.data > 12) then
        return nil
    end

    local d = art.data
    local w, h

    if d:sub(1, 2) == "\255\216" then
        w, h = jpegSize(d)

    elseif d:sub(2, 4) == "PNG" then
        w, h = pngSize(d)

    elseif d:sub(1, 4) == "RIFF" and d:sub(9, 12) == "WEBP" then
        w, h = webpSize(d)
    end

    if w and h and w > 0 and h > 0 then
        return w, h
    end

    return nil
end

local MP3_BR1 = { 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320 }
local MP3_BR2 = { 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160 }
local MP3_SR = {
    [3] = { 44100, 48000, 32000 },
    [2] = { 22050, 24000, 16000 },
    [0] = { 11025, 12000, 8000 }
}

local function mp3Duration(d)
    if not d or #d < 128 then
        return nil
    end

    local start = 1

    if d:sub(1, 3) == "ID3" then
        local size = synchsafe(d, 7)

        if not size then
            return nil
        end

        start = 11 + size

        if d:byte(6) and d:byte(6) >= 16 and math.floor(d:byte(6) / 16) % 2 == 1 then
            start = start + 10
        end
    end

    local pos = start
    local limit = math.min(#d - 4, start + 65536)

    while pos <= limit do
        local b1, b2, b3, b4 = d:byte(pos, pos + 3)

        if b1 == 0xFF and b2 >= 0xE0 then
            local ver = math.floor(b2 / 8) % 4
            local layer = math.floor(b2 / 2) % 4
            local bri = math.floor(b3 / 16)
            local sri = math.floor(b3 / 4) % 4

            if ver ~= 1 and layer == 1 and bri >= 1 and bri <= 14 and sri <= 2 then
                local mpeg1 = ver == 3
                local br = (mpeg1 and MP3_BR1 or MP3_BR2)[bri]
                local sr = MP3_SR[ver][sri + 1]
                local spf = mpeg1 and 1152 or 576
                local mono = math.floor(b4 / 64) == 3

                local side
                if mpeg1 then
                    side = mono and 17 or 32
                else
                    side = mono and 9 or 17
                end

                local tag = d:sub(pos + 4 + side, pos + 7 + side)

                if tag == "Xing" or tag == "Info" then
                    local flags = u32be(d, pos + 8 + side)

                    if flags and flags % 2 == 1 then
                        local frames = u32be(d, pos + 12 + side)

                        if frames and frames > 0 then
                            return frames * spf / sr
                        end
                    end
                end

                local last = #d

                if d:sub(last - 127, last - 125) == "TAG" then
                    last = last - 128
                end

                return (last - pos + 1) * 8 / (br * 1000)
            end
        end

        pos = pos + 1
    end

    return nil
end

local tracks = {}

local function scanTracks()
    tracks = {}

    if not fs.isDir(MUSIC_DIR) then
        error("Folder not found: " .. MUSIC_DIR, 0)
    end

    local files = fs.list(MUSIC_DIR)
    table.sort(files)

    for _, name in ipairs(files) do
        if name:lower():match("%.mp3$") then
            local raw = name:gsub("%.[Mm][Pp]3$", "")

            local artist = "Unknown Artist"
            local title = raw

            local sep = raw:find(" %- ")

            if sep then
                artist = raw:sub(1, sep - 1)
                title = raw:sub(sep + 3)
            end

            table.insert(tracks, { file = MUSIC_DIR .. "/" .. name, name = title, artist = artist })
        end
    end
end

scanTracks()

if #tracks == 0 then
    error("No .mp3 files found in " .. MUSIC_DIR, 0)
end

local COL = {
    bg       = { 12, 13, 17 },
    border   = { 49, 53, 69 },
    borderHi = { 67, 72, 91 },

    panel    = { 27, 29, 38 },
    panelHi  = { 39, 42, 55 },

    track    = { 65, 69, 88 },

    accent   = { 34, 222, 157 },

    text     = { 246, 246, 250 },
    artist   = { 151, 158, 196 },
    time     = { 178, 183, 211 },

    icon     = { 242, 244, 250 },

    iconOn   = { 24, 168, 116 }
}

local function rect(x, y, w, h, c)
    gpu.fillRect(
        displayId,
        math.floor(x),
        math.floor(y),
        math.floor(w),
        math.floor(h),
        c[1], c[2], c[3]
    )
end

local function rrect(x, y, w, h, radius, c, filled)
    gpu.drawRoundedRect(
        displayId,
        math.floor(x),
        math.floor(y),
        math.floor(w),
        math.floor(h),
        math.floor(radius),
        c[1], c[2], c[3],
        filled
    )
end

local function circ(cx, cy, r, c, filled)
    gpu.drawCircle(
        displayId,
        math.floor(cx),
        math.floor(cy),
        math.floor(r),
        c[1], c[2], c[3],
        filled
    )
end

local function pt(x, y)
    return { math.floor(x), math.floor(y) }
end

local function poly(points, c)
    gpu.drawPolygon(displayId, points, c[1], c[2], c[3])
end

local function txt(s, x, y, c, size, style)
    gpu.drawText(
        displayId,
        s,
        math.floor(x),
        math.floor(y),
        c[1], c[2], c[3],
        "SansSerif",
        math.floor(size or 12),
        style or "plain"
    )
end

local function txtW(s, size, style)
    local ok2, m = pcall(function()
        return gpu.measureText(s, "SansSerif", size or 12, style or "plain")
    end)

    if ok2 and m and m.width then
        return m.width
    end

    return #s * (size or 12) * 0.55
end

local function txtCentered(s, y, c, size, style)
    local w = txtW(s, size, style)

    txt(s, math.floor((W - w) / 2), y, c, size, style)
end

local function ellipsize(s, maxW, size, style)
    if txtW(s, size, style) <= maxW then
        return s
    end

    local out = s

    while #out > 1 and txtW(out .. "...", size, style) > maxW do
        out = out:sub(1, #out - 1)
    end

    return out .. "..."
end

local function splitTitle(s, maxW, size, style)
    if txtW(s, size, style) <= maxW then
        return s, nil
    end

    local words = {}

    for word in s:gmatch("%S+") do
        table.insert(words, word)
    end

    if #words < 2 then
        return ellipsize(s, maxW, size, style), nil
    end

    local bestA = nil
    local bestB = nil
    local bestDiff = math.huge

    for split = 1, #words - 1 do
        local a = table.concat(words, " ", 1, split)
        local b = table.concat(words, " ", split + 1)

        if txtW(a, size, style) <= maxW
           and txtW(b, size, style) <= maxW then

            local diff = math.abs(txtW(a, size, style) - txtW(b, size, style))

            if diff < bestDiff then
                bestA = a
                bestB = b
                bestDiff = diff
            end
        end
    end

    if bestA then
        return bestA, bestB
    end

    local mid = math.ceil(#words / 2)

    local a = table.concat(words, " ", 1, mid)
    local b = table.concat(words, " ", mid + 1)

    if txtW(a, size, style) > maxW then
        a = ellipsize(a, maxW, size, style)
    end

    if b == "" then
        b = nil
    elseif txtW(b, size, style) > maxW then
        b = ellipsize(b, maxW, size, style)
    end

    return a, b
end

local function fmtTime(sec)
    if not sec then
        return "--:--"
    end

    sec = math.max(0, math.floor(sec))

    return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

local backdropOn = false

local function loadBackdrop(art)
    if not (art and art.data and #art.data > 0) then
        return false
    end

    local zoom = BG_ZOOM
    local fx   = BG_FOCUS_X
    local fy   = BG_FOCUS_Y

    local bg = art.bg

    if bg then
        zoom = BG_ZOOM * bg.zoom
        fx   = bg.fx + (BG_FOCUS_X - 0.5) * bg.spanX
        fy   = bg.fy + (BG_FOCUS_Y - 0.5) * bg.spanY
    end

    return (pcall(
        gpu.loadBlurredImage,
        displayId,
        art.data,
        {
            blur       = BLUR_PERCENT,
            brightness = BG_BRIGHTNESS,
            saturation = BG_SATURATION,
            zoom       = zoom,
            focusX     = fx,
            focusY     = fy,
            bottomDim  = BG_BOTTOM_DIM
        }
    ))
end

local function clearArea(x, y, w, h)
    x = math.floor(x)
    y = math.floor(y)
    w = math.floor(w)
    h = math.floor(h)

    if x < 0 then
        w = w + x
        x = 0
    end

    if y < 0 then
        h = h + y
        y = 0
    end

    if w <= 0 or h <= 0 then
        return
    end

    if backdropOn then
        if gpu.restoreBackdrop(displayId, x, y, w, h) then
            return
        end
    end

    rect(x, y, w, h, COL.bg)
end

local state = {
    index = 1,

    playing = false,
    paused = false,

    startEpoch = nil,
    elapsedBeforePause = 0,

    sawLiveProgress = false,

    duration = nil,

    art = nil,
    title = nil,
    artist = nil,

    artIndex = nil,
    artDirty = true,

    artWide = false,

    artAspect = nil,

    artScanIndex = nil,

    shuffle = false,
    played  = {},
    history = {},

    repeatOne = false
}

local BASE = 328
local SCALE = math.min(W, H) / BASE

local function S(n)
    return math.floor(n * SCALE + 0.5)
end

local ART_SIZE = S(112)
local ART_X = math.floor((W - ART_SIZE) / 2)
local ART_Y = S(31)

local ART_WIDE_MIN_ASPECT = 1.3

local ART_WIDE_W = S(192)
local ART_WIDE_H = math.floor(ART_WIDE_W * 9 / 16 + 0.5)

local TOP_PAD = S(10)

local TITLE_MAX_W = W - S(28)

local BAR_W = W - S(28)
local BAR_X = math.floor((W - BAR_W) / 2)
local BAR_H = S(6)
local BAR_Y = S(210)

local CTRL_CY = S(271)

local PLAY_CX = math.floor(W / 2)

local SIDE_GAP = S(49)
local OUTER_GAP = S(94)
local PREV_CX = PLAY_CX - SIDE_GAP
local NEXT_CX = PLAY_CX + SIDE_GAP
local SHUFFLE_CX = PLAY_CX - OUTER_GAP
local REPEAT_CX = PLAY_CX + OUTER_GAP

local PLAY_R = S(22)
local SIDE_R = S(16)

local KNOB_R = S(5)

local BORDER_X = S(4)
local BORDER_Y = S(4)
local BORDER_W = W - S(8)
local BORDER_H = H - S(8)

local function getElapsed()
    local prog = speakerProgress()

    if prog
       and prog.sampleRate
       and prog.sampleRate > 0
       and not prog.stale then

        state.sawLiveProgress = true

        local total = state.duration

        if not total and prog.totalSamples then
            total = prog.totalSamples / prog.sampleRate
        end

        return prog.elapsedSamples / prog.sampleRate, total
    end

    if state.playing then
        return (state.elapsedBeforePause + (os.epoch("utc") - state.startEpoch) / 1000), nil
    end

    return state.elapsedBeforePause, nil
end

local function applyClockShift(delta)
    if state.startEpoch then
        state.startEpoch =
            state.startEpoch - (delta * 1000)
    end
end

local function seekToFraction(fraction)
    if not (state.playing and state.index) then
        return
    end

    local elapsed, total = getElapsed()

    if not total or total <= 0 then
        return
    end

    fraction = math.max(0, math.min(1, fraction))

    local target = fraction * total
    local delta = target - elapsed

    if speakerSeek(delta) then
        applyClockShift(delta)
    end
end

local function playIndex(i)
    if not tracks[i] then
        return
    end

    speakerStop()

    state.index = i
    state.played[i] = true

    local data = readFile(tracks[i].file)

    state.duration = data and mp3Duration(data) or nil

    if i ~= state.artIndex then
        local meta = data and extractMetadata(data) or {}

        state.art = meta.art
        state.title = meta.title
        state.artist = meta.artist

        local iw, ih = imageSize(meta.art)

        state.artWide = false
        state.artAspect = nil
        state.artScanIndex = nil

        if iw and ih then
            state.artAspect = iw / ih

            if iw / ih >= ART_WIDE_MIN_ASPECT then
                state.artWide = true
            end
        end

        state.artIndex = i
        state.artDirty = true
    end

    if data and speakerPlay(data) then
        state.playing = true
        state.paused = false

        state.startEpoch = os.epoch("utc")
        state.elapsedBeforePause = 0
        state.sawLiveProgress = false
    end
end

local function togglePlayPause()
    if not state.playing and not state.paused then
        playIndex(state.index)

    elseif state.paused then
        if speakerResume() then
            state.paused = false
            state.playing = true

            state.startEpoch =
                os.epoch("utc")
                - state.elapsedBeforePause * 1000
        end

    else
        if speakerPause() then
            state.elapsedBeforePause =
                state.elapsedBeforePause
                + (os.epoch("utc") - state.startEpoch) / 1000

            state.playing = false
            state.paused = true
        end
    end
end

local function pickShuffleIndex()
    if #tracks <= 1 then
        return state.index
    end

    local pool = {}

    for i = 1, #tracks do
        if i ~= state.index and not state.played[i] then
            pool[#pool + 1] = i
        end
    end

    if #pool == 0 then
        state.played = { [state.index] = true }

        for i = 1, #tracks do
            if i ~= state.index then
                pool[#pool + 1] = i
            end
        end
    end

    return pool[math.random(#pool)]
end

local function nextTrack()
    if state.shuffle then
        local from = state.index

        state.history[#state.history + 1] = from

        if #state.history > 100 then
            table.remove(state.history, 1)
        end

        playIndex(pickShuffleIndex())
    else
        playIndex(state.index % #tracks + 1)
    end
end

local function prevTrack()
    if state.shuffle then
        while #state.history > 0 do
            local i = table.remove(state.history)

            if tracks[i] then
                playIndex(i)
                return
            end
        end
    end

    playIndex((state.index - 2) % #tracks + 1)
end

local function toggleShuffle()
    state.shuffle = not state.shuffle

    state.played  = { [state.index] = true }
    state.history = {}
end

local function toggleRepeat()
    state.repeatOne = not state.repeatOne
end

local function currentArtRect()
    local w = ART_SIZE
    local h = ART_SIZE

    if state.artWide then
        w = ART_WIDE_W
        h = ART_WIDE_H
    end

    local x = math.floor((W - w) / 2)
    local y = ART_Y + math.floor((ART_SIZE - h) / 2)

    return x, y, w, h
end

local function drawArt()
    if not state.artDirty then
        return
    end

    state.artDirty = false

    local hadBackdrop = backdropOn

    backdropOn = false

    if state.art and loadBackdrop(state.art) then
        backdropOn = true
    elseif hadBackdrop then
        pcall(gpu.clearBackdrop, displayId)

        rect(0, 0, W, H, COL.bg)
    end

    local ax, ay, aw, ah = currentArtRect()

    rrect(ax - S(3), ay - S(3), aw + S(6), ah + S(6), S(6), COL.bg, true)

    rrect(ax - S(2), ay - S(2), aw + S(4), ah + S(4), S(5), COL.borderHi, true)

    if not (state.art and loadAlbumArt(state.art, ax, ay, aw, ah)) then

        rrect(ax, ay, aw, ah, S(4), COL.panelHi, true)

        local m = math.min(aw, ah)

        circ(ax + aw / 2 - m * 0.12, ay + ah / 2 + m * 0.12, m * 0.14, COL.accent, true)

        rect(ax + aw / 2 + m * 0.08, ay + ah / 2 - m * 0.32, m * 0.08, m * 0.46, COL.accent)
    end
end

local ART_AUTO_CROP  = true
local CROP_SCAN_SIZE = 96
local CROP_BLACK_MAX = 32
local CROP_MIN_BAR   = 0.04
local CROP_FLAT_TOL  = 22
local CROP_DEBUG     = false

local function analyzeCover()
    state.artScanIndex = state.artIndex

    local art = state.art
    local sa  = state.artAspect

    if not (ART_AUTO_CROP and art and sa and gpu.getPixel) then
        return
    end

    art.crop = nil
    art.bg   = nil

    local sw, sh

    if sa >= 1 then
        sw = CROP_SCAN_SIZE
        sh = math.max(8, math.floor(CROP_SCAN_SIZE / sa + 0.5))
    else
        sh = CROP_SCAN_SIZE
        sw = math.max(8, math.floor(CROP_SCAN_SIZE * sa + 0.5))
    end

    sw = math.min(sw, W)
    sh = math.min(sh, H)

    if not loadAlbumArt(art, 0, 0, sw, sh) then
        return
    end

    local failed = false
    local N = 9

    local function isDark(x, y)
        local ok2, p = pcall(gpu.getPixel, displayId, x, y)

        if not ok2 or type(p) ~= "table" then
            failed = true
            return false
        end

        return p[1] <= CROP_BLACK_MAX
           and p[2] <= CROP_BLACK_MAX
           and p[3] <= CROP_BLACK_MAX
    end

    local function rowDark(y, x0, x1)
        local span = x1 - x0 + 1

        for i = 0, N - 1 do
            if not isDark(x0 + math.floor((i + 0.5) * span / N), y) then
                return false
            end
        end

        return true
    end

    local function colDark(x, y0, y1)
        local span = y1 - y0 + 1

        for i = 0, N - 1 do
            if not isDark(x, y0 + math.floor((i + 0.5) * span / N)) then
                return false
            end
        end

        return true
    end

    local top, bot, left, right = 0, 0, 0, 0

    while top < sh - 1 and rowDark(top, 0, sw - 1) do
        top = top + 1
    end

    while bot < sh - 1 - top and rowDark(sh - 1 - bot, 0, sw - 1) do
        bot = bot + 1
    end

    if failed then
        return
    end

    local y0 = top
    local y1 = sh - 1 - bot

    if y1 - y0 < 4 then
        return
    end

    local wideContent = sw / (y1 - y0 + 1) >= ART_WIDE_MIN_ASPECT

    local function colStats(x)
        local span = y1 - y0 + 1
        local sr, sg, sb = 0, 0, 0
        local lo = { 255, 255, 255 }
        local hi = { 0, 0, 0 }
        local mx = 0

        for i = 0, N - 1 do
            local ok2, p = pcall(gpu.getPixel, displayId, x, y0 + math.floor((i + 0.5) * span / N))

            if not ok2 or type(p) ~= "table" then
                failed = true
                return nil
            end

            sr, sg, sb = sr + p[1], sg + p[2], sb + p[3]

            for c = 1, 3 do
                if p[c] < lo[c] then lo[c] = p[c] end
                if p[c] > hi[c] then hi[c] = p[c] end
            end

            mx = math.max(mx, p[1], p[2], p[3])
        end

        local rng = math.max(hi[1] - lo[1], hi[2] - lo[2], hi[3] - lo[3])

        return sr / N, sg / N, sb / N, rng, mx
    end

    local function countBarCols(startX, dx)
        local n, ref = 0, nil

        while n < math.floor(sw / 2) do
            local mr, mg, mb, rng, mx = colStats(startX + dx * n)

            if not mr then
                return 0
            end

            if not ref then
                ref = { mr, mg, mb }
            end

            local black = mx <= CROP_BLACK_MAX
            local flat  = rng <= CROP_FLAT_TOL
                and math.abs(mr - ref[1]) <= CROP_FLAT_TOL
                and math.abs(mg - ref[2]) <= CROP_FLAT_TOL
                and math.abs(mb - ref[3]) <= CROP_FLAT_TOL

            if black or (wideContent and flat) then
                n = n + 1
            else
                break
            end
        end

        return n
    end

    left  = countBarCols(0, 1)
    right = countBarCols(sw - 1, -1)

    if failed then
        return
    end

    if top   / sh < CROP_MIN_BAR then top   = 0 end
    if bot   / sh < CROP_MIN_BAR then bot   = 0 end
    if left  / sw < CROP_MIN_BAR then left  = 0 end
    if right / sw < CROP_MIN_BAR then right = 0 end

    local function symmetric(a, b)
        return math.abs(a - b) <= math.max(3, math.max(a, b) * 0.35)
    end

    if not symmetric(top, bot) then
        top, bot = 0, 0
    end

    if not symmetric(left, right) then
        left, right = 0, 0
    end

    if top   > 0 then top   = top   + 1 end
    if bot   > 0 then bot   = bot   + 1 end
    if left  > 0 then left  = left  + 1 end
    if right > 0 then right = right + 1 end

    local x0 = left
    local x1 = sw - 1 - right
    local ry0 = top
    local ry1 = sh - 1 - bot

    if (x1 - x0 + 1) < sw * 0.2 or (ry1 - ry0 + 1) < sh * 0.2 then
        return
    end

    local trimmed = top > 0 or bot > 0 or left > 0 or right > 0

    local u0 = x0 / sw
    local u1 = (x1 + 1) / sw
    local v0 = ry0 / sh
    local v1 = (ry1 + 1) / sh

    local cwN = (u1 - u0) * sa
    local chN = (v1 - v0)
    local a   = cwN / chN

    if trimmed and (a < 0.6 or a > 2.5) then
        trimmed = false
        a = sa
    end

    local wide = a >= ART_WIDE_MIN_ASPECT

    state.artWide = wide

    if CROP_DEBUG then
        print(string.format(
            "cover %.2f  bars t%d b%d l%d r%d of %dx%d  -> content %.2f %s",
            sa, top, bot, left, right, sw, sh, a,
            wide and "(16:9 box)" or "(square box)"
        ))
    end

    if not trimmed then
        return
    end

    do
        local d = W / H
        local wantW

        if a > d then
            wantW = chN * d
        else
            wantW = cwN
        end

        local baseW

        if sa > d then
            baseW = d
        else
            baseW = sa
        end

        art.bg = {
            zoom  = math.max(1, baseW / wantW),
            fx    = (u0 + u1) / 2,
            fy    = (v0 + v1) / 2,
            spanX = u1 - u0,
            spanY = v1 - v0
        }
    end

    do
        local r = wide and (ART_WIDE_W / ART_WIDE_H) or 1
        local wantW

        if a > r then
            wantW = chN * r
        else
            wantW = cwN
        end

        local baseW

        if sa > r then
            baseW = r
        else
            baseW = sa
        end

        art.crop = { zoom = math.max(1, baseW / wantW), fx   = (u0 + u1) / 2, fy   = (v0 + v1) / 2 }
    end
end

local function drawTrackCounter()
    local counter = tostring(state.index) .. " / " .. tostring(#tracks)
    local size = S(11)
    local width = txtW(counter, size, "plain")

    txt(counter, W - S(10) - width, TOP_PAD, COL.time, size, "plain")
end

local function drawSongInfo()
    local track = tracks[state.index]

    if not track then
        return
    end

    local displayTitle =
        (state.title and state.title ~= "")
        and state.title
        or track.name

    local displayArtist =
        (state.artist and state.artist ~= "")
        and state.artist
        or track.artist

    local titleSize = S(15)
    local titleStyle = "bold"

    local line1, line2 =
        splitTitle(displayTitle, TITLE_MAX_W, titleSize, titleStyle)

    local titleY

    if line2 then
        titleY = S(146)

        txtCentered(line1, titleY, COL.text, titleSize, titleStyle)

        txtCentered(line2, titleY + S(18), COL.text, titleSize, titleStyle)
    else
        titleY = S(151)

        txtCentered(line1, titleY, COL.text, titleSize, titleStyle)
    end

    local artistY =
        line2
        and S(184)
        or S(173)

    local artistSize = S(11)

    local artistText =
        ellipsize(displayArtist, TITLE_MAX_W, artistSize, "plain")

    txtCentered(artistText, artistY, COL.artist, artistSize, "plain")
end

local function drawProgressBar()
    clearArea(BAR_X - S(5), BAR_Y - S(12), BAR_W + S(10), S(38))

    rrect(BAR_X, BAR_Y, BAR_W, BAR_H, S(3), COL.track, true)

    local elapsed, total = getElapsed()

    if total and total > 0 then
        local frac =
            math.max(0, math.min(1, elapsed / total))

        if frac > 0 then
            rrect(BAR_X, BAR_Y, math.max(S(5), BAR_W * frac), BAR_H, S(3), COL.accent, true)
        end

        local kx =
            BAR_X + BAR_W * frac

        local ky =
            BAR_Y + BAR_H / 2

        circ(kx, ky, KNOB_R, COL.accent, true)

        txt(fmtTime(elapsed), BAR_X, BAR_Y + S(14), COL.time, S(10), "plain")

        local totalText = fmtTime(total)

        txt(
            totalText,
            BAR_X + BAR_W
                - txtW(totalText, S(10), "plain"),
            BAR_Y + S(14),
            COL.time,
            S(10),
            "plain"
        )

    else
        if state.playing then
            local phase =
                (os.epoch("utc") / 1000)
                % 2 / 2

            local segW =
                BAR_W * 0.22

            rrect(BAR_X + (BAR_W - segW) * phase, BAR_Y, segW, BAR_H, S(3), COL.accent, true)
        end

        txt(fmtTime(elapsed), BAR_X, BAR_Y + S(14), COL.time, S(10), "plain")
    end

    hitboxes[#hitboxes + 1] = {
        x = BAR_X,
        y = BAR_Y - S(9),
        w = BAR_W,
        h = S(25),

        action = function(px)
            seekToFraction((px - BAR_X) / BAR_W)
        end
    }
end

local function drawPreviousButton()
    circ(PREV_CX, CTRL_CY, SIDE_R, COL.panel, true)

    rect(PREV_CX - S(7), CTRL_CY - S(7), S(2), S(14), COL.icon)

    poly({
        pt(PREV_CX + S(6), CTRL_CY - S(8)),
        pt(PREV_CX + S(6), CTRL_CY + S(8)),
        pt(PREV_CX - S(4), CTRL_CY)
    }, COL.icon)

    hitboxes[#hitboxes + 1] = {
        x = PREV_CX - S(19),
        y = CTRL_CY - S(19),
        w = S(38),
        h = S(38),
        action = prevTrack
    }
end

local function drawPlayButton()
    circ(PLAY_CX, CTRL_CY, PLAY_R, COL.accent, true)

    if state.playing then
        rect(PLAY_CX - S(6), CTRL_CY - S(9), S(5), S(18), COL.bg)

        rect(PLAY_CX + S(2), CTRL_CY - S(9), S(5), S(18), COL.bg)

    else
        poly({
            pt(PLAY_CX - S(6), CTRL_CY - S(10)),
            pt(PLAY_CX - S(6), CTRL_CY + S(10)),
            pt(PLAY_CX + S(10), CTRL_CY)
        }, COL.bg)
    end

    hitboxes[#hitboxes + 1] = {
        x = PLAY_CX - PLAY_R,
        y = CTRL_CY - PLAY_R,
        w = PLAY_R * 2,
        h = PLAY_R * 2,
        action = togglePlayPause
    }
end

local function drawNextButton()
    circ(NEXT_CX, CTRL_CY, SIDE_R, COL.panel, true)

    poly({
        pt(NEXT_CX - S(6), CTRL_CY - S(8)),
        pt(NEXT_CX - S(6), CTRL_CY + S(8)),
        pt(NEXT_CX + S(4), CTRL_CY)
    }, COL.icon)

    rect(NEXT_CX + S(5), CTRL_CY - S(7), S(2), S(14), COL.icon)

    hitboxes[#hitboxes + 1] = {
        x = NEXT_CX - S(19),
        y = CTRL_CY - S(19),
        w = S(38),
        h = S(38),
        action = nextTrack
    }
end

local function drawControls()
    clearArea(0, CTRL_CY - S(28), W, S(55))

    drawPreviousButton()
    drawPlayButton()
    drawNextButton()
end

local ICON_K      = 0.75 * SCALE

local ICON_STROKE = 2 * ICON_K

local ICON_SS     = 4
local ICON_COVER  = 0.45

local function newPath(x, y)
    return { { x, y } }
end

local function lineTo(p, x, y)
    p[#p + 1] = { x, y }
end

local function cubicTo(p, x1, y1, x2, y2, x3, y3, steps)
    local x0 = p[#p][1]
    local y0 = p[#p][2]

    steps = steps or 4

    for i = 1, steps do
        local t = i / steps
        local u = 1 - t

        p[#p + 1] = {
            u * u * u * x0
                + 3 * u * u * t * x1
                + 3 * u * t * t * x2
                + t * t * t * x3,

            u * u * u * y0
                + 3 * u * u * t * y1
                + 3 * u * t * t * y2
                + t * t * t * y3
        }
    end
end

local function arcTo(p, cx, cy, r, a0, a1, steps)
    steps = steps or 6

    for i = 1, steps do
        local a = math.rad(a0 + (a1 - a0) * i / steps)

        p[#p + 1] = { cx + r * math.cos(a), cy + r * math.sin(a) }
    end
end

local SHUFFLE_PATHS = {}

do
    local a = newPath(2, 18)
    lineTo(a, 3.4, 18)
    cubicTo(a, 4.7, 18, 5.9, 17.4, 6.7, 16.3)
    lineTo(a, 12.8, 7.7)
    cubicTo(a, 13.5, 6.6, 14.8, 6.0, 16.1, 6.0)
    lineTo(a, 22, 6)

    local b = newPath(2, 6)
    lineTo(b, 3.9, 6)
    cubicTo(b, 5.4, 6, 6.8, 6.9, 7.5, 8.2)

    local c = newPath(22, 18)
    lineTo(c, 16.1, 18)
    cubicTo(c, 14.8, 18, 13.5, 17.3, 12.8, 16.2)
    lineTo(c, 12.3, 15.4)

    local topHead = newPath(18, 2)
    lineTo(topHead, 22, 6)
    lineTo(topHead, 18, 10)

    local botHead = newPath(18, 14)
    lineTo(botHead, 22, 18)
    lineTo(botHead, 18, 22)

    SHUFFLE_PATHS = { a, b, c, topHead, botHead }
end

local REPEAT_PATHS = {}

do
    local top = newPath(3, 11)
    lineTo(top, 3, 10)
    arcTo(top, 7, 10, 4, 180, 270)
    lineTo(top, 21, 6)

    local topHead = newPath(17, 2)
    lineTo(topHead, 21, 6)
    lineTo(topHead, 17, 10)

    local bot = newPath(21, 13)
    lineTo(bot, 21, 14)
    arcTo(bot, 17, 14, 4, 0, 90)
    lineTo(bot, 3, 18)

    local botHead = newPath(7, 22)
    lineTo(botHead, 3, 18)
    lineTo(botHead, 7, 14)

    REPEAT_PATHS = { top, topHead, bot, botHead }
end

local function rasterizeIcon(paths)
    local segs = {}

    for _, path in ipairs(paths) do
        for i = 1, #path - 1 do
            segs[#segs + 1] = {
                (path[i][1]     - 12) * ICON_K,
                (path[i][2]     - 12) * ICON_K,
                (path[i + 1][1] - 12) * ICON_K,
                (path[i + 1][2] - 12) * ICON_K
            }
        end
    end

    local function distSq(px, py, s)
        local x1, y1, x2, y2 = s[1], s[2], s[3], s[4]
        local dx = x2 - x1
        local dy = y2 - y1
        local l2 = dx * dx + dy * dy
        local t = 0

        if l2 > 0 then
            t = ((px - x1) * dx + (py - y1) * dy) / l2

            if t < 0 then
                t = 0
            elseif t > 1 then
                t = 1
            end
        end

        local ex = px - (x1 + t * dx)
        local ey = py - (y1 + t * dy)

        return ex * ex + ey * ey
    end

    local function nearest(px, py)
        local best = math.huge

        for i = 1, #segs do
            local d = distSq(px, py, segs[i])

            if d < best then
                best = d
            end
        end

        return math.sqrt(best)
    end

    local half   = ICON_STROKE / 2
    local half2  = half * half
    local extent = math.ceil(12 * ICON_K) + 1
    local runs   = {}

    for py = -extent, extent - 1 do
        local runStart = nil

        for px = -extent, extent do
            local on = false

            if px < extent then
                local d = nearest(px + 0.5, py + 0.5)

                if d <= half - 0.7072 then
                    on = true

                elseif d < half + 0.7072 then
                    local hit = 0

                    for sy = 0, ICON_SS - 1 do
                        for sx = 0, ICON_SS - 1 do
                            local spx = px + (sx + 0.5) / ICON_SS
                            local spy = py + (sy + 0.5) / ICON_SS

                            for i = 1, #segs do
                                if distSq(spx, spy, segs[i]) <= half2 then
                                    hit = hit + 1
                                    break
                                end
                            end
                        end
                    end

                    on = hit / (ICON_SS * ICON_SS) >= ICON_COVER
                end
            end

            if on and not runStart then
                runStart = px

            elseif not on and runStart then
                runs[#runs + 1] = { runStart, py, px - runStart, 1 }
                runStart = nil
            end
        end
    end

    return runs
end

local SHUFFLE_RUNS = rasterizeIcon(SHUFFLE_PATHS)
local REPEAT_RUNS  = rasterizeIcon(REPEAT_PATHS)

local function drawRuns(runs, cx, cy, c)
    for i = 1, #runs do
        local r = runs[i]

        rect(cx + r[1], cy + r[2], r[3], r[4], c)
    end
end

local function drawShuffleIcon()
    drawRuns(SHUFFLE_RUNS, SHUFFLE_CX, CTRL_CY, state.shuffle and COL.iconOn or COL.icon)

    hitboxes[#hitboxes + 1] = {
        x = SHUFFLE_CX - S(19),
        y = CTRL_CY - S(19),
        w = S(38),
        h = S(38),
        action = toggleShuffle
    }
end

local function drawRepeatIcon()
    drawRuns(REPEAT_RUNS, REPEAT_CX, CTRL_CY, state.repeatOne and COL.iconOn or COL.icon)

    hitboxes[#hitboxes + 1] = {
        x = REPEAT_CX - S(19),
        y = CTRL_CY - S(19),
        w = S(38),
        h = S(38),
        action = toggleRepeat
    }
end

local function redraw()
    hitboxes = {}

    if state.artDirty
       and state.art
       and state.artScanIndex ~= state.artIndex then

        analyzeCover()
    end

    local hadBackdrop = backdropOn

    if state.artDirty then
        backdropOn = false

        if state.art and loadBackdrop(state.art) then
            backdropOn = true
        elseif hadBackdrop then
            pcall(gpu.clearBackdrop, displayId)

            rect(0, 0, W, H, COL.bg)
        end
    end

    if not backdropOn then
        rect(0, 0, W, H, COL.bg)
    end

    drawArt()

    drawTrackCounter()
    drawSongInfo()
    drawProgressBar()
    drawControls()

    drawShuffleIcon()
    drawRepeatIcon()

    gpu.updateDisplay(displayId)
end

local function handleClick(px, py)
    for _, h in ipairs(hitboxes) do
        if px >= h.x
           and px <= h.x + h.w
           and py >= h.y
           and py <= h.y + h.h then

            h.action(px)
            return
        end
    end
end

math.randomseed(os.epoch("utc"))

redraw()

print(("%dx%d Tom's Player%s."):format(
    W, H,
    MONITOR_NAME and (" on " .. MONITOR_NAME) or " (auto-detected monitor)"
))
print(("Speakers: %d (%s)"):format(
    #speakers,
    HAS_ALL and "synced speakerPlayAll" or "per-speaker fallback"
))
print("Press Ctrl+T to stop.")
print("Up/Down = blur % | Left/Right = zoom")

local POLL_INTERVAL = 0.05
local tmr = os.startTimer(POLL_INTERVAL)

local quit = false
local lastProgKey = nil
local statusY = nil

while not quit do
    local ev, p1 = os.pullEventRaw()

    if ev == "terminate" then
        quit = true

        elseif ev == "timer" and p1 == tmr then
            tmr = os.startTimer(POLL_INTERVAL)

            local needsFullRedraw = false
            local needsProgRedraw = false

            for _ = 1, 64 do
                local ok2, e = pcall(gpu.pollEvent, displayId)

                if not ok2 or not e then
                    break
                    end

                    if e.type == "mouse_click" then
                        handleClick(e.x, e.y)
                        needsFullRedraw = true
                        end
                        end

                        if state.playing and not state.paused then
                            local elapsed, total = getElapsed()
                            local key
                            if total and total > 0 then
                                key = math.floor(elapsed)
                                else
                                    key = "a" .. math.floor(os.epoch("utc") / 250)
                                    end

                                    if key ~= lastProgKey then
                                        lastProgKey = key
                                        needsProgRedraw = true
                                        end

                                        if (os.epoch("utc") - state.startEpoch) / 1000 >= 1.5 then

                                        local prog = speakerProgress()
                                        local finished = false

                                        if prog then
                                            if prog.stale then
                                                if state.sawLiveProgress then
                                                    finished = true
                                                    end
                                                    else
                                                        state.sawLiveProgress = true

                                                        if prog.totalSamples
                                                            and prog.elapsedSamples
                                                            >= prog.totalSamples - 1 then

                                                            finished = true
                                                            end
                                                            end
                                                            end

                                                            if not finished
                                                               and state.duration
                                                               and elapsed >= state.duration - 0.5 then

                                                                finished = true
                                                            end

                                                            if finished then
                                                                if state.repeatOne then
                                                                    playIndex(state.index)
                                                                    else
                                                                        nextTrack()
                                                                        end

                                                                        needsFullRedraw = true
                                                                        end
                                                                        end
                                                                        end

                                                                        if needsFullRedraw then
                                                                            lastProgKey = nil
                                                                            redraw()

                                                                            elseif needsProgRedraw then
                                                                                drawProgressBar()
                                                                                gpu.updateDisplay(displayId)
                                                                                end

    elseif ev == "key" then
        local changed = false

        if p1 == keys.up then
            BLUR_PERCENT =
                math.min(100, BLUR_PERCENT + 5)

            changed = true

        elseif p1 == keys.down then
            BLUR_PERCENT =
                math.max(0, BLUR_PERCENT - 5)

            changed = true

        elseif p1 == keys.right then
            BG_ZOOM =
                math.min(4, math.floor((BG_ZOOM + 0.1) * 10 + 0.5) / 10)

            changed = true

        elseif p1 == keys.left then
            BG_ZOOM =
                math.max(1, math.floor((BG_ZOOM - 0.1) * 10 + 0.5) / 10)

            changed = true
        end

        if changed then
            local line = string.format("blur %d%%  zoom %.1fx", BLUR_PERCENT, BG_ZOOM)

            if statusY then
                term.setCursorPos(1, statusY)
                term.clearLine()
                write(line)
                term.setCursorPos(1, statusY + 1)
            else
                print(line)
                local _, cy = term.getCursorPos()
                statusY = cy - 1
            end

            state.artDirty = true
            redraw()
        end

    elseif ev == "disk"
        or ev == "disk_eject" then

        scanTracks()

        if state.index > #tracks then
            state.index = 1
        end

        state.played  = { [state.index] = true }
        state.history = {}

        state.artIndex = nil
        state.artDirty = true

        redraw()
    end
end

speakerStop()
pcall(gpu.removeDisplay, displayId)
