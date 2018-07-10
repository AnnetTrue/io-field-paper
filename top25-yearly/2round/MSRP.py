from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.by import By
from selenium.webdriver import Chrome
from selenium.webdriver.support.ui import Select
from bs4 import BeautifulSoup, SoupStrainer
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
from selenium.common.exceptions import NoSuchElementException
from selenium.common.exceptions import StaleElementReferenceException
from selenium.common.exceptions import WebDriverException
from selenium.common.exceptions import NoSuchWindowException
import pandas as pd
import numpy as np
import os
import re
import time
from selenium.webdriver.common.action_chains import ActionChains
import ast
#%% 
""" Setting up the driver, openning the page """
chromeOptions = webdriver.ChromeOptions()
driver = webdriver.Chrome('F:\chromedriver.exe')
driver.maximize_window()
driver.get('http://www.motortrend.com/cars/')
html = driver.page_source
soup = BeautifulSoup(html)

#%%
""" Getting MSRP """

count = 0
for line in open('Models-IMCDB1.txt', "r"):
    count += 1
    if count > 7:
        delim = line.find(";")
        make = line[0:delim]
        delim1 = line.find(";",delim+1)
        value = int(line[delim+1:delim1])
        delim = line.find(";",delim1+1)
        model = line[delim1+1:delim]
        delim1 = line.find(";",delim+1)
        model_value = int(line[delim+1:delim1])
        delim = line.find(";",delim1+1)
        year_min = line[delim1+1:delim]
        delim1 = line.find(";",delim+1)
        year_max = line[delim+1:delim1]
        driver.get('http://www.motortrend.com/cars/')
        wait = WebDriverWait(driver, 5)
        while True:
            try:
                dropdown = driver.find_element_by_css_selector("main#main section.mod-cars-browse-by-search > div > form > label.label.-make > select")
                Select(dropdown).select_by_visible_text(make)
                model_dropdown = driver.find_element_by_css_selector("main#main section.mod-cars-browse-by-search > div > form > label.label.-model > select")
                Select(model_dropdown).select_by_visible_text(model)
                driver.find_element_by_css_selector("main#main section.mod-cars-browse-by-search > div > form > button[type='submit']").click()                
                break
            except NoSuchElementException:
                with open('Buyer_Guide_links.txt', "a") as f:
                    f.write(line[0:len(line)-1]+"; No MSRP available\n")
                break
            except WebDriverException:
                chromeOptions = webdriver.ChromeOptions()
                driver = webdriver.Chrome('F:\chromedriver.exe')
                driver.maximize_window()
                driver.get('http://www.motortrend.com/cars/')
        
        html = driver.page_source
        soup = BeautifulSoup(html)
        select_yr = soup.find_all('li',{'class':'year-item'})
        for yr in select_yr:
            year = yr.text
            delim = year.find("20")
            if delim == -1:
                delim = year.find("19")
            year = year[delim:delim+4]
            if year >= year_min and year <= year_max:
                link = yr.find('a',href = True)['href']
                with open('Buyer_Guide_links.txt', "a") as f:
                    f.write(line[0:len(line)-1]+";"+year+";"+link+"\n")
            
        
 #%%
        """ Divide between Fail to find and Success """
        
        """ Note that all MSRP found for >= 2014 only! - check site for later in search for brand """
        
for line in open('Buyer_Guide_links.txt', "r"):
    delim = line.find("; No MSRP available")
    if delim == -1:
       with open('Buyer_Guide_links-Success.txt', "a") as f:
           f.write(line) 
    else:
       with open('Buyer_Guide_links-Fail.txt', "a") as f:
           f.write(line[0:delim]+"\n") 
      
#%%
""" Removing duplicating links """
lines_seen = set() # holds lines already seen
outfile = open('Buyer_Guide_links-Success-unique.txt', "w")
for line in open('Buyer_Guide_links-Success.txt', "r"):
    if line not in lines_seen: # not a duplicate
        outfile.write(line)
        lines_seen.add(line)
outfile.close()
#%%
""" Leave links to models only """
count = 0
for line in open('Buyer_Guide_links-Success-unique.txt', "r"):
    count += 1
    if count > 0:
        delim = line.find(";")
#        make = line[0:delim]
        delim1 = line.find(";",delim+1)
#        value = int(line[delim+1:delim1])
        delim = line.find(";",delim1+1)
#        model = line[delim1+1:delim]
        delim1 = line.find(";",delim+1)
#        model_value = int(line[delim+1:delim1])
        delim = line.find(";",delim1+1)
#        year_min = line[delim1+1:delim]
        delim1 = line.find(";",delim+1)
        line1 = line[0:delim1]
