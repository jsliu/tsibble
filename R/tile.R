#' Tiling window calculation
#'
#' Tiling window without overlapping observations:
#' * `tile()` always returns a list.
#' * `tile_lgl()`, `tile_int()`, `tile_dbl()`, `tile_chr()` use the same
#' arguments as `tile()`, but return vectors of the corresponding type.
#' * `tile_dfr()` `tile_dfc()` return data frames using row-binding & column-binding.
#'
#' @inheritParams slide
#'
#' @rdname tile
#' @export
#' @seealso
#' * [tile2], [ptile]
#' * [slide] for sliding window with overlapping observations
#' * [stretch] for expanding more observations
#'
#' @examples
#' x <- 1:5
#' lst <- list(x = x, y = 6:10, z = 11:15)
#' tile_dbl(x, mean, .size = 2)
#' tile_lgl(x, ~ mean(.) > 2, .size = 2)
#' tile(lst, ~ ., .size = 2)
tile <- function(.x, .f, ..., .size = 1, .bind = FALSE) {
  lst_x <- tiler(.x, .size = .size, .bind = .bind)
  map(lst_x, .f, ...)
}

#' @evalRd paste0('\\alias{tile_', c("lgl", "chr", "dbl", "int"), '}')
#' @name tile
#' @rdname tile
#' @exportPattern ^tile_
for(type in c("lgl", "chr", "dbl", "int")){
  assign(
    paste0("tile_", type),
    replace_fn_names(tile, list(map = rlang::sym(paste0("map_", type))))
  )
}

#' @rdname tile
#' @export
tile_dfr <- function(.x, .f, ..., .size = 1, .bind = FALSE, .id = NULL) {
  out <- tile(.x = .x, .f = .f, ..., .size = .size, .bind = .bind)
  dplyr::bind_rows(!!! out, .id = .id)
}

#' @rdname tile
#' @export
tile_dfc <- function(.x, .f, ..., .size = 1, .bind = FALSE) {
  out <- tile(.x = .x, .f = .f, ..., .size = .size, .bind = .bind)
  dplyr::bind_cols(!!! out)
}

#' Tiling window calculation over multiple inputs simultaneously
#'
#' Tiling window without overlapping observations:
#' * `tile2()` and `ptile()` always returns a list.
#' * `tile2_lgl()`, `tile2_int()`, `tile2_dbl()`, `tile2_chr()` use the same
#' arguments as `tile2()`, but return vectors of the corresponding type.
#' * `tile2_dfr()` `tile2_dfc()` return data frames using row-binding & column-binding.
#'
#' @inheritParams slide2
#' @rdname tile2
#' @export
#' @seealso
#' * [tile]
#' * [slide2] for sliding window with overlapping observations
#' * [stretch2] for expanding more observations
#' @examples
#' x <- 1:5
#' y <- 6:10
#' z <- 11:15
#' lst <- list(x = x, y = y, z = z)
#' df <- as.data.frame(lst)
#' tile2(x, y, sum, .size = 2)
#' tile2(lst, lst, ~ ., .size = 2)
#' tile2(df, df, ~ ., .size = 2)
#' ptile(lst, sum, .size = 1)
#' ptile(list(lst, lst), ~ ., .size = 2)
tile2 <- function(.x, .y, .f, ..., .size = 1, .bind = FALSE) {
  lst <- ptiler(.x, .y, .size = .size, .bind = .bind)
  map2(lst[[1]], lst[[2]], .f, ...)
}

#' @evalRd paste0('\\alias{tile2_', c("lgl", "chr", "dbl", "int"), '}', collapse = '\n')
#' @name tile2
#' @rdname tile2
#' @exportPattern ^tile2_
for(type in c("lgl", "chr", "dbl", "int")){
  assign(
    paste0("tile2_", type),
    replace_fn_names(tile2, list(map2 = rlang::sym(paste0("map2_", type))))
  )
}

#' @rdname tile2
#' @export
tile2_dfr <- function(.x, .y, .f, ..., .size = 1, .bind = FALSE, .id = NULL) {
  out <- tile2(.x, .y, .f = .f, ..., .size = .size, .bind = .bind)
  dplyr::bind_rows(!!! out, .id = .id)
}

#' @rdname tile2
#' @export
tile2_dfc <- function(.x, .y, .f, ..., .size = 1, .bind = FALSE) {
  out <- tile2(.x, .y, .f = .f, ..., .size = .size, .bind = .bind)
  dplyr::bind_cols(!!! out)
}

#' @rdname tile2
#' @export
ptile <- function(.l, .f, ..., .size = 1, .bind = FALSE) {
  lst <- ptiler(!!! .l, .size = .size, .bind = .bind)
  pmap(lst, .f, ...)
}

#' @evalRd paste0('\\alias{ptile_', c("lgl", "chr", "dbl", "int"), '}')
#' @name ptile
#' @rdname tile2
#' @exportPattern ^ptile_
for(type in c("lgl", "chr", "dbl", "int")){
  assign(
    paste0("ptile_", type),
    replace_fn_names(ptile, list(pmap = rlang::sym(paste0("pmap_", type))))
  )
}

#' @rdname tile2
#' @export
ptile_dfr <- function(.l, .f, ..., .size = 1, .bind = FALSE, .id = NULL) {
  out <- ptile(.l, .f, ..., .size = .size, .bind = .bind)
  dplyr::bind_rows(!!! out, .id = .id)
}

#' @rdname tile2
#' @export
ptile_dfc <- function(.l, .f, ..., .size = 1, .bind = FALSE) {
  out <- ptile(.l, .f, ..., .size = .size, .bind = .bind)
  dplyr::bind_cols(!!! out)
}

#' Splits the input to a list according to the tiling window size.
#'
#' @inheritParams slider
#' @rdname tiler
#' @export
#' @examples
#' x <- 1:5
#' y <- 6:10
#' z <- 11:15
#' lst <- list(x = x, y = y, z = z)
#' df <- as.data.frame(lst)
#' 
#' tiler(x, .size = 2)
#' tiler(lst, .size = 2)
#' ptiler(lst, .size = 2)
#' ptiler(list(x, y), list(y))
#' ptiler(df, .size = 2)
#' ptiler(df, df, .size = 2)
tiler <- function(.x, .size = 1, .bind = FALSE) {
  bad_window_function(.size)
  abort_not_lst(.x, .bind = .bind)
  len_x <- NROW(.x)
  seq_x <- seq_len(len_x)
  denom <- len_x + 1
  frac <- ceiling((seq_x %% denom) / .size)
  out <- unname(split(.x, frac, drop = TRUE))
  if (.bind) bind_lst(out) else out
}

#' @rdname tiler
#' @export
ptiler <- function(..., .size = 1, .bind = FALSE) { # parallel tiling
  lst <- recycle(list2(...))
  map(lst, function(x) tiler(x, .size = .size, .bind = .bind))
}
