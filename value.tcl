#
# $Id$
#

set value_priv(counter) -1

proc value_no_filter {text} {
    return $text
}

widget value {
    param width 80
    param height 20
    param main
    param savehist 15
    member hist_no 0
    member send_filter value_no_filter
    method create {} {
	$self config -bd 2 -relief raised -highlightthickness 0
	pack [frame $self.title] -side top -fill x
	pack [label $self.title.l -text "Value:  "] -side left
	menubutton $self.title.vname -anchor w -menu $self.title.vname.m \
	    -bd 0 -state disabled
	menu $self.title.vname.m -postcommand "$self fill_vname_menu"
	pack $self.title.vname -fill x
	scrollbar $self.sb -relief sunken -bd 1 -command "$self.t yview"
	text $self.t -yscroll "$self.sb set"
	pack $self.sb -side right -fill y
	pack $self.t -side right -fill both -expand 1
	bind $self.t <Control-x><Control-s> "$self send_value"
	set m [$slot(main) add_menu Value]
	$m add command -label "Send Value" -command "$self send_value"
	$m add command -label "Save Value..." -state disabled
	$m add command -label "Load Value..." -state disabled
	$m add command -label "Detach Window" -command "$self detach"
	bind $self.t <FocusIn> \
	    "if {\[focus -lastfor $self\] != \"$self\"} { $slot(main) status \"C-x C-s to send value\" }; continue"
    }
    method reconfig {} {
	$self.t config -width $slot(width) -height $slot(height)
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
}
