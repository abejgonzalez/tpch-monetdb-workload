#!/bin/python3

# Parse a pystethoscope log given the following fields
#   thread, module, function, state, usec

import json
import os
import sys
from collections import defaultdict

file_name = sys.argv[1]

all_lines = []

current_sql_num = 1
with open(file_name) as f:
    for line in f:
        json_statement = json.loads(line)

        # parse the line and only keep if the state is "done"
        if json_statement["state"] == "done" and json_statement.get("operator", "") == "end":
            all_lines.append(line)

            #print(line)
            #print("Checking if can write")

            # write out current file (only if the json statement has a resultSet)
            found = False
            for item in all_lines:
                if "resultSet" in item:
                    found = True

            if found:
                with open(os.path.dirname(file_name) + "/" + "{}.s.log".format(current_sql_num), "w") as wf:
                    for item in all_lines:
                        wf.write(item)

                #print("Wrote to file")

                # increment the file number (i.e. sql number 1->22)
                current_sql_num += 1

            # clear all lines
            all_lines = []
        else:
            #print("Not End Line: {}".format(line))
            all_lines.append(line)
            #print("{} Lines to write".format(len(all_lines)))
