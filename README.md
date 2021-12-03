# Custom Julia package registry for the LEGEND experiment

This registry is intended for open-source Julia packages developed for the [LEGEND experiment](https://legend-exp.org/) that are too application-specific for the [Julia General](https://github.com/JuliaRegistries/General) registry.

To activate this registry, start Julia and run

```julia
julia> using Pkg; pkg"registry add General https://github.com/legend-exp/LegendJuliaRegistry.git"
```
