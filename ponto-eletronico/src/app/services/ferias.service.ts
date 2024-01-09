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
  itensFerias!: Array<Object>;

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

  getPrevFerias(filial: string, matricula: string): Observable<any> {
    const options = httpOptions;
    options.params = {
      filial: filial,
      matricula: matricula,
    };

    let url = this.apiURL + `/programacaoFerias/`;
    return this.http.get<any>(url, options);
  }

  getItensferias(filial: string, matricula: string, dataFerias: string): Observable<any> {
    const options = httpOptions;
    options.params = {
      filial: filial,
      matricula: matricula,
      data: dataFerias,
    };

    let url = this.apiURL + `/detalhesFerias/`;
    let resp = this.http.get(url, options);
    setTimeout(() => {
      return resp;
    }, 5000);
    return resp;
  }
}
