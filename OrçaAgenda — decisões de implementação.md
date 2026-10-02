# OrçaAgenda — decisões de implementação

## Produto e arquitetura

O OrçaAgenda é um SaaS multiempresa para Nicolas vender páginas de orçamento e agendamento sem criar uma nova infraestrutura por cliente. A primeira implantação usa um único frontend estático React/Vite no Cloudflare Pages e um único projeto Supabase com Auth, Postgres, Row Level Security (RLS), Storage opcional e Edge Functions. Dados persistentes vivem apenas no Postgres; estado de interface não é banco de produção.

- **Frontend:** React + TypeScript + CSS responsivo. Usa apenas a chave anônima publicável do Supabase.
- **Autenticação:** Supabase Auth por e-mail/senha e recuperação de senha. A sessão é fornecida pelo SDK; não há senha padrão.
- **Autorização e isolamento:** RLS e funções SQL validam associação do usuário à empresa. Cada operação administrativa confere o usuário autenticado e cada empresa só pode alcançar seus próprios registros.
- **Reservas:** RPC `create_booking` calcula preço no banco, toma bloqueio transacional por empresa/horário, aplica constraint de exclusão para impedir sobreposição e registra chave de idempotência. A confirmação pública ocorre somente após a RPC responder.
- **Demonstração:** empresa com `lifecycle='demo'`; a reserva real é bloqueada na função do banco. Links de demo são aleatórios e podem expirar/desativar. A interface identifica a prévia como proposta de Nicolas e como conteúdo ilustrativo.
- **Prospecção:** importação CSV segura e cadastro por URL pública são implementados. Links do Google Maps podem ser armazenados quando informados e verificados, mas não há scraping nem armazenamento de conteúdo do Google Maps. A busca automática por Google Places fica deliberadamente desativada: o Places API exige faturamento e os termos proíbem exportar/copiar e guardar listas de empresas fora do serviço. A aplicação prevê uma Edge Function para consulta explícita de URL pública, com bloqueio de destinos internos (SSRF), mas não extrai diretórios.
- **IA:** opcional. O rascunho determinístico local preenche apenas dados fornecidos e marca lacunas; a integração de IA é um ponto de extensão de Edge Function, protegida por segredo no servidor e limite de consumo. Agenda, cálculo, mensagens e demonstrações não dependem dela.

## Hospedagem escolhida e limites conhecidos

A implantação gratuita inicial proposta é **Cloudflare Pages (frontend estático)** + **Supabase Free (Auth/Postgres)**. O Cloudflare Pages Free indica 500 builds/mês, um build simultâneo, 20.000 arquivos por site e 25 MiB por arquivo; funções Pages contam para as cotas Workers. Workers Free tem 100.000 requisições/dia e 10 ms de CPU por invocação; ao exceder certos limites gratuitos a operação falha em vez de gerar cobrança automática. O plano pago de Workers começa em US$ 5/mês, portanto ele não é ativado neste projeto. [1] [2]

Supabase Free oferece duas instâncias ativas, 500 MB de banco por projeto, 1 GB de Storage, 5 GB de egress, 50.000 MAU e 500.000 invocações de Edge Functions, mas o projeto pode ser pausado após uma semana de baixa atividade. Ele pode ser retomado pelo painel durante um ano. Os backups automáticos diários pertencem aos planos pagos; por isso este projeto inclui exportação e instruções de backup manual. [3] [4]

As páginas públicas podem usar o subdomínio `*.pages.dev`; um domínio próprio é opcional. As contas devem ser criadas diretamente pelo Nicolas. Nenhum cartão, período de teste, plano pago ou cobrança é ativado pelo projeto. Não há promessa de gratuidade permanente, disponibilidade, desempenho ou capacidade ilimitada.

## Design

**Movimento:** produto B2B contemporâneo com referências de software operacional calmo, evitando aparência de template de marketing.

**Essência:** “Organize a jornada comercial e a agenda de cada empresa em um só lugar.” Personalidade: precisa, acolhedora e prática.

**Princípios:** informação priorizada; contraste para decisões importantes; espaços generosos; estados explícitos. A assinatura visual é o **Verde Agenda** (`#0f8b78`), apoiado por azul-noturno e superfícies creme. O layout combina uma barra lateral estrutural no desktop com uma faixa de contexto e cartões assimétricos; no celular a navegação vira uma barra inferior.

**Tipografia:** Inter (sistema de fallback) para interface, pesos 500–800 para hierarquia. O wordmark usa uma marca abstrata de duas agendas sobrepostas, criada em SVG, não uma fonte genérica.

**Interação e movimento:** transições de 160–220 ms comunicam mudança de etapa, seleção e salvamento. Estados de sucesso só surgem após resposta de dados. `prefers-reduced-motion` remove deslocamentos. Todos os controles seguem foco visível e navegação por teclado.

## Estrutura

```text
src/                 interface React, componentes, cliente Supabase e regras puras
supabase/migrations/ esquema, RLS, funções transacionais e dados de referência
supabase/functions/  extensões de servidor (URL pública e IA opcional)
tests/               testes unitários das regras de negócio críticas
docs/                publicação, custos, operação e tutorial do Windows
scripts/             comandos auxiliares seguros para Windows
public/              favicon, manifesto e manifesto de rotas
```

## Limitações assumidas

A instalação inicial requer que Nicolas configure uma conta Supabase e uma Cloudflare. E-mail transacional, WhatsApp, modelos de IA e Places API não são ativados sem credenciais e decisão explícita. O fluxo de mensagens prepara, copia e registra contato manualmente; ele nunca dispara em massa. Importação de lead só aceita dados comerciais públicos fornecidos/confirmados pelo usuário e a URL da fonte.

## Registro de progresso

- 2026-10-02: arquitetura e limites verificados em fontes oficiais; Cloudflare Pages + Supabase selecionados.
- 2026-10-02: implementação independente iniciada porque a inicialização gerenciada do Webdev não está disponível nesta sessão.

## Referências

[1]: https://developers.cloudflare.com/pages/platform/limits/ "Cloudflare Pages limits"
[2]: https://developers.cloudflare.com/workers/platform/pricing/ "Cloudflare Workers pricing"
[3]: https://supabase.com/pricing "Supabase pricing"
[4]: https://supabase.com/docs/guides/platform/free-project-pausing "Supabase project pausing"
[5]: https://developers.google.com/maps/documentation/places/web-service/usage-and-billing "Google Places API usage and billing"
[6]: https://cloud.google.com/maps-platform/terms "Google Maps Platform terms of service"
[7]: https://operations.osmfoundation.org/policies/nominatim/ "Nominatim usage policy"
