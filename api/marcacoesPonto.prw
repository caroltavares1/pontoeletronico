#INCLUDE 'TOTVS.CH'
#INCLUDE 'RESTFUL.CH'

WSRESTFUL marcacoes DESCRIPTION 'Consulta de marcacoes do relogio de ponto'
	Self:SetHeader('Access-Control-Allow-Credentials' , "true")

	//Cria��o dos Metodos
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
	Local aAfasta := {}
	Local aAfastamentos := {}
	Local aDiasAdNot := {}
	Local aParams := Self:AQueryString
	Local cFilFunc := ""
	Local cMatricula := ""
	Local cJornadaPrevista := ""
	Local nPosFil := aScan(aParams,{|x| x[1] == "FILIAL"})
	Local nPosMatri := aScan(aParams,{|x| x[1] == "MATRICULA"})
	Local nPosDtIni := aScan(aParams,{|x| x[1] == "DTINICIAL"})
	Local nPosDtFin := aScan(aParams,{|x| x[1] == "DTFINAL"})
	Local nPosAdNot := 0
	Local dDatAux := CTOD("")
	Local nMes := 0
	Local cHorasAbonadas := cMotivoAbono := ""
	Local cHoras1T := cHoras2T := cHoras3T := cHoras4T := cTotalHoras := ""
	Local nCont := 0
	Local aJornada := {}
	Local nMinHrNot := nFimHnot := nIniHNot := 0
	Local cAlias := GetNextAlias()
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

	AnalisarPeriodo(cFilFunc, cMatricula, cDataIni, cDataFin)

	If cDataIni == '19000101'
		If MONTH(Date()) == 1
			nMes := 12
		Else
			nMes := MONTH(Date())-1
		EndIf

		BEGINSQL ALIAS cAlias
		SELECT
			SP8.P8_DATA AS 'DATA', SP8.P8_TPMARCA AS 'TPMARCA', SP8.P8_FILIAL AS 'FILIAL', SP8.P8_MAT AS 'MAT',
			SP8.P8_CC AS 'CC', SP8.P8_MOTIVRG AS 'MOTIVRG', SP8.P8_TURNO AS 'TURNO', SP8.P8_HORA AS 'HORA', 
			SP8.P8_SEMANA AS 'SEMANA', SP8.R_E_C_N_O_ AS 'REG'
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
		BEGINSQL ALIAS cAlias
		SELECT
			SP8.P8_DATA AS 'DATA', SP8.P8_TPMARCA AS 'TPMARCA', SP8.P8_FILIAL AS 'FILIAL', SP8.P8_MAT AS 'MAT',
			SP8.P8_CC AS 'CC', SP8.P8_MOTIVRG AS 'MOTIVRG', SP8.P8_TURNO AS 'TURNO', SP8.P8_HORA AS 'HORA', 
			SP8.P8_SEMANA AS 'SEMANA', SP8.R_E_C_N_O_ AS 'REG'
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

	aFinsSem := GetFinalSemana(cDataIni, cDataFin, cFilFunc, cMatricula)
	aFeriados := GetFeriados(cDataIni, cDataFin, cFilFunc, cMatricula)
	aAbonos := GetAbonos(cDataIni, cDataFin, cFilFunc, cMatricula)

	fAfastaPer( @aAfasta , STOD(cDataIni) , STOD(cDataFin) , ALLTRIM(cFilFunc) , cMatricula)
	aAfastamentos := GetAfastamentos(cFilFunc, aAfasta, cMatricula)

	(cAlias)->(DBGOTOP()) //Volta para o topo da tabela temporaria
	While !(cAlias)->(Eof())
		Aadd(aMarcacoes, {})
		nPos := Len(aMarcacoes)
		cHorasAbonadas := cMotivoAbono := ""
		GetAbono(aAbonos, (cAlias)->DATA, @cHorasAbonadas, @cMotivoAbono)
		aJornada := GetJornada(cFilFunc, cMatricula, (cAlias)->DATA)
		Aadd(aLinha, ConvertData(AllTrim((cAlias)->DATA))) //1-data
		Aadd(aLinha, AllTrim((cAlias)->FILIAL)) //2-filial
		Aadd(aLinha, AllTrim((cAlias)->MAT)) //3-matricula
		Aadd(aLinha, Alltrim(DiaSemana(STOD((cAlias)->DATA)))) //4-dia
		Aadd(aLinha, AllTrim((cAlias)->CC)) //5-centrocusto
		Aadd(aLinha, AllTrim((cAlias)->CC)) //6-ordemClassificacao
		Aadd(aLinha, AllTrim((cAlias)->MOTIVRG)) //7-motivoRegistro
		Aadd(aLinha, aJornada[2]) //8-turno
		Aadd(aLinha, aJornada[3]) //9-seqTurno
		Aadd(aLinha, cHorasAbonadas) //10-abono
		Aadd(aLinha, cMotivoAbono) //11-observacoes
		Aadd(aLinha, AllTrim((cAlias)->TPMARCA)) //12-tipoMarca
		Aadd(aLinha, U_ConvertHora((cAlias)->HORA)) //13-marcacao
		Aadd(aLinha, .F.) //14-diaAbonado
		Aadd(aLinha, U_ConvertHora(0)) //15-Adicional Noturno
		Aadd(aLinha, aJornada[1]) //16-Jornada Prevista

		SR6->(DbSetOrder(1)) //R6_FILIAL + R6_TURNO
		If SR6->(MsSeek(Left(cFilFunc,2)+"  "+(cAlias)->TURNO)) //producao
			// If SR6->(MsSeek(Left(cFilFunc,2)+""+(cAlias)->TURNO)) //Teste
			nIniHNot := SR6->R6_INIHNOT
			nFimHnot := SR6->R6_FIMHNOT
			nMinHrNot := SR6->R6_MINHNOT
		EndIf

		If ((cAlias)->HORA > nIniHNot .OR. (cAlias)->HORA < nFimHnot) .AND. nIniHNot > 0
			aAdicionalNoturno := CalculaAdcNot((cAlias)->HORA, nIniHNot, nFimHnot, nMinHrNot)
			If Len(aAdicionalNoturno) > 0
				aAdd(aDiasAdNot, {ConvertData(AllTrim((cAlias)->DATA)), aAdicionalNoturno[1], aAdicionalNoturno[2]})
			EndIf
		EndIf

		aMarcacoes[nPos] := aLinha
		aLinha := {}
		(cAlias)->(DbSkip())
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
		GetTolerancias(cFilFunc, cMatricula, @nTolAbst, @nTolHoEx, STRTRAN(aMarcacoes[nCont][1],"-",""))
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

			nPosAdNot := aScan(aDiasAdNot,{|x| x[1] == aMarcacoes[nCont][1]})

			cJornadaPrevista := aMarcacoes[nCont][16]
			aDados[nPos]['diaAbonado'] := aMarcacoes[nCont][14]
			If nPosAdNot > 0
				aDados[nPos]['adicNoturno'] := aDiasAdNot[nPosAdNot,2]
			Else
				aDados[nPos]['adicNoturno'] := aMarcacoes[nCont][15]
			EndIf
			nCont++
		EndDo
		cHoras1T := SomaHoras(aDados[nPos]['1E'], aDados[nPos]['1S'])
		cHoras2T := SomaHoras(aDados[nPos]['2E'], aDados[nPos]['2S'])
		cHoras3T := SomaHoras(aDados[nPos]['3E'], aDados[nPos]['3S'])
		cHoras4T := SomaHoras(aDados[nPos]['4E'], aDados[nPos]['4S'])
		cTotalHoras := SomaHoras(cHoras1T, cHoras2T, "S")
		cTotalHoras := SomaHoras(cTotalHoras, cHoras3T, "S") //Soma terceiro turno
		cTotalHoras := SomaHoras(cTotalHoras, cHoras4T, "S") //Soma quarto turno

		If nPosAdNot > 0
			cTotalHoras := SomaHoras(cTotalHoras, aDiasAdNot[nPosAdNot,3], "S")
		EndIf

		aDados[nPos]['jornada'] := cTotalHoras
		aDados[nPos]['horasExtras'] := SomaHoras(cJornadaPrevista, cTotalHoras, "E")
		aDados[nPos]['abstencao'] := SomaHoras(cJornadaPrevista, cTotalHoras, "A")
		aDados[nPos]['jornadaPrevista'] := cJornadaPrevista

	EndDo
	(cAlias)->(DbCloseArea())

	If Len(aDados) == 0
		cResponse['erro'] := 204
		cResponse['message'] := "Nenhuma marca��o de ponto encontrada"
		lRet := .F.
	Else
		cResponse['marcacoes'] := aDados
		cResponse['resumo'] := aResumo
		cResponse['noturnas'] := aDiasAdNot
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

