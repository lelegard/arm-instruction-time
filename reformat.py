#!/usr/bin/env python
#
# Reformat result files into markdown tables for insertion in README.md and CSV for Excel.
#

import os, sys, re, string

# List of CPU cores and corresponding result files.
results = [
    {'core': 'Cortex A72',  'file': 'raspberrypi4_cortex_a72.txt'},
    {'core': 'Neoverse N1', 'file': 'ampere_altra_neoverse_n1.txt'},
    {'core': 'Neoverse V1', 'file': 'aws_graviton3_neoverse_v1.txt'},
    {'core': 'Apple M1',    'file': 'apple_m1.txt'}
]

# List of tables of results.
header = 'Mean instruction time (nanoseconds)'
tables = [
    {'title': 'Ignoring the empty loop time', 'grep': 'loop time ignored', 'data': [[header]]},
    {'title': 'After substracting the empty loop time', 'grep': 'loop time removed', 'data': [[header]]},
]

# Load a result file.
def read_file(corename, filename):

    # Add column title and get number of columns.
    width = 0
    for dat in [e['data'] for e in tables]:
        dat[0].append(corename)
        width = len(dat[0])

    # Load data lines.
    with open(filename, 'r') as input:
        tab = None
        datindex = 1
        for line in input:
            line = line.strip()
            if line.startswith('--'):
                # Header line, switch table.
                for i in range(len(tables)):
                    if line.find(tables[i]['grep']) > 0:
                        tab = tables[i]['data']
                        datindex = 1
                        break
            else:
                # Data line, must contain at least two fields.
                f = re.sub(r' +',' ',line).split(' ')
                if len(f) >= 2:
                    # Check if test name already present.
                    found = False
                    for i in range(datindex, len(tab)):
                        if tab[i][0] == f[0]:
                            datindex = i
                            found = True
                            break
                    if not found:
                        # Insert new header in current position
                        tab.insert(datindex, [f[0]])
                        while len(tab[datindex]) < width - 1:
                            tab[datindex].append('')
                    tab[datindex].append(f[1])
                    datindex += 1

    # Fill empty cells in columns
    for dat in [e['data'] for e in tables]:
        for i in range(1, len(dat)):
            while len(dat[i]) < width:
                dat[i].append('')

# Main code: load all result files.
rootdir = os.path.dirname(os.path.abspath(sys.argv[0]))
for res in results:
    read_file(res['core'], rootdir + '/results/' + res['file'])

# Reformat test names.
for dat in [e['data'] for e in tables]:
    for i in range(1, len(dat)):
        f = dat[i][0].upper().split('_')
        l = len(f) - 1
        if f[l] == 'ALT':
            f[l] = '(alt)'
        elif f[l] == 'DEPREG':
            f[l] = '(dep. regs)'
        elif f[l] == '2':
            f.pop()
            for x in range(len(f), 0, -1):
                f.insert(x, '...')
        dat[i][0] = ' '.join(f)

# Output CSV results.
for tab in tables:
    print()
    print(tab['title'])
    print()
    for line in tab['data']:
        print(','.join(line))

# Output markdown results.
for tab in tables:
    print()
    print('### %s' % tab['title'])
    print()
    dat = tab['data']
    # Compute columns widths.
    width = []
    colnum = len(dat[0])
    for col in range(colnum):
        w = 0
        for line in dat:
            w = max(w, len(line[col]))
        width.append(w)
    # Display lines.
    first = True
    for line in dat:
        for col in range(colnum):
            print('| %-*s ' % (width[col], line[col]), end='')
        print('|')
        if first:
            # Header line
            for w in width:
                if first:
                    ul = ''.center(w, '-')
                    first = False
                else:
                    ul = ':' + ''.center(w-2, '-') + ':'
                print('| %s ' % ul, end='')
            print('|')
