# 🐧 linux_012
> learn linux0.12 —— 从零开始，一步步积累 🚀

---

## 🌱 本章引言

在第一章中，我们实现了一个最简引导扇区：BIOS 加载后，在屏幕上打印 `"Hello World!"` 然后死循环。这个程序只有 512 字节，什么都做不了 —— 它甚至不知道磁盘上还有其他代码。

但真实的操作系统内核远比 512 字节大得多。开机时 BIOS 只能帮我们加载第一个扇区，剩下的工作必须**由引导程序自己完成**。这就是本章的核心任务：

> **bootsect.S 负责把自己搬到安全位置，然后用 BIOS 中断把 setup 模块从磁盘加载进内存，最后跳转到 setup 执行。**

本章代码对应《从零开始写 Linux 内核》第二章，引入了 `setup.S`、构建系统 `Makefile` 以及镜像拼接工具 `tools/build.c`，完成了从"单扇区玩具"到"多模块引导"的跨越。

---

## 📁 项目结构

```
.
├── bootsect.S      ← 引导扇区（512B），加载 setup
├── setup.S         ← 第二阶段程序，被 bootsect 加载到 0x90200
├── Makefile        ← 构建系统，编译 + 链接 + 拼接
├── tools/
│   └── build.c     ← 镜像拼接工具，保证各模块长度精确
└── linux.img       ← 最终生成的可引导镜像（2560B = 5 扇区）
```

---

## 🔨 编译 & 运行

### 1️⃣ 编译

```bash
make
```

| 产物 | 大小 | 说明 |
|------|------|------|
| `bootsect` | 512 B | 纯二进制，含引导签名 `0xAA55` |
| `setup` | ≤2048 B | 纯二进制，4 个扇区 |
| `linux.img` | 2560 B | `bootsect` + `setup` 的拼接镜像 |

`build` 工具的职责：
- 确保 `bootsect` 恰好 **512 字节**，不足补零、超出截断
- 确保 `setup` 恰好 **2048 字节**（`SETUPLEN = 4` 个扇区）
- 按顺序拼接生成 `linux.img`

### 2️⃣ 运行

```bash
qemu-system-i386 -fda linux.img
```

🎉 你会看到屏幕上先后显示：
- `Setup has been loaded`（bootsect 打印 🔴 红色）
- `setup is running`（setup 打印 🔴 红色）

---

## 📜 bootsect.S 逐行详解

### 🧭 整体作用

1. 把自己从 `0x7C00` 搬到 `0x90000`
2. 从新位置继续执行
3. 用 `int 0x13` 从磁盘读取 4 个扇区（setup）到 `0x90200`
4. 打印 `"Setup has been loaded"`
5. 跳转到 setup 执行

---

### 🧩 前置知识：段地址 × 16 = 物理地址

实模式下，CPU 用 **段寄存器 × 16 + 偏移** 计算物理地址：

```
物理地址 = 段基地址 × 0x10 + 偏移地址
```

| 符号 | 值 | 物理地址 |
|------|-----|----------|
| `BOOTSEG` | `0x7C0` | `0x7C0 × 16 = 0x7C00` |
| `INITSEG` | `0x9000` | `0x9000 × 16 = 0x90000` |
| `SETUPSEG` | `0x9020` | `0x9020 × 16 = 0x90200` |

---

### 📖 代码逐段解析

#### 1️⃣ 常量定义

```asm
SETUPLEN = 4
```
- setup 模块占 **4 个扇区**（4 × 512 = 2048 字节）

```asm
BOOTSEG = 0x7c0
INITSEG = 0x9000
SETUPSEG = 0x9020
SYSSEG = 0x1000
SYSSIZE = 0x3000
ENDSEG = SYSSEG + SYSSIZE
ROOT_DEV = 0x000
```
- `BOOTSEG = 0x7C0`：bootsect 最初被 BIOS 加载到的段地址
- `INITSEG = 0x9000`：bootsect 搬家后的目标段地址（0x90000）
- `SETUPSEG = 0x9020`：setup 模块被加载到的段地址（0x90200）
- `SYSSEG/ENDSEG/SYSSIZE`：为后续加载内核预留的符号（本章暂未使用）

```asm
.code16
.text
.global _start
```
- `.code16`：生成 16 位实模式代码
- `.text`：代码段
- `.global _start`：导出入口符号

#### 2️⃣ 远跳转 —— 统一段寄存器

```asm
_start:
    jmpl $BOOTSEG, $start2
```

BIOS 跳转时的 `CS:IP` 可能不统一（有的 BIOS 用 `0x0000:0x7C00`，有的用 `0x7C0:0x0000`）。这条远跳转**强制**设置 `CS = 0x7C0`，确保后续所有段寄存器环境一致 🎯

#### 3️⃣ 把自己搬到 0x90000

