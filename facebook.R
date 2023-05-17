library(tidyverse)
library(rvest)

# login facebook ----------------------------------------------------------

facebook_login <- function(){
  
  .config <- config::get()
  client$navigate("https://touch.facebook.com/login")
  
  # Identificar el campo del usuario y contraseña ---------------------------
  #correo
  input_usuario <- client$findElement(using ="xpath",
                                      value = "//input[@id = 'm_login_email']")
  input_usuario$sendKeysToElement(list(.config$facebook_user))
  #contraseña
  input_clave <- client$findElement(using ="xpath",
                                    value = "//input[@id = 'm_login_password']")
  input_clave$sendKeysToElement(list(.config$facebook_password))
  
  input_clave$sendKeysToElement(list(selKeys$enter)) # enviar un enter
  
  Sys.sleep(3) # esperamos a que cargue la pagina
  boton_aceptar <- client$findElement(using ="xpath",
                                      value = "//button[@value = 'Aceptar']")
  boton_aceptar$clickElement()
}


scroll <- function(navegador, tiempo_espera, tiempo_maximo) {
  hora_final <- Sys.time() + lubridate::seconds(tiempo_maximo)
  while (TRUE) {
    navegador$executeScript("window.scrollTo(0, document.body.scrollHeight);")
    Sys.sleep(tiempo_espera)
    if(Sys.time() > hora_final) break
  }
  return(invisible(navegador))
}

ir_a <- function(navegador, url){
  navegador$navigate(url)
  return(navegador)
}

extraer_publicaciones <- function(navegador){
  publicaciones <- navegador$findElements(using = "xpath", value = "//article")
  out <- lapply(publicaciones, function(post) {
    source <- unlist(post$getElementAttribute("outerHTML"))
    
    enlace <- read_html(source) %>% 
      html_element(xpath = "//a[contains(@href, 'story_fbid')]/@href") %>% 
      html_text2() %>% 
      paste0("https://touch.facebook.com",.)
    
    post <- str_extract(enlace, "(?<=story_fbid=)[\\d\\w]+")
    page <- str_extract(enlace, "(?<=&id=)\\d+")
    
    url <- enlace
    text <- read_html(source) %>%
      html_node(xpath = "//p") %>%
      html_text(trim = T)
    
    data.frame(
      page_id = page,
      post_id = post,
      text = text,
      url = url
    )
  })
  do.call("rbind", out)
}

cargar_comentarios <- function(navegador, publicacion){
  
  xpath <- paste0("//div[@id = 'see_prev_", publicacion$post_id,"']")
  cargar <- safely(navegador$findElement)
  
  mas_comentarios <- cargar(using = "xpath", value = xpath)$result
  altura <- unlist(navegador$executeScript("return document.body.scrollHeight"))
  nueva_altura <- 0
  
  while (altura != nueva_altura && !is.null(mas_comentarios)) {
    altura <- unlist(navegador$executeScript("return document.body.scrollHeight"))
    mas_comentarios$clickElement()
    Sys.sleep(2)
    nueva_altura <- unlist(navegador$executeScript("return document.body.scrollHeight"))
    mas_comentarios <- cargar(using = "xpath", value = xpath)$result
  }
}

extraer_comentarios <- function(navegador,publicacion){
  Sys.sleep(5)
  navegador$navigate(publicacion$url)
  suppressMessages(cargar_comentarios(navegador, publicacion))
  comentarios <- navegador$findElements(using = "xpath",
                                        value = "//div[@data-sigil = 'comment']")
  
  comentarios <- lapply(comentarios, function(comentario) {
    
    source <- unlist(comentario$getElementAttribute("outerHTML"))
    texto <- read_html(source) %>%
      html_node(xpath = "//div[@data-sigil = 'comment-body']") %>% 
      html_text() %>%
      unlist()
    
    id_comentario <- read_html(source) %>%
      html_node(xpath = "//div[@data-sigil = 'comment-body']") %>%
      html_attr("data-commentid") %>%
      unlist()
    
    usuario_url <- read_html(source) %>%
      html_node(xpath = "//div[@class = '_2b05']/a") %>%
      html_attr("href") %>%
      paste0("https://touch.facebook.com", .)
    
    usuario_nombre <- read_html(source) %>%
      html_node(xpath = "//div[@class = '_2b05']/a/text()") %>%
      html_text(trim = T)
    data.frame(
      page_id = publicacion$page_id,
      post_id = publicacion$post_id,
      id_comentario,
      usuario_url,
      usuario_nombre,
      texto
    )
  })
  do.call("rbind", comentarios)
}

with_progress <- function(x, f, m = lapply, text = "") {
  pb <- progress::progress_bar$new(format = paste0(text," [:bar] :current/:total (:percent)"),
                                   total = length(x),
                                   clear = FALSE,
                                   width = 120)
  fn <- function(...) {
    pb$tick()
    f(...)
  }
  
  m(x, fn)
}

