#INCLUDE 'TOTVS.CH'
#INCLUDE 'RESTFUL.CH'

WSRESTFUL marcacoes DESCRIPTION 'Manipulacao de Clientes'
	Self:SetHeader('Access-Control-Allow-Credentials' , "true")

	//Criação dos Metodos
	WSMETHOD GET DESCRIPTION 'Listar todas as marcacoes de uma matricula' WSSYNTAX '/marcacoes' PATH '/'

END WSRESTFUL

WSMETHOD GET WSSERVICE marcacoes
	//http://192.168.41.60:8090/rest/marcacoes/?filial=1201&matricula=000028
	//http://localhost:8090/rest/marcacoes/?filial=1201&matricula=000028

	Local aArea := GetArea()
	Local aAreaSP8 := SP8->(GetArea())
	Local cResponse := JsonObject():New()
	Local lRet := .T.
	Local aDados := {}
	Local aResumo := {}
	Local aPontos := {}
	Local aParams := Self:AQueryString
	Local cFilFunc := ""
	Local cMatricula := ""
	Local nPosFil := aScan(aParams,{|x| x[1] == "FILIAL"})
	Local nPosMatri := aScan(aParams,{|x| x[1] == "MATRICULA"})
	Local nPosDtIni := aScan(aParams,{|x| x[1] == "DTINICIAL"})
	Local nPosDtFin := aScan(aParams,{|x| x[1] == "DTFINAL"})
	Local dDatAux := CTOD("")
	Local nMes := 0
	Local cHorasAbonadas := cMotivoAbono := ""
	Local cHoras1T := cHoras2T := cTotalHoras := ""
	Local cTurno := ""
	Local cSqTurno := ""

	Default cDataIni := cDataFin := "19000101"

	If nPosFil > 0 .AND. nPosMatri > 0
		cFilFunc := aParams[nPosFil,2]
		cMatricula := aParams[nPosMatri,2]
		If nPosDtIni > 0 .AND. nPosDtFin > 0
			cDataIni := aParams[nPosDtIni,2]
			cDataFin := aParams[nPosDtFin,2]
		EndIf
	Else
		Return lRet
	EndIf

	If cDataIni == '19000101'
		If MONTH(Date()) == 1
			nMes := 12
		Else
			nMes := MONTH(Date())-1
		EndIf

		BEGINSQL ALIAS 'TSP8'
		SELECT
			SP8.R_E_C_N_O_, SP8.P8_DATA, SP8.P8_TPMARCA, SP8.P8_FILIAL, SP8.P8_MAT,
			SP8.P8_CC, SP8.P8_MOTIVRG, SP8.P8_TURNO, SP8.P8_HORA, SP8.P8_SEMANA
		FROM %Table:SP8% AS SP8
		WHERE
			SP8.%NotDel%
			AND SP8.P8_FILIAL = %exp:cFilFunc%
			AND SP8.P8_MAT = %exp:cMatricula%
			AND MONTH(SP8.P8_DATA) = %exp:nMes%
			ORDER BY SP8.P8_DATA
		ENDSQL
	Else
		BEGINSQL ALIAS 'TSP8'
		SELECT
			SP8.R_E_C_N_O_, SP8.P8_DATA, SP8.P8_TPMARCA, SP8.P8_FILIAL, SP8.P8_MAT,
			SP8.P8_CC, SP8.P8_MOTIVRG, SP8.P8_TURNO, SP8.P8_HORA, SP8.P8_SEMANA
		FROM %Table:SP8% AS SP8
		WHERE
			SP8.%NotDel%
			AND SP8.P8_FILIAL = %exp:cFilFunc%
			AND SP8.P8_MAT = %exp:cMatricula%
			AND SP8.P8_DATA BETWEEN %exp:cDataIni% AND %exp:cDataFin%
			ORDER BY SP8.P8_DATA
		ENDSQL
	EndIf

	GetResumo(@aResumo, cFilFunc, cMatricula, cDataIni, cDataFin)

	While !TSP8->(Eof())
		Aadd(aDados, JsonObject():new())
		nPos := Len(aDados)
		GetAbono(AllTrim(TSP8->P8_MAT), TSP8->P8_DATA, @cHorasAbonadas, @cMotivoAbono)
		GetTurno(@cTurno, @cSqTurno)
		aDados[nPos]['filial' ] := AllTrim(TSP8->P8_FILIAL)
		aDados[nPos]['matricula' ] := AllTrim(TSP8->P8_MAT)
		aDados[nPos]['data' ] := ConvertData(AllTrim(TSP8->P8_DATA))
		aDados[nPos]['dia' ] := DiaSemana(STOD(TSP8->P8_DATA))
		aDados[nPos]['centrocusto'] := AllTrim(TSP8->P8_CC)
		aDados[nPos]['ordemClassificacao'] := AllTrim(TSP8->P8_CC)
		aDados[nPos]['motivoRegistro'] := AllTrim(TSP8->P8_MOTIVRG)
		aDados[nPos]['turno'] := AllTrim(TSP8->P8_TURNO)
		aDados[nPos]['seqTurno'] := cSqTurno
		aDados[nPos]['abono'] := cHorasAbonadas
		aDados[nPos]['observacoes'] := cMotivoAbono

		dDatAux := TSP8->P8_DATA
		While dDatAux == TSP8->P8_DATA
			Aadd(aPontos, JsonObject():new())
			nPosPont := Len(aPontos)
			If AllTrim(TSP8->P8_TPMARCA) == "1E"
				aDados[nPos]['1E'] := ConvertHora(TSP8->P8_HORA)
			EndIf
			If AllTrim(TSP8->P8_TPMARCA) == "1S"
				aDados[nPos]['1S'] := ConvertHora(TSP8->P8_HORA)
			EndIf

			If AllTrim(TSP8->P8_TPMARCA) == "2E"
				aDados[nPos]['2E'] := ConvertHora(TSP8->P8_HORA)
			EndIf
			If AllTrim(TSP8->P8_TPMARCA) == "2S"
				aDados[nPos]['2S'] := ConvertHora(TSP8->P8_HORA)
			EndIf
			If AllTrim(TSP8->P8_TPMARCA) == "3E"
				aDados[nPos]['3E'] := ConvertHora(TSP8->P8_HORA)
			EndIf
			If AllTrim(TSP8->P8_TPMARCA) == "3S"
				aDados[nPos]['3S'] := ConvertHora(TSP8->P8_HORA)
			EndIf
			If AllTrim(TSP8->P8_TPMARCA) == "4E"
				aDados[nPos]['4E'] := ConvertHora(TSP8->P8_HORA)
			EndIf
			If AllTrim(TSP8->P8_TPMARCA) == "4S"
				aDados[nPos]['4S'] := ConvertHora(TSP8->P8_HORA)
			EndIf

			TSP8->(DbSkip())
		EndDo
		cHoras1T := SomaHoras(aDados[nPos]['1E'], aDados[nPos]['1S'])
		cHoras2T := SomaHoras(aDados[nPos]['2E'], aDados[nPos]['2S'])
		cTotalHoras := SomaHoras(cHoras1T, cHoras2T, "S")
		aDados[nPos]['jornada'] := cTotalHoras
		aDados[nPos]['horasExtras'] := SomaHoras(cTurno, cTotalHoras, "E")
		aDados[nPos]['abstencao'] := SomaHoras(cTurno, cTotalHoras, "A")
	EndDo

	TSP8->(DbCloseArea())

	If Len(aDados) == 0
		cResponse['erro'] := 204
		cResponse['message'] := "Nenhuma marcação de ponto encontrada"
		lRet := .F.
	Else
		cResponse['marcacoes'] := aDados
		cResponse['resumo'] := aResumo
		cResponse['hasContent'] := .T.
	EndIf

	Self:SetContentType('application/json')
	Self:SetResponse(EncodeUTF8(cResponse:toJson()))

	SP8->(RestArea(aAreaSP8))
	RestArea(aArea)
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
	
	If Len(cHora) == 5 .OR. Len(cHora) == 6
		cHora := STRTRAN(cHora,".",":") + ":00"
	Else
		cHora := "00:00:00"
	EndIf

