FUNCTION f_getevol, tree2, id0, numsnap, datalist, horg=horg, dir=dir;, tmerit=tmerit, tmass=tmass

	;;-----
	;; Settings
	;;-----
	tree	= tree2
	IF TYPENAME(tree) EQ 'POINTER' THEN tree = (*tree)

	n0	= numsnap
	IF ~KEYWORD_SET(horg) THEN horg = 'g'

	;;-----
	;; Memory Allocate
	;;-----

	IF TYPENAME(tree) EQ 'INT' THEN $
		RETURN, f_rdgal(n0, datalist, id0=id0, dir=dir, horg=horg)

	GAL	= REPLICATE(f_rdgal(n0, datalist, id0=1L, dir=dir, horg=horg), $
		N_ELEMENTS(tree.id))


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
		IF ~KEYWORD_SET(quick) THEN $
			GAL(i)	= f_rdgal(slist(i), datalist, id0=ilist(i), dir=dir, horg=horg)
	ENDFOR

	RETURN, GAL
END
