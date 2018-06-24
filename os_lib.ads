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

--  This package "extends" System.Os_Lib with some posix calls that
--  were not given c language bindings.  This package should really be
--  a subpackage of System.  But because the compiler will not allow
--  one to extend or add to System in such a way, we have resorted to
--  the following implementation.
package Os_Lib is
   pragma Pure;
end Os_Lib;
