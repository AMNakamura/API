Azure API - WIQL Setup
================
Ann Nakamura

-   [1 Purpose](#1-purpose)
-   [2 Creating a managed Work Item
    Query](#2-creating-a-managed-work-item-query)
-   [3 Creating a request message for the Azure
    API](#3-creating-a-request-message-for-the-azure-api)
    -   [3.1 Request message format](#31-request-message-format)
    -   [3.2 Request URI construction](#32-request-uri-construction)
-   [4 Finding variable names](#4-finding-variable-names)
-   [5 Sending a query to the Azure DevOps REST
    API](#5-sending-a-query-to-the-azure-devops-rest-api)
-   [6 Resources](#6-resources)

# 1 Purpose

Extract work items in Azure DevOps Services REST API using Work Item
Query Language (WIQL). Work item text can be used not only to track
work, but to identify unexplored relationships between system
functionality (e.g., through topic modeling of user story text).

> Note: Before querying Azure DevOps, please review instructions
> describing how to protect your secret token(s).

This document describes:

-   Creating a managed Work Item query
-   Creating request messages for Azure API work item resources.
-   Finding the internal variable names for work item fields of
    interest.
-   Sending a query to the Azure DevOps REST API to returns a list of
    work items with specified fields.

# 2 Creating a managed Work Item Query

There are a few ways to query work items in Azure DevOps. One method,
using the ODATA Analytics repository, was A work item query can be
created from the Azure DevOps user interface or from a query defined
using WIQL. It is often helpful to start with a managed query (a query
built using the query editor within the Azure web application). This can
help identify desired fields, filters, and parameter names for the
Request Uniform Resource Identifier (“Request URI”).

# 3 Creating a request message for the Azure API

## 3.1 Request message format

Request messages follow a standard format:

`{Method}{request URI}{HTTP version}`

-   `Method` describes the action to be taken (usually to GET
    information from or POST information to the resource).
-   `request URI` describes the resource. Usually this resource is in
    the form of an HTTP(S) URL; it will look like a website address with
    some optional query parameters (often following a ‘?’ character).
-   `HTTP version` is the HTTP version being used by the requester. This
    helps the server interpret the request and may or may not be
    required. For this example, the HTTP version is not needed as the
    Azure API and requester versions are the same.

GET requests extract data. If team members have write privileges that
enable them to update information, POST requests will add or alter
content.

## 3.2 Request URI construction

The Azure request URI has five parts:

-   {Instance}: The Azure DevOps Services organization you send the
    request to (e.g., “devops.domain”).
-   {Team Project}: The project area you wish to query (e.g.,
    “MyProjects/Favorite-Project”).
-   {Area}: The resource area (e.g., “wit” for Work Item Tracking).
-   {Resource}: The resource itself (e.g., “WorkItems”, “queries”,
    “wiql”).
-   {Version}: An (optional) version identifier (e.g., 5.1).

Request URIs for the Azure API Work Item Tracking resource have the
following form:

<a
href="https://dev.azure.com/%7Borganization%7D/%7Bproject%7D/\_apis/%7Barea%7D/%7Bresource%7D?api-version=%7Bversion%7D"
class="uri">https://dev.azure.com/{organization}/{project}/\_apis/{area}/{resource}?api-version={version}</a>

### 3.2.1

#### 3.2.1.1 Metadata requests

> To return a managed query name, when it was run, by whom, and other
> details:
> `https://devops.domain/ProjectGroup/Project/_apis/wit/queries/{id}?api_version=5.1`

> To return the field names for a managed query:
> `https://devops.domain/ProjectGroup/Project/_apis/wit/wiql/{id}?api-version=5.1`

#### 3.2.1.2 Work Item Tracking Requests

> To return a list of work item IDs:
> `https://devops.domain/MyProjects/Favorite-Project/_apis/wit/WorkItems?ids={id list}&api-version=5.1`

> To return a list of work item IDs with work item fields:

> \`<a
> href="https://devops.domain/ProjectGroup/Project/\_apis/wit/WorkItems?ids=%7Bid"
> class="uri">https://devops.domain/ProjectGroup/Project/\_apis/wit/WorkItems?ids={id</a>
> list}&fields={field list}&api-version=5.1”

> To run a query in the front end environment via the browser
> `https://devops.domain/MyProjects/Favorite-Project/_workitems?_a=query&wiql={Encoded WorkItemQueryLanguage}")`

#### 3.2.1.3 ODATA Analytics Requests

> Sample URI returning work item information from the ODATA Analytics
> Repository
> `https://devops.domain/ProjectGroup/Project/_odata/v3.0-preview/WorkItems?${query1}$expand={resource}({query2})`

# 4 Finding variable names

All internal variable names available can be found here:
\><a href="https://devops.domain/ProjectGroup/Project/\_apis/wit/fields"
class="uri">https://devops.domain/ProjectGroup/Project/\_apis/wit/fields</a>

Usinig a managed query is a helpful way to narrow down the list and
ensure Azure is returning the information you want. A request with the
query ID returns the work item ID and URL; the work item attributes
(Title, etc.) are not returned. However, pasting the query identifier
into a URI request returns the column names. <br> <br>

# 5 Sending a query to the Azure DevOps REST API

``` r
suppressMessages(library(httr))      # GET() formatting. Loads unparsed data. 
suppressMessages(library(jsonlite))  # To parse the data into data frames. 
suppressMessages(library(glue))      # pasting global objects into text strings, etc.
```

### 5.0.1 Step 1: Obtain the list of Work Item IDs from a managed query

``` r
username <- "myusername"

qid <- '00fake00-1a2b-3e33-ad44-55667faked00' 
wi1 <- glue("https:devops.domain/MyProjects/Favorite-Project/_apis/wit/wiql/{qid}?api-version=5.1")

wiGET <- GET(wi1,authenticate(username,Sys.getenv("AZURE1_PAT"),type="basic"))
wiGET$status_code  
wiGOT <- content(wiGET,"text")

wi1FLAT <- fromJSON(wiGOT, flatten = TRUE)[["workItems"]]$id
wi1FLAT <- as.data.frame(wi1FLAT)
colnames(wi1FLAT) <- "ID"
```

### 5.0.2 Step 2: Subset the list

Azure queries only fetch 200 records at a time. One way to reduce the
size of the list is to only download new work items.

``` r
suppressMessages(library(dplyr))
# File 1: Previously downloaded work items.

raw0 <- read.csv("~/WorkItemText2.csv",stringsAsFactors = FALSE)
names(raw0)

baselst <- raw0 %>%
  select(ID)

# File 2: Work items that have not been previously downloaded. 

wilst <- anti_join(wi1FLAT,baselst,by=c("ID"))
```

### 5.0.3 Step 3: Query a list of Work Item IDs

Now that you have work item IDs your are interested in, you can paste
them directly into the request URI. Note that not only is there a 200
work item limit, most browsers enforce a limit of between 2000 and 2083
characters for a URL string.

``` r
# Create the list of work item IDs, separated by commas. 

wistr <- paste(as.character(wilst$ID), collapse=",")

# Create the request URI and add parameters

wi <- glue("https://devops.domain/MyProjects/Favorite-Project/_apis/wit/WorkItems?ids={wistr}&fields=System.Id,System.Title,System.State,System.Description,Microsoft.VSTS.Common.AcceptanceCriteria&api-version=5.1")

wiGET <- GET(wi,authenticate(username,Sys.getenv("AZURE1_PAT"),type="basic"))

# Check the status of the request. A 200 status code indicates success. If you can log onto Azure from the front end application and your request is unsuccessful (e.g., 400), then check your query fields and URI statement for errors. 

wiGET$status_code  
wiGOT <- content(wiGET,"text")

wiFLAT <- fromJSON(wiGOT, flatten = TRUE)$value
```

# 6 Resources

Wickham, H. (2020). Managing secrets.
<https://cran.r-project.org/web/packages/httr/vignettes/secrets.html>
Lopp, S. (2018). RStudio Connect v1.5.14.
<https://blog.rstudio.com/2018/03/02/rstudio-connect-v1-5-14/>.

<https://docs.microsoft.com/en-us/rest/api/azure/devops/?view=azure-devops-rest-6.1>
