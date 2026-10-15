{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    gate.url = "github:Gen-cape/gate";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    riptide.url = "github:Gen-cape/riptide";
    neovim-riptide.url = "github:Gen-cape/neovim";
    nix-index-database.url = "github:nix-community/nix-index-database";
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    freesm-launcher.url = "github:FreesmTeam/FreesmLauncher";
    nur.url = "github:nix-community/NUR";
    hijacker.url = "github:chilipizdrick/hijacker";
    nix-search-tv.url = "github:3timeslazy/nix-search-tv";

    # pins
    jj-pin.url = "github:nixos/nixpkgs/nixos-26.05-small";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    inherit (pkgs) lib;
    gate = inputs.gate.lib;

    mkBundle = name: paths:
      pkgs.buildEnv {
        name = "bundle-${name}";
        paths = lib.flatten paths;
        ignoreCollisions = true;
      };

    roles = gate.withSystem system inputs (primes: import ./roles.nix (primes // {inherit pkgs lib;}));
  in {
    packages.${system} = lib.mapAttrs mkBundle roles;
  };
}
