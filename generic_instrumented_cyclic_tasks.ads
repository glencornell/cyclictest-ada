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


with System;

--  The generic cyclic task is a data structure encapsulating a task
--  object which invokes a procedure at a fixed rate.

generic
   --  State data that you provide and is maintained by the cyclic
   --  task.
   type T is limited private;

   --  Callback invoked when the task is started.  You are expected to
   --  initialize your state information to its initial condition.
   with procedure On_Start (Item : in out T);
   
   --  Callback invoked upon each iteration of the task loop.  You are
   --  expected to modify the state data.  If you wish to terminate
   --  the task within your callback, set the terminated parameter to
   --  True.
   with procedure On_Tick (Item : in out T; Terminated : out Boolean);
   
   --  Callback invoked upon the completion of the acyclic task.
   with procedure On_Stop (Item : in out T);
   
package Generic_Instrumented_Cyclic_Tasks is
   
   type Cyclic_Task (Task_Priority : System.Priority;
		     Period_In_Microseconds : Natural) is tagged limited private;
   
   --  Start the cyclic task.
   procedure Start (This : in out Cyclic_Task);
   
private
   task type Private_Cyclic_Task (Task_Priority : System.Priority;
				  Period_In_Microseconds : Natural) is
      pragma Priority(Task_Priority);
      
      entry On_Start_Entry;
   end Private_Cyclic_Task;
   
   type Cyclic_Task (Task_Priority : System.Priority;
		     Period_In_Microseconds : Natural) is tagged limited
      record
	 The_Task : Private_Cyclic_Task (Task_Priority, Period_In_Microseconds);
      end record;
   
end Generic_Instrumented_Cyclic_Tasks;