Static Function GetJornada(cFilFunc, cMatricula, cDataMovim)
	Local aRet := {"","",""}
	Local cTurno := ""
	Local cSqTurno := ""
	Local lEhFeriado := .F.

	BEGINSQL ALIAS 'TSPF'
		SELECT TOP 1
			SPF.PF_TURNOPA, SPF.PF_SEQUEPA, SPF.PF_FILIAL
		FROM %Table:SPF% AS SPF
		WHERE
			SPF.%NotDel%
			AND SPF.PF_FILIAL = %exp:cFilFunc%
			AND SPF.PF_MAT = %exp:cMatricula%
			AND SPF.PF_DATA <= %exp:cDataMovim%
			ORDER BY SPF.PF_DATA DESC
	ENDSQL

	If !TSPF->(Eof())
		cTurno := ALLTRIM(TSPF->PF_TURNOPA)
		cSqTurno := ALLTRIM(TSPF->PF_SEQUEPA)
		cDia := cValToChar(DOW(STOD(cDataMovim)))

		lEhFeriado := fEhFeriado(cDataMovim, cFilFunc)
		If lEhFeriado
			aRet := {}
			Aadd(aRet, U_ConvertHora(0)) //1 - Jornada Prevista
			Aadd(aRet, cTurno) //2 - Codigo do Turno
			Aadd(aRet, cSqTurno) //3 - Cod. Sequencia do Turno
		Else
			SPJ->(DbSetOrder(1)) //PJ_FILIAL + PJ_TURNO + PJ_SEMANA + PJ_DIA
			If SPJ->(MsSeek(Left(cFilFunc,2)+"  "+cTurno+cSqTurno+cDia))
				aRet := {}
				Aadd(aRet, U_ConvertHora(SPJ->PJ_HRTOTAL - SPJ->PJ_HRSINT1)) //1 - Jornada Prevista
				Aadd(aRet, cTurno) //2 - Codigo do Turno
				Aadd(aRet, cSqTurno) //3 - Cod. Sequencia do Turno
			EndIf
		EndIf
	Else
		SRA->(DbSetOrder(1))
		If SRA->(MsSeek(cFilFunc+cMatricula))
			cTurno := ALLTRIM(SRA->RA_TNOTRAB)
			cSqTurno := ALLTRIM(SRA->RA_SEQTURN)
			aRet := {}
			Aadd(aRet, U_ConvertHora(0)) //1 - Jornada Prevista
			Aadd(aRet, cTurno) //2 - Codigo do Turno
			Aadd(aRet, cSqTurno) //3 - Cod. Sequencia do Turno
		EndIf
	EndIf
	TSPF->(DbCloseArea())
