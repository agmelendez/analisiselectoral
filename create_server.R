library(RSelenium)
library(netstat)
library(wdman)

create_server <- function(headless = FALSE){
  out <- list()
  
  if(headless){
    remove_driver <- rsDriver(
      browser = "firefox",
      chromever = NULL,
      verbose = TRUE,
      extraCapabilities = list(
        "moz:firefoxOptions" = list(
          args = list('--headless')
        )
      ),
      port = free_port()
    )
  }else {
    remove_driver <- rsDriver(
      browser = "firefox",
      chromever = NULL,
      verbose = TRUE,
      port = free_port()
    )
  }
  
  
  client <- remove_driver$client
  client$setTimeout(type = "load", milliseconds = 5000)
  client$setTimeout(type = "implicit", milliseconds = 5000)
  
  out$server <- remove_driver
  out$client <- client
  
  return(out)
  
}

