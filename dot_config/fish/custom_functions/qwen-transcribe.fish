function qwen-transcribe --description "Transcribe audio files using mlx-qwen3-asr"
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
                echo "Usage: qwen-transcribe [options] <audio files...>"
                echo ""
                echo "Options:"
                echo "  -m, --model <name>       Model declared in ~/.config/asr/models.toml,"
                echo "                           or a HuggingFace repo name / local path"
                echo "  -o, --output-dir <path>  Output directory (default: .)"
                echo "  -h, --help               Show this help"
                echo ""
                echo "Models (aligner is used for timestamps):"
                asr-model --list mlx-qwen3-asr
                return 0
            case '*'
                set --append audio_files $argv[$i]
        end
        set i (math $i + 1)
    end

    if test (count $audio_files) -eq 0
        echo "Error: no audio files specified"
        echo "Usage: qwen-transcribe [options] <audio files...>"
        return 1
    end

    set --local model (asr-model mlx-qwen3-asr $model_name)
    or return 1
    set --local aligner (asr-model mlx-qwen3-asr aligner)
    or return 1

    mlx-qwen3-asr $audio_files \
        --model $model \
        --forced-aligner $aligner \
        --language Japanese \
        --timestamps \
        -f json \
        -o $output_dir \
        --verbose
end
