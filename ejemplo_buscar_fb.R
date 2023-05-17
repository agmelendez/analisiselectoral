library(duckdb)
library(dplyr)

con <- dbConnect(duckdb::duckdb(), dbdir = "data/datos.duckdb", read_only = FALSE)

comentarios <- tbl(con, "fb_comments") %>% 
  collect()

posts <- tbl(con, "fb_posts") %>% 
  collect()

patron <- regex("", ignore_case = TRUE) 

id <- posts %>% 
  filter(
    str_detect(text, patron)
  )

comentarios %>% 
  filter(
    post_id %in% id
  ) %>% 
  View()
