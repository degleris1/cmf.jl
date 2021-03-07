using CMF
using MLJBase

# Generate data
N, T = 30, 100
X = rand(N, T)

model = ConvolutionalFactorization()
fitresults, cache, report = fit(model, 0, X)