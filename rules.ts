import type { Lead } from '../types';

export function formatCurrency(cents: number | null | undefined): string {
  if (cents === null || cents === undefined) return 'Sob avaliação';
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(cents / 100);
}

export function sanitizeCsvCell(value: string | null | undefined): string {
  const text = value ?? '';
  return /^[=+\-@]/.test(text) ? `'${text}` : text;
}

export function normalizePhone(value: string | null | undefined): string | null {
  const digits = (value ?? '').replace(/\D/g, '');
  return digits.length >= 10 && digits.length <= 13 ? digits : null;
}

export function publicLeadScore(input: Pick<Lead, 'segment' | 'phone_public' | 'email_public' | 'whatsapp_verified' | 'website_url' | 'google_maps_url'>): { score: number; reasons: string[] } {
  const reasons: string[] = [];
  let score = 0;
  const schedulableSegments = /beleza|sal[aã]o|barbear|est[ée]tica|manuten[cç][aã]o|oficina|assist[eê]ncia|limpeza|instala[cç][aã]o|consult|advoc|contab/i;
  if (input.segment && schedulableSegments.test(input.segment)) {
    score += 30;
    reasons.push('Segmento com potencial de agenda ou orçamento.');
  }
  if (input.phone_public) {
    score += 20;
    reasons.push('Telefone comercial público encontrado.');
  }
  if (input.email_public) {
    score += 10;
    reasons.push('E-mail comercial público encontrado.');
  }
  if (input.whatsapp_verified) {
    score += 15;
    reasons.push('Canal de WhatsApp divulgado pela empresa.');
  }
  if (input.website_url) {
    score += 10;
    reasons.push('Site público disponível para conferência.');
  }
  if (input.google_maps_url) {
    score += 5;
    reasons.push('Link do Google Maps informado para verificação manual.');
  }
  if (!reasons.length) reasons.push('Poucas evidências nas fontes consultadas; revisar antes de contatar.');
  return { score, reasons };
}

export function buildFirstContactMessage(name: string, demoUrl: string | null): string {
  const business = name.trim() || '[empresa]';
  const link = demoUrl || '[link da demonstração]';
  return `Olá, pessoal da ${business}! Sou o Nicolas. Preparei uma demonstração de como poderia funcionar uma página de orçamento e agendamento para vocês: ${link}. É uma prévia, ainda sem reservas ativas. Se fizer sentido, posso explicar como adaptar aos serviços e horários da empresa.`;
}

export function isPublicHttpUrl(value: string): boolean {
  try {
    const url = new URL(value);
    return url.protocol === 'https:' || url.protocol === 'http:';
  } catch {
    return false;
  }
}

export function addMinutes(iso: string, minutes: number): string {
  return new Date(new Date(iso).getTime() + minutes * 60_000).toISOString();
}

export interface CompanyDraft {
  name: string;
  segment: string;
  city: string;
  weekdays: string[];
  missing: string[];
}

export function draftCompanyFromText(text: string): CompanyDraft {
  const normalized = text.trim();
  const nameMatch = normalized.match(/(?:chamada|nomeada)\s+([^,.;]+?)(?=\s+que|,|\.|$)/i) || normalized.match(/empresa\s+chamada\s+([^,.;]+?)(?=\s+que|,|\.|$)/i);
  const cityMatch = normalized.match(/\bem\s+([A-ZÀ-Ú][A-Za-zÀ-ú -]+?)(?=\s+(?:chamada|nomeada|que)|,|\.|$)/i);
  const weekdayMatches = ['segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', 'domingo'].filter((day) => normalized.toLocaleLowerCase('pt-BR').includes(day));
  const segment = normalized.match(/empresa de\s+([^,.;]+)|serviço[s]? de\s+([^,.;]+)/i)?.[1] || normalized.match(/empresa de\s+([^,.;]+)|serviço[s]? de\s+([^,.;]+)/i)?.[2] || '';
  const draft = { name: nameMatch?.[1]?.trim() || '', segment: segment.trim(), city: cityMatch?.[1]?.trim() || '', weekdays: weekdayMatches, missing: [] as string[] };
  if (!draft.name) draft.missing.push('nome da empresa');
  if (!draft.city) draft.missing.push('cidade');
  if (!draft.segment) draft.missing.push('segmento');
  if (!draft.weekdays.length) draft.missing.push('dias de funcionamento');
  draft.missing.push('serviços, preços, duração, contatos e regras — confirmar manualmente');
  return draft;
}