#        year_max = line[delim+1:delim1]
        delim = line.find(";",delim1+1)
#        year_guide = line[delim1+1:delim]
        delim1 = line.find("20",delim+1)
        line = line1 + line[delim:delim1] + "\n"
        with open('Buyer_Guide_links-Success-models.txt', "a") as f:
           f.write(line)

""" Removing duplicating links """
lines_seen = set() # holds lines already seen
outfile = open('Buyer_Guide_links-Success-models_unique.txt', "w")
for line in open('Buyer_Guide_links-Success-models.txt', "r"):
    if line not in lines_seen: # not a duplicate
        outfile.write(line)
        lines_seen.add(line)
outfile.close()

#%%
""" Checking for all year buyers' guides """
count = 0
for line in open('Buyer_Guide_links-Success-models_unique.txt', "r"):
    count += 1
    if count > 0:
        delim = line.rfind(";")
        link = line[delim+1:len(line)-1]
        delim1 = line.rfind(";",0,delim)
        year_max = line[delim1+1:delim]
        delim = line.rfind(";",0,delim1)
        year_min = line[delim+1:delim1]
        for yr in range(int(year_min),int(year_max)+1):
            link1 = link+str(yr)+"/\n"
            with open('Buyer_Guide_links-Success-models-ALL-Possible.txt', "a") as f:
                f.write(line[0:line.rfind(";")+1]+str(yr)+";"+link1)

count = 0
for line in open('Buyer_Guide_links-Success-models-ALL-Possible.txt', "r"):
    count += 1
    if count >= 1659:
      delim = line.rfind(";")
      link = line[delim+1:len(line)-1]
      while True:
        try:  
          driver.get(link)
          html = driver.page_source
          soup = BeautifulSoup(html)
          head = soup.find("h1",{"class":"page-title"})
          if head == None or "Oops" not in head.text:
              with open('Buyer_Guide_links-Success-models-ALL-working.txt', "a") as f:
                  f.write(line) 
          break
        except TimeoutException:
                driver.refresh()
        except WebDriverException:
                chromeOptions = webdriver.ChromeOptions()
                driver = webdriver.Chrome('F:\chromedriver.exe')
                driver.maximize_window()
