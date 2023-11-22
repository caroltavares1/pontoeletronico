import { Component, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';

import {
  PoCheckboxGroupOption,
  PoMultiselectOption,
} from '@po-ui/ng-components';

import {
  PoDialogService,
  PoModalAction,
  PoModalComponent,
  PoNotificationService,
  PoPageAction,
  PoPageFilter,
  PoPageListComponent,
  PoTableColumn,
} from '@po-ui/ng-components';
import { FeriasService } from 'src/app/services/ferias.service';

@Component({
  selector: 'app-ferias',
  templateUrl: './ferias.component.html',
  styleUrls: ['./ferias.component.css'],
})
export class FeriasComponent implements OnInit {
  @ViewChild('advancedFilterModal', { static: true })
  advancedFilterModal!: PoModalComponent;
  @ViewChild('poPageList', { static: true }) poPageList!: PoPageListComponent;

  disclaimerGroup: any;
  hiringProcesses!: Array<object>;
  hiringProcessesColumns!: Array<PoTableColumn>;
  hiringProcessesFiltered!: Array<object>;
  jobDescription: Array<string> = [];
  jobDescriptionOptions!: Array<PoMultiselectOption>;
  labelFilter: string = '';
  status: Array<string> = [];
  statusOptions!: Array<PoCheckboxGroupOption>;

  public readonly actions: Array<PoPageAction> = [
    {
      label: 'Prévia',
      action: this.hireCandidate.bind(this),
      disabled: this.disableHireButton.bind(this),
    },
  ];

  public readonly advancedFilterPrimaryAction: PoModalAction = {
    action: () => {
      this.poPageList.clearInputSearch();
      this.advancedFilterModal.close();
      const filters = [...this.jobDescription, ...this.status];
      this.filterAction(filters);
    },
    label: 'Apply filters',
  };

  public readonly filterSettings: PoPageFilter = {
    action: this.filterAction.bind(this),
    advancedAction: this.advancedFilterActionModal.bind(this),
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

    this.hiringProcesses = this.feriasService.getItems();
    this.hiringProcessesColumns = this.feriasService.getColumns();
    this.jobDescriptionOptions = this.feriasService.getJobs();
    this.statusOptions = this.feriasService.getHireStatus();

    this.hiringProcessesFiltered = [...this.hiringProcesses];
  }

  advancedFilterActionModal() {
    this.advancedFilterModal.open();
  }

  disableHireButton() {
    return !this.hiringProcesses.find(
      (candidate: any) => candidate['$selected']
    );
  }

  filter() {
    const filters = this.disclaimers.map((disclaimer: any) => disclaimer.value);
    filters.length
      ? this.hiringProcessesFilter(filters)
      : this.resetFilterHiringProcess();
  }

  filterAction(labelFilter: string | Array<string>) {
    const filter =
      typeof labelFilter === 'string' ? [labelFilter] : [...labelFilter];
    this.populateDisclaimers(filter);
    this.filter();
  }

  hireCandidate() {
    const selectedCandidate: any = this.hiringProcesses.find(
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

  hiringProcessesFilter(filters: any) {
    this.hiringProcessesFiltered = this.hiringProcesses.filter((item: any) =>
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
    this.hiringProcessesFiltered = [...this.hiringProcesses];
    this.status = [];
    this.jobDescription = [];
  }

  private beforeRedirect(itemBreadcrumbLabel: any) {
    if (this.hiringProcesses.some((candidate: any) => candidate['$selected'])) {
      this.poDialog.confirm({
        title: `Confirm redirect to ${itemBreadcrumbLabel}`,
        message: `There is data selected. Are you sure you want to quit?`,
        confirm: () => this.router.navigate(['/']),
      });
    } else {
      this.router.navigate(['/']);
    }
  }
}
