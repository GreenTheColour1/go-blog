FROM nixos/nix:latest AS build

COPY . /tmp/build
WORKDIR /tmp/build

RUN nix \
  --extra-experimental-features "nix-command flakes" \
  --option filter-syscalls false \
  build

RUN mkdir /tmp/nix-store-closure
RUN cp -R $(nix-store -qR result/) /tmp/nix-store-closure

RUN chmod +x /tmp/build/entrypoint.sh

FROM scratch

WORKDIR /app

COPY --from=build /tmp/nix-store-closure /nix/store
COPY --from=build /tmp/build/result /app
COPY --from=build /tmp/build/entrypoint.sh /app


EXPOSE 8080

ENTRYPOINT [ "/app/entrypoint.sh" ]
