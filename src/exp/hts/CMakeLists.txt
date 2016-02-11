cmake_minimum_required(VERSION 3.4)
project(prun_hts)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

set(SOURCE_FILES main.c)

add_executable(prun_hts ${SOURCE_FILES})

find_package(ZLIB REQUIRED)
include_directories(${ZLIB_INCLUDE_DIRS})
target_link_libraries(prun_hts ${ZLIB_LIBRARIES} pthread hts)
