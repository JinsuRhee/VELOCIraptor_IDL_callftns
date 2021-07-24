FUNCTION draw_gal_minmax, den, min=min, max=max
        cut     = WHERE(den LT min, ncut)
        IF ncut GE 1L THEN den(cut)= 0.

        cut     = WHERE(den GT 0.)
        den(cut)-= min

        cut     = WHERE(den GT max-min, ncut)
        IF ncut GE 1L THEN den(cut) = max-min

        den     = den/(max-min)
        RETURN, den
END

FUNCTION draw_gal, id, nsnap, $
	num_thread=num_thread, $
	dir_raw=dir_raw, dir_catalog=dir_catalog, $
	raw=raw, boxrange=boxrange, $
	n_pix=n_pix, min=min, max=max, $
	scale_type=scale_type, $
	adap_range=adap_range, $
	proj=proj, dlist=dlist, horg=horg

	;;-----
	;; SETTINGS
	;;-----
	IF ~KEYWORD_SET(num_thread) THEN num_thread = 10L
	IF ~KEYWORD_SET(n_pix) THEN n_pix = 1000L
	IF ~KEYWORD_SET(min) THEN min=1e4
	IF ~KEYWORD_SET(max) THEN max=1e11
	IF ~KEYWORD_SET(scale_type) THEN scale_type='log'
	IF ~KEYWORD_SET(horg) THEN horg = 'g'

	;;-----
	;; LOAD GAL
	;;-----
	gal	= f_rdgal(nsnap, ['Xc', 'Yc', 'Zc'], dir=dir_catalog, id0=id, horg=horg)

	cen	= [gal.xc, gal.yc]
	cind	= [0L, 1L]
	IF proj EQ 'xy' THEN BEGIN
		cen	= [gal.xc, gal.yc]
		cind	= [0L, 1L]
	ENDIF ELSE IF proj EQ 'yz' THEN BEGIN
		cen	= [gal.yc, gal.zc]
		cind	= [1L, 2L]
	ENDIF ELSE IF proj EQ 'xz' THEN BEGIN
		cen	= [gal.xc, gal.zc]
		cind	= [0L, 2L]
	ENDIF ELSE BEGIN
		PRINT, 'set the projection here'
		STOP
	ENDELSE
	;;-----
	;; LOAD PTCL
	;;-----
	tmp	= 'ptcl = f_rdptcl(id, nsnap, num_thread=num_thread, ' + $
		'dir_raw=dir_raw, dir_catalog=dir_catalog, /p_pos, /p_mass, horg=horg'

	IF KEYWORD_SET(raw) THEN BEGIN
		IF ~KEYWORD_SET(boxrange) THEN BEGIN
			PRINT, 'SET borange '
			STOP
		ENDIF
		boxrange2	= boxrange
		tmp	+= ', /raw, boxrange=boxrange2, domlist=dlist'
	ENDIF
	tmp	+= ')'
	void	= EXECUTE(tmp)

	IF ~KEYWORD_SET(raw) AND KEYWORD_SET(adap_range) THEN BEGIN
		box	= [MAX(ABS(ptcl.xp(*,cind(0)) - cen(0))), $
			MAX(ABS(ptcl.xp(*,cind(1)) - cen(1)))]
		box	= MAX(box)
		boxrange	= box
	ENDIF

	;;-----
	;; LOAD DE
	;;-----
	xr	= [-1., 1.]*boxrange + cen(0)
	yr	= [-1., 1.]*boxrange + cen(1)
	bw	= [xr(1)-xr(0), yr(1)-yr(0)]/n_pix

	den	= js_kde($
		xx=ptcl.xp(*,cind(0)), yy=ptcl.xp(*,cind(1)), xrange=xr, yrange=yr, $
		n_pix=n_pix, mode=-1L, kernel=1L, bandwidth=bw, weight=ptcl.mp, $
		num_thread=num_thread, /silent)

	;;-----
	;; MAKE IMAGE
	;;-----
	img	= draw_gal_minmax(den.z, min=min, max=max)

	IF scale_type EQ 'log' THEN $
		img	= ALOG(1000.*img + 1.) / ALOG(1000.)
	IF scale_type EQ 'asinh' THEN $
		img	= ASINH(10.*img)/3.

	img	= BYTE(img*255.)

	RETURN, img
END
