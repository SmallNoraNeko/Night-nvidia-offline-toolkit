[doca_offline_install.md](https://github.com/user-attachments/files/26863275/doca_offline_install.md)
# DOCA 離線安裝 SOP

**NVIDIA DOCA 3.2.1 — ARM64 Ubuntu 24.04 / Grace Blackwell (GB300)**

---

## 📋 前置條件確認

在開始前，請確認以下項目：

- [ ] 已在**有網路的 ARM64 Ubuntu 24.04 機台**完成下列步驟：
  1. 安裝 DOCA Local Repo `.deb` + 執行 `apt-get update`
  2. 執行 `sudo ./scripts/doca_offline_run.sh`
  3. 取得輸出的 `doca-3.2.1-offline-gb300-arm64.run` 自解壓安裝檔
- [ ] 安裝檔已複製到離線目標機台（建議放在 `/tmp/`）

---

## 🏗️ 打包端（有網路的機台）操作流程

> 如果你已有 `.run` 檔，可跳過此段直接到「安裝端」。

### 打包前置步驟

```bash
# 安裝打包必要工具
sudo apt-get update
sudo apt-get install -y makeself apt-rdepends

# 將 DOCA Local Repo .deb 放到工作目錄，然後掛載
sudo dpkg -i doca-host_3.2.1-044413-25.10-ubuntu2404_arm64.deb
sudo apt-get update

# 確認 APT 能解析 DOCA 套件（有輸出即成功）
apt-cache show doca-host
```

### 執行打包腳本

```bash
chmod +x scripts/doca_offline_run.sh
sudo ./scripts/doca_offline_run.sh
```

> ⏳ 依賴解析與下載需要 **10–30 分鐘**，輸出大量 `✓` 和 `Skipped` 為正常現象。

打包完成後，目錄中會出現：
```
doca-3.2.1-offline-gb300-arm64.run  （約 1–3 GB）
```

### 確認打包內容完整性

```bash
ls -lh doca_installer_payload/deps | wc -l   # 應有數百個 .deb
find doca_installer_payload/deps -size 0       # 應無輸出（無空檔案）
```

---

## 🖥️ 安裝端（離線目標機台）操作流程

### Step 1：複製安裝檔到目標機

**方式 A：使用 USB 碟/外部儲存**

直接複製 `.run` 檔到 `/tmp/` 或 home 目錄。

**方式 B：使用 scp（如果有區網但無外網）**

```bash
# 在打包機上執行：
scp doca-3.2.1-offline-gb300-arm64.run user@target-ip:/tmp/
```

---

### Step 2：給予執行權限並啟動安裝

```bash
chmod +x /tmp/doca-3.2.1-offline-gb300-arm64.run
sudo /tmp/doca-3.2.1-offline-gb300-arm64.run
```

安裝器會自動依序執行：
1. 安裝 Kernel Headers 與編譯工具
2. 設定本機 DOCA APT Repo（bypass GPG）
3. 安裝完整 DOCA Stack（doca-host, doca-all, doca-tools, doca-extra）
4. 啟用 OpenIB 服務

---

### Step 3：安裝過程中的正常現象

| 訊息 | 是否正常 | 說明 |
|---|---|---|
| `dpkg: warning: ... skipped due to errors` | ✅ 正常 | 安裝器最後會執行 `apt-get -f install` 修復 |
| 大量 `[WARN] Skipped: <package>` | ✅ 正常 | 部分套件可能已裝或在目標機不存在 |
| `openibd restart` 出現警告 | ✅ 正常 | 第一次安裝時服務尚未存在 |

---

### Step 4：安裝後驗證

```bash
# 重新開機（建議）
sudo reboot

# 重開機後確認 DOCA 版本
/opt/mellanox/doca/tools/doca-info

# 確認 InfiniBand / ConnectX 網卡狀態
ibstat

# 確認 OFED 模組
ofed_info -s
```

成功輸出範例：
```
DOCA Version: 3.2.1
ConnectX-7 [MT28908] - Active
```

---

## 🔧 故障排除

### 安裝中途停止 / 部分套件錯誤

```bash
# 手動修復
sudo dpkg --configure -a
sudo apt-get install -f -y \
    -o Dir::Etc::sourcelist="sources.list.d/doca-local-offline.list" \
    -o Dir::Etc::sourceparts="-"
```

### `doca-local-offline.list` 路徑錯誤

```bash
# 確認 DOCA repo 解壓路徑
ls /var/doca-repo-*

# 重新設定 APT 來源
echo "deb [trusted=yes] file:/var/doca-repo-<your-version>/ ./" \
    | sudo tee /etc/apt/sources.list.d/doca-local-offline.list

sudo apt-get update -o Dir::Etc::sourcelist="sources.list.d/doca-local-offline.list" \
    -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
```

### DKMS 核心模組編譯失敗（MLNX_OFED）

```bash
# 確認 flex 和 bison 已安裝（OFED 特別需要）
dpkg -l | grep -E "flex|bison"

# 查看 OFED 編譯日誌
ls /var/lib/dkms/mlnx-ofa_kernel/*/build/
cat /var/lib/dkms/mlnx-ofa_kernel/*/build/make.log | tail -30
```

> **最常見原因**：`flex` 和 `bison` 缺失導致 MLNX OFED 編譯失敗。
> `doca_offline_run.sh` 已將其納入 CORE_PKGS，若問題仍存在，請確認打包機下載成功。

### `ibstat` 顯示 Down 或 Initializing

```bash
# 重啟 OpenIB 服務
sudo /etc/init.d/openibd restart
sudo systemctl restart openibd

# 確認網卡是否被系統識別
lspci | grep -i mellanox
```

---

## ✅ 安裝完成後建議動作

1. 設定 DOCA 服務開機自啟：
   ```bash
   sudo systemctl enable openibd
   sudo systemctl enable opensmd  # 如果使用 InfiniBand Subnet Manager
   ```

2. 將驗證指令加入 runbook，供每次重開機後確認使用。

---

*文件版本：v1.0 | DOCA：3.2.1 | 架構：ARM64 | OS：Ubuntu 24.04 | 目標平台：GB300*
