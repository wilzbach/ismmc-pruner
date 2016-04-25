cmake_minimum_required(VERSION 3.4)
project(pruner)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")

set(SOURCE_FILES main.cpp flow.cpp flow.h flow.h)

#add_library(libbamtools STATIC IMPORTED)
#add_dependencies(libbamtools bamtools)

#include_directories(/usr/include/bamtools)
#add_subdirectory( bamtools )
#include_directories(bamtools/src)

add_executable(pruner ${SOURCE_FILES})

find_package(ZLIB REQUIRED)
include_directories(${ZLIB_INCLUDE_DIRS})
target_link_libraries(pruner ${ZLIB_LIBRARIES} pthread hts emon)

#target_link_libraries(pruner bamtools z)
#target_link_libraries(pruner z)