Return aRet

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
			SPC.PC_DATA, SPC.PC_PD, SPC.PC_QUANTC, SPC.PC_QUANTI, SPC.PC_QTABONO
		FROM %Table:SPC% AS SPC
		WHERE
			SPC.%NotDel%
			AND SPC.PC_FILIAL = %exp:cFilFunc%
			AND SPC.PC_DATA BETWEEN %exp:cDataIni% AND %exp:cDataFin%
			AND SPC.PC_MAT = %exp:cMatricula%
			ORDER BY SPC.PC_DATA, SPC.PC_PD
	ENDSQL

	While !TSPC->(Eof())
		If (TSPC->PC_QUANTC - TSPC->PC_QTABONO) > 0
			Aadd(aDados, {TSPC->PC_PD, U_HTOM(U_ConVertHora(TSPC->PC_QUANTC - TSPC->PC_QTABONO)), U_HTOM(U_ConvertHora(TSPC->PC_QUANTI))})
		EndIf
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

Static Function GetFinalSemana(cDataIni, cDataFin, cFilFunc, cMatricula)
	Local aDias := {}
	Local dInicial := STOD(cDataIni)
	Local dFinal := STOD(cDataFin)
	Local aArea := GetArea()
	Local aAreaSP8 := SP8->(GetArea())
	Local cJornadaPrevista := ""
	Local aJornada := {}
	Local cTurno := ""
	Local cSqTurno := ""

	SPJ->(DbSetOrder(1)) //PJ_FILIAL + PJ_TURNO + PJ_SEMANA + PJ_DIA
	While dInicial <= dFinal
		SP3->(DbSetOrder(1))
		If !SP3->(MsSeek(cFilFunc+DTOS(dInicial)))
			aJornada := GetJornada(cFilFunc, cMatricula, DTOS(dInicial))
			cJornadaPrevista := aJornada[1]
			cTurno := aJornada[2]
			cSqTurno := aJornada[3]
			If DOW(dInicial) == 7
				If SPJ->(MsSeek(Left(cFilFunc,2)+"  "+cTurno+cSqTurno+"7"))
					SP8->(DbSetOrder(2))
					If !SP8->(MsSeek(cFilFunc+cMatricula+DTOS(dInicial))) .AND. SPJ->PJ_TPDIA == 'C'
						Aadd(aDias, {ConvertData(DTOS(dInicial)),"","",ALLTRIM(DiaSemana(dInicial)),"","","",cTurno,cSqTurno,"","** Compensado **","","",.F.,U_ConvertHora(0),cJornadaPrevista})
					EndIf
				EndIf
			EndIf
			If DOW(dInicial) == 1
				If SPJ->(MsSeek(Left(cFilFunc,2)+"  "+cTurno+cSqTurno+"1"))
					SP8->(DbSetOrder(2))
					If !SP8->(MsSeek(cFilFunc+cMatricula+DTOS(dInicial))) .AND. SPJ->PJ_TPDIA == 'D'
						aJornada := GetJornada(cFilFunc, cMatricula, DTOS(dInicial))
						cJornadaPrevista := aJornada[1]
						cTurno := aJornada[2]
						cSqTurno := aJornada[3]
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

