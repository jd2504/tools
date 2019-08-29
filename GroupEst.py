#
# import csv, sys
# reader = csv.DictReader(open(sys.argv[1]))
# idDict = {}
#
# for row in reader:
#    if not idDict.has_key(row["Contract ID"]):
#       idDict[row["Contract ID"]] = {}
#    idDict[row["Contract ID"]][row["Internet Site"]] = None
#
# keys = [k for k in idDict.keys() if len(idDict[k]) == 1]
# keys.sort()
#
# for k in keys:
#    print "\t".join((k,idDict[k].keys()[0]))
#
# All of the rest of it is to make it robust and more usable.
#

import csv, sys, getopt

USAGE="""python GroupEstimates.py [-h] [-d delimiter] [-s site] [-o file] file.csv
where:
-h		Print a header on output
-d delimiter	Set the delimiter. Default is ",". "tab" sets
		the delimiter to an ASCII tab character.
-o file		Write the output to the given file
-s site		Limit output to the given Internet site
A single file argument is required. The file must be a CSV file.
"""

gDelimiter = ","
gPrintHeader = False
gSite = None

ofp = sys.stdout
errflag = False

#
# Process command line arguments
#

opts, args = getopt.getopt(sys.argv[1:], "d:s:o:h")

for k, v in opts:
    if k == "-d":                       # Set the delimiter
        if v == "tab":
            v = "\t"

        gDelimiter = v
    elif k == "-h":                     # Print a header
        gPrintHeader = True
    elif k == "-o":                     # Output file
        try:
            ofp = open(v,"w")
        except:
            sys.stderr.write("Can't open %s for writing\n" % v)
            errflag = True
    elif k == "-s":
        gSite = v.upper()
    else:                               # Invalid option
        sys.stderr.write("Unknown option: %s" % k)
        errflag = True

#
# Make sure we were given a file argument
#

if len(args) != 1:
    sys.stderr.write("Required file argument not provided\n")
    errflag = True

if not errflag:
    #
    # Try to open the file
    #

    try:
        f = open(args[0])
    except:
        sys.stderr.write("Couldn't open CSV file %s\n" % args[0])
        errflag = True

#
# If something went wrong, print a usage message and exit
#

if errflag:
    sys.stderr.write(USAGE)
    sys.exit(1)

reader = csv.DictReader(f, delimiter=gDelimiter)

idDict = {}

#
# Read in each row from the CSV, as a dictionary
#

for row in reader:
    try:
        contractID = row["Capture ID"]
    except:
        sys.stderr.write("Couldn't find Capture ID in row. Check the delimiter.\n")
        sys.exit(1)

    siteID = row["Internet Site"]

    if not idDict.has_key(contractID):
        #
        # This is one we haven't seen before
        #

        idDict[contractID] = {}

    #
    # Add this site to the per-contractID dictionary of sites
    #

    idDict[contractID][siteID] = None

#
# Grab the keys for all of the contract IDs that have only one site
#

keys = [k for k in idDict.keys() if len(idDict[k]) == 1]

if gPrintHeader:
    print "Capture ID\tInternet Site"

#
# Order them by contract ID
#

keys.sort()


for k in keys:

    #
    # For each contract ID that's only associated with one Internet
    # site, print the ID and the site
    #

    site = idDict[k].keys()[0]

    if gSite is None or gSite == site.upper():
        ofp.write("%s\t%s\n" % (k, site))

sys.exit(0)
