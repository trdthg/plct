# vscode dart 交叉编译调研

本文内容均在 XXX, dart 版本 xxx

## 安装

插件名称：dart-code.dart-code

![Alt text](image.png)

## 工程管理

## 如何使用插件

## riscv

## 编译

dart 编译器本身不支持交叉编译

- issue: <https://github.com/dart-lang/sdk/issues/28617>
- [虚拟机] codemagic: <https://blog.codemagic.io/cross-compiling-dart-cli-applications-with-codemagic/>
- [修改源代码] hack dart2native: <https://medium.com/flutter-community/cross-compiling-dart-apps-f88e69824639>
- [虚拟机] gihub action matrix

```bash
 dart2native foo.dart \
    --gen-snapshot out/ProductSIMARM/dart-sdk/bin/utils/gen_snapshot \
    --aot-runtime out/ProductXARM/dart-sdk/bin/dartaotruntime
```

## 运行

## 调试
