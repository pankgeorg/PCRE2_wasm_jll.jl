using Test, PCRE2_wasm_jll, SHA, TOML, Artifacts, Pkg
using Base.BinaryPlatforms: Platform

const TOMLFILE = joinpath(pkgdir(PCRE2_wasm_jll), "Artifacts.toml")
const ENTRY = TOML.parsefile(TOMLFILE)["PCRE2_wasm"]
const V = pkgversion(PCRE2_wasm_jll)

@testset "PCRE2_wasm_jll" begin
    dir = PCRE2_wasm_jll.artifact_dir
    @test isdir(dir)
    @test basename(dir) == ENTRY["git-tree-sha1"]
    @test Pkg.Artifacts.verify_artifact(Base.SHA1(ENTRY["git-tree-sha1"]))
    @test isfile(joinpath(dir, "share", "licenses", "PCRE2_wasm", "LICENCE.md"))

    # a cross-compiler asks with an explicit wasm platform and gets the same artifact
    for p in (Platform("wasm32", "wasi"), Platform("wasm64", "wasi"))
        @test artifact_meta("PCRE2_wasm", TOMLFILE; platform = p)["git-tree-sha1"] == ENTRY["git-tree-sha1"]
    end

    # the standalone module: wasm, beside the wasm32 archive
    @test libpcre2_8_wasm32_wasm == joinpath(dir, "wasm32-wasip1", "lib", "libpcre2-8.wasm")
    @test read(libpcre2_8_wasm32_wasm)[1:4] == codeunits("\0asm")

    for (archive, manifest, flavour, abi) in (
            (libpcre2_8_wasm32_a, wasm_provider_wasm32, "wasm32-wasip1", "wasm32-wasip1-ilp32-v0"),
            (libpcre2_8_wasm64_a, wasm_provider_wasm64, "wasm64-unknown-unknown", "wasm64-lp64-freestanding-v0"))
        @testset "$flavour" begin
            @test archive == joinpath(dir, flavour, "lib", "libpcre2-8.a")
            @test manifest == joinpath(dir, flavour, "share", "wasm-provider.toml")
            @test isfile(joinpath(dir, flavour, "include", "pcre2.h"))
            bytes = read(archive)
            @test bytes[1:8] == codeunits("!<arch>\n")
            @test occursin("\0asm", String(copy(bytes)))
            m = TOML.parsefile(manifest)
            @test m["abi"] == abi
            @test m["native"]["name"] == "PCRE2_jll"
            @test m["native"]["uuid"] == "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
            @test m["native"]["version"] == string(VersionNumber(V.major, V.minor, V.patch))
            lib = m["libraries"]["libpcre2-8"]
            @test joinpath(dir, flavour, lib["archive"]) == archive
            @test bytes2hex(sha256(bytes)) == lib["sha256"]
            @test endswith(m["build"]["source"], "pcre2-$(V.major).$(V.minor).tar.bz2")
        end
    end
end
