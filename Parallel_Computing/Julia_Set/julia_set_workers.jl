using Plots
Plots.gr()

@everywhere function generate_julia(z; c=2, maxiter=200)
    for i=1:maxiter
        if abs(z) > 2
            return i-1
        end
        z = z^2 + c
    end
    maxiter
end

# manual array division
@everywhere function myrange(q::SharedArray)
    idx = indexpids(q)
    if idx == 0
        # master has no chunks
        return 1:0, 1:0
    end
    # amount of chunks
    nchunks = length(procs(q))

    # counting chunk range
    splits = [round(Int, s) for s in linspace(0,size(q,2),nchunks+1)]
    # formated chunk range
    1:size(q,1), splits[idx]+1:splits[idx+1]
end

@everywhere function calc_julia_chunk!(julia_set, xrange, yrange, wrange, hrange)
  @show (wrange, hrange)
  for y in hrange, x in wrange
     z = xrange[x] + 1im*yrange[y]
     julia_set[x, y] = generate_julia(z, c=-0.70176-0.3842im, maxiter=200)
  end
  julia_set
end

@everywhere calc_julia_shared_chunk!(julia_set, xrange, yrange) = calc_julia_chunk!(julia_set, xrange, yrange, myrange(julia_set)...)

# call of a calc_julia_shared_chunk function for each worker
function calc_julia_shared!(julia_set, xrange, yrange)
   @sync begin
       for p in procs(julia_set)
           @async remotecall_wait(calc_julia_shared_chunk!, p, julia_set, xrange, yrange)
       end
   end
   julia_set
end

function calc_julia_main(h,w)
   xmin, xmax = -2,2
   ymin, ymax = -1,1
   xrange = linspace(xmin, xmax, w)
   yrange = linspace(ymin, ymax, h)
	 println(xrange[100],yrange[101])
   julia_set = SharedArray(Int64, (w, h))
   @time calc_julia_shared!(julia_set, xrange, yrange)
   Plots.heatmap(xrange, yrange, julia_set)
   png("julia_workers")
end


calc_julia_main(2000,2000)
