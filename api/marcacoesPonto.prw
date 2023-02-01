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
	Local aAreaSPA := SPA->(GetArea())
	Local cResponse := JsonObject():New()
	Local lRet := .T.
	Local aDados := {}
	Local aResumo := {}
	Local aLinha := {}
	Local aMarcacoes := {}
	Local aFinsSem := {}
	Local aFeriados := {}
	Local aAbonos := {}
	Local aTurnos := {}
	Local aAfasta := {}
	Local aAfastamentos := {}
	Local aParams := Self:AQueryString
	Local cFilFunc := ""
	Local cMatricula := ""
	Local cJornadaPrevista := ""
	Local nPosFil := aScan(aParams,{|x| x[1] == "FILIAL"})
	Local nPosMatri := aScan(aParams,{|x| x[1] == "MATRICULA"})
	Local nPosDtIni := aScan(aParams,{|x| x[1] == "DTINICIAL"})
	Local nPosDtFin := aScan(aParams,{|x| x[1] == "DTFINAL"})
	Local dDatAux := CTOD("")
	Local nMes := 0
	Local cHorasAbonadas := cMotivoAbono := ""
	Local cHoras1T := cHoras2T := cHoras3T := cHoras4T := cTotalHoras := ""
	Local cTurno := ""
	Local cSqTurno := ""
	Local nCont := 0
	Local nRegSP8 := 0
	Private nTolAbst := 0
	Private nTolHoEx := 0

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
			SP8.P8_CC, SP8.P8_MOTIVRG, SP8.P8_TURNO, SP8.P8_HORA, SP8.P8_SEMANA, SP8.R_E_C_N_O_
		FROM %Table:SP8% AS SP8
		WHERE
			SP8.%NotDel%
			AND SP8.P8_FILIAL = %exp:cFilFunc%
			AND SP8.P8_MAT = %exp:cMatricula%
			AND MONTH(SP8.P8_DATA) = %exp:nMes%
			AND SP8.P8_TPMCREP != 'D'
			ORDER BY SP8.P8_DATA
		ENDSQL
	Else
		BEGINSQL ALIAS 'TSP8'
		SELECT
			SP8.P8_DATA, SP8.P8_TPMARCA, SP8.P8_FILIAL, SP8.P8_MAT,
			SP8.P8_CC, SP8.P8_MOTIVRG, SP8.P8_TURNO, SP8.P8_HORA, SP8.P8_SEMANA, SP8.R_E_C_N_O_
		FROM %Table:SP8% AS SP8
		WHERE
			SP8.%NotDel%
			AND SP8.P8_FILIAL = %exp:cFilFunc%
			AND SP8.P8_MAT = %exp:cMatricula%
			AND SP8.P8_DATA BETWEEN %exp:cDataIni% AND %exp:cDataFin%
			AND SP8.P8_TPMCREP != 'D'
			ORDER BY SP8.P8_DATA
		ENDSQL
	EndIf

	GetResumo(@aResumo, cFilFunc, cMatricula, cDataIni, cDataFin)
	GetTolerancias(cFilFunc, cMatricula, @nTolAbst, @nTolHoEx)

	While !TSP8->(Eof()) //Varre o resultado da query para pegar o recno do ultimo registro
		If TSP8->R_E_C_N_O_ > nRegSP8
			nRegSP8 := TSP8->R_E_C_N_O_
		EndIf
		TSP8->(DbSkip())
	EndDo

	If nRegSP8 > 0 //Com o ultimo registro encontrado limita o resultado das buscas de fins de semana, feriados e abonos ate a data do ultimo registro
		SP8->(DbGoto(nRegSP8))
		cTurno := AllTrim(SP8->P8_TURNO)
		cSqTurno := AllTrim(SP8->P8_SEMANA)
		GetTurnos(@aTurnos, cFilFunc, cTurno, cSqTurno)

		If Empty(cSqTurno) //Se a sequencia do turno estiver vazia
			SRA->(DbSetOrder(1)) //RA_FILIAL + RA_MAT + RA_NOME
			If SRA->(MsSeek(cFilFunc+cMatricula))
				cTurno := AllTrim(SRA->RA_TNOTRAB)
				cSqTurno := AllTrim(SRA->RA_SEQTURN)
				GetTurnos(@aTurnos, cFilFunc, cTurno, cSqTurno)
			EndIf
		EndIf

		aFinsSem := GetFinalSemana(cDataIni, DTOS(SP8->P8_DATA), cFilFunc, cMatricula, cTurno, cSqTurno, aTurnos)
		aFeriados := GetFeriados(cDataIni, DTOS(SP8->P8_DATA), cFilFunc, cTurno, cSqTurno, aTurnos)
		aAbonos := GetAbonos(cDataIni, cDataFin, cFilFunc, cMatricula, cTurno, cSqTurno, aTurnos)
	Else
		If Empty(cSqTurno) //Se a sequencia do turno estiver vazia
			SRA->(DbSetOrder(1)) //RA_FILIAL + RA_MAT + RA_NOME
			If SRA->(MsSeek(cFilFunc+cMatricula))
				cTurno := AllTrim(SRA->RA_TNOTRAB)
				cSqTurno := AllTrim(SRA->RA_SEQTURN)
				GetTurnos(@aTurnos, cFilFunc, cTurno, cSqTurno)
			EndIf
		EndIf
	EndIf

	fAfastaPer( @aAfasta , STOD(cDataIni) , STOD(cDataFin) , ALLTRIM(cFilFunc) , cMatricula)
	aAfastamentos := GetAfastamentos(cFilFunc, aAfasta, cTurno, cSqTurno, aTurnos)

	TSP8->(DBGOTOP()) //Volta para o topo da tabela temporaria
	While !TSP8->(Eof())
		Aadd(aMarcacoes, {})
		nPos := Len(aMarcacoes)
		cHorasAbonadas := cMotivoAbono := ""
		GetAbono(aAbonos, TSP8->P8_DATA, @cHorasAbonadas, @cMotivoAbono)
		Aadd(aLinha, ConvertData(AllTrim(TSP8->P8_DATA))) //1-data
		Aadd(aLinha, AllTrim(TSP8->P8_FILIAL)) //2-filial
		Aadd(aLinha, AllTrim(TSP8->P8_MAT)) //3-matricula
		Aadd(aLinha, Alltrim(DiaSemana(STOD(TSP8->P8_DATA)))) //4-dia
		Aadd(aLinha, AllTrim(TSP8->P8_CC)) //5-centrocusto
		Aadd(aLinha, AllTrim(TSP8->P8_CC)) //6-ordemClassificacao
		Aadd(aLinha, AllTrim(TSP8->P8_MOTIVRG)) //7-motivoRegistro
		If !Empty(TSP8->P8_TURNO)
			Aadd(aLinha, Alltrim(TSP8->P8_TURNO)) //8-turno
		Else
			Aadd(aLinha, cTurno) //8-turno
		EndIf
		If !Empty(TSP8->P8_SEMANA)
			Aadd(aLinha, AllTrim(TSP8->P8_TURNO)) //9-seqTurno
		Else
			Aadd(aLinha, cSqTurno) //9-seqTurno
		EndIf
		Aadd(aLinha, cHorasAbonadas) //10-abono
		Aadd(aLinha, cMotivoAbono) //11-observacoes
		Aadd(aLinha, AllTrim(TSP8->P8_TPMARCA)) //12-tipoMarca
		Aadd(aLinha, U_ConvertHora(TSP8->P8_HORA)) //13-marcacao
		Aadd(aLinha, .F.) //14-diaAbonado
		Aadd(aLinha, U_ConvertHora(0)) //15-Adicional Noturno
		Aadd(aLinha, GetTurno(aTurnos, "T", STOD(TSP8->P8_DATA))) //16-Jornada Prevista

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

	For nCont := 1 To Len(aAfastamentos)
		Aadd(aMarcacoes, aAfastamentos[nCont])
	Next

	For nCont := 1 To Len(aAbonos)
		If Len(aAbonos[nCont]) > 7
			Aadd(aMarcacoes, aAbonos[nCont])
		EndIf
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

			If aMarcacoes[nCont][12] == "3E"
				aDados[nPos]['3E'] := aMarcacoes[nCont][13]
			EndIf
			If aMarcacoes[nCont][12] == "3S"
				aDados[nPos]['3S'] := aMarcacoes[nCont][13]
			EndIf

			If aMarcacoes[nCont][12] == "4E"
				aDados[nPos]['4E'] := aMarcacoes[nCont][13]
			EndIf
			If aMarcacoes[nCont][12] == "4S"
				aDados[nPos]['4S'] := aMarcacoes[nCont][13]
			EndIf

			cJornadaPrevista := aMarcacoes[nCont][16]
			aDados[nPos]['diaAbonado'] := aMarcacoes[nCont][14]
			aDados[nPos]['adicNoturno'] := aMarcacoes[nCont][15]
			nCont++
		EndDo
		cHoras1T := SomaHoras(aDados[nPos]['1E'], aDados[nPos]['1S'])
		cHoras2T := SomaHoras(aDados[nPos]['2E'], aDados[nPos]['2S'])
		cHoras3T := SomaHoras(aDados[nPos]['3E'], aDados[nPos]['3S'])
		cHoras4T := SomaHoras(aDados[nPos]['4E'], aDados[nPos]['4S'])
		cTotalHoras := SomaHoras(cHoras1T, cHoras2T, "S")
		cTotalHoras := SomaHoras(cTotalHoras, cHoras3T, "S") //Soma terceiro turno
		cTotalHoras := SomaHoras(cTotalHoras, cHoras4T, "S") //Soma quarto turno

		aDados[nPos]['jornada'] := cTotalHoras
		aDados[nPos]['horasExtras'] := SomaHoras(cJornadaPrevista, cTotalHoras, "E")
		aDados[nPos]['abstencao'] := SomaHoras(cJornadaPrevista, cTotalHoras, "A")
		aDados[nPos]['jornadaPrevista'] := cJornadaPrevista

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

	SPA->(RestArea(aAreaSPA))
	SP8->(RestArea(aAreaSP8))
	RestArea(aArea)
