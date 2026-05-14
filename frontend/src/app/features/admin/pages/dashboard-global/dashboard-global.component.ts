import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatToolbarModule } from '@angular/material/toolbar';
import { AdminService, DashboardGlobal } from '../../services/admin.service';
import { finalize, retry, take, timer } from 'rxjs';

@Component({
  selector: 'app-dashboard-global',
  standalone: true,
  imports: [
    CommonModule,
    MatButtonModule,
    MatCardModule,
    MatIconModule,
    MatProgressSpinnerModule,
    MatToolbarModule,
  ],
  templateUrl: './dashboard-global.component.html',
  styleUrls: ['./dashboard-global.component.css'],
})
export class DashboardGlobalComponent implements OnInit {
  private readonly adminService = inject(AdminService);

  dashboard: DashboardGlobal | null = null;
  cargando = false;
  error = '';
  ultimaActualizacion: Date | null = null;
  private requestActiva = false;

  ngOnInit(): void {
    this.cargarDashboard();
  }

  cargarDashboard(silencioso = false): void {
    if (this.requestActiva) {
      return;
    }

    if (!silencioso) {
      this.cargando = true;
      this.error = '';
    }
    this.requestActiva = true;

    this.adminService
      .getDashboardGlobal()
      .pipe(
        take(1),
        retry({ count: 1, delay: () => timer(1000) }),
        finalize(() => {
          this.requestActiva = false;
          this.cargando = false;
        }),
      )
      .subscribe({
        next: (response) => {
          this.dashboard = response;
          this.ultimaActualizacion = new Date();
        },
        error: (err) => {
          this.error = err?.error?.detail ?? 'Hubo un problema al obtener los datos del dashboard.';
          console.error('Error al cargar dashboard:', err);
        },
      });
  }
}
