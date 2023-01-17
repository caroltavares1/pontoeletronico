#INCLUDE 'TOTVS.CH'
#INCLUDE 'RESTFUL.CH'

WSRESTFUL turnos DESCRIPTION 'Manipula��o de turnos'
	Self:SetHeader('Access-Control-Allow-Credentials' , "true")

	//Cria��o dos Metodos
	WSMETHOD GET DESCRIPTION 'Buscar turnos pelo funcionario' WSSYNTAX '/turnos/' ;
		PATH '/turnos/'

END WSRESTFUL

WSMETHOD GET WSSERVICE turnos
	// http://localhost:8090/rest/turnos/?TURNO=001&SEQ=01
	// http://192.168.41.60:8090/rest/turnos/?TURNO=001&SEQ=01
	Local cResponse := JsonObject():New()
	Local lRet := .T.
	Local aDados := {}
	Local aParams := Self:AQueryString
	Local nPosTurno := aScan(aParams,{|x| x[1] == "TURNO"})
	Local nPosSqTurno := aScan(aParams,{|x| x[1] == "SEQ"})
	Local nPosFil := aScan(aParams,{|x| x[1] == "FILIAL"})
	Local cTurno := cSqTurno := cFilFunc := ""

	If nPosTurno > 0 .AND. nPosSqTurno > 0 .AND. nPosFil > 0
		cTurno := aParams[nPosTurno,2]
		cSqTurno := aParams[nPosSqTurno,2]
		cFilFunc := aParams[nPosFil,2]
	EndIf

	BEGINSQL ALIAS 'TSPJ'
    SELECT
      SPJ.*
    FROM %Table:SPJ% AS SPJ
    WHERE
      SPJ.%NotDel%
      AND SPJ.PJ_FILIAL = %exp:LEFT(cFilFunc,2)%
      AND SPJ.PJ_TURNO = %exp:cTurno%
      AND SPJ.PJ_SEMANA = %exp:cSqTurno%
	ENDSQL

	While !TSPJ->(Eof())
		Aadd(aDados, JsonObject():new())
		nPos := Len(aDados)
		aDados[nPos]['dia' ] := DiaExtenso(TSPJ->PJ_DIA)
		aDados[nPos]['1E'] := ConvertHora(TSPJ->PJ_ENTRA1)
		aDados[nPos]['1S'] := ConvertHora(TSPJ->PJ_SAIDA1)
		aDados[nPos]['2E'] := ConvertHora(TSPJ->PJ_ENTRA2)
		aDados[nPos]['2S'] := ConvertHora(TSPJ->PJ_SAIDA2)
		aDados[nPos]['turno'] := ALLTRIM(TSPJ->PJ_TURNO) + " - " + aDados[nPos]['1E'] + " " +aDados[nPos]['1S'] + " / " +;
		aDados[nPos]['2E'] + " " + aDados[nPos]['2S']
		TSPJ->(DbSkip())
	EndDo
	TSPJ->(DbCloseArea())

	If Len(aDados) == 0		//SetRestFault(204, "Nenhum registro encontrado!")
		cResponse['code'] := 204
		cResponse['message'] := 'Horario Padrao n�o encontrado'
		lRet := .F.
	Else
		cResponse['horarios'] := aDados
	EndIf

	Self:SetContentType('application/json')
	Self:SetResponse(EncodeUTF8(cResponse:toJson()))
Return lRet

Static Function ConvertHora(nHora)
	Local cHora := CValToChar(nHora)

	If Len(cHora) == 1
		cHora := "0"+cHora+".00"
	EndIf

	If Len(cHora) == 2
		cHora := cHora+".00"
	EndIf

	If Len(cHora) == 3
		cHora := "0"+cHora+"0"
	EndIf

	If Len(cHora) == 4
		If SubStr(cHora, 2, 1) == "."
			cHora := "0"+cHora
		Else
			cHora := cHora+"0"
		EndIf
	EndIf

	If Len(cHora) == 5
		cHora := STRTRAN(cHora,".",":") + ":00"
	Else
		cHora := "00:00:00"
	EndIf
Return cHora

Static Function DiaExtenso(nDia)
	Local cDia
	nDia := Val(nDia)

	If nDia == 1
		cDia := "Domingo"
	EndIf
	If nDia == 2
		cDia := "Segunda"
	EndIf
	If nDia == 3
		cDia := "Ter�a"
	EndIf
	If nDia == 4
		cDia := "Quarta"
	EndIf
	If nDia == 5
		cDia := "Quinta"
	EndIf
	If nDia == 6
		cDia := "Sexta"
	EndIf
	If nDia == 7
		cDia := "S�bado"
	EndIf
Return cDia
