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


/*----------------------------------------------------------------------------80
    The driver function of LSQT
------------------------------------------------------------------------------*/


#include "lsqt.h"
#include "vector.h"
#include "hamiltonian.h"
#include "sigma.h"
#include "model.h"
#include <iostream>


static void print_started_random_vector(int i)
{
    std::cout << std::endl;
    std::cout << "===========================================================";
    std::cout << std::endl;
    std::cout << "Started  simulation with random vector number " 
              << i << std::endl;
    std::cout << std::endl;
}


static void print_finished_random_vector(int i)
{
    std::cout << std::endl;
    std::cout << "Finished simulation with random vector number " 
              << i << std::endl; 
    std::cout << "===========================================================";
    std::cout << std::endl << std::endl;
}


static void print_started_ldos()
{
    std::cout << std::endl;
    std::cout << "===========================================================";
    std::cout << std::endl;
    std::cout << "Started LDOS calculation" << std::endl;
    std::cout << std::endl;
}


static void print_finished_ldos()
{
    std::cout << std::endl;
    std::cout << "Finished LDOS calculation" << std::endl; 
    std::cout << "===========================================================";
    std::cout << std::endl << std::endl;
}


static void run_dos(Model& model, Hamiltonian& H, Vector& random_state)
{
    clock_t time_begin = clock(); 
    find_dos(model, H, random_state, 0);
    clock_t time_finish = clock();
    double time_used = double(time_finish - time_begin) / CLOCKS_PER_SEC;
    std::cout << "- Time used for finding DOS = " 
              << time_used << " s" << std::endl;
}


static void run_vac0(Model& model, Hamiltonian& H, Vector& random_state)
{
    if (model.calculate_vac0 == 1)
    {
        clock_t time_begin = clock();
        find_vac0(model, H, random_state);
        clock_t time_finish = clock();
        double time_used = double(time_finish - time_begin) / CLOCKS_PER_SEC;
        std::cout << "- Time used for finding VAC0 = " 
                  << time_used << " s" << std::endl;
    }
}


static void run_vac(Model& model, Hamiltonian& H, Vector& random_state)
{
    if (model.calculate_vac == 1)
    {
        clock_t time_begin = clock();
        find_vac(model, H, random_state);
        clock_t time_finish = clock();
        double time_used = double(time_finish - time_begin) / CLOCKS_PER_SEC;
        std::cout << "- Time used for finding VAC = " 
                  << time_used << " s" << std::endl;
    }
}


static void run_msd(Model& model, Hamiltonian& H, Vector& random_state)
{
    if (model.calculate_msd == 1)
    {
        clock_t time_begin = clock();
        find_msd(model, H, random_state);
        clock_t time_finish = clock();
        double time_used = double(time_finish - time_begin) / CLOCKS_PER_SEC;
        std::cout << "- Time used for finding MSD = " 
                  << time_used << " s" << std::endl;
    }
}


static void run_spin(Model& model, Hamiltonian& H, Vector& random_state)
{
    if (model.calculate_spin == 1)  
    {
        clock_t time_begin = clock();
        find_spin_polarization(model, H, random_state);
        clock_t time_finish = clock();
        double time_used = double(time_finish - time_begin) / CLOCKS_PER_SEC;
        std::cout << "- Time used for finding spin polarization = " 
                  << time_used << " s" << std::endl;
    }
}


static void run_ldos(Model& model, Hamiltonian& H, Vector& random_state)
{
    if (model.calculate_ldos)
    {
        print_started_ldos();
        clock_t time_begin = clock();
        for (int i = 0; i < model.number_of_local_orbitals; ++i)
        {
            int orbital = model.local_orbitals[i];
            model.initialize_state(random_state, orbital);
            find_dos(model, H, random_state, 1);
        }
        clock_t time_finish = clock();
        double time_used = double(time_finish - time_begin) / CLOCKS_PER_SEC;
        std::cout << "- Time used for finding LDOS = "
                  << time_used << " s" << std::endl;
        print_finished_ldos();
    }
}


static void run_moments_kg(Model& model, Hamiltonian& H)
{
    if (model.calculate_moments_kg)
    {
        clock_t time_begin = clock();
        find_moments_kg(model, H);
        clock_t time_finish = clock();
        double time_used = double(time_finish - time_begin) / CLOCKS_PER_SEC;
        std::cout << "- Time used for finding KG moments = "
                  << time_used << " s" << std::endl;
    }
}


void lsqt(std::string input_directory)
{
    Model model(input_directory);
    Hamiltonian H(model);
    Vector random_state(model.number_of_atoms);
    for (int i = 0; i < model.number_of_random_vectors; ++i)
    {
        print_started_random_vector(i);
        int orbital = -1; // using random vectors rather than a local orbital
        model.initialize_state(random_state, orbital);
        run_dos(model, H, random_state);
        run_vac0(model, H, random_state);
        run_vac(model, H, random_state);
        run_msd(model, H, random_state);
        run_spin(model, H, random_state);
        print_finished_random_vector(i);
    }
    run_ldos(model, H, random_state);
    run_moments_kg(model, H);
}


