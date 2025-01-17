/*
    Copyright 2017 Zheyong Fan, Ville Vierimaa, and Ari Harju

    This file is part of GPUQT.

    GPUQT is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    GPUQT is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with GPUQT.  If not, see <http://www.gnu.org/licenses/>.
*/


#pragma once
class Model;
class Hamiltonian;
class Vector;


void find_dos(Model&, Hamiltonian&, Vector&, int);
void find_vac0(Model&, Hamiltonian&, Vector&);
void find_vac(Model&, Hamiltonian&, Vector&);
void find_msd(Model&, Hamiltonian&, Vector&);
void find_spin_polarization(Model&, Hamiltonian&, Vector&);
void find_moments_kg(Model&, Hamiltonian&);


