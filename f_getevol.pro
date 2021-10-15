FUNCTION f_getevol, tree2, numsnap, id0, header=header, datalist=datalist, horg=horg, dir=dir;, tmerit=tmerit, tmass=tmass

	;;-----
	;; Settings
	;;-----
	tree	= tree2
	IF TYPENAME(tree) EQ 'POINTER' THEN tree = (*tree)

	n0	= numsnap
	IF ~KEYWORD_SET(horg) THEN horg = 'g'

	;;-----
	;; READ FINAL GAL FIRST
	;;-----
	IF ~KEYWORD_SET(header) THEN g = f_rdgal(n0, id0, column_list=datalist, dir=dir, horg=horg)
	IF KEYWORD_SET(header) THEN g = f_rdgal(n0, id0, horg=horg, header=header)

	;;-----
	;; Memory Allocate
	;;-----

	IF TYPENAME(tree) EQ 'LONG' THEN $
		RETURN, g

	GAL	= REPLICATE(g, N_ELEMENTS(tree.id))


	slist	= tree.snap
	ilist	= tree.id

	cut	= WHERE(slist GE 0L)
	slist	= slist(cut)
	ilist	= ilist(cut)

	cut	= WHERE(ilist GE 0L)
	slist	= slist(cut)
	ilist	= ilist(cut)

	;;-----
	;; Input
	;;----
	FOR i=0L, N_ELEMENTS(ilist)-1L DO BEGIN
		IF KEYWORD_SET(header) THEN GAL(i) = f_rdgal(slist(i), ilist(i), horg=horg, header=header)
		IF ~KEYWORD_SET(header) THEN GAL(i) = f_rdgal(slist(i), ilist(i), column_list=datalist, dir=dir, horg=horg)
	ENDFOR

	RETURN, GAL
END
