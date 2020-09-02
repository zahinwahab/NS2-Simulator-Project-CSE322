# Copyright (c) 1997 Regents of the University of California.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. All advertising materials mentioning features or use of this software
#    must display the following acknowledgement:
#      This product includes software developed by the Computer Systems
#      Engineering Group at Lawrence Berkeley Laboratory.
# 4. Neither the name of the University nor of the Laboratory may be used
#    to endorse or promote products derived from this software without
#    specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# wireless2.tcl
# simulation of a wired-cum-wireless scenario consisting of 2 wired nodes
# connected to a wireless domain through a base-station node.
# ======================================================================
# Define options
# ======================================================================
set opt(chan)           Channel/WirelessChannel    ;# channel type
set opt(prop)           Propagation/TwoRayGround   ;# radio-propagation model
set opt(netif)          Phy/WirelessPhy            ;# network interface type
set opt(mac)            Mac/802_11                 ;# MAC type
set opt(ifq)            Queue/DropTail/PriQueue    ;# interface queue type
set opt(ll)             LL                         ;# link layer type
set opt(ant)            Antenna/OmniAntenna        ;# antenna model
set opt(ifqlen)         50                         ;# max packet in ifq
set opt(nn)             [lindex $argv 2]                          ;# number of mobilenodes
set opt(adhocRouting)   DSDV                       ;# routing protocol

set opt(cp)             ""                         ;# connection pattern file
set opt(sc)     ""    ;# node movement file. 

set opt(x)      670                            ;# x coordinate of topology
set opt(y)      670                            ;# y coordinate of topology
set opt(seed)   0.0                            ;# seed for random number gen.
set opt(stop)   250                            ;# time to stop simulation

set opt(ftp1-start)      160.0
set opt(ftp2-start)      170.0

set num_wired_nodes [lindex $argv 0]
set num_bs_nodes         1

# ============================================================================
# check for boundary parameters and random seed
if { $opt(x) == 0 || $opt(y) == 0 } {
	puts "No X-Y boundary values given for wireless topology\n"
}
if {$opt(seed) > 0} {
	puts "Seeding Random number generator with $opt(seed)\n"
	ns-random $opt(seed)
}

# create simulator instance
set ns_   [new Simulator]

# set up for hierarchical routing


$ns_ node-config -addressType hierarchical
set num_nodes_wireless [expr $opt(nn)+1]
AddrParams set domain_num_ 2          ;# wired, ha, number of domains
lappend cluster_num $num_wired_nodes 1               ;# in wired each node is a cluster itself, ha(1 cluster),fa(1 cluster) number of clusters in each domain
AddrParams set cluster_num_ $cluster_num

for {set i 0} {$i < [expr $num_wired_nodes]} {incr i} { 
    lappend eilastlevel 1
} 
lappend eilastlevel $num_nodes_wireless
          # number of nodes in each cluster 
AddrParams set nodes_num_ $eilastlevel ;# of each domain
set tracefd  [open traceFile.tr w]
set namtrace [open out.nam w]
$ns_ trace-all $tracefd
$ns_ namtrace-all-wireless $namtrace $opt(x) $opt(y)

# Create topography object
set topo   [new Topography]

# define topology
$topo load_flatgrid $opt(x) $opt(y)

# create God
create-god [expr $opt(nn) + $num_bs_nodes]

#create wired nodes
for {set i 0} {$i < $num_wired_nodes} {incr i} {
    set W($i) [$ns_ node 0.$i.0] 
}


# configure for base-station node
$ns_ node-config -adhocRouting $opt(adhocRouting) \
                 -llType $opt(ll) \
                 -macType $opt(mac) \
                 -ifqType $opt(ifq) \
                 -ifqLen $opt(ifqlen) \
                 -antType $opt(ant) \
                 -propType $opt(prop) \
                 -phyType $opt(netif) \
                 -channelType $opt(chan) \
		 -topoInstance $topo \
                 -wiredRouting ON \
		 -agentTrace ON \
                 -routerTrace OFF \
                 -macTrace OFF 

#create base-station node
set temp {1.0.0 1.0.1 1.0.2 1.0.3}   ;# hier address to be used for wireless
                                     ;# domain
set BS(0) [$ns_ node [lindex $temp 0]]
$BS(0) random-motion 0               ;# disable random motion

#provide some co-ord (fixed) to base station node
$BS(0) set X_ 1.0
$BS(0) set Y_ 2.0
$BS(0) set Z_ 0.0

# create mobilenodes in the same domain as BS(0)  
# note the position and movement of mobilenodes is as defined
# in $opt(sc)
set x_dim 10.0
set y_dim 10.0

