[gpu_driver_update.md](https://github.com/user-attachments/files/26863266/gpu_driver_update.md)
# GPU Driver 離線安裝 SOP

**NVIDIA Open Driver 580.x — ARM64 Ubuntu 24.04 (64k Page Size)**

---

## 📋 前置條件確認

在開始前，請確認以下項目：

- [ ] 已在**有網路的 ARM64 Ubuntu 24.04 機台**執行 `scripts/pack_nvidia.sh`，並取得：
  - `nvidia-headers.zip`
  - `nvidia-deps.zip`
  - `nvidia-all-packages.zip`
- [ ] 已從 NVIDIA 官網下載對應版本的 **Local Repo `.deb`** 檔案
  - 例：`nvidia-driver-local-repo-ubuntu2404-580.105.08_1.0-1_arm64.deb`
- [ ] 以上 4 個檔案已複製到離線目標機台的工作目錄（建議放在 `~/gpu-install/`）

---

## 🛠️ 安裝步驟

### Step 0：準備工作目錄

登入離線目標機台，執行：

```bash
mkdir -p ~/gpu-install
cd ~/gpu-install
# 確認檔案已就位
ls -lh
```

應可看到 3 個 `.zip` + 1 個 `.deb`。

---

### Step 1：解壓縮所有套件

```bash
cd ~/gpu-install

unzip nvidia-headers.zip
unzip nvidia-deps.zip
unzip nvidia-all-packages.zip
```

> **說明**：解壓後會分別出現 `nvidia-headers/`、`nvidia-deps/`、`nvidia-all-packages/` 三個資料夾。

---

### Step 2：安裝 Kernel Headers（核心標頭檔）

```bash
cd ~/gpu-install/nvidia-headers
sudo dpkg -i linux-headers-*.deb
```

> ✅ **為什麼先裝這個？** DKMS 需要在本機編譯 nvidia 核心模組，必須有對應版本的 kernel headers 才能進行。64k page size 的 headers 是 GB300 環境的必要條件。

確認安裝結果：
```bash
dpkg -l | grep linux-headers
```

---

### Step 3：安裝系統相依套件

```bash
cd ~/gpu-install/nvidia-deps
sudo dpkg -i *.deb
```

> ⚠️ 此步驟可能出現「依賴未滿足」的警告，屬正常現象。繼續執行 Step 4 即可修復。

---

### Step 4：安裝編譯工具鏈

```bash
cd ~/gpu-install/nvidia-all-packages
sudo dpkg -i gcc*.deb make*.deb dkms*.deb libc6-dev*.deb libglvnd-dev*.deb pkg-config*.deb libelf-dev*.deb
```

---

### Step 5：強制修復套件依賴

整理所有 `dpkg` 的未完成安裝狀態，並修復潛在的順序問題：

```bash
sudo dpkg --configure -a
sudo apt-get install -y -f
```

> **說明**：`-f` 旗標代表 "fix-broken"，apt 會嘗試在本機（不連網）的情況下解決相依性。

---

### Step 6：安裝 NVIDIA Local Repo 並匯入金鑰

```bash
cd ~/gpu-install
sudo dpkg -i nvidia-driver-local-repo-ubuntu2404-580.105.08_1.0-1_arm64.deb
sudo cp /var/nvidia-driver-local-repo-ubuntu2404-580.105.08/nvidia-driver-*-keyring.gpg /usr/share/keyrings/
sudo apt-get update
```

> ⚠️ **請將指令中的版本號替換為您實際下載的版本。**

確認 APT 能看到驅動：
```bash
apt-cache policy nvidia-open-580
```

輸出中應包含來自 `/var/nvidia-driver-local-repo-...` 的版本資訊。

---

### Step 7：安裝 NVIDIA Open Driver（DKMS 在線編譯）

```bash
sudo apt-get install -y nvidia-open-580
```

> ⏳ **此步驟會在本機進行 DKMS 核心模組編譯，耗時約 5–15 分鐘，請耐心等待。**

---

### Step 8：驗證安裝結果

```bash
nvidia-smi
```

成功輸出範例：
```
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 580.x.x       Driver Version: 580.x.x     CUDA Version: 12.x               |
|-------------------------------+----------------------+----------------------+
| GPU  Name                Persistence-M | Bus-Id        Disp.A | Volatile Uncorr. ECC |
|   0  NVIDIA Grace Blackwell ...  Off  | ...                  |
```

---

## 🔧 故障排除

### 安裝在 Step 7 失敗 → 查看 DKMS 編譯日誌

```bash
cat /var/lib/dkms/nvidia/580.105.08/build/make.log | tail -50
```

| 日誌中的錯誤訊息 | 原因 | 解決方法 |
|---|---|---|
| `cc: command not found` | gcc 沒有安裝成功 | 重新執行 Step 4，確認 `gcc*.deb` 有安裝 |
| `scripts/basic/fixdep: No such file or directory` | linux-headers 沒裝好或版本不符 | 重新執行 Step 2，確認 headers 版本與執行中的 kernel 相符 |
| `Module build for kernel X.X.X was skipped` | Headers 版本與 uname -r 不符 | 執行 `uname -r` 確認 kernel 版本後重新下載對應 headers |
| `dpkg: dependency problems` | 相依套件順序問題 | 重新執行 Step 5 (`dpkg --configure -a && apt-get -f install`) |

### 確認目前 kernel 版本

```bash
uname -r
# 應輸出類似：6.8.0-1025-nvidia
```

### 確認 DKMS 模組狀態

```bash
dkms status
# 應出現：nvidia/580.x.x, 6.8.0-1025-nvidia, aarch64: installed
```

---

## ✅ 安裝完成後建議動作

1. **重新開機**（非必須但建議）：
   ```bash
   sudo reboot
   ```

2. **重開機後再次確認**：
   ```bash
   nvidia-smi
   lsmod | grep nvidia
   ```

---

*文件版本：v1.0 | 適用驅動：580.x | 架構：ARM64 | OS：Ubuntu 24.04*
