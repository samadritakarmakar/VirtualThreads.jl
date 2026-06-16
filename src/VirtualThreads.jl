module VirtualThreads

"""
    @virtualthreads virtualThreadId for x in itr
        body
    end

Run a threaded loop over `itr`.

Inside the loop, `virtualThreadId` is a stable virtual worker id suitable for
indexing per-worker buffer state. It is independent of `Base.Threads.threadid()`
and is intended as a lightweight replacement for older thread-id-based
per-worker storage patterns discouraged since Julia 1.7 task migration.
"""

macro virtualthreads(virtThreadNo::Union{Symbol, Expr}, forLoopExpr::Expr)
    forLoopDo = forLoopExpr.args[2]
    if (forLoopExpr.head) == :for
        baseCounter = forLoopExpr.args[1].args[1]
        forLoopRange = forLoopExpr.args[1].args[2]
        
        itr = gensym(:itr)
        items = gensym(:items)
        noOfElements = gensym(:noOfElements)
        chunkSize = gensym(:chunkSize)
        elementChunks = gensym(:elementChunks)
        return quote
            $itr = $(esc(forLoopRange))
            $items = $itr isa Base.AbstractArray ? $itr : Base.collect($itr)
            $noOfElements = Base.length($items)
            if $noOfElements > 0
                $chunkSize = Base.cld($noOfElements, Base.Threads.nthreads())
                $elementChunks = Base.collect(Base.Iterators.partition($items, $chunkSize))
                Base.Threads.@threads for $(esc(virtThreadNo)) = Base.eachindex($elementChunks)
                    for $(esc(baseCounter)) = $elementChunks[$(esc(virtThreadNo))]
                        $(esc(forLoopDo))
                    end
                end
            end
        end
    else
        error("""virtualthreads only supports for loop and not "$(forLoopExpr.head)" """)
    end
end

end # module VirtualThreads
