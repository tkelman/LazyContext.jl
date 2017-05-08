var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#LazyContext.Environment",
    "page": "Home",
    "title": "LazyContext.Environment",
    "category": "Type",
    "text": "type Environment\n    dictionary::Base.ImmutableDict{Symbol,Any}()\nend\n\nA type to store all the names in your local environment.\n\nCan access and record new values in an environment.\n\njulia> using LazyContext\n\njulia> e = Environment();\n\njulia> e[:a] = 1;\n\njulia> e\nEnvironment. Most recent assignment: a\n\njulia> e[:a]\n1\n\nBy default, contains an :ENVIRONMENT key which points to itself. If the environment has a parent, it also will contain a :PARENT key which points to its parent.\n\njulia> using LazyContext\n\njulia> e = Environment();\n\njulia> e[:a] = 1;\n\njulia> e[:ENVIRONMENT][:a]\n1\n\njulia> e2 = copy(e);\n\njulia> e2[:PARENT][:a]\n1\n\njulia> e2[:b] = 1;\n\njulia> e2[:PARENT][:b]\nERROR: KeyError: key :b not found\n[...]\n\nCan merge! or merge new objects into an environment. You can merge in modules:\n\njulia> using LazyContext\n\njulia> e = Environment();\n\njulia> merge!(e, Core);\n\njulia> e[:Symbol]\nSymbol\n\nand dictonaries:\n\njulia> using LazyContext\n\njulia> e = Environment();\n\njulia> merge!(e, Dict(:a => 1) );\n\njulia> e[:a]\n1\n\nExtend immutable_merge to be able to merge in more types.\n\n\n\n"
},

{
    "location": "index.html#LazyContext.WithContext",
    "page": "Home",
    "title": "LazyContext.WithContext",
    "category": "Type",
    "text": "type WithContext\n    expression::Any\n    environment::Environment\nend\n\nAn expression in the context of its Environment\n\n\n\n"
},

{
    "location": "index.html#LazyContext.copy_of_base_environment-Tuple{}",
    "page": "Home",
    "title": "LazyContext.copy_of_base_environment",
    "category": "Method",
    "text": "copy_of_base_environment()\n\nGet an environment which contains Core and Base. Has no parent.\n\n\n\n"
},

{
    "location": "index.html#LazyContext.evaluate!-Tuple{Any}",
    "page": "Home",
    "title": "LazyContext.evaluate!",
    "category": "Method",
    "text": "evaluate!(w; locked = false)\n\nEvaluate w.expression in context of w.environment.\n\nUnlocked environments cannot be directly accessed in a type stable way. If you include the locked = true keyword, however, the bindings in the environment will be fixed allowing for type-stable access.\n\njulia> using LazyContext\n\njulia> @new_environment;\n\njulia> ENVIRONMENT[:a] = 1;\n\njulia> ENVIRONMENT[:b] = 2;\n\njulia> w = WithContext(:(a + b), ENVIRONMENT);\n\njulia> evaluate!(w)\n3\n\njulia> evaluate!(w, locked = true)\n3\n\njulia> evaluate!( WithContext(:(a = 1), ENVIRONMENT), locked = true)\nERROR: Cannot assign 1 to a: environment is locked\n[...]\n\n\n\n"
},

{
    "location": "index.html#LazyContext.immutable_merge-Tuple{Any,Any}",
    "page": "Home",
    "title": "LazyContext.immutable_merge",
    "category": "Method",
    "text": "immutable_merge(d, a)\n\nMerge d (usually an ImmutableDict) and a into a new ImmutableDict. For example:\n\njulia> using LazyContext\n\njulia> d = Base.ImmutableDict{Symbol, Any}();\n\njulia> a = Dict(:b => 2);\n\njulia> immutable_merge(d, a)[:b]\n2\n\n\n\n"
},

