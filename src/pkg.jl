@static if Base.VERSION >= v"1.7-"
    const write_manifest = Pkg.Types.write_manifest
else
    function write_manifest(io::IO, manifest::Dict)
        print(io, "# This file is machine-generated - editing it directly is not advised\n\n")
        TOML.print(io, manifest, sorted=true) do x
            x isa UUID || x isa SHA1 || x isa VersionNumber || pkgerror("unhandled type `$(typeof(x))`")
            return string(x)
        end
        return nothing
    end
end
