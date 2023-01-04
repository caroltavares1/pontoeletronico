import { Component, ElementRef, OnInit, ViewChild } from '@angular/core';
import { PoDialogService, PoPageAction, PoTableColumn } from '@po-ui/ng-components';
import { PoPageDynamicSearchFilters, PoPageDynamicSearchLiterals } from '@po-ui/ng-templates';
import { PontosService } from '../pontos.service';
import jsPDF from 'jspdf';
import html2canvas from 'html2canvas';

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
  loading = true
  loadingH = true
  loadingB = true

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
    { property: 'abono', width: '6,25%', label: 'abono' },
    { property: 'horasExtras', width: '6,25%', label: 'Horas Extras', type: 'time', format: 'HH:mm' },
    { property: 'abstencao', width: '6,25%', label: 'Absten.', type: 'time', format: 'HH:mm' },
    { property: 'jornada', width: '6,25%', label: 'Jornada', type: 'time', format: 'HH:mm' },
    { property: 'obs', width: '6,25%', label: 'Observação' },
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
    { property: 'bancoHoras', type: 'string', width: '32%', label: 'Banco de Horas' },
    { property: 'saldoAnterior', width: '17%', label: 'Saldo Anterior', type: 'number' },
    { property: 'credito', width: '17%', label: 'Crédito', type:'number' },
    { property: 'debito', width: '17%', label: 'Débito', type:'number' },
    { property: 'saldoAtual', width: '17%', label: 'Saldo Atual', type:'number' },



  ];

  constructor(private pontosService: PontosService, private poDialog: PoDialogService) { }

  ngOnInit(): void {
  }

  onLoadFields() {

    const today = new Date()
    let month = today.getMonth() - 1 //por enquanto busca os pontos do mês anterior
    let start = new Date(today.getFullYear(), month, 1).toISOString().slice(0, 10)
    let end = new Date(today.getFullYear(), month + 1, 0).toISOString().slice(0, 10)
    console.log(month, start, end)
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
          console.log(v)
          if (v.hasContent == true) {
            setTimeout(() => {
              let turno = v.marcacoes[0].turno
              let seq = v.marcacoes[0].seqTurno
              this.items = v.marcacoes
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

  getHorarios(turno: string, seq: string) {
    console.log(turno, seq)
    this.pontosService.turno = turno
    this.pontosService.seq = seq
    this.pontosService.listHorarios()
      .subscribe({
        next: (v: any) => {
          console.log(v)
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
    //console.log(filter)
    filter ? this.searchItems({ data: filter, dataATE: filter }) : this.resetFilters();
  }

  onChangeDisclaimers(disclaimers: any) {
    const filter: any = {};
    console.log(disclaimers)
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
    console.log(filter)
    let start = (filter.data)
    let end = (filter.dataATE)

    if (start !== undefined && end != undefined) {
      start = start.replaceAll('-', '')
      end = end.replaceAll('-', '')
    } else if (start !== undefined && end == undefined) {
      start = start.replaceAll('-', '')
      end = new Date().toISOString().slice(0, 10);
      end = end.replaceAll('-', '')
    }
    this.getlist(start, end);
  }
  private resetFilters() {
    this.getlist()
  }


  public openPDF(): void {
    var html = 'Empresa: BCI Comercializadora           cnpj: 19.191.0101/100-00'
    /* let printContents: any = document.getElementById('htmlData');
    var originalContents = document.body.innerHTML;

    document.body.innerHTML = printContents.innerHTML;

    window.print();

    document.body.innerHTML = originalContents; */
    let DATA: any = document.getElementById('htmlData');
    html2canvas(DATA).then((canvas) => {
      let fileWidth = 208;
      let fileHeight = (canvas.height * fileWidth) / canvas.width;
      const FILEURI = canvas.toDataURL('image/png');
      let PDF = new jsPDF('p', 'mm', 'a4');
      let position = 50;
      
      PDF.text(html, 20, 20, {baseline: 'top'})
      //PDF.addPage()
      PDF.addImage(FILEURI, 'PNG', 0, position, fileWidth, fileHeight);
      PDF.save('espelho-ponto.pdf');
    });
  }

  downloadPDFWithBrowserPrint() {
    window.print();
  }

}
