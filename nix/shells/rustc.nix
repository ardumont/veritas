{ pkgs ? import <nixpkgs> {
    # `pkgs` is provided by the flake normally, but `nix-shell` and `lorri` both use the default
    # value, so make sure that our custom packages are available using an overlay.
    overlays = [
      (_: super: {
        cargo-bisect-rustc = super.callPackage ../packages/cargo-bisect-rustc { };

        measureme = super.callPackage ../packages/measureme { };

        rustfilt = super.callPackage ../packages/rustfilt { };

        rustup-toolchain-install-master =
          super.callPackage ../packages/rustup-toolchain-install-master { };
      })
    ];
  }
}:

# This file contains a development shell for working on rustc.
let
  # Build configuration for rust-lang/rust. Based on `config.toml.example` from
  # `1bd30ce2aac40c7698aa4a1b9520aa649ff2d1c5`.
  config = pkgs.writeText "rustc-config" ''
    # =============================================================================
    # Tweaking how LLVM is compiled
    # =============================================================================
    [llvm]

    # Indicates whether the LLVM build is a Release or Debug build
    optimize = true

    # Indicates whether the LLVM assertions are enabled or not
    assertions = true

    # Indicates whether ccache is used when building LLVM
    ccache = true

    # Tell the LLVM build system to use Ninja instead of the platform default for
    # the generated build system. This can sometimes be faster than make, for
    # example.
    ninja = true

    # LLVM targets to build support for.
    # Note: this is NOT related to Rust compilation targets. However, as Rust is
    # dependent on LLVM for code generation, turning targets off here WILL lead to
    # the resulting rustc being unable to compile for the disabled architectures.
    # Also worth pointing out is that, in case support for new targets are added to
    # LLVM, enabling them here doesn't mean Rust is automatically gaining said
    # support. You'll need to write a target specification at least, and most
    # likely, teach rustc about the C ABI of the target. Get in touch with the
    # Rust team and file an issue if you need assistance in porting!
    targets = "AArch64;ARM;Hexagon;MSP430;Mips;NVPTX;PowerPC;RISCV;Sparc;SystemZ;WebAssembly;X86"

    # =============================================================================
    # General build configuration options
    # =============================================================================
    [build]

    # Indicate whether the compiler should be documented in addition to the standard
    # library and facade crates.
    compiler-docs = true

    # Indicate whether git submodules are managed and updated automatically.
    submodules = true

    # Update git submodules only when the checked out commit in the submodules differs
    # from what is committed in the main rustc repo.
    fast-submodules = true

    # The path to (or name of) the GDB executable to use. This is only used for
    # executing the debuginfo test suite.
    gdb = "${pkgs.gdb}/bin/gdb"

    # Python interpreter to use for various tasks throughout the build, notably
    # rustdoc tests, the lldb python interpreter, and some dist bits and pieces.
    # Note that Python 2 is currently required.
    #
    # Defaults to python2.7, then python2. If neither executable can be found, then
    # it defaults to the Python interpreter used to execute x.py.
    python = "${pkgs.python2Full}/bin/python"

    # =============================================================================
    # Options for compiling Rust code itself
    # =============================================================================
    [rust]

    # Whether or not to optimize the compiler and standard library.
    # WARNING: Building with optimize = false is NOT SUPPORTED. Due to bootstrapping,
    # building without optimizations takes much longer than optimizing. Further, some platforms
    # fail to build without this optimization (c.f. #65352).
    optimize = true

    # Indicates that the build should be configured for debugging Rust. A
    # `debug`-enabled compiler and standard library will be somewhat
    # slower (due to e.g. checking of debug assertions) but should remain
    # usable.
    #
    # Note: If this value is set to `true`, it will affect a number of
    #       configuration options below as well, if they have been left
    #       unconfigured in this file.
    #
    # Note: changes to the `debug` setting do *not* affect `optimize`
    #       above. In theory, a "maximally debuggable" environment would
    #       set `optimize` to `false` above to assist the introspection
    #       facilities of debuggers like lldb and gdb. To recreate such an
    #       environment, explicitly set `optimize` to `false` and `debug`
    #       to `true`. In practice, everyone leaves `optimize` set to
    #       `true`, because an unoptimized rustc with debugging
    #       enabled becomes *unusably slow* (e.g. rust-lang/rust#24840
    #       reported a 25x slowdown) and bootstrapping the supposed
    #       "maximally debuggable" environment (notably libstd) takes
    #       hours to build.
    #
    debug = false

    # Whether or not debug assertions are enabled for the compiler and standard
    # library.
    debug-assertions = true

    # Debuginfo level for most of Rust code, corresponds to the `-C debuginfo=N` option of `rustc`.
    # `0` - no debug info
    # `1` - line tables only
    # `2` - full debug info with variable and type information
    # Can be overriden for specific subsets of Rust code (rustc, std or tools).
    # Debuginfo for tests run with compiletest is not controlled by this option
    # and needs to be enabled separately with `debuginfo-level-tests`.
    debuginfo-level = 1

    # Whether or not `panic!`s generate backtraces (RUST_BACKTRACE)
    backtrace = true

    # Whether to always use incremental compilation when building rustc
    incremental = true

    # Indicates whether LLD will be compiled and made available in the sysroot for
    # rustc to execute.
    lld = true

    # Indicates whether some LLVM tools, like llvm-objdump, will be made available in the
    # sysroot.
    llvm-tools = true

    # Whether to deny warnings in crates
    deny-warnings = true

    # Print backtrace on internal compiler errors during bootstrap
    backtrace-on-ice = true

    # Run tests in various test suites with the "nll compare mode" in addition to
    # running the tests in normal mode. Largely only used on CI and during local
    # development of NLL
    test-compare-mode = false
  '';

  # Custom Vim configuration to disable ctags on directories we never want to look at.
  lvimrc = pkgs.writeText "rustc-lvimrc" ''
    let g:gutentags_ctags_exclude = [
    \   "src/llvm-project",
    \   "src/librustdoc/html",
    \   "src/doc",
    \   "src/ci",
    \   "src/bootstrap",
    \   "*.md"
    \ ]

    " Only use rust-analyzer.
    let g:ale_linters['rust'] = [ 'analyzer' ]

    " Same configuration as `x.py fmt`.
    let g:ale_rust_rustfmt_options = '--edition 2018 --unstable-features --skip-children'
    let g:ale_rust_rustfmt_executable = './build/x86_64-unknown-linux-gnu/stage0/bin/rustfmt'

    augroup RustcAU
      au!
      " Disable ALE in Clippy, rustfmt isn't used.
      au! BufRead,BufNewFile,BufEnter **/src/tools/clippy/** :ALEDisableBuffer
      au! BufRead,BufNewFile,BufEnter **/src/tools/clippy/** :let b:ale_fix_on_save = 0
    augroup END
  '';

  ripgrepConfig =
    let
      # Files that are ignored by ripgrep when searching.
      ignoreFile = pkgs.writeText "rustc-rgignore" ''
        configure
        config.toml.example
        x.py
        LICENSE-MIT
        LICENSE-APACHE
        COPYRIGHT
        **/*.txt
        **/*.toml
        **/*.yml
        **/*.nix
        *.md
        src/ci
        src/doc/
        src/etc/
        src/llvm-emscripten/
        src/llvm-project/
        src/rtstartup/
        src/rustllvm/
        src/stdsimd/
        src/tools/rls/rls-analysis/test_data/
      '';
    in
    pkgs.writeText "rustc-ripgreprc" "--ignore-file=${ignoreFile}";
in
pkgs.clangMultiStdenv.mkDerivation rec {
  name = "rustc";
  buildInputs = with pkgs; [
    git
    pythonFull
    gnumake
    cmake
    curl

    pkg-config
    libxml2
    ncurses
    swig
    openssl

    # If `llvm.ninja` is `true` in `config.toml`.
    ninja
    # If `llvm.ccache` is `true` in `config.toml`.
    ccache
    # Used by debuginfo tests.
    gdb
    # Used with emscripten target.
    nodejs

    # Local toolchain is added to rustup to avoid needing to set up
    # environment variables.
    rustup

    # Useful tools for working on upstream issues.
    cargo-bisect-rustc
    measureme
    rustfilt
    rustup-toolchain-install-master

    # Required for nested shells in lorri to work correctly.
    bashInteractive
  ];

  # Environment variables consumed by tooling.
  RUST_BOOTSTRAP_CONFIG = config;
  RIPGREP_CONFIG_PATH = ripgrepConfig;
  DTW_LOCALVIMRC = lvimrc;

  # Always show backtraces.
  RUST_BACKTRACE = 1;

  # Disable compiler hardening - required for LLVM.
  hardeningDisable = [ "all" ];
}

# vim:foldmethod=marker:foldlevel=0:ts=2:sts=2:sw=2:et:nowrap
