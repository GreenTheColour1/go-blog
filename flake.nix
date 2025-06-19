{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {

      devShells.x86_64-linux.default = pkgs.mkShell {
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

    };
}
