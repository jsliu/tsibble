% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/gaps.R
\name{has_gaps}
\alias{has_gaps}
\alias{has_gaps.tbl_ts}
\title{Does a tsibble have implict gaps in time?}
\usage{
has_gaps(.data, ...)

\method{has_gaps}{tbl_ts}(.data, .full = FALSE, ...)
}
\arguments{
\item{.data}{A \code{tbl_ts}.}

\item{...}{Other arguments passed on to individual methods.}

\item{.full}{\code{FALSE} to find gaps for each group within its own period. \code{TRUE}
to find gaps over the entire time span of the data.}
}
\description{
Returns a vector of \code{TRUE}/\code{FALSE} corresponding to each key.
}
\examples{
harvest <- tsibble(
  year = c(2010, 2011, 2013, 2011, 2012, 2013),
  fruit = rep(c("kiwi", "cherry"), each = 3),
  kilo = sample(1:10, size = 6),
  key = id(fruit), index = year
)
has_gaps(harvest)
has_gaps(harvest, .full = TRUE)
}
