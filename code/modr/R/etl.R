library(plyr)
library(RSocrata)
library(RPostgreSQL)
library(dplyr)
library(httr)
library(magrittr)

#' Construct a socrata url from a site root and an identifier
#'
#' @param site root of socrata site (e.g. "https://data.seattle.gov")
#' @param identifier
mk.socrata.url <- function(site, identifier) {
    url <- parse_url(site)
    url$path <- paste0("resource/", identifier, ".csv")
    as.character(build_url(url))
}


#' Import data from remote socrata server to local sqlite
#' database. Note, this isn't the most memory efficient approach to
#' populating a db. Big datasets may choke this. But, on the other
#' hand it should be able to infer column datatypes.
#'
#' @param site root of socrata site (e.g. "https://data.seattle.gov")
#' @param db a database connection as initialized by src_dbi from
#' dplyr
#' @return list of table handles, side effect is a database written to
#' disk
#' @examples
#' foo.db <- src_postgres("foo")
#' socrata2db(foo.db)
#' @export
socrata2db <- function(db, site="https://data.seattle.gov", app_token=NULL) {
    ds <- ls.socrata(site)[-1,]         # Note, 1st row is bogus
    ds <- ds[,sapply(ds, class) != "list"] # 1d columns only
    existing.tb <- db_list_tables(db$con)
    if(!("datasets" %in% existing.tb)) {
       copy_to(db, ds, name="datasets", temporary=FALSE)
    }
    identifiers <- ds$identifier
    identifiers <- setdiff(identifiers, existing.tb)
    rwfn <- function(identifier) {
        url <- mk.socrata.url(site, identifier)
        print(paste("Reading:", url))
        result <- read.socrata(url, app_token=app_token)
        if(nrow(result) == 0) {
            print(paste(identifier, "yielded zero rows of results"))
        } else {
        print(paste("Writing", identifier))
        copy_to(db, result, name=identifier, temporary=FALSE)
        }
    }
    Map(rwfn, identifiers)
}

#' An alternative database loading mechanism that relies on having a
#' directory full of csv files.
#'
#' @param db a database connection as initialized by src_dbi from
#' dplyr
#' @param path a path to a bunch of csv files that should be loaded
#' into a db
#' @return list of table handles, side effect is a database written to disk
#' @examples
#' foo.db <- src_postgres("foo")
#' csv2db(foo.db, "~/path/to/csvs")
#' @export
csv2db <- function(db, path) {
    src <- gsub("\\.csv", "", list.files(path, pattern="*.csv"))
    existing.tb <- db_list_tables(db$con)
    src <- setdiff(src, existing.tb) # Only load those that don't already exist
    rwfn <- function(srcfile) {
        result <- read.csv(paste0(path, "/", srcfile, ".csv"), header=TRUE)
        srcfilename <- gsub("\\.csv", "", srcfile)
        if(nrow(result) == 0) {
            print(paste(srcfile, "has zero rows"))
        } else {
        print(paste("Writing", srcfilename))
        copy_to(db, result, name=srcfilename, temporary=FALSE)
        }
    }
    Map(rwfn, src)
}
