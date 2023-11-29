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

	If nPosId > 0
		cCpf := aParams[nPosId,2]

		BEGINSQL ALIAS cAlias
            SELECT
                SRA.*
            FROM %Table:SRA% AS SRA
            WHERE
                SRA.%NotDel%
                AND SRA.RA_CIC = %exp:cCpf%
		ENDSQL

		While !(cAlias)->(Eof())
			Aadd(aDados, JsonObject():new())
			nPos := Len(aDados)
            aDados[nPos]['filial'] := (cAlias)->RA_FILIAL
            aDados[nPos]['nome' ] := (cAlias)->RA_NOME
            aDados[nPos]['matricula' ] := (cAlias)->RA_MAT
            aDados[nPos]['demissao' ] := (cAlias)->RA_DEMISSA
            aDados[nPos]['admissao' ] := (cAlias)->RA_ADMISSA
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
Return lRet
