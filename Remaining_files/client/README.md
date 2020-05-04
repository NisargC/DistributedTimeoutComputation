##JustInTimeout Client Shim

1. Open the source in IntelliJ Idea
1. Do a full rebuild to download maven dependencies
1. Run the configuration GenerateJar
1. It'll ask for Java/Lib path. Provide a complete path - for example /Library/Java/JavaVirtualMachines/jdk1.8.0_241.jdk/Contents/Home/jre/lib/ on a Mac
1. Next you'll need the path for the maven dependencies - enter that. For example aspectjrt on my machine is at /Users/yashtrivedi/.m2/repository/org/aspectj/aspectjrt/1.9.5/aspectjrt-1.9.5.jar
1. This will generate a jar - weavedjre.jar note the path, it'll be used in acmeairclient


##Plotting the graphs

1. The python file to plot the graphs is under src/main/resources - plot.py
1. Install matplotlib using - pip3 install matplotlib
1. If not running acmeair client using kubernetes
    1. Put the python file in the same location as  data_*.csv generated in the acmeairclient root directory. 
    1. Comment lines 86 and 87
    1. Run python3 plot.py
1. If running acmeairclient on kubernetes
    1. Get the kube pod name
    1. Run python3 plot.py <pod name>
    1. This will fetch the csv files at regular interval from the pod and update the graphs.