# 各画面・コンポーネントの解説

## 1. main.dart — エントリポイント

[../lib/main.dart](../lib/main.dart)

### `main()` 関数

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutterエンジンの初期化（非同期処理の前に必須）
  await Firebase.initializeApp();            // Firebaseの初期化
  runApp(const ProviderScope(child: KidswordApp())); // アプリ起動
}
```

`ProviderScope` は Riverpod を使うために必ずアプリのルートに置く必要があります。  
これがないと `ref.watch` などが動きません。

### `KidswordApp` クラス

```dart
class KidswordApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider); // ルーターを取得
    return MaterialApp.router(
      title: 'kidsword',
      theme: ThemeData(
        colorSchemeSeed: Colors.orange, // テーマカラーをオレンジに
        useMaterial3: true,             // Material Design 3 を使用
      ),
      routerConfig: router,
    );
  }
}
```

---

## 2. LoginScreen — ログイン画面

[../lib/screens/login_screen.dart](../lib/screens/login_screen.dart)

ログイン画面は最もシンプルなパターンです。

```
┌─────────────────────┐
│                     │
│   [子供アイコン]     │
│   kidsword          │
│   子供の可愛い...    │
│                     │
│  [Googleでログイン]  │
│                     │
└─────────────────────┘
```

### ポイント

**ローディング状態の管理**  
ボタン押下中は `_isLoading = true` にして CircularProgressIndicator を表示します。

```dart
bool _isLoading = false;

Future<void> _signIn() async {
  setState(() => _isLoading = true);  // ローディング開始
  try {
    await ref.read(authServiceProvider).signInWithGoogle();
  } catch (e) {
    // エラー時はSnackBarで通知
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ログインに失敗しました: $e')),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false); // ローディング終了
  }
}
```

**`mounted` チェック**  
`setState` の前に `mounted` を確認するのは、非同期処理中に画面が破棄された場合のクラッシュを防ぐためです。Flutter特有のパターンです。

**ログイン後の遷移**  
ログイン後の画面遷移はここでは行いません。`authStateProvider`（StreamProvider）がログイン状態の変化を検知し、go_router の `redirect` が自動的に `/home` または `/nickname` に遷移します。

---

## 3. NicknameScreen — ニックネーム設定画面

[../lib/screens/nickname_screen.dart](../lib/screens/nickname_screen.dart)

初回ログイン時のみ表示される画面です。

```
┌─────────────────────┐
│ ニックネームの設定   │
├─────────────────────┤
│ 投稿に表示される...  │
│                     │
│ ┌───────────────┐  │
│ │ ニックネーム  │  │
│ └───────────────┘  │
│                     │
│  [保存して始める]   │
└─────────────────────┘
```

### ポイント

**Form と バリデーション**  
`Form` Widget と `GlobalKey<FormState>` を使ったバリデーションパターン。

```dart
final _formKey = GlobalKey<FormState>();

// バリデーション実行
if (!_formKey.currentState!.validate()) return; // NGなら処理中断

// TextFormField にバリデーションルールを定義
TextFormField(
  validator: (v) {
    if (v == null || v.trim().isEmpty) return 'ニックネームを入力してください';
    if (v.trim().length > 20) return '20文字以内で入力してください';
    return null; // null を返すとOK
  },
)
```

**TextEditingController**  
テキストフィールドの入力値を取得するためのコントローラー。`dispose()` で必ず破棄します。

```dart
final _controller = TextEditingController();

@override
void dispose() {
  _controller.dispose(); // メモリリーク防止のため必須
  super.dispose();
}
```

---

## 4. HomeScreen — ホーム画面

[../lib/screens/home_screen.dart](../lib/screens/home_screen.dart)

メインの画面。TabBarで「みんなの投稿」と「自分の投稿」を切り替えます。

```
┌─────────────────────┐
│ kidsword     [ログアウト] │
│ [みんな] [自分]     │
├─────────────────────┤
│                     │
│ ┌─────────────────┐ │
│ │ PostCard        │ │
│ └─────────────────┘ │
│ ┌─────────────────┐ │
│ │ PostCard        │ │
│ └─────────────────┘ │
│                     │
└──────────────── [+] ┘
```

### ポイント

**FutureProvider の定義場所**  
Provider はファイルのトップレベルで定義します（クラスの外）。

```dart
// ファイル最上部（グローバル）
final feedPostsProvider = FutureProvider<List<Post>>((ref) async {
  final result = await ref.watch(apiServiceProvider).getFeedPosts();
  return result.posts;
});
```

**TabBar と TabController**  
タブの管理には `TabController` を使い、`SingleTickerProviderStateMixin` が必要です。

```dart
class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {   // ← TabController に必要
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // タブ数を指定
  }

  @override
  void dispose() {
    _tabController.dispose(); // 必ず破棄
    super.dispose();
  }
}
```

**`_PostList` — Providerを引数で受け取るWidget**  
「みんなの投稿」と「自分の投稿」は同じ表示ロジックを使うため、使用するProviderだけ差し替えられるように設計されています。

```dart
class _PostList extends ConsumerWidget {
  final FutureProvider<List<Post>> provider; // どのProviderを使うか受け取る

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider); // 受け取ったProviderをwatch
    return async.when(
      loading: () => CircularProgressIndicator(),
      error: (e, _) => ...,
      data: (posts) => RefreshIndicator( // 引っ張って更新
        onRefresh: () async => ref.refresh(provider),
        child: ListView.builder(...),
      ),
    );
  }
}
```

---

## 5. PostFormScreen — 投稿フォーム画面

[../lib/screens/post_form_screen.dart](../lib/screens/post_form_screen.dart)

言い間違いを投稿する画面。

```
┌─────────────────────┐
│ 言い間違いを投稿    │
├─────────────────────┤
│ ┌───────────────┐  │
│ │言い間違った言葉│  │
│ └───────────────┘  │
│ ┌───────────────┐  │
│ │伝えたかった言葉│  │
│ └───────────────┘  │
│ ┌───────────────┐  │
│ │説明（任意）   │  │
│ └───────────────┘  │
│  [投稿する]         │
└─────────────────────┘
```

### ポイント

**投稿後のキャッシュ破棄**  
投稿後にホーム画面の一覧を最新化するため、`ref.invalidate()` でProviderのキャッシュを破棄します。次にそのProviderにアクセスした時に再取得が走ります。

```dart
await ref.read(apiServiceProvider).createPost(...);

