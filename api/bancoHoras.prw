#INCLUDE 'TOTVS.CH'
#INCLUDE 'RESTFUL.CH'

WSRESTFUL bh DESCRIPTION 'Consulta do Banco de Horas'
	// Self:SetHeader('Access-Control-Allow-Credentials' , "true") - Saulo Maciel - 08/05/2023

	//Criação dos Metodos
	WSMETHOD GET DESCRIPTION 'Buscar banco de horas pelo funcionario' WSSYNTAX '/bh/' PATH '/bh/'

END WSRESTFUL

WSMETHOD GET WSSERVICE bh
	// http://localhost:8090/rest/bh/?FILIAL=01&MATRICULA=000028&DTINICIAL=20221001&DTFINAL=20221031
	// http://192.168.41.60:8090/rest/bh/?FILIAL=01&MATRICULA=000028&DTINICIAL=20221001&DTFINAL=20221031
	Local cResponse := JsonObject():New()
	Local lRet := .T.
	Local aParams := Self:AQueryString
	Local nPosFilial := aScan(aParams,{|x| x[1] == "FILIAL"})
	Local nPosMatricula := aScan(aParams,{|x| x[1] == "MATRICULA"})
	Local nPosDtIni := aScan(aParams,{|x| x[1] == "DTINICIAL"})
	Local nPosDtFin := aScan(aParams,{|x| x[1] == "DTFINAL"})
	Local cMatricula := cFilAtuacao := cDtInicial := cDtFinal := ""
	Local nSomaCreditos := nSomaDebitos := 0
	Local nSaldoAnterior := 0
	Local nSaldoAtual := 0
	Local nContMeses := 0
	Local aDados := {}
	Local aMeses := {}
	Local aBH := {}
	Local lSaldoNeg := .F.
	Local lCalcBH := .F.

	If nPosMatricula > 0 .AND. nPosFilial > 0 .AND. nPosDtIni > 0 .AND. nPosDtFin > 0
		cFilAtuacao := aParams[nPosFilial,2]
		cMatricula := aParams[nPosMatricula,2]
		cDtInicial := aParams[nPosDtIni,2]
		cDtFinal := aParams[nPosDtFin,2]
	EndIf

	AnalisarPeriodo(cFilAtuacao, cMatricula, cDtInicial, cDtFinal, @aMeses)

	If Len(aMeses) > 0
		For nContMeses := 1 to Len(aMeses)
			aDados := {}
			nSaldoAnterior := nSaldoAtual := nSaldoAtual := nSomaDebitos := nSomaCreditos:= 0
			cDtInicial := aMeses[nContMeses, 3]
			cDtFinal := aMeses[nContMeses, 4]

			BEGINSQL ALIAS 'TSPI'
				SELECT DISTINCT
					SPI.PI_QUANT, SP9.P9_TIPOCOD, SPI.PI_DATA
				FROM %Table:SPI% AS SPI
				INNER JOIN %Table:SP9% AS SP9 ON SPI.PI_PD = SP9.P9_CODIGO
				WHERE
				SPI.%NotDel% AND SP9.%NotDel%
				AND SPI.PI_FILIAL = %exp:cFilAtuacao%
				AND SPI.PI_MAT = %exp:cMatricula%
				AND SPI.PI_DATA BETWEEN %exp:cDtInicial% AND %exp:cDtFinal%
			ENDSQL

			While !TSPI->(Eof())
				If Val(TSPI->P9_TIPOCOD) == 1
					nSomaCreditos += U_HTOM(U_ConvertHora(TSPI->PI_QUANT))
				EndIf
				If Val(TSPI->P9_TIPOCOD) == 2
					nSomaDebitos += U_HTOM(U_ConvertHora(TSPI->PI_QUANT))
				EndIf
				TSPI->(DbSkip())
			EndDo

			lCalcBH := CalculaBH(cFilAtuacao, cMatricula)
			GetSaldoAnterior(@nSaldoAnterior, cFilAtuacao, cMatricula, cDtInicial, @lSaldoNeg)

			Aadd(aDados, JsonObject():new())
			nPos := Len(aDados)
			nSaldoAnterior := U_HTOM(U_ConvertHora(nSaldoAnterior))

			If lSaldoNeg //Se o saldo de horas anterior for negativo, entao ele é tratado como debito
				nSaldoAtual := nSomaCreditos - nSaldoAnterior - nSomaDebitos
				nSaldoAnterior *= -1 //Uma vez efetuado os calculos o valor é definido como negativo novamente
			Else
				nSaldoAtual := nSaldoAnterior + nSomaCreditos - nSomaDebitos
			EndIf
			aDados[nPos]['saldoAnterior'] := U_ConvertHora(U_MTOH(nSaldoAnterior))
			aDados[nPos]['totalDebitos'] := U_ConvertHora(U_MTOH(nSomaDebitos))
			aDados[nPos]['totalCreditos'] := U_ConvertHora(U_MTOH(nSomaCreditos))
			aDados[nPos]['saldoAtual'] := U_ConvertHora(U_MTOH(nSaldoAtual))
			aDados[nPos]['consideraBH'] := lCalcBH
			aDados[nPos]['anoMes'] := aMeses[nContMeses,1]

			TSPI->(DbCloseArea())
			Aadd(aBH, JsonObject():new())
			nPosBh := Len(aBH)
			aBH[nPosBh]['bh'] := aDados
		Next
	EndIf

	If Len(aBH) == 0
		cResponse['code'] := 204
		cResponse['message'] := 'Banco de Horas não encontrado para esse funcionario'
		lRet := .F.
	Else
		cResponse['bancoHoras'] := aBH
	EndIf

	Self:SetContentType('application/json')
	Self:SetResponse(EncodeUTF8(cResponse:toJson()))
