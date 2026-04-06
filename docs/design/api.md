# API設計

## 基本情報

- **ベースURL**: `https://{api-id}.execute-api.ap-northeast-1.amazonaws.com/dev`
- **認証**: Firebase ID Token（Bearerトークン）
- **Content-Type**: `application/json`

## 認証方式

すべてのAPIエンドポイントは `Authorization: Bearer {firebase_id_token}` ヘッダーが必要です。
LambdaはFirebase Admin SDKを使ってトークンを検証します。

---

## エンドポイント一覧

### ユーザ管理

#### `GET /users/me`

自分のプロフィールを取得します。

**レスポンス**

```json
{
  "userId": "firebase_uid",
  "nickname": "パパ",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

| ステータス | 説明 |
|-----------|------|
| 200 | 成功 |
| 404 | ユーザが存在しない（初回ログイン時） |
| 401 | 認証エラー |

---

#### `PUT /users/me`

プロフィール（ニックネーム）を作成・更新します。

**リクエストボディ**

```json
{
  "nickname": "パパ"
}
```

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| nickname | string | ✓ | 1〜20文字 |

**レスポンス**

```json
{
  "userId": "firebase_uid",
  "nickname": "パパ",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

| ステータス | 説明 |
|-----------|------|
| 200 | 成功 |
| 400 | バリデーションエラー |
| 401 | 認証エラー |

---

### 投稿管理

#### `POST /posts`

言い間違いを投稿します。

**リクエストボディ**

```json
{
  "mispronounced": "トウモコロシ",
  "intended": "トウモロコシ",
  "description": "3歳の娘が言いました"
}
```

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| mispronounced | string | ✓ | 言い間違った言葉（1〜100文字） |
| intended | string | ✓ | 伝えたかった言葉（1〜100文字） |
| description | string | - | 説明（最大500文字） |

**レスポンス**

```json
{
  "postId": "550e8400-e29b-41d4-a716-446655440000",
  "userId": "firebase_uid",
  "mispronounced": "トウモコロシ",
  "intended": "トウモロコシ",
  "description": "3歳の娘が言いました",
  "createdAt": "2024-01-01T00:00:00.000Z"
}
```

| ステータス | 説明 |
|-----------|------|
| 201 | 作成成功 |
| 400 | バリデーションエラー |
| 401 | 認証エラー |
| 403 | ニックネーム未設定 |

---

#### `GET /posts/me`

自分の投稿一覧を新着順で取得します。

**クエリパラメータ**

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| limit | number | - | 取得件数（デフォルト: 20、最大: 50） |
| nextToken | string | - | ページネーショントークン |

**レスポンス**

```json
{
  "posts": [
    {
      "postId": "550e8400-e29b-41d4-a716-446655440000",
      "userId": "firebase_uid",
      "nickname": "パパ",
      "mispronounced": "トウモコロシ",
      "intended": "トウモロコシ",
      "description": "3歳の娘が言いました",
      "createdAt": "2024-01-01T00:00:00.000Z"
    }
  ],
  "nextToken": "eyJ..."
}
```

| ステータス | 説明 |
|-----------|------|
| 200 | 成功 |
| 401 | 認証エラー |

---

#### `GET /posts`

全ユーザの投稿を新着順で取得します。

**クエリパラメータ**

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| limit | number | - | 取得件数（デフォルト: 20、最大: 50） |
| nextToken | string | - | ページネーショントークン |

**レスポンス**

```json
{
  "posts": [
    {
      "postId": "550e8400-e29b-41d4-a716-446655440000",
      "userId": "firebase_uid",
      "nickname": "パパ",
      "mispronounced": "トウモコロシ",
      "intended": "トウモロコシ",
      "description": "3歳の娘が言いました",
      "createdAt": "2024-01-01T00:00:00.000Z"
    }
  ],
  "nextToken": "eyJ..."
}
```

| ステータス | 説明 |
|-----------|------|
| 200 | 成功 |
| 401 | 認証エラー |

---

## エラーレスポンス形式

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "nicknameは1〜20文字で入力してください"
  }
}
```

## エラーコード一覧

| コード | HTTPステータス | 説明 |
|--------|--------------|------|
| UNAUTHORIZED | 401 | 認証トークンが無効または期限切れ |
| FORBIDDEN | 403 | アクセス権限がない |
| NOT_FOUND | 404 | リソースが存在しない |
| VALIDATION_ERROR | 400 | 入力値が不正 |
| INTERNAL_ERROR | 500 | サーバ内部エラー |
