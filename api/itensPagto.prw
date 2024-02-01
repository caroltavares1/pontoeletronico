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
	Local nTotalDes := nTotalPro := 0

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
				SRV.RV_TIPOCOD
            FROM
                %Table:SRD% as SRD
                INNER JOIN %Table:SRV% SRV ON SRV.RV_FILIAL = LEFT(SRD.RD_FILIAL, 2)
                AND SRV.RV_COD = SRD.RD_PD
            WHERE
                SRD.RD_FILIAL = %exp:aParams[nPosFilial,2]%
                AND SRD.RD_MAT = %exp:aParams[nPosMatr,2]%
                AND SRD.RD_DATARQ = %exp:aParams[nPosDtArq,2]%
                AND SRD.RD_ROTEIR = %exp:aParams[nPosRoteiro,2]%
				AND (SRV.RV_TIPOCOD = 1 OR SRV.RV_TIPOCOD = 2)
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
		cResponse['totalProventos'] := nTotalPro
		cResponse['totalDescontos'] := nTotalDes
		cResponse['liquidoReceber'] := nTotalPro - nTotalDes
		cResponse['itensPagto'] := aDados
	EndIf

	Self:SetContentType('application/json')
	Self:SetResponse(EncodeUTF8(cResponse:toJson()))
Return lRet
