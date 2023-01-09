import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { HttpClientModule } from '@angular/common/http';
import { AppRoutingModule } from './app-routing.module';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';

import { PoModule } from '@po-ui/ng-components';
import { PoTemplatesModule } from '@po-ui/ng-templates';

//componentes
import { AppComponent } from './app.component';
import { LoginComponent } from './login/login.component';
import { HomeComponent } from './home/home.component';

//componentes PO-UI
import { PoPageLoginModule } from '@po-ui/ng-templates';
import { PoMenuModule } from '@po-ui/ng-components';
import { UserService } from './services/user.service';
import { AuthGuard } from './auth/auth.guard';
import { AuthService } from './auth/auth.service';



@NgModule({
  declarations: [
    AppComponent,
    LoginComponent,
    HomeComponent
  ],
  imports: [
    BrowserModule,
    HttpClientModule,
    PoModule,
    PoTemplatesModule,
    AppRoutingModule,
    PoPageLoginModule,
    PoMenuModule,
    FormsModule,
    ReactiveFormsModule,
  ],
  providers: [UserService, AuthGuard, AuthService],
  bootstrap: [AppComponent]
})
export class AppModule { }
