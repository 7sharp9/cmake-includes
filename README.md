# CMake Includes for Pamplejuce

## Fork notes

This is `7sharp9/cmake-includes`, a fork of Pamplejuce's CMake includes used by the OwnHammer plugins. It differs from upstream in these ways:

- C++23 for `SharedCode`, `Tests` and `Benchmarks` (`cxx_std_23`).
- `Tests.cmake` also globs `modules/ownhammer_core/tests/dsp/*.cpp` with `CONFIGURE_DEPENDS` and compiles each file through a generated wrapper translation unit under the build directory, so JUCE's module scanner does not treat the `.cpp` files inside the module as part of the module. Rotted tests are excluded by a `list(FILTER ... EXCLUDE REGEX ...)` quarantine line (currently `IRCacheTests.cpp`).
- Catch2 is pinned to 3.11.0 through CPM (`Tests.cmake`); `catch_discover_tests` is disabled for both executables because logger output corrupts test discovery. Run `./Tests` directly.
- `Tests` and `Benchmarks` are `EXCLUDE_FROM_ALL`: build them with `--target Tests` / `--target Benchmarks`.
- macOS universal binaries are built only on CI or with `FORCE_UNIVERSAL_BINARY=ON` (`PamplejuceMacOS.cmake`).
- Test and benchmark include paths accept either `source/` or `src/`.

The rest of this README is upstream's.

Hi there!

## What is this?

It's most of the actual CMake functionality used by [Pamplejuce](https://github.com/sudara/pamplejuce), my template repository for plugins in the JUCE framework.

## Why is this its own git submodule?

It's to help projects built by the template pull in the lastest changes.

[Pamplejuce](https://github.com/sudara/pamplejuce) is a template repository. Unlike most "dependencies," when you hit "Create Template" you are literally copying and pasting the code. Which sorta sucks, as people can't get fixes or updates.

## Why would I want updates?

For at least the gritty CMake details, there are fixes, improvements and additional functionality being added. 

In the best case, as a submodule, you can pull in the fixes and improvements.

In the worst case, this seperate repo will help you see what exactly changed in Pamplejuce.

## Is it risky?

It could be! 

As of 2023, Pamplejuce is still being changed around a bunch, with the goal of being a better and better ecosystem for developers.

That means there could be breakage when you pull. 

## What changed recently tho?

See [CHANGELOG.md](CHANGELOG.md).
