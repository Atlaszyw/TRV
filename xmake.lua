add_rules("mode.debug", "mode.release")

-- 配置自定义的 RISC-V LLVM 工具链
toolchain("gcc-rv32imcb")
    set_kind("standalone")
    -- 设置工具链的路径
    set_sdkdir("/home/main/.local/gcc-rv32imcb")
    set_bindir("/home/main/.local/gcc-rv32imcb/bin")

    -- -- 使用 LLVM 提供的工具集
    set_toolset("cc", "riscv32-unknown-elf-gcc")   -- 注意这里的 cross 参数
    set_toolset("cxx", "riscv32-unknown-elf-g++")
    set_toolset("ld", "riscv32-unknown-elf-ld")
    set_toolset("ar", "riscv32-unknown-elf-ar")
    set_toolset("as", "riscv32-unknown-elf-gcc")
rule_end()

toolchain("llvm-rv32imcb")
    set_kind("standalone")
    -- 设置工具链的路径
    set_sdkdir("/home/main/.local/llvm-rv32imcb")
    set_bindir("/home/main/.local/llvm-rv32imcb/bin")

    -- 使用 LLVM 提供的工具集
    set_toolset("cc", "clang")   -- 注意这里的 cross 参数
    set_toolset("cxx", "clang++")
    set_toolset("ld", "ld.lld")
    set_toolset("ar", "llvm-ar")
    set_toolset("as", "clang")
rule_end()

-- 定义目标架构
set_arch("riscv")

-- 添加包含目录和源文件
add_includedirs("$(projectdir)/lib/inc")
add_files("$(projectdir)/lib/asm/*.S")
add_files("$(projectdir)/lib/src/*.c")

target("driver")
    set_kind("binary")
    set_toolchains("llvm-rv32imcb")

    -- 添加编译和链接标志
    add_cflags("-march=rv32imc", "-mabi=ilp32","-static","-MMD","-mcmodel=medany","-Wall", "-g","-fvisibility=hidden","-Os", "-fdata-sections","-ffreestanding", "-ffunction-sections","-nostdlib", "-nostartfiles")
    -- add_asflags()
    add_ldflags( "-T$(projectdir)/lib/ld/link.ld", {force = true})   -- 链接脚本

    -- 指定项目源文件
    add_files("src/*.c")
target_end()

after_build(function (target)
    local targetfile = path.join(target:targetdir(), target:name() )

    -- 使用 objdump 生成 .dis 文件
    os.execv("llvm-objdump", {"-s","-h","-C","-t", "-S", "--arch=riscv32",
    "-l","-x", targetfile}, {stdout = targetfile .. ".dis"})

    -- 使用 objcopy 生成 .bin 文件
    os.execv("llvm-objcopy", {"-O", "binary", targetfile, targetfile .. ".bin"})

    -- 接下来可以使用 srec_cat 或其他工具处理 .bin 文件，生成 .vmem 文件等
    -- 确保 srec_cat 在 PATH 中，或者提供完整的路径
    os.execv("convert.py", {
        "--byte_swap",
        "--offset", "0x00000000",
        "--bytes_per_address", "4",
        "--address_per_line", "8",
        targetfile .. ".bin",
        targetfile .. ".vmem"
    })
end)

-- 自定义清理任务
on_clean(function ()
    os.rm("$(buildir)/*")
    -- os.rm(".xmake/*")
end)
