# Supplier Catalog Integration & Stock Replenishment

An ETL and decision-support project that combines **Pentaho Kettle**, **SQL Server**, and **KNIME** to turn heterogeneous supplier catalogs into stock replenishment proposals.

Developed for Information Systems Integration, Computer Systems Engineering, 2026/2027.

[Watch the demo](video/31497_31502_demonstracao.mp4) · [Read the project report](doc/31497_31502_doc.pdf)

The demo lasts 4 minutes 40 seconds. If GitHub does not display a player, use **View raw** or **Download raw file**. The report also includes the video link and QR code in section 6. The original report and project identifiers are in Portuguese.

## Problem and approach

A computer equipment store receives catalogs from three suppliers in CSV, XML, and JSON. Supplier product references differ, and the inputs include invalid values and a duplicate offer.

1. **Kettle** normalizes and validates the catalogs, retains rejected records with their reasons, and maps supplier references to internal products.
2. **SQL Server** stores the consolidated catalog, inserting new offers and updating existing ones.
3. **KNIME** reads the catalog, stock levels, and replenishment rules. It identifies products below minimum stock and selects the cheapest offer capable of fulfilling the entire required quantity.


```text
CSV / XML / JSON → Kettle → SQL Server → KNIME → CSV proposals
                                         ↑
                              Stock CSV + rules JSON
```

The data is fictional. The workflow generates purchase proposals; it does not place orders. A product's requirement is not split across suppliers. Offers are identified by supplier and reference; missing offers in later catalogs are not deleted automatically.

## Technologies

Pentaho Data Integration / Kettle · Microsoft SQL Server · KNIME · JDBC · CSV · XML · JSON

## Repository structure

| Path | Contents |
| --- | --- |
| `doc/` | Final PDF report |
| `dataintegration/` | Five Kettle transformations (.ktr) and the integrated job (.kjb); normalization scripts are embedded in the transformation steps |
| `knime/` | Importable Reposicao_Stock.knwf package, including CSV/JSON inputs |
| `dados/entrada/` | Supplier catalogs, product mapping, stock, and replenishment rules |
| `dados/intermedios/` | Sample normalized supplier offers, overwritten by the job |
| `dados/saida/` | Consolidated catalog and valid/rejected XML samples; knime/ contains five output CSV files |
| `sqlserver/` | Database, table, and view creation script; verification queries |
| `drivers/` | Microsoft JDBC 13.6.0 driver, Windows x64 authentication library, and license |
| `video/` | MP4 demonstration and music credits |

## Requirements

- Windows x64 to reproduce the supplied authentication setup.
- Pentaho Data Integration / Spoon **10.2.0.0-222**, with a compatible Java installation.
- SQL Server **2019 or later**, plus SQL Server Management Studio.
- KNIME Analytics Platform **5.12.0**, with database, Microsoft SQL Server, JSON processing, and Math Formula extensions. Install missing extensions when prompted during import.
- A Windows account allowed to create the database and read/write data on the local SQL Server instance.

Clone or extract the repository while preserving its directory structure. Do not run the files from inside a ZIP archive.

## Setup and execution

### 1. Prepare SQL Server

1. Start the SQL Server instance and connect through Management Studio using **Windows Authentication**.
2. Run `sqlserver/01_criar_base_e_tabelas.sql`. It creates `TP1_FornecedoresStock`, the `Fornecedores`, `Produtos`, and `Ofertas` tables, reference data, and `dbo.vw_CatalogoKNIME`. It does not delete an existing database.
3. In SQL Server Configuration Manager, verify that **TCP/IP** is enabled and the local instance listens on port **1433**. If needed, set **IPAll → TCP Port = 1433**, remove the dynamic port, and restart the service. The supplied setup uses a local server and does not require remote access between the authors' computers.

### 2. Run Kettle

1. With Spoon closed, copy `drivers/mssql-jdbc-13.6.0.jre8.jar` into the Pentaho installation's `lib` directory. Avoid keeping different versions of the same driver there. Copy `drivers/mssql-jdbc_auth-13.6.0.x64.dll` into `libswt/win64`.
2. Open Spoon and load `dataintegration/00_executar_integracao_sqlserver.kjb`.
3. Press **F9**, select local execution, and confirm `SQL_HOST=localhost`, `SQL_PORT=1433`, and `SQL_DATABASE=TP1_FornecedoresStock`. Adjust these values and the KNIME connector if your instance differs.
4. Run the job and verify **Success**. Its five transformations import suppliers A, B, and C, consolidate the catalog, and load SQL Server. Input/output paths are relative to the transformations.
5. Run `sqlserver/03_consultas_demonstracao.sql` in Management Studio. The supplied data should produce **3 suppliers, 5 products, and 15 offers**.

### 3. Run KNIME

1. Import `knime/Reposicao_Stock.knwf` through **File → Import KNIME Workflow** or the home page's **Import workflow** option into your local workspace.
2. Register the driver through **File → Preferences → KNIME → Databases → Add**: ID `sqlserver_tp1`, type **Microsoft SQL Server**, class `com.microsoft.sqlserver.jdbc.SQLServerDriver`. Add the supplied JAR and use **Add directory** to include the `drivers` directory containing the authentication DLL. Restart KNIME if needed to load the native library.
3. In **Microsoft SQL Server Connector**, select that driver, server `localhost`, port `1433`, and database `TP1_FornecedoresStock`. The supplied connection uses Windows authentication without a SQL username/password, with `integratedSecurity=true`, `encrypt=true`, and `trustServerCertificate=true`. The last setting is for the local demonstration instance's certificate.
4. Stock and rule readers use `data/input` inside the imported workflow; writers use `data/output`. These relative paths do not depend on the authors' directories. Included inputs match `dados/entrada`.
5. Select **Reset**, then **Execute all**, to recalculate even if saved tables exist. Confirm that all **31 nodes** execute. Writers overwrite previous CSV outputs.
6. Inspect the workflow's `data/output` directory or the final node tables. Reference outputs are provided in `dados/saida/knime`.

## Expected results

These are the documented reference results for the supplied sample data.

| Output file | Expected result |
| --- | --- |
| `regras_invalidas.csv` | 0 invalid rules |
| `produtos_a_repor.csv` | 4 products below minimum stock |
| `propostas_compra.csv` | 3 proposals, 38 units, total cost **€291.60** |
| `produtos_sem_fornecedor.csv` | 1 exception: monitor P004, with no single offer able to provide the 12 required units |
| `resumo_fornecedores.csv` | FORN_B: 26 units / €147.60; FORN_C: 12 units / €144.00 |

For mouse P002, supplier B has the lowest price but only 5 units available. Since 12 are required, supplier C is selected at €12.00 per unit. This demonstrates availability filtering before price comparison.

## Authors and responsibilities

| Author | Student no. | Main contribution |
| --- | --- | --- |
| Pedro Filipe Martins Andrade | 31497 | Pentaho Kettle and SQL Server integration |
| Rodrigo Henrique Silva Pinheiro | 31502 | KNIME |

## Third-party credits

**Video music:** Jazz Brunch — Kevin MacLeod (incompetech.com), licensed under [Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/). [Official track source](https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1700074).

**JDBC driver:** [Official Microsoft JDBC 13.6.0 distribution](https://github.com/microsoft/mssql-jdbc/releases/tag/v13.6.0). The driver license is included in `drivers/`.
