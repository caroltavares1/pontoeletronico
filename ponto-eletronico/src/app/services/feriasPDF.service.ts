import { Injectable } from '@angular/core';
import * as uuid from 'uuid';
const pdfMake = require('pdfmake/build/pdfmake.js');
const pdfFonts = require('pdfmake/build/vfs_fonts');
(pdfMake as any).vfs = pdfFonts.pdfMake.vfs;

@Injectable({
  providedIn: 'root',
})
export class FeriasPDFService {
  cabecalho = {};

  constructor() {}

  setHeader(header: any) {
    this.cabecalho = header;
  }

  getHeader() {
    return this.cabecalho;
  }

  public openPDF(cabecalho: any): void {
    let header: any = {};
    let start = cabecalho.ferias.iniFerias;
    let end = cabecalho.ferias.fimFerias;
    let empresa = cabecalho.empresa;
    let matricula = cabecalho.matricula;

    console.log(cabecalho);

    header = this.getHeader();

    var dd = {
      pageMargins: [40, 120, 40, 60],
      pageSize: 'A4',
      pageOrientation: 'portrait',
      header: (currentPage: any, pageCount: any) => {
        let s, e;

        s = this.fixData(start);
        e = this.fixData(end);

        let stack = {
          stack: [
            {
              style: 'tableExample',
              color: '#444',
              table: {
                widths: ['*', 'auto', 'auto'],
                heights: [30],
                headerRows: 3,
                // keepWithHeaderRows: 1,
                body: [
                  [
                    {
                      text: 'Recibo de Ferias',
                      style: 'tableHeader',
                      colSpan: 3,
                      alignment: 'center',
                      bold: true,
                    },
                    {},
                    {},
                  ],
                  [
                    {
                      text: 'Razao Social',
                      style: 'tableHeader',
                      colSpan: 2,
                      alignment: 'left',
                      bold: true,
                    },
                    {},
                    {
                      text: 'CNPJ',
                      style: 'tableHeader',
                      alignment: 'left',
                      bold: true,
                    },
                  ],
                  [
                    { text: `${empresa.nome}`, colSpan: 2 },
                    '',
                    `${empresa.cgc}`,
                  ],
                  [
                    {
                      text: 'Matricula',
                      style: 'tableHeader',
                      alignment: 'left',
                      bold: true,
                    },
                    {
                      text: 'Nome do Funcionario',
                      style: 'tableHeader',
                      colSpan: 2,
                      alignment: 'left',
                      bold: true,
                    },
                    {},
                  ],
                  [
                    { text: `${matricula.matricula}` },
                    { text: `${matricula.nome}`, colSpan: 2 },
                    {},
                  ],
                ],
              },
            },
          ],
          margin: [10, 5, 2, 2],
          fontSize: 10,
        };

        return stack;
      },

      content: this.content(cabecalho),
    };

    let name = 'ferias_' + uuid.v4() + '.pdf';
    pdfMake.createPdf(dd).download(name);
  }

