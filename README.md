# 100歩目覚まし（100 Step Alarm）

100歩歩かないと止まらない目覚ましアプリ

## 概要

- スヌーズなし
- 100歩歩くまでアラームが鳴り続ける
- 緊急停止は月3回まで
- 買い切り ¥300-480

## 開発

```bash
# Xcodeで開く
open HundredStepAlarm.xcodeproj
```

## 技術スタック

- iOS 16.0+
- Swift 5.9+
- SwiftUI
- SwiftData
- CoreMotion (CMPedometer)
- AVFoundation
- UserNotifications

## プロジェクト構造

```
HundredStepAlarm/
├── App/
│   └── HundredStepAlarmApp.swift    # アプリエントリポイント
├── Models/
│   ├── Alarm.swift                   # アラームデータモデル
│   └── EmergencyStopManager.swift    # 緊急停止の残り回数管理
├── Views/
│   ├── AlarmListView.swift           # メイン画面（アラーム一覧）
│   ├── AlarmEditView.swift           # アラーム編集画面
│   ├── AlarmRingView.swift           # アラーム発動画面（歩数表示）
│   └── SettingsView.swift            # 設定画面
├── Services/
│   ├── PedometerService.swift        # CMPedometer ラッパー
│   ├── AudioService.swift            # アラーム音再生
│   └── NotificationService.swift     # ローカル通知
└── Resources/
    ├── Assets.xcassets/              # アプリアイコン、カラー
    └── Sounds/                       # アラーム音源（.caf/.m4a）
```

## 詳細

開発の詳細は [CLAUDE.md](./CLAUDE.md) を参照
