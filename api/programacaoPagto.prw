#INCLUDE 'TOTVS.CH'
#INCLUDE 'RESTFUL.CH'

WSRESTFUL folhaPagto DESCRIPTION 'Consulta de Pagamentos de Folha'
	// Self:SetHeader('Access-Control-Allow-Credentials' , "true") - Saulo Maciel - 08/05/2023

	//Criação dos Metodos
	WSMETHOD GET DESCRIPTION 'Buscar folha pelo cpf' WSSYNTAX '/folhaPagto/' ;
		PATH '/folhaPagto/'

END WSRESTFUL

WSMETHOD GET WSSERVICE folhaPagto

	Local cResponse := JsonObject():New()
	Local lRet := .T.
	Local aDados := {}
	Local aParams := Self:AQueryString
	Local nPosId := aScan(aParams,{|x| x[1] == "CPF"})
	Local cAlias := GetNextAlias()

	If nPosId > 0
		BEGINSQL ALIAS cAlias
			SELECT
				LEFT(SRD.RD_FILIAL, 2) EMPRESA,
				SRD.RD_FILIAL FILIAL,
				SRD.RD_MAT MATRICULA,
				LEFT(SRD.RD_PERIODO, 4) ANO,
				RIGHT(SRD.RD_PERIODO, 2) MES,
				SRD.RD_SEMANA SEMANA,
				SRD.RD_ROTEIR ROTEIRO
			FROM
				%Table:SRD% SRD
				INNER JOIN %Table:SRA% SRA ON SRA.RA_MAT = SRD.RD_MAT
				AND SRA.RA_FILIAL = SRD.RD_FILIAL
			WHERE
				SRD.D_E_L_E_T_ = ''
				AND SRA.D_E_L_E_T_ = ''
				AND SRA.RA_CIC = %exp:aParams[nPosId,2]%
			GROUP BY
				LEFT(SRD.RD_FILIAL, 2),
				SRD.RD_FILIAL,
				SRD.RD_MAT,
				LEFT(SRD.RD_PERIODO, 4),
				RIGHT(SRD.RD_PERIODO, 2),
				SRD.RD_SEMANA,
				SRD.RD_ROTEIR,
				SRA.RA_DEMISSA
			ORDER BY
				LEFT(SRD.RD_PERIODO, 4) DESC,
				RIGHT(SRD.RD_PERIODO, 2) DESC
		ENDSQL

		While !(cAlias)->(Eof())
			Aadd(aDados, JsonObject():new())
			nPos := Len(aDados)
			aDados[nPos]['empresa' ] := (cAlias)->EMPRESA
			aDados[nPos]['filial'] := (cAlias)->FILIAL
			aDados[nPos]['matricula' ] := (cAlias)->MATRICULA
			aDados[nPos]['ano' ] := (cAlias)->ANO
			aDados[nPos]['mes' ] := (cAlias)->MES
			aDados[nPos]['semana' ] := (cAlias)->SEMANA
			aDados[nPos]['roteiro' ] := GetDescri((cAlias)->ROTEIRO)
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
		cResponse['folhaPagto'] := aDados
	EndIf

	Self:SetContentType('application/json')
	Self:SetResponse(EncodeUTF8(cResponse:toJson()))
Return lRet

Static Function GetDescri(cCod)
	Local cDescricao := ""

	If cCod == 'FOL'
		cDescricao := '2 - (FOLHA)'
	ElseIf cCod == 'ADI'
		cDescricao := '1 - (ADIANTAMENTO)'
	ElseIf cCod == '131'
		cDescricao := '3 - (1ª PARCELA 13°)'
	ElseIf cCod == '132'
		cDescricao := '4 - (2ª PARCELA 13°)'
	EndIf
Return cDescricao
