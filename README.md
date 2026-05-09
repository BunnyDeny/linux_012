# 🐧 linux_012
> learn linux0.12

---

## 🛠️ 环境搭建

在 Ubuntu/Debian 系统上，安装编译和运行所需的工具：

```bash
sudo apt update
sudo apt install build-essential qemu-system-x86
```

其中：
- 🔧 `build-essential` 包含 `make`、`gcc` 等必要的编译工具
- 💻 `qemu-system-x86` 提供 QEMU 虚拟机，用于运行编译好的内核镜像

---

## 🔨 编译

在项目根目录执行：

```bash
make
```

✅ 编译成功后，会在 `build/` 目录下生成 `linux.img` 内核镜像文件。

---

## 🚀 启动系统

使用 QEMU 运行编译好的内核镜像：

```bash
qemu-system-i386 -fda build/linux.img
```

🖥️ 如果不需要图形界面（串口输出到终端），可加上 `-nographic`：

```bash
qemu-system-i386 -fda build/linux.img -nographic
```

> ⚠️ **注意**：目前镜像中不包含根文件系统，内核启动到最后会提示 `unable to mount root`，这是正常现象，说明内核本身已成功运行 🎉
