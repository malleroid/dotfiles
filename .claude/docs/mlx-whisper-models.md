# mlx-whisper モデル調査メモ

調査日: 2026-03-11

## モデルの取得元

- `--model` に HuggingFace のリポジトリ名を指定
- 初回実行時に自動ダウンロード、以降はキャッシュから読み込み
- キャッシュ先: `~/.cache/huggingface/hub/`

## モデル一覧

### mlx-community（公式変換・多言語対応）

| モデル | サイズ目安 | 日本語 | 備考 |
|---|---|---|---|
| `mlx-community/whisper-large-v3-turbo` | ~800MB | ◎ | 速さ×精度バランス最良 |
| `mlx-community/whisper-large-v3-mlx` | ~3GB | ◎ | 最高精度 |
| `mlx-community/whisper-large-v2-mlx-fp32` | ~3GB | ◎ | v3より旧世代 |
| `mlx-community/whisper-medium-mlx-fp32` | ~1.5GB | ○ | 中間 |
| `mlx-community/whisper-small-mlx` | ~240MB | △ | 軽量 |
| `mlx-community/whisper-base-mlx` | ~140MB | △ | 超軽量 |
| `mlx-community/whisper-tiny` | ~75MB | × | 動作確認用 |
| `mlx-community/distil-whisper-large-v3` | ~1.5GB | **英語のみ** | 英語特化・高速 |

量子化バリアント（サイズ↓・精度↓の順）: `fp32` → `8bit` → `4bit` → `q4` → `2bit`

mlx-community コレクション全体で 54 モデル以上。

### kotoba-whisper（日本語特化）

| モデル | 日本語 | 備考 |
|---|---|---|
| `kaiinui/kotoba-whisper-v2.0-mlx` | ◎ | large-v3 ベース、日本語用途では最有力 |
| `kaiinui/kotoba-whisper-v1.0-mlx` | ◎ | v1系、v2推奨 |

- large-v3 比 **6.3倍高速**、精度はほぼ同等（distil-large-v3 ベース）
- コミュニティ変換（`kaiinui` 個人）なので公式サポートなし

## 除外してよいもの

- `distil-whisper-*` — 英語専用
- `.en` サフィックス付き全般 — 英語専用

## OBS 日本語録音向け推奨

| 優先度 | モデル | 理由 |
|---|---|---|
| 第1候補 | `kaiinui/kotoba-whisper-v2.0-mlx` | 日本語特化・高速 |
| 第2候補 | `mlx-community/whisper-large-v3-turbo` | 公式変換・安定 |

## 参考リンク

- [mlx-community Whisper collection](https://huggingface.co/collections/mlx-community/whisper)
- [kaiinui/kotoba-whisper-v2.0-mlx](https://huggingface.co/kaiinui/kotoba-whisper-v2.0-mlx)
- [kotoba-tech/kotoba-whisper](https://github.com/kotoba-tech/kotoba-whisper)
