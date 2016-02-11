cmake_minimum_required(VERSION 3.4)
project(prun_seqan)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DSEQAN_HAS_ZLIB=1 -std=c++11")

set(SOURCE_FILES main.cpp)

add_executable(prun_seqan ${SOURCE_FILES})

find_package(ZLIB REQUIRED)
include_directories(${ZLIB_INCLUDE_DIRS})
target_link_libraries(prun_seqan ${ZLIB_LIBRARIES} pthread)
