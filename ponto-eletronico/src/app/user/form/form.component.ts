import { Component, OnInit } from '@angular/core';
import { Form, NgForm } from '@angular/forms';
import { PoDialogService, PoNotificationService } from '@po-ui/ng-components';
import { UserService } from '../../services/user.service';

@Component({
  selector: 'app-form',
  templateUrl: './form.component.html',
  styleUrls: ['./form.component.css']
})
export class FormComponent implements OnInit {
  password: string = '';
  confirmNewPassword: string = '';
  newPassword: string = '';

  constructor(
    private poAlert: PoDialogService,
    private userService: UserService,
    private poNotification: PoNotificationService
  ) { }


  ngOnInit(): void {
  }

  setPassword(passwordForm: NgForm) {

    if (this.confirmNewPassword === this.newPassword) {
      this.userService.altPassword(this.password, this.newPassword)
        .subscribe({
          next: (v: any) => {
            if (v.message.includes('sucesso')) {
              this.poNotification.success(v.message)
              passwordForm.form.reset()
            } else {
              this.poNotification.error(v.message)
            }
          },
          error: (e: any) => this.poNotification.error("Error"),
          complete: () => {
            this.password = '',
              this.newPassword = '',
              this.confirmNewPassword = ''
          }
        })
    } else {
      this.poAlert.alert({
        title: 'Erro',
        message: 'Sua (nova senha) é diferente da (confirmar nova senha)',
        ok: () => this.reset()
      });
    }
  }

  reset() {
    this.newPassword = '';
    this.confirmNewPassword = '';
  }
}