FUNCTION f_gettree, id0, snap, tree

	ntree	= N_ELEMENTS(tree)
	FOR i=0L, ntree-1L DO BEGIN
		tmp	= *tree(i)
		IF TYPENAME(tmp) EQ 'UNDEFINED' THEN CONTINUE

		cut	= WHERE(tmp.snap EQ snap, ncut)
		IF ncut EQ 0L THEN CONTINUE

		IF tmp.id(cut) EQ id0 THEN RETURN, tmp
	ENDFOR
END
