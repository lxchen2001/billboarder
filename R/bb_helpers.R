#' Helper for creating a bar chart
#'
#' @param bb A \code{billboard} \code{htmlwidget} object.
#' @param data A \code{data.frame}, the first column will be used for x axis unless
#' specified otherwise in \code{...}. If not a \code{data.frame}, an object coercible to \code{data.frame}.
#' @param stacked Logical, if several columns provided, produce a stacked bar chart, else
#' a dodge bar chart.
#' @param rotated Switch x and y axis position.
#' @param color Bar's color.
#' @param ... Arguments for slot bar, see \url{https://naver.github.io/billboard.js/release/latest/doc/Options.html#.bar}.
#' 
#' @note This function can be used with \code{\link{billboarderProxy}} in shiny application.
#'
#' @return A \code{billboard} \code{htmlwidget} object.
#' @export
#'
#' @examples
#' library("billboarder")
#' 
#' stars <- data.frame(
#'   package = c("billboarder", "ggiraph", "officer", "shinyWidgets", "visNetwork"),
#'   stars = c(1, 176, 42, 40, 166)
#' )
#' 
#' billboarder() %>%
#'   bb_barchart(data = stars)
#' 
#' billboarder() %>%
#'   bb_barchart(data = stars, labels = TRUE) %>%
#'   bb_data(names = list(stars = "Number of stars")) %>% 
#'   bb_axis(rotated = TRUE)
bb_barchart <- function(bb, data, stacked = FALSE, rotated = FALSE, color = NULL, ...) {
  
  if (missing(data))
    data <- bb$x$data
  
  data <- as.data.frame(data)
  args <- list(...)
  
  if (is.null(data)) {
    bb <- .bb_opt(bb, "bar", ...)
    return(bb)
  }
  
  x <- args$x %||% names(data)[1]
  
  if (stacked) {
    stacked <- list(as.list(base::setdiff(names(data), x)))
  } else {
    stacked <- list()
  }
  
  if (nrow(data) == 1) {
    json <- lapply(X = as.list(data), FUN = list)
  } else {
    json <- as.list(data)
  }
  
  
  data_opt <- list(
    x = x,
    json = json,
    type = "bar",
    groups = stacked
  )
  
  
  
  if ("billboarder_Proxy" %in% class(bb)) {
    
    # bb <- bb_load(proxy = bb, x = x, json = json, groups = stacked, unload = bb$unload) 
    
    if (!is.null(color)) {
      colp <- stats::setNames(as.list(color), setdiff(names(json), x))
    } else {
      colp <- NULL
    }
    
    bb <- bb_load(proxy = bb,
                  json = json[-which(names(json)==x)], 
                  groups = stacked, 
                  unload = bb$unload, 
                  colors = colp) 
    
    bb <- bb_categories(bb = bb, categories = json[[1]])

  } else {
    
    bb <- .bb_opt2(bb, "data", data_opt)
    
    bb <- .bb_opt(bb, "bar", ...)
    
    if (!is.null(color))
      bb <- bb_color(bb, color)
    
    bb <- .bb_opt(bb, "axis", x = list(type = "category"), rotated = rotated)
    
  }
  
  return(bb)
}



#' Manual color for barchart
#' 
#' @param bb A \code{billboard} \code{htmlwidget} object.
#' @param values A named vector, names represent the categories of the bar chart,
#' values correspond to colors. All categories must be present in the vector, in 
#' the same order of the chart.
#' 
#' @note Must be called after \code{bb_bar}.
#'  
#' @return A \code{billboard} \code{htmlwidget} object.
#' @export
#' 
#' @importFrom jsonlite toJSON
#' @importFrom htmlwidgets JS
#' 
#' @examples
#' \dontrun{
#' 
#' library("data.table")
#' library("billboarder")
#' 
#' data("mpg", package = "ggplot2")
#' setDT(mpg)
#' 
#' # all in blue
#' manufa <- unique(mpg$manufacturer)
#' cols <- rep("#08298A", length(manufa))
#' names(cols) <- manufa
#' 
#' # Nissan in red
#' cols[["nissan"]] <- "#DF0101"#' 
#' 
#' billboarder() %>%
#'   bb_barchart(data = mpg[, list(count = .N), by = manufacturer][order(count)]) %>%
#'   bb_bar_color_manual(values = cols)
#' }
bb_bar_color_manual <- function(bb, values) {
  
  x <- bb$x$bb_opts$data$x
  categories <- bb$x$bb_opts$data$json[[x]]
  
  if (is.null(categories))
    stop("This function must be called after 'bb_barchart'")
  
  colorjs <- htmlwidgets::JS(
    paste(
      "function(color, d) {",
      paste0(
        "var x = ", jsonlite::toJSON(categories), "; "
      ),
      paste(
        sprintf(
          "if (x[d.index] == '%s') { return '%s'; }", 
          names(values), unname(values)
        ),
        collapse = "\n"
      ),
      "else { return color; }",
      "}", collapse = "\n"
    )
  )
  
  bb <- .bb_opt(bb, "data", color = colorjs)
  
  return(bb)
}



