import { Injectable } from '@angular/core';
const pdfMake = require('pdfmake/build/pdfmake.js');
const pdfFonts = require("pdfmake/build/vfs_fonts");
(pdfMake as any).vfs = pdfFonts.pdfMake.vfs;

@Injectable({
  providedIn: 'root'
})
export class ExportToPDFService {

  columns = [
    'Data', 'Dia', '1ª Entrada', '1ª Saída', '2ª Entrada', '2ª Saída',
    '3ª Entrada', '3ª Saída', '4ª Entrada', '4ª Saída',
    'Abono  ', 'Horas Extras', 'Absent.', 'Jornada', 'Ad. Not.', 'Observação']
  propM = ['data', 'dia', '1E', '1S', '2E', '2S', '3E', '3S', '4E', '4S',
    'abono', 'horasExtras', 'abstencao', 'jornada', 'adicNoturno', 'observacoes']

  horasCol = [
    'Saldo Anterior', 'Débitos', 'Créditos', 'Saldo Atual'
  ]
  horasProp = ['saldoAnterior', 'totalDebitos', 'totalCreditos', 'saldoAtual']

  turnosCol = ['Dia', '1ª Entrada', '1ª Saída', '2ª Entrada', '2ª Saída', 'Turno']
  turnosProp = ['dia', '1E', '1S', '2E', '2S', 'turno']

  resumoCol = ['Código', 'Descrição', 'Total de Horas']
  resumoProp = ['codEvento', 'descEvento', 'totalHoras']

  s = ''
  e = ''

  cabecalho = {}

  constructor() { }

  setHeader(header: any) {
    this.cabecalho = header
  }

  getHeader() {
    return this.cabecalho
  }

