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
#%% 
""" Setting up the driver, openning the page """
chromeOptions = webdriver.ChromeOptions()
driver = webdriver.Chrome()
time.sleep(5)
driver.maximize_window()


count = 0
## for line in open('/Users/Anna/Documents/IO field paper/Data/drom-links.txt', "r"):
    #driver.get(line)
driver.get('https://www.drom.ru/catalog/kia/cee~d/178852/')
html = driver.page_source
soup = BeautifulSoup(html, 'lxml') 
table = soup.find('table', {'class': 'b-table'})

td=table.find('td', text='Ключ ДУ (дистанционный ключ)')
td=td.findNext('td')
print('td')


td = table.find('td', text='Название комплектации')
td=td.findNext('td')
configuration=td.text.strip()

td=table.find('td', text='Период выпуска')
td=td.findNext('td')
period=td.text.strip()

td=table.find('td', text='Тип привода')
td=td.findNext('td')
drive=td.text.strip()

td=table.find('td', text='Тип кузова')
td=td.findNext('td')
body=td.text.strip()

td=table.find('td', text='Тип трансмиссии')
td=td.findNext('td')
transmission=td.text.strip()

td=table.find('td', text='Объем двигателя, куб.см')
td=td.findNext('td')
engine=td.text.strip()

td=table.find('td', text='Время разгона 0-100 км/ч, с')
td=td.findNext('td')
acceleration=td.text.strip()

td=table.find('td', text='Клиренс (высота дорожного просвета), мм')
td=td.findNext('td')
clearance=td.text.strip()

td=table.find('td', text='Максимальная скорость, км/ч')
td=td.findNext('td')
maxspeed=td.text.strip()

td=table.find('td', text='Страна сборки')
td=td.findNext('td')
country=td.text.strip()

td=table.find('td', text='Габариты кузова (Д x Ш x В), мм')
td=td.findNext('td')
size=td.text.strip()

td=table.find('td', text='Колесная база, мм')
td=td.findNext('td')
wheelbase=td.text.strip()

td=table.find('td', text='Масса, кг')
td=td.findNext('td')
weight=td.text.strip()

td=table.find('td', text='Объем багажника, л')
td=td.findNext('td')
trunk=td.text.strip()

td=table.find('td', text='Максимальная мощность, л.с. (кВт) при об./мин.')
td=td.findNext('td')
horsepower=td.text.strip()

td=table.find('td', text='Расход топлива в городском цикле, л/100 км')
td=td.findNext('td')
fuelcons_city=td.text.strip()

td=table.find('td', text='Расход топлива за городом, л/100 км')
td=td.findNext('td')
fuelcons_rural=td.text.strip()

td=table.find('td', text='Расход топлива в смешанном цикле, л/100 км')
td=td.findNext('td')
fuelcons_mix=td.text.strip()







line1 = str(configuration) +";"+str(period)  +";"+str(drive) +";"+str(body)+";"+str(transmission)+";"+str(engine)+";"+str(acceleration)
line1=line1+";"+str(maxspeed)+";"+str(country)+";"+str(size)+";"+str(wheelbase)+";"+str(weight)+";"+str(trunk)+";"+str(horsepower)
print(line1)

#outfile = open('drom.txt', "w")
#outfile.write(line)
 