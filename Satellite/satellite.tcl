global ns
set ns [new Simulator]
proc attach-cbr-traffic { node sink size interval rate } {
    #Get an instance of the simulator
    set ns [Simulator instance]

    #Create a UDP agent and attach it to the node
    set source [new Agent/UDP]
    $ns attach-agent $node $source

    #Create an Expoo traffic agent and set its configuration parameters
    set traffic [new Application/Traffic/CBR]
    $traffic set interval_ 6
        # Attach traffic source to the traffic generator
    $traffic attach-agent $source
    #Connect the source and the sink
    $ns connect $source $sink
    return $traffic
}
proc rand_range {min max} { return [expr (rand()*($max-$min+1)) + $min] }
proc rand_range_int {min max} { return [expr int(rand()*($max-$min+1)) + $min] }
# Global configuration parameters
# We'll set these global options for the satellite terminals

global opt
set opt(chan)           Channel/Sat
set opt(bw_up)      2Mb
set opt(bw_down)    2Mb
set opt(phy)            Phy/Sat
set opt(mac)            Mac/Sat
set opt(ifq)            Queue/DropTail
set opt(qlim)       50
set opt(ll)             LL/Sat
set opt(wiredRouting)   OFF

# XXX This tracing enabling must precede link and node creation 
set outfile [open traceFile.tr w]
$ns trace-all $outfile

set num_node [lindex $argv 0]
# Set up satellite and terrestrial nodes

# Configure the node generator for bent-pipe satellite
# geo-repeater uses type Phy/Repeater
$ns node-config -satNodeType geo-repeater \
        -phyType Phy/Repeater \
        -channelType $opt(chan) \
        -downlinkBW $opt(bw_down)  \
        -wiredRouting $opt(wiredRouting)

# GEO satellite at 95 degrees longitude West
set n1 [$ns node]
$n1 set-position -95

# Configure the node generator for satellite terminals
$ns node-config -satNodeType terminal \
                -llType $opt(ll) \
                -ifqType $opt(ifq) \
                -ifqLen $opt(qlim) \
                -macType $opt(mac) \
                -phyType $opt(phy) \
                -channelType $opt(chan) \
                -downlinkBW $opt(bw_down) \
                -wiredRouting $opt(wiredRouting)

# Two terminals: one in NY and one in SF
# set x_pos [expr int($x_dim*rand())] ;#random settings
set max [expr $num_node-1]
for {set i 2} {$i < $max} {incr i} {
    set x [rand_range 30 50]
  

    set y [rand_range -125 -70]
    

    set n_($i) [$ns node]
$n_($i) set-position $x $y
    }







set n_($max) [$ns node]
$n_($max) set-position 37.8 -122.4; # SF

# Add GSLs to geo satellites
for {set i 2} {$i < $max} {incr i} {
    $n_($i) add-gsl geo $opt(ll) $opt(ifq) $opt(qlim) $opt(mac) $opt(bw_up) \
    $opt(phy) [$n1 set downlink_] [$n1 set uplink_]
}


  
$n_($max) add-gsl geo $opt(ll) $opt(ifq) $opt(qlim) $opt(mac) $opt(bw_up) \
    $opt(phy) [$n1 set downlink_] [$n1 set uplink_]

# Add an error model to the receiving terminal node
set em_ [new ErrorModel]
$em_ unit pkt
$em_ set rate_ 0.02
$em_ ranvar [new RandomVariable/Uniform]
$n_($max) interface-errormodel $em_ 

$ns trace-all-satlinks $outfile

# Attach agents for CBR traffic generator 
set j 0 
set flow [lindex $argv 1]

set k [expr $max-1]
for {set j 0} {$j < $flow} {incr j} {

     set null_($j) [new Agent/Null]
    $ns attach-agent $n_($max) $null_($j) 
    set i [rand_range_int 2 $k] 
    set source_($j) [attach-cbr-traffic $n_($i) $null_($j) 200 6 5]
    set tcp_($j) [$ns create-connection TCP $n_($i) TCPSink $n_($max) 0]
        set ftp_($j) [$tcp_($j) attach-app FTP]
        $ns at 7.0 "$ftp_($j) produce 100"
}
  

   
# Attach agents for FTP  



# We use centralized routing
set satrouteobject_ [new SatRouteObject]
$satrouteobject_ compute_routes

for {set i 0} {$i < $flow} {incr i} {
   $ns at 1.0 "$source_($i) start"

}


$ns at 100.0 "finish"

proc finish {} {
    global ns outfile
    $ns flush-trace
    close $outfile

    exit 0
}

$ns run
