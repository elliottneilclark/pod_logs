{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    flake-root.url = "github:srid/flake-root";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs = { nixpkgs-lib.follows = "nixpkgs"; };
    };
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-utils, flake-root, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = flake-utils.lib.defaultSystems;


      perSystem = { system, ... }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          beam = pkgs.beam;
          beamPackages = beam.packagesWith beam.interpreters.erlang;
          erlang = beamPackages.erlang;


          ### CHANGE ME TO WORK ##########
          # elixir = beamPackages.elixir_1_14;

          ### CHANGE ME TO REPRO #########
          elixir = beamPackages.elixir_1_15;
          rebar = beamPackages.rebar;
          rebar3 = beamPackages.rebar3;
          elixir-ls = beamPackages.elixir-ls;

          elixirNativeTools = with pkgs; [
            erlang
            elixir

            rebar
            rebar3
            hex
            elixir-ls
            postgresql

            bind
          ];

          rustNativeBuildTools = with pkgs; [
            pkg-config
            postgresql
          ];


          linuxOnlyTools = with pkgs; [
            # Track when files change for css updates
            inotify-tools
          ];

          frameworks = pkgs.darwin.apple_sdk.frameworks;

          darwinOnlyTools = [
            frameworks.Security
            frameworks.CoreServices
            frameworks.CoreFoundation
            frameworks.Foundation
          ];


          nativeBuildInputs = with pkgs; [
            # node is needed, because
            # javascript won for better or worse
            nodejs
          ]
          ++ elixirNativeTools
          ++ rustNativeBuildTools
          ++ lib.optionals pkgs.stdenv.isDarwin darwinOnlyTools
          ++ lib.optionals pkgs.stdenv.isLinux linuxOnlyTools;


          buildInputs = with pkgs; [
            openssl
            glibcLocales
          ];

          shellHook = ''
            # go to the top level.
            pushd $(git rev-parse --show-toplevel || echo ".")

            # this allows mix to work on the local directory
            export MIX_HOME=$PWD/.nix-mix
            mkdir -p $MIX_HOME

            export HEX_HOME=$PWD/.nix-hex
            mkdir -p $HEX_HOME

            export PATH=$MIX_HOME/bin:$PATH
            export PATH=$HEX_HOME/bin:$PATH

            pushd platform_umbrella
            mix local.rebar --if-missing rebar3 ${rebar3}/bin/rebar3 || true;
            mix local.hex --force --if-missing || true;
            popd
          '';


        in
        {
          devShells.default = pkgs.mkShell {
            inherit nativeBuildInputs buildInputs shellHook;
            LANG = "en_US.UTF-8";
            LC_ALL = "en_US.UTF-8";
            LC_CTYPE = "en_US.UTF-8";
            RUST_BACKTRACE = 1;
            ERL_AFLAGS = "-kernel shell_history enabled";
          };
        };
    };
}
