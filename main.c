#include <stdio.h> 		
#include <string.h>		
#include <stdlib.h>

#include "encode.h" 
#include "decode.h" 

int main(int argc, char *argv[])
{

	char *text, *input;
	int x; // 0 - encode, 1 - decode
	long i = 0, numbBytes;
	char *fileName;
	FILE *fp, *fb;

	printf("Type 0 to encode, or 1 to decode: ");
	scanf("%d", &x);
	if(x == 0)
	{
	     input = malloc(10000);
	     fileName = malloc(100);

	     printf("Name of file to encode: ");
	     scanf("%s", fileName);

	     if((fp = fopen(fileName,"r")) == NULL)
	     { 	
	        puts("Error! Opening file to encode failed.");
	      	exit(1);
	     }

	     long charNumber;
	     
	     while(!feof(fp))
	     {
		fscanf(fp, "%c", &input[i]);
	  	++i;
	     }

	     i--;
	     charNumber = i;

	     char inputText[i];
	     strncpy(inputText, input, charNumber);
	     inputText[charNumber] = '\0';
	     free(fileName);

	     text = malloc(10000);
	
	     puts("Character codes: ");
	     numbBytes = encode(inputText, charNumber, text);
	     puts("");
	     
	     fileName = malloc(100);
	     printf("Name of bin file to write encoded text to (add .bin at end): ");
 	     scanf("%s", fileName);
	     
	     if((fb = fopen(fileName,"wb")) == NULL)
	     {
		  puts("Error! Opening binary file to write failed.");
	    	  exit(1);
	     }
	     free(fileName);
	     
	     for(i=0; i< numbBytes ; ++i)
	     {
		  fprintf(fb, "%c", text[i]);
	     }

	     free(input);
	     free(text);
	     fclose(fb);	     
	     fclose(fp);
	}
	
	else if(x == 1)
	{
	    fileName = malloc(100);
	    printf("Name of bin file to read encoded text from (add .bin at end): ");
	    scanf("%s", fileName);
	    
	    if((fb = fopen(fileName,"rb")) == NULL)
    	    {
		 puts("Error! Opening binary file to read failed.");
	    	 exit(1);
	    }
	    free(fileName);

	    char k;
	    i = 0;
	    while(!feof(fb))
	    {
		 fread(&k, 1 , 1, fb);
	  	 ++i;
	    }
	    numbBytes = i - 1;
	    fseek(fb, 0, 0);

	    input = malloc(numbBytes);
	 
	    fread(input, 1, numbBytes, fb);	
	    text = malloc(10000);

	    long numbText = decode(input, numbBytes, text);

	    fileName = malloc(100);
	    printf("Name of file to write decoded text to: ");
 	    scanf("%s", fileName);
	     
	    if((fp = fopen(fileName,"w")) == NULL)
	    {
		 puts("Error! Opening text file to write failed.");
	   	 exit(1);
	    }
	    free(fileName);
	     
	    for(i=0; i<numbText; ++i)
	    {
		 fprintf(fp, "%c", text[i]);
    	    }
		
	    free(input);
	    free(text);
	    fclose(fb);	     
	    fclose(fp);
	}
 
	else{
	  
           puts("Wrong number! Choose 0 or 1");
	   exit(1);	
	}

	return 0;
}
