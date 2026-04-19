# 🛠️ Night NVIDIA Offline Toolkit

**離線安裝 NVIDIA GPU Driver 與 NVIDIA DOCA 的完整工具箱**
*ARM64 · Ubuntu 24.04 · 64k Page Size · Grace Blackwell (GB300) 環境適用*

---

## 📋 這個 Repo 是做什麼的？

在無法連接網際網路的伺服器上安裝 NVIDIA 驅動或 DOCA 網路堆疊時，需要事先在一台「有網路的同架構機器」上把所有相依套件打包好，再帶進離線環境安裝。

這個工具箱提供：

| 工具 | 用途 |
|---|---|
| `scripts/pack_nvidia.sh` | 在有網路的機台打包 GPU Driver 所需的全部 .deb，輸出三個 .zip |
| `scripts/doca_offline_run.sh` | 在有網路的機台打包 NVIDIA DOCA 3.2.1，輸出一個自解壓 `.run` 安裝檔 |
| `manual_sop/gpu_driver_update.md` | GPU Driver 離線安裝完整 SOP（含故障排除） |
| `manual_sop/doca_offline_install.md` | DOCA 離線安裝完整 SOP |

---

## 🏗️ 支援環境

- **架構**：ARM64 (aarch64)
- **OS**：Ubuntu 24.04 LTS (Noble)
- **Kernel**：`6.8.0-1025-nvidia` (含 64k page size variant)
- **GPU Driver**：NVIDIA Open Driver **580.x**
- **DOCA**：**3.2.1** (GB300 / Grace Blackwell)

> 在不同版本的 kernel 或 driver 上使用時，請修改腳本頂部的 `KERNEL_VERSION` / `DRIVER_VERSION` 變數。

---

## ⚡ 快速開始

### GPU Driver 離線打包 → 安裝

```bash
# [有網路的機台] 執行打包腳本
chmod +x scripts/pack_nvidia.sh
./scripts/pack_nvidia.sh

# 將以下 4 個檔案複製到離線機台：
# nvidia-headers.zip, nvidia-deps.zip, nvidia-all-packages.zip
# + NVIDIA Local Repo .deb (從 NVIDIA 官網另行下載)
```

詳細安裝步驟請見 → [`manual_sop/gpu_driver_update.md`](manual_sop/gpu_driver_update.md)

---

### DOCA 3.2.1 離線打包 → 安裝

```bash
# [有網路的機台] 先掛載 DOCA Local Repo，再執行打包腳本
sudo dpkg -i doca-host_3.2.1-*.deb
sudo apt-get update
chmod +x scripts/doca_offline_run.sh
sudo ./scripts/doca_offline_run.sh

# 將產出的 doca-3.2.1-offline-gb300-arm64.run 複製到離線機台：
chmod +x doca-3.2.1-offline-gb300-arm64.run
sudo ./doca-3.2.1-offline-gb300-arm64.run
```

詳細安裝步驟請見 → [`manual_sop/doca_offline_install.md`](manual_sop/doca_offline_install.md)

---

## 📁 Repository 結構

```
Night-nvidia-offline-toolkit/
├── README.md                        ← 你在這裡
├── LICENSE
├── .gitignore
├── scripts/
│   ├── pack_nvidia.sh               ← GPU Driver 打包腳本
│   └── doca_offline_run.sh          ← DOCA 離線 .run 生成腳本
└── manual_sop/
    ├── gpu_driver_update.md         ← GPU Driver 離線安裝 SOP
    └── doca_offline_install.md      ← DOCA 離線安裝 SOP
```

---

## ⚠️ 重要注意事項

1. **架構一致**：打包機與目標機必須都是 **ARM64**。在 x86 機台上打包的 `.deb` 無法在 ARM64 上安裝。
2. **OS 版本一致**：建議打包機與目標機使用相同的 Ubuntu 版本（24.04）。
3. **NVIDIA Local Repo .deb 需另行下載**：GPU Driver 的 Local Repo `.deb`（例如 `nvidia-driver-local-repo-ubuntu2404-580.105.08_1.0-1_arm64.deb`）請至 [NVIDIA 官網](https://www.nvidia.com/en-us/drivers/) 下載，不包含在本工具箱的打包腳本輸出中。
4. **DOCA 打包需先掛載 Repo**：執行 `doca_offline_run.sh` 前，必須在打包機上先安裝 DOCA Local Repo `.deb` 並執行 `apt-get update`，腳本才能解析完整的相依性樹。

---

## 🔗 參考資源

- [NVIDIA DOCA 官方文件](https://docs.nvidia.com/doca/)
- [NVIDIA Open GPU Kernel Modules](https://github.com/NVIDIA/open-gpu-kernel-modules)
- [Ubuntu 24.04 ARM64 Packages](https://packages.ubuntu.com/)

---

## 📄 License

MIT License — 詳見 [LICENSE](LICENSE)
