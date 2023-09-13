
library(purrr)
library(tibble)
library(digest)


instagram_login <- function(user, pass){
  .config <- config::get()
  username <- .config$instagram_user
  pass <- .config$instagram_pass
  
  client$navigate("https://www.instagram.com/")
  
  Sys.sleep(3)
  input_user <- client$findElement(
    using = "xpath",
    value = "//input[@name = 'username']"
  )
  input_user$sendKeysToElement(list(username))
  
  input_pass <- client$findElement(
    using = "xpath",
    value = "//input[@type = 'password']"
  )
  input_pass$sendKeysToElement(list(pass))
  input_pass$sendKeysToElement(list(RSelenium::selKeys$enter))
  
}

instagram_extract_comments <- function(page){
  
  client$navigate(page)
  
  posts <- client$findElements(
    using = "xpath",
    value = "//div[@class = '_aabd _aa8k  _al3l']/a"
  )
  posts <- map_chr(posts, function(post)post$getElementAttribute("href")[[1]])
  
  df <- map_df(posts, function(url){
    client$navigate(url)
    
    post_text <- client$findElements(
      using = "xpath",
      value = "//ul[@class = '_a9z6 _a9za']"
    )
    post_text <- post_text[[1]]$getElementText()[[1]]
    comments <- client$findElements(
      using = "xpath",
      value = "//ul[@class = '_a9ym']"
    )
    
    comments <- purrr::map_chr(comments, function(comment) comment$getElementText()[[1]])
    
    tibble(
      post_id = url,
      post_text,
      comments = comments
    )
  })
  
  return(df)
}
