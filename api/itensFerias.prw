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
	Local cError
	Local bError
	Local bErrorBlock
	Local oError

	bError := { |e| oError := e, BREAK(e) }
	bErrorBlock := ErrorBlock( bError )
    conout("Saulo1234: Antes do begin sequence")
	BEGIN SEQUENCE
		If nPosId > 0 .AND. nPosFil > 0 .AND. nPosData > 0
			BEGINSQL ALIAS cAlias
            SELECT
                SRR.*
            FROM %Table:SRR% AS SRR
            WHERE
                SRR.%NotDel%
                AND SRR.RR_FILIAL = %exp:aParams[nPosFil,2]%
                AND SRR.RR_MAT  = %exp:aParams[nPosId,2]%
                AND SRR.RR_DATA = %exp:aParams[nPosData,2]%
			ENDSQL

			While !(cAlias)->(Eof())
				Aadd(aDados, JsonObject():new())
				nPos := Len(aDados)
				aDados[nPos]['filial'] := (cAlias)->RR_FILIAL
				aDados[nPos]['matricula' ] := (cAlias)->RR_MAT
				aDados[nPos]['codVerba' ] := (cAlias)->RR_PD
				aDados[nPos]['descrVerba' ] := (cAlias)->RR_DESCPD
				aDados[nPos]['tipo' ] := (cAlias)->RR_TIPO1
				cResponse['hasContent'] := .T.
				(cAlias)->(DbSkip())
			EndDo
			(cAlias)->(DbCloseArea())
		EndIf

		If Len(aDados) == 0
			conout("Saulo1234: Encontrou dados")
			Self:SetRestFault(204, 'Nenhuma matricula encontrada')
			lRet := .F.
		Else
			conout("Saulo1234: Não encontrou dados")
			cResponse['matriculas'] := aDados
		EndIf

		Self:SetContentType('application/json')
		Self:SetResponse(EncodeUTF8(cResponse:toJson()))
		RECOVER
		cError := oError:Description
		Self:SetRestFault(500, cError)
		lRet := .F.
	END SEQUENCE
Return lRet
