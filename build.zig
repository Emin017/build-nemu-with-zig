const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    // build riscv32 library
    const riscv32 = b.addStaticLibrary(.{
        .name = "riscv32",
        .target = target,
        .optimize = optimize,
    });
    riscv32.addCSourceFiles(.{ .root = b.path("src/isa/riscv32"), .files = &.{
        "reg.c",
        "init.c",
        "logo.c",
        "reg.c",
        "inst.c",
        "difftest/dut.c",
        "system/mmu.c",
        "system/intr.c",
    } });
    riscv32.linkLibC();
    riscv32.addIncludePath(b.path("include"));
    riscv32.addIncludePath(b.path("src/isa/riscv32/include"));
    riscv32.addIncludePath(b.path("src/isa/riscv32/local-include"));
    riscv32.defineCMacro("__GUEST_ISA__", "riscv32");

    // TODO: llvm-18 and SDL2 still cannot be linked to nemu on macOS
    const dummy = b.addStaticLibrary(.{
        .name = "dummy",
        .target = target,
        .optimize = optimize,
    });

    dummy.addCSourceFiles(.{
        .files = &.{
            "dummy.c",
        },
        .flags = &.{
            "-Wall",
            "-W",
            "-fPIE",
            "-std=c++17",
        },
    });
    dummy.linkLibC();

    const device = b.addStaticLibrary(.{
        .name = "device",
        .target = target,
        .optimize = optimize,
    });
    device.addCSourceFiles(.{
        .files = &.{
            "src/device/dummy.c",
            "src/device/io/map.c",
            "src/device/io/mmio.c",
            "src/device/io/port-io.c",
        },
    });
    device.linkLibC();
    device.addIncludePath(b.path("include"));
    device.addIncludePath(b.path("src/isa/riscv32/include"));
    device.addIncludePath(b.path("src/isa/riscv32/local-include"));
    device.defineCMacro("__GUEST_ISA__", "riscv32");
    device.linkSystemLibrary("SDL2");
    device.linkSystemLibrary("readline");

    const nemu = b.addExecutable(.{
        .name = "nemu",
        .target = target,
        .optimize = optimize,
    });
    nemu.defineCMacro("__GUEST_ISA__", "riscv32"); // set guest ISA
    nemu.defineCMacro("ITRACE_COND", "false"); // disable instruction trace
    nemu.linkLibC();
    nemu.linkSystemLibrary("dl"); // for dlopen
    nemu.linkSystemLibrary("SDL2"); // for device
    nemu.linkSystemLibrary("readline"); // for readline
    nemu.addIncludePath(b.path("include"));
    nemu.addIncludePath(b.path("src/monitor/sdb"));
    nemu.addIncludePath(b.path("src/isa/riscv32/include"));
    nemu.addIncludePath(b.path("src/isa/riscv32/local-include"));
    nemu.addCSourceFiles(.{
        .root = b.path("src"),
        .files = &.{
            "nemu-main.c",
            "cpu/cpu-exec.c",
            "cpu/difftest/dut.c",
            "engine/interpreter/init.c",
            "engine/interpreter/hostcall.c",
            "memory/paddr.c",
            "memory/vaddr.c",
            "monitor/monitor.c",
            "monitor/sdb/expr.c",
            "monitor/sdb/sdb.c",
            "monitor/sdb/watchpoint.c",
            "utils/log.c",
            "utils/timer.c",
            "utils/state.c",
        },
        .flags = &.{"-pie"},
    });
    nemu.linkLibrary(riscv32);
    nemu.linkLibrary(device);
    nemu.linkLibrary(dummy);
    // FIXME: nemu cannot fetch inst from pmem

    b.installArtifact(nemu);
}
