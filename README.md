# Integração de catálogos de fornecedores e reposição de stock

Trabalho Prático I de **Integração de Sistemas de Informação**, Licenciatura em Engenharia de Sistemas Informáticos, IPCA, 2026/2027.

| Autor | Número | Plataforma explorada |
|---|---|---|
| Pedro Filipe Martins Andrade | 31497 | Pentaho Kettle e integração com SQL Server |
| Rodrigo Henrique Silva Pinheiro | 31502 | KNIME |

**[Vídeo de demonstração](https://github.com/rpinheiror/TP_ISI/blob/main/video/31497_31502_demonstracao.mp4)** · **[Relatório](doc/31497_31502_doc.pdf)** · **[Repositório](https://github.com/rpinheiror/TP_ISI)**

O vídeo tem 4 min 40 s. Se o GitHub não apresentar o leitor, selecionar **View raw** ou **Download raw file** para abrir ou descarregar o MP4. A ligação e o QR Code constam também da secção 6 do relatório.

## Problema e solução

Uma loja de material informático recebe catálogos de três fornecedores em CSV, XML e JSON. As referências dos artigos diferem entre fornecedores e existem valores inválidos e uma oferta duplicada. É necessário uniformizar estes dados antes de os comparar com o stock e com as regras de reposição da loja.

O Kettle normaliza e valida os catálogos, conserva os rejeitados com o respetivo motivo e associa as ofertas aos produtos internos através de um mapa de correspondências. O catálogo consolidado é inserido ou atualizado no SQL Server. O KNIME consulta a base de dados, identifica os produtos abaixo do stock mínimo e calcula a quantidade necessária para atingir o stock alvo. Para cada produto, escolhe a oferta mais barata que permita satisfazer a quantidade total requerida.

```text
Catálogos CSV, XML e JSON → Kettle → SQL Server → KNIME → Resultados CSV
                                                  ↑
                                        Stock CSV e regras JSON
```

Os dados são fictícios. O processo produz propostas de compra; não efetua encomendas. A necessidade de um produto não é repartida por vários fornecedores.

## Organização dos ficheiros

| Pasta | Conteúdo |
|---|---|
| `doc/` | Relatório final em PDF, com ligação e QR Code para o vídeo. |
| `dataintegration/` | Cinco transformações Kettle (`.ktr`) e o job integrado (`.kjb`). Os scripts de normalização estão nos próprios passos das transformações. |
| `knime/` | Pacote importável `Reposicao_Stock.knwf`, com o workflow e as suas entradas CSV/JSON. |
| `dados/entrada/` | Catálogos dos fornecedores, mapa de produtos, stock e regras de reposição. |
| `dados/intermedios/` | Exemplos das ofertas normalizadas por fornecedor; são substituídos pelo job. |
| `dados/saida/` | Exemplos do catálogo consolidado e dos XML de válidos e rejeitados; `knime/` contém os cinco CSV de resultados. |
| `sqlserver/` | Script de criação da base, tabelas e view; consultas para conferência. |
| `drivers/` | Driver JDBC Microsoft 13.6.0, biblioteca de autenticação Windows x64 e licença. |
| `video/` | Demonstração em MP4 e créditos da música. |

## Requisitos

- Windows x64, para reproduzir a configuração de autenticação utilizada.
- Pentaho Data Integration / Spoon **10.2.0.0-222**, com o Java compatível com essa instalação.
- SQL Server **2019 ou posterior** e SQL Server Management Studio.
- KNIME Analytics Platform **5.12.0**, com as extensões de bases de dados, Microsoft SQL Server, processamento JSON e o nó Math Formula. Ao importar, instalar as extensões em falta que o KNIME indicar.
- Conta Windows com autorização para criar a base e ler e escrever os dados no SQL Server local.

## Execução noutro computador

Descompactar a entrega ou clonar este repositório, mantendo a estrutura das pastas. Não executar os ficheiros diretamente dentro do ZIP.

### 1. Preparar o SQL Server

1. Iniciar o serviço da instância SQL Server e ligar através do Management Studio com **Windows Authentication**.
2. Executar `sqlserver/01_criar_base_e_tabelas.sql`. O script cria a base `TP1_FornecedoresStock`, as tabelas `Fornecedores`, `Produtos` e `Ofertas`, os dados de referência e a view `dbo.vw_CatalogoKNIME`. Não apaga uma base existente.
3. No SQL Server Configuration Manager, confirmar que o protocolo **TCP/IP** está ativo na instância e que esta escuta na porta **1433**. Se for necessário definir a porta, usar `IPAll → TCP Port = 1433`, sem porta dinâmica, e reiniciar o serviço. A configuração do projeto usa o servidor local; não requer acesso remoto entre os computadores dos autores.

### 2. Executar o Kettle

1. Com o Spoon fechado, copiar `drivers/mssql-jdbc-13.6.0.jre8.jar` para a pasta `lib` da instalação do Pentaho Data Integration. Evitar manter versões diferentes do mesmo driver nessa pasta. Copiar `drivers/mssql-jdbc_auth-13.6.0.x64.dll` para `libswt/win64` da mesma instalação.
2. Abrir o Spoon e o ficheiro `dataintegration/00_executar_integracao_sqlserver.kjb`.
3. Premir **F9**, escolher execução local e confirmar os parâmetros `SQL_HOST=localhost`, `SQL_PORT=1433` e `SQL_DATABASE=TP1_FornecedoresStock`. Se a instância tiver outra porta ou localização, adaptar estes parâmetros e, posteriormente, o conector do KNIME.
4. Executar o job e confirmar o estado **Success**. As cinco transformações importam A, B e C, consolidam o catálogo e carregam o SQL Server. As entradas e saídas usam caminhos relativos às transformações.
5. Executar `sqlserver/03_consultas_demonstracao.sql` no Management Studio. Para os dados fornecidos, a base deve conter **3 fornecedores, 5 produtos e 15 ofertas**.

A carga identifica cada oferta pelo fornecedor e pela referência: insere novas ofertas e atualiza as existentes, sem duplicar essa chave. Não elimina ofertas ausentes de um catálogo posterior.

### 3. Executar o KNIME

1. Importar `knime/Reposicao_Stock.knwf` através de **File → Import KNIME Workflow** ou da opção **Import workflow** da página inicial. Selecionar o pacote e concluir a importação para o workspace local.
2. Registar o driver em **File → Preferences → KNIME → Databases → Add**: ID `sqlserver_tp1`, tipo **Microsoft SQL Server**, classe `com.microsoft.sqlserver.jdbc.SQLServerDriver`. Adicionar o JAR fornecido e, através de **Add directory**, a pasta `drivers`, que contém a DLL de autenticação. Reiniciar o KNIME se for necessário carregar a biblioteca nativa.
3. Abrir o nó **Microsoft SQL Server Connector** e confirmar o driver `sqlserver_tp1`, servidor `localhost`, porta `1433` e base `TP1_FornecedoresStock`. A ligação utiliza a conta Windows, sem utilizador ou palavra-passe SQL, e as propriedades JDBC `integratedSecurity=true`, `encrypt=true` e `trustServerCertificate=true`. Esta última destina-se ao certificado da instância local de demonstração.
4. Os leitores de stock e regras usam `data/input` dentro do workflow importado. Os escritores usam `data/output` no mesmo workflow. Estes caminhos são relativos e não dependem das pastas dos autores. As entradas incluídas no pacote correspondem às amostras em `dados/entrada`.
5. Selecionar **Reset** no workflow e depois **Execute all**. Esta sequência recalcula os resultados, mesmo que existam tabelas guardadas. Confirmar a execução dos **31 nós**. Os escritores substituem os CSV anteriores.
6. Consultar a pasta `data/output` do workflow importado ou as tabelas dos nós finais. Os exemplos incluídos na entrega estão em `dados/saida/knime`.

## Resultados esperados

| Ficheiro KNIME | Resultado |
|---|---|
| `regras_invalidas.csv` | 0 registos inválidos. |
| `produtos_a_repor.csv` | 4 produtos abaixo do stock mínimo. |
| `propostas_compra.csv` | 3 propostas, 38 unidades e custo total de **291,60 €**. |
| `produtos_sem_fornecedor.csv` | 1 exceção: monitor P004, sem oferta individual suficiente para as 12 unidades necessárias. |
| `resumo_fornecedores.csv` | FORN_B: 26 unidades e 147,60 €; FORN_C: 12 unidades e 144,00 €. |

No caso do rato P002, o fornecedor B tem o menor preço, mas só dispõe de 5 unidades. Como são necessárias 12, é escolhido C, a 12,00 € por unidade. O exemplo demonstra a aplicação da restrição de disponibilidade antes da comparação de preços.

## Música do vídeo

**Jazz Brunch** — Kevin MacLeod (incompetech.com). Licensed under Creative Commons: By Attribution 4.0.

[Licença CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) · [Fonte oficial da música](https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1700074) · [Distribuição oficial do driver JDBC](https://github.com/microsoft/mssql-jdbc/releases/tag/v13.6.0).
