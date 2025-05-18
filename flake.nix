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
        ];

        shellHook = ''
          export PGHOST=$USER
          export PGDATA=./pgdata
          export PGSOCKET=/tmp

          initdb -D $PGDATA
          pg_ctl -D "$PGDATA" -l $PGDATA/logfile -o "-k $PGSOCKET" start
          # psql -h localhost -U $USER

          cleanup() {
            echo "Stopping PostgreSQL server..."
            pg_ctl -D "$PGDATA" stop
          }

          trap cleanup EXIT

          # if [ -z "$ZSH_VERSION" ]; then
          #   exec zsh
          # fi
        '';
      };

    };
}
