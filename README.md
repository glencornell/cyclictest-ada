# cyclictest-ada

Cyclictest program written in Ada.

## Overview

This program is a (very) simplified version of the cyclictest program.
My objectives when writing this program were 1) to learn how to
utilize Ada native language real-time features and 2) to create an Ada
program that performs properly on a POSIX.4 real-time compliant
operating system utilizing as little OS-specific real-time features as
possible.  In this manner, one can use this code as one possible
implementation for portable real-time applications in Ada on
POSIX-compliant operating systems.

The following was used as a reference guide for the creation of this
program:

https://wiki.linuxfoundation.org/realtime/documentation/howto/applications/application_base

This application also serves as a test that measures the jitter of a
real-time Ada application on your system, similar to the cyclictest
program distributed with the rt-tests package.

## Compiling

```
gprbuild -P cyclictest.gpr cyclictest
'''

## Running

```
./cyclictest | tee output.txt | head
'''

Text emitted on standard output can be used to generate a histogram or
scatter plot using your favorite plotting program (such as gnuplot).

## Notes

The program should be run as root (to lock process virtual memory in
RAM and set task priority).

## TODO

* Add a sigint handler to prevent the program from being interrupted.

* Refactor the code into a generic cyclic task that performs the
  mechanics of this program, yet allows one to add their own
  subprogram which is invoked periodically.  This would be a good
  starting point for other real-time programs.
