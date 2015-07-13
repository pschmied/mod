library(ggplot2)
library(igraph)

dat <- read.csv("~/Projects/mod/geospatialresults.csv", header=FALSE, stringsAsFactors=FALSE)
names(dat) <- c("O", "D", "matches")

dat_thinned <- dat[dat$matches > 5,]

gr <- graph.data.frame(dat, directed=FALSE)

gr_thinned <- graph.data.frame(dat_thinned, directed=FALSE)

## Network graph of weighted edges
pdf("./edgesgraph.pdf", width=8, height=8)
plot(gr, layout=layout.fruchterman.reingold)
dev.off()

## Network graph of weighted edges - Thinned
pdf("./edgesgraph_thinned.pdf", width=8, height=8)
plot(gr_thinned, layout=layout.fruchterman.reingold)
dev.off()

## Network graph of weighted edges
pdf("./weightededgesgraph_thinned.pdf", width=8, height=8)
plot(gr_thinned, layout=layout.fruchterman.reingold,
     edge.width=log(E(gr)$matches))
dev.off()

