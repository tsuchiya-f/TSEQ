
proc connect_cnc_and_load_db {} {
	# connect plugin
	if { ! $::utope::connected } {
		::utope::connect CncProto
		::utope::waittime 1.000

		if { ! $::utope::connected } {
			syslog -src TEST "Unable to connected to CncProto!! Exiting..."
			return
		}
	}
	syslog -src TEST "Connected to CncProto."

	# load database
	::utope::loaddb
	::utope::waitForDbLoaded
	syslog -src TEST "Finished loading database."

	return
}

# setup and connect to SIS

proc setup_and_connect_sis {} {

	connect_cnc_and_load_db

	# connect TM port
	CncProto::connect SIS_TM
	waittime 1.0000
	syslog -src TEST "Connected to SIS_TM."

	# connect TC port
	CncProto::connect SIS_TC
	waittime 1.0000
	syslog -src TEST "Connected to SIS_TC."

	return
}


setup_and_connect_sis
