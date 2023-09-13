library(httr)
.config <- config::get()
api_key <- .config$open_ai_api_key
# Define la URL y los headers

get_tags <- function(text){
  url <- "https://api.openai.com/v1/completions"
  headers <- c(
    "Content-Type" = "application/json",
    "Authorization" = paste("Bearer", api_key)
  )
  
  # Define el cuerpo de la solicitud
  body <- list(
    model = "text-davinci-003",
    prompt = paste0('a partir del contenido del texto crea una serie de tags que permitan 
                    clasificar los temas del texto, estas separadas por coma, retorna
                    solamente los tags por ejemplo, (politica, impustos, enojo, educación)', text,'tags:'),
    temperature = 1,
    max_tokens = 256,
    top_p = 1,
    frequency_penalty = 0,
    presence_penalty = 0
  )
  
  # Hacer la solicitud
  response <- POST(url, add_headers(.headers=headers), body=body, encode="json")
  
  # Imprimir la respuesta
  x <- content(response)
  x <- x$choices[[1]]$text
  return(x)
}

get_tags("se roban los impuestos y nada va a dar a las escuelas")

comentarios <- read_rds("database/all_comments2023-09-10 10:13:41.rds")
sentimientos <- map_chr(comentarios$post_text, ~get_tags(.x))
comentarios$tags <- sentimientos
write_rds(comentarios, "database/all_comments2023-09-10 10:13:41.rds")

