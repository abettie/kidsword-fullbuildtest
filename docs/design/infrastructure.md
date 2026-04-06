# インフラ構成

## AWS構成

### リージョン: ap-northeast-1（東京）

### 使用サービス一覧

| サービス | 用途 | 設定 |
|---------|------|------|
| API Gateway | REST APIエンドポイント | dev ステージ |
| Lambda | バックエンド処理 | Node.js 20.x / 256MB / タイムアウト30秒 |
| DynamoDB | データストア | オンデマンド課金（PAY_PER_REQUEST） |
| Secrets Manager | Firebase認証情報保管 | 1シークレット |
| S3 | Terraform state 管理 | 既存バケット利用 |
| CloudWatch Logs | Lambda ログ | 保持期間: 30日 |
| IAM | 最小権限ロール | Lambda実行ロール |

### Lambda関数

| 関数名 | メモリ | タイムアウト | 用途 |
|--------|--------|------------|------|
| kidsword-dev-users | 256MB | 30秒 | ユーザ管理API |
| kidsword-dev-posts | 256MB | 30秒 | 投稿管理API |

### DynamoDBテーブル

| テーブル名 | 課金モード | GSI数 |
|-----------|-----------|-------|
| kidsword-dev-users | PAY_PER_REQUEST | 0 |
| kidsword-dev-posts | PAY_PER_REQUEST | 2 |

---

## 月額コスト見積もり（開発環境）

> 前提: 1日あたりAPIコール 500回、DynamoDB読み書き 1,000回、Lambdaメモリ 256MB

### サービス別内訳

| サービス | 月額費用（USD） | 月額費用（JPY） | 備考 |
|---------|--------------|--------------|------|
| API Gateway | ~$0.02 | ~3円 | 15,000コール/月 × $3.50/百万 |
| Lambda | ~$0.00 | ~0円 | 無料枠内（100万リクエスト/月） |
| DynamoDB | ~$0.00 | ~0円 | 無料枠内（25GB/月, 2.5百万読み書き） |
| Secrets Manager | ~$0.40 | ~60円 | 1シークレット × $0.40/月 |
| CloudWatch Logs | ~$0.05 | ~8円 | ログ取り込み 0.5GB/月 |
| S3（Terraform state） | ~$0.02 | ~3円 | 1MB未満 |
| **合計** | **~$0.49** | **~約74円** | **→ 3,000円以内 ✓** |

※ 1USD = 150JPY で計算
※ AWSの無料枠（12ヶ月）が適用される場合はさらに低コスト
※ 本番環境でトラフィックが増加した場合でも、月1万ユーザ規模まで数百円以内の見込み

### コスト最適化ポイント

- DynamoDBはオンデマンド課金（低トラフィック時にコスト効率が高い）
- LambdaはAWS無料枠（100万リクエスト/月）内に収まる
- API Gatewayも月100万コール以下なら費用は数円程度
- 月額3,000円を超えるとしたら月間1億以上のAPIコールが必要

---

## Terraform 構成

```
infrastructure/
├── environments/
│   └── dev/
│       ├── main.tf          # プロバイダ、バックエンド設定
│       ├── variables.tf     # 変数定義
│       ├── terraform.tfvars # 変数値（git管理、機密情報なし）
│       └── outputs.tf       # 出力値（APIエンドポイントなど）
└── modules/
    ├── dynamodb/            # DynamoDBテーブル
    ├── lambda/              # Lambda関数 + IAMロール
    └── api_gateway/         # API Gateway
```

### Terraform state 管理

- **バックエンド**: S3
- **バケット**: `tfstate-d0ecb71b-6149-48ce-99c8-94e41b353713`
- **キー**: `kidsword/dev/terraform.tfstate`
- **DynamoDBテーブル（state lock）**: 作成しない（小規模のため）
