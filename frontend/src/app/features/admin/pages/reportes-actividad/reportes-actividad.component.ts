import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatTableModule } from '@angular/material/table';
import { MatToolbarModule } from '@angular/material/toolbar';
import { ActividadItem, AdminService } from '../../services/admin.service';

@Component({
  selector: 'app-reportes-actividad',
  standalone: true,
  imports: [
    CommonModule,
    MatButtonModule,
    MatCardModule,
    MatIconModule,
    MatProgressSpinnerModule,
    MatTableModule,
    MatToolbarModule,
  ],
  templateUrl: './reportes-actividad.component.html',
  styleUrls: ['./reportes-actividad.component.css'],
})
export class ReportesActividadComponent implements OnInit {
  private readonly adminService = inject(AdminService);

  columnasMostrar: string[] = ['tabla_afectada', 'operacion', 'total_eventos', 'ultimo_evento'];
  dataSource: ActividadItem[] = [];
  cargando = false;
  error = '';

  ngOnInit(): void {
    this.cargarReporte();
  }

  cargarReporte(): void {
    this.cargando = true;
    this.error = '';

    this.adminService.getReportesActividad().subscribe({
      next: (response) => {
        this.dataSource = response.items ?? [];
        this.cargando = false;
      },
      error: (err) => {
        this.dataSource = [];
        this.cargando = false;
        this.error = err?.error?.detail ?? 'No se pudo cargar el reporte de actividad.';
        console.error('Error al cargar reportes de actividad:', err);
      },
    });
  }

  imprimirReporte(): void {
    window.print();
  }
}