#' @title Set categories on X axis
#' 
#' @description Set or modify x axis labels.
#'
#' @param bb A \code{billboard} \code{htmlwidget} object. 
#' @param categories A character vector to set names on a category axis.
#' 
#' @note This function can be used with \code{\link{billboarder-shiny}} to modify labels on axis, e.g. for barcharts.
#'
#' @return A \code{billboard} \code{htmlwidget} object.
#' @export
#'
#' @examples
#' # Simple line with month names as x labels
#' billboarder() %>% 
#'   bb_linechart(data = round(rnorm(12))) %>% 
#'   bb_categories(categories = month.name)
#'   
bb_categories <- function(bb, categories) {
  
  if ("billboarder_Proxy" %in% class(bb)) {
    
    bb <- .bb_proxy(bb, "categories", categories)
    
  } else {

    bb <- .bb_opt(bb, "axis", x = list(type = "category", categories = categories))
    
  }
  
  bb
}




#' Helper for creating a scatter chart
#'
#' @param bb A \code{billboard} \code{htmlwidget} object.
#' @param data A \code{data.frame}
#' @param x Variable to map to the x-axis, if \code{NULL} first variable is used.
#' @param y Variable to map to the y-axis, if \code{NULL} second variable is used.
#' @param group Variable to use to plot data by group.
#' @param ... unused
#' 
#' @note This function can be used with \code{\link{billboarderProxy}} in shiny application.
#'
#' @return A \code{billboard} \code{htmlwidget} object.
#' @export
#' 
#' @importFrom stats setNames
#'
#' @examples
#' \dontrun{
#' billboarder() %>% 
#'   bb_scatterplot(data = iris, x = "Sepal.Length", y = "Sepal.Width")
#' }
bb_scatterplot <- function(bb, data, x = NULL, y = NULL, group = NULL, ...) {
  
  if (missing(data))
    data <- bb$x$data
  
  args <- list(...)
  
  x <- x %||% names(data)[1]
  y <- y %||% names(data)[2]
  
  if (is.null(group)) {
    xs <- stats::setNames(list(x), y)
    json <- as.list(data[, c(x, y)])
  } else {
    xs <- stats::setNames(
      object = as.list(paste(unique(data[[group]]), "x", sep = "_")), 
      nm = unique(data[[group]])
    )
    json <- c(
      split(x = data[[x]], f = paste(data[[group]], "x", sep = "_")),
      split(x = data[[y]], f = data[[group]])
    )
  }
  
  data_opt <- list(
    xs = xs,
    json = json,
    type = "scatter"
  )
  
  data_axis <- list(
    x = list(
      label = list(
        text = x
      )
    ),
    y = list(
      label = list(
        text = y
      )
    )
  )
  
  
  if ("billboarder_Proxy" %in% class(bb)) {
    
    bb <- bb_load(proxy = bb, json = json, xs = xs, unload = bb$unload) 
    
    bb <- bb_axis_labels(proxy = bb, x = x, y = y)
    
  } else {
    
    bb <- .bb_opt2(bb, "data", data_opt)
    
    bb <- .bb_opt(bb, "legend", show = !is.null(group))
    
    bb <- .bb_opt2(bb, "axis", data_axis)
    
  }
  
  
  return(bb)
}




