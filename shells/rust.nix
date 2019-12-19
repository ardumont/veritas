# This file contains a development shell for working on rustc. To use, symlink it into the
# directory where Rust is being worked on.

let
  # Import unstable channel for newer versions of packages.
  pkgs = import (import ../nix/sources.nix).nixpkgs-unstable {};
  # Build configuration for rust-lang/rust. Based on `config.toml.example` from
  # `1bd30ce2aac40c7698aa4a1b9520aa649ff2d1c5`.
  config = pkgs.writeText "rust-config" ''
    # =============================================================================
    # Tweaking how LLVM is compiled
    # =============================================================================
    [llvm]

    # Indicates whether the LLVM build is a Release or Debug build
    optimize = false

    # Indicates whether LLVM should be built with ThinLTO. Note that this will
    # only succeed if you use clang, lld, llvm-ar, and llvm-ranlib in your C/C++
    # toolchain (see the `cc`, `cxx`, `linker`, `ar`, and `ranlib` options below).
    # More info at: https://clang.llvm.org/docs/ThinLTO.html#clang-bootstrap
    #thin-lto = false

    # Indicates whether an LLVM Release build should include debug info
    #release-debuginfo = false

    # Indicates whether the LLVM assertions are enabled or not
    assertions = true

    # Indicates whether ccache is used when building LLVM
    ccache = true
    # or alternatively ...
    #ccache = "/path/to/ccache"

    # If an external LLVM root is specified, we automatically check the version by
    # default to make sure it's within the range that we're expecting, but setting
    # this flag will indicate that this version check should not be done.
    #version-check = true

    # Link libstdc++ statically into the librustc_llvm instead of relying on a
    # dynamic version to be available.
    #static-libstdcpp = false

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
    targets = "AArch64;ARM;NVPTX;RISCV;X86"

    # LLVM experimental targets to build support for. These targets are specified in
    # the same format as above, but since these targets are experimental, they are
    # not built by default and the experimental Rust compilation targets that depend
    # on them will not work unless the user opts in to building them.
    #experimental-targets = ""

    # Cap the number of parallel linker invocations when compiling LLVM.
    # This can be useful when building LLVM with debug info, which significantly
    # increases the size of binaries and consequently the memory required by
    # each linker process.
    # If absent or 0, linker invocations are treated like any other job and
    # controlled by rustbuild's -j parameter.
    #link-jobs = 0

    # When invoking `llvm-config` this configures whether the `--shared` argument is
    # passed to prefer linking to shared libraries.
    #link-shared = false

    # When building llvm, this configures what is being appended to the version.
    # If absent, we let the version as-is.
    #version-suffix = "-rust"

    # On MSVC you can compile LLVM with clang-cl, but the test suite doesn't pass
    # with clang-cl, so this is special in that it only compiles LLVM with clang-cl
    #clang-cl = '/path/to/clang-cl.exe'

    # Pass extra compiler and linker flags to the LLVM CMake build.
    #cflags = "-fextra-flag"
    #cxxflags = "-fextra-flag"
    #ldflags = "-Wl,extra-flag"

    # Use libc++ when building LLVM instead of libstdc++. This is the default on
    # platforms already use libc++ as the default C++ library, but this option
    # allows you to use libc++ even on platforms when it's not. You need to ensure
    # that your host compiler ships with libc++.
    #use-libcxx = true

    # The value specified here will be passed as `-DLLVM_USE_LINKER` to CMake.
    #use-linker = "lld"

    # Whether or not to specify `-DLLVM_TEMPORARILY_ALLOW_OLD_TOOLCHAIN=YES`
    #allow-old-toolchain = false

    # =============================================================================
    # General build configuration options
    # =============================================================================
    [build]

    # Build triple for the original snapshot compiler. This must be a compiler that
    # nightlies are already produced for. The current platform must be able to run
    # binaries of this build triple and the nightly will be used to bootstrap the
    # first compiler.
    #build = "x86_64-unknown-linux-gnu"    # defaults to your host platform

    # In addition to the build triple, other triples to produce full compiler
    # toolchains for. Each of these triples will be bootstrapped from the build
    # triple and then will continue to bootstrap themselves. This platform must
    # currently be able to run all of the triples provided here.
    #host = ["x86_64-unknown-linux-gnu"]   # defaults to just the build triple

    # In addition to all host triples, other triples to produce the standard library
    # for. Each host triple will be used to produce a copy of the standard library
    # for each target triple.
    #target = ["x86_64-unknown-linux-gnu"] # defaults to just the build triple

    # Instead of downloading the src/stage0.txt version of Cargo specified, use
    # this Cargo binary instead to build all Rust code
    #cargo = "/path/to/bin/cargo"

    # Instead of downloading the src/stage0.txt version of the compiler
    # specified, use this rustc binary instead as the stage0 snapshot compiler.
    #rustc = "/path/to/bin/rustc"

    # Flag to specify whether any documentation is built. If false, rustdoc and
    # friends will still be compiled but they will not be used to generate any
    # documentation.
    #docs = true

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
    gdb = "${pkgs.unstable.gdb}/bin/gdb"

    # The node.js executable to use. Note that this is only used for the emscripten
    # target when running tests, otherwise this can be omitted.
    #nodejs = "node"

    # Python interpreter to use for various tasks throughout the build, notably
    # rustdoc tests, the lldb python interpreter, and some dist bits and pieces.
    # Note that Python 2 is currently required.
    #
    # Defaults to python2.7, then python2. If neither executable can be found, then
    # it defaults to the Python interpreter used to execute x.py.
    python = "${pkgs.python2Full}/bin/python"

    # Force Cargo to check that Cargo.lock describes the precise dependency
    # set that all the Cargo.toml files create, instead of updating it.
    #locked-deps = false

    # Indicate whether the vendored sources are used for Rust dependencies or not
    #vendor = false

    # Typically the build system will build the rust compiler twice. The second
    # compiler, however, will simply use its own libraries to link against. If you
    # would rather to perform a full bootstrap, compiling the compiler three times,
    # then you can set this option to true. You shouldn't ever need to set this
    # option to true.
    #full-bootstrap = false

    # Enable a build of the extended rust tool set which is not only the compiler
    # but also tools such as Cargo. This will also produce "combined installers"
    # which are used to install Rust and Cargo together. This is disabled by
    # default.
    #extended = false

    # Installs chosen set of extended tools if enabled. By default builds all.
    # If chosen tool failed to build the installation fails.
    #tools = ["cargo", "rls", "clippy", "rustfmt", "analysis", "src"]

    # Verbosity level: 0 == not verbose, 1 == verbose, 2 == very verbose
    #verbose = 0

    # Build the sanitizer runtimes
    #sanitizers = false

    # Build the profiler runtime
    #profiler = false

    # Indicates whether the native libraries linked into Cargo will be statically
    # linked or not.
    #cargo-native-static = false

    # Run the build with low priority, by setting the process group's "nice" value
    # to +10 on Unix platforms, and by using a "low priority" job object on Windows.
    #low-priority = false

    # Arguments passed to the `./configure` script, used during distcheck. You
    # probably won't fill this in but rather it's filled in by the `./configure`
    # script.
    #configure-args = []

    # Indicates that a local rebuild is occurring instead of a full bootstrap,
    # essentially skipping stage0 as the local compiler is recompiling itself again.
    #local-rebuild = false

    # Print out how long each rustbuild step took (mostly intended for CI and
    # tracking over time)
    #print-step-timings = false

    # =============================================================================
    # General install configuration options
    # =============================================================================
    [install]

    # Instead of installing to /usr/local, install to this path instead.
    #prefix = "/usr/local"

    # Where to install system configuration files
    # If this is a relative path, it will get installed in `prefix` above
    #sysconfdir = "/etc"

    # Where to install documentation in `prefix` above
    #docdir = "share/doc/rust"

    # Where to install binaries in `prefix` above
    #bindir = "bin"

    # Where to install libraries in `prefix` above
    #libdir = "lib"

    # Where to install man pages in `prefix` above
    #mandir = "share/man"

    # Where to install data in `prefix` above (currently unused)
    #datadir = "share"

    # Where to install additional info in `prefix` above (currently unused)
    #infodir = "share/info"

    # Where to install local state (currently unused)
    # If this is a relative path, it will get installed in `prefix` above
    #localstatedir = "/var/lib"

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
    debug = true

    # Number of codegen units to use for each compiler invocation. A value of 0
    # means "the number of cores on this machine", and 1+ is passed through to the
    # compiler.
    #codegen-units = 1

    # Sets the number of codegen units to build the standard library with,
    # regardless of what the codegen-unit setting for the rest of the compiler is.
    #codegen-units-std = 1

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
    debuginfo-level = 2

    # Debuginfo level for the compiler.
    #debuginfo-level-rustc = debuginfo-level

    # Debuginfo level for the standard library.
    #debuginfo-level-std = debuginfo-level

    # Debuginfo level for the tools.
    #debuginfo-level-tools = debuginfo-level

    # Debuginfo level for the test suites run with compiletest.
    # FIXME(#61117): Some tests fail when this option is enabled.
    #debuginfo-level-tests = 0

    # Whether or not `panic!`s generate backtraces (RUST_BACKTRACE)
    backtrace = true

    # Whether to always use incremental compilation when building rustc
    incremental = true

    # Build a multi-threaded rustc
    #parallel-compiler = false

    # The default linker that will be hard-coded into the generated compiler for
    # targets that don't specify linker explicitly in their target specifications.
    # Note that this is not the linker used to link said compiler.
    #default-linker = "cc"

    # The "channel" for the Rust build to produce. The stable/beta channels only
    # allow using stable features, whereas the nightly and dev channels allow using
    # nightly features
    #channel = "dev"

    # The root location of the MUSL installation directory.
    #musl-root = "..."

    # By default the `rustc` executable is built with `-Wl,-rpath` flags on Unix
    # platforms to ensure that the compiler is usable by default from the build
    # directory (as it links to a number of dynamic libraries). This may not be
    # desired in distributions, for example.
    #rpath = true

    # Emits extraneous output from tests to ensure that failures of the test
    # harness are debuggable just from logfiles.
    #verbose-tests = false

    # Flag indicating whether tests are compiled with optimizations (the -O flag).
    #optimize-tests = true

    # Flag indicating whether codegen tests will be run or not. If you get an error
    # saying that the FileCheck executable is missing, you may want to disable this.
    # Also see the target's llvm-filecheck option.
    #codegen-tests = true

    # Flag indicating whether git info will be retrieved from .git automatically.
    # Having the git information can cause a lot of rebuilds during development.
    # Note: If this attribute is not explicitly set (e.g. if left commented out) it
    # will default to true if channel = "dev", but will default to false otherwise.
    #ignore-git = true

    # When creating source tarballs whether or not to create a source tarball.
    #dist-src = false

    # After building or testing extended tools (e.g. clippy and rustfmt), append the
    # result (broken, compiling, testing) into this JSON file.
    #save-toolstates = "/path/to/toolstates.json"

    # This is an array of the codegen backends that will be compiled for the rustc
    # that's being compiled. The default is to only build the LLVM codegen backend,
    # and currently the only standard option supported is `"llvm"`
    #codegen-backends = ["llvm"]

    # This is the name of the directory in which codegen backends will get installed
    #codegen-backends-dir = "codegen-backends"

    # Indicates whether LLD will be compiled and made available in the sysroot for
    # rustc to execute.
    lld = true

    # Indicates whether some LLVM tools, like llvm-objdump, will be made available in the
    # sysroot.
    llvm-tools = true

    # Indicates whether LLDB will be made available in the sysroot.
    # This is only built if LLVM is also being built.
    lldb = true

    # Whether to deny warnings in crates
    deny-warnings = true

    # Print backtrace on internal compiler errors during bootstrap
    #backtrace-on-ice = false

    # Whether to verify generated LLVM IR
    #verify-llvm-ir = false

    # Map all debuginfo paths for libstd and crates to `/rust/$sha/$crate/...`,
    # generally only set for releases
    #remap-debuginfo = false

    # Link the compiler against `jemalloc`, where on Linux and OSX it should
    # override the default allocator for rustc and LLVM.
    #jemalloc = false

    # Run tests in various test suites with the "nll compare mode" in addition to
    # running the tests in normal mode. Largely only used on CI and during local
    # development of NLL
    test-compare-mode = false

    # Use LLVM libunwind as the implementation for Rust's unwinder.
    #llvm-libunwind = false

    # =============================================================================
    # Options for specific targets
    #
    # Each of the following options is scoped to the specific target triple in
    # question and is used for determining how to compile each target.
    # =============================================================================
    [target.x86_64-unknown-linux-gnu]

    # C compiler to be used to compiler C code. Note that the
    # default value is platform specific, and if not specified it may also depend on
    # what platform is crossing to what platform.
    #cc = "cc"

    # C++ compiler to be used to compiler C++ code (e.g. LLVM and our LLVM shims).
    # This is only used for host targets.
    #cxx = "c++"

    # Archiver to be used to assemble static libraries compiled from C/C++ code.
    # Note: an absolute path should be used, otherwise LLVM build will break.
    #ar = "ar"

    # Ranlib to be used to assemble static libraries compiled from C/C++ code.
    # Note: an absolute path should be used, otherwise LLVM build will break.
    #ranlib = "ranlib"

    # Linker to be used to link Rust code. Note that the
    # default value is platform specific, and if not specified it may also depend on
    # what platform is crossing to what platform.
    #linker = "cc"

    # Path to the `llvm-config` binary of the installation of a custom LLVM to link
    # against. Note that if this is specified we don't compile LLVM at all for this
    # target.
    #llvm-config = "../path/to/llvm/root/bin/llvm-config"

    # Normally the build system can find LLVM's FileCheck utility, but if
    # not, you can specify an explicit file name for it.
    #llvm-filecheck = "/path/to/FileCheck"

    # If this target is for Android, this option will be required to specify where
    # the NDK for the target lives. This is used to find the C compiler to link and
    # build native code.
    #android-ndk = "/path/to/ndk"

    # Force static or dynamic linkage of the standard library for this target. If
    # this target is a host for rustc, this will also affect the linkage of the
    # compiler itself. This is useful for building rustc on targets that normally
    # only use static libraries. If unset, the target's default linkage is used.
    #crt-static = false

    # The root location of the MUSL installation directory. The library directory
    # will also need to contain libunwind.a for an unwinding implementation. Note
    # that this option only makes sense for MUSL targets that produce statically
    # linked binaries
    #musl-root = "..."

    # The root location of the `wasm32-wasi` sysroot.
    #wasi-root = "..."

    # Used in testing for configuring where the QEMU images are located, you
    # probably don't want to use this.
    #qemu-rootfs = "..."

    # =============================================================================
    # Distribution options
    #
    # These options are related to distribution, mostly for the Rust project itself.
    # You probably won't need to concern yourself with any of these options
    # =============================================================================
    [dist]

    # This is the folder of artifacts that the build system will sign. All files in
    # this directory will be signed with the default gpg key using the system `gpg`
    # binary. The `asc` and `sha256` files will all be output into the standard dist
    # output folder (currently `build/dist`)
    #
    # This folder should be populated ahead of time before the build system is
    # invoked.
    #sign-folder = "path/to/folder/to/sign"

    # This is a file which contains the password of the default gpg key. This will
    # be passed to `gpg` down the road when signing all files in `sign-folder`
    # above. This should be stored in plaintext.
    #gpg-password-file = "path/to/gpg/password"

    # The remote address that all artifacts will eventually be uploaded to. The
    # build system generates manifests which will point to these urls, and for the
    # manifests to be correct they'll have to have the right URLs encoded.
    #
    # Note that this address should not contain a trailing slash as file names will
    # be appended to it.
    #upload-addr = "https://example.com/folder"

    # Whether to build a plain source tarball to upload
    # We disable that on Windows not to override the one already uploaded on S3
    # as the one built on Windows will contain backslashes in paths causing problems
    # on linux
    #src-tarball = true
    #

    # Whether to allow failures when building tools
    #missing-tools = false
  '';
  # Custom Vim configuration to disable ctags on directories we never want to look at.
  lvimrc = pkgs.writeText "rust-lvimrc" ''
    let g:gutentags_ctags_exclude = [
      "src/llvm-project",
      "src/librustdoc/html",
      "src/doc",
      "src/ci",
      "src/bootstrap",
      "*.md"
    ]
  '';
  # Files that are ignored by ripgrep when searching.
  rgignore = pkgs.writeText "rust-rgignore" ''
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
    src/bootstrap
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
  workmanConfig = pkgs.writeText "rust-workman_config" ''
    # Directory where working directories are kept.
    WORKDIR_PATH="."
    # Name of stamp file placed in active working directories.
    ACTIVE_STAMP_NAME=".workman_active_working_directory"
    # Name of stamp file placed in working directories that are updated but not assigned.
    DO_NOT_ASSIGN_STAMP_NAME=".workman_do_not_assign"

    # Use git worktrees.
    USE_GIT_WORKTREE="YES"

    # Name of project, used in working directory names.
    PROJECT_NAME="rust"
    # Default branch to check out and update.
    DEFAULT_BRANCH="master"

    # Name of upstream remote to create and update from.
    UPSTREAM_NAME="upstream"
    # Url of upstream remote to create and update from.
    UPSTREAM_URL="git@github.com:rust-lang/rust.git"

    # Name of origin remote to clone from.
    ORIGIN_NAME="origin"
    # Url of origin remote to clone from.
    ORIGIN_URL="git@github.com:davidtwco/rust.git"

    # Command to run before creating a new working directory.
    BEFORE_COMMAND="
    ln -s ${config} ./config.toml &&
    ln -s ${rgignore} ./.rgignore &&
    ln -s ${lvimrc} ./.lvimrc
    "
    # Command to run to clean a working directory.
    CLEAN_COMMAND="python2 x.py clean"
    # Command to run to build in a working directory.
    BUILD_COMMAND="python2 x.py build"
    # Command to run after creating a new working directory.
    AFTER_COMMAND="
    rustup toolchain link $(basename $(pwd))-stage1 ./build/x86_64-unknown-linux-gnu/stage1 &&
    rustup toolchain link $(basename $(pwd))-stage2 ./build/x86_64-unknown-linux-gnu/stage2
    "
  '';
in
pkgs.mkShell rec {
  name = "rust";
  buildInputs = with pkgs; [
    git
    pythonFull
    gnumake
    cmake
    curl
    clang

    libxml2
    ncurses
    swig

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

    # Working directory management.
    workman
  ];

  # Environment variable used by `workman` to find configuration.
  WORKMAN_CONFIG_FILE = workmanConfig;
}
