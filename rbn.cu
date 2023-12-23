#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>
#include <stdlib.h>
#include <iostream>

#define cinf(n,x) for(int i = 0;i<n;i++)cin >>x[i];
using namespace std;

__global__ void add_joutyou(int* d_a, int* d_b, int* d_c, int* d_s, int n){
	int i = blockDim.x * blockIdx.x + threadIdx.x;
	if (i < n) {
		/*一番下の桁の被加数と加数から中間和と中間桁上げの場合分けを以下のように行った。
	二番目以降の桁は一つ下の桁の被加数と加数の値によって分岐するが、この桁だけは分岐しないため、他の桁とは別で処理を行った。*/
		if (i == 0) {
			if (d_a[0] == 1 && d_b[0] == 1) {
				d_c[0] = 1;
				d_s[0] = 0;
			}
			else if ((d_a[0] == 1 && d_b[0] == 0) || (d_a[0] == 0 && d_b[0] == 1)) {
				d_c[0] = 0;
				d_s[0] = 1;
			}
			else if (d_a[0] == 0 && d_b[0] == 0) {
				d_c[0] = 0;
				d_s[0] = 0;
			}
			else if ((d_a[0] == -1 && d_b[0] == 1) || (d_a[0] == 1 && d_b[0] == -1)) {
				d_c[0] = 0;
				d_s[0] = 0;
			}
			else if ((d_a[0] == -1 && d_b[0] == 0) || (d_a[0] == 0 && d_b[0] == -1)) {
				d_c[0] = 0;
				d_s[0] = -1;
			}
			else if (d_a[0] == -1 && d_b[0] == -1) {
				d_c[0] = -1;
				d_s[0] = 0;
			}
		}
		/*2桁目以降の桁の被加数と加数から中間和と中間桁上げの場合分けを以下のように行った。
	一桁目とは異なり、前の桁の被加数と加数の値によって分岐することがある。*/
		else {
			for (int i = 1; i < n; i++) {
				if (d_a[i] == 1 && d_b[i] == 1) {
					d_c[i] = 1;
					d_s[i] = 0;
				}
				else if ((d_a[i] == 1 && d_b[i] == 0) || (d_a[i] == 0 && d_b[i] == 1)) {
					if (d_a[i - 1] >= 0 && d_b[i - 1] >= 0) {
						d_c[i] = 1;
						d_s[i] = -1;
					}
					else {
						d_c[i] = 0;
						d_s[i] = 1;
					}
				}
				else if (d_a[i] == 0 && d_b[i] == 0) {
					d_c[i] = 0;
					d_s[i] = 0;
				}
				else if ((d_a[i] == 1 && d_b[i] == -1) || (d_a[i] == -1 && d_b[i] == 1)) {
					d_c[i] = 0;
					d_s[i] = 0;
				}
				else if ((d_a[i] == 0 && d_b[i] == -1) || (d_a[i] == -1 && d_b[i] == 0)) {
					if (d_a[i - 1] >= 0 && d_b[i - 1] >= 0) {
						d_c[i] = 0;
						d_s[i] = -1;
					}
					else {
						d_c[i] = -1;
						d_s[i] = 1;
					}
				}
				else if (d_a[i] == -1 && d_b[i] == -1) {
					d_c[i] = -1;
					d_s[i] = 0;
				}
			}
		}
	}

}
int main(int argc,char*argv[]) {
	//桁数nを入力
	int n;
	cin >> n;

	//CPUの動的メモリの確保
	int* a, * b, * c, * s;
	a = (int*)malloc(n * sizeof(int));
	b = (int*)malloc(n * sizeof(int));
	c = (int*)malloc(n * sizeof(int));
	s = (int*)malloc(n * sizeof(int));

	//GPUの動的メモリの確保
	int* d_a,* d_b,* d_c,* d_s;
	cudaMalloc(&d_a, n * sizeof(int));
	cudaMalloc(&d_b, n * sizeof(int));
	cudaMalloc(&d_c, n * sizeof(int));
	cudaMalloc(&d_s, n * sizeof(int));

	
	//n桁の被加数a[n]を入力。但し-1から1まで
	cinf(n, a);

	//n桁の加数b[n]を入力。但し-1から1まで
	cinf(n, b);

	//CPUからGPUにメモリを移動させる
	cudaMemcpy(d_a, a, n * sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(d_b, b, n * sizeof(int), cudaMemcpyHostToDevice);

	//被加数と加数から中間和と中間桁上げを出力する関数を生成
	add_joutyou << < (n + 256 - 1) / 256, 256 >> > (d_a, d_b, d_c, d_s, n);

	//GPUからCPUにメモリを戻す
	cudaMemcpy(c, d_c, n * sizeof(int), cudaMemcpyDeviceToHost);
	cudaMemcpy(s, d_s, n * sizeof(int), cudaMemcpyDeviceToHost);

	//全ての桁の中間桁上げを出力
	cout << "中間桁上げ" << endl;
	for (int i = 0; i < n; i++) {
		cout << c[i] << " ";
	}
	cout << endl;
	//全ての桁の中間和を出力
	cout << "中間和" << endl;
	for (int i = 0; i < n; i++) {
		cout << s[i] << " ";
	}
	cout << endl;
	//全ての桁の和を出力
	cout << "和" << endl;
	cout << s[0] << " ";
	for (int i = 1; i < n; i++) {
		cout << s[i] + c[i - 1] << " ";
	}
	cout << c[n - 1] << endl;

	//CPu上のメモリの開放
	free(a);
	free(b);
	free(c);
	free(s);
	//GPU上のメモリの開放
	cudaFree(d_a);
	cudaFree(d_b);
	cudaFree(d_c);
	cudaFree(d_s);
}