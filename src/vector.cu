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


#include "vector.h"
#include <string.h>        // memcpy
#define BLOCK_SIZE 512     // optimized


#ifndef CPU_ONLY 
__global__ void gpu_set_zero
(int number_of_elements, double *g_state_real, double *g_state_imag)
{
    int n = blockIdx.x * blockDim.x + threadIdx.x;
    if (n < number_of_elements)
    {
        g_state_real[n] = 0;
        g_state_imag[n] = 0;
    }
}
#else
void cpu_set_zero
(int number_of_elements, double *g_state_real, double *g_state_imag)
{
    for (int n = 0; n < number_of_elements; ++n)
    {
        g_state_real[n] = 0;
        g_state_imag[n] = 0;
    }
}
#endif


#ifndef CPU_ONLY
void Vector::initialize_gpu(int n)
{
    this->n = n;
    array_size = n * sizeof(double);
    cudaMalloc((void**)&real_part, array_size);
    cudaMalloc((void**)&imag_part, array_size);
}
#else
void Vector::initialize_cpu(int n)
{
    this->n = n;
    array_size = n * sizeof(double);
    real_part = new double[n];
    imag_part = new double[n];
}
#endif


Vector::Vector(int n)
{
#ifndef CPU_ONLY
    initialize_gpu(n);
    gpu_set_zero<<<(n - 1) / BLOCK_SIZE + 1, BLOCK_SIZE>>>
    (n, real_part, imag_part);
#else
    initialize_cpu(n);
    cpu_set_zero(n, real_part, imag_part);
#endif
}


#ifndef CPU_ONLY
__global__ void gpu_copy_state
(int N, double *in_real, double *in_imag, double *out_real, double *out_imag)
{
    int n = blockIdx.x * blockDim.x + threadIdx.x;
    if (n < N)
    {
        out_real[n] = in_real[n];
        out_imag[n] = in_imag[n];
    }
}
#else
void cpu_copy_state
(int N, double *in_real, double *in_imag, double *out_real, double *out_imag)
{
    for (int n = 0; n < N; ++n)
    {
        out_real[n] = in_real[n];
        out_imag[n] = in_imag[n];
    }
}
#endif


Vector::Vector(Vector& original)
{
    // Just teach myself: one can access private members of another instance
    // of the class from within the class
#ifndef CPU_ONLY
    initialize_gpu(original.n);
    gpu_copy_state<<<(n - 1) / BLOCK_SIZE + 1, BLOCK_SIZE>>>
    (n, original.real_part, original.imag_part, real_part, imag_part);
#else
    initialize_cpu(original.n);
    cpu_copy_state
    (n, original.real_part, original.imag_part, real_part, imag_part);
#endif
}


Vector::~Vector()
{
#ifndef CPU_ONLY
    cudaFree(real_part);
    cudaFree(imag_part);
#else
    delete[] real_part;
    delete[] imag_part;
#endif
}


#ifndef CPU_ONLY
__global__ void gpu_add_state
(int n, double *in_real, double *in_imag, double *out_real, double *out_imag)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n)
    {
        out_real[i] += in_real[i];
        out_imag[i] += in_imag[i];
    }
}
#else
void cpu_add_state
(int n, double *in_real, double *in_imag, double *out_real, double *out_imag)
{
    for (int i = 0; i < n; ++i)
    {
        out_real[i] += in_real[i];
        out_imag[i] += in_imag[i];
    }
}
#endif


void Vector::add(Vector& other)
{
#ifndef CPU_ONLY
    gpu_add_state<<<(n - 1) / BLOCK_SIZE + 1, BLOCK_SIZE>>>
    (n, other.real_part, other.imag_part, real_part, imag_part);
#else
    cpu_add_state(n, other.real_part, other.imag_part, real_part, imag_part);
#endif
}


void Vector::copy(Vector& other)
{
#ifndef CPU_ONLY
    gpu_copy_state<<<(n - 1) / BLOCK_SIZE + 1, BLOCK_SIZE>>>
    (n, other.real_part, other.imag_part, real_part, imag_part);
#else
    cpu_copy_state
    (n, other.real_part, other.imag_part, real_part, imag_part);
#endif
}


#ifndef CPU_ONLY
__global__ void gpu_apply_sz
(int n, double *in_real, double *in_imag, double *out_real, double *out_imag)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n)
    {
        if (i % 2 == 0)
        {
            out_real[i] = in_real[i];
            out_imag[i] = in_imag[i];
        }
        else
        {
            out_real[i] = -in_real[i];
            out_imag[i] = -in_imag[i];
        }
    }
}
#else
void cpu_apply_sz
(int n, double *in_real, double *in_imag, double *out_real, double *out_imag)
{
    for (int i = 0; i < n; ++i)
    {
        if (i % 2 == 0)
        {
            out_real[i] = in_real[i];
            out_imag[i] = in_imag[i];
        }
        else
        {
            out_real[i] = -in_real[i];
            out_imag[i] = -in_imag[i];
        }
    }
}
#endif


