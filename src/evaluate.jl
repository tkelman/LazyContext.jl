anonymous(expression; locked = false) = begin
    meta = MetaEnvironment(locked = locked)
    body = meta[expression]
    wrapped_body = if locked
        variables = collect(meta.variables)
        meta.locked = false
        refs = map(variables) do variable
            meta[variable]
        end
        :( ( ($(variables...),) -> $body)( $(refs...) ) )
    else
        body
    end
    :( ( $(meta.name) -> $wrapped_body ) )
end

export evaluate!
"""
    evaluate!(w; locked = false)

Evaluate `w.expression` in context of `w.environment`.

Unlocked environments cannot be directly accessed in a type stable way. If you
include the `locked = true` keyword, however, the bindings in the `environment`
will be fixed allowing for type-stable access.

```jldoctest
julia> using LazyContext

julia> @new_environment;

julia> ENVIRONMENT[:a] = 1;

julia> ENVIRONMENT[:b] = 2;

julia> w = WithContext(:(a + b), ENVIRONMENT);

julia> evaluate!(w)
3

julia> evaluate!(w, locked = true)
3

julia> evaluate!( WithContext(:(a = 1), ENVIRONMENT), locked = true)
ERROR: Cannot assign 1 to a: environment is locked
[...]
```
"""
evaluate!(w; locked = false) = begin
    anon = anonymous(w.expression; locked = locked)
    environment_function = function() w.environment end
    :( $anon( $environment_function() ) ) |> eval
end

export @evaluate
"""
    macro evaluate(expression)

[`evaluate!`](@ref) `expression` in the context of `ENVIRONMENT`.

Only limited syntax is supported inside `@evaluate`.

Anonymous are suppported, but only using the terse syntax.

```jldoctest
julia> using LazyContext

julia> @new_environment;

julia> @evaluate begin
           test_function = (a, b...; c = 1) -> +(a, c, b...)
           test_function(1, 2, 3; c = 4)
       end
10
```

Anonymous functions create new environments. The parent environment can be
accessed with `PARENT`, while the local environment can be accessed with
`ENVIRONMENT`.

```jldoctest
julia> using LazyContext

julia> @new_environment;

julia> @evaluate begin
           a = 1
           test = b -> begin
               merge!(ENVIRONMENT, Dict(:a => 2))
               a + b + PARENT[:a]
           end
           test(3)
       end
6
```

Anonymous functions use dynamic scoping: changes in global variables will change
functions which reference them.

```jldoctest
julia> using LazyContext

julia> @new_environment;

julia> (3, 4) == @evaluate begin
           a = 1
           test = b -> a + b
           first_result = test(2)
           a = 2
           second_result = test(2)
           first_result, second_result
       end
true
```

Macro calls do not call macros. Instead, they create `WithContext` expression
wrappers out of all arguments and pass them to the function with the same name.

```jldoctest
julia> using LazyContext

julia> @new_environment;

julia> e = @evaluate begin
           a = 1
           b = 2
           @identity a + b
       end
WithContext(a + b)

julia> evaluate!(e)
3
```
"""
macro evaluate(expression)
    :( $( anonymous(expression) )(ENVIRONMENT) ) |> esc
end
