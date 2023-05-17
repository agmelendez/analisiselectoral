library(duckdb)
library(DBI)
library(writexl)
source("R/create_server.R")
source("R/facebook.R")
source("R/twitter.R")

con <- dbConnect(duckdb::duckdb(), dbdir = "data/datos.duckdb", read_only = FALSE)
bot <- create_server()
client <- bot$client

# Extracción FB -----------------------------------------------------------

facebook_login()

paginas <- c("https://touch.facebook.com/crhoy.comnoticias/",
             "https://www.facebook.com/hablandoclarocr","https://www.facebook.com/ameliarueda",
             "https://www.facebook.com/laronchacr","https://www.facebook.com/Noticias.Monumental")

for (pagina in paginas) {
  client$navigate(pagina)
  scroll(client, tiempo_espera = 2, tiempo_maximo = 5)}
  
  posts <- extraer_publicaciones(client)
  DBI::dbWriteTable(con, "fb_posts", posts)
  
  comentarios <- map_dfr(transpose(posts), ~extraer_comentarios(client,.x))
  DBI::dbAppendTable(con, "fb_comments", comentarios)

commentarios <- tbl(con, "fb_comments") %>% 
 collect()

write_xlsx(commentarios, "data/comentrios_fb.xlsx")

# Extracción twitter ------------------------------------------------------

twitter_login(client)
find_term(client, "RodrigoChaves")
posts <- load_posts(client, 3)
comentarios <- map_dfr(posts, ~post_commets(client, .x))

DBI::dbAppendTable(con, "tw_comments", df)

write_xlsx(comentarios, "data/comentrios_tw.xlsx")

dbDisconnect(con, shutdown=TRUE)