void Vector::apply_sz(Vector& other)
{
#ifndef CPU_ONLY
    gpu_apply_sz<<<(n - 1) / BLOCK_SIZE + 1, BLOCK_SIZE>>>
    (n, other.real_part, other.imag_part, real_part, imag_part);
#else
    cpu_apply_sz(n, other.real_part, other.imag_part, real_part, imag_part);
#endif
}


void Vector::copy_from_host(double* other_real, double* other_imag)
{
#ifndef CPU_ONLY 
    cudaMemcpy(real_part, other_real, array_size, cudaMemcpyHostToDevice);
    cudaMemcpy(imag_part, other_imag, array_size, cudaMemcpyHostToDevice);
#else
    memcpy(real_part, other_real, array_size);
    memcpy(imag_part, other_imag, array_size);
#endif
}


void Vector::copy_to_host(double* target_real, double* target_imag)
{
#ifndef CPU_ONLY
    cudaMemcpy(target_real, real_part, array_size, cudaMemcpyDeviceToHost);
    cudaMemcpy(target_imag, imag_part, array_size, cudaMemcpyDeviceToHost);
#else
    memcpy(target_real, real_part, array_size);
    memcpy(target_imag, imag_part, array_size);
#endif
}


void Vector::swap(Vector& other)
{
    double* tmp_real = real_part;
    double* tmp_imag = imag_part;
    real_part = other.real_part,
    imag_part = other.imag_part;
    other.real_part = tmp_real;
    other.imag_part = tmp_imag;
}


#ifndef CPU_ONLY
__device__ void warp_reduce(volatile double *s, int t)
{
    s[t] += s[t + 32]; s[t] += s[t + 16]; s[t] += s[t + 8];
    s[t] += s[t + 4];  s[t] += s[t + 2];  s[t] += s[t + 1];
}
#endif


#ifndef CPU_ONLY
__global__ void gpu_find_inner_product_1
(
    int number_of_atoms,
    double *g_final_state_real,
    double *g_final_state_imag,
    double *g_random_state_real,
    double *g_random_state_imag,
    double *g_inner_product_real,
    double *g_inner_product_imag,
    int   g_offset
)
{
    int tid = threadIdx.x;
    int n = blockIdx.x * blockDim.x + tid;
    int m;
    double a, b, c, d;
    __shared__ double s_data_real[BLOCK_SIZE];
    __shared__ double s_data_imag[BLOCK_SIZE];
    s_data_real[tid] = 0.0;
    s_data_imag[tid] = 0.0;
    
    if (n < number_of_atoms)
    {
        a = g_final_state_real[n];
        b = g_final_state_imag[n];
        c = g_random_state_real[n];
        d = g_random_state_imag[n];
        s_data_real[tid] = (a * c + b * d);
        s_data_imag[tid] = (b * c - a * d);
    }
    __syncthreads();

    if (tid < 256) 
    {
        m = tid + 256;
        s_data_real[tid] += s_data_real[m];
        s_data_imag[tid] += s_data_imag[m];
    }
    __syncthreads();
    if (tid < 128)
    {
        m = tid + 128;
        s_data_real[tid] += s_data_real[m];
        s_data_imag[tid] += s_data_imag[m];
    }
    __syncthreads();
    if (tid < 64)
    {
        m = tid + 64;
        s_data_real[tid] += s_data_real[m];
        s_data_imag[tid] += s_data_imag[m];
    }
    __syncthreads();
    if (tid < 32)
    {
        warp_reduce(s_data_real, tid);
        warp_reduce(s_data_imag, tid);
    }
    if (tid == 0)
    {        
        g_inner_product_real[blockIdx.x + g_offset] = s_data_real[0];
        g_inner_product_imag[blockIdx.x + g_offset] = s_data_imag[0];
    }
}
#else
void cpu_find_inner_product_1
(
    int grid_size,
    int number_of_atoms,
    double *g_final_state_real,
    double *g_final_state_imag,
    double *g_random_state_real,
    double *g_random_state_imag,
    double *g_inner_product_real,
    double *g_inner_product_imag,
    int   g_offset
)
{
    for (int m = 0; m < grid_size; ++m)
    {
        double s_data_real = 0.0;
        double s_data_imag = 0.0;
        for (int k = 0; k < BLOCK_SIZE; ++k)
        {
            int n = m * BLOCK_SIZE + k;
            if (n < number_of_atoms)
            {
                double a = g_final_state_real[n];
                double b = g_final_state_imag[n];
                double c = g_random_state_real[n];
                double d = g_random_state_imag[n];
                s_data_real += (a * c + b * d);
                s_data_imag += (b * c - a * d);
            }
        }
        g_inner_product_real[m + g_offset] = s_data_real;
        g_inner_product_imag[m + g_offset] = s_data_imag;
    }
}
#endif


