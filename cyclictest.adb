--  Cyclictest program written in Ada.
--  Copyright (C) 2018 Glen Cornell <glen.m.cornell@gmail.com>
--  
--  This program is free software: you can redistribute it and/or
--  modify it under the terms of the GNU General Public License as
--  published by the Free Software Foundation, either version 3 of the
--  License, or (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
--  General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see
--  <http://www.gnu.org/licenses/>.


--  This program is a (very) simplified version of the cyclictest
--  program.  My objectives when writing this program were 1) to learn
--  how to utilize Ada native language real-time features and 2) to
--  create an Ada program that performs properly on a POSIX.4
--  real-time compliant operating system utilizing as little
--  OS-specific real-time features as possible.  In this manner, one
--  can use this code as one possible implementation for portable
--  real-time applications in Ada on POSIX-compliant operating
--  systems.
--
--  The following was used as a reference guide for the creation of
--  this program:
--  
--  https://wiki.linuxfoundation.org/realtime/documentation/howto/applications/application_base
--
--  This application also serves as a test that measures the jitter of
--  a real-time Ada application on your system, similar to the
--  cyclictest program distributed with the rt-tests package.
--
--  TODO:
--
--  * Add a sigint handler to prevent the program from being interrupted.
--

--  ==================================================================
--  STEP 1: Set the scheduler to SHCED_FIFO
--
--  This pragma is used to set the scheduling policy to SCHED_FIFO.
pragma Task_Dispatching_Policy (FIFO_Within_Priorities);

with Ada.Text_Io;
with Os_Lib.Posix;
with Generic_Instrumented_Cyclic_Tasks;
with System;
with Interfaces.C;

procedure Cyclictest is
   --  ===============================================================
   --  STEP 2: Set the scheduler and process priority:
   --
   --  By setting the time slice (A.K.A. "tick") to zero, the Ada
   --  run-time task scheduler is prevented from waiting until a tick
   --  interval to schedule this task.
   pragma Time_Slice (0.0);
   
   use type Interfaces.C.Int;
   use type Interfaces.C.Unsigned;
   
   type Task_Data is record
      Count : Natural;
      Max_Count : Positive;
   end record;
   procedure On_Start (Item : in out Task_Data) is 
   begin
      Item.Count     := 0;
      Item.Max_Count := 1_000_000;
   end On_Start;
   procedure On_Tick (Item : in out Task_Data; Terminated : out Boolean) is 
   begin
      Item.Count := Item.Count + 1;
      Terminated := Item.Count >= Item.Max_Count;
   end On_Tick;
   procedure On_Stop (Item : in out Task_Data) is
   begin
      null;
   end On_Stop;
   package Cyclic_Tasks is new Generic_Instrumented_Cyclic_Tasks 
     (T => Task_Data,
      On_Start => On_Start,
      On_Tick => On_Tick,
      On_Stop => On_Stop);
   
   T1 : Cyclic_Tasks.Cyclic_Task 
     (Task_Priority => System.Priority'Pred(System.Priority'Last),
      Period_In_Microseconds => 1000);
   
begin
   --  ===============================================================
   --  STEP 3: check for root effective user id and warn user
   if Os_Lib.Posix.Geteuid /= 0 
   then
      Ada.Text_Io.Put_Line("Warning: Program must be run as root to run in real-time.");
      Ada.Text_Io.Put_Line("         Continuing as regular user.  Results may be affected");
      Ada.Text_Io.Put_Line("         by virtual memory paging operations.");
   else
      --  ===============================================================
      --  STEP 4: Lock the virtual memory of the process into physical
      --  memory.
      --
      if Os_Lib.Posix.Mlockall (Os_Lib.Posix.Mcl_Current or Os_Lib.Posix.Mcl_Future) /= 0
      then
	 raise Program_Error with "mlockall() failed";
      end if;
   end if;
   
   T1.Start;
   
end Cyclictest;
