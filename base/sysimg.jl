# This file is a part of Julia. License is MIT: https://julialang.org/license

Core.include(Main, "Base.jl")

using .Base

# Ensure this file is also tracked
pushfirst!(Base._included_files, (@__MODULE__, joinpath(@__DIR__, "Base.jl")))
pushfirst!(Base._included_files, (@__MODULE__, joinpath(@__DIR__, "sysimg.jl")))

# set up depot & load paths to be able to find stdlib packages
@eval Base creating_sysimg = true
Base.init_depot_path()
Base.init_load_path()

if Base.is_primary_base_module
# load some stdlib packages but don't put their names in Main
let
    # Stdlibs manually sorted in top down order
    stdlibs = [
            # No deps
            :Base64,
            :CRC32c,
            :SHA,
            Base.DISABLE_LIBUV ? nothing : :FileWatching,
            :Unicode,
            :Mmap,
            Base.DISABLE_LIBUV ? nothing : :Serialization,
            :Libdl,
            :Markdown,
            Base.DISABLE_LIBUV ? nothing : :LibGit2,
            :Logging,
            Base.DISABLE_LIBUV ? nothing : :Sockets,
            :Printf,
            :Profile,
            :Dates,
            :DelimitedFiles,
            Base.DISABLE_LIBUV ? nothing : :Random,
            Base.DISABLE_LIBUV ? nothing : :UUIDs,
            Base.DISABLE_LIBUV ? nothing : :Future,
            Base.DISABLE_LIBUV ? nothing : :LinearAlgebra,
            Base.DISABLE_LIBUV ? nothing : :SparseArrays,
            Base.DISABLE_LIBUV ? nothing : :SuiteSparse,
            Base.DISABLE_LIBUV ? nothing : :Distributed,
            Base.DISABLE_LIBUV ? nothing : :SharedArrays,
            Base.DISABLE_LIBUV ? nothing : :Pkg,
            Base.DISABLE_LIBUV ? nothing : :Test,
            Base.DISABLE_LIBUV ? nothing : :REPL,
            Base.DISABLE_LIBUV ? nothing : :Statistics,
        ]
    filter!(x -> x !== nothing, stdlibs)

    maxlen = maximum(textwidth.(string.(stdlibs)))

    print_time = (mod, t) -> (print(rpad(string(mod) * "  ", maxlen + 3, "─")); Base.time_print(t * 10^9); println())
    print_time(Base, (Base.end_base_include - Base.start_base_include) * 10^(-9))

    Base._track_dependencies[] = true
    Base.tot_time_stdlib[] = @elapsed for stdlib in stdlibs
        tt = @elapsed Base.require(Base, stdlib)
        print_time(stdlib, tt)
    end
    for dep in Base._require_dependencies
        dep[3] == 0.0 && continue
        push!(Base._included_files, dep[1:2])
    end
    empty!(Base._require_dependencies)
    Base._track_dependencies[] = false

    print_time("Stdlibs total", Base.tot_time_stdlib[])
end
end

# Clear global state
empty!(Core.ARGS)
empty!(Base.ARGS)
empty!(LOAD_PATH)
@eval Base creating_sysimg = false
Base.init_load_path() # want to be able to find external packages in userimg.jl

let
tot_time_userimg = @elapsed (Base.isfile("userimg.jl") && Base.include(Main, "userimg.jl"))


tot_time_base = (Base.end_base_include - Base.start_base_include) * 10.0^(-9)
tot_time = tot_time_base + Base.tot_time_stdlib[] + tot_time_userimg

println("Sysimage built. Summary:")
print("Total ─────── "); Base.time_print(tot_time               * 10^9); print(" \n");
print("Base: ─────── "); Base.time_print(tot_time_base          * 10^9); print(" "); show(IOContext(stdout, :compact=>true), (tot_time_base          / tot_time) * 100); println("%")
print("Stdlibs: ──── "); Base.time_print(Base.tot_time_stdlib[] * 10^9); print(" "); show(IOContext(stdout, :compact=>true), (Base.tot_time_stdlib[] / tot_time) * 100); println("%")
if isfile("userimg.jl")
print("Userimg: ──── "); Base.time_print(tot_time_userimg       * 10^9); print(" "); show(IOContext(stdout, :compact=>true), (tot_time_userimg       / tot_time) * 100); println("%")
end
end

empty!(LOAD_PATH)
empty!(DEPOT_PATH)
