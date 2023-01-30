#INCLUDE 'TOTVS.CH'
#INCLUDE 'RESTFUL.CH'

WSRESTFUL bh DESCRIPTION 'Consulta do Banco de Horas'
	Self:SetHeader('Access-Control-Allow-Credentials' , "true")

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
	Local aDados := {}
	Local lSaldoNeg := .F.
	Local lCalcBH := .F.

	If nPosMatricula > 0 .AND. nPosFilial > 0 .AND. nPosDtIni > 0 .AND. nPosDtFin > 0
		cFilAtuacao := aParams[nPosFilial,2]
		cMatricula := aParams[nPosMatricula,2]
		cDtInicial := aParams[nPosDtIni,2]
		cDtFinal := aParams[nPosDtFin,2]
	EndIf

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
			nSomaCreditos += HTOM(U_ConvertHora(TSPI->PI_QUANT))
		EndIf
		If Val(TSPI->P9_TIPOCOD) == 2
			nSomaDebitos += HTOM(U_ConvertHora(TSPI->PI_QUANT))
		EndIf
		TSPI->(DbSkip())
	EndDo

	lCalcBH := CalculaBH(cFilAtuacao, cMatricula)
	GetSaldoAnterior(@nSaldoAnterior, cFilAtuacao, cMatricula, cDtInicial, @lSaldoNeg)

	Aadd(aDados, JsonObject():new())
	nPos := Len(aDados)
	nSaldoAnterior := HTOM(U_ConvertHora(nSaldoAnterior))
	
	If lSaldoNeg //Se o saldo de horas anterior for negativo, entao ele é tratado como debito
		nSaldoAtual := nSomaCreditos - nSaldoAnterior - nSomaDebitos
		nSaldoAnterior *= -1 //Uma vez efetuado os calculos o valor é definido como negativo novamente
	Else
		nSaldoAtual := nSaldoAnterior + nSomaCreditos - nSomaDebitos
	EndIf
	aDados[nPos]['saldoAnterior'] := U_ConvertHora(MTOH(nSaldoAnterior))
	aDados[nPos]['totalDebitos'] := U_ConvertHora(MTOH(nSomaDebitos))
	aDados[nPos]['totalCreditos'] := U_ConvertHora(MTOH(nSomaCreditos))
	aDados[nPos]['saldoAtual'] := U_ConvertHora(MTOH(nSaldoAtual))
	aDados[nPos]['consideraBH'] := lCalcBH

	TSPI->(DbCloseArea())

	If Len(aDados) == 0
		cResponse['code'] := 204
		cResponse['message'] := 'Banco de Horas não encontrado para esse funcionario'
		lRet := .F.
	Else
		cResponse['bh'] := aDados
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
			nSomaCreditos += HTOM(U_ConvertHora(TMP->PI_QUANT))
		EndIf
		If Val(TMP->P9_TIPOCOD) == 2
			nSomaDebitos += HTOM(U_ConvertHora(TMP->PI_QUANT))
		EndIf
		TMP->(DbSkip())
	EndDo

	nSaldoAnterior := MTOH(nSomaCreditos - nSomaDebitos)
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
