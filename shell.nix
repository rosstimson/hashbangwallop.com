let
  # See https://nixos.wiki/wiki/FAQ/Pinning_Nixpkgs for more information on pinning
  nixpkgs = builtins.fetchTarball {
    # Descriptive name to make the store path easier to identify
    name = "nixpkgs-unstable-2020-08-27";
    # Commit hash for nixos-unstable as of 2020-08-27
    url = https://github.com/NixOS/nixpkgs/archive/5f8d0e4d7578fa08f4bf645fb5eb03f695bddf0d.tar.gz;
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "0dr4ci73x1fqii4hhlxkq676r27chaqwislsvmw1awq167989y2n";
  };

in

{ pkgs ? import nixpkgs {} }:

with pkgs;

mkShell {
  buildInputs = [
    coreutils
    lowdown
    nodejs
    yarn
  ];
}
