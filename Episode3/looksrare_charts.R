library(readr)
library(here)
library(dplyr)
library(ggplot2)
library(ghql)
library(jsonlite)
library(ggdark)
library(scales)
library(magick)
library(cowplot)
# disable scientific notation
options(scipen=999)
# import looksrare logo to add to plots
looksrare_png = image_read(paste0(here(),"/Episode3/looksrare_logo.png"))

# import data
data = read_csv(paste0(here(),'/Episode3/looksrare_data.csv'))
# view data - observe wash trading cases of large trades back and forth between accounts
View(data)

# Summarize activity between accounts to detect wash trading
maker_taker = data %>% 
  # group by user id on both buy and sell side
  group_by(makerID, takerID) %>% 
  # count transactions for user id combinations
  summarize(count = n(), usd_amount_traded = sum(priceUSD)) %>% 
  # show results with highest counts first
  arrange(desc(count))
# show data - notice how top result is clear wash trading
maker_taker

# Figure out number of trades by user to then find if most of them went to one account
data %<>% 
  # group by user
  group_by(makerID) %>% 
  # count transactions by user
  count() %>% 
  # sort data by most transactions to least
  arrange(desc(n)) %>% 
  # join data to the previous output to compare user transactions to how often they traded with specific users and calculate wash trading flag
  right_join(maker_taker) %>% # if we stopped here we could see legitimate users, like 0xd86e3031447a197cd24e80bf3913c63bd1021451
  # calculate wash trading flag - if more than 40% of trades were between same user, flag account as wash trading
  mutate(wash_trading = case_when((count/n)>0.4 ~ TRUE,
                                  TRUE ~ FALSE)) %>% 
  # now make list of user accounts and whether they are practicing wash trading
  summarize(wash_trading = max(wash_trading)) %>% 
  # join back to the original data
  left_join(data)
# show new dataset with wash trading flag added
data

# compare totals between wash trading and not wash trading
data %>% 
  # group by flag
  group_by(wash_trading) %>% 
  # summarize totals
  summarize(count=n(), usd_volume = sum(priceUSD), avg_price = usd_volume/count)
# observe how those practicing wash trading are paying much more on average 

# summarize data by day
data_daily = data %>% 
  # extract the day from the timestamp
  mutate(day = as.Date(substr(date, 1, 10))) %>% 
  # group by day
  group_by(day, wash_trading) %>% 
  # summarize totals
  summarize(count=n(), usd_volume = sum(priceUSD), avg_price = usd_volume/count) %>% 
  # remove partial data from oldest and most recent dates
  ungroup() %>% 
  filter(day != min(day), day != max(day))
# show data
data_daily


# Visualize data
ggplot(data_daily, aes(day, usd_volume, fill=as.factor(wash_trading))) + 
  geom_area(position = "stack")

# The reason for the drop is a combination of decrease of LOOKS token price, as well as a decrease in the tokens rewarded for trades
# - vesting contract: https://docs.looksrare.org/about/looks-tokenomics
# - can check current rewards here: https://thegraph.com/explorer/subgraph?id=3BKe1G9sy7cFS5SdEMvCWkD5wXoJ7N3pLbrnimMAbuWA&view=Playground
# - in mid-May the amount of LOOKS rewards provided for making trades got cut by almost a third:
read.csv(paste0(here(),'/Episode3/looksrare_rewards_summary.csv'))
# - this compounded with a drop in the price of LOOKS resulted in a lot less wash-trading starting in mid-May 
#(price of LOOKS went from $1.8 in May 5th to less than $0.5 on May 19th)


# Organic volume visualization --------------------------------------------

# Now let's just visualize organic volume
organicc_viz = data_daily %>% 
  # filter out wash trading
  filter(wash_trading == 0) %>% 
  # visualize results
  ggplot(aes(day, usd_volume)) + 
  geom_area(color='#0ac255', size=1.2, fill='#0ac255') + # geom_point(size=0.4, color='white') +
  dark_theme_minimal() +
  ggtitle('LooksRare Daily Trading Volume Excluding Wash Trading',
          subtitle=paste0('From ', min(data_daily$day), ' To ', max(data_daily$day))) +
  ylab('Volume (USD)') +
  xlab('Date') +
  scale_y_continuous(labels=scales::dollar_format())
# add logo
organicc_viz = ggdraw() +
  draw_plot(organicc_viz) +
  draw_image(looksrare_png, x = 0.4, y = 0.36, scale = 0.09)
organicc_viz

# takeaway: if we included wash trading, it would have seemed like the high-point happened at the start of April, but organic traffic high-point was actually right at the start of May


# INTERESTING NEXT STEPS IDEAS:
# - create a breakdown of which collections drove organic volume the most





# NOTES TO SELF:
# - no transaction id. Removed original id and did distinct and went from 200k to 178k
# - for was trading do we also want to account for cases when users are consistently buying multiple assets at much higher than market value? To detect more sophisticated wash trading where they are changing between accounts more frequently



