import { Component, HostListener, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { PoMenuItem, PoToolbarAction } from '@po-ui/ng-components';
import { AuthService } from '../auth/auth.service';

@Component({
  selector: 'app-home',
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.css'],
})
export class HomeComponent implements OnInit {
  constructor(private router: Router, private auth: AuthService) {}

  actions: Array<PoToolbarAction> = [
    { label: 'Sair', icon: 'po-icon-exit', action: this.logout.bind(this) },
  ];

  public readonly menus: Array<PoMenuItem> = [
    {
      label: 'Dados do Funcionário',
      link: '/user/info',
      icon: 'po-icon-user',
      shortLabel: 'Info',
    },
    {
      label: 'Ponto',
      link: '/user/list',
      icon: 'po-icon-calendar-ok',
      shortLabel: 'Ponto',
    },
    {
      label: 'Demonstrativo',
      icon: 'po-icon po-icon-menu-open',
      shortLabel: 'Demonstrativo',
      subItems: [
        { label: 'Ferias', link: '/demonstrativo/ferias' },
        { label: 'Pagamento', link: '/demonstrativo/pagamento' },
      ],
    },
    {
      label: 'Alterar Senha',
      link: '/user/edit',
      icon: 'po-icon-edit',
      shortLabel: 'Senha',
    },
  ];

  ngOnInit(): void {}

  public logout() {
    setTimeout(() => {
      this.auth.isLoggedIn = false;
      this.router.navigate(['/login']);
    }, 1500);
  }

  @HostListener('window:beforeunload', ['$event'])
  handleKeyDown(event: BeforeUnloadEvent) {
    event.returnValue = false;
  }
}