Return lRet

User Function ConvertHora(nHora)
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
		cHora := STRTRAN(cHora,".",":")
	Else
		cHora := "00:00"
	EndIf

Return cHora

Static Function ConvertData(cData)
	Local cDtCorrigida := ""
	Local cAno := SubStr(cData, 1, 4)
	Local cMes := SubStr(cData, 5, 2)
	Local cDia := SubStr(cData, 7, 2)

	cDtCorrigida := cAno+"-"+cMes+"-"+cDia
Return cDtCorrigida

Static Function GetAbono(aAbonos, cDataAbono, cHorasAbonadas, cMotivoAbono)
	Local nPosAbon := aScan(aAbonos,{|x| x[6] == cDataAbono})

	If nPosAbon > 0
		cMotivoAbono := aAbonos[nPosAbon,3]
		cHorasAbonadas := U_ConvertHora(aAbonos[nPosAbon,4])
	EndIf
Return

Static Function GetTurnos(aTurnos, cFilFunc, cTurno, cSqTurno)
	Local cTurnoTmp := cSqTurnoTmp := ""
	Local cQry := ""

	BEGINSQL ALIAS 'TSPJ'
		SELECT
			SPJ.PJ_HRTOTAL, SPJ.PJ_SEMANA, SPJ.PJ_HRSINT1, SPJ.PJ_DIA
		FROM %Table:SPJ% AS SPJ
		WHERE
			SPJ.%NotDel%
			AND SPJ.PJ_FILIAL = %exp:LEFT(cFilFunc,2)%
			AND SPJ.PJ_TURNO = %exp:cTurno%
			AND SPJ.PJ_SEMANA = %exp:cSqTurno%
	ENDSQL

	cQry := GetLastQuery()[2]

	While !TSPJ->(Eof())
		cTurnoTmp := U_ConvertHora(TSPJ->PJ_HRTOTAL - TSPJ->PJ_HRSINT1)
		cSqTurnoTmp := TSPJ->PJ_SEMANA
		Aadd(aTurnos, {TSPJ->PJ_DIA, cTurnoTmp, cSqTurnoTmp})
		TSPJ->(DbSkip())
	EndDo
	TSPJ->(DbCloseArea())
