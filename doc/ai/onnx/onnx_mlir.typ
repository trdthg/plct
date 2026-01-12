#import "@preview/grayness:0.1.0": grayscale-image
#import "@preview/touying:0.6.0": *
#import themes.metropolis: *
#import "@preview/chronos:0.2.1"

#import "@preview/numbly:0.1.0": numbly

#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  footer: self => self.info.institution,
  config-info(
    title: [手搓 ONNX 模型],
    subtitle: [ONNX 格式分析及生成 ONNX 模型],
    author: [Mingzhu Yan],
    date: datetime.today(),
    institution: [ISRC],
  ),
)

#set heading(numbering: numbly("{1}.", default: "1.1"))

#title-slide()

= Outline <touying:hidden>

#outline(title: none, indent: 1em, depth: 1)

= 介绍

ONNX 是一个通用的模型格式

== 看看 onnx-mlir 对 Abs 算子的声明

https://github.com/onnx/onnx-mlir/blob/main/src/Dialect/ONNX/ONNXOps.td.inc#L7

== ONNX 下降到 LLVM

- 可能需要先经过中间 IR
  - Abs: ONNX -> LLVM
  - Softmax: ONNX -> Krnl (Kernel Dialect) -> LLVM
- 在下降过程中要考虑各种优化
  - 是否标量
  - 尝试SIMD
  - 尝试指令融合
  - 最后才是常规路径

== 先看看 Abs 算子是如何下降到 LLVM IR

src/Conversion/ONNXToKrnl/Math/Elementwise.cpp

包含了各种 Lowering

Abs 在这里

逐元素

```cpp
struct ONNXElementwiseUnaryOpLowering
    : public OpConversionPattern<ElementwiseUnaryOp> {
```

所有 Lowering 都继承自 OpConversionPattern, 要求实现构造函数和 matchAndRewrite


```cpp
auto loweredOpResult = emitScalarOpFor<ElementwiseUnaryOp>(
    rewriter, loc, op, outputElementType, args);
```

看一下有哪些

```
rg emitScalarOpFor

relu/min/max/unary/binary
```

Abs 对应的是这个

```
template <typename Op>
mlir::Value emitScalarOpFor(mlir::ConversionPatternRewriter &rewriter,
    mlir::Location loc, mlir::Operation *op, mlir::Type elementType,
    llvm::ArrayRef<mlir::Value> scalarOperands) {
      ...
      return ScalarIOp<Op>::create(rewriter, loc, elementType, scalarsSplatted);
}
```

直接映射到了 mlir 内置的 Abs Op

src/Conversion/ONNXToKrnl/Math/Elementwise.hpp:170
```
template <>
struct ScalarOp<mlir::ONNXAbsOp> {
  using FOp = mlir::math::AbsFOp;
  using IOp = mlir::math::AbsIOp;
};
```

== 看看 Softmax

src/Conversion/ONNXToKrnl/Math/Softmax.cpp
```cpp
template <typename SoftmaxOp>
struct ONNXSoftmaxLowering : public OpConversionPattern<SoftmaxOp> {

     emitInstForSoftmax<SoftmaxOp>(rewriter, op, loc, alloc, input, zero,
        negInfinity, axis, enableParallelLocal);
}

        Value nextMax = create.krnl.load(input, maxLoopIVs);
```

```
Value KrnlBuilder::load(
    Value memref, ValueRange indices, ValueRange offsets) const {
  return onnx_mlir::impl::load<KrnlBuilder, KrnlLoadOp>(
      *this, memref, indices, offsets);
}

```
              KrnlLoadOpLowering
KrnlLoadOp -----------------------> LLVM IR

/// KrnlLoad will be lowered to std.load or affine.load, depending on whether
/// the access indices are all affine maps or not.
class KrnlLoadLowering : public ConversionPattern {
public:
  explicit KrnlLoadLowering(TypeConverter &typeConverter, MLIRContext *context)
      : ConversionPattern(
            typeConverter, KrnlLoadOp::getOperationName(), 1, context) {}

  LogicalResult matchAndRewrite(Operation *op, ArrayRef<Value> operands,
      ConversionPatternRewriter &rewriter) const override {
    auto loadOp = mlir::cast<KrnlLoadOp>(op);
    KrnlLoadOpAdaptor operandAdaptor(loadOp);

    // Prepare inputs.
    Value memref = operandAdaptor.getMemref();
    SmallVector<Value, 4> indices = operandAdaptor.getIndices();

    // Check whether all indices are affine maps or not.
    bool affineIndices =
        !llvm::any_of(indices, [](Value v) { return !affine::isValidDim(v); });

    if (affineIndices)
      rewriter.replaceOpWithNewOp<affine::AffineLoadOp>(op, memref, indices);
    else
      rewriter.replaceOpWithNewOp<memref::LoadOp>(op, memref, indices);

    return success();
  }
};
```

== 指令融合

```diff
+// Try to fuse the unary elementwise consumers
+OpFusionHelper opFusionHelper(rewriter, op, dimAnalysis);
+opFusionHelper.findFusibleOps();
+outputMemRefType = opFusionHelper.getOutputType(outputMemRefType);

 auto loweredOpResult = emitScalarOpFor<ElementwiseUnaryOp>(
    rewriter, loc, op, outputElementType, args);
+loweredOpResult = opFusionHelper.emitFuseOps(loweredOpResult, alloc);
+// Store result in the resulting array.
+create.krnl.store(loweredOpResult, alloc);

// Emit fusion Ops
Value OpFusionHelper::emitFuseOps(
    Value defOpResult, const Value alloc, ValueRange loopInd) {
  if (isFusibleListEmpty())
    return defOpResult;

  Operation *defOp = rootOp;

  for (size_t i = 0; i < fusibleOps.size(); i++) {
    Operation *useOp = fusibleOps[i];

    for (size_t i = 0; i < useOp->getOperands().size(); i++) {
      // 后续算子的输入 是 Abs
      if (inputOp == defOp) {
        inputValues.emplace_back(defOpResult);
      } else {
        IndexExprScope innerScope(create.krnl, shapeHelper.getScope());
        SmallVector<IndexExpr, 4> outputAccessExprs;
        getIndexExprList<DimIndexExpr>(loopInd, outputAccessExprs);
        SmallVector<IndexExpr, 4> loadAccessExprs;
        LogicalResult res = shapeHelper.getAccessExprs(
            inputValue, i, outputAccessExprs, loadAccessExprs, true);
        assert(succeeded(res) && "Could not compute access indices");
        Value load = create.krnl.loadIE(useOperands[i], loadAccessExprs);
        inputValues.emplace_back(load);
      }
    }
    defOpResult = fuseEmitFuctions[i](rewriter, loc, useOp, currentElementType, inputValues);
    defOp = useOp;
  }
  return defOpResult;
}

```

= 展望

#pagebreak()

