# Resultados de testes

Data: 2 de outubro de 2026.

## Executado neste ambiente

| Verificação | Comando/método | Resultado |
|---|---|---|
| Tipagem e build de produção | `npm run build` | Aprovado — TypeScript e Vite concluíram; `dist/` gerado |
| Regras de moeda | Vitest | Aprovado — preço em centavos e serviço manual mostra “Sob avaliação” |
| CSV | Vitest | Aprovado — células iniciadas por `=`, `+`, `-` ou `@` recebem apóstrofo de neutralização |
| Telefones | Vitest | Aprovado — normalização aceita somente comprimento plausível |
| Score de potencial | Vitest | Aprovado — score usa evidências e não afirma necessidade, compra ou faturamento |
| URLs | Vitest | Aprovado — somente URL HTTP(S) de sintaxe válida passa para revisão |
| Mensagens | Vitest | Aprovado — identifica Nicolas, usa dados passados, declara prévia sem reservas e não promete venda |

Execução registrada: **1 arquivo, 8 testes aprovados**.

## Inspeção da implementação

- A reserva é uma RPC `SECURITY DEFINER`, não um insert direto do navegador.
- A função recalcula preço/tempo, verifica empresa ativa, serviço, janela, aviso mínimo, horizonte, bloqueio e sobreposição.
- A constraint `appointments_no_active_overlap` adiciona segunda barreira contra corrida de reservas.
- A chave de idempotência é única por empresa.
- `companies.lifecycle='demo'` não pode ter `booking_enabled=true` por constraint.
- As views públicas separam empresa ativa com agenda de demonstração.
- RLS restringe CRUD da empresa a associação, papel e/ou administrador da plataforma.

## Não validado neste ambiente

A conta Supabase e a conta Cloudflare pertencem ao Nicolas e não foram criadas/acessadas. Portanto, estas etapas estão **preparadas, mas não foram executadas contra produção**:

- aplicação real da migração no projeto Supabase;
- login, recuperação por e-mail e URLs autorizadas da conta;
- teste com dois usuários/duas empresas no Postgres remoto;
- corrida de reserva com duas requisições reais simultâneas;
- expiração de hold por cron/rotina remota;
- publicação Pages e URL final;
- SMTP, IA, Maps/Places ou mensageria de terceiros.

Depois da configuração, execute a sequência do README, principalmente `npm test`, `npm run build`, login/logout, RLS por dois usuários, reserva concorrente, demonstração, ativação, CSV, Não contatar e modo de movimento reduzido. Não declare essas validações como concluídas antes de executá-las na sua conta.
