ns wireless_802_15_4.tcl 20 10 100 2
awk -f BonusAwk.awk traceFile.tr > debug.out

gnuplot -c "plotGraph.sh" "Node_PerNodeThroughput" "Node" "PerNodeThroughput" "Nodes_vs_Throughput.dat" "Node_PerNodeThroughput"
