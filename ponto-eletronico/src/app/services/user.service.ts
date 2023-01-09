import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { map, Observable, take } from 'rxjs';
import { environment } from 'src/environments/environment';

const auth = environment.authorization

const httpOptions = {
  headers: new HttpHeaders(
    {
      'Content-Type': 'application/json',
      'Authorization': auth,
    }
  ),
  params : {}
};

@Injectable({
  providedIn: 'root'
})
export class UserService {

  userCPF = ''
  filatu = ''
  matricula = ''
  apiURL = environment.apiURL;

  constructor(private http: HttpClient) { }

  public login(formData: any): Observable<any> {
    const options = httpOptions
    options.params = {
      'cpf' : formData.login,
      'senha' : formData.password
    }
    
    return this.http.get<any>(this.apiURL + `/participantes/`, options).pipe(
      map((resposta: any) => resposta)
    );
  }

  public getUser(): Observable<any> {
    const options = httpOptions
    options.params = {
      'cpf' : this.userCPF
    }

    return this.http.get<any>(this.apiURL + `/funcionarios/`, options).pipe(
      map((resposta: any) => resposta)
    );
  }

  public getFilial(): Observable<any> {
    const options = httpOptions
    options.params = {
      'filial' : this.filatu
    }

    return this.http.get<any>(this.apiURL + `/filiais/`, options).pipe(
      map((resposta: any) => resposta)
    );
  }

  public getUserCPF(){
    return this.userCPF
  }

  public altPassword(senhaAtual: string, novaSenha: string) {
    let body = {
      cpf: this.userCPF,
      senhaAtual : senhaAtual,
      novaSenha: novaSenha
    }
    return this.http.put<any>(this.apiURL + '/participantes/', JSON.stringify(body), httpOptions).pipe(take(1))

  }

  public resetPassword(cpf: string, senha: string){
    let url = this.apiURL+`/participantes/reset/?cpf=${cpf}&senha=${senha}`
    return this.http.put<any>(url, httpOptions).pipe(take(1))

  }
}
