import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSelectModule } from '@angular/material/select';
import { MatTableModule } from '@angular/material/table';
import { MatToolbarModule } from '@angular/material/toolbar';
import { AdminService, AuditLogItem } from '../../services/admin.service';

@Component({
  selector: 'app-audit-log',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    MatButtonModule,
    MatCardModule,
    MatFormFieldModule,
    MatIconModule,
    MatInputModule,
    MatProgressSpinnerModule,
    MatSelectModule,
    MatTableModule,
    MatToolbarModule,
  ],
  templateUrl: './audit-log.component.html',
  styleUrls: ['./audit-log.component.css'],
})
export class AuditLogComponent implements OnInit {
  private readonly adminService = inject(AdminService);

  columnasMostrar: string[] = [
    'fecha_evento',
    'tabla_afectada',
    'operacion',
    'id_registro',
    'usuario_bd',
    'datos',
  ];

  logs: AuditLogItem[] = [];
  cargando = false;
  error = '';
  total = 0;

  filtroTabla = '';
  filtroOperacion = '';
  limite = 50;

  ngOnInit(): void {
    this.cargarAuditoria();
  }

  cargarAuditoria(): void {
    this.cargando = true;
    this.error = '';

    this.adminService
      .getAuditLogs({
        tabla: this.filtroTabla || undefined,
        operacion: this.filtroOperacion || undefined,
        limite: this.limite,
      })
      .subscribe({
        next: (response) => {
          this.logs = response.items ?? [];
          this.total = response.total ?? this.logs.length;
          this.cargando = false;
        },
        error: (err) => {
          this.logs = [];
          this.total = 0;
          this.cargando = false;
          this.error = err?.error?.detail ?? 'No se pudo cargar la bitácora de auditoría.';
          console.error('Error al cargar audit_log:', err);
        },
      });
  }

  limpiarFiltros(): void {
    this.filtroTabla = '';
    this.filtroOperacion = '';
    this.limite = 50;
    this.cargarAuditoria();
  }

  formatearJson(valor: unknown): string {
    if (valor === null || valor === undefined) {
      return '—';
    }

    if (typeof valor === 'string') {
      return valor;
    }

    return JSON.stringify(valor, null, 2);
  }
}