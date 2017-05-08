map_expression(f, e) = Expr(e.head, map(f, e.args)...)

export immutable_merge
"""
    immutable_merge(d, a)

Merge `d` (usually an `ImmutableDict`) and `a` into a new `ImmutableDict`.
For example:

```jldoctest
julia> using LazyContext

julia> d = Base.ImmutableDict{Symbol, Any}();

julia> a = Dict(:b => 2);

julia> immutable_merge(d, a)[:b]
2
```
"""
immutable_merge(d, a) = begin
    for (key, value) in a
        d = Base.ImmutableDict(d, key => value)
    end
    d
end

immutable_merge(d, m::Module) = begin
    for name in names(m)
        d = Base.ImmutableDict(d, name => getfield(m, name) )
    end
    d
end
