% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/writeFastq.R
\name{writeFastq}
\alias{writeFastq}
\title{Append a sequence to a fastq file}
\usage{
writeFastq(outf, vals, allow_spaces = FALSE, check = TRUE)
}
\arguments{
\item{outf}{Name of fastq file to append sequence}

\item{vals}{A list containing entries named "seq" (sequence) and
"quals" (quality scores, in ASCII format)}

\item{allow_spaces}{Should spaces in the sequence name be
substituted with underscores?  TRUE or FALSE}

\item{check}{Check whether reads with the same name already
exist in the output fastq.  (Default: TRUE)}
}
\value{
None.  The sequences in "vals" are written to outf
}
\description{
Used by abifToFastq to write sanger sequences
to fastq format  As abifToFastq appends output to files,
writeFastq checks that sequence names are unique.  This
function is faster with checking switched off.
}
\author{
Helen Lindsay
}

