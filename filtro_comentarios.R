library(tidyverse)

datos <- read_rds("database/all_comments2023-09-10 10:13:41.rds")

# busqueda por tags
tags <- c("impuestos")

df <- datos %>% 
  mutate(tags=str_to_lower(tags)) %>% 
  filter(str_detect(tags, paste0(tags, collapse = "|"))) 

write.csv(df, paste0("database/busqueda_tags_",paste0(tags, collapse = "|"),".csv"))


# busqueda por tags
palabras <- "impuestos"

df <- datos %>% 
  mutate(text=str_to_lower(post_text)) %>% 
  filter(str_detect(post_text, paste0(palabras, collapse = "|"))) 

write.csv(df, paste0("database/busqueda_palabras_",paste0(tags, collapse = "|"),".csv"))
