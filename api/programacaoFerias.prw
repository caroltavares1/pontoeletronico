#INCLUDE 'TOTVS.CH'
#INCLUDE 'RESTFUL.CH'

WSRESTFUL programacaoFerias DESCRIPTION 'Manipulação de programacaoFerias'
	// Self:SetHeader('Access-Control-Allow-Credentials' , "true") - Saulo Maciel - 08/05/2023

	//Criação dos Metodos
	WSMETHOD GET DESCRIPTION 'Buscar programacaoFerias pelo cpf' WSSYNTAX '/programacaoFerias/' ;
		PATH '/programacaoFerias/'

END WSRESTFUL

WSMETHOD GET WSSERVICE programacaoFerias

	Local cResponse := JsonObject():New()
	Local lRet := .T.
	Local aDados := {}
	Local aParams := Self:AQueryString
	Local nPosFil := aScan(aParams,{|x| x[1] == "FILIAL"})
	Local nPosId := aScan(aParams,{|x| x[1] == "MATRICULA"})
	Local cAlias := GetNextAlias()

	If nPosId > 0 .AND. nPosFil > 0
		BEGINSQL ALIAS cAlias
            SELECT
                SRH.*
            FROM %Table:SRH% AS SRH
            WHERE
                SRH.%NotDel%
                AND SRH.RH_FILIAL = %exp:aParams[nPosFil,2]%
				AND SRH.RH_MAT = %exp:aParams[nPosId,2]%
		ENDSQL

		While !(cAlias)->(Eof())
			Aadd(aDados, JsonObject():new())
			nPos := Len(aDados)
			aDados[nPos]['filial'] := (cAlias)->RH_FILIAL
			aDados[nPos]['matricula' ] := (cAlias)->RH_MAT
			aDados[nPos]['iniPerAq' ] := (cAlias)->RH_DATABAS
			aDados[nPos]['fimPerAq' ] := (cAlias)->RH_DBASEAT
			aDados[nPos]['iniFerias' ] := (cAlias)->RH_DATAINI
			aDados[nPos]['fimFerias' ] := (cAlias)->RH_DATAFIM
			cResponse['hasContent'] := .T.
			(cAlias)->(DbSkip())
		EndDo
		(cAlias)->(DbCloseArea())
	Else
		cResponse['code'] := 400
		cResponse['message'] := 'Algum parametro obrigatorio, nao foi informado'
		lRet := .F.
	EndIf

	If Len(aDados) == 0		//SetRestFault(204, "Nenhum registro encontrado!")
		cResponse['code'] := 204
		cResponse['message'] := 'Nenhum registro de ferias encontrado'
		lRet := .F.
	Else
		cResponse['programacaoFerias'] := aDados
	EndIf

	Self:SetContentType('application/json')
	Self:SetResponse(EncodeUTF8(cResponse:toJson()))
Return lRet
