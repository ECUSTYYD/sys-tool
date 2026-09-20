# Sys-Tool · 上课 PPT 静默抓取工具

> 上课总有老师不喜欢让同学把 PPT 拷走，上完课还会把 PPT 拖入垃圾桶，我们就找不到了。运行这个一键安装文件，让你在电脑上面检测老师拖出来的 PPT，下课点击 OPEN 打开抓取的文件，直接拷贝走！可以课前运行，或者按操作设计开机自启动。

---

## ✨ 功能特点

- **静默运行**：后台进程无窗口，老师完全无感
- **自动监视**：实时监听桌面、下载、文档、微信文件夹及所有 U 盘的 PPT/PDF 文件
- **断点续拷**：PPT 被 Office 占用也能复制，文件大小稳定后自动归档
- **按日期归档**：文件按 `yyyy-MM-dd` 分类存放，一目了然
- **U 盘即用即走**：插入 U 盘 → 双击一键启动 → 拔出 U 盘即可，脚本自动复制到 D 盘运行
- **还原卡兼容**：归档目录强制写入 D 盘（开放盘），重启不丢失

## 📁 文件说明

| 文件 | 用途 |
|---|---|
| `一键启动.bat` | **主入口**，U 盘插上双击即可，自动复制到 D 盘后静默运行 |
| `ppt-archiver.ps1` | 主程序，PowerShell 编写，监视 + 归档 PPT/PDF |
| `start.vbs` | 静默启动器（隐藏 PowerShell 窗口） |
| `open.bat` | 一键打开归档目录（下课取 PPT 用这个） |
| `detect.bat` | 机房环境检测（识别还原卡品牌和驱动） |
| `test-c-persistence.bat` | 测试 C 盘哪些位置重启后存活（判断能否无密码自启动） |
| `install-autostart.bat` | 无密码自启动安装器（测试通过后用） |

## 🚀 快速开始（U 盘方案 · 无需密码）

> 适合**不能解冻 C 盘**、**没有还原卡密码**的机房电脑

### 第 1 步：拷贝到 U 盘

把整个 `SysTool` 文件夹复制到 U 盘根目录：

```
U:\
  └─ SysTool\
       ├─ 一键启动.bat
       ├─ ppt-archiver.ps1
       ├─ start.vbs
       ├─ open.bat
       ├─ detect.bat
       ├─ test-c-persistence.bat
       └─ install-autostart.bat
```

### 第 2 步：在机房电脑上运行

1. 插入 U 盘
2. 打开 `SysTool` 文件夹
3. **右键 `一键启动.bat` → 以管理员身份运行**
4. 看到 `YOU CAN UNPLUG THE USB NOW` 提示后，**拔出 U 盘即可**

### 第 3 步：下课取 PPT

双击 `open.bat`（在 D:\SysTool 里），打开归档目录，按日期找到当天所有 PPT，直接拷贝走。

---

## 🔧 进阶：开机自启动方案

### 方案 A：还原卡开放启动文件夹（无密码）

1. 右键 `test-c-persistence.bat` → 以管理员身份运行
2. **重启电脑**
3. 重启后再跑一次同一个脚本
4. 如果 `Startup folder` 显示 `[SURVIVED]`，说明启动文件夹不被保护
5. 右键 `install-autostart.bat` → 以管理员身份运行
6. 重启验证——开机后任务管理器应自动出现 `wscript.exe`

### 方案 B：标准方案（需要还原卡密码）

> 最稳定，一次配置永久生效，适合能拿到还原卡密码的场景

1. 按还原卡品牌对应的快捷键（通常是开机按 **F10**）进 BIOS
2. 选 `Boot Thawed`（解冻启动）→ 重启
3. 运行 `install.bat`（解冻后注册计划任务）
4. 再次进 BIOS → 选 `Boot Frozen`（冻结启动）→ 重启
5. 完成，之后每次开机自动启动

**常见还原卡默认密码**：

| 品牌 | 进入键 | 密码 |
|---|---|---|
| 小哨兵 | F10 | `manager` → `12345678` |
| 海光 | F10 | `manager` → `88888888` |
| 远志 | F10 | `00000000` → `88888888` |
| 联想硬盘保护 | F4/F10 | `00000000` → `lenovo` |
| 冰点还原 | Ctrl+Shift+双击图标 | 空 → `12345678` |

不知道品牌？先跑 `detect.bat` 自动识别。

---

## 📂 归档目录结构

```
D:\AppCacheData\              ← 隐藏目录，老师看不到
  ├─ .marker                  ← 定位标记文件
  ├─ log.txt                  ← 运行日志
  ├─ 2026-09-20\              ← 按日期分类
  │   ├─ 高等数学课件.pptx
  │   ├─ 大学物理.pdf
  │   └─ 数据结构_第3章.pptx
  └─ 2026-09-21\
      └─ ...
```

## 🎯 监视范围

脚本会自动监视以下位置的 PPT/PDF 文件：

- 桌面 (`%USERPROFILE%\Desktop`)
- 下载文件夹 (`%USERPROFILE%\Downloads`)
- 文档文件夹 (`%USERPROFILE%\Documents`)
- 微信文件目录 (`%USERPROFILE%\xwechat_files`)
- WPS Office 临时目录
- **所有插入的 U 盘**（自动识别热插拔）

支持扩展名：`.ppt` `.pptx` `.pps` `.ppsx` `.pdf`

## 💡 工作原理

```
老师把 PPT 从 U 盘拷到桌面
       ↓
FileSystemWatcher 检测到新文件
       ↓
等待文件大小稳定（避免复制到一半）
       ↓
以 ReadWrite 共享模式打开（不影响老师打开 PPT）
       ↓
静默复制到 D:\AppCacheData\yyyy-MM-dd\
       ↓
open.bat 一键打开归档目录
```

## ⚠️ 注意事项

1. **D 盘必须是开放盘**：归档目录在 D 盘，确保 D 盘不被还原卡保护。第一次使用前可以先把一个文件放 D 盘，重启后看是否还在
2. **U 盘方案每次开机要重新运行**：因为 C 盘被还原，脚本不会自动启动。一键启动后拔 U 盘不影响当前会话
3. **不要删除 D:\SysTool 文件夹**：脚本运行依赖它
4. **多台机房电脑需要分别配置**：每台机器都要插 U 盘跑一次一键启动

## 🛠️ 技术栈

- **PowerShell**：主程序 + 文件监视器 + 归档逻辑
- **VBScript**：静默启动器（隐藏 PowerShell 窗口）
- **Batch**：安装/检测/辅助脚本
- **Windows 文件系统监视器**：`FileSystemWatcher` + `CimIndicationEvent`（U盘热插拔）

## 📜 License

MIT License