Return cHora

Static Function ConvertData(cData)
	Local cDtCorrigida := ""
	Local cAno := SubStr(cData, 1, 4)
	Local cMes := SubStr(cData, 5, 2)
	Local cDia := SubStr(cData, 7, 2)

	cDtCorrigida := cAno+"-"+cMes+"-"+cDia
Return cDtCorrigida

Static Function GetAbono(cMatricula, cDataAbono, cHorasAbonadas, cMotivoAbono)
	Local aAreaSPK := SPK->(GetArea())

	SPK->(DbSetOrder(1))
	If SPK->(MsSeek(xFilial("SPK")+cMatricula+cDataAbono))
		cMotivoAbono := ALLTRIM(POSICIONE("SP6", 1, xFilial("SP6")+SPK->PK_CODABO, "P6_DESC"))
		cHorasAbonadas := ConvertHora(SPK->PK_HRSABO)
	EndIf

	SPK->(RestArea(aAreaSPK))
Return

Static Function GetTurno(cTurno, cSqTurno)
	Local nDia := DOW(STOD(TSP8->P8_DATA))

	BEGINSQL ALIAS 'TSPJ'
		SELECT
			SPJ.PJ_HRTOTAL, SPJ.PJ_SEMANA, SPJ.PJ_HRSINT1
		FROM %Table:SPJ% AS SPJ
		WHERE
			SPJ.%NotDel%
			AND SPJ.PJ_TURNO = %exp:TSP8->P8_TURNO%
			AND SPJ.PJ_SEMANA = %exp:TSP8->P8_SEMANA%
			AND SPJ.PJ_DIA = %exp:nDia%
	ENDSQL

	If !TSPJ->(Eof())
		cTurno := ConvertHora(TSPJ->PJ_HRTOTAL - TSPJ->PJ_HRSINT1)
		cSqTurno := TSPJ->PJ_SEMANA
	EndIf
	TSPJ->(DbCloseArea())
