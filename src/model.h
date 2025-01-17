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
#include "anderson.h"
#include "charge.h"
#include <random>
class Vector;


class Model
{
public:
    Model(std::string input_dir);
    ~Model();
    void initialize_state(Vector& random_state, int orbital);

    bool calculate_vac0 = false;
    bool calculate_vac = false;
    bool calculate_msd = false;
    bool calculate_spin = false;
    bool calculate_ldos = false;
    bool calculate_moments_kg = false;

    int number_of_random_vectors = 1; 
    int number_of_atoms = 0; 
    int max_neighbor = 0;
    int number_of_pairs = 0;
    int number_of_energy_points = 0; 
    int number_of_moments = 1000; 
    int number_of_steps_correlation = 0;
    int number_of_local_orbitals = 0;
    std::string input_dir;
    double energy_max = 10;

    double *energy;
    double *time_step;
    std::vector<int> local_orbitals;
    
    int *neighbor_number;
    int *neighbor_list;  
    double *xx;
    double *potential;
    double *hopping_real;
    double *hopping_imag;

    double volume;
    
private:

    void print_started_reading(std::string filename);
    void print_finished_reading(std::string filename);

    // for both lattice and general models
    void initialize_parameters();
    void verify_parameters();
    void initialize_energy();
    void initialize_time();
    void initialize_local_orbitals();

    // only for general model
    void initialize_neighbor();
    void initialize_positions();
    void initialize_potential();
    void initialize_hopping();
    void initialize_model_general();

    // only for lattice model
    void initialize_lattice_model();
    void add_vacancies();
    void create_random_numbers(int, int, int*);
    void specify_vacancies(int*, int);
    void find_new_atom_index(int*, int*, int);
    
    bool requires_time = false;
    bool use_lattice_model = false;

    // disorder
    Anderson anderson;
    Charge charge;

    bool has_vacancy_disorder = false;
    int number_of_vacancies;

    int pbc[3];
    double box_length[3];
    std::vector<double> x, y, z;

    std::mt19937 generator;
};


