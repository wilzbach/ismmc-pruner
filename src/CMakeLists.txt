cmake_minimum_required(VERSION 3.5)
project(src)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

set(SOURCE_FILES
    cpp/build/CMakeFiles/3.4.3/CompilerIdC/CMakeCCompilerId.c
    cpp/build/CMakeFiles/3.4.3/CompilerIdCXX/CMakeCXXCompilerId.cpp
    cpp/build/CMakeFiles/feature_tests.c
    cpp/build/CMakeFiles/feature_tests.cxx
    cpp/flow.cpp
    cpp/flow.h
    cpp/main.cpp)

add_executable(src ${SOURCE_FILES})