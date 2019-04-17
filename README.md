DRILL under Delayed Sampling
=============================

An ns2.35 patch for DRILL under Delayed Sampling.

In the TCL script, add:
Classifier/MultiPath set mp_proto <protocol>
Classifier/MultiPath set samplingDelay <delay>
Classifier/MultiPath set a_log <logging>

where   protocol =  1 - for ECMP
                    2 - for DRILL
                    3 - for DRILL with Per Interval Updates
                    4 - for DRILL with Per Packet Updates
                    5 - for DRILL with Combined Updates

        delay = xxx ms - can be set to any amount in ms and is only used when protocol = 3 || 5

        a_log = 0 - when using trace files and queue monitors
                1 - when using flow logs