Return

Static Function SomaHoras(cHoraIni, cHoraFin, cTipo)
	Local cHoraSomada := "00:00"
	Local lHorasValidas := .F.

	Default cTipo := "D"

	If ValType(cHoraIni) == "C" .AND. ValType(cHoraFin) == "C"
		lHorasValidas := .T.
	EndIf

	If cTipo == "D" .AND. lHorasValidas

		inicial := HTOM(cHoraIni)
		final := HTOM(cHoraFin)

		If final > inicial
			cHoraSomada := MTOH(final - inicial)
		Else //Caso a hora da saida seja feita num dia posterior ao da entrada
			cHoraFin := SomaHoras(cHoraFin, "24:00:00", "S")
			inicial := HTOM(cHoraIni)
			final := HTOM(cHoraFin)
			cHoraSomada := MTOH(final - inicial)
		EndIf
	EndIf

	If cTipo == "E" .AND. lHorasValidas
		esperado := HTOM(cHoraIni)
		trabalhado := HTOM(cHoraFin)

		If trabalhado > esperado
			cHoraSomada := MTOH(trabalhado - esperado)
		Else
			cHoraSomada := "00:00"
		EndIf
	EndIf

	If cTipo == "A" .AND. lHorasValidas
		esperado := HTOM(cHoraIni)
		trabalhado := HTOM(cHoraFin)

		If trabalhado < esperado
			cHoraSomada := MTOH(esperado - trabalhado)
		Else
			cHoraSomada := "00:00"
		EndIf
	EndIf

	If cTipo == "S" .AND. lHorasValidas
		nSoma := HTOM(cHoraIni) + HTOM(cHoraFin)
		cHoraSomada := MTOH(nSoma)
	EndIf

Return ConvertHora(cHoraSomada)

Static Function HTOM(cHora) //00:00 formato que deve ser recebido
	Local nMinutos := 0
	Local nHo := Val(SUBSTR(cHora,1,2)) //pego apenas a parte da hora
	Local nMi := Val(SUBSTR(cHora,4,2)) //pego apenas a parte dos minutos

	nMinutos := (nHo * 60) + nMi //Transformo horas em minutos e adiciono os minutos

Return nMinutos

Static Function MTOH(nMinutos) //deve vim como um numero inteiro
	Local nResto := 0

	nResto := Mod(nMinutos, 60) //Separo quantos minutos faltam para horas completas
	nMinutos -= nResto //Retiro dos minutos a quantidades que sobraram da divisao para horas
	nMinutos /= 60 //transformo os minutos em horas
	nMinutos += (nResto / 100) //adiciono os minutos que tinham sobrado a hora

Return nMinutos

Static Function GetResumo(aResumo, cFilFunc, cMatricula, cDataIni, cDataFin)
	Local aDados := {}
	Local aSoma := {}
	Local nLinha := 0

	BEGINSQL ALIAS 'TSPC'
		SELECT DISTINCT
			SPC.PC_DATA, SPC.PC_PD, SPC.PC_QUANTC, SPC.PC_QUANTI
		FROM %Table:SPC% AS SPC
		WHERE
			SPC.%NotDel%
			AND SPC.PC_FILIAL = %exp:cFilFunc%
			AND SPC.PC_DATA BETWEEN %exp:cDataIni% AND %exp:cDataFin%
			AND SPC.PC_MAT = %exp:cMatricula%
			ORDER BY SPC.PC_DATA, SPC.PC_PD
	ENDSQL

	While !TSPC->(Eof())
		Aadd(aDados, {TSPC->PC_PD, HTOM(ConVertHora(TSPC->PC_QUANTC)), HTOM(ConvertHora(TSPC->PC_QUANTI))})
		TSPC->(DbSkip())
	EndDo

	For nLinha := 1 to Len(aDados)
		nPos := ascan(aSoma,{ |x| x[1] = aDados[nLinha,1] } )
		If Empty(nPos)
			aadd(aSoma,{aDados[nLinha, 1],aDados[nLinha, 2]-aDados[nLinha, 3]})
		Else
			aSoma[nPos,2] += aDados[nLinha,2] - aDados[nLinha, 3]
		EndIf
	Next nLinha

	ASORT(aSoma, , , { | x,y | x[1] < y[1] } )

	For nLinha := 1 To Len(aSoma)
		Aadd(aResumo, JsonObject():new())
		nPos := Len(aResumo)
		aResumo[nPos]['codEvento'] := aSoma[nLinha,1]
		aResumo[nPos]['descEvento'] := ALLTRIM(POSICIONE("SP9", 1, xFilial("SP9")+ aSoma[nLinha,1], "P9_DESC"))
		aResumo[nPos]['totalHoras'] := ConvertHora(MTOH(aSoma[nLinha,2]))
	Next

	TSPC->(DbCloseArea())
Return
