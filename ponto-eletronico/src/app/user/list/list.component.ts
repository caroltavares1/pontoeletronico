import { Component, ElementRef, OnInit, ViewChild } from '@angular/core';
import { PoDialogService, PoPageAction, PoTableColumn } from '@po-ui/ng-components';
import { PoPageDynamicSearchFilters, PoPageDynamicSearchLiterals } from '@po-ui/ng-templates';
import { PontosService } from '../pontos.service';
import jsPDF from 'jspdf';
import html2canvas from 'html2canvas';

declare var require: any;

//import * as pdfMake from "pdfmake/build/pdfmake";
const pdfMake = require('pdfmake/build/pdfmake.js');
const pdfFonts = require("pdfmake/build/vfs_fonts");
import { map } from 'rxjs';
import { CabecalhoService } from '../cabecalho.service';
(pdfMake as any).vfs = pdfFonts.pdfMake.vfs;

@Component({
  selector: 'app-list',
  templateUrl: './list.component.html',
  styleUrls: ['./list.component.css']
})
export class ListComponent implements OnInit {
  @ViewChild('htmlData') htmlData!: ElementRef;

  items: Array<any> = []
  itemsHorarios: Array<any> = []
  bancohorarios: Array<any> = []
  resumoItems: Array<any> = []
  loading = true
  loadingH = true
  loadingB = true
  start = ''
  end = ''

  customLiterals: PoPageDynamicSearchLiterals = {
    searchPlaceholder: 'Buscar uma data'
  };

  public readonly actions: Array<PoPageAction> = [
    { label: 'Exportar para PDF', action: this.openPDF.bind(this), icon: 'po-icon-pdf' },
  ]

  public readonly filters: Array<PoPageDynamicSearchFilters> = [
    { property: 'data', label: 'Data de', type: 'date', gridColumns: 6 },
    { property: 'dataATE', label: 'Data até', type: 'date', gridColumns: 6 },
  ]

  columns: Array<PoTableColumn> = [
    { property: 'data', type: 'date', width: '6,25%', label: 'Data' },
    { property: 'dataATE', type: 'date', width: '6,25%', label: 'Data', visible: false }, //Apenas usado na busca
    { property: 'dia', width: '6,25%', label: 'Dia' },
    { property: '1E', width: '6,25%', label: '1ª Entrada', type: 'time', format: 'HH:mm' },
    { property: '1S', width: '6,25%', label: '1ª Saída', type: 'time', format: 'HH:mm' },
    { property: '2E', width: '6,25%', label: '2ª Entrada', type: 'time', format: 'HH:mm' },
    { property: '2S', width: '6,25%', label: '2ª Saída', type: 'time', format: 'HH:mm' },
    { property: 'abono', width: '6,25%', label: 'Abono' },
    { property: 'horasExtras', width: '6,25%', label: 'Horas Extras', type: 'time', format: 'HH:mm' },
    { property: 'abstencao', width: '6,25%', label: 'Absten.', type: 'time', format: 'HH:mm' },
    { property: 'jornada', width: '6,25%', label: 'Jornada', type: 'time', format: 'HH:mm' },
    { property: 'observacoes', width: '6,25%', label: 'Observação' },
    { property: 'matricula', visible: false, type: 'string' }

  ];

  horarios: Array<PoTableColumn> = [
    { property: 'dia', type: 'string', width: '12,5%', label: 'Dia' },
    { property: '1E', width: '14,625%', label: '1ª Entrada', type: 'time', format: 'HH:mm' },
    { property: '1S', width: '14,625%', label: '1ª Saída', type: 'time', format: 'HH:mm' },
    { property: '2E', width: '14,625%', label: '2ª Entrada', type: 'time', format: 'HH:mm' },
    { property: '2S', width: '14,625%', label: '2ª Saída', type: 'time', format: 'HH:mm' },
    { property: 'turno', width: '25%', label: 'Turno' },
    { property: 'matricula', visible: false, type: 'string' }

  ];

  banco: Array<PoTableColumn> = [
    { property: 'saldoAnterior', width: '25%', label: 'Saldo Anterior', type: 'string' },
    { property: 'totalCreditos', width: '25%', label: 'Créditos', type: 'string' },
    { property: 'totalDebitos', width: '25%', label: 'Débitos', type: 'string' },
    { property: 'saldoAtual', width: '25%', label: 'Saldo Atual', type: 'string' },
  ];