  content(cabecalho: any) {
    let mat = cabecalho.matricula;
    let func = cabecalho.funcionario;
    let fer = cabecalho.ferias;

    let ret = [
      {
        style: 'tableExample',
        table: {
          widths: ['*', 'auto', 'auto', 'auto', 'auto'],
          body: [
            [
              //Linha Funcao
              {
                text: 'Função',
                style: 'tableHeader',
                alignment: 'left',
                bold: true,
              },
              {
                text: 'Data de Admissão',
                style: 'tableHeader',
                alignment: 'left',
                bold: true,
              },
              {
                text: 'Carteira de Trabalho',
                style: 'tableHeader',
                alignment: 'left',
                bold: true,
              },
              {
                text: 'Serie',
                style: 'tableHeader',
                alignment: 'left',
                bold: true,
              },
              {
                text: 'UF',
                style: 'tableHeader',
                alignment: 'left',
                bold: true,
              },
            ],
            [
              //Linha Funcao
              {
                text: `${mat.matricula}`,
                style: 'tableHeader',
                alignment: 'left',
              },
              {
                text: `${this.fixData(mat.admissao)}`,
                style: 'tableHeader',
                alignment: 'left',
              },
              {
                text: `${99999}`,
                style: 'tableHeader',
                alignment: 'left',
              },
              {
                text: `${99999}`,
                style: 'tableHeader',
                alignment: 'left',
              },
              {
                text: `${'PE'}`,
                style: 'tableHeader',
                alignment: 'left',
                bold: true,
              },
            ],
            [
              //Linha CPF
              {
                text: 'CPF',
                style: 'tableHeader',
                alignment: 'left',
                bold: true,
                colSpan: 2,
              },
              {},
              {
                text: 'Identidade',
                style: 'tableHeader',
                alignment: 'left',
                bold: true,
                colSpan: 2,
              },
              {},
              {
                text: 'Carteira de Trabalho',
                style: 'tableHeader',
                alignment: 'left',
                bold: true,
              },
            ],
            [
              //Linha CPF
              {
                text: `${func.cpf}`,
                style: 'tableHeader',
                alignment: 'left',
                colSpan: 2,
              },
              {},
              {
                text: `${'RG: 999999'}`,
                style: 'tableHeader',
                alignment: 'left',
                colSpan: 2,
              },
              {},
              {
                text: `${'IRRF'}`,
                style: 'tableHeader',
                alignment: 'left',
              },
            ],
            [
              //Linha Vencimento das Ferias
              {
                text: 'Vencimento das Férias',
                style: 'tableHeader',
                alignment: 'left',
                bold: true,
              },
              {
                text: 'Periodo de Gozo de Ferias',
                style: 'tableHeader',
                alignment: 'left',
                bold: true,
                colSpan: 3,
              },
              {},
              {},
              {
                text: 'Abono Pecuniario',
                style: 'tableHeader',
                alignment: 'left',
                bold: true,
              },
            ],
            [
              {
                text: `${this.fixData(fer.fimPerAq)}`,
                style: 'tableHeader',
                alignment: 'left',
                bold: true,
              },
              {
                text: `${cabecalho.periodoGozo}`,
                style: 'tableHeader',
                alignment: 'left',
                bold: true,
                colSpan: 3,
              },
              {},
              {},
              {
                text: `${cabecalho.diasAbono}`,
                style: 'tableHeader',
                alignment: 'left',
                bold: true,
              },
            ],
            [
              //Linha Salario Fixo
              {
                text: 'Sal. Fixo',
                style: 'tableHeader',
                alignment: 'left',
                bold: true,
                colSpan: 2,
              },
              {},
              {
                text: 'Banco',
                style: 'tableHeader',
                alignment: 'left',
                bold: true,
              },
              {
                text: 'Agencia',
                style: 'tableHeader',
                alignment: 'left',
                bold: true,
              },
              {
                text: 'Conta',
                style: 'tableHeader',
                alignment: 'left',
                bold: true,
              },
            ],
            [
              //Linha Salario Fixo
              {
                text: `${'9.999,99'}`,
                style: 'tableHeader',
                alignment: 'left',
                bold: true,
                colSpan: 2,
              },
              {},
              {
                text: `${'999'}`,
                style: 'tableHeader',
                alignment: 'left',
                bold: true,
              },
              {
                text: `${'99999'}`,
                style: 'tableHeader',
                alignment: 'left',
                bold: true,
              },
              {
                text: `${'999999999'}`,
                style: 'tableHeader',
                alignment: 'left',
                bold: true,
              },
            ],
            [
              //Linha Periodo Aquisitivo
              {
                text: 'Periodo Aquisitivo',
                style: 'tableHeader',
                alignment: 'left',
                bold: true,
                colSpan: 3,
              },
              {},
              {},
              {
                text: 'Data Pagto',
                style: 'tableHeader',
                alignment: 'left',
                bold: true,
                colSpan: 2,
              },
              {},
            ],
            [
              //Linha Periodo Aquisitivo
              {
                text: `${cabecalho.periodoAquisitivo}`,
                style: 'tableHeader',
                alignment: 'left',
                colSpan: 3,
              },
              {},
              {},
              {
                text: `${'DD/MM/AAAA'}`,
                style: 'tableHeader',
                alignment: 'left',
                colSpan: 2,
              },
              {},
            ],
            [
              //Linha Itens
              {
                text: 'Código',
                style: 'itens',
                alignment: 'left',
                bold: true,
              },
              {
                text: 'Descrição',
                style: 'itens',
                alignment: 'left',
                bold: true,
              },
              {
                text: 'Referencia',
                style: 'itens',
                alignment: 'left',
                bold: true,
              },
              {
                text: 'Provento',
                style: 'itens',
                alignment: 'left',
                bold: true,
              },
              {
                text: 'Desconto',
                style: 'itens',
                alignment: 'left',
                bold: true,
              },
            ],
            [
              //Linha Itens
              //Item 1
              {
                text: `${'126'}`,
                style: 'tableHeader',
                alignment: 'left',
                fillcolor: '#CCCCCC',
              },
              {
                text: `${'FERIAS'}`,
                style: 'tableHeader',
                alignment: 'left',
              },
              {
                text: `${'12,00'}`,
                style: 'tableHeader',
                alignment: 'left',
              },
              {
                text: `${'9.999,99'}`,
                style: 'tableHeader',
                alignment: 'left',
              },
              {
                text: `${''}`,
                style: 'tableHeader',
                alignment: 'left',
              },
            ],
            [
              //Linha Itens
              //Item 2
              {
                text: `${'127'}`,
                style: 'tableHeader',
                alignment: 'left',
                fillcolor: '#CCCCCC',
              },
              {
                text: `${'1/3 FERIAS'}`,
                style: 'tableHeader',
                alignment: 'left',
              },
              {
                text: `${'0,00'}`,
                style: 'tableHeader',
                alignment: 'left',
              },
              {
                text: `${'9.999,99'}`,
                style: 'tableHeader',
                alignment: 'left',
              },
              {
                text: `${''}`,
                style: 'tableHeader',
                alignment: 'left',
              },
            ],
          ],
        },

        layout: {
          fillColor: function (rowIndex: any, node: any) {
            if (rowIndex === 10) {
              let lista: [] = node.table.body;
              lista.filter((el: any) => {
                el.style === 'itens'
              });
            }
            return rowIndex === 10 ? '#CCCCCC' : null;
          },

          tableHeader: {
            color: '#CCCCCC',
          },
        },

        margin: [-30, 5, -30, 2],
        fontSize: 10,
      },
    ];

    return ret;
  }

  fixData(datastr: string): string {
    let dataCorreta =
      datastr.substring(6, 8) +
      '/' +
      datastr.substring(4, 6) +
      '/' +
      datastr.substring(0, 4);
    return dataCorreta;
  }
}
