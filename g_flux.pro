FUNCTION g_flux, mass, met, gyr, $
	lib=lib, band=band, num_thread=num_thread

	;;-----
	;; Settings
	;;-----

	;;-----
	;; Allocate memory
	;;-----
	cut	= where(gyr gt -1.0d7)
	flux_tmp= gyr(cut) * 0. - 1.0d8

	flux2	= gyr*0. - 1.0d8
	;;-----
	;; Load Tables
	;;-----
	restore, lib + 'ssp_table_chab.sav'
		ssp_table	= fltarr(6,n_elements(lambda), n_elements(age))
		;; Metallicity bin X Wavelength bin X Age bin

		FOR ii=0L, 5L DO ssp_table(ii,*,*) = flux(ii).f
		metal_str	= ['0.0004', '0.0010', '0.0040', '0.0100', '0.0200', '0.0400']
		metal_val	= double(metal_str)

	;;-----
	;; BAND SETTINGS
	;;-----
	band_zf	= 1.0d

	IF band EQ 'u' THEN BEGIN
		band_zf = 895.5*1d-11 ; f_lambda [1e-11 erg cm^-2 s^-1 A^-1]
		band_lam = float(lam_u) & band_tr = float(tr_u)
	ENDIF ELSE IF band EQ 'g' THEN BEGIN
		band_zf = 466.9*1d-11
		band_lam = float(lam_g) & band_tr = float(tr_g)
	ENDIF ELSE IF band EQ 'r' THEN BEGIN
		band_zf = 278.0*1d-11
		band_lam = float(lam_r) & band_tr = float(tr_r)
	ENDIF ELSE IF band EQ 'i' THEN BEGIN
		band_zf = 185.2*1d-11
		band_lam = float(lam_i) & band_tr = float(tr_i)
	ENDIF ELSE IF band EQ 'z' THEN BEGIN
		band_zf = 131.5*1d-11	
		band_lam = float(lam_z) & band_tr = float(tr_z)
	ENDIF ELSE BEGIN
		PRINT, 'NOT IMPLEMENTED YET'
		STOP
	ENDELSE

	;;-----
	;; Calculation
	;;-----
	ftr_name	= lib + 'fortran/get_flux.so'
		larr = lonarr(20) & darr = dblarr(20)
		larr(0)	= n_elements(cut)	; # of Ptcls
		larr(1) = n_elements(age) 	; # of age array of SSP
		larr(2) = n_elements(metal_val) ; # of metal array of SSP
		larr(3) = n_elements(lambda)	; # of wavelength array of SSP
		larr(4) = n_elements(band_lam)	; # of TR curve array
		larr(10)= num_thread

		void	= call_external(ftr_name, 'get_flux', $
			float(gyr(cut)), float(met(cut)), mass(cut), $
			float(age), float(metal_val), float(lambda), $
			ssp_table, band_lam, band_tr, $
			flux_tmp, larr, darr)

		;; flux_tmp	[FLUX / LUMINOSITY]

		flux_tmp	= flux_tmp * 3.826e33 / $
			(4. * !pi * (10.0 * 3.08567758128D+18)^2)
		;; flux_tmp	[Integrated Flux at D = 10 pc]

		dlambda	= band_lam(1L:*) - band_lam(0L:-2)
		clambda	= (band_lam(1L:*) + band_lam(0L:-2L))/2.
		trcurve = (band_tr(1L:*) + band_tr(0L:-2L))/2.
		flux_tmp        = flux_tmp / total(band_zf * dlambda * clambda * trcurve)
		;; flux_tmp > F/F0

	flux2(cut)	= flux_tmp

	RETURN, flux2
END
