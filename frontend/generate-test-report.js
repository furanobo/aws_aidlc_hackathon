const fs = require('fs');
const lines = fs.readFileSync('test-report.json', 'utf8').trim().split('\n');
const events = lines.map(l => JSON.parse(l));

const suites = {};
const tests = {};

for (const e of events) {
  if (e.type === 'suite') suites[e.suite.id] = e.suite;
  if (e.type === 'testStart') tests[e.test.id] = { ...e.test, result: 'running' };
  if (e.type === 'testDone') {
    if (tests[e.testID]) {
      tests[e.testID].result = e.result;
      tests[e.testID].skipped = e.skipped;
    }
  }
  if (e.type === 'error' && tests[e.testID]) {
    tests[e.testID].error = e.error;
  }
}

// ファイルパスから日本語カテゴリを推定
function fileCategory(path) {
  if (path.includes('unit/')) return '🔧 ユニットテスト';
  if (path.includes('shared/')) return '🧩 共通モジュール';
  if (path.includes('features/')) return '🎮 機能テスト';
  if (path.includes('screens/')) return '📱 画面レンダリング';
  if (path.includes('golden/')) return '🖼️ ゴールデン（スナップショット）';
  if (path.includes('integration/')) return '🔗 統合テスト';
  if (path.includes('main_test')) return '🏠 アプリ起動';
  if (path.includes('router')) return '🗺️ ルーティング';
  if (path.includes('login_legal')) return '📜 法務リンク';
  if (path.includes('pixel_app_bar')) return '🎨 UIコンポーネント';
  return '📋 その他';
}

// テスト名から日本語の説明を生成
function describeTest(name, filePath) {
  // ファイル名ベースの補足
  const descs = {
    'api_client_full_test': 'APIクライアントのHTTPメソッド・URL解決・エラーハンドリング',
    'auth_logout_avatar_test': '認証状態管理・ログアウト・アバター初期作成のリトライ処理',
    'image_cache_service_test': '画像キャッシュサービスのダウンロード失敗時の挙動',
    'boot_state_test': 'アプリ起動時の状態判定（トークン有無・API応答・遷移先決定）',
    'boot_state_unit_test': '起動状態の判定ロジック（トークンなし→ログイン、API失敗→ログイン）',
    'account_tab_screen_test': 'アカウントタブ画面のメニュー項目表示',
    'battle_fight_extended_test': 'バトル画面のライフサイクル（タイマー切れまでの全フロー）',
    'battle_fight_ws_test': 'バトル画面のWebSocketメッセージ処理（battleStart受信→入力解除）',
    'battle_ws_inject_test': 'バトルのWS通信テスト（開始→ターン結果→アクション選択）',
    'login_flow_test': 'ログインフロー（成功/失敗時のUI遷移・エラーダイアログ表示）',
    'network_screens_final_test': 'フレンド検索画面（検索クエリ入力→結果表示）',
    'network_screens_test': 'フレンドリスト画面のレンダリング',
    'provider_override_test': 'ホーム画面のProvider差し替えテスト（アバター・記録データ表示）',
    'tab_screens_coverage_test': '記録タブ画面のデータ表示・カバレッジ向上',
    'mock_server_test': 'モックサーバー経由のAPI統合テスト（認証・記録・アバター・バトル）',
    'all_routes_coverage_test': '全ルートがクラッシュせずレンダリングされるか',
    'all_screens_test': '各画面の基本レンダリング確認',
    'battle_fight_test': 'バトル画面のスキルタップ・ターン進行',
    'coverage_boost_test': 'ライセンス画面の表示・タップ操作',
    'coverage_deep_test': 'バトル画面のコマンドパネル（4スキル表示）',
    'coverage_final_push_test': 'バトル画面のタイマー減少・状態遷移',
    'extra_screens_test': 'バトル招待ダイアログのレンダリング',
    'full_render_test': 'ホーム画面のフルUI表示（APIエラー時のフォールバック）',
    'router_extra_test': 'extraパラメータ付きルート（バトル結果画面等）のレンダリング',
    'screen_coverage_test': '記録タブ画面のカテゴリ表示',
    'system_screens_test': 'システム画面（エラー・メンテナンス・強制アップデート）',
    'tab_screens_test': 'ホーム・記録タブの要素表示',
    'timer_screens_test': 'タイマー付き画面（進化アニメ・バトル）のレンダリング',
    'screens_golden_test': '画面のピクセル単位スナップショット比較',
    'router_test': 'GoRouterの全ルート定義・遷移テスト',
    'main_test': 'ButaAppのMaterialApp.router起動確認',
    'login_legal_links_test': 'ログイン画面の利用規約・プライバシーリンク表示',
    'pixel_app_bar_test': 'PixelAppBarコンポーネントのレンダリング',
    'router_routes_test': 'ルート定義の網羅性チェック',
    'coverage_final_test': 'ボトムナビゲーションバーの全タブ表示',
    'ui_widgets_test': 'PixelInputウィジェットのレンダリング',
    'widgets_extra_test': 'PixelBoxウィジェットのレンダリング',
    'router_test': 'ルーター全ルートの遷移テスト',
  };

  const fileName = filePath.replace(/.*[/\\]/, '').replace('.dart', '');
  return descs[fileName] || null;
}