  resumoCols: Array<PoTableColumn> = [
    { property: 'codEvento', width: '20%', label: 'Código', type: 'string' },
    { property: 'descEvento', width: '60%', label: 'Descrição', type: 'string' },
    { property: 'totalHoras', width: '20%', label: 'Total de Horas', type: 'string' },

  ];

  constructor(
    private pontosService: PontosService,
    private poDialog: PoDialogService,
    private headerService: CabecalhoService
  ) { }

  ngOnInit(): void {
  }

  onLoadFields() {

    const today = new Date()
    let month = today.getMonth()
    let start = new Date(today.getFullYear(), month, 1).toISOString().slice(0, 10)
    let end = new Date(today.getFullYear(), month + 1, 0).toISOString().slice(0, 10)
    return {
      filters: [
        { property: 'data', initValue: start },
        { property: 'dataATE', initValue: end }
      ],
      keepFilters: true
    };
  }

  getlist(ini?: string, fin?: string) {
    this.pontosService.list(ini, fin)
      .subscribe({
        next: (v: any) => {
          if (v.hasContent == true) {
            setTimeout(() => {
              let turno = v.marcacoes[0].turno
              let seq = v.marcacoes[0].seqTurno
              this.items = v.marcacoes
              this.resumoItems = v.resumo
              //this.items = .sort( (a:any,b:any) => a.data - b.data );
              this.loading = false
              this.getHorarios(turno, seq)
            }, 500);
          } else {
            if (ini == undefined && fin == undefined) {
              this.poDialog.alert({
                literals: { ok: 'Fechar' },
                title: 'Nenhum dado encontrado!',
                message: 'Nenhuma marcação de ponto encontrada.'
              });
            } else {
              this.poDialog.alert({
                literals: { ok: 'Fechar' },
                title: 'Nenhum dado encontrado!',
                message: 'Sua pesquisa não retornou nenhum resultado.'
              });
            }
          }
        },
        error: (e: any) => this.poDialog.alert({
          literals: { ok: 'Fechar' },
          title: 'Nenhum dado encontrado!',
          message: 'Sua pesquisa não retornou nenhum resultado.'
        })
      })

  }

  getBancoHora(dtini: string, dtfin: string) {
    this.pontosService.getBancoHoras(dtini, dtfin)
      .subscribe({
        next: (v: any) => {
          if (v.bh != undefined) {
            this.bancohorarios = v.bh
            this.loadingB = false
          }
        }
      })
  }

  getHorarios(turno: string, seq: string) {
    this.pontosService.turno = turno
    this.pontosService.seq = seq
    this.pontosService.listHorarios()
      .subscribe({
        next: (v: any) => {
          if (v != undefined) {
            setTimeout(() => {
              this.itemsHorarios = v.horarios
              this.loadingH = false
            }, 500);

          }
        }
      })
  }

  converteData(data: string) {
    if (data[2] == '/' && data[5] == '/') {
      var dateParts = data.split("/");
      (dateParts[2].length == 2) ? dateParts[2] = "20" + dateParts[2] : dateParts[2]
      // month is 0-based, that's why we need dataParts[1] - 1
      //new Date(year, month, day)

      var dateObject = new Date(+dateParts[2], (Number(dateParts[1]) - 1), +dateParts[0]).toISOString().slice(0, 10);
      return dateObject

    } else {
      this.poDialog.alert({
        literals: { ok: 'Fechar' },
        title: 'Nenhum dado encontrado!',
        message: 'Por favor tente buscar a data no formato dd/mm/aa ou dd/mm/aaaa'
      })
      return data
    }
  }


  onAdvancedSearch(filter: any) {
    if (this.alertaFiltroIncorreto(filter)) {
      return
    } else {
      filter ? this.searchItems(filter) : this.resetFilters()
    }
  }

  onQuickSearch(filter: any) {
    filter = this.converteData(filter)
    filter ? this.searchItems({ data: filter, dataATE: filter }) : this.resetFilters();
  }

  onChangeDisclaimers(disclaimers: any) {
    const filter: any = {};
    disclaimers.forEach((item: any) => {
      filter[item.property] = item.value;
    });
    (!this.alertaFiltroIncorreto(filter)) ? this.searchItems(filter) : this.searchItems({})
  }

