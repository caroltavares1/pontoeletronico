import { Component, OnInit, ViewChild } from '@angular/core';

import { PoCheckboxGroupOption } from '@po-ui/ng-components';

import {
  PoPageAction,
  PoPageFilter,
  PoPageListComponent,
  PoTableColumn,
} from '@po-ui/ng-components';
import { PagamentoService } from 'src/app/services/pagamento.service';
import { PagtoPDFService } from 'src/app/services/pagtoPDF.service';
import { UserService } from 'src/app/services/user.service';
import { Matricula } from '../matriculas.model';

@Component({
  selector: 'app-pagamento',
  templateUrl: './pagamento.component.html',
  styleUrls: ['./pagamento.component.css'],
})
export class PagamentoComponent implements OnInit {
  @ViewChild('poPageList', { static: true }) poPageList!: PoPageListComponent;

  disclaimerGroup: any;
  processoPagto: Array<object> = [];
  processoPagtoColumns!: Array<PoTableColumn>;
  processoPagtoFiltered!: Array<object>;
  labelFilter: string = '';
  status: Array<string> = [];
  statusOptions!: Array<PoCheckboxGroupOption>;
  matriculas: Array<Matricula> = [];
  options: any = [];
  matriculaSelecionada!: Matricula;
  filial: any;
  cabecalho: any;
  funcionario: any;
  hidden: boolean = false;
  cpf: any;

  public readonly actions: Array<PoPageAction> = [
    {
      label: 'Imprimir',
      action: this.imprimirRecibo.bind(this),
      disabled: this.disableButton.bind(this),
    },
  ];

  public readonly filterSettings: PoPageFilter = {
    action: this.filterAction.bind(this),
    placeholder: 'Procurar',
  };

  private disclaimers: any = [];

  constructor(
    private userService: UserService,
    private pdf: PagtoPDFService,
    private pagamentoService: PagamentoService
  ) { }

  ngOnInit() {
    this.disclaimerGroup = {
      title: 'Filters',
      disclaimers: [],
      change: this.onChangeDisclaimer.bind(this),
      remove: this.onClearDisclaimer.bind(this),
    };

    this.processoPagtoColumns = this.pagamentoService.getColumns();
    this.statusOptions = this.pagamentoService.getOptions();
    this.processoPagtoFiltered = [...this.processoPagto];
    this.getFilial();

    let data: any[];
    this.cpf = sessionStorage.getItem('cpf');

    if (this.cpf != null && this.cpf != undefined) {
      this.pagamentoService.getFolhaPagto(this.cpf).subscribe({
        next: (dados) => {
          data = dados.folhaPagto;
          data = data.sort( (a, b) => b.ano - a.ano || b.mes - a.mes)
          
          data = data.filter( (el)=>{
            return el.arquivo === 'SRD' || (el.arquivo === 'SRC' && el.roteiro.substring(0,1) === '1' || (el.arquivo === 'SRC' && el.ano+el.mes === el.MV_XPERFOL))
          })
        },
        
        complete: () => {
          this.processoPagto = data;
          this.processoPagtoFiltered = [...this.processoPagto];
          this.hidden = true;
        },
      });
    }
  }

  getFilial() {
    this.filial = this.userService.getFilial().subscribe((resp) => {
      this.filial = resp;
    });
  }

  disableButton() {
    return !this.processoPagto.find((recibo: any) => recibo['$selected']);
  }

  filter() {
    const filters = this.disclaimers.map((disclaimer: any) => disclaimer.value);
    filters.length
      ? this.processoPagtoFilter(filters)
      : this.resetFilterHiringProcess();
  }

  filterAction(labelFilter: string | Array<string>) {
    const filter =
      typeof labelFilter === 'string' ? [labelFilter] : [...labelFilter];
    this.populateDisclaimers(filter);
    this.filter();
  }

  imprimirRecibo() {
    

    const periodoSelecionado: any = this.processoPagto.find(
      (recibo: any) => recibo['$selected']
    );

    if (periodoSelecionado != undefined) {
      this.cabecalho = periodoSelecionado;
      this.cabecalho.cpf = this.cpf

      this.userService.getUser().subscribe({
        next: (data) => {
          this.funcionario = data.user[0]
        },
        complete: () => {
          this.cabecalho.funcionario = this.funcionario
        }
      })

      this.userService.getFilialById(this.cabecalho.filial).subscribe({
        next: (data) => {
          this.filial = data
          // console.log(this.filial)
        },
        complete: () => {
          this.cabecalho.empfil = this.filial
        }
      })

      this.pdf.openPDF(this.cabecalho);
    }
  }

  processoPagtoFilter(filters: any) {
    this.processoPagtoFiltered = this.processoPagto.filter((item: any) =>
      Object.keys(item).some(
        (key) =>
          !(item[key] instanceof Object) &&
          this.includeFilter(item[key], filters)
      )
    );
  }

  includeFilter(item: any, filters: any) {
    return filters.some((filter: any) =>
      String(item).toLocaleLowerCase().includes(filter.toLocaleLowerCase())
    );
  }

  onChangeDisclaimer(disclaimers: any) {
    this.disclaimers = disclaimers;
    this.filter();
  }

  onClearDisclaimer(disclaimers: any) {
    if (disclaimers.removedDisclaimer.property === 'search') {
      this.poPageList.clearInputSearch();
    }
    this.disclaimers = [];
    this.filter();
  }

  populateDisclaimers(filters: Array<any>) {
    const property = filters.length > 1 ? 'advanced' : 'search';
    this.disclaimers = filters.map((value) => ({ value, property }));

    if (this.disclaimers && this.disclaimers.length > 0) {
      this.disclaimerGroup.disclaimers = [...this.disclaimers];
    } else {
      this.disclaimerGroup.disclaimers = [];
    }
  }

  resetFilterHiringProcess() {
    this.processoPagtoFiltered = [...this.processoPagto];
    this.status = [];
  }

  setFilial(filial: any) {
    this.filial = filial;
  }

  setFuncionario(funcionario: any) {
    this.funcionario = funcionario[0];
  }

  convertData(data: string, separador: string, inverte: boolean) {
    let ret: string = '';
    if (inverte) {
      ret =
        data.substring(6, 8) +
        separador +
        data.substring(4, 6) +
        separador +
        data.substring(0, 4);
    } else {
      ret =
        data.substring(0, 4) +
        separador +
        data.substring(4, 6) +
        separador +
        data.substring(6, 8);
    }
    return ret;
  }

  calcDias(data1: string, data2: string) {
    const inicial = new Date(this.convertData(data1, '-', false));
    const final = new Date(this.convertData(data2, '-', false));
    const diffMs = final.getTime() - inicial.getTime();
    const diff = Math.round(diffMs / (24 * 60 * 60 * 1000));
    return diff + 1;
  }
}
