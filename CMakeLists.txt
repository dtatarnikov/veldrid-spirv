cmake_minimum_required (VERSION 3.5)

cmake_policy(SET CMP0057 NEW)

set(CMAKE_POLICY_VERSION_MINIMUM 3.5)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

add_subdirectory(ext/SPIRV-Cross)

set(SHADERC_SKIP_TESTS ON)
set(SHADERC_SKIP_INSTALL ON)
add_subdirectory(ext/shaderc)

set(CMAKE_CXX_STANDARD 17)
include_directories(ext/SPIRV-Cross)
include_directories(ext/SPIRV-Cross/include)
include_directories(ext/shaderc/libshaderc/include/shaderc)

file(GLOB_RECURSE LIBVELDRID_SPIRV_SOURCES src/libveldrid-spirv/*.cpp src/libveldrid-spirv/*.hpp)

project(veldrid-spirv)

set(LIBRARY_TYPE SHARED)
message( "Configured to build a shared library." )

add_library(veldrid-spirv ${LIBRARY_TYPE} ${LIBVELDRID_SPIRV_SOURCES})
target_link_libraries(veldrid-spirv
    spirv-cross-core
    spirv-cross-glsl
    spirv-cross-reflect
    spirv-cross-msl
    spirv-cross-hlsl
    shaderc
)

# macOS builds are expected to be dynamic libraries rather than frameworks,
# only output frameworks for iOS builds.
if(IOS)
	set_target_properties(veldrid-spirv PROPERTIES FRAMEWORK true)
	set_target_properties(veldrid-spirv PROPERTIES FRAMEWORK_VERSION A)
endif()

set_target_properties(veldrid-spirv PROPERTIES MACOSX_FRAMEWORK_IDENTIFIER "veldrid-spirv")
set_target_properties(veldrid-spirv PROPERTIES MACOSX_FRAMEWORK_BUNDLE_VERSION "1.0.15")
set_target_properties(veldrid-spirv PROPERTIES MACOSX_FRAMEWORK_SHORT_VERSION_STRING "1.0.15")

set_target_properties(veldrid-spirv PROPERTIES PREFIX "lib")
set_target_properties(veldrid-spirv PROPERTIES DEBUG_POSTFIX "")
