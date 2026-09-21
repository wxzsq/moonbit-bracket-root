# 本地工具链记录

取得日期：2026-09-21。全部工具、下载、构建和临时目录留在本项目内；没有修改用户 PATH，没有执行官方安装脚本中的删除操作。安装器仅保存作来源参考。

- Build tool: `moon 0.1.20260920 (914d7da 2026-09-20)`。
- Compiler: `v0.10.14+7d59c7ec9 (2026-09-18)`。
- 标准库：`moonbitlang/core 0.10.14+7d59c7ec9`。
- 已验证后端：JavaScript，系统 Node.js `v16.20.2`。
- 项目工具目录：`tools/moon-20260921`。
- 原始压缩包：`tools/downloads`，保留未删除。

官方来源：

- [下载及 SHA256 核验文档](https://www.moonbitlang.com/download/)
- [Windows 安装脚本](https://cli.moonbitlang.com/install/powershell.ps1)，只读检查取得二进制与核心库地址。
- [Windows 二进制压缩包](https://cli.moonbitlang.com/binaries/latest/moonbit-windows-x86_64.zip)
- [官方压缩包 SHA256](https://cli.moonbitlang.com/binaries/latest/moonbit-windows-x86_64.zip.sha256)
- [标准库压缩包](https://cli.moonbitlang.com/cores/core-latest.zip)

本轮编译器压缩包 SHA256 与官方公布值一致：

```text
faae225a8287d0ce69e44b5b3f754af988e97f4446056d8f32ceb3ddb998fce7
```

标准库压缩包本地 SHA256（仅记录本次内容，不声称是官方独立签名）：

```text
63e5b99991ac8fd49556b1e17bdbcbdc662d797000250dd11ef090f38a2175e84
```

链接中的 `latest` 会变化；本项目已保留下载件和具体版本。重现时优先使用保存的工具目录，勿将以后版本的运行结果混作本轮验证。

`tools/fetch-toolchain.mjs` 是兼容 Node 16 的 HTTPS 下载辅助程序，文件采用 `wx` 创建，拒绝覆盖已有下载。官方脚本先经 Windows TLS 读取失败，随后使用 Node HTTPS 成功获取；没有跳过 TLS 校验。

标准库构建命令在 `tools/moon-20260921/lib/core` 执行，事先令 `MOON_HOME` 指向项目工具目录、`TEMP`/`TMP` 指向项目临时目录：

```text
moon bundle --target js --warn-list -a
```

正式测试使用 `tools/test.ps1`，每次新建独立目录并还原进程环境。没有调用 `moon clean`、删除或清空旧目录。`.recovery` 保留曾修改的源码/配置，构建运行日志位于 `build-runs`。

编译器和标准库保留上游各自许可。项目原创实现采用 MIT；不把本项目许可证应用到上游工具。发布源码时 `.gitignore` 与 `.moonignore` 排除工具链、下载和恢复/构建目录，避免把工具二进制当作项目交付源码。
