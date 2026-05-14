import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../../environments/environment';

export interface CierreLiga {
  id_cierre_liga: number;
  id_liga: number;
  total_recaudado: number;
  comision: number;
  fondo_global: number;
  monto_neto: number;
  promedio_puntos?: number;
  fecha_cierre?: string;
}

export interface DistribucionPremio {
  id_distribucion_premio?: number;
  id_cierre_liga: number;
  posicion_final: number;
  porcentaje: number;
  monto: number;
  descripcion: string;
}

export interface PremioGanador {
  id_premio: number;
  id_liga: number;
  id_usuario: number;
  nombre_completo: string;
  tipo_premio: string;
  monto: number;
  descripcion: string;
  fecha_asignacion: string;
}

export interface PremiosLigaResponse {
  cierre: CierreLiga;
  distribucion: DistribucionPremio[];
  premios: PremioGanador[];
}

export interface CierreLigaResponse {
  message: string;
  id_liga: number;
  id_cierre_liga: number;
  participantes_activos: number;
  total_recaudado: number;
  comision: number;
  fondo_global: number;
  monto_neto: number;
  premios: Array<{
    id_premio: number;
    id_usuario: number;
    usuario: string;
    tipo_premio: string;
    monto: number;
    puntos: number;
  }>;
}

@Injectable({
  providedIn: 'root',
})
export class PremiosService {
  private readonly http = inject(HttpClient);
  private readonly apiUrl = `${environment.apiUrl}/premios`;

  getPremiosLiga(idLiga: number | string): Observable<PremiosLigaResponse> {
    return this.http.get<PremiosLigaResponse>(`${this.apiUrl}/ligas/${idLiga}`);
  }

  cerrarLiga(idLiga: number | string): Observable<CierreLigaResponse> {
    return this.http.post<CierreLigaResponse>(`${this.apiUrl}/ligas/${idLiga}/cerrar`, {});
  }
}