#' Helper for creating a gauge
#'
#' @param bb A \code{billboard} \code{htmlwidget} object.
#' @param value A numeric value.
#' @param name Name for the value, appear in  tooltip.
#' @param steps Upper bound for changing colors
#' @param steps_color Colors corresponding to steps
#' @param ... Arguments for slot gauge.
#' 
#' @note This function can be used with \code{\link{billboarderProxy}} in shiny application.
#'
#' @return A \code{billboard} \code{htmlwidget} object.
#' @export
#' 
#' @importFrom stats setNames
#'
#' @examples
#' \dontrun{
#' billboarder() %>% 
#'  bb_gaugechart(value = 50)
#' }
bb_gaugechart <- function(bb, value, name = "Value", 
                     steps = c(30, 60, 90, 100),
                     steps_color = c("#FF0000", "#F97600", "#F6C600", "#60B044"),
                     ...) {
  
  if (missing(value) || is.null(value)) {
    bb <- .bb_opt(bb, "gauge", ...)
    return(bb)
  }
  
  if (length(steps) != length(steps_color))
    stop("'steps' and 'steps_color' must have same length.")
  
  data_opt <- list(
    json = stats::setNames(list(list(value)), name),
    type = "gauge"
  )
  
  data_color <- list(
    pattern = steps_color,
    threshold = list(values = steps)
  )
  
  
  if ("billboarder" %in% class(bb)) {
    
    bb <- .bb_opt2(bb, "data", data_opt)
    
    bb <- .bb_opt(bb, "gauge", ...)
    
    bb <- .bb_opt2(bb, "color", data_color)
    
    return(bb)
    
  } else if ("billboarder_Proxy" %in% class(bb)) {
    .bb_proxy(bb, "data", json = data_opt$json, ...)
  }
  
}




#' Helper for creating a pie chart
#'
#' @param bb A \code{billboard} \code{htmlwidget} object.
#' @param data A \code{data.frame}, first column must contain labels and second values associated.
#' @param ... Arguments for slot pie, \url{https://naver.github.io/billboard.js/release/latest/doc/Options.html#.pie}.
#' 
#' @note This function can be used with \code{\link{billboarderProxy}} in shiny application.
#'
#' @return A \code{billboard} \code{htmlwidget} object.
#' @export
#' 
#' @examples
#' \dontrun{
#' stars <- data.frame(
#'   package = c("billboarder", "ggiraph", "officer", "shinyWidgets", "visNetwork"),
#'   stars = c(9, 177, 43, 44, 169)
#' )
#' 
#' billboarder() %>% 
#'   bb_piechart(data = stars)
#' }
bb_piechart <- function(bb, data, ...) {
  
  if (missing(data))
    data <- bb$x$data
  
  data <- as.data.frame(data)
  
  json <- as.list(data[[2]])
  json <- lapply(X = json, FUN = list)
  names(json) <- data[[1]]
  
  data_opt <- list(
    json = json,
    type = "pie"
  )

  if ("billboarder_Proxy" %in% class(bb)) {
    
    bb <- bb_load(proxy = bb, json = json, unload = bb$unload) 
    
  } else {
    
    bb <- .bb_opt2(bb, "data", data_opt)
    
    bb <- .bb_opt(bb, "pie", ...)
    
  }
  
  return(bb)
}




#' Helper for creating a donut chart
#'
#' @param bb A \code{billboard} \code{htmlwidget} object.
#' @param data A \code{data.frame}.
#' @param ... Arguments for slot donut, \url{https://naver.github.io/billboard.js/release/latest/doc/Options.html#.donut}.
#' 
#' @note This function can be used with \code{\link{billboarderProxy}} in shiny application.
#'
#' @return A \code{billboard} \code{htmlwidget} object.
#' @export
#' 
#' @examples
#' \dontrun{
#' stars <- data.frame(
#'   package = c("billboarder", "ggiraph", "officer", "shinyWidgets", "visNetwork"),
#'   stars = c(9, 177, 43, 44, 169)
#' )
#' 
#' billboarder() %>% 
#'   bb_donutchart(data = stars, title = "Stars")
#' }
bb_donutchart <- function(bb, data, ...) {
  
  if (missing(data))
    data <- bb$x$data
  
  data <- as.data.frame(data)
  
  json <- as.list(data[[2]])
  json <- lapply(X = json, FUN = list)
  names(json) <- data[[1]]
  
  data_opt <- list(
    json = json,
    type = "donut"
  )
  
  if ("billboarder_Proxy" %in% class(bb)) {
    
    bb <- bb_load(proxy = bb, json = json, unload = bb$unload) 
    
  } else {
    
    bb <- .bb_opt2(bb, "data", data_opt)
    
    bb <- .bb_opt(bb, "donut", ...)
    
  }
  
  return(bb)
}







#' Helper for creating an histogram
#'
#' @param bb A \code{billboard} \code{htmlwidget} object.
#' @param x A numeric \code{vector}.
#' @param breaks Arguments passed to \code{hist}.
#' @param ... Arguments for slot 
#'
#' @return A \code{billboard} \code{htmlwidget} object.
# @export
#' 
#' @importFrom graphics hist
#' 
bb_histogram <- function(bb, x, breaks = "Sturges", ...) {
  
  
  h <- graphics::hist(x = x, breaks = breaks, plot = FALSE)
  
  json <- list(
    data = h$counts,
    x = h$breaks
  )
  
  
  data_opt <- list(
    json = json,
    type = "area-step",
    x = "x"
  )
  
  bb <- .bb_opt2(bb, "data", data_opt)
  
  bb <- .bb_opt(bb, "area", ...)
  
  bb <- .bb_opt(bb, "line", step = list(type = "step"))
  
  return(bb)
}








