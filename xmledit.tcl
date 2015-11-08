#!wish
## Licensed under the Apache License, Version 2.0 (the "License"); you may not
## use this file except in compliance with the License. You may obtain a copy of
## the License at
##
##   http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
## WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
## License for the specific language governing permissions and limitations under
## the License.

# XML-Editor Asset
# Simple XML-Editor to edit XML as forms
# Elements have Sub-Elements or text
# plus: Text can contain <br /> tags to be multiline
# contains choicesFormula and formula as such!
# (calcing from topmost down after load and save node)
# ATTENTION: there is no guarantee 4 results being correct!
# evt'ly up to Spreadsheets some day ;-)
# - use @ your own risk & have fun!

package require Tk
package require Ttk
package require tdom
package require BWidget

# Check existence of XML file
if { $argc < 1 } {
	tk_messageBox -message "We need XML file as param!" -title "No file"
	exit
}

#tk_messageBox -message [lindex $argv 0]
# Compute pure file name
set xmlfile [lindex $argv 0]
set len [string length $xmlfile]
set slashpos [string last "\\" $xmlfile]
set xmlname [string range $xmlfile [expr $slashpos + 1] $len]

# Build main window using two frames
wm title . "XML-Editor - $xmlname"
wm minsize . 450 350
grid columnconfigure . 0 -weight 130 -uniform ufgrp
grid columnconfigure . 1 -weight 100 -uniform ufgrp
grid rowconfigure . 0 -weight 0 -minsize 30
grid rowconfigure . 1 -weight 0
grid rowconfigure . 2 -weight 100
frame .toolbar
grid .toolbar -row 0 -columnspan 2 -column 0 -sticky w
button .toolbar.add -text "Add Element" -command add_node
pack .toolbar.add -side left
button .toolbar.remove -text "Remove Element" -command remove_node
pack .toolbar.remove -side left
button .toolbar.clone -text "Clone Element" -command clone_node
pack .toolbar.clone -side left
button .toolbar.cut -text "Cut" -command cut_node
pack .toolbar.cut -side left
button .toolbar.copy -text "Copy" -command copy_node
pack .toolbar.copy -side left
button .toolbar.paste -text "Paste" -command paste_node
pack .toolbar.paste -side left
button .toolbar.moveup -text "Move up" -command move_node_up
pack .toolbar.moveup -side left
button .toolbar.movedown -text "Move down" -command move_node_down
pack .toolbar.movedown -side left
button .toolbar.setchoices -text "Set choices" -command node_set_choices
pack .toolbar.setchoices -side left
button .toolbar.setchoicesformula -text "Set choices formula" -command node_set_choices_formula
pack .toolbar.setchoicesformula -side left
button .toolbar.setformula -text "Set formula" -command node_set_formula
pack .toolbar.setformula -side left
label .toolbar.sep0 -text "    "
pack .toolbar.sep0 -side left
button .toolbar.search -text "Search" -command perform_search
pack .toolbar.search -side left
label .toolbar.sep2 -text "    "
pack .toolbar.sep2 -side left
button .toolbar.addsniplet -text "Add sniplet" -command add_sniplet
pack .toolbar.addsniplet -side left
button .toolbar.applysniplet -text "Apply sniplet" -command apply_sniplet
pack .toolbar.applysniplet -side left
button .toolbar.savesniplet -text "Save sniplet"
pack .toolbar.savesniplet -side left
button .toolbar.importer -text "Importer"
pack .toolbar.importer -side left
label .toolbar.sep3 -text "    "
pack .toolbar.sep3 -side left
button .toolbar.save -text "SAVE" -command save
pack .toolbar.save -side left
label .toolbar.sep4 -text "    "
pack .toolbar.sep4 -side left
button .toolbar.info -text "Info" -command {tk_messageBox -message "XML-Editor Asset - use @ your own risk & have fun!" -title "Info"}
pack .toolbar.info
frame .toolbar2
grid .toolbar2 -row 1 -columnspan 2 -column 0 -sticky w

Tree .tree -selectcommand show_node 
grid .tree -row 2 -column 0 -sticky nesw
frame .details
grid .details -row 2 -column 1  -sticky nesw

