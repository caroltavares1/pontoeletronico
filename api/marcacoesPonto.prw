#INCLUDE 'TOTVS.CH'
#INCLUDE 'RESTFUL.CH'

WSRESTFUL marcacoes DESCRIPTION 'Consulta de marcacoes do relogio de ponto'
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
	Local aLinha := {}
	Local aMarcacoes := {}
	Local aFinsSem := {}
	Local aFeriados := {}
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
	Local nCont := 0

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
			SP8.P8_DATA, SP8.P8_TPMARCA, SP8.P8_FILIAL, SP8.P8_MAT,
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
			SP8.P8_DATA, SP8.P8_TPMARCA, SP8.P8_FILIAL, SP8.P8_MAT,
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
	GetTurno(@cTurno, @cSqTurno, cFilFunc)

	If !TSP8->(Eof())
		aFinsSem := GetFinalSemana(cDataIni, cDataFin, cFilFunc, cMatricula, AllTrim(TSP8->P8_TURNO), cSqTurno)
		aFeriados := GetFeriados(cDataIni, cDataFin, cFilFunc, AllTrim(TSP8->P8_TURNO), cSqTurno)
	EndIf

	While !TSP8->(Eof())
		Aadd(aMarcacoes, {})
		nPos := Len(aMarcacoes)
		GetAbono(AllTrim(TSP8->P8_MAT), TSP8->P8_DATA, @cHorasAbonadas, @cMotivoAbono)
		Aadd(aLinha, ConvertData(AllTrim(TSP8->P8_DATA))) //1-data
		Aadd(aLinha, AllTrim(TSP8->P8_FILIAL)) //2-filial
		Aadd(aLinha, AllTrim(TSP8->P8_MAT)) //3-matricula
		Aadd(aLinha, DiaSemana(STOD(TSP8->P8_DATA))) //4-dia
		Aadd(aLinha, AllTrim(TSP8->P8_CC)) //5-centrocusto
		Aadd(aLinha, AllTrim(TSP8->P8_CC)) //6-ordemClassificacao
		Aadd(aLinha, AllTrim(TSP8->P8_MOTIVRG)) //7-motivoRegistro
		Aadd(aLinha, AllTrim(TSP8->P8_TURNO)) //8-turno
		Aadd(aLinha, cSqTurno) //9-seqTurno
		Aadd(aLinha, cHorasAbonadas) //10-abono
		Aadd(aLinha, cMotivoAbono) //11-observacoes
		Aadd(aLinha, AllTrim(TSP8->P8_TPMARCA)) //12-tipoMarca
		Aadd(aLinha, ConvertHora(TSP8->P8_HORA)) //13-marcacao

		aMarcacoes[nPos] := aLinha
		aLinha := {}
		TSP8->(DbSkip())
	EndDo

	For nCont := 1 To Len(aFinsSem)
		Aadd(aMarcacoes, aFinsSem[nCont])
	Next

	For nCont := 1 To Len(aFeriados)
		Aadd(aMarcacoes, aFeriados[nCont])
	Next

	nCont := 1
	aSort(aMarcacoes, , , {|x, y| x[1] < y[1]})
	While nCont <= Len(aMarcacoes)
		Aadd(aDados, JsonObject():new())
		nPos := Len(aDados)
		aDados[nPos]['data' ] := aMarcacoes[nCont][1]
		aDados[nPos]['filial' ] := aMarcacoes[nCont][2]
		aDados[nPos]['matricula' ] := aMarcacoes[nCont][3]
		aDados[nPos]['dia' ] := aMarcacoes[nCont][4]
		aDados[nPos]['centrocusto'] := aMarcacoes[nCont][5]
		aDados[nPos]['ordemClassificacao'] := aMarcacoes[nCont][6]
		aDados[nPos]['motivoRegistro'] := aMarcacoes[nCont][7]
		aDados[nPos]['turno'] := aMarcacoes[nCont][8]
		aDados[nPos]['seqTurno'] := aMarcacoes[nCont][9]
		aDados[nPos]['abono'] := aMarcacoes[nCont][10]
		aDados[nPos]['observacoes'] := aMarcacoes[nCont][11]

		dDatAux := aMarcacoes[nCont][1]
		While nCont <= Len(aMarcacoes) .AND. dDatAux == aMarcacoes[nCont][1]
			If aMarcacoes[nCont][12] == "1E"
				aDados[nPos]['1E'] := aMarcacoes[nCont][13]
			EndIf
			If aMarcacoes[nCont][12] == "1S"
				aDados[nPos]['1S'] := aMarcacoes[nCont][13]
			EndIf

			If aMarcacoes[nCont][12] == "2E"
				aDados[nPos]['2E'] := aMarcacoes[nCont][13]
			EndIf
			If aMarcacoes[nCont][12] == "2S"
				aDados[nPos]['2S'] := aMarcacoes[nCont][13]
			EndIf
			nCont++
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

Static Function GetTurno(cTurno, cSqTurno, cFilFunc)
	Local nDia := DOW(STOD(TSP8->P8_DATA))

	BEGINSQL ALIAS 'TSPJ'
		SELECT
			SPJ.PJ_HRTOTAL, SPJ.PJ_SEMANA, SPJ.PJ_HRSINT1
		FROM %Table:SPJ% AS SPJ
		WHERE
			SPJ.%NotDel%
			AND SPJ.PJ_FILIAL = %exp:LEFT(cFilFunc,2)%
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

Static Function GetFinalSemana(cDataIni, cDataFin, cFilFunc, cMatricula, cTurno, cSqTurno)
	Local aDias := {}
	Local dInicial := STOD(cDataIni)
	Local dFinal := STOD(cDataFin)

	While dInicial <= dFinal
		If DOW(dInicial) == 7
			SP8->(DbSetOrder(2))
			If !SP8->(MsSeek(cFilFunc+cMatricula+DTOS(dInicial)))
				Aadd(aDias, {ConvertData(DTOS(dInicial)),"","",DiaSemana(dInicial),"","","",cTurno,cSqTurno,"","** Compensado **","",""})
			EndIf
		EndIf
		If DOW(dInicial) == 1
			SP8->(DbSetOrder(2))
			If !SP8->(MsSeek(cFilFunc+cMatricula+DTOS(dInicial)))
				Aadd(aDias, {ConvertData(DTOS(dInicial)),"","",DiaSemana(dInicial),"","","",cTurno,cSqTurno,"","** D.S.R. **","",""})
			EndIf
		EndIf
		dInicial := DaySum(dInicial, 1)
	EndDo
Return aDias

Static Function GetFeriados(cDataIni, cDataFin, cFilFunc,  cTurno, cSqTurno)
	Local aFeriados := {}

	BEGINSQL ALIAS 'TSP3'
		SELECT
			SP3.P3_DATA AS 'DATA', SP3.P3_DESC AS 'DESC'
		FROM %Table:SP3% AS SP3
		WHERE
			SP3.%NotDel%
			AND SP3.P3_DATA BETWEEN %exp:cDataIni% AND %exp:cDataFin%
			AND SP3.P3_FILIAL = %exp:cFilFunc%
	ENDSQL

	While !TSP3->(Eof())
		Aadd(aFeriados, {ConvertData(TSP3->DATA),"","",DiaSemana(STOD(TSP3->DATA)),"","","",cTurno,cSqTurno,"",TSP3->DESC,"",""})
		TSP3->(DbSkip())
	EndDo

	TSP3->(DbCloseArea())

Return aFeriados
