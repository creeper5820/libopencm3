find_program(OpenOCD openocd)

function(set_openocd_interface interface)
  set(OPENOCD_INTERFACE ${interface} PARENT_SCOPE)
  message(STATUS "openocd interface: ${interface}")
endfunction()

function(set_openocd_target target)
  set(OPENOCD_TARGET ${target} PARENT_SCOPE)
  message(STATUS "openocd target: ${target}")
endfunction()

function(add_openocd_upload_target target)
  if(NOT OpenOCD)
    message(FATAL_ERROR "openocd not found.")
  endif()

  if(NOT DEFINED OPENOCD_INTERFACE)
    message(FATAL_ERROR "openocd interface not set.")
  endif()

  if(NOT DEFINED OPENOCD_TARGET)
    message(FATAL_ERROR "openocd target not set.")
  endif()

  add_custom_target(download.${target} ALL
    COMMAND ${OpenOCD}
    -f interface/${OPENOCD_INTERFACE}.cfg
    -f target/${OPENOCD_TARGET}.cfg
    -c "program ${target} verify reset exit"
  )

  set_target_properties(download.${target} PROPERTIES EXCLUDE_FROM_ALL TRUE)
endfunction()