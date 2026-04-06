# アーキテクチャ設計

## 概要

Firebase Auth を使ったGoogle認証と、AWS Lambda + DynamoDB によるサーバレスバックエンドで構成します。

## システム構成図

```mermaid
graph TB
    subgraph Android["Android端末"]
        App["Flutter App"]
    end

    subgraph Firebase["Firebase"]
        Auth["Firebase Auth\n(Google Sign-In)"]
    end

    subgraph AWS["AWS (ap-northeast-1)"]
        subgraph APIGateway["API Gateway (REST API)"]
            APIGW["API Gateway\n/dev"]
        end

        subgraph Lambda["Lambda Functions"]
            UsersHandler["users-handler\n(Node.js 20.x)"]
            PostsHandler["posts-handler\n(Node.js 20.x)"]
        end

        subgraph DynamoDB["DynamoDB"]
            UsersTable["users テーブル"]
            PostsTable["posts テーブル"]
        end

        subgraph SecretsManager["Secrets Manager"]
            FirebaseSecret["Firebase Admin SDK\n認証情報"]
        end
    end

    App -->|"Google Sign-In"| Auth
    Auth -->|"ID Token"| App
    App -->|"REST API + Bearer Token"| APIGW
    APIGW -->|"/users/*"| UsersHandler
    APIGW -->|"/posts/*"| PostsHandler
    UsersHandler -->|"Token検証"| FirebaseSecret
    PostsHandler -->|"Token検証"| FirebaseSecret
    UsersHandler --> UsersTable
    PostsHandler --> PostsTable
    PostsHandler --> UsersTable
```

## 認証フロー

```mermaid
sequenceDiagram
    participant App as Flutter App
    participant Firebase as Firebase Auth
    participant API as API Gateway
    participant Lambda as Lambda
    participant DB as DynamoDB

    App->>Firebase: Google Sign-In
    Firebase-->>App: Firebase ID Token
    App->>API: GET /users/me (Bearer Token)
    API->>Lambda: invoke
    Lambda->>Firebase: ID Token 検証
    Firebase-->>Lambda: userId (uid)
    Lambda->>DB: GetItem (users)
    DB-->>Lambda: ユーザ情報
    Lambda-->>API: 200 OK
    API-->>App: ユーザ情報
```

## コンポーネント詳細

### フロントエンド（Flutter）

| コンポーネント | 役割 |
|--------------|------|
| LoginScreen | Googleログイン画面 |
| NicknameScreen | 初回ニックネーム設定 |
| HomeScreen | タブ付きメイン画面（全体フィード / 自分の投稿） |
| PostFormScreen | 言い間違い投稿フォーム |
| AuthService | Firebase Auth 管理 |
| ApiService | バックエンドAPI呼び出し |

### バックエンド（Lambda）

| Lambda関数 | ルート | 役割 |
|-----------|--------|------|
| kidsword-dev-users | /users/* | ユーザ管理 |
| kidsword-dev-posts | /posts/* | 投稿管理 |

両Lambda関数は共通の認証ミドルウェアでFirebase IDトークンを検証します。

### インフラ（Terraform）

- **API Gateway**: REST API、CORSはAndroidアプリからのみのためシンプル設定
- **Lambda**: Node.js 20.x、メモリ256MB、タイムアウト30秒
- **DynamoDB**: オンデマンド課金（PAY_PER_REQUEST）
- **Secrets Manager**: Firebase Admin SDK サービスアカウントキー保存

## セキュリティ設計

- すべてのAPIエンドポイントでFirebase ID Token検証必須
- Lambda関数はVPC外（パブリック）だがIAMロールで最小権限設定
- DynamoDBへのアクセスはLambda実行ロール経由のみ
- 機密情報（Firebase認証情報）はSecrets Managerで管理

## ディレクトリ構成

```
/
├── frontend/                    # Flutter アプリ
│   ├── android/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   ├── nickname_screen.dart
│   │   │   ├── home_screen.dart
│   │   │   └── post_form_screen.dart
│   │   ├── models/
│   │   │   ├── user.dart
│   │   │   └── post.dart
│   │   ├── services/
│   │   │   ├── auth_service.dart
│   │   │   └── api_service.dart
│   │   └── widgets/
│   │       └── post_card.dart
│   └── pubspec.yaml
│
├── backend/                     # Lambda バックエンド
│   ├── src/
│   │   ├── handlers/
│   │   │   ├── users.ts
│   │   │   └── posts.ts
│   │   ├── middleware/
│   │   │   └── auth.ts
│   │   ├── repositories/
│   │   │   ├── userRepository.ts
│   │   │   └── postRepository.ts
│   │   └── utils/
│   │       └── response.ts
│   ├── package.json
│   └── tsconfig.json
│
├── infrastructure/              # Terraform
│   ├── environments/
│   │   └── dev/
│   └── modules/
│       ├── api_gateway/
│       ├── lambda/
│       └── dynamodb/
│
└── docs/
    └── design/
```
