# -*- coding: utf-8 -*-
"""
Created on Mon Oct  3 13:22:13 2022

@author: Nehal
"""

import os
import streamlit as st

#Custom Imports
from multipage import MultiPage
from pagesOCT import Decentraland_OCT,MetaverseSummaryGraph_OCT

# Create an instance of the app 
app = MultiPage()

# Add all your application here
app.add_page("Decentraland Map", Decentraland_OCT.app)
app.add_page("Metaverse Analytics", MetaverseSummaryGraph_OCT.app)


# The main app
app.run()
