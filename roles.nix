{
  pkgs,
  inputs',
  ...
} @ args: let
  custom = import ./custom-pkgs.nix args;

  exp = let
  in [
  ];

  # minimal system rescue kit
  raw = [
    pkgs.ripgrep # grep alternative
    pkgs.fd # find alternative
    pkgs.fzf # fzf finder
    pkgs.jq # json processor cli
    pkgs.ouch # archives
    pkgs.zoxide # cd may be overriden
    pkgs.eza # ls may be overriden
    pkgs.curl # web data transfer

    # Diagnostics
    pkgs.bottom
    pkgs.systemctl-tui
    pkgs.dua # rust space usage list, for mass deletions

    # Nix tooling
    inputs'.nix-index-database.packages.comma-with-db

    # Version control and docs
    pkgs.git
    pkgs.jujutsu # glorious git alternative
    pkgs.tealdeer # tldr for docs

    # editors & navigation
    pkgs.neovim
    pkgs.micro
    pkgs.yazi
  ];

  # Everything essential, small and cached
  main =
    raw
    ++ [
      # Core core
      pkgs.starship
      pkgs.trash-cli
      pkgs.translate-shell # Provides trans
      pkgs.ugrep

      # Diagnostics
      pkgs.gdu # space usage list
      pkgs.hyperfine # benchmark app

      # systemd managers
      pkgs.systemd-manager-tui
      pkgs.sysz

      pkgs.grc # colorizer
      pkgs.ripdrag #

      # Nix tooling
      inputs'.nix-index-database.packages.nix-index-with-small-db

      # Version control
      inputs'.jj-pin.legacyPackages.jj-fzf
      inputs'.jj-pin.legacyPackages.jujutsu
      # pkgs.jujutsu
      # pkgs.jj-fzf

      # Terminals
      pkgs.foot
      pkgs.alacritty
      pkgs.ghostty

      # Wayland stuff
      custom.satty-screenshot
      custom.script-spam
      pkgs.grim
      pkgs.slurp
      pkgs.satty
      pkgs.wl-clipboard
      pkgs.wl-clip-persist
      pkgs.wtype

      # Hardware & system controls
      pkgs.wluma
      pkgs.brightnessctl
      pkgs.amdgpu_top
      pkgs.networkmanagerapplet
      pkgs.libnotify

      # Apps (lightweight & system helpers)
      pkgs.nautilus
      pkgs.matugen
      pkgs.udiskie
      (
        let
          nix-search-tv = inputs'.nix-search-tv.packages.default;
        in (pkgs.writeShellApplication
          {
            name = "ns";
            runtimeInputs = with pkgs; [
              fzf
              nix-search-tv
            ];
            text = builtins.readFile "${nix-search-tv.src}/nixpkgs.sh";
          })
      )
      pkgs.hyprpicker
      pkgs.xdg-utils # Provides xdg-open
      pkgs.wooz

      # Editors
      (pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
        plugins = with pkgs.vimPlugins; [
          # tokyonight-nvim
        ];
        luaRcContent = ''
          vim.cmd("packloadall!")
          local config_path = (os.getenv("HOME") or "") .. "/.config/nvim/init.lua"
          if vim.uv.fs_stat(config_path) then
            dofile(config_path)
          end
        '';
      })
      # pkgs.nixd ...

      pkgs.neovide

      # Workflow and config
      pkgs.just
      pkgs.dotter
      pkgs.home-manager

      # Nix
      pkgs.npins
      pkgs.nix-init
      pkgs.nix-inspect
      pkgs.nix-melt
      inputs'.riptide.packages.drvinter
      pkgs.alejandra
      pkgs.nixd

      # Python
      pkgs.uv
      pkgs.pyright

      # Lua
      pkgs.lua51Packages.lua
      pkgs.lua51Packages.luarocks
      pkgs.lua-language-server
      pkgs.stylua

      # Misc toolchains & formatters
      pkgs.tree-sitter
      pkgs.shfmt
      pkgs.fixjson

      # Video and anime playback
      custom.mpv-custom
      pkgs.imv
      pkgs.decibels
      pkgs.ani-cli

      # Audio plumbing & controls
      pkgs.pavucontrol
      pkgs.easyeffects
      pkgs.coppwr
      pkgs.pamixer
      pkgs.playerctl
      inputs'.hijacker.packages.hijacker
      custom.hijacker-ctl

      # Documents & markup
      pkgs.typst
      pkgs.tinymist
      pkgs.typstyle
      pkgs.pandoc
      pkgs.zathura
      pkgs.vale
      pkgs.mdformat

      # Image / Media CLI primitives
      pkgs.tesseract
      pkgs.imagemagick
      pkgs.zbar
      pkgs.ffmpeg # Provides both ffmpeg and ffprobe
    ];

  # Heavy stuff, rare updates
  max = [
    # Browsers
    inputs'.zen-browser.packages.default
    pkgs.chromium
    # pkgs.dillo
    # pkgs.tor-browser

    # Communication
    pkgs.vesktop
    pkgs.telegram-desktop
    pkgs.thunderbird
    (pkgs.discord.override {withOpenASAR = true;})

    # Screen recorder
    pkgs.gpu-screen-recorder-gtk

    # Heavy Editors
    pkgs.zed-editor
    pkgs.vscode

    # C / C++
    pkgs.gnumake
    pkgs.llvmPackages.clang-tools
    pkgs.llvmPackages.clang
    pkgs.llvmPackages.lldb

    # Misc toolchains
    pkgs.openjdk21
    pkgs.vial

    # Video players
    pkgs.vlc

    # Audio apps
    # custom.spotify-spiced
    pkgs.spotify

    # Documents
    pkgs.obsidian
    pkgs.affine
    pkgs.onlyoffice-desktopeditors

    # Media acquisition & creation
    pkgs.krita
    pkgs.nomacs
    # pkgs.blender
    pkgs.qbittorrent

    # Tools / compatibility layers
    pkgs.mangohud
    pkgs.bottles
    pkgs.protontricks
    pkgs.r2modman

    # Launchers
    pkgs.heroic
    pkgs.faugus-launcher

    # Minecraft
    pkgs.packwiz
    inputs'.freesm-launcher.packages.default

    inputs'.nur.legacyPackages.repos.gepbird.drg-mint-notag
  ];
in {
  # Bundles (nix profile install .#<name>)
  inherit
    main
    max
    exp
    ;

  default = main;

  # Emergency shell (nix shell .#raw)
  inherit raw;

  # Dev shell exposure (nix develop .#raw)
  devShells.raw = pkgs.mkShellNoCC {packages = raw;};
}
