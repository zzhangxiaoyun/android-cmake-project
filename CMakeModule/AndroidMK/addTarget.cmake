SET(ADD_TARGET_DEBUG OFF)

SET(TMP_SRC_FILES "")
SET(TARGET_COMPILE_OPTIONS_FILTER "(-O.*)")

function(getSrc out)
    foreach(getSrc_src_list ${LOCAL_SRC_FILES})
        if( "${getSrc_src_list}" MATCHES ".*\\$.*")
            parseMakeFileFunc("${getSrc_src_list}" getSrc_src_list)
        endif()
        foreach(getSrc_src ${getSrc_src_list})
            if(EXISTS ${LOCAL_PATH}/${getSrc_src})
                LIST(APPEND tmp_list ${LOCAL_PATH}/${getSrc_src})
            endif()
        endforeach()
    endforeach()
    SET(${out} "${tmp_list}" PARENT_SCOPE)
endfunction()

function(addFlag module in)
    foreach(addFlag_flg_list ${${in}})
        if( "${addFlag_flg_list}" MATCHES ".*\\$.*")
            parseMakeFileFunc("${addFlag_flg_list}" addFlag_flg_list)
        endif()
        foreach(addFlag_flg ${addFlag_flg_list})
            if("${addFlag_flg}" MATCHES "^\\-D.*")
                string(REPLACE "\\" "" addFlag_flg "${addFlag_flg}")
                if(ADD_TARGET_DEBUG)
                    message("addFlag: ${addFlag_flg}")
                endif()
                target_compile_definitions(${module} PRIVATE "${addFlag_flg}")
            else()
                if(NOT ${addFlag_flg} MATCHES "${TARGET_COMPILE_OPTIONS_FILTER}")
                    if(ADD_TARGET_DEBUG)
                        message("addFlag Option: ${addFlag_flg}")
                    endif()
#                    target_compile_options(${module} PRIVATE ${addFlag_flg})
                endif()
            endif()
        endforeach()
    endforeach()
endfunction()

function(addInclude module in)
    target_include_directories(${module} PRIVATE ${LOCAL_PATH})
    foreach(addInclude_include_list ${${in}})
        if( "${addInclude_include_list}" MATCHES ".*\\$.*")
            parseMakeFileFunc("${addInclude_include_list}" addInclude_include_list)
        endif()
        foreach(addInclude_include ${addInclude_include_list})
#            target_include_directories(${module} PRIVATE ${PROJECT_DIR}/${addInclude_include})
            if( "${addInclude_include}" MATCHES "^/")
                if ("${addInclude_include}" MATCHES "^${PROJECT_DIR}.*" )
                    set(addInclude_directories "${addInclude_include}")
                else()
                    set(addInclude_directories "${PROJECT_DIR}${addInclude_include}")
                endif ()
            else()
                set(addInclude_directories "${PROJECT_DIR}/${addInclude_include}")
            endif()
            if(ADD_TARGET_DEBUG)
                message("addInclude dir: ${addInclude_directories}")
            endif()
            target_include_directories(${module} PRIVATE ${addInclude_directories})
        endforeach()
    endforeach()
endfunction()

function(addExportInclude module path)
    if(EXISTS "${path}")
        file(STRINGS ${path} addExportInclude_list)
        foreach(addExportInclude_include ${addExportInclude_list})
            if(ADD_TARGET_DEBUG)
                message("${module} addExportInclude : ${addExportInclude_include}")
            endif()
            target_include_directories("${module}" PRIVATE ${addExportInclude_include})
        endforeach()
    endif()
endfunction()

function(exportInclude module_type)
    foreach(exportInclude_include_list ${LOCAL_EXPORT_C_INCLUDE_DIRS})
        if( "${exportInclude_include_list}" MATCHES ".*\\$.*")
            parseMakeFileFunc("${exportInclude_include_list}" exportInclude_include_list)
        endif()
        foreach(exportInclude_include ${exportInclude_include_list})
            saveExportInclude("${module_type}" "${exportInclude_include}")
        endforeach()
        doNeedExport("${module_type}" "${exportInclude_include_list}")
    endforeach()
endfunction()

function(addDependencies module lib path)
    # TODO Android.mk
    parseAndroidMK(${PROJECT_DIR}/${path}/Android.mk)
endfunction()

function(addModuleLibraries module libraries type)
    string(REPLACE "@" "-" ${libraries} "${${libraries}}")
    foreach(addModuleLibraries_lib_list ${${libraries}})
        if( "${addModuleLibraries_lib_list}" MATCHES ".*\\$.*")
            parseMakeFileFunc("${addModuleLibraries_lib_list}" addModuleLibraries_lib_list)
        endif()

        foreach(addModuleLibraries_lib ${addModuleLibraries_lib_list})
#            containsModule("${addModuleLibraries_lib}_${type}" is_find)
#            if(is_find)
#                continue()
#            endif()

            if(ADD_TARGET_DEBUG)
                message("addModuleLibraries: ${type} ${addModuleLibraries_lib}")
            endif()
            addModuleDependencies("${module}" "${type}" "${addModuleLibraries_lib}")
        endforeach()

    endforeach()
endfunction()

function(addTarget type)
    if("${LOCAL_MODULE}" MATCHES ".*@.*")
        string(REPLACE "@" "-" LOCAL_MODULE "${LOCAL_MODULE}")
    endif()
    containsModule("${LOCAL_MODULE}_${type}" is_find)
    if(is_find)
        return()
    endif()

    getSrc(TMP_SRC_FILES)
    SET(local_module "${LOCAL_MODULE}_${type}")
    if(NOT TMP_SRC_FILES)
        message(STATUS "${local_module}: null src, continue and skip.")
        addModule("${local_module}" "${LOCAL_PATH}")
        return()
    endif()
    message("addTarget: ${local_module}")
    if("${type}" MATCHES "(${MK_SHARED}|${MK_STATIC})")
        add_library(${local_module} ${type} ${TMP_SRC_FILES})
        set_target_properties(${local_module} PROPERTIES PREFIX "")
        set_target_properties(${local_module} PROPERTIES OUTPUT_NAME "${LOCAL_MODULE}")
    else()
        add_executable(${local_module} ${TMP_SRC_FILES})
    endif()
    addFlag(${local_module} LOCAL_CFLAGS)
    addFlag(${local_module} LOCAL_CPPFLAGS)
    addInclude(${local_module} LOCAL_C_INCLUDES)
    addModule("${local_module}" "${LOCAL_PATH}")
    addModuleLibraries("${local_module}" LOCAL_SHARED_LIBRARIES "${MK_SHARED}")
    addModuleLibraries("${local_module}" LOCAL_STATIC_LIBRARIES "${MK_STATIC}")
    exportInclude("${local_module}")
endfunction()