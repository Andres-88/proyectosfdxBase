import os
import sys
import json
import xml.etree.ElementTree as ET
import zipfile

# # Alias de la Org registrada con SFDX o Usuario que identifica la Org registrada con SFDX
origen = sys.argv[1]

def indent(elem, level=0):
    i = "\n" + level*"  "
    j = "\n" + (level-1)*"  "
    if len(elem):
        if not elem.text or not elem.text.strip():
            elem.text = i + "  "
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
        for subelem in elem:
            indent(subelem, level+1)
        if not elem.tail or not elem.tail.strip():
            elem.tail = j
    else:
        if level and (not elem.tail or not elem.tail.strip()):
            elem.tail = j
    return elem

# Creacion del Archivo XML
root = ET.Element(
    'Package', {'xmlns': 'http://soap.sforce.com/2006/04/metadata'})
for subdir, dirs, files in os.walk('./data'):
    for f in files:
        tipo = f.split('.')
        tipos = ET.SubElement(root, 'types')
        componentes = open('./data/'+f)
        s = componentes.read()
        members = json.loads(s)
        if not isinstance(members, list):
            members = json.loads('['+s+']')
        not_necessary= ['CustomObjectTranslation.json', 'Workflow.json', 'InstalledPackage.json', 'KeywordLis.json', 'ModerationRule.json', 'WebLink.json', 'WorkflowFieldUpdate.json', 'UserCriteria.json', 'SiteDotCom.json', 'SharingRules.json', 'SharingGuestRule.json', 'Report.json','meta.json']
        if not f in not_necessary:
        # if f != 'meta.json'
            for j in members:
                metadata = ET.SubElement(tipos, 'members')
                metadata.text = j['fullName']
            name = ET.SubElement(tipos, 'name')
            name.text = tipo[0]
            componentes.close()

version = ET.SubElement(root, 'version')
version.text = '50.0'
tree = ET.ElementTree(indent(root))
tree.write('package.xml', xml_declaration=True, encoding='utf-8')

########## comentar desde de aqui si solo se busca el XML#################################
os.system("sfdx force:mdapi:retrieve -r ./ -u " + origen + " -k ./package.xml")

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
os.system("sfdx force:mdapi:convert --rootdir ./unpackaged --outputdir ./Salesforce")