# Clipboard variable
set clipboard "null"


# EVENT HANDLERS

proc show_node {{selpath null} {selargs null}} {
	# Now build a form for this node using packed labels
	# clear details frame first
	foreach kidelem [info commands ".details.*"] {
		destroy $kidelem
	}
	# build form for those elements without kids
	set node [.tree selection get]
	if { [string length $node] == 0 } {
		return
	}
	set ownkids 0
	foreach kid [$node childNodes] {
		if { [$kid nodeType] == "ELEMENT_NODE" } {
			incr ownkids
		}
	}
	if { $ownkids > 0 } {
		# form for all kids without text
		set cnt 0
		foreach kid [$node childNodes] {
			if { [$kid nodeType] == "ELEMENT_NODE" } {
				set ownkidkids 0
				foreach kidkid [$kid childNodes] {
					if { [$kidkid nodeType] == "ELEMENT_NODE" } {
						incr ownkidkids
					}
				}
				if { $ownkidkids == 0 } {
					label ".details.lab$cnt" -text [$kid nodeName]
					pack ".details.lab$cnt"
					if { [$kid hasAttribute "choices"] > 0 } {
						listbox ".details.lst$cnt" -height 3 -exportselection 0
						set choices [split [$kid getAttribute "choices"] ","]
						# insert and select current value if applicable
						set ind 0
						foreach choice $choices {
							".details.lst$cnt" insert end $choice
						}
						".details.lst$cnt" selection clear 0 end
						foreach choice $choices {
							if { $choice == [[$kid firstChild] nodeValue] } {
								".details.lst$cnt" selection set $ind
							}
							incr ind
						}
						pack ".details.lst$cnt" -fill x
					} elseif { [$kid hasAttribute "choicesFormula"] > 0 } {
						listbox ".details.lstf$cnt" -height 3 -exportselection 0
						set choicesNodes [$node selectNodes [$kid getAttribute "choicesFormula"]]
						set choices []
						foreach choiceNode $choicesNodes {
							lappend choices [[$choiceNode firstChild] nodeValue]
						}
						# insert and select current value if applicable
						set ind 0
						foreach choice $choices {
							".details.lstf$cnt" insert end $choice
						}
						".details.lstf$cnt" selection clear 0 end
						foreach choice $choices {
							if { $choice == [[$kid firstChild] nodeValue] } {
								".details.lstf$cnt" selection set $ind
							}
							incr ind
						}
						pack ".details.lstf$cnt" -fill x
					} elseif { [$kid hasAttribute "formula"] > 0 } {
						label ".details.ent$cnt" -text [[$kid firstChild] nodeValue]
						pack ".details.ent$cnt" -fill x
					} else {
						entry ".details.ent$cnt"
						pack ".details.ent$cnt" -fill x
						".details.ent$cnt" insert 0 [[$kid firstChild] nodeValue]
					}
					incr cnt
				}
			}
		}
		if { $cnt > 0 } {
			# add a save button to make sure we can save
			button .details.save -text "Change node" -command save_node
			pack .details.save -side top
		}
	} else {
		if { [$node hasAttribute "choices"] > 0 } {
			listbox .details.nodevallst -height 3 -exportselection 0
			set choices [split [$node getAttribute "choices"] ","]
			# insert and select current value if applicable
			set ind 0
			foreach choice $choices {
				.details.nodevallst insert end $choice
			}
			.details.nodevallst selection clear 0 end
			foreach choice $choices {
				if { $choice == [[$node firstChild] nodeValue] } {
					.details.nodevallst selection set $ind
				}
				incr ind
			}
			pack .details.nodevallst -fill x
		} elseif { [$node hasAttribute "choicesFormula"] > 0 } {
			listbox .details.nodevallstf -height 3 -exportselection 0
			set choicesNodes [[$node parentNode] selectNodes [$node getAttribute "choicesFormula"]]
			set choices []
			foreach choiceNode $choicesNodes {
				lappend choices [[$choiceNode firstChild] nodeValue]
			}
			# insert and select current value if applicable
			set ind 0
			foreach choice $choices {
				.details.nodevallstf insert end $choice
			}
			.details.nodevallstf selection clear 0 end
			foreach choice $choices {
				if { $choice == [[$node firstChild] nodeValue] } {
					.details.nodevallstf selection set $ind
				}
				incr ind
			}
			pack .details.nodevallstf -fill x
		} elseif { [$node hasAttribute "formula"] > 0 } {
			# only a label entry (i.e. only one)
			label .details.nodeval -text [[$node firstChild] nodeValue]
			pack .details.nodeval -fill x
		} else {
			# only a text entry (i.e. only one)
			entry .details.nodeval
			pack .details.nodeval -fill x
			.details.nodeval insert 0 [[$node firstChild] nodeValue]
		}
		# add a save button to make sure we can save
		button .details.save -text "Change node" -command save_node
		pack .details.save -side top
	}
	# also build toolbar2
	build_toolbar2
}

