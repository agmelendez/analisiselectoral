box::use(
  RSelenium[selKeys],
  glue[glue],
  utils[URLencode],
  rvest[...],
  purrr[map_chr, map_dfr, possibly],
  stringr[str_replace_all, str_extract, ],
  lubridate[parse_date_time]
  
)

#' @export
twitter_login <- function(client, username, password){
  client$navigate("https://twitter.com/i/flow/login")
  input_user <- client$findElement(
    using = "xpath",
    value = "//input[@autocomplete = 'username']"
  )
  input_user$sendKeysToElement(list(username))
  input_user$sendKeysToElement(list(selKeys$enter))
  
  input_pass <- client$findElement(
    using = "xpath",
    value = "//input[@autocomplete = 'current-password']"
  )
  input_pass$sendKeysToElement(list(password))
  input_pass$sendKeysToElement(list(selKeys$enter))
  return(client)
}

#' @export
find_terms <- function(client, text){
  text = URLencode(text)
  url <- glue("https://twitter.com/search?q={text}&src=typed_query")
  client$navigate(url)
  Sys.sleep(5)
}

#' @export
extract_posts <- function(client, n = 10){
  posts <- c()
  body <- client$findElement(
    using = "xpath",
    value = "//body"
  )
  for (i in seq_len(n)) {
    Sys.sleep(3)
    source <- unlist(client$getPageSource())
    page <- read_html(source)
    new_posts <- page %>% 
      html_elements(xpath = "//article") %>% 
      html_elements(xpath = "//div[@class = 'css-1dbjc4n r-18u37iz r-1q142lx']//a") %>% 
      html_attr("href") %>% 
      paste0("https://twitter.com",.)
    
    posts <- c(posts, new_posts)
    body$sendKeysToElement(list(selKeys$end))
  }
  return(posts)
}

get_reactions <- function() {
  x <- client$findElement(using = "xpath", value = "//div[@class = 'css-1dbjc4n r-18u37iz r-1w6e6rj']")
  x$getElementText()
}
get_reactions <- possibly(get_reactions,quiet = TRUE,otherwise = "")

extract_comments <- function(client, url){
  
  client$navigate(url)
  
  body <- client$findElement(
    using = "xpath",
    value = "//body"
  )
  for (i in 1:5) {
    Sys.sleep(2)
    body$sendKeysToElement(list(RSelenium::selKeys$end))
  }
  comments <- client$findElements(using = "xpath", value = "//div[@data-testid = 'tweetText']")
  comments <- map_chr(comments, function(x)x$getElementText()[[1]])
  
  text <- str_replace_all(comments,"\\n","")
  time <- lubridate::now()
  
  
  # Crea un data.frame
  df <- data.frame(
    post_id = str_extract(url, "\\d+$"),
    comment_id = sapply(comments,function(x) digest::digest(x, algo = "md5")),
    text = text
  )
  post_text <- df[1,]$text
  df$post_text <- post_text
  df <- df[-1,]
  row.names(df) <- NULL
  
  return(df)
}

#' @export
twitter_extract_comments <- possibly(extract_comments,
                             otherwise = NULL,
                             quiet = TRUE)


