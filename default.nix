{ system ? builtins.currentSystem
, lock ? builtins.fromJSON (builtins.readFile ./flake.lock)
  # The official nixpkgs input, pinned with the hash defined in the flake.lock file
, pkgs ? let
    nixpkgs = fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/${lock.nodes.nixpkgs.locked.rev}.tar.gz";
      sha256 = lock.nodes.nixpkgs.locked.narHash;
    };
  in
  import nixpkgs {
    overlays = [ ];
    config = { };
    inherit system;
  }
, buildClient ? false
, buildServer ? true
, buildProxy ? true
, useSDL2 ? true
}:
let
  lib = pkgs.lib;
  # Using mini_compile_commands to export compile_commands.json
  # https://github.com/danielbarter/mini_compile_commands/
  # Look at the README.md file for instructions on generating compile_commands.json
  # mcc-env = (pkgs.callPackage miniCompileCommands { }).wrap pkgs.stdenv;
  # mcc-hook = (pkgs.callPackage miniCompileCommands { }).hook;
  stdenv = pkgs.stdenv;

  useLuajit = lib.meta.availableOn stdenv.hostPlatform pkgs.luajit;
  # Stdenv is base for packaging software in Nix It is used to pull in dependencies such as the GCC toolchain,
  # GNU make, core utilities, patch and diff utilities, and so on. Basic tools needed to compile a huge pile
  # of software currently present in nixpkgs.
  #
  # Some platforms have different toolchains in their StdEnv definition by default
  # To ensure gcc being default, we use gccStdenv as a base instead of just stdenv
  # mkDerivation is the main function used to build packages with the Stdenv
  # package = mcc-env.mkDerivation (self: {
  package = stdenv.mkDerivation (self: {
    name = "luanti";
    version = "5.14.0";

    # Programs and libraries used/available at build-time
    nativeBuildInputs = with pkgs; [
      ncurses
      cmake
      doxygen
      graphviz
      ninja
      clang-tools
      keepBuildTree
    ];


    # Programs and libraries used by the new derivation at run-time
    buildInputs = with pkgs; [
      fmt
      jsoncpp
      gettext
      freetype
      sqlite
      curl
      bzip2
      ncurses
      gmp
      libspatialindex
      coreutils
    ]
    ++ lib.optional useLuajit [
      luajit
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      libiconv
    ]
    ++ lib.optionals buildClient [
      libpng
      libjpeg
      libGLU
      openal
      libogg
      libvorbis
    ]
    ++ lib.optionals (buildClient && useSDL2) [
      SDL2
    ]
    ++ lib.optionals (buildClient && !stdenv.hostPlatform.isDarwin && !useSDL2) [
      xorg.libX11
      xorg.libXi
    ]
    ++ lib.optionals (buildServer || buildProxy) [
      leveldb
      libpq
      hiredis
      prometheus-cpp
    ];

    # builtins.path is used since source of our package is the current directory: ./
    # Alternatively, you can use: fetchFromGitHub, fetchTarball or similar
    src = builtins.path {
      path = ./.;

      # Filter all files that begin with '.', for example '.git', that way
      # .git directory will not become part of the source of our package
      filter = path: type:
        !(pkgs.lib.hasPrefix "." (baseNameOf path));
    };

    patches = [
      (pkgs.substitute {
        src = ./0000-mark-rm-for-substitution.patch;
        substitutions = [
          "--subst-var-by"
          "RM_COMMAND"
          "${pkgs.coreutils}/bin/rm"
        ];
      })
    ];

    postPatch = lib.optionalString stdenv.hostPlatform.isDarwin ''
      			sed -i '/pagezero_size/d;/fixup_bundle/d' src/CMakeLists.txt
      		'';

    postInstall =
      lib.optionalString stdenv.hostPlatform.isLinux ''
        				patchShebangs $out
        			''
      + lib.optionalString stdenv.hostPlatform.isDarwin ''
        				mkdir -p $out/Applications
        				mv $out/luanti.app $out/Applications
        			'';

    doCheck = true;

    meta = with lib; {
      homepage = "https://www.luanti.org/";
      description = "An open source voxel game engine (formerly Minetest)";
      license = licenses.lgpl21Plus;
      platforms = platforms.linux ++ platforms.darwin;
      maintainers = with maintainers; [
        # coldelectrons
      ];
      mainProgram = if buildClient then "luanti" else "luantiserver";
    };

    cmakeFlags = [
      "--no-warn-unused-cli" # Supresses unused varibles warning
      (lib.cmakeBool "BUILD_CLIENT" buildClient)
      (lib.cmakeBool "BUILD_SERVER" buildServer)
      (lib.cmakeBool "BUILD_PROXY" buildProxy)
      (lib.cmakeBool "BUILD_UNITTESTS" (lib.finalAttrs.finalPackage.doCheck or false))
      (lib.cmakeBool "ENABLE_PROMETHEUS" buildServer)
      (lib.cmakeBool "USE_SDL2" useSDL2)
      (lib.cmakeBool "ENABLE_LUAJIT" useLuajit)
      # (lib.cmakeBool "USE_CURSES" true)
      # Ensure we use system libraries
      (lib.cmakeBool "ENABLE_SYSTEM_GMP" true)
      (lib.cmakeBool "ENABLE_SYSTEM_JSONCPP" true)
      # Updates are handled by nix anyway
      (lib.cmakeBool "ENABLE_UPDATE_CHECKER" false)
      # ...but make it clear that this is a nix package
      (lib.cmakeFeature "VERSION_EXTRA" "NixOS")

      # Remove when https://github.com/NixOS/nixpkgs/issues/144170 is fixed
      (lib.cmakeFeature "CMAKE_INSTALL_BINDIR" "bin")
      (lib.cmakeFeature "CMAKE_INSTALL_DATADIR" "share")
      (lib.cmakeFeature "CMAKE_INSTALL_DOCDIR" "share/doc/luanti")
      (lib.cmakeFeature "CMAKE_INSTALL_MANDIR" "share/man")
      (lib.cmakeFeature "CMAKE_INSTALL_LOCALEDIR" "share/locale")

    ];

    # Nix is smart enough to detect we're using cmake to build our project
    # It will read our CMakeLists.txt file and create needed definitions
    # Alternatively, we could have been pre-defining the default phases that nix does
    # for a CMake based projects (see definitions bellow that are commented-out ###)

    # buildDir = "build-nix-${self.name}-${self.version}";

    ### configurePhase = ''
    ###   mkdir ./${self.buildDir} && cd ./${self.buildDir}
    ###   cmake .. -DCMAKE_BUILD_TYPE=Release
    ### '';

    ### buildPhase = ''
    ###   make -j$(nproc)
    ### '';

    ### installPhase = ''
    ###   mkdir -p $out/bin
    ###   cp src/${self.name} $out/bin/
    ### '';

    # passthru - it is meant for values that would be useful outside of the derivation
    # in other parts of a Nix expression (e.g. in other derivations)
    passthru = {
      # inherit has nothing to do with OOP, it's a nix-specific syntax for
      # inheriting (copying) variables from the surrounding lexical scope
      inherit pkgs shell;
      # equivalent to:
      # pkgs = pkgs
      # shell = shell
    };

    passthru.updateScript = lib.gitUpdater {
      allowedVersions = "\\.";
      ignoredVersions = "-android$";
    };

  });

  # Development shell
  shell = (pkgs.mkShell.override { stdenv = stdenv; }) {
    LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
    env.LANG = "C.UTF-8";
    env.LC_ALL = "C.UTF-8";
    # Copy build inputs (dependencies) from the derivation the nix-shell environment
    # That way, there is no need for speciying dependencies separately for derivation and shell
    inputsFrom = [
      package
    ];

    # Shell (dev environment) specific packages
    packages = with pkgs; [
      gcc
      cmake
      zlib
      zstd
      libjpeg
      libpng
      libGL
      luajit
      SDL2
      openal
      curl
      libvorbis
      libogg
      gettext
      freetype
      sqlite
      toilet
    ];

    # Hook used for modifying the prompt look and printing the welcome message
    shellHook = ''
      		PS1="\[\e[32m\][\[\e[m\]\[\e[33m\]nix-shell\\[\e[m\]:\[\e[36m\]\w\[\e[m\]\[\e[32m\]]\[\e[m\]\\$\[\e[m\] "
      		alias ll="ls -la"
      		#nix build .#compileCommands --out-link compile_commands.json
      		toilet -F gay -f future -w160 --metal --gay LUANTI-DEVSHELL
    '';

    meta = with lib; {
      homepage = "https://luanti.org";
      description = "An open-source voxel game";
      license = licenses.lgpl21Plus;
      platforms = platforms.linux;
      maintainers = [ ];
      mainProgram = if buildClient then "luanti" else if buildProxy then "luantiproxy" else "luantiserver";
    };
  };
in
package
