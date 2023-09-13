
username <- "aguero2707@icloud.com"
pass <- "rizwok-2Wodki-posmaw"

client$navigate("https://www.tiktok.com/es/")

btn_login <- client$findElement(
  using = "css",
  value = "#header-login-button"
)

btn_login$clickElement()

btn_email <- client$findElement(
  using = "xpath",
  value = "//div[@id = 'loginContainer']/div/div/a[2]/div"
) 
btn_email$clickElement()
btn_email <- client$findElement(
  using = "xpath",
  value = "//form//a"
  
)

btn_email$clickElement()


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

### problemas con el login, se pide confirmar completando imagenes




### Extraer comentarios tiktok

i <- 10
df <- map_dfr(
  seq_len(i),
  function(i) {
    Sys.sleep(5)
    btn_siguiente <- client$findElement(
      using = "xpath",
      value = ".//button[@data-e2e = 'arrow-right']"
    )
    btn_siguiente$clickElement()
    
    Sys.sleep(3)
    comentarios <- client$findElements("xpath", ".//p[@data-e2e= 'comment-level-1']")
    comentarios <- map_chr(comentarios,function(x)x$getElementText()[[1]])
    post <- client$getCurrentUrl()[[1]]
    
    df <- tibble(
      post_id = post,
      comentarios = comentarios
    )
  }
)

