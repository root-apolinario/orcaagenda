import { describe, expect, it } from 'vitest';
import { draftCompanyFromText, formatCurrency, isPublicHttpUrl, normalizePhone, publicLeadScore, sanitizeCsvCell } from '../src/lib/rules';
import { buildMessage } from '../src/lib/messages';

describe('regras de apresentação e segurança', () => {
  it('formata valores somente a partir de centavos e não inventa preço manual', () => {
    expect(formatCurrency(12345)).toBe('R$ 123,45');
    expect(formatCurrency(null)).toBe('Sob avaliação');
  });

  it('neutraliza fórmulas perigosas em células CSV', () => {
    expect(sanitizeCsvCell('=HYPERLINK("https://malicioso")')).toBe("'=HYPERLINK(\"https://malicioso\")");
    expect(sanitizeCsvCell('+123')).toBe("'+123");
    expect(sanitizeCsvCell('Empresa segura')).toBe('Empresa segura');
  });

  it('aceita somente telefones comerciais plausíveis depois de normalizar', () => {
    expect(normalizePhone('(41) 99999-1234')).toBe('41999991234');
    expect(normalizePhone('abc')).toBeNull();
  });

  it('pontua evidências sem afirmar necessidade ou chance de compra', () => {
    const output = publicLeadScore({
      segment: 'assistência técnica', phone_public: '41999991234', email_public: 'contato@exemplo.com',
      whatsapp_verified: true, website_url: 'https://exemplo.com', google_maps_url: 'https://maps.google.com/?q=exemplo',
    });
    expect(output.score).toBe(90);
    expect(output.reasons.join(' ')).toContain('Segmento com potencial');
    expect(output.reasons.join(' ')).not.toMatch(/precisa|comprar|faturamento/i);
  });

  it('valida URLs HTTP públicas de sintaxe válida antes da revisão no servidor', () => {
    expect(isPublicHttpUrl('https://empresa.com.br/contato')).toBe(true);
    expect(isPublicHttpUrl('mailto:contato@empresa.com.br')).toBe(false);
    expect(isPublicHttpUrl('não é url')).toBe(false);
  });

  it('prepara rascunho editável sem preencher dados ausentes por suposição', () => {
    const draft = draftCompanyFromText('Prepare uma configuração para uma empresa de limpeza em Curitiba chamada Brilho, que atende de segunda a sábado.');
    expect(draft.name).toBe('Brilho');
    expect(draft.city).toBe('Curitiba');
    expect(draft.segment).toContain('limpeza');
    expect(draft.weekdays).toContain('sábado');
    expect(draft.missing.join(' ')).toContain('serviços');
  });
});

describe('mensagens comerciais manuais', () => {
  it('identifica Nicolas, usa dados fornecidos e não promete resultado comercial', () => {
    const text = buildMessage('first_contact', { companyName: 'Oficina Exemplo', demoUrl: 'https://demo.test/a' });
    expect(text).toContain('Sou o Nicolas');
    expect(text).toContain('Oficina Exemplo');
    expect(text).toContain('https://demo.test/a');
    expect(text).toContain('sem reservas ativas');
    expect(text).not.toMatch(/aumentar vendas|sou cliente|conheço vocês/i);
  });

  it('mantém valor de proposta explicitamente informado pelo administrador', () => {
    const text = buildMessage('proposal', { companyName: 'Empresa', priceText: 'R$ 490 de implantação' });
    expect(text).toContain('R$ 490 de implantação');
  });
});