```asm
start2:
    movw $BOOTSEG, %ax
    movw %ax, %ds        ; DS = 0x7C0（源段）
    movw $INITSEG, %ax
    movw %ax, %es        ; ES = 0x9000（目的段）
    movw $256, %cx       ; CX = 256 个字
    subw %si, %si        ; SI = 0（源偏移）
    subw %di, %di        ; DI = 0（目的偏移）

    rep
    movsw                ; 重复执行 movsw 256 次
```

- `256 个字 × 2 字节 = 512 字节`，恰好搬完整个引导扇区
- 从 `DS:SI = 0x7C0:0x0000 = 0x7C00` 搬到 `ES:DI = 0x9000:0x0000 = 0x90000`
- **为什么搬家？** `0x7C00` 附近的低地址内存后续会被内核覆盖，搬到 `0x90000` 更安全

#### 4️⃣ 跳转到新位置继续执行

```asm
    jmpl $INITSEG, $go
```

- 远跳转到 `0x9000:go`，CS 变成 `0x9000`
- 从这以后，代码在 `0x90000` 处执行

```asm
go:
    movw %cs, %ax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %ss
    movw $0xFF00, %sp
```

- 把 `DS`、`ES`、`SS` 都设为和 `CS` 一样（`0x9000`）
- 设置栈顶 `SP = 0xFF00`，栈底在 `0x90000 + 0xFF00 = 0x9FF00`

#### 5️⃣ 加载 setup 模块（核心！）

```asm
load_setup:
    movw $0x0000, %dx    ; DH = 0（磁头0）, DL = 0（软盘驱动器）
    movw $0x0002, %cx    ; CH = 0（0号柱面）, CL = 2（从第2扇区开始）
    movw $0x0200, %bx    ; ES:BX = 0x9000:0x0200 = 0x90200
    movb $SETUPLEN, %al  ; AL = 4（读4个扇区）
    movb $0x02, %ah      ; AH = 2（读磁盘扇区到内存）
    int $0x13            ; 🚀 调用 BIOS 磁盘服务
    jnc ok_load_setup    ; CF = 0 表示成功，跳转
```

**`int 0x13` 参数速查**：

| 寄存器 | 值 | 含义 |
|--------|-----|------|
| `AH` | `0x02` | 功能：读磁盘扇区到内存 |
| `AL` | `0x04` | 读取扇区数 |
| `CH` | `0x00` | 柱面号低 8 位 |
| `CL` | `0x02` | 开始扇区号（1-based） |
| `DH` | `0x00` | 磁头号 |
| `DL` | `0x00` | 驱动器号（0=软盘A） |
| `ES:BX` | `0x90200` | 数据缓冲区 |

> 💡 为什么从**第2扇区**开始？因为第1扇区（LBA 0）就是 bootsect 自己！setup 被构建系统放在 bootsect 之后。

```asm
    movw $0x0000, %dx
    movw $0x0000, %ax
    int $0x13            ; AH = 0：重置磁盘驱动器
    jmp load_setup       ; 重试
```

- 如果读盘失败（`CF = 1`），重置磁盘后循环重试

#### 6️⃣ 打印成功信息

```asm
ok_load_setup:
    movw $msg, %si
    movb $0x0E, %ah      ; AH = 0x0E：Teletype 输出字符
print_loop:
    lodsb                ; AL = [DS:SI]，SI++
    testb %al, %al       ; 检查字符串结束符 0
    jz print_done
    int $0x10            ; 输出 AL 中的字符，光标自动后移
    jmp print_loop
print_done:
    /* 输出回车换行，光标移到下一行开头 */
    movb $0x0D, %al
    int $0x10
    movb $0x0A, %al
    int $0x10
```

- `AH = 0x0E` 是最简单的字符输出功能，每调用一次输出一个字符并自动移动光标
- `0x0D` 是回车（光标移到行首），`0x0A` 是换行（光标移到下一行）
- 书中原版用 `AH = 0x13`（批量写字符串），功能相同但参数更复杂

#### 7️⃣ 跳转到 setup

```asm
    jmpl $SETUPSEG, $0   ; 远跳转到 0x9020:0x0000 = 0x90200
```

- 至此 bootsect 使命完成，CPU 开始执行 setup 模块

#### 8️⃣ 数据区

```asm
msg:
    .ascii "Setup has been loaded"
    .byte 0              ; 字符串结束符

.org 508
root_dev:
    .word ROOT_DEV
boot_flag:
    .word 0xaa55         ; 🪄 引导扇区签名
```

---

## 📜 setup.S 逐行详解

### 🧭 整体作用

被 bootsect 加载到 `0x90200` 后执行，在屏幕上打印 `"setup is running"`，然后死循环。

> 💡 真实的 Linux 0.11 中，setup.S 还要做很多工作（获取内存大小、切换保护模式等），本章先实现最简单的版本。

### 📖 代码解析

```asm
.code16
.text
.globl _start_setup
```
- 同样是 16 位实模式代码
- 入口符号为 `_start_setup`

