FUNCTION f_rdheader, file

	settings	= {header:'VR_header_structure'}

	OPENR, 10, file
	FOR i=0L, FILE_LINES(file)-1L DO BEGIN
		v1	= STRING(' ')
		READF, 10, v1
		v1	= STRTRIM(v1,2)

		IF STRLEN(v1) EQ 0L THEN CONTINUE
		in	= STRPOS(v1, '#')
		IF MAX(in) GE 0L THEN CONTINUE

		void	= EXECUTE(v1)

		tag_name= STRSPLIT(v1, '=', /extract)
		tag_name= tag_name(0)
		v2 	= 'settings = CREATE_STRUCT(settings, "' + STRTRIM(tag_name,2) + '", ' + $
			STRTRIM(tag_name,2) + ')'
		void	= EXECUTE(v2)
	ENDFOR
	CLOSE, 10

	RETURN, settings
END
