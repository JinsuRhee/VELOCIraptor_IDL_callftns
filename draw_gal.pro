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

FUNCTION draw_gal, nsnap, id, $
	vrheader=vrheader, $
	num_thread=num_thread, $
	raw=raw, boxrange=boxrange, $
	n_pix=n_pix, min=min, max=max, $
	scale_type=scale_type, $
	adap_range=adap_range, $
	proj=proj, dlist=dlist, horg=horg, weight=weight, $
	dir_raw=dir_raw, dir_catalog=dir_catalog, Neff=Neff, family=family, llint=llint

	;;-----
	;; SETTINGS
	;;-----
	IF ~KEYWORD_SET(num_thread) THEN num_thread = 10L
	IF ~KEYWORD_SET(n_pix) THEN n_pix = 1000L
	IF ~KEYWORD_SET(min) THEN min=1e4
	IF ~KEYWORD_SET(max) THEN max=1e11
	IF ~KEYWORD_SET(scale_type) THEN scale_type='log'
	IF ~KEYWORD_SET(horg) THEN horg = 'g'
	IF ~KEYWORD_SET(weight) THEN weight='mass'
	IF ~KEYWORD_SET(proj) THEN proj = 'xy'

	IF horg EQ 'h' AND ~KEYWORD_SET(Neff) AND ~KEYWORD_SET(vrheader) THEN BEGIN
                PRINT, '%123123 -----'
                PRINT, '        Specify "Neff"'
                DOC_LIBRARY, 'draw_gal'
                STOP
        ENDIF

	;;-----
	;; LOAD GAL
	;;-----
	IF KEYWORD_SET(vrheader) THEN BEGIN
		gal	= f_rdgal(nsnap, id, header=vrheader, horg=horg)
	ENDIF ELSE BEGIN
		gal	= f_rdgal(nsnap, id, column_list=['Xc', 'Yc', 'Zc'], dir=dir_catalog, horg=horg)
	ENDELSE

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
	IF KEYWORD_SET(vrheader) THEN BEGIN
		tmp	= 'ptcl = f_rdptcl(nsnap, id, num_thread=num_thread, ' + $
			'header=vrheader, /p_pos, horg=horg'
	ENDIF ELSE BEGIN
		tmp	= 'ptcl = f_rdptcl(nsnap, id, num_thread=num_thread, ' + $
			'dir_raw=dir_raw, dir_catalog=dir_catalog, /p_pos, horg=horg'
		IF KEYWORD_SET(family) THEN tmp += ', /family'
		IF KEYWORD_SET(llitn) THEN tmp += ', /llint'
		IF horg EQ 'h' THEN tmp += ', Neff=Neff'
	ENDELSE

	IF weight EQ 'mass' THEN BEGIN
		tmp	+= ', /p_mass'
	ENDIF ELSE BEGIN
		tmp	+= ', /p_gyr, /p_flux, flux_list=["' + STRTRIM(weight,2) + '"]'
	ENDELSE

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

	IF weight EQ 'mass' THEN BEGIN
		ww	= ptcl.mp
	ENDIF ELSE BEGIN
		tmp2	= 'ww = ptcl.f_' + STRTRIM(weight,2)
		void	= EXECUTE(tmp2)
	ENDELSE

	den	= js_kde($
		xx=ptcl.xp(*,cind(0)), yy=ptcl.xp(*,cind(1)), xrange=xr, yrange=yr, $
		n_pix=n_pix, mode=-1L, kernel=1L, bandwidth=bw, weight=ww, $
		num_thread=num_thread, /silent)

	;;-----
	;; MAKE IMAGE
	;;-----
	img	= draw_gal_minmax(den.z, min=min, max=max)

	IF scale_type EQ 'log' THEN $
		img	= ALOG(1000.*img + 1.) / ALOG(1000.)
	IF scale_type EQ 'asinh' THEN $
		img	= ASINH(10.*img)/3.

	img	= img < 1.
	img	= BYTE(img*255.)

	RETURN, img
END
