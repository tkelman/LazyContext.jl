export WithContext

# when get/set, will create get/set expressions for the underlying environment
type MetaEnvironment
    name::Symbol
    variables::Set{Symbol}
    locked::Bool
end

MetaEnvironment(; name = gensym(), variables = Set{Symbol}(), locked = false) =
    MetaEnvironment(name, variables, locked)

Base.getindex(m::MetaEnvironment, s::Symbol) =
    if m.locked
        push!(m.variables, s)
        s
    else
        :( $(m.name)[ $(Meta.quot(s)) ] )
    end

assign!(meta, name, value) =
    if meta.locked
        error("Cannot assign $value to $name: environment is locked")
    else
        Expr(:(=), meta[name], value)
    end

set_argument!(old_meta, new_meta, expression) =
    if MacroTools.isexpr(expression, :parameters)
        map_expression(expression) do arg
            set_argument!(old_meta, new_meta, arg)
        end
    else
        MacroTools.@match expression begin
            (name_ = value_) => Expr(:kw, set_argument!(old_meta, new_meta, name), old_meta[value] )
            dotted_... =>
                Expr(:..., set_argument!(old_meta, new_meta, dotted) )
            typed_::atype_ =>
                error("In $expression: function type annotations not supported (yet)")
            s_Symbol => new_meta[s]
            any_ => error("Cannot parse argument $any")
        end
    end

anonymous_function(old_meta, args, body) = begin
    new_meta = MetaEnvironment(locked = true)
    new_args = map(args) do arg
        set_argument!(old_meta, new_meta, arg)
    end
    new_meta.locked = false
    assignments = map(new_meta.variables) do variable
        assign!(new_meta, variable, variable)
    end
    :( ($(new_args...),) -> begin
        $(new_meta.name) = $copy( $(old_meta.name) )
        $( assignments...)
        $( new_meta[body] )
    end)
end

function_error(name) =
    error("Cannot create named function $name: named functions not supported (yet)")

Base.getindex(m::MetaEnvironment, a) = a
Base.getindex(m::MetaEnvironment, e::Expr) =
    if e.head in [:macro, :import, :export, :comprehension, :generator,
        :local, :global, :const, :module, :immutable, :type, :abstract, :for,
        :let, :function]
        error("$(e.head) expressions not supported (yet)")
    elseif e.head == :line
        e
    else
        MacroTools.@match e begin
            ( name_(args__) = body_) =>
                function_error(name)
            ( name_(args__)::atype_ = body_) =>
                function_error(name)
            (name_ = value_) => begin
                head = MacroTools.prettify(e).head
                if head == :(=)
                    assign!(m, name, m[value] )
                elseif head == :kw
                    Expr(:kw, name, m[value] )
                else
                    "$e not a keyword or assignment"
                end
            end
            ( (args__,) -> body_ ) => anonymous_function(m, args, body)
            ( arg_ -> body_ ) => anonymous_function(m, (arg,), body)
            @macrocall_(args__) => begin
                name = string(macrocall)
                new_name = if startswith(name, "@")
                    name[2:end] |> Symbol
                else
                    error("Was expecting macrocall $name to start with @")
                end
                context_args = map(args) do arg
                    :( $WithContext( $(Meta.quot(arg)), $(m.name) ) )
                end
                Expr(:call,
                    m[ new_name ],
                    context_args...)
            end
            :quoted_ => e
            any_ => map_expression(any) do arg
                m[arg]
            end
        end
    end
