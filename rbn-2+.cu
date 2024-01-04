#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>
#include <stdlib.h>
#include <iostream>

#define cinf(n,x) for(int i = 0;i<n;i++)cin >>x[i];
using namespace std;

__global__ void add_joutyou(int* d_a, int* d_b, int* d_c, int* d_s, int n) {
	int i = blockDim.x * blockIdx.x + threadIdx.x;
	if (i < n) {
		/*�S�Ă̔�����Ɖ������璆�Ԙa�ƒ��Ԍ��グ�̏ꍇ�������ȉ��̂悤�ɍs�����B*/
		for (int i = 0; i < n; i++) {
			if (d_a[i] == 1 && d_b[i] == 1) {
				d_c[i] = 1;
				d_s[i] = 0;
			}
			else if ((d_a[i] == 1 && d_b[i] == 0) || (d_a[i] == 0 && d_b[i] == 1)) {
				d_c[i] = 1;
				d_s[i] = -1;
			}
			else if (d_a[i] == 0 && d_b[i] == 0) {
				d_c[i] = 0;
				d_s[i] = 0;
			}
			else if (d_a[i] == -1 && d_b[i] == 1) {
				d_c[i] = 0;
				d_s[i] = 0;
			}
			else if (d_a[i] == -1 && d_b[i] == 0) {
				d_c[i] = 0;
				d_s[i] = -1;
			}
			else if (d_a[i] == -2 && d_b[i] == 1) {
				d_c[i] = 0;
				d_s[i] = -1;
			}
			else if (d_a[i] == -2 && d_b[i] == 0) {
				d_c[i] = -1;
				d_s[i] = 0;
			}
		}
	}
}

int main(int argc, char* argv[]) {
	//����n�����
	int n;
	cin >> n;

	//CPU�̓��I�������̊m��
	int* a, * b, * c, * s;
	a = (int*)malloc(n * sizeof(int));
	b = (int*)malloc(n * sizeof(int));
	c = (int*)malloc(n * sizeof(int));
	s = (int*)malloc(n * sizeof(int));

	//GPU�̓��I�������̊m��
	int* d_a, * d_b, * d_c, * d_s;
	cudaMalloc(&d_a, n * sizeof(int));
	cudaMalloc(&d_b, n * sizeof(int));
	cudaMalloc(&d_c, n * sizeof(int));
	cudaMalloc(&d_s, n * sizeof(int));


	//n���̔����a[n]����́B�A��-2����1�܂�
	cinf(n, a);

	//n���̉���b[n]����́B�A��0����1�܂�
	cinf(n, b);

	//CPU����GPU�Ƀ��������ړ�������
	cudaMemcpy(d_a, a, n * sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(d_b, b, n * sizeof(int), cudaMemcpyHostToDevice);

	//������Ɖ������璆�Ԙa�ƒ��Ԍ��グ���o�͂���֐��𐶐�
	add_joutyou << < (n + 256 - 1) / 256, 256 >> > (d_a, d_b, d_c, d_s, n);

	//GPU����CPU�Ƀ�������߂�
	cudaMemcpy(c, d_c, n * sizeof(int), cudaMemcpyDeviceToHost);
	cudaMemcpy(s, d_s, n * sizeof(int), cudaMemcpyDeviceToHost);

	//�S�Ă̌��̒��Ԍ��グ���o��
	cout << "���Ԍ��グ" << endl;
	for (int i = 0; i < n; i++) {
		cout << c[i] << " ";
	}
	cout << endl;
	//�S�Ă̌��̒��Ԙa���o��
	cout << "���Ԙa" << endl;
	for (int i = 0; i < n; i++) {
		cout << s[i] << " ";
	}
	cout << endl;
	//�S�Ă̌��̘a���o��
	cout << "�a" << endl;
	cout << s[0] << " ";
	for (int i = 1; i < n; i++) {
		cout << s[i] + c[i - 1] << " ";
	}
	cout << c[n - 1] << endl;

	//CPu��̃������̊J��
	free(a);
	free(b);
	free(c);
	free(s);
	//GPU��̃������̊J��
	cudaFree(d_a);
	cudaFree(d_b);
	cudaFree(d_c);
	cudaFree(d_s);
}