set num_col 10
set num_row [expr $num_wired_nodes/$num_col]
set x_start [expr $x_dim/($num_col*2)];
set y_start [expr $y_dim/($num_row*2)];
#configure for mobilenodes
$ns_ node-config -wiredRouting OFF
set j 1
  for {set i 0} {$i < $opt(nn)} {incr i} {
    set node_($i) [$ns_ node 1.0.$j] ;#Creating node
   
  set x_pos [expr $x_start+$j*($x_dim/$num_col)];#grid settings
   set y_pos [expr $y_start+$i*($y_dim/$num_row)];#grid settings
    $node_($i) set X_ $x_pos
    $node_($i) set Y_ $y_pos
    $node_($i) set Z_ 0.0
    incr j
    $node_($i) base-station [AddrParams addr2id \
	    [$BS(0) node-addr]]
}

#create links between wired and BS nodes



set i 0;
while {$i < $num_row } {
#in same column
    for {set j 0} {$j < $num_col } {incr j} {
#in same row
    set m [expr $i*$num_col+$j];

    
        set x_pos [expr $x_start+$j*($x_dim/$num_col)];#grid settings
        set y_pos [expr $y_start+$i*($y_dim/$num_row)];#grid settings
    
    $W($m) set X_ $x_pos;
    $W($m) set Y_ $y_pos;
    $W($m) set Z_ 0.0
    #puts -nonewline $topofile "$m x: [$W($m) set X_] y: [$W($m) set Y_] \n"
    }
    incr i;
}; 


#puts "node creation complete"
#puts "initializing duplex links"
################### PARALLEL FLOW ##########################
set i 0 
while {$i < $num_row} {

    for {set j 0} {$j < [expr $num_col-1] } {incr j} {
#in same row
    set m [expr $i*$num_col+$j]; #link grid[i][j] and grid[i][j+1]
    set n [expr $i*$num_col+[expr $j+1]];
    $ns_ duplex-link $W($m) $W($n) 1Mb 10ms DropTail
   # puts -nonewline $topofile "Link between: $m --- $n\n"
    }
    incr i;
};
#puts "done with establishing PARALLEL links"
#puts "starting with cross links"

set j 0 
while {$j < $num_col} {

    for {set i 0} {$i < [expr $num_row-1] } {incr i} {
#in same row
    set m [expr $i*$num_col+$j]; #link grid[i][j] and grid[i+1][j]
    set n [expr [expr $i+1]*$num_col+$j];
    $ns_ duplex-link $W($m) $W($n) 1Mb 10ms DropTail
  #  puts -nonewline $topofile "Link between: $m --- $n\n"

    }
    incr j;
};
#puts "done with establishing CROSS links"

set max [expr $num_wired_nodes-1]
$ns_ duplex-link $W($max) $BS(0) 5Mb 2ms DropTail

# setup TCP connections
set num_random_flow [lindex $argv 1]
set max_wired [expr $num_wired_nodes-1]
set max_wireless [expr $opt(nn)-1]
set i 0
while {$i < $num_random_flow } {
    set x [expr int($max_wired*rand())]
    set y [expr int($max_wireless*rand())]
    set tcp($i) [new Agent/TCP]
$tcp($i) set class_ 2
set sink($i) [new Agent/TCPSink]
$ns_ attach-agent $W($x) $tcp($i)
$ns_ attach-agent $node_($y) $sink($i)
$ns_ connect $tcp($i) $sink($i)
set ftp($i) [new Application/FTP]
$ftp($i) attach-agent $tcp($i)
$ns_ at $opt(ftp1-start) "$ftp($i) start"
    incr i
}





# source connection-pattern and node-movement scripts
if { $opt(cp) == "" } {
	puts "*** NOTE: no connection pattern specified."
        set opt(cp) "none"
} else {
	puts "Loading connection pattern..."
	source $opt(cp)
}
if { $opt(sc) == "" } {
	puts "*** NOTE: no scenario file specified."
        set opt(sc) "none"
} else {
	puts "Loading scenario file..."
	source $opt(sc)
	puts "Load complete..."
}

# Define initial node position in nam

for {set i 0} {$i < $opt(nn)} {incr i} {

    # 20 defines the node size in nam, must adjust it according to your
    # scenario
    # The function must be called after mobility model is defined

    $ns_ initial_node_pos $node_($i) 20
}     

# Tell all nodes when the simulation ends
for {set i } {$i < $opt(nn) } {incr i} {
    $ns_ at $opt(stop).0 "$node_($i) reset";
}
$ns_ at $opt(stop).0 "$BS(0) reset";

$ns_ at $opt(stop).0002 "puts \"NS EXITING...\" ; $ns_ halt"
$ns_ at $opt(stop).0001 "stop"
proc stop {} {
    global ns_ tracefd namtrace
#    $ns_ flush-trace
    close $tracefd
    close $namtrace
}

# informative headers for CMUTracefile
puts $tracefd "M 0.0 nn $opt(nn) x $opt(x) y $opt(y) rp \
	$opt(adhocRouting)"
puts $tracefd "M 0.0 sc $opt(sc) cp $opt(cp) seed $opt(seed)"
puts $tracefd "M 0.0 prop $opt(prop) ant $opt(ant)"

puts "Starting Simulation..."
$ns_ run