Static Function GetFeriados(cDataIni, cDataFin, cFilFunc, cMatricula)
	Local aFeriados := {}
	Local aJornada := {}
	Local cJornadaPrevista := ""
	Local cTurno := cSqTurno := ""

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
			aJornada := GetJornada(cFilFunc, cMatricula, TSP3->DATA)
			cJornadaPrevista := aJornada[1]
			cTurno := aJornada[2]
			cSqTurno := aJornada[3]
			Aadd(aFeriados, {ConvertData(cAno+cMesDia),"","",ALLTRIM(DiaSemana(STOD(TSP3->DATA))),"","","",cTurno,cSqTurno,"",ALLTRIM(TSP3->DESC),"","",.F.,U_ConvertHora(0),cJornadaPrevista})
		Else
			aJornada := GetJornada(cFilFunc, cMatricula, TSP3->DATA)
			cJornadaPrevista := aJornada[1]
			cTurno := aJornada[2]
			cSqTurno := aJornada[3]
			Aadd(aFeriados, {ConvertData(TSP3->DATA),"","",ALLTRIM(DiaSemana(STOD(TSP3->DATA))),"","","",cTurno,cSqTurno,"",ALLTRIM(TSP3->DESC),"","",.F.,U_ConvertHora(0),cJornadaPrevista})
		EndIf
		TSP3->(DbSkip())
	EndDo

	TSP3->(DbCloseArea())

Return aFeriados

Static Function GetAbonos(cDataIni, cDataFim, cFilFunc, cMatricula)
	Local aRet := {}
	Local cJornadaPrevista := ""
	Local aJornada := {}
	Local cTurno := ""
	Local cSqTurno := ""

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
			aJornada := GetJornada(cFilFunc, cMatricula, TSPK->PK_DATA)
			cJornadaPrevista := aJornada[1]
			cTurno := aJornada[2]
			cSqTurno := aJornada[3]
			Aadd(aRet, {ConvertData(TSPK->PK_DATA),"","",ALLTRIM(DiaSemana(STOD(TSPK->PK_DATA))),"","","",cTurno,cSqTurno, U_ConvertHoras(TSPK->PK_HRSABO),ALLTRIM(TSPK->P6_DESC),"","",.T.,U_ConvertHora(0),cJornadaPrevista})
		EndIf

		TSPK->(DbSkip())
	EndDo
	TSPK->(DbCloseArea())

Return aRet

