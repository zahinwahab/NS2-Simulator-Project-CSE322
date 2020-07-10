#!/bin/bash

#The metrics to be calculated
throughput=0.0
delay=0.0
delivery_ratio=0.0
drop_ratio=0.0
mkdir Graphs
cd Graphs
rm -rf throughput.dat
rm -rf delay.dat
rm -rf delivery_ratio.dat
rm -rf drop_ratio.dat


cd ..
#temp files to store the points for the graphs
th=Graphs/throughput.dat #for throughput
d=Graphs/delay.dat #for end-to-end delay 
de=Graphs/delivery_ratio.dat #for delivery ratio
dr=Graphs/drop_ratio.dat #for drop ratio

simulate()
{
	nodes=$1
	flows=$2

	throughput=0.0
	delay=0.0
	delivery_ratio=0.0
	drop_ratio=0.0
	

	
	r=1
	it=5
	itf=5.0
	while [ $r -le $it ]
	do
	echo "Iteration $(($r + 0)) starting"
	
	ns satellite.tcl $nodes $flows # 40 10 100 #$nodes $flows $packets_per_sec
	awk -f AWK_satellite.awk traceFile.tr > output.out
	i=0
	while read val
	do
	if [ $i = 0 ]; then
		throughput=$(echo "scale=5; $throughput+$val/$itf" | bc)
	elif [ $i = 1 ]; then
		delay=$(echo "scale=5; $delay+$val/$itf" | bc)
	elif [ $i = 2 ]; then
		delivery_ratio=$(echo "scale=5; $delivery_ratio+$val/$itf" | bc)
	elif [ $i = 3 ]; then
		drop_ratio=$(echo "scale=5; $drop_ratio+$val/$itf" | bc)
	fi
	
	let i=$(($i+1))
	done < output.out 
	echo "Iteration $(($r + 0)) finished"
	r=$(($r+1))
	done
	
	
	echo "Throughput     : $throughput"
	echo "Delay          : $delay"
	echo "Delivery Ratio : $delivery_ratio"
	echo "Drop Ratio     : $drop_ratio"
}
	

#		Varies number of nodes
#		Takes the outputs and stores them in tmp files
#		Then plots graphs



#		Varies transmission range
#		Takes the outputs and stores them in tmp files
#		Then plots graphs

nodes()
{
	for(( iteration=20;iteration<=100;iteration+=20))
	do
		echo "Simulating with $iteration nodes"
		simulate $iteration 10
		echo "$iteration $throughput" >> $th
		echo "$iteration $delay" >> $d
		echo "$iteration $delivery_ratio" >> $de
		echo "$iteration $drop_ratio" >> $dr
	done
	gnuplot -c "plotGraph.sh" "Nodes_Throughput" "Nodes" "Throughput" "$th" "Nodes_Throughput"
	gnuplot -c "plotGraph.sh" "Nodes_Delay" "Nodes" "Delay" "$d" "Nodes_Delay"
	gnuplot -c "plotGraph.sh" "Nodes_DeliveryRatio" "Nodes" "Delivery ratio" "$de" "Nodes_DeliveryRatio"
	gnuplot -c "plotGraph.sh" "Nodes_DropRatio" "Nodes" "Drop ratio" "$dr" "Nodes_DropRatio"
	#exec xgraph $th
}
flows()
{
	for(( iteration=10;iteration<=50;iteration+=10))
	do
		echo "Simulating with $iteration flows"
		simulate 20 $iteration 
		echo "$iteration $throughput" >> $th
		echo "$iteration $delay" >> $d
		echo "$iteration $delivery_ratio" >> $de
		echo "$iteration $drop_ratio" >> $dr
	done
	gnuplot -c "plotGraph.sh" "Flows_Throughput" "Flows" "Throughput" "$th" "Flows_Throughput"
	gnuplot -c "plotGraph.sh" "Flows_Delay" "Flows" "Delay" "$d" "Flows_Delay"
	gnuplot -c "plotGraph.sh" "Flows_DeliveryRatio" "Flows" "Delivery ratio" "$de" "Flows_DeliveryRatio"
	gnuplot -c "plotGraph.sh" "Flows_DropRatio" "Flows" "Drop ratio" "$dr" "Flows_DropRatio"
	#exec xgraph $th


}

echo "Running Wired Cum Wireless simulation"
echo "Which do you want on x-axis?"
echo "1. #nodes  2.#flows "
read choice

if [ $choice = "1" ]; then
	nodes
elif [ $choice = "2" ]; then
	flows
fi
rm -rf traceFile.tr
rm -rf out.nam

