#include <stdio.h>

void binaire(int nombre)
{
    int somme=0;
    int val=0;
    char bin[8]={};

    int entier[8]={128,64,32,16,8,4,2,1};
    
    for (int i=0 ; i<8 ; i++)
    {
        somme=val+entier[i];
        if (nombre >= somme)
        {
            bin[i]='1';
            val=somme;
        }
        else
        {
            bin[i]='0';
        } 
            
    }
    printf("Binaire:");
    for (int i=0; i<8; i++)
    {
        printf("%c", bin[i]);
    }
    printf("\n\n");
    
}

int main()
{
    int nombre;
    printf("Nombre:");
    scanf("%d", &nombre);
    binaire(nombre);
    return 0;
}