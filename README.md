# DRILL under Delayed Sampling

This repository contains the open source code for DRILL under Delayed Sampling.

## Getting Started

Install ns2.35 and apply the patch file named "drill_mod.patch".

## Running Scripts

In the TCL scripts, add:
```
Classifier/MultiPath set mp_proto <protocol>
Classifier/MultiPath set samplingDelay <delay>
Classifier/MultiPath set a_log <logging>
```

Change \<protocol> using the following key:
```
1 - for ECMP
2 - for DRILL
3 - for DRILL with Per Interval Updates
4 - for DRILL with Per Packet Updates
5 - for DRILL with Combined Updates
```

Set \<delay> as the update interval. This value is in milliseconds by default and is only used for Per Interval Updates and Combined Updates (when \<protocol> = 3 or 5)

Change \<a_log> using the following key:
```
0 - when using trace files and queue monitors
1 - when using flow logs
```
