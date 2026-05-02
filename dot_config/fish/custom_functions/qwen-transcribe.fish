function qwen-transcribe --description "Transcribe audio files using mlx-qwen3-asr"
    # Model shortcuts
    set --local model_small Qwen/Qwen3-ASR-0.6B
    set --local model_small_8bit mlx-community/Qwen3-ASR-0.6B-8bit
    set --local model_small_4bit mlx-community/Qwen3-ASR-0.6B-4bit
    set --local model_large Qwen/Qwen3-ASR-1.7B
    set --local model_large_8bit mlx-community/Qwen3-ASR-1.7B-8bit
    set --local model_large_4bit mlx-community/Qwen3-ASR-1.7B-4bit

    # Defaults
    set --local model $model_large_8bit
    set --local output_dir .
    set --local audio_files

    # Parse arguments
    set --local i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case -m --model
                set i (math $i + 1)
                switch $argv[$i]
                    case small 0.6b
                        set model $model_small
                    case small-8bit 0.6b-8bit
                        set model $model_small_8bit
                    case small-4bit 0.6b-4bit
                        set model $model_small_4bit
                    case large 1.7b
                        set model $model_large
                    case large-8bit 1.7b-8bit
                        set model $model_large_8bit
                    case large-4bit 1.7b-4bit
                        set model $model_large_4bit
                    case '*'
                        set model $argv[$i]
                end
            case -o --output-dir
                set i (math $i + 1)
                set output_dir $argv[$i]
            case -h --help
                echo "Usage: qwen-transcribe [options] <audio files...>"
                echo ""
                echo "Options:"
                echo "  -m, --model <name>       Model to use (default: large-8bit)"
                echo "                           Shortcuts:"
                echo "                             small        / 0.6b"
                echo "                             small-8bit   / 0.6b-8bit"
                echo "                             small-4bit   / 0.6b-4bit"
                echo "                             large        / 1.7b"
                echo "                             large-8bit   / 1.7b-8bit"
                echo "                             large-4bit   / 1.7b-4bit"
                echo "                           Or full HuggingFace repo name"
                echo "  -o, --output-dir <path>  Output directory (default: .)"
                echo "  -h, --help               Show this help"
                echo ""
                echo "Models:"
                echo "  small        $model_small"
                echo "  small-8bit   $model_small_8bit"
                echo "  small-4bit   $model_small_4bit"
                echo "  large        $model_large"
                echo "  large-8bit   $model_large_8bit"
                echo "  large-4bit   $model_large_4bit"
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

    mlx-qwen3-asr $audio_files \
        --model $model \
        --language Japanese \
        --timestamps \
        -f json \
        -o $output_dir \
        --verbose
end
