
FUNCTION f_rdgalquick, snap, dir=dir, horg=horg

	file	= dir
	IF horg EQ 'h' THEN file += 'Halo/VR_Halo/snap_'
	IF horg EQ 'g' THEN file += 'Galaxy/VR_Galaxy/snap_'

	file	+= STRING(snap,format='(I4.4)') + '/quick.txt'

	readcol, file, v1, v2, v3, v4, v5, v6, $
		format='L, D, D, D, D, D', numline=FILE_LINES(file)

	
	tmp	= {ID:0L, Mass_tot:0.d, Mvir:0.d, Xc:0.d, Yc:0.d, Zc:0.d, snapnum:snap}
	var	= REPLICATE(tmp, N_ELEMENTS(v1))

	var.ID		= v1
	var.Mass_tot	= v2
	var.Mvir	= v3
	var.xc		= v4
	var.yc		= v5
	var.zc		= v6
	RETURN, var
END



