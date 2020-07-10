if { $argc != 3 } {
    puts "Please pass parameters properly"
	puts "Format : ns <tcl filename> <#nodes> <#flows> <#packets per sec>"
	puts "Example : ns WirelessUDP.tcl 25 10 500"
	exit 0;
    }
  #Create a simulator object
set ns [new Simulator]
 #to use dynamic routing
$ns rtproto DV
#Open the nam trace file
set nt [open traceFile.tr w]
$ns trace-all $nt
set nf [open out.nam w]
$ns namtrace-all $nf

set topo_file topology.txt
set topofile [open $topo_file "w"]

 Queue/RED set q_weight_   0.002       
    Queue/RED set thresh_     10
    Queue/RED set maxthresh_  20
    Queue/RED set setbit_     true

#Define a 'finish' procedure
proc finish {} {
        global ns nf nt 
        $ns flush-trace
	#Close the trace file
        close $nf
        close $nt
       # exec nam out.nam &
        exit 0
}
proc attach-cbr-traffic { node sink size interval } {
	#Get an instance of the simulator
	set ns [Simulator instance]

	#Create a UDP agent and attach it to the node
	set source [new Agent/UDP]
	$ns attach-agent $node $source

	#Create an Expoo traffic agent and set its configuration parameters
	set traffic [new Application/Traffic/CBR]
	$traffic set packetSize_ $size
	$traffic set interval_ $interval
        
        # Attach traffic source to the traffic generator
    $traffic attach-agent $source
	#Connect the source and the sink
	$ns connect $source $sink
	return $traffic
}

proc attach-cbr-traffic-tcp { node sink interval } {
	#Get an instance of the simulator
	set ns [Simulator instance]

	#Create a UDP agent and attach it to the node
	set source [new Agent/TCP]
	$source set windowOption_ 99
	$ns attach-agent $node $source

	#Create an Expoo traffic agent and set its configuration parameters
	set traffic [new Application/Traffic/CBR]
	$traffic set interval_ $interval
        
        # Attach traffic source to the traffic generator
    $traffic attach-agent $source
	#Connect the source and the sink
	$ns connect $source $sink
	return $traffic
}
#define  #rows and #columns

set x_dim 1000
set y_dim 1000
set num_random_flow [lindex $argv 1]
set num_node [lindex $argv 0]
set num_row 10
set num_col [expr $num_node/10]

set pkt_per_sec [lindex $argv 2]
set cbr_interval [expr 1.0/$pkt_per_sec]
# #[expr 1/$pkt_per_sec]
#set grid settings / 1 for grid / 0 for random config
set grid 1

set isTCP 0
#puts "initializing nodes"
for {set i 0} {$i < [expr $num_row*$num_col]} {incr i} {
	set node_($i) [$ns node]
	#$node_($i) random-motion 0
}


#positioning of the nodes
set x_start [expr $x_dim/($num_col*2)];
set y_start [expr $y_dim/($num_row*2)];
set i 0;
while {$i < $num_row } {
#in same column
    for {set j 0} {$j < $num_col } {incr j} {
#in same row
	set m [expr $i*$num_col+$j];

	if {$grid == 1} {
		set x_pos [expr $x_start+$j*($x_dim/$num_col)];#grid settings
		set y_pos [expr $y_start+$i*($y_dim/$num_row)];#grid settings
	} else {
		set x_pos [expr int($x_dim*rand())] ;#random settings
		set y_pos [expr int($y_dim*rand())] ;#random settings
	}
	$node_($m) set X_ $x_pos;
	$node_($m) set Y_ $y_pos;
	$node_($m) set Z_ 0.0
	puts -nonewline $topofile "$m x: [$node_($m) set X_] y: [$node_($m) set Y_] \n"
    }
    incr i;
}; 

if {$grid == 1} {
	#puts "GRID topology"
} else {
	#puts "RANDOM topology"
}
#puts "node creation complete"
#puts "initializing duplex links"
################### PARALLEL FLOW ##########################
set i 0 
while {$i < $num_row} {

	for {set j 0} {$j < [expr $num_col-1] } {incr j} {
#in same row
	set m [expr $i*$num_col+$j]; #link grid[i][j] and grid[i][j+1]
	set n [expr $i*$num_col+[expr $j+1]];
	$ns duplex-link $node_($m) $node_($n) 1Mb 10ms RED
	puts -nonewline $topofile "Link between: $m --- $n\n"
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
	$ns duplex-link $node_($m) $node_($n) 1Mb 10ms RED
	puts -nonewline $topofile "Link between: $m --- $n\n"

    }
    incr j;
};
#puts "done with establishing CROSS links"
set server 0
set total [expr $num_col*$num_row]
set client [expr $total-1]

if {$isTCP == 1} {
	
	set tcp [new Agent/TCP]


for {set i 0} {$i < [expr $num_random_flow]} {incr i} {
	set sink_($i) [new Agent/TCPSink]

}
set max [expr $num_node-1]
set i 0
while {$i < $num_random_flow } {
	set x [expr int($max*rand())]
	set y [expr int($max*rand())]
	if {$x != $y} {
	$ns attach-agent $node_($x) $sink_($i)	
	set source_($i) [attach-cbr-traffic-tcp $node_($y) $sink_($i) $cbr_interval]
	puts -nonewline $topofile " Src: $y Dest: $x\n"
	incr i;
	}
	}


#Connecting sending and receiving transport agents

set startTime 0
set duration [expr $num_node/$num_random_flow]
for {set i 0} {$i < [expr $num_random_flow]} {incr i} {
	set startTime [expr $startTime+0.5]
	$ns at $startTime "$source_($i) start"
	puts -nonewline $topofile "$i starts at $startTime\n"

}
#puts "done starting all flows at $startTime "
set endTime [expr $startTime+0.5]
for {set i 0} {$i < [expr $num_random_flow]} {incr i} {
	set endTime [expr $endTime+0.5]
	$ns at $endTime "$source_($i) stop"
	puts -nonewline $topofile "$i ends at $endTime\n"
}
set finishTime [expr $endTime+0.5]
$ns at $finishTime "finish"

$ns run
$ns run
	} else {
		

		#setting null agents


for {set i 0} {$i < [expr $num_random_flow]} {incr i} {
	set null_($i) [new Agent/Null]

}

set max [expr $num_node-1]
set i 0
while {$i < $num_random_flow } {
	set x [expr int($max*rand())]
	set y [expr int($max*rand())]
	if {$x != $y} {
	$ns attach-agent $node_($x) $null_($i)	
	set source_($i) [attach-cbr-traffic $node_($y) $null_($i) 200 $cbr_interval]
	puts -nonewline $topofile " Src: $y Dest: $x\n"
	incr i;
	}
	}


set startTime 0
set duration [expr $num_node/$num_random_flow]
for {set i 0} {$i < [expr $num_random_flow]} {incr i} {
	set startTime [expr $startTime+0.5]
	$ns at $startTime "$source_($i) start"
	puts -nonewline $topofile "$i starts at $startTime\n"

}
#puts "done starting all flows at $startTime "
set endTime [expr $startTime+0.5]
for {set i 0} {$i < [expr $num_random_flow]} {incr i} {
	set endTime [expr $endTime+0.5]
	$ns at $endTime "$source_($i) stop"
	puts -nonewline $topofile "$i ends at $endTime\n"
}
set finishTime [expr $endTime+0.5]
$ns at $finishTime "finish"

$ns run
}
