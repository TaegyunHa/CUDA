#include <iostream>
#include <stdio.h>
#include "utils.h"

#include <cuda_runtime.h>
#include "device_launch_parameters.h"

// #define ARRAY_1D
#ifdef ARRAY_1D

// Device Code
__global__ void VecAdd(float* a, float* b, float* c, int N)
{
	int gid = blockDim.x * blockIdx.x + threadIdx.x;
	if (gid < N)
		c[gid] = a[gid] + b[gid];
}

int main()
{
	int N = 64;
	size_t byteSize = sizeof(float) * N;

	// Allocate input vectors in host memory
	float* h_A = (float*)malloc(byteSize);
	float* h_B = (float*)malloc(byteSize);
	float* h_C = (float*)malloc(byteSize);

	// Init input vectors
	utils::initVec<float>(h_A, 2, N);
	utils::initVec<float>(h_B, 3, N);

	// Allocate vectors in device memory
	float* d_A;
	cudaMalloc(&d_A, byteSize);
	float* d_B;
	cudaMalloc(&d_B, byteSize);
	float* d_C;
	cudaMalloc(&d_C, byteSize);

	// Copy vectors from host to device memory
	cudaMemcpy(d_A, h_A, byteSize, cudaMemcpyHostToDevice);
	cudaMemcpy(d_B, h_A, byteSize, cudaMemcpyHostToDevice);

	// Invoke kernel
	int threadPerBlock	= 256; // 16*16
	int blocksPerGrid	= (N + threadPerBlock - 1) / threadPerBlock;
	// This is done to make a margine to avoid floor result by
	// int-wise division. For example, 1/2 = 0
	VecAdd << <blocksPerGrid, threadPerBlock >> > (d_A, d_B, d_C, N);
	

	// Copy result from device to host memory
	cudaMemcpy(h_C, d_C, byteSize, cudaMemcpyDeviceToHost);
	
	// Free device memory
	cudaFree(d_A);
	cudaFree(d_B);
	cudaFree(d_C);

	// Display result
	utils::printVec<float>(h_C, N);

	// Free host memory
	free(h_A);
	free(h_B);
	free(h_C);

	//cudaDeviceSynchronize();
	cudaDeviceReset();
	return 0;
}
#endif // ARRAY_1D


#define ARRAY_2D
#ifdef ARRAY_2D

// Device Code
__global__ void loop2DArray(float* d_pArray, size_t pitch, int width, int height)
{
	for (int rowIdx = 0; rowIdx < height; ++rowIdx)
	{
		// (char*) is for 1byte increment
		float* row = (float*)((char*)d_pArray + rowIdx * pitch);
		for (int colIdx = 0; colIdx < width; ++colIdx)
		{
			// value will be corrupted when multi-threads try to access
			float& element = row[colIdx];
			printf("%f\n", ++element);
		}
	}
}

int main()
{
	int width = 64;
	int height = 64;
	float* d_pArray;
	float* d_pArrayDst;
	size_t pitch;
	size_t pitchDst;

	// Allocate 2D array in host memory
	size_t h_pitch	= sizeof(float) * width;
	size_t byteSize = sizeof(float) * width * height;
	float* h_pArray = (float*)malloc(byteSize);
	utils::initVec<float>(h_pArray, 1.f, width * height);
	utils::printVec<float>(h_pArray, width * height);

	// Allocate 2D array and get a pitch
	cudaMallocPitch(&d_pArray, &pitch, sizeof(float) * width, height);
	cudaMallocPitch(&d_pArrayDst, &pitchDst, sizeof(float) * width, height);

	// Copy array from host to device
	cudaMemcpy2D(d_pArray, pitch, h_pArray, h_pitch, sizeof(float) * width, height, cudaMemcpyHostToDevice);
	
	// Invoke kernel
	size_t N = 51200;
	int threadsPerBlock = 512;
	int blocksPerGrid = N / threadsPerBlock;	
	// loop2DArray << <blocksPerGrid, threadsPerBlock >> > (d_pArray, pitch, width, height);
	loop2DArray << <1, 1>> > (d_pArray, pitch, width, height);

	// Copy array from device to device
	cudaMemcpy2D(d_pArrayDst, pitchDst, d_pArray, pitch, sizeof(float) * width, height, cudaMemcpyDeviceToDevice);
	loop2DArray << <1, 1 >> > (d_pArrayDst, pitchDst, width, height);

	// Copy array from device to host
	cudaMemcpy2D(h_pArray, h_pitch, d_pArrayDst, pitchDst, sizeof(float) * width, height, cudaMemcpyDeviceToHost);
	utils::printVec(h_pArray, width * height);

	// free memory
	cudaFree(d_pArray);
	cudaFree(d_pArrayDst);
	free(h_pArray);

	cudaDeviceReset();
	return 0;
}
#endif // ARRAY_2D


//#define ARRAY_3D
#ifdef ARRAY_3D

// Device code
__global__ void loop3DArray(cudaPitchedPtr d_pPitch, int width, int height, int depth)
{
	char* d_ptr = (char*)d_pPitch.ptr;
	size_t pitch = d_pPitch.pitch;
	size_t slicePitch = pitch * height;

	for (int z = 0; z < depth; ++z)
	{
		char* slice = d_ptr + (z * slicePitch);
		for (int y = 0; y < height; ++y)
		{
			float* row = (float*)(slice + (y * pitch));
			for (int x = 0; x < width; ++x)
			{
				float element = row[x];
			}
		}
	}
}

int main()
{
	int width = 64;
	int height = 64;
	int depth = 64;
	cudaExtent extent = make_cudaExtent(sizeof(float) * width, height, depth);

	// Allocate 3D array
	cudaPitchedPtr d_pPitch;
	cudaMalloc3D(&d_pPitch, extent);
	
	// Invoke kernel
	loop3DArray << <100, 512 >> > (d_pPitch, width, height, depth);

	cudaDeviceReset();
	return 0;
}
#endif // ARRAY_3D