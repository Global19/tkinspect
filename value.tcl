#
# $Id$
#

set value_priv(counter) -1

proc value_no_filter {text} {
    return $text
}

widget value {
    param width 100
    param height 20
    param main
    param savehist 15
    param searchbackground indianred
    param searchforeground white
    member hist_no 0
    member send_filter value_no_filter
    method create {} {
	#$self config -bd 0 -relief flat -highlightthickness 0
	pack [ttk::frame $self.title] -side top -fill x
	pack [ttk::label $self.title.l -text "Value:  "] -side left
	ttk::menubutton $self.title.vname -menu $self.title.vname.m -state disabled
	menu $self.title.vname.m -postcommand "$self fill_vname_menu"
	pack $self.title.vname -fill x
	ttk::scrollbar $self.sb -command "$self.t yview"
	text $self.t -yscroll "$self.sb set" -background white
	pack $self.sb -side right -fill y
	pack $self.t -side right -fill both -expand 1
	bind $self.t <Control-x><Control-s> "$self send_value"
	bind $self.t <Control-s> "$self search_dialog"
	set m [$slot(main) add_menu Value]
	bind $self.t <3> "tk_popup $m %X %Y"
	$m add command -label "Send Value" -command "$self send_value" \
	    -underline 1
	$m add command -label "Find..." -command "$self search_dialog" \
	    -underline 0
	$m add command -label "Save Value..." -command "$self save" \
	    -underline 0
	$m add command -label "Load Value..." -command "$self load" \
	    -underline 0
	$m add command -label "Detach Window" -command "$self detach" \
	    -underline 0
    }
    method reconfig {} {
	$self.t config -width $slot(width) -height $slot(height)
	$self.t tag configure search -background $slot(searchbackground) \
	    -foreground $slot(searchforeground)
    }
    method set_value {name value redo_command} {
	$self.t delete 1.0 end
	$self.t insert 1.0 $value
	$self.title.vname config -text $name -state normal
	set slot(history.[incr slot(hist_no)]) [list $name $redo_command]
	if {($slot(hist_no) - $slot(savehist)) > 0} {
	    unset slot(history.[expr $slot(hist_no)-$slot(savehist)])
	}
    }
    method fill_vname_menu {} {
	set m $self.title.vname.m
	catch {$m delete 0 last}
	for {set i $slot(hist_no)} {[info exists slot(history.$i)]} {incr i -1} {
	    $m add command -label [lindex $slot(history.$i) 0] \
		-command [lindex $slot(history.$i) 1]
	}
    }
    method set_send_filter {command} {
	if {![string length $command]} {
	    set command value_no_filter
	}
	set slot(send_filter) $command
    }
    method send_value {} {
	send [$slot(main) target] \
	    [eval $slot(send_filter) [list [$self.t get 1.0 end]]]
	$slot(main) status "Value sent"
    }
    method detach {} {
	set w [tkinspect_create_main_window \
	       -default_lists {} \
	       -target [$slot(main) cget -target]]
	$w.value copy $self
    }
    method copy {v} {
	$self.t insert 1.0 [$v.t get 1.0 end]
    }
    method search_dialog {} {
	if ![winfo exists $self.search] {
	    value_search $self.search -value $self
	    center_window $self.search
	} else {
	    wm deiconify $self.search
	}
    }
    method search {type text} {
	$self.t tag remove search 0.0 end
	scan [$self.t index end] %d n_lines
	set start 1
	set end [expr $n_lines+1]
	set inc 1
	set l [string length $text]
	for {set i $start} {$i != $end} {incr i $inc} {
	    if {[string first $text [$self.t get $i.0 $i.1000]] == -1} {
		continue
	    }
	    set line [$self.t get $i.0 $i.1000]
	    set offset 0
	    while 1 {
		set index [string first $text $line]
		if {$index < 0} {
		    break
		}
		incr offset $index
		$self.t tag add search $i.[expr $offset] $i.[expr $offset+$l]
		incr offset $l
		set line [string range $line [expr $index+$l] 1000]
	    }
	}
	if [catch {$self.t see [$self.t index search.first]}] {
	    $slot(main) status "Search text not found."
	}
    }
    method save {} {
	#filechooser $self.fc -newfile 1 -title "Save Value"
	#set file [$self.fc run]
        set file [tk_getSaveFile -title "Save Value"]
	if ![string length $file] {
	    $slot(main) status "Save cancelled."
	    return
	}
	set fp [open $file w]
	puts $fp [$self.t get 1.0 end]
	close $fp
	$slot(main) status "Value saved to \"$file\""
    }
    method load {} {
	#filechooser $self.fc -title "Load Value"
	#set file [$self.fc run]
        set file [tk_getOpenFile -title "Load Value"]
	if ![string length $file] {
	    $slot(main) status "Load cancelled."
	    return
	}
	$self.t delete 1.0 end
	set fp [open $file r]
	$self.t insert 1.0 [read $fp]
	close $fp
	$slot(main) status "Value read from \"$file\""
    }
}

dialog value_search {
    param value
    member search_type exact
    method create {} {
	ttk::frame $self.top
	pack $self.top -side top -fill x
	ttk::label $self.l -text "Search for:"
	ttk::entry $self.e
	bind $self.e <Return> "$self search"
	pack $self.l -in $self.top -side left
	pack $self.e -in $self.top -fill x -expand 1
	ttk::checkbutton $self.re -variable [object_slotname search_type] \
	    -onvalue regexp -offvalue exact -text "Regexp search"
	pack $self.re -side top -anchor w
	ttk::button $self.go -text "Highlight" -command "$self search"
	ttk::button $self.close -text "Close" -command "destroy $self"
	pack $self.go $self.close -side left
	wm title $self "Find in Value.."
	wm iconname $self "Find in Value.."
	focus $self.e
    }
    method reconfig {} {
    }
    method search {} {
	set text [$self.e get]
	if ![string length $text] return
	$slot(value) search $slot(search_type) $text
    }
}
