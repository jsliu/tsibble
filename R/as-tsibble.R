#' Create a tsibble object
#'
#' @param ... A set of name-value pairs. The names of "key" and "index" should
#' be avoided as they are used as the arguments.
#' @param key Structural variable(s) that define unique time indices, used with
#' the helper [id]. If a univariate time series (without an explicit key),
#' simply call `id()`. See below for details.
#' @param index A bare (or unquoted) variable to specify the time index variable.
#' @param regular Regular time interval (`TRUE`) or irregular (`FALSE`). The
#' interval is determined by the greatest common divisor of positive time distances,
#' if `TRUE`.
#'
#' @inheritSection tsibble-package Index
#'
#' @inheritSection tsibble-package Key
#'
#' @inheritSection tsibble-package Interval
#'
#' @details A tsibble is sorted by its key first and index.
#'
#' @return A tsibble object.
#' @seealso [build_tsibble]
#'
#' @examples
#' # create a tsibble w/o a key ----
#' tsibble(
#'   date = as.Date("2017-01-01") + 0:9,
#'   value = rnorm(10)
#' )
#'
#' # create a tsibble with one key ----
#' tsibble(
#'   qtr = rep(yearquarter("201001") + 0:9, 3),
#'   group = rep(c("x", "y", "z"), each = 10),
#'   value = rnorm(30),
#'   key = id(group)
#' )
#'
#' @export
tsibble <- function(..., key = id(), index, regular = TRUE) {
  dots <- list2(...)
  if (has_length(dots, 1) && is.data.frame(dots[[1]])) {
    abort("Must not be a data frame, do you want `as_tsibble()`?")
  }
  tbl <- tibble(!!! dots)
  index <- enquo(index)
  build_tsibble(tbl, key = !! enquo(key), index = !! index, regular = regular)
}

#' Coerce to a tsibble object
#'
#' @param x Other objects to be coerced to a tsibble (`tbl_ts`).
#' @inheritParams tsibble
#' @param validate `TRUE` suggests to verify that each key or each combination
#' of key variables lead to unique time indices (i.e. a valid tsibble). If you 
#' are sure that it's a valid input, specify `FALSE` to skip the checks.
#' @param ... Other arguments passed on to individual methods.
#'
#' @return A tsibble object.
#' @rdname as-tsibble
#' @seealso [tsibble]
#'
#' @examples
#' # coerce tibble to tsibble w/o a key ----
#' tbl1 <- tibble(
#'   date = as.Date("2017-01-01") + 0:9,
#'   value = rnorm(10)
#' )
#' as_tsibble(tbl1)
#' # specify the index var
#' as_tsibble(tbl1, index = date)
#'
#' # coerce tibble to tsibble with one key ----
#' # "date" is automatically considered as the index var, and "group" is the key
#' tbl2 <- tibble(
#'   mth = rep(yearmonth("201701") + 0:9, 3),
#'   group = rep(c("x", "y", "z"), each = 10),
#'   value = rnorm(30)
#' )
#' as_tsibble(tbl2, key = id(group))
#' as_tsibble(tbl2, key = id(group), index = mth)
#'
#' @export
as_tsibble <- function(x, ...) {
  UseMethod("as_tsibble")
}

#' @rdname as-tsibble
#' @export
as_tsibble.tbl_df <- function(
  x, key = id(), index, regular = TRUE, validate = TRUE, ...
) {
  index <- enquo(index)
  build_tsibble(
    x, key = !! enquo(key), index = !! index, regular = regular,
    validate = validate
  )
}

#' @rdname as-tsibble
#' @export
as_tsibble.tbl_ts <- function(x, validate = FALSE, ...) {
  if (validate) return(NextMethod())
  x
}

#' @rdname as-tsibble
#' @export
as_tsibble.data.frame <- as_tsibble.tbl_df

#' @keywords internal
#' @export
as_tsibble.tbl <- as_tsibble.tbl_df

#' @rdname as-tsibble
#' @export
as_tsibble.list <- as_tsibble.tbl_df

