Function c_YY, A, _extra=extra
	;; NH / YZiCS
	;OM=0.272000014781952E+00
	;OL=0.727999985218048E+00

	;; YZiCS2
	;OM=0.311100006103516E+00
	;OL=0.688899993896484E+00
	oM	= extra.oM
	oL	= extra.oL
	Return, 1./(A^3 * sqrt(OM / A^3 + OL))
End
PRO c_conformal, oM=oM, oL=oL, dir=dir

	sfact	= dindgen(10000)/9999.*0.98 + 0.02 
	conft	= dblarr(10000)
	for i=0L, 9999L do begin
		qsimp, 'c_YY', sfact(i), 1, val, /double, oM=oM, oL=oL
		conft(i)	= val * (-1.)
	endfor
	;conft(i) = qsimp('YY', sfact(i), 1., /double, oM=oM, oL=oL)
	;conft	= conft * (-1.)
	doM = oM & doL = oL
	SAVE, filename=dir + 'conformal_table.sav', sfact, conft, doM, doL
End
