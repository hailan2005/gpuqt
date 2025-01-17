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


#include "model.h"
#include "vector.h"
#include <random>
#include <iostream>
#include <fstream>
#include <sstream>
#include <chrono>

#define PI 3.141592653589793


Model::Model(std::string input_dir)
{
    #ifdef DEBUG
        // use the same seed for different runs
        generator = std::mt19937(12345678);
    #else
        // use different seeds for different runs
        generator = std::mt19937
        (std::chrono::system_clock::now().time_since_epoch().count());
    #endif

    // determine the input directory
    this->input_dir = input_dir;

    // read in para.in
    initialize_parameters();

    // initialize the model
    if (use_lattice_model) // use a lattice model
    {
        initialize_lattice_model();
    }
    else // use general inputs to build the model
    {
        initialize_model_general();
    }

    // always need to read in energies
    initialize_energy();

    // only read in time steps when needed
    if (requires_time)
        initialize_time();

    // only read in local orbitals when needed
    if (calculate_ldos)
        initialize_local_orbitals();
}


Model::~Model()
{ 
    // other memory will be freed when constructing the Hamiltonian
    delete[] energy;
    if (requires_time)
        delete[] time_step;
}


// This function is called by the lsqt function in the lsqt.cu file
// It initializes a random vector
void Model::initialize_state(Vector& random_state, int orbital)
{
    std::uniform_real_distribution<double> phase(0, 2 * PI);
    double *random_state_real = new double[number_of_atoms];
    double *random_state_imag = new double[number_of_atoms];

    if (orbital >= 0)
    {
        for (int n = 0; n < number_of_atoms; ++n)
        {
            random_state_real[n] = 0.0;
            random_state_imag[n] = 0.0;
        }
        random_state_real[orbital] = sqrt(1.0 * number_of_atoms);
    }
    else if (calculate_spin) // normalize to N/2 to remove spin degeneracy
    {
        for (int n = 0; n < number_of_atoms; n += 2)
        {
            double random_phase = phase(generator);
            random_state_real[n] = cos(random_phase);
            random_state_imag[n] = sin(random_phase);
            random_state_real[n+1] = 0.0;
            random_state_imag[n+1] = 0.0;
        }
    }
    else // normalize to N to keep spin degeneracy
    {
        for (int n = 0; n < number_of_atoms; ++n)
        {
            double random_phase = phase(generator);
            random_state_real[n] = cos(random_phase);
            random_state_imag[n] = sin(random_phase);
        }
    }
    random_state.copy_from_host(random_state_real, random_state_imag);
    delete[] random_state_real;
    delete[] random_state_imag;
}


void Model::print_started_reading(std::string filename)
{
    std::cout << std::endl;
    std::cout << "===========================================================";
    std::cout << std::endl;
    std::cout << "Started reading " + filename << std::endl;
    std::cout << std::endl;
}


void Model::print_finished_reading(std::string filename)
{
    std::cout << std::endl;
    std::cout << "Finished reading " + filename << std::endl;
    std::cout << "===========================================================";
    std::cout << std::endl << std::endl;
}


