#include <stdio.h>

void process_array(int *arr, int length) {
    for(int i = 0; i < length; i++) {
        printf("Element %d: %d\n", i, arr[i]);
    }
}
