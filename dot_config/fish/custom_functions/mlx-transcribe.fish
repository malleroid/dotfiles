function mlx-transcribe --description "Transcribe audio files using mlx-whisper"
    set --local model_name
    set --local output_dir .
    set --local audio_files

    # Parse arguments
    set --local i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case -m --model
                set i (math $i + 1)
                set model_name $argv[$i]
            case -o --output-dir
                set i (math $i + 1)
                set output_dir $argv[$i]
            case -h --help
                echo "Usage: mlx-transcribe [options] <audio files...>"
                echo ""
                echo "Options:"
                echo "  -m, --model <name>       Model declared in ~/.config/asr/models.toml,"
                echo "                           or a HuggingFace repo name / local path"
                echo "  -o, --output-dir <path>  Output directory (default: .)"
                echo "  -h, --help               Show this help"
                echo ""
                echo "Models:"
                asr-model --list mlx-whisper
                return 0
            case '*'
                set --append audio_files $argv[$i]
        end
        set i (math $i + 1)
    end

    if test (count $audio_files) -eq 0
        echo "Error: no audio files specified"
        echo "Usage: mlx-transcribe [options] <audio files...>"
        return 1
    end

    set --local model (asr-model mlx-whisper $model_name)
    or return 1

    mlx_whisper $audio_files \
        --model $model \
        --language Japanese \
        --condition-on-previous-text False \
        --output-format json \
        --output-dir $output_dir \
        --verbose True
end
