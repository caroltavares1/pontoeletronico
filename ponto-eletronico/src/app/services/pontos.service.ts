import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { map } from 'rxjs';
import { environment } from 'src/environments/environment';
import { UserService } from '../services/user.service';

const auth = environment.authorization

const httpOptions = {
  headers: new HttpHeaders(
    {
      'Content-Type': 'application/json',
      'Authorization': auth,
    }
  )
};

@Injectable({
  providedIn: 'root'
})
export class PontosService {

  apiURL = environment.apiURL;
  turno = ''
  seq = ''

  resumo: Array<any> = [
    {
      codigo: '001',
      descricao: 'HORAS NORMAIS',
      calculo: 159.29,
      inform: 0.00
    },
    {
      codigo: '014',
      descricao: 'SAIDA ANTECIPADA',
      calculo: 7.29,
      inform: 0.00
    }
  ]

  constructor(private userService: UserService, private http: HttpClient) { }


  public list(dtini?: string, dtfin?: string) {
    let filial = this.userService.filatu
    let mat = this.userService.matricula
    let url = ''
    if (dtini == undefined && dtfin == undefined)
      url = this.apiURL+ `/marcacoes/?filial=${filial}&matricula=${mat}`
    else
      url = this.apiURL+ `/marcacoes/?filial=${filial}&matricula=${mat}&dtinicial=${dtini}&dtfinal=${dtfin}`

    return this.http.get<any>(url, httpOptions,  ).pipe(
      map((resposta: any) => resposta)
    );
  }
  public listHorarios() {
    let url = this.apiURL+ `/turnos/?turno=${this.turno}&seq=${this.seq}`
    return this.http.get<any>(url, httpOptions,  ).pipe(
      map((resposta: any) => resposta)
    );
  }

  public getBancoHoras(dtini: string, dtfin: string){
    let filial = this.userService.filatu
    let mat = this.userService.matricula
    let url = this.apiURL + `/bh/?FILIAL=${filial}&MATRICULA=${mat}&DTINICIAL=${dtini}&DTFINAL=${dtfin}`
    return this.http.get<any>(url, httpOptions,  ).pipe(
      map((resposta: any) => resposta)
    );
  }

  public listResumo() {
    return this.resumo
  }
}
