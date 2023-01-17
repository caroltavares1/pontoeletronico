import { HttpClient, HttpHeaders } from '@angular/common/http';
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
  ),
  params: {}
};

@Injectable({
  providedIn: 'root'
})
export class PontosService {

  apiURL = environment.apiURL;
  turno = ''
  seq = ''


  constructor(private userService: UserService, private http: HttpClient) { }


  public list(dtini?: string, dtfin?: string) {
    console.log(dtini, dtfin)
    let filial = this.userService.filatu
    let mat = this.userService.matricula
    const options = httpOptions
    options.params = {
      'filial': filial,
      'matricula': mat,
      'dtinicial': dtini,
      'dtfinal': dtfin
    }
    let url = this.apiURL + `/marcacoes/`

    return this.http.get<any>(url, options,).pipe(
      map((resposta: any) => resposta)
    );
  }
  public listHorarios() {
    let filial = this.userService.filatu
    const options = httpOptions
    options.params = {
      'turno': this.turno,
      'seq': this.seq,
      'filial': filial
    }
    let url = this.apiURL + `/turnos/`
    return this.http.get<any>(url, options,).pipe(
      map((resposta: any) => resposta)
    );
  }

  public getBancoHoras(dtini: string, dtfin: string) {
    let filial = this.userService.filatu
    let mat = this.userService.matricula
    const options = httpOptions
    options.params = {
      'filial': filial,
      'matricula': mat,
      'dtinicial': dtini,
      'dtfinal': dtfin
    }
    let url = this.apiURL + `/bh/`
    return this.http.get<any>(url, options,).pipe(
      map((resposta: any) => resposta)
    );
  }
}
