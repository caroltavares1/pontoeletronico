import { Injectable } from '@angular/core';

import { HttpClient, HttpHeaders } from '@angular/common/http';
import { PoTableColumn } from '@po-ui/ng-components';
import { Observable, map } from 'rxjs';
import { environment } from 'src/environments/environment';

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
  ferias: any[] = [];
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

  getPrevFerias(filial: string, matricula: string) : Observable<any>{
    const options = httpOptions;
    options.params = {
      filial: filial,
      matricula: matricula,
    };

    let url = this.apiURL + `/programacaoFerias/`;

    let response = this.http
      .get<any>(url, options)
      .pipe(map((resposta: any) => resposta));
    return response;
  }
}
