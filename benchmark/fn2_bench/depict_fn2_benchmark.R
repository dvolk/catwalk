# analyse python performance
rm(list = ls())

library(ggplot2)

timing_file <- file.path('benchmark','fn2_bench','results','fn2_bench.1000.fasta.perfprofile_20.csv')
memuse_file <- file.path('benchmark','fn2_bench','results','fn2_bench.1000.fasta.memprofile_20.csv')
outputdir <- file.path('benchmark','fn2_bench','results')
timings <- read.csv(timing_file)
memuse <- read.csv(memuse_file)

## compute memory usage per sample
# is memory use linear by sample added (yes)
min_memory_usage <- min(memuse$rss_memory)
memuse$change_in_rss_memory <- (memuse$rss_memory - min_memory_usage) / 1024000
p <- ggplot(memuse, aes(x= n_loaded, y= change_in_rss_memory))
p <- p + geom_point()
p <- p + scale_y_continuous(name = 'Memory use (Mb)')
p <- p + scale_x_continuous(name = 'Number of samples added')
p <- p + ggtitle("Python implementation")
p <- p + geom_smooth(method = 'lm')
memory_use <- max(memuse$change_in_rss_memory) / 1000  # Mb per sample
p1 <- p + geom_text(x=100, y= 1000, label = paste("Use per sample ",round(memory_use, digits = 2),"Mb"))
ggsave(p1, filename = file.path(outputdir, 'memuse.svg'))
p1


# compute load time
load_time_1000 <- (difftime(as.POSIXct(memuse$timenow[1000]), as.POSIXct(memuse$timenow[1]), units= 'secs'))/1000
load_time_1000

# compute stats for query timings
summary(timings$delta_seconds)