Return lRet

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
		cDia := "Terça"
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
		cDia := "Sábado"
	EndIf
Return cDia

Static Function GetSaldoAnterior(nSaldoAnterior, cFilAtuacao, cMatricula, cDtInicial, lSaldoNeg)
	Local nSomaCreditos := nSomaDebitos := 0

	BEGINSQL ALIAS 'TMP' //Lista todos os registros anteriores a data inicial informada
		SELECT DISTINCT
			SPI.PI_QUANT, SP9.P9_TIPOCOD, SPI.PI_DATA
		FROM %Table:SPI% AS SPI
		INNER JOIN %Table:SP9% AS SP9 ON SPI.PI_PD = SP9.P9_CODIGO
		WHERE
			SPI.%NotDel% AND SP9.%NotDel%
			AND SPI.PI_FILIAL = %exp:cFilAtuacao%
			AND SPI.PI_MAT = %exp:cMatricula%
			AND SPI.PI_DATA < %exp:cDtInicial% 
	ENDSQL

	While !TMP->(Eof()) //soma todos os debitos e creditos
		If Val(TMP->P9_TIPOCOD) == 1
			nSomaCreditos += U_HTOM(U_ConvertHora(TMP->PI_QUANT))
		EndIf
		If Val(TMP->P9_TIPOCOD) == 2
			nSomaDebitos += U_HTOM(U_ConvertHora(TMP->PI_QUANT))
		EndIf
		TMP->(DbSkip())
	EndDo

	nSaldoAnterior := U_MTOH(nSomaCreditos - nSomaDebitos)
	If nSaldoAnterior < 0
		lSaldoNeg := .T.
		nSaldoAnterior *= -1 //Caso o saldo resulte num valor negativo, nesse ponto é transformado em positivo
	EndIf

	TMP->(DbCloseArea())
Return

Static Function CalculaBH(cFilAtuacao, cMatricula)
	Local lCalculaBancoHoras := .F.

	BEGINSQL ALIAS 'TSRA'
		SELECT
			SRA.RA_ACUMBH, SRA.RA_BHFOL
		FROM %Table:SRA% AS SRA
		WHERE
			SRA.%NotDel%
			AND SRA.RA_FILIAL = %exp:cFilAtuacao%
			AND SRA.RA_MAT = %exp:cMatricula%
	ENDSQL

	While !TSRA->(Eof())
		If TSRA->RA_ACUMBH == 'S' .AND. TSRA->RA_BHFOL == 'S'
			lCalculaBancoHoras := .T.
		EndIf
		TSRA->(DbSkip())
	EndDo

	TSRA->(DbCloseArea())
Return lCalculaBancoHoras

Static Function AnalisarPeriodo(cFilFunc, cMatricula, cDataIni, cDataFin, aMeses)
	Local cAlias := GetNextAlias()
	Local nPosMes := 0
	Local dDia := STOD("")
	Local nAnoMes := 0

	BEGINSQL ALIAS cAlias
		SELECT DISTINCT
			SPI.PI_DATA AS 'DATA', YEAR(SPI.PI_DATA) AS 'ANO',
			MONTH(SPI.PI_DATA) AS 'MES'
		FROM %Table:SPI% AS SPI
		INNER JOIN %Table:SP9% AS SP9 ON SPI.PI_PD = SP9.P9_CODIGO
		WHERE
			SPI.%NotDel% AND SP9.%NotDel%
			AND SPI.PI_FILIAL = %exp:cFilFunc%
			AND SPI.PI_MAT = %exp:cMatricula%
			AND SPI.PI_DATA BETWEEN %exp:cDataIni% AND %exp:cDataFin%
	ENDSQL

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

	aSort(aMeses,,,{|x,y| x[1] < y[1]})
Return
