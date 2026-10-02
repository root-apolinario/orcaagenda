# OrçaAgenda

Plataforma multiempresa para **orçamento, agendamento, demonstrações e prospecção responsável**. Nicolas instala uma vez, configura as contas e gerencia cada empresa pelo painel. O código não depende do Manus nem cria hospedagem, repositório ou planilha por cliente.

> **O que este projeto não faz:** não ativa plano pago, cartão, teste ou cobrança; não faz disparos automáticos; não raspa Google Maps; não inventa empresas, contatos, preços ou resultados comerciais. Uma demonstração é uma proposta identificada e sem reservas reais.

## 1. O que está pronto

| Área | Implementado |
|---|---|
| Base | React responsivo, identidade OrçaAgenda, favicon, menu lateral/adaptado ao celular, estados de vazio/erro/carregamento e redução de movimento |
| Dados | Migração Postgres, RLS por empresa, perfis, papéis, empresas, serviços, horários, bloqueios, leads, agenda, auditoria e demonstrações |
| Segurança | Auth do Supabase, políticas RLS, operações de reserva no banco, idempotência, constraint de sobreposição, URLs públicas restritas, CSV seguro e nenhum segredo no frontend |
| Agendamento | Etapas de serviço, data, horário real via RPC, dados do consumidor, revisão, confirmação após servidor, preço de servidor e aprovação manual/automática |
| Prospecção | Cadastro manual, CSV, URL pública, fontes, score explicável, deduplicação de nome/cidade e domínio, funil e “Não contatar” |
| Demonstração | Aceitar cliente cria cadastro sem duplicar, tema por segmento, token de link, expiração, rótulo de proposta e bloqueio de reservas reais |
| Mensagens | Oito modelos editáveis em português, com cópia manual depois de criar a demonstração |
| Operação | Funil, empresas, serviços, agenda inicial, configurações, exportação RPC e scripts de backup |

Algumas telas administrativas são deliberadamente preparadas para receber os registros reais depois de conectar o Supabase. Não há dados fictícios de clientes, faturamento, reservas ou mensagens enviadas.

## 2. Arquitetura e contas

| Camada | Serviço escolhido | Conta/plano inicial | Para que serve |
|---|---|---|---|
| Interface | Cloudflare Pages | Free | Hospeda o frontend em um endereço `*.pages.dev` |
| Banco, Auth e RLS | Supabase | Free | Postgres, autenticação, políticas, funções SQL e Edge Functions opcionais |
| Código | GitHub privado (recomendado) | Free | Histórico, publicação automática e retorno de versão |
| IA | Nenhuma por padrão | — | Rascunho determinístico funciona sem IA; só conecte um provedor depois de definir custo e limite |
| Google Maps/Places | Não conectado | — | Links do Maps podem ser registrados quando fornecidos/verificados; não há scraping nem Places automático |

Leia também: [custos e limites](docs/custos-e-limites.md), [segurança e limites operacionais](docs/seguranca-e-operacao.md) e [resultados dos testes](docs/testes.md).

## 3. Pré-requisitos no Windows

Crie as contas abaixo **diretamente pelos sites oficiais**. Não envie senhas, tokens ou chaves pelo chat.