proc save_node {} {
	# same as show, just the other way round
	set node [.tree selection get]
	set ownkids 0
	foreach kid [$node childNodes] {
		if { [$kid nodeType] == "ELEMENT_NODE" } {
			incr ownkids
		}
	}
	if { $ownkids > 0 } {
		# form for all kids without text
		set cnt 0
		foreach kid [$node childNodes] {
			if { [$kid nodeType] == "ELEMENT_NODE" } {
				set ownkidkids 0
				foreach kidkid [$kid childNodes] {
					if { [$kidkid nodeType] == "ELEMENT_NODE" } {
						incr ownkidkids
					}
				}
				if { $ownkidkids == 0 } {
					if { [$kid hasAttribute "choices"] > 0 } {
						[$kid firstChild] nodeValue [".details.lst$cnt" get [".details.lst$cnt" curselection]]
					} elseif { [$kid hasAttribute "choicesFormula"] > 0 } {
						[$kid firstChild] nodeValue [".details.lstf$cnt" get [".details.lstf$cnt" curselection]]
					} elseif { [$kid hasAttribute "formula"] > 0 } {
						# (do nothing)
					} else {
						[$kid firstChild] nodeValue [".details.ent$cnt" get]
					}
					incr cnt
				}
			}
		}
	} else {
		if { [$node hasAttribute "choices"] > 0 } {
			[$node firstChild] nodeValue [.details.nodevallst get [.details.nodevallst curselection]]
		} elseif { [$node hasAttribute "choicesFormula"] > 0 } {
			[$node firstChild] nodeValue [.details.nodevallstf get [.details.nodevallstf curselection]]
		} elseif { [$node hasAttribute "formula"] > 0 } {
			# (do nothing)
		} else {
			[$node firstChild] nodeValue [.details.nodeval get]
		}
	}
	# apply validation if there is one (validation = condition yields at least one result - based on current node) - only display message
	if { [$node hasAttribute "validation"] > 0 } {
		set checkNodes [$node selectNodes [concat [$node toXPath] [$node getAttribute "validation"]]]
		set checkNodesCnt 0
		foreach kid $checkNodes {
			incr checkNodesCnt
		}
		if { $checkNodesCnt == 0 } {
			if { [$node hasAttribute "validationMessage"] } {
				tk_messageBox -message [$node getAttribute "validationMessage"] -title "Invalid content"
			} else {
				tk_messageBox -message "Current node not valid - pls correct!" -title "Invalid content"
			}
		}
	}
	# plus do calcs
	global rootelem
	calc_node $rootelem
	# also update the tree
	compute_treetext $node
	if { [string length [$node parentNode]] > 0 } {
		compute_treetext [$node parentNode]
	}
	foreach kid [$node childNodes] {
		if { [$kid nodeType] == "ELEMENT_NODE" } {
			compute_treetext $kid
		}
	}
	# and show from new
	show_node
}

