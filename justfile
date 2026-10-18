export NIXPKGS_ALLOW_UNFREE := "1"

set shell := ["bash", "-euo pipefail", "-c"]

fzf := "fzf --height=45% --layout=reverse --border=rounded --info=inline --pointer='▶ ' --marker='✓ '"

# Interactive menu
[private]
default:
    #!/usr/bin/env bash
    set -euo pipefail
    sys=$(nix eval --impure --raw --expr 'builtins.currentSystem')
    flake_dir=$(pwd -P)

    while true; do
        lock_info=$(jq -r '
            (.nodes.root.inputs.nixpkgs | if type == "array" then .[0] else . end) as $k |
            (.nodes[$k].locked // {}) as $np |
            "nixpkgs: \(($np.rev // "unknown")[0:7]) (\(($np.lastModified // 0) | todate[0:10]))"
        ' flake.lock 2>/dev/null || echo "no flake.lock")

        installed=$(nix profile list --json | jq -r --arg dir "$flake_dir" --arg sys "$sys" '
            .elements | to_entries[]
            | select((.value.originalUrl // "" | endswith($dir)) or (.value.url // "" | endswith($dir)))
            | "\(.value.attrPath | sub("^packages\\." + $sys + "\\."; ""))\t\(.value.storePaths[0])"
        ')

        menu=$(printf "[install]  Select bundles\n[install]  All bundles\n[upgrade]  All installed\n[remove]   All installed\n[flake]    Update inputs\n")
        if [ -n "$installed" ]; then
            while IFS=$'\t' read -r b spath; do
                drv=$(basename "$spath" | cut -c1-7)
                reg=$(nix path-info --json "$spath" 2>/dev/null | jq -r '
                    (if type == "array" then .[0].registrationTime else to_entries[0].value.registrationTime end)
                    | if . then todate[0:10] else "unknown" end
                ' || echo "unknown")
                menu=$(printf "%s\nbundle     %-14s [drv:%s | installed:%s | %s]" "$menu" "$b" "$drv" "$reg" "$lock_info")
            done <<< "$installed"
        fi

        choice=$(printf "%s\n" "$menu" | {{fzf}} --header="Lock -> $lock_info" --prompt="Menu > " || true)
        [ -z "$choice" ] && exit 0

        case "$choice" in
            "[install]  Select bundles") just install ;;
            "[install]  All bundles")    just install all ;;
            "[upgrade]  All installed")  just upgrade all ;;
            "[remove]   All installed")   just remove all ;;
            "[flake]    Update inputs")  just flake-update ;;
            bundle*)
                b=$(awk '{print $2}' <<< "$choice")
                info=$(cut -d'[' -f2- <<< "$choice" | tr -d ']')
                act=$(printf "upgrade\nremove\nback\n" | {{fzf}} --header="$b ($info)" --prompt="$b > " || true)
                case "$act" in
                    upgrade) just upgrade "$b" ;;
                    remove)  just remove "$b" ;;
                esac
                ;;
        esac
    done

