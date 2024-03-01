#INCLUDE 'TOTVS.CH'
#INCLUDE 'RESTFUL.CH'

WSRESTFUL detalhesFerias DESCRIPTION 'Consulta de Itens de Ferias'
	// Self:SetHeader('Access-Control-Allow-Credentials' , "true") - Saulo Maciel - 08/05/2023

	//Criação dos Metodos
	WSMETHOD GET DESCRIPTION 'Busca os registros de ferias por filial e matricula' WSSYNTAX '/detalhesFerias/' ;
		PATH '/detalhesFerias/'

END WSRESTFUL

WSMETHOD GET WSSERVICE detalhesFerias

	Local cResponse := JsonObject():New()
	Local lRet := .T.
	Local aDados := {}
	Local aParams := Self:AQueryString
	Local nPosFil := aScan(aParams,{|x| x[1] == "FILIAL"})
	Local nPosId := aScan(aParams,{|x| x[1] == "MATRICULA"})
	Local nPosData := aScan(aParams,{|x| x[1] == "DATA"})
	Local cAlias := GetNextAlias()
	Local nTotalPro := 0
	Local nTotalDes := 0
	Local cLiqExt := ""

	If nPosId > 0 .AND. nPosFil > 0 .AND. nPosData > 0
		BEGINSQL ALIAS cAlias
            SELECT DISTINCT
                SRR.RR_FILIAL, SRR.RR_MAT, SRR.RR_HORAS, SRR.RR_PD, SRR.RR_TIPO1, 
				SRR.RR_VALOR, SRV.RV_DESC, SRV.RV_TIPOCOD, SRR.RR_VALORBA, SRR.RR_DATAPAG
            FROM %Table:SRR% AS SRR
			INNER JOIN %Table:SRV% AS SRV
			ON LEFT(SRV.RV_FILIAL, 2) = LEFT(SRR.RR_FILIAL, 2) AND SRV.RV_COD = SRR.RR_PD
            WHERE
                SRR.%NotDel%
                AND SRR.RR_FILIAL = %exp:aParams[nPosFil,2]%
                AND SRR.RR_MAT  = %exp:aParams[nPosId,2]%
                AND SRR.RR_DATA = %exp:aParams[nPosData,2]%
				AND (SRV.RV_TIPOCOD = 1 OR SRV.RV_TIPOCOD = 2)
				AND SRV.RV_CODFOL != '0102'
		ENDSQL

		While !(cAlias)->(Eof())
			Aadd(aDados, JsonObject():new())
			nPos := Len(aDados)
			aDados[nPos]['filial'] := (cAlias)->RR_FILIAL
			aDados[nPos]['matricula' ] := (cAlias)->RR_MAT
			aDados[nPos]['codVerba' ] := (cAlias)->RR_PD
			aDados[nPos]['descVerba' ] := (cAlias)->RV_DESC
			aDados[nPos]['tipoVerba' ] := (cAlias)->RV_TIPOCOD
			aDados[nPos]['provento' ] := (cAlias)->RR_VALOR
			aDados[nPos]['tipo' ] := (cAlias)->RR_TIPO1
			aDados[nPos]['referencia' ] := (cAlias)->RR_HORAS
			If (cAlias)->RV_TIPOCOD == "1"
				nTotalPro += (cAlias)->RR_VALOR
			ElseIf (cAlias)->RV_TIPOCOD == "2"
				nTotalDes += (cAlias)->RR_VALOR
			EndIf
			cResponse['salario'] := (cAlias)->RR_VALORBA
			cResponse['dtPagto'] := (cAlias)->RR_DATAPAG
			cResponse['hasContent'] := .T.
			cResponse['totalProventos'] := nTotalPro
			cResponse['totalDescontos'] := nTotalDes
			cResponse['liquidoReceber'] := nTotalPro - nTotalDes
			cLiqExt := Upper(Alltrim(Extenso(nTotalPro - nTotalDes,.F.,1,,"1",.T.,.F.)))
			cResponse['receberExtenso'] := cLiqExt

			(cAlias)->(DbSkip())
		EndDo
		(cAlias)->(DbCloseArea())
	EndIf

	If Len(aDados) == 0
		Self:SetRestFault(204, 'Nenhuma matricula encontrada')
		lRet := .F.
	Else
		cResponse['matriculas'] := aDados
	EndIf

	Self:SetContentType('application/json')
	Self:SetResponse(EncodeUTF8(cResponse:toJson()))
Return lRet
