;; Procedure that converts conformal time to scale factor and Gyr

FUNCTION g_gyr, t_conf, $
	dir_raw=dir_raw, dir_lib=dir_lib, $
	num_thread=num_thread, n_snap=n_snap

	;;-----
	;; Settings
	;;-----
	IF(~KEYWORD_SET(num_thread)) THEN SPAWN, 'nproc --all', num_thread
	IF(~KEYWORD_SET(num_thread)) THEN num_thread = LONG(num_thread)

	infoname	= dir_raw + 'output_' + STRING(n_snap,format='(I5.5)') + $
		'/info_' + string(n_snap,format='(I5.5)') + '.txt'
	rd_info, siminfo, file=infoname

	oM	= siminfo.omega_m
	oL	= siminfo.omega_l
	H0	= siminfo.h0

	;;-----
	;; Run or Load - conformal time table
	;;-----
	skip	= 0L
	conf_file	= dir_lib + 'conformal_table.sav'
	IF STRLEN(FILE_SEARCH(conf_file)) GE 5L THEN BEGIN
		RESTORE, conf_file
		IF doM NE oM OR doL NE oL THEN skip=1L
	ENDIF ELSE BEGIN
		skip	= 1L
	ENDELSE

	IF skip EQ 1L THEN BEGIN
		c_conformal, oM=oM, oL=oL, dir=dir_lib
		RESTORE, conf_file
	ENDIF
		
	;;-----
	;; Run or Load - Gyr time table
	;;-----
	skip	= 0L
	lbt_file	= dir_lib + 'LBT_table.sav'
	IF STRLEN(FILE_SEARCH(lbt_file)) GE 5L THEN BEGIN
		RESTORE, lbt_file
		IF doM NE oM OR doL NE oL OR dH0 NE H0 THEN skip=1L
	ENDIF ELSE BEGIN
		skip	= 1L
	ENDELSE

	IF skip EQ 1L THEN BEGIN
		c_lbt, oM=oM, oL=oL, H0=H0, dir=dir_lib
		RESTORE, lbt_file
	ENDIF

	;;-----
	;; Allocate Memory
	;;-----

	n_mpi	= n_elements(siminfo.hindex(*,0))
	n_part	= n_elements(t_conf)

	t_res	= dblarr(n_part,2) - 1.0d8	;; [SFactor, GYR]
	v1 = dblarr(n_part) - 1.0d8 & v2 = dblarr(n_part) - 1.0d8
	;;-----
	;; Fortran Routine
	;;-----
	ftr_name	= dir_lib + 'fortran/prop_time.so'
		larr = lonarr(20) & darr = dblarr(20)
		larr(0)	= n_part
		larr(1)	= num_thread

		darr(0)	= 1./siminfo.aexp - 1.0d

	void	= call_external(ftr_name, 'prop_time', $
		t_conf, v1, v2, conft, sfact, tmp_red, tmp_gyr, $
		larr, darr)

	t_res(*,0) = v1 & t_res(*,1) = v2
	return, t_res

END
