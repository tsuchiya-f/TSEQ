set group_store {}
set first_packet_rcvd 0
set sockChan 0

## Get sequence control flags from packet
#
# @param pkt Reference to packet.
#
# @return Sequence control flags as integer.
proc getgroupingflags {pkt} {
	return [::utope::tmprop [gettmcacheid $pkt] groupingFlags]
	#return 3
}

## Get science data from packet.
#
# @param header Flag indicating if header is present or not.
# @param pkt Reference to packet.
#
# @return Science data from packet as a 8-bit signed integer list.
proc getsciencedata {header pkt} {
	set rawdata [getrawdata $pkt]

	set rawbindata [hextobin $rawdata]

	set hdr_len 6
	set dfh_len 10
	set rpwi_hdr_len 8
	set n_skip [expr $hdr_len + $dfh_len + $rpwi_hdr_len]
	set rauxlen 0

	if {$header == 1} {
		#binary scan $rawbindata c16c1I1c1 nothing rsid rdeltatime rauxlen
		binary scan $rawbindata c16c1I1c2c1 nothing rsid rdeltatime seqcount rauxlen
		set raux {}
		binary scan $rawbindata c22c $rauxlen nothing raux

		incr n_skip [expr {$rauxlen}]
	}

	set n_mydata [expr {[string length $rawbindata]}]
	binary scan $rawbindata c${n_mydata} mydata
	syslog -src TEST "rauxlen: $rauxlen, c{$n_skip}c{$n_mydata}c2 llength mydata: [llength $mydata]"
	# set n_mydata [expr {[string length $rawbindata] - $n_skip - 2}]
	# binary scan $rawbindata c${n_skip}c${n_mydata}c2 nothing mydata crc
	# syslog -src TEST "rauxlen: $rauxlen, c{$n_skip}c{$n_mydata}c2 llength mydata: [llength $mydata]"

	return $mydata
}

## Accept client connection to server.
#
# This functions is intended to be passed as the callback command in the socket
# server initialisation call.
#
# Currently overwrites the global socket channel based on the latest connected
# client, hence connecting more than one client does not work.
#
# @param channel New socket channel to associate with the client.
# @param addr Address of the connecting client.
# @param addr Port of the connecting client.
proc acceptConnection { channel addr port } {
	global sockChan

	syslog -src TEST "Accept $channel connection from $addr on port $port"

	# Flush automatically after every output
	fconfigure $channel -buffering none
	# Send raw bytes
	fconfigure $channel -encoding binary
	# Avoid injecting carriage return before 0x10 bytes
	fconfigure $channel -translation binary

	set sockChan $channel
}

## Send data to a socket channel.
#
# The data will be sent in string format, delimited by spaces.
#
# @param channel Socket channel to send data to.
# @param data Data to send.
proc sendData {channel data} {
	set rawbytes [binary format c* $data]
	if {[catch {puts -nonewline $channel $rawbytes} err]} {
		syslog -src TEST "Failed to send data: $err"
		return
	}
}

## Get science data from packets and send to client.
#
# Uses packet sequence control flags to determine sequencing. Stand alone
# packets are sent directly, whereas sequenced packets are accumulated and sent
# as a recombined set of packets.
#
# This is intended to be registered as a trace callback whenever the packet
# variable is updated by write.
#
# @param pkt Reference to packet.
# @param unused_idx Unused (index into array if tracing array).
# @param unused_op Unused (operation being performed on packet variable).
proc processPacket {pkt_ref unused_idx unused_op} {
	global group_store
	global first_packet_rcvd
	global sockChan

	# need to grab variable from outer scope here
	upvar $pkt_ref pkt
	
	set myrawdata [getrawdata $pkt]

	switch [getgroupingflags $pkt] {
		1 { # first packet
			syslog -src TEST "first packet. id: [gettmcacheid $pkt]"
			set first_packet_rcvd 1
			set group_store {}
			eval lappend group_store [getsciencedata 1 $pkt]
		}

		0 { # continuation packet
			syslog -src TEST "continuation packet. id: [gettmcacheid $pkt]"
			if {$first_packet_rcvd} {
				eval lappend group_store [getsciencedata 0 $pkt]
			} else {
				syslog -src TEST "Sequence error, unexpected coninuation packet"
				set group_store {}
			}

		}

		2 { # last packet
			set last_packet_id [gettmcacheid $pkt]
			syslog -src TEST "last packet. id: $last_packet_id"
			if {$first_packet_rcvd} {
				eval lappend group_store [getsciencedata 0 $pkt]

				sendData $sockChan $group_store
				syslog -src TEST "length group_store: [llength $group_store]"

				set first_packet_rcvd 0
			}
		}

		3 { # standalone packet
			syslog -src TEST "standalone packet. id: [gettmcacheid $pkt]"
			set group_store {}
			eval lappend group_store [getsciencedata 1 $pkt]
			
			sendData $sockChan $group_store
			syslog -src TEST "The data to server sent"			
			set first_packet_rcvd 0
		}

		default {
			syslog -src TEST "strange packet with grouping flag: [getgroupingflags $pkt]. id: [gettmcacheid $pkt]"

			set first_packet_rcvd 0
		}

	}
}

set acceptSock [socket -server acceptConnection 7902]

trace add variable ::hf_tm write processPacket

subscribepacket 79002 referby hf_tm

vwait forever

return
