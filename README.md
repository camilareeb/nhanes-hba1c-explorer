# NHANES HbA1c Explorer

Aplicación interactiva en R Shiny para explorar la relación entre la
hemoglobina glicosilada (HbA1c) y variables antropométricas y
sociodemográficas, sobre datos de la encuesta NHANES.

Es el complemento interactivo de
[hba1c-diabetes-analysis](https://github.com/camireeb/hba1c-diabetes-analysis):
mientras ese repo contiene el análisis estático (EDA, modelos, conclusiones),
esta app permite explorar los mismos datos de forma dinámica, filtrando por
subgrupos y comparando visualmente.

## Qué hace

La app tiene un panel lateral para cargar un archivo (.tsv/.csv) y filtrar
por rango de edad, sexo, raza/etnia, nivel de ingresos y diagnóstico de
diabetes o prediabetes. Los resultados se organizan en 5 pestañas:

- **Vista previa** — primeras filas del archivo cargado.
- **HbA1c por edad** — dispersión de HbA1c vs edad, coloreada por
  diagnóstico, con línea de tendencia.
- **HbA1c por grupos** — boxplots comparando la distribución de HbA1c
  entre subgrupos (diagnóstico, sexo, raza/etnia o ingresos, seleccionable).
- **Relación HbA1c vs antropometría** — dispersión de HbA1c frente a IMC o
  circunferencia de cintura (seleccionable), con línea de tendencia.
- **Resumen** — tabla con N total, media/mediana de HbA1c, media de IMC y
  de circunferencia de cintura, todo recalculado según los filtros activos.


## Formato de entrada esperado

Archivo delimitado (tab/coma/punto y coma) con estas columnas:

| Columna | Descripción |
|---|---|
| `age` | Edad (numérica) |
| `sex` | Sexo (`male` / `female`) |
| `re` | Raza / etnia |
| `income` | Nivel de ingresos familiares |
| `dx` | Diagnóstico de diabetes/prediabetes (`0`/`1`) |
| `gh` | HbA1c (%) |
| `bmi` | Índice de masa corporal |
| `waist` | Circunferencia de cintura |

## Pruébala con el ejemplo incluido

`example_data/example_nhanes.tsv` es un dataset sintético (300 filas) con
las columnas exactas que espera la app, listo para subir directamente al
abrirla.

Para usar los datos reales de NHANES, descarga `nhgh.tsv` desde
[hbiostat.org/data](https://hbiostat.org/data) (misma fuente que el repo de
análisis) y súbelo desde la app.

## Cómo ejecutarla

```r
install.packages(c("shiny", "ggplot2", "dplyr"))
shiny::runApp("app.R")
```

## Tecnologías

R · Shiny · ggplot2 · dplyr
