[README.md](https://github.com/user-attachments/files/26866846/README.md)
# 🛠️ Night NVIDIA Offline Toolkit

**離線安裝 NVIDIA GPU Driver 與 NVIDIA DOCA 的完整工具箱**

![Platform](https://img.shields.io/badge/Platform-ARM64%20%2F%20aarch64-blue)
![OS](https://img.shields.io/badge/OS-Ubuntu%2024.04%20LTS-orange)
![GPU](https://img.shields.io/badge/GPU-NVIDIA%20Blackwell%20GB300-76b900)
![License](https://img.shields.io/badge/License-MIT-green)

ARM64 · Ubuntu 24.04 · 64k Page Size · Grace Blackwell (GB300) 環境適用

---

## 📋 這個 Repo 是做什麼的？

在無法連接網際網路的伺服器上安裝 NVIDIA 驅動或 DOCA 網路堆疊時，需要事先在一台「有網路的同架構機器」上把所有相依套件打包好，再帶進離線環境安裝。

**適用對象：已有 NVIDIA 環境的機台進行驅動更新。**
若你的目標機台是全新的 Pure OS 環境（無任何 NVIDIA 套件），請參考其他 workflow。

這個工具箱提供：

| 工具 | 用途 |
|------|------|
| `scripts/pack_nvidia.sh` | 在有網路的機台打包 GPU Driver 所需的全部 .deb，輸出三個 .zip |
| `scripts/doca_offline_run.sh` | 在有網路的機台打包 NVIDIA DOCA 3.2.1，輸出一個自解壓 `.run` 安裝檔 |
| `manual_sop/gpu_driver_update.md` | GPU Driver 離線安裝完整 SOP（含故障排除） |
| `manual_sop/doca_offline_install.md` | DOCA 離線安裝完整 SOP |

---

## 🏗️ 支援環境

| 項目 | 規格 |
|------|------|
| 架構 | ARM64 (aarch64) |
| OS | Ubuntu 24.04 LTS (Noble) |
| Kernel | `6.8.0-1025-nvidia` (含 64k page size variant) |
| GPU Driver | NVIDIA Open Driver 580.x |
| DOCA | 3.2.1 (GB300 / Grace Blackwell) |

> 在不同版本的 kernel 或 driver 上使用時，請修改腳本頂部的 `KERNEL_VERSION` / `DRIVER_VERSION` 變數。

> **為什麼需要 64k page size？**
> GB200/GB300 Grace CPU 預設使用 64k 記憶體分頁大小。Kernel headers 必須與執行中的 kernel variant 完全相符（`-nvidia-64k`）。若不相符，DKMS 會在模組重建時靜默失敗，導致驅動安裝後 `nvidia-smi` 無法顯示裝置。

---

## ⚡ 快速開始

### GPU Driver 離線打包 → 安裝

```bash
# [有網路的機台] 執行打包腳本
chmod +x scripts/pack_nvidia.sh
./scripts/pack_nvidia.sh

# 將以下檔案複製到離線機台：
# nvidia-headers.zip, nvidia-deps.zip, nvidia-all-packages.zip
# + NVIDIA Local Repo .deb（從 NVIDIA 官網另行下載）
```

詳細安裝步驟請見 → [`manual_sop/gpu_driver_update.md`](manual_sop/gpu_driver_update.md)

---

### DOCA 3.2.1 離線打包 → 安裝

```bash
# [有網路的機台]
# Step 1：掛載 DOCA Local Repo（讓 apt 能解析完整相依性樹）
sudo dpkg -i doca-repo-aarch64-ubuntu2404-local-host-3.2.1_*.deb
sudo apt-get update

# Step 2：執行打包腳本
# 確認 doca-host_3.2.1-044413-25.10-ubuntu2404_arm64.deb 在同一目錄
chmod +x scripts/doca_offline_run.sh
sudo ./scripts/doca_offline_run.sh

# [離線目標機台] 安裝
chmod +x doca-3.2.1-offline-gb300-arm64.run
sudo ./doca-3.2.1-offline-gb300-arm64.run
# 安裝完成後需重新開機
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

1. **架構一致**：打包機與目標機必須都是 ARM64。在 x86 機台上打包的 `.deb` 無法在 ARM64 上安裝。
2. **OS 版本一致**：建議打包機與目標機使用相同的 Ubuntu 版本（24.04）。
3. **NVIDIA Local Repo .deb 需另行下載**：GPU Driver 的 Local Repo `.deb`（例如 `nvidia-driver-local-repo-ubuntu2404-580.105.08_1.0-1_arm64.deb`）請至 [NVIDIA 官網](https://www.nvidia.com/en-us/drivers/) 下載，不包含在本工具箱的打包腳本輸出中。
4. **DOCA 打包需先掛載 Repo**：執行 `doca_offline_run.sh` 前，必須在打包機上先安裝 DOCA **Local Repo** `.deb`（`doca-repo-aarch64-ubuntu2404-local-host-3.2.1_*.deb`，非 doca-host 本身）並執行 `apt-get update`，腳本才能解析完整的相依性樹。

---

## 🔧 常見問題

**`apt-get install -f` 嘗試連線到外網並失敗**

在指令中加入 sourcelist 覆蓋旗標，防止 apt 嘗試存取任何線上來源：

```bash
sudo apt-get install -f -y \
    -o Dir::Etc::sourcelist="/dev/null" \
    -o Dir::Etc::sourceparts="-"
```

---

**DKMS 模組建置失敗：`flex: command not found`**

MLNX_OFED 編譯需要 `flex`、`bison`、`graphviz`。這些工具已包含在 `doca_offline_run.sh` 的 `CORE_PKGS` 清單中。手動安裝時，請確認在執行 DOCA 安裝前，這些套件已從相依性壓縮檔中安裝完畢。

---

**重新開機後 `nvidia-smi` 顯示 `No devices were found`**

通常是 kernel headers 不符合。確認方式：

```bash
uname -r                       # 確認目前執行的 kernel variant
dpkg -l | grep linux-headers   # 確認已安裝的 headers 與 kernel 完全相符
dkms status                    # 確認模組建置狀態
```

若 headers 缺失（DKMS 靜默失敗），重新安裝正確版本後執行：

```bash
sudo dkms autoinstall
```

---

**APT 出現 GPG / signature 錯誤**

移除自動產生的線上來源清單，避免與本地 repo 衝突：

```bash
sudo rm -f /etc/apt/sources.list.d/nvidia-driver-local-repo.list
sudo rm -f /etc/apt/sources.list.d/doca.list
```

---

## ✅ 安裝後驗證

```bash
# GPU Driver
nvidia-smi
nvidia-smi -q | grep "Driver Version"

# DOCA Stack
/opt/mellanox/doca/tools/doca-info
ibstat
ofed_info -s

# DKMS 模組狀態
dkms status
# 預期輸出包含：nvidia/<version>, mlnx-ofed-kernel/<version> — installed
```

---

## 🔗 參考資源

- [NVIDIA DOCA 官方文件](https://docs.nvidia.com/doca/)
- [NVIDIA Open GPU Kernel Modules](https://github.com/NVIDIA/open-gpu-kernel-modules)
- [Ubuntu 24.04 ARM64 Packages](https://packages.ubuntu.com/)

---

## 📄 License

MIT License — 詳見 [LICENSE](LICENSE)

---

## 👤 Author

Night Kuronos Huang
[linkedin.com/in/night-kuronos-huang-548518317](https://www.linkedin.com/in/night-kuronos-huang-548518317)
