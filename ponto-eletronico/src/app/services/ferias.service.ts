import { Injectable } from '@angular/core';

import { HttpClient, HttpHeaders } from '@angular/common/http';
import { PoTableColumn } from '@po-ui/ng-components';
import { Observable, map } from 'rxjs';
import { environment } from 'src/environments/environment';
import { Ferias } from '../demonstrativo/ferias/ferias.model';

const auth = environment.authorization;

const httpOptions = {
  headers: new HttpHeaders({
    'Content-Type': 'application/json',
    Authorization: auth,
  }),
  params: {},
};

@Injectable()
export class FeriasService {
  ferias: Ferias[] = [];
  apiURL = environment.apiURL;

  constructor(private http: HttpClient) {}

  getColumns(): Array<PoTableColumn> {
    return [
      {
        property: 'periodoAquisitivo',
        label: 'Periodo Aquisitivo',
        type: 'string',
      },
      {
        property: 'periodoGozo',
        label: 'Periodo de Gozo das Férias',
        type: 'string',
      },
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
      diasAbono: 10,
    });

    this.ferias.push({
      periodoAquisitivo: 'DE 03/01/2021 A 02/01/2022',
      periodoGozo: 'DE 07/03/2022 A 26/03/2022',
      diasAbono: 10,
    });

    return this.ferias;
  }

  getMatriculas(userCpf: string): Observable<any> {
    const options = httpOptions;
    options.params = {
      cpf: userCpf,
    };

    let url = this.apiURL + `/matriculas/`;

    return this.http
      .get<any>(url, options)
      .pipe(map((resposta: any) => resposta));
  }
}
