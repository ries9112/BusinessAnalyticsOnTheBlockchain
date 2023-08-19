# Pull proposals data from endpoints

# NOTE: not sure I finished pulling all for opcollective.eth! Pull again at the end

library(jsonlite)
library(httr)
library(purrr)
library(ghql)
library(readr)
library(dplyr)


# import data
governance_frameworks = read_csv('governance_framework_info_20230626.csv')


# connect to the endpoint
con = GraphqlClient$new(
  url = "https://gateway.thegraph.com/api/391c2df32bde87775f17c67aa78e45e5/subgraphs/id/D7azkFFPFT5H8i32ApXLr34UQyBfxDAfKoCEK4M832M6"
)

final_data = NULL
counter = 0

# removed/already collected:
#- uniswap
#- opcollective.eth

# NOTE: if a DAO doesn't have all data collected, it will start from the beginning due to how script is designed with the if/else

tryCatch({
  
  for (token in unique(governance_frameworks$tokenAddress)){
      
    counter = counter + 1
    print(counter)
    print(token)
    Sys.sleep(0.2) # could enable this just to be safer against rate limiting (although shouldn't be an issue without this)

    # initialize a new query
    graphql_request = Query$new()

    # construct the query
    graphql_query = paste0('
            {
        tokenDayDatas(
          where: {token: "', token ,'"}
          orderBy: date
          orderDirection: desc
          first: 1000
        ) {
          priceUSD
          date
          id
          token {
            id
            name
            symbol
          }
          volumeUSD
          liquidityUSD
          }
      }')

    graphql_request$query('mydata', graphql_query)

    # Run query (pull data)
    temp_data = con$exec(graphql_request$queries$mydata)

    # convert results to JSON
    temp_data = fromJSON(temp_data)

    # extract results
    temp_data = temp_data$data$tokenDayDatas

    # add protocol
    temp_data$Protocol = filter(governance_frameworks, tokenAddress == token)$name
    temp_data$symbol =  temp_data$token$symbol
    # drop nested columns
    if(length(temp_data) != 1){
      temp_data = select(temp_data, -token)
    }

    # Append data to the final data
    if(is.null(final_data)){
      final_data = temp_data
    } else {
      final_data = bind_rows(final_data, temp_data)
    }

    print(paste("Rows extracted in total: ", nrow(final_data)))
    
    
    # write to csv after each protocol is done
    write_csv(unique(final_data), file = paste0("token_prices_", format(Sys.Date(), "%Y%m%d"), ".csv"))
    
  } # close for loop for all protocols
  
}) # close tryCatch









