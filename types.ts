export type CompanyLifecycle = 'demo' | 'active' | 'suspended' | 'archived';
export type BookingMode = 'automatic' | 'manual';
export type AppointmentState = 'confirmed' | 'pending' | 'hold' | 'declined' | 'cancelled' | 'completed';
export type DealStage = 'new' | 'analyzed' | 'demo_prepared' | 'contacted' | 'replied' | 'interested' | 'proposal_sent' | 'won' | 'lost' | 'do_not_contact';

export interface Company {
  id: string;
  slug: string;
  public_token: string;
  name: string;
  description: string | null;
  theme_key: 'beauty' | 'maintenance' | 'professional';
  lifecycle: CompanyLifecycle;
  booking_enabled: boolean;
  booking_mode: BookingMode;
  timezone: string;
  city: string | null;
  state: string | null;
  contact_phone: string | null;
  contact_email: string | null;
  demo_expires_at: string | null;
  created_at: string;
}

export interface Service {
  id: string;
  company_id: string;
  name: string;
  description: string | null;
  price_type: 'fixed' | 'manual';
  price_cents: number | null;
  duration_minutes: number;
  buffer_minutes: number;
  is_active: boolean;
}

export interface Lead {
  id: string;
  name: string;
  segment: string | null;
  city: string | null;
  state: string | null;
  website_url: string | null;
  google_maps_url: string | null;
  phone_public: string | null;
  email_public: string | null;
  whatsapp_verified: boolean;
  source_urls: string[];
  source_checked_at: string | null;
  verification_status: 'unverified' | 'verified' | 'needs_review';
  score: number;
  score_reasons: string[];
  deal_stage: DealStage;
  notes: string | null;
  last_contact_at: string | null;
  next_action_at: string | null;
  created_at: string;
}

export interface BookingResult {
  appointment_id: string;
  public_token: string;
  state: AppointmentState;
  starts_at: string;
  ends_at: string;
  price_cents: number | null;
  price_type: 'fixed' | 'manual';
}

export const dealStageLabels: Record<DealStage, string> = {
  new: 'Novo',
  analyzed: 'Analisado',
  demo_prepared: 'Demonstração preparada',
  contacted: 'Contatado',
  replied: 'Respondeu',
  interested: 'Interessado',
  proposal_sent: 'Proposta enviada',
  won: 'Fechado',
  lost: 'Sem interesse',
  do_not_contact: 'Não contatar',
};

export const appointmentStateLabels: Record<AppointmentState, string> = {
  confirmed: 'Confirmado',
  pending: 'Aguardando aprovação',
  hold: 'Horário retido',
  declined: 'Recusado',
  cancelled: 'Cancelado',
  completed: 'Concluído',
};