  public openPDF(items: any[], bh: any[], turno: any[], resumos: any[], start: string, end: string, consideraBH: boolean): void {
    let header: any = {}
    header = this.getHeader()
    this.s = start
    this.e = end

    let marcacoes = structuredClone(items) //Cria uma copia por valor e não por referência

    let horas = structuredClone(bh)

    let turnos = structuredClone(turno)

    let resumo = structuredClone(resumos)

    var dd = {
      pageMargins: [40, 120, 40, 60],
      pageSize: 'A4',
      pageOrientation: "landscape",
      /*       header:
            {
              stack: [
                { text: `Espelho do Ponto ${this.s} - ${this.e}`, margin: [260, 5, 0, 5] },
                {
                  columns: [
                    { text: `Empresa: ${header.empresa}`, margin: [15, 2, 5, 1] },
                    { text: `CNPJ: ${header.cnpj}`, margin: [15, 2, 5, 1] },
                  ]
                },
                {
                  columns: [
                    { text: `Endereço: ${header.endereco}`, margin: [15, 2, 5, 5] },
                    { text: `Emissão: ${header.emissao}`, margin: [15, 2, 5, 5] },
                  ]
                },
                { canvas: [{ type: 'line', x1: 15, y1: 0, x2: 732, y2: 0, lineWidth: 1 }] },
                {
                  columns: [
                    { text: `Matrícula: ${header.matricula}`, margin: [15, 5, 5, 5] },
                    { text: `Nome: ${header.nome}`, margin: [15, 5, 5, 5] },
                    { text: `Admissão: ${header.admissao}`, margin: [15, 5, 5, 5] },
                  ]
                },
                {
                  columns: [
                    { text: `Função: ${header.funcao}`, margin: [15, 2, 5, 1] },
                    { text: `C.C: ${header.cc}`, margin: [15, 2, 5, 1] },
                    { text: `CPF: ${header.cpf}`, margin: [15, 2, 5, 1] },
                  ]
                },
                {
                  columns: [
                    { text: `Categoria: ${header.categoria}`, margin: [15, 2, 5, 5] },
                    { text: `Situação: ${header.situacao}`, margin: [15, 2, 5, 5] },
                    { text: `Departamento: ${header.departamento}`, margin: [15, 2, 5, 5] },
                  ]
      
                },
                { canvas: [{ type: 'line', x1: 15, y1: 0, x2: 732, y2: 0, lineWidth: 1, }] },
              ],
              margin: [40, 5, 2, 2], fontSize: 8
            }, */
      header: function (currentPage: any, pageCount: any, pageSize: any): any {
        // you can apply any logic and return any valid pdfmake element
        let s = start
        if ((pageCount / 2) < currentPage) {
          s = '2023-02-05'
        }
        console.log(currentPage, pageCount, pageSize)
        return {
          stack: [
            { text: `Espelho do Ponto ${s} - ${end}`, margin: [260, 5, 0, 5] },
            {
              columns: [
                { text: `Empresa: ${header.empresa}`, margin: [15, 2, 5, 1] },
                { text: `CNPJ: ${header.cnpj}`, margin: [15, 2, 5, 1] },
              ]
            },
            {
              columns: [
                { text: `Endereço: ${header.endereco}`, margin: [15, 2, 5, 5] },
                { text: `Emissão: ${header.emissao}`, margin: [15, 2, 5, 5] },
              ]
            },
            { canvas: [{ type: 'line', x1: 15, y1: 0, x2: 732, y2: 0, lineWidth: 1 }] },
            {
              columns: [
                { text: `Matrícula: ${header.matricula}`, margin: [15, 5, 5, 5] },
                { text: `Nome: ${header.nome}`, margin: [15, 5, 5, 5] },
                { text: `Admissão: ${header.admissao}`, margin: [15, 5, 5, 5] },
              ]
            },
            {
              columns: [
                { text: `Função: ${header.funcao}`, margin: [15, 2, 5, 1] },
                { text: `C.C: ${header.cc}`, margin: [15, 2, 5, 1] },
                { text: `CPF: ${header.cpf}`, margin: [15, 2, 5, 1] },
              ]
            },
            {
              columns: [
                { text: `Categoria: ${header.categoria}`, margin: [15, 2, 5, 5] },
                { text: `Situação: ${header.situacao}`, margin: [15, 2, 5, 5] },
                { text: `Departamento: ${header.departamento}`, margin: [15, 2, 5, 5] },
              ]

            },
            { canvas: [{ type: 'line', x1: 15, y1: 0, x2: 732, y2: 0, lineWidth: 1, }] },
          ],
          margin: [40, 5, 2, 2], fontSize: 8
        }
      },
      footer: [
        {
          text: '**Espelho de ponto apenas para consulta. O original será entregue pelo RH no fechamento mensal.',
          margin: [240, 5, 0, 5], fontSize: 7
        },

      ],
      content: this.content(marcacoes, horas, turnos, resumo, consideraBH),
      pageBreakBefore: function (
        currentNode: any,
        followingNodesOnPage: any,
        nodesOnNextPage: any,
        previousNodesOnPage: any) {
        //Break para não separar a tabela e o texto acima dela
        return (currentNode.id === 'BREAK' || currentNode.id === 'BREAK2') && followingNodesOnPage.length === 29;
      }

    }
    pdfMake.createPdf(dd).download("espelho-ponto.pdf");
  }

  public content(marcacoes: any[], horas: any[], turnos: any[], resumo: any[], consideraBH: boolean) {
    let i = 0
    let contentList = []
    while (i < 2) {
      contentList.push(this.table(marcacoes, this.columns, this.propM))
      contentList.push({ canvas: [{ type: 'line', x1: 15, y1: 15, x2: 732, y2: 15, lineWidth: 1, }] })
      contentList.push((consideraBH) ? ({ text: 'Banco de Horas', margin: [15, 5, 5, 0], fontSize: 10, id: 'BREAK' + String(i) }) : { text: '', margin: [15, 5, 5, 0] })
      contentList.push((consideraBH) ? this.tableBH(horas, this.horasCol, this.horasProp) : { text: '', margin: [15, 5, 5, 0] })
      contentList.push((consideraBH) ? { canvas: [{ type: 'line', x1: 15, y1: 15, x2: 732, y2: 15, lineWidth: 1, }] } : { text: '', margin: [15, 5, 5, 0] })
      contentList.push({ text: 'Horários', margin: [15, 5, 5, 0], fontSize: 10, id: 'BR' + String(i + 1) })
      contentList.push(this.tableTurno(turnos, this.turnosCol, this.turnosProp))
      contentList.push({ canvas: [{ type: 'line', x1: 15, y1: 15, x2: 732, y2: 15, lineWidth: 1, }] })
      contentList.push({ text: '', margin: [15, 10, 5, 0] })
      contentList.push(this.tableResumo(resumo, this.resumoCol, this.resumoProp))
      contentList.push({ text: '', pageBreak: 'after' })

      this.s = '2023-02-05'

      i++
    }
    contentList.pop()

    return contentList
  }

