# # Calibration
#
# The aim is to find the slope between sensor readout (μS/cm) and concentration (g/l) for each sensor

bucketsize = 1.0 # calibration bucket size in liters
solution_conc = 1.0 # calibration solution concentration (g/l)

# Total calibration ml solution vs sensor readout (μS/cm) for each sensor
# Example from 2021:

calibrations = Dict(#=309=>[ ## sensor 309
                             ## first calibration
                          [ 0 0.54 ## First row needs to be the background reading!
                            1 1.35
                            5 4.7
                            10 9.7],
                             ## second calibration
                          [ 0 1.6
                            1 2.43
                            2 3.34
                            5 6.23
                            10 12.3
                            20 28.6 ],
                            ## etc.
                          ],
                    145=>[## sensor 145
                            [ 0 0.31 ## First row needs to be the background reading!
                              1 1.03
                              5 4.29
                              10 9.9 ],
                            [ 0 1.21
                              1 2.14
                              2 3.03
                              5 5.88
                              10 11.83 ],
                            ],=#

                    ## For 1g/l concentration:
                    :wtw_upper_stream=>[ ## note that sensors non-numeric ID are best written as a :symbol
                           [0 1.8
                            1 4.5
                            2 6.7
                            5 13.6
                            10 24.2]],
                    :wtw_lower_stream=>[ ## note that sensors non-numeric ID are best written as a :symbol
                           [0 1.5
                            1 4.8
                            2 6.2
                            5 14.0
                            10 24.5]],
                    :wtw_lake=>[ ## note that sensors non-numeric ID are best written as a :symbol
                           [0 4.4
                            1 7.3
                            2 9.5
                            5 16.5
                            10 26.7]],

                    ## For 10g/l concentration:
                    #=
                    :wtw_upper_stream=>[ ## note that sensors non-numeric ID are best written as a :symbol
                           [0 1.5
                            2 46.2
                            4 90.7 
                            9 197.0
                            13 283.0]],
                    :wtw_lower_stream=>[ ## note that sensors non-numeric ID are best written as a :symbol
                           [0 1.4
                            2 46.3
                            4 90.9
                            9 197.6
                            13 282.0]],
                    :wtw_lake=>[ ## note that sensors non-numeric ID are best written as a :symbol
                           [0 4.3
                            2 47.5
                            4 90.8
                            9 194.3
                            13 280.0]],
                            =#


                    ## add more:
                    ## 049=>[],
                    ## :someother=>[], ## etc
                    )

# Convert ml solution added to concentration

"""
Converts ml added to bucket to a concentration (g/l == kg/m^3).

Input:

- ml -- how many mililiters were added
- solution_conc -- the concentration of the calibration solution (kg/m^3 == g/l)
- bucketsize -- the size of the bucket/bottle to which the solution was added (l)

Output:

- concentration (kg/m^3 == g/l)
"""
function ml_to_concentration(ml, solution_conc, bucketsize)
    mass = ml/1e3 * solution_conc # salt mass added to bucket (g)
    return mass/bucketsize # concentration in g/l (== kg/m^3)
end
# An example, convert to concentration (g/l):
ml_to_concentration(calibrations[:wtw_upper_stream][1][:,1], solution_conc, bucketsize)

# Now fit a linear function to it.  The function is pre-defined in the file helper_functions.jl with
# name `fit_calibration`.
include("helper_functions.jl")

delta_cond2conc = Dict(a[1] => fit_calibration(bucketsize, solution_conc, a[2]...) for a in pairs(calibrations))

# Plot them

using GLMakie
Makie.inline!(false)
## Note if you want a zoom-able plot opening in a new window do:
## Makie.inline!(false)
## to go back to in-line plots set it true again

fig = Figure()
for (i,sens) in enumerate(keys(delta_cond2conc))
    Axis(fig[i, 1], title="Sensor $sens",
        xlabel="concentration (g/l)",
        ylabel="Sensor readout change (μS/cm)")
    delta_fn = delta_cond2conc[sens]
    calis = calibrations[sens]
    ## scatter plots (x,y) points
    maxreadout = 0
    for cali in calis
        conc = ml_to_concentration(cali[:,1], solution_conc, bucketsize)
        maxreadout = max(maxreadout, maximum(cali[:,2].-cali[1,2]))
        scatter!(conc, cali[:,2].-cali[1,2],
                 label="Calibration 1")
    end

    ## Now plot the line of best fit:
    readouts = 0:maxreadout
    ## (lines! plots a line)
    lines!(delta_fn(readouts), readouts, label="line of best fit")
end
fig

# Save them as files:

mkpath("../plots")
save("../plots/calibration.png", fig) ## to save this figure to a file, useful for your presentation

#md save("../docs/calibration.png", fig) #hide
#md # ![](calibration.png)
