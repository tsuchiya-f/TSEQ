set group_store {}
set first_packet_rcvd 0
set first_packet_id 0

proc processPacket {v1 v2 op} {
	global group_store
	global first_packet_rcvd
	global first_packet_id
	global sockChan
	
	# local variable pkt is now reference to whatever variable was updated
	upvar $v1 pkt
	#syslog -src TEST "Arguments: <$v1> <$v2> <$op>"

	# do something with pkt
	switch [getgroupingflags $pkt] {
		1 { # first packet
			syslog -src TEST "first packet. id: [gettmcacheid $pkt]"
			set first_packet_rcvd 1
			set first_packet_id [gettmcacheid $pkt]
			set group_store {}
			#set sciencedata [getsciencedata 1 $pkt]
			#append group_store $sciencedata
			eval lappend group_store [getsciencedata 1 $pkt]
		}

		0 { # continuous packet
			syslog -src TEST "continuous packet. id: [gettmcacheid $pkt]"
			#if {$first_packet_rcvd} {append group_store [getsciencedata 0 $pkt]}
			if {$first_packet_rcvd} {eval lappend group_store [getsciencedata 0 $pkt]}
		}

		2 { # last packet
			set last_packet_id [gettmcacheid $pkt]
			syslog -src TEST "last packet. id: $last_packet_id"
			if {$first_packet_rcvd} {
				eval lappend group_store [getsciencedata 0 $pkt]
				# unsubscribepacket 79002
				# trace vdelete ::lf_tm w processPacket

				#send data to matlab
				syslog -src TEST "length group_store: [llength $group_store]"
			}
		}

		3 { # standalone packet
			syslog -src TEST "standalone packet. id: [gettmcacheid $pkt]"
			set group_store {}
			eval lappend group_store [getsciencedata 1 $pkt]
			
			#puts $sockChan $line
			#puts $sck $group_store
			#set server 192.168.56.101
			#set sockChan [socket $server 8889]
			puts $sockChan $group_store
			flush $sockChan
			#close $sockChan
			syslog -src TEST "The data to server sent"			
		}

		default {
			syslog -src TEST "strange packet with grouping flag: [getgroupingflags $pkt]. id: [gettmcacheid $pkt]"
		}

	}
}


set server localhost
set sockChan [socket $server 8889]

trace add variable ::lf_tm write processPacket

subscribepacket 79001 referby lf_tm

vwait forever

return

