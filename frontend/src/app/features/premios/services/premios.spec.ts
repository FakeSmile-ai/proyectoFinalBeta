import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { PremiosService } from './premios.service';

describe('PremiosService', () => {
  let service: PremiosService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()],
    });
    service = TestBed.inject(PremiosService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});