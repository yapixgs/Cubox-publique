# Référentiel Cloudox (R8.4, R8.6) — fichier canonique, ne pas modifier : `normes synchro` le réécrit.
# L'environnement de la CI : chaque job lance `nix develop --command just <recette>`, et un
# poste obtient les mêmes outils, aux mêmes versions, avec `nix develop`.
{
  description = "Environnement de CI Cloudox";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      versionNormes = "v3.2.0";
      python = pkgs.python312;
      # L'outil du référentiel, à la version épinglée, depuis le registre de paquets de la forge.
      normes = pkgs.writeShellScriptBin "normes" ''
        exec ${pkgs.uv}/bin/uvx --quiet --python ${python}/bin/python3.12 \
          --index cloudox=https://forge.oxitablock.com/api/packages/Cloudox/pypi/simple \
          --from "cloudox-normes==${pkgs.lib.removePrefix "v" versionNormes}" normes "$@"
      '';
      # Le Python de l'outil normes, pour les recettes propres à un dépôt qui s'appuient sur ses
      # modules (livraison de Spym, de Cubox, de Ponguy) : `normes-python script.py`.
      normesPython = pkgs.writeShellScriptBin "normes-python" ''
        exec ${pkgs.uv}/bin/uv run --quiet --no-project --python ${python}/bin/python3.12 \
          --index cloudox=https://forge.oxitablock.com/api/packages/Cloudox/pypi/simple \
          --with "cloudox-normes==${pkgs.lib.removePrefix "v" versionNormes}" python "$@"
      '';
      tesseract = pkgs.tesseract.override {
        enableLanguages = [ "eng" "fra" "spa" "deu" "ita" "nld" "por" ];
      };
      environnement = pkgs.mkShellNoCC {
        packages = [
          normes
          normesPython
          python
          tesseract
        ]
        ++ (with pkgs; [
          uv
          nodejs_22
          just
          git
          jq
          gitleaks
          trivy
          crane
          gnupg
          sops
          chromium
          postgresql_17
          redis
          ffmpeg-headless
          ocrmypdf
          poppler-utils
          fontconfig
          dejavu_fonts
        ]);
        env = {
          UV_PYTHON = "${python}/bin/python3.12";
          UV_PYTHON_DOWNLOADS = "never";
          # Playwright pilote ce Chromium : ses propres navigateurs ne tournent pas sous Nix (R7.10).
          CHROMIUM_PATH = "${pkgs.chromium}/bin/chromium";
          # Les roues manylinux attendent libstdc++ et zlib aux emplacements d'une distribution classique.
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib pkgs.zlib ];
          FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [ pkgs.dejavu_fonts ]; };
        };
        # ocrmypdf (une application Python de nixpkgs) remplit PYTHONPATH avec ses propres
        # modules, en Python 3.14 : les venv des produits les importeraient à la place des
        # leurs. Il n'en a pas besoin, son lanceur fixe déjà ses chemins.
        shellHook = ''
          unset PYTHONPATH PYTHONHASHSEED
        '';
      };
    in
    {
      devShells.x86_64-linux.default = environnement;
    };
}
