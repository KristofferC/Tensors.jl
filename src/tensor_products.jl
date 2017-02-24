# dcontract, dot, tdot, otimes, cross
"""
```julia
dcontract(::SecondOrderTensor, ::SecondOrderTensor)
dcontract(::SecondOrderTensor, ::FourthOrderTensor)
dcontract(::FourthOrderTensor, ::SecondOrderTensor)
dcontract(::FourthOrderTensor, ::FourthOrderTensor)
```
Computes the double contraction between two tensors.
The symbol `⊡`, written `\\boxdot`, is overloaded for double contraction.
The reason `:` is not used is because it does not have the same precedence as multiplication.

**Example:**

```jldoctest
julia> A = rand(SymmetricTensor{2, 2});

julia> B = rand(SymmetricTensor{2, 2});

julia> dcontract(A,B)
1.9732018397544984

julia> A ⊡ B
1.9732018397544984
```
"""
@generated function dcontract{dim}(S1::SecondOrderTensor{dim}, S2::SecondOrderTensor{dim})
    idxS1(i, j) = compute_index(get_base(S1), i, j)
    idxS2(i, j) = compute_index(get_base(S2), i, j)
    ex1, ex2 = Expr[], Expr[]
    for j in 1:dim, i in 1:dim
        push!(ex1, :(get_data(S1)[$(idxS1(i, j))]))
        push!(ex2, :(get_data(S2)[$(idxS2(i, j))]))
    end
    exp = make_muladd_exp(ex1, ex2)
    return quote
        $(Expr(:meta, :inline))
        @inbounds return $exp
    end
end

@generated function dcontract{dim}(S1::SecondOrderTensor{dim}, S2::FourthOrderTensor{dim})
    TensorType = getreturntype(dcontract, get_base(S1), get_base(S2))
    idxS1(i, j) = compute_index(get_base(S1), i, j)
    idxS2(i, j, k, l) = compute_index(get_base(S2), i, j, k, l)
    exps = Expr(:tuple)
    for l in 1:dim, k in 1:dim
        ex1, ex2 = Expr[], Expr[]
        for j in 1:dim, i in 1:dim
            push!(ex1, :(get_data(S1)[$(idxS1(i, j))]))
            push!(ex2, :(get_data(S2)[$(idxS2(i, j, k, l))]))
        end
        push!(exps.args, make_muladd_exp(ex1, ex2))
    end
    expr = remove_duplicates(TensorType, exps)
    quote
        $(Expr(:meta, :inline))
        @inbounds return $TensorType($expr)
    end
end

@generated function dcontract{dim}(S1::FourthOrderTensor{dim}, S2::SecondOrderTensor{dim})
    TensorType = getreturntype(dcontract, get_base(S1), get_base(S2))
    idxS1(i, j, k, l) = compute_index(get_base(S1), i, j, k, l)
    idxS2(i, j) = compute_index(get_base(S2), i, j)
    exps = Expr(:tuple)
    for j in 1:dim, i in 1:dim
        ex1, ex2 = Expr[], Expr[]
        for l in 1:dim, k in 1:dim
            push!(ex1, :(get_data(S1)[$(idxS1(i, j, k, l))]))
            push!(ex2, :(get_data(S2)[$(idxS2(k, l))]))
        end
        push!(exps.args, make_muladd_exp(ex1, ex2))
    end
    expr = remove_duplicates(TensorType, exps)
    quote
        $(Expr(:meta, :inline))
        @inbounds return $TensorType($expr)
    end
end

@generated function dcontract{dim}(S1::FourthOrderTensor{dim}, S2::FourthOrderTensor{dim})
    TensorType = getreturntype(dcontract, get_base(S1), get_base(S2))
    idxS1(i, j, k, l) = compute_index(get_base(S1), i, j, k, l)
    idxS2(i, j, k, l) = compute_index(get_base(S2), i, j, k, l)
    exps = Expr(:tuple)
    for l in 1:dim, k in 1:dim, j in 1:dim, i in 1:dim
        ex1, ex2 = Expr[], Expr[]
        for n in 1:dim, m in 1:dim
            push!(ex1, :(get_data(S1)[$(idxS1(i, j, m, n))]))
            push!(ex2, :(get_data(S2)[$(idxS2(m, n, k, l))]))
        end
        push!(exps.args, make_muladd_exp(ex1, ex2))
    end
    expr = remove_duplicates(TensorType, exps)
    quote
        $(Expr(:meta, :inline))
        @inbounds return $TensorType($expr)
    end
