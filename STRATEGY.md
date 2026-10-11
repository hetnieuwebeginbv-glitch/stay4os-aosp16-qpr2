# Stay4S 2-Jaren Strategisch Architectuurplan (2026-2028)

## Fase 1: Nu - Q1 2026 (Stabilisatie & Device Sovereignty)
- Pixel 9a: AOSP QPR2 build met hybride BP41 vendor/kernel
- Toestel draait volledig cloud-onafhankelijk met Stay4S 1.15B model
- Mesh binding: WireGuard/Tailscale tussen Pixel 9a en Pi 5
- Token rotation: Vervanging hardcoded tokens door Vault

## Fase 2: Q2-Q3 2026 (Federated Intelligence)
- Universele Pixel support: Tensor G2/G3/G4/G5
- Hybrid model routing:
  - Simpele intenties -> NPU on-device (1.15B, <50ms)
  - Complexe vragen -> Pi 5 (7B/Vision)
  - Zware generatie -> GPU nodes (Vast.ai/RunPod)

## Fase 3: 2027-2028 (Autonoom Systeem)
- On-Device Continuous Learning (Droom-Engine)
- Lokale interacties -> versleuteld vectorarchief
- Nachtelijke synthetische feedback -> Pi 5 Knowledge Graph
- Volledige uitschakeling Google Telemetry
- microG of Stay4S Core Services als Play Services alternatief

## Hardware Stack
| Component | Spec | Rol |
|-----------|------|-----|
| Pixel 9a | Tensor G4, 8GB LPDDR5 | Edge device |
| Pi 5 (8GB) | BCM2712, 8GB | Hub node |
| Pi 5 (16GB) | BCM2712, 16GB | Hub node (upgraded) |
| Vast.ai | A6000 48GB | Build/Training |
| RunPod | A6000 48GB | Training |

## Memory Management (8GB LPDDR5)
- ZRAM: 50% van fysiek (4GB) met LZ4/ZSTD
- GGUF mmap: Direct loading van flash naar virtueel geheugen
- Stay4S 1.15B Q4_K_M: ~706MB RAM (veilige marge)
- Android 16 idle: ~3.2-3.8GB

## NPU/GPU Acceleratie (Tensor G4)
- LiteRT / Google AI Edge: NPU delegates
- llama.cpp Vulkan: Mali-G715 GPU (~18-25 t/s op 1.15B)

## Kernel & Cgroup
- cgroup_disable=memory cgroup.memory=nokmem
- cgroups.json: Optional:true op niet-GKI controllers
