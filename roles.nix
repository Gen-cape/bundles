{
  pkgs,
  inputs',
  ...
} @ args: let
  custom = import ./custom-pkgs.nix args;

  exp = let
  in [
    # special

    # cli

    # gui

    # inbox
  ];

  # minimal system rescue kit
  raw = [
    # special

    # cli
    pkgs.ripgrep # grep alternative
    pkgs.fd # find alternative
    pkgs.rip2 # rm alternative
    pkgs.fzf # fzf finder
    pkgs.jq # json processor cli
    pkgs.ouch # archives
    pkgs._7zz # fallback for tricky archives, nix shell nixpkgs#_7zip-zstd-rar if mega obscure
    pkgs.zoxide # cd may be overriden
    pkgs.eza # ls may be overriden
    pkgs.curl # web data transfer
    pkgs.bottom # process management
    pkgs.dua # rust space usage list, for mass deletions
    pkgs.sysz # systemd management
    pkgs.psmisc # fuser to see what locks stuff
    pkgs.gitMinimal
    pkgs.just # command runner for projects and helpers
    pkgs.tealdeer # tldr for docs
    # pkgs.neovim # comfy and reliable editor, esp with own config
    pkgs.neovim-unwrapped # without wl-clipboard and other stuff not needed in emergency
    pkgs.micro # if nvim is cooked, its a better nano

    # gui

    # inbox
  ];

  # Everything essential, small and cached
  main =
    raw
    ++ [
      # special
      inputs'.nix-index-database.packages.comma-with-db # so I can ", program", handy
      custom.script-spam
      custom.mpv-custom
      custom.hijacker-ctl
      inputs'.jj-pin.legacyPackages.jj-fzf # jj fzf breaks with fresh jj
      inputs'.jj-pin.legacyPackages.jujutsu
      # pkgs.jujutsu
      # pkgs.jj-fzf
      inputs'.riptide.packages.drvinter # my custom script to guide through package phases
      inputs'.hijacker.packages.hijacker
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
      ) # home manager, nixos options and pkg searcher

      # cli
      pkgs.yazi # fav small tui file manager
      pkgs.starship # shell prompt
      pkgs.hyperfine # bench commands
      pkgs.poop # also bench commands
      pkgs.systemctl-tui # manage systemd processes
      pkgs.grc # colorizer
      pkgs.translate-shell # Provides trans
      pkgs.grim
      pkgs.slurp
      pkgs.wl-clipboard
      pkgs.wl-clip-persist
      pkgs.wtype
      # pkgs.wluma # smart brightness
      pkgs.brightnessctl # useful for brightness binds
      pkgs.libnotify # notify-send
      pkgs.matugen # styling colors
      # pkgs.hyprpicker # pick color
      pkgs.xdg-utils # Provides xdg-open
      pkgs.dotter
      pkgs.home-manager
      # pkgs.nix-init # init new package with fetched source
      # pkgs.nix-inspect # inspect nix flakes
      # pkgs.nix-melt # find flake missing .follows
      pkgs.alejandra
      pkgs.nixd
      pkgs.uv
      pkgs.pyright
      pkgs.lua51Packages.lua
      pkgs.lua51Packages.luarocks
      pkgs.lua-language-server
      pkgs.stylua
      pkgs.gnumake
      pkgs.tree-sitter
      pkgs.shfmt
      pkgs.fixjson
      pkgs.pamixer
      pkgs.playerctl
      pkgs.typst
      pkgs.tinymist
      pkgs.typstyle
      pkgs.vale
      pkgs.viddy # watch but fancier

      # gui
      pkgs.foot # the most basic one
      pkgs.alacritty # daily driver
      pkgs.wooz # zoom in
      pkgs.neovide # nvim gui
      # (pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
      #   plugins = with pkgs.vimPlugins; [
      #     # tokyonight-nvim
      #   ];
      #   luaRcContent = ''
      #     vim.cmd("packloadall!")
      #     local config_path = (os.getenv("HOME") or "") .. "/.config/nvim/init.lua"
      #     if vim.uv.fs_stat(config_path) then
      #       dofile(config_path)
      #     end
      #   '';
      # }) # if I'd want to package it one day
      # if high priority
      # (lib.setPrio 4 (pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped { ... }))
      # pkgs.nixd ...
      pkgs.neovim # full neovim with wl-clipboard and other stuff
      pkgs.imv

      # inbox
    ];

  # Heavy stuff, rare updates
  max = [
    # special
    inputs'.zen-browser.packages.default
    inputs'.freesm-launcher.packages.default
    inputs'.nur.legacyPackages.repos.gepbird.drg-mint-notag

    # cli
    pkgs.llvmPackages.clang-tools
    pkgs.llvmPackages.clang
    pkgs.llvmPackages.lldb
    pkgs.openjdk21
    pkgs.ani-cli
    pkgs.pandoc
    pkgs.packwiz
    pkgs.tesseract # OCR
    pkgs.imagemagick # image manipulations
    pkgs.zbar # read qr
    pkgs.ffmpeg # Provides both ffmpeg and ffprobe
    pkgs.npins

    # gui
    pkgs.chromium
    # pkgs.dillo
    # pkgs.tor-browser
    pkgs.vesktop
    pkgs.telegram-desktop
    pkgs.thunderbird
    (pkgs.discord.override {withOpenASAR = true;})
    pkgs.gpu-screen-recorder-gtk
    pkgs.zed-editor
    pkgs.vscode
    pkgs.vial
    pkgs.vlc
    pkgs.decibels
    # custom.spotify-spiced
    pkgs.spotify
    pkgs.pavucontrol
    pkgs.easyeffects
    pkgs.coppwr
    pkgs.obsidian
    pkgs.affine
    pkgs.onlyoffice-desktopeditors
    pkgs.zathura
    pkgs.krita
    pkgs.nomacs
    # pkgs.blender
    pkgs.qbittorrent
    pkgs.mangohud
    pkgs.bottles
    pkgs.protontricks
    pkgs.r2modman
    pkgs.ripdrag # drag and drop for cli
    pkgs.heroic
    pkgs.faugus-launcher
    pkgs.ghostty # for kitty protocol binds like TUI file managers
    pkgs.satty
    pkgs.nautilus # file manager
    pkgs.kdePackages.dolphin # moving from nautilus
    pkgs.mdformat
    pkgs.trash-cli # not needed with rip, but apps do make use of local share trash

    # inbox
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
}
