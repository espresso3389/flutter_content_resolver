cmake_minimum_required(VERSION 3.4.1)

add_link_options("LINKER:--build-id=none")

add_library(dbufhelper SHARED cpp/directBufferAndroid.cpp)

target_compile_options(dbufhelper PRIVATE -DBUILD_FOR_ANDROID)
