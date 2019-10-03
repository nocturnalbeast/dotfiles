#!/usr/bin/env python2
import re, sys, json

# the color names, with indexes as the respective color numbers
list_colors = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "grey", "dark_black", "bright_red", "bright_green", "bright_yellow", "bright_blue", "bright_magenta", "bright_cyan", "white"]
# pretty printing column offsets for the i3 color section
i3_pprint_offsets = [7, 14, 7]
termite_pprint_offset = 17

# in the case there aren't enough arguments, or if there are too much of them
if len(sys.argv) != 3:
	print "Incorrect usage.\n" + "Usage: python2 theme-gen.py [path-to-xresources-file] [format-to-generate]\n" + "Formats supported: json, i3, termite\n"
	exit(1)

# now if we have all the arguments we need, then we can proceed
else:

	# open the file and read the lines into a list
	with open(sys.argv[1]) as xres_file:
		xres_lines = xres_file.readlines()

	# initialize an empty dictionary
	dict_colors = dict()

	# filter and process the lines with a little bit of regex and splicing, and enter the processed entries into the dictionary
	for line in xres_lines:
		if re.match(r"^\*\.color|^\*\.foreground|^\*\.background|^\*\.cursorColor", line):
			proc_line = line[2:].translate(None, ' \n').partition(':')[::2]
			#if re.match(r"^color", proc_line[0]):
			#	proc_line = (int(proc_line[0][5:]), proc_line[1])
			dict_colors.update({proc_line[0]:proc_line[1]})

	# if the output format is json, just dump the pretty printed JSON
	if sys.argv[2] == "json":
		print json.dumps(dict_colors, indent=2, sort_keys=True)
	
	# if the output format is i3, then print the block using i3_pprint_offsets
	elif sys.argv[2] == "i3":
		print "# Xresources" + (' ' * i3_pprint_offsets[0]) + "var" + (' ' * i3_pprint_offsets[1]) + "value" + (' ' * i3_pprint_offsets[2]) + "fallback"
		print "set_from_resource" + (' ' * (i3_pprint_offsets[0] - 5)) + "$bg" + (' ' * i3_pprint_offsets[1]) + "background" + (' ' * (i3_pprint_offsets[2] - 5)) + dict_colors["background"]
		print "set_from_resource" + (' ' * (i3_pprint_offsets[0] - 5)) + "$fg" + (' ' * i3_pprint_offsets[1]) + "foreground" + (' ' * (i3_pprint_offsets[2] - 5)) + dict_colors["foreground"]
		for i in xrange(16):
			print "set_from_resource" + (' ' * (i3_pprint_offsets[0] - 5)) + "$" + list_colors[i] + (' ' * ((i3_pprint_offsets[1] + 2) - len(list_colors[i]))) + "color" + str(i) + (' ' * ((i3_pprint_offsets[2] + 5) - len("color" + str(i)))) + dict_colors["color" + str(i)]

	# if the output format is termite, generate the termite color scheme using termite_pprint_offset
	elif sys.argv[2] == "termite":
				if raw_input("Do you want to use a transparent background? (y/n) ").lower() == "y":
					alpha = input("Enter the transparency percentage you want to use: ")
					dict_colors["background"] = "rgba(" + str(int(dict_colors["background"][1:3], 16)) + ", " + str(int(dict_colors["background"][3:5], 16)) + ", " + str(int(dict_colors["background"][5:7], 16)) + ", " + str(float(alpha) / 100) + ")"
				print "\n[colors]\n"
				print "# special"
				print "foreground" + (' ' * (termite_pprint_offset - len("foreground"))) + "= " + dict_colors["foreground"]
				print "foreground_bold" + (' ' * (termite_pprint_offset - len("foreground_bold"))) + "= " + dict_colors["foreground"]
				print "cursor" + (' ' * (termite_pprint_offset - len("cursor"))) + "= " + dict_colors["cursorColor"]
				print "background" + (' ' * (termite_pprint_offset - len("background"))) + "= " + dict_colors["background"]
				print ""
				print "# colors"
				for i in xrange(16):
					print "color" + str(i) + (' ' * (termite_pprint_offset - len("color" + str(i)))) + "= " + dict_colors["color" + str(i)]


	# if there is an invalid output format selected, then show an error message
	else:
		print "Error in input, the script will exit now. Bye!"