Return cQry

Static Function GetTurno(aTurno, cTipo, dDataTurno)
	Local nDia := DOW(dDataTurno)
	Local nPosTurno := aScan(aTurno,{|x| Val(x[1]) == nDia})
	Local cRet := "" //Turno ou Sequencia de Turno

	If cTipo == 'T' .AND. nPosTurno > 0
		cRet := aTurno[nPosTurno,2]
	EndIf

	If cTipo == 'S' .AND. nPosTurno > 0
		cRet := aTurno[nPosTurno,3]
	EndIf

Return cRet

Static Function SomaHoras(cHoraIni, cHoraFin, cTipo)
	Local cHoraSomada := "00:00"
	Local lHorasValidas := .F.

	Default cTipo := "D"

	If ValType(cHoraIni) == "C" .AND. ValType(cHoraFin) == "C"
		lHorasValidas := .T.
	EndIf

	If cTipo == "D" .AND. lHorasValidas

		inicial := U_HTOM(cHoraIni)
		final := U_HTOM(cHoraFin)

		If final > inicial
			cHoraSomada := U_MTOH(final - inicial)
		Else //Caso a hora da saida seja feita num dia posterior ao da entrada
			cHoraFin := SomaHoras(cHoraFin, "24:00:00", "S")
			inicial := U_HTOM(cHoraIni)
			final := U_HTOM(cHoraFin)
			cHoraSomada := U_MTOH(final - inicial)
		EndIf
	EndIf

	If cTipo == "E" .AND. lHorasValidas
		esperado := U_HTOM(cHoraIni)
		trabalhado := U_HTOM(cHoraFin)

		If trabalhado > esperado .AND. (trabalhado - esperado) > U_HTOM(U_ConvertHora(nTolHoEx))
			cHoraSomada := U_MTOH(trabalhado - esperado)
		Else
			cHoraSomada := "00:00"
		EndIf
	EndIf

	If cTipo == "A" .AND. lHorasValidas
		esperado := U_HTOM(cHoraIni)
		trabalhado := U_HTOM(cHoraFin)

		If trabalhado < esperado .AND. (esperado - trabalhado) > U_HTOM(U_ConvertHora(nTolAbst))
			cHoraSomada := U_MTOH(esperado - trabalhado)
		Else
			cHoraSomada := "00:00"
		EndIf
	EndIf

	If cTipo == "S" .AND. lHorasValidas
		nSoma := U_HTOM(cHoraIni) + U_HTOM(cHoraFin)
		cHoraSomada := U_MTOH(nSoma)
	EndIf