1. [Supabase](https://supabase.com/dashboard/sign-up): crie uma organização e um projeto no plano **Free**.
2. [Cloudflare](https://dash.cloudflare.com/sign-up): crie a conta Free. O Pages informa início gratuito sem cartão na página oficial. [1]
3. [GitHub](https://github.com/signup), opcional porém recomendado para publicação e rollback.
4. Instale [Node.js LTS](https://nodejs.org/). Depois abra **PowerShell** e execute `node --version`. O resultado esperado começa com `v20` ou `v22`.
5. Instale [Git for Windows](https://git-scm.com/download/win) se for usar GitHub. No PowerShell, `git --version` deve mostrar uma versão.
6. Instale [Visual Studio Code](https://code.visualstudio.com/) (recomendado). Não é obrigatório.

> **CMD x PowerShell:** o CMD mostra algo como `C:\Users\Nicolas>`; o PowerShell mostra `PS C:\Users\Nicolas>`. Ambos funcionam, mas comandos de cópia são diferentes. Os blocos deste guia dizem qual terminal usar.

## 4. Baixar, extrair e abrir o projeto

1. Baixe o arquivo `orcaagenda.zip` entregue com este projeto.
2. Clique com botão direito no ZIP → **Extrair tudo**.
3. Extraia, por exemplo, para `C:\Projetos\OrçaAgenda`. Pastas com espaço e acentos são aceitas.
4. Abra essa pasta no VS Code: botão direito → **Abrir com Code**, ou no VS Code: **Arquivo → Abrir Pasta**.
5. Abra o terminal do VS Code (`Ctrl` + `` ` ``). Escolha PowerShell no seletor do terminal.

**PowerShell, dentro da pasta do projeto:**

```powershell
Get-Location
```

Resultado esperado: uma linha terminando em `\OrçaAgenda`.

**CMD, dentro da pasta do projeto:**

```bat
cd
```

Resultado esperado: o caminho completo da pasta.

## 5. Configurar o Supabase e criar o banco

### 5.1 Criar o projeto

No painel Supabase:

1. Clique em **New project**.
2. Escolha a organização e um nome, por exemplo `orcaagenda`.
3. Selecione uma região próxima do Brasil.
4. Escolha o plano **Free**. Não escolha upgrade nem adicione método de pagamento.
5. Crie uma senha forte do banco e guarde-a no gerenciador de senhas. Ela é um segredo: **não vai para `.env` do frontend**.
6. Aguarde o status do projeto ficar saudável.

### 5.2 Executar a migração

Há duas formas. Para um iniciante, a primeira é mais simples.

**Opção A — SQL Editor (mais simples)**

1. Abra **SQL Editor → New query** no Supabase.
2. Abra localmente `supabase/migrations/0001_initial.sql`, copie o conteúdo inteiro e cole no editor.
3. Clique em **Run**.
4. Resultado esperado: `Success. No rows returned` (ou mensagens de criação). Se aparecer erro, não execute outra vez parcialmente; consulte “Erros comuns”.

**Opção B — CLI (PowerShell)**

No PowerShell, dentro da pasta do projeto:

```powershell
npx supabase@latest login
npx supabase@latest link --project-ref SEU_PROJECT_REF
npx supabase@latest db push
```

- O primeiro comando abre/solicita autenticação segura no navegador.
- O segundo solicita o **Project Reference**, visível em **Settings → General** no Supabase.
- O terceiro envia `supabase/migrations/0001_initial.sql`.
- Resultado esperado do último: a migração `0001_initial.sql` aparece como aplicada.

### 5.3 Criar o primeiro administrador sem senha padrão

1. No Supabase, abra **Authentication → Users → Add user**.
2. Informe **seu próprio e-mail** e uma senha forte. Confirme o e-mail se o painel oferecer essa opção.
3. Copie o UUID do usuário criado.
4. Abra **SQL Editor → New query** e execute, trocando o valor:

```sql
insert into public.platform_admins(user_id)
values ('COLE-O-UUID-DO-SEU-USUARIO-AQUI');
```

Resultado esperado: `Success. No rows returned`.

Isso é necessário uma vez. Sem essa associação, o login acontece mas o usuário não pode administrar empresas e potenciais. Não crie uma senha padrão e não conceda a função a terceiros sem decisão consciente.

### 5.4 Configurar autenticação e URLs autorizadas

No Supabase, abra **Authentication → URL Configuration**.

1. Em **Site URL**, coloque durante desenvolvimento: `http://localhost:5173`.
2. Em **Redirect URLs**, adicione `http://localhost:5173/**`.
3. Depois da publicação, adicione também `https://SEU-PROJETO.pages.dev/**` e altere Site URL para a URL final.
4. Em **Authentication → Providers → Email**, escolha a política de confirmação de e-mail adequada. Para produção, mantenha confirmação habilitada.
5. O e-mail padrão do plano Free é adequado para início, mas tem limites. Para volume comercial, configure SMTP próprio somente depois de avaliar custo e requisitos.

## 6. Criar `.env` e executar localmente

No Supabase, abra **Settings → API**. Copie somente:

- **Project URL**;
- chave **anon / publishable**.

Nunca copie `service_role`, senha de banco, token de IA ou token administrativo para o frontend.

**PowerShell:**

```powershell
Copy-Item .env.example .env
notepad .env
```

**CMD:**

```bat
copy .env.example .env
notepad .env
```

Preencha:

```ini
VITE_SUPABASE_URL=https://SEU-PROJETO.supabase.co
VITE_SUPABASE_ANON_KEY=COLE_A_CHAVE_ANON_PUBLICAVEL
VITE_APP_URL=http://localhost:5173
```

Depois instale e inicie:

```powershell
npm install
npm run dev
```

Resultado esperado:

```text
Local: http://localhost:5173/
```

Abra esse endereço. Na primeira tela, use **Abrir login** e entre com o usuário administrador criado no Supabase. Alternativamente, dê duplo clique em `scripts\instalar-e-executar.bat`; ele usa `"%~dp0.."`, por isso funciona em caminhos com espaço e acentos.

## 7. Tabela de variáveis e segredos

| Variável/configuração | Finalidade | Onde obter | É segredo? | Onde configurar |
|---|---|---|---|---|
| `VITE_SUPABASE_URL` | Endereço público do projeto | Supabase → Settings → API | Não | `.env` local e Cloudflare Pages → Environment variables |
| `VITE_SUPABASE_ANON_KEY` | Cliente público submetido a RLS | Supabase → Settings → API | Não, mas não alterar | `.env` local e Cloudflare Pages → Environment variables |
| `VITE_APP_URL` | URL base para redirecionamentos e links | Seu localhost ou `*.pages.dev` | Não | `.env` local e Cloudflare Pages |
| Senha do banco | Administração e CLI | Definida ao criar o projeto | **Sim** | Gerenciador de senhas; nunca no frontend |
| `service_role` | Rotinas administrativas de servidor | Supabase → Settings → API | **Sim** | Somente segredo de Edge Function/servidor, se uma integração futura realmente exigir |
| Chave de IA | Rascunho opcional | Provedor escolhido | **Sim** | Apenas segredo de Edge Function/servidor, com limite de consumo |
| Google Maps/Places key | Integração opcional paga | Google Cloud | **Sim** | Não configurada por padrão; avaliar faturamento e termos antes |

## 8. Testar antes de publicar

No PowerShell ou CMD, na pasta do projeto:

```powershell
npm test
npm run build
```

Resultado esperado: `8 passed` nos testes e, no build, a pasta `dist` criada sem erro.

Teste manualmente:

1. Faça login e depois saia; entre novamente.
2. Use **Esqueci minha senha**. O e-mail só chegará se Auth estiver configurado.
3. Cadastre uma empresa ou um potencial de **dados comerciais públicos**.
4. Use **Aceitar cliente e criar projeto**. A empresa vira demonstração e o painel oferece link/mensagem para revisão manual.
5. Abra a demonstração: ela diz que é proposta, não coleta dados e não permite reservas.
6. Complete serviços, contatos e janelas de horário diretamente no painel/banco. Só então execute a ativação por RPC/painel administrativo.
7. Em uma empresa ativa, abra `/agenda/slug`, escolha serviço, data e horário; a disponibilidade vem do banco. Tente repetir a reserva: o banco deve impedir sobreposição e repetir a mesma chave idempotente retorna a mesma reserva.

## 9. Publicar no Cloudflare Pages

### 9.1 GitHub privado (recomendado)

**PowerShell:**

```powershell
git init
git add .
git commit -m "Primeira versão do OrçaAgenda"
```

Crie um repositório **privado** no GitHub sem README adicional. Depois conecte:

```powershell
git branch -M main
git remote add origin https://github.com/SEU-USUARIO/orcaagenda.git
git push -u origin main
```

Resultado esperado: o commit aparece no GitHub. Confirme que `.env` não aparece na lista de arquivos. O `.gitignore` já o exclui.

### 9.2 Criar projeto Pages

1. Cloudflare Dashboard → **Workers & Pages → Create application → Pages → Connect to Git**.
2. Escolha o repositório privado `orcaagenda`.
3. Use estas configurações:

| Campo | Valor |
|---|---|
| Production branch | `main` |
| Build command | `npm ci && npm run build` |
| Build output directory | `dist` |
| Node version | `22` (variável `NODE_VERSION`, se o painel oferecer) |

4. Em **Environment variables** para Production e Preview, adicione `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY` e `VITE_APP_URL`. Para `VITE_APP_URL`, comece com a URL `https://SEU-PROJETO.pages.dev` recebida depois da primeira publicação e faça novo deploy.
5. Clique em **Save and Deploy**. Isso não cria plano pago.
6. Resultado esperado: Cloudflare mostra `Success` e uma URL `https://SEU-PROJETO.pages.dev`.

O arquivo `public/_redirects` é copiado para `dist/_redirects` e garante que links como `/agenda/minha-empresa` e `/demonstracao/TOKEN` carreguem o aplicativo. `robots.txt` pede que rastreadores não indexem demonstrações, mas **não é controle de acesso**; o token e a revogação continuam necessários.

### 9.3 Domínio próprio (opcional)

Não é necessário no início. Para usar um domínio próprio, compre-o no fornecedor de sua escolha e siga **Pages → Custom domains** no Cloudflare. Isso pode envolver custo do domínio, fora deste projeto. Não é preciso uma hospedagem nova por cliente.

## 10. Operação diária do Nicolas

1. No painel, abra **Prospecção**.
2. Adicione manualmente, importe CSV ou registre URL pública. Informe só dados comerciais públicos e URL de fonte. Não marque telefone como WhatsApp sem divulgação explícita.
3. Confira o score: ele mostra evidências, não afirma que a empresa precisa do sistema.
4. Selecione **Aceitar cliente e criar projeto**. O cadastro é reaproveitado e a empresa nasce como **demonstração**.
5. Revise campos ausentes. Não use logotipo, preço, endereço ou condição não autorizados.
6. Abra a prévia e escolha a mensagem. Copie, revise e envie manualmente. Somente depois marque o contato como realizado/mova o funil.
7. Se a empresa contratar, confirme serviço, preço, duração, janelas de atendimento, pausas, bloqueios, contato e administrador. Só então use `activate_company`/o fluxo de ativação para habilitar reservas reais.
8. Empresas marcadas **Não contatar** não devem voltar à fila ou novas sugestões.

### Modelo CSV

Use [docs/modelo-potenciais.csv](docs/modelo-potenciais.csv). Campos sugeridos: `nome,cidade,estado,segmento,telefone,email,site,google_maps,whatsapp,fonte`. `fonte` precisa ser URL pública da origem. O importador limita a 100 linhas por lote e o banco deduplica por nome/cidade/UF e domínio quando disponível.

## 11. Atualizar e voltar a uma versão anterior

**Atualizar código (PowerShell):**

```powershell
git pull origin main
npm ci
npx supabase@latest db push
npm run build
```

Resultado esperado: dependências instaladas, migrações pendentes aplicadas e build concluído. Nunca edite ou apague uma migração já usada em produção; crie uma nova em `supabase/migrations/`.

Para voltar o código, no GitHub abra **Commits**, identifique o commit anterior e faça um novo revert pela interface ou, no PowerShell:

```powershell
git revert SEU_COMMIT
 git push
```

Resultado esperado: um novo commit de reversão. Não use `git push --force` em produção. Reverter código não reverte dados automaticamente; trate migrações de banco como mudanças separadas.

## 12. Backup e restauração

O plano Free do Supabase não inclui backup diário automático como os planos pagos. Faça backup antes de mudanças estruturais e periodicamente.

**Backup (PowerShell):**

```powershell
.\scripts\backup-supabase.ps1 -ProjectRef SEU_PROJECT_REF
```

Resultado esperado: arquivo `.sql` em `backups\orcaagenda_DATA.sql`. O CLI pedirá login seguro se necessário. Guarde o backup em local protegido e criptografado porque pode conter informações de agendamento.

**Restaurar — faça apenas em projeto de teste primeiro:**

```powershell
npx supabase@latest db reset --linked
```

Para restaurar um dump específico, siga o procedimento atual do [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started), pois o comando depende do formato/exportação. Não execute restauração em produção sem ter um backup recente e uma janela de manutenção.

## 13. Erros comuns

| Sintoma | Causa provável | Como resolver |
|---|---|---|
| Tela mostra assistente em vez de login | `.env` ausente ou chave pública incompleta | Copie `.env.example`, preencha URL/anon key e reinicie `npm run dev` |
| `Invalid API key` | Chave errada ou projeto incorreto | Confira Supabase → Settings → API; use anon/publicável, não `service_role` |
| Login entra mas painel não salva | Usuário não é admin da plataforma | Execute o `insert` em `platform_admins` com o UUID correto |
| `booking_not_available` | Empresa demo/suspensa ou reserva não habilitada | Confirme dados e ative a empresa somente após revisão |
| `outside_business_hours` | Não há janela de disponibilidade que cubra o atendimento | Cadastre dias/horários em `availability_windows` |
| `slot_unavailable` | Outro pedido ocupou o horário | Escolha outro horário; não force nova confirmação |
| Link publicado mostra 404 ao atualizar | `_redirects` não chegou ao build | Confirme que `public/_redirects` está no repositório e faça novo deploy |
| E-mail de recuperação não chega | Configuração de e-mail/Auth incompleta | Confira Authentication → Providers → Email e URLs autorizadas |
| Projeto Supabase parece indisponível | Projeto Free foi pausado por baixa atividade | Retome pelo Dashboard; veja o guia de pausa oficial [4] |

## 14. Custos comerciais sugeridos (não são custos da infraestrutura)

Essas são **estimativas de posicionamento comercial**, não promessa de preço e não incluem impostos, marketing, suporte fora do combinado ou integrações pagas.

| Oferta | Faixa de implantação sugerida | Mensalidade sugerida | Inclui |
|---|---:|---:|---|
| Essencial | R$ 500–1.200 | R$ 79–149 | Página pública, serviços, agenda e suporte básico |
| Profissional | R$ 1.200–2.500 | R$ 149–299 | Personalização, orçamento, regras de aprovação e acompanhamento mensal |
| Operação assistida | R$ 2.500–5.000 | R$ 299–690 | Implantação detalhada, treinamento, ajustes recorrentes e relatórios operacionais |

Defina por contrato os limites de empresas, usuários, reservas, armazenamento, suporte e integrações. Se ultrapassar cotas gratuitas ou exigir SMTP/IA/Places/WhatsApp, calcule custo real antes de aceitar a obrigação.

## 15. Segurança e limites que permanecem

A migração e a interface implementam RLS, sessões do Supabase, autorização de empresa, preços server-side, validação de inputs, idempotência, exclusão de sobreposição, logs de auditoria, proteção básica contra CSV injection e recusa de URLs internas pela função opcional. Isso não significa segurança de 100%.

Antes de vender em escala, faça revisão independente de segurança, defina política LGPD/privacidade, termos de uso, retenção e exclusão, teste carga, configure backup e monitore os limites. Páginas de demonstração devem ter expiração e remoção; `robots.txt` não é proteção de acesso.

## Referências oficiais

[1]: https://www.cloudflare.com/developer-platform/products/pages/ "Cloudflare Pages"
[2]: https://developers.cloudflare.com/pages/platform/limits/ "Cloudflare Pages limits"
[3]: https://developers.cloudflare.com/workers/platform/pricing/ "Cloudflare Workers pricing"
[4]: https://supabase.com/docs/guides/platform/free-project-pausing "Supabase project pausing"
[5]: https://supabase.com/pricing "Supabase pricing"
[6]: https://supabase.com/docs/guides/platform/billing-on-supabase "Supabase billing"
[7]: https://developers.google.com/maps/documentation/places/web-service/usage-and-billing "Google Places API usage and billing"
[8]: https://cloud.google.com/maps-platform/terms "Google Maps Platform terms of service"
