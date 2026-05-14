# CT226 鐵人三項心得 · 一頁部落格

> 2026.04.25 · 台東 · Wilson Yeh

一份用「英雄旅程」框架寫成的 CT226 完賽心得，做成可推到 GitHub Pages 的靜態網頁，也可在公司團隊做 10 分鐘分享時直接捲動展示。

---

## 專案結構

```
.
├── index.html               # 主頁面 (8 個章節，含 TODO 標記)
├── assets/
│   ├── css/style.css        # 樣式
│   └── js/main.js           # 互動 (淡入、目錄、Lightbox)
├── photos/
│   ├── raw/                 # ★ 原始照片放這 (不進 git)
│   └── web/                 # ★ 壓縮過的 web 版 (會進 git)
├── scripts/
│   └── process-photos.ps1   # 批次縮圖腳本
├── .gitignore
├── .nojekyll
└── README.md
```

---

## 使用流程

### 1. 填寫文字內容

開啟 `index.html`，按 `Ctrl+F` 搜尋 **`TODO`**。8 個章節依序填空：

| # | 章節 | 引導問題 |
|---|---|---|
| 1 | 召喚 | 為什麼會參加 CT226？是誰、什麼觸發了你？ |
| 2 | 啟程 | 開始訓練後，生活有什麼改變？|
| 3 | 試煉 | 比賽當天最痛苦的部分？(分游泳/單車/路跑) |
| 4 | 轉變 | 過程中腦袋在想什麼？什麼讓你撐下去？|
| 5 | 凱旋 | 通過終點線那一刻 + 帶回來的三件禮物 |
| 6 | 下一段 | 還會想再參加嗎？對團隊說的一句話 |
| 7 | Q&A | 預準備 4–6 個你想被問到的題目 |

每段下方都有灰色斜體的 placeholder 文字，是寫作提示，填好後把它整段刪掉就行。

### 2. 處理照片

a. 從 `D:\照片-活動\260425_CT226` 內，挑出 **20–30 張代表照**，依下表重新命名後丟進 `photos/raw/`：

| 檔名 | 用途 |
|---|---|
| `00-hero.jpg` | 序章大圖 (賽道全景 / 衝線 / 集合最有畫面感的一張) |
| `01-call.jpg` | 召喚 — 報名 / 開始那一刻 |
| `02-threshold-a.jpg` | 啟程 — 訓練畫面 (直幅) |
| `02-threshold-b.jpg` | 啟程 — 訓練/賽前 (橫幅) |
| `03-ordeal-swim.jpg` | 試煉 — 游泳 |
| `03-ordeal-bike.jpg` | 試煉 — 單車 |
| `03-ordeal-run.jpg` | 試煉 — 路跑 |
| `04-transformation.jpg` | 轉變 — 比賽中最猙獰 / 最有戲那張 |
| `05-return-finish.jpg` | 凱旋 — 衝線 |
| `05-return-medal.jpg` | 凱旋 — 獎牌 / 完賽合照 |
| `06-next.jpg` | 下一段 — 展望未來感 |

> 如果某個檔名找不到對應照片，網頁會自動顯示「📷 等候照片中…」的占位框，不會壞掉版面。

b. 執行縮圖腳本：

```powershell
pwsh ./scripts/process-photos.ps1
```

腳本會：
- 從 `photos/raw/` 讀取所有 jpg
- 長邊縮到 1600px、JPEG 品質 80
- 處理 EXIF 旋轉
- 輸出到 `photos/web/`，每張約 200–400 KB

可選參數：
```powershell
pwsh ./scripts/process-photos.ps1 -MaxDimension 1920 -Quality 85
pwsh ./scripts/process-photos.ps1 -Force   # 強制重做
```

### 3. 本機預覽

雙擊 `index.html`，或在這個資料夾裡跑：
```powershell
# Python 內建 server (有裝 Python 的話)
python -m http.server 8000
# 然後開 http://localhost:8000
```

> ⚠️ Lightbox 點擊放大功能在 file:// 協定下也能用，但若照片載入有怪事 (例如部分瀏覽器擋 `file://`)，建議用 http server 預覽。

### 4. 推到 GitHub + 啟用 Pages

```powershell
# 第一次設定
git init
git add .
git commit -m "init: CT226 完賽心得網站"

# 到 GitHub 新建 public repo (建議名稱 ct226-experience)，然後：
git branch -M main
git remote add origin https://github.com/<你的帳號>/ct226-experience.git
git push -u origin main
```

接著到 repo 的 **Settings → Pages**：
- Source: `Deploy from a branch`
- Branch: `main` / `/ (root)` → Save

等約 30 秒，網站就會出現在：
```
https://<你的帳號>.github.io/ct226-experience/
```

> `.nojekyll` 已預先放好，GitHub Pages 會跳過 Jekyll，確保 `/assets/` 路徑與底線開頭檔案不被過濾。

---

## 10 分鐘分享時的操作建議

1. 開分享前打開網頁，按 `F11` 進全螢幕。
2. 右側浮動目錄可快速跳章節 — 如果觀眾提問，可直接點對應章節跳過去。
3. 圖片點一下會放大 (Lightbox)；按 `Esc` 或點背景關閉。
4. 預計時長：
   - 第 1–2 章 各 ~1 分鐘
   - 第 3 章 (試煉) ~2 分鐘 — 整場最有戲、慢慢講
   - 第 4 章 (轉變) ~2 分鐘 — 情緒核心，pull quote 那句要停頓
   - 第 5–6 章 各 1.5 分鐘
   - Q&A ~1 分鐘

---

## 後續想擴充？

- 想換配色：改 `assets/css/style.css` 開頭的 `:root` 變數
- 想加章節：複製一段 `<section class="chapter">` 並更新右側 `.toc` 目錄
- 想加影片：在對應 `<figure>` 內把 `<img>` 換成 `<video controls>` 即可

---

## 致謝

- 攝影：James、蘇峻民、賽事官方
- 賽事：2026 CT226 · 台東

