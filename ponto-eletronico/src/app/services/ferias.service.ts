import { Injectable } from '@angular/core';

import { PoTableColumn } from '@po-ui/ng-components';
import { Ferias } from '../demonstrativo/ferias/ferias.model';

@Injectable()
export class FeriasService {
  ferias : Ferias [] = []
  
  getColumns(): Array<PoTableColumn> {
    return [
      { property: 'periodoAquisitivo', label: 'Periodo Aquisitivo', type: 'string' },
      { property: 'periodoGozo', label: 'Periodo de Gozo das Férias', type: 'string' },
      { property: 'diasAbono', label: 'Dias de Abono', type: 'number' },
    ];
  }

  getHireStatus() {
    return [
      { value: 'hired', label: 'Hired' },
      { value: 'progress', label: 'Progress' },
      { value: 'canceled', label: 'Canceled' },
    ];
  }

  getItems() {
    this.ferias.push({
      periodoAquisitivo: 'DE 03/01/2022 A 02/01/2023',
      periodoGozo: 'DE 20/03/2023 A 08/04/2023',
      diasAbono: 10
    })
    
    this.ferias.push({
      periodoAquisitivo: 'DE 03/01/2021 A 02/01/2022',
      periodoGozo: 'DE 07/03/2022 A 26/03/2022',
      diasAbono: 10
    })
    
    return this.ferias
  }

  getJobs() {
    return [
      { value: 'Systems Analyst', label: 'Systems Analyst' },
      { value: 'Trainee', label: 'Trainee' },
      { value: 'Programmer', label: 'Programmer' },
      { value: 'Web Developer', label: 'Web developer' },
      { value: 'Recruiter', label: 'Recruiter' },
      { value: 'Consultant', label: 'Consultant' },
      { value: 'DBA', label: 'DBA' },
    ];
  }
}
