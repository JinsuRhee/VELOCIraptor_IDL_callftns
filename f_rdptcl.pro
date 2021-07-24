;;
;;	gid : Galaxy ID (not an index)
;;
;;	family : boolean
;;		if raw data files contain family types
;;	boxrange : boxsize in Kpc
FUNCTION f_rdptcl, gid, n_snap, num_thread=num_thread, $
	dir_raw=dir_raw, dir_catalog=dir_catalog, $
	p_pos=p_pos, p_vel=p_vel, p_gyr=p_gyr, p_sfactor=p_sfactor, $
	p_mass=p_mass, p_flux=p_flux, p_metal=p_metal, p_id=p_id, $
	flux_list=flux_list, $
	llint=llint, raw=raw, alldom=alldom, domlist=domlist, $
	boxrange=boxrange, $
	family=family, horg=horg

	;;-----
	;; Settings
	;;-----
	FINDPRO, 'f_rdptcl', dirlist=curr_dir
	dir_lib	= curr_dir(0)

	IF ~KEYWORD_SET(dir_catalog) OR ~KEYWORD_SET(dir_raw) THEN BEGIN
		PRINT, 'dir location should be referred'
		DOC_LIBRARY, 'f_rdptcl'
		RETURN, 0L
	ENDIF

	IF ~KEYWORD_SET(flux_list) THEN BEGIN
		IF KEYWORD_SET(p_flux) THEN BEGIN
			PRINT, 'flux list should be input when p_flux turned on'
			DOC_LIBRARY, 'f_rdptcl'
			RETURN, 0L
		ENDIF

		flux_list	= ['u']
	ENDIF

	IF ~KEYWORD_SET(p_gyr) AND KEYWORD_SET(p_flux) THEN BEGIN
		PRINT, 'p_gyr should be turned on when computing flux'
		DOC_LIBRARY, 'f_rdptcl'
		RETURN, 0L
	ENDIF

	IF ~KEYWORD_SET(num_thread) THEN num_thread=1L
	IF ~KEYWORD_SET(horg) THEN horg='g'
	;;-----
	;; Read Particle IDs & Domain & Center & Radius
	;;	*) Halo options should be added though horg keyword !!
	;;-----
	IF horg EQ 'h' THEN $
		dir	= dir_catalog + 'Halo/VR_Halo/snap_' + string(n_snap,format='(I4.4)') + '/'
	IF horg EQ 'g' THEN $
		dir	= dir_catalog + 'Galaxy/VR_Galaxy/snap_' + string(n_snap,format='(I4.4)') + '/'
	
	fname	= dir + 'GAL_' + string(gid,format='(I6.6)') + '.hdf5'

	fid = H5F_OPEN(fname) & did = H5D_OPEN(fid, '/P_Prop/P_ID')
	pid = H5D_READ(did) & H5D_CLOSE, did & H5F_CLOSE, fid

	IF horg EQ 'g' THEN BEGIN
		fid = H5F_OPEN(fname) & did = H5D_OPEN(fid, '/Domain_List')
		dom_list = H5D_READ(did) & H5D_CLOSE, did & H5F_CLOSE, fid
	ENDIF ELSE IF horg EQ 'h' THEN BEGIN
		dom_list	= LONARR(4800)-1L
	ENDIF

	fid	= H5F_OPEN(fname)
       	did = H5D_OPEN(fid, '/G_Prop/G_Xc') & xc = H5D_READ(did) & H5D_CLOSE, did
	did = H5D_OPEN(fid, '/G_Prop/G_Yc') & yc = H5D_READ(did) & H5D_CLOSE, did
	did = H5D_OPEN(fid, '/G_Prop/G_Zc') & zc = H5D_READ(did) & H5D_CLOSE, did
	did = H5D_OPEN(fid, '/G_Prop/G_R_HalfMass') & Rsize = H5D_READ(did) & H5D_CLOSE, did
	H5F_CLOSE, fid

	;;-----
	;; Read Info File
	;;-----
	infoname	= dir_raw + 'output_' + STRING(n_snap,format='(I5.5)') + $
		'/info_' + STRING(n_snap,format='(I5.5)') + '.txt'
	rd_info, siminfo, file=infoname

	;;-----
	;; Settings
	;;-----
	n_ptcl	= N_ELEMENTS(pid)
	dlist	= (WHERE(dom_list ge 0L)) + 1L
	n_band	= N_ELEMENTS(flux_list)

	xc	= xc / siminfo.unit_l * 3.086d21
	yc	= yc / siminfo.unit_l * 3.086d21
        zc	= zc / siminfo.unit_l * 3.086d21
	Rsize	= Rsize / siminfo.unit_l * 3.086d21	

	;;-----
	;; Allocate Memory
	;;-----
	pinfo	= DBLARR(n_ptcl,9) -  1.0d8
		;; POS, VEL, MASS, AGE, METALLICITY

	;;-----
	;; Get Ptcl
	;;-----
	IF ~KEYWORD_SET(raw) THEN BEGIN
		ftr_name	= dir_lib + 'fortran/get_ptcl.so'
			larr = LONARR(20) & darr = DBLARR(20)
			larr(0) = n_ptcl
			larr(1) = N_ELEMENTS(dlist)
			larr(2) = n_snap
			larr(3)	= num_thread
			larr(10)= STRLEN(dir_raw)
			IF horg EQ 'g' THEN larr(11) = 10L
			IF horg EQ 'h' THEN larr(11) = -10L
			larr(18)= 0L
			larr(19)= 0L
			IF KEYWORD_SET(family) THEN larr(18) = 100L
			IF KEYWORD_SET(llint) THEN larr(19)= 100L

		void	= CALL_EXTERNAL(ftr_name, 'get_ptcl', $
			larr, darr, dir_raw, pid, pinfo, dlist)

	ENDIF ELSE BEGIN
		;;----- Get Domain Again
		dom_list2	= dom_list * 0L - 1L
		ftr_name	= dir_lib + 'fortran/find_domain.so'
			larr = LONARR(20) & darr = DBLARR(20)
			larr(0) = N_ELEMENTS(xc)
			larr(1) = N_ELEMENTS(dom_list2)
			larr(2) = num_thread

			darr(0) = 50.
			IF KEYWORD_SET(boxrange) THEN darr(0) = boxrange / (Rsize * siminfo.unit_l / 3.086d21)

		void	= CALL_EXTERNAL(ftr_name, 'find_domain', $
			xc, yc, zc, Rsize, siminfo.hindex, siminfo.levmax, dom_list2, larr, darr)

		dlist	= WHERE(dom_list2 GE 0L) + 1L

		domlist	= dlist	; for output

		;;----- Get # of Ptcls
		nbody	= 0L
		FOR ii=0L, N_ELEMENTS(dlist)-1L DO BEGIN
			fname	= dir_raw + 'output_' + STRING(n_snap,format='(I5.5)') + '/part_' + $
				STRING(n_snap,format='(I5.5)') + '.out' + STRING(dlist(ii),format='(I5.5)')
			nbodydum = 0L
			OPENR, 1, fname, /f77_unformatted, SWAP_ENDIAN=swap
			READU, 1
			READU, 1
			READU, 1, nbodydum
			CLOSE, 1
			nbody	= nbody + nbodydum
		ENDFOR

		pinfo	= DBLARR(nbody,9)
		ftr_name	= dir_lib + 'fortran/get_ptcl.so'
			larr = LONARR(20) & darr = DBLARR(20)
			larr(0) = nbody
			larr(1) = N_ELEMENTS(dlist)
			larr(2) = n_snap
			larr(3)	= num_thread
			larr(10)= STRLEN(dir_raw)
			IF horg EQ 'g' THEN larr(11) = 10L
			IF horg EQ 'h' THEN larr(11) = -10L
			larr(17)	= 100L
			larr(18)	= 0L
			larr(19)	= 0L
			IF KEYWORD_SET(family) THEN larr(18) = 100L
			IF KEYWORD_SET(llint) THEN larr(19)= 100L

		void	= CALL_EXTERNAL(ftr_name, 'get_ptcl', $
			larr, darr, dir_raw, pid, pinfo, dlist)
		pinfo	= pinfo(0L:larr(16)-1L,*)
	ENDELSE

	;;-----
	;; Extract
	;;-----
	cut	= WHERE(pinfo(*,0) gt -1.0d7)
	IF MAX(cut) LT 0 THEN BEGIN
		PRINT, '	%%%%% This galaxy has no matched particles'
		RETURN, -1.
	ENDIF

	output	= {rate: (N_ELEMENTS(cut) * 1.d ) / n_ptcl}

	xp	=  pinfo(*,0:2) * siminfo.unit_l / 3.086d21
	IF KEYWORD_SET(p_pos) THEN $
		output = CREATE_STRUCT(output, 'xp', xp(cut,*))

	vp	=  pinfo(*,3:5) * siminfo.kms
	IF KEYWORD_SET(p_vel) THEN $
		output = CREATE_STRUCT(output, 'vp', vp(cut,*))

	mp	=  pinfo(*,6) * siminfo.unit_m / 1.98892d33
	IF KEYWORD_SET(p_mass) THEN $
		output = CREATE_STRUCT(output, 'mp', mp(cut,*))

	IF KEYWORD_SET(p_gyr) OR KEYWORD_SET(p_sfactor) THEN BEGIN
		dummy   = g_gyr(pinfo(*,7), dir_raw=dir_raw, dir_lib=dir_lib, $
			num_thread=num_thread, n_snap=n_snap)
		IF KEYWORD_SET(p_gyr) THEN $
			output = CREATE_STRUCT(output, 'GYR', dummy(cut,1))
	        IF KEYWORD_SET(p_sfactor) THEN $
			output = CREATE_STRUCT(output, 'SFACTOR', dummy(cut,0))
	ENDIF

	IF KEYWORD_SET(p_id) THEN $
		output = CREATE_STRUCT(output, 'id', pid)

	zp	= pinfo(*,8)
	IF KEYWORD_SET(p_metal) THEN $
		output = CREATE_STRUCT(output, 'zp', zp(cut))

	IF KEYWORD_SET(p_flux) THEN BEGIN
		FOR i=0L, n_band - 1L DO BEGIN
			dummy2	= g_flux(mp, zp, dummy(*,1), $
				lib=dir_lib, band=flux_list(i), num_thread=num_thread)

			output = CREATE_STRUCT(output, 'F_' + flux_list(i), dummy2(cut))
		ENDFOR
	ENDIF

	IF KEYWORD_SET(raw) THEN $
		output	= CREATE_STRUCT(output, 'dom_list', dlist)


	RETURN, output
END
