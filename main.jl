# PostProc: Post processing routines for CFD simulations on rectilinear grids

# Load modules
import FortranFiles as FFile
import Dates
import WriteVTK
import FFTW
using Printf
using Base.Threads: @threads, threadid, nthreads
using Polyester: @batch
using StrideArrays: PtrArray
# Load functions
include("src/structs.jl")
include("src/file_io.jl")
include("src/plane_averages.jl")
include("src/integral_quantities.jl")
include("src/tools_integral.jl")
include("src/spectral_quantities.jl")
include("src/tools_spectral.jl")

# Reporting
const t1 = report("Starting post-processing", 1)
# Read parameter file
const grid, input, thermo, x0, dataDir = readSettings("post.par")
# Get first time step
t = 0.0
timeStep = rpad(string(round(t, digits=8)), 10, "0")
# Load grid
const x, y, z = readPlot3DGrid(timeStep, grid.Nx, grid.Ny, grid.Nz, dataDir)

# Loop over all time steps
for n = 1:input.nFiles
    # Get time step
    global t = input.startTime + (n - 1) * input.Δt
    global timeStep = rpad(string(round(t, digits=8)), 10, "0")

    # Load solution
    Q = readPlot3DSolution(timeStep, grid.Nx, grid.Ny, grid.Nz, input.nVars, dataDir)

    # Convert to primitive variables
    convertSolution!(Q, grid.Nx, grid.Ny, grid.Nz, input.nVars)

    # Write out full solution
    writeSolution(t, x, y, z, Q, input.nVars, dataDir)

    # Write out slice
    writeSlice(t, x, y, z, Q, input.nVars, "xy", x0, dataDir)

    # Calculate plane averages
    QBar = getPlaneAverages(@view(x[:, 1, 1]), Q, grid.Nx, grid.Ny, grid.Nz, input.nVars, thermo)
    
    # Write plane averages
    writePlaneAverages(t, QBar, grid, dataDir)
    
    # Calculate integral quantities
    calcIntegralQuantities(t, @view(x[:, 1, 1]), @view(y[1, :, 1]), @view(z[1, 1, :]), Q, QBar, grid, dataDir)

    # Calculate spectral quantities
    calcSpectralQuantities(t, @view(x[:, 1, 1]), Q, QBar, grid, dataDir)
end

# Reporting
const t2 = report("Finished post-processing...", 1)
report("Total time: $(t2 - t1)")