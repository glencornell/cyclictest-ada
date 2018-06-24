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
with Interfaces.C;

package Os_Lib.Posix is
   pragma Preelaborate;
   
   subtype Int is Interfaces.C.Int;
   subtype Unsigned is Interfaces.C.Unsigned;
   
   --------------------
   -- Memory Locking --
   --------------------
   
   MCL_CURRENT : constant := 1;
   MCL_FUTURE  : constant := 2;
   MCL_ONFAULT : constant := 4;
   
   function Mlockall (Flags : in Unsigned) return Int;
   pragma Import (C, Mlockall, "mlockall");
   
   ------------------------
   -- Process Management --
   ------------------------
   
   function Geteuid return Int;
   pragma Import (C, Geteuid, "geteuid");
   
end Os_Lib.Posix;

