#INCLUDE 'TOTVS.CH'
#INCLUDE 'RESTFUL.CH'

WSRESTFUL matriculas DESCRIPTION 'Manipulação de matriculas'
	// Self:SetHeader('Access-Control-Allow-Credentials' , "true") - Saulo Maciel - 08/05/2023

	//Criação dos Metodos
	WSMETHOD GET DESCRIPTION 'Buscar matriculas pelo cpf' WSSYNTAX '/matriculas/' ;
		PATH '/matriculas/'

END WSRESTFUL

WSMETHOD GET WSSERVICE matriculas

	Local cResponse := JsonObject():New()
	Local lRet := .T.
	Local aDados := {}
	Local aParams := Self:AQueryString
	Local nPosId := aScan(aParams,{|x| x[1] == "CPF"})
	Local cCpf := ""
	Local cAlias := GetNextAlias()
	Local cError
	Local bError
	Local bErrorBlock
	Local oError
	Local aSM0 := {}
	bError := { |e| oError := e, BREAK(e) }
	bErrorBlock := ErrorBlock( bError )

	BEGIN SEQUENCE
		If nPosId > 0
			cCpf := aParams[nPosId,2]

			BEGINSQL ALIAS cAlias
            SELECT
                SRA.*
            FROM %Table:SRA% AS SRA
            WHERE
                SRA.%NotDel%
                AND SRA.RA_CIC = %exp:cCpf%
				ORDER BY SRA.RA_DEMISSA
			ENDSQL

			While !(cAlias)->(Eof())
				aSM0 := FWSM0Util():GetSM0Data( , (cAlias)->RA_FILIAL , {'M0_FILIAL'})
				Aadd(aDados, JsonObject():new())
				nPos := Len(aDados)
				aDados[nPos]['filial'] := (cAlias)->RA_FILIAL
				aDados[nPos]['nome' ] := (cAlias)->RA_NOME
				aDados[nPos]['matricula' ] := (cAlias)->RA_MAT
				aDados[nPos]['demissao' ] := (cAlias)->RA_DEMISSA
				aDados[nPos]['admissao' ] := (cAlias)->RA_ADMISSA
				aDados[nPos]['razao' ] := ALLTRIM(aSM0[1,2])
				cResponse['hasContent'] := .T.
				(cAlias)->(DbSkip())
			EndDo
			(cAlias)->(DbCloseArea())
		EndIf

		If Len(aDados) == 0		//SetRestFault(204, "Nenhum registro encontrado!")
			cResponse['code'] := 204
			cResponse['message'] := 'Nenhuma matricula encontrada'
			lRet := .F.
		Else
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
