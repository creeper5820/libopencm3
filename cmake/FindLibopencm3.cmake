include(FindPackageHandleStandardArgs)

cmake_minimum_required(VERSION 3.3)

find_program(PYTHON_EXE python)

set(_LOCM3_PKG_VARIABLES "")

if(NOT Libopencm3_FIND_COMPONENTS)
	set(Libopencm3_FIND_COMPONENTS hal ld)
endif()

if("hal" IN_LIST Libopencm3_FIND_COMPONENTS)
	list(APPEND _LOCM3_PKG_VARIABLES
		Libopencm3_LIBRARY
		Libopencm3_LIBRARY_DIRS
		Libopencm3_INCLUDE_DIRS
		Libopencm3_DEFINITIONS
		Libopencm3_LINK_OPTIONS
	)
endif()

if("ld" IN_LIST Libopencm3_FIND_COMPONENTS)
	list(APPEND _LOCM3_PKG_VARIABLES
		Libopencm3_LINKER_SCRIPT
	)
endif()

if("${PYTHON_EXE}" STREQUAL "PYTHON_EXE-NOTFOUND")
	message(FATAL_ERROR "请安装Python，libopencm3构建依赖Python")
endif()

if(NOT DEVICE)
	message(FATAL_ERROR "未指定目标设备，请在Makefile中定义变量DEVICE以包含MCU的\"完整名称\"")
endif()