proc add_node {} {
	if { [llength [info commands .namequery]] > 0 } {
		destroy .namequery
	}
	set node [.tree selection get]
	if { [string length $node] == 0 } {
		return
	}
	# ask for a name of the element
	toplevel .namequery
	wm title .namequery "Please enter name for new element: "
	wm geometry .namequery "=400x60+[expr [winfo x .] + 40]+[expr [winfo x .] + 40]"
	bind .namequery <KeyPress-Return> add_node_impl
	entry .namequery.newname
	pack .namequery.newname -fill x 
	button .namequery.ok -text " O K " -command add_node_impl
	pack .namequery.ok -side left
	button .namequery.cancel -text "cancel" -command { destroy .namequery }
	pack .namequery.cancel -side left
	focus .namequery.newname
}
proc add_node_impl {} {
	global doc
	set node [.tree selection get]
	set newname [.namequery.newname get]
	destroy .namequery
	if { [string length $newname] <= 0 } {
		return
	}
	if { [regexp {^([A-Za-z])([A-Za-z_0-9]*)$} $newname] > 0 } {
	} else {
		tk_messageBox -message "The element name you entered is not valid!" -title "No valid element name" -icon error
		return
	}
	
	# determine the number of children already existing
	set ownkids 0
	foreach kid [$node childNodes] {
		if { [$kid nodeType] == "ELEMENT_NODE" } {
			incr ownkids
		}
	}
	# we use this as an index for the new element
	set newelem [$doc createElement $newname]
	$node appendChild $newelem
	$newelem appendChild [$doc createTextNode ""]
	.tree insert $ownkids $node $newelem -text $newname
	# finally, update the tree and the form as well
	build_tree $newelem
	compute_treetext $newelem
	compute_treetext $node
	show_node
}

proc remove_node {} {
	set node [.tree selection get]
	if { [string length $node] == 0 } {
		return
	}
	set parentnode [$node parentNode]
	if { [string length $parentnode] == 0 } {
		return
	}
	.tree delete $node
	.tree selection set $parentnode
	$parentnode removeChild $node
	# finally, update the tree and the form as well
	compute_treetext $parentnode
	show_node
}

proc clone_node {} {
	set node [.tree selection get]
	if { [string length $node] == 0 } {
		return
	}
	set parentnode [$node parentNode]
	if { [string length $parentnode] == 0 } {
		return
	}
	# insert the cloned element
	# determine the number of children already existing
	set ownkids 0
	foreach kid [$parentnode childNodes] {
		if { [$kid nodeType] == "ELEMENT_NODE" } {
			incr ownkids
		}
	}
	# we use this as an index for the new element
	set newelem [$node cloneNode -deep]
	clean_node_impl $newelem
	$parentnode appendChild $newelem
	.tree insert $ownkids $parentnode $newelem -text [$newelem nodeName]
	# finally, update the tree and the form as well (plus: subelements!)
	build_tree $newelem
	compute_treetext $newelem
	compute_treetext $parentnode
	show_node
}
proc clean_node_impl {node} {
	# iterate, delete all non-elements and each element that has the same name as before
	set prevkidn ""
	foreach kid [$node childNodes] {
		if { [$kid nodeType] == "ELEMENT_NODE" } {
			if { $prevkidn == [$kid nodeName] } {
				$node removeChild $kid
			} else {
				set prevkidn [$kid nodeName]
				clean_node_impl $kid
			}
		} else {
			$node removeChild $kid
		}
	}
}

proc cut_node {} {
	global clipboard
	set node [.tree selection get]
	if { [string length $node] == 0 } {
		return
	}
	set parentnode [$node parentNode]
	if { [string length $parentnode] == 0 } {
		return
	}
	# set the clipboard
	set clipboard [$node cloneNode -deep]
	.tree delete $node
	.tree selection set $parentnode
	$parentnode removeChild $node
	# finally, update the tree and the form as well
	compute_treetext $parentnode
	show_node
}

proc copy_node {} {
	global clipboard
	set node [.tree selection get]
	if { [string length $node] == 0 } {
		return
	}
	# set the clipboard
	set clipboard [$node cloneNode -deep]
}

proc paste_node {} {
	global clipboard
	if { $clipboard == "null" } {
		return
	}
	set node [.tree selection get]
	if { [string length $node] == 0 } {
		return
	}
	# paste the clipboard
	# determine the number of children already existing
	set ownkids 0
	foreach kid [$node childNodes] {
		if { [$kid nodeType] == "ELEMENT_NODE" } {
			incr ownkids
		}
	}
	# we use this as an index for the new element
	set newelem [$clipboard cloneNode -deep]
	$node appendChild $newelem
	.tree insert $ownkids $node $newelem -text [$newelem nodeName]
	# finally, update the tree and the form as well (plus: subelements!)
	build_tree $newelem
	compute_treetext $newelem
	compute_treetext $node
	show_node
}

