box::use(
  RSelenium[selKeys],
  tibble[tibble],
  rvest[...],
  stringr[str_extract],
  digest[digest],
  purrr[map_dfr, transpose,safely]
)


#' @export
facebook_login <- function(client, user, pass){
  client$navigate("https://touch.facebook.com/login")

  input_usuario <- client$findElement(using ="xpath", value = "//input[@id = 'm_login_email']")
  input_usuario$sendKeysToElement(list(user))

  input_clave <- client$findElement(using ="xpath", value = "//input[@id = 'm_login_password']")
  input_clave$sendKeysToElement(list(pass))

  input_clave$sendKeysToElement(list(selKeys$enter))
  
  Sys.sleep(3)
  boton_aceptar <- client$findElement(using ="xpath", value = "//button[@value = 'Aceptar']")
  boton_aceptar$clickElement()
  return(client)
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

load_comments <- function(navegador, publicacion){
  xpath <- "//a[text()[contains(.,'Ver más comentarios…')]]"
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

#' @export
extract_posts <- function(client, page, seconds = 30){
  client$navigate(page)
  Sys.sleep(3)
  scroll(client, tiempo_espera = 3, tiempo_maximo = seconds)
  publicaciones <- client$findElements(using = "xpath", value = "//article")
  out <- map_dfr(publicaciones, function(post) {
    source <- unlist(post$getElementAttribute("outerHTML"))
    
    url <- read_html(source) %>%
      html_node(xpath = "//a[@class = '_5msj']") %>%
      html_attr("href") %>%
      paste0("https://touch.facebook.com", .)
    
    page <- str_extract(url, "(?<=&id=)\\d+")
    
    text <- read_html(source) %>%
      html_node(xpath = "//p") %>%
      html_text(trim = T)
    
    tibble(
      page_id = page,
      post_id = digest(url, algo = "md5"),
      text = text,
      url = url
    )
  })
  return(out)
}

#' @export
facebook_extract_comments <- function(client, posts){
  
  out <- map_dfr(transpose(posts),function(post) {
    Sys.sleep(10)
    client$navigate(post$url)
    load_comments(client, post)
    comments <- client$findElements(using = "xpath",
                                          value = "//div[@data-sigil = 'comment']")
    
    comments <- map_dfr(comments, function(comment) {
      
      source <- unlist(comment$getElementAttribute("outerHTML"))
      text <- read_html(source) %>%
        html_node(xpath = "//div[@data-sigil = 'comment-body']") %>% 
        html_text() %>%
        unlist()
      
      id_comentario <- read_html(source) %>%
        html_node(xpath = "//div[@data-sigil = 'comment-body']") %>%
        html_attr("data-commentid") %>%
        unlist()
      
      use_url <- read_html(source) %>%
        html_node(xpath = "//div[@class = '_2b05']/a") %>%
        html_attr("href") %>%
        paste0("https://touch.facebook.com", .)
      
      user_name <- read_html(source) %>%
        html_node(xpath = "//div[@class = '_2b05']/a/text()") %>%
        html_text(trim = T)
      
      tibble(
        page_id = post$page_id,
        post_text = post$text,
        post_id = post$post_id,
        id_comentario,
        use_url,
        user_name,
        text
      )
    })
  })
  return(out)
}
