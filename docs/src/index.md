# LazyContext.jl

`LazyContext` makes true lazy evaluation easy. Here is a simple port of `with` in R.

```jldoctest
julia> using LazyContext

julia> with(d::WithContext, e::WithContext) = begin
           d_evaluated = evaluate!(d)
           e_copy = copy(e)
           merge!(e_copy.environment, d_evaluated)
           evaluate!(e_copy)
       end;

julia> @new_environment;

julia> @import_to_environment with;

julia> @evaluate begin
           d = Dict(:a => 1, :b => 2)
           @with d a + b
       end
3
```

Merging will work for any type which can be key-value iterated.

```@index
```

```@autodocs
Modules = [LazyContext]
```
