{
  pkgs,
  inputs',
  ...
}: let
  spicePkgs = inputs'.spicetify-nix.legacyPackages;

  spotify-spiced = inputs'.spicetify-nix.lib.mkSpicetify pkgs {
    spotifyPackage = pkgs.spotify;

    theme = {
      name = "Blackout";
      src = "${pkgs.fetchFromGitHub {
        owner = "spicetify";
        repo = "spicetify-themes";
        rev = "a9ce22b3d3df303d994974b746c839c7d0907101";
        sha256 = "sha256-HQJrCB5kN8mE4yzC6Sc0Dh7mpttoAGIx3cvlNGnkPvc=";
      }}/Blackout";
    };
    colorScheme = "def";

    enabledExtensions = with spicePkgs.extensions; [
      # shuffle
      # fullAlbumDate
      # showQueueDuration
      # history
      # hidePodcasts
      # playNext
      # volumePercentage
    ];

    enabledCustomApps = with spicePkgs.apps; [
      # lyricsPlus
      # ncsVisualizer
    ];
  };

  mpv-custom = pkgs.mpv.override {
    scripts = with pkgs.mpvScripts; [
      uosc
      sponsorblock
    ];
  };

  satty-screenshot = pkgs.writeShellScriptBin "satty-screenshot" ''
    set -e
    SCREENSHOT_DIR=~/Pictures/screenshots
    ${pkgs.coreutils}/bin/mkdir -p "$SCREENSHOT_DIR"
    ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.satty}/bin/satty -f - \
      -o "$SCREENSHOT_DIR/screenshot-$(${pkgs.coreutils}/bin/date +'%Y-%m-%d_%H-%M-%S').png" \
      --early-exit \
      --save-after-copy \
      --actions-on-enter save-to-clipboard \
      --copy-command '${pkgs.wl-clipboard}/bin/wl-copy' \
      --initial-tool brush \
      --no-window-decoration
  '';

  hijacker2 = pkgs.rustPlatform.buildRustPackage {
    pname = "hijacker2";
    version = "0.1.0";

    src = pkgs.fetchFromGitHub {
      owner = "chilipizdrick";
      repo = "hijacker2";
      rev = "master";
      hash = "sha256-fk+Nt5Mq7sDJAfmkScMwpavVWsEVqC5mhDYsG1bp1F4=";
    };

    cargoHash = "sha256-mJb/Vf1ayF1I0NRWUracjy4/bkqvlAWEjufyW0Fr3Xg";

    nativeBuildInputs = [
      pkgs.pkg-config
      pkgs.rustPlatform.bindgenHook
    ];

    buildInputs = [
      pkgs.pipewire
    ];
  };

  clever-hijacker = pkgs.writeShellScriptBin "clever-hijacker" ''
    set -e

    if ${pkgs.pipewire}/bin/pw-dump | ${pkgs.gnugrep}/bin/grep -q "$1"; then
      ${hijacker2}/bin/hijacker2 -a "$1" "$2"
    else
      ${hijacker2}/bin/hijacker2 "$2"
    fi
  '';

  hijacker-ctl = pkgs.writeShellScriptBin "hijacker-ctl" ''
    STATE_FILE="''${XDG_RUNTIME_DIR:-/tmp}/hijacker_enabled"

    case "$1" in
      toggle)
        if [ -f "$STATE_FILE" ]; then
          rm -f "$STATE_FILE"
          noctalia msg notification-show 'Hijacker' 'Disabled'
        else
          touch "$STATE_FILE"
          noctalia msg notification-show 'Hijacker' 'Enabled'
        fi
        ;;
      play)
        if [ -f "$STATE_FILE" ]; then
          ${clever-hijacker}/bin/clever-hijacker 'easyeffects_source' "$HOME/Music/hijacker-presets/$2.mp3"
        fi
        ;;
      *)
        exit 1
        ;;
    esac
  '';

  script-spam = pkgs.writeShellScriptBin "spam" ''
    cat ~/spam.txt | ${pkgs.wl-clipboard}/bin/wl-copy \
      && ${pkgs.libnotify}/bin/notify-send "Propaganda" "ready to spread!" \
      && sleep 0.3 \
      && ${pkgs.lib.getExe pkgs.wtype} -M ctrl -M shift -k v -m shift -m ctrl -s 300 -k Return
  '';
in {
  inherit
    spotify-spiced
    mpv-custom
    satty-screenshot
    hijacker2
    clever-hijacker
    hijacker-ctl
    script-spam
    ;

  hijacker-tools = [
    hijacker2
    clever-hijacker
    hijacker-ctl
  ];
}
