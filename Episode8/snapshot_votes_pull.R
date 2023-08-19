# Pull proposals data from endpoints

# NOTE: not sure I finished pulling all for opcollective.eth! Pull again at the end

library(jsonlite)
library(httr)
library(purrr)
library(ghql)
library(readr)
library(dplyr)

  

# connect to the endpoint
con = GraphqlClient$new(
  url = "https://hub.snapshot.org/graphql"
)

last_created = NULL
final_data = NULL
counter = 0

list_protocols = c('aave.eth', 'comp-vote.eth', #'nouns.eth' <- no official snapshot so excluding
                   'gitcoindao.eth', 'ens.eth', 'dydxgov.eth', 'fei.eth', 'hop.eth',
                   'silofinance.eth', 'pooltogether.eth', 'ampleforthorg.eth', 'idlefinance.eth',
                   'gov.radicle.eth', 'unlock-protocol.eth', 'threshold.eth')
# removed/already collected:
#- uniswap
#- opcollective.eth

# NOTE: if a DAO doesn't have all data collected, it will start from the beginning due to how script is designed with the if/else

tryCatch({
  
  for (protocol in list_protocols){
    
      # While loop to ensure all records are extracted
      while (TRUE) {

        counter = counter + 1
        print(counter)
        print(protocol)
        Sys.sleep(0.2) # could enable this just to be safer against rate limiting (although shouldn't be an issue without this)
        
        # initialize a new query
        graphql_request = Query$new()
        
        # construct the query
        if (is.null(last_created)){
          graphql_query = paste0('
            {
              votes (
                first: 1000
                skip: 0
                where: {
                  space: "',protocol,'"
                }
                orderBy: "created",
                orderDirection: desc
              ) {
                id
                voter
                created
                vp
                proposal {
                  id
                }
              }
            }')
        } 
        else {
          graphql_query = paste0('{
    votes (
      first: 1000
      skip: 0
      where: {
        space: "',protocol,'"
        created_lt: ', last_created,'
      }
      orderBy: "created",
      orderDirection: desc
    ) {
      id
      voter
      created
      vp
      proposal {
        id
      }
    }
  }')
        }
        
        graphql_request$query('mydata', graphql_query)
        
        # Run query (pull data)
        temp_data = con$exec(graphql_request$queries$mydata)
        
        # convert results to JSON
        temp_data = fromJSON(temp_data)
        
        # extract results
        temp_data = temp_data$data$votes
        temp_data$proposal_id = temp_data$proposal$id
        
        # rest last created and break the loop if no data returned
        if(length(temp_data) == 0){
          last_created = NULL
          break
        } 
        # drop nested columns (do after break because otherwise this throws an error on that last run)
        temp_data = select(temp_data, -proposal)
        # add protocol
        temp_data$Protocol = protocol
        
        # Append data to the final data
        if(is.null(final_data)){
          final_data = temp_data
        } else {
          final_data = bind_rows(final_data, temp_data)
        }
        
        # Update last token balance for the next iteration
        last_created = tail(temp_data$created, n=1)
        
        print(paste("Rows extracted in total: ", nrow(final_data)))
        
        # every 100 rounds write the data
        if (counter%%101 == TRUE){
          # write to csv after each protocol is done
          write_csv(final_data, file = paste0("snapshot_votes_", format(Sys.Date(), "%Y%m%d"), ".csv"))
        }
    
      } #close while loop for current protocol
    
    
    # write to csv after each protocol is done
    write_csv(unique(final_data), file = paste0("snapshot_votes_", format(Sys.Date(), "%Y%m%d"), ".csv"))

    } # close for loop for all protocols
  
  }) # close tryCatch
  

  






