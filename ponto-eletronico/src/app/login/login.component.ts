import { Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { Router } from '@angular/router';
import { PoModalComponent, PoNotificationService } from '@po-ui/ng-components';
import { PoPageLoginLiterals } from '@po-ui/ng-templates';
import { AuthService } from '../auth/auth.service';
import { FeriasService } from '../services/ferias.service';
import { UserService } from '../services/user.service';

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css']
})


export class LoginComponent implements OnInit {
  @ViewChild(PoModalComponent, { static: true }) poModal!: PoModalComponent;

  password = ''
  cpf = ''
  customLiterals: PoPageLoginLiterals = {
    registerUrl: "Cadastrar Usuário",
    loginHint: 'Caso não possua usuário entre em contato com o suporte',
    loginPlaceholder: 'Insira seu CPF (só os números) ',
    passwordErrorPattern: 'Senha deve possuir exatamente seis caracteres numéricos.',
    loginErrorPattern: 'Login deve possuir apenas os onze digitos do seu cpf.'
  };

  loading: boolean = false;
  loginErrors: string[] = [];
  passwordErrors: string[] = [];


  myRecovery() {
    this.poModal.open()
  }

  cancelar() {
    this.poModal.close()
  }

  constructor(
    private router: Router,
    private auth: AuthService,
    private userService: UserService,
    private poNotification: PoNotificationService,
    private feriasService : FeriasService
  ) { }

  checkLogin(formData: any) {
    this.loading = true;
    this.userService.login(formData)
      .subscribe({
        next: (v: any) => {
          if (v.hasContent === true) {
            this.passwordErrors = [];
            this.loginErrors = [];
            this.userService.userCPF = v.cpf // atualiza cpf e filial de atuação
            this.userService.filatu = v.filialAtuacao
            this.auth.isLoggedIn = true //autentica
            setTimeout(() => {
              this.router.navigate(['/user/info'])
            }, 2000);
          } else {
            this.loading = false;
            formData.login = ''
            formData.password = ''
            this.poNotification.error(v.message)
          }
        },
        error: (e: any) => {
          this.loading = false
        },
        complete: () => {
          this.getMatriculas(formData.login)
        }
      })

  }

  resetPassword(form: NgForm) {
    let cpf = form.form.value.cpf
    let senha = form.form.value.password
    this.userService.resetPassword(cpf, senha)
      .subscribe({
        next: (v: any) => {
          if (v.erro == undefined) {
            this.poNotification.success("Sua senha foi resetada com sucesso")
            this.poModal.close()
          } else {
            this.poNotification.error("Senha informada não coincide com o padrão ou o CPF está incorreto. Tente novamente")
          }

        }

      })
  }

  passwordChange() {
    if (this.passwordErrors.length) {
      this.passwordErrors = [];
    }
  }

  loginChange() {
    if (this.loginErrors.length) {
      this.loginErrors = [];
    }
  }

  ngOnInit(): void {
  }

  getMatriculas(cpf : string) {
    this.feriasService.getMatriculas(cpf).subscribe((mat) => {
      localStorage.setItem('matriculas', JSON.stringify(mat.matriculas));
    });
  }

}
