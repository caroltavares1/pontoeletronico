import { Component, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';

import { PoCheckboxGroupOption } from '@po-ui/ng-components';

import {
  PoDialogService,
  PoNotificationService,
  PoPageAction,
  PoPageFilter,
  PoPageListComponent,
  PoTableColumn,
} from '@po-ui/ng-components';
import { FeriasService } from 'src/app/services/ferias.service';
import { Matricula } from './matriculas.model';

@Component({
  selector: 'app-ferias',
  templateUrl: './ferias.component.html',
  styleUrls: ['./ferias.component.css'],
})
export class FeriasComponent implements OnInit {
  @ViewChild('poPageList', { static: true }) poPageList!: PoPageListComponent;

  disclaimerGroup: any;
  processoFerias!: Array<object>;
  processoFeriasColumns!: Array<PoTableColumn>;
  processoFeriasFiltered!: Array<object>;
  labelFilter: string = '';
  status: Array<string> = [];
  statusOptions!: Array<PoCheckboxGroupOption>;
  matriculas! : Matricula []
  options : any = []

  public readonly actions: Array<PoPageAction> = [
    {
      label: 'Prévia',
      action: this.hireCandidate.bind(this),
      disabled: this.disableHireButton.bind(this),
    },
  ];

  setOptions(){
    this.matriculas.forEach( el =>{
      this.options.push({ value : 'Filial: '+el.filial+'/'+'Matricula: '+el.matricula+' - Nome: '+el.nome})
    })
  }

  public readonly filterSettings: PoPageFilter = {
    action: this.filterAction.bind(this),
    placeholder: 'Procurar',
  };

  private disclaimers: any = [];

  constructor(
    private feriasService: FeriasService,
    private poNotification: PoNotificationService,
    private poDialog: PoDialogService,
    private router: Router
  ) {}


  ngOnInit() {
    this.disclaimerGroup = {
      title: 'Filters',
      disclaimers: [],
      change: this.onChangeDisclaimer.bind(this),
      remove: this.onClearDisclaimer.bind(this),
    };

    this.processoFerias = this.feriasService.getItems();
    this.processoFeriasColumns = this.feriasService.getColumns();
    this.statusOptions = this.feriasService.getHireStatus();

    this.processoFeriasFiltered = [...this.processoFerias];
    this.getMatriculas()
    this.setOptions()
  }

  disableHireButton() {
    return !this.processoFerias.find(
      (candidate: any) => candidate['$selected']
    );
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

  hireCandidate() {
    const selectedCandidate: any = this.processoFerias.find(
      (candidate: any) => candidate['$selected']
    );

    console.log(selectedCandidate);

    if (selectedCandidate != undefined) {
      switch (selectedCandidate['hireStatus']) {
        case 'progress':
          selectedCandidate['hireStatus'] = 'hired';
          this.poNotification.success('Hired candidate!');
          break;

        case 'hired':
          this.poNotification.warning('This candidate has already been hired.');
          break;

        case 'canceled':
          this.poNotification.error(
            'This candidate has already been disqualified.'
          );
          break;
      }
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
    // this.jobDescription = [];
  }

  getMatriculas() {
    let cpf = '00976379473';
    this.feriasService.getMatriculas(cpf).subscribe((mat) => {
      localStorage.setItem('matriculas', JSON.stringify(mat.matriculas));
    });
    let dados = localStorage.getItem('matriculas')

    if (dados != undefined && dados != null){
      this.matriculas = JSON.parse(dados)
    }
  }
}
