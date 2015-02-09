#' Function lists the attributes of one or more tables
#'
#' @param tbids character vector of table identifiers
#' @param db connection to a database as set up by dplyr
#' @return data.frame
#' @examples
#' foo.db <- src_postgres("foo")
#' attrs <- ls.attr(foo.db)
#' @export
ls.attr <- function(db) {
    tbids <- db_list_tables(db$con)
    getcols <- function(tbid) {
        table <- tbl(db, tbid)
        colnames(table)
    }
    Map(getcols, tbids)
}

#' Converts a string to tokens
#'
#' @param x a string
#' @param split optional, regex to split on
#' @export
tokify <- function(x, split=NULL) {
    if(is.null(split)) split="[.]"
    ts <- tolower(unlist(strsplit(x, split)))
    ts[ts != "X" & ts != ""]
}

#' Intersect based on grep. Much slower / more inefficient than
#' base::intersect
#'
#' @param xs a vector of strings to compare
#' @param ys a vector of strings to compare
#' @return a vector containing the intersection of xs and ys where
#' matching elements are sorted and concatenated to form an identifier
#' @export
intersect.grep <- function(xs, ys, ...) {
    com <- expand.grid(xs, ys, stringsAsFactors=FALSE)
    fn <- function(x, y) {
        if(grepl(x, y, ignore.case=TRUE, ...)) {
            paste(sort(c(x, y)), collapse="~")
        }
    }
    as.vector(unlist(mapply(fn, com[,1], com[,2])))
}

#' Intersect based on agrep. Much slower / more inefficient than
#' base::intersect. Typically called by edge.attrs()
#'
#' @inheritParams intersect.agrep
#' @return a vector containing the intersection of xs and ys where
#' matching elements are sorted and concatenated to form an identifier
#' @export
intersect.agrep <- function(xs, ys, ...) {
    com <- expand.grid(xs, ys, stringsAsFactors=FALSE)
    fn <- function(x, y) {
        if(agrepl(x, y, ignore.case=TRUE, ...)) {
            paste(sort(c(x, y)), collapse="~")
        }
    }
    as.vector(unlist(mapply(fn, com[,1], com[,2])))
}

#' Intersect based on tokenized versions of names
#'
#' @inheritParams intersect.grep
#' @return a vector containing the intersection of xs and ys where
#' matching elements are sorted and concatenated to form an identifier
#' @export
intersect.token <- function(xs, ys, ...) {
    com <- expand.grid(xs, ys, stringsAsFactors=FALSE)
    fn <- function(x, y) {
        xtok <- tokify(x, ...)
        ytok <- tokify(y, ...)
        if(length(intersect(xtok, ytok)) > 0) {
            paste(sort(c(x, y)), collapse="~")
        }
    }
    as.vector(unlist(mapply(fn, com[,1], com[,2])))
}

#' Intersect based on innerjoin of table crossproducts (VERY SLOW)
#'
#' @inheritParams intersect.grep
#' @param xtab name of the table containing xs
#' @param ytab name of the table containing ys
#' @param db database connection as set up by dplyr
#' @param threshold optional, number of matching rows to constitute a
#' column match
#' @export
intersect.innerjoin <- function(xs, ys, xtab, ytab, db, threshold=1, ...) {
    com <- expand.grid(xs, ys, stringsAsFactors=FALSE)
    xt <- tbl(db, xtab)               # Convert table names to handles
    yt <- tbl(db, ytab)
    print(paste("joining", xtab, "and", ytab))
    fn <- function(x, y) {
        j <- try(inner_join(xt, yt, setNames(x, y)), silent=TRUE)
        if(class(j)[1] != "try-error") {
            nset <- collect(summarize(j, n()))[[1,1]]
            if(nset > threshold) paste(sort(c(x,y)), collapse="~")
        }
    }
    as.vector(unlist(mapply(fn, com[,1], com[,2])))
}

#' Identifies edges between table attributes based on arbitrary
#' function
#'
#' @param attrs a list containing table attributes, as returned by
#' ls.attr
#' @param fn function used to compare attribute names, returning
#' logical intersection
#' @param tabs does the fn require table names to be passed
#' (e.g. function works against a sql store)?
#' @return dataframe representing an edgelist
#' @examples
#' foo.db <- src_postgres("foo")
#' attrs <- ls.attr(foo.db)
#'
#' res.grep <- edge.attrs(attrs, fn=intersect.grep)
#' res.token <- edge.attrs(attrs, fn=intersect.token)
#' res.innerjoin <- edge.attrs(attrs, fn=intersect.innerjoin, tabs=TRUE, db=foo.db)
#'
#' library(igraph)
#' graph.grep <- graph.data.frame(res.grep, directed=FALSE)
#' write.graph(graph.grep, "~/Desktop/graph.grep.dot", format="dot")
#' plot(graph) # might take a while!
#'
#' res.grep.n <- res.grep %>%
#'                  group_by(xn, yn) %>%
#'                  summarize(count=n())
#' graph.grep.n <- graph.data.frame(res.grep.n, directed=FALSE)
#' @export
edge.attrs <- function(attrs, fn=intersect, tabs=FALSE, ...) {
    com <- combn(names(attrs), 2)
    compfn <- function(xn, yn) {
        if(tabs) {
            hit <- fn(attrs[[xn]], attrs[[yn]], xn, yn, ...)
        } else {
            hit <- fn(attrs[[xn]], attrs[[yn]], ...)
        }
        if(length(hit) > 0) data.frame(xn, yn, hit, row.names=NULL)
    }
    res <- do.call(rbind, Map(compfn, com[1,], com[2,]))
    row.names(res) <- NULL
    res
}

