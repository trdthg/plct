import onnx
from onnx import helper
from onnx import TensorProto

input_tensor_info = helper.make_tensor_value_info(
    name="X", elem_type=TensorProto.FLOAT, shape=[1, 4]
)

output_tensor_info = helper.make_tensor_value_info(
    name="Y", elem_type=TensorProto.FLOAT, shape=[1, 4]
)

node_def = helper.make_node(
    op_type="Softmax", inputs=["X"], outputs=["Y"], name="node_softmax_1"
)

graph_def = helper.make_graph(
    name="test_softmax_graph",
    inputs=[input_tensor_info],
    outputs=[output_tensor_info],
    nodes=[node_def],
    initializer=[],
)

model_def = helper.make_model(
    graph_def,
    producer_name="my_human_hand",
    opset_imports=[helper.make_opsetid(domain="", version=11)],
    ir_version=11,
)

onnx.save(model_def, "softmax.onnx")

print("Model saved to softmax.onnx")
