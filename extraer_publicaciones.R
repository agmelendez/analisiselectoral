library(wdman)
library(RSelenium)
library(config)
library(rvest)
library(tidyverse)
library(netstat)

credenciales <- config::get(file = "config.yml")

source("R/utilidades.R")

# Iniciar Servidor --------------------------------------------------------

selenium_object <- selenium(retcommand = TRUE, check = F)
remote_driver <- rsDriver(
  browser = "firefox",
  chromever = NULL,
  verbose = TRUE,
  port = free_port()
)
navegador <- remote_driver$client
navegador$setTimeout(type = "implicit", milliseconds = 3000)
navegador$setTimeout(type = "page load", milliseconds = 3000)


# Iniciar Sesion ----------------------------------------------------------
# 
navegador <- iniciar_sesion(navegador, credenciales)


# Cargar publicaciones ----------------------------------------------------
# 

paginas <- c("https://touch.facebook.com/crhoy.comnoticias",
             "https://m.facebook.com/profile.php?id=100064679861659",
             "https://m.facebook.com/profile.php?id=100067201668918")

resultados <- map_dfr(paginas, function(pagina){
  navegador$navigate(pagina)
  scroll(navegador = navegador, tiempo_espera = 2, tiempo_maximo = 5)
  publicaciones <- extraer_publicaciones(navegador)
  #publicaciones <- na.omit(publicaciones)
  publicaciones <- tail(publicaciones,10)
  
  
  comentarios <- extraer_comentarios(navegador,
                                     transpose(publicaciones))
  
}, .id = "pagina")


#Cerramos el navegador y detenemos le servidor
navegador$close()
remote_driver$server$stop()


