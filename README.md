# bracket-root

一个小型 MoonBit 一维求根库：二分法、带区间保护的割线法，以及可以审查的终止原因和区间轨迹。用于校准方程、阈值交点等已知连续函数的异号区间；不包含多维优化或符号求解。

[English documentation](README.en.md) · [算法与数值边界](docs/ALGORITHM.md) · [API](docs/API.md)

**评审入口：[MVP 复现与验收说明](docs/MVP-REVIEW.md)**。现有三个完整场景：
平方根教学、[标定反解](docs/CALIBRATION.md)、[冷却阈值](docs/COOLING.md)。
支持可配置命令行、本地交互演示、JSON/CSV 导出和候选区间扫描。

推荐使用 Node.js 18+ 和已有 MoonBit 工具链，从仓库根目录运行：

```sh
node tools/verify.mjs
node tools/run-demo.mjs cooling 50 secant
node tools/serve-demo.mjs
```

最后一条启动 [本地演示](http://127.0.0.1:4317)。无须 npm 依赖或付费服务；
工具链不在 PATH 时设置 `MOON_HOME`，见 [复现环境说明](docs/REPRODUCING.md)。

## 运行

已有 MoonBit 工具链时：

```powershell
moon test --target js --frozen --deny-warn
moon run --target js --frozen cmd/main
```

本工作区的固定工具链和保留构建记录的运行方式：

```powershell
pwsh -NoProfile -File .\tools\test.ps1 -Target js -Demo
```

脚本为每次运行生成新的 `build-runs/时间-随机标识`，保存测试与示例日志，不清理旧构建、不更改用户 PATH。工具来源和版本见 [TOOLCHAIN.md](tools/TOOLCHAIN.md)。发布代码无需携带工具链压缩包、构建目录或恢复目录。

2026-09-21 已使用 MoonBit 编译器 `v0.10.14+7d59c7ec9` 与 `moon 0.1.20260920` 在 Windows/JavaScript 后端通过 **33 项 MoonBit 测试**，其中一项覆盖两种算法的 **1000 个确定性缩放问题**；另有 **16 组 JavaScript/CLI 集成检查**。警告按错误处理。其他后端尚未验证。

## 使用

导入根包为 `@root` 后：

```moonbit
let result = @root.bisect(
  x => x * x - 2.0,
  1.0,
  2.0,
  @root.Options::default(),
)
match result {
  Ok(solution) => println(solution.root)
  Err(error) => println(error.message())
}
```

模块暂用本地名称 `local/bracket_root`，没有发布到包仓库。完整可运行的导入配置与示例在 `cmd/main`。

## 返回什么

`Result[Solution, RootError]` 把输入错误与正常停止分开。`Solution` 包含已求值的根估计、对应函数值、最终区间、迭代数、实际回调次数、终止原因，以及初始化和每次更新后的区间轨迹。

| 原因 | `converged()` | 含义 |
|---|---|---|
| `ExactZero` | true | 回调在一个已求值点返回浮点零；不等于数学表达式精确为零。 |
| `IntervalTolerance` | true | 整个最终区间宽度不超过 `atol + rtol * abs(root)`。 |
| `FloatingPointLimit` | false | 区间内无法构造新的浮点中点，且容差未满足。 |
| `IterationLimit` | false | 迭代预算已用尽，且未满足收敛条件。 |

函数必须连续、确定，并在被访问点返回有限值。程序不能证明连续性：一个跳跃也可能使区间变窄，因此区间收敛本身不证明残差小或存在数学根。不会因为函数值很小就提前成功。

## 数值约定

- 输入端点必须有限且严格递增，重复或倒序端点直接报错。
- 默认 `atol=1e-12`、`rtol=1e-12`、最多 128 次内部迭代；支持零次预算。
- `atol >= 0`、`0 <= rtol < 1`，至少一个正；参数必须有限。预算是 0 至 1,000,000 的整数。
- 两个端点均求值后才接受端点零。成功结果的求值次数为 `iterations + 2`。
- 保留异号依靠符号比较，不计算端点函数值乘积；中点和割线权重单独处理极大与极小数值。
- 保护割线只接受区间中央一半中的候选，其余情况使用二分。它不是 Brent 法，也不保证比二分更快。
- 返回点是函数残差较小的已评估端点。因此位置误差界用**整个区间宽度**，没有误用半宽。
- 默认保存完整轨迹需要 O(迭代数) 空间；传入 `record_trace=false` 使用常量求解器存储。非有限回调值返回错误，不伪造成功结果。
- `scan_brackets` 可对有限区间均匀采样并返回异号子区间与采样零点；它可能漏掉切触根或采样间的多个根，不保证发现全部根。

## 测试覆盖

解析根与嵌套异号区间、端点零和负零、乘积下溢、跨正负极大端点、同号极大端点、割线分母溢出、无效输入、非有限回调、零/一次预算、相邻浮点停滞、端点误差界反例、保护步长、尺度变化和实际调用计数均有回归测试。另有不连续函数案例，专门说明 API 前提的边界。

实现与测试由 AI 协助开发，并经过独立数值反例审查。结果仍需使用者结合具体模型检查；当前成果是本地开发版本，活动申请、评审和付款均不属于测试结论。

## 许可

原创项目源码使用 [MIT](LICENSE)。MoonBit 编译器与标准库各自的上游许可不由本项目 MIT 许可替代，详见工具来源说明。
