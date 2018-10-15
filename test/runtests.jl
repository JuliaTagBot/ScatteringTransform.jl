# tests for the various forms of layeredTransform for the ShatteringTransform
using Revise
using Pkg; Pkg.activate("/home/dsweber/.julia/dev/ScatteringTransform.jl")
using Interpolations, Wavelets
using FFTW
using ScatteringTransform
using Test
f = randn(102)
lay = layeredTransform(1,f)
scattered(lay, f)
# some basic tests for the scattered type
# m=2, 3extra, 2transformed
fixDims = [3,5,2]
m = 2; k=2
n = [100 200; 50 100; 25 50]; q = [5, 5, 5]
ex1 = scattered(m, k, fixDims, n, q,Float64)
@test ex1.m==m
@test ex1.k==k
@test size(ex1.data,1)==m+1
@test size(ex1.output,1)==m+1
for i=1:size(ex1.output,1)
    @test size(ex1.output[i])[1:size(fixDims,1)] == tuple(fixDims...)
    @test size(ex1.data[i])[1:size(fixDims,1)] == tuple(fixDims...)
    @test size(ex1.output[i])[size(fixDims,1)+1:end-1] == tuple(n[i,:]...)
    @test size(ex1.data[i])[size(fixDims,1)+1:end-1] == tuple(n[i,:]...)
end


# TODO: build tests for cwt

################################ cwt tests ################################
# 1D input tests
inputs = [randn(128), randn(100,128), randn(10, 21, 128), randn(2, 3, 5, 128)]
averagingTypes = [:Mother, :Dirac]
scalingfactors = reverse([1/2, 1, 2, 8, 16, 32])
waves = [WT.morl WT.dog2 WT.paul4]
for f in inputs
  for wave in waves
    for sb in scalingfactors
      for ave in averagingTypes
        waveConst = CFWA(wave, scalingfactor=sb, averagingType = ave)
        println("$(wave), $(sb), $(ave), $(size(f))")
        output = cwt(f,waveConst)
        @test numScales(waveConst,size(f)[end]) == size(output)[end]
        @test length(size(output))== 1+length(size(f))
        output = cwt(f,waveConst,J1=0)
        @test size(output)[end]==1
        @test length(size(output))== 1+length(size(f))
        output = cwt(f,waveConst,J1=20)
        @test 20-waveConst.averagingLength+2 == size(output)[end]
        @test length(size(output))== 1+length(size(f))
      end
    end
  end
end

function testConstruction1D(lay::layeredTransform, m::Int, shearType, averagingLength, averagingType, nShears::Vector{Int}, subsampling::Array{Float64,1}, n::Int)
  @test lay.m == m
  @test lay.subsampling==subsampling
  sizes = ScatteringTransform.sizes(bspline,lay.subsampling,n)
  for i=1:length(lay.shears)
    @test typeof(lay.shears[i]) == shearType[i]
    @test lay.shears[i].averagingLength == averagingLength[i]
    @test lay.shears[i].averagingType == averagingType[i]
    @test numScales(lay.shears[i], sizes[i]) == nShears[i]
  end
end
n = 10214
f = randn(10214)
lay = layeredTransform(1,f)
m=3
# @testset "1D layerTransform constructors"
lay = layeredTransform(m, f, subsampling=[8,4,2,1], nScales=[16,8,8,8], CWTType=WT.dog2, averagingLength=[16,4,4,2],averagingType=[:Mother for i=1:(m+1)],boundary=[WT.DEFAULT_BOUNDARY for i=1:(m+1)])
lay.shears[1].averagingLength
testConstruction1D(lay, 3, [ScatteringTransform.CFWA{Wavelets.WT.PerBoundary} for i=1:4], [16, 4, 4, 2], [:Mother for i=1:4], [167,64,48,42], [8,4,2,1]*1.0, n)

f=1.0 .*[1:50; 50:-1:1]
lay = layeredTransform(3,f)
function testTransform(f::Array{T}, lay::layeredTransform) where T<:Number
  n=size(f)[1]
  @time output = st(f,lay)
  sizes = ScatteringTransform.sizes(bspline,lay.subsampling,n)
  actualSizes = fill(0, size(sizes))
  actualSizes[1] = size(output.data[1])[end-1]
  for i=1:length(actualSizes)-2
    @test size(output.data[i+1])[end-1] == size(output.output[i])[end-1]
    actualSizes[i+1] = size(output.data[i+1])[end-1]
  end
  actualSizes[end] = size(output.output[end])[end-1]
  @test actualSizes== sizes
  scaleSizes = [ ScatteringTransform.numScales(lay.shears[i],sizes[i])-1 for i =1:m] # the number of wavelets in a layer (excluding the averaging function)
  # check the number of paths grows correctly
  numTransformed = [prod(scaleSizes[1:k]) for k=1:length(scaleSizes)]
  @test numTransformed==([size(out)[end] for out in output.output])[2:end]
  @test eltype(output.data) == Matrix{Complex{eltype(f)}}
  @test eltype(output.output) == Matrix{Complex{eltype(f)}}