Return U_ConvertHora(cHoraSomada)

User Function HTOM(cHora) //00:00 formato que deve ser recebido
	Local nMinutos := 0
	Local nHo := Val(SUBSTR(cHora,1,2)) //pego apenas a parte da hora
	Local nMi := Val(SUBSTR(cHora,4,2)) //pego apenas a parte dos minutos

	nMinutos := (nHo * 60) + nMi //Transformo horas em minutos e adiciono os minutos

Return nMinutos

User Function MTOH(nMinutos) //deve vim como um numero inteiro
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
		Aadd(aDados, {TSPC->PC_PD, U_HTOM(U_ConVertHora(TSPC->PC_QUANTC)), U_HTOM(U_ConvertHora(TSPC->PC_QUANTI))})
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
		aResumo[nPos]['totalHoras'] := U_ConvertHora(U_MTOH(aSoma[nLinha,2]))
	Next

	TSPC->(DbCloseArea())
Return

Static Function GetFinalSemana(cDataIni, cDataFin, cFilFunc, cMatricula, cTurno, cSqTurno, aTurnos)
	Local aDias := {}
	Local dInicial := STOD(cDataIni)
	Local dFinal := STOD(cDataFin)
	Local aArea := GetArea()
	Local aAreaSP8 := SP8->(GetArea())
	Local cJornadaPrevista := ""

	SPJ->(DbSetOrder(1)) //PJ_FILIAL + PJ_TURNO + PJ_SEMANA + PJ_DIA
	While dInicial <= dFinal
		SP3->(DbSetOrder(1))
		If !SP3->(MsSeek(cFilFunc+DTOS(dInicial)))
			If DOW(dInicial) == 7
				If SPJ->(MsSeek(Left(cFilFunc,2)+"  "+cTurno+cSqTurno+"7"))
					SP8->(DbSetOrder(2))
					If !SP8->(MsSeek(cFilFunc+cMatricula+DTOS(dInicial))) .AND. SPJ->PJ_TPDIA == 'C'
						cJornadaPrevista := GetTurno(aTurnos, "T", dInicial)
						cJornadaPrevista := GetTurno(aTurnos, "T", dInicial)
						Aadd(aDias, {ConvertData(DTOS(dInicial)),"","",ALLTRIM(DiaSemana(dInicial)),"","","",cTurno,cSqTurno,"","** Compensado **","","",.F.,U_ConvertHora(0),cJornadaPrevista})
					EndIf
				EndIf
			EndIf
			If DOW(dInicial) == 1
				If SPJ->(MsSeek(Left(cFilFunc,2)+"  "+cTurno+cSqTurno+"1"))
					SP8->(DbSetOrder(2))
					If !SP8->(MsSeek(cFilFunc+cMatricula+DTOS(dInicial))) .AND. SPJ->PJ_TPDIA == 'D'
						cJornadaPrevista := GetTurno(aTurnos, "T", dInicial)
						Aadd(aDias, {ConvertData(DTOS(dInicial)),"","",ALLTRIM(DiaSemana(dInicial)),"","","",cTurno,cSqTurno,"","** D.S.R. **","","",.F.,U_ConvertHora(0),cJornadaPrevista})
					EndIf
				EndIf
			EndIf
		EndIf
		dInicial := DaySum(dInicial, 1)
	EndDo

	SP8->(RestArea(aAreaSP8))
	RestArea(aArea)
