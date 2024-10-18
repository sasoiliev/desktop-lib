{ stdenv, libX11, gcc }:

stdenv.mkDerivation (rec {
  pname = "if-at-edge";
  version = "0.1";
  name = "${pname}-${version}";

  src = ./.;

  buildInputs = [ libX11 ];

  unpackPhase = "";
  configurePhase = "";
  buildPhase = ''
    ${gcc}/bin/gcc -lX11 -o ${pname} main.c
  '';

  installPhase = ''
    mkdir -p $out/bin
    install -m 0755 ${pname} $out/bin/${pname}
  '';
})
