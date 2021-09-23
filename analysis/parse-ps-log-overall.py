#!/bin/python3

# Parse a pystethoscope log given the following fields
#   thread, module, function, state, usec

import json
import os
import sys
from collections import defaultdict
from anytree import Node, RenderTree

if len(sys.argv) != 2:
    print("ERROR: Need the filename")
    sys.exit(1)

log_files = [sys.argv[1]]
in_dir = os.path.dirname(log_files[0])
print("Converting {}".format(log_files))

# categorizations
def classify_function(module_name, function_name):
    combo_tuple = (module_name, function_name)
    if (module_name == "aggr" or
        module_name == "group" or
        "hash" in function_name or #hashing
        combo_tuple == ("mkey", "rotate") or
        combo_tuple == ("algebra", "groupby") or
        combo_tuple == ("bat", "setHash")):
        return "aggregate"
    elif (module_name == "batcalc" or # misc comp
        module_name == "calc" or
        module_name == "pcre" or #regex
        combo_tuple == ("str", "replace") or #regex
        combo_tuple == ("batpcre", "replace") or #regex
        combo_tuple == ("batpcre", "replace_first") or #regex
        combo_tuple == ("algebra", "like") or #regex
        combo_tuple == ("algebra", "not_like") or #regex
        combo_tuple == ("batalgebra", "like") or #regex
        combo_tuple == ("batalgebra", "not_like") or #regex
        module_name == "txtsim" or #textstuff
        module_name == "mmath" or
        combo_tuple == ("algebra", "crossproduct") or
        combo_tuple == ("bat", "isaKey") or
        module_name == "batmmath" or
        module_name == "batstr"):
        return "compute"
    elif (combo_tuple == ("algebra", "thetaselect") or
        combo_tuple == ("algebra", "likeselect") or #regex
        combo_tuple == ("algebra", "select") or
        combo_tuple == ("algebra", "selectNotNil") or
        combo_tuple == ("algebra", "unique")):
        return "filter"
    elif (module_name == "algebra" and "join" in function_name):
        return "join"
    elif (combo_tuple == ("mat", "new") or
        combo_tuple == ("bat", "pack") or
        combo_tuple == ("mat", "pack") or
        combo_tuple == ("mat", "packIncrement") or
        combo_tuple == ("algebra", "firstn") or#limit
        combo_tuple == ("algebra", "difference") or
        combo_tuple == ("algebra", "intersect") or
        combo_tuple == ("bat", "append") or
        combo_tuple == ("bat", "replace") or
        combo_tuple == ("bat", "mirror") or
        combo_tuple == ("bat", "delete") or
        combo_tuple == ("bat", "densebat") or
        combo_tuple == ("bat", "mergecand") or
        combo_tuple == ("bat", "intersectcand") or
        combo_tuple == ("bat", "diffcand")):
        return "materialize"
    elif (combo_tuple == ("algebra", "projectionpath") or
        combo_tuple == ("algebra", "projection") or
        combo_tuple == ("algebra", "project") or
        combo_tuple == ("algebra", "slice") or
        combo_tuple == ("algebra", "subslice")):
        return "project"
    elif (combo_tuple == ("algebra", "sort") or
        combo_tuple == ("bat", "isSorted") or
        combo_tuple == ("bat", "isSortedReverse")):
        return "sort"
    elif module_name == "remote":
        return "remote"

    return "other"

