{
  pkgs,
  inputs',
  ...
} @ args: let
  custom = import ./custom-pkgs.nix args;

  scratchpad = let
  in [
  ];

  base = [
    # Core core
    pkgs.starship
    pkgs.eza
    pkgs.ripgrep
    pkgs.fd
    pkgs.fzf
    pkgs.jq
    pkgs.tealdeer
    pkgs.trash-cli
    pkgs.zip
    pkgs.p7zip
    pkgs.killall
    pkgs.zoxide

    # Diagnostics
    pkgs.btop
    pkgs.gdu
    pkgs.ncdu
    pkgs.hyperfine
    pkgs.isd
    pkgs.evtest
    pkgs.grc
    pkgs.ripdrag
    pkgs.exiftool

    # Nix tooling
    inputs'.nix-index-database.packages.nix-index-with-small-db
    inputs'.nix-index-database.packages.comma-with-db

    # File management & tag navigation
    pkgs.yazi
    # pkgs.tmsu
    # inputs'.riptide.packages.tmsufolders
    # inputs'.riptide.packages.tmsufs
    # inputs'.riptide.packages.quest
    # inputs'.riptide.packages.tray-tui

    # Version control
    pkgs.git
    inputs'.jj-pin.legacyPackages.jj-fzf
    inputs'.jj-pin.legacyPackages.jujutsu
    # pkgs.jujutsu
    # pkgs.jj-fzf
  ];

  desktop = [
    # Terminals
    pkgs.foot
    pkgs.alacritty
    pkgs.ghostty

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

    # Wayland utilities
    custom.satty-screenshot
    custom.script-spam
    pkgs.grim
    pkgs.slurp
    pkgs.satty
    pkgs.wl-clipboard
    pkgs.wl-clip-persist
    pkgs.xclip
    pkgs.wtype

    # Hardware & system controls
    pkgs.wluma
    pkgs.brightnessctl
    pkgs.gpu-screen-recorder-gtk
    pkgs.amdgpu_top
    pkgs.networkmanagerapplet
    pkgs.libnotify

    # Apps
    pkgs.nautilus
    pkgs.baobab
    pkgs.activate-linux
    pkgs.matugen
    pkgs.hyprland-qtutils
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
  ];

  dev = [
    # Editors
    # inputs'.neovim-riptide.packages.default

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
    pkgs.zed-editor
    pkgs.vscode

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

    # C / C++
    pkgs.gnumake
    pkgs.llvmPackages.clang-tools
    pkgs.llvmPackages.clang
    pkgs.llvmPackages.lldb

    # Python
    (pkgs.python3.withPackages (ps: [ps.pip]))
    pkgs.uv
    pkgs.pyright

    # Lua
    pkgs.lua51Packages.lua
    pkgs.lua51Packages.luarocks
    pkgs.lua-language-server
    pkgs.stylua

    # Misc toolchains & formatters
    pkgs.openjdk21
    pkgs.tree-sitter
    pkgs.shfmt
    pkgs.fixjson
    pkgs.vial
  ];

  media = [
    # Video and anime playback
    custom.mpv-custom
    pkgs.vlc
    pkgs.imv
    pkgs.decibels
    pkgs.ani-cli

    # Audio
    # custom.spotify-spiced
    pkgs.spotify
    pkgs.pavucontrol
    pkgs.easyeffects
    pkgs.coppwr
    pkgs.pamixer
    pkgs.playerctl
    inputs'.hijacker.packages.hijacker
    custom.hijacker-ctl

    # Documents
    pkgs.obsidian
    pkgs.affine
    pkgs.typst
    pkgs.tinymist
    pkgs.typstyle
    pkgs.onlyoffice-desktopeditors
    pkgs.pandoc
    pkgs.zathura
    pkgs.vale
    pkgs.mdformat

    # Media acquisition
    pkgs.krita
    pkgs.nomacs
    # pkgs.blender
    pkgs.qbittorrent
  ];

  gaming = [
    # Tools / compatibility layers
    pkgs.mangohud
    pkgs.bottles
    pkgs.protontricks
    pkgs.r2modman

    # Launchers
    pkgs.heroic
    pkgs.faugus-launcher

    # Minecraft
    pkgs.ferium
    pkgs.packwiz
    inputs'.freesm-launcher.packages.default

    inputs'.nur.legacyPackages.repos.gepbird.drg-mint-notag
  ];

  workstation = base ++ desktop ++ dev ++ media ++ gaming;
in {
  # Bundles (nix profile install .#<name>)
  inherit
    base
    desktop
    dev
    media
    gaming
    scratchpad
    ;

  # Full set
  inherit workstation;
  default = workstation;
}
