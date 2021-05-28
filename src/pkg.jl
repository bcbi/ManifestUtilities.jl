function _write_manifest(io::IO, manifest::Dict)
    print(io, "# This file is machine-generated - editing it directly is not advised\n\n")
    TOML.print(io, manifest, sorted=true) do x
        (x isa UUID || x isa SHA1 || x isa VersionNumber) && return string(x)
        error("unhandled type `$(typeof(x))`")
    end
    return nothing
end

# TODO: use the version of `write_manifest` in Pkg
const write_manifest = _write_manifest
