struct ProjectTOMLDict{T <: AbstractDict}
    project::T
end

struct ManifestTOMLDict{T <: AbstractDict}
    manifest::T
end

@enum ManifestFormatVersion manifest_format_1_0
