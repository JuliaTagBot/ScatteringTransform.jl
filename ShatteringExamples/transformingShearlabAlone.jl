#using Distributed
#addprocs(13)
using MLDatasets
using MLDataUtils
using HDF5
using Shearlab
#@everywhere using ScatteringTransform
using JLD
using SharedArrays
#@everywhere using FFTW
using FFTW




println("using statements done")
train_x, train_y = MNIST.traindata();
test_x, test_y = MNIST.testdata();
dataTot = SharedArray{Float32}(Float32.(cat(permutedims(train_x, (3,1,2)),
                                            permutedims(test_x, (3,1,2)),
                                            dims=1)));
labelTot = [train_y; test_y];
file = open("/fasterHome/workingDataDir/shattering/MNIST_labels_juliaOrdered.bin", "w+")
write(file, length(labelTot))
write(file, labelTot)
close(file)
println("data loaded")
#@everywhere nTot = 70000; @everywhere m =2
nTot = 70000; m =2
#@everywhere layers = layeredTransform(m, (28, 28), subsamples=[28/19, 19/13,13/8],shearLevel=Int.(ceil.((1:4)/4)),typeBecomes = Float32);
layers = layeredTransform(m, (28, 28), subsamples=[28/19, 19/13, 13/8], shearLevel=Int.(ceil.((1:4)/4)), typeBecomes = Float32);
println("successfully formed some layers")

n, q, dataSizes, outputSizes, resultingSize = ScatteringTransform.calculateSizes(layers,
                                                                                 (-1,-1),
                                                                                 (70000,28,28))
save("/fasterHome/workingDataDir/shattering/shatteredMNISTabs2_4shearLevels.jld",
     "layers", layers)
# COLUMN-MAJOR
dimension = sum(prod(x[2:end]) for x in outputSizes)
typeBase = Float32
s = open("/fasterHome/workingDataDir/shattering/shatteredMNISTabs2_4shearLevels.bin", "w+")
# We'll write the dimensions of the array as the first two Ints in the file
write(s, dimension)
write(s, nTot)
batchSize = 70000
totalBatches = ceil.(nTot/batchSize)
start = time()
a = time()
for i=1:Int(totalBatches)
    global a
    println("at batch $(i), taking $(time()-a), total time of $(time()-start)")
    a = time()
    shatteredTraining = st(dataTot[((i-1)*batchSize+1):(i*batchSize), :, :], layers, absType(), thin=true,fftPlans=false)
    write(s, shatteredTraining)
end

# for i=1:Int(nTot/nprocs()/10)
#   println("on run $i out of $(Int(nTot/nprocs()/10))")
#   @sync Threads.@threads for j=1:nprocs()*10
#     shatteredTraining[:, j] = shatter(dataTot[:, :, (i-1)*nprocs()*10+j], layers, softplusType(), thin=true)
#     # shatteredTraining[:, j] = A[:, (i-1)*nprocs()*10+j]
#   end
#   write(s, shatteredTraining)
# end
close(s)
error("all done now")
close(s)
s = open("/fasterHome/workingDataDir/shattering/shatteredMNISTsoftplus2_4shearLevels.bin", "r")
dimension = read(s,Int)
nTot = read(s,Int)
transData = read!(s,zeros(Float32, (dimension, nTot)))
using sklearn

using Profile
using ProfileView
dataTot = Array{Float16}(Float16.(cat(train_x, test_x, dims=3)))
Profile.init(n=10^9)
layers = layeredTransform(2, 28, 28, subsamples=[28/19, 19/13, 13/8], shearLevel=Int.(ceil.((1:4)/4)), typeBecomes = Float16)
@profile st = shatter(dataTot[:, :, 1], layers, softplusType(), thin=true)
ProfileView.view()
f = open("debugging2.txt","w+")
data,lidict = Profile.retrieve()
Profile.print(f, data, lidict)
close(f)
using JLD, MNIST
testingDataTot, testingClassesTot = testdata()
nTot = length(testingClassesTot)
testingDataTot = reshape(testingDataTot,(28,28,:))
s = open("/fasterHome/workingDataDir/shattering/testSets/shatteredMNISTabs2Test.bin", "w+")
# We'll write the dimensions of the array as the first two Ints in the file
write(s, dimension)
write(s, nTot)
shatteredTraining = SharedArray{ComplexF64, 2}(dimension, nprocs()*10)
for i=1:Int(nTot/nprocs()/10)
    println("on run $i out of $(Int(nTot/nprocs()/10))")
    @sync @parallel for j=1:nprocs()*10
        shatteredTraining[:, j] = shatter(testingDataTot[:, :, (i-1)*nprocs()*10+j], layers, absType(), thin=true)
        # shatteredTraining[:,j] = A[:,(i-1)*nprocs()*10+j]
    end
    write(s, shatteredTraining)
end
close(s)
# catch e
#     yo()
#     throw(e)
# end
yo()