proc move_node_up {} {
	set node [.tree selection get]
	if { [string length $node] == 0 } {
		return
	}
	set parentnode [$node parentNode]
	if { [string length $parentnode] == 0 } {
		return
	}
	# find previous and insert before
	set prev [$node previousSibling]
	while { [string length $prev] > 0 && [$prev nodeType] != "ELEMENT_NODE" } {
		set prev [$prev previousSibling]
	}
	if { [string length $prev] > 0 } {
		$parentnode removeChild $node
		$parentnode insertBefore $node $prev
	}
	foreach kid [$parentnode childNodes] {
		if { [$kid nodeType] == "ELEMENT_NODE" } {
			.tree delete $kid
		}
	}
	build_tree $parentnode
	.tree selection set $node
}

proc move_node_down {} {
	set node [.tree selection get]
	if { [string length $node] == 0 } {
		return
	}
	set parentnode [$node parentNode]
	if { [string length $parentnode] == 0 } {
		return
	}
	# find next and it before ourselves
	set next [$node nextSibling]
	while { [string length $next] > 0 && [$next nodeType] != "ELEMENT_NODE" } {
		set prev [$next nextSibling]
	}
	if { [string length $next] > 0 } {
		$parentnode removeChild $next
		$parentnode insertBefore $next $node
	}
	foreach kid [$parentnode childNodes] {
		if { [$kid nodeType] == "ELEMENT_NODE" } {
			.tree delete $kid
		}
	}
	build_tree $parentnode
	.tree selection set $node
}

proc node_set_choices {} {
	set node [.tree selection get]
	if { [string length $node] == 0 } {
		return
	}
	toplevel .choicesquery
	wm title .choicesquery "Please enter (comma-sep.) choices for the element: "
	wm geometry .choicesquery "=400x60+[expr [winfo x .] + 40]+[expr [winfo x .] + 40]"
	bind .choicesquery <KeyPress-Return> node_set_choices_impl
	entry .choicesquery.choices
	if { [$node hasAttribute "choices"] > 0 } {
		.choicesquery.choices insert 0 [$node getAttribute "choices"]
	}
	pack .choicesquery.choices -fill x 
	button .choicesquery.ok -text " O K " -command node_set_choices_impl
	pack .choicesquery.ok -side left
	button .choicesquery.unset -text "unset" -command node_set_choices_unset
	pack .choicesquery.unset -side left
	button .choicesquery.cancel -text "cancel" -command { destroy .choicesquery }
	pack .choicesquery.cancel -side left
	focus .choicesquery.choices
}
proc node_set_choices_impl {} {
	set node [.tree selection get]
	set newchoice [.choicesquery.choices get]
	destroy .choicesquery
	if { [string length $newchoice] <= 0 } {
		return
	}
	$node setAttribute "choices" $newchoice
	show_node
}
proc node_set_choices_unset {} {
	set node [.tree selection get]
	destroy .choicesquery
	$node removeAttribute "choices"
	show_node
}

proc node_set_choices_formula {} {
	set node [.tree selection get]
	if { [string length $node] == 0 } {
		return
	}
	toplevel .choicesformulaquery
	wm title .choicesformulaquery "Please enter a choices formula for the element: "
	wm geometry .choicesformulaquery "=400x60+[expr [winfo x .] + 40]+[expr [winfo x .] + 40]"
	bind .choicesformulaquery <KeyPress-Return> node_set_choices_formula_impl
	entry .choicesformulaquery.choicesformula
	if { [$node hasAttribute "choicesFormula"] > 0 } {
		.choicesformulaquery.choicesformula insert 0 [$node getAttribute "choicesFormula"]
	}
	pack .choicesformulaquery.choicesformula -fill x 
	button .choicesformulaquery.ok -text " O K " -command node_set_choices_formula_impl
	pack .choicesformulaquery.ok -side left
	button .choicesformulaquery.unset -text "unset" -command node_set_choices_formula_unset
	pack .choicesformulaquery.unset -side left
	button .choicesformulaquery.cancel -text "cancel" -command { destroy .choicesformulaquery }
	pack .choicesformulaquery.cancel -side left
	focus .choicesformulaquery.choicesformula
}
proc node_set_choices_formula_impl {} {
	set node [.tree selection get]
	set newchoiceformula [.choicesformulaquery.choicesformula get]
	destroy .choicesformulaquery
	if { [string length $newchoiceformula] <= 0 } {
		return
	}
	$node setAttribute "choicesFormula" $newchoiceformula
	show_node
}
proc node_set_choices_formula_unset {} {
	set node [.tree selection get]
	destroy .choicesformulaquery
	$node removeAttribute "choicesFormula"
	show_node
}

