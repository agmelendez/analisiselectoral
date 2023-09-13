
# dependencias ------------------------------------------------------------
library(tidyverse)
box::use(R/selenium_server)
box::use(R/facebook_extractor)
box::use(R/twitter_extractor)
source("R/instagram_extractor.R")
.config <- config::get()


# configuracion selenium --------------------------------------------------

server <- selenium_server$start_selenium()
client <- server$client
client$setTimeout(type = "load", milliseconds = 5000)
client$setTimeout(type = "implicit", milliseconds = 5000)



# extraer datos facebook --------------------------------------------------

facebook_extractor$facebook_login(
  client = client,
  user = .config$facebook_user,
  pass = .config$facebook_pass
)

pages <- c("https://m.facebook.com/profile.php?id=100064249467077")

df_fb <- map_dfr(pages,~{
  posts <- facebook_extractor$extract_posts(
    client = client,
    page = .x,
    second = 1)
  comments <- facebook_extractor$facebook_extract_comments(client, posts)
  return(comments)
})

df_fb$page <- "facebook"

df_fb <- df_fb %>% 
  select(
    page, 
    page_id,
    post_id, 
    post_text,
    comment_id = id_comentario,
    text
  )


# extract twitter ---------------------------------------------------------

twitter_extractor$twitter_login(
  client = client,
  username = .config$twitter_user,
  password = .config$twitter_pass
)

pages <- c("Rodrigo Chavez")

df_twitter <- map_dfr(pages, ~{
  twitter_extractor$find_terms(client, .x)
  posts <- twitter_extractor$extract_posts(client, 2)

  x <- map_dfr(posts, ~twitter_extractor$twitter_extract_comments(client,.x))
  return(x)
})

df_twitter <- df_twitter %>%
  mutate(
    page_id = NA,
  page = "twitter"
) %>%
  select(
    page, post_text, page_id, post_id, comment_id, text
  )



# extract instagram -------------------------------------------------------
instagram_login(.config$instagram_user, .config$instagram_pass)
pages <- c("https://www.instagram.com/crhoy/")

df_instagram <- map_dfr(pages, ~{
  df <- instagram_extract_comments(.x)
  df$page_id <- digest::digest(.x, algo = "md5")
  return(df)
})

df_instagram <- df_instagram %>% 
  mutate(
    comment_id = map_chr(comments,~digest::digest(.x, algo = "md5")),
    page = "instagram"
    ) %>% 
  select(
    page, post_text, page_id, post_id, comment_id, text = comments
  )



df_all <- rbind(df_fb, df_twitter, df_instagram)
write_rds(df_all, paste0("database/all_comments",Sys.time(),".rds"))

server$server$stop()