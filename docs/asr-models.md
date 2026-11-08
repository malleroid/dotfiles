# ASR models

The speech recognition models used by the transcription fish functions are
declared in one file, `dot_config/asr/models.toml` (deployed to
`~/.config/asr/models.toml`), instead of being named inside each function and
fetched implicitly on first use.

| Function | Engine (table) | Runtime |
|---|---|---|
| `mlx-transcribe` | `mlx-whisper` | `pipx:mlx-whisper` (mise) |
| `qwen-transcribe` | `mlx-qwen3-asr` | `pipx:mlx-qwen3-asr` (mise) |
| `haas-transcribe` | `speech-cpp` | `github:nyosegawa/speech.cpp` (mise) |

Each function resolves `-m <name>` (or the table's `default`) through
`asr-model <engine> [name]`, which reads the file with `dasel` and `jq`.
`asr-model --list <engine>` prints the declared models; each function's `-h`
shows the same list. A name that is not declared but contains `/` or `~` is
passed through as a repository id or path, unpinned.

## Speaker turns

`haas-transcribe -d` adds `--diarize` (the `speech-cpp.diarize` model) to the
recognition and runs the output through `dot_config/asr/diarize-turns.jq`.
Each region gets `dominant_speaker` and `turns` ({speaker, start, end, text}),
and the top level gets all turns with consecutive same-speaker turns joined, so
later steps can read the turns without the token timings.

Within a region:

1. A token goes to the speaker interval containing its midpoint (largest
   overlap first, else the nearest interval; ties go to the lower speaker id).
2. A turn shorter than 0.5 s (`min_sec`) is absorbed into a neighbour: the one
   of the region's `dominant_speaker` if only one neighbour is, else the longer.
3. A region left with one turn takes the `dominant_speaker`.

To tune the threshold without recognizing again, keep speech.cpp's own output
and rerun the filter on it:

```sh
speech asr haas-ja-v1.0 --format json --timestamps --vad silero-vad \
  --diarize nemotron-3-diarization meeting.wav >meeting.raw.json
jq --argjson min_sec 0.3 -f ~/.config/asr/diarize-turns.jq meeting.raw.json
```

Character-count absorption, A / B / A absorption and moving boundaries to
punctuation were tried and dropped: they were tuned on one recording, absorbed
genuine short replies, and changed little at the region level.

## Sources and pinning

| Source | Stored in | Pinned by |
|---|---|---|
| `hf:<repo>` | Hugging Face cache (`~/.cache/huggingface/hub`, or `$HF_HUB_CACHE` / `$HF_HOME/hub`) | `revision`, a commit sha. The function passes the `snapshots/<sha>` directory as a path, since neither MLX CLI takes a revision |
| `local:<path>` | the given path | not pinned; `from` and `build` say how it was made |
| `speech:<name>[:<type>]` | `~/.cache/speech.cpp/models`, set by `SPEECH_MODEL_DIR` in `config.fish` (speech.cpp's own default is `~/Library/Caches/speech.cpp/models`) | the speech.cpp version pinned in `dot_config/mise/config.toml`; each release fixes the revision it fetches |

## Fetching and removing

Nothing is fetched implicitly for `hf:` sources: a missing snapshot fails with
the `hf download <repo> --revision <sha>` command to run. `hf` comes from
`python3Packages.huggingface-hub` in `flake.nix`.

speech.cpp models are fetched on first use, or ahead with `speech pull <name>`.
`speech models` shows what is fetched, `speech rm <name>` removes one, and
`speech rm --old` removes files no model of the installed release names.

Old Hugging Face snapshots are not removed automatically; `hf cache` lists and
deletes them.

To change a pinned revision, update `revision` and download the new snapshot.
Look up the current sha with `https://huggingface.co/api/models/<repo>` (`sha`).

## Quantized Qwen3-ASR

mlx-community's pre-quantized Qwen3-ASR variants ship the audio tower
unquantized while `config.json` declares full quantization, so the loader fails
on missing `.scales` / `.biases`. Use the 8-bit artifacts published by the
mlx-qwen3-asr author (`moona3k/mlx-qwen3-asr-*-8bit`, mlx-qwen3-asr 0.4.3 or
later) instead.
