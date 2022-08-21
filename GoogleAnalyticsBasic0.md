Google Analytics Reporting Server Query Setup
================
Ann

<H1>
Querying Google Analytics Using Httr
</H1>

# Use Case

Submit an exploratory call to the Google Analytics API to measure the
number of sessions or other web page use statistics within a given date
range.

# Request a fresh Oauth access token

The following defines the necessary pieces of information (credentials)
needed for a GoogleAnalytics query. This step mainly relies on the
**httr** package, which lets R users work with URLs, tokens, etc. You
will need your Google Account ID and to have set up your client secret.

-   Note that `httr` sets the `httr_oob_default` option and redefines
    the URI to **`redirect_uri <- "urn:ietf:wg:oauth:2.0:oob"`**.
-   Note also that my `client secret` is secret - it’s saved as an
    environmental variable called through the `Sys.getenv()` function.

``` r
suppressMessages(library(httr))      # GET() formatting. Loads unparsed data. 
suppressMessages(library(jsonlite))  # To parse the data into data frames. 
suppressMessages(library(glue))      # pasting global objects into text strings, etc.
suppressMessages(library(dplyr))


ga_id         <- 123456789  # Account ID
client_id     <- Sys.getenv('GA_CID')
redirect_uri  <- 'urn:ietf:wg:oauth:2.0:oob'
scope         <- 'https://www.googleapis.com/auth/analytics.readonly'
client_secret <- Sys.getenv('GA_CLAV')
response_type <-'code'
```

GoogleAnalytics uses the `OAuth` standard to grant applications (like
our `R` application here) access to their information, without having to
give away passwords. The `oauth2.0_token()` function generates an
`oauth2.0` token. The function will use the credentials provided in the
previous step to create a fresh token. After you enter the authorization
code, `httr` will create a new token and store it in `.httr-oaut` below
your home directory. Type the token you receive in the console at the
“Enter authorization code:”

``` r
auth1 <- oauth2.0_token(
   endpoint = oauth_endpoints("google"),
   app = oauth_app(
      "google", 
      key = client_id, 
      secret = client_secret
      ),
   scope,
   use_oob = TRUE,
   cache = TRUE
)
```

# Website Data Points