void Model::verify_parameters()
{
    // determine whether or not we need to read in time steps
    if (calculate_vac || calculate_msd || calculate_spin)
        requires_time = true;

    //Verify the used parameters (make a seperate function later)
    if (use_lattice_model)
    {
        std::cout << "- Use lattice model" << std::endl;
        if (calculate_spin)
        {
            std::cout << "Error: lattice model does not support "
                      << "spin calculations yet" << std::endl;
            exit(1);
        }

        if (anderson.has_disorder)
        {
            std::cout << "- Add Anderson disorder with strength W = "
                      << anderson.disorder_strength << std::endl;
        }
        else
        {
            std::cout << "- No Anderson disorder" << std::endl;
        }

        if (charge.has)
        {
            std::cout << "- Add charged impurities with " << std::endl
                      << "  N = " << charge.Ni << std::endl
                      << "  W = " << charge.W << std::endl
                      << "  xi = " << charge.xi << std::endl;
        }
        else
        {
            std::cout << "- No charged impurity" << std::endl;
        }

        if (has_vacancy_disorder)
        {
            std::cout << "- Add " << number_of_vacancies
                      << " vacancies" << std::endl;
            if (number_of_vacancies <= 0)
            {
                std::cout << "Error: number of vacancies should > 0"
                          << std::endl;
                exit(1);
            }
        }
        else
        {
            std::cout << "- No vacancy disorder" << std::endl;
        }
    }
    else
    {
        std::cout << "- Use general model" << std::endl;
        if (anderson.has_disorder)
        {
            std::cout << "Error: General model does not allowed to add "
                      << "Anderson disorder" << std::endl;
            exit(1);
        }
        if (has_vacancy_disorder)
        {
            std::cout << "Error: General model does not allowed to add "
                      << "vacancy disorder" << std::endl;
            exit(1);
        }
        if (charge.has)
        {
            std::cout << "Error: General model does not allowed to add "
                      << "charged impurities" << std::endl;
            exit(1);
        }
    }

    std::cout << "- DOS will be calculated" << std::endl;

    if (calculate_vac0)
        std::cout << "- VAC0 will be calculated" << std::endl;
    else
        std::cout << "- VAC0 will not be calculated" << std::endl;

    if (calculate_vac)
        std::cout << "- VAC will be calculated" << std::endl;
    else
        std::cout << "- VAC will not be calculated" << std::endl;

    if (calculate_msd)
        std::cout << "- MSD will be calculated" << std::endl;
    else
        std::cout << "- MSD will not be calculated" << std::endl;

    if (calculate_spin)
        std::cout << "- spin polarization will be calculated" << std::endl;
    else
        std::cout << "- spin polarization will not be calculated" << std::endl;

    if (calculate_moments_kg)
        std::cout << "- KG moments will be calculated" << std::endl;
    else
        std::cout << "- KG moments will not be calculated" << std::endl;

    if (calculate_spin && calculate_vac0)
    {
        std::cout << "Error: spin and VAC0 cannot be calculated together"
                  << std::endl;
        exit(1);
    }

    if (calculate_spin && calculate_vac)
    {
        std::cout << "Error: spin and VAC cannot be calculated together"
                  << std::endl;
        exit(1);
    }

    if (calculate_spin && calculate_msd)
    {
        std::cout << "Error: spin and MSD cannot be calculated together"
                  << std::endl;
        exit(1);
    }

    std::cout << "- Number of random vectors is " << number_of_random_vectors
              << std::endl;
    if (number_of_random_vectors <= 0)
    {
        std::cout << "Error: Number of random vectors should > 0" << std::endl;
        exit(1);
    }

    std::cout << "- Number of moments is " << number_of_moments << std::endl;
    if (number_of_moments <= 0)
    {
        std::cout << "Error: Number of moments should > 0" << std::endl;
        exit(1);
    }

    std::cout << "- Energy maximum is " << energy_max << std::endl;
    if (energy_max <= 0)
    {
        std::cout << "Error: Energy maximum should > 0" << std::endl;
        exit(1);
    }
}


