# 技術選定記録

README.mdに記載のなかった技術の選定理由を記録します。

## バックエンド

### Lambda関数の分割方針: ルート別関数（usersとposts）

- **選定**: 機能別（users / posts）に2つのLambda関数を作成
- **理由**: 単一のmonolith関数よりも関心事が分離され、デプロイ・スケールが独立。機能が増えても管理しやすい。
- **代替案**: 単一Lambda関数（express + serverless-http）→ シンプルだが全機能をまとめてデプロイする必要があり柔軟性が低い

### Node.jsランタイム: Node.js 20.x

- **選定**: Node.js 20.x（LTS）
- **理由**: TypeScriptと相性が良く、AWSの現行LTSランタイム。Cold start時間もJavaより短い。

### バリデーション: zod

- **選定**: zodライブラリ
- **理由**: TypeScriptとの親和性が高く、型推論とバリデーションを同時に行える。軽量。

### DynamoDB操作: AWS SDK v3 + DynamoDB DocumentClient

- **選定**: `@aws-sdk/lib-dynamodb`（DocumentClient）
- **理由**: v3はモジュラー設計でLambdaのバンドルサイズを削減できる。DocumentClientでTypeScriptの型安全を保ちやすい。

---

## フロントエンド

### 状態管理: Provider（flutter_riverpod）

- **選定**: flutter_riverpod
- **理由**: Flutter公式が推奨するProviderの後継。テスタブルで、認証状態やAPIデータの管理が整理しやすい。
- **代替案**: bloc → ボイラープレートが多く小規模アプリには過剰

### HTTP通信: dio

- **選定**: dioパッケージ
- **理由**: Interceptorが使いやすく、Firebase IDトークンの自動付与ミドルウェアを実装しやすい。

### ナビゲーション: go_router

- **選定**: go_routerパッケージ（Flutter公式）
- **理由**: 宣言的ルーティングで認証ガードの実装が明確になる。

---

## インフラ

### API Gateway: REST API（v1）

- **選定**: API Gateway REST API
- **理由**: HTTP APIよりも機能が豊富。将来的なAPI KeyやUsage Planの追加が容易。
- **代替案**: HTTP API → シンプルで低コストだが機能が限られる（今回はどちらでも大差なし）

### DynamoDB課金モード: PAY_PER_REQUEST（オンデマンド）

- **選定**: オンデマンド課金
- **理由**: 開発・検証環境でトラフィックが不定期かつ少量。プロビジョニング済みキャパシティより低コスト。

### Firebase Admin SDK認証情報の保管: Secrets Manager

- **選定**: AWS Secrets Manager
- **理由**: Lambdaの環境変数に直接置くよりセキュア。ローテーションも可能。月$0.40と低コスト。

---

## CI/CD

### GitHub Actions

- **選定**: GitHub Actions
- **理由**: リポジトリがGitHubにある前提で、追加ツール不要。Terraform / Node.js / Flutter すべてのアクションが充実している。
