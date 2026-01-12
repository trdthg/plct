import onnx
from onnx import helper
from onnx import TensorProto

input_info = helper.make_tensor_value_info("X", TensorProto.FLOAT, [None, None])
output_info = helper.make_tensor_value_info("Y", TensorProto.FLOAT, [None, None])

# y = (ax + b) + (ax + b)

# ax
ax = helper.make_node("Mul", ["X", "A"], ["AX"])

# y1 = ax + b
y1 = helper.make_node("Add", ["AX", "B"], ["Y1"])
# y2 = ax + b
y2 = helper.make_node("Add", ["AX", "B"], ["Y2"])

# y = y1 + y2
y = helper.make_node("Add", ["Y1", "Y2"], ["Y"])

weight_a = helper.make_tensor("A", TensorProto.FLOAT, [1], [2.0])
weight_b = helper.make_tensor("B", TensorProto.FLOAT, [1], [1.0])

graph = helper.make_graph(
    [ax, y1, y2, y],
    "ax+b + ax+b",
    [input_info],
    [output_info],
    [weight_a, weight_b],
)

model = helper.make_model(
    graph,
    producer_name="my_human_hand",
    opset_imports=[helper.make_opsetid("", 13)],
    ir_version=11,
)

onnx.checker.check_model(model)
print(f"Model checked successfully! IR Version: {model.ir_version}")

# 序列化为二进制并写入文件
onnx.save(model, "ax_b.onnx")
print("Model saved to ax_b.onnx")
