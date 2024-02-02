#INCLUDE 'TOTVS.CH'
#INCLUDE 'RESTFUL.CH'

WSRESTFUL detalhesPagto DESCRIPTION 'Consulta de Itens de pagto'
	// Self:SetHeader('Access-Control-Allow-Credentials' , "true") - Saulo Maciel - 08/05/2023

	//Criação dos Metodos
	WSMETHOD GET DESCRIPTION 'Busca os registros de pagto por filial e matricula' WSSYNTAX '/detalhesPagto/' ;
		PATH '/detalhesPagto/'

END WSRESTFUL

WSMETHOD GET WSSERVICE detalhesPagto

	Local cResponse := JsonObject():New()
	Local lRet := .T.
	Local cAlias := GetNextAlias()
	Local aDados := {}
	Local aParams := Self:AQueryString
	Local nPosFilial := aScan(aParams,{|x| x[1] == "FILIAL"})
	Local nPosMatr := aScan(aParams,{|x| x[1] == "MATRICULA"})
	Local nPosDtArq := aScan(aParams,{|x| x[1] == "DATAARQ"})
	Local nPosRoteiro := aScan(aParams,{|x| x[1] == "ROTEIRO"})
	Local nTotalDes := 0
	Local nTotalPro := 0
	Local nValFgts := 0
	Local nTotalPensao := 0
	Local nBaseFgts := 0
	Local nBaseIrrf := 0
	Local nContrInss := 0
	Local cVrbPensao := ""

	If nPosFilial > 0 .AND. nPosMatr > 0  .AND. nPosDtArq > 0 .AND. nPosRoteiro > 0
		BEGINSQL ALIAS cAlias
            SELECT
                SRD.RD_FILIAL,
                SRD.RD_MAT,
                SRD.RD_DATARQ,
                SRD.RD_ROTEIR,
                SRD.RD_VALOR,
                SRD.RD_PD,
				SRD.RD_HORAS,
				SRD.RD_DATPGT,
				SRD.RD_VALORBA,
                SRV.RV_DESC,
				SRV.RV_TIPOCOD,
				SRV.RV_CODFOL
            FROM
                %Table:SRD% as SRD
                INNER JOIN %Table:SRV% SRV ON SRV.RV_FILIAL = LEFT(SRD.RD_FILIAL, 2)
                AND SRV.RV_COD = SRD.RD_PD
            WHERE
                SRD.RD_FILIAL = %exp:aParams[nPosFilial,2]%
                AND SRD.RD_MAT = %exp:aParams[nPosMatr,2]%
                AND SRD.RD_DATARQ = %exp:aParams[nPosDtArq,2]%
                AND SRD.RD_ROTEIR = %exp:aParams[nPosRoteiro,2]%
		ENDSQL

		// cResponse['query'] := GetLastQuery()[2]

		While !(cAlias)->(Eof())
			Aadd(aDados, JsonObject():new())
			nPos := Len(aDados)
			aDados[nPos]['filial'] := (cAlias)->RD_FILIAL
			aDados[nPos]['matricula' ] := (cAlias)->RD_MAT
			aDados[nPos]['dataArquivo' ] := (cAlias)->RD_DATARQ
			aDados[nPos]['roteiro' ] := (cAlias)->RD_ROTEIR
			aDados[nPos]['provento' ] := (cAlias)->RD_VALOR
			aDados[nPos]['referencia' ] := (cAlias)->RD_HORAS
			aDados[nPos]['codVerba' ] := (cAlias)->RD_PD
			aDados[nPos]['descVerba' ] := ALLTRIM((cAlias)->RV_DESC)
			aDados[nPos]['tipoVerba' ] := (cAlias)->RV_TIPOCOD


			If (cAlias)->RV_TIPOCOD == "1"
				nTotalPro += (cAlias)->RD_VALOR
			ElseIf (cAlias)->RV_TIPOCOD == "2"
				nTotalDes += (cAlias)->RD_VALOR
			EndIf

			If (cAlias)->RV_CODFOL == "0017"
				nBaseFgts += (cAlias)->RD_VALOR
			ElseIf (cAlias)->RV_CODFOL == "0018"
				nValFgts += (cAlias)->RD_VALOR
			ElseIf (cAlias)->RV_CODFOL == "0015"
				nBaseIrrf += (cAlias)->RD_VALOR
			ElseIf (cAlias)->RV_CODFOL == "0013"
				nContrInss += (cAlias)->RD_VALOR
			EndIf

			cVrbPensao := GetVrbPensao(aParams[nPosFilial,2], aParams[nPosMatr,2])
			If (cAlias)->RD_PD $ cVrbPensao
				nTotalPensao += (cAlias)->RD_VALOR
			EndIf

			cResponse['salario'] := (cAlias)->RD_VALORBA
			cResponse['dtPagto'] := (cAlias)->RD_DATPGT
			cResponse['hasContent'] := .T.

			(cAlias)->(DbSkip())
		EndDo
		(cAlias)->(DbCloseArea())
	EndIf

	If Len(aDados) == 0
		cResponse['code'] := 204
		cResponse['message'] := 'Nenhum registro de ferias encontrado'
		lRet := .F.
	Else
		cResponse['baseFgts'] := nBaseFgts
		cResponse['valorFgts'] := nValFgts
		cResponse['baseIrrf'] := nBaseIrrf
		cResponse['contribInss'] := nContrInss
		cResponse['totalProventos'] := nTotalPro
		cResponse['totalDescontos'] := nTotalDes
		cResponse['totalPensao'] := nTotalPensao
		cResponse['liquidoReceber'] := nTotalPro - nTotalDes
		cResponse['itensPagto'] := aDados
	EndIf

	Self:SetContentType('application/json')
	Self:SetResponse(EncodeUTF8(cResponse:toJson()))
