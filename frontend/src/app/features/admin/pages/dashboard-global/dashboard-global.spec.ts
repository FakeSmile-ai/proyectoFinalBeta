import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { DashboardGlobalComponent } from './dashboard-global.component';

describe('DashboardGlobalComponent', () => {
  let component: DashboardGlobalComponent;
  let fixture: ComponentFixture<DashboardGlobalComponent>;
  let httpMock: HttpTestingController;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [DashboardGlobalComponent],
      providers: [provideHttpClient(), provideHttpClientTesting()],
    }).compileComponents();

    httpMock = TestBed.inject(HttpTestingController);
    fixture = TestBed.createComponent(DashboardGlobalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should create', () => {
    const req = httpMock.expectOne('http://127.0.0.1:8000/api/admin/dashboard-global');
    req.flush({
      total_usuarios: 0,
      total_ligas: 0,
      ligas_apuesta: 0,
      ligas_diversion: 0,
      premios_activos: 0,
      total_recaudado_global: 0,
      comision_global: 0,
      fondo_global: 0,
    });

    expect(component).toBeTruthy();
  });
});