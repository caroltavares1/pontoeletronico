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
            SELECT DISTINCT
                SRD.RD_FILIAL FILIAL,
                SRD.RD_MAT MATRICULA,
                SRD.RD_DATARQ DATAARQ,
                SRD.RD_ROTEIR ROTEIRO,
                SRD.RD_VALOR VALOR,
                SRD.RD_PD PD,
				SRD.RD_HORAS HORAS,
				SRD.RD_DATPGT DATA_PAGTO,
				SRD.RD_VALORBA VALOR_BASE,
                SRV.RV_DESC DESCRICAO,
				SRV.RV_TIPOCOD TIPO,
				SRV.RV_CODFOL CODFOL
            FROM
                %Table:SRD% as SRD
                INNER JOIN %Table:SRV% SRV ON SRV.RV_FILIAL = LEFT(SRD.RD_FILIAL, 2)
                AND SRV.RV_COD = SRD.RD_PD
            WHERE
                SRD.RD_FILIAL = %exp:aParams[nPosFilial,2]%
                AND SRD.RD_MAT = %exp:aParams[nPosMatr,2]%
                AND SRD.RD_DATARQ = %exp:aParams[nPosDtArq,2]%
                AND SRD.RD_ROTEIR = %exp:aParams[nPosRoteiro,2]%
			UNION
			SELECT DISTINCT
                SRC.RC_FILIAL FILIAL,
                SRC.RC_MAT MATRICULA,
                SRC.RC_PERIODO DATAARQ,
                SRC.RC_ROTEIR ROTEIRO,
                SRC.RC_VALOR VALOR,
                SRC.RC_PD PD,
				SRC.RC_HORAS HORAS,
				SRC.RC_DTREF DATA_PAGTO,
				SRC.RC_VALORBA VALOR_BASE,
                SRV.RV_DESC DESCRICAO,
				SRV.RV_TIPOCOD TIPO,
				SRV.RV_CODFOL CODFOL
            FROM
                %Table:SRC% as SRC
                INNER JOIN %Table:SRV% SRV ON SRV.RV_FILIAL = LEFT(SRC.RC_FILIAL, 2)
                AND SRV.RV_COD = SRC.RC_PD
            WHERE
                SRC.RC_FILIAL = %exp:aParams[nPosFilial,2]%
                AND SRC.RC_MAT = %exp:aParams[nPosMatr,2]%
                AND SRC.RC_PERIODO = %exp:aParams[nPosDtArq,2]%
                AND SRC.RC_ROTEIR = %exp:aParams[nPosRoteiro,2]%
		ENDSQL

		// cResponse['query'] := GetLastQuery()[2]

		While !(cAlias)->(Eof())
			Aadd(aDados, JsonObject():new())
			nPos := Len(aDados)
			aDados[nPos]['filial'] := (cAlias)->FILIAL
			aDados[nPos]['matricula' ] := (cAlias)->MATRICULA
			aDados[nPos]['dataArquivo' ] := (cAlias)->DATAARQ
			aDados[nPos]['roteiro' ] := (cAlias)->ROTEIRO
			aDados[nPos]['provento' ] := (cAlias)->VALOR
			aDados[nPos]['referencia' ] := (cAlias)->HORAS
			aDados[nPos]['codVerba' ] := (cAlias)->PD
			aDados[nPos]['descVerba' ] := ALLTRIM((cAlias)->DESCRICAO)
			aDados[nPos]['tipoVerba' ] := (cAlias)->TIPO


			If (cAlias)->TIPO == "1"
				nTotalPro += (cAlias)->VALOR
			ElseIf (cAlias)->TIPO == "2"
				nTotalDes += (cAlias)->VALOR
			EndIf

			If (cAlias)->CODFOL == "0017"
				nBaseFgts += (cAlias)->VALOR
			ElseIf (cAlias)->CODFOL == "0018"
				nValFgts += (cAlias)->VALOR
			ElseIf (cAlias)->CODFOL == "0015"
				nBaseIrrf += (cAlias)->VALOR
			ElseIf (cAlias)->CODFOL == "0013"
				nContrInss += (cAlias)->VALOR
			EndIf

			cVrbPensao := GetVrbPensao(aParams[nPosFilial,2], aParams[nPosMatr,2])
			If (cAlias)->PD $ cVrbPensao
				nTotalPensao += (cAlias)->VALOR
			EndIf

			cResponse['salario'] := (cAlias)->VALOR_BASE
			cResponse['dtPagto'] := (cAlias)->DATA_PAGTO
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
