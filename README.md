# kidsword

子供が発した可愛い言い間違いを記録・共有するアプリです。

## アプリ概要

小さな子供が発した可愛い言い間違い（例：トウモロコシ→トウモコロシ）を投稿・閲覧できるアプリです。

## 機能

- **Googleログイン**によるユーザ管理
- 投稿者のニックネーム設定（必須）
- 言い間違いの投稿（「言い間違った言葉」「伝えたかった言葉」「説明」を入力）
- 自分の過去投稿の閲覧
- 他のユーザの投稿を新着順で閲覧

## 制限事項

- 他のユーザの投稿はソートや絞り込みができません
- いいねなどの評価機能はありません
- ランキング機能はありません
- 画像投稿機能はありません

## プロジェクト構成

```
/
├── infrastructure/    # インフラ
├── frontend/          # フロントエンド
└── backend/           # バックエンド
```

## 技術スタック

- **インフラ**: Terraform (AWS Lambda, DynamoDB, etc.)
- **フロントエンド**: Flutter（Android）
- **バックエンド**: TypeScript, AWS Lambda, DynamoDB
- **ユーザ認証**: Firebase Auth

---

## ローカル開発環境

### 必要なツール

- Node.js 20+
- Flutter 3.x
- Terraform 1.5+
- AWS CLI（デプロイ時）

### バックエンド

```bash
cd backend
npm install
npm test          # テスト実行
npm run lint      # 型チェック
node esbuild.mjs  # ビルド (dist/ に出力)
bash build.sh     # ビルド + ZIP化 (Lambda デプロイ用)
```

### フロントエンド

1. `frontend/android/app/google-services.json` を Firebase コンソールからダウンロードして配置
2. `frontend/lib/services/api_service.dart` の `API_BASE_URL` をデプロイ後のエンドポイントに設定

```bash
cd frontend
flutter pub get
flutter analyze   # 静的解析
flutter test      # テスト実行
flutter run       # 実機/エミュレータで起動 (google-services.json が必要)
```

#### WSL2 + 実機Androidで起動する場合

WSL2はUSBデバイスをそのまま認識しないため、追加のセットアップが必要です。

**1. usbipd-win をインストール（Windowsで実施・初回のみ）**

PowerShell（管理者）で実行:

```powershell
winget install usbipd
```

**2. Android実機をWSL2に接続（Windowsで実施）**

実機をUSBで接続した後、PowerShell（管理者）で実行:

```powershell
# ADB接続中のデバイスを自動検出してWSL2にアタッチ
$busid = (usbipd list | Select-String "ADB").ToString().Trim() -split '\s+' | Select-Object -First 1; usbipd bind --busid $busid; usbipd attach --wsl --busid $busid
```

**3. WSL2側のUSB権限を設定（初回のみ）**

```bash
echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", GROUP="plugdev"' | sudo tee /etc/udev/rules.d/51-android.rules
sudo chmod a+r /etc/udev/rules.d/51-android.rules
sudo udevadm control --reload-rules && sudo udevadm trigger
```

設定後、PowerShellで一度 detach → attach をやり直す:

```powershell
usbipd detach --busid <BUSID>
usbipd attach --wsl --busid <BUSID>
```

**4. Android SDK をインストール（初回のみ）**

```bash
# Command Line Tools をダウンロード・配置
mkdir -p ~/Android/SDK/cmdline-tools
cd /tmp
wget https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip
unzip commandlinetools-linux-13114758_latest.zip -d ~/Android/SDK/cmdline-tools
mv ~/Android/SDK/cmdline-tools/cmdline-tools ~/Android/SDK/cmdline-tools/latest

# PATH に追加
echo 'export ANDROID_HOME=$HOME/Android/SDK' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools' >> ~/.bashrc
source ~/.bashrc

# SDK コンポーネントをインストール・ライセンスに同意
sdkmanager --install "platform-tools" "platforms;android-36" "build-tools;36.0.0"
sdkmanager --licenses

# Flutter に SDK パスを設定
flutter config --android-sdk ~/Android/SDK
```

**5. Java 17 をインストール（初回のみ）**

Flutter/Gradle は Java 17〜24 が必要です（Java 25以上は非対応）。

```bash
sudo apt install -y openjdk-17-jdk
flutter config --jdk-dir=/usr/lib/jvm/java-17-openjdk-amd64
```

**6. 実機でアプリを起動**

```bash
adb devices   # 実機が表示されることを確認
cd ~/repositories/kidsword/frontend
flutter run
```

**7. 実機にアプリを永続インストール**

`flutter run` はUSB接続中のみ動作するデバッグ起動です。
USBを外しても使えるよう実機にインストールするには、`flutter install` を使います。

```bash
cd ~/repositories/kidsword/frontend
flutter build apk && flutter install
```

インストール後はUSBを外してもアプリを起動できます。

---

## 環境変数の設定

### GitHub Actions Secrets

CI/CDを動かすには以下のSecretをGitHubリポジトリに設定してください。

| シークレット名 | 説明 |
|--------------|------|
| `AWS_ACCESS_KEY_ID` | AWS アクセスキー |
| `AWS_SECRET_ACCESS_KEY` | AWS シークレットキー |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Firebase Admin SDK サービスアカウントキーのJSON文字列 |

### API エンドポイントの設定

`terraform apply` 後に出力される `api_endpoint` を Flutter アプリに設定します。

```bash
# Terraform output の確認
cd infrastructure/environments/dev
terraform output api_endpoint
```

`frontend/lib/services/api_service.dart` の `_apiBaseUrl` を更新するか、
Flutter ビルド時に `--dart-define=API_BASE_URL=https://...` で渡してください。

```bash
flutter build apk --dart-define=API_BASE_URL=https://YOUR_API_ENDPOINT
```

---

## テストの実行

```bash
# バックエンドテスト
cd backend && npm test

# フロントエンドテスト
cd frontend && flutter test
```

---

## デプロイ手順

### 前提条件

1. AWS CLI が設定されていること (`aws configure`)
2. Terraform state 用 S3 バケットが存在すること
3. Firebase Admin SDK サービスアカウントキーを取得済みであること

### dev環境へのデプロイ

```bash
# 1. バックエンドをビルド
cd backend
npm ci
bash build.sh

# 2. Terraform でインフラを構築
cd ../infrastructure/environments/dev
terraform init
terraform apply \
  -var="firebase_service_account_json=$(cat /path/to/service-account.json)"

# 3. API エンドポイントを確認
terraform output api_endpoint
```

### CI/CD による自動デプロイ

| トリガー | 対象 | 内容 |
|---------|------|------|
| push to master | dev環境 | `deploy-staging.yml` が自動実行 |
| tag push (v*) | prod環境 | `deploy-prod.yml` が自動実行 |

### インフラの削除

```bash
cd infrastructure/environments/dev
terraform destroy
```