proc node_set_formula {} {
	set node [.tree selection get]
	if { [string length $node] == 0 } {
		return
	}
	toplevel .formulaquery
	wm title .formulaquery "Please enter a formula for the element: "
	wm geometry .formulaquery "=400x60+[expr [winfo x .] + 40]+[expr [winfo x .] + 40]"
	bind .formulaquery <KeyPress-Return> node_set_formula_impl
	entry .formulaquery.formula
	if { [$node hasAttribute "formula"] > 0 } {
		.formulaquery.formula insert 0 [$node getAttribute "formula"]
	}
	pack .formulaquery.formula -fill x 
	button .formulaquery.ok -text " O K " -command node_set_formula_impl
	pack .formulaquery.ok -side left
	button .formulaquery.unset -text "unset" -command node_set_formula_unset
	pack .formulaquery.unset -side left
	button .formulaquery.cancel -text "cancel" -command { destroy .formulaquery }
	pack .formulaquery.cancel -side left
	focus .formulaquery.formula
}
proc node_set_formula_impl {} {
	set node [.tree selection get]
	set newformula [.formulaquery.formula get]
	destroy .formulaquery
	if { [string length $newformula] <= 0 } {
		return
	}
	$node setAttribute "formula" $newformula
	calc_node [$node parentNode]
	compute_treetext $node
	compute_treetext [$node parentNode]
	show_node
}
proc node_set_formula_unset {} {
	set node [.tree selection get]
	destroy .formulaquery
	$node removeAttribute "formula"
	show_node
}

proc perform_search {} {
	set node [.tree selection get]
	if { [string length $node] == 0 } {
		return
	}
	toplevel .search
	wm title .search "Please enter search formula: "
	wm geometry .search "=400x60+[expr [winfo x .] + 40]+[expr [winfo x .] + 40]"
	bind .search <KeyPress-Return> perform_search_impl
	entry .search.formula
	pack .search.formula -fill x
	button .search.ok -text " O K " -command perform_search_impl
	pack .search.ok -side left
	button .search.cancel -text "cancel" -command { destroy .search }
	pack .search.cancel -side left
	focus .search.formula
}
proc perform_search_impl {} {
	set node [.tree selection get]
	if { [string length $node] == 0 } {
		return
	}
	set selxpath [.search.formula get]
	destroy .search
	if { [string length $selxpath] <= 0 } {
		return
	}
	# run Xpath, scroll to first found
	set found [$node selectNodes $selxpath]
	if { [llength $found] <= 0 } {
		return
	}
	.tree selection set [lrange $found 0 0]
	set visitem [lindex $found 0]
	while { [string length $visitem] > 0 && $visitem != "root" } {
		.tree itemconfigure $visitem -open true
		set visitem [.tree parent $visitem]
	}
}

