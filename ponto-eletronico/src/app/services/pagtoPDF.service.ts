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
                      text: 'Recibo de Ferias',
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
      },
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
            text: 'Carteira de Trabalho\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          { text: `${func.numCp}` },
        ],
      },
      {
        text: [
          {
            text: 'Serie\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          { text: `${func.serieCp}` },
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
          { text: `${func.ufCp}` },
        ],
      },
    ]);

    itensPdf.push([
      //Linha CPF
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
        colSpan: 2,
      },
      {},
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
        colSpan: 2,
      },
      {},
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
      //Linha Vencimento das Ferias
      {
        text: [
          {
            text: 'Vencimento das Férias\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          { text: `${this.fixData("")}` },
        ],
      },
      {
        text: [
          {
            text: 'Periodo de Gozo de Ferias\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          { text: `${cabecalho.periodoGozo}` },
        ],
        colSpan: 3,
      },
      {},
      {},
      {
        text: [
          {
            text: 'Abono Pecuniario\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          { text: `${cabecalho.diasAbono}` },
        ],
      },
    ]);

    itensPdf.push([
      //Linha Salario Fixo
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
          },
        ],
        colSpan: 2,
      },
      {},
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
      },
    ]);

    itensPdf.push([
      //Linha Periodo Aquisitivo
      {
        text: [
          {
            text: 'Periodo Aquisitivo\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          { text: `${cabecalho.periodoAquisitivo}` },
        ],
        colSpan: 3,
      },
      {},
      {},
      {
        text: [
          {
            text: 'Data Pagto\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
          },
          { text: `${this.fixData(pagtos.dtPagto)}` },
        ],
        colSpan: 2,
      },
      {},
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
          },
          {
            text: `${referencia}`,
            style: 'tableHeader',
            alignment: 'left',
          },
          {
            text: `${el.provento.toLocaleString(undefined, {
              minimumFractionDigits: 2,
            })}`,
            style: 'tableHeader',
            alignment: 'left',
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
          },
          {
            text: `${referencia}`,
            style: 'tableHeader',
            alignment: 'left',
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
            alignment: 'left',
          },
        ]);
      }
    });

    itensPdf.push([
      //Linha Resumo
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
          },
        ],
      },
    ]);

    itensPdf.push([
      //Linha Resumo
      {
        text: [
          {
            text: 'Informativo:\n\n\n',
            style: 'tableHeader',
            alignment: 'left',
            bold: true,
            fontSize: 9,
          },
        ],
        colSpan: 5,
      },
      {},
      {},
      {},
      {},
    ]);

    itensPdf.push([
      //Linha Resumo
      {
        text: [
          {
            text: `De acordo com o parágrafo único do artigo 145 da CLT, recebi da firma ${cabecalho.empresa.nome}, a importância líquida de R$ ${liquidoReceber} (${""})  que me paga adiantadamente por motivos de minhas férias regulamentares. Ora concedidas e que vou gozar de acordo com a descrição acima. Tudo conforme aviso que recebi em tempo ao que dei meu ciente. Para clareza e documento, firmo o presente recebido.Dando firma, plena e geral quitação\n\n`,
            style: 'tableHeader',
            alignment: 'left',
            fontSize: 9,
          },
        ],
        colSpan: 5,
      },
      {},
      {},
      {},
      {},
    ]);

    itensPdf.push([
      //Linha Resumo
      {
        columns: [
          {
            text: `${'__________________________________________________'}\n${func.nome
              }\n\n`,
            style: 'tableHeader',
            alignment: 'center',
          },
          {
            text: `${'__________________________________________________'}\n${cabecalho.empresa.nome
              }\n\n`,
            style: 'tableHeader',
            alignment: 'center',
          },
        ],
        colSpan: 5,
      },
      {},
      {},
      {},
      {},
    ]);

    let ret = [
      {
        style: 'tableExample',
        table: {
          widths: ['auto', '*', 'auto', 'auto', 'auto'],
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
    let dataCorreta =
      datastr.substring(6, 8) +
      '/' +
      datastr.substring(4, 6) +
      '/' +
      datastr.substring(0, 4);
    return dataCorreta;
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
