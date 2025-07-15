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
        go-migrate-pg = pkgs.go-migrate.overrideAttrs (oldAttrs: {
          tags = [ "postgres" ];
        });
      in
      rec {
        devShell = pkgs.mkShell {
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
            go-migrate-pg
          ];

          shellHook = ''
            export PGHOST=$USER
            export PGDATA=./pgdata
            export PGSOCKET=/tmp

            export POSTGRES_USER=$USER
            export POSTGRES_PORT=5432
            export POSTGRES_PASSWORD=""
            export POSTGRES_DB=postgres
            export ENVIRONMENT=dev

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

          vendorHash = "sha256-q9MUb+zhEKzDGSxJga3nxkT1iP++ckrxbsbTvW3QQhw=";

          nativeBuildInputs = with pkgs; [
            templ
          ];

          buildInputs = [
            go-migrate-pg
          ];

          preBuild = ''
            templ generate
          '';

        };

        packages.blog-image = pkgs.dockerTools.buildLayeredImage {
          name = "go-blog";
          # contents = [ go-migrate-pg ];
          contents = [
            ./database/migrations
            go-migrate-pg
          ];
          config = {
            Cmd = [
              "migrate -source file://migrations -database postgresql://blog:blog@db:5432/posts up"
              "${packages.go-blog}/bin/blog"
            ];
            ExposedPorts = {
              "8080/tcp" = { };
            };
          };
        };

        defaultPackage = packages.go-blog;
      }
    );
}
