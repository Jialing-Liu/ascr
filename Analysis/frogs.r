## Letting R know where everything is.
admbsecr.dir <- "~/admbsecr" # Point this to the admbsecr file.
if (.Platform$OS == "unix"){
  sep <- "/"
} else if (.Platform$OS == "windows") {
  sep <- "\\"
}
## admb.dir only required when user provides the .tpl file.
admb.dir <- paste(admbsecr.dir, "ADMB", sep = sep)
work.dir <- paste(admbsecr.dir, "Analysis", sep = sep)
dat.dir <- paste(admbsecr.dir, "Data", sep = sep)

## Load admbsecr either using devtools or as a library.
setwd(admbsecr.dir)
library(devtools)
load_all()
##library(admbsecr)

## Running setup code.
setwd(work.dir)
library(secr)
source("frogsetup.r")

## Carrying out simple SECR analysis.

## With secr package.
simplefit1 <- secr.fit(capt, model = list(D~1, g0~1, sigma~1), mask = mask, verify = FALSE)
## With admbsecr().
simplefit.hn <- admbsecr(capt, traps = traps, mask, sv = "auto", method = "simple")
simplefit.th <- admbsecr(capt, traps = traps, mask, sv = c(shape = -1),
                         method = "simple", detfn = "th")
simplefit.logth <- admbsecr(capt, traps = traps, mask,
                            sv = c(shape1 = 17.1493, shape2 = 2.9919, scale = -0.0204),
                            method = "simple", detfn = "logth")
simplefit.hr1 <- admbsecr(capt, traps = traps, mask, sv = c(sigma = 7, z = 12),
                          method = "simple", detfn = "hr")
simplefit.hr2 <- admbsecr(capt, traps = traps, mask, sv = c(sigma = 7, z = 12),
                          fix = list(g0 = 1), method = "simple", detfn = "hr")

## Carrying out TOA analysis.

## Fitting with admbsecr(). Doesn't require start values.
toafit.hn <- admbsecr(capt = capt.toa, traps = traps, mask = mask, sv = "auto",
                      method = "toa")
toafit.th <- admbsecr(capt = capt.toa, traps = traps, mask = mask,
                      method = "toa", detfn = "th")
toafit.hr1 <- admbsecr(capt = capt.toa, traps = traps, mask = mask, sv = "auto",
                       method = "toa", detfn = "hr")
toafit.hr2 <- admbsecr(capt = capt.toa, traps = traps, mask = mask, sv = "auto",
                       fix = list(g0 = 1), method = "toa", detfn = "hr")

## Carrying out signal strength analysis.

## Fitting with secr.fit().
ssfit1 <- secr.fit(sscapt, model = list(D~1, g0~1, sigma~1), detectfn = 10, mask = mask,
                   verify = FALSE, steptol = 1e-4)

## Fitting with admbsecr().
ssfit2 <- admbsecr(capt.ss, traps = traps, mask, cutoff = 150, sv = "auto",
                   admbwd = admb.dir, method = "ss")
ssfit2.log <- admbsecr(capt.ss, traps = traps, mask, cutoff = 150, sv = "auto",
                       admbwd = admb.dir, method = "ss", detfn = "log")

## Carrying out analysis with both signal strength and TOA information incorporated.
## Only possible with admbsecr().
jointfit <- admbsecr(capt = capt.joint, traps = traps, mask = mask,
                     bounds = list(ssb0 = c(150, 1e8)),
                     cutoff = 150, admbwd = admb.dir, method = "sstoa")


## Comparison of fitted detection functions.
x <- seq(0, 20, 0.01)
hn <- function(x, coef){
  g0 <- coef[2]
  sigma <- coef[3]
  g0*exp(-x^2/(2*sigma^2))
}
ss <- function(x, c, coef){
  ssb0 <- coef[2]
  ssb1 <- coef[3]
  sigmass <- coef[4]
  1 - pnorm(c, ssb0 + ssb1*x, sigmass)
}
logss <- function(x, c, coef){
  ssb0 <- coef[2]
  ssb1 <- coef[3]
  sigmass <- coef[4]
  1 - pnorm(c, exp(ssb0 + ssb1*x), sigmass)
}
erf <- function(x) 2*pnorm(x*sqrt(2)) - 1
th <- function(x, coef){
  shape <- coef[2]
  scale <- coef[3]
  0.5 - 0.5*erf(shape - scale*x)
}
logth <- function(x, coef){
  par1 <- coef[2]
  par2 <- coef[3]
  par3 <- coef[4]
  0.5 - 0.5*erf(par1 - exp(par2 + par3*x))
}
hr <- function(x, coef){
  g0 <- coef[2]
  sigma <- coef[3]
  z <- coef[4]
  g0*(1 - exp(-(x/sigma)^(-z)))
}

## Comparison of detection functions without TOA.
plot(x, hn(x, coef(simplefit.hn)), type = "l")
lines(x, ss(x, 150, coef(ssfit2)), col = "red")
lines(x, logss(x, 150, coef(ssfit2.log)), col = "purple")
lines(x, th(x, coef(simplefit.th)), col = "green")
lines(x, logth(x, coef(simplefit.logth)), col = "orange")
lines(x, hr(x, coef(simplefit.hr1)), col = "blue")
hr2pars <- c(0, 1, coef(simplefit.hr2)[2:3])
lines(x, hr(x, hr2pars), col = "brown")

## Comparison of detection functions with TOA.
plot(x, hn(x, coef(toafit.hn)), type = "l")
lines(x, th(x, coef(toafit.bo)), col = "green")
lines(x, hr(x, coef(toafit.hr1)), col = "blue")
hr2pars <- c(0, 1, coef(toafit.hr2)[2:3])
lines(x, hr(x, hr2pars), col = "brown")
