# Use baremodule to shave off a few KB from the serialized `.ji` file
baremodule PCRE2_wasm_jll
using Base
using Base: UUID
import JLLWrappers

JLLWrappers.@generate_main_file_header("PCRE2_wasm")
JLLWrappers.@generate_main_file("PCRE2_wasm", Base.UUID("8ba14a24-31f9-58b7-aede-60c6b67cf7b6"))
end  # module PCRE2_wasm_jll