# Update flake inputs ('all', names, or interactive with lock info)
flake-update *inputs:
    #!/usr/bin/env bash
    set -euo pipefail
    targets="{{inputs}}"
    if [ "$targets" = "all" ]; then
        read -rp "Update ALL flake inputs? [y/N] " ans
        [[ ! "$ans" =~ ^[Yy]$ ]] && exit 0
        nix flake update --impure
        exit 0
    elif [ -z "$targets" ]; then
        lines=$(jq -r '
            .nodes as $nodes |
            .nodes.root.inputs | to_entries[] |
            .key as $name |
            (if (.value | type) == "array" then .value[-1] else .value end) as $node_key |
            ($nodes[$node_key].locked // {}) as $l |
            ($nodes[$node_key].original // {}) as $o |
            "\($name)\t\($l.owner // $o.owner // $l.type // "input")/\($l.repo // $o.repo // "")\t\(($l.rev // "unknown")[0:7])\t\(if $l.lastModified then ($l.lastModified | todate[0:10]) else "unknown" end)"
        ' flake.lock | column -t -s $'\t')
        picked=$(printf "ALL\n%s\n" "$lines" | {{fzf}} --multi --prompt="Update Input(s) > " || true)
        [ -z "$picked" ] && exit 0
        if grep -qx "ALL" <<< "$picked"; then
            read -rp "Update ALL flake inputs? [y/N] " ans
            [[ ! "$ans" =~ ^[Yy]$ ]] && exit 0
            nix flake update --impure
            exit 0
        fi
        targets=$(awk '{print $1}' <<< "$picked")
    fi
    read -ra arr <<< $(echo "$targets" | tr '\n' ' ')
    nix flake update --impure "${arr[@]}"

# Install bundles ('all', names, or interactive)
install *bundles:
    #!/usr/bin/env bash
    set -euo pipefail
    sys=$(nix eval --impure --raw --expr 'builtins.currentSystem')
    flake_dir=$(pwd -P)

    all=$(nix eval ".#packages.$sys" --apply 'builtins.attrNames' --json | jq -r '.[]')
    installed=$(nix profile list --json | jq -r --arg dir "$flake_dir" --arg sys "$sys" '
        .elements | to_entries[]
        | select((.value.originalUrl // "" | endswith($dir)) or (.value.url // "" | endswith($dir)))
        | (.value.attrPath | sub("^packages\\." + $sys + "\\."; ""))
    ')
    available=$(comm -23 <(echo "$all" | sort) <(echo "$installed" | sort))

    targets="{{bundles}}"
    if [ "$targets" = "all" ]; then
        [ -z "$available" ] && echo "Nothing left to install." && exit 0
        read -rp "Install ALL available bundles ($(tr '\n' ' ' <<< "$available"))? [y/N] " ans
        [[ ! "$ans" =~ ^[Yy]$ ]] && exit 0
        targets="$available"
    elif [ -z "$targets" ]; then
        [ -z "$available" ] && echo "Nothing left to install." && exit 0
        targets=$(printf "ALL\n%s\n" "$available" | {{fzf}} --multi --prompt="Install > " || true)
        [ -z "$targets" ] && exit 0
        if grep -qx "ALL" <<< "$targets"; then
            read -rp "Install ALL available bundles ($(tr '\n' ' ' <<< "$available"))? [y/N] " ans
            [[ ! "$ans" =~ ^[Yy]$ ]] && exit 0
            targets="$available"
        fi
    fi

    pkgs=()
    for b in $targets; do
        grep -qx "$b" <<< "$installed" && continue
        pkgs+=(".#$b")
    done
    [ ${#pkgs[@]} -eq 0 ] && exit 0
    nix profile install --impure "${pkgs[@]}"

# Upgrade installed bundles ('all', names, or interactive)
upgrade *bundles:
    #!/usr/bin/env bash
    set -euo pipefail
    sys=$(nix eval --impure --raw --expr 'builtins.currentSystem')
    flake_dir=$(pwd -P)

    map=$(nix profile list --json | jq -r --arg dir "$flake_dir" --arg sys "$sys" '
        .elements | to_entries[]
        | select((.value.originalUrl // "" | endswith($dir)) or (.value.url // "" | endswith($dir)))
        | "\(.value.attrPath | sub("^packages\\." + $sys + "\\."; ""))\t\(.key)"
    ')
    [ -z "$map" ] && exit 0

    targets="{{bundles}}"
    if [ "$targets" = "all" ]; then
        read -rp "Upgrade ALL installed bundles? [y/N] " ans
        [[ ! "$ans" =~ ^[Yy]$ ]] && exit 0
        keys=$(awk '{print $2}' <<< "$map")
    elif [ -z "$targets" ]; then
        picked=$(printf "ALL\n%s\n" "$(awk '{print $1}' <<< "$map")" | {{fzf}} --multi --prompt="Upgrade > " || true)
        [ -z "$picked" ] && exit 0
        if grep -qx "ALL" <<< "$picked"; then
            read -rp "Upgrade ALL installed bundles? [y/N] " ans
            [[ ! "$ans" =~ ^[Yy]$ ]] && exit 0
            keys=$(awk '{print $2}' <<< "$map")
        else
            keys=$(grep -F -f <(sed 's/$/\t/' <<< "$picked") <<< "$map" | awk '{print $2}')
        fi
    else
        keys=$(grep -F -f <(printf "%s\n" $targets | sed 's/$/\t/') <<< "$map" | awk '{print $2}')
    fi

    read -ra arr <<< $(echo "$keys" | tr '\n' ' ')
    [ ${#arr[@]} -eq 0 ] && exit 0
    nix profile upgrade --impure "${arr[@]}"

# Remove installed bundles ('all', names, or interactive)
remove *bundles:
    #!/usr/bin/env bash
    set -euo pipefail
    sys=$(nix eval --impure --raw --expr 'builtins.currentSystem')
    flake_dir=$(pwd -P)

    map=$(nix profile list --json | jq -r --arg dir "$flake_dir" --arg sys "$sys" '
        .elements | to_entries[]
        | select((.value.originalUrl // "" | endswith($dir)) or (.value.url // "" | endswith($dir)))
        | "\(.value.attrPath | sub("^packages\\." + $sys + "\\."; ""))\t\(.key)"
    ')
    [ -z "$map" ] && exit 0

    targets="{{bundles}}"
    if [ "$targets" = "all" ]; then
        read -rp "Remove ALL installed bundles? [y/N] " ans
        [[ ! "$ans" =~ ^[Yy]$ ]] && exit 0
        keys=$(awk '{print $2}' <<< "$map")
    elif [ -z "$targets" ]; then
        picked=$(printf "ALL\n%s\n" "$(awk '{print $1}' <<< "$map")" | {{fzf}} --multi --prompt="Remove > " || true)
        [ -z "$picked" ] && exit 0
        if grep -qx "ALL" <<< "$picked"; then
            read -rp "Remove ALL installed bundles? [y/N] " ans
            [[ ! "$ans" =~ ^[Yy]$ ]] && exit 0
            keys=$(awk '{print $2}' <<< "$map")
        else
            keys=$(grep -F -f <(sed 's/$/\t/' <<< "$picked") <<< "$map" | awk '{print $2}')
        fi
    else
        keys=$(grep -F -f <(printf "%s\n" $targets | sed 's/$/\t/') <<< "$map" | awk '{print $2}')
    fi

    read -ra arr <<< $(echo "$keys" | tr '\n' ' ')
    [ ${#arr[@]} -eq 0 ] && exit 0
    nix profile remove "${arr[@]}"
