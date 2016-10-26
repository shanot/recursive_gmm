#!/bin/zsh

awk '
BEGIN{i=0}
/REMARK GAUSS.* W /{W=$5}
/REMARK GAUSS.* M /{Mx=$5 ; My=$6 ; Mz=$7}
/REMARK GAUSS.* CovM *xx /{Cxx=$6 ; Cxy=$8 ; Cxz=$10}
/REMARK GAUSS.* CovM *yy /{
	Cyy=$6 ; Cyz=$8 ; Czz=$10;
	printf("|%d|%g|%g %g %g|%g %g %g %g %g %g %g %g %g|\n",i,W,Mx,My,Mz,Cxx,Cxy,Cxz,Cxy,Cyy,Cyz,Cxz,Czy,Czz)
	i++
}
' < $1