#' @keywords internal
#' @export
as_tsibble.grouped_df <- function(
  x, key = id(), index, regular = TRUE, validate = TRUE, ...
) {
  index <- enquo(index)
  build_tsibble(
    x, key = !! enquo(key), index = !! index,
    regular = regular, validate = validate
  )
}

#' @keywords internal
#' @export
as_tsibble.grouped_ts <- as_tsibble.tbl_ts

#' @keywords internal
#' @export
as_tsibble.default <- function(x, ...) {
  dont_know(x, "as_tsibble")
}

#' @keywords internal
#' @export
as_tsibble.NULL <- function(x, ...) {
  abort("A tsibble must not be NULL.")
}

#' @export
groups.tbl_ts <- function(x) {
  NULL
}

#' @export
groups.grouped_ts <- function(x) {
  res <- as_grouped_df(x)
  groups(res)
}

#' @export
group_vars.tbl_ts <- function(x) {
  character(0L)
}

#' @export
group_vars.grouped_ts <- function(x) {
  res <- as_grouped_df(x)
  group_vars(res)
}

#' @export
group_size.grouped_ts <- function(x) {
  res <- as_grouped_df(x)
  group_size(res)
}

#' @export
n_groups.tbl_ts <- function(x) {
  res <- as_grouped_df(x)
  n_groups(res)
}

#' @export
group_indices.grouped_ts <- function(.data, ...) {
  res <- as_grouped_df(.data)
  group_indices(res)
}

#' Return measured variables
#'
#' @param x A `tbl_ts`.
#'
#' @rdname measured-vars
#' @examples
#' measured_vars(pedestrian)
#' measured_vars(tourism)
#' @export
measured_vars <- function(x) {
  UseMethod("measured_vars")
}

#' @export
measured_vars.tbl_ts <- function(x) {
  all_vars <- dplyr::tbl_vars(x)
  key_vars <- key_vars(x)
  idx_var <- as_string(index(x))
  setdiff(all_vars, c(key_vars, idx_var))
}

#' Return index and interval from a tsibble
#'
#' @param x A tsibble object.
#' @rdname index-rd
#' @examples
#' data(pedestrian)
#' index(pedestrian)
#' interval(pedestrian)
#' @export
interval <- function(x) {
  not_tsibble(x)
  attr(x, "interval")
}

#' @rdname index-rd
#' @export
index <- function(x) {
  not_tsibble(x)
  attr(x, "index")
}

#' @rdname index-rd
#' @export
index2 <- function(x) {
  not_tsibble(x)
  attr(x, "index2")
}

#' `is_regular` checks if a tsibble is spaced at regular time or not; `is_ordered`
#' checks if a tsibble is ordered by key and index.
#'
#' @param x A tsibble object.
#' @rdname regular
#' @examples
#' data(pedestrian)
#' is_regular(pedestrian)
#' is_ordered(pedestrian)
#' @export
is_regular <- function(x) {
  not_tsibble(x)
  attr(x, "regular")
}

#' @rdname regular
#' @export
is_ordered <- function(x) {
  not_tsibble(x)
  attr(x, "ordered")
}

#' If the object is a tsibble
#'
#' @param x An object.
#'
#' @return TRUE if the object inherits from the tbl_ts class.
#' @rdname is-tsibble
#' @aliases is.tsibble
#' @examples
#' # A tibble is not a tsibble ----
#' tbl <- tibble(
#'   date = seq(as.Date("2017-10-01"), as.Date("2017-10-31"), by = 1),
#'   value = rnorm(31)
#' )
#' is_tsibble(tbl)
#'
#' # A tsibble ----
#' tsbl <- as_tsibble(tbl, index = date)
#' is_tsibble(tsbl)
#' @export
is_tsibble <- function(x) {
  inherits(x, "tbl_ts")
}

#' @rdname is-tsibble
#' @usage NULL
#' @export
is.tsibble <- is_tsibble

