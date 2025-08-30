<div align="center">
  <h1>lock_project</h1>
  <p>組合語言密碼鎖模擬系統</p>
</div>

---

## 目錄
- [目錄](#目錄)
- [專案簡介](#專案簡介)
- [技術棧](#技術棧)
- [安裝與啟動](#安裝與啟動)
- [其他](#其他)


## 專案簡介

本專案旨在設計一套具備實用性與學術價值的電子門禁控制系統，藉由使用經典且廣為人知的 AT89S52（8051）微控制器作為核心，培養對嵌入式系統設計與微控制器程式開發的實務能力。透過整合兩個中斷輸入、16×2 LCD 顯示、密碼比對、蜂鳴器與 LED 顯示等功能，實現一個可實際應用於門禁安全的控制裝置，達成「學以致用」的教學目標。

## 技術棧
- **組合語言（Assembly）**
- **at89s52(8051)**：微控制器
- **UVision**：程式編譯與模擬工具
- **Nuvoton Tools**：燒入韌體工具

## 安裝與啟動
1. 下載並安裝所需的軟體工具（如 Keil uVision、Nuvoton ISP-ICP Utility）。
2. 不編輯可略過，直接進第 3 步驟。使用 Keil uVision 開啟本專案（.uvproj 檔），如果編輯更動完成後，點擊「Build」按鈕進行編譯，產生 .hex 韌體檔案（位於 Objects 資料夾）。
3. 開啟 Nuvoton ISP-ICP Utility，選擇目標微控制器型號，選擇 USB 連接電路的 Port 號，點擊「Load File」載入剛剛產生的 .hex 檔案，並「Update Chip」按鈕進行上傳，過程中需要點擊電路上的「Reset」一次。

## 其他
更多資訊請參考：
[小組期末報告簡報](https://www.canva.com/design/DAGqM8lh3UA/IeToAfowIwrXNBWW4k1Igg/edit?utm_content=DAGqM8lh3UA&utm_campaign=designshare&utm_medium=link2&utm_source=sharebutton
)