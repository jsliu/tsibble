by_row <- function(FUN, .data, ordered = TRUE, interval = NULL, ...) {
  FUN <- match.fun(FUN, descend = FALSE)
  tbl <- FUN(as_tibble(.data), ...)
  update_tsibble(tbl, .data, ordered = ordered, interval = interval)
}

# put new data with existing attributes
update_tsibble <- function(
  new, old, ordered = TRUE, interval = NULL, validate = FALSE
) {
  restore_index_class(build_tsibble(
    new, key = key(old), index = !! index(old), index2 = !! index2(old),
    regular = is_regular(old), ordered = ordered, interval = interval, 
    validate = validate
  ), old)
}

# needed when grouping by index2 (e.g. summarise)
group_by_index2 <- function(x) {
  grps <- groups(x)
  idx2 <- index2(x)
  x <- as_tibble(x)
  group_by(x, !!! flatten(c(grps, idx2)))
}

as_grouped_df <- function(x) {
  class(x) <- class(x)[-match("tbl_ts", class(x))] # remove "tbl_ts"
  class(x)[match("grouped_ts", class(x))] <- "grouped_df"
  x
}

grped_df_by_key <- function(.data) {
  grp <- group_vars(.data)
  key <- key_vars(.data)
  if (all(is.element(key, grp))) {
    as_grouped_df(.data)
  } else {
    grouped_df(as_tibble(.data), key)
  }
}

restore_index_class <- function(new, old) {
  old_idx <- as_string(index(old))
  new_idx <- as_string(index(new))
  class(new[[new_idx]]) <- class(old[[old_idx]])
  if (!identical(interval(new), interval(old))) {
    attr(new, "interval") <- pull_interval(new[[new_idx]])
  }
  new
}

join_tsibble <- function(FUN, x, y, by = NULL, copy = FALSE, validate = FALSE, 
  ...) {
  FUN <- match.fun(FUN, descend = FALSE)
  tbl_x <- as_tibble(x)
  tbl_y <- as_tibble(y)
  tbl <- FUN(x = tbl_x, y = tbl_y, by = by, copy = copy, ...)
  update_tsibble(tbl, x, ordered = is_ordered(x), validate = validate)
}

tsibble_rename <- function(.data, ...) {
  names_dat <- names(.data)
  val_vars <- tidyselect::vars_rename(names_dat, ...)

  # index
  res <- .data %>% 
    rename_index(val_vars) %>% 
    rename_index2(val_vars) %>% 
    rename_key(val_vars) %>% 
    rename_group(val_vars)
  names(res) <- names(val_vars)

  build_tsibble_meta(
    res, key = key(res), index = !! index(res), index2 = !! index2(res),
    regular = is_regular(res), ordered = is_ordered(res), 
    interval = interval(res)
  )
}

tsibble_select <- function(.data, ..., validate = TRUE) {
  dots <- c(enexprs(...), index(.data))
  names_dat <- names(.data)
  val_vars <- tidyselect::vars_select(names_dat, !!! dots)
  sel_data <- select(as_tibble(.data), !!! val_vars)
  
  # key (key of the reduced size (bf & af) but also different names)
  key_vars <- syms(val_vars[val_vars %in% key_vars(.data)])
  
  if (validate) {
    vec_names <- union(names(val_vars), names(.data))
    validate <- has_any_key(vec_names, .data)
  }
  
  build_tsibble(
    sel_data, key = key_vars, index = !! index(.data), index2 = !! index2(.data),
    regular = is_regular(.data), validate = validate, 
    ordered = is_ordered(.data), interval = interval(.data)
  )
}

has_index <- function(j, x) {
  is_index_null(x)
  index <- c(quo_name(index(x)), quo_name(index2(x)))
  any(index %in% j)
}

has_any_key <- function(j, x) {
  key_vars <- key_vars(x)
  any(key_vars %in% j)
}
