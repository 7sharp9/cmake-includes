# Required for ctest (which is just an easier way to run in cross-platform CI)
# include(CTest) could be used too, but adds additional targets we don't care about
# See: https://github.com/catchorg/Catch2/issues/2026
# You can also forgo ctest entirely and call ./Tests directly from the build dir
enable_testing()

include (CPM)

# Go into detail when there's a CTest failure
set(CTEST_OUTPUT_ON_FAILURE ON)
set_property(GLOBAL PROPERTY CTEST_TARGETS_ADDED 1)

# "GLOBS ARE BAD" is brittle and silly dev UX, sorry CMake!
file(GLOB_RECURSE TestFiles CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/tests/*.cpp" "${CMAKE_CURRENT_SOURCE_DIR}/tests/*.h")

# Exclude Catch2-based ownhammer_core test files from the top-level Tests target.
# CONFIGURE_DEPENDS lets the generator re-glob when a new test .cpp lands, so
# extraction tests added between configures still make it into the binary.
file(GLOB_RECURSE OwnHammerDSPTestFiles CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/modules/ownhammer_core/tests/dsp/*.cpp"
)

# Quarantine list — tests that have rotted against the current API and are
# tracked separately. Re-enable them as their owners port to the new API.
list(FILTER OwnHammerDSPTestFiles EXCLUDE REGEX "/tests/dsp/processors/IRCacheTests\\.cpp$")

# Remove these files from TestFiles so only ownhammer_core_tests builds them
list(REMOVE_ITEM TestFiles ${OwnHammerDSPTestFiles})

# Organize the test source in the Tests/ folder in Xcode
source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR}/tests PREFIX "" FILES ${TestFiles})


# Workaround for CLion
# See https://www.jetbrains.com/help/clion/catch-tests-support.html#long-testnames-bug
# and https://github.com/catchorg/Catch2/issues/2751
if (DEFINED ENV{CLION_IDE})
    set(CATCH_CONFIG_CONSOLE_WIDTH 200 CACHE STRING "CLion Workaround" FORCE)
endif ()

# Use Catch2 v3 on the devel branch
CPMAddPackage("gh:catchorg/Catch2@3.11.0")

# Build wrapper translation units outside the JUCE module tree so only the
# Tests target compiles ownhammer_core's Catch2 test sources.
set(OwnHammerDSPTestWrappers)
foreach(testFile IN LISTS OwnHammerDSPTestFiles)
    file(TO_CMAKE_PATH "${testFile}" testFileCMakePath)
    file(RELATIVE_PATH testRelPath
        "${CMAKE_CURRENT_SOURCE_DIR}/modules/ownhammer_core/tests/dsp"
        "${testFileCMakePath}")
    string(REPLACE "/" "_" testRelPathSanitized "${testRelPath}")
    string(REPLACE ".cpp" "" testRelPathStem "${testRelPathSanitized}")
    set(wrapperFile
        "${CMAKE_CURRENT_BINARY_DIR}/generated/ownhammer_core_tests/${testRelPathStem}_wrapper.cpp")
    file(GENERATE OUTPUT "${wrapperFile}" CONTENT "#include \"${testFileCMakePath}\"\n")
    list(APPEND OwnHammerDSPTestWrappers "${wrapperFile}")
endforeach()

# Setup the test executable, again C++20 please.
# EXCLUDE_FROM_ALL: a plain `cmake --build` builds the plugin only; build the
# tests with `--target Tests`.
add_executable(Tests EXCLUDE_FROM_ALL ${TestFiles} ${OwnHammerDSPTestWrappers})
target_compile_features(Tests PRIVATE cxx_std_23)

# Our test executable also wants to know about our plugin code...
target_include_directories(Tests PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/source ${CMAKE_CURRENT_SOURCE_DIR}/src)

# Copy over compile definitions from our plugin target so it has all the JUCEy goodness
target_compile_definitions(Tests PRIVATE $<TARGET_PROPERTY:${PROJECT_NAME},COMPILE_DEFINITIONS>)

# And give tests access to our shared code
target_link_libraries(Tests PRIVATE SharedCode Catch2::Catch2)

# Make an Xcode Scheme for the test executable so we can run tests in the IDE
set_target_properties(Tests PROPERTIES XCODE_GENERATE_SCHEME ON)

# When running Tests we have specific needs
target_compile_definitions(Tests PUBLIC
    JUCE_MODAL_LOOPS_PERMITTED=1 # let us run Message Manager in tests
    RUN_PAMPLEJUCE_TESTS=1 # also run tests in other module .cpp files guarded by RUN_PAMPLEJUCE_TESTS
)

# Let our tests target know we are running in CI
if ((DEFINED ENV{CI}))
    target_compile_definitions(Tests PUBLIC CI=1)
endif ()

# Load and use the .cmake file provided by Catch2
# https://github.com/catchorg/Catch2/blob/devel/docs/cmake-integration.md
# We have to manually provide the source directory here for now
include(${Catch2_SOURCE_DIR}/extras/Catch.cmake)

# ${DISCOVERY_MODE} set to "PRE_TEST" for MacOS arm64 / Xcode development
# fixes error when Xcode attempts to run test executable
# NOTE: catch_discover_tests disabled - logger output corrupts JSON during discovery
# Tests still work fine when run directly: ./build/Tests
# catch_discover_tests(Tests ${DISCOVERY_MODE} "PRE_TEST")
