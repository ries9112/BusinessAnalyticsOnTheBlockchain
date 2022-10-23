# -*- coding: utf-8 -*-
"""
Created on Wed Sep 21 10:08:03 2022

@author: Nehal
"""

import streamlit as st
import pandas as pd
from datetime import datetime
import altair as alt
import plotly.express as px
import numpy as np
from PIL import Image

def app():
    
    datacsv = pd.read_csv("OpenSeaMetaversesMERGED.csv", encoding= 'unicode_escape') #To load it from Github
    df = pd.DataFrame(datacsv)
    
    ## Dashboard formatting in Streamlit ##
    
    
    st.header("Metaverse Analytics")
    
    
    # Create date field
    df['transaction_date'] = pd.to_datetime(df['transaction_date']).dt.date
    df['transaction_date']=df['transaction_date'].astype('datetime64')
    
    
    MetaverseInput = st.sidebar.selectbox('Select a Metaverse', ('Decentraland','Cryptovoxels','NFT Worlds', 'Somnium Space', 'The Sandbox'))
    
    if MetaverseInput == 'Decentraland':
        metaverse = "Decentraland LAND"
        image = Image.open('images/decentraland.png')
    elif MetaverseInput == 'Cryptovoxels':
        metaverse = "Cryptovoxels Parcel"
        image = Image.open('images/CryptoVoxel1.png')
    elif MetaverseInput == 'NFT Worlds':
        metaverse = "NFT Worlds"
        image = Image.open('images/NFTWorlds.jpg')
    elif MetaverseInput == 'Somnium Space':
        metaverse = "Somnium Space Land"
        image = Image.open('images/SomniumSpace2.png')
    else:
        metaverse = "Sandbox's LANDs"
        image = Image.open('images/the-sandbox-sand-logo.png')
        
    #Data filtering based on the input data and storing it into a different Dataframe
    df_dashboard = df.loc[df['collection'] == metaverse]
    
    
    st.sidebar.image(image, width=200, clamp=True)
    
    
    st.subheader("Floor Sale Prices")
    st.caption('Select a Metaverse from the sidebar to view the `Floor Sale Prices` of land parcels in USD.')
    
    #Chart 1
    fig = px.line(df_dashboard, x="transaction_date", y="dailyMinSalePrice_USD", line_group="collection",
                  hover_data={"transaction_date": "|%B %d, %Y"},
                  labels={"transaction_date":"Transaction Date", "dailyMinSalePrice_USD": "Daily Minimum Sale Price ($)"})
    
    
    fig.update_xaxes(
        showgrid=False,
        tickformat="%b %d\n%Y",
        rangeslider_visible=True,
        rangeselector= dict(
            buttons=list([
                dict(count=1, label="1d", step="day", stepmode="backward"),
                dict(count=7, label="7d", step="day", stepmode="backward"),
                dict(count=1, label="1m", step="month", stepmode="backward"),
                dict(count=3, label="3m", step="month", stepmode="backward")
            ])
        )
        )
    
    # update
    fig.update_layout(template='plotly_dark',
                  xaxis_rangeselector_font_color='black',
                  xaxis_rangeselector_activecolor='red',
                  xaxis_rangeselector_bgcolor='green',
                  xaxis=dict(
                      #autorange=True,
                      range=["2022-07-01", "2022-09-30"],
                      rangeslider=dict(
                          #autorange=True,
                          range=["2022-07-01", "2022-09-30"]
                          ),
                      type="date"
                      ),
                  yaxis=dict(
                      autorange=True,
                      #range=[0, 11000]
                      ),
                  yaxis_tickprefix = '$',
                  height=600,
                  width =500
                 )
    
    st.plotly_chart(fig, use_container_width=True)
    
    st.subheader("Daily Trade Volume")
    st.caption('Select a Metaverse from the sidebar to view the `Daily Trade Volume` of land parcels in USD.')
    
    #Chart 2
    fig1 = px.line(df_dashboard, x="transaction_date", y="DailyTradeVolumeUSD", line_group="collection",
                  hover_data={"transaction_date": "|%B %d, %Y"},
                  labels={"transaction_date":"Transaction Date", "DailyTradeVolumeUSD": "Daily Trade Volume ($)"})
    
    fig1.update_xaxes(
        showgrid=False,
        tickformat="%b %d\n%Y",
        rangeslider_visible=True,
        rangeselector= dict(
            buttons=list([
                dict(count=1, label="1d", step="day", stepmode="backward"),
                dict(count=7, label="7d", step="day", stepmode="backward"),
                dict(count=1, label="1m", step="month", stepmode="backward"),
                dict(count=3, label="3m", step="month", stepmode="backward")
            ])
        )
        )
    
    # update
    fig1.update_layout(template='plotly_dark',
                  xaxis_rangeselector_font_color='black',
                  xaxis_rangeselector_activecolor='red',
                  xaxis_rangeselector_bgcolor='green',
                  xaxis=dict(
                      range=["2022-07-01", "2022-09-30"],
                      rangeslider=dict(
                          #autorange=True,
                          range=["2022-07-01", "2022-09-30"]
                          ),
                      type="date"
                      ),
                  yaxis=dict(
                      autorange=True,
                      ),
                  yaxis_tickprefix = '$',
                  height=600,
                  width =500
                 )
    
    st.plotly_chart(fig1, use_container_width=True)
