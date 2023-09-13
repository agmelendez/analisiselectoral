box::use(
  duckdb[duckdb],
  DBI[dbConnect, dbWriteTable],
  withr[local_db_connection],
  cli[cli_alert_success]
)


#' @export
write_comments <- function(comments, db_path = "database/comments.duckdb"){
  con <- local_db_connection(
    con = dbConnect(
      drv = duckdb(),
      dbdir = db_path,
      read_only = FALSE)
    )
  
  out <- dbWriteTable(con, "comments", value = comments, append = TRUE)
  if(out) cli_alert_success("tabla escrita con éxito")
}