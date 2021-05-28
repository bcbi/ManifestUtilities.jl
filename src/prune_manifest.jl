const _prune_manifest_kwargs_docstring = """
## Required Keyword Arguments

You must specify one (and exactly one) of `project` and `project_filename`.
Similarly, you must specify one (and exactly one) of `manifest` and
`manifest_filename`.

- `project::Union{AbstractString, IO}`: the contents of the input `Project.toml` file
- `project_filename::AbstractString`: the filename of the input `Project.toml` file
- `manifest::Union{AbstractString, IO}`: the contents of the input `Manifest.toml` file
- `manifest_filename::AbstractString`: the filename of the input `Manifest.toml` file
"""

"""
    prune_manifest(; kwargs...) --> new_manifest::AbstractString

Parse the given project and manifest, and generate a new manifest that only
includes packages that are direct or indirect (recursive) dependencies of the
given project. The new manifest is returned as an `AbstractString`.

$(_prune_manifest_kwargs_docstring)
"""
function prune_manifest(; kwargs...)
    return sprint(io -> prune_manifest(io; kwargs...))
end

"""
    prune_manifest(io::IO; kwargs...)

Parse the given project and manifest, and generate a new manifest that only
includes packages that are direct or indirect (recursive) dependencies of the
given project. The new manifest is printed to the given `IO`.

$(_prune_manifest_kwargs_docstring)
"""
function prune_manifest(io::IO;
                        project::Union{AbstractString, IO, Nothing}       = nothing,
                        project_filename::Union{AbstractString, Nothing}  = nothing,
                        manifest::Union{AbstractString, IO, Nothing}      = nothing,
                        manifest_filename::Union{AbstractString, Nothing} = nothing)
    if (project !== nothing) && (project_filename !== nothing)
        throw(ArgumentError("You may not specify both `project` or `project_filename`; you must only specify one"))
    elseif (project !== nothing) && (project_filename === nothing)
        project_dict = TOML.parse(project)
    elseif (project === nothing) && (project_filename !== nothing)
        project_dict = TOML.parsefile(project_filename)
    else
        throw(ArgumentError("You must specify either `project` or `project_filename`"))
    end
    if (manifest !== nothing) && (manifest_filename !== nothing)
        throw(ArgumentError("You may not specify both `manifest` or `manifest_filename`; you must only specify one"))
    elseif (manifest !== nothing) && (manifest_filename === nothing)
        manifest_dict = TOML.parse(manifest)
    elseif (manifest === nothing) && (manifest_filename !== nothing)
        manifest_dict = TOML.parsefile(manifest_filename)
    else
        throw(ArgumentError("You must specify either `manifest` or `manifest_filename`"))
    end

    project_struct = ProjectTOMLDict(project_dict)
    manifest_struct = ManifestTOMLDict(manifest_dict)
    return prune_manifest(io, project_struct, manifest_struct)
end

function prune_manifest(io::IO,
                        project::ProjectTOMLDict,
                        manifest::ManifestTOMLDict)
    name_to_uuid = Dict{String, Base.UUID}()

    for (name, infos_vec) in pairs(manifest.manifest)
        info = only(infos_vec)
        uuid_string = info["uuid"]
        uuid = Base.UUID(uuid_string)
        condition = !haskey(name_to_uuid, name)
        msg = "duplicate package with name `$(name)`"
        condition || throw(ErrorException(msg))
        name_to_uuid[name] = uuid
    end

    for (name, uuid_string_from_project) in pairs(project.project["deps"])
        uuid_from_project = Base.UUID(uuid_string_from_project)
        condition_1 = haskey(name_to_uuid, name)
        msg_1 = "Manifest does not have a dep with name $(name)"
        condition_1 || throw(ErrorException(msg_1))
        uuid_from_manifest = name_to_uuid[name]
        condition_2 = uuid_from_project == uuid_from_manifest
        msg_2 = "For dep $(name), project UUID $(uuid_from_project) does not match manifest UUID $(uuid_from_manifest)"
        condition_2 || throw(ErrorException(msg_2))
    end

    graph = MetaGraphs.MetaDiGraph()
    MetaGraphs.set_indexing_prop!(graph, :uuid)
    for uuid in values(name_to_uuid)
        MetaGraphs.add_vertex!(graph, :uuid, uuid)
    end

    for (name, infos_vec) in pairs(manifest.manifest)
        info = only(infos_vec)
        uuid_string = info["uuid"]
        uuid = Base.UUID(uuid_string)
        deps_names = get(info, "deps", String[])
        for dep_name in deps_names
            dep_uuid = name_to_uuid[dep_name]
            a = graph[uuid, :uuid]
            b = graph[dep_uuid, :uuid]
            MetaGraphs.add_edge!(
                graph,
                graph[uuid, :uuid],
                graph[dep_uuid, :uuid],
            )
        end
    end

    project_recursive_dependencies_uuids = Set{Base.UUID}()

    for (name, uuid_string_from_project) in pairs(project.project["deps"])
        uuid_from_project = Base.UUID(uuid_string_from_project)
        out_pars_indices = MetaGraphs.bfs_parents(graph, graph[uuid_from_project, :uuid]; dir = :out)
        nonzero_out_pars_indices  = findall(x -> x != 0, out_pars_indices)
        nonzero_out_pars_uuids = getindex.(Ref(graph), nonzero_out_pars_indices, :uuid)
        for nonzero_out_par_uuid in nonzero_out_pars_uuids
            push!(project_recursive_dependencies_uuids, nonzero_out_par_uuid)
        end
    end

    output_manifest_dict = Dict{String, Any}()
    for (name, infos_vec) in pairs(manifest.manifest)
        info = only(infos_vec)
        uuid_string = info["uuid"]
        uuid = Base.UUID(uuid_string)
        if uuid in project_recursive_dependencies_uuids
            output_manifest_dict[name] = infos_vec
        end
    end

    write_manifest(io, output_manifest_dict)

    return nothing
end
