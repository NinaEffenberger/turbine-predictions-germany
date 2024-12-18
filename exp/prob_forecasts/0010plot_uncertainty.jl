using Plots

gp = GP(SqExponentialKernel())
sampleplot(gp(rand(5)); samples = 10, linealpha = 1.0)