#' Helper for creating a line chart
#'
#' @param bb A \code{billboard} \code{htmlwidget} object.
#' @param data A \code{data.frame} or a \code{vector}.
#' @param type Type of chart : line, spline, step, area, area-spline, area-step.
#' @param show_point Whether to show each point in line.
#' @param ... Not used.
#' 
#' @note This function can be used with \code{\link{billboarderProxy}} in shiny application.
#'
#' @return A \code{billboard} \code{htmlwidget} object.
#' @export
#'
#' @examples
#' 
#' # Different types
#' x <- round(rnorm(20), 2)
#' 
#' billboarder() %>% 
#'   bb_linechart(data = x)
#' 
#' billboarder() %>% 
#'   bb_linechart(data = x, type = "spline")
#' 
#' billboarder() %>% 
#'   bb_linechart(data = x, type = "area")
#' 
#' billboarder() %>% 
#'   bb_linechart(data = x, type = "area-spline")
#'   
#'   
#' # Timeserie with date (Date)
#' data("economics", package = "ggplot2")
#' 
#' billboarder() %>%
#'   bb_linechart(data = economics[, c("date", "psavert")]) %>% 
#'   bb_x_axis(tick = list(format = "%Y-%m", fit = FALSE)) %>%
#'   bb_y_axis(tick = list(format = suffix("%")), 
#'             label = list(text = "Personal savings rate")) %>% 
#'   bb_legend(show = FALSE) %>% 
#'   bb_x_grid(show = TRUE) %>% 
#'   bb_y_grid(show = TRUE) %>% 
#'   bb_subchart(show = TRUE)
#'   
#'
#' # Timeserie with datetime (POSIXct)
#' data("cdc_prod_filiere")
#' 
#' billboarder() %>% 
#'   bb_linechart(data = cdc_prod_filiere[, c("date_heure", "prod_eolien")])
#'  
#'  
#' ## Other type for x-axis 
#'  
#' # character/factor on x-axis
#' AirPassengers1960 <- data.frame(
#'   month = month.name, 
#'   AirPassengers = tail(AirPassengers, 12)
#' )
#' # you have to specify that x-axis is of type 'category'
#' billboarder() %>% 
#'   bb_linechart(data = AirPassengers1960, x = "month") %>% 
#'   bb_x_axis(type = "category")
#' 
#' 
#' # numeric on x-axis
#' lynx.df <- data.frame(
#'   year = time(lynx),
#'   lynx = lynx
#' )
#' # just specify which variable must be use n the x-axis
#' billboarder() %>% 
#'   bb_linechart(data = lynx.df, x = "year")
#'   
bb_linechart <- function(bb, data, type = "line", show_point = FALSE, ...) {
  
  type <- match.arg(
    arg = type, 
    choices = c("line", "spline", "step", "area", "area-spline", "area-step", "bar"),
    several.ok = TRUE
  )
  
  if (missing(data))
    data <- bb$x$data
  
  args <- list(...)
  
  if (is.vector(data)) {
    data_opt <- list(
      json = list(
        x = data
      ),
      type = type
    )
  } else {
    if (inherits(x = data[[1]], what = c("Date", "POSIXct"))) {
      if (inherits(x = data[[1]], what = c("POSIXct"))) {
        if (!"billboarder_Proxy" %in% class(bb)) {
          bb <- bb_data(bb, xFormat = "%Y-%m-%d %H:%M:%S")
        }
      }
      data[[1]] <- as.character(data[[1]])
      data_opt <- list(
        x = names(data)[1],
        json = as.list(data),
        type = type
      )
      if (!"billboarder_Proxy" %in% class(bb)) {
        bb <- bb_x_axis(bb, type = "timeseries")
      }
    } else {
      data_opt <- list(
        json = as.list(data),
        type = type
      )
    }
  }
  
  if ("billboarder_Proxy" %in% class(bb)) {
    
    bb <- bb_load(proxy = bb, json = data_opt$json, unload = bb$unload) 
    
  } else {
    
    bb <- .bb_opt2(bb, "data", c(data_opt, args))

    bb <- bb_point(bb, show = show_point)
    
  }
  
  return(bb)
}


