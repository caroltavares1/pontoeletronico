import { Component, OnInit } from '@angular/core';
import { PoDynamicViewField, PoNotificationService } from '@po-ui/ng-components';
import { ExportToPDFService } from '../../services/exportToPDF.service';
import { UserService } from '../../services/user.service';

@Component({
  selector: 'app-info',
  templateUrl: './info.component.html',
  styleUrls: ['./info.component.css']
})
export class InfoComponent implements OnInit {

  dados: any = {}
  funcionario = {}
  empresa: any = {}
  hidden = false

  fields: Array<PoDynamicViewField> = [
    { property: 'empresa', divider: 'Empresa', gridColumns: 8, gridSmColumns: 6, order: 1 },
    { property: 'cnpj', label: 'CNPJ', gridColumns: 4, gridSmColumns: 6 },
    { property: 'endereco', gridColumns: 8, gridSmColumns: 6 },
    { property: 'emissao', label: 'Emissão', gridColumns: 4, gridSmColumns: 6, format: 'dd/MM/yyyy' },
    { property: 'matricula', label: 'Matrícula', gridColumns: 3, gridSmColumns: 4, divider: 'Funcionário' },
    { property: 'nome', label: 'Nome', gridColumns: 6, gridSmColumns: 4 },
    { property: 'admissao', label: 'Admissão', gridColumns: 3, gridSmColumns: 4, format: 'dd/MM/yyyy' },
    { property: 'funcao', label: 'Função', gridColumns: 3, gridSmColumns: 4 },
    { property: 'cc', label: 'C.C.', gridColumns: 3, gridSmColumns: 4 },
    { property: 'cpf', label: 'CPF', gridColumns: 3, gridSmColumns: 4 },
    { property: 'categoria', label: 'Categoria', gridColumns: 3, gridSmColumns: 4 },
    { property: 'situacao', label: 'Situação', gridColumns: 3, gridSmColumns: 4 },
    { property: 'departamento', label: 'Departamento', gridColumns: 4, gridSmColumns: 4 },

  ];
  constructor(
    private userService: UserService,
    private poNotification: PoNotificationService,
    private pdf: ExportToPDFService
  ) { }

  ngOnInit(): void {
    this.getEmpresa()
    this.funcionario = this.userService.getUser()
      .subscribe({
        next: (v: any) => {
          if (v.user !== undefined) {
            setTimeout(() => {
              this.userService.matricula = v.user[0].matricula
              v.user[0].admissao = new Date(v.user[0].admissao).toLocaleDateString()
              v.user[0].cpf = this.formataCPF(v.user[0].cpf)
              this.funcionario = v.user[0]
              this.dados = { ...this.funcionario, ...this.empresa }
              this.pdf.setHeader(this.dados)
              this.hidden = true
            }, 800);
          } else {
            this.poNotification.error(v.message)
          }
        },
        error: (e: any) => this.poNotification.error("Error"),
      })
  }

  private formataCPF(cpf: string): string {
    return (cpf.substring(0, 3) + '.' + cpf.substring(3, 6) + '.' + cpf.substring(6, 9) + '-' + cpf.substring(9))
  }
  private formataCNPJ(cnpj: string): String {
    //'12.103.781/0001-29'
    return (cnpj.substring(0, 2)) + '.' + cnpj.substring(2, 5) + '.' + cnpj.substring(5, 8) + '/' + cnpj.substring(8, 12) + '-' + cnpj.substring(12)
  }

  public getEmpresa() {
    this.empresa = this.userService.getFilial()
      .subscribe({
        next: (v: any) => {
          if (v.hasContent == true) {
            setTimeout(() => {
              v.cgc = this.formataCNPJ(v.cgc)
              this.empresa = {
                empresa: v.nome,
                cnpj: v.cgc,
                endereco: v.endereco,
                emissao: new Date().toLocaleDateString()
              }
            }, 200);
          } else {
            this.empresa = {
              empresa: '',
              cnpj: '',
              endereco: '',
              emissao: new Date().toLocaleDateString()
            }
            console.log(v.message)
          }
        },
        error: (e: any) => console.log(e.message)
      })

  }

}
