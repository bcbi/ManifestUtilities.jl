using ManifestUtilities
using Test

@testset "manifest_format_1_0" begin
    format_dir = joinpath(@__DIR__, "manifest_format_1_0")
    @testset "test_1" begin
        test_dir = joinpath(format_dir, "test_1")
        project_filename = joinpath(test_dir, "Project_in.toml")
        manifest_filename = joinpath(test_dir, "Manifest_in.toml")
        project = read(project_filename, String)
        manifest = read(manifest_filename, String)
        kwargs_list = [
            (;
                project,
                manifest,
            ),
            (;
                project = IOBuffer(project),
                manifest = IOBuffer(manifest),
            ),
            (;
                project_filename,
                manifest_filename,
            ),
        ]
        for kwargs in kwargs_list
            x_1_a = prune_manifest(; deepcopy(kwargs)...)
            x_1_b = sprint(io -> prune_manifest(io; deepcopy(kwargs)...))
            @test strip(x_1_a) == strip(x_1_b)
            x_2 = read(joinpath(test_dir, "Manifest_out_correct.toml"), String)
            x_3 = read(joinpath(test_dir, "Manifest_out_incorrect.toml"), String)
            for x_1 in [x_1_a, x_1_b]
                @test strip(x_1) == strip(x_2)
                @test strip(x_2) != strip(x_3)
            end
        end
    end
end

@testset "errors" begin
    format_dir = joinpath(@__DIR__, "manifest_format_1_0")
    test_dir = joinpath(format_dir, "test_1")
    project_filename = joinpath(test_dir, "Project_in.toml")
    manifest_filename = joinpath(test_dir, "Manifest_in.toml")
    project = read(project_filename, String)
    manifest = read(manifest_filename, String)
    kwargs_and_exceptions = [
        (;) => ArgumentError,
        (;
            project,
        ) => ArgumentError,
        (;
            project,
            project_filename,
        ) => ArgumentError,
        (;
            manifest,
            manifest_filename,
        ) => ArgumentError,
    ]
    for (kwargs, ex) in kwargs_and_exceptions
        @test_throws ex prune_manifest(; deepcopy(kwargs)...)
        @test_throws ex sprint(io -> prune_manifest(io; deepcopy(kwargs)...))
    end
end
