# アーキテクチャ解説

このドキュメントでは、コードを読むうえで前提となる設計パターンを説明します。

## 1. Riverpod — 状態管理

### Riverpodとは

Riverpodは「アプリ全体でデータを共有・管理する仕組み」です。  
Flutterでは画面（Widget）の間でデータを渡すのが面倒なため、Riverpodを使ってどこからでもデータにアクセスできるようにします。

### Provider（プロバイダー）

Riverpodでは、データや処理を **Provider** という単位で定義します。

```dart
// サービスのインスタンスを提供するProvider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// 非同期でデータを取得するProvider
final feedPostsProvider = FutureProvider<List<Post>>((ref) async {
  final result = await ref.watch(apiServiceProvider).getFeedPosts();
  return result.posts;
});

// リアルタイムで変化するデータのProvider（ログイン状態など）
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
```

### Widgetからのアクセス方法

Riverpodを使うWidgetは `ConsumerWidget` または `ConsumerStatefulWidget` を継承します。

```dart
// ConsumerWidget の場合（状態を持たないWidget）
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch: データを購読（変化があると再描画される）
    final posts = ref.watch(feedPostsProvider);

    // ref.read: 一度だけ読み取る（ボタン押下時の処理など）
    ref.read(authServiceProvider).signOut();

    // ref.refresh: Providerを強制的に再実行（再読み込み）
    ref.refresh(feedPostsProvider);

    // ref.invalidate: Providerのキャッシュを破棄（次回アクセス時に再取得）
    ref.invalidate(feedPostsProvider);
  }
}
```

### FutureProvider の結果の扱い方

非同期データは `AsyncValue` という型で返ってきます。`.when()` で3つの状態を処理します。

```dart
final async = ref.watch(feedPostsProvider);
return async.when(
  loading: () => CircularProgressIndicator(), // データ取得中
  error: (e, _) => Text('エラー: $e'),         // エラー発生時
  data: (posts) => ListView(...),              // 取得成功時
);
```

このパターンは [home_screen.dart](../lib/screens/home_screen.dart) の `_PostList` クラスで使われています。

---

## 2. go_router — 画面遷移

### ルートの定義

[main.dart](../lib/main.dart) でアプリ全体のルートを定義しています。

```dart
routes: [
  GoRoute(path: '/',         builder: (context, state) => const LoginScreen()),
  GoRoute(path: '/login',    builder: (context, state) => const LoginScreen()),
  GoRoute(path: '/nickname', builder: (context, state) => const NicknameScreen()),
  GoRoute(path: '/home',     builder: (context, state) => const HomeScreen()),
  GoRoute(path: '/post/new', builder: (context, state) => const PostFormScreen()),
],
```

### 画面遷移の方法

```dart
// 現在の画面を置き換えて遷移（戻れない）
context.go('/home');

// スタックに積んで遷移（戻れる）
context.push('/post/new');

// 前の画面に戻る
context.pop();
```

### リダイレクト（自動振り分け）

`redirect` 関数でログイン状態に応じて自動的に遷移先を振り分けています。

```dart
redirect: (context, state) async {
  final user = authState.valueOrNull;

  // 未ログインならログイン画面へ
  if (user == null) {
    return state.matchedLocation == '/login' ? null : '/login';
  }

  // ログイン済みでルートにアクセスした場合、プロフィール確認
  if (state.matchedLocation == '/login' || state.matchedLocation == '/') {
    final profile = await apiService.getMyProfile();
    if (profile == null) return '/nickname'; // 初回ならニックネーム設定へ
    return '/home';
  }

  return null; // リダイレクト不要
},
```

---

## 3. レイヤー構成

このアプリは責務ごとに3つのレイヤーに分かれています。

```
┌─────────────────────────────────────┐
│  screens/  ・  widgets/             │  UI層
│  ユーザーに見える画面・部品           │
├─────────────────────────────────────┤
│  services/                          │  サービス層
│  外部との通信（Firebase, API）        │
├─────────────────────────────────────┤
│  models/                            │  データ層
│  データの型定義・JSONの変換           │
└─────────────────────────────────────┘
```

### データの流れ

```
ユーザー操作（ボタン押下など）
    |
    v
Screen（画面Widget）
    |  ref.read(apiServiceProvider).createPost(...)
    v
ApiService（API呼び出し）
    |  dio.post('/posts', data: {...})
    v
バックエンドAPI（AWS Lambda）
    |  JSONレスポンス
    v
Post.fromJson(...)（モデルに変換）
    |
    v
ref.invalidate(feedPostsProvider)（キャッシュ破棄→再取得）
    |
    v
FutureProvider が再実行 → 画面が再描画
```

---

## 4. Widget の種類

Flutterには複数種類のWidgetがあります。このプロジェクトでの使い分け：

| 種類 | 説明 | このプロジェクトでの使用例 |
|---|---|---|
| `StatelessWidget` | 状態を持たないWidget | `PostCard` |
| `StatefulWidget` | ローカルな状態（`_isLoading`など）を持つWidget | （Riverpodを使っているため直接は不使用） |
| `ConsumerWidget` | Riverpodにアクセスできる StatelessWidget | `_PostList`、`KidswordApp` |
| `ConsumerStatefulWidget` | Riverpodにアクセスできる StatefulWidget | `LoginScreen`、`HomeScreen`、`NicknameScreen`、`PostFormScreen` |

ローカルな状態（ローディングフラグ、テキスト入力など）は `ConsumerStatefulWidget` で管理し、  
APIデータなど画面をまたぐ状態は Riverpod の Provider で管理しています。

---

## 5. 認証フロー

```
[アプリ起動]
    |
    v
Firebase.initializeApp()  ← Firebaseを初期化
    |
    v
authStateProvider（StreamProvider）がログイン状態を監視
    |
    v
go_router の redirect がログイン状態を確認
    |
    +-- 未ログイン → /login に遷移
    |
    +-- ログイン済み
            |
            v
        Firebase ID Token を取得（getIdToken）
            |
            v
        APIリクエストの Authorization ヘッダーに Bearer トークンをセット
            |
            v
        バックエンドがトークンを検証してリクエスト処理
```

ID Tokenのセットは [api_service.dart](../lib/services/api_service.dart) の Dio インターセプターで自動的に行われます。すべてのAPIリクエストに自動付与されるため、各API呼び出しで個別に書く必要はありません。
