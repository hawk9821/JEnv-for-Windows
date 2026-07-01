# JEnv for Windows v2
### Java 版本管理工具

通过简单的命令切换 Windows 上的 Java 版本

 - JEnv 可以帮助你快速切换当前的 JDK 版本
 - 这对于测试或项目需要不同 Java 版本时非常有用
 - 例如你可以构建一个需要 Java 8 的 Gradle 项目，然后切换回 Java 17 继续其他工作
 - 使用 cmd 和 PowerShell 编写，支持 Windows 10 及以上版本

如果觉得好用，请给个 Star！谢谢！

# 演示视频：
![jenv](https://user-images.githubusercontent.com/55546882/162501231-b2e030bf-1194-4a1d-8565-ccd503b63402.svg)

## 安装
1) **克隆本仓库**
2) **添加到系统 PATH**
3) **运行一次 `jenv` 让脚本完成初始化**
4) **CMD 用户调用 batch 文件，PowerShell 用户调用 src/jenv.ps1**
5) **注意：放在 C:/Programs 文件夹可能需要管理员权限**
6) **遇到问题请提 Issue**

## 注意：
有时进入一个设置了 local jenv 的目录后需要手动执行一次 jenv 命令来设置 JAVA_HOME，这样才能确保 Maven 等工具正常工作

## 性能优化
JEnv 使用路径缓存机制，避免每次执行 `java` 命令时启动 PowerShell 的开销：
- 首次 `java` 调用：约 1-2 秒（调用 PowerShell 解析路径并缓存）
- 后续 `java` 调用：约 300 毫秒（直接读取缓存）
- 如果设置了 `JENVUSE` 环境变量，`java` 直接使用该值，无需缓存查找

强制刷新缓存：在修改 `jenv local` 后再次执行 `jenv local <name>` 或调用 `jenv getjava`。如需从配置历史重建缓存，使用 `jenv getjava --sync-cache`。

## 使用说明（优先级：local > change > global > use）
1) **添加新的 Java 环境（需要绝对路径）**
*jenv add `<名称> <路径>`*
示例：`jenv add jdk15 "D:\Programme\Java\jdk-15.0.1"`

2) **为当前会话切换 Java 版本**
*jenv use `<名称>`*
示例：`jenv use jdk15`
脚本中设置环境变量：
---PowerShell: `$ENV:JENVUSE="jdk17"`
---CMD/BATCH: `set "JENVUSE=jdk17"`

3) **清除当前会话的 Java 版本**
*jenv use remove*
示例：`jenv use remove`
---PowerShell: `$ENV:JENVUSE=$null`
---CMD/BATCH: `set "JENVUSE="`

4) **全局切换 Java 版本**
*jenv change `<名称>`*
示例：`jenv change jdk15`

5) **为当前目录设置永久使用的 Java 版本**
*jenv local `<名称>`*
示例：`jenv local jdk15`

6) **清除当前目录的 Java 版本设置**
*jenv local remove*
示例：`jenv local remove`

7) **列出所有已注册的 Java 环境**
*jenv list*
示例：`jenv list`

8) **从 JEnv 列表中移除某个 JDK**
*jenv remove `<名称>`*
示例：`jenv remove jdk15`

9) **创建链接以直接调用 java 目录下的可执行文件**
*jenv link `<可执行文件名>`*
示例：`jenv link javac`
在 JEnv 根目录创建 batch 文件（如 javac.bat），之后可直接调用 `javac`

10) **卸载 JEnv 并自动恢复一个 Java 版本**
*jenv uninstall `<名称>`*
示例：`jenv uninstall jdk17`

11) **自动扫描并添加 Java 版本**
*jenv autoscan [--yes|-y] [路径]*
示例：`jenv autoscan "C:\Program Files\Java"`
示例：`jenv autoscan` // 搜索整个系统
示例：`jenv autoscan -y "C:\Program Files\Java"` // 自动接受默认选项
注意：自动扫描使用 JDK 版本号作为名称（如 "8"、"11"、"17"），不是 "jdk8"、"jdk11" 等

12) **获取解析后的 Java 路径（用于脚本或调试）**
*jenv getjava [--sync-cache | -s]*
示例：`jenv getjava`
示例：`jenv getjava --sync-cache`
返回将使用的 Java 路径，优先级：JENVUSE > local > parent local > global

**--sync-cache / -s**：当缓存文件不存在时，从配置历史（locals + global）重建缓存。在重新安装 JEnv 或缓存文件被删除后很有用。

## Maven / Maven Daemon 集成

JEnv 提供 `mvn.bat` 和 `mvnd.bat` 包装脚本，在调用 Maven 前自动设置 `JAVA_HOME`：

- **MAVEN_HOME**（必须）：设置为你的 Maven 安装目录
- **MVND_HOME**（必须）：设置为你的 Maven Daemon 安装目录

与 Java 版本管理不同，Maven/Mvnd 安装不由 JEnv 管理。你需要单独安装它们并配置环境变量。

如果环境变量未设置，batch 文件将显示错误信息并退出。

## 工作原理
JEnv 创建一个 java.bat 文件来拦截 java 命令并调用正确版本的 java.exe
当 PowerShell 脚本修改环境变量时，会导出到临时文件，batch 文件读取这些临时文件来应用环境变量变化
使用 "--output"（别名 "-o"）参数可以让 PowerShell 脚本生成临时文件

### Java 路径解析流程
1. `java` 命令调用 `java.bat`
2. `java.bat` 首先检查 `JENVUSE` 环境变量（会话级覆盖）
3. 回退到读取 `jenv.java.cache` 文件（即时，无 PowerShell 开销）
4. 如果没有缓存，调用 `jenv getjava` 通过 PowerShell 解析并缓存路径
5. 子目录继承：`jenv getjava` 遍历父目录查找 `jenv local` 设置
6. 使用 `jenv getjava --sync-cache` 可在缓存文件缺失时从配置历史重建缓存

![SystemEnvironmentVariablesHirachyShell](https://user-images.githubusercontent.com/55546882/130204196-1a800310-4454-49bd-8d80-161b0e7cca3f.PNG)

![SystemEnvironmentVariablesHirachyPowerShell PNG](https://user-images.githubusercontent.com/55546882/130204185-b54368cc-34db-40d1-a707-4c5477ca236b.PNG)

## 贡献代码
欢迎贡献代码！代码量不大，很容易理解，适合初学者。
运行测试需要使用最新版本的 PowerShell (pwsh.exe)：
https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.2
注意：要用 pwsh 而不是 powershell
还需要安装 Pester：`Install-Module -Name Pester -Force -SkipPublisherCheck`
（Windows 自带的 PowerShell 5.1 内置的 Pester 版本太旧，无法使用）
进入 test 文件夹运行 `test.ps1`。测试会自动备份和恢复你的环境变量和 JEnv 配置，**但测试必须完整运行完毕才能正确恢复**，如果中断将无法恢复。
