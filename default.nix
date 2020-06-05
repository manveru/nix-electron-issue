let
  sources = import ./nix/sources.nix { };
  binary = "$out/lib/electron/debug/electron.debug";
in with import sources.nixpkgs { };
stdenv.mkDerivation {
  pname = "electron";
  version = "8.3.1";

  dontWrapGApps = true; # electron is in lib, we need to wrap it manually
  dontUnpack = true;
  dontBuild = true;
  dontStrip = true;
  dontPatchELF = true;

  nativeBuildInputs = [ unzip makeWrapper wrapGAppsHook patchelfUnstable ];

  src = fetchurl {
    "url" =
      "https://github.com/electron/electron/releases/download/v8.3.1/electron-v8.3.1-linux-x64-debug.zip";
    "sha256" =
      "33785b8e2d9de7985efadc354bd609fe0116451c0a043d04b46f4b3f70fb4b81";
  };

  installPhase = ''
    mkdir -p $out/lib/electron $out/bin
    unzip -d $out/lib/electron $src
    ln -s ${binary} $out/bin/electron
  '';

  postFixup = ''
    set -x
    patchelf --version
    patchelf \
      --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "${atomEnv.libPath}:${
        lib.makeLibraryPath [ libuuid at-spi2-atk at-spi2-core ]
      }:$out/lib/electron" \
      ${binary}

    wrapProgram ${binary} \
      --prefix LD_PRELOAD : ${
        lib.makeLibraryPath [ xorg.libXScrnSaver ]
      }/libXss.so.1 \
      "''${gappsWrapperArgs[@]}"
  '';
}
