#!/usr/bin/python

# go to a dir with vala code and do:
# valamap.py ./ | dot -Tsvg -o /tmp/valamap.svg && firefox /tmp/valamap.svg

import sys
import os
import re
from lxml import etree


class ValaMap ():

	def __init__ (self, dir):

		self.dir = os.path.abspath (dir) + "/"
		self.classfiledict = {}
		self.root = etree.Element ("valamap")
		self.root.set ("path", self.dir)


	
	def parse_classes (self):

		files = os.listdir (self.dir)
		for file in files:
			if (file.split (".")[-1] == "vala"):
				self.find_classes_in_file (file)



	def parse_references (self):

		for child in self.root:
			name = child.get ("name")
			for cname in self.classfiledict:
				if cname != name:
					refs = self.get_references (self.classfiledict[cname], name)
					if len (refs) >= 1:
						node = etree.SubElement (child, "reference")
						node.set ("class", cname)
						for ref in refs:
							subnode = etree.SubElement (node, "line")
							subnode.set ("num", str (ref))



	def print_xml (self):
	
		print (etree.tostring (self.root, pretty_print=True))
	
	
	
	def print_dot (self):
	
		dot_style = ""
		dot_nodes = ""
		
		# styles & co
		for child in self.root:
			dot_style += child.get ("name") + " "
			dot_style += "["
			
			file = child.get ("file")
			lnum = child.get ("line")
			dot_style += 'href="' + self.dir + file + '",'
			dot_style += 'tooltip="' + file + ' @ ' + lnum + '",'
			
			if child.get ("main") == "True":
				dot_style += "shape=house"
			elif child.get ("type") == "public":
				dot_style += "shape=box"
			else:
				dot_style += "shape=box, style=rounded"
			
			dot_style += "];\n"

		# nodes
		for child in self.root:
			name = child.get ("name")
			if len (child) < 1:
				dot_nodes += name + " "
			else:
				for subchild in child:
					dot_nodes += name + "->" + subchild.get ("class") + " "
			dot_nodes += ";\n"

		node_list = dot_nodes.split ("\n")
		node_list.sort (cmp=self.bylength)
		dot_nodes = "\n".join (node_list)

		print "digraph G {\n"
		print 'size="6.0,6.0";'
		print "node [fontsize=16,fontname=sans,aname=dot];"
		print dot_nodes
		print dot_style
		print "}"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



	def bylength (self, str1, str2):
		return len (str2) - len (str1)



	def get_references (self, file, classname):
		f = open (self.dir + file, 'r')
		refname = "new " + classname
		output = []
		linenum = 0
		for line in f:
			linenum += 1
			line.strip ()
			if line.startswith ("//"):
				continue
			if line.find (refname) > -1:
				output.append (linenum)
		return output



	def find_classes_in_file (self, file):
		found = False
		main = False
		foundline = ""
		foundlinenum = 0
		linenum = 0
	
		f = open (self.dir + file, 'r')

		for line in f:
			linenum += 1
			line.strip ()

			if line.startswith ("//"):
				continue

			if line.find (" class ") > -1:
				foundline = line
				foundlinenum = linenum
				found = True

			if line.find ("public static int main") > -1:
				main = True
	
		if found == True:
			self.class_to_xml (foundline, file, foundlinenum, main)
		


	def class_to_xml (self, line, file, linenum, main):
		exp = "^(\w+)\s+class\s+(\w+\.)?(\w+)(\s*:\s*)?(\w\.+)?(\s*,\s*)?(\w+)?"
		res = re.search (exp, line)
		if (res):
			node = etree.SubElement (self.root, "class")
			node.set ("name", res.group (3))
			#node.set ("space", res.group (2).rstrip(".") or "")
			node.set ("space", res.group (2) or "")
			node.set ("type", res.group (1))
			node.set ("super", res.group (5) or "")
			node.set ("interface", res.group (7) or "")
			node.set ("file", file)
			node.set ("line", str (linenum))
			node.set ("main", str (main))
			self.classfiledict[res.group (3)] = file

################################################################################

if __name__ == "__main__":

	if len (sys.argv) <= 1:
		print "Usage: " + sys.argv[0] + " <source dir>"
		exit (1)

	valamap = ValaMap (sys.argv[1])
	valamap.parse_classes ()
	valamap.parse_references ()
	#valamap.print_xml ()
	valamap.print_dot ()