# split file up into all lines that are within a start and end
# this means that the lines are all within one runtime (no multiple parent nodes)
for file_name in log_files:
    print("Analyzing {}".format(file_name))
    section_lines = []
    all_sections = []
    current_scope = None # match on the pc (unique within a scope)
    with open(file_name) as f:
        for line in f:
            json_statement = json.loads(line)
            scope = json_statement["pc"]
            if json_statement["state"] == "start":
                if current_scope == None:
                    current_scope = scope
                section_lines.append(json_statement)
            elif json_statement["state"] == "done":
                if current_scope == scope:
                    section_lines.append(json_statement)
                    all_sections.append(section_lines)
                    section_lines = []
                    current_scope = None
                elif current_scope == None:
                    # just ignore this line
                    print("No matching start. Ignore {}".format(line))
                else:
                    # within the scope but not the final
                    section_lines.append(json_statement)
            else:
                print("ERROR: {}".format(line))
                sys.exit(1)

    print("Split file into {} sections".format(len(all_sections)))

    all_section_nodes = []
    for section_jsons in all_sections:

        #print("Section JSONs: <{}>".format(len(section_jsons)))
        #print(*section_jsons, sep = "\n")

        # this corresponds to a single tree
        global_parent_node = None
        parent_node = None
        for json in section_jsons:
            if json["state"] == "start":
                # either has module,function or is just operator
                name = ""
                if json.get("module") != None and json.get("function") != None:
                    name = json.get("module") + ":" + json.get("function")
                else:
                    name = json.get("operator")
                node = Node(name, start_usec=json.get("usec"), end_usec=0)

                if parent_node:
                    parent_node.children = parent_node.children + (node,)
                    parent_node = node
                else:
                    # no parent node yet
                    parent_node = node
                    global_parent_node = node # keep track of topmost node
            elif json["state"] == "done":
                parent_node.end_usec = json.get("usec")
                parent_node = parent_node.parent # move up the tree
            else:
                print("ERROR: {}".format(json))
                sys.exit(1)

        #print("Tree Print")
        #print(RenderTree(global_parent_node))
        all_section_nodes.append(global_parent_node)

# assume this so that the parsing/aggregating is easy
for section_node in all_section_nodes:
    #print(RenderTree(section_node))
    assert(section_node.depth == 1 or section_node.depth == 0)

# start to categorize it
csv_arr = []
counter = 1
for section_node in all_section_nodes:
    if ("resultSet" in section_node.name) or any(map(lambda x: "resultSet" in x.name, section_node.children)):
        # if tree has resultSet inside then calculate it
        mod_func_usec_dict = defaultdict(int)
        total_time_of_children = 0
        for child in section_node.children:
            mod_func_usec_dict[child.name] += (child.end_usec - child.start_usec)
            total_time_of_children += (child.end_usec - child.start_usec)
        mod_func_usec_dict[section_node.name] = child.end_usec - child.start_usec - total_time_of_children

        # count user.main
        #if "user:main" in mod_func_usec_dict:
        #    del mod_func_usec_dict["user:main"]

        #print("MAL Categorizations and Usec")
        #print("----------------------------")
        cat_usec_dict = defaultdict(int)
        for i in mod_func_usec_dict.items():
            name_list = i[0].split(":")
            if len(name_list) == 1:
                # this is just an operator
                module = "none"
                function = name_list[0]
            else:
                module = name_list[0]
                function = name_list[1]
            usec = i[1]
            category = classify_function(module, function)
            cat_usec_dict[category] += usec
            #print("{:<30} -> {:<15} = {} usec".format(module + "." + function, category, usec))

        #print("\nTotal Usec Per Category")
        #print("-----------------------")
        #for i in cat_usec_dict.items():
        #    print("{:<20} -> {:<10}".format(i[0], i[1]))

        # drop other from pcts
        #print("\n***Dropping other category from categorizations***")
        del cat_usec_dict["other"]

        total = 0
        for i in cat_usec_dict.items():
            total += i[1]

        #print("\nTotal Usec: {} usec".format(total))

        pct = {}
        for i in cat_usec_dict.items():
            pct[i[0]] = i[1] * 100 / total

        # list of tuples (cat, amt)
        pct_list = []
        for i in cat_usec_dict.items():
            pct_list.append((i[0], i[1] * 100 / total))

        for cat in ["aggregate", "compute", "filter", "join", "materialize", "project", "sort"]:
            if cat not in [i[0] for i in pct_list]:
                pct_list.append((cat, 0))

        # make sure this is sorted by the categories
        pct_list.sort()
        if len(csv_arr) == 0:
            stri = "query_num, "
            for i in pct_list:
                stri += "{}, ".format(i[0])
            csv_arr.append(stri[:-2] + "\n")

        #print("\nPercentage Total Time Per Category")
        #print("------------------------------------")
        #for i in pct.items():
        #    print("{:<20} -> {:<10}".format(i[0], i[1]))

        #query_num = os.path.basename(file_name[:-6])
        query_num = str(counter)
        counter += 1
        csv_list = query_num + ", "
        for i in pct_list:
            value = i[1]
            csv_list += "{}, ".format(value)
        csv_arr.append(csv_list[:-2] + "\n")

total_file_csv = in_dir + "/" + "out.csv"
print("Output: {}".format(total_file_csv))
with open(total_file_csv, "w") as f:
    for item in csv_arr:
        f.write(item)

