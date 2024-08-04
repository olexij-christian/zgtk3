with import <nixpkgs> {};
stdenv.mkDerivation {
  name = "env";
  buildInputs = [
    gtk3
    pkg-config
  ];
}
