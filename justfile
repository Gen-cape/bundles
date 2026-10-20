# Fresh machine wants lite bundle
deploy:
    nix profile install .#lite

# Upgrade all
upgrade:
    nix profile upgrade '.*'

# Update flake and upgrade then all
end-of-week:
    nix flake update
    nix profile upgrade '.*'

# Garbage collect
gc:
    nix profile wipe-history
    nix-collect-garbage -d
