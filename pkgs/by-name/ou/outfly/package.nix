{
  lib,
  stdenvNoCC,
  fetchFromCodeberg,
  rustPlatform,
  makeDesktopItem,
  copyDesktopItems,
  makeWrapper,
  pkg-config,
  libxkbcommon,
  alsa-lib,
  libGL,
  vulkan-loader,
  wayland,
  libxrandr,
  libxcursor,
  libx11,
  libxi,
  nix-update-script,
  unfreeAssets ? true,
}:
stdenvNoCC.mkDerivation (finalAttr: {
  pname = "outfly" + (if !unfreeAssets then "-libre" else "");
  version = "0.16.0-pre-release";

  src = fetchFromCodeberg {
    owner = "outfly";
    repo = "outfly";
    #tag = "v${finalAttr.version}";
    #hash = "sha256-BOm5SxpWowq5LCTqRqDkbKGPnZo0pJYz8w3kB/WnH9M=";
    rev = "0860ce4c7b712f961eed0d6d94632f2f49683047";
    hash = "sha256-TK7tJRMOK0DlbGEVSnMHoUPthgV2Y07IYKEc8Ibrwqw=";
  };

  outflyBin =
let inherit (finalAttr) src version; in
 rustPlatform.buildRustPackage (finalAttr: {
    inherit version src;
    name = "outfly-bin";

    cargoHash = "sha256-MEWVUh+17xaBi5pODfIYP2LfDbXp6OsznpvEOLvQ3sQ=";# "sha256-UXqS4JfKuLxeTW1MDMnKLzw8oHf1Gpgv8SktTtf12mc=";
    runtimeInputs = [
      libxkbcommon
      libGL
      libxrandr
      libx11
      vulkan-loader
    ];

    buildInputs = [
      alsa-lib.dev
      libxcursor
      libxi
      wayland
    ];

    buildFeatures = [
      "wayland"
      "x11"
    ];
    buildNoDefaultFeatures = true;
    nativeBuildInputs = [ pkg-config ];
    doCheck = false; # no meaningful tests

    postFixup = ''
      patchelf $out/bin/outfly \
      --add-rpath ${lib.makeLibraryPath finalAttr.runtimeInputs}
    '';

  });
  nativeBuildInputs = [
    copyDesktopItems
    makeWrapper
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "outfly";
      exec = "outfly";
      desktopName = "OutFly";
      categories = [ "Game" ];
    })
  ];

  buildPhase= ''
    makeWrapper ${finalAttr.outflyBin}/bin/outfly outfly \
    --set BEVY_ASSET_ROOT $out/share
  '';

  postInstall = ''
    #install -Dm444 doc/branding/logo.png $out/share/pixmaps/outfly.png
    #install -Dm444 build/linux/outfly.desktop $out/share/applications/outfly.desktop
    install -D outfly $out/bin/outfly
    install -d $out/share
    cp  -r  assets $out/share
  '' + lib.optionalString (!unfreeAssets) ''
    [ -d "assets-libre" ] && cp -r  assets-libre/* $out/share/assets
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description =
      "Breathtaking 3D space game in the rings of Jupiter"
      + (if unfreeAssets then "" else " (version only using gpl-compatible assets)");
    homepage = "https://yunicode.itch.io/outfly";
    downloadPage = "https://codeberg.org/outfly/outfly/releases";
    changelog = "https://codeberg.org/outfly/outfly/releases/tag/v${finalAttr.version}";
    license =
      with lib.licenses;
      if unfreeAssets then
        [ unfree ]
      else
        [
          cc-by-30
          cc-by-40
          cc-by-sa-20
          cc-by-sa-30
          cc0
          gpl3
          ofl
          publicDomain
        ];
    maintainers = with lib.maintainers; [ _71rd ];
    mainProgram = "outfly";
  };
})
