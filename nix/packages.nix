# nix/packages.nix — KOPI Agent package built with uv2nix
{ inputs, ... }:
{
  perSystem =
    { pkgs, inputs', ... }:
    let
      kopiAgent = pkgs.callPackage ./kopi-agent.nix {
        inherit (inputs) uv2nix pyproject-nix pyproject-build-systems;
        npm-lockfile-fix = inputs'.npm-lockfile-fix.packages.default;
        # Only embed clean revs — dirtyRev doesn't represent any upstream
        # commit, so comparing it would always claim "update available".
        rev = inputs.self.rev or null;
      };
    in
    {
      packages = {
        default = kopiAgent;
        tui = kopiAgent.kopiTui;
        web = kopiAgent.kopiWeb;

        fix-lockfiles = kopiAgent.kopiNpmLib.mkFixLockfiles {
          packages = [ kopiAgent.kopiTui kopiAgent.kopiWeb ];
        };
      };
    };
}
