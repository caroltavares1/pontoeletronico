#INCLUDE 'TOTVS.CH'
#INCLUDE 'RESTFUL.CH'

WSRESTFUL funcionarios DESCRIPTION 'Manipulação de funcionarios'
	// Self:SetHeader('Access-Control-Allow-Credentials' , "true") - Saulo Maciel - 08/05/2023

	//Criação dos Metodos
	WSMETHOD GET DESCRIPTION 'Buscar funcionario pela matricula' WSSYNTAX '/funcionarios/' ;
		PATH '/funcionarios/'

END WSRESTFUL

WSMETHOD GET WSSERVICE funcionarios
	Local cResponse := JsonObject():New()
	Local lRet := .T.
	Local aDados := {}
	//Local aUrlParams := Self:aUrlParms
	Local aParams := Self:AQueryString
	Local nPosId := aScan(aParams,{|x| x[1] == "CPF"})
	Local nPosAno := aScan(aParams,{|x| x[1] == "ANO"})
	Local nPosMes := aScan(aParams,{|x| x[1] == "MES"})
	Local cAno := ''
	Local cMes := ''

	If nPosId > 0
		cCpf := aParams[nPosId,2]
	Else
		SetRestFault(400, "Verifique se todos os parametros obrigatorios foram enviados!")
		lRet := .F.
		Return lRet
	EndIf

	If nPosAno > 0 .AND. nPosMes > 0
		cAno := aParams[nPosAno,2]
		cMes := aParams[nPosMes,2]
		aDados := getArrFun(cvaltochar(cCpf), cAno, cMes)
	Else
		aDados := getArrFun(cvaltochar(cCpf))
	EndIf


	If Len(aDados) == 0		//SetRestFault(204, "Nenhum registro encontrado!")
		cResponse['code'] := 204
		cResponse['message'] := 'Funcionário não encontrado'
		lRet := .F.
	Else
		//cResponse:set(aDados)
		cResponse['user'] := aDados
	EndIf

	Self:SetContentType('application/json')
	Self:SetResponse(EncodeUTF8(cResponse:toJson()))
Return lRet

Static Function getArrFun(cId, cAno, cMes)
	Local aArea := GetArea()
	Local aAreaSRA := SRA->(GetArea())
	Local aDados := {}
	Local nSRAreg := 0

	Default cAno := '0000'
	Default cMes := '00''

	BEGINSQL ALIAS 'TSRA'
		SELECT
			SRA.R_E_C_N_O_
		FROM %Table:SRA% AS SRA
		WHERE
			SRA.%NotDel% AND
			SRA.RA_CIC = %exp:cId% AND
			SRA.RA_SITFOLH IN (' ', 'F')
	ENDSQL

	If !TSRA->(Eof())
		nSRAreg := TSRA->R_E_C_N_O_
	EndIf
	TSRA->(DbCloseArea())

	SRA->(DbGoto(nSRAreg))
	While !SRA->(Eof()) .AND. SRA->RA_CIC == cId
		Aadd(aDados, JsonObject():new())
		nPos := Len(aDados)
		aDados[nPos]['matricula' ] := AllTrim(SRA->RA_MAT)
		aDados[nPos]['nome' ] := AllTrim(SRA->RA_NOME)
		aDados[nPos]['admissao' ] := (SRA->RA_ADMISSA)

		If cAno == '0000' .AND. cMes == '00'
			aDados[nPos]['funcao' ] := ALLTRIM(POSICIONE("SRJ", 1, xFilial("SRJ")+SRA->RA_CODFUNC, "RJ_DESC"))
		Else
			aDados[nPos]['funcao' ] := GetFuncao(SRA->RA_FILIAL, AllTrim(SRA->RA_MAT), cAno, cMes)
		EndIf

		aDados[nPos]['cc' ] := AllTrim(SRA->RA_CC)
		aDados[nPos]['rg' ] := AllTrim(SRA->RA_RG)
		aDados[nPos]['cpf' ] := AllTrim(SRA->RA_CIC )
		aDados[nPos]['numCp' ] := AllTrim(SRA->RA_NUMCP )
		aDados[nPos]['serieCp' ] := AllTrim(SRA->RA_SERCP )
		aDados[nPos]['ufCp' ] := AllTrim(SRA->RA_UFCP )
		aDados[nPos]['categoria' ] := AllTrim(SRA->RA_CATFUNC )
		aDados[nPos]['depIR' ] := AllTrim(SRA->RA_DEPIR )
		aDados[nPos]['depSF' ] := AllTrim(SRA->RA_DEPSF )
		aDados[nPos]['bancoAgencia' ] := AllTrim(SRA->RA_BCDEPSA )
		aDados[nPos]['conta' ] := AllTrim(SRA->RA_CTDEPSA )
		aDados[nPos]['endereco' ] := AllTrim(SRA->RA_ENDEREC ) +" "+AllTrim(SRA->RA_LOGRNUM)
		aDados[nPos]['bairro' ] := AllTrim(SRA->RA_BAIRRO )
		aDados[nPos]['municipio' ] := AllTrim(SRA->RA_MUNICIP )
		aDados[nPos]['estado' ] := AllTrim(SRA->RA_ESTADO )
		aDados[nPos]['cep' ] := AllTrim(SRA->RA_CEP )
		aDados[nPos]['pis' ] := AllTrim(SRA->RA_PIS )

		if (AllTrim(SRA->RA_SITFOLH ) == '')
			aDados[nPos]['situacao' ] := 'NORMAL'
		elseif AllTrim(SRA->RA_SITFOLH ) == 'F'
			aDados[nPos]['situacao' ] := 'FÉRIAS'
		end if
		aDados[nPos]['departamento' ] := ALLTRIM(POSICIONE("SQB", 1, xFilial("SQB")+SRA->RA_DEPTO, "QB_DESCRIC"))

		SRA->(DbSkip())
	EndDo

	RestArea(aArea)
	SRA->(RestArea(aAreaSRA))
