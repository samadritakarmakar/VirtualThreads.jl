# VirtualThreads.jl

`VirtualThreads.jl` provides a lightweight threaded-loop macro with a stable
virtual worker id.

It is intended for threaded loops that need per-worker buffers without relying on `Base.Threads.threadid()`.

## Installation

```julia
using Pkg
Pkg.add(url = "https://github.com/samadritakarmakar/VirtualThreads.jl")
```

## Usage

```julia
using VirtualThreads

buffers = [Int[] for _ in 1:Base.Threads.nthreads()]

@virtualthreads virtualThreadId for x in 1:100
    push!(buffers[virtualThreadId], x)
end
```

Inside the loop, `virtualThreadId` is a stable virtual worker id assigned by the macro.

## Why?

Before Julia 1.7, threaded Julia code often used patterns like:

```julia
buffer = buffers[Base.Threads.threadid()]
```

This pattern is discouraged in modern Julia. With task migration, the physical
thread running a task should not generally be treated as stable, and
`Base.Threads.threadid()` is not a safe basis for indexing per-worker buffers.

Julia 1.12 also defaults to an additional interactive thread, making it even
more important not to assume that physical thread ids correspond neatly to
worker-buffer indices.

`@virtualthreads` instead gives you a stable virtual id:

```julia
@virtualthreads virtualThreadId for x in xs
    buffer = buffers[virtualThreadId]
    push!(buffer, f(x))
end
```

The virtual id is independent of `Base.Threads.threadid()`.

## Supported iteration

`@virtualthreads` follows normal Julia `for`-loop behavior.

```julia
@virtualthreads virtualThreadId for x in 1:10
    println(virtualThreadId, " => ", x)
end

@virtualthreads virtualThreadId for x in [1, 2, 3]
    println(virtualThreadId, " => ", x)
end

@virtualthreads virtualThreadId for x in Set([1, 2, 3])
    println(virtualThreadId, " => ", x)
end

@virtualthreads virtualThreadId for pair in Dict(:a => 1, :b => 2)
    println(virtualThreadId, " => ", pair)
end
```

For dictionaries, iteration produces `Pair` objects, just like a normal Julia loop:

```julia
@virtualthreads virtualThreadId for (k, v) in Dict(:a => 1, :b => 2)
    println(virtualThreadId, " => ", k, " = ", v)
end
```

Matrices are iterated element-wise in Julia’s default column-major order:

```julia
A = [1 2; 3 4]

@virtualthreads virtualThreadId for x in A
    println(virtualThreadId, " => ", x)
end
```

## API

```julia
@virtualthreads virtualThreadId for x in itr
    body
end
```

Run a threaded loop over `itr`.

Inside the loop, `virtualThreadId` is a stable virtual worker id suitable for indexing per-worker buffer state. It is independent of `Base.Threads.threadid()`.

## Warning

This lightweight package does not make loop bodies thread-safe. Ensuring
thread safety is still the developer's responsibility.

Good:

```julia
buffers = [Float64[] for _ in 1:Base.Threads.nthreads()]

@virtualthreads virtualThreadId for x in xs
    push!(buffers[virtualThreadId], f(x))
end
```

Bad:

```julia
result = Float64[]

@virtualthreads virtualThreadId for x in xs
    push!(result, f(x))  # shared mutation
end
```
