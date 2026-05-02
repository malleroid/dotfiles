function mlx-transcribe --description "Transcribe audio files using mlx-whisper"
    # Model shortcuts
    set --local model_kotoba kaiinui/kotoba-whisper-v2.0-mlx
    set --local model_turbo mlx-community/whisper-large-v3-turbo
    set --local model_large mlx-community/whisper-large-v3-mlx

    # Defaults
    set --local model $model_turbo
    set --local output_dir .
    set --local audio_files

    # Parse arguments
    set --local i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case -m --model
                set i (math $i + 1)
                switch $argv[$i]
                    case kotoba
                        set model $model_kotoba
                    case turbo
                        set model $model_turbo
                    case large
                        set model $model_large
                    case '*'
                        set model $argv[$i]
                end
            case -o --output-dir
                set i (math $i + 1)
                set output_dir $argv[$i]
            case -h --help
                echo "Usage: mlx-transcribe [options] <audio files...>"
                echo ""
                echo "Options:"
                echo "  -m, --model <name>       Model to use (default: turbo)"
                echo "                           Shortcuts: kotoba, turbo, large"
                echo "                           Or full HuggingFace repo name"
                echo "  -o, --output-dir <path>  Output directory (default: .)"
                echo "  -h, --help               Show this help"
                echo ""
                echo "Models:"
                echo "  kotoba  $model_kotoba"
                echo "  turbo   $model_turbo"
                echo "  large   $model_large"
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

    mlx_whisper $audio_files \
        --model $model \
        --language Japanese \
        --condition-on-previous-text False \
        --output-format json \
        --output-dir $output_dir \
        --verbose True
end
