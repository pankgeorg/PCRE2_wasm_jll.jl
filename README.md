# PCRE2_wasm_jll.jl

[PCRE2](https://github.com/PCRE2Project/pcre2) compiled to **WebAssembly**, as static archives and as a standalone module, packaged as a JLL for Julia programs compiled to WebAssembly (e.g. with [WasmCodegen.jl](https://github.com/gbaraldi/WasmCodegen.jl)). It is input to a linker or to a WebAssembly host, not a library Julia loads: nothing here is `dlopen`ed.

> **Interim package.** This package stands in for `PCRE2_wasm_jll` until [JuliaPackaging/Yggdrasil#15468](https://github.com/JuliaPackaging/Yggdrasil/pull/15468) is merged and registered.
>
> It is what Yggdrasil's registration would generate from that recipe:
> - the same name, and the same UUID (`8ba14a24-31f9-58b7-aede-60c6b67cf7b6`, BinaryBuilder's `jll_uuid("PCRE2_wasm_jll")`);
> - the same artifact name, `PCRE2_wasm`;
> - the same products.
>
> Once the registered package exists, switching needs no code change: `pkg> free PCRE2_wasm_jll`, or remove it and `add` it again from the registry.

## Versions

The PCRE2 version must equal the `PCRE2_jll` of the Julia that compiles the program, because error behaviour differs between PCRE2 releases.

| Julia | `PCRE2_jll` | This package | Install |
|---|---|---|---|
| 1.13.2 | 10.46.0+0 | 10.46.0+1 (`main`, tag `PCRE2-v10.46.0+1`), with the standalone module | `pkg> add https://github.com/pankgeorg/PCRE2_wasm_jll.jl` |
| 1.13.2 | 10.46.0+0 | 10.46.0+0 (tag `PCRE2-v10.46.0+0`), archives only | `pkg> add https://github.com/pankgeorg/PCRE2_wasm_jll.jl#PCRE2-v10.46.0+0` |
| 1.13.3 | 10.47.0+0 | 10.47.0+1 (tag `PCRE2-v10.47.0+1`), with the standalone module | `pkg> add https://github.com/pankgeorg/PCRE2_wasm_jll.jl#PCRE2-v10.47.0+1` |
| 1.13.3 | 10.47.0+0 | 10.47.0+0 (branch `pcre2-10.47`, tag `PCRE2-v10.47.0+0`), archives only | `pkg> add https://github.com/pankgeorg/PCRE2_wasm_jll.jl#PCRE2-v10.47.0+0` |

## Contents

The artifact holds two flavours, each self-contained:

| Flavour | ABI | libc | Product |
|---|---|---|---|
| `wasm32-wasip1/` | ILP32 (`size_t` = 4) | link wasi-libc (wasi-sdk 34) | `libpcre2_8_wasm32_a` |
| `wasm64-unknown-unknown/` | LP64, freestanding, memory64 | none: the consumer supplies the symbols listed under `needs` | `libpcre2_8_wasm64_a` |

Each flavour has:

- `lib/libpcre2-8.a`;
- `include/pcre2.h`;
- `share/licenses/PCRE2/`;
- `share/wasm-provider.toml` (products `wasm_provider_wasm32` and `wasm_provider_wasm64`).

`wasm32-wasip1/` also has **`lib/libpcre2-8.wasm`** (product `libpcre2_8_wasm32_wasm`): the same
archive linked with wasi-libc into a standalone module that **imports nothing**, for a host or a
program that calls PCRE2 as a separate instance with its own memory instead of linking it. It exports:

- PCRE2's whole 8-bit API (`pcre2_compile_8`, `pcre2_match_8`, ...), where pointers and sizes are
  32-bit addresses and lengths in the module's memory;
- `memory`, `malloc` and `free`;
- `mem_load8`, `mem_load32`, `mem_load64`, `mem_store8`, `mem_store32` and `mem_store64` (address,
  value): loads and stores by address, for a caller that cannot reach the module's memory directly,
  such as another WebAssembly module whose imports are wired to these exports.

It has 1 MiB of stack. Its size is about 400 KB, 110 KB gzipped (10.46: 399 KB; 10.47: 405 KB).

The provider manifest records:

- the native JLL it mirrors (`PCRE2_jll`, its UUID and version);
- the archive's sha256;
- the undefined symbols it needs from outside (`needs`);
- the source, compiler, sysroot and recipe.

The build configuration is 8-bit code units, Unicode, **no JIT** (sljit has no WebAssembly backend) and static only. Other settings are PCRE2's defaults (LINK_SIZE 2, LF newline, default limits), as in the native `PCRE2_jll`.

## Usage

```julia
using PCRE2_wasm_jll
PCRE2_wasm_jll.libpcre2_8_wasm64_a     # .../wasm64-unknown-unknown/lib/libpcre2-8.a
PCRE2_wasm_jll.wasm_provider_wasm64    # its manifest
PCRE2_wasm_jll.libpcre2_8_wasm32_wasm  # .../wasm32-wasip1/lib/libpcre2-8.wasm, the standalone module
```

In JavaScript, the module instantiates with no imports:

```js
const { instance } = await WebAssembly.instantiate(fs.readFileSync(path), {});
const { pcre2_compile_8, pcre2_match_8, malloc, memory } = instance.exports;
```

The artifact is platform-independent (`AnyPlatform`): the same bytes on every host, installed by plain `Pkg.add`. A cross-compiler that looks artifacts up for an explicit wasm platform gets the same entry, and then picks the flavour directory for its ABI:

```julia
using Pkg.Artifacts, Base.BinaryPlatforms
toml = joinpath(pkgdir(PCRE2_wasm_jll), "Artifacts.toml")
dir = ensure_artifact_installed("PCRE2_wasm", toml; platform = Platform("wasm64", "wasi"))
joinpath(dir, "wasm64-unknown-unknown")
```

## Why a JLL, and not a host or compatibility package

- **Host packages, like WasmHost.jl, provide capabilities from the host.** These are functions the embedding environment implements and the module imports.
- **[WasmCompat.jl](https://github.com/pankgeorg/WasmCompat.jl) overlays standard libraries** so they run in WebAssembly.
- **A C library compiled to WebAssembly is neither.** It's a build artifact of a JLL's library, linked into the module, and it belongs where Yggdrasil will put it.

## Provenance

| | |
|---|---|
| Source | https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.46/pcre2-10.46.tar.bz2, sha256 `15fbc5aba6beee0b17aecb04602ae39432393aba1ebd8e39b7cabf7db883299f` (10.47: `pcre2-10.47.tar.bz2`, sha256 `47fe8c99461250d42f89e6e8fdaeba9da057855d06eb7fc08d9ca03fd08d7bc7`) |
| Recipe | [pankgeorg/Yggdrasil@8291fc176](https://github.com/pankgeorg/Yggdrasil/tree/8291fc176/P/PCRE2_wasm), branch `wasm-data-jlls-pcre2-module` (`P/PCRE2_wasm/build_tarballs.jl`, `bundled/pcre2_wasm_memory.c`, `platforms/wasm.jl`); 10.46.0+0 and 10.47.0+0: [@cbc4370da](https://github.com/pankgeorg/Yggdrasil/tree/cbc4370da822/P/PCRE2_wasm), branch `wasm-data-jlls` |
| Builder | BinaryBuilder.jl `d2b11c2`, BinaryBuilderBase.jl `f705a01` (master on 2026-11-05), Julia 1.13.2, BinaryBuilder's sandbox, `AnyPlatform` |
| Compiler | clang 23.1.1 from BinaryBuilder's LLVMBootstrap 23.1.1 shard (llvm-project `6dfe1677ab8dffbc6ec13d53a1e0215d75147689`) |
| Sysroot | `wasi-sysroot-34.0.tar.gz`, sha256 `9d813544eeebe38b7b8f2244ed591de46b6db812c6dd1a257ff9f0d2a905a2be` |
| Builtins | `libclang_rt-34.0.tar.gz`, sha256 `eee3e634dcf71aa22b1333391623cf5c9965a637dc428a27b1a858c026c587f1` |

The 10.47 build uses the same recipe with `version = v"10.47.0"` and the 10.47 source hash; nothing else changes.

| Release asset | git-tree-sha1 | sha256 |
|---|---|---|
| `PCRE2_wasm.v10.46.0.any.tar.gz` (10.46.0+1, with the module) | `2aeb9a5bad8546a8a6513db5e32c55c866675ea1` | `94a5253ac4a5145a19caa6d3c640d5cae4a7bb9fe294f3360ae2281a97dbf97f` |
| `PCRE2_wasm.v10.46.0.any.tar.gz` (10.46.0+0) | `ebc55b10c9ab6e116c314ed22db4ed1fb453cf85` | `8ec3139e6813d56ebd16ae3208b2f41dbfc847e4a6f5ead226bd8545df2fb394` |
| `PCRE2_wasm.v10.47.0.any.tar.gz` (10.47.0+1, with the module) | `ba75a42ff64da39fa3e81dd5a8b6aa502c3f2045` | `7078af747e1e08f55dd0b53a72aaa299e1551590242ba288bae98b6bc3a2a8af` |
| `PCRE2_wasm.v10.47.0.any.tar.gz` (10.47.0+0) | `6fc67893fb4fafa6a4cf521633675f2627686c8c` | `675d01a94bdcc81f336a1713178ac508074ccb5a27541b951d0138c371801171` |

The builds are reproducible: rebuilding the recipe gave a byte-identical tarball. The build logs are attached to each release as `PCRE2_wasm-logs.*.tar.gz`.

## License

The Julia code in this repository (`src/`, `test/`) is MIT-licensed; see [LICENSE](LICENSE). PCRE2 is distributed under `BSD-3-Clause WITH PCRE2-exception`. Its licence is in [LICENCE-PCRE2.md](LICENCE-PCRE2.md), and inside the artifact at `share/licenses/PCRE2_wasm/LICENCE.md` and in each flavour's `share/licenses/PCRE2/`.
