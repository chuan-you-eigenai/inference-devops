# sglang-model Helm Chart

通用 Helm Chart，用于部署基于 sglang 的推理服务，可选启用 Dragonfly initContainer 预热 HuggingFace 缓存。每个模型有独立 values 文件，使用多个 release 实现「一次一个模型」。

## 仓库结构

```
charts/
  sglang-model/
    Chart.yaml
    values.yaml
    templates/
      deployment.yaml
      service.yaml
      keda-scaledobject.yaml
values/
  qwen3-8b-vl.yaml
  qwen3-32b-vl.yaml
Jenkinsfile
```

## 使用步骤

1. 预创建 HF Token Secret：
   ```bash
   kubectl -n default create secret generic hf-token --from-literal=token='YOUR_HF_TOKEN'
   ```
2. 部署 Qwen3-8B-VL：
   ```bash
   helm upgrade --install qwen3-8b-vl charts/sglang-model -n default -f values/qwen3-8b-vl.yaml
   ```
3. 部署 Qwen3-32B-VL（带 Dragonfly init 容器）：
   ```bash
   helm upgrade --install qwen3-32b-vl charts/sglang-model -n default -f values/qwen3-32b-vl.yaml
   ```
4. 新增模型时，只需在 `values/` 目录复制一份配置并覆盖 `container.port/command/args`、`service`、`cacheVolume` 等字段，然后使用新的 release 名称执行 `helm upgrade --install`。

## Chart 说明

- `charts/sglang-model/values.yaml` 提供通用默认值，覆盖镜像、资源、服务类型、HF/Dragonfly 参数和缓存路径。
- Dragonfly initContainer 始终启用，镜像固定为 `eigenai/dragonfly-hf-snapshot-loader`, 仅通过 `dragonfly.tag` 覆盖版本（默认 `v0.0.1`）。
- HF Token 统一通过 Secret 注入 `HUGGING_FACE_HUB_TOKEN` 与 `HF_TOKEN`。
- `container.port` 必须在每个模型的 values 文件中设置，Service 未指定 `port` 时会复用该值。
- `cacheVolume` 默认绑定宿主机缓存路径 `/model-local` 和 64Gi `/dev/shm`。
- `keda.enabled` 打开后会渲染 `ScaledObject`，默认指向当前 Deployment；若需要副本上下限或 HPA 行为，直接在 `keda` 下显式填写（未填写则走 KEDA 默认值），通常只需提供触发器即可。

## Jenkins / KubeSphere DevOps

`Jenkinsfile` 使用 KubeSphere 凭据 `kubeconfig-cred-id`，自动执行：
1. `Checkout`
2. `helm upgrade --install qwen3-8b-vl ...`
3. `helm upgrade --install qwen3-32b-vl ...`

如需参数化，可在 Jenkins pipeline 中将 release 名称与 values 文件改为输入参数，复用同一条流水线部署更多模型。
