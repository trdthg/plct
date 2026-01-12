import torch
import json

# 加载模型
state_dict = torch.load("model.pth", map_location="cpu")

# 将张量转换为列表（以便 JSON 序列化）
readable_dict = {}
for k, v in state_dict.items():
    # 只取前 5 个值作为示例，避免文件过大
    readable_dict[k] = {
        "shape": list(v.shape),
        "values_preview": v.flatten()[:5].tolist(),
    }

# 保存为 JSON
with open("model_structure.json", "w") as f:
    json.dump(readable_dict, f, indent=4)
