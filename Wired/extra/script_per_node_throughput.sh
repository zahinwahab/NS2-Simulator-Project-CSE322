rm -rf queueSize
mkdir queueSize
ns wired.tcl 40 10 100 #$nodes $flows $packets_per_sec
awk -f extra.awk traceFile.tr > debug.out
gnuplot -c "plotGraph.sh" "PerNode_Throughput" "Node_Number" "Throughput" "PerNode_Throughput.dat" "PerNode_Throughput"

mv *.dat queueSize




