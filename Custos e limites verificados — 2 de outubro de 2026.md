# Custos e limites verificados — 2 de outubro de 2026

A configuração inicial recomendada para o OrçaAgenda é **Cloudflare Pages Free + Supabase Free**. Ela serve para início e validação comercial, não para prometer operação ilimitada ou sem custo permanente.

| Serviço | Decisão | Limites/condições oficiais relevantes | Ao atingir limite ou inatividade | Cartão/cobrança automática |
|---|---|---|---|---|
| Cloudflare Pages | Usado para frontend estático | Free: 500 builds/mês, 1 build simultâneo, 20.000 arquivos/site, 25 MiB por arquivo e até 100 projetos por conta. [1] | Build pode falhar/aguardar conforme o limite; reduzir builds ou mudar de plano por decisão explícita | A página do Pages informa início gratuito sem cartão. Não foi ativado plano pago. [2] |
| Cloudflare Workers | Não necessário na primeira versão | Free: 100.000 requisições/dia, 10 ms CPU por invocação; KV e outros recursos têm cotas diárias. [3] | Operações gratuitas excedentes podem falhar; plano Paid começa em US$ 5/mês. [3] | Não habilitar Paid sem autorização. Nenhuma função Pages é necessária nesta implantação. |
| Supabase | Usado para banco, Auth e RLS | Free: 2 projetos ativos, 500 MB por banco, 1 GB Storage, 5 GB egress, 50.000 MAU, 500.000 invocações de função e 200 conexões Realtime. [4] [5] | Projetos Free podem ser pausados após 1 semana de baixa atividade; há restauração pelo painel por até 1 ano. [6] | Free não requer migração a plano pago. Organizações pagas têm método de pagamento e cobrança por sobreuso; não alterar de plano sem decisão. [5] |
| Google Maps/Places | Não integrado automaticamente | Places usa preços por SKU/evento e documentação de uso exige faturamento habilitado para a API. [7] | Quotas podem parar respostas; uso pode virar cobrável segundo SKU. | Não configurar projeto de cobrança, key ou Places na versão inicial. |
| Google Maps conteúdo | Links externos apenas | Termos proíbem exportar, extrair, armazenar/copiar nomes, endereços ou conteúdo do Maps para uso fora dos serviços. [8] | Não aplicável: não há scraping nem diretório criado de dados do Maps. | Não aplicável. |
| Nominatim público | Não usado como motor de listas | Limite absoluto de 1 req/s, sem autocompletar, sem consultas sistemáticas e com restrições para uso comercial/escalável. [9] | Pode bloquear pedidos; alternativas requerem instância própria ou fornecedor. | Não assumir que seja backend comercial gratuito. |
| IA | Desativada por padrão | Não existe API de IA incluída por este projeto ou pela assinatura Manus do operador. | Rascunho determinístico continua disponível; apenas campos fornecidos são usados. | Só conectar provedor após analisar plano, chave, limite e custo. |

## Uso comercial

A documentação oficial consultada apresenta Cloudflare Pages e Supabase como plataformas para desenvolvimento e implantação, sem cláusula de plano Free citada que proíba operar um produto comercial. Isso **não é uma garantia jurídica**: Nicolas deve ler os termos vigentes e requisitos de privacidade antes de vender. A recomendação evita Vercel Hobby e não depende dele.

## Consequências práticas

- O endereço inicial deve ser `https://SEU-PROJETO.pages.dev`; domínio próprio é opcional e tem custo próprio fora das cotas.
- O banco deve receber backup manual antes de mudanças, porque backup diário automático é recurso de planos pagos do Supabase. [4]
- A pausa por inatividade é um risco real: o proprietário recebe avisos e pode retomar pelo Dashboard. Não automatize “heartbeat” só para contornar a política; faça acompanhamento operacional honesto.
- Ao crescer, estime custo de egress, Storage, usuários, SMTP, IA e suporte antes de assinar cada empresa. Não anuncie “ilimitado”.
- Como Places requer faturamento e os termos vedam o armazenamento/exportação de listings fora do serviço, a aplicação usa CSV, URL pública e validação manual de fontes. Links do Maps podem ser conservados quando fornecidos e verificados como link, sem copiar dados do Maps.

## Referências

[1]: https://developers.cloudflare.com/pages/platform/limits/ "Cloudflare Pages limits"
[2]: https://www.cloudflare.com/developer-platform/products/pages/ "Cloudflare Pages"
[3]: https://developers.cloudflare.com/workers/platform/pricing/ "Cloudflare Workers pricing"
[4]: https://supabase.com/pricing "Supabase pricing"
[5]: https://supabase.com/docs/guides/platform/billing-on-supabase "Supabase billing"
[6]: https://supabase.com/docs/guides/platform/free-project-pausing "Supabase project pausing"
[7]: https://developers.google.com/maps/documentation/places/web-service/usage-and-billing "Google Places API usage and billing"
[8]: https://cloud.google.com/maps-platform/terms "Google Maps Platform terms of service"
[9]: https://operations.osmfoundation.org/policies/nominatim/ "Nominatim usage policy"