  public buildTableBody(data: any[], columns: any[], col: any[], flag?: boolean, ausente: boolean = false) {
    let body = [];

    let cols = structuredClone(columns)
    body.push(cols);


    data.forEach((row: any) => {
      let dataRow: any = [];
      if (ausente && row['diaAbonado'] == true) {
        dataRow.push(row['data'].toString())
        dataRow.push(row['dia'].toString())

        dataRow.push({ text: '** Ausente **', colSpan: 8, alignment: 'center' })
        dataRow.push('')
        dataRow.push('')
        dataRow.push('')
        dataRow.push('')
        dataRow.push('')
        dataRow.push('')
        dataRow.push('')

        dataRow.push(row['abono'].toString())
        dataRow.push('')
        dataRow.push(row['abstencao'].toString())
        dataRow.push('')
        dataRow.push('')
        dataRow.push(row['observacoes'].toString())

        body.push(dataRow);
      } else if (ausente && row['jornada'] == '00:00') {
        dataRow.push(row['data'].toString())
        dataRow.push(row['dia'].toString())

        dataRow.push({ text: '', colSpan: 8, alignment: 'center' })
        dataRow.push('')
        dataRow.push('')
        dataRow.push('')
        dataRow.push('')
        dataRow.push('')
        dataRow.push('')
        dataRow.push('')

        dataRow.push('')
        dataRow.push('')
        dataRow.push('')
        dataRow.push('')
        dataRow.push('')
        dataRow.push(row['observacoes'].toString())

        body.push(dataRow);

      } else {

        col.forEach((column: any) => {
          let rc
          if (row[column] == '00:00' /* && flag == true */) {
            row[column] = ''
          }
          (row[column] == null) ? rc = '' : rc = row[column].toString()
          dataRow.push(rc);
        })
        body.push(dataRow);
      }
    });
    return body;
  }

  public table(data: any[], columns: any[], col: any[]) {
    return {
      margin: [15, 5, 0, 5],
      //layout: 'lightHorizontalLines',
      color: '#444',
      fontSize: 7, bold: false,
      alignment: 'center',
      //styles: 'table',
      table: {
        headerRows: 1,
        widths: ['auto', 'auto', 'auto', 'auto', 'auto', 'auto', 'auto', 'auto', 'auto', 'auto', 'auto', 'auto', 'auto', 'auto', 'auto', 137],
        body: this.buildTableBody(data, columns, col, true, true),

      },
      layout: {
        fillColor: function (i: any, node: any) {
          return (i % 2 === 0) ? '#e5e5e5' : null;
        }
      }
    };

  }
  public tableBH(data: any[], columns: any[], col: any[]) {
    return {
      margin: [15, 2, 0, 5],
      //layout: 'ligtHorizontalLines',
      color: '#444',
      fontSize: 7, bold: false,
      alignment: 'center',
      //styles: 'table',
      table: {
        headerRows: 1,
        widths: [170, 170, 170, 170],
        body: this.buildTableBody(data, columns, col, false),
      },
      layout: {
        fillColor: function (i: any, node: any) {
          return (i % 2 === 0) ? '#e5e5e5' : null;
        }
      }
    };

  }

  public tableTurno(data: any[], columns: any[], col: any[]) {
    return {
      margin: [15, 2, 0, 5],
      //layout: 'lightHorizontalLines',
      color: '#444',
      fontSize: 7, bold: false,
      alignment: 'center',
      //styles: 'table',
      table: {
        headerRows: 1,
        widths: [80, 80, 80, 80, 80, 262],
        body: this.buildTableBody(data, columns, col, false),
      },
      layout: {
        fillColor: function (i: any, node: any) {
          return (i % 2 === 0) ? '#e5e5e5' : null;
        }
      }
    };

  }

  public tableResumo(data: any[], columns: any[], col: any[]) {
    return {
      margin: [15, 2, 0, 5],
      //layout: 'lightHorizontalLines',
      color: '#444',
      fontSize: 7, bold: false,
      alignment: 'center',
      //styles: 'table',
      table: {
        headerRows: 1,
        widths: [80, 400, 210],
        body: this.buildTableBody(data, columns, col, false),
      },
      layout: {
        fillColor: function (i: any, node: any) {
          return (i % 2 === 0) ? '#e5e5e5' : null;
        }
      }
    };

  }
}
