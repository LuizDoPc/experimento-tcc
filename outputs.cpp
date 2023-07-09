#include <iostream>

using namespace std;

int main(){
    int size = 10000;

    cout << "[";
    for(int i = 0; i < size; i++){
        if(i == size - 1) cout << i;
        else cout << i << ", ";
    }

    cout << "]";
}