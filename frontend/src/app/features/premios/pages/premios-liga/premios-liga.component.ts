import { Component, OnInit, inject } from '@angular/core';
import { CommonModule, Location } from '@angular/common';
import { ActivatedRoute } from '@angular/router';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatTableModule } from '@angular/material/table';
import { MatToolbarModule } from '@angular/material/toolbar';
import { PremiosLigaResponse, PremiosService } from '../../services/premios.service';

@Component({
  selector: 'app-premios-liga',
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
  templateUrl: './premios-liga.component.html',
  styleUrls: ['./premios-liga.component.css'],
})
export class PremiosLigaComponent implements OnInit {
  private readonly route = inject(ActivatedRoute);
  private readonly premiosService = inject(PremiosService);
  private readonly location = inject(Location);

  idLiga = '';
  nombreLiga = 'Liga';
  datosCierre: PremiosLigaResponse | null = null;
  cargando = false;
  error = '';

  columnasDistribucion: string[] = ['posicion', 'porcentaje', 'monto', 'descripcion'];
  columnasGanadores: string[] = ['nombre', 'tipo', 'monto', 'fecha'];

  ngOnInit(): void {
    this.idLiga = this.route.snapshot.paramMap.get('id') ?? '';
    this.nombreLiga = this.idLiga ? `Liga #${this.idLiga}` : 'Liga';

    if (this.idLiga) {
      this.obtenerDatos();
    } else {
      this.error = 'No se recibió el id de la liga.';
    }
  }

  obtenerDatos(): void {
    this.cargando = true;
    this.error = '';

    this.premiosService.getPremiosLiga(this.idLiga).subscribe({
      next: (res) => {
        this.datosCierre = res;
        this.cargando = false;
      },
      error: (err) => {
        this.datosCierre = null;
        this.cargando = false;
        this.error = err?.error?.detail ?? 'La liga aún no tiene cierre registrado.';
        console.error('Error al consultar premios:', err);
      },
    });
  }

  ejecutarCierre(): void {
    this.cargando = true;
    this.error = '';

    this.premiosService.cerrarLiga(this.idLiga).subscribe({
      next: () => this.obtenerDatos(),
      error: (err) => {
        this.cargando = false;
        this.error = err?.error?.detail ?? 'No se pudo cerrar la liga y calcular los premios.';
        console.error('Error al cerrar la liga:', err);
      },
    });
  }

  regresar(): void {
    this.location.back();
  }
}