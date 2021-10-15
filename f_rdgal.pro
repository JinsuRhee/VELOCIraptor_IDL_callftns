FUNCTION f_rdgal_getidlist, flist

	idlist	= LONARR(N_ELEMENTS(flist))
	FOR i=0L, N_ELEMENTS(flist)-1L DO BEGIN
		str	= STRSPLIT(flist(i), '/', /extract)
		str	= str(-1)
		str	= STRSPLIT(str, '_', /extract)
		str	= str(1)
		str	= STRSPLIT(str, '.', /extract)
		str	= str(0)
		idlist(i)	= LONG(str)
	ENDFOR
	RETURN, idlist
END

;;---------------
;; IDL routine for calling VR output
;;	Written by JR
;;	(jinsu.rhee@gmail.com)
;;
;; Name
;;	- f_rdgal
;;
;; Purpose
;;	- read galaxy list as a structure array
;;
;; Input
;;	- snapshot number
;;		
;;	- id
;;		VR Galaxy (or Halo) ID to call
;;		negative ID calls all galaxies
;;
;; Keyword
;;	- header
;;		full path for 'vrheader.txt' which includes default setting values of VR outputs
;;
;;	- horg
;;		halo('h') or galaxy('g') specification
;;		default setting is 'g'
;;
;;	- column_list (not required if header keyword is set)
;;		list of galaxy properties that you want to call
;;		['Xc', 'Yc', ...]
;;		refer to the VR raw output file (*.dat.properties.0)
;;
;;	- dir (not required if header keyword is set)
;;		full parth for the raw VR output
;;
;;	- num_thread
;;		not available
;; Example
;;	gal = f_rdgal(1026, -1L, header='vrheader.txt', horg='g')
;;		'read all galaxies at #SS = 1026'
;;	gal = f_rdgal(1026, 1L, horg='g', column_list=['Xc', 'Yc', 'Zc', 'Mass_tot'], dir='a/full/path/VELOCIraptor/')
;;		'read ID=1 galaxy at #SS = 1026 with its position and total mass output'
;;---------------
FUNCTION f_rdgal, n_snap, id0, header=header, horg=horg, $
	column_list=column_list, dir=dir, $
	num_thread=num_thread

	;;-----
	;; Initial Settings
	;;-----
	IF KEYWORD_SET(header) THEN BEGIN
		settings	 = f_rdheader(header)
		Gprop2	= settings.column_list
		IF horg EQ 'g' THEN Gprop2 = [Gprop2, settings.gal_prop]
		dir	= settings.dir_catalog
		dir_lib	= settings.dir_lib
	ENDIF ELSE BEGIN
		IF ~KEYWORD_SET(dir) OR ~KEYWORD_SET(column_list) THEN BEGIN
			PRINT, '%123123	-----'
			PRINT, '	Either header or column_list/dir keywords should turn on'
			DOC_LIBRARY, 'f_rdgal'
			RETURN, -1
		ENDIF
		Gprop2	= column_list
		FINDPRO, 'f_rdgal', dirlist=curr_dir, /noprint
		dir_lib = curr_dir(0)
	ENDELSE

	IF ~KEYWORD_SET(horg) THEN horg = 'g'
	;;-----
	;; Correction for the naming convention
	;;-----
	Gprop	= Gprop2
	FOR i=0L, N_ELEMENTS(Gprop)-1L DO BEGIN
		IF Gprop(i) EQ 'sfr' THEN Gprop(i) = 'SFR'
		IF Gprop(i) EQ 'ABMAG' OR $
			Gprop(i) EQ 'abmag' THEN Gprop(i) = 'ABmag'
		;IF Gprop(i) EQ 'SFR' THEN Gprop = [Gprop, 'SFR_clumpycorr']
	ENDFOR

	;;-----
	;; Settings
	;;-----
	dir_catalog	= dir
	IF horg EQ 'g' THEN $
		dir_catalog += 'Galaxy/VR_Galaxy/snap_' + STRING(n_snap,format='(I4.4)') + '/'
	IF horg EQ 'h' THEN $
		dir_catalog += 'Halo/VR_Halo/snap_' + STRING(n_snap,format='(I4.4)') + '/'

	IF ~KEYWORD_SET(num_thread) THEN num_thread = 1L

	;;-----
	;; GET File list
	;;-----
	IF id0 GE 0L THEN BEGIN
		flist	= dir_catalog + 'GAL_' + STRING(id0, format='(I6.6)') + '.hdf5'
	ENDIF ELSE BEGIN
		flist	= file_search(dir_catalog + 'GAL_*')
	ENDELSE

	n_gal	= n_elements(flist)

	;;-----
	;; Allocate Memory
	;;-----
	tmpstr	= 'GP = {snapnum:0L,'
	fid	= H5F_OPEN(flist(0))
	FOR j=0L, N_ELEMENTS(Gprop) - 1L DO BEGIN
		did	= H5D_OPEN(fid, '/G_Prop/G_' + $
			STRTRIM(Gprop(j),2))
		IF Gprop(j) EQ 'SFR' OR Gprop(j) EQ 'ABmag' OR Gprop(j) EQ 'SFR_clumpycorr' THEN BEGIN
			tmp	= 't' + Gprop(j) + '= H5D_READ(did)'
		ENDIF ELSE BEGIN
			tmp	= 't' + Gprop(j) + '= H5D_READ(did)'
			tmp	+= ' & t' + Gprop(j) + '= t' + Gprop(j) + '(0)'
		ENDELSE
		void	= EXECUTE(tmp)
		H5D_CLOSE, did
		tmpstr	+= Gprop(j) + ':t'+ Gprop(j) + ', '
	ENDFOR

	IF horg EQ 'g' THEN BEGIN
		did	= H5D_OPEN(fid, '/Domain_List')
		dlist	= H5D_READ(did)
		H5D_CLOSE, did

		did	= H5D_OPEN(fid, '/Flux_List')
		flux_list	= H5D_READ(did)
		H5D_CLOSE, did

		did	= H5D_OPEN(fid, '/MAG_R')
		mag_r	= H5D_READ(did)
		H5D_CLOSE, did

		did	= H5D_OPEN(fid, '/SFR_R')
		sfr_r	= H5D_READ(did)
		H5D_CLOSE, did

		did	= H5D_OPEN(fid, '/SFR_T')
		sfr_t	= H5D_READ(did)
		H5D_CLOSE, did

		did	= H5D_OPEN(fid, '/G_Prop/G_ConFrac')
		confrac	= H5D_READ(did)
		H5D_CLOSE, did

		did	= H5D_OPEN(fid, '/CONF_R')
		conf_r	= H5D_READ(did)
		H5D_CLOSE, did

		H5F_CLOSE, fid
		tmpstr	+= 'isclump:1L, rate:1.0d, Domain_List:dlist, Flux_List:flux_list, Aexp:1.0d, '
		tmpstr	+= 'MAG_R:MAG_R, SFR_R:SFR_R, SFR_T:SFR_T, CONF_R:CONF_R, CONFRAC:CONFRAC}'
		n_mpi	= N_ELEMENTS(dlist)
	ENDIF ELSE BEGIN
		tmpstr	+= 'Aexp:1.0d, CONFRAC:-1.d}'
		H5F_CLOSE, fid
	ENDELSE

	void	= EXECUTE(tmpstr)

	GP	= REPLICATE(GP, n_gal)


	;;-----
	;; READ BY FORTRAN
	;;
	;;	--JS--
	;;		To Do list... read multiple hdf5 files with a fortran routine (perhaps w/ omp parallelization)
	;;-----
	;idlist	= f_rdgal_getidlist(flist)

	;ftr_name	= dir_lib + 'fortran/f_rdgal';.so'
	;	larr = LONARR(20) & darr = DBLARR(20)
	;	larr(0)	= n_gal
	;	larr(1)	= STRLEN(dir_catalog)
	;	larr(2)	= num_thread

	;FOR i=0L, N_ELEMENTS(Gprop)-1L DO BEGIN
	;	;; EXTRACT
	;	void	= EXECUTE('tmp = GP.' + Gprop(i))


	;	IF TYPENAME(tmp) EQ 'LONG64' THEN BEGIN
	;		ftr_name2	= ftr_name + '_l64.so'
	;		routine_name	= 'f_rdgal_l64'
	;	ENDIF ELSE IF TYPENAME(tmp) EQ 'LONG' THEN BEGIN
	;		ftr_name2	= ftr_name + '_l.so'
	;		routine_name	= 'f_rdgal_l'
	;	ENDIF ELSE IF TYPENAME(tmp) EQ 'FLOAT' THEN BEGIN
	;		ftr_name2	= ftr_name + '_f.so'
	;		routine_name	= 'f_rdgal_f'
	;	ENDIF ELSE IF TYPENAME(tmp) EQ 'DOUBLE' THEN BEGIN
	;		ftr_name2	= ftr_name + '_d.so'
	;		routine_name	= 'f_rdgal_d'
	;	ENDIF ELSE BEGIN
	;		PRINT, 'undefined type'
	;		STOP
	;	ENDELSE

	;	larr(3)	= STRLEN(Gprop(i))
	;	void	= CALL_EXTERNAL(ftr_name2, routine_name, $
	;		larr, darr, Gprop(i), dir_catalog, idlist, tmp)
	;	STOP
	;ENDFOR
	;STOP

	;;-----
	;; Read Galaxies
	;;-----
	FOR i=0L, n_gal - 1L DO BEGIN

		fid	= H5F_OPEN(flist(i))
		FOR j=0L, N_ELEMENTS(Gprop) - 1L DO BEGIN
			did	= H5D_OPEN(fid, '/G_Prop/G_' + $
				STRTRIM(Gprop(j),2))
			tmp	= 'GP(' + STRTRIM(i,2) + ').' + STRTRIM(Gprop(j),2) + $
				'=H5D_READ(did)'
			void	= EXECUTE(tmp)
			H5D_CLOSE, did
		ENDFOR

		IF horg EQ 'g' THEN BEGIN
			did	= H5D_OPEN(fid, '/isclump')
			GP(i).isclump	= H5D_READ(did)
			H5D_CLOSE, did

			did	= H5D_OPEN(fid, '/Domain_List')
			GP(i).Domain_list	= H5D_READ(did)
			H5D_CLOSE, did

			did	= H5D_OPEN(fid, '/rate')
			GP(i).rate	= H5D_READ(did)
			H5D_CLOSE, did

			did	= H5D_open(fid, '/Flux_List')
			GP(i).flux_list	= H5D_READ(did)
			H5D_close, did

			did	= H5D_open(fid, '/Aexp')
			GP(i).aexp	= H5D_READ(did)
			H5D_close, did
		ENDIF

		H5F_close, fid
		GP(i).snapnum	= n_snap
	ENDFOR

	RETURN, GP

END
