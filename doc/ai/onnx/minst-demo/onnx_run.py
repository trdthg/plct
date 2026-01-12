import sys
import numpy as np
import onnxruntime
from PIL import Image
from torchvision import transforms


def predict_onnx(image_path):
    # 1. 创建推理会话 (Inference Session)
    # 相当于 torch.load + network.eval()
    session = onnxruntime.InferenceSession("./model.onnx")

    # 2. 获取输入节点的名称 (通常是 "input" 或 "input.1")
    input_name = session.get_inputs()[0].name

    # 3. 图像预处理 (保持与 PyTorch 逻辑一致)
    transform = transforms.Compose(
        [
            transforms.Grayscale(num_output_channels=1),
            transforms.Resize((28, 28)),
            transforms.ToTensor(),
            transforms.Normalize((0.1307,), (0.3081,)),
        ]
    )

    try:
        img = Image.open(image_path)
        img_tensor = transform(img).unsqueeze(0)

        # --- 关键区别点 ---
        # ONNX Runtime 接收的是 NumPy 数组，而不是 torch.Tensor
        img_numpy = img_tensor.detach().cpu().numpy()

        # 4. 执行推理
        # run 的第一个参数是输出节点名（None 表示获取所有输出），第二个是输入字典
        outputs = session.run(None, {input_name: img_numpy})

        # 5. 后处理
        # outputs 是一个列表，每个元素是一个 NumPy 数组
        output_tensor = outputs[0]
        prediction = np.argmax(output_tensor, axis=1)

        print(f"图片路径：{image_path}")
        print(f"ONNX 预测结果 (数字): {prediction[0]}")

    except Exception as e:
        print(f"出错啦：{e}")


if __name__ == "__main__":
    # 假设你导出的文件名是 model.onnx
    predict_onnx(sys.argv[1])
