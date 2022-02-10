module lox.memset;

// bug: https://issues.dlang.org/show_bug.cgi?id=19946
extern(C) int *_memset32(int *p, int value, size_t count)
{
	version (D_InlineAsm_X86)
	{
		asm
		{
			mov     EDI,p           ;
			mov     EAX,value       ;
			mov     ECX,count       ;
			mov     EDX,EDI         ;
			rep                     ;
			stosd                   ;
			mov     EAX,EDX         ;
		}
	}
	else
	{
		int *pstart = p;
		int *ptop;

		for (ptop = &p[count]; p < ptop; p++)
			*p = value;
		return pstart;
	}
}

extern(C) float *_memsetFloat(float *p, float value, size_t count)
{
    float *pstart = p;
    float *ptop;

    for (ptop = &p[count]; p < ptop; p++)
        *p = value;
    return pstart;
}

extern(C) double *_memsetDouble(double *p, double value, size_t count)
{
    double *pstart = p;
    double *ptop;

    for (ptop = &p[count]; p < ptop; p++)
        *p = value;
    return pstart;
}