-   Landing Page Path: The final URL that a user landed on when they
    arrived on your page.
    [Source](https://dashthis.com/blog/google-analytics-the-difference-between-landing-page-path-and-destination-url/)

-   Destination URL: the exact link a user clicked on in order to get to
    a particular page.
    [Source](https://dashthis.com/blog/google-analytics-the-difference-between-landing-page-path-and-destination-url/)

-   Data layer: An object used by Google Tag Manager and javascript
    (`gtag.js`) to pass information about the web usage to tags. If tags
    are written into web pages, or applications (e.g., pages of an
    online application to make a purchase or sign up for an event or
    services). Events (page landings) or variables (session length) can
    be passed via the data layer, which can then use those data to
    trigger events (e.g., send data somewhere else, open a modal).

-   Client ID: The anonymous cookie identifier that Google Analytics
    assigns to every single browser instance of a given web visitor.

-   User ID: identifier that you are able to link to the logged in user
    (e.g., if they are logged into gmail and have authorized use of
    their information or they’ve given permission to you to capture
    their web browsing data). Generally a pseudonymized key that gets
    written into the data layer. The identifier is produced on the
    back-end (e.g., if your web server writes the User ID in a browser
    cookie).

# Sending the Request Query

## Preparing the Request URL

The following, `make.ga.list()` is a helper function that converts a
list of metrics and dimensions into GoogleAnalytics-specific parameters
for a `GET request`. This function creates the request URL, with the
query parameters. The request URL has to be sent in a very specific way
to be parsed correctly. The function helps ensure the URL syntax is
correct.

The `glue()` function makes the URL easier to read (i.e., as opposed to
using `paste()`).

``` r
make.ga.list <- function(l){
  for (i in 1:length(l)) {
  l[i]<- paste0("ga:",l[i]) 
}

l <- paste0(l,collapse=",")
}

# Create the request URL with query parameters and use the OAuth token previously created to fetch
# the data

get.ga.mypages <- function(ga_id,pullstart,pullend,mets,dims,max.results,fltr){
  
  m <- make.ga.list(mets)
  d <- make.ga.list(dims)
  
  a <- glue("https://www.googleapis.com/analytics/v3/data/ga?ids=ga:{ga_id}&dimensions={d}&metrics={m}&start-date={pullstart}&end-date={pullend}&max-results={max.results}&filters={fltr}")
  
 
  # Use token to fetch the data.
 rget     <- GET(a,config(token = auth1))
 rcontent <- content(rget,"text")
 rflat    <- fromJSON(rcontent, flatten = TRUE)[["rows"]]
 colnames(rflat) <- c(dims,mets)
 return(rflat)
}
```

## Consuming and Processing Query Results

### Simple example, one metric only

The following submits an exploratory call to the GA API using just the
`make.ga.list()` helper function to measure the number of sessions in a
date range. The call uses the helper function inputs to create the URL.
Then, a `GET` statement submits the URL and the token created earlier.
The `content()` function loads the content into the global environment
in a JSON format. The `fromJSON()` function flattens the data into rows
and columns.

``` r
pullstart <- "2018-01-01"
pullend   <- as.character(Sys.Date())
mets <- c("sessions")
fltr <- "ga:pagePath=@/programs/cid/doa/pages"

m <- make.ga.list(mets)
d <- make.ga.list(dims)
  
stest <- glue("https://www.googleapis.com/analytics/v3/data/ga?ids=ga:{ga_id}&metrics={m}&start-date={pullstart}&end-date={pullend}&filters={fltr}")
  
sget     <- GET(stest,config(token = auth1))
scontent <- content(sget,"text")
sflat    <- fromJSON(scontent, flatten = TRUE)[["rows"]]
prettyNum(sflat[1,1],big.mark=",",scientific=FALSE)
```

### A more complex example, metrics and dimensios

The following submits a call to the GA API to measure the number of page
views, by date, and page using the `get.ga.mypages()` helper function.
Visitor information requested includes location (latitude and longitude)
and the visitor type (new, returning). The call uses the helper function
inputs to create the URL.

If a field is not queryable, you will get the following error:
`Error in`colnames\<-`(`*tmp*`, value = c(dims, mets)) :`

``` r
pullstart <- "2018-01-01"
pullend   <- as.character(Sys.Date())

mets <- c("pageviews")
dims <- c("date","clientId","pageTitle","landingPagePath","source", "latitude","longitude","VisitorType")
dims <- c("date","clientId","pageTitle","landingPagePath","source")


fltr <- "ga:pagePath=@/PageRoot/Subpage1/Subpage2/pages"


# If field isn't queriable, you will get the following error: Error in `colnames<-`(`*tmp*`, value = c(dims, mets)) : 
# attempt to set 'colnames' on an object with less than two dimensions

r1 <- get.ga.mypages(ga_id,pullstart,pullend,mets,dims,max.results=10000,fltr)
r1 <- as.data.frame(r1) 
colnames(r1) <- c("date","clientID","pageTitle","landingPagePath","source","pageviews")

r1 <- r1 %>%
  dplyr::mutate(gadate = as.Date(date,format="%Y%m%d"),
         pageviews = as.integer(pageviews))
```

# Visualizing Web Traffic

The following syntax can be used to chart page views over time.

``` r
suppressMessages(library(ggplot2))
suppressMessages(library(stringr))

ggplot(r1, aes(x = gadate,y = pageviews) ) + 
  geom_point(aes(colour=source)) + 
  geom_smooth() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme_minimal()
```

The following produces a Tree Map with custom labels that can separate
page views by page title. Optional filters allow restriction by where
the visitor came from previously, using the source URL.

``` r
tmp <- subset(r1,!str_detect(landingPagePath,"form") &
                 !str_detect(pageTitle,"Form") &
                 !source %in% c("google","bing","(direct)","yahoo","duckduckgo","duckduckgo.com", "MyOtherSite.com"))

tmp1 <- tmp %>%
  group_by(pageTitle,source) %>%
  summarise(pageviews = sum(pageviews))


suppressMessages(library(treemap))
 
# Tree Map 1, by Page Title, then Source. Just switch the order of Page and Source in the index to reverse.

treemap(tmp1, index=c("pageTitle","source"), vSize="pageviews", type="index",
 
    fontsize.labels=c(15,12),                # Label size - two levels: one for the group, one for the subgroup 
    fontcolor.labels=c("white","red"),       # Label color - two levels
    fontface.labels=c(2,1),                  # Label font. Numbers (1,2,3,4) correspond to normal, bold, italic, bold-italic.
    bg.labels=c("transparent"),              # Background color 
    align.labels=list(
        c("center", "center"), 
        c("right", "bottom")
        ),                                   # Where to place labels 
    overlap.labels=0.5,                      # number between 0 and 1 that determines the tolerance of overlap 
                                             # 0: levels not printed if higher level labels overlap, 
                                             # 1: labels always printed. 
                                             # 0.1 - 0.99: lower level are printed if other labels do not overlap 
                                             # with higher levels that are more than n (e.g., 0.5) times their size.
    inflate.labels=F,                        # If true, labels are bigger when rectangle is bigger.
 
)
```

# Software Resources

Hadley Wickham (2020). httr: Tools for Working with URLs and HTTP. R
package version 1.4.2. <https://CRAN.R-project.org/package=httr>

Jeroen Ooms (2014). The jsonlite Package: A Practical and Consistent
Mapping Between JSON Data and R Objects. arXiv:1403.2805 \[stat.CO\] URL
<https://arxiv.org/abs/1403.2805>.

Jim Hester and Jennifer Bryan (2022). glue: Interpreted String Literals.
R package version 1.6.2. <https://CRAN.R-project.org/package=glue>

Hadley Wickham, Romain François, Lionel Henry and Kirill Müller (2022).
dplyr: A Grammar of Data Manipulation. R package version 1.0.8.
<https://CRAN.R-project.org/package=dplyr>

H. Wickham. ggplot2: Elegant Graphics for Data Analysis. Springer-Verlag
New York, 2016.

Hadley Wickham (2019). stringr: Simple, Consistent Wrappers for Common
String Operations. R package version 1.4.0.
<https://CRAN.R-project.org/package=stringr>

Martijn Tennekes (2021). treemap: Treemap Visualization. R package
version 2.4-3. <https://CRAN.R-project.org/package=treemap>
