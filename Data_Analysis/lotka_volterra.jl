using DifferentialEquations
using ParameterizedFunctions
using DataFrames
using DataArrays
using Gadfly


# definition of differential equations
g = @ode_def_nohes LotkaVolterra begin
         dx = A*x - B*x*y
         dy = -C*y + D*x*y
end A=>1.0 B =>1.0 C =>1.0 D =>1.0

# solving differential equations
function lotka_volterra(a, b, c, d, t0, t1, x0, y0)
  u0 = [x0;y0]
  tspan = (t0,t1)
  h = LotkaVolterra(A=a,B=b,C=c,D=d)
  prob = ODEProblem(h,u0,tspan)
  return solve(prob, RK4(), dt=0.01)
end

# extracting results and saving into array
function into_array(sol, expNum)
  results = Array{Any,1}[]
  mintime = first(sol.t)
  maxtime = last(sol.t)
  i = mintime
  push!(results, ["t", "x", "y", "experiment"])
  while i < maxtime
    push!(results, [i, sol(i)[1], sol(i)[2], "exp$expNum"])
    i += 0.1
  end
  return results
end

# saving results (array) into csv file
function into_file(filename, results)
  open(filename,"w")
  writecsv(filename, results)
end

# read in csv files into DataFrame
function read_in(res...)
  df = vcat([readtable(res[i]) for i in 1:length(res)])
end

# print out min, max and mean value for each experiment
function min_max_mean(data)
  experiments = sort(unique(data[:experiment]))
  i = 1
  for exp in experiments
    println("Experiment $i\n")
    exp_data = data[data[:experiment] .== exp, :]
    println("Prey population\n")
    println("Minimum: $(minimum(exp_data[:x]))")
    println("Maximum: $(maximum(exp_data[:x]))")
    println("Mean:    $(mean(exp_data[:x]))")
    println("\nPredator population\n")
    println("Minimum: $(minimum(exp_data[:y]))")
    println("Maximum: $(maximum(exp_data[:y]))")
    println("Mean:    $(mean(exp_data[:y]))")
    println("\n")
    i += 1
  end
end

# adding new column
function diff_column(data)
  new_data = data
  new_data[:diff] = new_data[:y] - new_data[:x]
  return new_data
end


# plotting functions
function plot_prey_population(sol)
  df=DataFrame(t=sol.t, prey=map(x->x[1],sol.u))
  plot(df,  x="t", y="prey") 
end

function plot_predator_population(sol)
  df2=DataFrame(t=sol.t, predator=map(y->y[2],sol.u))
  plot(df2,  x="t", y="predator")
end



function plot_prey_predator_dependency(data)
  dataframe = DataFrame()

  exp1_data = data[data[:experiment] .== "exp1", :]
  exp2_data = data[data[:experiment] .== "exp2", :]
  exp3_data = data[data[:experiment] .== "exp3", :]
  exp4_data = data[data[:experiment] .== "exp4", :]
  
  dataframe[:x1] = exp1_data[:x]
  dataframe[:y1] = exp1_data[:y]
  dataframe[:x2] = exp2_data[:x]
  dataframe[:y2] = exp2_data[:y]
  dataframe[:x3] = exp3_data[:x]
  dataframe[:y3] = exp3_data[:y]
  dataframe[:x4] = exp4_data[:x]
  dataframe[:y4] = exp4_data[:y]

  plot(dataframe, layer(x="x1", y="y1", Geom.point, Theme(default_color= colorant"blue")),
                  layer(x="x2", y="y2", Geom.point, Theme(default_color= colorant"red")),
                  layer(x="x3", y="y3", Geom.point, Theme(default_color= colorant"green")),
                  layer(x="x4", y="y4", Geom.point, Theme(default_color= colorant"yellow")),
                  Guide.XLabel("Prey population"),
                  Guide.YLabel("Predator population"),
                  Guide.Title("Lotka - Volterra"))
end

# running experiments
function experiments()
  s1 = lotka_volterra(1.5,1.0,3.0,1.0,0.0,5.0,8.0,4.0)
  s2 = lotka_volterra(1.5,1.0,3.0,1.0,0.0,5.0,16.0,2.0)
  s3 = lotka_volterra(1.5,1.0,3.0,1.0,0.0,5.0,12.0,4.0)
  into_file("res1.csv",into_array(s1,1))
  into_file("res2.csv",into_array(s2,2))
  into_file("res3.csv",into_array(s3,3))
  into_file("res4.csv",into_array(s4,4))
  return [s1,s2,s3,s4]
end

function run_homework()
  solutions = experiments()
  solutions_data = read_in("res1.csv", "res2.csv", "res3.csv", "res4.csv")
  min_max_mean(solutions_data)
  diff_column(solutions_data)
  plot_prey_population(solutions[1])
  plot_predator_population(solutions[1])
  plot_prey_predator(solutions_data)
end

