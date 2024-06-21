project(proto)

option(ENABLE_GRPC "" OFF)

set(FILE_DIR "${CMAKE_CURRENT_LIST_DIR}")
find_package(Protobuf CONFIG REQUIRED)
if (ENABLE_GRPC)
    find_package(gRPC CONFIG REQUIRED)
endif ()
if (NOT _GRPC_CPP_PLUGIN_EXECUTABLE)
    find_program(_GRPC_CPP_PLUGIN_EXECUTABLE grpc_cpp_plugin)
endif ()
if (NOT Protobuf_PROTOC_EXECUTABLE)
    find_program(Protobuf_PROTOC_EXECUTABLE protoc)
endif ()

message("--------------------------------------")
message("| Protobuf Info:              ")
message("| Version: ${Protobuf_VERSION}")
message("| protoc:  ${Protobuf_PROTOC_EXECUTABLE}")
message("--------------------------------------")
set(_PROTOBUF_LIBPROTOBUF protobuf::libprotobuf)
if (ENABLE_GRPC)
    set(_REFLECTION gRPC::grpc++_reflection)
    message("| gRPC Info: ")
    message("| Version: ${gRPC_VERSION}")
    message("| plugin:  ${_GRPC_CPP_PLUGIN_EXECUTABLE}")
    message("--------------------------------------")
endif ()
function(my_proto_gen target_name)
    set(oneValueArgs OUTPUT_DIR)
    set(multiValueArgs PROTO)
    cmake_parse_arguments(PARSE_ARGV 1 ARG "" "${oneValueArgs}" "${multiValueArgs}")
    set(ARG_TARGET ${target_name})
    message("┌─────── PROTO GEN ────────────")
    message("│ Target Name: ${ARG_TARGET}")
    message("│ Proto:       ${ARG_PROTO}")
    message("└──────────────────────────────")
    add_library(${ARG_TARGET} STATIC)

    if (NOT ARG_OUTPUT_DIR)
        set(ARG_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}")
    endif ()

    make_directory(${ARG_OUTPUT_DIR})

    foreach (proto_src ${ARG_PROTO})
        get_filename_component(proto_abs_path "${proto_src}" ABSOLUTE BASE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
        get_filename_component(rg_proto "${proto_abs_path}" NAME)
        get_filename_component(proto_name ${proto_abs_path} NAME_WLE)
        get_filename_component(proto_dir ${proto_abs_path} DIRECTORY)

        # Generated sources
        set(rg_proto_srcs "${ARG_OUTPUT_DIR}/${proto_name}.pb.cc")
        set(rg_proto_hdrs "${ARG_OUTPUT_DIR}/${proto_name}.pb.h")
        if (ENABLE_GRPC)
            set(rg_grpc_srcs "${ARG_OUTPUT_DIR}/${proto_name}.grpc.pb.cc")
            set(rg_grpc_hdrs "${ARG_OUTPUT_DIR}/${proto_name}.grpc.pb.h")
            add_custom_command(
                    OUTPUT "${rg_proto_srcs}" "${rg_proto_hdrs}" "${rg_grpc_srcs}" "${rg_grpc_hdrs}"
                    COMMAND ${Protobuf_PROTOC_EXECUTABLE}
                    ARGS --grpc_out "${ARG_OUTPUT_DIR}" --cpp_out "${ARG_OUTPUT_DIR}" -I "${proto_dir}"
                    --plugin=protoc-gen-grpc="${_GRPC_CPP_PLUGIN_EXECUTABLE}" "${rg_proto}"
                    DEPENDS "${proto_abs_path}" "${Protobuf_PROTOC_EXECUTABLE}"
            )
            target_sources(${ARG_TARGET}
                    PRIVATE
                    ${rg_grpc_srcs}
                    ${rg_proto_srcs}
                    PUBLIC
                    ${rg_grpc_hdrs}
                    ${rg_proto_hdrs})
            target_link_libraries(${ARG_TARGET} PUBLIC protobuf::libprotobuf gRPC::grpc++_reflection gRPC::grpc++)

        else ()
            add_custom_command(
                    OUTPUT "${rg_proto_srcs}" "${rg_proto_hdrs}"
                    COMMAND ${Protobuf_PROTOC_EXECUTABLE}
                    ARGS --cpp_out "${ARG_OUTPUT_DIR}" -I "${proto_dir}"
                    "${rg_proto}"
                    DEPENDS "${proto_abs_path}" "${Protobuf_PROTOC_EXECUTABLE}"
            )
            target_sources(${ARG_TARGET}
                    PRIVATE
                    ${rg_grpc_srcs}
                    ${rg_proto_srcs}
            )
            target_link_libraries(${ARG_TARGET} PUBLIC protobuf::libprotobuf)

        endif ()
    endforeach ()

    target_include_directories(${ARG_TARGET} INTERFACE ${ARG_OUTPUT_DIR})
endfunction()

unset(FILE_DIR)