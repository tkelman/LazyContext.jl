using LazyContext

import Documenter
Documenter.makedocs(
    modules = [LazyContext],
    format = :html,
    sitename = "LazyContext.jl",
    root = joinpath(dirname(dirname(@__FILE__)), "docs"),
    pages = Any["Home" => "index.md"],
    strict = true,
    linkcheck = true,
    checkdocs = :exports,
    authors = "Brandon Taylor"
)

using Base.Test

# write your own tests here
@test 1 == 1
