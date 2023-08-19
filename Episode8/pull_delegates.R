# Pull proposals data from endpoints

library(jsonlite)
library(httr)
library(purrr)
library(ghql)
library(readr)
library(dplyr)

# Fetch the JSON
response = GET("https://raw.githubusercontent.com/messari/subgraphs/master/deployment/deployment.json")

# Parse the JSON
data = fromJSON(content(response, "text"))

# Filter projects related to governance
governance_projects = data[sapply(data, function(x) x$schema == "governance")]

# Base URL
base_url = "https://api.thegraph.com/subgraphs/name/messari/"

# get request urls
request_urls <- data.frame()
for (i in 1:length(governance_projects)){
  
  s = governance_projects[[i]]$protocol
  
  temp <- data.frame(slug = governance_projects[[s]][["deployments"]][[1]][["services"]][["hosted-service"]][["slug"]])
  request_urls <- rbind(request_urls, temp)
}

print(request_urls)

# GraphQL Requests --------------------------------------------------------

# Initialize an empty data.frame outside the for loop
all_data = data.frame() 

fields <- c("id", "delegatedStakedTokenVotes", "delegatedStakedTokenVotesRaw",
            "delegatedVotes", "delegatedVotesRaw", "id",
            "numberVotes", "tokenHoldersRepresentedAmount", "Protocol")

# For loop to extract data from each endpoint
for (i in 1:nrow(request_urls)) {
  
  tryCatch({
    
    print(paste0("https://api.thegraph.com/subgraphs/name/messari/", request_urls$slug[i]))
    
    # connect to the endpoint
    con = GraphqlClient$new(
      url = paste0("https://api.thegraph.com/subgraphs/name/messari/", request_urls$slug[i])
    )
    
    last_id <- NULL
    final_data <- NULL
    
    # While loop to ensure all records are extracted
    while (TRUE) {
      
      Sys.sleep(0.4) # could enable this just to be safer against rate limiting (although shouldn't be an issue without this)
      
      print(if (!is.null(final_data)) nrow(final_data) else 0)
      
      # initialize a new query
      graphql_request = Query$new()
      
      # construct the query
      if (is.null(last_id)) {
        graphql_query <- '{
          delegates(orderBy: "id", orderDirection: "asc", first:1000) {
            delegatedStakedTokenVotes
            delegatedStakedTokenVotesRaw
            delegatedVotes
            delegatedVotesRaw
            id
            numberVotes
            tokenHoldersRepresentedAmount
          }
        }'
      } else {
        graphql_query <- paste0('{
          delegates(orderBy: "id", orderDirection: "asc", first:1000, where: {id_gt: "', last_id, '"}) {
            delegatedStakedTokenVotes
            delegatedStakedTokenVotesRaw
            delegatedVotes
            delegatedVotesRaw
            id
            numberVotes
            tokenHoldersRepresentedAmount
          }
        }')
      }
      
      graphql_request$query('mydata', graphql_query)
      
      # Run query (pull data)
      temp_data = con$exec(graphql_request$queries$mydata)
      
      # convert results to JSON
      temp_data = fromJSON(temp_data)
      
      # extract result
      temp_data = temp_data$data$delegates
      
      # break the loop if no data returned
      if(length(temp_data) == 0) break
      
      # ADJUSTMENT: set Protocol and ensure consistent column names
      temp_data[, "Protocol"] <- as.character(request_urls$slug[i])
      temp_data <- temp_data[, fields]
      
      # Append data to the final data
      if(is.null(final_data)){
        final_data <- temp_data
      } else {
        final_data <- rbind(final_data, temp_data)
      }
      
      # Update last token balance for the next iteration
      last_id <- tail(temp_data$id, n=1)
      
    }
    
    # Append final_data to all_data
    all_data <- rbind(all_data, final_data)
    
    print(paste("Completed endpoint: ", request_urls$slug[i]))
    print(paste("Rows extracted for protocol: ", nrow(final_data)))
    print(paste("Rows extracted in total: ", nrow(all_data)))
    
    
  })
  
  # write to csv after each protocol is done
  write.csv(all_data, file = paste0("subgraph_data_delegates_", format(Sys.Date(), "%Y%m%d"), ".csv"), row.names = FALSE)
  
}






