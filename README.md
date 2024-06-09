# build-nemu-with-zig
This is a toy project to build NEMU with Zig.
I just want to try zig build system and see how it works.

## TODO list

There still are some problems to solve, but I will try to fix them:

- [ ] `make menuconfig` is still needed to config `nemu` before building
- [ ] `nemu` cannot link to llvm-18 and SDL2(in deivce mode)

Although `nemu` can be built with zig, it cannot run correctly:
- [ ] `nemu` cannot fetch instructions from pmem
