FROM nixos/nix:latest AS build

COPY . /tmp/build
WORKDIR /tmp/build

RUN nix \
  --extra-experimental-features "nix-command flakes" \
  --option filter-syscalls false \
  build

RUN mkdir /tmp/nix-store-closure
RUN cp -R $(nix-store -qR result/) /tmp/nix-store-closure

FROM scratch

WORKDIR /app

COPY --from=build /tmp/nix-store-closure /nix/store
COPY --from=build /tmp/build/result /app
COPY --from=build /tmp/build/database/migrations /app/database/migrations

EXPOSE 8080

CMD ["/app/database/migrations/migrate.sh && /app/bin/blog"]
