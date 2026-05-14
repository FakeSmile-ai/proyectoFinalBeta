import { Routes } from '@angular/router';

import { DashboardGlobalComponent } from './features/admin/pages/dashboard-global/dashboard-global.component';

import { AuditLogComponent } from './features/admin/pages/audit-log/audit-log.component';
import { ReportesActividadComponent } from './features/admin/pages/reportes-actividad/reportes-actividad.component';
import { PremiosLigaComponent } from './features/premios/pages/premios-liga/premios-liga.component';
export const routes: Routes = [

  {
    path: '',
    redirectTo: 'admin/dashboard',
    pathMatch: 'full',
  },

  {
    path: 'admin/dashboard',
    component: DashboardGlobalComponent,
  },

  {
    path: 'admin/auditoria',
    component: AuditLogComponent,
  },

  {
    path: 'admin/reportes',
    component: ReportesActividadComponent,
  },

  {
    path: 'premios/liga/:id',
    component: PremiosLigaComponent,
  },

  {
    path: '**',
    redirectTo: 'admin/dashboard',
  },

];