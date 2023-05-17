
twitter_login <- function(x){
  .config <- config::get()
  x$navigate("https://twitter.com/i/flow/login")
  Sys.sleep(3)
  input_username <- x$findElement(
    using = "xpath",
    value = "//input[@autocomplete = 'username']"
  )
  
  input_username$sendKeysToElement(list(.config$twitter_user,selKeys$enter))
  
  Sys.sleep(3)
  
  input_pass <- x$findElement(
    using = "xpath",
    value = "//input[@name = 'password']"
  )
  input_pass$sendKeysToElement(list(.config$twitter_password,selKeys$enter))
  
  return(x)
}

load_posts <- function(client, n = 10){
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

find_term <- function(client, text){
  text <- URLencode(text)
  url <- paste0("https://twitter.com/search?q=",text,"&src=typed_query")
  client$navigate(url)
  Sys.sleep(5)
}

get_reactions <- function() {
  x <- client$findElement(using = "xpath", value = "//div[@class = 'css-1dbjc4n r-18u37iz r-1w6e6rj']")
  x$getElementText()
}
get_reactions <- possibly(get_reactions,quiet = TRUE,otherwise = "")
post_commets <- function(client, url){
  client$navigate(url)
  
  body <- client$findElement(
    using = "xpath",
    value = "//body"
  )
  for (i in 1:5) {
    Sys.sleep(2)
    body$sendKeysToElement(list(selKeys$end))
  }
  
  comments <- client$findElements(using = "xpath", value = "//div[@data-testid = 'tweetText']")
  comments <- map_chr(comments, function(x)x$getElementText()[[1]])
  
  reactions <- get_reactions()
  text <- str_replace_all(reactions,"\\n","")
  
  retweets <- as.numeric(str_extract(text, "\\d+(?= Retweets)"))
  quotes <- as.numeric(str_extract(text, "\\d+(?= Quotes)"))
  likes <- as.numeric(str_extract(text, "\\d+(?= Likes)"))
  bookmarks <- as.numeric(str_extract(text, "\\d+(?= Bookmark)"))
  
  time <- client$findElement(using = "xpath", value = "//time")
  time <- time$getElementText()[[1]]
  
  # Lee la fecha y la hora con lubridate
  time <- parse_date_time(time, "%I:%M %p · %b %d, %Y")
  
  
  # Crea un data.frame
  df <- data.frame(
    tweet_datetime = time, 
    post_id = str_extract(url, "\\d+$"),
    Retweets = retweets,
    Quotes = quotes,
    Likes = likes,
    Bookmark = bookmarks,
    comments = comments
  )
  
  return(df)
}