Return lRet


Static Function GetVrbPensao(cFilFunc, cMatricula)
	Local cVrbPensao := ""
	Local cAlias := GetNextAlias()

	BEGINSQL ALIAS cAlias
        SELECT
            SRQ.RQ_VERBADT,
            SRQ.RQ_VERBFOL,
            SRQ.RQ_VERBFER,
            SRQ.RQ_VERB131,
            SRQ.RQ_VERB132,
            SRQ.RQ_VERBPLR
        FROM
            %Table:SRQ% AS SRQ
        WHERE
            SRQ.%NotDel%
            AND SRQ.RQ_FILIAL = %exp:cFilFunc%
            AND SRQ.RQ_MAT = %exp:cMatricula%
            AND SRQ.RQ_CIC != ''
	ENDSQL

	While !(cAlias)->(Eof())
		If !Empty((cAlias)->RQ_VERBADT)
			cVrbPensao += (cAlias)->RQ_VERBADT + ";"
		EndIf

		If !Empty((cAlias)->RQ_VERBFOL)
			cVrbPensao += (cAlias)->RQ_VERBFOL + ";"
		EndIf

		If !Empty((cAlias)->RQ_VERBFER)
			cVrbPensao += (cAlias)->RQ_VERBFER + ";"
		EndIf

		If !Empty((cAlias)->RQ_VERB131)
			cVrbPensao += (cAlias)->RQ_VERB131 + ";"
		EndIf

		If !Empty((cAlias)->RQ_VERB132)
			cVrbPensao += (cAlias)->RQ_VERB132 + ";"
		EndIf

		If !Empty((cAlias)->RQ_VERBPLR)
			cVrbPensao += (cAlias)->RQ_VERBPLR + ";"
		EndIf
		(cAlias)->(DbSkip())
	EndDo
	(cAlias)->(DbCloseArea())

	cVrbPensao := LEFT(cVrbPensao, Len(cVrbPensao)-1)

Return cVrbPensao
