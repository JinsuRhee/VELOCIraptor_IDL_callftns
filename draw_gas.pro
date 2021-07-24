; :Keywords:
;	amr: in, required, type=structure
;		a structure that includes amr data (use f_rdgas.pro)
;	GAL: in, required, type=structure
;		a structure that includes gal data (use f_rdgal.pro)
;	id: in, required, type=long
;		galaxy VR ID
;
;	position:
;		figure position
;	num_thread:
;		# of thread numbers
;	xr, yr, zr:
;		rectangular range for drawing
;	z_type:
;		variable for drawing
;		'nH' for nH
;		'mass' for Msun
;		'temp' for K
;		'metal' for Z
;		
;	den_type:
;		density type
;		'3Dden' for density
;		'2Dden' for surface density
;		'1Dden' for column density
;	maxlev, minlev:
;		amr level range
;
; :Notes
;	Currently, gas map is drawn by using 2D density weight

Pro draw_gas, amr, GAL, id, position=position, num_thread=num_thread, $
	xr=xr, yr=yr, zr=zr, metal=metal, z_type=z_type, $
	den_type=den_type, maxlev=maxlev, minlev=minlev, npix=npix

	;;-----
	;; Setting
	;;-----
	ind	= WHERE(GAL.id EQ id, nid)
	IF nid EQ 0L THEN BEGIN
		PRINT, 'no matched gal'
		DOC_LIBRARY, 'draw_gas'
		RETURN
	ENDIF

	IF ~KEYWORD_SET(num_thread) THEN num_thread = 1L
	ind	= ind(0)
	FINDPRO, 'draw_gas', dirlist=curr_dir
	dir_lib	= curr_dir(0)

	mindx	= MIN(amr.dx)
	IF KEYWORD_SET(npix) THEN BEGIN
		mindx	= (xr(1) - xr(0)) / npix
	ENDIF

	IF ~KEYWORD_SET(z_type) THEN BEGIN
		z_type	= 'mass'
		DOC_LIBRARY, 'draw_gas'
		PRINT, 'z_type is automatically set by mass'
	ENDIF

	IF ~KEYWORD_SET(den_type) THEN BEGIN
		den_type = '3Dden'
		DOC_LIBRARY, 'draw_gas'
		PRINT, 'den_type is automatically set by 3D den'
	ENDIF

	;;-----
	;; Make a Map
	;;-----
	npix	= LONG(MAX([xr(1) - xr(0), yr(1) - yr(0)]) / mindx) + 1L

	map	= FLTARR(npix, npix)

	mapX = FINDGEN(npix) + 0.5 & mapY = FINDGEN(npix) + 0.5
	mapX = REBIN(mapX, npix, npix) & mapY = REBIN(TRANSPOSE(mapY), npix, npix)
	mapX = mapX * mindx + xr(0) & mapY = mapY * mindx  + yr(0)

	;;-----
	;; Projection
	;;-----
	;lev	= LONG(ALOG10(amr.dx / MIN(amr.dx)) / ALOG10(2.0))
	
	IF ~KEYWORD_SET(maxlev) THEN maxlev = 100L
	IF ~KEYWORD_SET(minlev) THEN minlev = 0L
	cut	= WHERE(amr.level LE maxlev AND amr.level GE minlev AND $
		amr.x + amr.dx/2 - GAL.xc(ind) GE xr(0) AND $
		amr.x - amr.dx/2 - GAL.xc(ind) LE xr(1) AND $
		amr.y + amr.dx/2 - GAL.yc(ind) GE yr(0) AND $
		amr.y - amr.dx/2 - GAL.yc(ind) LE yr(1) AND $
		amr.z + amr.dx/2 - GAL.zc(ind) GE zr(0) AND $
		amr.z - amr.dx/2 - GAL.zc(ind) LE zr(1), ncut)
	IF ncut EQ 0L THEN BEGIN
		PRINT, 'NO AVAILABLE DATA LEFT'
		DOC_LIBRARY, 'draw_gas'
		RETURN
	ENDIF

	;ftr_name	= dir_lib + '../fortran/f_rdgas.so'
	ftr_name	= dir_lib + 'fortran/f_rdgas.so'
		larr = lonarr(20) & darr = dblarr(20)
		larr(0)	= ncut
		larr(1)	= npix
		larr(2)	= num_thread

		IF den_type EQ '3Dden' THEN larr(18) = 1
		IF den_type EQ '2Dden' THEN larr(18) = 2
		IF den_type EQ '1Dden' THEN larr(18) = 3

		IF z_type EQ 'nH' THEN larr(19) = 1
		IF z_type EQ 'temp' THEN larr(19) = 2
		IF z_type EQ 'metal' THEN larr(19) = 3

		;IF larr(19) GE 2L OR larr(18) GE 2L THEN BEGIN
		IF larr(18) GE 2L THEN BEGIN
			PRINT, 'current set has not been implemented yet'
			STOP
		ENDIF

		darr(0)	= mindx
		darr(10:11) = xr
		darr(12:13) = yr
		darr(14:15) = zr

		dum	= DBLARR(ncut,3)
			dum(*,0)	= amr.density(cut)		; in solar mass
			dum(*,1)	= amr.temperature(cut)
			dum(*,2)	= amr.metal(cut)
		void	= CALL_EXTERNAL(ftr_name, 'f_rdgas', $
			larr, darr, amr.dx(cut), $
			amr.x(cut) - GAL.xc(ind), $
			amr.y(cut) - GAL.yc(ind), $
			amr.z(cut) - GAL.zc(ind), $
			dum, map)
		       
	;;-----
	;; Draw
	;;-----
	Loadct, 33

	drange	= [MIN(map(WHERE(map GT 0.))), MAX(map)]
	drange	= ALOG10(drange)
	;loadct, 42, file='~/idl_setting/js_idlcolor.tbl'
	map(WHERE(map EQ 0.)) = 1e-20
	map2	= BYTSCL(ALOG10(map), min=drange(0), max=drange(1))
	cgImage, map2, position=position, /noerase
	;PRINT, drange

End
