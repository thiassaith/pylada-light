###############################
#  This file is part of PyLaDa.
#
#  Copyright (C) 2013 National Renewable Energy Lab
# 
#  PyLaDa is a high throughput computational platform for Physics. It aims to
#  make it easier to submit large numbers of jobs on supercomputers. It
#  provides a python interface to physical input, such as crystal structures,
#  as well as to a number of DFT (VASP, CRYSTAL) and atomic potential
#  programs. It is able to organise and launch computational jobs on PBS and
#  SLURM.
# 
#  PyLaDa is free software: you can redistribute it and/or modify it under the
#  terms of the GNU General Public License as published by the Free Software
#  Foundation, either version 3 of the License, or (at your option) any later
#  version.
# 
#  PyLaDa is distributed in the hope that it will be useful, but WITHOUT ANY
#  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
#  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
#  details.
# 
#  You should have received a copy of the GNU General Public License along
#  with PyLaDa.  If not, see <http://www.gnu.org/licenses/>.
###############################

if(tests)

    # Makes tests in this directory a submodule of pylada.crystal
    # Adds an empty __init__.py and compiles a test extension
    add_python_module("pylada.tests"
        INSTALL FAKE_INIT
        EXTENSION _quantity
        MAIN quantity.cc
    )
    add_python_module("pylada.tests._pyobject" INSTALL MAIN pyobject.cc)
    add_nose_tests(test_*.py INSTALL "pylada.tests" LABELS cinterface)

endif(tests)

