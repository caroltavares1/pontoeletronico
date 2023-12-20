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
                widths: ['*', 'auto', '*'],
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
                      text: [
                        { text: 'Razao Social\n', style: 'tableHeader', alignment: 'left', bold: true},
                        { text: `${empresa.nome}`},
                      ],
                      colSpan:2
                    },
                    {},
                    {
                      text: [
                        { text: 'CNPJ\n', style: 'tableHeader', alignment: 'left', bold: true},
                        { text: `${empresa.cgc}`},
                      ]
                    },
                  ],
                  [
                    {
                      text: [
                        { text: 'Matricula\n', style: 'tableHeader', alignment: 'left', bold: true},
                        { text: `${matricula.matricula}`},
                      ]
                    },
                    {
                      text:[
                        { text: 'Nome do Funcionario\n', style: 'tableHeader', alignment: 'left', bold: true},
                        { text: `${matricula.nome}`},
                      ],
                      colSpan: 2
                    },
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
                text:[
                  { text: 'Função\n', style: 'tableHeader', alignment: 'left', bold: true},
                  { text: `${mat.matricula}`,},
                ]
              },
              {
                text:[
                  { text: 'Data de Admissão\n', style: 'tableHeader', alignment: 'left', bold: true},
                  { text: `${this.fixData(mat.admissao)}`},
                ]
              },
              {
                text:[
                  { text: 'Carteira de Trabalho\n', style: 'tableHeader', alignment: 'left', bold: true},
                  { text: `${99999}`},
                ]
              },
              {
                text:[
                  { text: 'Serie\n', style: 'tableHeader', alignment: 'left', bold: true},
                  { text: `${99999}`},
                ]
              },
              {
                text:[
                  { text: 'UF\n', style: 'tableHeader', alignment: 'left', bold: true},
                  { text: `${'PE'}`},
                ]
              },
            ],
            [
              //Linha CPF
              {
                text:[
                  { text: 'CPF\n', style: 'tableHeader', alignment: 'left', bold: true},
                  { text: `${func.cpf}`},
                ],
                colSpan: 2
              },
              {},
              {
                text:[
                  { text: 'Identidade\n', style: 'tableHeader', alignment: 'left', bold: true},
                  { text: `${'RG: 999999'}`},
                ],
                colSpan: 2
              },
              {},
              {
                text:[
                  { text: 'Carteira de Trabalho\n', style: 'tableHeader', alignment: 'left', bold: true},
                  { text: `${'IRRF'}`},
                ],
              },
            ],
            [
              //Linha Vencimento das Ferias
              {
                text:[
                  { text: 'Vencimento das Férias\n', style: 'tableHeader', alignment: 'left', bold: true},
                  { text: `${this.fixData(fer.fimPerAq)}`},
                ],
              },
              {
                text:[
                  { text: 'Periodo de Gozo de Ferias\n', style: 'tableHeader', alignment: 'left', bold: true},
                  { text: `${cabecalho.periodoGozo}`},
                ],
                colSpan: 3
              },
              {},
              {},
              {
                text:[
                  { text: 'Abono Pecuniario\n', style: 'tableHeader', alignment: 'left', bold: true},
                  { text: `${cabecalho.diasAbono}`},
                ],
              },
            ],
            [
              //Linha Salario Fixo
              {
                text:[
                  { text: 'Sal. Fixo\n', style: 'tableHeader', alignment: 'left', bold: true},
                  { text: `${'9.999,99'}`},
                ],
                colSpan: 2
              },
              {},
              {
                text:[
                  { text: 'Banco\n', style: 'tableHeader', alignment: 'left', bold: true},
                  { text: `${'999'}`},
                ]
              },
              {
                text:[
                  { text: 'Agencia\n', style: 'tableHeader', alignment: 'left', bold: true},
                  { text: `${'99999'}`},
                ]
              },
              {
                text:[
                  { text: 'Conta\n', style: 'tableHeader', alignment: 'left', bold: true},
                  { text: `${'999999999'}`},
                ]
              },
            ],
            [
              //Linha Periodo Aquisitivo
              {
                text:[
                  { text: 'Periodo Aquisitivo\n', style: 'tableHeader', alignment: 'left', bold: true},
                  { text: `${cabecalho.periodoAquisitivo}`},
                ],
                colSpan: 3
              },
              {},
              {},
              {
                text:[
                  { text: 'Data Pagto\n', style: 'tableHeader', alignment: 'left', bold: true},
                  { text: `${'DD/MM/AAAA'}`},
                ],
                colSpan: 2
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
            // if (rowIndex === 10) { 
            //   let lista: [] = node.table.body;
            //   lista.filter((el: any) => {
            //     el.style === 'itens'
            //   });
            // }
            return rowIndex === 5 ? '#CCCCCC' : null; //Aqui eu defini manualmente a linha que deve ficar cinza, porque nao consegui localizar de forma dinamica a linha do cabeçalho dos itens
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
