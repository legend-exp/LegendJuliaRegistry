#!/usr/bin/env julia

targetdir = get(ARGS, 1, ".")
cd(targetdir)

if !isdir(".git")
    error("Current directory is not a git repository.")
end

run(`git pull origin main`)

using Pkg
Pkg.activate(".")

package_name = Pkg.project().name
package_version = Pkg.project().version
@assert !isnothing(package_name) && !isnothing(package_version)

if !startswith(Pkg.project().name, "Legend")
    error("This doesn't look like a LEGEND Julia package.")
end

@info "Register package $package_name in LegendJuliaRegistry"

if length(ARGS) > 1
    new_version = ARGS[2]

    if !occursin(r"^\d+\.\d+\.\d+$", new_version)
        error("Version format not correct, should be MAJOR.MINOR.PATCH where each is an integer")
    end

    old_version_parts = split(string(package_version), ".")
    new_version_parts = split(new_version, ".")

    old_major, old_minor, old_patch = parse.(Int, old_version_parts)
    new_major, new_minor, new_patch = parse.(Int, new_version_parts)

    if (new_major, new_minor, new_patch) <= (old_major, old_minor, old_patch)
        error("New version must be greater than the current version $package_version")
    end

    @info "Updating package version from $package_version to $new_version"
    proj_path = joinpath(pwd(), "Project.toml")
    lines = readlines(proj_path)
    open(proj_path, "w") do io
        for line in lines
            if startswith(strip(line), "version =")
                println(io, "version = \"$new_version\"")
            else
                println(io, line)
            end
        end
    end

    run(`git add Project.toml`)
    run(`git commit -m "Increase package version to $new_version"`)
    run(`git push origin main`)
else
    @info "Using package version $package_version"
end

Pkg.activate(".")

package_name = Pkg.project().name
package_version = Pkg.project().version
@assert !isnothing(package_name) && !isnothing(package_version)

# Remove possibly stale Manifest.toml
isfile("Manifest.toml") && rm("Manifest.toml")

Pkg.resolve()


#Pkg.test(package_name)

#using TestEnv; TestEnv.activate()
#
#cd("docs") do
#    @info pwd()
#    include(joinpath(pwd(), "make.jl"))
#end

Pkg.activate(".")
using LocalRegistry; register(registry = "LegendJuliaRegistry")
run(`git tag -a v$package_version -m v$package_version`)
run(`git push origin v$package_version`)

# Remove left-over Manifest.toml
isfile("Manifest.toml") && rm("Manifest.toml")

@info("Successfully registered $package_name $package_version")

gh_available = Sys.isunix() ? !isempty(Sys.which("gh")) : false
if !gh_available
    @warn "The 'gh' command (GitHub CLI) is not available on this system, please create release manually"
    exit(0)
end

# Check if gh is authenticated
auth_status = readchomp(pipeline(`gh auth status --hostname github.com`, stderr=stdout))
if occursin("You are not logged into any GitHub hosts", auth_status) || occursin("not logged in", auth_status)
    @warn "The 'gh' command is not authenticated. Please run 'gh auth login' and create release manually with 'gh release create v$package_version --generate-notes'"
    exit(0)
end

# Check if user has permission to create releases
repo_info = readchomp(pipeline(`gh repo view --json viewerPermission --jq '.viewerPermission'`, stderr=stdout))
if isempty(repo_info) || repo_info != "ADMIN"
    error("You do not have permission to create releases in this repository, please contact your administrator.")
end

run(`gh release create v$package_version --generate-notes`)
@info "Successfully created GitHub release v$package_version"