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


with Ada.Real_Time;
with Ada.Text_Io;

package body Generic_Instrumented_Cyclic_Tasks is
   use type Ada.Real_Time.Time;
   use type Ada.Real_Time.Time_Span;
   
   --  Used in calculation of jitter metrics
   function Max(A : in Ada.Real_Time.Time_Span;
		B : in Ada.Real_Time.Time_Span) return Ada.Real_Time.Time_Span is
   begin
      if A > B then
	 return A;
      end if;
      return B;
   end Max;
   
   function Min(A : in Ada.Real_Time.Time_Span;
		B : in Ada.Real_Time.Time_Span) return Ada.Real_Time.Time_Span is
   begin
      if A < B then
	 return A;
      end if;
      return B;
   end Min;
   
   task body Private_Cyclic_Task is
      -- User-defined state data:
      User_Data : T;
      
      -- Periodic state data
      Terminated : Boolean := False;
      Next : Ada.Real_Time.Time;
      Now : Ada.Real_Time.Time;
      Period : constant Ada.Real_Time.Time_Span :=
	Ada.Real_Time.Microseconds (Period_In_Microseconds);
      
      -- Jitter metrics
      Jitter : Ada.Real_Time.Time_Span := Ada.Real_Time.Time_Span_Zero;
      Min_Jitter : Ada.Real_Time.Time_Span := Ada.Real_Time.Time_Span_Last;
      Max_Jitter : Ada.Real_Time.Time_Span := Ada.Real_Time.Time_Span_Zero;
      Avg_Jitter : Ada.Real_Time.Time_Span := Ada.Real_Time.Time_Span_Zero;
      Accumulated_Jitter : Ada.Real_Time.Time_Span := Ada.Real_Time.Time_Span_Zero;
      Number_Of_Jitter_Samples : Positive := 1;
      
   begin
      accept On_Start_Entry do
	 On_Start(User_Data);
      end On_Start_Entry;
      Next := Ada.Real_Time.Clock + Period;
      while not Terminated loop
	 -- Sleep for a duration:
	 delay until Next;
	 
	 -- Perform the periodic activity
	 On_Tick(User_Data, Terminated);
	 
	 --  Grab the actual wake-up time
	 Now := Ada.Real_Time.Clock;
	 
	 --  Calculate the jitter metrics...
	 Jitter := Now - Next;
	 Min_Jitter := Min(Min_Jitter, Jitter);
	 Max_Jitter := Max(Max_Jitter, Jitter);
	 begin
	    --  Increment the accumulated jitter within a declarative
	    --  block to prevent overflow
	    Accumulated_Jitter := Accumulated_Jitter + Jitter;
	    Number_Of_Jitter_Samples := Number_Of_Jitter_Samples + 1;
	 exception
	    when others =>
	       -- Print out metrics
	       Ada.Text_Io.Put_Line("Overflow reached.  Current metrics:");
	       Ada.Text_Io.Put_Line("  Number of Samples " & Ascii.Ht & Positive'Image(Number_Of_Jitter_Samples));
	       Ada.Text_Io.Put_Line("  Minimum Jitter (s)" & Ascii.Ht & Duration'Image(Ada.Real_Time.To_Duration(Min_Jitter)));
	       Ada.Text_Io.Put_Line("  Maximum Jitter (s)" & Ascii.Ht & Duration'Image(Ada.Real_Time.To_Duration(Max_Jitter)));
	       Ada.Text_Io.Put_Line("  Average Jitter (s)" & Ascii.Ht & Duration'Image(Ada.Real_Time.To_Duration(Avg_Jitter)));
	       
	       -- Reset accumulated values to initial conditions
	       Accumulated_Jitter := Jitter;
	       Number_Of_Jitter_Samples := 1;
	       Now := Ada.Real_Time.Clock;
	 end;
	 --  Calculate the running average jitter.
	 Avg_Jitter := Accumulated_Jitter / Number_Of_Jitter_Samples;
	 
	 --  Final step: calculate the next time to wake up...
	 Next := Now + Period;
      end loop;
      
      -- Print out metrics
      Ada.Text_Io.Put_Line("Task terminated.  Current metrics:");
      Ada.Text_Io.Put_Line("  Number of Samples " & Ascii.Ht & Positive'Image(Number_Of_Jitter_Samples));
      Ada.Text_Io.Put_Line("  Minimum Jitter (s)" & Ascii.Ht & Duration'Image(Ada.Real_Time.To_Duration(Min_Jitter)));
      Ada.Text_Io.Put_Line("  Maximum Jitter (s)" & Ascii.Ht & Duration'Image(Ada.Real_Time.To_Duration(Max_Jitter)));
      Ada.Text_Io.Put_Line("  Average Jitter (s)" & Ascii.Ht & Duration'Image(Ada.Real_Time.To_Duration(Avg_Jitter)));
      Ada.Text_Io.New_Line;
      
      -- Invoke the user's on_stop callback:
      On_Stop(User_Data);
   end Private_Cyclic_Task;
   
   procedure Start (This : in out Cyclic_Task) is
   begin
      This.The_Task.On_Start_Entry;
   end Start;
end Generic_Instrumented_Cyclic_Tasks;
