-- Clear all DirectGPU displays
print("DirectGPU Display Cleaner")
print("=========================")

local gpu = peripheral.find("directgpu")
if not gpu then
    print("ERROR: DirectGPU peripheral not found!")
    return
    end

    print("Found DirectGPU peripheral")

    -- Get all displays
    local displays = gpu.listDisplays()

    if #displays == 0 then
        print("No displays found - nothing to clear")
        return
        end

        print("Found " .. #displays .. " display(s)")

        -- Remove each display
        for i, displayId in ipairs(displays) do
            print("Removing display " .. displayId .. "...")
            local success = gpu.removeDisplay(displayId)
            if success then
                print("  Removed!")
                else
                    print("  Failed to remove")
                    end
                    end

                    print("\nAll displays cleared!")
