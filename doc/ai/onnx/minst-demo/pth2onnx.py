import torch
import torch.nn as nn
import torch.nn.functional as F


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


network = Net()
network.load_state_dict(torch.load("./model.pth", map_location=torch.device("cpu")))
network.eval()

# 2. 创建一个“伪输入” (Dummy Input)
# ONNX 导出需要通过一次“干跑”来追踪计算图
dummy_input = torch.randn(1, 1, 28, 28)

# 3. 导出模型
torch.onnx.export(
    network,  # 要导出的模型
    dummy_input,  # 伪输入 # type: ignore
    "model.onnx",  # 导出文件名
    do_constant_folding=False,  # 是否执行常量折叠优化
    input_names=["input"],  # 输入节点名称
    output_names=["output"],  # 输出节点名称
)

