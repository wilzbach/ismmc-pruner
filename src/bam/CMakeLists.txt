cmake_minimum_required(VERSION 3.4)
project(pruner)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")

set(SOURCE_FILES main.cpp)

add_executable(pruner_in in.c)
target_link_libraries(pruner_in z pthread hts emon)

add_executable(pruner_out out.c)
target_link_libraries(pruner_out z pthread hts emon)
