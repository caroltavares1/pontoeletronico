import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { PoDynamicModule } from '@po-ui/ng-components';
import { SharedModule } from '../shared/shared.module';
import { DemonstrativoRoutingModule } from './demonstrativo-routing.module';
import { FeriasComponent } from './ferias/ferias.component';
import { PagamentoComponent } from './pagamento/pagamento.component';

@NgModule({
  declarations: [
    FeriasComponent,
    PagamentoComponent
  ],
  imports: [
    CommonModule,
    DemonstrativoRoutingModule,
    PoDynamicModule,
    SharedModule
  ]
})
export class DemonstrativoModule { }
