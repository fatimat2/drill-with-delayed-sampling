import threading
import os
import Queue
import sys

def worker():
        while True:
                try:
                        j = q.get(block = 0)
                except Queue.Empty:
                        return
                #Make directory to save results
                os.system('mkdir '+j[1])
                os.system(j[0])

q = Queue.Queue()
outer_dir = sys.argv[1]
os.system('mkdir '+outer_dir)

sim_end=1000000000
link_rate=10
mean_link_delay=0.0000002
host_delay=0.000020
queueSize=50
connections_per_pair=8
meanFlowSize=1138*1460
paretoShape=1.05
flow_cdf='CDF_search.tcl'

initWindow=12
ackRatio=1
max_rto=2
min_rto=0.0002
prob_cap_=5

topology_spt=4
topology_tors=8
topology_spines=10
topology_x=1.25

enable_tr = 0
load_arr = [0.9,0.8,0.7,0.6,0.5,0.4,0.3,0.2,0.1]
interval_arr = [0.1,0.01,0.001,0.0001]

ns_path = 'ns'
sim_script = 'run.tcl'

for load in load_arr:
        #Simulation command
        cmd = ns_path+' '+sim_script+' '\
                +str(sim_end)+' '+str(link_rate)+' '+str(mean_link_delay)+' '+str(host_delay)+' '+str(queueSize)+' '\
                +str(load)+' '+str(connections_per_pair)+' '+str(meanFlowSize)+' '+str(paretoShape)+' '+str(flow_cdf)+' '\
                +str(topology_spt)+' '+str(topology_tors)+' '+str(topology_spines)+' '+str(topology_x)+' '\
                +str(ackRatio)+' '+str(max_rto)+' '+str(initWindow)+' '+str(min_rto)+' '+str(prob_cap_)+' '\
                +str(enable_tr)+' '

        for interval in interval_arr:
                dir_name = '/piu:%f-%d' % (interval, int(load*100))
                dir_name = outer_dir+dir_name.lower()
                q.put([cmd+'4 '+str(interval)+' ./'+dir_name+'/ > ./'+dir_name+'/logFile.tr', dir_name])

                dir_name = '/cu:%f-%d' % (interval, int(load*100))
                dir_name = outer_dir+dir_name.lower()
                q.put([cmd+'6 '+str(interval)+' ./'+dir_name+'/ > ./'+dir_name+'/logFile.tr', dir_name])

        dir_name = '/rps-%d' % (int(load*100))
        dir_name = outer_dir+dir_name.lower()
        q.put([cmd+'1 0 ./'+dir_name+'/ > ./'+dir_name+'/logFile.tr', dir_name])

        dir_name = '/ecmp-%d' % (int(load*100))
        dir_name = outer_dir+dir_name.lower()
        q.put([cmd+'2 0 ./'+dir_name+'/ > ./'+dir_name+'/logFile.tr', dir_name])

        dir_name = '/drill-%d' % (int(load*100))
        dir_name = outer_dir+dir_name.lower()
        q.put([cmd+'3 0 ./'+dir_name+'/ > ./'+dir_name+'/logFile.tr', dir_name])

        dir_name = '/ppu-%d' % (int(load*100))
        dir_name = outer_dir+dir_name.lower()
        q.put([cmd+'5 0 ./'+dir_name+'/ > ./'+dir_name+'/logFile.tr', dir_name])


#Create all worker threads
threads = []
number_worker_threads = 30

#Start threads to process jobs
for i in range(number_worker_threads):
        t = threading.Thread(target = worker)
        threads.append(t)
        t.start()

#Join all completed threads
for t in threads:
        t.join()