proc add_sniplet {} {
	set node [.tree selection get]
	if { [string length $node] == 0 } {
		return
	}
	toplevel .snipletselect
	wm title .snipletselect "Please select a sniplet to add below the current selection: "
	wm geometry .snipletselect "=400x60+[expr [winfo x .] + 40]+[expr [winfo x .] + 40]"
	bind .snipletselect <KeyPress-Return> add_sniplet_impl
	# determine sniplets from file
	set sniplets [glob "sniplets/*.xml"]
	ttk::combobox .snipletselect.sniplet -state readonly -values $sniplets
	pack .snipletselect.sniplet -fill x 
	button .snipletselect.ok -text " O K " -command add_sniplet_impl
	pack .snipletselect.ok -side left
	button .snipletselect.cancel -text "cancel" -command { destroy .snipletselect }
	pack .snipletselect.cancel -side left
	focus .snipletselect.sniplet
}
proc add_sniplet_impl {} {
	set node [.tree selection get]
	set selsniplet [.snipletselect.sniplet get]
	destroy .snipletselect
	if { [string length $selsniplet] <= 0 } {
		return
	}
	set snxmlch [open $selsniplet]
	set sndoc [dom parse -channel $snxmlch]
	set snrootelem [$sndoc documentElement]
	# determine the number of children already existing
	set ownkids 0
	foreach kid [$node childNodes] {
		if { [$kid nodeType] == "ELEMENT_NODE" } {
			incr ownkids
		}
	}
	# we use this as an index for the new element
	set newelem [$snrootelem cloneNode -deep]
	$node appendChild $newelem
	.tree insert $ownkids $node $newelem -text [$newelem nodeName]
	# finally, update the tree and the form as well (plus: subelements!)
	build_tree $newelem
	compute_treetext $newelem
	compute_treetext $node
	show_node
}

proc apply_sniplet {} {
	set node [.tree selection get]
	if { [string length $node] == 0 } {
		return
	}
	toplevel .snipletselect
	wm title .snipletselect "Please select a sniplet to apply to the current selection: "
	wm geometry .snipletselect "=400x60+[expr [winfo x .] + 40]+[expr [winfo x .] + 40]"
	bind .snipletselect <KeyPress-Return> apply_sniplet_impl
	# determine sniplets from file
	set sniplets [glob "sniplets/*.xml"]
	ttk::combobox .snipletselect.sniplet -state readonly -values $sniplets
	pack .snipletselect.sniplet -fill x 
	button .snipletselect.ok -text " O K " -command apply_sniplet_impl
	pack .snipletselect.ok -side left
	button .snipletselect.cancel -text "cancel" -command { destroy .snipletselect }
	pack .snipletselect.cancel -side left
	focus .snipletselect.sniplet
}
proc apply_sniplet_impl {} {
	set node [.tree selection get]
	set selsniplet [.snipletselect.sniplet get]
	destroy .snipletselect
	if { [string length $selsniplet] <= 0 } {
		return
	}
	set snxmlch [open $selsniplet]
	set sndoc [dom parse -channel $snxmlch]
	set snrootelem [$sndoc documentElement]
	# now merge with the sniplet
	merge_nodes $node $snrootelem
	# rebuild the tree
	.tree delete [.tree nodes $node]
	calc_node $node
	build_tree $node
	compute_treetext $node
	show_node
}

# Helper for merging (re-usable in importers, in sniplet apply)
proc merge_nodes {existnode newnode} {
	global doc
	# check for each child whether we have such a node
	# - within all non-merged nodes
	# (remember all merged nodes)
	set newkids 0
       	foreach newkid [$newnode childNodes] {
		if { [$newkid nodeType] == "ELEMENT_NODE" } {
			incr newkids
		}
	}
	# for all nodes: merge attributes
	if { [llength [$newnode attributes]] > 0 } {
		foreach attr [$newnode attributes] {
			$existnode setAttribute $attr [$newnode getAttribute $attr]
		}
	}
	# for nodes without kids: merge text (when sniplet has one)
	if { $newkids == 0 & [llength [$newnode childNodes]] > 0 } {
		if { [string length [[$newnode firstChild] nodeValue]] > 0 } {
			if { [llength [$existnode childNodes]] == 0 } {
				$existnode appendChild [$doc createTextNode ""]
			}
			# ask for confirm when target also has text and it differs
			set existvalue [[$existnode firstChild] nodeValue]
			set newvalue [[$newnode firstChild] nodeValue]
			set tagname [$existnode nodeName]
			if { [string length $existvalue] == 0 | $existvalue == $newvalue } {
				[$existnode firstChild] nodeValue $newvalue 
			} elseif { [$existnode hasAttribute "formula"] > 0 } {
				# do nothing, we get evaluated
			} elseif { [tk_messageBox -icon question -type yesno -message "Replace $existvalue with $newvalue in $tagname?" ] == "yes" } {
				[$existnode firstChild] nodeValue $newvalue 
			}
		}
	}	
	# for nodes with kids: merge kids
	if { $newkids > 0 } {
		set merged {}
		foreach newkid [$newnode childNodes] {
			if { [$newkid nodeType] == "ELEMENT_NODE" } {
				set existkidsel ""
				foreach existkid [$existnode childNodes] {
					if { [lsearch $merged $existkid] < 0 } {
						if { [$existkid nodeName] == [$newkid nodeName] } {
							set existkidsel $existkid	
							lappend merged $existkidsel
							break
						}
					} 
				}
				if { [string length $existkidsel] == 0 } {
					set existkidsel [$doc createElement [$newkid nodeName]]
					$existnode appendChild $existkidsel
					lappend merged $existkidsel
				}
				merge_nodes $existkidsel $newkid
			}
		}
	}
}


