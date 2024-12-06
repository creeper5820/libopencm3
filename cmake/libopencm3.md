# FindLibopencm3

查找适用于在变量 DEVICE 中指定的目标设备的 Libopencm3 库。在调用 `find_package(Libopencm3)` 之前,您必须将此变量设置为 MCU 的完整名称,否则搜索将失败。

## 概述

此目录包含可在您的项目中使用的 CMake 支持模块。该模块提供了使用 CMake 的 `find_package()` 命令来收集编译器定义、链接器选项、Libopencm3 库名称及其路径的能力。此外,它还为您的 MCU 生成适用的链接器脚本。

典型调用方式:

```plaintext
list(APPEND CMAKE_MODULE_PATH <path_to_libopencm3>/cmake)
set(DEVICE <full_name_of_your_mcu>)
find_package(Libopencm3 REQUIRED)
```

虽然 Libopencm3 是一个多目标库,并为各种设备提供支持,但在调用 `find_package()` 之前必须提供 MCU 的标识。您必须将变量 DEVICE 设置为包含 MCU 的完整名称。然后,此模块将正确配置所有变量和/或目标。

如果设备被识别,是实际支持的 MCU,并且找到了给定 MCU 系列的编译库,那么上述调用将成功。然后,您可以将 Libopencm3 与您的二进制文件和/或库一起使用。

## 使用方法

有两种使用 Libopencm3 的方法。您可以显式引用此模块定义的变量:

```plaintext
add_definitions(${Libopencm3_DEFINITIONS})
add_link_options(${Libopencm3_LINK_OPTIONS})
link_directories(${Libopencm3_LIBRARY_DIRS})
include_directories(${Libopencm3_INCLUDE_DIRS})

add_executable(foo foo.bar)
target_link_library(foo ${Libopencm3_LIBRARY})
```

或者,您可以使用自动创建的导入目标:

```plaintext
add_executable(foo foo.bar)
target_link_library(foo Libopencm3::Libopencm3)
```

请注意,在后一种情况下,不需要手动添加编译器定义、链接器选项、包含和链接目录。如果您将目标链接到 Libopencm3,它们将自动添加。

此模块基于 Libopencm3 模板和编译器/链接器选项自动生成链接器脚本。此链接器文件生成到您的二进制输出目录中。其完整路径可在变量 `Libopencm3_LINKER_SCRIPT` 中获得。请注意,如果您使用导入的目标或变量 `Libopencm3_LINK_OPTIONS`,则此链接器脚本会自动被您的目标使用。

## 组件

Libopencm3 包提供了用户可以选择的几个组件:

### `hal`

此组件代表 Libopencm3 HAL 库。如果指定了此组件,则 Libopencm3 包将提供用于链接目的的导入目标,以及包含编译器和链接器指令、包含和链接路径的变量。

### `ld`

此组件提供自动生成的链接器脚本。如果指定了此组件,则 Libopencm3 包将尝试生成链接器脚本。这将存储在您的二进制输出目录中。

如果未指定任何组件,默认行为是同时搜索 hal 和 ld 组件。如果其中任何一个未找到,则包搜索失败。

如果同时指定了 hal 和 ld 组件,则生成的链接器脚本会自动被导入的目标和链接器选项变量使用。

## 导入的目标

### `Libopencm3::Libopencm3`

适用于您的 MCU 的 Libopencm3 HAL。此库自动配置编译器以使用正确的自动生成的链接器脚本进行链接,导出包含路径和编译器定义。

## 可用的CMAKE变量

- `Libopencm3_FOUND`: 如果找到 Libopencm3,则为 True。由 hal 组件提供。
- `Libopencm3_LIBRARY`: 链接 Libopencm3 所需的库名称。由 hal 组件提供。
- `Libopencm3_DEFINITIONS`: 正确使用 Libopencm3 所需的编译定义。由 hal 组件提供。
- `Libopencm3_INCLUDE_DIRS`: Libopencm3 包含目录的路径。由 hal 组件提供。
- `Libopencm3_LIBRARY_DIRS`: 存在 Libopencm3 库的目录路径。由 hal 组件提供。
- `Libopencm3_LINK_OPTIONS`: 正确使用 Libopencm3 所需的链接器选项。由 hal 组件提供。
- `Libopencm3_LINKER_SCRIPT`: 适用于目标设备的自动生成的链接器脚本的路径。由 ld 组件提供。
- `Libopencm3_ROOT_DIR`: Libopencm3 的根目录。始终可用。


## 修改链接脚本

如果您需要在使用之前修改链接器脚本,可以使用以下方法:

```plaintext
find_package(Libopencm3 REQUIRED COMPONENTS hal)
find_package(Libopencm3 REQUIRED COMPONENTS ld)

# Libopencm3_LINKER_SCRIPT 现在包含链接器脚本的路径,但不会自动引用。
# 您可以在此处以编程方式修改它,生成新的链接器脚本,然后从导入的目标引用它。

set_properties(TARGET Libopencm3::Libopencm3
    APPEND PROPERTY INTERFACE_LINK_OPTIONS -T${path_to_your_linker_script}
)

# 或者全局使用它

add_link_options(-T${path_to_your_linker_script})
```

这样,您就可以在使用 Libopencm3 之前对链接器脚本进行自定义修改。