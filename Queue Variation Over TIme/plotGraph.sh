#print "script name        : ", ARG0
#print "first argument     : ", ARG1
#print "second argument     : ", ARG2
#print "third argument     : ", ARG3 
#print "fourth argument     : ", ARG4
#print "fifth argument     : ", ARG5
#print "number of arguments: ", ARGC 


set title ARG1
set xlabel ARG2
set ylabel ARG3
set grid
plot ARG4 with linespoints title ARG1 ;

set term png
set output ARG5
replot