proc save {} {
	global doc
	global argv
	#tk_messageBox -message [$doc asXML]
	set fle [open [lindex $argv 0] w]
	puts $fle {<?xml version="1.0" encoding="utf-8"?>}
	puts $fle [$doc asXML]
	close $fle
}


# Helper to do calculation
proc calc_node {node} {
	global doc
	foreach kid [$node childNodes] {
		if { [$kid nodeType] == "ELEMENT_NODE" } {
			if { [llength [$kid childNodes]] == 0 } {
				$kid appendChild [$doc createTextNode ""]
			}
			if { [$kid hasAttribute "formula"] > 0 } {
				set res [$node selectNodes [$kid getAttribute "formula"]]
				if { [string range $res 0 6] == "domNode" } {
					set res [[$res firstChild] nodeValue]
				}
				[$kid firstChild] nodeValue $res
			}
			calc_node $kid
		}
	}
}


# parse file and build tree
set xmlch [open $xmlfile]
set doc [dom parse -channel $xmlch]
set rootelem [$doc documentElement]

# calcs
calc_node $rootelem

proc build_tree {node} {
	global doc
	set cnt 0
	foreach kid [$node childNodes] {
		if { [$kid nodeType] == "ELEMENT_NODE" } {
			.tree insert $cnt $node $kid -text [$kid nodeName]
			build_tree $kid
			compute_treetext $kid
			incr cnt
		}
	}
	if { [llength [$node childNodes]] == 0 } {
		$node appendChild [$doc createTextNode ""]
	}
}

proc compute_treetext {node} {
	set ownkids 0
	foreach kid [$node childNodes] {
		if { [$kid nodeType] == "ELEMENT_NODE" } {
			incr ownkids
		}
	}
	if { $ownkids > 0 } {
		# when we have own kids, display first three subelements, poss. with text
		set nodecaption ""
		set cnt 0
		foreach kid [$node childNodes] {
			if { [$kid nodeType] == "ELEMENT_NODE" } {
				if { $cnt < 3 } {
					if { [string length $nodecaption] > 0 } {
						set nodecaption "$nodecaption, [$kid nodeName]"
					} else {
						set nodecaption [$kid nodeName]
					}
					set ownkidkids 0
					foreach kidkid [$kid childNodes] {
						if { [$kidkid nodeType] == "ELEMENT_NODE" } {
							incr ownkidkids
						}
					}
					if { $ownkidkids == 0 } {
						set nodecaption "$nodecaption = [[$kid firstChild] nodeValue]"
					}
				} else {
					if { $cnt == 3 } {
						set nodecaption "$nodecaption, ..."
					}
				}
				incr cnt
			}
		}
		.tree itemconfigure $node -text "[$node nodeName] \[$nodecaption\]"
	} else {
		# otherwise, display the content of the first text node (assumed only content)
		.tree itemconfigure $node -text "[$node nodeName] = [[$node firstChild] nodeValue]"
	}
}


proc build_toolbar2 {} {
	# call all applicable scripts in sequence passing the selected node
}
			

.tree insert 0 root $rootelem -text [$rootelem nodeName]
build_tree $rootelem
compute_treetext $rootelem


# end of script