import onnxruntime as ort
import numpy as np

# 1. 创建推理会话 (Session)
# 这一步会解析 ModelProto，编译图，并分配内存
session = ort.InferenceSession("ax_b.onnx")

# 2. 准备数据
# 注意类型必须匹配 (Float32)
x_input = np.array([[1.0, 2.0, 3.0, 4.0]], dtype=np.float32)

# 3. 运行推理
# run(output_names, input_feed)
outputs = session.run(["Y"], {"X": x_input})

print("\n--- Inference Result ---")
print(f"Input: {x_input}")
print(f"Output (2x+1)+(2x+1): {outputs[0]}")

# 简单的数值验证
# softmax([1, 2, 3, 4]) 应该倾向于最后一个元素
# exp(4) / sum(exp(1)..exp(4))
expected = x_input * 2 + 1
print(f"Manual Verification: {np.allclose(outputs[0], expected)}")
