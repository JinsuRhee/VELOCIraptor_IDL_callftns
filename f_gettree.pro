FUNCTION f_gettree, snap, id0, tree, tree_key

	keyval	= snap + tree_key(0)*id0
	ind 	= tree_key(keyval)
	IF ind EQ -1L THEN RETURN, -1L
	RETURN, tree(ind)

	;ntree	= N_ELEMENTS(tree)
	;FOR i=0L, ntree-1L DO BEGIN
	;	tmp	= *tree(i)
	;	IF TYPENAME(tmp) EQ 'UNDEFINED' THEN CONTINUE

	;	cut	= WHERE(tmp.snap EQ snap, ncut)
	;	IF ncut EQ 0L THEN CONTINUE

	;	IF tmp.id(cut) EQ id0 THEN RETURN, tmp
	;ENDFOR
END
