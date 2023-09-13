library(httr)
.config <- config::get()
api_key <- .config$open_ai_api_key
# Define la URL y los headers

get_sentiment <- function(text){
  url <- "https://api.openai.com/v1/completions"
  headers <- c(
    "Content-Type" = "application/json",
    "Authorization" = paste("Bearer", api_key)
  )
  
  # Define el cuerpo de la solicitud
  body <- list(
    model = "text-davinci-003",
    prompt = paste0('evalúa el siguiente comentario y determina si es positivo,
    negativo o neutro. Considera el contexto general del comentario y usa
    tu mejor juicio para ofrecer una respuesta concisa. solo puedes contestar algunas de 
                    estas 3 palabras (positivo, negativo o neutro) Comentario:', text,'Sentimiento:'),
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

get_sentiment("no se la verdad")

comentarios <- read_csv("database/busqueda_tags_impuestos.csv")
sentimientos <- map_chr(comentarios$text, ~get_sentiment(.x))
comentarios$sentimiento <- sentimientos
write_csv(comentarios, "database/all_comments.sentimental.csv")