```asm
_start_setup:
    movw %cs, %ax
    movw %ax, %ds
    movw %ax, %es
```
- 初始化段寄存器。此时 `CS = 0x9020`（由 bootsect 的远跳转设置）

```asm
    movw $setup_msg, %si
    movb $0x0E, %ah
setup_print_loop:
    lodsb
    testb %al, %al
    jz setup_print_done
    int $0x10
    jmp setup_print_loop
setup_print_done:
```
- 逐个字符输出 `"setup is running"`，光标从 bootsect 留下的下一行继续

```asm
    jmp .                ; 死循环
```
- setup 执行完毕，停在这里

```asm
setup_msg:
    .ascii "setup is running"
    .byte 0
```

---

## 🔧 Makefile 详解

```makefile
AS := as
LD := ld

LDFLAGS := -m elf_i386 -Ttext 0x0 -s --oformat binary
```

| 参数 | 含义 |
|------|------|
| `-m elf_i386` | 目标架构为 32 位 x86 |
| `-Ttext 0x0` | 代码段起始虚拟地址为 `0x0` |
| `-s` | 去除符号表，减小体积 |
| `--oformat binary` | 输出纯二进制，不要 ELF 头 |

```makefile
linux.img: tools/build bootsect setup
	./tools/build bootsect setup
```

- `build` 工具把 `bootsect` 和 `setup` 拼接成 `linux.img`
- bootsect 占 512B，setup 占 2048B，共 2560B（5 扇区）

```makefile
bootsect: bootsect.o
	$(LD) $(LDFLAGS) -o $@ $<

setup: setup.o
	$(LD) $(LDFLAGS) -e _start_setup -o $@ $<
```

- bootsect 用默认入口 `_start`
- setup 显式指定入口 `-e _start_setup`

---

## 🛠️ tools/build.c 详解

这是一个**镜像拼接工具**，作用是把多个纯二进制模块按固定大小拼成一个可引导镜像。

### 核心逻辑

```c
#define BOOTSECT_SIZE 512
#define SETUP_SIZE    2048  /* 4 扇区 */
```

1. **读 bootsect**：确保恰好 512 字节，不足补零
2. **强制引导签名**：`buf[510] = 0x55`，`buf[511] = 0xAA`
3. **读 setup**：确保恰好 2048 字节，不足补零、超出截断
4. **拼接写入**：`bootsect (512B) + setup (2048B) = linux.img (2560B)`

> 💡 为什么需要这个工具？因为 `ld` 只负责生成单个模块的二进制，`dd` 命令虽然也能拼接，但 build.c 可以**精确控制每个模块的长度**，保证磁盘布局符合 bootsect 中的硬编码预期。

---

## 🗺️ 内存布局与时序

```
阶段一：BIOS 加载 bootsect
    0x07C00 ─┬─ bootsect（512B）← BIOS 自动加载
             │
阶段二：bootsect 搬家
    0x07C00 ─┼─ （原位置，将被覆盖）
    0x90000 ─┼─ bootsect 复制到这里 ← rep movsw
             │
阶段三：bootsect 加载 setup
    0x90200 ─┼─ setup（2048B）← int 0x13 从磁盘第2~5扇区读取
             │
阶段四：跳转到 setup
    0x90200 ─┴─ CPU 开始执行 setup
```

---

## 🎯 完整启动流程图

```
CPU 上电
   ↓
BIOS 自检，读取第 0 扇区到 0x7C00
   ↓
检查引导签名 0xAA55 ✅
   ↓
跳转到 0x7C0:0x0000（_start）
   ↓
远跳转到 0x7C0:start2（统一段寄存器）
   ↓
初始化 DS/ES/FS/GS = 0x7C0
   ↓
rep movsw：把自己搬到 0x90000
   ↓
远跳转到 0x9000:go（从新位置执行）
   ↓
初始化 DS/ES/SS = 0x9000，设置栈
   ↓
int 0x13：从磁盘读 setup 到 0x90200
   ↓
打印 "Setup has been loaded"
   ↓
远跳转到 0x9020:0x0000（setup 入口）
   ↓
setup 执行：打印 "setup is running"
   ↓
死循环 🔒
```

---

## 🧠 关键概念回顾

| 概念 | 一句话解释 |
|------|-----------|
| **为什么搬家？** | `0x7C00` 太低，会被后续内核覆盖 |
| **为什么硬编码扇区号？** | 没有文件系统，bootsect 只能按物理扇区读 |
| **为什么 `Ttext 0x0`？** | 代码最终会被搬到 0x0，链接地址必须匹配 |
| **BIOS 中断 vs 内核代码** | BIOS 是主板固件，bootsect 只是"打电话"让它干活 |
| **段地址 × 16** | 实模式下唯一的地址计算公式 |

---

> 📝 **注意**：`playground` 分支是一个活跃的学习分支，每次提交可能内容差异很大，代码从零开始一点点积累。欢迎一起探索操作系统的奥秘！🐧✨
