# 验证记录｜2026-09-21

## 实际运行

Windows，Node.js v16.20.2，MoonBit compiler v0.10.14+7d59c7ec9，moon 0.1.20260920。

```powershell
pwsh -NoProfile -File .\tools\test.ps1 -Target js -Demo
```

结果：`Total tests: 19, passed: 19, failed: 0.` 使用 `--deny-warn`，无编译警告。保留日志：`build-runs/20260921-001900-322-a2f2615c/test.log` 与 `demo.log`。测试产物不进入源码包。

示例输出：

```text
root=1.4142135623733338, f(root)=6.754596881819452e-13, reason=interval_tolerance
iterations=39, evaluations=41, converged=true
root=1.4142135623730951, f(root)=4.440892098500626e-16, reason=interval_tolerance
iterations=40, evaluations=42, converged=true
```

这不是性能排名。默认容差下，保护割线在这个例子中用了更多迭代。

## 独立审查

独立审查者读取实际保留的编译 JavaScript 产物并调用，不重写求根算法；16 个结果通过基于 Fraction 的精确位置与误差界核验，104 项调用范围、预算及返回残差来源断言通过。独立证据保存在工作区 `research/bracket-root-review/FINAL-REVIEW-20260921.md`，没有把它当作本项目自身测试套件的一部分。

本实现与测试文件的 SHA256：

```text
bracket_root.mbt
07c168b0047b657ccec92a425701439ffdbd6fc67d1321e69276b1dbfa1e4cbf

bracket_root_wbtest.mbt
5f6cfae64d0d32f1160a6c5fce80b1650ee9ba78e5871728841c4e2b661a7b3f
```

## 包检查与范围

`moon package --list --frozen` 触发本地检查及源码归档，未访问发布账户、未上传。首次运行因默认检查未安装的 wasm 标准库失败；随后配置 `preferred_target="js"`、`supported_targets="js"`，与实际验证范围一致，再运行检查通过。检查只提示尚无公开仓库 URL，因此 `repository` 元数据留空；没有伪造仓库。

当前 `.moonignore` 排除工具链、下载压缩包、旧构建、临时与恢复目录。保存的源码归档位于 `build-runs/package-list-js/publish`，后续文档更新不应与这份较早归档混淆；如需最终提交，重新打包并校验文件清单。

尚未完成的外部事项：公开仓库、持续公开提交记录、活动入群/申报、选题审批、收款核实与主办方验收。这些事项不属于本地测试通过的含义。
