import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router'; // MUY IMPORTANTE para el routerLink

// Módulos de Angular Material para la navegación
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatSidenavModule } from '@angular/material/sidenav';
import { MatListModule } from '@angular/material/list';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    CommonModule,
    RouterModule, // Lo necesitamos para <router-outlet> y routerLink
    MatToolbarModule,
    MatButtonModule,
    MatIconModule,
    MatSidenavModule,
    MatListModule
  ],
  templateUrl: './app.component.html', // O './app.html' dependiendo de tu archivo
  styleUrls: ['./app.component.css']
})
export class AppComponent {
  title = 'Sistema Quiniela Mundialista 2026';
}