// 投稿一覧のキャッシュを破棄 → ホーム画面に戻った時に再取得される
ref.invalidate(feedPostsProvider);
ref.invalidate(myPostsProvider);

context.pop(); // 前の画面（ホーム）に戻る
```

**description の条件付き送信**  
説明文は任意項目のため、空欄の場合はAPIに送らないようにしています（`api_service.dart` 側の処理）。

```dart
// api_service.dart
if (description != null && description.isNotEmpty) 'description': description,
```

---

## 6. PostCard — 投稿カードWidget

[../lib/widgets/post_card.dart](../lib/widgets/post_card.dart)

1件の投稿を表示する再利用可能なWidget。

```
┌──────────────────────────────┐
│ [人アイコン] パパ    2024/01/15 │
│                              │
│ 言い間違い → 伝えたかった言葉  │
│ トウモコロシ  トウモロコシ     │
│                              │
│ 3歳の娘が言いました           │
└──────────────────────────────┘
```

### ポイント

**`StatelessWidget`**  
状態を持たず、受け取った `post` データを表示するだけなので最もシンプルな `StatelessWidget` です。

**`description` の条件付き表示**  
`...` スプレッド演算子と `if` を使ったFlutter特有のリスト内条件分岐パターン。

```dart
if (post.description != null && post.description!.isNotEmpty) ...[
  const SizedBox(height: 8),
  Text(post.description!),
],
```

**日付フォーマット**  
バックエンドからISO 8601形式（`2024-01-15T10:30:00.000Z`）で届く日時を、  
`yyyy/MM/dd` 形式に変換してローカルタイムで表示しています。

---

## 7. モデルクラス

### User

[../lib/models/user.dart](../lib/models/user.dart)

```dart
class User {
  final String userId;
  final String nickname;
  final String createdAt;
  final String updatedAt;

  // factory コンストラクタ: JSONから User オブジェクトを生成
  factory User.fromJson(Map<String, dynamic> json) => User(
    userId: json['userId'] as String,
    ...
  );
}
```

### Post

[../lib/models/post.dart](../lib/models/post.dart)

```dart
class Post {
  final String postId;
  final String userId;
  final String nickname;
  final String mispronounced; // 言い間違い
  final String intended;      // 伝えたかった言葉
  final String? description;  // 説明（任意 → null許容型 String?）
  final String createdAt;
  ...
}
```

`String?` の `?` は「nullになりうる型」を表すDartの記法です。  
`description` は任意入力なので null になる場合があります。

---

## 8. サービスクラス

### AuthService

[../lib/services/auth_service.dart](../lib/services/auth_service.dart)

Firebase AuthとGoogleサインインをラップしたクラス。

| メソッド | 説明 |
|---|---|
| `authStateChanges` | ログイン状態の変化をStreamで監視 |
| `currentUser` | 現在のログインユーザーを返す |
| `getIdToken()` | Firebase ID Tokenを取得（API認証に使用） |
| `signInWithGoogle()` | Googleログインを実行 |
| `signOut()` | ログアウト |

### ApiService

[../lib/services/api_service.dart](../lib/services/api_service.dart)

Dioを使ったHTTPクライアント。全リクエストに自動でFirebase ID Tokenを付与します。

| メソッド | HTTPメソッド・エンドポイント | 説明 |
|---|---|---|
| `getMyProfile()` | GET `/users/me` | 自分のプロフィール取得（404→null） |
| `updateProfile(nickname)` | PUT `/users/me` | ニックネームを更新 |
| `createPost(...)` | POST `/posts` | 言い間違いを投稿 |
| `getMyPosts(...)` | GET `/posts/me` | 自分の投稿一覧 |
| `getFeedPosts(...)` | GET `/posts` | 全員の投稿一覧（フィード） |

**インターセプター**  
Dioのインターセプターを使って、すべてのリクエストに自動でトークンを付与しています。

```dart
_dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) async {
    final token = await _authService.getIdToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token'; // 自動付与
    }
    handler.next(options); // リクエストを続行
  },
));
```
