# Script to pull rewards per block data
library(ghql)
library(jsonlite)
library(dplyr)

# initialize connection to the subgraph
con = GraphqlClient$new(
  url = "https://gateway.thegraph.com/api/[API-KEY-HERE]/subgraphs/id/3BKe1G9sy7cFS5SdEMvCWkD5wXoJ7N3pLbrnimMAbuWA"
)
# initialize a new query
graphql_request = Query$new()
# make request
graphql_request$query('mydata', '{
  looksRewards(orderBy: id, orderDirection: desc, first:1000){
    looksRewardsPerBlock
    reward{
      timestamp
    }
  }
  }
')
# Run query (pull data)
rewards = con$exec(graphql_request$queries$mydata)
# convert results to JSON
rewards = fromJSON(rewards)
# extract result
rewards = as.data.frame(rewards$data$looksRewards)
# remove row names
rownames(rewards) = NULL
# now union results from for loop
skip = 1000
for (i in 1:90){
  print(skip)
  con = GraphqlClient$new(
    url = "https://gateway.thegraph.com/api/[API-KEY-HERE]/subgraphs/id/3BKe1G9sy7cFS5SdEMvCWkD5wXoJ7N3pLbrnimMAbuWA"
  )
  # initialize a new query
  graphql_request = Query$new()
  # make request
  graphql_request$query('mydata', paste0('{
  looksRewards(orderBy: id, orderDirection: desc, first:1000, skip:',skip,'){
    looksRewardsPerBlock
    reward{
      timestamp
    }
  }
  }
'))
  # Run query (pull data)
  temp = con$exec(graphql_request$queries$mydata)
  # convert results to JSON
  temp = fromJSON(temp)
  # extract result
  temp = as.data.frame(temp$data$looksRewards)
  # remove row names
  row.names(temp) = NULL
  # union datasets
  rewards = union(rewards, temp)
  # increment skip
  skip = skip + 1000
}