get_filename_component(Libopencm3_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
include(${Libopencm3_ROOT_DIR}/cmake/openocd.cmake)

set(_LOCM3_DATA_FILE ${Libopencm3_ROOT_DIR}/ld/devices.data)

if(NOT EXISTS ${_LOCM3_DATA_FILE})
	message(FATAL_ERROR "未找到${_LOCM3_DATA_FILE}")
endif()

function(_genlink_obtain DEVICE PROPERTY OUTPUT)
	execute_process(COMMAND
		${PYTHON_EXE} ${Libopencm3_ROOT_DIR}/scripts/genlink.py ${_LOCM3_DATA_FILE} ${DEVICE} ${PROPERTY}
		OUTPUT_VARIABLE OUT_DATA
		RESULT_VARIABLE SUCCESS
	)

	if("${SUCCESS}" EQUAL "0")
		message(DEBUG ">> ${OUT_DATA}")
		set("${OUTPUT}" "${OUT_DATA}" PARENT_SCOPE)
	else()
		message(FATAL_ERROR "未能获取${DEVICE}的具体型号，请确认设备完整名称是否正确")
	endif()
endfunction()

_genlink_obtain(${DEVICE} FAMILY _DEVICE_FAMILY)
_genlink_obtain(${DEVICE} SUBFAMILY _DEVICE_SUBFAMILY)
_genlink_obtain(${DEVICE} CPU _DEVICE_CPU)
_genlink_obtain(${DEVICE} FPU _DEVICE_FPU)

if("${_DEVICE_FAMILY}" STREQUAL "")
	message(FATAL_ERROR "未在${_LOCM3_DATA_FILE}中找到${DEVICE}")
endif()

# This essentially duplicates actions of genlink-config.mk
set(_LOCM3_THUMB_DEVS
	cortex-m0
	cortex-m0plus
	cortex-m3
	cortex-m4
	cortex-m7
)

set(_ARCH_FLAGS "")
list(APPEND _ARCH_FLAGS -mcpu=${_DEVICE_CPU})

if("${_DEVICE_CPU}" IN_LIST _LOCM3_THUMB_DEVS)
	list(APPEND _ARCH_FLAGS -mthumb)
endif()

if("${_DEVICE_FPU}" STREQUAL "soft")
	list(APPEND _ARCH_FLAGS -msoft-float)
elseif("${_DEVICE_FPU}" STREQUAL "hard-fpv4-sp-d16")
	list(APPEND _ARCH_FLAGS -mfloat-abi=hard -mfpu=fpv4-sp-d16)
elseif("${_DEVICE_FPU}" STREQUAL "hard-fpv5-sp-d16")
	list(APPEND _ARCH_FLAGS -mfloat-abi=hard -mfpu=fpv5-sp-d16)
else()
	message(FATAL_ERROR "未找到匹配的FPU参数(soft, hard-fpv4-sp-d16, hard-fpv5-sp-d16)")
endif()

# Find library for given family or subfamily
set(_LOCM3_LIBNAME
	opencm3_${_DEVICE_FAMILY}
	opencm3_${_DEVICE_SUBFAMILY}
)

if("ld" IN_LIST Libopencm3_FIND_COMPONENTS)
	_genlink_obtain(${DEVICE} DEFS _DEVICE_DEFS)
	string(REPLACE " " ";" _DEVICE_DEFS ${_DEVICE_DEFS})

	set(Libopencm3_LINKER_SCRIPT ${CMAKE_BINARY_DIR}/generated.${DEVICE}.ld)

	# 判断C编译器是否被设置
	if(NOT CMAKE_C_COMPILER)
		message(FATAL_ERROR "未指定C编译器，请设置CMAKE_C_COMPILER")
	endif()

	# If found, then generate the linker script
	execute_process(COMMAND ${CMAKE_C_COMPILER}
		${_ARCH_FLAGS} ${_DEVICE_DEFS}
		-P -E ${Libopencm3_ROOT_DIR}/ld/linker.ld.S
		-o ${Libopencm3_LINKER_SCRIPT}
		RESULT_VARIABLE CPP_RESULT
	)

	if(NOT "${CPP_RESULT}" EQUAL "0")
		message(FATAL_ERROR "无法为 ${DEVICE} 生成链接脚本")
	else()
		set(Libopencm3_ld_FOUND TRUE)
	endif()
endif()

if("hal" IN_LIST Libopencm3_FIND_COMPONENTS)
	_genlink_obtain(${DEVICE} CPPFLAGS Libopencm3_DEFINITIONS)

	foreach(LOCM3_CANDIDATE ${_LOCM3_LIBNAME})
		if(EXISTS ${Libopencm3_ROOT_DIR}/lib/lib${LOCM3_CANDIDATE}.a)
			set(Libopencm3_LIBRARY ${LOCM3_CANDIDATE})
			set(Libopencm3_LIBRARY_DIRS ${Libopencm3_ROOT_DIR}/lib)
			set(Libopencm3_INCLUDE_DIRS ${Libopencm3_ROOT_DIR}/include)
			set(Libopencm3_DEFINITIONS ${Libopencm3_DEFINITIONS} ${_ARCH_FLAGS})
			set(Libopencm3_LINK_OPTIONS -static -nostartfiles -specs=nosys.specs ${_ARCH_FLAGS})

			if("ld" IN_LIST Libopencm3_FIND_COMPONENTS)
				list(APPEND Libopencm3_LINK_OPTIONS -T${Libopencm3_LINKER_SCRIPT})
			endif()

			if(NOT TARGET Libopencm3::Libopencm3)
				# Provide imported target, which wraps Libopencm3
				add_library(Libopencm3::Libopencm3 STATIC IMPORTED)
				set_target_properties(Libopencm3::Libopencm3
					PROPERTIES
					IMPORTED_LOCATION ${Libopencm3_LIBRARY_DIRS}/lib${Libopencm3_LIBRARY}.a
					INTERFACE_INCLUDE_DIRECTORIES ${Libopencm3_INCLUDE_DIRS}
				)

				set_property(TARGET Libopencm3::Libopencm3
					PROPERTY INTERFACE_COMPILE_OPTIONS
					${Libopencm3_DEFINITIONS}
				)

				set_property(TARGET Libopencm3::Libopencm3
					PROPERTY INTERFACE_LINK_OPTIONS
					${Libopencm3_LINK_OPTIONS}
				)
			endif()

			set(Libopencm3_hal_FOUND TRUE)
			break()
		else()
			message(FATAL_ERROR "未找到静态链接文件${Libopencm3_ROOT_DIR}/lib/lib"
				"${LOCM3_CANDIDATE}.a，请编译libopencm3相关模块")
		endif()
	endforeach()
endif()

find_package_handle_standard_args(Libopencm3
	FOUND_VAR Libopencm3_FOUND
	REQUIRED_VARS ${_LOCM3_PKG_VARIABLES}
	HANDLE_COMPONENTS
)