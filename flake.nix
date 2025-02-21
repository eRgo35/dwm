{
  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system}.dwm = pkgs.stdenv.mkDerivation rec {
      pname = "dwm";
      version = "custom";
      src = ./.;
      
      buildInputs = with pkgs; [
        xorg.libX11
        xorg.libXft
        xorg.libXinerama
      ];

      makeFlags = [ "CC=${pkgs.gcc}/bin/cc" ];

      installPhase = ''
        mkdir -p $out/bin
        cp dwm $out/bin/
      '';

      meta = with pkgs.lib; {
        description = "Dynamic Window Manager";
        license = licenses.mit;
        maintainers = [ ];
      };
    };

    defaultPackage.${system} = self.packages.${system}.dwm;

    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        gnumake
        gcc
        xorg.libX11
        xorg.libX11.dev
        xorg.libXft
        xorg.libXinerama
      ];
      
      shellHook = ''
        echo "Development shell for dwm ready."
      '';
    };
  };
}
