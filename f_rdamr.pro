;;-----
;;INPUT
;; 	gid
;;		- galaxy id in VR (GAL_id.hdf5)
;;
;;KEYWORD
;; 	n_snap (required)
;;		- snapshot number
;;	xr, yr, zr
;;		- volume range for finding amr cell
;;		- IF not set, rfact is used to find spherical volume
;;	num_thread
;;		- # of threads
;;	dir_raw, dir_catalog
;;		- dir_raw for the path of the RAMSES raw data files
;;		- dir_catalog for the parth of the VR raw data files


FUNCTION f_rdamr, gid, n_snap=n_snap, $
	xr=xr, yr=yr, zr=zr, rfact=rfact, $
	num_thread=num_thread, dir_raw=dir_raw, dir_catalog=dir_catalog

	;;-----
	;; Settings
	;;-----
	IF ~KEYWORD_SET(dir_raw) OR ~KEYWORD_SET(dir_catalog) THEN BEGIN
		PRINT, 'Input kewords for the directory path (dir_raw, dir_catalog)'
		DOC_LIBRARY, 'f_rdamr'
		RETURN, !NULL
	ENDIF
	IF ~KEYWORD_SET(n_snap) THEN BEGIN
		PRINT, 'Input snapshot number'
		DOC_LIBRARY, 'f_rdamr'
		RETURN, !NULL
	ENDIF

	IF ~KEYWORD_SET(num_thread) THEN num_thread = 1L
	IF ~KEYWORD_SET(rfact) THEN rfact = 1.0d

	FINDPRO, 'f_rdamr', dirlist=curr_dir
	curr_dir	= curr_dir(0)

	;;-----
	;; Domain & Center & Radius
	;;-----
	fname	= dir_catalog + 'Galaxy/VR_Galaxy/' + 'snap_' + $
		STRING(n_snap,format='(I4.4)') + '/GAL_' + $
		STRING(gid,format='(I6.6)') + '.hdf5'
	fid = H5F_OPEN(fname) & did = H5D_OPEN(fid, '/Domain_List')
	dom_list = H5D_READ(did) & H5D_CLOSE, did & H5F_CLOSE, fid

	fid     = H5F_OPEN(fname)
	did = H5D_OPEN(fid, '/G_Prop/G_Xc') & xc = H5D_READ(did) & H5D_CLOSE, did
	did = H5D_OPEN(fid, '/G_Prop/G_Yc') & yc = H5D_READ(did) & H5D_CLOSE, did
	did = H5D_OPEN(fid, '/G_Prop/G_Zc') & zc = H5D_READ(did) & H5D_CLOSE, did
	did = H5D_OPEN(fid, '/G_Prop/G_R_HalfMass') & Rsize = H5D_READ(did) & H5D_CLOSE, did
	H5F_CLOSE, fid

	dlist	= (WHERE(dom_list GE 0L)) + 1L

	;;-----
	;; Read Info File
	;;-----
	infoname        = dir_raw + 'output_' + STRING(n_snap,format='(I5.5)') + $
		'/info_' + STRING(n_snap,format='(I5.5)') + '.txt'
	rd_info, siminfo, file=infoname

	xc	= xc / siminfo.unit_l * 3.086d21
	yc	= yc / siminfo.unit_l * 3.086d21
	zc	= zc / siminfo.unit_l * 3.086d21
	rsize	= rsize / siminfo.unit_l * 3.086d21

	IF ~KEYWORD_SET(xr) OR ~KEYWORD_SET(yr) OR ~KEYWORD_SET(zr) THEN BEGIN
		xr	= [-rsize, rsize] * rfact + MEAN(xc)
		yr	= [-rsize, rsize] * rfact + MEAN(yc)
		zr	= [-rsize, rsize] * rfact + MEAN(zc)
	ENDIF

	;;-----
	;; Read AMR
	;;-----
	jsamr2cell, cell, dir=dir_raw + 'output_' + STRING(n_snap,format='(I5.5)'), $
		num_thread=num_thread, domlist=dlist


	mass	= cell.var(*,0) * cell.dx^3 * siminfo.unit_m / 1.98892d+33
	nH	= cell.var(*,0) * siminfo.unit_nH
	temp	= cell.var(*,4) / cell.var(*,0) * siminfo.unit_t2
	metal	= cell.var(*,6)

	dx	= cell.dx * siminfo.unit_l / 3.086d21
	x	= cell.x * siminfo.unit_l / 3.086d21
	y	= cell.y * siminfo.unit_l / 3.086d21
	z	= cell.z * siminfo.unit_l / 3.086d21

	cell	= {dx:dx, x:x, y:y, z:z, density:nH, $
		temperature:temp, metal:metal, mass:mass, level:cell.level}
	RETURN, cell
END
