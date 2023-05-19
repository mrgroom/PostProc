# Tools for use in functions from spectral_quantities.jl

# Function to integrate E(κ)
function integrate(E::PtrArray{Float64,1}, Δκ::Float64, N::Int64)
    integral = 0.0
    @inbounds begin
        @turbo for i in 1:N
            integral += 0.5 * Δκ * (E[i] + E[i+1])
        end
    end
    return integral
end

# Function to integrate E(κ) / κ
function integrateEonK(E::PtrArray{Float64,1}, κ::PtrArray{Float64,1}, Δκ::Float64, N::Int64)
    integral = 0.5 * Δκ * (0.0 + E[2] / κ[2]) # i=1
    @inbounds begin
        @turbo for i in 2:N
            integral += 0.5 * Δκ * (E[i] / κ[i] + E[i+1] / κ[i+1])
        end
    end
    return integral
end