#' @rdname is-tsibble
#' @export
is_grouped_ts <- function(x) {
  inherits(x, "grouped_ts")
}

#' @rdname is-tsibble
#' @usage NULL
#' @export
is.grouped_ts <- is_grouped_ts

## tsibble is a special class of tibble that handles temporal data. It
## requires a sequence of time index to be unique across every identifier.

#' Low-level constructor to a tsibble object
#'
#' * `build_tsibble()` creates a `tbl_ts` object with more controls. It is useful
#' for creating a `tbl_ts` internally inside a function, and it allows users to
#' determine if the time needs ordering and the interval needs calculating.
#' * `build_tsibble_meta()` assigns the attributes to an object, assuming this
#' object is a valid tsibble.
#'
#' @param x A `data.frame`, `tbl_df`, `tbl_ts`, or other tabular objects.
#' @inheritParams as_tsibble
#' @param index2 A candidate of `index` to update the index to a new one when
#' [index_by]. By default, it's identical to `index`.
#' @param ordered The default of `NULL` arranges the key variable(s) first and
#' then index from past to future. `TRUE` suggests to skip the ordering as `x` in
#' the correct order. `FALSE` also skips the ordering but gives a warning instead.
#' @param interval `NULL` computes the interval. Use the specified interval via
#' [new_interval()] as is, if an class of `interval` is supplied.
#'
#' @rdname build_tsibble
#' @export
#' @examples
#' # Prepare `pedestrian` to use a new index `Date` ----
#' pedestrian %>%
#'   build_tsibble(
#'     key = key(.), index = !! index(.), index2 = Date, interval = interval(.)
#'   )
build_tsibble <- function(
  x, key, index, index2, regular = TRUE, ordered = NULL, interval = NULL,
  validate = TRUE
) {
  # if key is quosures
  key <- use_id(x, !! enquo(key))

  tbl <- as_tibble(x)
  # extract or pass the index var
  qindex <- enquo(index)
  index <- validate_index(tbl, qindex)
  # if index2 not specified
  index2 <- enquo(index2)
  if (quo_is_missing(index2)) {
    index2 <- index
  } else if (identical(qindex, index2)) {
    index2 <- get_expr(index2)
  } else {
    index2 <- validate_index(tbl, index2)
  }
  # (1) validate and process key vars (from expr to a list of syms)
  key_vars <- validate_key(tbl, key)
  # (2) index cannot be part of the keys
  idx_chr <- c(as_string(index), as_string(index2))
  is_index_in_keys <- intersect(idx_chr, key_vars)
  if (is_false(is_empty(is_index_in_keys))) {
    abort(sprintf("Column `%s` can't be both index and key.", idx_chr[[1]]))
  }
  # validate tbl_ts
  if (validate) {
    tbl <- validate_tsibble(data = tbl, key = key_vars, index = index)
  }
  build_tsibble_meta(
    tbl, key = key_vars, index = !! index, index2 = !! index2,
    regular = regular, ordered = ordered, interval = interval
  )
}

