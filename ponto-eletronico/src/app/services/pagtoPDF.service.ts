import { Injectable } from '@angular/core';
import * as uuid from 'uuid';
import { PagamentoService } from './pagamento.service';
const pdfMake = require('pdfmake/build/pdfmake.js');
const pdfFonts = require('pdfmake/build/vfs_fonts');
(pdfMake as any).vfs = pdfFonts.pdfMake.vfs;

@Injectable({
  providedIn: 'root',
})
export class PagtoPDFService {
  cabecalho = {};
  urlLogo!: string;
  pagtos: Array<Object> = [];

  constructor(private pagtoService: PagamentoService) { }

  setDados(cpf: string) {
    this.pagtoService.getItensPagto(cpf).subscribe((data) => {
      this.pagtos = data;
    });
  }

  public async openPDF(cabecalho: any) {
    let pagto: any = null;

    const logoURL64 = this.getBase64ImageFromURL(
      '../../assets/images/grupoBCI.jpg'
    );

    await logoURL64.then((el) => {
      this.urlLogo = el;
    });

    this.pagtoService.getItensPagto(cabecalho).subscribe({
      next: (data: any) => {
        pagto = data;
      },
      complete: () => {
        this.pagtos = pagto;
        this.processa(cabecalho);
      },
    });
  }

