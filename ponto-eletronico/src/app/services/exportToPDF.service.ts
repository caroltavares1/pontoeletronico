import { Injectable } from '@angular/core';
const pdfMake = require('pdfmake/build/pdfmake.js');
const pdfFonts = require("pdfmake/build/vfs_fonts");
(pdfMake as any).vfs = pdfFonts.pdfMake.vfs;

@Injectable({
  providedIn: 'root'
})
export class ExportToPDFService {

  cabecalho = {}

  constructor() { }

  setHeader(header: any) {
    this.cabecalho = header
  }

  getHeader() {
    return this.cabecalho
  }

  public openPDF(items: any[], bh: any[], turno: any[], resumos: any[], start: string, end: string): void {
    let header: any = {}
    header = this.getHeader()

    let marcacoes = structuredClone(items) //Cria uma copia por valor e não por referência
    let columns = [
      'Data', 'Dia', '1ª Entrada', '1ª Saída', '2ª Entrada', '2ª Saída',
      'Abono  ', 'Horas Extras', 'Absent.', 'Jornada', 'Observação']
    let propM = ['data', 'dia', '1E', '1S', '2E', '2S', 'abono', 'horasExtras', 'abstencao', 'jornada', 'observacoes']

    let horas = structuredClone(bh)
    let horasCol = [
      'Saldo Anterior', 'Débitos', 'Créditos', 'Saldo Atual'
    ]
    let horasProp = ['saldoAnterior', 'totalDebitos', 'totalCreditos', 'saldoAtual']

    let turnos = structuredClone(turno)
    let turnosCol = ['Dia', '1ª Entrada', '1ª Saída', '2ª Entrada', '2ª Saída', 'Turno']
    let turnosProp = ['dia', '1E', '1S', '2E', '2S', 'turno']

    let resumo = structuredClone(resumos)
    let resumoCol = ['Código', 'Descrição', 'Total de Horas']
    let resumoProp = ['codEvento', 'descEvento', 'totalHoras']



    var dd = {
      pageMargins: [40, 150, 40, 60],
      pageSize: 'A4',
      pageOrientation: "landscape",
      //header: `Espelho do Ponto ${this.start} - ${this.end}`,
      header: {
        stack: [
          { text: `Espelho do Ponto ${start} - ${end}`, margin: [260, 5, 0, 5] },
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
        margin: [40, 5, 2, 5]
      },
      footer: [
        {
          text: '**Espelho de ponto apenas para consulta. O original será entregue pelo RH no fechamento mensal.',
          margin: [240, 5, 0, 5], fontSize: 9
        },

      ],
      content: [
        this.table(marcacoes, columns, propM),
        { canvas: [{ type: 'line', x1: 15, y1: 15, x2: 732, y2: 15, lineWidth: 1, }] },
        { text: 'Banco de Horas', margin: [15, 5, 5, 0] },
        this.tableBH(horas, horasCol, horasProp),
        { canvas: [{ type: 'line', x1: 15, y1: 15, x2: 732, y2: 15, lineWidth: 1, }] },
        { text: 'Horários', margin: [15, 5, 5, 0] },
        this.tableTurno(turnos, turnosCol, turnosProp),
        { canvas: [{ type: 'line', x1: 15, y1: 15, x2: 732, y2: 15, lineWidth: 1, }] },
        { text: '', margin: [15, 10, 5, 0] },
        this.tableResumo(resumo, resumoCol, resumoProp),
      ],
      styles: {
        header: {
          margin: 'auto',
          alignment: 'center',
          bold: true
        },
      }
    }

    pdfMake.createPdf(dd).download("espelho-ponto.pdf");
  }

  public buildTableBody(data: any[], columns: any[], col: any[], flag?: boolean, ausente: boolean = false) {
    let body = [];

    body.push(columns);

    data.forEach((row: any) => {
      let dataRow: any = [];

      if (ausente) {
        dataRow.push(row['data'].toString())
        dataRow.push(row['dia'].toString())

        dataRow.push({ text: '** Ausente **', colSpan: 4, alignment: 'center' })
        dataRow.push('')
        dataRow.push('')
        dataRow.push('')

        dataRow.push(row['abono'].toString())
        dataRow.push(row['horasExtras'].toString())
        dataRow.push(row['abstencao'].toString())
        dataRow.push(row['jornada'].toString())
        dataRow.push(row['observacoes'].toString())

        body.push(dataRow);
      } else {

        col.forEach((column: any) => {
          let rc
          if (row[column] == '00:00:00' /* && flag == true */) {
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
      margin: [15, 20, 0, 0],
      //layout: 'lightHorizontalLines',
      color: '#444',
      fontSize: 10, bold: false,
      alignment: 'center',
      //styles: 'table',
      table: {
        headerRows: 1,
        widths: [60, 50, 50, 50, 50, 50, 50, 60, 50, 50, 100,],
        body: this.buildTableBody(data, columns, col, true),

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
      margin: [15, 2, 0, 0],
      //layout: 'lightHorizontalLines',
      color: '#444',
      fontSize: 10, bold: false,
      alignment: 'center',
      //styles: 'table',
      table: {
        headerRows: 1,
        widths: [170, 170, 170, 172],
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
      margin: [15, 2, 0, 0],
      //layout: 'lightHorizontalLines',
      color: '#444',
      fontSize: 10, bold: false,
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
      margin: [15, 2, 0, 0],
      //layout: 'lightHorizontalLines',
      color: '#444',
      fontSize: 10, bold: false,
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
