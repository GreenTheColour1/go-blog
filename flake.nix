{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        templui = pkgs.buildGoModule rec {
          pname = "templui";
          version = "0.75.4";

          src = pkgs.fetchFromGitHub {
            owner = "axzilla";
            repo = "templui";
            tag = "v${version}";
            hash = "sha256-YxRC170+UsTxLrkYwWENwtknljZFh+PKmoRPCQlKMcM=";
          };

          nativeBuildInputs = with pkgs; [ templ ];

          preBuild = ''
            templ generate
          '';

          vendorHash = "sha256-oi225lRIyvuEvHJj0cwGwwUa1O5MeWWzsPkFK1cPwEY=";

          meta = {
            description = "The UI Kit for templ";
            homepage = "https://templui.io/";
            license = pkgs.lib.licenses.mit;
          };
        };
      in
      rec {

        devShell = pkgs.mkShell {
          buildInputs = [ pkgs.zsh ];

          nativeBuildInputs = with pkgs; [
            go
            templ
            postgresql
            nodejs
            air
            overmind
            delve
            tailwindcss_4
            templui
            docker
          ];

          shellHook = ''
            export PGHOST=$USER
            export PGDATA=./pgdata
            export PGSOCKET=/tmp

            # needed for debugging with delve
            export CGO_CFLAGS="-O2"
            export CGO_CPPFLAGS="-O2"

            initdb -D $PGDATA
            pg_ctl -D "$PGDATA" -l $PGDATA/logfile -o "-k $PGSOCKET" start
            # psql -h localhost -U $USER

            cleanup() {
              echo "Stopping PostgreSQL server..."
              pg_ctl -D "$PGDATA" stop
            }

            trap cleanup EXIT

            CURRENT_DIR=$(pwd)
            tmuxp load "$CURRENT_DIR"
          '';
        };

        packages.go-blog = pkgs.buildGoModule {
          pname = "go-blog";
          version = "0.1";

          src = ./.;

          vendorHash = "sha256-TJDRrjiW8j2pw5qyD0YT7YtvEpKxgVhlvAXntl8clIk=";

          nativeBuildInputs = with pkgs; [ templ ];

          preBuild = ''
            templ generate
          '';

        };

        defaultPackage = packages.go-blog;
      }
    );
}
