import { Injectable } from '@angular/core';
import * as uuid from 'uuid';
const pdfMake = require('pdfmake/build/pdfmake.js');
const pdfFonts = require('pdfmake/build/vfs_fonts');
(pdfMake as any).vfs = pdfFonts.pdfMake.vfs;

@Injectable({
  providedIn: 'root',
})
export class FeriasPDFService {
  //   columns = [
  //     'Data', 'Dia', '1ª Entrada', '1ª Saída', '2ª Entrada', '2ª Saída',
  //     '3ª Entrada', '3ª Saída', '4ª Entrada', '4ª Saída',
  //     'Abono  ', 'Horas Extras', 'Absent.', 'Jornada', 'Ad. Not.', 'Observação']
  //   propM = ['data', 'dia', '1E', '1S', '2E', '2S', '3E', '3S', '4E', '4S',
  //     'abono', 'horasExtras', 'abstencao', 'jornada', 'adicNoturno', 'observacoes']

  //   horasCol = [
  //     'Saldo Anterior', 'Débitos', 'Créditos', 'Saldo Atual'
  //   ]
  //   horasProp = ['saldoAnterior', 'totalDebitos', 'totalCreditos', 'saldoAtual']

  //   turnosCol = ['Dia', '1ª Entrada', '1ª Saída', '2ª Entrada', '2ª Saída', 'Turno']
  //   turnosProp = ['dia', '1E', '1S', '2E', '2S', 'turno']

  //   resumoCol = ['Código', 'Descrição', 'Total de Horas']
  //   resumoProp = ['codEvento', 'descEvento', 'totalHoras']

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
    let empresa = cabecalho.empresa
    let matricula = cabecalho.matricula

    header = this.getHeader();

    var dd = {
      pageMargins: [40, 120, 40, 60],
      pageSize: 'A4',
      pageOrientation: 'portrait',
      header: (currentPage: any, pageCount: any) => {
        let s, e;

        s = start;
        e = end;

        return {
          stack: [
            { text: `Recibo de ferias ${s} - ${e}`, margin: [10, 5, 10, 5], alignment: 'center' },
            {
              columns: [
                { text: `Razao Social: ${empresa.nome}`, margin: [15, 2, 5, 1] },
                { text: `CNPJ: ${empresa.cgc}`, margin: [15, 2, 5, 1] },
              ],
            },
            {
              canvas: [
                { type: 'line', x1: 15, y1: 0, x2: 732, y2: 0, lineWidth: 1 },
              ],
            },
            {
              columns: [
                {
                  text: `Matrícula: ${matricula.matricula}`,
                  margin: [15, 5, 5, 5],
                },
                { text: `Nome: ${matricula.nome}`, margin: [15, 5, 5, 5] },
                { text: `Admissão: ${matricula.admissao}`, margin: [15, 5, 5, 5] },
              ],
            },
            {
              columns: [
                { text: `Função: ${header.funcao}`, margin: [15, 2, 5, 1] },
                { text: `C.C: ${header.cc}`, margin: [15, 2, 5, 1] },
                { text: `CPF: ${header.cpf}`, margin: [15, 2, 5, 1] },
              ],
            },
            {
              columns: [
                {
                  text: `Categoria: ${header.categoria}`,
                  margin: [15, 2, 5, 5],
                },
                { text: `Situação: ${header.situacao}`, margin: [15, 2, 5, 5] },
                {
                  text: `Departamento: ${header.departamento}`,
                  margin: [15, 2, 5, 5],
                },
              ],
            },
            {
              canvas: [
                { type: 'line', x1: 15, y1: 0, x2: 732, y2: 0, lineWidth: 1 },
              ],
            },
          ],
          margin: [10, 5, 2, 2],
          fontSize: 10,
        };
      },
    };

    let name = 'ferias_' + uuid.v4() + '.pdf';
    pdfMake.createPdf(dd).download(name);
  }
}
