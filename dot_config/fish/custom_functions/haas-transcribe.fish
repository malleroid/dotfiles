function haas-transcribe --description "Transcribe audio files using speech.cpp (Haas-ja by default)"
    set --local model_name
    set --local output_dir .
    set --local keywords
    set --local use_vad 1
    set --local use_diarize 0
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
            case -k --keyword
                set i (math $i + 1)
                set --append keywords $argv[$i]
            case --no-vad
                set use_vad 0
            case -d --diarize
                set use_diarize 1
            case -h --help
                echo "Usage: haas-transcribe [options] <audio files...>"
                echo ""
                echo "Options:"
                echo "  -m, --model <name>       Model declared in ~/.config/asr/models.toml,"
                echo "                           or a speech.cpp NAME[:TYPE] / .gguf path"
                echo "  -o, --output-dir <path>  Output directory (default: .)"
                echo "  -k, --keyword <word>     Boost a keyword, as WORD or WORD=reading (repeatable)."
                echo "                           Output has no timestamps when keywords are given"
                echo "      --no-vad             Recognize each file whole instead of by speech regions"
                echo "  -d, --diarize            Label each speech region with its speakers (needs VAD)"
                echo "                           and split it into speaker turns (top-level turns[])"
                echo "  -h, --help               Show this help"
                echo ""
                echo "Models (vad finds speech regions, diarize finds speakers):"
                asr-model --list speech-cpp
                return 0
            case '*'
                set --append audio_files $argv[$i]
        end
        set i (math $i + 1)
    end

    if test (count $audio_files) -eq 0
        echo "Error: no audio files specified"
        echo "Usage: haas-transcribe [options] <audio files...>"
        return 1
    end

    if test $use_diarize -eq 1 -a $use_vad -eq 0
        echo "Error: --diarize needs VAD; drop --no-vad"
        return 1
    end

    set --local model (asr-model speech-cpp $model_name)
    or return 1

    set --local args asr $model --format json
    if test $use_vad -eq 1
        set --append args --vad (asr-model speech-cpp vad)
        or return 1
    end
    if test $use_diarize -eq 1
        set --append args --diarize (asr-model speech-cpp diarize)
        or return 1
    end
    if test (count $keywords) -gt 0
        set --append args --keywords (string join \n -- $keywords)
    else
        set --append args --timestamps
    end

    mkdir -p $output_dir
    set --local tmp (mktemp -d -t haas-transcribe)
    set --local failed 0
    for file in $audio_files
        set --local base (path change-extension '' (path basename -- $file))
        set --local wav $tmp/$base.wav
        echo "==> $file"
        if not ffmpeg -hide_banner -loglevel error -y -i $file -ar 16000 -ac 1 $wav
            set failed 1
            continue
        end
        if test $use_diarize -eq 0
            speech $args $wav >$output_dir/$base.json
            or set failed 1
        else if speech $args $wav >$tmp/$base.json
            jq -f ~/.config/asr/diarize-turns.jq $tmp/$base.json >$output_dir/$base.json
            or set failed 1
        else
            set failed 1
        end
    end
    rm -r $tmp
    return $failed
end
