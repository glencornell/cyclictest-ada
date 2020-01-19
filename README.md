# cyclictest-ada

Cyclictest program written in Ada.

## Overview

This program is a (very) simplified version of the cyclictest program.
My objectives when writing this program were to:

1. learn how to utilize Ada native language real-time features and

2. to create an Ada program that performs properly on a POSIX.4
real-time compliant operating system utilizing as little OS-specific
real-time features as possible.

In this manner, one can use this code as one possible implementation
for portable real-time applications in Ada on POSIX-compliant
operating systems.

The following was used as a reference guide for the creation of this
program:

https://wiki.linuxfoundation.org/realtime/documentation/howto/applications/application_base

This application also serves as a test that measures the jitter of a
real-time Ada application on your system, similar to the cyclictest
program distributed with the rt-tests package.

## Compiling

```
gprbuild -P cyclictest.gpr cyclictest
```

## Running

```
./cyclictest
```

## Notes

The program should be run as root (to lock process virtual memory in
RAM and set task priority).

## TODO

* Add a sigint handler to prevent the program from being interrupted.

* Create an uninstrumented form of the
  generic_instrumented_cyclic_tasks package.

* Add processor affinity to the task as a creation option.

* Add an option to print out a histogram of jitter samples.