Return aDias

Static Function GetFeriados(cDataIni, cDataFin, cFilFunc,  cTurno, cSqTurno, aTurnos)
	Local aFeriados := {}
	Local cJornadaPrevista := ""

	BEGINSQL ALIAS 'TSP3'
		SELECT
			SP3.P3_DATA AS 'DATA', SP3.P3_DESC AS 'DESC', SP3.P3_FIXO AS 'FIXO', SP3.P3_MESDIA
		FROM %Table:SP3% AS SP3
		WHERE
			SP3.%NotDel%
			AND SP3.P3_DATA BETWEEN %exp:cDataIni% AND %exp:cDataFin%
			AND SP3.P3_FILIAL = %exp:cFilFunc%
	ENDSQL

	While !TSP3->(Eof())
		If TSP3->FIXO == 'S'
			cAno := cValToChar(Ano(Date()))
			cMesDia := TSP3->P3_MESDIA
			cJornadaPrevista := GetTurno(aTurnos, "T", STOD(TSP3->DATA))
			Aadd(aFeriados, {ConvertData(cAno+cMesDia),"","",ALLTRIM(DiaSemana(STOD(TSP3->DATA))),"","","",cTurno,cSqTurno,"",ALLTRIM(TSP3->DESC),"","",.F.,U_ConvertHora(0),cJornadaPrevista})
		Else
			cJornadaPrevista := GetTurno(aTurnos, "T", STOD(TSP3->DATA))
			Aadd(aFeriados, {ConvertData(TSP3->DATA),"","",ALLTRIM(DiaSemana(STOD(TSP3->DATA))),"","","",cTurno,cSqTurno,"",ALLTRIM(TSP3->DESC),"","",.F.,U_ConvertHora(0),cJornadaPrevista})
		EndIf
		TSP3->(DbSkip())
	EndDo

	TSP3->(DbCloseArea())

Return aFeriados

