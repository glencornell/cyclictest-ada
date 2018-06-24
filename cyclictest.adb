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

with Ada.Real_Time;
with Ada.Text_Io;
with Os_Lib.Posix;
with Interfaces.C;

procedure Cyclictest is
   --  ===============================================================
   --  STEP 2: Set the scheduler and process priority:
   --
   --  By setting the time slice (A.K.A. "tick") to zero, the Ada
   --  run-time task scheduler is prevented from waiting until a tick
   --  interval to schedule this task.
   pragma Time_Slice (0.0);
      
   use type Ada.Real_Time.Time;
   use type Ada.Real_Time.Time_Span;
   use type Interfaces.C.Int;
   use type Interfaces.C.Unsigned;
   
   type Diff_Array_Index_Type is range 1 .. 100_000;
   type Diff_Array_Type is array (Diff_Array_Index_Type) of Ada.Real_Time.Time_Span;

   Now : Ada.Real_Time.Time;
   Next : Ada.Real_Time.Time;
   Interval : constant Ada.Real_Time.Time_Span := Ada.Real_Time.Microseconds(250);
   Diff_Array : Diff_Array_Type;
   --  Diff_Array contains the jitter measurements.
   
   -- Jitter values
   Jitter : Ada.Real_Time.Time_Span := Ada.Real_Time.Time_Span_Zero;
   Min_Jitter : Ada.Real_Time.Time_Span := Ada.Real_Time.Time_Span_Last;
   Max_Jitter : Ada.Real_Time.Time_Span := Ada.Real_Time.Time_Span_Zero;
   Avg_Jitter : Ada.Real_Time.Time_Span := Ada.Real_Time.Time_Span_Zero;
   Accumulated_Jitter : Ada.Real_Time.Time_Span := Ada.Real_Time.Time_Span_Zero;
   Number_Of_Jitter_Samples : Positive := 1;
   
   --  Used in calculation of jitter metrics
   function Max(A : in Ada.Real_Time.Time_Span;
		B : in Ada.Real_Time.Time_Span) return Ada.Real_Time.Time_Span is
      use type Ada.Real_Time.Time_Span;
   begin
      if A > B then
	 return A;
      end if;
      return B;
   end Max;
   
   function Min(A : in Ada.Real_Time.Time_Span;
		B : in Ada.Real_Time.Time_Span) return Ada.Real_Time.Time_Span is
      use type Ada.Real_Time.Time_Span;
   begin
      if A < B then
	 return A;
      end if;
      return B;
   end Min;

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
   
   --  ===============================================================
   --  Main data collection loop.  This loop sleeps for a bit and then
   --  stores the difference between the expected and actual wake-up
   --  times (jitter).  The loop iterates over the size of the data
   --  collection array.
   Now := Ada.Real_Time.Clock;
   Next := Now + Interval;
   for I in Diff_Array_Index_Type'Range loop
      --  An Ada "delay until" statement maps to a POSIX.4-compliant
      --  sleep statement, such as clock_nanosleep(), which utilizes
      --  the system's monotonic clock.  The language also guarantees
      --  that the delay is no less than the specified duration.
      delay until Next;
      
      --  This is where you would perform your cyclic activity...
      
      --  Grab the actual wake-up time
      Now := Ada.Real_Time.Clock;

      --  Calculate the jitter metrics...
      Jitter := Now - Next;
      Min_Jitter := Min(Min_Jitter, Jitter);
      Max_Jitter := Max(Max_Jitter, Jitter);
      begin
	 --  Calculate the running average jitter.  The declarative
	 --  block is necessary to prevent overflow.
	 Accumulated_Jitter := Accumulated_Jitter + Jitter;
	 Number_Of_Jitter_Samples := Number_Of_Jitter_Samples + 1;
      exception
	 when others =>
	    Accumulated_Jitter := Jitter;
	    Number_Of_Jitter_Samples := 1;
      end;
      Avg_Jitter := Accumulated_Jitter / Number_Of_Jitter_Samples;
      Diff_Array(I) := Jitter;
      
      --  Final step: calculate the next time to wake up...
      Next := Next + Interval;
   end loop;
   
   Ada.Text_Io.Put_Line("Minimum Jitter (s)" & Ascii.Ht & Duration'Image(Ada.Real_Time.To_Duration(Min_Jitter)));
   Ada.Text_Io.Put_Line("Maximum Jitter (s)" & Ascii.Ht & Duration'Image(Ada.Real_Time.To_Duration(Max_Jitter)));
   Ada.Text_Io.Put_Line("Average Jitter (s)" & Ascii.Ht & Duration'Image(Ada.Real_Time.To_Duration(Avg_Jitter)));
   
   Ada.Text_Io.Put_Line("Jitter Samples");
   for I in Diff_Array_Index_Type'Range loop
      Ada.Text_Io.Put_Line(Duration'Image(Ada.Real_Time.To_Duration(Diff_Array(I))));
   end loop;
end Cyclictest;
