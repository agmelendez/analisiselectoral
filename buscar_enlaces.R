library(RSelenium)
library(netstat)
library(wdman)
library(rvest)
library(purrr)
library(stringr)
library(tibble)

mail <- "aguero16404550"
pass <- "Bizcus-fumfus-7xipne"

remove_driver <- rsDriver(
  browser = "firefox",
  chromever = NULL,
  verbose = TRUE,
  port = free_port()
)

navegador <- remove_driver$client
navegador$setTimeout(type = "load", milliseconds = 5000)
navegador$setTimeout(type = "implicit", milliseconds = 5000)

navigate <- function(x, url) {
  x$navigate(url)
  return(x)
}

twitter_login <- function(x, user, pass){
  x$navigate("https://twitter.com/i/flow/login")
  Sys.sleep(3)
  input_username <- x$findElement(
    using = "xpath",
    value = "//input[@autocomplete = 'username']"
  )
  
  input_username$sendKeysToElement(list(mail,selKeys$enter))
  
  Sys.sleep(3)
  
  input_pass <- navegador$findElement(
    using = "xpath",
    value = "//input[@name = 'password']"
  )
  input_pass$sendKeysToElement(list(pass,selKeys$enter))
  
  return(x)
}
extract_urls <- function(x, n = 10){
  body <- x$findElement(
    using = "xpath",
    value = "//body"
  )
  
  out <- map(seq_len(n),~{
    Sys.sleep(5)
    body$sendKeysToElement(list(selKeys$end))
    
    pagina <- read_html(
      x$getPageSource()[[1]]
    )
    
    url <- pagina %>% 
      html_elements(xpath = "//article//a") %>% 
      html_attr("href")
    
    url <- url[str_detect(url, "https")]
    return(url)
  })
  return(out)
}



navegador %>% 
  twitter_login(user = mail, pass = pass)
  
medios <- c("nacion","crhoycom","MonumentalCR","DiarioExtraCR")

df <- map_df(medios , function(medio){
  enlaces <- navegador %>% 
    navigate(paste0("https://twitter.com/",medio)) %>% 
    extract_urls(n = 10) 
  
  enlaces <- enlaces %>% 
    flatten_chr() %>% 
    unique()
  
  tibble(medio, enlaces)
})

df


navegador$close()
servidor$stop()

