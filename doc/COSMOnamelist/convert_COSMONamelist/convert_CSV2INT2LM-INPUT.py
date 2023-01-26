import datetime 
import os

csvFile = './INT2LM_NAMELIST_IBG3_all-IBG3_12km_INT2LMv300.csv'
mapGroups2Filename = {
        '&CONTRL': 'INPUT',
        '&GRID_IN': 'INPUT',
        '&LMGRID': 'INPUT',
        '&DATABASE': 'INPUT',
        '&DATA': 'INPUT',
        '&PRICTR': 'INPUT',
        '&EPSCTL':'INPUT'}

# remove namelists to write to clean files
for group in mapGroups2Filename:
    try:
        os.remove(f'{mapGroups2Filename[group]}')
    except FileNotFoundError:
        pass

tmpNameStr = []
NamelistFileName = 'SomethingWentWrongIfThisNameIsNotChanged'
with open(csvFile) as f:
    lines = f.readlines()
    for line in lines:
        # Remove tailing and leading new line characters as well as spaces
        line = line.strip()
        # Split line along delimiter
        line = line.split(',')
        # Remove tailing and leading " from strings (export google sheets)
        line = [item[1:-1] if item != '' and item[0] == '\"' and item[-1] == '\"' else item for item in line]
        # convert `;`to `,`
        line = [item.replace(';', ',') for item in line]
        # convert "" to '
        line = [item.replace('""', '\'') for item in line]
        # Convert " to empty string. This could occure if the key (line[1]) is
        # a list of values, which comes from google sheet as "1,2,3,4", but 
        # COSMO expect 1,2,3,4
        line = [item.replace('"', '') for item in line]
        # In case of above list join all befor splited key elements
        if len(line) > 2:
            line[1:] = [','.join(line[1:])]
        # Check if new namelist group is starting
        if line[0] in mapGroups2Filename.keys():
            NamelistFileName = mapGroups2Filename[line[0]]
            tmpNameStr.append(f'{line[0]}\n')
        # Check if end of namelist group is reached
        elif line[0] == '/':
            tmpNameStr.append(f'{line[0]}\n')
            # Write naemlist group to file
            with open(NamelistFileName, 'a') as fout:
                fout.writelines(tmpNameStr)
            # Clear tmpNameStr for next namelist group
            tmpNameStr = []
        # Check is key AND value is missing --> ignore
        elif line[0] == '' and line[1] == '':
            continue
        # Check if value is missing --> comment line 
        elif line[1] == '':
            tmpNameStr.append(f'! {line[0]}=,\n')
        # Check if key is missing --> propably multi line entry, add spaces 
        elif line[0] == '':
            tmpNameStr.append(f'    {line[1]},\n')
        # Everything else is valide namelist content
        else:
            tmpNameStr.append(f'{line[0]}={line[1]},\n')
