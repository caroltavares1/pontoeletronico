import { Component, OnInit, ViewChild } from '@angular/core';

import { PoCheckboxGroupOption } from '@po-ui/ng-components';

import {
  PoNotificationService,
  PoPageAction,
  PoPageFilter,
  PoPageListComponent,
  PoTableColumn,
} from '@po-ui/ng-components';
import { FeriasService } from 'src/app/services/ferias.service';
import { FeriasPDFService } from 'src/app/services/feriasPDF.service';
import { UserService } from 'src/app/services/user.service';
import { Ferias } from './ferias.model';
import { Matricula } from './matriculas.model';

@Component({
  selector: 'app-ferias',
  templateUrl: './ferias.component.html',
  styleUrls: ['./ferias.component.css'],
})
export class FeriasComponent implements OnInit {
  @ViewChild('poPageList', { static: true }) poPageList!: PoPageListComponent;

  disclaimerGroup: any;
  processoFerias: Array<object> = [];
  processoFeriasColumns!: Array<PoTableColumn>;
  processoFeriasFiltered!: Array<object>;
  labelFilter: string = '';
  status: Array<string> = [];
  statusOptions!: Array<PoCheckboxGroupOption>;
  matriculas: Array<Matricula> = [];
  options: any = [];
  matriculaSelecionada!: Matricula;
  filial: any;
  cabecalho: any;
  funcionario: any;
  itensFerias: any = [];

  public readonly actions: Array<PoPageAction> = [
    {
      label: 'Imprimir',
      action: this.imprimirRecibo.bind(this),
      disabled: this.disableHireButton.bind(this),
    },
  ];

  setOptions() {
    if (this.matriculas.length > 0) {
      this.matriculas.forEach((el) => {
        this.options.push({
          value: el,
          label:
            'Filial: ' +
            el.filial +
            '/' +
            'Matricula: ' +
            el.matricula +
            ' - Empresa: ' +
            el.razao,
        });
      });
    }
  }

  public readonly filterSettings: PoPageFilter = {
    action: this.filterAction.bind(this),
    placeholder: 'Procurar',
  };

  private disclaimers: any = [];

  constructor(
    private feriasService: FeriasService,
    private poNotification: PoNotificationService,
    private userService: UserService,
    private pdf: FeriasPDFService
  ) {}

  ngOnInit() {
    this.disclaimerGroup = {
      title: 'Filters',
      disclaimers: [],
      change: this.onChangeDisclaimer.bind(this),
      remove: this.onClearDisclaimer.bind(this),
    };
    this.processoFeriasColumns = this.feriasService.getColumns();
    this.statusOptions = this.feriasService.getHireStatus();
    this.processoFeriasFiltered = [...this.processoFerias];
    this.getMatriculas();
    this.setOptions();
    this.getFilial();
  }

  getFilial() {
    this.filial = this.userService.getFilial().subscribe((resp) => {
      this.filial = resp;
    });
  }

  disableHireButton() {
    return !this.processoFerias.find((recibo: any) => recibo['$selected']);
  }

  filter() {
    const filters = this.disclaimers.map((disclaimer: any) => disclaimer.value);
    filters.length
      ? this.processoFeriasFilter(filters)
      : this.resetFilterHiringProcess();
  }

  filterAction(labelFilter: string | Array<string>) {
    const filter =
      typeof labelFilter === 'string' ? [labelFilter] : [...labelFilter];
    this.populateDisclaimers(filter);
    this.filter();
  }

  imprimirRecibo() {
    const periodoSelecionado: any = this.processoFerias.find(
      (recibo: any) => recibo['$selected']
    );

    if (periodoSelecionado != undefined) {
      this.pdf.setHeader(periodoSelecionado);
      this.cabecalho = periodoSelecionado;
      this.pdf.openPDF(this.cabecalho);
    }
  }

  processoFeriasFilter(filters: any) {
    this.processoFeriasFiltered = this.processoFerias.filter((item: any) =>
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
    this.processoFeriasFiltered = [...this.processoFerias];
    this.status = [];
  }

  getMatriculas() {
    let dados = localStorage.getItem('matriculas');
    if (dados != undefined && dados != null) {
      this.matriculas = JSON.parse(dados);
    }
  }

  onSelect(matricula: any) {
    const value = matricula.value;
    if (value != null) {
      this.userService.getFilialById(value.filial).subscribe((resp) => {
        this.setFilial(resp);
      });

      this.userService.getUser().subscribe((func) => {
        this.setFuncionario(func.user);
      });

      this.feriasService
        .getPrevFerias(value.filial, value.matricula)
        .subscribe((data) => {
          if (data.hasContent) {
            let lista : Array<any> = data.programacaoFerias as [];
            lista.sort( (a, b) => b.iniPerAq - a.iniPerAq)
            lista.forEach((el: Ferias) => {
              this.processoFerias.push({
                periodoAquisitivo:
                  'DE ' +
                  this.convertData(el.iniPerAq, '/', true) +
                  ' A ' +
                  this.convertData(el.fimPerAq, '/', true),
                periodoGozo:
                  'DE ' +
                  this.convertData(el.iniFerias, '/', true) +
                  ' A ' +
                  this.convertData(el.fimFerias, '/', true),
                diasAbono: this.calcDias(el.iniFerias, el.fimFerias),
                empresa: this.filial,
                ferias: el,
                matricula: matricula.value,
                funcionario: this.funcionario,
              });
            });
            this.processoFeriasFiltered = [...this.processoFerias];
          } else {
            this.processoFerias = [];
            this.processoFeriasFiltered = [...this.processoFerias];
          }
        });
    }
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
