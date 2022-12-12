import { Component, OnInit } from '@angular/core';
import { PoMenuItem } from '@po-ui/ng-components';

@Component({
  selector: 'app-home',
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.css']
})
export class HomeComponent implements OnInit {

  constructor() { }

  public readonly menus: Array<PoMenuItem> = [
    { label: 'Info', link: '/user/info', icon: "po-icon-user", shortLabel: 'Info' },
    { label: 'Pontos', link: '/user/list', icon: "po-icon-calendar-ok", shortLabel: 'Pontos' },
    { label: 'Editar usuário', icon: "po-icon-edit", shortLabel: 'Editar' }
  ];

  ngOnInit(): void {
  }

}
