#!/usr/bin/env julia

targetdir = get(ARGS, 1, ".")
cd(targetdir)

using Pkg
Pkg.activate(".")

package_name = Pkg.project().name
package_version = Pkg.project().version
@assert !isnothing(package_name) && !isnothing(package_version)

if !startswith(Pkg.project().name, "Legend")
    error("This doesn't look like a LEGEND Julia package.")
end


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

@info("Successfully registered $package_name $package_version, please create release on GitHub manually.")