Return aDados

Static Function GetFuncao(cFilFunc, cMatric, cAno, cMes)
	Local cFuncao := ''
	Local cAliasSR7 := GetNextAlias()
	Local cDataOri := cAno+cMes+"01"
	Local dLastData := LastDate(STOD(cDataOri))
	Local nDia := Last_Day(dLastData)
	Local nAno := YEAR(dLastData)
	Local nMes := MONTH(dLastData)

	BEGINSQL ALIAS cAliasSR7
		%noparser%
		SELECT TOP 1
			T.R7_FILIAL,
			T.R7_FUNCAO,
			T.R7_DESCFUN FUNCAO,
			T.R7_DATA DT_FUNC
		FROM
			(
				SELECT
					SR7.R7_FILIAL,
					SR7.R7_FUNCAO,
					SR7.R7_DESCFUN,
					SR7.R7_DATA,
					0 AS PrioridadeTipoBusca,
					CASE
						WHEN DATEPART(MONTH, SR7.R7_DATA) = %exp:nMes% AND DATEPART(YEAR, SR7.R7_DATA) = %exp:nAno% THEN 0
						ELSE 1
					END AS PrioridadeMesAno,
					SR7.R7_DATA AS DataOrdenacaoPrimaria,
					NULL AS DataOrdenacaoSecundaria
				FROM
					%Table:SR7% SR7
				WHERE
					SR7.R7_FILIAL = %exp:cFilFunc%
					AND SR7.R7_MAT = %exp:cMatric%
					AND SR7.R7_DATA <= DATEFROMPARTS(%exp:nAno%, %exp:nMes%, %exp:nDia%)
					AND SR7.%NotDel%

				UNION ALL

				SELECT
					SR7_OLD.R7_FILIAL,
					SR7_OLD.R7_FUNCAO,
					SR7_OLD.R7_DESCFUN,
					SR7_OLD.R7_DATA,
					1 AS PrioridadeTipoBusca,
					99 AS PrioridadeMesAno,
					NULL AS DataOrdenacaoPrimaria,
					SR7_OLD.R7_DATA AS DataOrdenacaoSecundaria
				FROM
					%Table:SR7% SR7_OLD
				WHERE
					SR7_OLD.R7_FILIAL = %exp:cFilFunc%
					AND SR7_OLD.R7_MAT = %exp:cMatric%
					AND SR7_OLD.%NotDel%
			) T
		ORDER BY
			T.PrioridadeTipoBusca ASC,
			T.PrioridadeMesAno ASC,
			CASE WHEN T.PrioridadeTipoBusca = 0 THEN T.DataOrdenacaoPrimaria END DESC,
			CASE WHEN T.PrioridadeTipoBusca = 1 THEN T.DataOrdenacaoSecundaria END ASC
	ENDSQL



	// conout('Query de consulta de funcao')
	// conout(GetLastquery()[2])

	If !(cAliasSR7)->(Eof())
		cFuncao := (cAliasSR7)->FUNCAO
	EndIf

	(cAliasSR7)->(DbCloseArea())

Return cFuncao
