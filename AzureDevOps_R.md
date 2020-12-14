# Purpose

Enable the use of the Azure (or other APIs) in the RStudio Connect environment while protecting the confidentiality of API tokens needed for authentication.  

<br>

This document describes: 

* Getting the "key" to an API (creating your token)
* Using your token locally to query the Azure analytics API (securely) while you perfect your document in RStudio
* Using the token in production so that a published documents can be updated without having to republish via your RSudio development environment.  


# Getting the "key" to an API 

This example uses the Azure DevOps ODATA analytics repository.  

1. Open the [AzureDevOps application](https://YourDevOpsURL/YourProject/YourSubProject). 
2. Open your security settings by clicking on the circle containing your initials in the the upper right hand corner, then choosing "Security" in the dropdown menu. Alternatively, you can navigate to: https://YourDevOpsURL/YourProjects/_usersSettings/tokens 
3. On the "Personal Access Tokens" page, click on "New Token"
4. In "Create a new personal access token", 
    a. Create a name (e.g., "MyToken")
    b. Under "Scopes", make sure the radio button for "Custom Defined" is selected. 
    c. Find the "Analytics" scope. If you don't see it, click on the "Show all scopes" link and it should appear.
    d. Click on the "Read" checkbox.
    e. Click on the "Create" button.
    
You should see a "Success!" or other indication that you have successfully added a new personal access token to your account. This token is secret and should be protected just like your username and password. Copy this token. If you want to delete it, you can delete it by 'revoking' it while within Azure DevOps. 

# Using the token locally to query the Azure analytics API (securely) 

While developing and perfecting your R markdown, Shiny or other document, you will want to use this token to query the API while in the RStudio Pro IDE (Integrated Development Environment). The way to do this securely is to save it to your local environment, which is only available to you.

## Saving your token to your local environment file

1. Load the `usethis` package.
2. Type `usethis::edit_r_environ()` into an R chunk and hit 'run'.
3. When your .Renviron file opens up, type the following at line 1: MYTOKEN=faketokenkeyyourtokengoeshere
    a. at the end of the last line, add a carriage return. There will be one blank line at the end of your document. This is the end-of-line indicator needed by R to read the file.
4. Save and close the .Renviron file
5. Restart R

When you re-open R, you can call this token into your local environment with the `Sys.getenv()` command.
You will need to send your congiguration file as a resource file when publishing. Below is a sample YAML header.

---
title: "Azure API Setup"
author: "Ann Nakamura"
date: "10/19/2019"
output:
  bookdown::html_document2:
subtitle: Establishing a connection to the Project Azure API and safely passing secret keys to
  RStudio Connect
resource_files:
- config.yml
---


Calls to API endpoints are handled using  `httr` (@R-httr), and `jsonlite` (@R-jsonlite) packages. 


```{r loadpkgs, warning=FALSE,message=FALSE}

suppressMessages(library(config))


suppressMessages(library(httr))      # GET() formatting. Loads unparsed data. 
suppressMessages(library(jsonlite))  # To parse the data into data frames. 

suppressMessages(library(glue))      # pasting global objects into titles, etc.
suppressMessages(library(ggplot2))

```

## Query the Azure analytics API locally  

Here's an example of a query that will be passed to Azure as a GET request. Note the call to GET contains `Sys.getenv("MYPAT")`. 'MYPAT' is the name of my token. The `type="basic"` parameter tells R we're using OAuth2 authentication (basic).  

The query will return a JSON file, which can be parsed using `jsonlite` or other JSON parsing tools. 

```{r GetCall1, warning=FALSE, message=FALSE, eval=FALSE}
username <- "myEmailOrUserName"

wi <- "https://YourDevOpsURL/YourProject/YourSubProject/_odata/v3.0-preview/WorkItems?$select=WorkItemId,CompletedWork,ParentWorkitemId,TagNames,Title,State,WorkItemType,Custom_OASPoints,StoryPoints,Severity,OriginalEstimate,AssignedToUserSK,RemainingWork&$expand=Iteration($select=IterationPath,IterationLevel1,IterationLevel2,StartDate,EndDate,IsEnded),Area($select=AreaPath)"

wiGET <- GET(wi,authenticate(username,Sys.getenv("MYPAT"),type="basic"))
wiGOT <- content(wiGET,"text")

wiFLAT <- fromJSON(wiGOT, flatten = TRUE)$value

```


# Using the token in production 

RConnect cannot read the token from your local environment. In order to evaluate the GET call, the token has to be readable in the production environment (https://MyConnectURL/connect/). The method used in this example is the easiest to implement: 

1. Create a configuration file that allows the credentials to vary, depending on the deployment. The configuration file contains two lists, one set of credentials for the local deployment in RStudio IDE ("default") and another for production ("rsconnect"). The details for the production environment (e.g., relative path and token) will be updated after step 3. 
2. Test the code for deployment locally. 
3. Deploy the document, with the source code to identify the relative path to the final document.
4. Add the token and username to the RConnect document's environmental variables using the environmental variable panel
5. Update the configuration file with the relative URL.
6. Repeat step 3 (Deploy the document) with the final credentials. 


## Create a configuration file

A configuration file is a good way to keep your token out of your source code. This example uses a YAML as the configuration file. 

Create a new text file called `config.yml` and save it to the root directory of your source document. In this example, I'm calling the same token, but you can use different tokens for different environments, if you wish.

Below is a copy of a sample `config.yml` file. YAML can be finicky about format, particularly white space. For great examples on how to create YAML files correctly, see [Tips from Monash University's Data Fluency project](https://monashdatafluency.github.io/r-rep-res/yaml-introduction.html). 

Here are some of the formatting notes: 

- The YAML header has three dashes `---` in line 1.
- There is no white space at the beginning or ending of first-level lists (default and rsconnect).
- There is only one space between the colon `:` and the value for each key-value pair.
- `!expr` evaluates R code (use this to keep passwords and other secrets hidden)
- The path to `myconfig` is only temporary (NO_PATH_YET will be updated later)
- Four-space indents for second-level list items. 
- One extra line between the two first level lists
- There is one extra line after the  `---` footer. 


`config.yaml`: 

```{yaml, eval=FALSE, attr.source = ".numberLines"}
---
default:
    myconfig: ~/home/development/MyAzureProject/config.yml
    username: myusername
    MYPAT: !expr Sys.getenv("MYPAT")
  
rsconnect:
    myconfig: NO_PATH_YET
    username: myusername
    MYPAT: !expr Sys.getenv("MYPAT")
---

```


For the final YAML, you will need to complete two tasks: 

1. Identify the relative URL (the value for `myconfig`) in the RConnect environment.
2. Add the username and token to the environmental variables associated with this document. In this example, I'm using "MYPAT" for both, but the token names can be different). 


### Test the code locally 
First, test the authentication using the `config.yml` locally, by knitting the markdown or running the shiny UI. The code below loads the `yaml` package, specifies the query, makes the GET call to the Azure server, and processes the resulting JSON file.


```{r GetCall2, warning=FALSE, message=FALSE, attr.source = ".numberLines"}

suppressMessages(library(yaml))

mytkn <- config::get("MYPAT")
usr   <- config::get("username")

wi <- "https://YourDevOpsURL/YourProjects/_odata/v3.0-preview/WorkItems?$select=WorkItemId,CompletedWork,ParentWorkitemId,TagNames,Title,State,WorkItemType,Custom_OASPoints,StoryPoints,Severity,OriginalEstimate,AssignedToUserSK,RemainingWork&$expand=Iteration($select=IterationPath,IterationLevel1,IterationLevel2,StartDate,EndDate,IsEnded),Area($select=AreaPath)"

wiGET <- GET(wi,authenticate(usr,mytkn,type="basic"))
wiGOT <- content(wiGET,"text")

wiFLAT <- fromJSON(wiGOT, flatten = TRUE)$value

wicount <- length(wiFLAT[,1])


```

### Identify the relative URL

If there are no errors, you can click on the `publish` icon to obtain the relative URL. Make sure to choose the option to publish with the source code and make sure the config.yml is listed with the source document to be bundled at deployment. 

*You can identify the URL at this point, but you will not be able to render the document until you add the environmental variables.* 

The number assigned to the document will appear in the "Publish to Server" window when you first attempt to deploy the document and in the Error email alert sent from Ronnect  when your document fails to render.

### Add the token to the environment pane

Open the document settings using the link provided with the error alert email or by clicking on the document. Look for the following icon: 
<p style="font-size:30px">{X}</p>

In the `Name` field, add the token name (it must match the variable name used in the GET call). In the `Value` field, paste the token. Do not add quotes. Save. 


### Update the config.yml file

Update the value for rsconnect: `myconfig`. 

`config.yaml`: 

```{yaml, eval=FALSE, attr.source = ".numberLines"}
---
default:
    myconfig: ~/home/development/MyAzureProject/config.yml
    username: myusername
    MYPAT: !expr Sys.getenv("MYPAT")
  
rsconnect:
    myconfig: /apps/###/config.yml
    username: myusername
    MYPAT: !expr Sys.getenv("MYPAT")
---

``` 


### (Re)deploy and test

From within RStudio IDE, click on `publish` again to replace the previous `config.yml` file with the new one. In RConnect, test by refreshing the report in the production environment. 

Depending on the current browser settings, you may see a message indicating that the pop-ups were blocked. Hit 'Cancel' to close the warning modal window.  To test the success of your deployment, you can open the Deploy tab in the bottom left pane of the RStudio IDE. If your deployment was successful, you'll see a the following message.
<p style="color:red">"Document successfully deployed to..."</p>.  


# Resources 

Wickham, H. (2020). Managing secrets. https://cran.r-project.org/web/packages/httr/vignettes/secrets.html 
Lopp, S. (2018). RStudio Connect v1.5.14. https://blog.rstudio.com/2018/03/02/rstudio-connect-v1-5-14/. 

