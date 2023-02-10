import { Component, ElementRef, OnInit, ViewChild } from '@angular/core';
import { PoDialogService, PoPageAction, PoTableColumn } from '@po-ui/ng-components';
import { PoPageDynamicSearchFilters, PoPageDynamicSearchLiterals } from '@po-ui/ng-templates';
import { ExportToPDFService } from '../../services/exportToPDF.service';
import { PontosService } from '../../services/pontos.service';

@Component({
  selector: 'app-list',
  templateUrl: './list.component.html',
  styleUrls: ['./list.component.css']
})
export class ListComponent implements OnInit {
  @ViewChild('htmlData') htmlData!: ElementRef;

  items: Array<any> = []
  itemsHorarios: Array<any> = []
  itemsBH: Array<any> = []
  itemsResumo: Array<any> = []
  pontos: Array<any> = []
  loading = true
  loadingB = true
  start = ''
  end = ''
  consideraBH = false

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
    { property: 'data', type: 'date', label: 'Data' },
    { property: 'dataATE', type: 'date', label: 'Data', visible: false }, //Apenas usado na busca
    { property: 'dia', label: 'Dia' },
    { property: '1E', label: '1ª Entrada', type: 'string' },
    { property: '1S', label: '1ª Saída', type: 'string' },
    { property: '2E', label: '2ª Entrada', type: 'string' },
    { property: '2S', label: '2ª Saída', type: 'string' },
    { property: '3E', label: '3ª Entrada', type: 'string' },
    { property: '3S', label: '3ª Saída', type: 'string' },
    { property: '4E', label: '4ª Entrada', type: 'string' },
    { property: '4S', label: '4ª Saída', type: 'string' },
    { property: 'abono', label: 'Abono' },
    { property: 'horasExtras', label: 'Horas Extras', type: 'string' },
    { property: 'abstencao', label: 'Absent.', type: 'string' },
    { property: 'jornada', label: 'Jornada', type: 'string' },
    { property: 'adicNoturno', label: 'Ad. Not.', type: 'string' },
    { property: 'observacoes', label: 'Observação' },
    { property: 'matricula', visible: false, type: 'string' },
    { property: 'diaAbonado', visible: false, type: 'boolean' }

  ];

  horarios: Array<PoTableColumn> = [
    { property: 'dia', type: 'string', width: '12,5%', label: 'Dia' },
    { property: '1E', width: '14,625%', label: '1ª Entrada', type: 'string' },
    { property: '1S', width: '14,625%', label: '1ª Saída', type: 'string' },
    { property: '2E', width: '14,625%', label: '2ª Entrada', type: 'string' },
    { property: '2S', width: '14,625%', label: '2ª Saída', type: 'string' },
    { property: 'turno', width: '25%', label: 'Turno' }

  ];

  banco: Array<PoTableColumn> = [
    { property: 'saldoAnterior', width: '25%', label: 'Saldo Anterior', type: 'string' },
    { property: 'totalDebitos', width: '25%', label: 'Débitos', type: 'string' },
    { property: 'totalCreditos', width: '25%', label: 'Créditos', type: 'string' },
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
    private pdf: ExportToPDFService
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
              let indice = 0
              if (v.ponto.length !== undefined) {
                indice = v.ponto.length - 1
              }
              let turno = v.ponto[indice].marcacoes[0].turno
              let seq = v.ponto[indice].marcacoes[0].seqTurno
              this.items = v.ponto[indice].marcacoes
              this.itemsResumo = v.ponto[indice].resumo
              this.pontos = v.ponto
              this.loading = false
              this.getHorarios(turno, seq)
            }, 500);
          } else {
            this.loading = false
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
            this.consideraBH = v.bh[0].consideraBH
            this.itemsBH = v.bh
            this.loadingB = false
          } else {
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

  public openPDF() {
    this.pdf.openPDF(
      this.pontos,
      //this.items,
      this.itemsBH,
      this.itemsHorarios,
      //this.itemsResumo,
      this.start,
      this.end,
      this.consideraBH)
  }

}