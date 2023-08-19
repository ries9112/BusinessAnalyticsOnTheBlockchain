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
for (i in 1:length(governance_projects)){
  
  s = governance_projects[[i]]$protocol
  
  if (i == 1){
    request_urls = governance_projects[[s]][["deployments"]][[1]][["services"]][["hosted-service"]][["slug"]]
  }
  else{
    temp = governance_projects[[s]][["deployments"]][[1]][["services"]][["hosted-service"]][["slug"]]
    request_urls = rbind(temp, request_urls)
  }
}

print(request_urls)



# GraphQL Requests --------------------------------------------------------


# For loop to extract daily data
for (i in 1:nrow(request_urls)){
  
  Sys.sleep(0.5)
  
  tryCatch({
    
    print(paste0("https://api.thegraph.com/subgraphs/name/messari/", request_urls[i]))
    # connect to the blocks endpoint
    con = GraphqlClient$new(
      url = paste0("https://api.thegraph.com/subgraphs/name/messari/", request_urls[i])
    )
    
    # initialize a new query
    graphql_request = Query$new()
    
    # On first loop get latest result
    if (i == 1){
      # latest block and timestamp
      graphql_request$query('mydata', '{
  proposals(first: 1000, orderBy: creationBlock, orderDirection: desc) {
    id
    state
    abstainDelegateVotes
    abstainWeightedVotes
    againstDelegateVotes
    againstWeightedVotes
    creationBlock
    description
    executionBlock
    executionETA
    executionTime
    forDelegateVotes
    forWeightedVotes
    quorumVotes
    startBlock
    txnHash
    totalWeightedVotes
    totalDelegateVotes
    tokenHoldersAtStart
  }
}')
      # Run query (pull data)
      data = con$exec(graphql_request$queries$mydata)
      # convert results to JSON
      data = fromJSON(data)
      # extract result
      data = data$data$proposals
      # add protocol
      data[, "Protocol"] <- as.character(request_urls[i])
      
    }
    else{
      graphql_request$query('mydata', '{
  proposals(first: 1000, orderBy: creationBlock, orderDirection: desc) {
    id
    state
    abstainDelegateVotes
    abstainWeightedVotes
    againstDelegateVotes
    againstWeightedVotes
    creationBlock
    description
    executionBlock
    executionETA
    executionTime
    forDelegateVotes
    forWeightedVotes
    quorumVotes
    startBlock
    txnHash
    totalWeightedVotes
    totalDelegateVotes
    tokenHoldersAtStart
  }
}')
      tryCatch({
        # Run query (pull data)
        temp = con$exec(graphql_request$queries$mydata)
        # convert results to JSON
        temp = fromJSON(temp)
        # extract result
        temp = temp$data$proposals
        # add protocol
        temp[, "Protocol"] <- as.character(request_urls[i])
        
        # union data
        data = rbind(data, temp)
      }, error = function(e) {
        # here you can handle the error, e is the error message
        print(paste("Error:", e))
      })
      
    }
    
  })
  
}

# write to csv
write.csv(data, file = paste0("proposals_", format(Sys.Date(), "%Y%m%d"), ".csv"), row.names = FALSE)








