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
             "https://m.facebook.com/profile.php?id=100067201668918",
             "https://m.facebook.com/profile.php?id=100064679861659")

for (pagina in paginas) {
  client$navigate(pagina)
  scroll(client, tiempo_espera = 2, tiempo_maximo = 5)
  
  posts <- extraer_publicaciones(client)
  DBI::dbAppendTable(con, "fb_posts", posts)
  
  comentarios <- map_dfr(transpose(posts), ~extraer_comentarios(client,.x))
  DBI::dbAppendTable(con, "fb_comments", comentarios)
}


# commentarios <- tbl(con, "fb_comments") %>% 
#   collect()
# 
# write_xlsx(commentarios, "data/comentrios_fb.xlsx")

# Extracción twitter ------------------------------------------------------

twitter_login(client)
Sys.sleep(10)
find_term(client, "Rodrigo Chaves")
posts <- load_posts(client, 3)
comentarios <- map_dfr(posts, ~post_commets(client, .x))

DBI::dbAppendTable(con, "tw_comments2", comentarios)


dbDisconnect(con, shutdown=TRUE)

bot$server$server$stop()
