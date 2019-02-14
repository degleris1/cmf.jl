module ANNLS
"""
Fit CNMF using Alternating Non-Negative Least Squares.
Note: this requires having the NonNegLeastSquares source available 
in a directory adjacent to the cmf.jl directory.
"""

# Import 
push!(LOAD_PATH, "../../")
import NonNegLeastSquares
using LinearAlgebra
include("./common.jl")

mutable struct ANNLSmeta
    resids
    data_norm
end

"""
Main update rule
"""
function update(data, W, H, meta, options)
    if (meta == nothing)
        meta = _initialize_meta(data, W, H)
    end

    # W update
    _update_W!(data, W, H)

    # H update
    H_old = copy(H)
    _update_H!(data, W, H)

    meta.resids = tensor_conv(W, H) - data
    return norm(meta.resids) / meta.data_norm, meta
end

function _initialize_meta(data, W, H)    
    resids = tensor_conv(W, H) - data
    data_norm = norm(data)
    return ANNLSmeta(resids, data_norm)
end

function _update_W!(data, W, H)
    """
    This is just a single NNLS solve using the unfolded H
    matrix.
    """
    L,N,K = size(W)
    H_unfold = shift_and_stack(H, L)
    W_unfold = NonNegLeastSquares.nonneg_lsq(t(H_unfold), t(data))
    W[:,:,:] = fold_W(t(W_unfold), L, N, K)
end

function _update_H!(data, W, H)
    K, T = size(H)
    L, N, K = size(W)

    # Form big matrix of kronecker products.
    # This is just a temporary solution to get this working.
    # TODO: Change this to update a single column of H at a time.
    A = zeros(N*T, K*T)
    for l in 1:L
        A = A + kron(shift_matrix(T, 1-l), W[l,:,:])
    end

    # Update H with NNLS
    H_vec = NonNegLeastSquares.nonneg_lsq(A, vec(data))
    H[:,:] = reshape(H_vec, size(H)...)
end

"""
Fold W_tilde (a block matrix) into a W tensor
"""
function fold_W(W_mat, L, N, K)
    W_tens = zeros(L, N, K)
    for l in 0:L-1
        W_fac = W_mat[:,1+(K*l):K*(l+1)]
        W_tens[l+1,:,:] = W_fac
    end
    return W_tens
end

"""
Convenience function for transpose
"""
function t(A)
    return permutedims(A, (2,1))
end

end  # module
