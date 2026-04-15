cmake_minimum_required(VERSION 3.11)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

project(hello VERSION 1.0.0 LANGUAGES C CXX)

add_executable(${PROJECT_NAME} main.cpp)
target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_23)
target_compile_options(${PROJECT_NAME} PRIVATE -fno-exceptions -fno-rtti -fwrapv -fomit-frame-pointer -ffunction-sections -fdata-sections -fno-asynchronous-unwind-tables -Wl,--gc-sections -s -Wl,--build-id=none -fno-math-errno # -fwhole-program
)
target_link_options(${PROJECT_NAME} PRIVATE -flto -s
  -nostdlib++
  )
target_link_libraries(${PROJECT_NAME} PRIVATE
    pspdebug
    pspdisplay
    pspge
)

# Create an EBOOT.PBP file
create_pbp_file(
    TARGET ${PROJECT_NAME}
    ICON_PATH NULL
    BACKGROUND_PATH NULL
    PREVIEW_PATH NULL
    TITLE ${PROJECT_NAME}
    VERSION 01.00
)
