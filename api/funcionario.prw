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
	//Local cId := aUrlParams[1]

	If nPosId > 0
		cCpf := aParams[nPosId,2]
	EndIf
	aDados := getArrFun(cvaltochar(cCpf))

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

Static Function getArrFun(cId)
	Local aArea := GetArea()
	Local aAreaSRA := SRA->(GetArea())
	Local aDados := {}
	Local nSRAreg := 0


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
		aDados[nPos]['funcao' ] := ALLTRIM(POSICIONE("SRJ", 1, xFilial("SRJ")+SRA->RA_CODFUNC, "RJ_DESC"))
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

Static Function GetFuncao(cFilFunc, cMatric)
	Local cFuncao := ''

	//ALLTRIM(POSICIONE("SRJ", 1, cFilFunc+SR7->R7_FUNCAO, "RJ_DESC"))
Return cFuncao
