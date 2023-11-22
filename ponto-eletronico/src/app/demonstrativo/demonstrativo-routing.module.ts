import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { FeriasComponent } from './ferias/ferias.component';
import { PagamentoComponent } from './pagamento/pagamento.component';

const routes: Routes = [
  { path: 'ferias', component: FeriasComponent, /* canDeactivate: [AuthGuard] */ },
  { path: 'pagamento', component: PagamentoComponent, /* canDeactivate: [AuthGuard] */ },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class DemonstrativoRoutingModule { }