Static Function GetTolerancias(cFilFunc, cMatricula, nTolAbst, nTolHoEx, cDataMovim)
	Local aArea := GetArea()
	Local aAreaSPA := SPA->(GetArea())
	Local aAreaSRA := SRA->(GetArea())


	BEGINSQL ALIAS 'TSPFA'
		SELECT TOP 1
			SPF.PF_TURNOPA, SPF.PF_SEQUEPA, SPF.PF_FILIAL, SPF.PF_REGRAPA
		FROM %Table:SPF% AS SPF
		WHERE
			SPF.%NotDel%
			AND SPF.PF_FILIAL = %exp:cFilFunc%
			AND SPF.PF_MAT = %exp:cMatricula%
			AND SPF.PF_DATA <= %exp:cDataMovim%
			ORDER BY SPF.PF_DATA DESC
	ENDSQL

	If !TSPFA->(Eof())
		SPA->(DbSetOrder(1))
		If SPA->(MsSeek(xFilial("SPA")+TSPFA->PF_REGRAPA))
			nTolAbst := SPA->PA_TOLFALT
			nTolHoEx := SPA->PA_TOLHEPE
		EndIf
	Else
		SRA->(DbSetOrder(1))
		If SRA->(MsSeek(cFilFunc+cMatricula))
			SPA->(DbSetOrder(1))
			If SPA->(MsSeek(xFilial("SPA")+SRA->RA_REGRA))
				nTolAbst := SPA->PA_TOLFALT
				nTolHoEx := SPA->PA_TOLHEPE
			EndIf
		EndIf
	EndIf

	TSPFA->(DbCloseArea())
	SRA->(RestArea(aAreaSRA))
	SPA->(RestArea(aAreaSPA))
	RestArea(aArea)
Return

Static Function GetAfastamentos(cFilFunc, aAfasta, cMatricula)
	Local aArea := GetArea()
	Local aAreaRCM := RCM->(GetArea())
	Local nCont := 0
	Local aAfastamentos := {}
	Local dInicial := STOD("")
	Local dFinal := STOD("")
	Local cTpAfast := ""
	Local cObservacoes := ""
	Local cJornadaPrevista := ""
	Local cTurno := ""
	Local cSqTurno := ""
	Local aJornada := {}

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
				aJornada := GetJornada(cFilFunc, cMatricula, DTOS(dInicial))
				cJornadaPrevista := aJornada[1]
				cTurno := aJornada[2]
				cSqTurno := aJornada[3]
				Aadd(aAfastamentos, {ConvertData(DTOS(dInicial)),"","",ALLTRIM(DiaSemana(dInicial)),"","","",cTurno,cSqTurno,"",cObservacoes,"","",.T.,U_ConvertHora(0),cJornadaPrevista})
				dInicial := DaySum(dInicial, 1)
			EndDo
		EndIf
	Next

	RCM->(RestArea(aAreaRCM))
	RestArea(aArea)
Return aAfastamentos

Static Function fEhFeriado(cDataMovim, cFilFunc)
	Local lRet := .F.

	BEGINSQL ALIAS 'TSP3A'
		SELECT
			SP3.P3_DATA AS 'DATA', SP3.P3_DESC AS 'DESC', SP3.P3_FIXO AS 'FIXO', SP3.P3_MESDIA
		FROM %Table:SP3% AS SP3
		WHERE
			SP3.%NotDel%
			AND (SP3.P3_DATA = %exp:cDataMovim% OR SP3.P3_MESDIA = %exp:RIGHT(cDataMovim,4)%)
			AND SP3.P3_FILIAL = %exp:cFilFunc%
	ENDSQL

	If !TSP3A->(Eof())
		lRet := .T.
	EndIf
	TSP3A->(DbCloseArea())

Return lRet


Static Function CalculaAdcNot(nHora, nIniNot, nFimNot, nMinNot)
	Local aAdicionalNoturno := {}
	Local nHoraM := U_HTOM(U_ConVertHora(nHora)) //transforma hora em minutos
	Local nIniNotM := U_HTOM(U_ConVertHora(nIniNot)) //transforma hora em minutos
	Local nCalculado := nHoraM - nIniNotM
	Local nReal := U_MTOH(nCalculado)
	Local nDiff := 0

	nCalculado := Round(nCalculado / nMinNot * 60,0) //Calcula novo valor baseado no adicional noturno
	nCalculado := U_MTOH(nCalculado) //transforma minutos em horas

	nDiff := nCalculado - nReal
	aAdd(aAdicionalNoturno, U_ConVertHora(nCalculado))
	aAdd(aAdicionalNoturno, U_ConVertHora(nDiff))

