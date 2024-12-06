# OpenOCD烧录功能

## 概述

本项目使用OpenOCD(Open On-Chip Debugger)来烧录固件到目标设备。OpenOCD是一个开源工具,用于嵌入式设备的调试、编程和边界扫描测试。我们的CMake脚本提供了一种简单的方法来配置和使用OpenOCD进行固件烧录。

## 前提条件

- 安装CMake(版本3.0或更高)
- 安装OpenOCD
- 支持的调试器(如ST-Link)
- 目标设备(如STM32F1系列微控制器)

## 设置

1. 确保OpenOCD已正确安装并添加到系统PATH中。
2. 在您的CMakeLists.txt文件中包含OpenOCD相关的函数定义。

## 使用方法

### 1. 设置OpenOCD目标

使用`set_openocd_target`函数设置目标设备。例如,对于STM32F1系列:

```cmake
set_openocd_target(stm32f1x)
```

### 2. 设置OpenOCD接口

使用`set_openocd_interface`函数设置调试器接口。例如,对于ST-Link:

```plaintext
set_openocd_interface(stlink)
```

### 3. 添加烧录目标

使用`add_openocd_upload_target`函数添加烧录目标。通常,您会将项目名称作为参数传递:

```plaintext
add_openocd_upload_target(${PROJECT_NAME})
```

### 4. 烧录固件

完成上述设置后,您可以使用以下命令烧录固件:

```plaintext
cmake --build . --target download.${PROJECT_NAME}
```

或者,如果您使用的是Unix Makefile:

```plaintext
make download.${PROJECT_NAME}
```

## 示例

以下是一个完整的示例,展示了如何在CMakeLists.txt中设置OpenOCD烧录:

```plaintext
cmake_minimum_required(VERSION 3.0)
project(MySTM32Project)

# ... 其他项目设置 ...

# 设置OpenOCD目标和接口
set_openocd_target(stm32f1x)
set_openocd_interface(stlink)

# 添加烧录目标
add_openocd_upload_target(${EXECUTABLE})
```

## 注意事项

- 确保在调用`add_openocd_upload_target`之前设置目标和接口。
- 烧录目标名称将是"download.$PROJECT_NAME"。
- 如果OpenOCD未找到或目标/接口未设置,脚本将报错。
- 您可以根据需要多次调用`add_openocd_upload_target`来为不同的目标创建烧录任务。


## 故障排除

如果遇到问题:

1. 确保OpenOCD已正确安装并在PATH中。
2. 验证您的硬件连接是否正确。
3. 检查是否为您的特定设备选择了正确的目标和接口配置。
4. 查看OpenOCD的输出以获取更详细的错误信息。