end

const ⊡ = dcontract

"""
```julia
otimes(::Vec, ::Vec)
otimes(::SecondOrderTensor, ::SecondOrderTensor)
```
Computes the open product between two tensors.
The symbol `⊗`, written `\\otimes`, is overloaded for tensor products.

**Example:**

```jldoctest
julia> A = rand(SymmetricTensor{2, 2});

julia> B = rand(SymmetricTensor{2, 2});

julia> A ⊗ B
2×2×2×2 Tensors.SymmetricTensor{4,2,Float64,9}:
[:, :, 1, 1] =
 0.271839  0.352792
 0.352792  0.260518

[:, :, 2, 1] =
 0.469146  0.608857
 0.608857  0.449607

[:, :, 1, 2] =
 0.469146  0.608857
 0.608857  0.449607

[:, :, 2, 2] =
 0.504668  0.654957
 0.654957  0.48365
```
"""
@generated function otimes{dim}(S1::Vec{dim}, S2::Vec{dim})
    exps = Expr(:tuple)
    for j in 1:dim, i in 1:dim
        push!(exps.args, :(get_data(S1)[$i] * get_data(S2)[$j]))
    end
    quote
        $(Expr(:meta, :inline))
        @inbounds return Tensor{2, dim}($exps)
    end
end

@generated function otimes{dim}(S1::SecondOrderTensor{dim}, S2::SecondOrderTensor{dim})
    TensorType = getreturntype(otimes, get_base(S1), get_base(S2))
    idxS1(i, j) = compute_index(get_base(S1), i, j)
    idxS2(i, j) = compute_index(get_base(S2), i, j)
    exps = Expr(:tuple)
    for l in 1:dim, k in 1:dim, j in 1:dim, i in 1:dim
        push!(exps.args, :(get_data(S1)[$(idxS1(i, j))] * get_data(S2)[$(idxS2(k, l))]))
    end
    expr = remove_duplicates(TensorType, exps)
    quote
        $(Expr(:meta, :inline))
        @inbounds return $TensorType($expr)
    end
end

const ⊗ = otimes

"""
```julia
dot(::Vec, ::Vec)
dot(::Vec, ::SecondOrderTensor)
dot(::SecondOrderTensor, ::Vec)
dot(::SecondOrderTensor, ::SecondOrderTensor)
```
Computes the dot product (single contraction) between two tensors.
The symbol `⋅`, written `\\cdot`, is overloaded for single contraction.

**Example:**

```jldoctest
julia> A = rand(Tensor{2, 2})
2×2 Tensors.Tensor{2,2,Float64,4}:
 0.590845  0.566237
 0.766797  0.460085

julia> B = rand(Tensor{1, 2})
2-element Tensors.Tensor{1,2,Float64,2}:
 0.794026
 0.854147

julia> dot(A, B)
2-element Tensors.Tensor{1,2,Float64,2}:
 0.952796
 1.00184

julia> A ⋅ B
2-element Tensors.Tensor{1,2,Float64,2}:
 0.952796
 1.00184
```
"""
@inline Base.dot{dim}(v1::Vec{dim}, v2::Vec{dim}) = tovector(v1) ⋅ tovector(v2)

@inline function Base.dot{dim}(S1::Tensor{2, dim}, v2::Vec{dim})
    return Vec{dim}(tomatrix(S1) * tovector(v2))
end