Static Function GetAbonos(cDataIni, cDataFim, cFilFunc, cMatricula, cTurno, cSqTurno, aTurnos)
	Local aRet := {}
	Local cJornadaPrevista := ""

	BEGINSQL ALIAS 'TSPK'
		SELECT
			SPK.PK_MAT, SPK.PK_CODABO, SP6.P6_DESC, SPK.PK_HRSABO, 
			SPK.PK_TPMARCA, SPK.PK_DATA, SPK.R_E_C_N_O_
		FROM %Table:SPK% AS SPK
		INNER JOIN %Table:SP6% AS SP6
		ON SP6.P6_FILIAL = %exp:Left(cFilFunc,2)% AND SP6.P6_CODIGO = SPK.PK_CODABO
		WHERE
			SPK.%NotDel% AND SP6.%NotDel%
			AND SPK.PK_FILIAL = %exp:cFilFunc%
			AND SPK.PK_MAT = %exp:cMatricula%
			AND SPK.PK_DATA BETWEEN %exp:cDataIni% AND %exp:cDataFim%
	ENDSQL

	While !TSPK->(Eof())
		SP8->(DbSetOrder(2))
		If SP8->(MsSeek(cFilFunc+cMatricula+TSPK->PK_DATA))
			Aadd(aRet, {TSPK->PK_MAT, TSPK->PK_CODABO, ALLTRIM(TSPK->P6_DESC), TSPK->PK_HRSABO, TSPK->PK_TPMARCA, TSPK->PK_DATA, TSPK->R_E_C_N_O_})
		Else
			cJornadaPrevista := GetTurno(aTurnos, "T", STOD(TSPK->PK_DATA))
			Aadd(aRet, {ConvertData(TSPK->PK_DATA),"","",ALLTRIM(DiaSemana(STOD(TSPK->PK_DATA))),"","","",cTurno,cSqTurno, U_ConvertHoras(TSPK->PK_HRSABO),ALLTRIM(TSPK->P6_DESC),"","",.T.,U_ConvertHora(0),cJornadaPrevista})
		EndIf

		TSPK->(DbSkip())
	EndDo
	TSPK->(DbCloseArea())

Return aRet

Static Function GetTolerancias(cFilFunc, cMatricula, nTolAbst, nTolHoEx)
	Local aArea := GetArea()
	Local aAreaSPA := SPA->(GetArea())
	Local aAreaSRA := SRA->(GetArea())

	SRA->(DbSetOrder(1))
	If SRA->(MsSeek(cFilFunc+cMatricula))
		SPA->(DbSetOrder(1))
		If SPA->(MsSeek(xFilial("SPA")+SRA->RA_REGRA))
			nTolAbst := SPA->PA_TOLFALT
			nTolHoEx := SPA->PA_TOLHEPE
		EndIf
	EndIf

	SRA->(RestArea(aAreaSRA))
	SPA->(RestArea(aAreaSPA))
	RestArea(aArea)
Return

Static Function GetAfastamentos(cFilFunc, aAfasta, cTurno, cSqTurno, aTurnos)
	Local aArea := GetArea()
	Local aAreaRCM := RCM->(GetArea())
	Local nCont := 0
	Local aAfastamentos := {}
	Local dInicial := STOD("")
	Local dFinal := STOD("")
	Local cTpAfast := ""
	Local cObservacoes := ""
	Local cJornadaPrevista := ""

	For nCont := 1 To Len(aAfasta)
		dInicial := aAfasta[nCont,1]
		dFinal := aAfasta[nCont,2]
		cTpAfast := Alltrim(aAfasta[nCont,3])

		RCM->(DbSetOrder(1))
		If RCM->(MsSeek(LEFT(cFilFunc,2)+"  "+cTpAfast))
			cObservacoes := AllTrim(RCM->RCM_DESCRI)
		EndIf

		SR8->(DbSetOrder(5)) //R8_FILIAL + R8_NUMID
		If SR8->(MsSeek(cFilFunc+aAfasta[nCont,4]))
			While dInicial <= dFinal
				cJornadaPrevista := GetTurno(aTurnos, "T", dInicial)
				Aadd(aAfastamentos, {ConvertData(DTOS(dInicial)),"","",ALLTRIM(DiaSemana(dInicial)),"","","",cTurno,cSqTurno,"",cObservacoes,"","",.T.,U_ConvertHora(0),cJornadaPrevista})
				dInicial := DaySum(dInicial, 1)
			EndDo
		EndIf
	Next

	RCM->(RestArea(aAreaRCM))
	RestArea(aArea)
Return aAfastamentos
