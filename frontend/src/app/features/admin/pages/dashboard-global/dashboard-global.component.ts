import { Component, OnDestroy, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatToolbarModule } from '@angular/material/toolbar';
import { AdminService, DashboardGlobal } from '../../services/admin.service';

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
export class DashboardGlobalComponent implements OnInit, OnDestroy {
  private readonly adminService = inject(AdminService);

  dashboard: DashboardGlobal | null = null;
  cargando = false;
  error = '';
  ultimaActualizacion: Date | null = null;
  private autoRefreshId: ReturnType<typeof setInterval> | null = null;

  ngOnInit(): void {
    this.cargarDashboard();
    this.autoRefreshId = setInterval(() => this.cargarDashboard(true), 30000);
  }

  ngOnDestroy(): void {
    if (this.autoRefreshId) {
      clearInterval(this.autoRefreshId);
      this.autoRefreshId = null;
    }
  }

  cargarDashboard(silencioso = false): void {
    if (!silencioso) {
      this.cargando = true;
    }
    this.error = '';

    this.adminService.getDashboardGlobal().subscribe({
      next: (response) => {
        this.dashboard = response;
        this.cargando = false;
        this.ultimaActualizacion = new Date();
      },
      error: (err) => {
        this.dashboard = null;
        this.cargando = false;
        this.error = err?.error?.detail ?? 'Hubo un problema al obtener los datos del dashboard.';
        console.error('Error al cargar dashboard:', err);
      },
    });
  }
}
