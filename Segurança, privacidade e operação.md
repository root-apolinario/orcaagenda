# Segurança, privacidade e operação

## Controles implementados

| Controle | Implementação | Limite importante |
|---|---|---|
| Login e sessões | Supabase Auth com senha e recuperação | Configurar confirmação de e-mail, URLs e SMTP no Supabase |
| Separação por empresa | RLS em tabelas e função `is_company_member` | Testar cada nova migração e não usar service role no navegador |
| Administração Nicolas | `platform_admins` separado de membros de empresa | A primeira associação é manual e deve ser feita somente ao seu próprio usuário |
| Preços | `create_booking` busca o serviço no Postgres e usa `price_cents` do banco | O navegador nunca é fonte do preço final |
| Conflito de agenda | `pg_advisory_xact_lock`, constraint `EXCLUDE` de intervalos, bloqueios e nova checagem server-side | O tratamento visual do erro ainda precisa orientar o consumidor a escolher outro horário |
| Idempotência | `company_id + idempotency_key` é único | Clientes devem reutilizar a chave ao repetir a mesma solicitação; o frontend gera uma por tentativa |
| Aprovação manual | Estado `hold`/`pending`, expiração e função `expire_holds` | Chame a expiração antes de aceitar/mostrar slots; configure cron se houver crescimento |
| Demonstrações | Ciclo `demo`, token aleatório, expiração/revogação e `booking_enabled=false` | Token é barreira de descoberta, não autenticação; não coloque dados privados na prévia |
| Prospecção | Dados comerciais públicos, URLs de fonte, sem scraper de Maps e “Não contatar” | O operador continua responsável por revisar fonte e conformidade LGPD/contato |
| CSV | Proteção de fórmulas na função de exportação/uso de dados | Mantenha CSVs em UTF-8 e não abra conteúdo não confiável em modo que execute fórmulas |
| URLs externas | Edge Function opcional restringe sintaxe/protocolos e recusa host interno | Ela não busca a URL por padrão; um proxy que segue redirecionamentos exige análise específica contra SSRF/DNS rebinding |
| Logs | `audit_logs` sem segredos | Restrinja acesso ao Dashboard e não registre tokens/chaves no frontend |

## Políticas de dados

- Colete dados de consumidores somente quando uma empresa ativa receber um pedido. Demonstrações não têm formulário de reserva.
- Não use CPF, dados privados de potenciais empresas nem telefone como “WhatsApp confirmado” sem divulgação expressa.
- Defina prazo de retenção de leads e de dados de reservas conforme seu contrato e base legal. Crie uma rotina administrativa para exclusão quando solicitado.
- Exporte apenas dados da empresa solicitante. Antes de entregar um CSV/backup, avalie dados pessoais presentes.
- Não coloque chave `service_role`, senha de Postgres, token de IA ou segredo de SMTP em `VITE_*`, Git, logs, HTML ou mensagens comerciais.

## Ações obrigatórias antes de operação comercial

1. Configurar política de privacidade, termos e canal para solicitações de dados.
2. Definir contrato com cada empresa: quem é controlador, quem acessa dados e quanto tempo ficam retidos.
3. Conferir RLS com dois usuários reais de empresas diferentes. Trocar um `company_id` em uma requisição não pode revelar registros.
4. Configurar backup manual e executar restauração em ambiente de teste.
5. Definir limite de reservas, leads, Storage, IA e suporte por plano vendido.
6. Avaliar SMTP, WhatsApp, IA ou Places separadamente antes de ativar, com limite de gasto explícito.
7. Revisar as fontes e o texto antes de cada contato; o aplicativo não envia nem registra contato automaticamente.

## O que ainda exige configuração do operador

- Configuração de e-mail transacional e recuperação em Supabase Auth.
- Rotina agendada/cron para `expire_holds`, expiração/desativação e exclusão de demonstrações, caso o volume justifique.
- Interface completa para edição de janelas de horário, bloqueios, membros e ação de ativação (o banco já impõe os pré-requisitos e o frontend possui a base de catálogo/agenda).
- Auditoria de segurança independente e testes de carga antes de expandir.

Não há promessa de segurança absoluta, disponibilidade contínua, LGPD automática ou operação gratuita em qualquer escala.
