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

import os
import re
import time
from selenium.webdriver.common.action_chains import ActionChains
import ast
import codecs
#%% 
""" Setting up the driver, openning the page """
chromeOptions = webdriver.ChromeOptions()
driver = webdriver.Chrome()
time.sleep(5)
driver.maximize_window()


count = 0
## for line in open('/Users/Anna/Documents/IO field paper/Data/drom-links.txt', "r"):
#driver.get(line)
driver.get('https://www.drom.ru/catalog/kia/rio/185623/')
html = driver.page_source
soup = BeautifulSoup(html, 'lxml') 
table = soup.find('table', {'class': 'b-table'})

rating=""
td = soup.find('div', text='оценка модели')
try:
    td=td.parent.text.strip()
    rating=" ".join(re.split("\s+", td, flags=re.UNICODE))
    rating=rating.rsplit(' ',1)[1]
except AttributeError:
    rating=""

price=""
td = table.find('td', text='Рекомендованная цена новой машины, руб.')
try:
    td=td.findNext('td')
    price=td.text.split('\n',1)[0]
    price=re.sub("\D","",price)
except AttributeError:
	price=""

configuration =""
td = table.find('td', text='Название комплектации')
td=td.findNext('td')
configuration=td.text.strip()

period=""
td=table.find('td', text='Период выпуска')
td=td.findNext('td')
period=td.text.strip()

drive=""
td=table.find('td', text='Тип привода')
td=td.findNext('td')
drive=td.text.strip()

body=""
td=table.find('td', text='Тип кузова')
td=td.findNext('td')
body=td.text.strip()

transmission=""
td=table.find('td', text='Тип трансмиссии')
td=td.findNext('td')
transmission=td.text.strip()

engine=""
td=table.find('td', text='Объем двигателя, куб.см')
td=td.findNext('td')
engine=td.text.strip()

acceleration=""
td=table.find('td', text='Время разгона 0-100 км/ч, с')
td=td.findNext('td')
acceleration=td.text.strip()

clearance=""
td=table.find('td', text='Клиренс (высота дорожного просвета), мм')
td=td.findNext('td')
clearance=td.text.strip()

maxspeed=""
td=table.find('td', text='Максимальная скорость, км/ч')
td=td.findNext('td')
maxspeed=td.text.strip()

country=""
td=table.find('td', text='Страна сборки')
td=td.findNext('td')
country=td.text.strip()

size=""
td=table.find('td', text='Габариты кузова (Д x Ш x В), мм')
td=td.findNext('td')
size=td.text.strip()

wheelbase=""
try:
    td=table.find('td', text='Колесная база, мм')
    td=td.findNext('td')
    wheelbase=td.text.strip()
except AttributeError:
    wheelbase=""

weight=""
try:
    td=table.find('td', text='Масса, кг')
    td=td.findNext('td')
    weight=td.text.strip()
except AttributeError:
    td=table.find('td', text='Допустимая полная масса, кг')
    td=td.findNext('td')
    weight=td.text.strip()

trunk=""
td=table.find('td', text='Объем багажника, л')
td=td.findNext('td')
trunk=td.text.strip()
trunk=" ".join(trunk.split())

horsepower=""
td=table.find('td', text='Максимальная мощность, л.с. (кВт) при об./мин.')
td=td.findNext('td')
horsepower=td.text.strip()

fuelcons_city=""
td=table.find('td', text='Расход топлива в городском цикле, л/100 км')
td=td.findNext('td')
fuelcons_city=td.text.strip()

fuelcons_rural=""
td=table.find('td', text='Расход топлива за городом, л/100 км')
td=td.findNext('td')
fuelcons_rural=td.text.strip()

fuelcons_mix=""
td=table.find('td', text='Расход топлива в смешанном цикле, л/100 км')
td=td.findNext('td')
fuelcons_mix=td.text.strip()

ac=""
try:
    td=table.find('td', text='Кондиционер').findNext('td')
    td=td.svg.use
    td=td['xlink:href']
    if td=="#yes":
        ac=1
    if td=="option":
	    ac=2
except AttributeError:
    ac=0
print(ac)

line1 =str(rating)+";"+ str(price)+";"+str(configuration) +";"+str(period)  +";"+str(drive) +";"+str(body)+";"+str(transmission)+";"+str(engine)+";"+str(acceleration)
line1=line1+";"+str(maxspeed)+";"+str(country)+";"+str(size)+";"+str(wheelbase)+";"+str(weight)+";"+str(trunk)+";"+str(horsepower)+";"+str(ac)

print(line1)
with codecs.open('try.txt', "a", "utf-8") as f:
    f.write('https://www.drom.ru/catalog/kia/rio/185623/ '+line1)
#td=td.text.split('\n',1)[0]
#print(td)
#configuration=td.text.strip()

#print(td)
#td=td.findNext('use')
#print(td)
#td=td['xlink:href']
#if td=="#yes":
#   ac=1
#print(ac)













#outfile = open('drom.txt', "w")
#outfile.write(line)
 