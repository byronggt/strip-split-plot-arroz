if(!require(emmeans)){install.packages("emmeans")}
if(!require(agridat)){install.packages("agridat")}

# Con información del texto de Gomez, K.A, and A.A. Gomez. 1984
# Statistical Procedures for Agriculture Research 
# 2nd Ed. John Wiley and Sons. New York 

# Variedades (gen) en las franjas en el sentido 1
# Nitrógeno (nitro) en las franjas en el sentido 2
# Métodos de plantación (planting) en las intersecciones

data(gomez.stripsplitplot)
dat <- gomez.stripsplitplot
dat # nitro/columna, gen/fila, planting/intersección

# Layout

libs(desplot)
windows(11,11)
desplot(dat, gen ~ col*row,
        out1=rep, col=nitro, text=planting, cex=1,
        main="Croquis de campo")

# Gómez y Gómez tabla 4.19, ANOVA para el arreglo strip-split-plot

dat <- transform(dat, nf=factor(nitro));dat # Convertir nitro a factor
m1 <- aov(yield ~ nf * gen * planting +
            Error(rep + rep:nf + rep:gen + rep:nf:gen), data=dat)
summary(m1)

# Prueba de medias para:

# gen*nf (Var*N) 

means_gen_nf <- emmeans(m1, ~gen*nf)
multcomp::cld(means_gen_nf, Letters = LETTERS)

# gen*planting (Var*Plant)

means_gen_planting <- emmeans(m1, ~gen*planting)
multcomp::cld(means_gen_planting, Letters = LETTERS)