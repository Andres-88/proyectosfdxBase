import os
import sys
import json
import xml.etree.ElementTree as ET
import zipfile 


print("Empiezo a listar ficheros")
with os.scandir('./') as ficheros:
    for fichero in ficheros:
        print(fichero.name)
print("Termino de listar ficheros")

print("Inicio creacion UNPACKAGED")

with zipfile.ZipFile("./unpackaged.zip", "r") as zip_ref:
    zip_ref.extractall("./")
try:
    if os.listdir('./unpackaged/audience/'):
        os.system('rm -r ./unpackaged/audience/')
except:
    print('audience no existe')
try:
    if os.listdir('./unpackaged/customindex/'):
        os.system('rm -r ./unpackaged/customindex/')
except:
    print('customindex no existe')
try:
    if os.listdir('./unpackaged/uiObjectRelationConfigs/'):
        os.system('rm -r ./unpackaged/uiObjectRelationConfigs/')
except:
    print('uiObjectRelationConfigs no existe')

print("FIN creacion UNPACKAGED")

os.system("sfdx force:mdapi:convert --rootdir ./unpackaged --outputdir ./Salesforce")