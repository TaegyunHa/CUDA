#pragma once
#include <iostream>
#include <sstream>

namespace utils
{
template<typename _Tp>
void initVec(_Tp* inputVec, _Tp initVal, size_t vecSize)
{
	if (inputVec == nullptr)
		return;

	for (size_t i = 0; i < vecSize; ++i)
	{
		inputVec[i] = initVal;
	}
}

template<typename _Tp>
void printVec(_Tp* inputVec, size_t vecSize)
{
	if (inputVec == nullptr)
		return;

	std::stringstream inputStream;
	for (size_t i = 0; i < vecSize; ++i)
	{
		inputStream << inputVec[i] << " ";
	}
	std::cout << "[ " << inputStream.str() << "]" << std::endl;
}
} // utils