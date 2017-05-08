using LazyContext
using Base.Test

import Documenter
Documenter.makedocs(
    modules = [LazyContext],
    format = :html,
    sitename = "LazyContext.jl",
    root = joinpath(dirname(dirname(@__FILE__)), "docs"),
    pages = Any["Home" => "index.md"],
    strict = true,
    linkcheck = true,
    authors = "Brandon Taylor"
)

@new_environment

@test_throws ErrorException LazyContext.anonymous(:(test(a) = a))
@test_throws ErrorException LazyContext.anonymous(:(test(a)::Int = a))
@test_throws ErrorException evaluate!(WithContext(Expr(:macrocall, Symbol(:no_at)), ENVIRONMENT))
@test_throws ErrorException LazyContext.anonymous(:(function(x) x end))
@test_throws ErrorException LazyContext.anonymous(:((x + y) -> x))