void Vector::inner_product_1
(int number_of_atoms, Vector& other, Vector& target, int offset)
{
    int grid_size = (number_of_atoms - 1) / BLOCK_SIZE + 1;
#ifndef CPU_ONLY
    gpu_find_inner_product_1<<<grid_size, BLOCK_SIZE>>>
    (
        number_of_atoms, real_part, imag_part,
        other.real_part, other.imag_part, target.real_part, target.imag_part,
        offset
    );
#else
    cpu_find_inner_product_1
    (
        grid_size, number_of_atoms, real_part, imag_part,
        other.real_part, other.imag_part, target.real_part, target.imag_part,
        offset
    );
#endif
}


#ifndef CPU_ONLY
__global__ void gpu_find_inner_product_2
(
    int number_of_atoms,
    double *g_inner_product_1_real,
    double *g_inner_product_1_imag,
    double *g_inner_product_2_real,
    double *g_inner_product_2_imag
)
{
    //<<<para.number_of_energy_points, BLOCK_SIZE)>>>
    int tid = threadIdx.x;
    int patch, n, m;

    __shared__ double s_data_real[BLOCK_SIZE];
    __shared__ double s_data_imag[BLOCK_SIZE];
    s_data_real[tid] = 0.0;
    s_data_imag[tid] = 0.0;
    int number_of_blocks  = (number_of_atoms - 1) / BLOCK_SIZE + 1;
    int number_of_patches = (number_of_blocks - 1) / BLOCK_SIZE + 1;

    for (patch = 0; patch < number_of_patches; ++patch)
    {
        n = tid + patch * BLOCK_SIZE;
        if (n < number_of_blocks)
        {
            m = blockIdx.x * number_of_blocks + n;
            s_data_real[tid] += g_inner_product_1_real[m];
            s_data_imag[tid] += g_inner_product_1_imag[m];
        }
    }
    __syncthreads();
  
    if (tid < 256)
    {
        m = tid + 256;
        s_data_real[tid] += s_data_real[m];
        s_data_imag[tid] += s_data_imag[m];
    }
    __syncthreads();
    if (tid < 128)
    {
        m = tid + 128; 
        s_data_real[tid] += s_data_real[m];
        s_data_imag[tid] += s_data_imag[m];
    }
    __syncthreads();
    if (tid < 64)
    {
        m = tid + 64; 
        s_data_real[tid] += s_data_real[m];
        s_data_imag[tid] += s_data_imag[m];
    }
    __syncthreads();
    if (tid < 32) 
    {
        warp_reduce(s_data_real, tid);
        warp_reduce(s_data_imag, tid);
    }
    if (tid == 0)
    {
        g_inner_product_2_real[blockIdx.x] = s_data_real[0];
        g_inner_product_2_imag[blockIdx.x] = s_data_imag[0];
    }
}
#else
void cpu_find_inner_product_2
(
    int number_of_moments,
    int grid_size,
    double *g_inner_product_1_real,
    double *g_inner_product_1_imag,
    double *g_inner_product_2_real,
    double *g_inner_product_2_imag
)
{
    for (int m = 0; m < number_of_moments; ++m)
    {
        double s_data_real = 0.0;
        double s_data_imag = 0.0;
        for (int k = 0; k < grid_size; ++k)
        {
            int n = m * grid_size + k;
            s_data_real += g_inner_product_1_real[n];
            s_data_imag += g_inner_product_1_imag[n];
        }
        g_inner_product_2_real[m] = s_data_real;
        g_inner_product_2_imag[m] = s_data_imag;
    }
}
#endif


void Vector::inner_product_2
(int number_of_atoms, int number_of_moments, Vector& target)
{
#ifndef CPU_ONLY
    gpu_find_inner_product_2<<<number_of_moments, BLOCK_SIZE>>>
    (
        number_of_atoms, real_part, imag_part,
        target.real_part, target.imag_part
    );
#else
    int grid_size = (number_of_atoms - 1) / BLOCK_SIZE + 1;
    cpu_find_inner_product_2
    (
        number_of_moments, grid_size, real_part, imag_part,
        target.real_part, target.imag_part
    );
#endif
}


