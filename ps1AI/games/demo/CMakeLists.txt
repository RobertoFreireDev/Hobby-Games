cmake_minimum_required(VERSION 3.21)
project(game LANGUAGES C CXX ASM VERSION 1.0.0)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(ENGINE_DIR ${CMAKE_CURRENT_LIST_DIR}/../../engine)
file(GLOB GAME_SRC   CONFIGURE_DEPENDS ${CMAKE_CURRENT_LIST_DIR}/src/*.cpp)
file(GLOB ENGINE_SRC CONFIGURE_DEPENDS ${ENGINE_DIR}/*.cpp)

psn00bsdk_add_executable(game GPREL ${GAME_SRC} ${ENGINE_SRC})
target_include_directories(game PRIVATE ${CMAKE_CURRENT_LIST_DIR}/src ${ENGINE_DIR})
# -fno-strict-aliasing: psxgpu.h macros write primitive headers through P_TAG* casts
# (type punning); without it -O2 warns and may reorder those writes.
target_compile_options(game PRIVATE -Wall -Wextra -Wno-unused-parameter -fno-strict-aliasing)
# The engine's hot loops (GTE transforms, primitive setup) are ~2x slower at -Og: optimize them
# in every configuration (asserts stay on in Debug, game code keeps -Og for debugging).
set_source_files_properties(${ENGINE_SRC} PROPERTIES COMPILE_OPTIONS -O2)

# Embed a binary file (only if ever needed): psn00bsdk_target_incbin(game PRIVATE sym path)
psn00bsdk_add_cd_image(iso game iso.xml DEPENDS game system.cnf)
