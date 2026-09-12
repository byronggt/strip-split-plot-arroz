# Analisis strip-split-plot del rendimiento de arroz

Este documento presenta un flujo reproducible para analizar el rendimiento de arroz con el conjunto de datos `gomez.stripsplitplot` del paquete `agridat`. El experimento corresponde a un arreglo **strip-split-plot**: las variedades (`gen`) se asignan a franjas en una direccion, las dosis de nitrogeno (`nitro`) a franjas perpendiculares y los metodos de plantacion (`planting`) a las intersecciones de ambas franjas.

El analisis sigue el modelo de Gomez y Gomez (1984), ajustado con `aov()` y su estructura de errores. Las comparaciones multiples se obtienen con `emmeans` y letras de agrupamiento compacto para las interacciones que interesan: `gen:nitro` y `gen:planting`.

**Profesor:** Dr. Byron González

## Tabla de contenido

- [Objetivo y estructura experimental](#objetivo-y-estructura-experimental)
- [1. Instalar y cargar paquetes](#1-instalar-y-cargar-paquetes)
- [2. Cargar y revisar los datos](#2-cargar-y-revisar-los-datos)
- [3. Preparar los factores](#3-preparar-los-factores)
- [4. Visualizar el croquis de campo](#4-visualizar-el-croquis-de-campo)
- [5. Ajustar el modelo strip-split-plot](#5-ajustar-el-modelo-strip-split-plot)
- [6. Obtener el resumen del ANOVA](#6-obtener-el-resumen-del-anova)
- [7. Comparar `gen:nitro`](#7-comparar-gennitro)
- [8. Comparar `gen:planting`](#8-comparar-genplanting)
- [9. Interpretar y reportar los resultados](#9-interpretar-y-reportar-los-resultados)
- [Referencias](#referencias)

## Objetivo y estructura experimental

La respuesta es `yield`, el rendimiento observado en cada unidad experimental. Las variables tienen la siguiente funcion:

| Variable | Funcion en el diseno |
| --- | --- |
| `rep` | Repeticion o bloque del experimento |
| `gen` | Variedad, asignada a franjas en una direccion |
| `nitro` | Nivel de nitrogeno, asignado a franjas perpendiculares |
| `planting` | Metodo de plantacion, asignado a las intersecciones |
| `yield` | Rendimiento de arroz |

En un strip-split-plot no todas las fuentes de variacion tienen el mismo error experimental. Por eso no se debe analizar el experimento como si fuera un factorial completamente aleatorizado con un unico error residual. La clausula `Error()` de `aov()` representa los estratos asociados con las repeticiones, las franjas y sus combinaciones.

## 1. Instalar y cargar paquetes

Este chunk instala los paquetes que no esten disponibles y luego los carga. `agridat` proporciona los datos de ejemplo; `emmeans` calcula medias marginales estimadas; `multcomp` genera las letras de agrupamiento; y `desplot` permite dibujar el croquis del campo.

```r
paquetes <- c("agridat", "emmeans", "multcomp", "desplot")
nuevos <- paquetes[!vapply(paquetes, requireNamespace, logical(1), quietly = TRUE)]

if (length(nuevos) > 0) {
  install.packages(nuevos)
}

library(agridat)
library(emmeans)
library(multcomp)
library(desplot)
```

La instalacion solo debe ejecutarse cuando sea necesaria. En un servidor de GitHub Actions o en otro entorno automatizado, es preferible instalar las dependencias en una etapa separada y dejar el documento dedicado al analisis.

## 2. Cargar y revisar los datos

El siguiente chunk carga `gomez.stripsplitplot` y crea una copia de trabajo llamada `dat`. Las inspecciones iniciales permiten comprobar los nombres de las columnas, el tipo de cada variable y la cantidad de observaciones por combinacion experimental.

```r
data(gomez.stripsplitplot, package = "agridat")
dat <- gomez.stripsplitplot

str(dat)
head(dat)
summary(dat)

with(dat, table(rep, gen, nitro, planting))
```

Antes de ajustar el modelo, hay que verificar que cada combinacion prevista exista y que las repeticiones esten correctamente identificadas. La tabla de frecuencias tambien ayuda a detectar datos faltantes o celdas con diferente numero de observaciones.

## 3. Preparar los factores

Aunque `nitro` puede aparecer como variable numerica, en este experimento representa niveles discretos de tratamiento. Debe tratarse como factor para que el modelo estime una media por nivel y no una tendencia lineal impuesta por los valores numericos.

```r
dat <- transform(
  dat,
  rep = factor(rep),
  gen = factor(gen),
  nf = factor(nitro),
  planting = factor(planting)
)

str(dat)
```

Se conserva `nitro` para identificar los niveles originales y se crea `nf` como el factor que entra en el modelo. Esta conversion es importante porque las interacciones `gen:nf` y `gen:planting` deben representar combinaciones de tratamientos, no pendientes numericas.

## 4. Visualizar el croquis de campo

El croquis permite comprobar la asignacion espacial de los tratamientos. En `desplot()`, `gen` y `nitro` se muestran como franjas, mientras que `planting` se escribe en las intersecciones.

```r
desplot(
  dat,
  gen ~ col * row,
  out1 = rep,
  col = nitro,
  text = planting,
  cex = 1,
  main = "Croquis de campo: experimento strip-split-plot"
)
```

`out1 = rep` separa visualmente las repeticiones. `col = nitro` colorea las franjas de nitrogeno y `text = planting` etiqueta el tratamiento de plantacion en cada interseccion. Esta figura no sustituye al modelo, pero sirve para validar que la estructura declarada en `Error()` corresponde al arreglo experimental.

## 5. Ajustar el modelo strip-split-plot

El modelo se ajusta con la formula factorial completa `gen * nf * planting`, que incluye los tres efectos principales, las tres interacciones de dos factores y la interaccion triple. La parte `Error()` especifica los estratos de aleatorizacion del diseño.

```r
m1 <- aov(
  yield ~ gen * nf * planting +
    Error(rep + rep:nf + rep:gen + rep:nf:gen),
  data = dat
)
```

La interpretacion de los terminos de error es la siguiente:

- `rep`: variacion entre repeticiones.
- `rep:nf`: error asociado con las franjas de nitrogeno dentro de repeticion.
- `rep:gen`: error asociado con las franjas de variedades dentro de repeticion.
- `rep:nf:gen`: error de las intersecciones `nf` por `gen`, dentro de repeticion; este es el estrato en el que se evaluan los tratamientos de `planting` y las interacciones que los incluyen.

La formula debe mantenerse vinculada al modo en que se aleatorizaron los tratamientos. Cambiarla por un modelo con un unico residual puede producir pruebas F y errores estandar incorrectos para algunas fuentes.

## 6. Obtener el resumen del ANOVA

`summary(m1)` imprime el resumen de cada estrato de error creado por `aov()`. Es normal recibir varios bloques de resultados en lugar de una sola tabla, porque cada bloque corresponde a una escala distinta de aleatorizacion.

```r
summary(m1)
```

La lectura debe comenzar por los efectos principales y las interacciones en el estrato que les corresponde. Si una interaccion es significativa, sus medias marginales deben examinarse antes de interpretar los efectos principales. En particular, una interaccion significativa `gen:nf` indica que la respuesta de las variedades cambia segun el nivel de nitrogeno; una interaccion significativa `gen:planting` indica que el metodo de plantacion no tiene el mismo comportamiento en todas las variedades.

Para conservar el resumen en un objeto y facilitar un reporte posterior:

```r
anova_m1 <- summary(m1)
anova_m1
```

## 7. Comparar `gen:nitro`

Las medias marginales estimadas para cada combinacion de variedad y nitrogeno se solicitan con `emmeans(m1, ~ gen * nf)`. `emmeans` usa el modelo ajustado y, por tanto, respeta la informacion disponible y los ajustes del modelo en lugar de calcular solamente promedios aritmeticos sin contexto.

```r
means_gen_nf <- emmeans(m1, ~ gen * nf)
means_gen_nf
```

Primero es recomendable obtener la tabla de contrastes pareados con ajuste por multiplicidad:

```r
pairs_gen_nf <- pairs(means_gen_nf, adjust = "tukey")
pairs_gen_nf
```

El ajuste de Tukey controla el error familiar cuando se comparan todas las combinaciones de `gen` por `nf`. Para presentar las medias de forma compacta, se generan letras: dos medias que comparten al menos una letra no se consideran diferentes al nivel de significancia utilizado.

```r
cld_gen_nf <- multcomp::cld(
  means_gen_nf,
  Letters = LETTERS,
  adjust = "tukey",
  sort = FALSE
)

cld_gen_nf
```

La columna `.group` contiene las letras de agrupamiento. Conviene ordenar la tabla por `gen` y `nf` para que conserve la estructura experimental:

```r
cld_gen_nf[order(cld_gen_nf$gen, cld_gen_nf$nf), ]
```

Estas comparaciones responden a la pregunta: **que variedades presentan rendimientos diferentes dentro de la combinacion de niveles de nitrogeno?** Si el interes cientifico es comparar variedades dentro de cada nivel de nitrogeno, es mas claro estimar y contrastar con `by = "nf"`:

```r
emmeans(m1, pairwise ~ gen | nf, adjust = "tukey")
```

Esta ultima forma evita mezclar en una sola familia comparaciones entre niveles de nitrogeno que responden a preguntas diferentes.

## 8. Comparar `gen:planting`

El mismo procedimiento se aplica a la interaccion entre variedad y metodo de plantacion. Primero se calculan las medias marginales estimadas y despues se realizan las comparaciones multiples.

```r
means_gen_planting <- emmeans(m1, ~ gen * planting)
means_gen_planting
```

```r
pairs_gen_planting <- pairs(means_gen_planting, adjust = "tukey")
pairs_gen_planting
```

```r
cld_gen_planting <- multcomp::cld(
  means_gen_planting,
  Letters = LETTERS,
  adjust = "tukey",
  sort = FALSE
)

cld_gen_planting
```

Para comparar metodos de plantacion dentro de cada variedad, que suele ser la interpretacion mas util cuando `gen:planting` es significativa:

```r
emmeans(m1, pairwise ~ planting | gen, adjust = "tukey")
```

La pregunta que responde este conjunto de contrastes es: **que metodos de plantacion difieren dentro de cada variedad?** La interpretacion debe hacerse con las medias y sus errores estandar, no solamente con las letras.

## 9. Interpretar y reportar los resultados

Un reporte completo debe incluir:

1. La unidad experimental y la estructura de asignacion de `gen`, `nitro` y `planting`.
2. El modelo utilizado, incluida la estructura `Error(rep + rep:nf + rep:gen + rep:nf:gen)`.
3. El resumen del ANOVA con grados de libertad, cuadrados medios, estadisticos F y valores p.
4. Las medias marginales estimadas para las interacciones de interes.
5. El metodo de ajuste por comparaciones multiples, aqui Tukey.
6. Las letras de agrupamiento, indicando el nivel de significancia empleado.

Las letras no deben interpretarse como una escala de calidad por si mismas. Una media con la letra `A` no es necesariamente agronomicamente superior a otra con `B`; la conclusion estadistica depende de la diferencia estimada, su incertidumbre y la pregunta experimental. Tambien conviene reportar las unidades de `yield` y el nivel de significancia, por ejemplo `alpha = 0.05`.

Para una tabla final ordenada de cada interaccion:

```r
resultado_gen_nf <- as.data.frame(cld_gen_nf)
resultado_gen_planting <- as.data.frame(cld_gen_planting)

resultado_gen_nf
resultado_gen_planting
```

Si el experimento presenta datos faltantes, desbalance o supuestos claramente incumplidos, es necesario revisar el modelo antes de aceptar las pruebas multiples. En todos los casos, las comparaciones deben derivarse del mismo ajuste que se utilizó para el ANOVA.

## Referencias

- Gomez, K. A., y Gomez, A. A. (1984). *Statistical Procedures for Agricultural Research*. 2nd ed. John Wiley & Sons.
- Heining, C. (paquete `agridat`). Datos `gomez.stripsplitplot`.
- Lenth, R. V. (paquete `emmeans`). Estimated marginal means, contrasts y comparaciones multiples.