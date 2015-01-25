#'@title Plot a table of counts with colours indicating frequency
#'@rdname plotFreqHeatmap
#'@export
setGeneric("plotFreqHeatmap", function(obj, ...) {
  standardGeneric("plotFreqHeatmap")})


#'@rdname plotFreqHeatmap
#'@param obj A matrix of counts with rows = feature, columns = sample
#'@param col.sums Include a row of column totals at the top of the
#'plot (Default: TRUE)
#'@param row.sums 
#'@param group Grouping factor for columns.  If supplied, columns are
#'ordered to match the levels  (Default: NULL)
#'@param group.colours Colours for column groups, should match levels of "group".
#'If "NULL", groups are coloured differently (Default: NULL)
#'@param as.percent  Should colours represent the percentage of reads 
#'per sample (TRUE) or the actual counts (FALSE)?  (Default: TRUE)   
#'@param x.axis.title A title for the x-axis.  (Default: NULL)
#'@param x.size Font size for x-labels (Default: 16)
#'@param y.size Font size for y-labels (Default: 16)
#'@param x.angle  Angle for x-labels (Default: 90, i.e. vertical)
#'@param legend.text.size Font size for legend (Default: 16)
#'@param plot.text.size Font size counts within plot (Default: 8)
#'@param ...
setMethod("plotFreqHeatmap", signature("matrix"),  
          function(obj, ..., col.sums = TRUE, row.sums = FALSE, group = NULL,
                   group.colours = NULL, as.percent = TRUE, x.axis.title = NULL,
                   x.size = 16, y.size = 16, x.angle = 90, legend.text.size = 16,
                   plot.text.size = 8) {            
            
  if (col.sums == TRUE){
  # Make space for totals to be added
    obj <- rbind(Total = rep(NA, ncol(obj)), obj)
  }
  if (row.sums == TRUE){
    obj <- cbind(obj, Total = rep(NA, nrow(obj)))
  }
  
  if (! is.null(group)){
    if (! class(group) == "factor") group <- as.factor(group) 
    
    # If a sample group is supplied, reorder the columns of counts  
    obj <- obj[,order(group), drop = FALSE] 
   
    if (is.null(group.colours)){
      clrs <- c("#332288","#661100","#117733","#882255","#D55E00", 
                "#0072B2","#AA4499","#009E73","#56B4E9","#CC79A7",
                "#44AA99","#999933","#CC6677","#E69F00","#88CCEE")
      clrs <- clrs[group]
    } else { 
      clrs <- group.colours[group] 
    }   
  }    
  
  counts <- reshape2::melt(obj)  
  colnames(counts) <- c("Feature", "Sample","Count")
  counts$Feature <- factor(counts$Feature, levels = rev(levels(counts$Feature)))
  
  # Create coloured tile background
  if (as.percent == TRUE){
    m <- apply(obj, 2, function(x) x/sum(na.omit(x)))  
    m <- melt(m)
    colnames(m) <- c("Feature", "Sample","Percentage")  
    m$Feature <- factor(m$Feature, levels = rev(levels(m$Feature)))
    g <- ggplot(m, aes(x = Sample, y = Feature, fill = Percentage)) + geom_tile()
  }
  else{    
    g <- ggplot(counts, aes(x = Sample, y = Feature, fill = Count)) + geom_tile()
  }
  
  # Add the count numbers to the boxes,
  # if totals are included, add bold boxes to indicate these
  counts$ff <- "plain"
  box_coords <- data.frame(xmin = integer(), xmax=integer(),
                           ymin=integer(), ymax=integer())
  box_row <- 1
  xranges <- ggplot_build(g)$panel$ranges[[1]]$x.range  
  yranges <- ggplot_build(g)$panel$ranges[[1]]$y.range  
  
  # Add values for totals, plot boxes around totals
  if (row.sums == TRUE){
    totals <- rowSums(obj, na.rm = TRUE)
    row_totals <- (nrow(counts)-nrow(obj)+1):nrow(counts)
    counts$Count[row_totals] <- totals
    counts$ff[row_totals] <- "bold"
    box_coords[box_row,] <- c(max(xranges)-1, max(xranges), min(yranges), 
                              max(yranges))
    box_row <- 2
  }
  
  if (col.sums == TRUE){ 
    idxs <- which(is.na(counts$Count))
    csums <- colSums(obj, na.rm = TRUE)
    if (row.sums == TRUE) csums <- csums[1:(length(csums) -1)]
    counts$Count[idxs] <- csums
    counts$ff[idxs] <- "bold"
    box_coords[box_row,] <- c(min(xranges), max(xranges), 
                             nrow(obj) -0.5,max(yranges))  
  }
  
  if (row.sums == TRUE & col.sums == TRUE){
    tc <- sum(obj, na.rm = TRUE)
    counts[(counts$Sample=="Total" & counts$Feature == "Total"),"Count"] <- tc 
  }
  if (nrow(box_coords) > 0){
    g <- g + geom_rect(data=box_coords, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax,
                                            ymax = ymax, x = NULL, y = NULL),
                       color = "black", size = 1, fill = "transparent")   
  }
  
  # Plot the counts
  g <- g + geom_text(data = counts, aes(label = Count, fill = NULL, fontface = ff), 
                     size = plot.text.size)
  
  # Colour the boxes - white for 0, darkred for highest
  hmcols<-colorRampPalette(c("white","gold","orange","orangered","red", "darkred"))(50) 
  g <- g + scale_fill_gradientn(colours = hmcols, na.value = "white") 
  
  # Set plot labels
  g <- g + ylab(NULL) + xlab(x.axis.title) + theme_bw() +
    theme(axis.text.x = element_text(size = x.size, angle = x.angle, hjust = 1),
          axis.text.y = element_text(size = y.size),
          legend.text = element_text(size = legend.text.size),
          legend.title = element_text(size = legend.text.size),
          legend.key.height = unit(5, "lines"))         
  
  # Colour xlabels by group
  if (! is.null(group)){
    g <- g + theme(axis.text.x=element_text(colour= clrs))
  }
  
  return(g)
})


#'@rdname plotFreqHeatmap
#'@param top.n  Show the n top ranked variants.  Note that if the nth and n+1th 
#'variants have equal rank, they will not be shown.   (Default: show all)
#'@param freq.cutoff Show variants with frequency >= freq.cutoff 
#'(Default: 0, i.e. no cutoff)
setMethod("plotFreqHeatmap", signature("CrisprSet"),  
          function(obj, ..., top.n = nrow(obj$cigar_freqs), freq.cutoff = 0) {
  
  result <- obj$heatmapCigarFreqs(top_n = top.n, freq_cutoff = freq.cutoff, ...)          
  return(result)
})      