@inline function Base.dot{dim}(v1::Vec{dim}, S2::Tensor{2, dim})
    return Vec{dim}(tomatrix(S2)' * tovector(v1))
end

@inline function Base.dot{dim}(S1::Tensor{2, dim}, S2::Tensor{2, dim})
    return Tensor{2, dim}(tomatrix(S1) * tomatrix(S2))
end

@inline function Base.dot{dim}(S1::SymmetricTensor{2, dim}, S2::SymmetricTensor{2, dim})
    S1_t = convert(Tensor{2, dim}, S1)
    S2_t = convert(Tensor{2, dim}, S2)
    return Tensor{2, dim}(tomatrix(S1_t) * tomatrix(S2_t))
end

@inline Base.dot{dim}(S1::SymmetricTensor{2, dim}, v2::Vec{dim}) = dot(convert(Tensor{2, dim}, S1), v2)

@inline Base.dot{dim}(v2::Vec{dim}, S1::SymmetricTensor{2, dim}) = dot(S1, v2)

# Promotion
Base.dot{dim}(S1::Tensor{2, dim}, S2::SymmetricTensor{2, dim}) = dot(promote(S1, S2)...)
Base.dot{dim}(S1::SymmetricTensor{2, dim}, S2::Tensor{2, dim}) = dot(promote(S1, S2)...)

"""
```julia
tdot(::SecondOrderTensor)
```
Computes the transpose-dot of a second order tensor with itself.
Returns a `SymmetricTensor`.

**Example:**

```jldoctest
julia> A = rand(Tensor{2,3})
3×3 Tensors.Tensor{2,3,Float64,9}:
 0.590845  0.460085  0.200586
 0.766797  0.794026  0.298614
 0.566237  0.854147  0.246837

julia> tdot(A)
3×3 Tensors.SymmetricTensor{2,3,Float64,6}:
 1.2577   1.36435   0.48726
 1.36435  1.57172   0.540229
 0.48726  0.540229  0.190334
```
"""
@generated function tdot{dim}(S1::SecondOrderTensor{dim})
    TensorType = getreturntype(tdot, get_base(S1))
    idxS1(i,j) = compute_index(get_base(S1), i, j)
    ex = Expr(:tuple)
    for j in 1:dim, i in 1:dim
        ex1, ex2 = Expr[], Expr[]
        for k in 1:dim
            push!(ex1, :(get_data(S1)[$(idxS1(k,i))]))
            push!(ex2, :(get_data(S1)[$(idxS1(k,j))]))
        end
        push!(ex.args, make_muladd_exp(ex1, ex2))
    end
    expr = remove_duplicates(TensorType, ex)
    return quote
        $(Expr(:meta, :inline))
        @inbounds return $TensorType($expr)
    end
end

"""
```julia
dott(::SecondOrderTensor)
```
Computes the dot-transpose of a second order tensor with itself.
Returns a `SymmetricTensor`.

**Example:**

```jldoctest
julia> A = rand(Tensor{2,3})
3×3 Tensors.Tensor{2,3,Float64,9}:
 0.590845  0.460085  0.200586
 0.766797  0.794026  0.298614
 0.566237  0.854147  0.246837

julia> dott(A)
3×3 Tensors.SymmetricTensor{2,3,Float64,6}:
 0.601011  0.878275  0.777051
 0.878275  1.30763   1.18611
 0.777051  1.18611   1.11112
```
"""
@inline dott(S::SecondOrderTensor) = tdot(transpose(S))

"""
```julia
cross(::Vec, ::Vec)
```
Computes the cross product between two `Vec` vectors, returns a `Vec{3}`. For dimensions 1 and 2 the `Vec`'s
are expanded to 3D first. The infix operator `×` (written `\\times`) can also be used.

**Example:**

```jldoctest
julia> a = rand(Vec{3})
3-element Tensors.Tensor{1,3,Float64,3}:
 0.590845
 0.766797
 0.566237

julia> b = rand(Vec{3})
3-element Tensors.Tensor{1,3,Float64,3}:
 0.460085
 0.794026
 0.854147

julia> a × b
3-element Tensors.Tensor{1,3,Float64,3}:
  0.20535
 -0.24415
  0.116354
```
"""
function Base.cross{T}(u::Vec{3, T}, v::Vec{3, T})
    @inbounds w = Vec{3}((u[2]*v[3] - u[3]*v[2], u[3]*v[1] - u[1]*v[3], u[1]*v[2] - u[2]*v[1]))
    return w
end
function Base.cross{T}(u::Vec{2, T}, v::Vec{2, T})
    @inbounds w = Vec{3}((zero(T), zero(T), u[1]*v[2] - u[2]*v[1]))
    return w
end
function Base.cross{T}(::Vec{1, T}, ::Vec{1, T})
    return zero(Vec{3,T})
end
