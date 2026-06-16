using VirtualThreads

function test(endVal)
    VirtualThreads.@virtualthreads threadNo for a ∈ endVal
        println("a = $a at virtThreadNo $threadNo")
    end
    
end