  private alertaFiltroIncorreto(filter: any): boolean {
    if (filter.data == undefined && filter.dataATE !== undefined) {
      this.poDialog.alert({
        literals: { ok: 'Fechar' },
        title: 'Alerta',
        message: 'É preciso informar a data inicial. Sua pesquisa não surtirá efeito.'
      });
      return true
    }
    return false
  }

  private searchItems(filter: any) {
    let start = (filter.data)
    let end = (filter.dataATE)

    if (start !== undefined && end != undefined) {
      this.start = start
      this.end = end
      start = start.replaceAll('-', '')
      end = end.replaceAll('-', '')
    } else if (start !== undefined && end == undefined) {
      this.start = start
      start = start.replaceAll('-', '')
      end = new Date().toISOString().slice(0, 10);
      this.end = end
      end = end.replaceAll('-', '')
    }
    this.getlist(start, end);
    this.getBancoHora(start, end)
  }
  private resetFilters() {
    this.getlist()
  }


  public openPDF(): void {
    let header: any = {}
    header = this.headerService.getHeader()

    let marcacoes = structuredClone(this.items) //Cria uma copia por valor e não por referência
    let columns = [
      'Data', 'Dia', '1ª Entrada', '1ª Saída', '2ª Entrada', '2ª Saída',
      'Abono  ', 'Horas Extras', 'Abstenção', 'Jornada', 'Observação']
    let propM = ['data', 'dia', '1E', '1S', '2E', '2S', 'abono', 'horasExtras', 'abstencao', 'jornada', 'observacoes']

    let horas = structuredClone(this.bancohorarios)
    let horasCol = [
      'Saldo Anterior', 'Créditos', 'Débitos', 'Saldo Atual'
    ]
    let horasProp = ['saldoAnterior', 'totalCreditos', 'totalDebitos', 'saldoAtual']

    let turnos = structuredClone(this.itemsHorarios)
    let turnosCol = ['Dia', '1ª Entrada', '1ª Saída', '2ª Entrada', '2ª Saída', 'Turno']
    let turnosProp = ['dia', '1E', '1S', '2E', '2S', 'turno']

    let resumo = structuredClone(this.resumoItems)
    let resumoCol = ['Código', 'Descrição', 'Total de Horas']
    let resumoProp = ['codEvento', 'descEvento', 'totalHoras']



    var dd = {
      pageMargins: [40, 150, 40, 60],
      pageSize: 'A4',
      pageOrientation: "landscape",
      //header: `Espelho do Ponto ${this.start} - ${this.end}`,
      header: {
        stack: [
          { text: `Espelho do Ponto ${this.start} - ${this.end}`, margin: [260, 5, 0, 5] },
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
              { text: `categoria: ${header.categoria}`, margin: [15, 2, 5, 5] },
              { text: `Situação: ${header.situacao}`, margin: [15, 2, 5, 5] },
              { text: `Departamento: ${header.departamento}`, margin: [15, 2, 5, 5] },
            ]

          },
          { canvas: [{ type: 'line', x1: 15, y1: 0, x2: 732, y2: 0, lineWidth: 1, }] },
        ],
        margin: [40, 5, 2, 5]
      },
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


  public buildTableBody(data: any, columns: any, col: any, flag?:boolean) {
    let body = [];

    body.push(columns);

    data.forEach((row: any) => {
      let dataRow: any = [];

      col.forEach((column: any) => {
        let rc
        if (row[column] == '00:00:00' && flag == true) {
          row[column] = ''
        }
        (row[column] == null) ? rc = '' : rc = row[column].toString()
        dataRow.push(rc);
      })
      body.push(dataRow);
    });

    return body;
  }

  public table(data: any, columns: any, col: any) {
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
        fillColor: function (i:any, node:any) {
          return (i % 2 === 0) ? '#e5e5e5' : null;
        }
      }
    };

  }
  public tableBH(data: any, columns: any, col: any) {
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
        fillColor: function (i:any, node:any) {
          return (i % 2 === 0) ? '#e5e5e5' : null;
        }
      }
    };

  }

  public tableTurno(data: any, columns: any, col: any) {
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
        fillColor: function (i:any, node:any) {
          return (i % 2 === 0) ? '#e5e5e5' : null;
        }
      }
    };

  }

  public tableResumo(data: any, columns: any, col: any) {
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
        fillColor: function (i:any, node:any) {
          return (i % 2 === 0) ? '#e5e5e5' : null;
        }
      }
    };

  }
}