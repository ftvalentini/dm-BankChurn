# librerias y funciones
source("load_librerias.R")
source("funciones.R")

# features ----------------------------------------------------------------
# variables no numericas segun docs/DiccionarioDatos (categoricas, fechas y clase)
kvars_cat <- c("marketing_activo_ultimos90dias",
               "cliente_vip",
               "internet",
               "tpaquete"%+%1:9,
               "tcaja_seguridad",
               "tcallcenter",
               "thomebanking",
               "Master_marca_atraso",
               "Master_cuenta_estado",
               "Visa_marca_atraso",
               "Visa_cuenta_estado")
# kvars_dates_ym <- c("foto_mes")
kvars_dates_ymd <- c("Master_Fvencimiento",
                     "Master_Finiciomora",
                     "Master_fultimo_cierre",
                     "Master_fechaalta",
                     "Visa_Fvencimiento",
                     "Visa_Finiciomora",
                     "Visa_fultimo_cierre",
                     "Visa_fechaalta")
kvars_id <- "numero_de_cliente"
kvars_delete <- c("foto_mes")
kclase <- "clase_ternaria"

# datos -------------------------------------------------------------------
# usa data.table::fread porque es mas rapido
base_raw <- data.table::fread("data/raw/201802.txt", header=TRUE, sep="\t")

# transformacion segun tipo de datos
base <- base_raw %>% 
  mutate_at(kvars_cat, as.factor) %>% 
  mutate_at(kvars_dates_ymd, function(x) as.Date(as.character(x),format="%Y%m%d")) %>% 
  mutate_at(kclase, as.factor) %>%
  select(-kvars_id) %>% 
  select(-kvars_delete)

# cantidad de vars segun tipo
base %>% map_chr(class) %>% table

# base numeric, cat y date
base_num <- base %>% select_if(is.numeric)
base_cat <- base %>% select_if(is.factor)
base_dat <- base %>% select_if(lubridate::is.Date)


# exploratorio ------------------------------------------------------------

# distribucion de las categoricas
map2(.x=base_cat, .y=names(base_cat), 
     function(x,y) table(x, dnn=y) %>% knitr::kable())

# En porcentaje
map2(.x=base_cat, .y=names(base_cat), 
     function(x,y)table(x, dnn=y) %>% prop.table() %>% '*'(100) %>%   knitr::kable())

# distribucion de la clase
table(base_raw$clase_ternaria)

# distribucion de las numericas
histogramas_l <- map2(.x=base_num, .y=names(base_num), 
                      function(x,y) hist(x, main=y))
map_dfr(.x=base_num,
     function(x) summary(x) %>% broom::tidy(),
     .id="variable") %>% tail

# correlacion de las numericas

cor_num <- base_num %>% cor() 
cor_num[lower.tri(cor_num,diag=TRUE)]=NA  # Como lo hago con dplyr? Es como un mutate_all pero deberia buscar 
                                          # otro enfoque que pasar un vector TRUE/FALSE no?
cor_num2 <- cor_num %>% as.table %>%
  as.data.frame() %>%  na.omit() %>%
  rename(correlacion = Freq) %>%
  dplyr::filter(correlacion > 0.6 | correlacion < -0.6) %>% 
  arrange(desc(correlacion))


### Categoricas
# gain ratio
df_gr <- FSelector::gain.ratio(clase_ternaria~., data=base_cat) %>%
  dplyr::mutate(var=rownames(.)) %>% dplyr::select(2:1) %>% 
  dplyr::arrange(-attr_importance) %>% rename(Attribute_importance = attr_importance)
knitr::kable(df_gr)