#' @rdname build_tsibble
#' @export
build_tsibble_meta <- function(
  x, key, index, index2, regular = TRUE, ordered = NULL, interval = NULL
) {
  if (is_null(regular)) abort("Argument `regular` must not be `NULL`.")

  key <- eval_tidy(enquo(key))
  index <- get_expr(enquo(index))
  index2 <- enquo(index2)
  if (quo_is_missing(index2)) {
    index2 <- index
  } else {
    index2 <- get_expr(index2)
  }
  tbl <- as_tibble(x)

  if (NROW(x) == 0) {
    if (is_false(regular)) {
      interval <- irregular()
    } else {
      interval <- init_interval()
    }
    return(set_tsibble_class(
      tbl,
      "key" = key,
      # "key_indices" = attr(grped_key, "indices"),
      "index" = index,
      "index2" = index2,
      "interval" = interval,
      "regular" = regular,
      "ordered" = TRUE
    ))
  }

  if (is_false(regular)) {
    interval <- irregular()
  } else if (regular && is.null(interval)) {
    eval_idx <- eval_tidy(index, data = tbl)
    interval <- pull_interval(eval_idx)
  } else if (is_false(inherits(interval, "interval"))) {
    abort(sprintf(
      "Argument `interval` must be class interval, not %s.",
      class(interval)[1]
    ))
  }

  # arrange in time order (by key and index)
  if (is.null(ordered)) { # first time to create a tsibble
    tbl <- tbl %>%
      arrange(!!! key, !! index)
    ordered <- TRUE
  } else if (is_false(ordered)) { # false returns a warning
    msg_header <- "Unexpected temporal order. Please sort by %s."
    idx_txt <- expr_text(index)
    if (is_empty(key)) {
      msg <- sprintf(msg_header, idx_txt)
    } else {
      msg <- sprintf(msg_header, paste_comma(c(key, idx_txt)))
    }
    warn(msg)
  } # true do nothing

  idx_lgl <- identical(index, index2)
  # convert grouped_df to tsibble:
  # the `groups` arg must be supplied, otherwise returns a `tbl_ts` not grouped
  if (!idx_lgl) {
    tbl <- tbl %>% group_by(!! index2, add = TRUE)
  }
  set_tsibble_class(
    tbl,
    "key" = key,
    # "key_indices" = attr(grped_key, "indices"),
    "index" = index,
    "index2" = index2,
    "interval" = structure(interval, class = "interval"),
    "regular" = regular,
    "ordered" = ordered
  )
}


#' Identifier to construct structural variables
#'
#' Impose a structure to a tsibble
#'
#' @param ... Variables passed to tsibble()/as_tsibble().
#'
#' @seealso [tsibble], [as_tsibble]
#' @export
id <- function(...) {
  unname(enexprs(...))
}

## Although the "index" arg is possible to automate the detection of time
## objects, it would fail when tsibble contain multiple time objects.
validate_index <- function(data, index) {
  val_idx <- map_lgl(data, index_valid)
  if (quo_is_null(index)) {
    abort("Argument `index` must not be `NULL`.")
  }
  if (quo_is_missing(index)) {
    if (sum(val_idx, na.rm = TRUE) != 1) {
      abort("Can't determine the index and please specify argument `index`.")
    }
    chr_index <- names(data)[val_idx]
    chr_index <- chr_index[!is.na(chr_index)]
    inform(sprintf("Column `%s` is the index.", chr_index))
  } else {
    chr_index <- tidyselect::vars_pull(names(data), !! index)
    idx_pos <- names(data) %in% chr_index
    val_lgl <- val_idx[idx_pos]
    if (is.na(val_lgl)) {
      return(sym(chr_index))
    } else if (!val_idx[idx_pos]) {
      cls_idx <- map_chr(data, ~ class(.)[1])
      abort(sprintf(
        "Unsupported index type: %s", cls_idx[idx_pos])
      )
    }
  }
  if (anyNA(data[[chr_index]])) {
    abort(sprintf("Column `%s` (the index) must not contain `NA`.", chr_index))
  }
  sym(chr_index)
}

# check if a comb of key vars result in a unique data entry
# if TRUE return the data, otherwise raise an error
validate_tsibble <- function(data, key, index) {
  # NOTE: bug in anyDuplicated.data.frame() (fixed in R 3.5.0)
  # identifiers <- c(key, idx)
  # below calls anyDuplicated.data.frame():
  # time zone associated with the index will be dropped,
  # e.g. nycflights13::weather, thus result in duplicates.
  # dup <- anyDuplicated(data[, identifiers, drop = FALSE])
  tbl_dup <- grouped_df(data, vars = key) %>%
    summarise(!! "zzz" := anyDuplicated.default(!! index))
  if (any_not_equal_to_c(tbl_dup$zzz, 0)) {
    header <- "A valid tsibble must have distinct rows identified by key and index.\n"
    hint <- "Please use `find_duplicates()` to check the duplicated rows."
    abort(paste0(header, hint))
  }
  data
}

