export Environment

"""
    type Environment
        dictionary::Base.ImmutableDict{Symbol,Any}()
    end

A type to store all the names in your local environment.

Can access and record new values in an environment.

```jldoctest
julia> using LazyContext

julia> e = Environment();

julia> e[:a] = 1;

julia> e
Environment. Most recent assignment: a

julia> e[:a]
1
```

By default, contains an `:ENVIRONMENT` key which points to itself. If
the environment has a parent, it also will contain a `:PARENT` key which
points to its parent.
```jldoctest
julia> using LazyContext

julia> e = Environment();

julia> e[:a] = 1;

julia> e[:ENVIRONMENT][:a]
1

julia> e2 = copy(e);

julia> e2[:PARENT][:a]
1

julia> e2[:b] = 1;

julia> e2[:PARENT][:b]
ERROR: KeyError: key :b not found
[...]
```

Can `merge!` or `merge` new objects into an environment. You can merge in
modules:

```jldoctest
julia> using LazyContext

julia> e = Environment();

julia> merge!(e, Core);

julia> e[:Symbol]
Symbol
```

and dictonaries:
```jldoctest
julia> using LazyContext

julia> e = Environment();

julia> merge!(e, Dict(:a => 1) );

julia> e[:a]
1
```

Extend [`immutable_merge`](@ref) to be able to merge in more types.
"""
type Environment
    dictionary::Base.ImmutableDict{Symbol,Any}
    Environment(d::Base.ImmutableDict{Symbol, Any} = Base.ImmutableDict{Symbol, Any}()) = begin
        result = new(d)
        result[:ENVIRONMENT] = result
        result
    end
end

Base.show(io::IO, e::Environment) =
    print(io, "Environment. Most recent assignment: $(e.dictionary.key)")

Base.getindex(e::Environment, name) = e.dictionary[name]
Base.setindex!(e::Environment, value, name) = begin
    e.dictionary = Base.ImmutableDict(e.dictionary, name => value)
    e
end

Base.copy(e::Environment) = begin
    result = Environment(e.dictionary)
    result[:PARENT] = e
    result
end

Base.merge!(e::Environment, args...) = begin
    dictionary = e.dictionary
    for arg in args
        dictionary = immutable_merge(dictionary, arg)
    end
    e.dictionary = dictionary
    e
end

base_environment = merge!(Environment(), Core, Base)

export copy_of_base_environment
"""
    copy_of_base_environment()

Get an environment which contains `Core` and `Base`. Has no parent.
"""
copy_of_base_environment() = copy(base_environment)

export @new_environment
"""
    macro new_environment

Will create a new [`copy_of_base_environment`](@ref) named `ENVIRONMENT`.
Prerequisite for many macros in this package. Be careful not to overwrite
`ENVIRONMENT`.

```jldoctest
julia> using LazyContext

julia> @new_environment;

julia> Dict == ENVIRONMENT[:Dict]
true
```
"""
macro new_environment()
    :( ENVIRONMENT = $copy_of_base_environment() ) |> esc
end

export @import_to_environment
"""
    macro import_to_environment(args...)

Make `args`, a list of names, available in the global `ENVIRONMENT`.

```jldoctest
julia> using LazyContext

julia> @new_environment;

julia> import MacroTools;

julia> @import_to_environment LazyContext MacroTools;

julia> Environment == @evaluate LazyContext.Environment
true

julia> MacroTools.prettify == @evaluate MacroTools.prettify
true
```
"""
macro import_to_environment(args...)
    assignments = map(args) do arg
        :( ENVIRONMENT[$(Meta.quot(arg))] = $arg)
    end
    Expr(:block, assignments...) |> esc
end

export @use_in_environment
"""
    use_in_environmnet(args...)

Make the contents of each item in `args` available in the global `ENVIRONMENT`,
by merging in each one by one.

```jldoctest
julia> using LazyContext

julia> @new_environment;

julia> import MacroTools;

julia> @use_in_environment LazyContext MacroTools;

julia> Environment == @evaluate Environment
true

julia> MacroTools.prettify == @evaluate prettify
true
```
"""
macro use_in_environment(args...)
    :($merge!(ENVIRONMENT, $(args...) ) ) |> esc
end

export WithContext
"""
    type WithContext
        expression::Any
        environment::Environment
    end

An expression in the context of its [`Environment`](@ref)
"""
type WithContext
    expression::Any
    environment::Environment
end

Base.show(io::IO, w::WithContext) =
    print(io, string("WithContext($(w.expression))") )

Base.copy(w::WithContext) = WithContext( copy(w.expression), copy(w.environment) )