end
# check that various constructions are well-defined
testTransform(f,lay)
output = st(f,lay)

f = randn(1020)
m=3
lay = layeredTransform(m, f, subsampling=[8,4,2,1], nScales=[16,8,8,8], CWTType=WT.dog2, averagingLength=[16,4,4,2],averagingType=[:Mother for i=1:(m+1)],boundary=[WT.DEFAULT_BOUNDARY for i=1:(m+1)])
testTransform(f, lay)
layeredTransform(3, length(f), [2, 2, 2, 2], [2, 2, 2, 2], WT.dog2)
layeredTransform(3, length(f), 8, [2, 2, 2, 2], WT.dog2)
layeredTransform(3, length(f), [2, 2, 2, 2], 2, WT.dog2)
layeredTransform(3, length(f), 8, 2, WT.dog2)
st(randn(3, 1020), lay)

# scattered construction tests
scattered1D{Float64,1}(2,randn(10,10),randn(10,10))
layers = layeredTransform(3, length(f), 8, 4)

results = scattered1D(layers, f)
layeredTransform(3, f, [2, 2, 2, 2], [2, 2, 2, 2], WT.dog2)
layeredTransform(3, f, 8, [2, 2, 2, 2], WT.dog2)
layeredTransform(3, f, [2, 2, 2, 2], 2, WT.dog2)
layeredTransform(3, f, 8, 2, WT.dog2)

layeredTransform(3, f, [2, 2, 2, 2], WT.dog2)
layeredTransform(3, f, 7, WT.dog2)
layeredTransform(3, length(f), [7, 7, 7, 7], WT.dog2)
layeredTransform(3, length(f), 7, WT.dog2)

layeredTransform(3,f,WT.dog2)

layeredTransform(3, length(f), [2, 2, 2, 2], [2, 2, 2, 2])
layeredTransform(3, length(f), 8, [2, 2, 2, 2])
layeredTransform(3, length(f), [2, 2, 2, 2], 2)
layeredTransform(3, length(f), 8, 2)

layeredTransform(3, f, [2, 2, 2, 2], [2, 2, 2, 2])
layeredTransform(3, f, 8, [2, 2, 2, 2])
layeredTransform(3, f, [2, 2, 2, 2], 2)
layeredTransform(3, f, 8, 2)

layeredTransform(3, f, [2, 2, 2, 2])
layeredTransform(3, f, 7)
layeredTransform(3, length(f), [7, 7, 7, 7])
layeredTransform(3, length(f), 7)

layeredTransform(3,f)

f = randn(10,30,500) #there are 10 examples of length 500
layeredTransform(3,f[1,1,:])
#TODO: make a version that can handle input of arbitrary number of initial dimensions
tmp = layeredTransform(1,f[1,1,:])
ScatteringTransform.cwt(f, tmp.shears[1])
ifft(fft(randn(10,30,61,500),3), 3)
averageNoiseMat = cwt(f,tmp.shears[1],J1=1)
using FFTW
A = randn(10,10,30)
eachindex
CI = CartesianIndex(size(A))
for i in Tuple(CI)
  print(i)
end
axes(A,3)
for x in axes(A)[1:end-1]
  print(x)
end
for x in eachindex.(axes(A)[1:end-1])
  print("$(size(A[x]))")
end
A = randn(10,10,30)
using LinearAlgebra
for x in eachindex(view(A,axes(A)[1:end-1]..., 1))
  print(x)
  print("$(size(A[x,:]))")
  println("     ")
end
CartesianIndex.(axes(A, 1), axes(A, 2))
view(A,100,100, :)
for i in eachindex(view(A,:,1))
  @show i
end
randn(100,100,100).*
using LinearAlgebra

dw = zeros(10000,10000)
v = rand(10000)
h = rand(10000)
@time for i = 1:10
  dw += h*v'
end
@time for i = 1:10
  BLAS.gemm!('N', 'T', 1.0, h, v, 1.0, dw)
end



# fixed tests, improved final layer efficiency
