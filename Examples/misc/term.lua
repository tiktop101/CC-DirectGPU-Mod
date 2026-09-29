local gpu = peripheral.wrap("directgpu_1") or peripheral.find("directgpu")

local id = gpu.autoDetectAndCreateDisplay(1)

local kb = peripheral.wrap("front")

gpu.run(id, "clear")
gpu.run(id, "multishell")
