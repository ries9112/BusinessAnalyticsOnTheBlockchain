# -*- coding: utf-8 -*-
"""
Created on Mon Oct  3 13:22:15 2022

@author: Nehal
"""

import streamlit as st
import pandas as pd
from datetime import datetime
import altair as alt
import numpy as np
from PIL import Image

@st.cache
def load_data():
    datacsv = pd.read_csv("DecentralandTheGraphOpenSea.csv") #To load it from Github
    df = pd.DataFrame(datacsv)
    return df

df = load_data()

df = df.rename(columns={'TokenPrice_USD': 'price_USD'})

# only keep relevant columns
df = df [['x','y', 'transaction_date','price_USD','tokenId']]
    
# Create date field
df['transaction_date'] = pd.to_datetime(df['transaction_date']).dt.date

#### Calculate average price for a given area #### 
# first add columns for ranges for average
df['x_range_min'] = df["x"] - 20 
df['x_range_max'] = df["x"] + 20 
df['y_range_min'] = df["y"] - 20 
df['y_range_max'] = df["y"] + 20 

#Drop Duplicates
df = df.drop_duplicates()

# Create function that calculates the average price
def area_avg_price_fun_eth(x_range_min, x_range_max, y_range_min, y_range_max):
    df_temp = df.loc[(df['x'] >= x_range_min) & (df['x'] <= x_range_max) & (df['y'] >= y_range_min) & (df['y'] <= y_range_max)]
    area_avg_price = df_temp['price_USD'].mean()
    return area_avg_price

df['area_avg_price'] = list(map(area_avg_price_fun_eth,df['x_range_min'],df['x_range_max'],df['y_range_min'],df['y_range_max']))


## Dashboard formatting in Streamlit ##

st.header('Decentraland')
st.subheader("Map - Area Average Price")
st.caption('This map shows us the `area average price (USD)` of Decentraland LAND parcels based on the paramaters selected from the sidebar.')
st.sidebar.subheader("Parameters for the Map")


#Side slider bar
x_range = st.sidebar.slider('X-Coordinate Range', value= [-200, 200])
y_range = st.sidebar.slider('Y-Coordinate Range', value= [-200, 200])

#Min and max values for Transaction Date Range
oldest = df['transaction_date'].min() # Earliest date
latest = df['transaction_date'].max() # Latest date

## Input fields
areaInput = st.sidebar.selectbox('Size of area to calculate `Area Average Price` (shown on map)',('20x20','10x10','50x50','100x100'))
date_transaction_max = st.sidebar.date_input('Max Transaction Date',latest,oldest,latest)
date_transaction_min = st.sidebar.date_input('Min Transaction Date',oldest,oldest,latest)
usd_range = st.sidebar.slider('USD Price Range', value = [0,30000],step = 10)

#Data filtering based on the input data and storing it into a different Dataframe
df_dashboard = df.loc[(df['x'] >= x_range[0]) & (df['x'] <= x_range[1]) & 
            (df['y'] >= y_range[0]) & (df['y'] <= y_range[1]) & 
            (df['transaction_date'] <= date_transaction_max)&
            (df['transaction_date'] >= date_transaction_min)&
            (df['area_avg_price'] >= usd_range[0])&
            (df['area_avg_price'] <= usd_range[1])]

if areaInput == '10x10':
    area = 10
elif areaInput == '20x20':
    area = 20
elif areaInput == '50x50':
    area = 50
else:
    area = 100
    
df_dashboard['x_range_min'] = df["x"] - area 
df_dashboard['x_range_max'] = df["x"] + area 
df_dashboard['y_range_min'] = df["y"] - area 
df_dashboard['y_range_max'] = df["y"] + area 

df_dashboard['area_avg_price'] = list(map(area_avg_price_fun_eth,df_dashboard['x_range_min'],df_dashboard['x_range_max'],df_dashboard['y_range_min'],df_dashboard['y_range_max']))


#Plot Data in a Heatmap for Area Average Price
c = alt.Chart(df_dashboard).mark_circle().encode(
    x='x', 
    y='y', 
    size = alt.Size(scale=alt.Scale(range=[0.1, 0.5])),
    color = alt.Color('area_avg_price', scale=alt.Scale(scheme= 'plasma')),
    tooltip=['x', 'y', 'area_avg_price']).properties(
    width=500,
    height=450).configure_mark(
    size = 10,
    opacity= 0.7
).interactive()
st.altair_chart(c, use_container_width=True)

st.caption('The blank spaces in the above map indicate that land cannot be purchased on the parcels where `Purple` and `Green` colored properties like Vegas City, Aetherian Project, Genesis Plaza.. are located.')


st.subheader("Decentraland Map")
image = Image.open('images/Decentraland_Map.jpg')
st.image(image, width=620)
