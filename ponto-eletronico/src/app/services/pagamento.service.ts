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

@Injectable({
  providedIn: 'root',
})
export class PagamentoService {
  ferias: any[] = [];
  apiURL = environment.apiURL;
  itensFerias!: Array<Object>;

  constructor(private http: HttpClient) {}

  getColumns(): Array<PoTableColumn> {
    return [
      {
        property: 'empresa',
        label: 'Empresa',
        type: 'string',
      },
      {
        property: 'filial',
        label: 'Filial',
        type: 'string',
      },
      {
        property: 'matricula',
        label: 'Matricula',
        type: 'string',
      },
      {
        property: 'ano',
        label: 'Ano',
        type: 'string',
      },
      {
        property: 'mes',
        label: 'Mês',
        type: 'string',
      },
      {
        property: 'semana',
        label: 'Semana',
        type: 'string',
      },
      {
        property: 'roteiro',
        label: 'Cod. Tipo - Descrição',
        type: 'string',
      },
    ];
  }

  getOptions() {
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

  getFolhaPagto(cpf: string): Observable<any> {
    const options = httpOptions;
    options.params = {
      cpf: cpf,
    };

    let url = this.apiURL + `/folhaPagto/`;
    return this.http.get<any>(url, options);
  }

  getItensPagto(
    cpf: string,
  ): Observable<any> {
    const options = httpOptions;
    options.params = {
      cpf: cpf,
    };

    let url = this.apiURL + `/detalhesFerias/`;
    let resp = this.http.get(url, options);
    setTimeout(() => {
      return resp;
    }, 5000);
    return resp;
  }
}