Return aAdicionalNoturno

Static Function AnalisarPeriodo(cFilFunc, cMatricula, cDataIni, cDataFin)
	Local cAlias := GetNextAlias()
	Local aMeses := {}
	Local nPosMes := 0
	Local nCont := 0
	Local nAnoMesIni := 0
	Local nAnoMesFim := 0
	Local dDia := STOD("")

	If cDataIni == '19000101'
		If MONTH(Date()) == 1
			nMes := 12
		Else
			nMes := MONTH(Date())-1
		EndIf

		BEGINSQL ALIAS cAlias
		SELECT
			SPG.PG_DATA AS 'DATA', SPG.PG_TPMARCA AS 'TPMARCA', SPG.PG_FILIAL AS 'FILIAL', SPG.PG_MAT AS 'MAT',
			SPG.PG_CC AS 'CC', SPG.PG_MOTIVRG AS 'MOTIVRG', SPG.PG_TURNO AS 'TURNO', SPG.PG_HORA AS 'HORA', 
			SPG.PG_SEMANA AS 'SEMANA', SPG.R_E_C_N_O_ AS 'REG', 
			MONTH(SPG.PG_DATA) AS 'MES', YEAR(SPG.PG_DATA) AS 'ANO'
		FROM %Table:SPG% AS SPG
		WHERE
			SPG.%NotDel%
			AND SPG.PG_FILIAL = %exp:cFilFunc%
			AND SPG.PG_MAT = %exp:cMatricula%
			AND MONTH(SPG.PG_DATA) = %exp:nMes%
			AND SPG.PG_TPMCREP != 'D'
			ORDER BY SPG.PG_DATA
		ENDSQL
	Else
		BEGINSQL ALIAS cAlias
		SELECT
			SPG.PG_DATA AS 'DATA', SPG.PG_TPMARCA AS 'TPMARCA', SPG.PG_FILIAL AS 'FILIAL', SPG.PG_MAT AS 'MAT',
			SPG.PG_CC AS 'CC', SPG.PG_MOTIVRG AS 'MOTIVRG', SPG.PG_TURNO AS 'TURNO', SPG.PG_HORA AS 'HORA', 
			SPG.PG_SEMANA AS 'SEMANA', SPG.R_E_C_N_O_ AS 'REG', 
			MONTH(SPG.PG_DATA) AS 'MES', YEAR(SPG.PG_DATA) AS 'ANO'
		FROM %Table:SPG% AS SPG
		WHERE
			SPG.%NotDel%
			AND SPG.PG_FILIAL = %exp:cFilFunc%
			AND SPG.PG_MAT = %exp:cMatricula%
			AND SPG.PG_DATA BETWEEN %exp:cDataIni% AND %exp:cDataFin%
			AND SPG.PG_TPMCREP != 'D'
			ORDER BY SPG.PG_DATA
		ENDSQL
	EndIf

	While !(cAlias)->(Eof())
		nAnoMes :=  Val(StrZero((cAlias)->ANO,4) + StrZero((cAlias)->MES,2))
		If Len(aMeses) == 0
			dDia := STOD((cAlias)->(DATA))
			aAdd(aMeses, {nAnoMes, .T., Firstdate(dDia), Lastdate(dDia)}) //Numero do Mes e Flag de periodo fechado
		Else
			nPosMes := aScan(aMeses,{|x| x[1] == nAnoMes})
			dDia := STOD((cAlias)->(DATA))
			If Empty(nPosMes)
				aAdd(aMeses, {nAnoMes, .T., Firstdate(dDia), Lastdate(dDia)})
			EndIf
		EndIf
		(cAlias)->(DbSkip())
	EndDo
	(cAlias)->(DbCloseArea())

	nAnoMesIni := Val(Left(cDataIni,6))
	nAnoMesFim := Val(Left(cDataFin,6))

	For nCont := nAnoMesIni to nAnoMesFim
		nPosMes := aScan(aMeses,{|x| x[1] == nCont })
		If Empty(nPosMes)
			dDia := STOD(cValToChar(nCont)+"01")
			aAdd(aMeses, {nCont, .F., Firstdate(dDia), Lastdate(dDia)})
		EndIf
		If Right(StrZero(nCont,6),2) == '12'
			nCont := nCont + 89
		EndIf
	Next nCont

Return
