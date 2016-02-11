cmake_minimum_required(VERSION 3.4)
project(prun_bamtools)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

set(SOURCE_FILES main.cpp)

#add_library(libbamtools STATIC IMPORTED)
#add_dependencies(libbamtools bamtools)

include_directories(/usr/include/bamtools)
#add_subdirectory( bamtools )
#include_directories(bamtools/src)

add_executable(prun_bamtools ${SOURCE_FILES})
target_link_libraries(prun_bamtools bamtools)
