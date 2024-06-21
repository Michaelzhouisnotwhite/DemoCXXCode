message("setting up 3rdparty")
set(thirdparty_dir ${CMAKE_CURRENT_LIST_DIR}/../thirdparty)
set(thirdparty_build_dir ${CMAKE_BINARY_DIR}/thirdparty-build)
set(thirdparty_install_dir ${CMAKE_BINARY_DIR}/thirdparty-install)
message("thirdparty dir: ${CMAKE_CURRENT_LIST_DIR}/../thirdparty")

include(${thirdparty_dir}/ModernExternalProject.cmake/src/ModernExternalProject.cmake)

ModernExternalProject_Add(abseil-cpp
        SOURCE_DIR ${thirdparty_dir}/abseil-cpp
        CMAKE_CACHE "ABSL_ENABLE_INSTALL:BOOL=ON" "CMAKE_CXX_STANDARD:STRING=14"
        BUILD_TYPE Release
        INSTALL_DIR ${thirdparty_install_dir}
        VERBOSE configure
)
ModernExternalProject_Add(fmt
        SOURCE_DIR ${thirdparty_dir}/fmt
        CMAKE_CACHE FMT_PRINT=ON
        BUILD_TYPE Release
        INSTALL_DIR ${thirdparty_install_dir}
        VERBOSE configure
)

ModernExternalProject_Add(protobuf
        SOURCE_DIR ${thirdparty_dir}/protobuf
        CMAKE_CACHE "protobuf_ABSL_PROVIDER=package" "CMAKE_PREFIX_PATH:STRING=${CMAKE_BINARY_DIR}/thirdparty-install" CMAKE_CXX_STANDARD:STRING=14 protobuf_BUILD_TESTS=OFF
        BUILD_TYPE Release
        INSTALL_DIR ${thirdparty_install_dir}
        VERBOSE configure
)
if (ENABLE_GRPC)

    ModernExternalProject_Add(grpc
            SOURCE_DIR ${thirdparty_dir}/grpc
            CMAKE_CACHE "gRPC_ABSL_PROVIDER=package"
            gRPC_INSTALL=ON
            "CMAKE_PREFIX_PATH:STRING=${CMAKE_BINARY_DIR}/thirdparty-install"
            CMAKE_CXX_STANDARD:STRING=14
            gRPC_PROTOBUF_PROVIDER=package

            BUILD_TYPE Release
            INSTALL_DIR ${thirdparty_install_dir}
            VERBOSE configure
    )
endif ()