{
    "location": "index.html#LazyContext.@evaluate-Tuple{Any}",
    "page": "Home",
    "title": "LazyContext.@evaluate",
    "category": "Macro",
    "text": "macro evaluate(expression)\n\nevaluate! expression in the context of ENVIRONMENT. This is useful to allow repeated calling, but be careful when modifying ENVIRONMENT.\n\njulia> using LazyContext\n\njulia> @new_environment;\n\njulia> @evaluate a = 1;\n\njulia> @evaluate a\n1\n\njulia> ENVIRONMENT[:a] = 2;\n\njulia> @evaluate a\n2\n\nOnly limited syntax is supported inside @evaluate.\n\nAnonymous functions are suppported, but only using the terse syntax.\n\njulia> using LazyContext\n\njulia> @new_environment;\n\njulia> @evaluate begin\n           test_function = (a, b...; c = 1) -> +(a, c, b...)\n           test_function(1, 2, 3; c = 4)\n       end\n10\n\nAnonymous functions create new environments. The parent environment can be accessed with PARENT, while the local environment can be accessed with ENVIRONMENT.\n\njulia> using LazyContext\n\njulia> @new_environment;\n\njulia> @evaluate begin\n           a = 1\n           test = b -> begin\n               merge!(ENVIRONMENT, Dict(:a => 2))\n               a + b + PARENT[:a]\n           end\n           test(3)\n       end\n6\n\nAnonymous functions use dynamic scoping: changes in global variables will change functions which reference them.\n\njulia> using LazyContext\n\njulia> @new_environment;\n\njulia> (3, 4) == @evaluate begin\n           a = 1\n           test = b -> a + b\n           first_result = test(2)\n           a = 2\n           second_result = test(2)\n           first_result, second_result\n       end\ntrue\n\nMacro calls do not call macros. Instead, they create WithContext expression wrappers out of all arguments and pass them to the function with the same name.\n\njulia> using LazyContext\n\njulia> @new_environment;\n\njulia> e = @evaluate begin\n           a = 1\n           b = 2\n           @identity a + b\n       end\nWithContext(a + b)\n\njulia> evaluate!(e)\n3\n\n\n\n"
},

{
    "location": "index.html#LazyContext.@import_to_environment-Tuple",
    "page": "Home",
    "title": "LazyContext.@import_to_environment",
    "category": "Macro",
    "text": "macro import_to_environment(args...)\n\nMake args, a list of names, available in the global ENVIRONMENT.\n\njulia> using LazyContext\n\njulia> @new_environment;\n\njulia> import MacroTools;\n\njulia> @import_to_environment LazyContext MacroTools;\n\njulia> Environment == @evaluate LazyContext.Environment\ntrue\n\njulia> MacroTools.prettify == @evaluate MacroTools.prettify\ntrue\n\n\n\n"
},

{
    "location": "index.html#LazyContext.@new_environment-Tuple{}",
    "page": "Home",
    "title": "LazyContext.@new_environment",
    "category": "Macro",
    "text": "macro new_environment\n\nWill create a new copy_of_base_environment named ENVIRONMENT. Prerequisite for many macros in this package. Be careful not to overwrite ENVIRONMENT.\n\njulia> using LazyContext\n\njulia> @new_environment;\n\njulia> Dict == ENVIRONMENT[:Dict]\ntrue\n\n\n\n"
},

{
    "location": "index.html#LazyContext.@use_in_environment-Tuple",
    "page": "Home",
    "title": "LazyContext.@use_in_environment",
    "category": "Macro",
    "text": "use_in_environmnet(args...)\n\nMake the contents of each item in args available in the global ENVIRONMENT, by merging in each one by one.\n\njulia> using LazyContext\n\njulia> @new_environment;\n\njulia> import MacroTools;\n\njulia> @use_in_environment LazyContext MacroTools;\n\njulia> Environment == @evaluate Environment\ntrue\n\njulia> MacroTools.prettify == @evaluate prettify\ntrue\n\n\n\n"
},

{
    "location": "index.html#LazyContext.jl-1",
    "page": "Home",
    "title": "LazyContext.jl",
    "category": "section",
    "text": "LazyContext makes true lazy evaluation easy. Here is a simple port of with in R.julia> using LazyContext\n\njulia> with(d::WithContext, e::WithContext) = begin\n           d_evaluated = evaluate!(d)\n           e_copy = copy(e)\n           merge!(e_copy.environment, d_evaluated)\n           evaluate!(e_copy)\n       end;\n\njulia> @new_environment;\n\njulia> @import_to_environment with;\n\njulia> @evaluate begin\n           d = Dict(:a => 1, :b => 2)\n           @with d a + b\n       end\n3Merging will work for any type which can be key-value iterated.Modules = [LazyContext]"
},

]}
