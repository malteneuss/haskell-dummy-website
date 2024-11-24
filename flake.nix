{
  description = "srid/haskell-template: Nix template for Haskell projects";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
    haskell-flake.url = "github:srid/haskell-flake";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    fourmolu-nix.url = "github:jedimahdi/fourmolu-nix";
  };

  outputs = inputs@{self, flake-parts, ...}:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        inputs.haskell-flake.flakeModule
        inputs.treefmt-nix.flakeModule
        inputs.fourmolu-nix.flakeModule
      ];
      flake = {
        nixosModules.module-haskell-dummy-website = { system, ... }: {
          systemd.services.haskell-dummy-website = {
            enable = true;
            # package = haskellapp.packages.${system}.haskell-dummy-website;
            serviceConfig = {
              ExecStart = "${self.packages.${system}.haskell-dummy-website}/bin/haskell-dummy-website";
              Restart = "always";
              DynamicUser = true;
              # Environment = "RUST_LOG=info";
              StateDirectory = ["haskell-dummy-website"]; # Set the state directory
              WorkingDirectory = "/var/lib/haskell-dummy-website"; # Set the working directory to state directory
            };
            wantedBy = [ "multi-user.target" ];
          };
          networking.firewall.allowedTCPPorts = [ 8081 ];
        };
      };
      perSystem = { self', system, lib, config, pkgs, ... }: {
        # Our only Haskell project. You can have multiple projects, but this template
        # has only one.
        # See https://github.com/srid/haskell-flake/blob/master/example/flake.nix
        haskellProjects.default = {
        # haskellProjects.haskell-dummy-website = {
          # To avoid unnecessary rebuilds, we filter projectRoot:
          # https://community.flake.parts/haskell-flake/local#rebuild
          # projectRoot = builtins.toString (lib.fileset.toSource {
          #   root = ./.;
          #   fileset = lib.fileset.unions [
          #     # ./haskell-dummy-website.cabal
          #     # ./app
          #     ./subpackage/subapp.cabal
          #     ./subpackage/app
          #     ./CHANGELOG.md
          #   ];
          # });
          # defaults.packages = {
          #   subapp.source = ./subpackage;
          # };

          # The base package set (this value is the default)
# basePackages = pkgs.haskellPackages.override {
# overrides = self: super: {
#   openai-hs = super.openai-hs.override {
#   version = "0.3.0.1";
#   doCheck = false;
#   };
#   broken=false;
# };
# };


          # Packages to add on top of `basePackages`
#           packages = {
#             # Add source or Hackage overrides here
#             # (Local packages are added automatically)
# # aeson.source = "1.5.0.0" # Hackage version
# # shower.source = inputs.shower; # Flake input
# # broken in nixpkgs, force to use openai-hs


# # openai-hs = {
# #   source = "0.3.0.1";
# #   doCheck = false;
# # };


#           };

          # Add your package overrides here
          settings = {
            /*
            haskell-template = {
              haddock = false;
            };
            aeson = {
              check = false;
            };
            */
            openai-hs = {
              # doCheck = false;
broken = false;

            };
          };

          # Development shell configuration
          devShell = {
            hlsCheck.enable = false;
          };

          # What should haskell-flake add to flake outputs?
          autoWire = [ "packages" "apps" "checks" ]; # Wire all but the devShell
        };

        # Auto formatters. This also adds a flake check to ensure that the
        # source tree was auto formatted.
        treefmt.config = {
          projectRootFile = "flake.nix";

          programs.ormolu.enable = true;
          programs.nixpkgs-fmt.enable = true;
          programs.cabal-fmt.enable = true;
          programs.hlint.enable = true;
        };

        # Default package & app.
        # packages.default = self'.packages.subpackage;
        # apps.default = self'.apps.haskell-template;

        # Default shell.
        devShells.default = pkgs.mkShell rec {
          name = "haskell-template";
          meta.description = "Haskell development environment";
          # See https://community.flake.parts/haskell-flake/devshell#composing-devshells
          inputsFrom = [
            config.haskellProjects.default.outputs.devShell
            config.treefmt.build.devShell
          ];
          nativeBuildInputs = with pkgs; [
            just
            # needed for command line tools like pg_config and psql
            postgresql_15
            # manage database schema and migrations
            dbmate
            zlib
          ];
          # Ensure that libz.so and other libraries are available to TH
          # splices, cabal repl, etc.
          LD_LIBRARY_PATH = lib.makeLibraryPath nativeBuildInputs;
        };
      };
    };
}
