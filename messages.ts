export type MessageKind = 'first_contact' | 'demo' | 'interested' | 'proposal' | 'follow_up_1' | 'follow_up_2' | 'decline' | 'delivery';

export interface MessageContext {
  companyName: string;
  demoUrl?: string;
  priceText?: string;
}

export const messageLabels: Record<MessageKind, string> = {
  first_contact: 'Primeiro contato',
  demo: 'Apresentação da demonstração',
  interested: 'Resposta para interessado',
  proposal: 'Proposta com preço',
  follow_up_1: 'Acompanhamento 1',
  follow_up_2: 'Acompanhamento 2',
  decline: 'Resposta para sem interesse',
  delivery: 'Entrega após ativação',
};

export function buildMessage(kind: MessageKind, context: MessageContext): string {
  const company = context.companyName.trim() || '[empresa]';
  const link = context.demoUrl || '[link da demonstração]';
  const price = context.priceText || '[valor definido por você]';
  const templates: Record<MessageKind, string> = {
    first_contact: `Olá, pessoal da ${company}! Sou o Nicolas. Preparei uma demonstração de como poderia funcionar uma página de orçamento e agendamento para vocês: ${link}. É uma prévia, ainda sem reservas ativas. Se fizer sentido, posso explicar como adaptar aos serviços e horários da empresa.`,
    demo: `Olá, pessoal da ${company}! Deixo aqui a demonstração preparada: ${link}. Ela é uma prévia independente, sem reservas ativas e com campos que ainda podem ser ajustados conforme as informações confirmadas por vocês.`,
    interested: `Que bom que fez sentido para vocês, pessoal da ${company}. Posso alinhar os serviços, preços, duração dos atendimentos e horários para deixar a configuração pronta para revisão.`,
    proposal: `Pessoal da ${company}, conforme conversamos, a proposta é ${price}. Antes de ativar, revisamos juntos os serviços, horários, contatos e regras de atendimento.`,
    follow_up_1: `Olá, pessoal da ${company}! Passando para saber se conseguiram ver a demonstração ${link}. Se não for o momento, sem problema; posso encerrar o acompanhamento por aqui.`,
    follow_up_2: `Olá, pessoal da ${company}! Este é meu último acompanhamento sobre a demonstração ${link}. Caso não faça sentido agora, agradeço a atenção e não volto a insistir.`,
    decline: `Obrigado pelo retorno, pessoal da ${company}. Entendi e não vou insistir. Se o cenário mudar no futuro, fico à disposição.`,
    delivery: `Pessoal da ${company}, a configuração foi ativada. O acesso administrativo será entregue por um fluxo seguro separado; a partir de agora podemos validar o primeiro agendamento real juntos.`,
  };
  return templates[kind];
}
