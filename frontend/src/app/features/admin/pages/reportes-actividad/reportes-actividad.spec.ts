import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { ReportesActividadComponent } from './reportes-actividad.component';

describe('ReportesActividadComponent', () => {
  let component: ReportesActividadComponent;
  let fixture: ComponentFixture<ReportesActividadComponent>;
  let httpMock: HttpTestingController;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ReportesActividadComponent],
      providers: [provideHttpClient(), provideHttpClientTesting()],
    }).compileComponents();

    httpMock = TestBed.inject(HttpTestingController);
    fixture = TestBed.createComponent(ReportesActividadComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should create', () => {
    const req = httpMock.expectOne('http://127.0.0.1:8000/api/admin/reportes/actividad');
    req.flush({ items: [] });

    expect(component).toBeTruthy();
  });
});