include(FindPackageHandleStandardArgs)
include(PythonInstall)
include(TargetCopyFiles)
include(EnvironmentScript)

if(NOT PYTHON_BINARY_DIR)
    set(PYTHON_BINARY_DIR "${PROJECT_BINARY_DIR}/python_package"
        CACHE PATH "Location of python package in build tree")
endif()
add_to_python_path(${PYTHON_BINARY_DIR})

function(add_python_module module)
    string(REGEX REPLACE "\\." "/" location "${module}")
    string(REGEX REPLACE "/" "_" fullname "${location}")
    string(FIND "${module}" "." first_dot)
    if(first_dot EQUAL -1)
        set(base_module ${module})
    else()
        string(SUBSTRING "${module}" 0 ${first_dot} base_module)
    endif()
    get_filename_component(module_name "${location}" NAME)
    cmake_parse_arguments(${fullname}
        "FAKE_INIT;NOINSTALL;INSTALL"
        "MAIN;WRAPPERNAME;HEADER_DESTINATION;TARGETNAME;EXTENSION"
        "SOURCES;HEADERS;PYFILES;EXCLUDE;LIBRARIES" 
        ${ARGN}
    )
    if(NOT ${fullname}_MAIN)
        set(${fullname}_MAIN "module.cc")
    endif()
    set(do_install TRUE)
    if(${fullname}_NOINSTALL)
        set(do_install FALSE)
    endif()
    set(has_extension FALSE) # No compiled python module
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${${fullname}_MAIN}")
        set(has_extension TRUE)
        if(${fullname}_EXTENSION)
            set(extension_name ${${fullname}_EXTENSION})
        else()
            get_filename_component(extension_name ${location} NAME_WE)
            if("${extension_name}" STREQUAL "${module_name}")
                get_filename_component(location "${location}" PATH)
                if("${location}" STREQUAL "")
                    set(location "./")
                endif()
            endif()
        endif()
    endif()
    set(excluded "${${fullname}_MAIN}")
    if(${fullname}_EXCLUDE)
        file(GLOB files RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" ${${fullname}_EXCLUDE})
        list(APPEND excluded ${files})
    endif()
    if(${fullname}_SOURCES)
        file(GLOB sources RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" ${${fullname}_SOURCES})
        list(REMOVE_ITEM sources ${excluded})
        list(INSERT sources 0 "${${fullname}_MAIN}")
        list(REMOVE_DUPLICATES sources)
    else()
        set(sources "${${fullname}_MAIN}")
    endif()
    if(${fullname}_HEADERS)
        file(GLOB headers RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" ${${fullname}_HEADERS})
        list(REMOVE_ITEM headers ${excluded})
    endif()
    if(${fullname}_PYFILES)
        file(GLOB pyfiles RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" ${${fullname}_PYFILES})
        list(REMOVE_ITEM pyfiles ${excluded})
    endif()
    set(header_destination ${base_module}/include/${location})
    if(${fullname}_HEADER_DESTINATION)
        string(REGEX REPLACE
            "\\." "/"
            header_destination 
            ${${fullname}_HEADER_DESTINATION}
        )
    endif()
    set(targetname ${fullname})
    if(${fullname}_TARGETNAME)
        set(targetname ${${fullname}_TARGETNAME})
    endif()
    if(${fullname}_FAKE_INIT)
        set(fake_init_file "${PYTHON_BINARY_DIR}/${location}/__init__.py")
        if(NOT EXISTS "${fake_init_file}")
           file(WRITE "${fake_init_file}" "# Empty file added by CMake")
        endif()
        if(do_install)
            install_python(FILES "${fake_init_file}" DESTINATION ${location})
        endif()
    endif()


    include_directories(${PYTHON_INCLUDE_DIRS})
    if(NUMPY_INCLUDE_DIRS)
        include_directories(${NUMPY_INCLUDE_DIRS})
    endif()

    if(has_extension)
        add_library (${targetname} MODULE ${sources})
        target_link_libraries(${targetname} ${PYTHON_LIBRARIES})
        set_target_properties(${targetname}
            PROPERTIES
            OUTPUT_NAME "${extension_name}"
            PREFIX "" SUFFIX ".so"
            LIBRARY_OUTPUT_DIRECTORY "${PYTHON_BINARY_DIR}/${location}"
        )
        if(${fullname}_LIBRARIES)
            target_link_libraries(${targetname} ${${fullname}_LIBRARIES})
        endif()
        if(do_install)
            install_python(TARGETS ${targetname} DESTINATION ${location})
        endif()
    endif()
    if(NOT "${pyfiles}" STREQUAL "")
        file(RELATIVE_PATH targetname_copy "${PROJECT_SOURCE_DIR}"
            "${CMAKE_CURRENT_SOURCE_DIR}")
        string(REGEX REPLACE "( |/)" "_" targetname_copy "${targetname_copy}")
        set(targetname_copy "copy_${targetname_copy}")
        if(NOT TARGET ${targetname_copy} AND NOT TARGET ${targetname})
            add_custom_target(${targetname_copy} ALL)
        endif()
        add_copy_files(${targetname_copy}
            FILES ${pyfiles}
            DESTINATION "${PYTHON_BINARY_DIR}/${location}"
        )
        if(TARGET ${targetname})
            add_dependencies(${targetname} ${targetname_copy})
        endif()
        if(do_install)
            install_python(FILES ${pyfiles} DESTINATION ${location})
        endif()
    endif()

    if(NOT "${headers}" STREQUAL "" AND do_install)
        install_python(FILES ${headers} 
            DESTINATION ${header_destination}
            COMPONENT dev
        )
    endif()
endfunction()
