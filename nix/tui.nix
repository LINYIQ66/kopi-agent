# nix/tui.nix — KOPI TUI (Ink/React) compiled with tsc and bundled
{ pkgs, kopiNpmLib, ... }:
let
  src = ../ui-tui;
  npmDeps = pkgs.fetchNpmDeps {
    inherit src;
    hash = "sha256-9r1EYQ600gNXOnNXwakorpEk7hS/FPxZVbB2JksrhYs=";
  };

  npm = kopiNpmLib.mkNpmPassthru { folder = "ui-tui"; attr = "tui"; pname = "kopi-tui"; };

  packageJson = builtins.fromJSON (builtins.readFile (src + "/package.json"));
  version = packageJson.version;
in
pkgs.buildNpmPackage (npm // {
  pname = "kopi-tui";
  inherit src npmDeps version;

  doCheck = false;
  npmFlags = [ "--legacy-peer-deps" ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/kopi-tui

    # Single self-contained bundle built by scripts/build.mjs (esbuild).
    cp -r dist $out/lib/kopi-tui/dist

    # package.json kept for "type": "module" resolution on `node dist/entry.js`.
    cp package.json $out/lib/kopi-tui/

    runHook postInstall
  '';
})
