# フロントエンド概要

Flutter初心者向けに、このプロジェクトのフロントエンドの全体像を説明します。

## アプリの概要

**kidsword** は、子供の可愛い言い間違いを記録・共有するAndroidアプリです。

主な機能：
- Googleアカウントでログイン
- 言い間違いの投稿（言い間違い → 本来の言葉 + 説明文）
- みんなの投稿一覧（フィード）
- 自分の投稿一覧

## ファイル構成

```
frontend/
├── lib/                        # Dartのソースコード（ここを主に読む）
│   ├── main.dart               # アプリのエントリポイント・ルーティング定義
│   ├── screens/                # 各画面のWidget
│   │   ├── login_screen.dart   # ログイン画面
│   │   ├── nickname_screen.dart # ニックネーム設定画面（初回のみ）
│   │   ├── home_screen.dart    # ホーム画面（投稿一覧）
│   │   └── post_form_screen.dart # 投稿フォーム画面
│   ├── widgets/                # 画面をまたいで使い回すWidget
│   │   └── post_card.dart      # 投稿1件を表示するカード
│   ├── models/                 # データの型定義
│   │   ├── user.dart           # ユーザー情報
│   │   └── post.dart           # 投稿情報
│   └── services/               # 外部とのやりとり（APIやFirebase）
│       ├── auth_service.dart   # Firebase Authを使った認証処理
│       └── api_service.dart    # バックエンドAPIとの通信
├── pubspec.yaml                # 使用パッケージの定義（package.jsonに相当）
└── android/                    # Android固有の設定（通常は触らない）
```

## 使用している主なパッケージ

| パッケージ | 役割 |
|---|---|
| `flutter_riverpod` | 状態管理。画面間でデータを共有する仕組み |
| `go_router` | 画面遷移（ルーティング）の管理 |
| `firebase_auth` + `google_sign_in` | Googleログイン認証 |
| `dio` | HTTPクライアント。バックエンドAPIの呼び出しに使用 |
| `shared_preferences` | 端末へのデータ保存（現在は主にfirebaseが担当） |

## 画面遷移の全体像

```
アプリ起動
    |
    v
[ログイン判定（自動）]
    |
    +-- 未ログイン --> /login (ログイン画面)
    |                      |
    |                      v Googleでログイン
    |
    +-- ログイン済み
            |
            v プロフィール確認
            |
            +-- ニックネーム未設定 --> /nickname (ニックネーム設定画面)
            |                               |
            |                               v 保存
            |
            +-- ニックネーム設定済み --> /home (ホーム画面)
                                            |
                                            v [+]ボタン
                                        /post/new (投稿フォーム)
```

## コードを読む順番（おすすめ）

1. [main.dart](../lib/main.dart) — アプリの起動と画面遷移の全体像を把握
2. [models/post.dart](../lib/models/post.dart) — 扱うデータの型を理解
3. [services/auth_service.dart](../lib/services/auth_service.dart) — 認証の仕組みを理解
4. [services/api_service.dart](../lib/services/api_service.dart) — APIとのやりとりを理解
5. [screens/login_screen.dart](../lib/screens/login_screen.dart) — 最もシンプルな画面
6. [screens/home_screen.dart](../lib/screens/home_screen.dart) — Riverpodによる状態管理の典型例

詳細は各ドキュメントを参照してください：
- [architecture.md](./architecture.md) — アーキテクチャ・パターンの解説
- [screens.md](./screens.md) — 各画面のコード解説