#%%
count = 0
for line in open('Buyer_Guide_links-Success-models-ALL-working.txt', "r"):
    count += 1
    if count > 1431 and count <= 1435:   #622, 1191-1195 1431-1435 was broken link!
        d = line.find("http")
        link= line[d:len(line)-1]
        while True:  # Отладить с таймаутом!!!
            try:
              driver.get(link)
              html = driver.page_source
              soup = BeautifulSoup(html) 
              oops = soup.find_all('h1',{'class':'page-title'})
              f = False
              for i in oops:
                if "Oops! That page can't be found" in i.text:
                    f = True     
              if f == True:
                with open('oops.txt', "a") as f:
                                f.write(line)
              else:
                                
                price = soup.find_all('span',{'class':'price-label'})
                msrp = ""  # Getting price
                if price == None:
                    driver.close()
                    chromeOptions = webdriver.ChromeOptions()
                    driver = webdriver.Chrome('F:\chromedriver.exe')
                    driver.maximize_window()     
                else:
                    for i in price:
                        if "Manufacturer's Suggested Retail" in i.text:
                            p = i.parent.next_sibling.next_sibling
                            if p != None:
                                msrp = p.text.encode('utf8','replace')
                char = soup.find_all('div',{'class':'key'})
                engine = ""
                transmission = ""
                trim = ""
                car_class = ""
                horsepower = ""
                mpg = ""
                body_style = ""
                drivetrain = ""
                fuel_type = ""
                seat_cap = ""
                if char != None:
                  for i in char:
                    if "Engine Name" in i.text:
                        engine = i.next_sibling.text.encode('utf8','replace').replace("\t","").replace(chr(10),"")
                    if "Transmission Name" in i.text:
                        transmission = i.next_sibling.text.encode('utf8','replace').replace("\t","").replace(chr(10),"")
                    if "Trim" in i.text:
                        trim = i.next_sibling.text.encode('utf8','replace').replace("\t","").replace(chr(10),"")   
                    if "Class" in i.text:
                        car_class = i.next_sibling.text.encode('utf8','replace').replace("\t","").replace(chr(10),"")
                    if "Horsepower" in i.text:
                        horsepower = i.next_sibling.text.encode('utf8','replace').replace("\t","").replace(chr(10),"").replace(chr(32),"")
                    if "Standard MPG" in i.text:
                        mpg = i.next_sibling.text.encode('utf8','replace').replace("\t","").replace(chr(10),"").replace(chr(32),"")
                        delim = mpg.find("City/")
                        mpg_city = mpg[0:delim]
                        mpg_hwy = mpg[mpg.find("/",delim+1)+1: mpg.find("Hwy")] 
                    if "Body Style" in i.text:
                        body_style = i.next_sibling.text.encode('utf8','replace').replace("\t","").replace(chr(10),"")
                    if "Drivetrain" in i.text:
                        drivetrain = i.next_sibling.text.encode('utf8','replace').replace("\t","").replace(chr(10),"")
                    if "Fuel Type" in i.text:
                        fuel_type = i.next_sibling.text.encode('utf8','replace').replace("\t","").replace(chr(10),"")
                    if "Seating Capacity" in i.text:
                        seat_cap = i.next_sibling.text.encode('utf8','replace').replace("\t","").replace(chr(10),"")
                
                accel = ""
                char = soup.find_all('span',{'itemprop':'name'})
                if char != None:
                  for i in char:
                    
                    if "0-60 MPH" in i.text:
                        accel =  i.parent.next_sibling.next_sibling.text.encode('utf8','replace').replace("\t","").replace(chr(10),"").replace(chr(32),"")
                rating = ""
                char = soup.find('div',{'class':'bold rating list-in'})
                if char != None:
                    rating = char.text.encode('utf8','replace').replace("\t","").replace(chr(10),"").replace(chr(32),"")
                    delim = rating.find("/")
                    rating = rating[delim-1:delim+2]
                safety = ""
                char = soup.find_all('h3',{'class':'title'})  
                if char != None:      
                    for i in char:
                        if "Safety" in i.text:
                            temp = i.next_sibling.next_sibling.text
                            safety = 0
                            for j in range(0,len(temp)):
                                if temp[j] == u'★':
                                    safety += 1
                line1 = msrp+";"+engine +";"+transmission+";"+trim+";"+car_class+";"+horsepower+";"+mpg+";"+body_style+";"+drivetrain+";"+fuel_type+";"+seat_cap+";"+accel+";"+rating+";"+str(safety)+"\n"
                while line1 == ";;;;;;;;;;;;;\n":
                    driver.refresh()
                    
                with open('MSRP_Char.txt', "a") as f:
                        f.write(line[0:d]+line1)
              break        
            except TimeoutException:
                chromeOptions = webdriver.ChromeOptions()
                driver = webdriver.Chrome('F:\chromedriver.exe')
                driver.maximize_window()  
            except NoSuchWindowException:
                chromeOptions = webdriver.ChromeOptions()
                driver = webdriver.Chrome('F:\chromedriver.exe')
                driver.maximize_window()  
            except WebDriverException:
                chromeOptions = webdriver.ChromeOptions()
                driver = webdriver.Chrome('F:\chromedriver.exe')
                driver.maximize_window()  


#%%
char = soup.find_all('div',{'class':'key'})
engine = ""
transmission = ""
trim = ""
car_class = ""
horsepower = ""
mpg = ""
body_style = ""
drivetrain = ""
fuel_type = ""
seat_cap = ""

for i in char:
    if "Engine Name" in i.text:
        engine = i.next_sibling.text
    if "Transmission Name" in i.text:
        transmission = i.next_sibling.text
    if "Trim" in i.text:
        trim = i.next_sibling.text        
    if "Class" in i.text:
        car_class = i.next_sibling.text
    if "Horsepower" in i.text:
        horsepower = i.next_sibling.text
    if "Standard MPG" in i.text:
        mpg = i.next_sibling.text
    if "Body Style" in i.text:
        body_style = i.next_sibling.text
    if "Drivetrain" in i.text:
        drivetrain = i.next_sibling.text
    if "Fuel Type" in i.text:
        fuel_type = i.next_sibling.text
    if "Seating Capacity" in i.text:
        seat_cap = i.next_sibling.text  
#%%
accel = ""
char = soup.find_all('span',{'itemprop':'name'})
for i in char:
    
        if "0-60 MPH" in i.text:
            accel =  i.parent.next_sibling.next_sibling.text
#%%
rating = ""
char = soup.find('div',{'class':'bold rating list-in'})
if char != None:
    rating = char.text
    delim = rating.find("/")
    rating = rating[delim-1:delim+2]

#%%
safety = ""
char = soup.find_all('h3',{'class':'title'})  
if char != None:      
    for i in char:
        if "Safety" in i.text:
            temp = i.next_sibling.next_sibling.text
            safety = 0
            for j in range(0,len(temp)):
                if temp[j] == u'★':
                    safety += 1 