// Organize by file
const byFile = {};
for (const t of Object.values(tests)) {
  if (t.name === '(setUpAll)' || t.name === '(tearDownAll)') continue;
  const suite = suites[t.suiteID];
  const file = suite ? suite.path.replace(/.*[/\\]test[/\\]/, '') : 'unknown';
  if (!byFile[file]) byFile[file] = [];
  byFile[file].push(t);
}

const total = Object.values(tests).filter(t => !t.name.includes('setUpAll') && !t.name.includes('tearDownAll')).length;
const passed = Object.values(tests).filter(t => t.result === 'success').length;
const failed = Object.values(tests).filter(t => t.result === 'failure' || t.result === 'error').length;
const skipped = Object.values(tests).filter(t => t.skipped).length;

const html = `<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<title>Flutter テスト結果レポート</title>
<style>
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #f5f5f5; padding: 20px; max-width: 1200px; margin: 0 auto; }
h1 { margin-bottom: 8px; color: #333; }
h2 { margin: 24px 0 12px; color: #555; border-bottom: 2px solid #ddd; padding-bottom: 8px; }
.summary { display: flex; gap: 16px; margin-bottom: 24px; flex-wrap: wrap; }
.card { background: white; border-radius: 8px; padding: 16px 24px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); text-align: center; min-width: 120px; }
.card .num { font-size: 2em; font-weight: bold; }
.card.pass .num { color: #22c55e; }
.card.fail .num { color: #ef4444; }
.card.skip .num { color: #f59e0b; }
.card.total .num { color: #3b82f6; }
.card .label { color: #666; font-size: 0.9em; margin-top: 4px; }
.file-section { background: white; border-radius: 8px; margin-bottom: 12px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); overflow: hidden; }
.file-header { padding: 12px 16px; background: #f8f9fa; border-bottom: 1px solid #eee; font-weight: bold; cursor: pointer; display: flex; justify-content: space-between; align-items: center; }
.file-header:hover { background: #e9ecef; }
.file-desc { padding: 8px 16px; background: #f0f7ff; color: #1e40af; font-size: 0.85em; border-bottom: 1px solid #e0e7ff; }
.file-header .badge { font-size: 0.8em; padding: 2px 8px; border-radius: 12px; color: white; }
.badge-pass { background: #22c55e; }
.badge-fail { background: #ef4444; }
.test-list { list-style: none; }
.test-item { padding: 8px 16px; border-bottom: 1px solid #f0f0f0; display: flex; align-items: center; gap: 8px; font-size: 0.9em; }
.test-item:last-child { border-bottom: none; }
.icon { width: 20px; text-align: center; flex-shrink: 0; }
.test-name { flex: 1; }
.error-msg { background: #fef2f2; color: #991b1b; padding: 8px 16px 8px 44px; font-family: monospace; font-size: 0.8em; white-space: pre-wrap; word-break: break-all; max-height: 120px; overflow-y: auto; border-bottom: 1px solid #fecaca; }
.timestamp { color: #999; margin-bottom: 20px; }
.category-header { margin-top: 32px; padding: 8px 0; font-size: 1.2em; color: #333; }
</style>
</head>
<body>
<h1>🐷 ぶたそだて Flutter テスト結果</h1>
<p class="timestamp">実行日時: ${new Date().toLocaleString('ja-JP', { timeZone: 'Asia/Tokyo' })}</p>

<div class="summary">
  <div class="card total"><div class="num">${total}</div><div class="label">合計</div></div>
  <div class="card pass"><div class="num">${passed}</div><div class="label">成功</div></div>
  <div class="card fail"><div class="num">${failed}</div><div class="label">失敗</div></div>
  <div class="card skip"><div class="num">${skipped}</div><div class="label">スキップ</div></div>
</div>

${(() => {
  // Group by category
  const categories = {};
  for (const [file, fileTests] of Object.entries(byFile)) {
    const cat = fileCategory(file);
    if (!categories[cat]) categories[cat] = [];
    categories[cat].push([file, fileTests]);
  }
  
  return Object.entries(categories).map(([cat, files]) => {
    return `<h2>${cat}</h2>\n` + files.sort(([a],[b]) => a.localeCompare(b)).map(([file, tests]) => {
      const fileFailed = tests.some(t => t.result === 'failure' || t.result === 'error');
      const badge = fileFailed ? '<span class="badge badge-fail">FAIL</span>' : '<span class="badge badge-pass">PASS</span>';
      const desc = describeTest(null, file);
      const descHtml = desc ? `<div class="file-desc">💡 ${desc}</div>` : '';
      return `<details class="file-section" ${fileFailed ? 'open' : ''}>
  <summary class="file-header"><span>${file}</span> ${badge}</summary>
  ${descHtml}
  <ul class="test-list">
${tests.map(t => {
  const icon = t.skipped ? '⚠️' : (t.result === 'success' ? '✅' : '❌');
  const err = t.error ? `\n<div class="error-msg">${t.error.replace(/</g,'&lt;').substring(0, 400)}</div>` : '';
  return `    <li class="test-item"><span class="icon">${icon}</span><span class="test-name">${t.name.replace(/</g,'&lt;')}</span></li>${err}`;
}).join('\n')}
  </ul>
</details>`;
    }).join('\n');
  }).join('\n');
})()}

</body>
</html>`;

fs.writeFileSync('test-report.html', html);
console.log('Generated: test-report.html (' + total + ' tests)');
