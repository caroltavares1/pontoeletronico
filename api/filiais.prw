#INCLUDE 'TOTVS.CH'
#INCLUDE 'RESTFUL.CH'

WSRESTFUL filiais DESCRIPTION 'Manipulacao de Clientes'
	// Self:SetHeader('Access-Control-Allow-Credentials' , "true") - Saulo Maciel - 08/05/2023

	//Criação dos Metodos
	WSMETHOD GET DESCRIPTION 'Pegar dados de uma filial' WSSYNTAX '/filiais' PATH '/'

END WSRESTFUL

WSMETHOD GET WSSERVICE filiais
	//http://192.168.41.60:8090/rest/filiais/?filial=0301

	Local cResponse := JsonObject():New()
	Local lRet := .T.
	Local aDados := {}
	Local aParams := Self:AQueryString
	Local cFilFunc := ""
	Local nPosId := aScan(aParams,{|x| x[1] == "FILIAL"})
	Local aCampos := {"M0_CODFIL","M0_FILIAL", "M0_CGC", "M0_ENDENT"}
	Local aDadosFilial := {}

	If nPosId > 0
		cFilFunc := aParams[nPosId,2]
		aDadosFilial := FWSM0Util():GetSM0Data( cEmpAnt , cFilFunc , aCampos)

		If Len(aDadosFilial) > 0
			Aadd(aDados, JsonObject():new())
			nPos := Len(aDados)
			cResponse['filial' ] := ALLTRIM(aDadosFilial[1][2])
			cResponse['nome' ] := ALLTRIM(aDadosFilial[2][2])
			cResponse['cgc' ] := ALLTRIM(aDadosFilial[3][2])
			cResponse['endereco' ] := ALLTRIM(aDadosFilial[4][2])
			cResponse['hasContent'] := .T.
		EndIf
	EndIf

	If nPosId == 0
		cResponse['erro'] := 204
		cResponse['message'] := "Filial não encontrada"
		lRet := .F.
	EndIf

	Self:SetContentType('application/json')
	Self:SetResponse(EncodeUTF8(cResponse:toJson()))
Return lRet