#' Coerce to a tibble or data frame
#'
#' @param x A `tbl_ts`.
#' @param ... Ignored.
#' @inheritParams base::as.data.frame
#'
#' @rdname as-tibble
#' @export
#' @examples
#' as_tibble(pedestrian)
#'
#' # a grouped tbl_ts -----
#' grped_ped <- pedestrian %>% group_by(Sensor)
#' as_tibble(grped_ped)
as_tibble.tbl_ts <- function(x, ...) {
  x <- remove_tsibble_attrs(x)
  class(x) <- c("tbl_df", "tbl", "data.frame")
  as_tibble(x, ...)
}

#' @export
as_tibble.grouped_ts <- function(x, ...) {
  as_grouped_df(x)
}

#' @keywords internal
#' @export
as_tibble.lst_ts <- function(x, ...) {
  class(x) <- c("tbl_df", "tbl", "data.frame")
  x
}

#' @keywords internal
#' @export
as.data.frame.lst_ts <- function(x, ...) {
  class(x) <- "data.frame"
  x
}

#' @rdname as-tibble
#' @export
as.data.frame.tbl_ts <- function(x, row.names = NULL, optional = FALSE, ...) {
  x <- as_tibble(x)
  NextMethod()
}

use_id <- function(x, key) {
  key <- enquo(key)
  if (quo_is_call(key)) {
    call_fn <- call_name(key)
    if (call_fn == "key") return(eval_tidy(key)) # key(x)
    if (call_fn != "id") {
      abort(sprintf("Please use `key = id(...)`, not `%s(...)`.", call_fn))
    } # vars(x)
  }
  key_expr <- get_expr(key)
  if (is_string(key_expr)) {
    abort(suggest_key(key_expr))
  }
  safe_key <- purrr::safely(eval_tidy)(
    key_expr,
    env = child_env(get_env(key), id = id)
  )
  if (is_null(safe_key$error)) {
    fn <- function(x) {
      if (is_list(x)) all(map_lgl(x, fn)) else is_expression(x)
    }
    lgl <- fn(safe_key$result)
    if (lgl) return(safe_key$result)
  }
  abort(suggest_key(as_string(key_expr)))
}

#' Find duplication of key and index variables
#'
#' Find which row has duplicated key and index elements
#'
#' @param data A `tbl_ts` object.
#' @param key Structural variable(s) that define unique time indices, used with
#' the helper [id]. If a univariate time series (without an explicit key),
#' simply call `id()`.
#' @param index A bare (or unquoted) variable to specify the time index variable.
#' @param fromLast `TRUE` does the duplication check from the last of identical
#' elements.
#'
#' @return A logical vector of the same length as the row number of `data`
#' @export
find_duplicates <- function(data, key = id(), index, fromLast = FALSE) {
  key <- use_id(data, !! enquo(key))
  index <- validate_index(data, enquo(index))

  grouped_df(data, vars = key) %>%
    mutate(!! "zzz" := duplicated.default(!! index, fromLast = fromLast)) %>%
    dplyr::pull(!! "zzz")
}

set_tsibble_class <- function(x, ...) {
  attribs <- list(...)
  attributes(x)[names(attribs)] <- attribs
  attr(x, "row.names") <- .set_row_names(NROW(x))
  if (is_empty(groups(x))) {
    class(x) <- c("tbl_ts", "tbl_df", "tbl", "data.frame")
  } else {
    class(x) <- c("grouped_ts", "tbl_ts", "tbl_df", "tbl", "data.frame")
  }
  x
}

remove_tsibble_attrs <- function(x) {
  attr(x, "key") <- attr(x, "index") <- attr(x, "index2") <- NULL
  attr(x, "interval") <- attr(x, "regular") <- attr(x, "ordered") <- NULL
  x
}

#' @export
`row.names<-.tbl_ts` <- function(x, value) {
  if (!is_null(value)) {
    warn("Setting row names on a tsibble is deprecated.")
  }
  NextMethod()
}
