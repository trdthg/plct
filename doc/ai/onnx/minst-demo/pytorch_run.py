import sys
import torch
import torch.nn as nn
import torch.nn.functional as F
from PIL import Image
from torchvision import transforms


# 1. 必须定义完全相同的模型结构
class Net(nn.Module):
    def __init__(self):
        super(Net, self).__init__()
        self.conv1 = nn.Conv2d(1, 10, kernel_size=5)
        self.conv2 = nn.Conv2d(10, 20, kernel_size=5)
        self.conv2_drop = nn.Dropout2d()
        self.fc1 = nn.Linear(320, 50)
        self.fc2 = nn.Linear(50, 10)

    def forward(self, x):
        x = F.relu(F.max_pool2d(self.conv1(x), 2))
        x = F.relu(F.max_pool2d(self.conv2_drop(self.conv2(x)), 2))
        x = x.view(-1, 320)
        x = F.relu(self.fc1(x))
        x = F.dropout(x, training=self.training)
        x = self.fc2(x)
        return F.log_softmax(x, dim=1)


def predict(image_path):
    # 2. 实例化模型并加载参数
    network = Net()
    network.load_state_dict(torch.load("./model.pth", map_location=torch.device("cpu")))
    network.eval()  # 切换到预测模式

    # 3. 图像预处理 (必须与训练时的 transforms 一致)
    # MNIST 是黑底白字，28x28，单通道
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
        # 转换维度 [1, 1, 28, 28]
        img_tensor = transform(img).unsqueeze(0)  # type: ignore

        # 执行推理
        with torch.no_grad():
            output = network(img_tensor)
            # 获取概率最大的索引
            prediction = output.data.max(1, keepdim=True)[1]

        print(f"图片路径：{image_path}")
        print(f"模型预测结果 (数字): {prediction.item()}")

    except Exception as e:
        print(f"出错啦：{e}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法：python predict.py <图片路径>")
    else:
        predict(sys.argv[1])
