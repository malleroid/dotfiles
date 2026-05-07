function _tp_connect_plist -d "Locate the TablePlus Connections.plist (App Store / standalone)"
    set -l candidates \
        "$HOME/Library/Application Support/com.tinyapp.TablePlus/Data/Connections.plist" \
        "$HOME/Library/Containers/com.tinyapp.TablePlus/Data/Library/Application Support/com.tinyapp.TablePlus/Data/Connections.plist"

    for c in $candidates
        if test -r "$c"
            echo $c
            return 0
        end
    end

    for c in $HOME/Library/Group\ Containers/*.com.tinyapp.TablePlus/Data/Connections.plist
        if test -r "$c"
            echo $c
            return 0
        end
    end

    return 1
end