#%%
count = 0
for line in open('MSRP_Char.txt', "r"):
    count += 1   
    if count > 0:    
        delim = line.rfind(";")
        delim1 = line[0:delim].rfind(";")
        rating = line[delim1+1:delim]
        rating = rating[0:rating.find("/")]
        delim2 = line[0:delim1].rfind(";")
        delim3 = line[0:delim2].rfind(";")
        capacity = line[delim3+1:delim2]
        capacity_max = capacity[0:capacity.find("/")]
        capacity = capacity[capacity.find("/")+1:len(capacity)]
        line2 = line[0:delim3+1] + capacity + ";" + capacity_max + line[delim2:delim1+1]+ rating + "\n"

        with open('MSRP_Char_1.txt', "a") as f:
                        f.write(line2)
#%%
df1 = pd.read_csv("MSRP_Char-3-1.csv")
#%%
df.to_csv("MSRP_Char-2.csv")
#%% Cyllinder

for i in range(0,len(df)):
#for i in range(0,1):
    engine = str(df.engine[i])
    if engine != 'nan':
        
        if engine.find("4-Cyl") != -1:
            df.cyl[i] = 4
        if engine.find("5-Cyl") != -1:
            df.cyl[i]  = 5
        if engine.find("6-Cyl") != -1:
            df.cyl[i]  = 6
        if engine.find("3-Cyl") != -1:
            df.cyl[i]  = 3
        if engine.find("V6") != -1:
            df.cyl[i]  = 6
        if engine.find("V8") != -1:
            df.cyl[i]  = 8    
        if engine.find("V10") != -1:
            df.cyl[i]  = 10    
        if engine.find("W12") != -1:
            df.cyl[i]  = 12   
#        if engine.find("Single Electric") != -1:
#            df.cyl = 4      
#        if engine.find("Double Electric") != -1:
#            df.cyl = 4    
#        if engine.find("AC electric") != -1:
#            df.cyl = 4           
#        
#%% Engine Volume

for i in range(0,len(df)): #start with i at which stopped
#for i in range(0,1):
    engine = str(df.engine[i])
    if engine != 'nan':
        delim = engine.find(" Liter")
        if delim != -1:
            df.volume[i] = engine[delim-4:delim]
            
#%%
for i in range(0,len(df)): #start with i at which stopped
#for i in range(0,1):
    hp = str(df.hp[i])
    if hp != 'nan':
        delim = hp.find("@")
        if delim != -1:
            df.hp[i] = hp[0:delim]        

#%%
for i in range(0,len(df)): #start with i at which stopped
#for i in range(0,1):
    mpg = str(df.mpg[i])
    if mpg != 'nan':
        delim = mpg.find("City/")
        delim2 = mpg.find("Hwy")
        if delim != -1:
            df.mpg[i] = mpg[0:delim] + "*" + mpg[delim+4:delim2] 


#%%
df = pd.read_csv("size-tbd.csv")
#%%
for i in range(0,len(df)):
    car_name = df.make[i] + "_" + df.model[i]
    with open('size-names.txt', "a") as f:
        f.write(car_name+'\n')
    
#%%    
count = 0
for line in open('size-names.txt', "r"):
  count += 1   
  if count > 0:        
    link = "https://en.wikipedia.org/wiki/" + line[0:len(line)-1]
    car_class = ""
    
    while True:
            try:
              driver.get(link)
              html = driver.page_source
              soup = BeautifulSoup(html) 
              
              table = soup.tbody
              
              if table != None:
                 for row in table.find_all(lambda tag: tag.name=='tr'):
                     for cell in row.find_all(lambda tag: tag.name=='th'):
#
                            if "Class" in cell.text and "-Class" not in cell.text:

                                car_class = cell.next_sibling.next_sibling.text.encode('utf-8','replace').replace('\t',' ').replace('\n',' ')

              with open('size-names-1.txt', "a") as f:
                  f.write(line[0:len(line)-1]+";"+car_class+'\n')               
              
              break        
            except TimeoutException:
                chromeOptions = webdriver.ChromeOptions()
                driver = webdriver.Chrome('F:\chromedriver.exe')
                driver.maximize_window()  
            except NoSuchWindowException:
                chromeOptions = webdriver.ChromeOptions()
                driver = webdriver.Chrome('F:\chromedriver.exe')
                driver.maximize_window()  

#%%
count = 0
for line in open('size-names-1.txt', "r"):
  delim = line.find(";")
  df.class_W[count] = line[delim+1:len(line)-1]
  count += 1 

#%%
df1.to_csv("MSRP_Char-3-1.csv")
#%%
for i in range(0,len(df1)):
    for j in range(0,len(df)):
        if df1.make[i] == df.make[j] and df1.model[i] == df.model[j]:
           df1.class_W[i] = df.class_W[j]












        