void Model::initialize_parameters()
{
    std::string filename = input_dir + "/para.in";
    std::ifstream input(filename);
    if (!input.is_open())
    {
        std::cout << "Error: cannot open " + filename << std::endl;
        exit(1);
    }
    print_started_reading(filename);

    std::string line;
    while (std::getline(input, line))
    {
        std::stringstream ss(line);
        std::string token;
        ss >> token;
        if (token == "") continue;
        if (token == "model")
        {
            ss >> use_lattice_model;
        }
        else if (token == "anderson_disorder")
        {
            anderson.has_disorder = true;
            ss >> anderson.disorder_strength;
        }
        else if (token == "charged_impurity")
        {
            charge.has = true;
            ss >> charge.Ni;
            ss >> charge.W;
            ss >> charge.xi;
        }
        else if (token == "vacancy_disorder")
        {
            has_vacancy_disorder = true;
            ss >> number_of_vacancies;
        }
        else if (token == "calculate_vac0")
        {
            calculate_vac0 = true;
        }
        else if (token == "calculate_vac")
        {
            calculate_vac = true;
        }
        else if (token == "calculate_msd")
        {
            calculate_msd = true;
        }
        else if (token == "calculate_spin")
        {
            calculate_spin = true;
        }
        else if (token == "calculate_ldos")
        {
            calculate_ldos = true;
        }
        else if (token == "calculate_moments_kg")
        {
            calculate_moments_kg = true;
        }
        else if (token == "number_of_random_vectors")
        {
            ss >> number_of_random_vectors;
        }
        else if (token == "number_of_moments")
        {
            ss >> number_of_moments;
        }
        else if (token == "energy_max")
        {
            ss >> energy_max;
        }
        else
        {
            std::cout << "Error: Unknown identifier in "
                      << input_dir + "/para.in: " + line
                      << std::endl;
            std::cout << "Valid keywords include: " << std::endl
                      << "--model" << std::endl
                      << "--anderson_disorder" << std::endl
                      << "--charged_impurity" << std::endl
                      << "--vacancy_disorder" << std::endl
                      << "--calculate_vac0" << std::endl
                      << "--calculate_vac" << std::endl
                      << "--calculate_msd" << std::endl
                      << "--calculate_spin" << std::endl
                      << "--calculate_ldos" << std::endl
                      << "--calculate_moments_kg" << std::endl
                      << "--number_of_random_vectors" << std::endl
                      << "--number_of_moments" << std::endl
                      << "--energy_max" << std::endl;
            exit(1);
        }
    }
    input.close();
    verify_parameters();
    print_finished_reading(filename);
}


void Model::initialize_energy()
{
    std::string filename = input_dir + "/energy.in";
    std::ifstream input(filename);
    if (!input.is_open())
    {
        std::cout <<"Error: cannot open " + filename << std::endl;
        exit(1);
    }

    print_started_reading(filename);

    input >> number_of_energy_points;
    std::cout << "- number of energy points = "
              << number_of_energy_points
              << std::endl;
    energy = new double[number_of_energy_points];

    for (int n = 0; n < number_of_energy_points; ++n)
    {
        input >> energy[n];
    }

    input.close();

    print_finished_reading(filename);
}


void Model::initialize_local_orbitals()
{
    std::string filename = input_dir + "/local_orbitals.in";
    std::ifstream input(filename);

    if (!input.is_open())
    {
        std::cout <<"Error: cannot open " + filename << std::endl;
        exit(1);
    }
    print_started_reading(filename);

    input >> number_of_local_orbitals;
    std::cout << "- number of local orbitals = "
              << number_of_local_orbitals
              << std::endl;
    local_orbitals.resize(number_of_local_orbitals);

    for (int n = 0; n < number_of_local_orbitals; ++n)
    {
        input >> local_orbitals[n];
        if (local_orbitals[n] < 0 || local_orbitals[n] >= number_of_atoms)
        {
            std::cout << "Error: wrong local orbital index: "
                      << local_orbitals[n] << std::endl;
            exit(1);
        }
    }

    input.close();
    print_finished_reading(filename);
}


void Model::initialize_time()
{
    std::string filename = input_dir + "/time_step.in";
    std::ifstream input(filename);

    if (!input.is_open())
    {
        std::cout <<"Error: cannot open " + filename << std::endl;
        exit(1);
    }
    print_started_reading(filename);

    input >> number_of_steps_correlation;
    std::cout << "- number of time steps = "
              << number_of_steps_correlation
              << std::endl;
    time_step = new double[number_of_steps_correlation];

    for (int n = 0; n < number_of_steps_correlation; ++n)
    {
        input >> time_step[n];
    }

    input.close();
    print_finished_reading(filename);
}