  processa(cabecalho: any) {
    let empresa = cabecalho.empfil;
    let matricula = cabecalho.funcionario;

    var dd = {
      pageMargins: [40, 120, 40, 60],
      pageSize: 'A4',
      pageOrientation: 'portrait',
      header: () => {

        let stack = {
          stack: [
            {
              style: 'tableExample',
              color: '#444',
              table: {
                widths: ['*', 'auto', '*'],
                heights: [50],
                headerRows: 3,
                body: [
                  [
                    {
                      image: this.urlLogo,
                      width: 70,
                      height: 45,
                      border: [true, true, false, false],
                    },
                    {
                      text: 'Demonstrativo de Pagamento Mensal',
                      style: 'tableHeader',
                      colSpan: 2,
                      alignment: 'left',
                      bold: true,
                      fontSize: 18,
                      border: [false, true, true, true],
                      margin: [-35, 0, 0, 0],
                    },
                    {},
                  ],
                  [
                    {
                      text: [
                        {
                          text: 'Razao Social\n',
                          style: 'tableHeader',
                          alignment: 'left',
                          bold: true,
                        },
                        { text: `${empresa.nome}` },
                      ],
                      colSpan: 2,
                    },
                    {},
                    {
                      text: [
                        {
                          text: 'CNPJ\n',
                          style: 'tableHeader',
                          alignment: 'left',
                          bold: true,
                        },
                        { text: `${empresa.cgc}` },
                      ],
                    },
                  ],
                  [
                    {
                      text: [
                        {
                          text: 'Matricula\n',
                          style: 'tableHeader',
                          alignment: 'left',
                          bold: true,
                        },
                        { text: `${matricula.matricula}` },
                      ],
                    },
                    {
                      text: [
                        {
                          text: 'Nome do Funcionario\n',
                          style: 'tableHeader',
                          alignment: 'left',
                          bold: true,
                        },
                        { text: `${matricula.nome}` },
                      ],
                      colSpan: 2,
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
      content: this.content(cabecalho, this.pagtos),
    };

    let name = 'pagto_' + uuid.v4() + '.pdf';
    pdfMake.createPdf(dd).download(name);
  }

  content(cabecalho: any, pagtos: any) {
    let func = cabecalho.funcionario;
    let itensPdf: Array<any> = [];
    let itens: Array<any> = pagtos.itensPagto;
    let banco = func.bancoAgencia.substring(0, 3);
    let agencia = func.bancoAgencia.substring(3);
    let conta = func.conta;

    let totalProventos = pagtos.totalProventos.toLocaleString(undefined, {
      minimumFractionDigits: 2,
    });

    let totalDescontos = pagtos.totalDescontos.toLocaleString(undefined, {
      minimumFractionDigits: 2,
    });

    let liquidoReceber = pagtos.liquidoReceber.toLocaleString(undefined, {
      minimumFractionDigits: 2,
    });

    let salario = pagtos.salario.toLocaleString(undefined, {
      minimumFractionDigits: 2,
    });

    let valorFgts = pagtos.valorFgts.toLocaleString(undefined, {
      minimumFractionDigits: 2,
    });

    let baseFgts = pagtos.baseFgts.toLocaleString(undefined, {
      minimumFractionDigits: 2,
    });

    let baseIrrf = pagtos.baseIrrf.toLocaleString(undefined, {
      minimumFractionDigits: 2,
    });

    let contribInss = pagtos.contribInss.toLocaleString(undefined, {
      minimumFractionDigits: 2,
    });

    let pensaoAliment = pagtos.totalPensao.toLocaleString(undefined, {
      minimumFractionDigits: 2,
    });

    itensPdf.push([
      //Linha Funcao
      {
        text: [
          {
            text: 'Função\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          { text: `${func.funcao}` },
        ],
        colSpan: 6,

      }, {}, {}, {}, {}, {}

    ]);

    itensPdf.push([
      //Linha Data de Admissao
      {
        text: [
          {
            text: 'Data de Admissão\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          { text: `${this.fixData(func.admissao)}` },
        ],
      },
      {
        text: [
          {
            text: 'Endereço\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          { text: `${func.endereco}` },
        ],
        colSpan: 5
      }, {}, {}, {}, {}
    ]);

    itensPdf.push([
      //Linha Bairro
      {
        text: [
          {
            text: 'Bairro\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          { text: `${func.bairro}` },
        ],
        colSpan: 2,
      },
      {},
      {
        text: [
          {
            text: 'CEP\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          { text: `${func.cep}` },
        ],
        colSpan: 2,
      },
      {},
      {
        text: [
          {
            text: 'Cidade\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          { text: `${func.municipio}` },
        ],
      },
      {
        text: [
          {
            text: 'UF\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          { text: `${func.estado}` },
        ],
      }
    ]);

    itensPdf.push([
      //Linha PIS
      {
        text: [
          {
            text: 'PIS\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          { text: `${func.pis}` },
        ],
      },
      {
        text: [
          {
            text: 'CPF\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          { text: `${func.cpf}` },
        ],
      },
      {
        text: [
          {
            text: 'Identidade\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          { text: `${func.rg}` },
        ],
      },
      {
        text: [
          {
            text: 'Competência\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          { text: `${this.getCompetencia(cabecalho.ano, cabecalho.mes)}` },
        ],
      },
      {
        text: [
          {
            text: 'Dep. Sal. Família\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          { text: `${func.depSF}` },
        ],
      },
      {
        text: [
          {
            text: 'Dep. IRRF\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          { text: `${func.depIR}` },
        ],
      },
    ]);

    itensPdf.push([
      //Linha Salario
      {
        text: [
          {
            text: 'Salário\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          {
            text: `${salario}`,
            alignment: 'right',
          },
        ],
      },
      {
        text: [
          {
            text: 'Data Pagto\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          {
            text: `${this.fixData(pagtos.dtPagto)}`,
          },
        ],
      },
      {
        text: [
          {
            text: 'Banco\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          { text: `${banco}` },
        ],
      },
      {
        text: [
          {
            text: 'Agencia\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          { text: `${agencia}` },
        ],
      },
      {
        text: [
          {
            text: 'Conta\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          { text: `${conta}` },
        ],
        colSpan: 2,
      }, {}
    ]);

    itensPdf.push([
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
        colSpan: 2,
      }, {},
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
    ]);

    itens.sort((a, b) => {
      return a.codVerba - b.codVerba;
    });

    itens.forEach((el) => {
      let referencia = el.referencia.toLocaleString(undefined, {
        minimumFractionDigits: 2,
      });
      if (el.tipoVerba == '1') {
        itensPdf.push([
          {
            text: `${el.codVerba}`,
            style: 'tableHeader',
            alignment: 'left',
            fillcolor: '#CCCCCC',
          },
          {
            text: `${el.descVerba}`,
            style: 'tableHeader',
            alignment: 'left',
            colSpan: 2,
          }, {},
          {
            text: `${referencia}`,
            style: 'tableHeader',
            alignment: 'right',
          },
          {
            text: `${el.provento.toLocaleString(undefined, {
              minimumFractionDigits: 2,
            })}`,
            style: 'tableHeader',
            alignment: 'right',
          },
          {
            text: `${''}`,
            style: 'tableHeader',
            alignment: 'left',
          },
        ]);
      } else if (el.tipoVerba == '2') {
        itensPdf.push([
          {
            text: `${el.codVerba}`,
            style: 'tableHeader',
            alignment: 'left',
            fillcolor: '#CCCCCC',
          },
          {
            text: `${el.descVerba}`,
            style: 'tableHeader',
            alignment: 'left',
            colSpan: 2,
          }, {},
          {
            text: `${referencia}`,
            style: 'tableHeader',
            alignment: 'right',
          },
          {
            text: `${''}`,
            style: 'tableHeader',
            alignment: 'left',
          },
          {
            text: `${el.provento.toLocaleString(undefined, {
              minimumFractionDigits: 2,
            })}`,
            style: 'tableHeader',
            alignment: 'right',
          },
        ]);
      }
    });

    let linhasEmBranco = 28 - itensPdf.length

    for (let index = 0; index < linhasEmBranco; index++) {
      itensPdf.push([
        //Linhas em Branco
        {
          text: [
            {
              text: '    ',
              style: 'tableHeader',
              alignment: 'left',
              fontSize: 9,
            },
          ],
          colSpan: 6,
        }, {}, {}, {}, {}, {}
      ]);
    }

    itensPdf.push([
      //Linha Observacoes
      {
        text: [
          {
            text: `'Valido como Comprovante Mensal de Rendimentos' - ( Artigo no. 41 e 464 da CLT, Portaria MTPS/GM 3.626 de 13/11/1991 )\n\n`,
            style: 'tableHeader',
            alignment: 'left',
            fontSize: 9,
          },
        ],
        colSpan: 6,
      }, {}, {}, {}, {}, {}
    ]);

    itensPdf.push([
      //Linha Base para FGTS
      {
        text: [
          {
            text: 'Base para FGTS\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          {
            text: `${baseFgts}`,
            alignment: 'right',
          },
        ],
        colSpan: 2,
      },
      {},
      {
        text: [
          {
            text: 'FGTS do Mês\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          {
            text: `${valorFgts}`,
            alignment: 'right',
          },
        ],
        colSpan: 2,
      },
      {},
      {
        text: [
          {
            text: 'Total de Proventos\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          {
            text: `${totalProventos}`,
            alignment: 'right',
          },
        ],
        colSpan: 2,
      }, {}
    ]);

    itensPdf.push([
      //Linha Base Calc IRRF
      {
        text: [
          {
            text: 'Base Cálc. IRRF\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          {
            text: `${baseIrrf}`,
            alignment: 'right',
          },
        ],
        colSpan: 2,
      },
      {},
      {
        text: [
          {
            text: 'Pensão Alimentícia Judicial\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          {
            text: `${pensaoAliment}`,
            alignment: 'right',
          },
        ],
        colSpan: 2,
      },
      {},
      {
        text: [
          {
            text: 'Total de Descontos\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          {
            text: `${totalDescontos}`,
            alignment: 'right',
          },
        ],
        colSpan: 2,
      }, {}
    ]);

    itensPdf.push([
      //Linha Sal. Contribuição
      {
        text: [
          {
            text: 'Sal. Contribuição. INSS\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          {
            text: `${contribInss}`,
            alignment: 'right',
          },
        ],
        colSpan: 2,
      },
      {},
      {
        text: [
          {
            text: '\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          {
            text: `${""}`,
          },
        ],
        colSpan: 2,
      },
      {},
      {
        text: [
          {
            text: 'Líquido a Receber\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          {
            text: `${liquidoReceber}`,
            alignment: 'right',
          },
        ],
        colSpan: 2,
      }, {}
    ]);

    let ret = [
      {
        style: 'tableExample',
        table: {
          widths: ['auto', '*', 'auto', 'auto', 'auto', 60],
          body: itensPdf,
        },
        layout: {
          fillColor: function (rowIndex: any, node: any) {
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
    datastr = datastr.replaceAll("/", "")

    let dataCorreta =
      datastr.substring(6, 8) +
      '/' +
      datastr.substring(4, 6) +
      '/' +
      datastr.substring(0, 4);
    return dataCorreta;
  }

  getCompetencia(ano: string, mes: string) {
    let competencia = ano + mes
    let mesExtenso

    if (mes == "01") {
      mesExtenso = "Janeiro"
    }

    if (mes == "02") {
      mesExtenso = "Fevereiro"
    }

    if (mes == "03") {
      mesExtenso = "Março"
    }

    if (mes == "04") {
      mesExtenso = "Abril"
    }

    if (mes == "05") {
      mesExtenso = "Maio"
    }

    if (mes == "06") {
      mesExtenso = "Junho"
    }

    if (mes == "07") {
      mesExtenso = "Julho"
    }

    if (mes == "08") {
      mesExtenso = "Agosto"
    }

    if (mes == "09") {
      mesExtenso = "Setembro"
    }

    if (mes == "10") {
      mesExtenso = "Outubro"
    }

    if (mes == "11") {
      mesExtenso = "Novembro"
    }

    if (mes == "12") {
      mesExtenso = "Dezembro"
    }

    competencia = mesExtenso + "/" + ano
    return competencia
  }

  getBase64ImageFromURL(url: string): Promise<any> {
    return new Promise((resolve, reject) => {
      var img = new Image();
      img.setAttribute('crossOrigin', 'anonymous');

      img.onload = () => {
        var canvas = document.createElement('canvas');
        canvas.width = img.width;
        canvas.height = img.height;

        var ctx = canvas.getContext('2d');
        ctx!.drawImage(img, 0, 0);

        var dataURL = canvas.toDataURL('image/png');

        resolve(dataURL);
      };

      img.onerror = (error) => {
        reject(error);
      };

      img.src = url;
    });
  }
}
