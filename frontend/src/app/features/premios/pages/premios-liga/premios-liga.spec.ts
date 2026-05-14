import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { provideRouter } from '@angular/router';
import { PremiosLigaComponent } from './premios-liga.component';

describe('PremiosLigaComponent', () => {
  let component: PremiosLigaComponent;
  let fixture: ComponentFixture<PremiosLigaComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [PremiosLigaComponent],
      providers: [provideHttpClient(), provideRouter([])],
    }).compileComponents();

    fixture = TestBed.createComponent(PremiosLigaComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});